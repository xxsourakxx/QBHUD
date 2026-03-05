local HUD_VISIBLE = true
local STATE = {
    health = 100,
    armor = 0,
    hunger = 100,
    thirst = 100,
    stress = 0,
    voiceMode = 2,
    talking = false,
    paused = false
}

local function sendUI(action, payload)
    SendNUIMessage({ action = action, data = payload })
end

local function applyConfig()
    sendUI('config', {
        position = Config.Position,
        offsetX = Config.OffsetX,
        offsetY = Config.OffsetY,
        barWidth = Config.BarWidth,
        barHeight = Config.BarHeight,
        barSpacing = Config.BarSpacing,
        barRadius = Config.BarRadius,
        panelOpacity = Config.PanelOpacity,
        animationSpeed = Config.AnimationSpeed,
        enableStress = Config.EnableStress,
        theme = Config.Theme,
        low = Config.LowThresholds
    })
end

function UpdateHudValue(key, value)
    value = math.max(0, math.min(100, math.floor(value + 0.5)))
    if STATE[key] == value then return end
    STATE[key] = value
    sendUI('status', { key = key, value = value })
end

function UpdateVoice(mode, talking)
    local mapped = Config.VoiceModes[mode] and mode or 2
    local changed = false

    if STATE.voiceMode ~= mapped then
        STATE.voiceMode = mapped
        changed = true
    end

    if STATE.talking ~= talking then
        STATE.talking = talking
        changed = true
    end

    if not changed then return end

    local voiceData = Config.VoiceModes[STATE.voiceMode]
    sendUI('voice', {
        mode = STATE.voiceMode,
        label = voiceData.label,
        icon = voiceData.icon,
        color = voiceData.color,
        talking = STATE.talking,
        range = voiceData.range
    })
end

local function setHudVisible(toggle)
    if HUD_VISIBLE == toggle then return end
    HUD_VISIBLE = toggle
    sendUI('toggle', { visible = HUD_VISIBLE })
end

RegisterCommand('hud', function()
    setHudVisible(not HUD_VISIBLE)
end, false)

RegisterCommand('hudreset', function()
    applyConfig()
    sendUI('reset', {})
end, false)

RegisterNetEvent('qbx_hud:client:setStress', function(value)
    if not Config.EnableStress then return end
    UpdateHudValue('stress', tonumber(value) or 0)
end)

CreateThread(function()
    Wait(500)
    applyConfig()

    for key, value in pairs(STATE) do
        if key == 'voiceMode' or key == 'talking' or key == 'paused' then
            goto continue
        end
        sendUI('status', { key = key, value = value })
        ::continue::
    end

    UpdateVoice(STATE.voiceMode, STATE.talking)
    sendUI('toggle', { visible = HUD_VISIBLE })
end)

CreateThread(function()
    local lastPause = false
    while true do
        local paused = IsPauseMenuActive()
        if paused ~= lastPause then
            lastPause = paused
            sendUI('pause', { paused = paused })
        end
        Wait(Config.UpdateIntervals.pause)
    end
end)
