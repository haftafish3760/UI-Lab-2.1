import { BackupError, MAX_OBJECT_BYTES, reject, token } from './backup_contract.mjs';

// Authentication is injected for tests. The production entry point below always
// verifies revocation and App Check, without an emulator/auth bypass switch.
export function backupRequestHandler({ authenticate, ledger, objects, enabled }) {
  return async (req, res) => {
    res.set('Cache-Control', 'no-store').set('X-Content-Type-Options', 'nosniff');
    try {
      if (!enabled()) reject(503, 'backup_not_enabled');
      if (req.method !== 'POST') reject(405, 'post_required');
      const route = req.path.split('/').filter(Boolean).at(-1);
      if (!['usage', 'claim', 'reserve', 'cancel', 'recover', 'upload', 'download'].includes(route)) reject(404, 'unknown_backup_action');
      const limit = route === 'upload' ? MAX_OBJECT_BYTES : 4096;
      if (!Buffer.isBuffer(req.rawBody) || req.rawBody.length > limit) reject(413, 'request_too_large');
      const actor = await authenticate(req);
      if (route === 'upload') {
        const companyId = token(req.get('X-Backup-Workspace'));
        const attemptId = token(req.get('X-Backup-Attempt'));
        await ledger.admitRequest(actor, companyId, route, req.rawBody.length, attemptId);
        return res.json(await objects.upload(actor, companyId, attemptId, req.get('Content-Type'), req.rawBody));
      }
      if (!req.is('application/json') || !req.body || Array.isArray(req.body)) reject(400, 'json_required');
      const companyId = token(req.body.companyId);
      await ledger.admitRequest(actor, companyId, route, req.rawBody.length, req.body.attemptId);
      if (route === 'usage') return res.json(await ledger.usage(actor, companyId));
      if (route === 'claim') return res.json(await ledger.claim(actor, companyId, req.body.approvalId));
      const attemptId = token(req.body.attemptId);
      if (route === 'reserve') return res.json(await ledger.reserve(actor, companyId, attemptId, req.body));
      if (route === 'cancel') return res.json(await objects.cancel(actor, companyId, attemptId));
      if (route === 'recover') return res.json(await objects.recover(actor, companyId, attemptId));
      const result = await objects.download(actor, companyId, attemptId);
      return res.set('Content-Disposition', 'attachment').type(result.contentType).send(result.body);
    } catch (error) {
      // Never return raw provider errors, tokens, object paths or receipt bytes.
      const known = error instanceof BackupError;
      return res.status(known ? error.status : 503).json({ error: known ? error.code : 'backup_temporarily_unavailable' });
    }
  };
}
