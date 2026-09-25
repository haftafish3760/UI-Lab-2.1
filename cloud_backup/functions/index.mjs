import { onRequest } from 'firebase-functions/v2/https';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getAppCheck } from 'firebase-admin/app-check';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { BackupAllowanceLedger } from './backup_allowance_ledger.mjs';
import { BackupObjectStore } from './backup_object_store.mjs';
import { backupRequestHandler } from './backup_request_handler.mjs';
import { reject } from './backup_contract.mjs';

if (!getApps().length) initializeApp();
let handler;
async function authenticate(req) {
  const bearer = req.get('Authorization');
  const appCheck = req.get('X-Firebase-AppCheck');
  if (typeof bearer !== 'string' || !bearer.startsWith('Bearer ') || !appCheck) reject(401, 'authentication_required');
  const allowedApps = (process.env.BACKUP_ALLOWED_APP_IDS ?? '').split(',').map(s => s.trim()).filter(Boolean);
  if (!allowedApps.length) reject(503, 'backup_app_allowlist_required');
  let identity, attestation;
  try {
    [identity, attestation] = await Promise.all([
      getAuth().verifyIdToken(bearer.slice(7), true), getAppCheck().verifyToken(appCheck),
    ]);
  } catch { reject(401, 'authentication_required'); }
  if (!allowedApps.includes(attestation.appId)) reject(403, 'backup_app_not_allowed');
  return identity;
}

// Deployment is intentionally not configured in firebase.emulator.json. Cloud
// project, bucket, IAM, membership and eligibility providers need verification.
export const backupApi = onRequest({ cors: false, maxInstances: 3, concurrency: 1,
  memory: '256MiB', timeoutSeconds: 60 }, async (req, res) => {
  if (process.env.BACKUP_ENABLED !== 'true' || !process.env.BACKUP_BUCKET) {
    return res.set('Cache-Control', 'no-store').status(503).json({ error: 'backup_not_enabled' });
  }
  if (!handler) {
    const ledger = new BackupAllowanceLedger(getFirestore());
    const objects = new BackupObjectStore(getStorage().bucket(process.env.BACKUP_BUCKET), ledger,
      { allowInFlightCancellation: process.env.BACKUP_OBJECT_PRECONDITIONS_VERIFIED === 'true' });
    handler = backupRequestHandler({ authenticate, ledger, objects,
      enabled: () => process.env.BACKUP_ENABLED === 'true' });
  }
  return handler(req, res);
});
