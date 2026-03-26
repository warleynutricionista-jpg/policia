fx_version 'cerulean'
game 'gta5'

description 'QB-ActiveOfficers - Active Police Officers Listing System'
version '1.0.0'
author 'Claude'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css',
    'img/ranks/*.png',
    'img/default_avatar.png'
}

dependencies {
    'qbx_core',
    'pma-voice'   
}

lua54 'yes'
