local function getStatusValue(name)
    -- Supports qbx exports as primary and event-based updates as backup.
    local ok, value = pcall(function()
        if exports.qbx_core and exports.qbx_core.GetStatus then
            return exports.qbx_core:GetStatus(name)
        end
    end)

    if ok and value then
        local percent = value.percent or value.value or value
        return math.max(0, math.min(100, tonumber(percent) or 100))
    end

    return nil
end

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    if newHunger ~= nil then UpdateHudValue('hunger', newHunger) end
    if newThirst ~= nil then UpdateHudValue('thirst', newThirst) end
end)

RegisterNetEvent('qbx_hud:client:updateNeeds', function(payload)
    if type(payload) ~= 'table' then return end
    if payload.hunger ~= nil then UpdateHudValue('hunger', payload.hunger) end
    if payload.thirst ~= nil then UpdateHudValue('thirst', payload.thirst) end
    if payload.stress ~= nil and Config.EnableStress then UpdateHudValue('stress', payload.stress) end
end)

CreateThread(function()
    local ped

    while true do
        ped = PlayerPedId()
        if ped and ped ~= 0 then
            local health = GetEntityHealth(ped) - 100
            local maxHealth = GetEntityMaxHealth(ped) - 100
            local normalizedHealth = maxHealth > 0 and (health / maxHealth) * 100 or 100
            UpdateHudValue('health', normalizedHealth)
            UpdateHudValue('armor', GetPedArmour(ped))
        end

        Wait(Config.UpdateIntervals.healthArmor)
    end
end)

CreateThread(function()
    while true do
        local hunger = getStatusValue('hunger')
        local thirst = getStatusValue('thirst')
        local stress = getStatusValue('stress')

        if hunger then UpdateHudValue('hunger', hunger) end
        if thirst then UpdateHudValue('thirst', thirst) end
        if stress and Config.EnableStress then UpdateHudValue('stress', stress) end

        Wait(Config.UpdateIntervals.statusFallback)
    end
end)
