--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Zignal = require(ReplicatedStorage.Zignal)


type InternalHumanoid = {
	["MoveToFinished"]:Zignal.Signal<boolean>,
	read ["Root"]:Part,
	["AlignRotation"]:AlignOrientation,
	["Manager"]:ControllerManager,
	["_MoveConnect"]:RBXScriptConnection?,
	["_MoveAccumulator"]:number
}

type HumanoidFunction = {
	
	MoveTo: 	(HumanoidID:number, Location:Vector3) -> (),
	Destroy:	(HumanoidID:number) -> ()
}



local Humanoids:{[number]:InternalHumanoid?} = {}
local HumanoidFunction = {} ::HumanoidFunction




local function New(Model:Model)
	local ModelRoot = Model.PrimaryPart :: Part
	local newSignal = Zignal.new()
	
	
	local baseHumanoid: InternalHumanoid = {
		MoveToFinished = newSignal,
		Root = ModelRoot, 
		AlignRotation = ModelRoot:FindFirstChildOfClass("AlignOrientation"),
		Manager = Model:FindFirstChildOfClass("ControllerManager") :: ControllerManager,
		_MoveAccumulator = 0,
		_MoveConnect = nil
	} :: InternalHumanoid
	
	Humanoids[#Humanoids+1] = baseHumanoid

	return #Humanoids
end


local function GetMoveDirection(self: InternalHumanoid, target: Vector3): Vector3?
	local result = target - self.Root.Position

	if result.Magnitude <= 4 then
		return nil
	end
	
	return result.Unit
end

local function MoveTo(HumanoidID:number, Position:Vector3)
	local self = Humanoids[HumanoidID]
	
	if self == nil then return end
	
	if self._MoveConnect ~= nil then
		self._MoveConnect:Disconnect()
		self._MoveConnect = nil
	end

	if Position == Vector3.zero then

		self.Manager.MovingDirection =  Vector3.zero
		self.MoveToFinished:Fire(false)
		
		return

	end
	
	local TargetPosition = Position
	
	self._MoveAccumulator = 0
	
	self._MoveConnect = RunService.Heartbeat:Connect(function(deltaTime)
		
		self._MoveAccumulator += deltaTime
		
		if self._MoveAccumulator >= 8 then
			
			if self._MoveConnect then
				self._MoveConnect:Disconnect()
				self._MoveConnect = nil
			end
			self.MoveToFinished:Fire(false)
			
			return
		end
		
		local Direction = GetMoveDirection(self, TargetPosition)
		
		if Direction ~= nil then
			
			self.Manager.FacingDirection = Direction
			self.Manager.MovingDirection = Direction
			
		else

			self.Manager.MovingDirection = Vector3.zero
			
			if self._MoveConnect ~= nil then
				self._MoveConnect:Disconnect()
				self._MoveConnect = nil
			end
			
			self.MoveToFinished:Fire(true)
			
			return

		end

	end)

end

local function Destroy(HumanoidID:number)
	local FoundHumanoid = Humanoids[HumanoidID]
	if FoundHumanoid == nil then return end
	FoundHumanoid.MoveToFinished:DisconnectAll()
	Humanoids[HumanoidID] = nil
end

HumanoidFunction.MoveTo = MoveTo
HumanoidFunction.Destroy = Destroy

return New
