local RSGCore = exports['rsg-core']:GetCoreObject()

-- Utility function for logging
local function LogAction(action, success, details)
    if type(details) == 'number' then
        details = tostring(details)
    end
    print(string.format("[Money Transfer] %s | Success: %s | Details: %s", 
        action, tostring(success), details))
end

RegisterNetEvent('phil-giveCash:server:charge', function(id, amount)
    local src = source
    
    -- Get both players
    local giver = RSGCore.Functions.GetPlayer(src)
    local given = RSGCore.Functions.GetPlayer(tonumber(id))
    
    -- Initial validation
    if not giver or not given then 
        LogAction("Player Validation", false, "Player not found")
        TriggerClientEvent('RSGCore:Notify', src, 'Player not found', 'error')
        return 
    end
    
    -- Check if giver is injured
    if giver.PlayerData.metadata["isdead"] then
        LogAction("Injury Check", false, "Player is injured")
        TriggerClientEvent('RSGCore:Notify', src, 'You cannot give money while injured.', 'error')
        return
    end
    
    -- Amount validation
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        LogAction("Amount Validation", false, "Invalid amount: " .. tostring(amount))
        TriggerClientEvent('RSGCore:Notify', src, 'Invalid amount', 'error')
        return
    end
    
    -- Money check
    local giverMoney = giver.Functions.GetMoney('cash')
    LogAction("Money Check", giverMoney >= amount, "Required: " .. tostring(amount) .. ", Available: " .. tostring(giverMoney))
    
    if giverMoney < amount then
        TriggerClientEvent('RSGCore:Notify', src, 'You don\'t have enough money!', 'error')
        return
    end
    
    -- Distance check
    local givenPed = GetPlayerPed(tonumber(id))
    local giverPed = GetPlayerPed(src)
    local distance = #(GetEntityCoords(givenPed) - GetEntityCoords(giverPed))
    
    if distance > 3.0 then
        LogAction("Distance Check", false, "Distance: " .. tostring(distance))
        TriggerClientEvent('RSGCore:Notify', src, 'You are too far from the other player', 'error')
        return
    end
    
    -- Perform transaction
    local success = giver.Functions.RemoveMoney('cash', amount, "Cash transfer to " .. tostring(id))
    if success then
        given.Functions.AddMoney('cash', amount, "Cash received from " .. tostring(src))
        
        LogAction("Transaction", true, 
            "Amount: $" .. tostring(amount) .. " | From: " .. tostring(src) .. " | To: " .. tostring(id))
        
        -- Notify both players
        TriggerClientEvent('RSGCore:Notify', src, 'You gave $' .. amount, 'success')
        TriggerClientEvent('RSGCore:Notify', tonumber(id), 'You received $' .. amount, 'success')
    else
        LogAction("Transaction", false, "Failed to remove money from Player " .. tostring(src))
        TriggerClientEvent('RSGCore:Notify', src, 'Transaction failed', 'error')
    end
end)

RegisterServerEvent('rsg-telegram:server:SavePerson')
AddEventHandler('rsg-telegram:server:SavePerson', function(name, cid)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    
    if not xPlayer then
        LogAction("Address Book", false, "Player not found")
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Failed to load player data',
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Add additional validation for name and cid
    if not name or not cid or name == '' or cid == '' then
        LogAction("Address Book", false, "Invalid name or citizen ID")
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Invalid player information',
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Use REPLACE INTO to handle duplicates
    exports.oxmysql:execute('REPLACE INTO address_book (`citizenid`, `name`, `owner`) VALUES (?, ?, ?)',
        {cid, name, xPlayer.PlayerData.citizenid},
        function(result)
            local success = result and result.affectedRows > 0
            LogAction("Address Book Entry", success,
                string.format("Added/Updated %s (CID: %s) in address book", name, cid))
            
            if success then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Success',
                    description = 'Address book updated successfully!',
                    type = 'success',
                    duration = 5000
                })
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Error',
                    description = 'Failed to update address book',
                    type = 'error',
                    duration = 5000
                })
            end
        end
    )
end)

RegisterNetEvent('phil-giveCash:server:requestCitizenId', function(targetId, playerName)
    local src = source
    local targetPlayer = RSGCore.Functions.GetPlayer(tonumber(targetId))
    
    if targetPlayer then
        -- Get the character's full name from PlayerData
        local charName = string.format("%s %s", 
            targetPlayer.PlayerData.charinfo.firstname or "",
            targetPlayer.PlayerData.charinfo.lastname or "")
            
        -- Trim any extra whitespace
        charName = charName:match("^%s*(.-)%s*$")
        
        -- If the character name is empty, fall back to player name
        if charName == "" then
            charName = playerName
        end
        
        TriggerClientEvent('phil-giveCash:client:receiveCitizenId', src, charName, targetPlayer.PlayerData.citizenid)
    else
        TriggerClientEvent('phil-giveCash:client:receiveCitizenId', src, playerName, nil)
    end
end)

RegisterNetEvent('phil-giveCash:server:getCharacterName', function(targetId)
    local src = source
    local targetPlayer = RSGCore.Functions.GetPlayer(tonumber(targetId))
    
    if targetPlayer then
        -- Get the character's full name
        local charName = string.format("%s %s", 
            targetPlayer.PlayerData.charinfo.firstname or "",
            targetPlayer.PlayerData.charinfo.lastname or "")
            
        -- Trim any extra whitespace
        charName = charName:match("^%s*(.-)%s*$")
        
        -- If the character name is empty, fall back to player name
        if charName == "" then
            charName = GetPlayerName(targetId)
        end
        
        TriggerClientEvent('phil-giveCash:client:showMenu', src, targetId, charName)
    else
        TriggerClientEvent('RSGCore:Notify', src, "Could not find player", "error")
    end
end)