--[[
-- @Name: Production Control
-- @Version: 1.0.0.0
-- @Author: Temmmych
-- @Contacts: https://github.com/Temmmych/FS25_ProductionControl
--]]

local modName = g_currentModName
local modDirectory = g_currentModDirectory
local version = g_modManager:getModByName(modName).version
local fileSettingsName = "ProductionControlSettings.xml"
local PCP = "productionControlSelfSpec_"
local debug = 0

ProductionControl = {}
ProductionControl._productionPoints = {}
ProductionControl._productions = {}
ProductionControl.productivityOptions = {50, 80, 100, 120, 150, 200, 300}

function ProductionControl.GetProductionProductivityFromSaveData(uniqueId, id)
    if debug > 0 then print("-- ProductionControl.GetProductionProductivityFromSaveData()") end
    local productionPoint = nil  
    for i = 1, #ProductionControl._productionPoints do
        if ProductionControl._productionPoints[i].uniqueId == uniqueId then
            productionPoint = ProductionControl._productionPoints[i]
            break
        end
    end

    if productionPoint == nil then
        return nil
    end
    
    local products = productionPoint.products
    if products == nil then
        return nil
    end

    for i = 1, #products do
        if products[i].id == id then
            return products[i].productivity
        end
    end

    return nil
end

function ProductionControl.CalculateAllPerMonth(production)
    if debug > 0 then print("-- ProductionControl.CalculateAllPerMonth()") end
    if production[PCP .. "productivity"] > ProductionControl.productivityOptions[#ProductionControl.productivityOptions] 
        or production[PCP .. "productivity"] < ProductionControl.productivityOptions[1] then production[PCP .. "productivity"] = 100 end
    local daysPerPeriod = 1
    if g_currentMission.environment ~= nil and g_currentMission.environment.daysPerPeriod ~= nil then
        daysPerPeriod = g_currentMission.environment.daysPerPeriod
    end
    production.cyclesPerMonth = production.cyclesPerMonth * (production[PCP .. "productivity"] / 100)
    production.cyclesPerHour = production.cyclesPerMonth / (24 * daysPerPeriod)
    production.cyclesPerMinute = production.cyclesPerHour / 60
    production.costsPerActiveMonth = production.costsPerActiveMonth * (production[PCP .. "productivity"] / 100)
    production.costsPerActiveHour = production.costsPerActiveMonth / (24 * daysPerPeriod)
    production.costsPerActiveMinute = production.costsPerActiveHour / 60
end

function ProductionControl:productionPointRegister()
    if debug > 0 then print("-- ProductionControl:productionPointRegister()") end
    self[PCP .. "uniqueId"] = self.owningPlaceable.uniqueId
    for i = 1, #self.productions do
        if self.productions[i] ~= nil then
            self.productions[i][PCP .. "productivity"] = ProductionControl.GetProductionProductivityFromSaveData(self[PCP .. "uniqueId"], self.productions[i].id) or 100
            self.productions[i][PCP .. "baseCyclesPerMonth"] = self.productions[i].cyclesPerMonth
            self.productions[i][PCP .. "baseCostsPerActiveMonth"] = self.productions[i].costsPerActiveMonth
            if self.productions[i][PCP .. "productivity"] ~= 100 then
                ProductionControl.CalculateAllPerMonth(self.productions[i])
            end
        end
    end
end

function ProductionControl.RecalculateProductionPointFromOnServer(__uniqueId, productionId, productivity)
    if debug > 0 then printf("--// ProductionControl.RecalculateProductionPointFromOnServer(%s, %s, %s)", __uniqueId, productionId, productivity) end
    if g_currentMission.productionChainManager ~= nil then
        local productionPoints = g_currentMission.productionChainManager.productionPoints
        for _, productionPoint in pairs(productionPoints) do
            if productionPoint[PCP .. "uniqueId"] ~= nil and productionPoint[PCP .. "uniqueId"] == __uniqueId and productionPoint.productions ~= nil  then
                for _,production in productionPoint.productions do
                    if production.id == productionId then
                        production.cyclesPerMonth = production[PCP .. "baseCyclesPerMonth"] or production.cyclesPerMonth
                        production.costsPerActiveMonth = production[PCP .. "baseCostsPerActiveMonth"] or production.costsPerActiveMonth
                        production[PCP .. "productivity"] = productivity
                        ProductionControl.CalculateAllPerMonth(production)
                        if g_server ~= nil then
                            ProductivityUpdate.sendEvent(__uniqueId, productionId, productivity)
                        end
                        return true
                    end
                end
            end
        end
    else
        if debug > 0 then print("-- Прозиводства не найдены!") end
    end
    if debug > 0 then print("-- Продукция не найдена!") end
    return false
end

function ProductionControl:RecalculateProductionPoint(__uniqueId, production, productivityIndex)
    if debug > 0 then print("-- ProductionControl:RecalculateProductionPoint()") end
    production.cyclesPerMonth = production[PCP .. "baseCyclesPerMonth"] or production.cyclesPerMonth
    production.costsPerActiveMonth = production[PCP .. "baseCostsPerActiveMonth"] or production.costsPerActiveMonth
    production[PCP .. "productivity"] = productivity or ProductionControl.productivityOptions[productivityIndex]
    ProductionControl.CalculateAllPerMonth(production)
    if g_client and g_currentMission.missionDynamicInfo 
        and g_currentMission.missionDynamicInfo.isMultiplayer then
            ProductivityRequest.sendEvent(__uniqueId, production.id, production[PCP .. "productivity"])
    end
end

function ProductionControl:updateMenuButtons(superFunc)
    if debug > 2 then print("-- ProductionControl:updateMenuButtons()") end
    local production, productionPoint = self:getSelectedProduction()
    local ownerFarmId = (productionPoint and productionPoint.ownerFarmId) or 0
    ProductionControl.productionFrame = self
    if ownerFarmId ~= 0 
        and ownerFarmId == g_currentMission:getFarmId()
        and g_currentMission:getHasPlayerPermission(Farm.PERMISSION.EDIT_FARM, g_currentMission.player) then
        local focusedElement = FocusManager:getFocusedElement()
        if focusedElement ~= nil and focusedElement.endClipperElementName == "endClipperProducts" then
            local productionPointId = productionPoint.id
            table.insert(self.menuButtonInfo, {
            inputAction = InputAction.MENU_EXTRA_1,
            text = g_i18n:getText("productivity_button_label") .. " " .. production[PCP .. "productivity"] .. "%",
            callback = function()

                local diagOptionsSelected = 3
                local diagOptions = {}
                for i, value in ipairs(ProductionControl.productivityOptions) do
                    diagOptions[i] = value .. "%"
                    if value == production[PCP .. "productivity"] then
                        diagOptionsSelected = i
                    end
                end

                local dialogArguments = {
                    title = production.name,
                    text = "\r\n" .. g_i18n:getText("productivity_warning_label"),
                    options = diagOptions,
                    defaultOption = diagOptionsSelected,
                    target = self,
                    args = {production},
                    callback = function(target, selectedOption, a)
                        if type(selectedOption) ~= "number" or selectedOption == 0 then return end
                        ProductionControl:RecalculateProductionPoint(productionPoint[PCP .. "uniqueId"], a[1], selectedOption)
                        self.timeSinceLastStateUpdate = 11000
                        if self.updateProductionLists ~= nil then
                            local success, err = pcall(function()
                                self:updateProductionLists()
                            end)

                            if not success then
                                Timer.new(200, function()
                                    if self.updateProductionLists ~= nil then
                                        self:updateProductionLists()
                                    end
                                end):start()
                                
                            end
                        end
                    end,
                }

                OptionDialog.createFromExistingGui({
                    optionTitle = dialogArguments.title,
                    optionText = dialogArguments.text,
                    options = dialogArguments.options,
                    callbackFunc = dialogArguments.callback,
                }, modName .. "OptionDialog")
                
                local optionDialog = OptionDialog.INSTANCE
                if dialogArguments.okButtonText ~= nil or dialogArguments.cancelButtonText ~= nil then
                    optionDialog:setButtonTexts(dialogArguments.okButtonText, dialogArguments.cancelButtonText)
                end

                local defaultOption = dialogArguments.defaultOption or 1
                optionDialog.optionElement:setState(defaultOption)
                if dialogArguments.callback and (type(dialogArguments.callback)) == "function" then
                    optionDialog:setCallback(dialogArguments.callback, dialogArguments.target, dialogArguments.args)
                end

            end
            })
        end

        self:setMenuButtonInfoDirty()
    end
end

function ProductionControl:updateProductionLists()
    if debug > 0 then print("-- InGameMenuProductionFrame:updateProductionLists()") end
    if self.productionPoints ~= nil then
        for i, prod in ipairs(self.productionPoints) do
            for ii, production in ipairs(prod.productions) do
                if production[PCP .. "name"] == nil then
                    production[PCP .. "name"] = production.name
                end
                production.name = production[PCP .. "name"] .. " (" .. production[PCP .. "productivity"] .. "%)"
            end
        end
    end
end

function ProductionControl:writeStream(streamId, connection)
    if debug > 0 then printf("-- ProducntionControl:writeStream(%s, %s)", streamId, connection) end
    streamWriteString(streamId, self[PCP .. "uniqueId"])
    streamWriteInt32(streamId, #self.productions)
    for _, prod in ipairs(self.productions) do
        streamWriteString(streamId, prod.id)
        streamWriteInt32(streamId, prod[PCP .. "productivity"])
        streamWriteInt32(streamId, prod[PCP .. "baseCyclesPerMonth"])
        streamWriteInt32(streamId, prod[PCP .. "baseCostsPerActiveMonth"])
    end
end

function ProductionControl:readStream(streamId, connection)
    if debug > 0 then print("-- ProducntionControl:readStream(streamId, connection)") end
    self[PCP .. "uniqueId"] = streamReadString(streamId)
    local count = streamReadInt32(streamId)
    for i = 1, count do
        local id = streamReadString(streamId)
        local productivity = streamReadInt32(streamId)
        local __baseCyclesPerMonth = streamReadInt32(streamId)
        local __baseCostsPerActiveMonth = streamReadInt32(streamId)
        for i = 1, #self.productions do
            if self.productions[i].id == id then
                self.productions[i][PCP .. "productivity"] = productivity
                self.productions[i].cyclesPerMonth = __baseCyclesPerMonth
                self.productions[i].costsPerActiveMonth = __baseCostsPerActiveMonth
                ProductionControl.CalculateAllPerMonth(self.productions[i])
            end
        end
    end
end

function ProductionControl:productionPointSaveToXMLFile(xmlFile, key, usedModNames)
    if debug > 0 then print("-- ProductionControl:productionPointSaveToXMLFile()") end
    local uniqueId = self.owningPlaceable.uniqueId
    local _products = {}
    _products.uniqueId = uniqueId
    _products.products = {}
    for i = 1, #self.productions do
        table.insert(_products.products, {productivity = self.productions[i][PCP .. "productivity"], id = self.productions[i].id})
    end

    table.insert(ProductionControl._productions, _products)
end

function ProductionControl.SaveSettings()
    if debug > 0 then print("-- ProductionControl.saveSettings()") end
    if g_server == nil then return end
    if g_currentMission.missionInfo.savegameDirectory == nil then  return end
    if next (ProductionControl._productions) == nil then return end

    local saveGameDirectory = g_currentMission.missionInfo.savegameDirectory
    local xmlContent = '<?xml version="1.0" encoding="utf-8" standalone="no"?>\n'
    xmlContent = xmlContent .. "<productionPoints>\n"
    for id, production in pairs(ProductionControl._productions) do
        xmlContent = xmlContent .. string.format('  <production uniqueId="%s">\n', production.uniqueId)
        for _, product in ipairs(production.products) do
            xmlContent = xmlContent .. string.format('    <product productivity="%d" id="%s"/>\n', product.productivity, product.id)
        end
        xmlContent = xmlContent .. "  </production>\n"
    end

    xmlContent = xmlContent .. "</productionPoints>"
    local filePath = saveGameDirectory .. "/" .. fileSettingsName
    local file = io.open(filePath, "w")
    file:write(xmlContent)
    file:close()
    ProductionControl._productions = {}
end

function ProductionControl:LoadSettings()
    if debug > 0 then print("-- ProductionControl:loadSettings()") end
    if g_server == nil then return end
    if g_currentMission.missionInfo.savegameDirectory == nil then  return end

    local saveGameDirectory = g_currentMission.missionInfo.savegameDirectory
    local filePath = saveGameDirectory .. "/" .. fileSettingsName
    if not fileExists(filePath) then
        return nil
    end

    local xmlFile = loadXMLFile("productionPoints", filePath)
    if xmlFile ~= nil then
        local _productionPoints = {}
        local i = 0
        while true do
            local productionKey = string.format("productionPoints.production(%d)", i)
            if not hasXMLProperty(xmlFile, productionKey) then
                break
            end

            local uniqueId = getXMLString(xmlFile, productionKey .. "#uniqueId")
            local production = {products = {}}
            local j = 0
            while true do
                local productKey = productionKey .. string.format(".product(%d)", j)
                if not hasXMLProperty(xmlFile, productKey) then
                    break
                end
                
                local productivity = getXMLInt(xmlFile, productKey .. "#productivity")
                local id = getXMLString(xmlFile, productKey .. "#id")
                table.insert(production.products, {productivity = productivity, id = id})
                j = j + 1
            end

            ProductionControl._productionPoints[i + 1] = production
            ProductionControl._productionPoints[i + 1].uniqueId = uniqueId
            i = i + 1
        end

        delete(xmlFile)
    end
end

function ProductionControl.init()
    if debug > 0 then print("-- " .. modName .. " v. " .. version) end
    Mission00.load = Utils.appendedFunction(Mission00.load, ProductionControl.LoadSettings)
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ProductionControl.SaveSettings)
    ProductionPoint.register =  Utils.appendedFunction(ProductionPoint.register, ProductionControl.productionPointRegister)
    ProductionPoint.saveToXMLFile =  Utils.appendedFunction(ProductionPoint.saveToXMLFile, ProductionControl.productionPointSaveToXMLFile)
    ProductionPoint.writeStream = Utils.appendedFunction(ProductionPoint.writeStream, ProductionControl.writeStream)
    ProductionPoint.readStream = Utils.appendedFunction(ProductionPoint.readStream, ProductionControl.readStream)
    InGameMenuProductionFrame.updateMenuButtons = Utils.appendedFunction(InGameMenuProductionFrame.updateMenuButtons, ProductionControl.updateMenuButtons)
    InGameMenuProductionFrame.updateProductionLists =  Utils.appendedFunction(InGameMenuProductionFrame.updateProductionLists, ProductionControl.updateProductionLists)
end

ProductionControl.init()