local currentMode = 2

local function modeFromDistance(distance)
    local nearestMode = 2
    local nearestDiff = math.huge

    for mode, data in pairs(Config.VoiceModes) do
        local diff = math.abs(distance - data.range)
        if diff < nearestDiff then
            nearestDiff = diff
            nearestMode = mode
        end
    end

    return nearestMode
end

RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
    currentMode = tonumber(mode) or currentMode
    UpdateVoice(currentMode, NetworkIsPlayerTalking(PlayerId()))
end)

RegisterNetEvent('pma-voice:setVoiceProperty', function(property, value)
    if property ~= 'proximity' then return end
    currentMode = modeFromDistance(tonumber(value) or Config.VoiceModes[2].range)
    UpdateVoice(currentMode, NetworkIsPlayerTalking(PlayerId()))
end)

CreateThread(function()
    while true do
        local talking = NetworkIsPlayerTalking(PlayerId())

        local ok, mode = pcall(function()
            if exports['pma-voice'] and exports['pma-voice'].getVoiceMode then
                return exports['pma-voice']:getVoiceMode()
            end
        end)

        if ok and mode then
            currentMode = tonumber(mode) or currentMode
        end

        UpdateVoice(currentMode, talking)
        Wait(Config.UpdateIntervals.voice)
    end
end)
