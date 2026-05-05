local ESX = exports['es_extended']:getSharedObject()

local menuOpen = false

-- ========================
-- PAUSE INTERCEPTION
-- ========================

CreateThread(function()
    while true do
        Wait(0)

        DisableControlAction(0, 199, true) -- INPUT_FRONTEND_PAUSE (ESC)
        DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE

        if IsDisabledControlJustPressed(0, 199) or IsDisabledControlJustPressed(0, 200) then
            if not menuOpen then
                OpenPauseMenu()
            end
        end
    end
end)

-- ========================
-- OPEN MENU
-- ========================

function OpenPauseMenu()
    menuOpen = true

    local ped      = PlayerPedId()
    local scenario = Config.Animations.scenarios[1]

    if Config.Animations.randomEnabled then
        scenario = Config.Animations.scenarios[math.random(#Config.Animations.scenarios)]
    end

    TaskStartScenarioInPlace(ped, scenario, 0, true)

    ESX.TriggerServerCallback('azakit_pausemenu:getPlayerData', function(playerData)
        SendNUIMessage({
            colors = {
                accentColor = Config.UI.accentColor,
                accentGlow  = Config.UI.accentGlow,
                bgDark      = Config.UI.bgDark,
            },
            translations = Config.Locale,
            nameServer   = Config.Locale.mainpage.server_name,
            DataPlayer   = playerData,
        })
    end)

    SetNuiFocus(true, true)
end

-- ========================
-- CLOSE MENU
-- ========================

function CloseMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    ClearPedTasks(PlayerPedId())
end

-- ========================
-- NUI CALLBACKS
-- ========================

RegisterNUICallback('closePauseMenu', function(_, cb)
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('actionPauseMenu', function(data, cb)
    CloseMenu()

    if data == 'maps' then
        Wait(300)
        ActivateFrontendMenu(GetHashKey('FE_PAUSE_MENU_CORONA'), false, -1)

    elseif data == 'settings' then
        Wait(300)
        ActivateFrontendMenu(GetHashKey('FE_PAUSE_MENU_CORONA'), false, -1)

    elseif data == 'quit' then
        TriggerServerEvent('azakit_pausemenu:dropPlayer')
    end

    cb('ok')
end)