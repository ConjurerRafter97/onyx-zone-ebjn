-- Pumpkin Playground utility script (source: rbxsc.com/pumpkin-playground-script/, Nov 21, 140 views)
-- Keyless, keybind-based: Q = Speed/Jump boost, E = Character Highlight

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

local function enhanceAbilities()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 45
        humanoid.JumpPower = 75
    end
end

local function createVisualAid()
    local highlight = Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(255, 140, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        enhanceAbilities()
    elseif input.KeyCode == Enum.KeyCode.E then
        createVisualAid()
    end
end)

print("Utility initialized. Press Q for Speed/Jump and E for Glow.")
