local ESX = exports['es_extended']:getSharedObject()

-- ========================
-- CALLBACK: Player Data
-- ========================

ESX.RegisterServerCallback('azakit_pausemenu:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cb(nil)
        return
    end

    cb({
        playerID = source,
        name     = xPlayer.getName(),
        job      = xPlayer.getJob().label,
        cash     = xPlayer.getMoney(),
        bank     = xPlayer.getAccount('bank').money,
    })
end)

-- ========================
-- EVENT: Drop Player
-- ========================

RegisterNetEvent('azakit_pausemenu:dropPlayer')
AddEventHandler('azakit_pausemenu:dropPlayer', function()
    local src = source
    DropPlayer(src, Config.Locale.dropplayer)
end)