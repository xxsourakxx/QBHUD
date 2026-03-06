local QBCore = exports['qb-core']:GetCoreObject()
local profileCache = {}

local function randomDigits(length)
    local out = ''
    for _ = 1, length do
        out = out .. tostring(math.random(0, 9))
    end
    return out
end

local function formatCardNumber()
    return string.format('%s %s %s %s', randomDigits(4), randomDigits(4), randomDigits(4), randomDigits(4))
end

local function generateAccountNumber()
    return ('AC-%s'):format(randomDigits(8))
end

local function generateIban()
    return ('RPBL-%s-%s-%s'):format(randomDigits(4), randomDigits(4), randomDigits(4))
end

local function creditTier(score)
    for _, tier in ipairs(Config.CreditTiers) do
        if score >= tier.min and score <= tier.max then
            return tier
        end
    end
    return Config.CreditTiers[1]
end

local function now()
    return os.date('%Y-%m-%d %H:%M:%S')
end

local function fetchProfile(citizenid)
    if profileCache[citizenid] then return profileCache[citizenid] end
    local row = MySQL.single.await('SELECT * FROM bank_profiles WHERE citizenid = ?', { citizenid })
    if row then
        profileCache[citizenid] = row
    end
    return row
end

local function createFinancialProfile(Player)
    local citizenid = Player.PlayerData.citizenid
    local exists = fetchProfile(citizenid)
    if exists then return exists end

    local branch = Config.Branches[math.random(1, #Config.Branches)]
    local score = Config.StartingCreditScore
    local tier = creditTier(score)
    local accountNumber = generateAccountNumber()
    local iban = generateIban()

    MySQL.insert.await([[
        INSERT INTO bank_profiles
            (citizenid, account_holder, account_number, iban, branch_code, credit_score, credit_rating, financial_risk, account_status, debit_card_status, created_at)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', 'UNISSUED', ?)
    ]], {
        citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        accountNumber,
        iban,
        branch.code,
        score,
        tier.label,
        tier.label,
        now()
    })

    local profile = fetchProfile(citizenid)

    MySQL.insert.await([[
        INSERT INTO bank_accounts
            (citizenid, account_type, account_number, iban, branch_code, balance, overdraft_limit, status, created_at)
        VALUES
            (?, 'personal', ?, ?, ?, 0, ?, 'ACTIVE', ?)
    ]], {
        citizenid,
        accountNumber,
        iban,
        branch.code,
        Config.DefaultOverdraftLimit,
        now()
    })

    profileCache[citizenid] = nil
    return fetchProfile(citizenid)
end

local function addTransaction(citizenid, accountId, txType, amount, location, balanceAfter, meta)
    MySQL.insert.await([[
        INSERT INTO bank_transactions
            (transaction_id, citizenid, account_id, tx_type, amount, location, balance_after, metadata, created_at)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        ('TX-%s'):format(randomDigits(8)),
        citizenid,
        accountId,
        txType,
        amount,
        location,
        balanceAfter,
        json.encode(meta or {}),
        now()
    })
end

local function updateCredit(citizenid, delta, reason)
    local profile = fetchProfile(citizenid)
    if not profile then return end
    local score = math.min(Config.MaxCreditScore, math.max(Config.MinCreditScore, (profile.credit_score or 600) + delta))
    local tier = creditTier(score)
    MySQL.update.await('UPDATE bank_profiles SET credit_score = ?, credit_rating = ?, financial_risk = ? WHERE citizenid = ?', {
        score,
        tier.label,
        tier.label,
        citizenid
    })
    MySQL.insert.await('INSERT INTO bank_credit_score (citizenid, delta, reason, created_at) VALUES (?, ?, ?, ?)', {
        citizenid,
        delta,
        reason,
        now()
    })
    profileCache[citizenid] = nil
end

local function accountById(citizenid, accountId)
    return MySQL.single.await('SELECT * FROM bank_accounts WHERE id = ? AND citizenid = ?', { accountId, citizenid })
end

local function setBalance(accountId, newBalance)
    MySQL.update.await('UPDATE bank_accounts SET balance = ? WHERE id = ?', { newBalance, accountId })
end

local function chargePayment(citizenid, amount, reason)
    local account = MySQL.single.await("SELECT * FROM bank_accounts WHERE citizenid = ? AND account_type = 'personal' ORDER BY id ASC LIMIT 1", { citizenid })
    if not account then return false, 'No personal account' end
    local projected = (account.balance or 0) - amount
    if projected < -(account.overdraft_limit or 0) then
        return false, 'Overdraft limit exceeded'
    end
    setBalance(account.id, projected)
    addTransaction(citizenid, account.id, reason, -amount, 'AUTOMATED_PAYMENT', projected)
    return true
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    createFinancialProfile(Player)
end)

QBCore.Functions.CreateCallback('qb-ultra-bank:server:getDashboard', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end

    local citizenid = Player.PlayerData.citizenid
    local profile = createFinancialProfile(Player)
    local accounts = MySQL.query.await('SELECT * FROM bank_accounts WHERE citizenid = ? ORDER BY id ASC', { citizenid })
    local cards = MySQL.query.await('SELECT * FROM bank_cards WHERE citizenid = ? ORDER BY id DESC', { citizenid })
    local loans = MySQL.query.await('SELECT * FROM bank_loans WHERE citizenid = ? ORDER BY id DESC', { citizenid })
    local transactions = MySQL.query.await('SELECT * FROM bank_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT 50', { citizenid })

    cb({
        profile = profile,
        accounts = accounts,
        cards = cards,
        loans = loans,
        transactions = transactions,
        serverTime = now()
    })
end)

QBCore.Functions.CreateCallback('qb-ultra-bank:server:createAccount', function(source, cb, accountType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false, 'Invalid player') end
    if not Config.AccountTypes[accountType] then return cb(false, 'Invalid account type') end

    local citizenid = Player.PlayerData.citizenid
    local count = MySQL.single.await('SELECT COUNT(*) as c FROM bank_accounts WHERE citizenid = ?', { citizenid })
    if (count and count.c or 0) >= Config.MaxAccounts then
        return cb(false, 'Maximum account limit reached')
    end

    if Player.PlayerData.money.bank < Config.AccountCreationFee then
        return cb(false, 'Insufficient bank funds for account creation fee')
    end

    Player.Functions.RemoveMoney('bank', Config.AccountCreationFee, 'bank-account-creation-fee')

    local branch = Config.Branches[math.random(1, #Config.Branches)]
    local accountNumber = generateAccountNumber()
    local iban = generateIban()

    MySQL.insert.await([[
        INSERT INTO bank_accounts
        (citizenid, account_type, account_number, iban, branch_code, balance, overdraft_limit, status, created_at)
        VALUES (?, ?, ?, ?, ?, 0, ?, 'ACTIVE', ?)
    ]], {
        citizenid,
        accountType,
        accountNumber,
        iban,
        branch.code,
        Config.AccountTypes[accountType].overdraft and Config.DefaultOverdraftLimit or 0,
        now()
    })

    cb(true, 'Account created')
end)

RegisterNetEvent('qb-ultra-bank:server:atmWithdraw', function(accountId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local account = accountById(Player.PlayerData.citizenid, accountId)
    if not account then return end

    local projected = account.balance - amount
    if projected < -(account.overdraft_limit or 0) then
        TriggerClientEvent('QBCore:Notify', src, 'Overdraft limit exceeded', 'error')
        return
    end

    setBalance(account.id, projected)
    Player.Functions.AddMoney('cash', amount, 'atm-withdraw')
    addTransaction(Player.PlayerData.citizenid, account.id, 'WITHDRAWAL', -amount, 'ATM', projected)
    updateCredit(Player.PlayerData.citizenid, 1, 'healthy_atm_usage')
    TriggerClientEvent('QBCore:Notify', src, ('Withdrew $%s'):format(amount), 'success')
end)

RegisterNetEvent('qb-ultra-bank:server:atmDeposit', function(accountId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if Player.PlayerData.money.cash < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Insufficient cash', 'error')
        return
    end

    local account = accountById(Player.PlayerData.citizenid, accountId)
    if not account then return end

    Player.Functions.RemoveMoney('cash', amount, 'atm-deposit')
    local newBalance = account.balance + amount
    setBalance(account.id, newBalance)
    addTransaction(Player.PlayerData.citizenid, account.id, 'DEPOSIT', amount, 'ATM', newBalance)
    updateCredit(Player.PlayerData.citizenid, 2, 'consistent_deposit')
    TriggerClientEvent('QBCore:Notify', src, ('Deposited $%s'):format(amount), 'success')
end)

RegisterNetEvent('qb-ultra-bank:server:transfer', function(fromAccountId, destinationIban, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local citizenid = Player.PlayerData.citizenid
    local fromAccount = accountById(citizenid, fromAccountId)
    if not fromAccount then return end

    local totalDebit = amount + Config.TransferFee
    local projected = fromAccount.balance - totalDebit
    if projected < -(fromAccount.overdraft_limit or 0) then
        TriggerClientEvent('QBCore:Notify', src, 'Insufficient balance/overdraft for transfer', 'error')
        return
    end

    local dest = MySQL.single.await('SELECT * FROM bank_accounts WHERE iban = ? OR account_number = ?', { destinationIban, destinationIban })
    if not dest then
        TriggerClientEvent('QBCore:Notify', src, 'Destination account not found', 'error')
        return
    end

    setBalance(fromAccount.id, projected)
    setBalance(dest.id, dest.balance + amount)

    addTransaction(citizenid, fromAccount.id, 'TRANSFER_OUT', -totalDebit, 'ONLINE', projected, {
        to = destinationIban,
        fee = Config.TransferFee
    })
    addTransaction(dest.citizenid, dest.id, 'TRANSFER_IN', amount, 'ONLINE', dest.balance + amount, {
        from = fromAccount.iban
    })

    updateCredit(citizenid, 1, 'valid_transfer_activity')
    TriggerClientEvent('QBCore:Notify', src, 'Transfer completed', 'success')
end)

RegisterNetEvent('qb-ultra-bank:server:requestCard', function(accountId, cardType, pin)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Config.CardTypes[cardType] then return end
    if not tostring(pin):match('^%d%d%d%d%d?%d?$') then
        TriggerClientEvent('QBCore:Notify', src, 'PIN must be 4 to 6 digits', 'error')
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local account = accountById(citizenid, accountId)
    if not account then return end

    local cardNumber = formatCardNumber()
    local expiry = os.date('%m/%y', os.time() + (3600 * 24 * 365 * 3))
    local cvv = randomDigits(3)

    MySQL.insert.await([[
        INSERT INTO bank_cards
        (citizenid, account_id, card_type, card_number, expiry, cvv, pin_hash, status, failed_attempts, freeze_until, created_at)
        VALUES (?, ?, ?, ?, ?, ?, SHA2(?, 256), 'ACTIVE', 0, NULL, ?)
    ]], {
        citizenid,
        account.id,
        cardType,
        cardNumber,
        expiry,
        cvv,
        tostring(pin),
        now()
    })

    MySQL.update.await('UPDATE bank_profiles SET debit_card_status = ? WHERE citizenid = ?', { 'ACTIVE', citizenid })
    profileCache[citizenid] = nil

    Player.Functions.AddItem('bank_card', 1, false, {
        holder = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        number = cardNumber,
        expiry = expiry,
        cvv = cvv,
        type = Config.CardTypes[cardType],
        iban = account.iban
    })
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['bank_card'], 'add', 1)
    TriggerClientEvent('QBCore:Notify', src, 'Debit card issued', 'success')
end)

RegisterNetEvent('qb-ultra-bank:server:applyLoan', function(accountId, loanType, amount, months)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    amount = tonumber(amount)
    months = tonumber(months)
    if not Config.LoanTypes[loanType] then return end
    local loanCfg = Config.LoanTypes[loanType]
    if amount < loanCfg.min or amount > loanCfg.max then return end

    local validMonth = false
    for _, m in ipairs(loanCfg.months) do
        if m == months then validMonth = true break end
    end
    if not validMonth then return end

    local citizenid = Player.PlayerData.citizenid
    local profile = fetchProfile(citizenid)
    if not profile then return end

    local account = accountById(citizenid, accountId)
    if not account then return end

    local tier = creditTier(profile.credit_score)
    local interest = loanCfg.baseInterest * tier.loanModifier
    local monthlyRate = interest / 12
    local monthlyPayment = math.floor((amount * monthlyRate) / (1 - ((1 + monthlyRate) ^ (-months))))
    local risk = tier.label

    MySQL.insert.await([[
        INSERT INTO bank_loans
        (citizenid, account_id, loan_type, principal, interest_rate, months_total, months_remaining, monthly_payment, status, risk_tier, next_due_date, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, DATE_ADD(NOW(), INTERVAL 30 DAY), ?)
    ]], {
        citizenid,
        account.id,
        loanType,
        amount,
        interest,
        months,
        months,
        monthlyPayment,
        risk,
        now()
    })

    local newBalance = account.balance + amount
    setBalance(account.id, newBalance)
    addTransaction(citizenid, account.id, 'LOAN_DISBURSEMENT', amount, 'BRANCH', newBalance, { loanType = loanType })
    updateCredit(citizenid, 4, 'loan_approved')

    TriggerClientEvent('QBCore:Notify', src, ('Loan approved. $%s credited'):format(amount), 'success')
end)

CreateThread(function()
    while true do
        Wait(60 * 60 * 1000)
        local loans = MySQL.query.await("SELECT * FROM bank_loans WHERE status = 'ACTIVE' AND next_due_date <= NOW()")
        for _, loan in ipairs(loans or {}) do
            local ok = select(1, chargePayment(loan.citizenid, loan.monthly_payment, 'LOAN_PAYMENT'))
            if ok then
                local remaining = loan.months_remaining - 1
                if remaining <= 0 then
                    MySQL.update.await("UPDATE bank_loans SET status = 'PAID', months_remaining = 0 WHERE id = ?", { loan.id })
                    updateCredit(loan.citizenid, 8, 'loan_paid_off')
                else
                    MySQL.update.await("UPDATE bank_loans SET months_remaining = ?, next_due_date = DATE_ADD(next_due_date, INTERVAL 30 DAY) WHERE id = ?", {
                        remaining,
                        loan.id
                    })
                    updateCredit(loan.citizenid, 2, 'on_time_loan_payment')
                end
            else
                local penalty = math.floor(loan.monthly_payment * 0.1)
                MySQL.update.await("UPDATE bank_loans SET monthly_payment = monthly_payment + ?, next_due_date = DATE_ADD(next_due_date, INTERVAL 7 DAY) WHERE id = ?", {
                    penalty,
                    loan.id
                })
                updateCredit(loan.citizenid, -15, 'missed_loan_payment')
            end
        end
    end
end)

exports('GetCreditScore', function(citizenid)
    local profile = fetchProfile(citizenid)
    return profile and profile.credit_score or Config.StartingCreditScore
end)

RegisterNetEvent('qb-phone:server:getBankingData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local profile = fetchProfile(citizenid)
    local personal = MySQL.single.await("SELECT * FROM bank_accounts WHERE citizenid = ? AND account_type = 'personal' LIMIT 1", { citizenid })
    local tx = MySQL.query.await('SELECT * FROM bank_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT 15', { citizenid })

    TriggerClientEvent('qb-phone:client:bankingData', src, {
        balance = personal and personal.balance or 0,
        creditScore = profile and profile.credit_score or Config.StartingCreditScore,
        creditRating = profile and profile.credit_rating or 'GOOD',
        transactions = tx
    })
end)
