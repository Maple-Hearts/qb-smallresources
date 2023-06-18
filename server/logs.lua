local QBCore = exports['qb-core']:GetCoreObject()
local logQueue, isProcessingQueue, logCount = {}, false, 0
local lastRequestTime, requestDelay = 0, 0



local Colors = { -- https://www.spycolor.com/
    ['default'] = 14423100,
    ['blue'] = 255,
    ['red'] = 16711680,
    ['green'] = 65280,
    ['white'] = 16777215,
    ['black'] = 0,
    ['orange'] = 16744192,
    ['yellow'] = 16776960,
    ['pink'] = 16761035,
    ["lightgreen"] = 65309,
}

---Log Queue
local function applyRequestDelay()
    local currentTime = GetGameTimer()
    local timeDiff = currentTime - lastRequestTime

    if timeDiff < requestDelay then
        local remainingDelay = requestDelay - timeDiff

        Wait(remainingDelay)
    end

    lastRequestTime = GetGameTimer()
end

local allowedErr = {
    [200] = true,
    [201] = true,
    [204] = true,
    [304] = true
}

---Log Queue
---@param payload Log Queue
local function logPayload(payload)
    PerformHttpRequest(payload.webhook, function(err, text, headers)
        if err and not allowedErr[err] then
            print('^1Error occurred while attempting to send log to discord: ' .. err .. '^7')
            return
        end

        local remainingRequests = tonumber(headers["X-RateLimit-Remaining"])
        local resetTime = tonumber(headers["X-RateLimit-Reset"])

        if remainingRequests and resetTime and remainingRequests == 0 then
            local currentTime = os.time()
            local resetDelay = resetTime - currentTime

            if resetDelay > 0 then
                requestDelay = resetDelay * 1000 / 10
            end
        end
    end, 'POST', json.encode({content = payload.tag and '@everyone' or nil, embeds = {payload.embed}}), { ['Content-Type'] = 'application/json' })
end

---Log Queue
local function processLogQueue()
    if #logQueue > 0 then
        local payload = table.remove(logQueue, 1)

        logPayload(payload)

        logCount += 1

        if logCount % 5 == 0 then
            Wait(60000)
        else
            applyRequestDelay()
        end

        processLogQueue()
    else
        isProcessingQueue = false
    end
end

RegisterNetEvent('qb-log:server:CreateLog', function(name, title, color, message, tagEveryone)
    local tag = tagEveryone or false
    local webHook = Webhooks[name] or Webhooks['default']
    local embedData = {
        {
            ['title'] = title,
            ['color'] = Colors[color] or Colors['default'],
            ['footer'] = {
                ['text'] = os.date('%H:%M:%S %m-%d-%Y'),
            },
            ['description'] = message,
            ['author'] = {
                ['name'] = 'Whitelisted Logs',
                ['icon_url'] = 'https://media.discordapp.net/attachments/870094209783308299/870104331142189126/Logo_-_Display_Picture_-_Stylized_-_Red.png?width=670&height=670',
            },
        }
    }
    logQueue[#logQueue + 1] = {
        webhook = webHook,
        tag = tag,
        embed = embedData
    }

    if not isProcessingQueue then
        isProcessingQueue = true

        CreateThread(processLogQueue)
    end
end)

QBCore.Commands.Add('testwebhook', 'Test Your Discord Webhook For Logs (God Only)', {}, false, function()
    TriggerEvent('qb-log:server:CreateLog', 'testwebhook', 'Test Webhook', 'default', 'Webhook setup successfully')
end, 'god')
