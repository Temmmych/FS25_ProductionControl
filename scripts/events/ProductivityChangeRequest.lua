--[[
-- @Name: Production Control
-- @Version: 1.0.0.0
-- @Date: 02.04.2025
-- @Author: Temmmych
--]]

local debug = 1

ProductivityChangeRequest = {}
local ProductivityChangeRequest_mt = Class(ProductivityChangeRequest, Event)
InitEventClass(ProductivityChangeRequest, "ProductivityChangeRequest")

function ProductivityChangeRequest:emptyNew()
    if debug > 0 then print("--//ProductivityChangeRequest:emptyNew()") end
    return Event.new(ProductivityChangeRequest_mt)
end

function ProductivityChangeRequest.new(uniqueId, productionId, productivity)
    if debug > 0 then print("-- ProductivityChangeRequest.new()") end
    local self = ProductivityChangeRequest:emptyNew()
    self.uniqueId = uniqueId 
    self.productionId = productionId
    self.productivity = productivity
    if debug > 1 then print("//ProductivityChangeRequest.new()") end
    return self
end

function ProductivityChangeRequest:writeStream(streamId)
    if debug > 0 then print("-- ProductivityChangeRequest.writeStream()") end
    streamWriteString(streamId, self.uniqueId)
    streamWriteString(streamId, self.productionId)
    streamWriteInt32(streamId, self.productivity)
    if debug > 1 then print("//ProductivityChangeRequest.writeStream()") end
end

function ProductivityChangeRequest:readStream(streamId, connection)
    if debug > 0 then print("-- ProductivityChangeRequest.readStream()") end
    self.uniqueId = streamReadString(streamId)
    self.productionId = streamReadString(streamId)
    self.productivity = streamReadInt32(streamId)
    self:run(connection)
    if debug > 1 then print("//ProductivityChangeRequest.readStream()") end
end

function ProductivityChangeRequest:run(connection)
    if debug > 0 then print("-- ProductivityChangeRequest.run(connection)") end
    if g_server ~= nil then
        if debug > 0 then print("-- g_server ~= nil") end
        ProductionControl.RecalculateProductionPointFromOnServer(self.uniqueId, self.productionId, self.productivity) -- пересчёт на сервере
    end
    if debug > 1 then print("//ProductivityChangeRequest.run(connection)") end
end

function ProductivityChangeRequest.sendEvent(uniqueId, productionId, productivity)
    if debug > 0 then print("-- ProductivityChangeRequest.sendEvent()") end
    g_client:getServerConnection():sendEvent(ProductivityChangeRequest.new(uniqueId, productionId, productivity)) -- сюда попадает только g_client
    if debug > 1 then print("//ProductivityChangeRequest.sendEvent()") end
end