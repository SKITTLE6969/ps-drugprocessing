local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('ps-drugprocessing:Processlsd', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if Player.Functions.RemoveItem("lsa", 1) and Player.Functions.RemoveItem("empty_weed_bag", 1) then
		if Player.Functions.RemoveItem("thionyl_chloride", 1) then
			if Player.Functions.AddItem("lsd", 1) then
				TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["lsd"], "add")
				TriggerClientEvent('QBCore:Notify', src, Lang:t("success.lsd"), "success")
			else
				Player.Functions.AddItem("lsa", 1)
				Player.Functions.AddItem("thionyl_chloride", 1)
			end
		else
			Player.Functions.AddItem("lsa", 1)
			TriggerClientEvent('QBCore:Notify', src, Lang:t("error.no_thionyl_chloride"), "error")
		end
	else
		TriggerClientEvent('QBCore:Notify', src, Lang:t("error.no_lsa"), "error")
	end
end)

RegisterServerEvent('ps-drugprocessing:processThionylChloride', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if Player.Functions.RemoveItem("lsa", 1) then
		if Player.Functions.RemoveItem("chemicals", 1) then
			if Player.Functions.AddItem("thionyl_chloride", 1) then
				TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["thionyl_chloride"], "add")
				TriggerClientEvent('QBCore:Notify', src, Lang:t("success.thionyl_chloride"), "success")
			else
				Player.Functions.AddItem("lsa", 1)
				Player.Functions.AddItem("chemicals", 1)
			end
		else
			Player.Functions.AddItem("lsa", 1)
			TriggerClientEvent('QBCore:Notify', src, Lang:t("error.no_chemicals"), "error")
		end
	else
		TriggerClientEvent('QBCore:Notify', src, Lang:t("error.no_lsa"), "error")
	end
end)

---Lsd lab enter--

RegisterServerEvent('ps-weedplanting:RemoveLsdkey', function()
	local Player = QBCore.Functions.GetPlayer(source)
	Player.Functions.RemoveItem('cocainekey', 1)
	TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['cocainekey'], "Remove", 1)
end)