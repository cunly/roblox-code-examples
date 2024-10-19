local LERP_SPEED = 0.3 -- lower number = slower. higher number = faster

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Maid = shared("Maid")
local GridUtils = shared("GridUtils")
local PromiseInvokeServer = shared("PromiseInvokeServer")

local BuildServiceClient = {}

function BuildServiceClient:Main()
	self.maid = Maid.new()
	
	ReplicatedStorage.Events.StartBuildMode.OnClientEvent:Connect(function(model, platform)
		self:startBuildMode(model, platform)
	end)
	
	ReplicatedStorage.Events.StopBuildMode.OnClientEvent:Connect(function()
		self:stopBuildMode()
	end)
end

local function lerp(a, b, alpha)
	return a + alpha * (b - a)
end

function BuildServiceClient:startBuildMode(model, platform)
	-- init
	local modelClone = model:Clone()
	self.maid.modelClone = modelClone
	modelClone.Parent = workspace
	
	-- highlight
	local highlight = Instance.new("Highlight")
	highlight.Parent = modelClone
	highlight.FillColor = Color3.fromHex("#ff0000")
	
	self.maid.heartbeat = RunService.Heartbeat:Connect(function()
		local character = Players.LocalPlayer.Character

		-- end BuildMode if the character doesn't exist
		if not character then
			self.maid:DoCleaning()
			return
		end

		local mouse = Players.LocalPlayer:GetMouse()
		mouse.TargetFilter = modelClone

		local targetPosition = mouse.Hit.Position
		self.gridPosition = GridUtils.CalculatePlacement(modelClone, targetPosition, platform)
		local currentPos = modelClone.PrimaryPart.Position
		local smoothPosition = lerp(currentPos, self.gridPosition, LERP_SPEED)

		modelClone:SetPrimaryPartCFrame(CFrame.new(smoothPosition))
		
		-- TODO: add throttling and caching for improved performance?
		local isWithinPlatformBounds = GridUtils.IsWithinPlatformBounds(self.gridPosition, platform, model)
		
		if isWithinPlatformBounds then
			local isCollidingWithOtherObjects = GridUtils.IsCollidingWithOtherObjects(modelClone, self.gridPosition, platform)
			if isCollidingWithOtherObjects then
				highlight.FillColor = Color3.fromHex("#ff0000")
				return
			end
			
			highlight.FillColor = Color3.fromHex("#0099ff")
		else
			highlight.FillColor = Color3.fromHex("#ff0000")
		end
	end)

	ContextActionService:BindAction("PlaceModel", function(_, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then
			return
		end

		PromiseInvokeServer(ReplicatedStorage.Functions.RequestPlaceModel, model, self.gridPosition):Then(function(approved)
			if not approved then
				return
			end

			self:onApprovedPlaceModel()
		end)
	end, false, Enum.UserInputType.MouseButton1)
end

function BuildServiceClient:stopBuildMode()
	self.maid:DoCleaning()
end

function BuildServiceClient:onApprovedPlaceModel()
	self.maid:DoCleaning()
end

return BuildServiceClient
