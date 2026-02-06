-- Modern Boss Menu for QB-Management using core_gps_advanced UI style
local QBCore = exports['qb-core']:GetCoreObject()
local isMenuOpen = false

RegisterNetEvent('core_bossmenu:openMenu', function(data)
    SetNuiFocus(true, true)
    isMenuOpen = true
    SendNUIMessage({
        action = 'open',
        data = data
    })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    isMenuOpen = false
    cb('ok')
end)

RegisterNUICallback('bossAction', function(data, cb)
    TriggerServerEvent('core_bossmenu:bossAction', data)
    cb('ok')
end)

-- Command to open the menu (for testing, replace with job check/trigger)
RegisterCommand('bossmenu', function()
    TriggerServerEvent('core_bossmenu:getBossData')
end)
