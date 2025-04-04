--[[
-- @Name: Production Control
-- @Version: 1.0.0.0
-- @Author: Temmmych
-- @Contacts: https://github.com/Temmmych/FS25_ProductionControl
--]]

local debug = 1

ProductivityChange = {}
local ProductivityChange_mt = Class(ProductivityChange, Event)
InitEventClass(ProductivityChange, "ProductivityChange")

function ProductivityChange:emptyNew()
    if debug > 1 then print("--//ProductivityChange:emptyNew()") end
    return  Event.new(ProductivityChange_mt)
end

function ProductivityChange.new(uniqueId, productionId, productivity)
    if debug > 0 then print("-- ProductivityChange.new()") end
    local self = ProductivityChange:emptyNew()
    self.uniqueId = uniqueId 
    self.productionId = productionId
    self.productivity = productivity
    if debug > 1 then print("//ProductivityChange.new()") end
    return self
end

function ProductivityChange:writeStream(streamId)
    if debug > 0 then print("-- ProductivityChange.writeStream()") end
    streamWriteString(streamId, self.uniqueId)
    streamWriteString(streamId, self.productionId)
    streamWriteInt32(streamId, self.productivity)
    if debug > 1 then print("//ProductivityChange.writeStream()") end
end

function ProductivityChange:readStream(streamId, connection)
    if debug > 0 then print("-- ProductivityChange.readStream()") end
    self.uniqueId = streamReadString(streamId)
    self.productionId = streamReadString(streamId)
    self.productivity = streamReadInt32(streamId)
    self:run(connection)
    if debug > 1 then print("//ProductivityChange.readStream()") end
end

function ProductivityChange:run(connection)
    if debug > 0 then print("-- ProductivityChange.run()") end
    if g_server == nil then -- на сервере уже был пересчёт в Request
        if debug > 0 then print("-- g_server == nil") end
        ProductionControl.RecalculateProductionPointFromOnServer(self.uniqueId, self.productionId, self.productivity)
    end
    if debug > 1 then print("//ProductivityChange.run()") end
end

function ProductivityChange.sendEvent(uniqueId, productionId, productivity)
    if debug > 0 then printf("-- ProductivityChange.sendEvent(%s, %s, %s)", uniqueId, productionId, productivity) end
    g_server:broadcastEvent(ProductivityChange.new(uniqueId, productionId, productivity)) -- сюда попадает только g_server или (g_server и g_client(хост))
    if debug > 1 then print("//ProductivityChange.sendEvent()") end
end