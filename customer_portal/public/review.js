const el = (id) => document.getElementById(id);
const token = location.hash.slice(1);
let review, busy = false;
async function request(action, body = {}) {
  const response = await fetch(`/api/${action}`, { method: 'POST', cache: 'no-store',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify(body) });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || 'The review service is unavailable.');
  return data;
}
function money(cents) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: review.snapshot.currency }).format(cents / 100);
}
function displayDecision(decision) {
  el('response').hidden = true;
  el('decision').hidden = false;
  el('decision').textContent = `${decision.action === 'approved' ? 'Approved' : 'Declined'} by ${decision.name} on ${new Date(decision.at).toLocaleString()}. Your response is recorded for this version.`;
}
function render() {
  const d = review.snapshot;
  el('company').textContent = d.company;
  el('approve').textContent = `Approve ${d.kind.toLowerCase()}`;
  el('decline').textContent = `Decline ${d.kind.toLowerCase()}`;
  el('heading').textContent = `Review your ${d.kind.toLowerCase()}`;
  el('number').textContent = d.number;
  el('title').textContent = d.title;
  el('description').textContent = d.description;
  el('customer').textContent = d.customer;
  el('address').textContent = d.customerDetails;
  el('expiry').textContent = new Date(review.expiresAt).toLocaleDateString();
  el('reference').textContent = d.reference ? `Purchase order: ${d.reference}` : '';
  el('terms').textContent = d.terms;
  el('contact').textContent = d.companyDetails;
  el('items').replaceChildren(...d.items.map((i) => {
    const row = document.createElement('li'); row.className = 'item-row';
    for (const value of [`${i.name}${i.description ? `\n${i.description}` : ''}`, `${i.quantity} ${i.unit}`, money(i.unitPriceCents), money(i.totalCents)]) {
      const cell = document.createElement('span'); cell.textContent = value; row.append(cell);
    }
    return row;
  }));
  const totals = [['Subtotal', d.items.reduce((sum, i) => sum + i.totalCents, 0)],
    ...(d.discountCents ? [['Discount', -d.discountCents]] : []), ...(d.taxCents ? [['Tax', d.taxCents]] : []), ['Total', d.totalCents]];
  el('totals').replaceChildren(...totals.map(([name, value]) => {
    const row = document.createElement('div'), term = document.createElement('dt'), amount = document.createElement('dd');
    term.textContent = name; amount.textContent = money(value); row.append(term, amount); return row;
  }));
  el('document').hidden = false;
  el('status').textContent = '';
  el('response').hidden = !['Estimate', 'Quote'].includes(d.kind) || Boolean(review.decision);
  if (review.decision) displayDecision(review.decision);
}
async function load() {
  el('retry').hidden = true;
  if (!/^[A-Za-z0-9_-]{43}$/.test(token)) {
    el('status').textContent = 'Open the private review link sent by your service company.'; return;
  }
  try { review = await request('view'); render(); }
  catch (error) { el('status').textContent = error.message; el('retry').hidden = false; }
}
async function respond(action) {
  if (busy || !review) return;
  if (!el('name').reportValidity()) return;
  if (action === 'approved' && !el('reviewed').checked) {
    el('status').textContent = 'Please confirm that you reviewed the work and terms.'; el('reviewed').focus(); return;
  }
  if (action === 'declined' && !window.confirm(`Decline this ${review.snapshot.kind.toLowerCase()}? The company will receive your response.`)) return;
  busy = true; el('approve').disabled = el('decline').disabled = true;
  try {
    const result = await request('respond', { action, name: el('name').value.trim(), reviewed: el('reviewed').checked, digest: review.digest });
    displayDecision(result.decision); el('status').textContent = '';
  } catch (error) { el('status').textContent = `${error.message} You can retry safely.`; }
  finally { busy = false; el('approve').disabled = el('decline').disabled = false; }
}
el('response').addEventListener('submit', (event) => { event.preventDefault(); respond('approved'); });
el('decline').addEventListener('click', () => respond('declined'));
el('retry').addEventListener('click', load);
el('print').addEventListener('click', () => window.print());
load();
