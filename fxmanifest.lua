fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'Cadburry (ByteCode Studios)'
description 'Weather/Time Sync with climate zones'
version '0.8'

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/**/shared.lua',
    'modules/**/shared.lua'
}

files {
    'config.lua'
}

client_scripts {
    'bridge/**/client.lua',
    'modules/**/client.lua',
}

server_scripts {
    'bridge/**/server.lua',
    'modules/**/server.lua',
}

dependencies {
    'ox_lib'
}
