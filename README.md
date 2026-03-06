# QBHUD

## qb-ultra-bank

A full financial ecosystem resource for QBCore servers.

### Features
- Automatic financial identity generation (account number, IBAN, branch, credit score, risk profile)
- Multi-account banking (personal, business, savings, investment, HVC)
- Physical debit card issuance with secure PIN hashing
- ATM + digital banking actions (withdraw, deposit, transfer)
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
- `/openbank` opens full branch-style dashboard
- `/openatm` opens ATM-mode UI
- Target any ATM prop with qb-target to open ATM directly

### Notes
- Add an inventory item named `bank_card` in your item definitions.
- Loan processing runs hourly and checks for due installments.
- All monetary mutations are server-authoritative.
