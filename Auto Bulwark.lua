local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local function noti(msg)

    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title =  "NiggerSploit",
        Text = msg,
        Duration = 5
    })
    

end

-- Connects to a tool's stance and reacts based on value
local function connectToTool(tool, char)
	if tool:IsA("Tool") and tool:FindFirstChild("Stance") then
		print("Character found with Tool")
		local PlrRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not PlrRoot then return end

		tool.Stance.Changed:Connect(function()
			local vRoot = char:FindFirstChild("HumanoidRootPart")
			if vRoot and (vRoot.Position - PlrRoot.Position).Magnitude < 17 then
				local stance = tool.Stance.Value
				if stance == "Release" then
					VirtualInputManager:SendKeyEvent(true, "R", false, game)
				elseif stance == "Parrying" then
					VirtualInputManager:SendKeyEvent(true, "E", false, game)
				elseif stance == "KickWindup" then
					VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
					task.wait(.6)
					VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
					elseif stance == "Riposte" then
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
					task.wait()
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
				
				end
			end
		end)
	end
end

local trackedWalls = {}

-- Toggles
local hitboxExpansionEnabled = true
local solidPartEnabled = true

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.H then
        hitboxExpansionEnabled = not hitboxExpansionEnabled
        noti("Hitbox Expansion " .. (hitboxExpansionEnabled and "Enabled" or "Disabled"))
    elseif input.KeyCode == Enum.KeyCode.P then
        solidPartEnabled = not solidPartEnabled
        noti("Solid Part " .. (solidPartEnabled and "Enabled" or "Disabled"))
    end
end)

local function clearHitboxes()
    -- Disconnect and destroy all tracked walls
    for _, data in ipairs(trackedWalls) do
        if data.conn then data.conn:Disconnect() end
        if data.wall and data.wall.Parent then
            data.wall:Destroy()
        end
    end
    trackedWalls = {}

    -- Remove highlights and reset HRP size/transparency on all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local hl = hrp:FindFirstChildOfClass("Highlight")
                if hl then hl:Destroy() end

                hrp.Size = Vector3.new(2, 2, 1) -- Default size
                hrp.Transparency = 0
            end
        end
    end
end

local function hitboxFunction()
    if not hitboxExpansionEnabled then
        return
    end

    clearHitboxes()

    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - myHRP.Position).Magnitude<= 35 then
                hrp.Size = Vector3.new(15, 5, 15)
                hrp.Transparency = 0.9

               if player ~= LocalPlayer and not hrp:FindFirstChildOfClass("Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.FillTransparency = 1
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = hrp
            end

                if solidPartEnabled and not char:FindFirstChild("SolidHitbox") then
                    local wall = Instance.new("Part")
                    wall.Name = "SolidHitbox"
                    wall.Size = Vector3.new(14, 5, 14)
                    wall.Anchored = true
                    wall.CanCollide = true
                    wall.Transparency = 1
                    wall.Massless = true
                    wall.Parent = char

                    local conn
                    conn = RunService.Heartbeat:Connect(function()
                        if char and hrp and wall and wall.Parent then
                            wall.CFrame = hrp.CFrame
                        else
                            if conn then conn:Disconnect() end
                        end
                    end)

                    table.insert(trackedWalls, {wall = wall, conn = conn})
                end
            end
        end
    end

    noti("[Hitbox]: Solid walls added. ESP applied.")
end

LocalPlayer.CharacterAdded:Connect(function()
    clearHitboxes()
end)



-- Scans all players except LocalPlayer and connects to their characters
local function runCode()
    hitboxFunction()
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= LocalPlayer then
			local function onCharacterAdded(char)
				-- Connect to existing tools
				for _, item in ipairs(char:GetChildren()) do
					connectToTool(item, char)
				end
				-- Watch for new tools
				char.ChildAdded:Connect(function(child)
					connectToTool(child, char)
				end)
			end

			if v.Character then
				onCharacterAdded(v.Character)
			end

			v.CharacterAdded:Connect(onCharacterAdded)
		end
	end
end

-- Detects when the local player equips a tool and starts logic
local function setupToolDetection()
	local function onEquipped()
		runCode()
	end

	local function connectToTool(tool)
		if tool:IsA("Tool") then
			tool.Equipped:Connect(onEquipped)
		end
	end

	local function onLocalCharacterAdded(character)
		for _, item in ipairs(character:GetChildren()) do
			connectToTool(item)
		end
		character.ChildAdded:Connect(connectToTool)
	end

	if LocalPlayer.Character then
		onLocalCharacterAdded(LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
end



local v1 = workspace.gameComponents.DuelQueueBoard.ClickDetector
local v2 = workspace.gameComponents.TeamFightQueueBoard.ClickDetector

local queued1v1 = false
local queuedTeamfight = false

-- Reset flags when character respawns (after duel)
LocalPlayer.CharacterAdded:Connect(function()
	queued1v1 = false
	queuedTeamfight = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.V then
		if not queued1v1 then
			noti("Queued up for 1v1")
			fireclickdetector(v1)
			queued1v1 = true
		else
			noti("Unqueued 1v1")
			fireclickdetector(v1)
			queued1v1 = false
		end

	elseif input.KeyCode == Enum.KeyCode.T then
		if not queuedTeamfight then
			noti("Queued up for Teamfight")
			fireclickdetector(v2)
			queuedTeamfight = true
		else
			noti("Unqueued Teamfight")
			fireclickdetector(v2)
			queuedTeamfight = false
		end
	end
end)




local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local brightLoop -- to store the connection

local function toggleFullBright()
    if brightLoop then
        brightLoop:Disconnect()
        brightLoop = nil
        noti("FullBright disabled")
    else
        local function brightFunc()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end

        brightLoop = RunService.RenderStepped:Connect(brightFunc)
        noti("FullBright enabled")
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        toggleFullBright()
    end
end)

local Lighting = game:GetService("Lighting")

local noFogEnabled = false

local function toggleNoFog()
    if noFogEnabled then
        -- Optionally, reset fog or atmosphere if you want (not in original code)
        noFogEnabled = false
        noti("NoFog disabled")
    else
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
        noFogEnabled = true
        noti("NoFog enabled")
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        toggleNoFog()
    end
end)



local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId
local JobId = game.JobId

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.J then
	noti("Rejoining...")
	task.wait(2)
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
        end
    end
end)


local HttpService = game:GetService("HttpService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.U then
        -- Serverhop logic
        local success, err = pcall(function()
            local servers = {}
            local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
            local body = HttpService:JSONDecode(req)

            if body and body.data then
                for _, v in ipairs(body.data) do
                    if typeof(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
                        table.insert(servers, v.id)
                    end
                end
            end

            if #servers > 0 then
                noti("ServerHopping...")
				task.wait(2)
                TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], Players.LocalPlayer)
            else
                noti("Serverhop: Couldn't find a server.")
            end
        end)

        if not success then
            warn("Serverhop failed: ", err)
            noti("Serverhop error occurred.")
        end
    end
end)




-- Start the script
setupToolDetection()