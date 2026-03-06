const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const identityGrid = document.getElementById('identityGrid');
const accounts = document.getElementById('accounts');
const accountSelect = document.getElementById('accountSelect');
const loanSummary = document.getElementById('loanSummary');
const txFeed = document.getElementById('txFeed');
const serverTime = document.getElementById('serverTime');

let state = { data: null };

const nui = (event, payload = {}) => fetch(`https://${GetParentResourceName()}/${event}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json; charset=UTF-8' },
  body: JSON.stringify(payload)
});

const currency = (n) => `$${Number(n || 0).toLocaleString()}`;

function render(payload) {
  state.data = payload;
  const profile = payload.profile || {};

  serverTime.innerText = payload.serverTime || '';
  identityGrid.innerHTML = `
    <div>Account: ${profile.account_number || '-'}</div>
    <div>IBAN: ${profile.iban || '-'}</div>
    <div>Branch: ${profile.branch_code || '-'}</div>
    <div>Credit: ${profile.credit_score || '-'} (${profile.credit_rating || '-'})</div>
    <div>Status: ${profile.account_status || '-'}</div>
    <div>Risk: ${profile.financial_risk || '-'}</div>`;

  accounts.innerHTML = '';
  accountSelect.innerHTML = '';
  payload.accounts.forEach((acc) => {
    const row = document.createElement('div');
    row.className = 'list-item';
    row.innerHTML = `<strong>${acc.account_type.toUpperCase()}</strong><br>${acc.account_number}<br>${currency(acc.balance)}`;
    accounts.appendChild(row);

    const opt = document.createElement('option');
    opt.value = acc.id;
    opt.textContent = `${acc.account_type} | ${acc.account_number}`;
    accountSelect.appendChild(opt);
  });

  const card = payload.cards[0];
  if (card) {
    document.getElementById('cardNum').innerText = card.card_number;
    document.getElementById('cardHolder').innerText = profile.account_holder || 'ACCOUNT HOLDER';
    document.getElementById('cardExpiry').innerText = card.expiry;
  }

  loanSummary.innerHTML = payload.loans.length
    ? payload.loans.map((loan) => `<div class='list-item'>${loan.loan_type.toUpperCase()} | ${currency(loan.principal)} | ${currency(loan.monthly_payment)}/mo | ${loan.months_remaining} months left</div>`).join('')
    : '<div class="list-item">No active loans</div>';

  txFeed.innerHTML = payload.transactions.map((tx) =>
    `<div class='list-item'><strong>${tx.tx_type}</strong> ${currency(tx.amount)}<br><small>${tx.location} • ${tx.created_at}</small></div>`
  ).join('');
}

window.addEventListener('message', (e) => {
  const msg = e.data;
  if (msg.action === 'open') app.classList.remove('hidden');
  if (msg.action === 'close') app.classList.add('hidden');
  if (msg.action === 'hydrate') render(msg.data);
});

closeBtn.addEventListener('click', () => nui('close'));

document.getElementById('withdrawBtn').addEventListener('click', () => nui('withdraw', {
  accountId: Number(accountSelect.value),
  amount: Number(document.getElementById('amount').value)
}));

document.getElementById('depositBtn').addEventListener('click', () => nui('deposit', {
  accountId: Number(accountSelect.value),
  amount: Number(document.getElementById('amount').value)
}));

document.getElementById('transferBtn').addEventListener('click', () => nui('transfer', {
  accountId: Number(accountSelect.value),
  destination: document.getElementById('destination').value,
  amount: Number(document.getElementById('amount').value)
}));
