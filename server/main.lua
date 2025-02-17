local QBCore = exports['qb-core']:GetCoreObject()
local VehicleNitrous = {}
local start = os.time()

RegisterNetEvent('tackle:server:TacklePlayer', function(playerId)
    TriggerClientEvent("tackle:client:GetTackled", playerId)
end)


QBCore.Commands.Add("id", "Check Your ID #", {}, false, function(source)
    TriggerClientEvent('QBCore:Notify', source,  "ID: "..source)
end)

QBCore.Functions.CreateUseableItem("harness", function(source, item)
    TriggerClientEvent('seatbelt:client:UseHarness', source, item)
end)

RegisterNetEvent('equip:harness', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if item.metadata.harnessuses == nil then
        item.metadata.harnessuses = 19
        exports.ox_inventory:SetMetadata(src, item.slot, item.metadata)
    elseif item.metadata.harnessuses == 1 then
        exports.ox_inventory:RemoveItem(src, 'harness', 1)
    else
        item.metadata.harnessuses -= 1
        exports.ox_inventory:SetMetadata(src, item.slot, item.metadata)
    end
end)

RegisterNetEvent('seatbelt:DoHarnessDamage', function(hp, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local harness = exports.ox_inventory:Search(src, 1, 'harness')

    if not Player then return end

    if hp == 0 then
        exports.ox_inventory:RemoveItem(src, 'harness', 1, data.metadata, data.slot)
    else
        harness.metadata.harnessuses -= 1
        exports.ox_inventory:SetMetadata(src, harness.slot, harness.metadata)
    end
end)

RegisterNetEvent('qb-carwash:server:washCar', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.Functions.RemoveMoney('cash', Config.DefaultPrice, "car-washed") then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    elseif Player.Functions.RemoveMoney('bank', Config.DefaultPrice, "car-washed") then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error.dont_have_enough_money"), 'error')
    end
end)

-- QBCore.Functions.CreateCallback('smallresources:server:GetCurrentPlayers', function(_, cb)
--     local TotalPlayers = 0
--     local players = QBCore.Functions.GetPlayers()
--     for _ in pairs(players) do
--         TotalPlayers += 1
--     end
--     cb(TotalPlayers)
-- end)


CreateThread(function()
    while true do
        Wait(1000 * 60)

        local uptimeString = ""
        local uptime = os.difftime(os.time(), start)
        local hrs = math.floor(uptime / 3600)
        local mins = math.floor((uptime - (hrs * 3600)) / 60)

        if hrs > 0 then
            uptimeString = string.format("%d:%02d", hrs, mins)
        else
            uptimeString = string.format("%d minutes", mins)
        end

        SetConvarServerInfo('Uptime', uptimeString)
    end
end)