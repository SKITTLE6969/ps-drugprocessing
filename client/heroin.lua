local spawnedPoppys = 0
local PoppyPlants = {}
local isPickingUp, isProcessing, inHeroinField = false, false, false
local QBCore = exports['qb-core']:GetCoreObject()

local function ValidateHeroinCoord(plantCoord)
	local validate = true
	if spawnedPoppys > 0 then
		for k, v in pairs(PoppyPlants) do
			if #(plantCoord - GetEntityCoords(v)) < 5 then
				validate = false
			end
		end
		if not inHeroinField then
			validate = false
		end
	end
	return validate
end

local function GetCoordZHeroin(x, y)
	local groundCheckHeights = { 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 50.0, 75.0, 100.0, 110.0, 125.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 12.64
end

local function GenerateHeroinCoords()
	while true do
		Wait(1)

		local heroinCoordX, heroinCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-60, 60)

		Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-60, 60)

		heroinCoordX = Config.CircleZones.HeroinField.coords.x + modX
		heroinCoordY = Config.CircleZones.HeroinField.coords.y + modY

		local coordZ = GetCoordZHeroin(heroinCoordX, heroinCoordY)
		local coord = vector3(heroinCoordX, heroinCoordY, coordZ)

		if ValidateHeroinCoord(coord) then
			return coord
		end
	end
end

local function SpawnPoppyPlants()
	while spawnedPoppys < 15 do
		Wait(0)
		local heroinCoords = GenerateHeroinCoords()
		RequestModel(`prop_plant_01b`)
		while not HasModelLoaded(`prop_plant_01b`) do
			Wait(100)
		end
		local obj = CreateObject(`prop_plant_01b`, heroinCoords.x, heroinCoords.y, heroinCoords.z, false, true, false)
		PlaceObjectOnGroundProperly(obj)
		FreezeEntityPosition(obj, true)
		table.insert(PoppyPlants, obj)
		spawnedPoppys += 1
	end
end

local function ProcessHeroin()
	isProcessing = true
	local playerPed = PlayerPedId()

	TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
	QBCore.Functions.Progressbar("search_register", Lang:t("progressbar.processing"), 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function()
		TriggerServerEvent('ps-drugprocessing:processPoppyResin')

		local timeLeft = Config.Delays.HeroinProcessing / 1000
		while timeLeft > 0 do
			Wait(1000)
			timeLeft -= 1

			if #(GetEntityCoords(playerPed)-Config.CircleZones.HeroinProcessing.coords) > 4 then
				TriggerServerEvent('ps-drugprocessing:cancelProcessing')
				break
			end
		end
		ClearPedTasks(playerPed)
		isProcessing = false
	end, function()
		ClearPedTasks(playerPed)
		isProcessing = false
	end)
end

RegisterNetEvent('ps-drugprocessing:ProcessPoppy', function()
	local coords = GetEntityCoords(PlayerPedId(source))
	
	if #(coords-Config.CircleZones.HeroinProcessing.coords) < 5 then
		if not isProcessing then
			QBCore.Functions.TriggerCallback('ps-drugprocessing:validate_items', function(result)
				if result then
					ProcessHeroin()
				else
					QBCore.Functions.Notify(Lang:t("error.not_all_items"), 'error')
				end
			end, {poppyresin = Config.HeroinProcessing.Poppy})
		end
	end
end)

RegisterNetEvent("ps-drugprocessing:processHeroin",function()
	QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
	QBCore.Functions.TriggerCallback('ps-drugprocessing:validate_items', function(result)
		if result then
			ProcessHeroin()
		else
			QBCore.Functions.Notify(Lang:t("no poppy resin"), 'error')
		end
	end, {poppyresin = Config.HeroinProcessing.Poppy})
	else
		QBCore.Functions.Notify('no empty weed bag', "error")
	end
  	end, 'empty_weed_bag') 
end)


RegisterNetEvent("ps-drugprocessing:pickHeroin", function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local nearbyObject, nearbyID

	for i=1, #PoppyPlants, 1 do
		if GetDistanceBetweenCoords(coords, GetEntityCoords(PoppyPlants[i]), false) < 2 then
			nearbyObject, nearbyID = PoppyPlants[i], i
		end
	end

	if nearbyObject and IsPedOnFoot(playerPed) then
		isPickingUp = true
		TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)
		QBCore.Functions.Progressbar("search_register", Lang:t("progressbar.collecting"), 10000, false, true, {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		}, {}, {}, {}, function() -- Done
			ClearPedTasks(playerPed)
			SetEntityAsMissionEntity(nearbyObject, false, true)
			DeleteObject(nearbyObject)

			table.remove(PoppyPlants, nearbyID)
			spawnedPoppys -= 1

			TriggerServerEvent('ps-drugprocessing:pickedUpPoppy')
			isPickingUp = false

		end, function()
			ClearPedTasks(playerPed)
			isPickingUp = false
		end)
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(PoppyPlants) do
			SetEntityAsMissionEntity(v, false, true)
			DeleteObject(v)
		end
	end
end)

CreateThread(function()
	local heroinZone = CircleZone:Create(Config.CircleZones.HeroinField.coords, 50.0, {
		name = "ps-heroinzone",
		debugPoly = false
	})
	heroinZone:onPlayerInOut(function(isPointInside, point, zone)
        if isPointInside then
            inHeroinField = true
            SpawnPoppyPlants()
        else
            inHeroinField = false
        end
    end)
end)

--heroin lab enter--

RegisterNetEvent("qb-weedplant:EnterHeroinLab", function()
	QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
	if hasItem then
		TriggerServerEvent("ps-weedplanting:RemoveHeroinkey")
		DoScreenFadeOut(500)
			while not IsScreenFadedOut() do	Citizen.Wait(10) end
			SetEntityCoords(PlayerPedId(), vector4(729.53, -778.04, 25.09, 284.06))
			FreezeEntityPosition(PlayerPedId(), true)
			Wait(2000)
			DoScreenFadeIn(500)
			FreezeEntityPosition(PlayerPedId(), false)
	else
			QBCore.Functions.Notify("You dont have the required keys", "error")
		end
	  end, 'cocainekey')
	end)
	
	
	RegisterNetEvent("qb-weedplant:ExitHeroinLab", function()
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do	Citizen.Wait(10) end
		SetEntityCoords(PlayerPedId(), vector4(895.77, -896.23, 27.8, 91.22))
		DoScreenFadeIn(500)
	end)
	
	
	exports['qb-target']:AddBoxZone("Enter-HeroinLab", vector3(896.41, -896.27, 27.79), 1, 0.5, {
		name = "Enter-HeroinLab",
		heading = 0,
		debugPoly = false,
		minZ = 25.19,
		maxZ = 29.19,
	}, {
		options = {
			{
				type = "client",
				event = "qb-weedplant:EnterHeroinLab",
				icon = "fas fa-key",
				label = "Enter Heroin Lab",
			},
		},
		distance = 2.5
	})
	
	exports['qb-target']:AddBoxZone("Exit-HeroinLab", vector3(728.22, -777.93, 25.09), 1.4, 0.6, {
		name = "Exit-HeroinLab",
		heading = 0,
		debugPoly = false,
		minZ = 22.69,
		maxZ = 26.69,
	}, {
		options = {
			{
				type = "client",
				event = "qb-weedplant:ExitHeroinLab",
				icon = "fas fa-lock",
				label = "Exit Heroin Lab",
			},
		},
		distance = 2.5
	})
