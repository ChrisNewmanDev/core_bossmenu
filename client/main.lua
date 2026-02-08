local QBCore = exports['qb-core']:GetCoreObject()
local isMenuOpen = false
local BossLocations = {}
local targetZones = {}
local nearestLocation = nil
local isAimMode = false
local aimedCoords = nil

function GetCoordsFromCam(distance)
    local camRot = GetGameplayCamRot(0)
    local camPos = GetGameplayCamCoord()
    local direction = RotationToDirection(camRot)
    local destination = vector3(
        camPos.x + direction.x * distance,
        camPos.y + direction.y * distance,
        camPos.z + direction.z * distance
    )
    
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0)
    local _, hit, coords = GetShapeTestResult(ray)
    
    if hit then
        return coords
    else
        return destination
    end
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('core_bossmenu:requestLocations')
end)

RegisterNetEvent('core_bossmenu:receiveLocations', function(locations)
    BossLocations = locations
    if Config.TargetSystem == 'qb-target' then
        SetupQBTargetZones()
    elseif Config.TargetSystem == 'ox_target' then
        SetupOxTargetZones()
    end
end)

function SetupQBTargetZones()
    if GetResourceState('qb-target') ~= 'started' then
        print('[core_bossmenu] qb-target resource is not started!')
        return
    end
    
    for _, zoneName in ipairs(targetZones) do
        exports['qb-target']:RemoveZone(zoneName)
    end
    targetZones = {}
    
    for job, locations in pairs(BossLocations) do
        for i, loc in ipairs(locations) do
            local zoneName = 'bossmenu_' .. job .. '_' .. i
            exports['qb-target']:AddBoxZone(zoneName, loc.coords, 1.5, 1.5, {
                name = zoneName,
                heading = 0,
                debugPoly = false,
                minZ = loc.coords.z - 1.0,
                maxZ = loc.coords.z + 1.0,
            }, {
                options = {
                    {
                        type = "client",
                        event = "core_bossmenu:openBossMenu",
                        icon = "fas fa-briefcase",
                        label = "Open Boss Menu",
                        job = job,
                    },
                },
                distance = 2.5
            })
            table.insert(targetZones, zoneName)
        end
    end
end

function SetupOxTargetZones()
    if GetResourceState('ox_target') ~= 'started' then
        print('[core_bossmenu] ox_target resource is not started!')
        return
    end
    
    for _, zoneId in ipairs(targetZones) do
        exports.ox_target:removeZone(zoneId)
    end
    targetZones = {}
    
    for job, locations in pairs(BossLocations) do
        for i, loc in ipairs(locations) do
            local zoneName = 'bossmenu_' .. job .. '_' .. i
            local zoneId = exports.ox_target:addBoxZone({
                coords = loc.coords,
                size = vec3(1.5, 1.5, 2.0),
                rotation = 0,
                debug = false,
                options = {
                    {
                        name = zoneName,
                        event = 'core_bossmenu:openBossMenu',
                        icon = 'fas fa-briefcase',
                        label = 'Open Boss Menu',
                        groups = job,
                    }
                }
            })
            table.insert(targetZones, zoneId)
        end
    end
end

RegisterNetEvent('core_bossmenu:openBossMenu', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job and PlayerData.job.isboss then
        TriggerServerEvent('core_bossmenu:getBossData')
    else
        QBCore.Functions.Notify('You are not a boss!', 'error')
    end
end)

if Config.TargetSystem == 'none' then
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local PlayerData = QBCore.Functions.GetPlayerData()
            
            if PlayerData.job then
                local jobLocations = BossLocations[PlayerData.job.name]
                if jobLocations then
                    for _, loc in ipairs(jobLocations) do
                        local distance = #(playerCoords - loc.coords)
                        
                        if distance < Config.MarkerDrawDistance then
                            sleep = 0
                            
                            if Config.DrawMarker then
                                DrawMarker(
                                    Config.MarkerType,
                                    loc.coords.x, loc.coords.y, loc.coords.z + Config.MarkerHeight,
                                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                    0.3, 0.3, 0.5,
                                    Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
                                    false, false, 2, false, nil, nil, false
                                )
                            end
                        end
                        
                        if distance < Config.InteractionDistance then
                            
                            QBCore.Functions.DrawText3D(loc.coords.x, loc.coords.y, loc.coords.z, '[E] Boss Menu')
                            
                            if IsControlJustReleased(0, Config.InteractionKey) and PlayerData.job.isboss then
                                TriggerServerEvent('core_bossmenu:getBossData')
                            end
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

RegisterNetEvent('core_bossmenu:openMenu', function(data)
    SetNuiFocus(true, true)
    isMenuOpen = true
    SendNUIMessage({
        action = 'open',
        data = data
    })
end)

RegisterNetEvent('core_bossmenu:updateBalance', function(balance)
    SendNUIMessage({
        action = 'updateBalance',
        balance = balance
    })
end)

RegisterNetEvent('core_bossmenu:closeMenu', function()
    SetNuiFocus(false, false)
    isMenuOpen = false
    SendNUIMessage({
        action = 'close'
    })
end)

RegisterNetEvent('core_bossmenu:refresh', function()
    TriggerServerEvent('core_bossmenu:getBossData')
end)

local function GetNearbyPlayers()
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerId = PlayerId()
    
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= playerId then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= Config.HireRange then
                table.insert(players, {
                    serverId = GetPlayerServerId(player),
                    name = GetPlayerName(player)
                })
            end
        end
    end
    
    return players
end

CreateThread(function()
    while true do
        Wait(1000)
        
        if isMenuOpen then
            local nearbyPlayers = GetNearbyPlayers()
            SendNUIMessage({
                action = 'updateNearbyPlayers',
                players = nearbyPlayers
            })
        end
    end
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

RegisterNUICallback('closeAdmin', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('placeLocation', function(data, cb)
    TriggerServerEvent('core_bossmenu:placeLocation', data.job, data.coords)
    cb('ok')
end)

RegisterNUICallback('removeLocation', function(data, cb)
    TriggerServerEvent('core_bossmenu:removeLocationById', data.id, data.job)
    cb('ok')
end)

RegisterNUICallback('moveLocation', function(data, cb)
    TriggerServerEvent('core_bossmenu:moveLocation', data.id, data.job, data.coords)
    cb('ok')
end)

RegisterNUICallback('teleportToLocation', function(data, cb)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, data.coords.x, data.coords.y, data.coords.z, false, false, false, true)
    QBCore.Functions.Notify('Teleported to location', 'success')
    cb('ok')
end)

RegisterNUICallback('toggleAimMode', function(data, cb)
    isAimMode = not isAimMode
    
    if isAimMode then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(true)
        SendNUIMessage({ action = 'hideAdminUI' })
        QBCore.Functions.Notify('Aim mode enabled - Look where you want to place the location', 'primary')
        QBCore.Functions.Notify('Press [E] to confirm or [X] to cancel', 'primary')
    else
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'showAdminUI' })
        aimedCoords = nil
        QBCore.Functions.Notify('Aim mode disabled', 'error')
    end
    
    cb('ok')
end)

CreateThread(function()
    while true do
        local sleep = 1000
        
        if isAimMode then
            sleep = 0
            local coords = GetCoordsFromCam(100.0)
            aimedCoords = coords
            
            DrawMarker(
                28,
                coords.x, coords.y, coords.z,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.5, 0.5, 0.5,
                0, 255, 0, 200,
                false, false, 2, false, nil, nil, false
            )
            
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~g~[E]~w~ Confirm Location | ~r~[X]~w~ Cancel")
            DrawText(0.5, 0.95)
            
            if IsControlJustReleased(0, 38) then
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(false)
                SendNUIMessage({ action = 'showAdminUI' })
                SendNUIMessage({
                    action = 'confirmAimedLocation',
                    coords = {x = coords.x, y = coords.y, z = coords.z}
                })
                isAimMode = false
                aimedCoords = nil
            end
            
            if IsControlJustReleased(0, 73) then
                isAimMode = false
                aimedCoords = nil
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(false)
                SendNUIMessage({ action = 'showAdminUI' })
                QBCore.Functions.Notify('Aim mode cancelled', 'error')
            end
        end
        
        Wait(sleep)
    end
end)

RegisterNetEvent('core_bossmenu:openAdminMenu', function(jobs, locations)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdmin',
        jobs = jobs,
        locations = locations
    })
end)

RegisterNetEvent('core_bossmenu:updateAdminLocations', function(locations)
    SendNUIMessage({
        action = 'updateAdminLocations',
        locations = locations
    })
end)

if Config.EnableCommand then
    RegisterCommand('bossmenu', function()
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData.job and PlayerData.job.isboss then
            TriggerServerEvent('core_bossmenu:getBossData')
        else
            QBCore.Functions.Notify('You are not a boss!', 'error')
        end
    end)
    
    if Config.UseKeybind then
        RegisterKeyMapping('bossmenu', 'Open Boss Menu', 'keyboard', Config.Keybind)
    end
end
