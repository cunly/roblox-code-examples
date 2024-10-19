--[[
	This modules allows you to declare actions (functions) to run when a player enters and exits the range of a BasePart.
	
	MaxDistanceActivation: The maximum distance for the player to be in range.
	RangeEnteredAction: The action that'll happen when the player enters the range.
	RangeExitedAction: The action that'll happen when the player exits the range.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Maid = shared("Maid")

local ProximityAction = {}
ProximityAction.__index = ProximityAction

function ProximityAction.new(player, basePart)
	assert(player:IsA("Player"), "ProximityAction argument #1 is not a Player.")
	assert(basePart:IsA("BasePart"), "ProximityAction argument #2 is not a BasePart.")

	local self = setmetatable({}, ProximityAction)
	
	-- public
	
	self.MaxDistanceActivation = 10
	
	self.RangeEnteredAction = nil
	self.RangeExitedAction = nil
	
	-- private
	
	self.player = player
	self.basePart = basePart
	
	self.maid = Maid.new()

	self.lastInRange = false
	
	self.maid:GiveTask(self.basePart.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:Destroy()
		end
	end))

	self.maid:GiveTask(RunService.Heartbeat:Connect(function()
		local character = self.player.Character
		if not character then
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			return
		end

		-- detects change between current "InRange" bool and "lastInRange" bool
		local inRange = (rootPart.Position - self.basePart.Position).Magnitude <= self.MaxDistanceActivation
		if inRange ~= self.lastInRange then
			if inRange == true then
				if self.RangeEnteredAction then
					task.spawn(self.RangeEnteredAction)
				end
			else
				if self.RangeExitedAction then
					task.spawn(self.RangeExitedAction)
				end
			end
		end

		self.lastInRange = inRange
	end))
	
	return self
end

function ProximityAction:Destroy()
	self.maid:DoCleaning()
end

return ProximityAction
