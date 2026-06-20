local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid:Humanoid = character:WaitForChild("Humanoid")
local backpack = player.Backpack

local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Unknown_Module = game:GetService("ReplicatedFirst"):FindFirstChildOfClass("ModuleScript")
local Sam_Module = require(Unknown_Module)

local sam = workspace.Ignore.NPCs.DailyQuest.Sam
local sam_root = sam:FindFirstChild("HumanoidRootPart")

local compass_ready_text = "Ready! (1/1)"
local sam_ready_label = player.PlayerGui.Menu.Frame.MenuList.Stats.Frame.A.Sam.SamTimer

local rare_drop_location = Vector3.new(-1125, 225, -1425)
local fruit_drop_location = Vector3.new(-1370, 227.5, -1410)

local fruit_triangulation_position_1 = Vector3.new(4900, 216, -7780)
local fruit_triangulation_position_2 = Vector3.new(-11360, 218, -2470)

local function Update_Character()
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")
end

local function Press(vk)
	task.wait(1/10)
	keypress(vk)
	keyrelease(vk)
	task.wait(1/10)
end

local function Drop_All_Items()
	for _, item in next, backpack:GetChildren() do
		if not item:IsA("Tool") then continue end

		pcall(function() 
			humanoid:EquipTool(item) 
			Press(0x08)
		end)		
	end
end

local function Insection_Point_2D(a_start, a_direction, b_start, b_direction)
	local dx = b_start.X - a_start.X
	local dy = b_start.Z - a_start.Z
	local det = b_direction.X * a_direction.Z - b_direction.Z * a_direction.X
	local u = (dy * b_direction.X - dx * b_direction.Z) / det
	return a_start + (a_direction * u)
end

local function Test_Location(location)
	local compass = character:FindFirstChildWhichIsA("Tool")
	if not compass then return end

	local needle = compass:FindFirstChild("CompassNeedle")
	if not needle then return end

	root.CFrame = CFrame.new(location)

	task.wait(1)
	VirtualInputManager:SendMouseButtonEvent(250, 250, 0, true, game, 1)
	task.wait(1)
	VirtualInputManager:SendMouseButtonEvent(250, 250, 0, false, game, 1)

	local start = needle.CFrame.Position
	local direction = ((needle.CFrame * CFrame.new(0, -2.5, 0)).Position - start) * Vector3.new(1, 0, 1)

	task.wait(1)
	return start, direction.Unit
end

local function Has_Compass()
	for _, tool in next, backpack:GetChildren() do
		if string.match(tool.Name, "Compass") and not tool:FindFirstChild("CompassNeedle") then return tool end
	end

	return
end

local function Solve_Compass()
	local a_start, a_direction = Test_Location(fruit_triangulation_position_1)
	local b_start, b_direction = Test_Location(fruit_triangulation_position_2)

	if not a_start or not b_start then return end
	local position = Insection_Point_2D(a_start, a_direction, b_start, b_direction)

	VirtualInputManager:SendMouseButtonEvent(250, 250, 0, true, game, 1)
	task.wait(1)
	root.CFrame = CFrame.new(position + Vector3.new(0, 500, 0))

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.MapFolder.Trees}

	local spawners = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(100, 1000, 100), params)
	for _, part in next, spawners do
		if part.Name ~= "Spawner" then continue end

		root.Anchored = false
		root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
		task.wait(1/2)
		humanoid.Jump = true
		task.wait(1/2)


		local compass = character:FindFirstChildWhichIsA("Tool")
		if not compass then break end
	end

	task.wait(0.1)
	VirtualInputManager:SendMouseButtonEvent(250, 250, 0, false, game, 1)

	local rare_drop_location = Vector3.new(-1125, 225, -1425)
	root.CFrame = CFrame.new(rare_drop_location, rare_drop_location + Vector3.new(0, 0, -3))
	
	Drop_All_Items()
end

local function Run_Sam(arg1, arg2)
	return Sam_Module["\t"](arg1, arg2)
end

local function Collect_Sam()
	if compass_ready_text ~= sam_ready_label.Text then return end
	
	Update_Character()
	if not character or not humanoid or humanoid.Health <= 0 then return end
	
	root.CFrame = CFrame.new(fruit_drop_location, fruit_drop_location + Vector3.new(0, 0, -3))
	task.wait(1/2)
	Drop_All_Items()
	task.wait(1/2)
	root.CFrame = sam_root.CFrame * CFrame.new(0, 0, -3)
	task.wait(1/2)
	
	Run_Sam("Sam", { "ClaimAmount", sam, 1 })
	
	local compass = backpack:WaitForChild("Compass", 10)
	if not compass then return end
	humanoid:UnequipTools()
	
	compass = Has_Compass()
	while compass do
		humanoid:EquipTool(compass)
		Solve_Compass()
		
		compass = Has_Compass()
	end
	
	task.wait(1/2)
end

local function Collect_Fruits()
	for _, tool:Tool in next, workspace.MapFolder.Fruits:GetChildren() do
		if not tool:IsA("Tool") then continue end

		root.CFrame = tool.Handle.CFrame * CFrame.new(0, 2, 0)
		task.wait(1/5)
	end
	
	root.CFrame = CFrame.new(fruit_drop_location, fruit_drop_location + Vector3.new(0, 0, -3))
	task.wait(1/2)
	Drop_All_Items()
	
	task.wait(1/2)
end

Collect_Fruits()
Collect_Sam()

