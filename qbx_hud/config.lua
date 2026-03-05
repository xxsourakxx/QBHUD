Config = Config or {}

Config.Position = 'bottom-left'
Config.OffsetX = 1.35 -- vw
Config.OffsetY = 2.4 -- vh

Config.BarWidth = 178
Config.BarHeight = 8
Config.BarSpacing = 5
Config.BarRadius = 999
Config.PanelOpacity = 0.28
Config.AnimationSpeed = 180
Config.EnableStress = true

Config.UpdateIntervals = {
    healthArmor = 300,
    statusFallback = 2500,
    voice = 150,
    pause = 400
}

Config.Theme = {
    health = '#ff4d5f',
    armor = '#62a9ff',
    hunger = '#ffba59',
    thirst = '#5ad9ff',
    stress = '#be78ff',
    panel = 'rgba(18, 30, 48, 0.28)',
    text = '#ebf6ff',
    muted = '#9db0c0',
    accent = '#42ffd7'
}

Config.LowThresholds = {
    health = 25,
    hunger = 20,
    thirst = 20,
    stress = 80
}

Config.VoiceModes = {
    [1] = { label = 'Whisper', range = 1.5, icon = '🔈', color = '#67d3ff' },
    [2] = { label = 'Normal', range = 8.0, icon = '🔉', color = '#60ffc6' },
    [3] = { label = 'Shout', range = 20.0, icon = '📢', color = '#ff8a5a' }
}
