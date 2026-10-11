local Players = game:GetService("Players")

local function createPlatform(player)
    local character = player.Character
        or player.CharacterAdded:Wait()

    local root = character:WaitForChild("HumanoidRootPart")

    local platform = Instance.new("Part")
    platform.Name = "SteepFlightPlatform"
    platform.Size = Vector3.new(8, 1, 10)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.Metal
    platform.Color = Color3.fromRGB(35, 120, 255)
    platform.CFrame = root.CFrame * CFrame.new(0, -3, 0)
    platform.Parent = workspace

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Subir"
    prompt.ObjectText = "Plataforma voladora"
    prompt.Parent = platform

    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer ~= player then
            return
        end

        local char = player.Character
        local humanoid = char
            and char:FindFirstChildOfClass("Humanoid")
        local hrp = char
            and char:FindFirstChild("HumanoidRootPart")

        if humanoid and hrp then
            hrp.CFrame = platform.CFrame * CFrame.new(0, 3, 0)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        createPlatform(player)
    end)
end)