local spawnedWeeds = 0
local weedPlants = {}
local isPickingUp, isProcessing, inWeedField = false, false, false
local QBCore = exports['qb-core']:GetCoreObject()

local function ValidateWeedCoord(plantCoord)
	local validate = true
	if spawnedWeeds > 0 then
		for k, v in pairs(weedPlants) do
			if #(plantCoord - GetEntityCoords(v)) < 5 then
				validate = false
			end
		end
		if not inWeedField then
			validate = false
		end
	end
	return validate
end

local function GetCoordZWeed(x, y)
	local groundCheckHeights = { 50, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0, 59.0, 60.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 53.85
end

local function GenerateWeedCoords()
	while true do
		Wait(1)

		local weedCoordX, weedCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-20, 20)

		Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-20, 20)

		weedCoordX = Config.CircleZones.WeedField.coords.x + modX
		weedCoordY = Config.CircleZones.WeedField.coords.y + modY

		local coordZ = GetCoordZWeed(weedCoordX, weedCoordY)
		local coord = vector3(weedCoordX, weedCoordY, coordZ)

		if ValidateWeedCoord(coord) then
			return coord
		end
	end
end

local function SpawnWeedPlants()
	while spawnedWeeds < 15 do
		Wait(0)
		local weedCoords = GenerateWeedCoords()
		RequestModel(`mw_weed_plant`)
		while not HasModelLoaded(`mw_weed_plant`) do
			Wait(100)
		end
		local obj = CreateObject(`mw_weed_plant`, weedCoords.x, weedCoords.y, weedCoords.z, false, true, false)
		PlaceObjectOnGroundProperly(obj)
		FreezeEntityPosition(obj, true)
		table.insert(weedPlants, obj)
		spawnedWeeds += 1
	end
end

local function RollJoint()
	isProcessing = true
	local playerPed = PlayerPedId()

	TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
	QBCore.Functions.Progressbar("search_register", Lang:t("progressbar.rolling_joint"), 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function()
		TriggerServerEvent('ps-drugprocessing:rollJoint')
		local timeLeft = Config.Delays.WeedProcessing / 1000
		while timeLeft > 0 do
			Wait(1000)
			timeLeft -= 1
		end
		ClearPedTasks(PlayerPedId())
		isProcessing = false
	end, function()
		ClearPedTasks(PlayerPedId())
		isProcessing = false
	end)
end

local function ProcessWeed()
	isProcessing = true
	local playerPed = PlayerPedId()

	TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
	QBCore.Functions.Progressbar("search_register", Lang:t("progressbar.processing"), 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function()
		TriggerServerEvent('ps-drugprocessing:processCannabis')
		local timeLeft = Config.Delays.WeedProcessing / 1000
		while timeLeft > 0 do
			Wait(1000)
			timeLeft -= 1
			if #(GetEntityCoords(playerPed)-Config.CircleZones.WeedProcessing.coords) > 4 then
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

RegisterNetEvent("ps-drugprocessing:processWeed",function()
	QBCore.Functions.TriggerCallback('ps-drugprocessing:validate_items', function(result)
		if result then
			ProcessWeed()
		else
			QBCore.Functions.Notify(Lang:t("error.no_cannabis"), 'error')
		end
	end,{cannabis = 1})
end)

RegisterNetEvent("ps-drugprocessing:pickWeed", function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local nearbyObject, nearbyID

	for i=1, #weedPlants, 1 do
		if GetDistanceBetweenCoords(coords, GetEntityCoords(weedPlants[i]), false) < 2 then
			nearbyObject, nearbyID = weedPlants[i], i
		end
	end

	if nearbyObject and IsPedOnFoot(playerPed) then
		if not isPickingUp then
			isPickingUp = true
			TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)
			QBCore.Functions.Progressbar("search_register", Lang:t("progressbar.collecting"), 10000, false, true, {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			}, {}, {}, {}, function() -- Done
				ClearPedTasks(PlayerPedId())
				SetEntityAsMissionEntity(nearbyObject, false, true)
				DeleteObject(nearbyObject)
				table.remove(weedPlants, nearbyID)
				spawnedWeeds -= 1
				TriggerServerEvent('ps-drugprocessing:pickedUpCannabis')
				isPickingUp = false
			end, function()
				ClearPedTasks(PlayerPedId())
				isPickingUp = false
			end)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(weedPlants) do
			SetEntityAsMissionEntity(v, false, true)
			DeleteObject(v)
		end
	end
end)

RegisterNetEvent('ps-drugprocessing:client:rollJoint', function()
    QBCore.Functions.TriggerCallback('ps-drugprocessing:validate_items', function(result)
		if result then
			RollJoint()
		else
			QBCore.Functions.Notify(Lang:t("error.no_marijuhana"), 'error')
		end
	end, {marijuana = 1})
end)

CreateThread(function()
	local weedZone = CircleZone:Create(Config.CircleZones.WeedField.coords, 10.0, {
		name = "ps-weedzone",
		debugPoly = false
	})
	weedZone:onPlayerInOut(function(isPointInside, point, zone)
        if isPointInside then
            inWeedField = true
            SpawnWeedPlants()
        else
            inWeedField = false
        end
    end)
end)


--weed lab enter--

RegisterNetEvent("qb-weedplant:EnterWeedLab", function()
	QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
	if hasItem then
		TriggerServerEvent("ps-weedplanting:RemoveWeedkey")
		DoScreenFadeOut(500)
			while not IsScreenFadedOut() do	Citizen.Wait(10) end
			SetEntityCoords(PlayerPedId(), vector4(1065.88, -3183.51, -39.16, 95.11))
			FreezeEntityPosition(PlayerPedId(), true)
			Wait(2000)
			DoScreenFadeIn(500)
			FreezeEntityPosition(PlayerPedId(), false)
	else
			QBCore.Functions.Notify("You dont have the required items", "error")
		end
	  end, 'cocainekey')
	end)
	
	
	RegisterNetEvent("qb-weedplant:ExitWeedLab", function()
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do	Citizen.Wait(10) end
		SetEntityCoords(PlayerPedId(), vector4(-38.24, 1908.26, 195.36, 288.22))
		DoScreenFadeIn(500)
	end)
	
	
	exports['qb-target']:AddBoxZone("Enter-weedLab", vector3(-39.58, 1908.1, 195.36), 1.6, 1, {
		name = "Enter-weedLab",
		heading = 5,
		debugPoly = false,
		minZ = 192.96,
		maxZ = 196.96,
	}, {
		options = {
			{
				type = "client",
				event = "qb-weedplant:EnterWeedLab",
				icon = "fas fa-cannabis",
				label = "Enter Weed Lab",
			},
		},
		distance = 2.5
	})
	
	exports['qb-target']:AddBoxZone("Exit-Lab", vector3(1066.63, -3183.42, -39.16), 1.7, 0.2, {
		name = "Exit-Lab",
		heading = 0,
		debugPoly = false,
		minZ = -41.76,
		maxZ = -37.76,
	}, {
		options = {
			{
				type = "client",
				event = "qb-weedplant:ExitWeedLab",
				icon = "fas fa-cannabis",
				label = "Exit Weed Lab",
			},
		},
		distance = 2.5
	})