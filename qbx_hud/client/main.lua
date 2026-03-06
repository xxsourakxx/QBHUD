local HUD_VISIBLE = true
local STATE = {
    health = 100,
    hunger = 100,
    thirst = 100,
    stress = 0,
    bleeding = 0,
    speed = 0,
    voiceMode = 2,
    talking = false
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
        barGap = Config.BarGap,
        panelOpacity = Config.PanelOpacity,
        animationSpeed = Config.AnimationSpeed,
        low = Config.LowThresholds,
        theme = Config.Theme,
        bleeding = Config.Bleeding,
        speedometer = Config.Speedometer
    })
end

local function setCircleMap(enabled)
    if not enabled then
        SetMinimapClipType(0)
        return
    end

    SetMinimapClipType(1)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end

function UpdateHudValue(key, value)
    local clamped = math.max(0, math.min(100, math.floor((tonumber(value) or 0) + 0.5)))
    if STATE[key] == clamped then return end
    STATE[key] = clamped
    sendUI('status', { key = key, value = clamped })
end

function UpdateSpeed(speed)
    local safe = math.max(0, math.floor((tonumber(speed) or 0) + 0.5))
    if STATE.speed == safe then return end
    STATE.speed = safe
    sendUI('speed', { value = safe, unit = Config.Speedometer.unit })
end

function UpdateBleeding(level)
    local safeLevel = math.max(0, math.min(Config.Bleeding.maxLevel, math.floor((tonumber(level) or 0) + 0.5)))
    if STATE.bleeding == safeLevel then return end
    STATE.bleeding = safeLevel
    sendUI('bleeding', { level = safeLevel, max = Config.Bleeding.maxLevel })
end

function UpdateVoice(mode, talking)
    local mapped = Config.VoiceModes[tonumber(mode) or 2] and (tonumber(mode) or 2) or 2
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
        label = voiceData.label,
        color = voiceData.color,
        icon = voiceData.icon,
        range = voiceData.range,
        talking = STATE.talking
    })
end

local function setVisible(toggle)
    if HUD_VISIBLE == toggle then return end
    HUD_VISIBLE = toggle
    sendUI('toggle', { visible = HUD_VISIBLE })
    DisplayRadar(HUD_VISIBLE)
end

RegisterCommand('hud', function()
    setVisible(not HUD_VISIBLE)
end, false)

RegisterCommand('hudreset', function()
    applyConfig()
    sendUI('reset', {})
end, false)

RegisterNetEvent('qbx_hud:client:setStress', function(value)
    UpdateHudValue('stress', value)
end)

RegisterNetEvent('qbx_hud:client:setBleeding', function(level)
    UpdateBleeding(level)
end)

CreateThread(function()
    Wait(500)
    applyConfig()
    setCircleMap(Config.CircleMap.enabled)

    sendUI('status', { key = 'health', value = STATE.health })
    sendUI('status', { key = 'hunger', value = STATE.hunger })
    sendUI('status', { key = 'thirst', value = STATE.thirst })
    sendUI('status', { key = 'stress', value = STATE.stress })
    sendUI('speed', { value = STATE.speed, unit = Config.Speedometer.unit })
    sendUI('bleeding', { level = STATE.bleeding, max = Config.Bleeding.maxLevel })
    sendUI('toggle', { visible = HUD_VISIBLE })
    UpdateVoice(STATE.voiceMode, false)
end)

CreateThread(function()
    local paused = false
    while true do
        local nowPaused = IsPauseMenuActive()
        if nowPaused ~= paused then
            paused = nowPaused
            sendUI('pause', { paused = paused })
        end
        Wait(Config.UpdateIntervals.pause)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local speedKmh = GetEntitySpeed(vehicle) * 3.6
            UpdateSpeed(speedKmh)
            DisplayRadar(HUD_VISIBLE)
        else
            UpdateSpeed(0)
            DisplayRadar(HUD_VISIBLE and IsPedOnFoot(ped) == false)
        end

        Wait(Config.UpdateIntervals.speed)
    end
end)
