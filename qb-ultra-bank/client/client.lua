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

local function createBankBlips()
    if not Config.ShowBankBlips then return end
    for _, bank in ipairs(Config.BankLocations) do
        local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
        SetBlipSprite(blip, bank.blip or 108)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.75)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(('Bank: %s'):format(bank.label))
        EndTextCommandSetBlipName(blip)
    end
end

local function createBankInteractions()
    if Config.UseTargetForBanks and GetResourceState('qb-target') == 'started' then
        for i, bank in ipairs(Config.BankLocations) do
            exports['qb-target']:AddCircleZone(('qb-ultra-bank:%s'):format(i), bank.coords, 1.2, {
                name = ('qb-ultra-bank:%s'):format(i),
                debugPoly = false,
                useZ = true
            }, {
                options = {
                    {
                        icon = 'fas fa-building-columns',
                        label = ('Open %s'):format(bank.label),
                        action = function()
                            openBankUi('bank')
                        end
                    }
                },
                distance = Config.BankInteractDistance
            })
        end
        return
    end

    CreateThread(function()
        while true do
            local sleep = 1250
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            for _, bank in ipairs(Config.BankLocations) do
                local dist = #(coords - bank.coords)
                if dist <= 15.0 then
                    sleep = 0
                    DrawMarker(2, bank.coords.x, bank.coords.y, bank.coords.z + 0.12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 91, 224, 255, 180, false, false, 2, false, nil, nil, false)
                    if dist <= Config.BankInteractDistance then
                        QBCore.Functions.DrawText3D(bank.coords.x, bank.coords.y, bank.coords.z + 0.35, '[E] Open Bank')
                        if IsControlJustPressed(0, 38) then
                            openBankUi('bank')
                        end
                    end
                end
            end
            Wait(sleep)
        end
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
        if ok then
            setNui(false)
            Wait(100)
            openBankUi('bank')
        end
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
    createBankBlips()
    createBankInteractions()

    if GetResourceState('qb-target') == 'started' then
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
    end
end)
