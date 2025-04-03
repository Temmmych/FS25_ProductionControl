--[[
-- @Name: Production Control
-- @Version: 1.0.0.0
-- @Date: 01.04.2025
-- @Author: Temmmych
--]]

local modDirectory = g_currentModDirectory

source(modDirectory .. "scripts/events/ProductivityChangeRequest.lua")
source(modDirectory .. "scripts/events/ProductivityChange.lua")
source(modDirectory .. "scripts/ProductionControl.lua")