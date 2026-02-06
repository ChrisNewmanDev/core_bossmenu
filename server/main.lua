-- Modern Boss Menu for QB-Management using core_gps_advanced UI style
local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('core_bossmenu:getBossData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local job = Player.PlayerData.job.name
    local grade = Player.PlayerData.job.grade.level
    if grade < 4 then return end
    local jobAccount = exports['qb-banking']:GetAccount(job)
    if not jobAccount then
        exports['qb-banking']:CreateJobAccount(job, 0)
    end
    local account = exports['qb-banking']:GetAccountBalance(job)
    local employees = {}
    local players = MySQL.query.await("SELECT * FROM `players` WHERE `job` LIKE '%" .. job .. "%'", {})
    if players[1] ~= nil then
        for _, value in pairs(players) do
            local Target = QBCore.Functions.GetPlayerByCitizenId(value.citizenid) or QBCore.Functions.GetOfflinePlayerByCitizenId(value.citizenid)
            if Target and Target.PlayerData.job.name == job then
                local isOnline = Target.PlayerData.source
                employees[#employees + 1] = {
                    citizenid = Target.PlayerData.citizenid,
                    grade = Target.PlayerData.job.grade.level,
                    isboss = Target.PlayerData.job.isboss,
                    name = (isOnline and '🟢 ' or '❌ ') .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname
                }
            end
        end
        table.sort(employees, function(a, b)
            return a.grade.level > b.grade.level
        end)
    end
    TriggerClientEvent('core_bossmenu:openMenu', src, {
        job = job,
        grade = grade,
        account = account,
        employees = employees
    })
end)

RegisterServerEvent('core_bossmenu:bossAction', function(data)
    if data.action == 'fire' and data.target then
        -- Prevent firing if not boss
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not Player.PlayerData.job or not Player.PlayerData.job.isboss then return end
        -- Allow firing self
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(data.target) or QBCore.Functions.GetOfflinePlayerByCitizenId(data.target)
        if targetPlayer then
            if targetPlayer.Functions and targetPlayer.Functions.SetJob then
                targetPlayer.Functions.SetJob('unemployed', 0)
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been fired!', 'error')
                if src == targetPlayer.PlayerData.source then
                    TriggerClientEvent('core_bossmenu:closeMenu', src)
                end
            else
                local jobData = { name = 'unemployed', label = 'Unemployed', grade = { name = 'unemployed', level = 0, isboss = false } }
                MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(jobData), data.target })
            end
        end
        return
    end
end)
