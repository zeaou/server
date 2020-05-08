-- CLIENTSIDED

-- Registers a network event
RegisterNetEvent('Engine')

local vehicles = {}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if GetSeatPedIsTryingToEnter(GetPlayerPed(-1)) == -1 and not table.contains(vehicles, GetVehiclePedIsTryingToEnter(GetPlayerPed(-1))) then
			table.insert(vehicles, {GetVehiclePedIsTryingToEnter(GetPlayerPed(-1)), IsVehicleEngineOn(GetVehiclePedIsTryingToEnter(GetPlayerPed(-1)))})
		elseif IsPedInAnyVehicle(GetPlayerPed(-1), false) and not table.contains(vehicles, GetVehiclePedIsIn(GetPlayerPed(-1), false)) then
			table.insert(vehicles, {GetVehiclePedIsIn(GetPlayerPed(-1), false), IsVehicleEngineOn(GetVehiclePedIsIn(GetPlayerPed(-1), false))})
		end
		for i, vehicle in ipairs(vehicles) do
			if DoesEntityExist(vehicle[1]) then
				if (GetPedInVehicleSeat(vehicle[1], -1) == GetPlayerPed(-1)) or IsVehicleSeatFree(vehicle[1], -1) then
					SetVehicleEngineOn(vehicle[1], vehicle[2], true, false)
					SetVehicleJetEngineOn(vehicle[1], vehicle[2])
					if not IsPedInAnyVehicle(GetPlayerPed(-1), false) or (IsPedInAnyVehicle(GetPlayerPed(-1), false) and vehicle[1]~= GetVehiclePedIsIn(GetPlayerPed(-1), false)) then
						if IsThisModelAHeli(GetEntityModel(vehicle[1])) or IsThisModelAPlane(GetEntityModel(vehicle[1])) then
							if vehicle[2] then
								SetHeliBladesFullSpeed(vehicle[1])
							end
						end
					end
				end
			else
				table.remove(vehicles, i)
			end
		end
	end
end)

AddEventHandler('Engine', function()
	local veh
	local Index
	for i, vehicle in ipairs(vehicles) do
		if vehicle[1] == GetVehiclePedIsIn(GetPlayerPed(-1), false) then
			veh = vehicle[1]
			Index = i
		end
	end
	Citizen.Wait(1500)
	if IsPedInAnyVehicle(GetPlayerPed(-1), false) then 
		if (GetPedInVehicleSeat(veh, -1) == GetPlayerPed(-1)) then
			vehicles[Index][2] = not GetIsVehicleEngineRunning(veh)
			if vehicles[Index][2] then
				TriggerEvent("chatMessage", "", {0, 255, 0}, "Engine turned ON!")
			else
				TriggerEvent("chatMessage", "", {255, 0, 0}, "Engine turned OFF!")
			end
		end 
    end 
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if GetSeatPedIsTryingToEnter(GetPlayerPed(-1)) == -1 then
			for i, vehicle in ipairs(vehicles) do
				if vehicle[1] == GetVehiclePedIsTryingToEnter(GetPlayerPed(-1)) and not vehicle[2] then
					Citizen.Wait(3500)
					vehicle[2] = true
					TriggerEvent("chatMessage", "", {0, 255, 0}, "Engine turned ON!")
				end
			end
		end
		if (IsControlJustPressed(1, 178) or IsDisabledControlJustPressed(1, 303)) and GetLastInputMethod(2) then
			TriggerEvent('Engine')
		end
	end
end)

function table.contains(table, element)
  for _, value in pairs(table) do
    if value[1] == element then
      return true
    end
  end
  return false
end