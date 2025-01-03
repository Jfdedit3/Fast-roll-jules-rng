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
    DEBUG_MODE = true -- Set to true to see rarity logs
}

-- List of auras to automatically delete
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

-- Function to create the user interface
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

-- Stats variables
local stats = {
    startTime = tick(),
    deletedCount = 0,
    lastAuraDeleted = "",
    acceptedCount = 0
}

-- Function to accept new auras
local function acceptNewAuras()
    local aurasFolder = ReplicatedStorage:FindFirstChild("Auras")
    if aurasFolder then
        for _, aura in pairs(aurasFolder:GetChildren()) do
            if not table.find(AURAS_TO_DELETE, aura.Name) then
                stats.acceptedCount = stats.acceptedCount + 1
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

-- Function to delete unwanted auras
local function deleteUnwantedAuras()
    for _, auraName in ipairs(AURAS_TO_DELETE) do
        pcall(function()
            ReplicatedStorage.Remotes.DeleteAura:FireServer(auraName, CONFIG.DELETE_AMOUNT)
            stats.deletedCount = stats.deletedCount + 1
            stats.lastAuraDeleted = auraName
            if CONFIG.DEBUG_MODE then
                print("Deleted:", auraName)
            end
        end)
        task.wait(CONFIG.DELAY_BETWEEN_DELETES)
    end
end

-- Main function
local function main()
    local statsLabel, statusLabel = createUI()
    local iterationCount = 0
    
    -- Main loop
    while true do
        local success, err = pcall(function()
            -- Invoke ZachRLL
            ReplicatedStorage.Remotes.ZachRLL:InvokeServer()
            
            -- Delete unwanted auras
            deleteUnwantedAuras()
            
            -- Accept new auras
            acceptNewAuras()
            
            -- Update the interface
            local timeElapsed = math.floor(tick() - stats.startTime)
            statsLabel.Text = string.format(
                "Time: %02d:%02d\nDeleted: %d\nAccepted: %d",
                timeElapsed / 60,
                timeElapsed % 60,
                stats.deletedCount,
                stats.acceptedCount
            )
            
            statusLabel.Text = string.format(
                "Last deleted:\n%s\n\nThreshold: 1/%s",
                stats.lastAuraDeleted,
                string.format("%d", CONFIG.RARITY_THRESHOLD)
            )
        end)
        
        if not success and CONFIG.DEBUG_MODE then
            warn("Error:", err)
        end
        
        task.wait(CONFIG.DELAY_BETWEEN_CHECKS)
    end
end

-- Safe start
local success, err = pcall(function()
    print("Starting script...")
    main()
end)

if not success then
    warn("Fatal error:", err)
end