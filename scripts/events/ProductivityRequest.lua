--[[
-- @Name: Production Control
-- @Version: 1.0.0.0
-- @Author: Temmmych
-- @Contacts: https://github.com/Temmmych/FS25_ProductionControl
--]]

ProductivityRequest = {}
local ProductivityChangeRequest_mt = Class(ProductivityRequest, Event)
InitEventClass(ProductivityRequest, "ProductivityRequest")
local debug = 0

function ProductivityRequest:emptyNew()
    return Event.new(ProductivityChangeRequest_mt)
end

function ProductivityRequest.new(uniqueId, productionId, productivity)
    if debug > 0 then print("-- ProductivityChangeRequest.new()") end
    local self = ProductivityRequest:emptyNew()
    self.uniqueId = uniqueId 
    self.productionId = productionId
    self.productivity = productivity
    return self
end

function ProductivityRequest:writeStream(streamId)
    if debug > 0 then print("-- ProductivityChangeRequest.writeStream()") end
    streamWriteString(streamId, self.uniqueId)
    streamWriteString(streamId, self.productionId)
    streamWriteInt32(streamId, self.productivity)
end

function ProductivityRequest:readStream(streamId, connection)
    if debug > 0 then print("-- ProductivityChangeRequest.readStream()") end
    self.uniqueId = streamReadString(streamId)
    self.productionId = streamReadString(streamId)
    self.productivity = streamReadInt32(streamId)
    self:run(connection)
end

function ProductivityRequest:run(connection)
    if debug > 0 then print("-- ProductivityChangeRequest.run(connection)") end
    if g_server ~= nil then
        ProductionControl.RecalculateProductionPointFromOnServer(self.uniqueId, self.productionId, self.productivity)
    end
end

function ProductivityRequest.sendEvent(uniqueId, productionId, productivity)
    if debug > 0 then print("-- ProductivityChangeRequest.sendEvent()") end
    g_client:getServerConnection():sendEvent(ProductivityRequest.new(uniqueId, productionId, productivity))
end