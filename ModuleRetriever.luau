local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleRetriever = {}
ModuleRetriever.__index = ModuleRetriever

--[=[
    Binds a metatable to the shared global table which uses the "__call"
    metamethod to effectively turn it into a function that can retrieve a module by name.
]=]

function ModuleRetriever.new()
	setmetatable(shared, ModuleRetriever)

	shared.ranMain = {} -- modules which have already had their Main() function ran
end

function ModuleRetriever:__call(moduleName)
	local loadedModule = nil
	
	if RunService:IsServer() == true then
		loadedModule = require(assert(ReplicatedStorage.SharedModules:FindFirstChild(moduleName) or ServerStorage.ServerModules:FindFirstChild(moduleName), string.format("%q is not available. Please create this module and make sure it is placed in a valid path.", moduleName)))	
	else
		loadedModule = require(assert(ReplicatedStorage.SharedModules:FindFirstChild(moduleName) or ReplicatedStorage.ClientModules:FindFirstChild(moduleName), string.format("%q is not available. Please create this module and make sure it is placed in a valid path.", moduleName)))
	end
	
	local hasMainFunction = type(loadedModule) == "table"
		and type(loadedModule.Main) == "function" 
		and not self.ranMain[loadedModule]
		and type(loadedModule.new) ~= "function"
	
	if hasMainFunction == true then
		self:callFunctionNoYield(loadedModule, "Main")
		self.ranMain[loadedModule] = true
	end
	
	return loadedModule
end

function ModuleRetriever:callFunctionNoYield(loadedModule, functionName, ...)
	local args = ...
	local current
	task.spawn(function()
		debug.setmemorycategory(functionName)
		current = coroutine.running()
		loadedModule[functionName](loadedModule, args)
	end)

	local isDead = coroutine.status(current) == "dead"
	if not isDead then
		error(`A function named "{functionName}" has yielded while being retrieved.`)
	end
end

return ModuleRetriever
