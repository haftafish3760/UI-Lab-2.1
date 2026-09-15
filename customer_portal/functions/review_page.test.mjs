import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { JSDOM } from 'jsdom';
import { sample } from './review_contract.test.mjs';

test('customer page renders the public document and records approval once', async () => {
  const dom = new JSDOM(await readFile(new URL('../public/index.html', import.meta.url), 'utf8'), {
    url: `https://review.example/#${'a'.repeat(43)}`, runScripts: 'outside-only',
  });
  const { window } = dom, requests = [];
  window.fetch = async (url, options) => {
    requests.push({ url, body: JSON.parse(options.body) });
    return { ok: true, json: async () => url.endsWith('view')
      ? { snapshot: { ...sample, description: '<script>private</script>' }, expiresAt: Date.now() + 10000, digest: 'current' }
      : { decision: { action: 'approved', name: 'Maya Thompson', at: Date.now() } } };
  };
  window.eval(await readFile(new URL('../public/review.js', import.meta.url), 'utf8'));
  await new Promise(resolve => setTimeout(resolve, 0));
  const doc = window.document;
  assert.equal(doc.getElementById('document').hidden, false);
  assert.equal(doc.querySelectorAll('.item-row').length, 1);
  assert.equal(doc.getElementById('description').children.length, 0);
  doc.getElementById('name').value = 'Maya Thompson';
  doc.getElementById('reviewed').checked = true;
  doc.getElementById('response').dispatchEvent(new window.Event('submit', { cancelable: true }));
  await new Promise(resolve => setTimeout(resolve, 0));
  assert.equal(requests[1].body.digest, 'current');
  assert.equal(doc.getElementById('response').hidden, true);
  assert.match(doc.getElementById('decision').textContent, /Approved by Maya/);
  window.close();
});
