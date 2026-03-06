CREATE TABLE IF NOT EXISTS bank_profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL UNIQUE,
  account_holder VARCHAR(120) NOT NULL,
  account_number VARCHAR(32) NOT NULL UNIQUE,
  iban VARCHAR(64) NOT NULL UNIQUE,
  branch_code VARCHAR(20) NOT NULL,
  credit_score INT NOT NULL DEFAULT 640,
  credit_rating VARCHAR(20) NOT NULL DEFAULT 'GOOD',
  financial_risk VARCHAR(20) NOT NULL DEFAULT 'GOOD',
  account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  debit_card_status VARCHAR(20) NOT NULL DEFAULT 'UNISSUED',
  created_at DATETIME NOT NULL,
  INDEX idx_profiles_credit (credit_score)
);

CREATE TABLE IF NOT EXISTS bank_accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL,
  account_type VARCHAR(30) NOT NULL,
  account_number VARCHAR(32) NOT NULL UNIQUE,
  iban VARCHAR(64) NOT NULL UNIQUE,
  branch_code VARCHAR(20) NOT NULL,
  balance BIGINT NOT NULL DEFAULT 0,
  overdraft_limit BIGINT NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL,
  INDEX idx_accounts_citizenid (citizenid),
  INDEX idx_accounts_iban (iban)
);

CREATE TABLE IF NOT EXISTS bank_cards (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL,
  account_id INT NOT NULL,
  card_type VARCHAR(20) NOT NULL,
  card_number VARCHAR(25) NOT NULL UNIQUE,
  expiry VARCHAR(5) NOT NULL,
  cvv VARCHAR(3) NOT NULL,
  pin_hash VARCHAR(128) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  failed_attempts INT NOT NULL DEFAULT 0,
  freeze_until DATETIME NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_cards_citizenid (citizenid),
  INDEX idx_cards_account_id (account_id)
);

CREATE TABLE IF NOT EXISTS bank_transactions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  transaction_id VARCHAR(24) NOT NULL UNIQUE,
  citizenid VARCHAR(50) NOT NULL,
  account_id INT NOT NULL,
  tx_type VARCHAR(30) NOT NULL,
  amount BIGINT NOT NULL,
  location VARCHAR(100) NOT NULL,
  balance_after BIGINT NOT NULL,
  metadata JSON NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_tx_citizenid_date (citizenid, created_at),
  INDEX idx_tx_account_date (account_id, created_at)
);

CREATE TABLE IF NOT EXISTS bank_loans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL,
  account_id INT NOT NULL,
  loan_type VARCHAR(20) NOT NULL,
  principal BIGINT NOT NULL,
  interest_rate DECIMAL(6,4) NOT NULL,
  months_total INT NOT NULL,
  months_remaining INT NOT NULL,
  monthly_payment BIGINT NOT NULL,
  status VARCHAR(20) NOT NULL,
  risk_tier VARCHAR(20) NOT NULL,
  next_due_date DATETIME NOT NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_loans_citizenid (citizenid),
  INDEX idx_loans_due (status, next_due_date)
);

CREATE TABLE IF NOT EXISTS bank_credit_score (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL,
  delta INT NOT NULL,
  reason VARCHAR(80) NOT NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_credit_history (citizenid, created_at)
);
