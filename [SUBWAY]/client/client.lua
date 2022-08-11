RegisterCommand('attachsubway', function()
    local belowFaxMachine = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 1.0, 0.0, -1.0)
    local boatCoordsInWorldLol = GetEntityCoords(GetPlayerPed(-1))
    local testnb = 0.0
    GetVehicleInDirection2(vector3(boatCoordsInWorldLol.x, boatCoordsInWorldLol.y, boatCoordsInWorldLol.z), vector3(belowFaxMachine.x, belowFaxMachine.y, belowFaxMachine.z - testnb))
    Citizen.SetTimeout(1500, function()
        if notfindtrailer then
            havetobreak = true
        end
    end)
    while notfindtrailer do
        GetVehicleInDirection2(vector3(boatCoordsInWorldLol.x, boatCoordsInWorldLol.y, boatCoordsInWorldLol.z), vector3(belowFaxMachine.x, belowFaxMachine.y, belowFaxMachine.z - testnb))
        testnb = testnb + 0.1
        if havetobreak then
            break
        end
        Citizen.Wait(0)
    end
    if trailerfind and trailerfind ~= nil then
        AttachEntityToEntity(GetPlayerPed(-1), trailerfind, GetEntityBoneIndexByName(trailerfind, 'chassis'), GetOffsetFromEntityGivenWorldCoords(trailerfind, GetEntityCoords(GetPlayerPed(-1))), 0.0, 0.0, 0.0, false, false, true, false, 20, true)
    end
end, false)

RegisterCommand('detachsubway', function()
    DetachEntity(GetPlayerPed(-1), true, false)
end, false)

SubWay = {}
SubWay.Menu = {}
SubWay.Menu.IsOpen = false
SubWay.Menu.Main = RageUI.CreateMenu("", "Shop", nil, nil, "root_cause", "shopui_title_elitastravel")
SubWay.Menu.SubWayGarage = RageUI.CreateMenu("", "Garage Metro", nil, nil, "root_cause", "shopui_title_elitastravel")
SubWay.Menu.ChooseTrailTrain = RageUI.CreateMenu("", "Track", nil, nil, "root_cause", "shopui_title_elitastravel")

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local playercoords = GetEntityCoords(GetPlayerPed(-1))
        for k, v in pairs(SubWayConfig.Garage) do
            if GetDistanceBetweenCoords(playercoords, v.coords, true) < 10 then
                wait = 0
                DrawMarker(20, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0., 0.3, 255, 255, 255, 200, 1, true, 2, 0, nil, nil, 0)
                if GetDistanceBetweenCoords(playercoords, v.coords, true) < 2 then
                    HelpNotification(Config.Lang["OpenStation"])
                    if IsControlJustReleased(0, 38) then
                        OpenSubWayGarage(k)
                    end
                end
            end
        end
        Citizen.Wait(wait)
    end
end)  

Citizen.CreateThread(function()
    while true do 
        local wait = 1000
        local playercoords = GetEntityCoords(GetPlayerPed(-1))
        for k, v in pairs(SubWayConfig.Garage) do
            local traintodelete = GetVehiclePedIsIn(PlayerPedId(), false)
            if traintodelete ~= 0 and traintodelete ~= nil then
                if GetDistanceBetweenCoords(playercoords, v.coordsdeletetrain, true) < 30 and traintodelete ~= nil and GetVehicleClass(traintodelete) == 21 then
                    wait = 0
                    HelpNotification(Config.Lang["StowTrain"])
                    if IsControlJustReleased(0, 38) then
                        for x, w in pairs(CurrentTrain) do
                            if w.entity == traintodelete then
                                if k == tonumber(w.station) then
                                    DeleteMissionTrain(traintodelete)
                                    CurrentTrain[x] = nil
                                else
                                    SendNotification(Config.Lang["NotGoodStation"])
                                end
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(wait)
    end
end)

function GetVehicleInDirection2(cFrom, cTo)
    trailerfind = nil
    notfindtrailer = true
    local rayHandle = CastRayPointToPoint(cFrom.x, cFrom.y, cFrom.z, cTo.x, cTo.y, cTo.z, 10, GetPlayerPed(-1), 0)
    local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
    if vehicle == 0 then
        notfindtrailer = true
    else
        if vehicle and vehicle ~= nil then
            notfindtrailer = false
            trailerfind = vehicle
        else
            notfindtrailer = true
        end
    end
end

function SubWay.Menu.Open(index)
    Citizen.CreateThread(function()
        while SubWay.Menu.IsOpen do
            RageUI.IsVisible(SubWay.Menu.ChooseTrailTrain, function()
                RageUI.Button(Config.Lang["ChooseTrail"], nil, {}, true, {
                    onSelected = function()
                    end,
                })
                for k, v in pairs(SubWayConfig.Garage[index].path) do
                    RageUI.Button(Config.Lang["Track"]..k, nil, {}, true, {
                        onSelected = function()
                            for k, v in pairs(OwnedTrain) do
                                if tonumber(index) == tonumber(v.stationstock) then
                                    if not incooldownspawntrain then
                                        RageUI.CloseAll()
                                        incooldownspawntrain = true
                                        Citizen.SetTimeout(5000, function()
                                            incooldownspawntrain = false
                                        end)
                                        SpawnSubWayInTrail(v.stationstock, tonumber(v.trainmodelindex), tonumber(v.uniqueID), lastcoordstrail)
                                    end
                                end
                            end
                        end,
                        onActive = function()
                            lastcoordstrail = v
                            DrawMarker(20, v.x, v.y, v.z + 1.1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0., 0.3, 255, 255, 255, 200, 1, true, 2, 0, nil, nil, 0)
                        end
                    })
                end
            end)
            RageUI.IsVisible(SubWay.Menu.SubWayGarage, function()
                local notraininstation = true
                for k, v in pairs(OwnedTrain) do 
                    if tonumber(v.trainmodelindex) == 25 then
                        if GetPlayerName(PlayerId()) == v.owneur then
                            if tonumber(index) == tonumber(v.stationstock) then
                                notraininstation = false
                                if #CurrentTrain > 0 then
                                    local notgetout = true
                                    for l, m in pairs(CurrentTrain) do
                                        if tonumber(v.uniqueID) == tonumber(m.uniqueID) then
                                            notgetout = false
                                            RageUI.Button('ID :'.. v.uniqueID.. ', ' ..Config.Lang["Modele"] .. v.modellabel.. Config.Lang["TrainOut"], Config.Lang["BoughtThe"]..v.achatdate.. Config.Lang["at"]..v.stationachat, {}, true, {
                                                onSelected = function()
                                                    SendNotification(Config.Lang["AlreadyOut"])
                                                end,
                                            })
                                        end
                                    end
                                    if notgetout then
                                        RageUI.Button('ID :'.. v.uniqueID.. ', ' ..Config.Lang["Modele"] .. v.modellabel, Config.Lang["Station"].. v.stationstock .. '\n'..Config.Lang["BoughtThe"]..v.achatdate.. Config.Lang["at"]..v.stationachat, {}, true, {
                                            onSelected = function()
                                                ChooseTrackSubWayGarage(index, v.uniqueID)
                                            end,
                                        })
                                    end
                                else
                                    RageUI.Button('ID :'.. v.uniqueID.. ', ' ..Config.Lang["Modele"] .. v.modellabel, Config.Lang["Station"].. v.stationstock ..'\n'..Config.Lang["BoughtThe"]..v.achatdate.. Config.Lang["at"]..v.stationachat, {}, true, {
                                        onSelected = function()
                                            ChooseTrackSubWayGarage(index, v.uniqueID)
                                        end,
                                    })
                                end
                            end
                        end
                    end
                end
                if notraininstation then
                    RageUI.Button(Config.Lang["NoTrainAtThisStation"], nil, {}, true, {
                        onSelected = function()
                        end,
                    })
                end
            end)
            Citizen.Wait(1)
        end
    end)
end

function SpawnSubWayInTrail(station, trainindex, uniqueID, trailcoords)
    if ModelsLoaded then
        temptrain = CreateMissionTrain(trainindex, trailcoords.x, trailcoords.y, trailcoords.z, math.random(0,100))
        SetTrainsForceDoorsOpen(true)
        TriggerServerEvent('az_train:synchroCurrentTrainServer', VehToNet(temptrain), false, uniqueID, trainindex, station)
        SetTrainSpeed(temptrain, 0)
        SetTrainCruiseSpeed(temptrain,0)
        Citizen.Wait(2000)
        trainfreezequaie = true
        TriggerServerEvent('az_train:openStashRobberyServer', VehToNet(temptrain))
    else
        SendNotification(Config.Lang["ProblemChargeTrain"])
    end
end

function OpenSubWayGarage(index)
    RageUI.CloseAll()
    RageUI.Visible(SubWay.Menu.SubWayGarage, true)
    SubWay.Menu.IsOpen = true
    SubWay.Menu.Open(index)
end

function ChooseTrackSubWayGarage(index)
    RageUI.CloseAll()
    RageUI.Visible(SubWay.Menu.ChooseTrailTrain, true)
    SubWay.Menu.IsOpen = true
    SubWay.Menu.Open(index)
end

Citizen.CreateThread(function()
    for k, v in pairs(SubWayConfig.Station) do
        local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
        SetBlipSprite (blip, 120)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.4)
        SetBlipColour (blip, 45)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Lang["Subway"])
        EndTextCommandSetBlipName(blip)
    end
end)