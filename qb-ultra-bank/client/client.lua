local QBCore = exports['qb-core']:GetCoreObject()
local uiOpen = false

local function setNui(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close' })
end

local function openBankUi(mode)
    if uiOpen then return end
    QBCore.Functions.TriggerCallback('qb-ultra-bank:server:getDashboard', function(payload)
        if not payload then return end
        setNui(true)
        SendNUIMessage({
            action = 'hydrate',
            mode = mode,
            data = payload,
            accountTypes = Config.AccountTypes,
            loanTypes = Config.LoanTypes,
            cardTypes = Config.CardTypes
        })
    end)
end

RegisterCommand('openbank', function()
    openBankUi('bank')
end)

RegisterCommand('openatm', function()
    openBankUi('atm')
end)

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb({ ok = true })
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('qb-ultra-bank:server:atmWithdraw', data.accountId, data.amount)
    cb({ ok = true })
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('qb-ultra-bank:server:atmDeposit', data.accountId, data.amount)
    cb({ ok = true })
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('qb-ultra-bank:server:transfer', data.accountId, data.destination, data.amount)
    cb({ ok = true })
end)

RegisterNUICallback('newAccount', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-ultra-bank:server:createAccount', function(ok, msg)
        QBCore.Functions.Notify(msg, ok and 'success' or 'error')
        if ok then openBankUi('bank') end
        cb({ ok = ok })
    end, data.accountType)
end)

RegisterNUICallback('newCard', function(data, cb)
    TriggerServerEvent('qb-ultra-bank:server:requestCard', data.accountId, data.cardType, data.pin)
    cb({ ok = true })
end)

RegisterNUICallback('loanApply', function(data, cb)
    TriggerServerEvent('qb-ultra-bank:server:applyLoan', data.accountId, data.loanType, data.amount, data.months)
    cb({ ok = true })
end)

CreateThread(function()
    exports['qb-target']:AddTargetModel(Config.ATMModels, {
        options = {
            {
                icon = 'fas fa-credit-card',
                label = 'Use ATM',
                action = function()
                    openBankUi('atm')
                end
            }
        },
        distance = 1.4
    })
end)
