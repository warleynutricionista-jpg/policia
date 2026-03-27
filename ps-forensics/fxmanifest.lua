fx_version 'cerulean'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
game 'gta5'

name 'ps-forensics'
author 'Sistema Policial RP'
description 'Sistema Forense Completo - Perícia Criminal, Medicina Legal, Laboratório Forense'
version '1.1.0'

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
    'shared/constants.lua',
    'config.lua',
    'shared/locale.lua',
    'shared/utils.lua',
    -- Mapeamento de imagens (acessível em client e server)
    'data/evidence_images.lua',
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
    -- Imagens de evidências (suporte a PNG, SVG e WebP)
    'html/images/evidence/*.png',
    'html/images/evidence/*.svg',
    'html/images/evidence/*.webp',
    'data/*.lua',
    'locales/*.lua',
    'sql/*.sql',
    'sql/migrations/*.lua',
    'sql/migrations/*.sql',
    'sql/backup/*.sql',
}
