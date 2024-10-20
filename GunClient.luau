local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Link = shared("Link")
local Maid = shared("Maid")
local Crosshair = shared("Crosshair")
local GunControl = shared("GunControl")
local ParticleUtils = shared("ParticleUtils")
local AnimationUtils = shared("AnimationUtils")
local GunFirstPerson = shared("GunFirstPerson")
local PerspectiveServiceClient = shared("PerspectiveServiceClient")

local GunClient = {}
GunClient.__index = GunClient

-- TODO: public IsADS() function in GunControl.lua
-- TODO: stop gun animations on destroy

function GunClient.new(gun)
	local self = setmetatable({}, GunClient)
	
	-- setting gun attribute(s) early so that GetAttributeChangedSignal can be connected without worrying about the attribute not existing
	self.gun = gun
	self.gun:SetAttribute("IsADS", false)
	
	self.maid = Maid.new()
	
	self.maid:GiveTask(self.gun.Equipped:Connect(function()
		if Players:GetPlayerFromCharacter(self.gun.Parent) == Players.LocalPlayer then
			self:onGunEquipped()
		end
		
		self.maid.listenForUnequip = self.gun.Unequipped:Connect(function()
			self:onGunUnequipped()
		end)
	end))
	
	return self
end

function GunClient:Destroy()
	self.maid:DoCleaning()
	
	UserInputService.MouseIconEnabled = true
	workspace.CurrentCamera.FieldOfView = 70
	
	-- TODO: find better solution?
	local animator = AnimationUtils.getOrCreateAnimator(Players.LocalPlayer)
	AnimationUtils.stopAnimation(animator, 18988901560) -- IDLE
end

function GunClient:Shoot(toggle)
	if toggle == true then
		ParticleUtils.gunShotEffect(self.gun)
		ReplicatedStorage.Events.RequestShootGun(self.gun)
	end
end

function GunClient:ToggleADS(toggle)
	-- making it public whether or not the player holding the gun is ADS
	self.gun:SetAttribute("IsADS", toggle)
end

function GunClient:onGunEquipped()	
	if PerspectiveServiceClient:IsFirstPerson(self.gun.Parent) then
		self:onFirstPerson()
	else
		-- giving them a crosshair when they equip the gun as long as they aren't first person
		self.maid.crosshair = Crosshair.new()
		self.maid.crosshair:SetSpread(7)
	end
	
	self.maid.perspectiveChanged = PerspectiveServiceClient:PerspectiveChanged(self.gun.Parent):Connect(function()
		if PerspectiveServiceClient:IsFirstPerson(self.gun.Parent) then
			self:onFirstPerson()
		else
			self:onThirdPerson()
		end
	end)
	
	self.maid.gunControl = GunControl.new(self)
	
	local animator = AnimationUtils.getOrCreateAnimator(Players.LocalPlayer)
	AnimationUtils.playAnimation(animator, 18988913494) -- EQUIP 
	AnimationUtils.playAnimation(animator, 18988901560) -- IDLE
	
	UserInputService.MouseIconEnabled = false
end

function GunClient:onGunUnequipped()
	-- destroying connections
	self.maid.listenForUnequip = nil
	self.maid.perspectiveChanged = nil
	self.maid.gunFirstPerson = nil
	self.maid.gunControl = nil
	self.maid.crosshair = nil
	
	local animator = AnimationUtils.getOrCreateAnimator(Players.LocalPlayer)
	AnimationUtils.stopAnimation(animator, 18988913494) -- EQUIP 
	AnimationUtils.stopAnimation(animator, 18988901560) -- IDLE
	
	UserInputService.MouseIconEnabled = true
end

-- perspective changes

function GunClient:onFirstPerson()
	self.maid.gunFirstPerson = GunFirstPerson.new(self.gun.Parent, self.gun)
	self.maid.crosshair = nil
end

function GunClient:onThirdPerson()
	self.maid.gunFirstPerson = nil
	self.maid.crosshair = Crosshair.new()
	self.maid.crosshair:SetSpread(7)
end

return Link.new("Gun", GunClient)
