fx_version 'cerulean'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
game 'gta5'

name 'ps-mdt'
author "Project Sloth Development Team"
description 'Project Sloth MDT - QBox Optimized'
version '3.1.0'

ui_page 'web/dist/index.html'

dependencies {
  'oxmysql',
  'ox_lib',
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/ps.lua',
}

client_scripts {
  'client/**.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/schema.lua',
  'server/items.lua',
  'server/*.lua',
  'server/backend/*.lua'
}

files {
  'web/dist/index.html',
  'web/dist/**/*',
  'items/*.lua',
}

data_file 'DLC_ITYP_REQUEST' 'stream/ps-mdt.ytyp'

-- Server convars (set in server.cfg):
-- set ps_mdt_fivemanage_key_images "YOUR_FIVEMANAGE_IMAGES_API_KEY"
-- set ps_mdt_fivemanage_key_logs   "YOUR_FIVEMANAGE_LOGS_API_KEY"
convar_category 'PS-MDT' {
  'Settings for ps-mdt resource',
  {
    { 'FiveManage Images API Key', 'ps_mdt_fivemanage_key_images', 'CV_STRING', '' },
    { 'FiveManage Logs API Key',   'ps_mdt_fivemanage_key_logs',   'CV_STRING', '' },
  }
}
