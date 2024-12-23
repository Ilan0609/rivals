local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Variables Globales
local Holding = false
local MenuVisible = true

_G.AimbotEnabled = true
_G.ESPEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"  -- Cibler la tête
_G.Sensitivity = 0.1

-- Définir la distance maximale de l'aimbot
_G.AimbotMaxDistance = 350

-- FOV - Champ de vision
_G.CircleRadius = 200
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

-- Création du cercle FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

-- Fonction pour obtenir la distance entre deux points en mètres
local function GetDistanceInMeters(p1, p2)
    return (p1 - p2).Magnitude
end

-- Fonction pour vérifier si un joueur est dans le cercle FOV
local function IsInFOV(target)
    local screenPoint = Camera:WorldToScreenPoint(target)
    local distance = (Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
    return distance <= _G.CircleRadius
end

local function GetClosestPlayer()
    local MaximumDistance = _G.AimbotMaxDistance
    local Target = nil

    for _, v in next, Players:GetPlayers() do
        if v.Name ~= LocalPlayer.Name then
            if _G.TeamCheck == true and v.Team == LocalPlayer.Team then
                continue
            end
            if v.Character ~= nil and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid").Health > 0 then
                local Distance = GetDistanceInMeters(LocalPlayer.Character.HumanoidRootPart.Position, v.Character.HumanoidRootPart.Position)
                
                if Distance <= _G.AimbotMaxDistance then
                    if IsInFOV(v.Character[_G.AimPart]) then
                        Target = v
                    end
                end
            end
        end
    end

    return Target
end

UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- Mettre à jour la position et le rayon du cercle FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    -- Si on maintient le clic droit et que l'aimbot est activé
    if Holding and _G.AimbotEnabled then
        local Target = GetClosestPlayer()
        if Target and Target.Character:FindFirstChild(_G.AimPart) then
            -- Calculer la direction vers la tête du joueur
            local TargetPosition = Target.Character[_G.AimPart].Position
            local CameraPosition = Camera.CFrame.Position

            -- Calculer la direction vers la cible
            local DirectionToTarget = (TargetPosition - CameraPosition).Unit  -- Normaliser le vecteur de direction
            local CameraLookAt = Camera.CFrame.LookVector  -- Vecteur de direction de la caméra

            -- Appliquer une interpolation pour rendre le mouvement plus fluide
            local NewCFrame = CFrame.lookAt(CameraPosition, TargetPosition)

            -- Utilisation d'un Tween pour rendre la transition de la caméra plus douce
            local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local goal = {CFrame = NewCFrame}
            local tween = TweenService:Create(Camera, tweenInfo, goal)
            tween:Play()
        end
    end
end)

-- ESP Fonctionnalités (si nécessaire)
local function createHighlight(target)
    if target:FindFirstChild("Highlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight"
    highlight.Adornee = target
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = target
end

local function highlightPlayers()
    if not _G.ESPEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            createHighlight(player.Character)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if _G.ESPEnabled then
            createHighlight(character)
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if _G.ESPEnabled then
        highlightPlayers()
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Highlight") then
                player.Character.Highlight:Destroy()
            end
        end
    end
end)

-- Création du menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Enabled = MenuVisible

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 200)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true -- Rendre le menu déplaçable

local AimbotButton = Instance.new("TextButton")
AimbotButton.Size = UDim2.new(1, 0, 0, 30)
AimbotButton.Position = UDim2.new(0, 0, 0, 0)
AimbotButton.Text = "Toggle Aimbot"
AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimbotButton.TextColor3 = Color3.new(1, 1, 1)
AimbotButton.Parent = Frame

local ESPButton = Instance.new("TextButton")
ESPButton.Size = UDim2.new(1, 0, 0, 30)
ESPButton.Position = UDim2.new(0, 0, 0, 40)
ESPButton.Text = "Toggle ESP"
ESPButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ESPButton.TextColor3 = Color3.new(1, 1, 1)
ESPButton.Parent = Frame

local FOVSlider = Instance.new("TextBox")
FOVSlider.Size = UDim2.new(1, 0, 0, 30)
FOVSlider.Position = UDim2.new(0, 0, 0, 80)
FOVSlider.Text = tostring(_G.CircleRadius)
FOVSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FOVSlider.TextColor3 = Color3.new(1, 1, 1)
FOVSlider.Parent = Frame

-- Bouton logique
AimbotButton.MouseButton1Click:Connect(function()
    _G.AimbotEnabled = not _G.AimbotEnabled
    AimbotButton.Text = "Toggle Aimbot (" .. tostring(_G.AimbotEnabled) .. ")"
end)

ESPButton.MouseButton1Click:Connect(function()
    _G.ESPEnabled = not _G.ESPEnabled
    ESPButton.Text = "Toggle ESP (" .. tostring(_G.ESPEnabled) .. ")"
end)

FOVSlider.FocusLost:Connect(function()
    local newValue = tonumber(FOVSlider.Text)
    if newValue then
        _G.CircleRadius = newValue
    else
        FOVSlider.Text = tostring(_G.CircleRadius)
    end
end)

-- Touche pour afficher/masquer le menu
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then -- Appuyez sur 'M' pour basculer
        MenuVisible = not MenuVisible
        ScreenGui.Enabled = MenuVisible
    end
end)
