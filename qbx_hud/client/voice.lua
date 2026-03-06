local currentMode = 2

local function modeFromDistance(distance)
    local selected = 2
    local diffMin = math.huge

    for mode, data in pairs(Config.VoiceModes) do
        local diff = math.abs((tonumber(distance) or 8.0) - data.range)
        if diff < diffMin then
            diffMin = diff
            selected = mode
        end
    end

    return selected
end

RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
    currentMode = tonumber(mode) or currentMode
    UpdateVoice(currentMode, NetworkIsPlayerTalking(PlayerId()))
end)

RegisterNetEvent('pma-voice:setVoiceProperty', function(property, value)
    if property ~= 'proximity' then return end
    currentMode = modeFromDistance(value)
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
