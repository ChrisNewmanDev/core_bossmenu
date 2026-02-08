local QBCore = exports['qb-core']:GetCoreObject()
local BossLocations = {}

-- Version Checker
local versionDataRaw = LoadResourceFile(GetCurrentResourceName(), 'version.json')
local CURRENT_VERSION = 'unknown'
local RESOURCE_NAME = 'unknown'
local GITHUB_REPO = 'unknown'
local VERSION_CHECK_URL = ''
if versionDataRaw then
    local success, versionData = pcall(function() return json.decode(versionDataRaw) end)
    if success and versionData then
        if versionData.version then CURRENT_VERSION = versionData.version end
        if versionData.resource_name then RESOURCE_NAME = versionData.resource_name end
        if versionData.github_repo then GITHUB_REPO = versionData.github_repo end
        VERSION_CHECK_URL = 'https://raw.githubusercontent.com/' .. GITHUB_REPO .. '/main/version.json'
    end
end

local function ParseVersion(version)
    local major, minor, patch = version:match('(%d+)%.(%d+)%.(%d+)')
    return {
        major = tonumber(major) or 0,
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0
    }
end

local function CompareVersions(current, latest)
    local currentVer = ParseVersion(current)
    local latestVer = ParseVersion(latest)
    
    if latestVer.major > currentVer.major then return 'outdated'
    elseif latestVer.major < currentVer.major then return 'ahead' end
    
    if latestVer.minor > currentVer.minor then return 'outdated'
    elseif latestVer.minor < currentVer.minor then return 'ahead' end
    
    if latestVer.patch > currentVer.patch then return 'outdated'
    elseif latestVer.patch < currentVer.patch then return 'ahead' end
    
    return 'current'
end

local function CheckVersion()
    PerformHttpRequest(VERSION_CHECK_URL, function(statusCode, response, headers)
        if statusCode ~= 200 then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to check for updates (HTTP ' .. statusCode .. ')^7')
            print('^3[' .. RESOURCE_NAME .. '] ^3Please verify the version.json URL is correct^7')
            return
        end
        
        local success, versionData = pcall(function() return json.decode(response) end)
        
        if not success or not versionData or not versionData.version then
            print('^3[' .. RESOURCE_NAME .. '] ^1Failed to parse version data^7')
            return
        end
        
        local latestVersion = versionData.version
        local versionStatus = CompareVersions(CURRENT_VERSION, latestVersion)
        
        print('^3========================================^7')
        print('^5[' .. RESOURCE_NAME .. '] Version Checker^7')
        print('^3========================================^7')
        print('^2Current Version: ^7' .. CURRENT_VERSION)
        print('^2Latest Version:  ^7' .. latestVersion)
        print('')
        
        if versionStatus == 'current' then
            print('^2✓ You are running the latest version!^7')
        elseif versionStatus == 'ahead' then
            print('^3⚠ You are running a NEWER version than released!^7')
            print('^3This may be a development version.^7')
        elseif versionStatus == 'outdated' then
            print('^1⚠ UPDATE AVAILABLE!^7')
            print('')
            
            if versionData.changelog and versionData.changelog[latestVersion] then
                local changelog = versionData.changelog[latestVersion]
                
                if changelog.date then
                    print('^6Release Date: ^7' .. changelog.date)
                    print('')
                end
                
                if changelog.changes and #changelog.changes > 0 then
                    print('^5Changes:^7')
                    for _, change in ipairs(changelog.changes) do
                        print('  ^2✓^7 ' .. change)
                    end
                    print('')
                end
                
                if changelog.files_to_update and #changelog.files_to_update > 0 then
                    print('^1Files that need to be updated:^7')
                    for _, file in ipairs(changelog.files_to_update) do
                        print('  ^3➤^7 ' .. file)
                    end
                    print('')
                end
            end
            
            print('^2Download: ^7https://github.com/ChrisNewmanDev/core_bossmenu/releases/latest')
        end
        print('^3========================================^7')
    end, 'GET')
end

CreateThread(function()
    Wait(2000)
    CheckVersion()
end)

print('^2[' .. RESOURCE_NAME .. '] ^7Server initialized - v' .. CURRENT_VERSION)

-- Load boss menu locations from database
CreateThread(function()
    local locations = MySQL.query.await('SELECT * FROM core_bossmenu_locations', {})
    if locations then
        for _, loc in ipairs(locations) do
            local coords = json.decode(loc.coords)
            if not BossLocations[loc.job] then
                BossLocations[loc.job] = {}
            end
            table.insert(BossLocations[loc.job], {
                id = loc.id,
                coords = vector3(coords.x, coords.y, coords.z)
            })
        end
        print('[core_bossmenu] Loaded ' .. #locations .. ' boss menu locations')
    end
end)

-- Sync locations to client
RegisterServerEvent('core_bossmenu:requestLocations', function()
    local src = source
    TriggerClientEvent('core_bossmenu:receiveLocations', src, BossLocations)
end)

-- Webhook function
local function SendWebhook(webhookUrl, title, description, color, fields)
    if not webhookUrl or webhookUrl == '' then return end
    
    local embed = {
        {
            ['title'] = title,
            ['description'] = description,
            ['color'] = color,
            ['fields'] = fields or {},
            ['footer'] = {
                ['text'] = os.date('%Y-%m-%d %H:%M:%S')
            }
        }
    }
    
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({
        username = 'Boss Menu Logs',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end


-- Admin command to open boss menu management
QBCore.Commands.Add(Config.AdminCommand, 'Manage boss menu locations (place/remove)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get all available jobs from QBCore
    local jobs = {}
    for jobName, jobData in pairs(QBCore.Shared.Jobs) do
        table.insert(jobs, {
            name = jobName,
            label = jobData.label or jobName
        })
    end
    
    -- Sort jobs alphabetically by label
    table.sort(jobs, function(a, b)
        return a.label < b.label
    end)
    
    -- Get all existing locations
    local locations = {}
    for jobName, jobLocs in pairs(BossLocations) do
        for _, loc in ipairs(jobLocs) do
            table.insert(locations, {
                id = loc.id,
                job = jobName,
                coords = {
                    x = loc.coords.x,
                    y = loc.coords.y,
                    z = loc.coords.z
                }
            })
        end
    end
    
    -- Open admin NUI menu
    TriggerClientEvent('core_bossmenu:openAdminMenu', src, jobs, locations)
end, Config.AdminPermission)

-- Handle job placement from NUI
RegisterServerEvent('core_bossmenu:placeLocation', function(jobName, providedCoords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Verify admin permission
    if not QBCore.Functions.HasPermission(src, Config.AdminPermission) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    if not jobName or jobName == '' then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid job name', 'error')
        return
    end
    
    -- Get coords from provided coords or player position
    local coords
    if providedCoords and providedCoords.x and providedCoords.y and providedCoords.z then
        coords = vector3(providedCoords.x, providedCoords.y, providedCoords.z)
    else
        local playerPed = GetPlayerPed(src)
        coords = GetEntityCoords(playerPed)
    end
    
    -- Save to database
    local result = MySQL.insert.await('INSERT INTO core_bossmenu_locations (job, coords) VALUES (?, ?)', {
        jobName,
        json.encode({x = coords.x, y = coords.y, z = coords.z})
    })
    
    if result then
        -- Add to local cache
        if not BossLocations[jobName] then
            BossLocations[jobName] = {}
        end
        table.insert(BossLocations[jobName], {
            id = result,
            coords = vector3(coords.x, coords.y, coords.z)
        })
        
        -- Sync to all clients
        TriggerClientEvent('core_bossmenu:receiveLocations', -1, BossLocations)
        TriggerClientEvent('QBCore:Notify', src, 'Boss menu location placed for ' .. jobName, 'success')
        
        -- Send webhook
        SendWebhook(Config.Webhooks.AdminActions, '📍 Location Placed', 
            'A boss menu location has been placed',
            3066993, -- Green
            {
                {name = 'Admin', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
                {name = 'Job', value = jobName, inline = true},
                {name = 'Coordinates', value = 'X: ' .. math.floor(coords.x) .. ', Y: ' .. math.floor(coords.y) .. ', Z: ' .. math.floor(coords.z), inline = false}
            }
        )
        
        -- Send updated locations to requesting client for admin UI refresh
        local locations = {}
        for job, jobLocs in pairs(BossLocations) do
            for _, loc in ipairs(jobLocs) do
                table.insert(locations, {
                    id = loc.id,
                    job = job,
                    coords = {
                        x = loc.coords.x,
                        y = loc.coords.y,
                        z = loc.coords.z
                    }
                })
            end
        end
        TriggerClientEvent('core_bossmenu:updateAdminLocations', src, locations)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to save location', 'error')
    end
end)

-- Remove location from database (from NUI)
RegisterServerEvent('core_bossmenu:removeLocationById', function(locationId, jobName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check admin permission
    if not QBCore.Functions.HasPermission(src, Config.AdminPermission) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    MySQL.query.await('DELETE FROM core_bossmenu_locations WHERE id = ?', {locationId})
    
    -- Remove from cache
    if BossLocations[jobName] then
        for i, loc in ipairs(BossLocations[jobName]) do
            if loc.id == locationId then
                table.remove(BossLocations[jobName], i)
                break
            end
        end
    end
    
    -- Sync to all clients
    TriggerClientEvent('core_bossmenu:receiveLocations', -1, BossLocations)
    TriggerClientEvent('QBCore:Notify', src, 'Boss menu location removed', 'success')
    
    -- Send webhook
    SendWebhook(Config.Webhooks.AdminActions, '🗑️ Location Removed', 
        'A boss menu location has been removed',
        15158332, -- Red
        {
            {name = 'Admin', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
            {name = 'Job', value = jobName, inline = true},
            {name = 'Location ID', value = tostring(locationId), inline = true}
        }
    )
    
    -- Send updated locations to requesting client for admin UI refresh
    local locations = {}
    for job, jobLocs in pairs(BossLocations) do
        for _, loc in ipairs(jobLocs) do
            table.insert(locations, {
                id = loc.id,
                job = job,
                coords = {
                    x = loc.coords.x,
                    y = loc.coords.y,
                    z = loc.coords.z
                }
            })
        end
    end
    TriggerClientEvent('core_bossmenu:updateAdminLocations', src, locations)
end)

-- Move/update location coordinates
RegisterServerEvent('core_bossmenu:moveLocation', function(locationId, jobName, providedCoords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check admin permission
    if not QBCore.Functions.HasPermission(src, Config.AdminPermission) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission', 'error')
        return
    end
    
    -- Use provided coords or get player coords
    local coords
    if providedCoords and providedCoords.x and providedCoords.y and providedCoords.z then
        coords = vector3(providedCoords.x, providedCoords.y, providedCoords.z)
    else
        local playerPed = GetPlayerPed(src)
        coords = GetEntityCoords(playerPed)
    end
    
    -- Update in database
    MySQL.update.await('UPDATE core_bossmenu_locations SET coords = ? WHERE id = ?', {
        json.encode({x = coords.x, y = coords.y, z = coords.z}),
        locationId
    })
    
    -- Update in cache
    if BossLocations[jobName] then
        for i, loc in ipairs(BossLocations[jobName]) do
            if loc.id == locationId then
                BossLocations[jobName][i].coords = vector3(coords.x, coords.y, coords.z)
                break
            end
        end
    end
    
    -- Sync to all clients
    TriggerClientEvent('core_bossmenu:receiveLocations', -1, BossLocations)
    TriggerClientEvent('QBCore:Notify', src, 'Boss menu location moved successfully', 'success')
    
    -- Send webhook
    SendWebhook(Config.Webhooks.AdminActions, '📦 Location Moved', 
        'A boss menu location has been moved',
        3447003, -- Blue
        {
            {name = 'Admin', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
            {name = 'Job', value = jobName, inline = true},
            {name = 'New Coordinates', value = 'X: ' .. math.floor(coords.x) .. ', Y: ' .. math.floor(coords.y) .. ', Z: ' .. math.floor(coords.z), inline = false}
        }
    )
    
    -- Send updated locations to requesting client for admin UI refresh
    local locations = {}
    for job, jobLocs in pairs(BossLocations) do
        for _, loc in ipairs(jobLocs) do
            table.insert(locations, {
                id = loc.id,
                job = job,
                coords = {
                    x = loc.coords.x,
                    y = loc.coords.y,
                    z = loc.coords.z
                }
            })
        end
    end
    TriggerClientEvent('core_bossmenu:updateAdminLocations', src, locations)
end)

RegisterServerEvent('core_bossmenu:getBossData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local job = Player.PlayerData.job.name
    local grade = Player.PlayerData.job.grade.level
    if not Player.PlayerData.job.isboss then
        TriggerClientEvent('QBCore:Notify', src, 'You are too low in rank to access the boss menu!', 'error')
        return
    end
    
    -- ====================================
    -- BANKING INTEGRATION - qb-banking
    -- ====================================
    -- If you are NOT using qb-banking, replace the exports below with your banking script's exports
    -- You need to:
    --   1. Check if job account exists
    --   2. Create job account if it doesn't exist
    --   3. Get the current account balance
    -- ====================================
    local jobAccount = exports['qb-banking']:GetAccount(job)
    if not jobAccount then
        exports['qb-banking']:CreateJobAccount(job, 0)
    end
    local account = exports['qb-banking']:GetAccountBalance(job)
    -- ==================================== END BANKING INTEGRATION ====================================
    local employees = {}
    local players = MySQL.query.await("SELECT * FROM `players` WHERE `job` LIKE '%" .. job .. "%'", {})
    local added = {}
    -- Always add the current player (src) first
    employees[#employees + 1] = {
        citizenid = Player.PlayerData.citizenid,
        grade = Player.PlayerData.job.grade.level,
        isboss = Player.PlayerData.job.isboss,
        name = ('🟢 ') .. Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    }
    added[Player.PlayerData.citizenid] = true
    if players[1] ~= nil then
        for _, value in pairs(players) do
            if not added[value.citizenid] then
                local Target = QBCore.Functions.GetPlayerByCitizenId(value.citizenid) or QBCore.Functions.GetOfflinePlayerByCitizenId(value.citizenid)
                if Target and Target.PlayerData.job.name == job then
                    local isOnline = Target.PlayerData.source
                    employees[#employees + 1] = {
                        citizenid = Target.PlayerData.citizenid,
                        grade = Target.PlayerData.job.grade.level,
                        isboss = Target.PlayerData.job.isboss,
                        name = (isOnline and '🟢 ' or '❌ ') .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname
                    }
                    added[Target.PlayerData.citizenid] = true
                end
            end
        end
        table.sort(employees, function(a, b)
            return a.grade > b.grade
        end)
    end
    
    local jobGrades = {}
    if QBCore.Shared.Jobs[job] and QBCore.Shared.Jobs[job].grades then
        for gradeLevel, gradeData in pairs(QBCore.Shared.Jobs[job].grades) do
            jobGrades[#jobGrades + 1] = {
                level = tonumber(gradeLevel),
                name = gradeData.name
            }
        end
        table.sort(jobGrades, function(a, b)
            return a.level < b.level
        end)
    end
    TriggerClientEvent('core_bossmenu:openMenu', src, {
        job = job,
        grade = grade,
        account = account,
        employees = employees,
        grades = jobGrades,
        currency = Config.Currency,
        hireRange = Config.HireRange
    })
end)

RegisterServerEvent('core_bossmenu:bossAction', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData.job or not Player.PlayerData.job.isboss then return end
    local job = Player.PlayerData.job.name
    
    if data.action == 'deposit' and data.amount then
        local amount = tonumber(data.amount)
        if amount and amount > 0 then
            if Player.Functions.RemoveMoney('cash', amount) then
                -- ====================================
                -- BANKING INTEGRATION - qb-banking (DEPOSIT)
                -- ====================================
                -- If you are NOT using qb-banking, replace the exports below:
                --   - AddMoney: Add money to the job account
                --   - GetAccountBalance: Get the new balance after deposit
                -- ====================================
                exports['qb-banking']:AddMoney(job, amount)
                local newBalance = exports['qb-banking']:GetAccountBalance(job)
                -- ==================================== END BANKING INTEGRATION ====================================
                
                TriggerClientEvent('QBCore:Notify', src, 'Deposited ' .. Config.Currency .. amount .. ' to job account', 'success')
                TriggerClientEvent('core_bossmenu:updateBalance', src, newBalance)
                
                SendWebhook(Config.Webhooks.MoneyDeposit, '💵 Money Deposited', 
                    'Money has been deposited into job account',
                    3066993,
                    {
                        {name = 'Employee', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
                        {name = 'Job', value = job, inline = true},
                        {name = 'Amount', value = Config.Currency .. amount, inline = true},
                        {name = 'New Balance', value = Config.Currency .. newBalance, inline = true}
                    }
                )
            else
                TriggerClientEvent('QBCore:Notify', src, 'You do not have enough cash!', 'error')
            end
        end
        return
    elseif data.action == 'withdraw' and data.amount then
        local amount = tonumber(data.amount)
        if amount and amount > 0 then
            -- ====================================
            -- BANKING INTEGRATION - qb-banking (WITHDRAW)
            -- ====================================
            -- If you are NOT using qb-banking, replace the exports below:
            --   - GetAccountBalance: Check current balance before withdrawing
            --   - RemoveMoney: Remove money from the job account
            --   - GetAccountBalance: Get the new balance after withdrawal
            -- ====================================
            local balance = exports['qb-banking']:GetAccountBalance(job)
            if balance >= amount then
                exports['qb-banking']:RemoveMoney(job, amount)
                Player.Functions.AddMoney('cash', amount)
                local newBalance = exports['qb-banking']:GetAccountBalance(job)
                -- ==================================== END BANKING INTEGRATION ====================================
                
                TriggerClientEvent('QBCore:Notify', src, 'Withdrew ' .. Config.Currency .. amount .. ' from job account', 'success')
                TriggerClientEvent('core_bossmenu:updateBalance', src, newBalance)
                
                SendWebhook(Config.Webhooks.MoneyWithdraw, '💸 Money Withdrawn', 
                    'Money has been withdrawn from job account',
                    15105570, -- Orange
                    {
                        {name = 'Employee', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
                        {name = 'Job', value = job, inline = true},
                        {name = 'Amount', value = Config.Currency .. amount, inline = true},
                        {name = 'New Balance', value = Config.Currency .. newBalance, inline = true}
                    }
                )
            else
                TriggerClientEvent('QBCore:Notify', src, 'Insufficient job account balance!', 'error')
            end
        end
        return
    elseif data.action == 'changeGrade' and data.target and data.grade then
        if data.target == Player.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'You cannot change your own grade!', 'error')
            return
        end
        local newGrade = tonumber(data.grade)
        if newGrade and newGrade >= 0 then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.target)
            if targetPlayer then
                local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
                targetPlayer.Functions.SetJob(job, newGrade)
                TriggerClientEvent('QBCore:Notify', src, 'Employee grade changed to ' .. newGrade, 'success')
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Your grade has been changed to ' .. newGrade, 'primary')
                
                SendWebhook(Config.Webhooks.EmployeeActions, '🔄 Grade Changed', 
                    'An employee\'s grade has been changed',
                    3447003,
                    {
                        {name = 'Boss', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
                        {name = 'Employee', value = targetName, inline = true},
                        {name = 'Job', value = job, inline = true},
                        {name = 'New Grade', value = tostring(newGrade), inline = true}
                    }
                )
            else
                local offlinePlayer = QBCore.Functions.GetOfflinePlayerByCitizenId(data.target)
                if offlinePlayer then
                    local targetName = offlinePlayer.PlayerData.charinfo.firstname .. ' ' .. offlinePlayer.PlayerData.charinfo.lastname
                    offlinePlayer.PlayerData.job.grade.level = newGrade
                    MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(offlinePlayer.PlayerData.job), data.target })
                    TriggerClientEvent('QBCore:Notify', src, 'Employee grade changed to ' .. newGrade, 'success')
                    
                    SendWebhook(Config.Webhooks.EmployeeActions, '🔄 Grade Changed (Offline)', 
                        'An offline employee\'s grade has been changed',
                        3447003,
                        {
                            {name = 'Boss', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
                            {name = 'Employee', value = targetName .. ' (Offline)', inline = true},
                            {name = 'Job', value = job, inline = true},
                            {name = 'New Grade', value = tostring(newGrade), inline = true}
                        }
                    )
                end
            end
            TriggerClientEvent('core_bossmenu:refresh', src)
        end
        return
    elseif data.action == 'fire' and data.target then
        if data.target == Player.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'You cannot fire yourself!', 'error')
            return
        end
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.target) or QBCore.Functions.GetOfflinePlayerByCitizenId(data.target)
        if targetPlayer then
            local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
            local isOnline = targetPlayer.Functions and targetPlayer.Functions.SetJob
            
            if isOnline then
                targetPlayer.Functions.SetJob('unemployed', 0)
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been fired!', 'error')
                if src == targetPlayer.PlayerData.source then
                    TriggerClientEvent('core_bossmenu:closeMenu', src)
                end
            else
                local jobData = { name = 'unemployed', label = 'Unemployed', grade = { name = 'unemployed', level = 0, isboss = false } }
                MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(jobData), data.target })
            end
            
            SendWebhook(Config.Webhooks.EmployeeActions, '🗑️ Employee Fired', 
                'An employee has been fired',
                15158332,
                {
                    {name = 'Boss', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
                    {name = 'Employee', value = targetName .. (isOnline and '' or ' (Offline)'), inline = true},
                    {name = 'Job', value = job, inline = true}
                }
            )
        end
        return
    elseif data.action == 'hire' and data.target then
        local targetSrc = tonumber(data.target)
        local targetPlayer = QBCore.Functions.GetPlayer(targetSrc)
        
        if not targetPlayer then
            TriggerClientEvent('QBCore:Notify', src, 'Player not found!', 'error')
            return
        end
        
        if targetPlayer.PlayerData.job.name == job then
            TriggerClientEvent('QBCore:Notify', src, 'Player is already in this job!', 'error')
            return
        end
        
        targetPlayer.Functions.SetJob(job, Config.HireGrade)
        local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
        
        TriggerClientEvent('QBCore:Notify', src, 'Successfully hired ' .. targetName, 'success')
        TriggerClientEvent('QBCore:Notify', targetSrc, 'You have been hired as ' .. job, 'success')
        
        SendWebhook(Config.Webhooks.EmployeeActions, '✅ Employee Hired', 
            'A new employee has been hired',
            3066993,
            {
                {name = 'Boss', value = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' (' .. GetPlayerName(src) .. ')', inline = true},
                {name = 'New Employee', value = targetName .. ' (' .. GetPlayerName(targetSrc) .. ')', inline = true},
                {name = 'Job', value = job, inline = true},
                {name = 'Starting Grade', value = tostring(Config.HireGrade), inline = true}
            }
        )
        
        TriggerClientEvent('core_bossmenu:refresh', src)
        return
    end
end)
