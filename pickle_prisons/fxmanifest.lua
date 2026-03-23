-- fxmanifest.lua — pickle_prisons (ajustado p/ Qbox)
fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

name 'pickle_prisons'
author 'Pickle Mods'
version '1.1.6'
description 'Prison system with XP bridge (Qbox/ox_lib/oxmysql)'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/assets/**/*.*',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/locale.lua',
    'locales/translations/*.lua',
    'core/shared.lua',
}

client_scripts {
    'bridge/**/**/client.lua',
    'modules/**/client.lua',
    'core/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',         -- ✅ substitui mysql-async
    'bridge/**/**/server.lua',
    'modules/**/server.lua',
}

dependencies {
    'ox_lib'
}
