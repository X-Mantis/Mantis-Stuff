local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer :: Player
local character= player.Character or player.CharacterAdded:Wait()

local rootPart:Part = character:WaitForChild("HumanoidRootPart") :: Part

local tweenEvent = ReplicatedStorage.Events.RemoteEvents.Tween --//Or whatever remote your have brap

player.CharacterAdded:Connect(function(newCharacter)
	rootPart = newCharacter:WaitForChild("HumanoidRootPart") :: Part
end)


local function Tween(instance:Instance?, tweenInfo:{any}, properties:{[string]:any})
	if instance == nil then return end
	if rootPart == nil then return end
	
	if instance:IsA("BasePart") then
		if (instance.Position - rootPart.Position).Magnitude > 40 then return end 
	end
	
	local tween = TweenService:Create(instance, TweenInfo.new(table.unpack(tweenInfo)),properties)
	
	tween.Completed:Once(function()
		tween:Destroy()
	end)
	
	tween:Play()
end

tweenEvent.OnClientEvent:Connect(Tween)
