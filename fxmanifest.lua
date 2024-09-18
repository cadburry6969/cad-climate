fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'Cadburry (ByteCode Studios)'
description 'Climate Control & Sync'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua',
    'bridge/cl_*.lua',
}

server_scripts {
    'server.lua',
    'bridge/sv_*.lua',
}

dependencies {
    'ox_lib'
}
