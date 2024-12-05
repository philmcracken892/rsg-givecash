fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

shared_scripts {
    '@ox_lib/init.lua',
   
}

client_scripts {
    'cgivecash.lua'
}

server_scripts {
    'sgivecash.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
	'ox_target'
	
    
}

lua54 'yes'

