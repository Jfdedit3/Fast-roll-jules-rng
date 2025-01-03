-- Services
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local COLORS = {
    PRIMARY = Color3.fromRGB(0, 230, 255),     -- Neon cyan
    SECONDARY = Color3.fromRGB(170, 0, 255),   -- Neon purple
    BACKGROUND = Color3.fromRGB(8, 10, 15),    -- Deep dark
    DARKER = Color3.fromRGB(12, 15, 22),       -- Darker shade
    TEXT = Color3.fromRGB(255, 255, 255),      -- White text
    ACCENT = Color3.fromRGB(0, 255, 157),      -- Neon green
    WARNING = Color3.fromRGB(255, 0, 98),      -- Neon pink
    GLOW = Color3.fromRGB(0, 230, 255)         -- Glow color
}

local TWEEN_INFO = {
    SHORT = TweenInfo.new(0.3, Enum.EasingStyle.Quint),
    LONG = TweenInfo.new(0.6, Enum.EasingStyle.Back),
    BOUNCE = TweenInfo.new(0.4, Enum.EasingStyle.Bounce)
}

local CONFIG = {
    DELAY_BETWEEN_DELETES = 0.02,
    DELAY_BETWEEN_CHECKS = 0.1,
    RARITY_THRESHOLD = 20000, -- 1/20,000
    DELETE_AMOUNT = "6",
    DEBUG_MODE = true -- Set to true to see rarity logs
}

-- Liste des auras à supprimer avec leur rareté
local AURAS_TO_DELETE = {
    "Heat", -- 1/100
    "Flames Curse", -- 1/500
    "Dark Matter", -- 1/1,000
    "Frigid", -- 1/2,500
    "Sorcerous", -- 1/5,000
    "Starstruck", -- 1/7,500
    "Voltage", -- 1/10,000
    "Constellar", -- 1/12,500
    "Iridescent", -- 1/15,000
    "Gale", -- 1/17,500
    "Shiver",
    "Bloom",
    "Fiend",
    "Tidal",
    "Flame",
    "Frost",
    "Antimatter",
    "Numerical",
    "Orbital",
    "Moonlit",
    "Glacial",
    "Prism",
    "Nebula",
    "Storm"
}

-- État global et statistiques
local State = {
    running = false,
    paused = false
}

local Stats = {
    startTime = tick(),
    deletedCount = 0,
    acceptedCount = 0,
    lastAuraDeleted = ""
}

-- Fonction pour créer l'interface
local function CreateInterface()
    -- Initialisation des variables de l'interface
    local interface = {}
    
    -- Création du ScreenGui principal
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AuraManager"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    -- Fonctions utilitaires pour l'interface
    local function CreateGlow(parent, intensity)
        local glow = Instance.new("ImageLabel")
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://131317109"
        glow.ImageColor3 = COLORS.GLOW
        glow.ImageTransparency = intensity or 0.85
        glow.Size = UDim2.new(1.5, 0, 1.5, 0)
        glow.Position = UDim2.new(-0.25, 0, -0.25, 0)
        glow.ZIndex = parent.ZIndex - 1
        glow.Parent = parent
        return glow
    end

    local function CreateCyberCorner(parent, size)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, size or 8)
        corner.Parent = parent
        return corner
    end

    local function CreateNeonStroke(parent, thickness)
        local stroke = Instance.new("UIStroke")
        stroke.Color = COLORS.PRIMARY
        stroke.Thickness = thickness or 2
        stroke.Parent = parent
        return stroke
    end

    -- Création du cadre principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0.75, 0, 0.7, 0)
    MainFrame.Position = UDim2.new(0.125, 0, 1.1, 0)
    MainFrame.BackgroundColor3 = COLORS.BACKGROUND
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    CreateCyberCorner(MainFrame, 12)
    CreateNeonStroke(MainFrame)
    CreateGlow(MainFrame)

    -- Création du motif d'arrière-plan
    local Pattern = Instance.new("ImageLabel")
    Pattern.Size = UDim2.new(1, 0, 1, 0)
    Pattern.BackgroundTransparency = 1
    Pattern.Image = "rbxassetid://6444378561"
    Pattern.ImageColor3 = COLORS.PRIMARY
    Pattern.ImageTransparency = 0.95
    Pattern.Parent = MainFrame

    -- Label des statistiques
    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    StatsLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.TextColor3 = COLORS.TEXT
    StatsLabel.TextSize = 14
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
    StatsLabel.Font = Enum.Font.Gotham
    StatsLabel.Text = "Stats: Initializing..."
    StatsLabel.Parent = MainFrame

    -- Fonction pour créer un bouton cyber
    local function CreateCyberButton(text, position, color)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.25, -10, 0.12, 0)
        button.Position = position
        button.BackgroundColor3 = color or COLORS.PRIMARY
        button.BackgroundTransparency = 0.9
        button.Text = text
        button.TextColor3 = color or COLORS.PRIMARY
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.AutoButtonColor = false
        button.Parent = MainFrame

        local buttonStroke = CreateNeonStroke(button, 1)
        buttonStroke.Color = color or COLORS.PRIMARY
        CreateCyberCorner(button, 6)
        
        local glowEffect = CreateGlow(button, 0.9)
        
        -- Effets de survol
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TWEEN_INFO.SHORT, {
                BackgroundTransparency = 0.7,
                TextSize = 15
            }):Play()
            TweenService:Create(buttonStroke, TWEEN_INFO.SHORT, {
                Thickness = 2
            }):Play()
            TweenService:Create(glowEffect, TWEEN_INFO.SHORT, {
                ImageTransparency = 0.7
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(button, TWEEN_INFO.SHORT, {
                BackgroundTransparency = 0.9,
                TextSize = 14
            }):Play()
            TweenService:Create(buttonStroke, TWEEN_INFO.SHORT, {
                Thickness = 1
            }):Play()
            TweenService:Create(glowEffect, TWEEN_INFO.SHORT, {
                ImageTransparency = 0.9
            }):Play()
        end)

        return button
    end

    -- Boutons d'action
    local startButton = CreateCyberButton("START", UDim2.new(0.73, 0, 0.05, 0), COLORS.ACCENT)
    local stopButton = CreateCyberButton("STOP", UDim2.new(0.73, 0, 0.2, 0), COLORS.WARNING)

    -- Bouton de basculement
    local ToggleButton = Instance.new("ImageButton")
    ToggleButton.Size = UDim2.new(0, 30, 0, 30)
    ToggleButton.Position = UDim2.new(0.5, -15, 0, 10)
    ToggleButton.BackgroundColor3 = COLORS.BACKGROUND
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = ScreenGui

    CreateCyberCorner(ToggleButton, UDim.new(0.5, 0))
    local toggleStroke = CreateNeonStroke(ToggleButton)
    CreateGlow(ToggleButton)

    -- Icône de flèche
    local Arrow = Instance.new("ImageLabel")
    Arrow.Size = UDim2.new(0.6, 0, 0.6, 0)
    Arrow.Position = UDim2.new(0.2, 0, 0.2, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Image = "rbxassetid://7072718412"
    Arrow.ImageColor3 = COLORS.PRIMARY
    Arrow.Parent = ToggleButton

    -- État de l'interface
    local isVisible = false

    -- Fonction de basculement de l'interface
    local function ToggleInterface()
        isVisible = not isVisible
        
        local targetPos = isVisible and 
            UDim2.new(0.125, 0, 0.15, 0) or 
            UDim2.new(0.125, 0, 1.1, 0)

        TweenService:Create(MainFrame, TWEEN_INFO.LONG, {
            Position = targetPos
        }):Play()

        TweenService:Create(Arrow, TWEEN_INFO.BOUNCE, {
            Rotation = isVisible and 180 or 0
        }):Play()

        local newColor = isVisible and COLORS.SECONDARY or COLORS.PRIMARY
        TweenService:Create(toggleStroke, TWEEN_INFO.SHORT, {
            Color = newColor
        }):Play()
        TweenService:Create(Arrow, TWEEN_INFO.SHORT, {
            ImageColor3 = newColor
        }):Play()
    end

    -- Configuration des boutons
    startButton.MouseButton1Click:Connect(function()
        State.running = true
    end)

    stopButton.MouseButton1Click:Connect(function()
        State.running = false
    end)

    ToggleButton.MouseButton1Click:Connect(ToggleInterface)

    -- Retourne l'interface
    interface.ScreenGui = ScreenGui
    interface.StatsLabel = StatsLabel
    return interface
end

-- Fonctions de gestion des auras
local function acceptNewAuras()
    local aurasFolder = ReplicatedStorage:FindFirstChild("Auras")
    if aurasFolder then
        for _, aura in pairs(aurasFolder:GetChildren()) do
            if not table.find(AURAS_TO_DELETE, aura.Name) then
                Stats.acceptedCount = Stats.acceptedCount + 1
                if CONFIG.DEBUG_MODE then
                    print("Kept:", aura.Name)
                end
            end
            pcall(function()
                ReplicatedStorage.Remotes.AcceptAura:FireServer(aura.Name, true)
            end)
            task.wait(0.02)
        end
    end
end

local function deleteUnwantedAuras()
    for _, auraName in ipairs(AURAS_TO_DELETE) do
        pcall(function()
            ReplicatedStorage.Remotes.DeleteAura:FireServer(auraName, CONFIG.DELETE_AMOUNT)
            Stats.deletedCount = Stats.deletedCount + 1
            Stats.lastAuraDeleted = auraName
            if CONFIG.DEBUG_MODE then
                print("Deleted:", auraName)
            end
        end)
        task.wait(CONFIG.DELAY_BETWEEN_DELETES)
    end
end

-- Boucle principale
local function main()
    local interface = CreateInterface()
    local StatsLabel = interface.StatsLabel
    
    while true do
        if State.running then
            local success, err = pcall(function()
                -- Invocation de ZachRLL
                ReplicatedStorage.Remotes.ZachRLL:InvokeServer()
                
                -- Suppression des auras indésirables
                deleteUnwantedAuras()
                
                -- Acceptation des nouvelles auras
                acceptNewAuras()
                
                -- Mise à jour de l'interface
                local timeElapsed = math.floor(tick() - Stats.startTime)
                StatsLabel.Text = string.format(
                    "Time: %02d:%02d\nDeleted: %d\nAccepted: %d\nLast Deleted: %s",
                    timeElapsed / 60,
                    timeElapsed % 60,
                    Stats.deletedCount,
                    Stats.acceptedCount,
                    Stats.lastAuraDeleted
                )
            end)
            
            if not success and CONFIG.DEBUG_MODE then
                warn("Error:", err)
            end
        end
        
        task.wait(CONFIG.DELAY_BETWEEN_CHECKS)
    end
end

-- Démarrage sécurisé
print("Starting script...")
local success, err = pcall(main)
if not success then
    warn("Fatal error:", err)
end