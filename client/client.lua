local isLoaded = false
local npcEntity = nil
local spawnedVehicle = nil

-- ──────────────────────────────────────────────
-- Framework Bootstrap
-- ──────────────────────────────────────────────
local QBCore = nil
local ESX    = nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
else
    print(Locales[Config.Locale]['error_invalid_framework']:format(Config.Framework))
end

-- ──────────────────────────────────────────────
-- Notification helper
-- ──────────────────────────────────────────────
local function Notify(msg, nType)
    nType = nType or 'primary'
    if Config.Framework == 'qb' and QBCore then
        QBCore.Functions.Notify(msg, nType)
    elseif Config.Framework == 'esx' and ESX then
        ESX.ShowNotification(msg)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentSubstringPlayerName(msg)
        DrawNotification(false, true)
    end
end

-- ──────────────────────────────────────────────
-- NUI Helpers
-- ──────────────────────────────────────────────
local function SendNUI(action, data)
    data = data or {}
    data.action = action
    SendNUIMessage(data)
end

-- ──────────────────────────────────────────────
-- Vehicle Spawn
-- ──────────────────────────────────────────────
local function GetFreeSpawnLocation()
    for _, loc in ipairs(Config.SpawnLocations) do
        local occupied = false
        local nearbyVehs = GetGamePool('CVehicle')
        for _, veh in ipairs(nearbyVehs) do
            local vehPos = GetEntityCoords(veh)
            local dist   = #(vector3(loc.x, loc.y, loc.z) - vehPos)
            if dist < 4.0 then
                occupied = true
                break
            end
        end
        if not occupied then
            return loc
        end
    end
    return nil
end

local function SpawnVehicle(model, cb)
    local hash = GetHashKey(model)

    if not IsModelValid(hash) then
        Notify(Locales[Config.Locale]['notif_model_loading_failed'] .. model, 'error')
        if cb then cb(false) end
        return
    end

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(hash) then
        Notify(Locales[Config.Locale]['notif_model_loading_failed'] .. model, 'error')
        if cb then cb(false) end
        return
    end

    local spawnLoc = GetFreeSpawnLocation()
    if not spawnLoc then
        Notify(Locales[Config.Locale]['notif_no_parking'], 'error')
        if cb then cb(false) end
        SetModelAsNoLongerNeeded(hash)
        return
    end

    -- Delete previous spawned vehicle if exists
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
        spawnedVehicle = nil
    end

    local veh = CreateVehicle(hash, spawnLoc.x, spawnLoc.y, spawnLoc.z, spawnLoc.w, true, false)
    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNumberPlateText(veh, 'RENTAL')
    spawnedVehicle = veh

    SetModelAsNoLongerNeeded(hash)
    if cb then cb(true, veh) end
end

-- ──────────────────────────────────────────────
-- Market UI
-- ──────────────────────────────────────────────
local isMarketOpen = false

local function OpenMarket()
    if not isLoaded then
        Notify(Locales[Config.Locale]['notif_system_loading'], 'error')
        return
    end

    if isMarketOpen then return end
    isMarketOpen = true

    SetNuiFocus(true, true)
    SendNUI('open', {
        title      = Config.ShopTitle,
        subtitle   = Config.ShopSubtitle,
        taxRate    = Config.TaxRate,
        background = Config.UIBackground,
        categories = Config.Categories,
        cars       = Config.Cars,
        locale     = Locales[Config.Locale],
    })
end

local function CloseMarket()
    if not isMarketOpen then return end
    isMarketOpen = false
    SetNuiFocus(false, false)
    SendNUI('close', {})
end

-- ──────────────────────────────────────────────
-- NUI Callbacks
-- ──────────────────────────────────────────────
RegisterNUICallback('closeMarket', function(_, cb)
    CloseMarket()
    cb('ok')
end)

RegisterNUICallback('buyCar', function(data, cb)
    TriggerServerEvent('wasd-carrental:server:buyCar', {
        model = data.model,
        label = data.label,
        price = data.price,
        tax   = data.tax,
        total = data.total,
    })
    cb('ok')
end)

-- ──────────────────────────────────────────────
-- Server → Client: purchase result
-- ──────────────────────────────────────────────
RegisterNetEvent('wasd-carrental:client:purchaseSuccess', function(data)
    CloseMarket()

    local msg = Locales[Config.Locale]['notif_car_delivered']:format(data.label)
    Notify(msg, 'success')

    SpawnVehicle(data.model, function(success, veh)
        if not success then return end
        local ped = PlayerPedId()
        TaskWarpPedIntoVehicle(ped, veh, -1)
        SetVehicleEngineOn(veh, true, true, false)
    end)
end)

RegisterNetEvent('wasd-carrental:client:purchaseFailed', function(reason)
    Notify(reason or Locales[Config.Locale]['notif_purchase_failed'], 'error')
    -- Re-enable UI buttons so the player can try again
    SendNUIMessage({ action = 'enableButtons' })
end)

-- ──────────────────────────────────────────────
-- NPC Spawn
-- ──────────────────────────────────────────────
local function SpawnNPC()
    local cfg  = Config.NPC
    local hash = GetHashKey(cfg.model)

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(hash) then
        print(Locales[Config.Locale]['error_npc_model_failed']:format(cfg.model))
        return
    end

    local coords = cfg.coords
    npcEntity = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)

    if not DoesEntityExist(npcEntity) then
        print(Locales[Config.Locale]['error_invalid_npc_entity'])
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityAsMissionEntity(npcEntity, true, true)
    SetPedCanRagdoll(npcEntity, false)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    SetEntityInvincible(npcEntity, true)
    FreezeEntityPosition(npcEntity, true)
    TaskStartScenarioInPlace(npcEntity, cfg.scenario, 0, true)

    SetModelAsNoLongerNeeded(hash)

    -- ── Target integration ──
    if GetResourceState('ox_target') == 'started' then
        exports['ox_target']:addLocalEntity(npcEntity, {
            {
                name     = 'wasd_car_market',
                icon     = cfg.targetIcon,
                label    = cfg.targetLabel,
                distance = cfg.targetDistance,
                onSelect = function()
                    OpenMarket()
                end,
            },
        })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetEntity(npcEntity, {
            options = {
                {
                    type     = 'client',
                    event    = 'wasd-carrental:client:openMarket',
                    icon     = cfg.targetIcon,
                    label    = cfg.targetLabel,
                    distance = cfg.targetDistance,
                },
            },
            distance = cfg.targetDistance,
        })
    else
        -- ── Fallback: proximity check ──
        -- FIX: Split into two threads.
        -- Slow thread: updates isNearNpc every 500ms (cheap distance math).
        -- Fast thread: draws text and polls input every frame only when near.
        -- Previously both were in one Wait(500) loop, making DrawText invisible.

        local isNearNpc = false

        -- Distance polling (slow)
        CreateThread(function()
            while DoesEntityExist(npcEntity) do
                Wait(500)
                local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(npcEntity))
                isNearNpc = (dist <= cfg.targetDistance)
            end
            isNearNpc = false
        end)

        -- Draw + input (per-frame when in range)
        CreateThread(function()
            while DoesEntityExist(npcEntity) do
                if isNearNpc then
                    Wait(0)
                    local x, y, z = table.unpack(GetEntityCoords(npcEntity))

                    SetTextScale(0.35, 0.35)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 255, 255, 215)
                    SetTextEntry('STRING')
                    SetTextCentre(true)
                    AddTextComponentSubstringPlayerName('[E] ' .. cfg.targetLabel)
                    SetDrawOrigin(x, y, z + 1.2, 0)
                    DrawText(0.0, 0.0)
                    ClearDrawOrigin()

                    if IsControlJustReleased(0, 38) then -- E key
                        OpenMarket()
                    end
                else
                    Wait(500)
                end
            end
        end)
    end

    -- ── Blip ──
    if cfg.blipEnabled then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, cfg.blipSprite)
        SetBlipColour(blip, cfg.blipColor)
        SetBlipScale(blip, cfg.blipScale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(cfg.blipName)
        EndTextCommandSetBlipName(blip)
    end
end

-- ──────────────────────────────────────────────
-- Event: open market from qb-target
-- ──────────────────────────────────────────────
RegisterNetEvent('wasd-carrental:client:openMarket', function()
    OpenMarket()
end)

-- ──────────────────────────────────────────────
-- Init
-- ──────────────────────────────────────────────
CreateThread(function()
    Wait(1000)
    SpawnNPC()
    isLoaded = true
end)