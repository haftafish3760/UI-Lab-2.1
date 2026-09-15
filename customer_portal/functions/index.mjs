import { onRequest } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { ReviewError, publicSnapshot, newToken, tokenKey, digest, requireOpen, decisionFor } from './review_contract.mjs';

initializeApp();
const db = getFirestore();
const bearer = (req) => (req.headers.authorization ?? '').replace(/^Bearer /, '');
async function publisher(req) {
  let actor;
  try { actor = await getAuth().verifyIdToken(bearer(req), true); }
  catch { throw new ReviewError(401, 'Sign in to share documents.'); }
  if (!actor.companyId || actor.canShareDocuments !== true) throw new ReviewError(403, 'Document sharing is not permitted.');
  const grant = await db.doc(`portalPermissions/${digest(`${actor.companyId}:${actor.uid}`)}`).get();
  if (!grant.exists || grant.data().canShareDocuments !== true || grant.data().companyId !== actor.companyId) {
    throw new ReviewError(403, 'Document sharing is not permitted.');
  }
  return actor;
}

export const reviewApi = onRequest({ cors: false, maxInstances: 5 }, async (req, res) => {
  res.set('Cache-Control', 'no-store').set('Referrer-Policy', 'no-referrer');
  try {
    if (req.method !== 'POST') throw new ReviewError(405, 'Use a supported request.');
    if (!req.is('application/json') || Buffer.byteLength(JSON.stringify(req.body ?? {})) > 300000) {
      throw new ReviewError(400, 'The request is invalid or too large.');
    }
    const route = req.path.split('/').filter(Boolean).at(-1);
    if (route === 'issue') {
      const actor = await publisher(req);
      const snapshot = publicSnapshot(req.body.snapshot ?? {});
      const recordId = req.body.recordId;
      if (typeof recordId !== 'string' || !recordId || recordId.length > 200) throw new ReviewError(400, 'Invalid document identity.');
      const token = newToken(), key = tokenKey(token), now = Date.now();
      const expiresAt = Math.min(now + 7 * 86400000, snapshot.validUntil ? Date.parse(snapshot.validUntil) : Infinity);
      if (expiresAt <= now) throw new ReviewError(409, 'Update the expired document before sharing.');
      const sourceKey = digest(`${actor.companyId}:${recordId}`);
      const sourceRef = db.doc(`portalSources/${sourceKey}`);
      const review = { snapshot, digest: digest(JSON.stringify(snapshot)), companyId: actor.companyId,
        recordId, sourceKey, createdBy: actor.uid, createdAt: now, expiresAt, revokedAt: null, decision: null };
      await db.runTransaction(async (tx) => {
        const source = await tx.get(sourceRef);
        if (source.exists && source.data().revision > snapshot.revision) throw new ReviewError(409, 'A newer revision has already been shared.');
        if (source.exists && source.data().revision === snapshot.revision && source.data().digest !== review.digest) throw new ReviewError(409, 'This revision already has a different customer copy. Save a new revision first.');
        if (source.exists && source.data().revision === snapshot.revision) {
          const prior = await tx.get(db.doc(`portalReviews/${source.data().activeKey}`));
          if (prior.exists && prior.data().decision) throw new ReviewError(409, 'This version already has a customer response. Create a new revision for changes.');
        }
        tx.create(db.doc(`portalReviews/${key}`), review);
        tx.set(sourceRef, { revision: snapshot.revision, activeKey: key, digest: review.digest, companyId: actor.companyId });
      });
      return res.json({ token, expiresAt, digest: review.digest });
    }
    if (route === 'status') {
      const actor = await publisher(req);
      const row = await db.doc(`portalReviews/${tokenKey(req.body.token)}`).get();
      if (!row.exists || row.data().companyId !== actor.companyId) throw new ReviewError(404, 'Review unavailable.');
      const r = row.data();
      return res.json({ snapshot: r.snapshot, digest: r.digest, decision: r.decision, revokedAt: r.revokedAt, expiresAt: r.expiresAt });
    }
    if (route === 'revoke') {
      const actor = await publisher(req);
      const key = tokenKey(req.body.token);
      await db.runTransaction(async (tx) => {
        const ref = db.doc(`portalReviews/${key}`), row = await tx.get(ref);
        if (!row.exists || row.data().companyId !== actor.companyId) throw new ReviewError(404, 'Review unavailable.');
        tx.update(ref, { revokedAt: Date.now(), revokedBy: actor.uid });
      });
      return res.json({ revoked: true });
    }
    const key = tokenKey(bearer(req));
    const ref = db.doc(`portalReviews/${key}`);
    const result = await db.runTransaction(async (tx) => {
      const row = await tx.get(ref), review = row.data();
      requireOpen(review);
      const source = await tx.get(db.doc(`portalSources/${review.sourceKey}`));
      if (!source.exists || source.data().activeKey !== key) throw new ReviewError(410, 'A newer document link is available. Ask the company for that link.');
      if (route === 'view') return { snapshot: review.snapshot, digest: review.digest, expiresAt: review.expiresAt, decision: review.decision };
      if (route !== 'respond') throw new ReviewError(404, 'Review action unavailable.');
      const decision = decisionFor(review, req.body);
      tx.update(ref, { decision });
      return { decision };
    });
    return res.json(result);
  } catch (error) {
    return res.status(error instanceof ReviewError ? error.status : 503).json({
      error: error instanceof ReviewError ? error.message : 'The review service is unavailable. Please try again.' });
  }
});
