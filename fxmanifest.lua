fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'Cadburry (ByteCode Studios)'
description 'Climate Control & Sync'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}
client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib'
}
