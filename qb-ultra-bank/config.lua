Config = {}

Config.Debug = false
Config.StartingCreditScore = 640
Config.MinCreditScore = 300
Config.MaxCreditScore = 850
Config.MaxPinAttempts = 3
Config.CardFreezeHours = 24
Config.DefaultOverdraftLimit = 1500
Config.OverdraftInterestRate = 0.06
Config.TransferFee = 25
Config.AccountCreationFee = 500
Config.MaxAccounts = 5

Config.CreditTiers = {
    { label = 'POOR', min = 300, max = 500, loanModifier = 1.35 },
    { label = 'FAIR', min = 501, max = 650, loanModifier = 1.15 },
    { label = 'GOOD', min = 651, max = 720, loanModifier = 1.0 },
    { label = 'EXCELLENT', min = 721, max = 800, loanModifier = 0.85 },
    { label = 'ELITE', min = 801, max = 850, loanModifier = 0.7 }
}

Config.AccountTypes = {
    personal = { label = 'Personal Account', overdraft = true, interest = 0.00 },
    business = { label = 'Business Account', overdraft = true, interest = 0.00 },
    savings = { label = 'Savings Account', overdraft = false, interest = 0.02 },
    investment = { label = 'Investment Account', overdraft = false, interest = 0.04 },
    hvc = { label = 'High Value Client Account', overdraft = true, interest = 0.01 }
}

Config.CardTypes = {
    standard = 'Standard Debit',
    premium = 'Premium Debit',
    business = 'Business Card',
    credit = 'Credit Card'
}

Config.Branches = {
    { code = 'DTF01', name = 'Downtown Financial Center' },
    { code = 'VNB02', name = 'Vinewood Private Banking' },
    { code = 'SND03', name = 'Sandy Regional Branch' }
}

Config.LoanTypes = {
    personal = { label = 'Personal Loan', min = 1000, max = 100000, baseInterest = 0.075, months = { 6, 12, 24 } },
    vehicle = { label = 'Vehicle Loan', min = 5000, max = 250000, baseInterest = 0.065, months = { 12, 24, 36 } },
    business = { label = 'Business Loan', min = 10000, max = 500000, baseInterest = 0.08, months = { 12, 24, 48 } },
    mortgage = { label = 'Mortgage', min = 100000, max = 2000000, baseInterest = 0.055, months = { 60, 120, 240 } },
    emergency = { label = 'Emergency Loan', min = 500, max = 20000, baseInterest = 0.095, months = { 3, 6, 12 } }
}

Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

Config.UseTargetForBanks = true
Config.ShowBankBlips = true
Config.BankInteractDistance = 2.0

Config.BankLocations = {
    { label = 'Legion Fleeca', coords = vector3(149.88, -1040.89, 29.37), blip = 108 },
    { label = 'Hawick Fleeca', coords = vector3(313.47, -278.81, 54.17), blip = 108 },
    { label = 'Del Perro Fleeca', coords = vector3(-1212.98, -330.84, 37.79), blip = 108 },
    { label = 'Rockford Hills Fleeca', coords = vector3(-351.34, -49.63, 49.04), blip = 108 },
    { label = 'Alta Fleeca', coords = vector3(1175.07, 2706.41, 38.09), blip = 108 },
    { label = 'Paleto Bay Bank', coords = vector3(-111.2, 6469.42, 31.63), blip = 108 }
}
