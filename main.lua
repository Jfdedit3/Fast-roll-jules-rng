-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local CONFIG = {
    DELAY_BETWEEN_DELETES = 0.02,
    DELAY_BETWEEN_CHECKS = 0.1,
    RARITY_THRESHOLD = 20000, -- 1/20,000
    DELETE_AMOUNT = "6",
    DEBUG_MODE = true -- Mettre à true pour voir les logs de rareté
}

-- Liste des auras à supprimer automatiquement
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

-- Fonction pour créer l'interface utilisateur
local function createUI()
    local gui = Instance.new("ScreenGui")
    local frame = Instance.new("Frame")
    local statsLabel = Instance.new("TextLabel")
    local statusLabel = Instance.new("TextLabel")
    
    gui.Parent = game.CoreGui
    
    frame.Size = UDim2.new(0, 200, 0, 150)
    frame.Position = UDim2.new(1, -220, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.Parent = gui
    
    statsLabel.Size = UDim2.new(1, -10, 0.5, -5)
    statsLabel.Position = UDim2.new(0, 5, 0, 5)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = Color3.new(1, 1, 1)
    statsLabel.TextSize = 14
    statsLabel.Parent = frame
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    
    statusLabel.Size = UDim2.new(1, -10, 0.5, -5)
    statusLabel.Position = UDim2.new(0, 5, 0.5, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.TextSize = 14
    statusLabel.Parent = frame
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    
    return statsLabel, statusLabel
end

-- Variables de statistiques
local stats = {
    startTime = tick(),
    deletedCount = 0,
    lastAuraDeleted = "",
    acceptedCount = 0
}

-- Fonction pour accepter les nouvelles auras
local function acceptNewAuras()
    local aurasFolder = ReplicatedStorage:FindFirstChild("Auras")
    if aurasFolder then
        for _, aura in pairs(aurasFolder:GetChildren()) do
            if not table.find(AURAS_TO_DELETE, aura.Name) then
                stats.acceptedCount = stats.acceptedCount + 1
                if CONFIG.DEBUG_MODE then
                    print("Gardé:", aura.Name)
                end
            end
            pcall(function()
                ReplicatedStorage.Remotes.AcceptAura:FireServer(aura.Name, true)
            end)
            task.wait(0.02)
        end
    end
end

-- Fonction pour supprimer les auras indésirables
local function deleteUnwantedAuras()
    for _, auraName in ipairs(AURAS_TO_DELETE) do
        pcall(function()
            ReplicatedStorage.Remotes.DeleteAura:FireServer(auraName, CONFIG.DELETE_AMOUNT)
            stats.deletedCount = stats.deletedCount + 1
            stats.lastAuraDeleted = auraName
            if CONFIG.DEBUG_MODE then
                print("Supprimé:", auraName)
            end
        end)
        task.wait(CONFIG.DELAY_BETWEEN_DELETES)
    end
end

-- Fonction principale
local function main()
    local statsLabel, statusLabel = createUI()
    local iterationCount = 0
    
    -- Boucle principale
    while true do
        local success, err = pcall(function()
            -- Invoquer ZachRLL
            ReplicatedStorage.Remotes.ZachRLL:InvokeServer()
            
            -- Supprimer les auras indésirables
            deleteUnwantedAuras()
            
            -- Accepter les nouvelles auras
            acceptNewAuras()
            
            -- Mettre à jour l'interface
            local timeElapsed = math.floor(tick() - stats.startTime)
            statsLabel.Text = string.format(
                "Temps: %02d:%02d\nSupprimées: %d\nAcceptées: %d",
                timeElapsed / 60,
                timeElapsed % 60,
                stats.deletedCount,
                stats.acceptedCount
            )
            
            statusLabel.Text = string.format(
                "Dernière supprimée:\n%s\n\nSeuil: 1/%s",
                stats.lastAuraDeleted,
                string.format("%d", CONFIG.RARITY_THRESHOLD)
            )
        end)
        
        if not success and CONFIG.DEBUG_MODE then
            warn("Erreur:", err)
        end
        
        task.wait(CONFIG.DELAY_BETWEEN_CHECKS)
    end
end

-- Démarrage sécurisé
local success, err = pcall(function()
    print("Démarrage du script...")
    main()
end)

if not success then
    warn("Erreur fatale:", err)
end
