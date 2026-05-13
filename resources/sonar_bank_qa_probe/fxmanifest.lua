fx_version 'cerulean'
game 'gta5'
lua54 'yes'

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua',
}

dependencies {
  'oxmysql',
  'sonar_bridges',
  'sonar_bank_app',
}
