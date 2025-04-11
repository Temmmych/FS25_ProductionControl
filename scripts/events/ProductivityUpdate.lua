--[[
-- @Name: Production Control
-- @Version: 1.0.0.0
-- @Author: Temmmych
-- @Contacts: https://github.com/Temmmych/FS25_ProductionControl
--]]

ProductivityUpdate = {}
local ProductivityChange_mt = Class(ProductivityUpdate, Event)
InitEventClass(ProductivityUpdate, "ProductivityUpdate")
local debug = 0

function ProductivityUpdate:emptyNew()
    return  Event.new(ProductivityChange_mt)
end

function ProductivityUpdate.new(uniqueId, productionId, productivity)
    if debug > 0 then print("-- ProductivityChange.new()") end
    local self = ProductivityUpdate:emptyNew()
    self.uniqueId = uniqueId 
    self.productionId = productionId
    self.productivity = productivity
    return self
end

function ProductivityUpdate:writeStream(streamId)
    if debug > 0 then print("-- ProductivityChange.writeStream()") end
    streamWriteString(streamId, self.uniqueId)
    streamWriteString(streamId, self.productionId)
    streamWriteInt32(streamId, self.productivity)
end

function ProductivityUpdate:readStream(streamId, connection)
    if debug > 0 then print("-- ProductivityChange.readStream()") end
    self.uniqueId = streamReadString(streamId)
    self.productionId = streamReadString(streamId)
    self.productivity = streamReadInt32(streamId)
    self:run(connection)
end

function ProductivityUpdate:run(connection)
    if debug > 0 then print("-- ProductivityChange.run()") end
    if g_server == nil then
        ProductionControl.RecalculateProductionPointFromOnServer(self.uniqueId, self.productionId, self.productivity) -- пересчёт на сервере был в Request
    end
end

function ProductivityUpdate.sendEvent(uniqueId, productionId, productivity)
    if debug > 0 then printf("-- ProductivityChange.sendEvent(%s, %s, %s)", uniqueId, productionId, productivity) end
    g_server:broadcastEvent(ProductivityUpdate.new(uniqueId, productionId, productivity))
end