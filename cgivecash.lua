local RSGCore = exports['rsg-core']:GetCoreObject()

CreateThread(function()
    exports['ox_target']:addGlobalPlayer({
        {
            name = 'give_citizen_money',
            event = 'phil-giveCash:client:menu',
            icon = 'fas fa-money',
            label = 'Give citizen money',
            type = 'client'
        }
    }, {
        distance = 3.0
    })
end)

RegisterNetEvent('phil-giveCash:client:menu', function(data)
    local player, distance = RSGCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 3.0 then
        local playerId = GetPlayerServerId(player)
        
        -- Request character info from server first
        TriggerServerEvent('phil-giveCash:server:getCharacterName', playerId)
    else
        RSGCore.Functions.Notify("No player nearby", "error")
    end
end)

-- New event to receive character name and show menu
RegisterNetEvent('phil-giveCash:client:showMenu', function(playerId, characterName)
    lib.registerContext({
        id = 'give_cash_menu',
        title = string.format('Give Cash to %s', characterName),
        options = {
            {
                title = 'Give $10',
                description = string.format('Give $10 to %s', characterName),
                icon = 'fas fa-dollar-sign',
                event = 'phil-giveCash:client:giveAmount',
                args = { playerId = playerId, amount = 10 }
            },
            {
                title = 'Give $50',
                description = string.format('Give $50 to %s', characterName),
                icon = 'fas fa-dollar-sign',
                event = 'phil-giveCash:client:giveAmount',
                args = { playerId = playerId, amount = 50 }
            },
            {
                title = 'Give $100',
                description = string.format('Give $100 to %s', characterName),
                icon = 'fas fa-dollar-sign',
                event = 'phil-giveCash:client:giveAmount',
                args = { playerId = playerId, amount = 100 }
            },
            {
                title = 'Custom Amount',
                description = string.format('Enter a custom amount to give to %s', characterName),
                icon = 'fas fa-edit',
                event = 'phil-giveCash:client:customAmount',
                args = { playerId = playerId, playerName = characterName }
            },
            {
                title = 'Add to Address Book',
                description = string.format('Add %s to your address book', characterName),
                icon = 'fas fa-address-book',
                event = 'phil-giveCash:client:requestAddToAddressBook',
                args = { playerId = playerId, playerName = characterName }
            }
        }
    })
    lib.showContext('give_cash_menu')
end)

-- New event to handle address book addition
RegisterNetEvent('phil-giveCash:client:requestAddToAddressBook', function(data)
    if not data.playerId or not data.playerName then return end
    
    -- Request citizenid from server
    TriggerServerEvent('phil-giveCash:server:requestCitizenId', data.playerId, data.playerName)
end)

-- Event to receive citizenid from server and add to address book
RegisterNetEvent('phil-giveCash:client:receiveCitizenId', function(playerName, citizenId)
    if citizenId then
        TriggerServerEvent('rsg-telegram:server:SavePerson', playerName, citizenId)
    else
        RSGCore.Functions.Notify("Could not get player information", "error")
    end
end)

RegisterNetEvent('phil-giveCash:client:giveAmount', function(data)
    if not data or not data.playerId or not data.amount then 
        RSGCore.Functions.Notify("Invalid transaction data", "error")
        return 
    end
    
    -- Verify amount is a number
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        RSGCore.Functions.Notify("Invalid amount", "error")
        return
    end
    
    TriggerServerEvent("phil-giveCash:server:charge", data.playerId, amount)
end)

RegisterNetEvent('phil-giveCash:client:customAmount', function(data)
    if not data or not data.playerId then 
        RSGCore.Functions.Notify("Invalid player data", "error")
        return 
    end

    local input = lib.inputDialog(string.format('Give Cash to %s', data.playerName or "Player"), {
        {
            type = 'number',
            label = 'Amount in $',
            description = 'Enter the amount you want to give (up to 2 decimal places)',
            required = true,
            min = 0.01,
            max = 1000000,
            precision = 2  -- Allow up to 2 decimal places
        }
    })


    if input and input[1] then
        local amount = tonumber(input[1])
        if amount and amount > 0 then
            TriggerServerEvent("phil-giveCash:server:charge", data.playerId, amount)
        else
            RSGCore.Functions.Notify("Invalid amount", "error")
        end
    end
end)
