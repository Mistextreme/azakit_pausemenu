fx_version "adamant"
game "gta5"
lua54 'yes'

name         'azakit_pausemenu'
version      '1.0.0'
author 'Azakit'
description 'Pause Menu'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

ui_page "html/index.html"

files {
    "html/index.html",
    "html/styles.css",
    "html/script.js",
}

escrow_ignore {
    'fxmanifest.lua',
    'config.lua'
}

dependency '/assetpacks'