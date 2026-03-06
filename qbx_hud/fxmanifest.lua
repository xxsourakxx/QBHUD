fx_version 'cerulean'
game 'gta5'

name 'qbx_hud'
author 'Codex'
description 'Minimal futuristic survival HUD for QBX with pma-voice integration'
version '1.0.0'

lua54 'yes'

ui_page 'web/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/status.lua',
    'client/voice.lua'
}

server_scripts {
    'server/server.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/assets/icons/*.svg',
    'web/assets/fonts/*.*'
}
