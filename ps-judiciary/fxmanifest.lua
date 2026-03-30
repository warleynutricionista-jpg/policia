fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'ps-judiciary'
author 'Sistema Policial RP'
description 'Painel Jurídico para Tribunal RP (Juiz/Promotor/Advogado)'
version '1.0.0'

ui_page 'html/index.html'

dependencies {
    'oxmysql',
    'ox_lib',
    'ps-mdt',
    'ps-forensics',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'items/items.lua',
    'sql/*.sql',
}
