fx_version 'cerulean'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
game 'gta5'

name 'ps-forensics'
author 'Sistema Policial RP'
description 'Sistema Forense Completo - Perícia Criminal, Medicina Legal, Laboratório Forense'
version '1.0.0'

ui_page 'html/index.html'

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'ps-mdt',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/locale.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/backend/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/schema.lua',
    'server/auth.lua',
    'server/backend/*.lua',
}

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'data/*.lua',
    'locales/*.lua',
    'sql/*.sql',
}
