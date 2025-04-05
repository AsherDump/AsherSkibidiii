getgenv()._4sh_lua = {
    ["Aimbot"] = {
        ["Prediction"] = { Horizontal = 0.1, Vertical = 0.1 },
        ["HitPart"] = "Head"
    },
    ["Resolver"] = {
        ["Enabled"] = true
    }
}

local ValidHitParts = {
    ["Head"] = true, ["UpperTorso"] = true, ["HumanoidRootPart"] = true, ["LowerTorso"] = true,
    ["LeftHand"] = true, ["RightHand"] = true, ["LeftLowerArm"] = true, ["RightLowerArm"] = true,
    ["LeftUpperArm"] = true, ["RightUpperArm"] = true, ["LeftFoot"] = true, ["LeftLowerLeg"] = true,
    ["LeftUpperLeg"] = true, ["RightLowerLeg"] = true, ["RightFoot"] = true, ["RightUpperLeg"] = true
}

local function getHitPart(character)
    local hitPart = _4sh_lua.Aimbot.HitPart
    if ValidHitParts[hitPart] and character:FindFirstChild(hitPart) then
        return character[hitPart]
    else
        return character:FindFirstChild("HumanoidRootPart")
    end
end

local ScreenGui = Instance.new("ScreenGui")
local CamlockButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

CamlockButton.Parent = ScreenGui
CamlockButton.Size = UDim2.new(0, 150, 0, 60)
CamlockButton.Position = UDim2.new(0.5, -75, 0.5, -30)
CamlockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CamlockButton.Font = Enum.Font.GothamBold
CamlockButton.TextSize = 18
CamlockButton.Text = "4sh.lua [Off]"
CamlockButton.TextColor3 = Color3.fromRGB(255, 0, 0)
CamlockButton.AutoButtonColor = false

UICorner.Parent = CamlockButton
UICorner.CornerRadius = UDim.new(0.3, 0)

-- Mouse + Touch draggable support
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    CamlockButton.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

CamlockButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = CamlockButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

CamlockButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

local camlockEnabled = false
local lockedPlayer = nil

local function getClosestToCrosshair()
    local closestTarget, closestDist = nil, math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local aimPart = getHitPart(v.Character)
            if aimPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestTarget = v
                    end
                end
            end
        end
    end

    return closestTarget
end

local previousPosition = nil
local previousTime = nil

local function NewVelocity(object)
    local currentPosition = object.Position
    local currentTime = tick()

    if previousPosition and previousTime then
        local deltaTime = currentTime - previousTime
        local velocity = (currentPosition - previousPosition) / deltaTime
        object.Velocity = velocity
    end

    previousPosition = currentPosition
    previousTime = currentTime
end

if _4sh_lua.Resolver.Enabled then
    RunService.Heartbeat:Connect(function()
        if lockedPlayer and lockedPlayer.Character then
            local targetPart = getHitPart(lockedPlayer.Character)
            if targetPart and targetPart.Velocity.magnitude > 0 then
                NewVelocity(targetPart)
            end
        end
    end)
end

local function lockOn(target)
    lockedPlayer = target
    while camlockEnabled and lockedPlayer and lockedPlayer.Character do
        local aimPart = getHitPart(lockedPlayer.Character)
        if aimPart then
            local prediction = Vector3.new(
                aimPart.Velocity.X * _4sh_lua.Aimbot.Prediction.Horizontal,
                aimPart.Velocity.Y * _4sh_lua.Aimbot.Prediction.Vertical,
                0
            )
            camera.CFrame = CFrame.new(camera.CFrame.Position, aimPart.Position + prediction)
        end
        task.wait()
    end
end

CamlockButton.MouseButton1Click:Connect(function()
    camlockEnabled = not camlockEnabled
    CamlockButton.Text = "4sh.lua [" .. (camlockEnabled and "On" or "Off") .. "]"

    if camlockEnabled then
        local target = getClosestToCrosshair()
        if target then
            lockOn(target)
            target.CharacterAdded:Connect(function()
                if camlockEnabled and lockedPlayer == target then
                    task.wait(0.5)
                    lockOn(target)
                end
            end)
        end
    end
end)