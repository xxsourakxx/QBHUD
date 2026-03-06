local QBCore = exports['qb-core'] and exports['qb-core']:GetCoreObject() or nil

local function getMetaValue(name)
    if not QBCore or not QBCore.Functions then return nil end
    local data = QBCore.Functions.GetPlayerData()
    if not data or not data.metadata then return nil end
    local value = data.metadata[name]
    if value == nil then return nil end
    return tonumber(value)
end

local function syncMetadata()
    local hunger = getMetaValue('hunger')
    local thirst = getMetaValue('thirst')
    local stress = getMetaValue('stress')
    local bleeding = getMetaValue('bleeding') or getMetaValue('isbleeding')

    if hunger ~= nil then UpdateHudValue('hunger', hunger) end
    if thirst ~= nil then UpdateHudValue('thirst', thirst) end
    if stress ~= nil then UpdateHudValue('stress', stress) end
    if bleeding ~= nil then UpdateBleeding(bleeding) end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', syncMetadata)
RegisterNetEvent('QBCore:Player:SetPlayerData', function(playerData)
    if type(playerData) ~= 'table' or type(playerData.metadata) ~= 'table' then return end

    if playerData.metadata.hunger ~= nil then UpdateHudValue('hunger', playerData.metadata.hunger) end
    if playerData.metadata.thirst ~= nil then UpdateHudValue('thirst', playerData.metadata.thirst) end
    if playerData.metadata.stress ~= nil then UpdateHudValue('stress', playerData.metadata.stress) end

    local bleed = playerData.metadata.bleeding or playerData.metadata.isbleeding
    if bleed ~= nil then UpdateBleeding(bleed) end
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    if newHunger ~= nil then UpdateHudValue('hunger', newHunger) end
    if newThirst ~= nil then UpdateHudValue('thirst', newThirst) end
end)

RegisterNetEvent('hospital:client:SetBleeding', function(level)
    UpdateBleeding(level)
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            local maxHealth = GetEntityMaxHealth(ped) - 100
            local health = GetEntityHealth(ped) - 100
            local value = maxHealth > 0 and (health / maxHealth) * 100 or 100
            UpdateHudValue('health', value)
        end

        Wait(Config.UpdateIntervals.health)
    end
end)

CreateThread(function()
    while true do
        syncMetadata()
        Wait(Config.UpdateIntervals.needs)
    end
end)
