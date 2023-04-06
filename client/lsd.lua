local isPickingUp, isProcessing = false, false
local QBCore = exports['qb-core']:GetCoreObject()

local function Processlsd()
	isProcessing = true
	local playerPed = PlayerPedId()

	TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
	QBCore.Functions.Progressbar("search_register", Lang:t("progressbar.processing"), 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
		disableKeyboard = true,
	}, {}, {}, {}, function()
		TriggerServerEvent('ps-drugprocessing:Processlsd')

		local timeLeft = Config.Delays.lsdProcessing / 1000
		while timeLeft > 0 do
			Wait(1000)
			timeLeft -= 1
			if #(GetEntityCoords(playerPed)-Config.CircleZones.lsdProcessing.coords) > 5 then
				QBCore.Functions.Notify(Lang:t("error.too_far"))
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

local function Processthionylchloride()
	isProcessing = true
	local playerPed = PlayerPedId()

	TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_PARKING_METER", 0, true)
	QBCore.Functions.Progressbar("search_register", Lang:t("progressbar.processing"), 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
		disableKeyboard = true,
	}, {}, {}, {}, function()
		TriggerServerEvent('ps-drugprocessing:processThionylChloride')
		local timeLeft = Config.Delays.thionylchlorideProcessing / 1000
		while timeLeft > 0 do
			Wait(1000)
			timeLeft -= 1
			if #(GetEntityCoords(playerPed)-Config.CircleZones.thionylchlorideProcessing.coords) > 5 then
				QBCore.Functions.Notify(Lang:t("error.too_far"))
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

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if #(coords-Config.CircleZones.lsdProcessing.coords) < 2 then
            if not isProcessing then
                local pos = GetEntityCoords(PlayerPedId())
                QBCore.Functions.DrawText3D(pos.x, pos.y, pos.z, Lang:t("drawtext.process_lsd"))
            end
            if IsControlJustReleased(0, 38) and not isProcessing then
				QBCore.Functions.TriggerCallback('ps-drugprocessing:validate_items', function(result)
					if result then
                        Processlsd()
					else
						QBCore.Functions.Notify(Lang:t("error.not_all_items"), 'error')
					end
				end, {lsa = 1, thionyl_chloride = 1})
            end
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('ps-drugprocessing:processingThiChlo', function()
	local coords = GetEntityCoords(PlayerPedId(source))
	
	if #(coords-Config.CircleZones.thionylchlorideProcessing.coords) < 5 then
		if not isProcessing then
			QBCore.Functions.TriggerCallback('ps-drugprocessing:validate_items', function(result)
				if result then
					Processthionylchloride()
				else
					QBCore.Functions.Notify(Lang:t("error.not_all_items"), 'error')
				end
			end, {lsa = 1, chemicals = 1})
		end
	end
end)

--lsd lab enter--

RegisterNetEvent("qb-weedplant:EnterLsdLab", function()
	QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
	if hasItem then
		TriggerServerEvent("ps-weedplanting:RemoveLsdkey")
		DoScreenFadeOut(500)
			while not IsScreenFadedOut() do	Citizen.Wait(10) end
			SetEntityCoords(PlayerPedId(), vector4(887.33, -955.29, 39.28, 171.17))
			FreezeEntityPosition(PlayerPedId(), true)
			Wait(2000)
			DoScreenFadeIn(500)
			FreezeEntityPosition(PlayerPedId(), false)
	else
			QBCore.Functions.Notify("You dont have the required keys", "error")
		end
	  end, 'cocainekey')
	end)
	
	
	RegisterNetEvent("qb-weedplant:ExitLsdLab", function()
		DoScreenFadeOut(500)
		while not IsScreenFadedOut() do	Citizen.Wait(10) end
		SetEntityCoords(PlayerPedId(), vector4(812.86, -911.53, 25.44, 191.89))
		DoScreenFadeIn(500)
	end)
	
	
	exports['qb-target']:AddBoxZone("Enter-LsdLab", vector3(812.74, -910.41, 25.61), 2, 0.6, {
		name = "Enter-LsdLab",
		heading = 270,
		debugPoly = false,
		minZ = 23.01,
		maxZ = 27.01,
	}, {
		options = {
			{
				type = "client",
				event = "qb-weedplant:EnterLsdLab",
				icon = "fas fa-key",
				label = "Enter Lsd Lab",
			},
		},
		distance = 2.5
	})
	
	exports['qb-target']:AddBoxZone("Exit-LsdLab", vector3(887.38, -954.23, 39.28), 1.5, 0.5, {
		name = "Exit-LsdLab",
		heading = 270,
		debugPoly = false,
		minZ = 36.48,
		maxZ = 40.48,
	}, {
		options = {
			{
				type = "client",
				event = "qb-weedplant:ExitLsdLab",
				icon = "fas fa-lock",
				label = "Exit Lsd Lab",
			},
		},
		distance = 2.5
	})
