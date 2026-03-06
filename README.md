# QBHUD

## qb-ultra-bank

A full financial ecosystem resource for QBCore servers.

### Features
- Automatic financial identity generation (account number, IBAN, branch, credit score, risk profile)
- Multi-account banking (personal, business, savings, investment, HVC)
- Physical debit card issuance with secure PIN hashing
- ATM + digital banking actions (withdraw, deposit, transfer)
- Real map bank support (bank blips + in-world interaction zones)
- Credit score engine and historical score events
- Loan underwriting + recurring repayment processor
- Overdraft-aware balance validation
- qb-phone banking data event integration
- Glassmorphism NUI dashboard with animated card and financial feed

### Install
1. Import SQL schema from `qb-ultra-bank/sql/bank.sql`.
2. Place `qb-ultra-bank` in your resources folder.
3. Ensure dependencies:
   - `qb-core`
   - `qb-target`
   - `oxmysql`
   - `ox_lib`
4. Add to `server.cfg`:
   ```cfg
   ensure qb-ultra-bank
   ```

### Usage
- Walk up to any configured bank branch marker or map blip and interact.
- Target any ATM prop with qb-target to open ATM directly.
- `/openbank` opens full branch-style dashboard.
- `/openatm` opens ATM-mode UI.

### Troubleshooting
- If bank UI does not open, verify resource load order:
  `ensure oxmysql` -> `ensure qb-core` -> `ensure qb-target` -> `ensure qb-ultra-bank`.
- Confirm `bank_card` exists in your item definitions.
- Ensure `qb-target` is running if you want ATM model targeting.
- If you disable target usage, set `Config.UseTargetForBanks = false` for marker + `[E]` mode.

### Notes
- Loan processing runs hourly and checks for due installments.
- All monetary mutations are server-authoritative.
