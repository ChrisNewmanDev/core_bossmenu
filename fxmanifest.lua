fx_version 'cerulean'
game 'gta5'

description 'Modern Boss Menu for QB-Management using core_gps_advanced UI style'

author 'YourName'

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
    'html/style.css',
    'html/app.js'
}
