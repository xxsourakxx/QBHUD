Config = Config or {}

Config.Position = 'bottom-left'
Config.OffsetX = 1.2 -- vw
Config.OffsetY = 2.2 -- vh

Config.BarWidth = 118
Config.BarHeight = 8
Config.BarGap = 7
Config.PanelOpacity = 0.24
Config.AnimationSpeed = 170

Config.UpdateIntervals = {
    health = 250,
    needs = 1800,
    voice = 120,
    pause = 350
}

Config.Theme = {
    panel = 'rgba(150, 205, 255, 0.08)',
    text = '#e8f6ff',
    muted = '#9ab0c2',
    health = '#ff667a',
    hunger = '#ffbd73',
    thirst = '#78e7ff',
    stress = '#c88dff',
    bleeding = '#ff4d67',
    whisper = '#76ccff',
    normal = '#74ffc4',
    shout = '#ff9b70'
}

Config.LowThresholds = {
    health = 25,
    hunger = 20,
    thirst = 20,
    stress = 80
}

Config.Bleeding = {
    maxLevel = 4,
    pulseFromLevel = 2
}

Config.VoiceModes = {
    [1] = { label = 'Whisper', range = 1.5, icon = 'assets/icons/voice-whisper.svg', color = '#76ccff' },
    [2] = { label = 'Normal', range = 8.0, icon = 'assets/icons/voice-normal.svg', color = '#74ffc4' },
    [3] = { label = 'Shout', range = 20.0, icon = 'assets/icons/voice-shout.svg', color = '#ff9b70' }
}
