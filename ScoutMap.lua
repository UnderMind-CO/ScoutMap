--[[ 
TreasureMap - A WoW Classic addon for TurtleWOW that shows treasure chests on the world map and minimap
]]

-- Initialize addon and local variables
local addonName, addon = ...
if not addonName then addonName = "TreasureMap" end

TreasureMap = {}
local TM = TreasureMap
TM.version = "1.0"
TM.chests = {}
TM.pins = {}
TM.miniPins = {}
TM.showOnWorldMap = true
TM.showOnMinimap = true
TM.minimapButtonPosition = 45 -- degrees

-- Database of known chest locations
-- Format: [zoneID] = { {x, y, name, respawnTime}, ... }
local treasureDB = {
    -- Elwynn Forest (ID: 1429)
    [1429] = {
        {32.3, 53.4, "Elwynn Forest Treasure Chest", 600},
        {41.2, 63.5, "Elwynn Forest Treasure Chest", 600},
        {61.8, 54.0, "Elwynn Forest Treasure Chest", 600},
        {75.9, 86.5, "Elwynn Forest Treasure Chest", 600}
    },
    -- Dun Morogh (ID: 1426)
    [1426] = {
        {25.6, 44.2, "Dun Morogh Treasure Chest", 600},
        {40.7, 65.1, "Dun Morogh Treasure Chest", 600},
        {53.2, 35.3, "Dun Morogh Treasure Chest", 600},
        {70.8, 56.7, "Dun Morogh Treasure Chest", 600}
    },
    -- Teldrassil (ID: 1438)
    [1438] = {
        {36.7, 55.8, "Teldrassil Treasure Chest", 600},
        {45.5, 58.6, "Teldrassil Treasure Chest", 600},
        {56.3, 61.4, "Teldrassil Treasure Chest", 600},
        {63.2, 75.2, "Teldrassil Treasure Chest", 600}
    },
    -- Darkshore (ID: 1439)
    [1439] = {
        {35.4, 47.6, "Darkshore Treasure Chest", 600},
        {41.8, 80.7, "Darkshore Treasure Chest", 600},
        {56.7, 13.5, "Darkshore Treasure Chest", 600},
        {61.4, 16.8, "Darkshore Treasure Chest", 600}
    },
    -- Mulgore (ID: 1412)
    [1412] = {
        {32.5, 52.8, "Mulgore Treasure Chest", 600},
        {39.2, 37.5, "Mulgore Treasure Chest", 600},
        {53.6, 14.7, "Mulgore Treasure Chest", 600},
        {60.3, 47.6, "Mulgore Treasure Chest", 600}
    },
    -- Barrens (ID: 1413)
    [1413] = {
        {41.5, 58.3, "Barrens Treasure Chest", 600},
        {52.3, 30.8, "Barrens Treasure Chest", 600},
        {56.2, 19.4, "Barrens Treasure Chest", 600},
        {62.7, 49.5, "Barrens Treasure Chest", 600},
        {48.7, 84.2, "Barrens Treasure Chest", 600}
    },
    -- Tirisfal Glades (ID: 1420)
    [1420] = {
        {25.8, 59.4, "Tirisfal Glades Treasure Chest", 600},
        {37.2, 42.1, "Tirisfal Glades Treasure Chest", 600},
        {51.7, 54.3, "Tirisfal Glades Treasure Chest", 600},
        {65.3, 42.0, "Tirisfal Glades Treasure Chest", 600}
    },
    -- Durotar (ID: 1411) 
    [1411] = {
        {37.2, 17.8, "Durotar Treasure Chest", 600},
        {53.1, 25.5, "Durotar Treasure Chest", 600},
        {51.7, 54.8, "Durotar Treasure Chest", 600},
        {67.2, 87.3, "Durotar Treasure Chest", 600}
    },
    -- Westfall (ID: 1436)
    [1436] = {
        {39.8, 19.6, "Westfall Treasure Chest", 600},
        {44.2, 69.5, "Westfall Treasure Chest", 600},
        {52.8, 53.7, "Westfall Treasure Chest", 600},
        {61.4, 19.3, "Westfall Treasure Chest", 600}
    },
    -- Loch Modan (ID: 1432)
    [1432] = {
        {35.5, 18.5, "Loch Modan Treasure Chest", 600},
        {47.6, 13.7, "Loch Modan Treasure Chest", 600},
        {70.8, 21.3, "Loch Modan Treasure Chest", 600},
        {73.5, 38.7, "Loch Modan Treasure Chest", 600}
    }
    -- Add more zones as needed
}

-- Format numbers to limit decimal places and avoid scientific notation
local function FormatCoord(coord)
    return format("%.1f", coord)
end

-- SlashCommand Handler
local function SlashCommandHandler(msg)
    if not msg or msg == "" then
        -- Toggle visibility of the configuration window
        if TM.optionsFrame and TM.optionsFrame:IsVisible() then
            TM.optionsFrame:Hide()
        else
            TM:ShowOptions()
        end
    elseif msg == "worldmap" then
        TM.showOnWorldMap = not TM.showOnWorldMap
        TM:Print("World map icons " .. (TM.showOnWorldMap and "enabled" or "disabled"))
        if WorldMapFrame:IsVisible() then
            TM:RefreshWorldMapIcons()
        end
    elseif msg == "minimap" then
        TM.showOnMinimap = not TM.showOnMinimap
        TM:Print("Minimap icons " .. (TM.showOnMinimap and "enabled" or "disabled"))
        TM:RefreshMinimapIcons()
    elseif msg == "reset" then
        TM:ResetDB()
        TM:Print("Database has been reset.")
    else
        TM:Print("TreasureMap commands:")
        TM:Print("  /tm - Toggle configuration")
        TM:Print("  /tm worldmap - Toggle world map icons")
        TM:Print("  /tm minimap - Toggle minimap icons")
        TM:Print("  /tm reset - Reset database")
    end
end

-- Slash Commands Registration
function TM:RegisterSlashCommands()
    SLASH_TREASUREMAP1 = "/treasuremap"
    SLASH_TREASUREMAP2 = "/tm"
    SlashCmdList["TREASUREMAP"] = SlashCommandHandler
end

-- Print function for debug and user messages
function TM:Print(msg)
    if msg then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00TreasureMap:|r " .. msg)
    end
end

-- Function to initialize the addon
function TM:Initialize()
    -- Initialize the saved variables if they don't exist
    if not TreasureMapDB then
        TreasureMapDB = {
            showOnWorldMap = true,
            showOnMinimap = true,
            minimapButtonPosition = 45,
            foundChests = {}
        }
    end
    
    -- Load settings from saved variables
    self.showOnWorldMap = TreasureMapDB.showOnWorldMap
    self.showOnMinimap = TreasureMapDB.showOnMinimap
    self.minimapButtonPosition = TreasureMapDB.minimapButtonPosition
    
    -- Load chest database
    for zoneID, chests in pairs(treasureDB) do
        if not self.chests[zoneID] then
            self.chests[zoneID] = {}
        end
        
        for _, chest in ipairs(chests) do
            table.insert(self.chests[zoneID], {
                x = chest[1], 
                y = chest[2], 
                name = chest[3], 
                respawnTime = chest[4],
                found = TreasureMapDB.foundChests[zoneID .. ":" .. chest[1] .. ":" .. chest[2]] or false
            })
        end
    end
    
    -- Register Events
    self:RegisterEvents()
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Create minimap button
    self:CreateMinimapButton()
    
    -- Print initialization message
    self:Print("v" .. self.version .. " loaded. Type /tm for options.")
end

-- Register Event Handlers
function TM:RegisterEvents()
    -- Create a frame for handling events
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("ADDON_LOADED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("WORLD_MAP_UPDATE")
    self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and arg1 == addonName then
            TM:Initialize()
        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            TM:RefreshMinimapIcons()
        elseif event == "WORLD_MAP_UPDATE" then
            TM:RefreshWorldMapIcons()
        end
    end)
end

-- Create a button for the minimap
function TM:CreateMinimapButton()
    -- Create minimap button frame
    local button = CreateFrame("Button", "TreasureMapMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    
    -- Set button texture
    button:SetNormalTexture("Interface\\AddOns\\TreasureMap\\MinimapButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Position the button around the minimap
    local radius = 80
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (radius * cos(self.minimapButtonPosition)), (radius * sin(self.minimapButtonPosition)) - 52)
    
    -- Make the button draggable
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function()
        button:StartMoving()
    end)
    
    button:SetScript("OnDragStop", function()
        button:StopMovingOrSizing()
        
        -- Calculate position
        local xpos, ypos = button:GetCenter()
        local xmin, ymin = Minimap:GetCenter()
        
        xpos = xpos - xmin
        ypos = ypos - ymin
        
        -- Calculate angle
        local angle = math.deg(math.atan2(ypos, xpos))
        if angle < 0 then angle = angle + 360 end
        
        -- Save position
        TM.minimapButtonPosition = angle
        TreasureMapDB.minimapButtonPosition = angle
        
        -- Update position
        local radius = 80
        button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (radius * cos(angle)), (radius * sin(angle)) - 52)
    end)
    
    -- Set up tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:AddLine("TreasureMap")
        GameTooltip:AddLine("Left-click: Toggle options", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Toggle minimap icons", 1, 1, 1)
        GameTooltip:AddLine("Shift+click: Toggle world map icons", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Set button click handlers
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            if IsShiftKeyDown() then
                TM.showOnWorldMap = not TM.showOnWorldMap
                TreasureMapDB.showOnWorldMap = TM.showOnWorldMap
                TM:Print("World map icons " .. (TM.showOnWorldMap and "enabled" or "disabled"))
                if WorldMapFrame:IsVisible() then
                    TM:RefreshWorldMapIcons()
                end
            else
                if TM.optionsFrame and TM.optionsFrame:IsVisible() then
                    TM.optionsFrame:Hide()
                else
                    TM:ShowOptions()
                end
            end
        elseif arg1 == "RightButton" then
            TM.showOnMinimap = not TM.showOnMinimap
            TreasureMapDB.showOnMinimap = TM.showOnMinimap
            TM:Print("Minimap icons " .. (TM.showOnMinimap and "enabled" or "disabled"))
            TM:RefreshMinimapIcons()
        end
    end)
    
    self.minimapButton = button
end

-- Function to reset the database to default values
function TM:ResetDB()
    TreasureMapDB = {
        showOnWorldMap = true,
        showOnMinimap = true,
        minimapButtonPosition = 45,
        foundChests = {}
    }
    
    -- Reload settings
    self.showOnWorldMap = TreasureMapDB.showOnWorldMap
    self.showOnMinimap = TreasureMapDB.showOnMinimap
    self.minimapButtonPosition = TreasureMapDB.minimapButtonPosition
    
    -- Reset found status on chest database
    for zoneID, chests in pairs(self.chests) do
        for _, chest in ipairs(chests) do
            chest.found = false
        end
    end
    
    -- Refresh displays
    self:RefreshWorldMapIcons()
    self:RefreshMinimapIcons()
end

-- Function to create or show the options window
function TM:ShowOptions()
    if not self.optionsFrame then
        -- Create the options window
        local frame = CreateFrame("Frame", "TreasureMapOptions", UIParent)
        frame:SetWidth(300)
        frame:SetHeight(200)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function() frame:StartMoving() end)
        frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
        
        -- Title
        local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOP", frame, "TOP", 0, -20)
        title:SetText("TreasureMap Options")
        
        -- World Map Checkbox
        local worldMapCheckbox = CreateFrame("CheckButton", "TreasureMapWorldMapCheckbox", frame, "UICheckButtonTemplate")
        worldMapCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -50)
        worldMapCheckbox:SetChecked(self.showOnWorldMap)
        getglobal(worldMapCheckbox:GetName() .. "Text"):SetText("Show on World Map")
        worldMapCheckbox:SetScript("OnClick", function()
            TM.showOnWorldMap = worldMapCheckbox:GetChecked()
            TreasureMapDB.showOnWorldMap = TM.showOnWorldMap
            TM:RefreshWorldMapIcons()
        end)
        
        -- Minimap Checkbox
        local minimapCheckbox = CreateFrame("CheckButton", "TreasureMapMinimapCheckbox", frame, "UICheckButtonTemplate")
        minimapCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -80)
        minimapCheckbox:SetChecked(self.showOnMinimap)
        getglobal(minimapCheckbox:GetName() .. "Text"):SetText("Show on Minimap")
        minimapCheckbox:SetScript("OnClick", function()
            TM.showOnMinimap = minimapCheckbox:GetChecked()
            TreasureMapDB.showOnMinimap = TM.showOnMinimap
            TM:RefreshMinimapIcons()
        end)
        
        -- Reset Button
        local resetButton = CreateFrame("Button", "TreasureMapResetButton", frame, "UIPanelButtonTemplate")
        resetButton:SetWidth(100)
        resetButton:SetHeight(25)
        resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
        resetButton:SetText("Reset Data")
        resetButton:SetScript("OnClick", function()
            StaticPopupDialogs["TREASUREMAP_RESET"] = {
                text = "Are you sure you want to reset your TreasureMap data?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    TM:ResetDB()
                    worldMapCheckbox:SetChecked(TM.showOnWorldMap)
                    minimapCheckbox:SetChecked(TM.showOnMinimap)
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true
            }
            StaticPopup_Show("TREASUREMAP_RESET")
        end)
        
        -- Close Button
        local closeButton = CreateFrame("Button", "TreasureMapCloseButton", frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        
        self.optionsFrame = frame
    end
    
    self.optionsFrame:Show()
end

-- Function to create World Map Icons
function TM:CreateWorldMapIcon(index, x, y, name, found)
    local pin = getglobal("TreasureMapPin" .. index)
    
    if not pin then
        pin = CreateFrame("Button", "TreasureMapPin" .. index, WorldMapFrame)
        pin:SetWidth(16)
        pin:SetHeight(16)
        pin:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 5)
        
        -- Set tooltip
        pin:SetScript("OnEnter", function()
            GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
            GameTooltip:AddLine(pin.name)
            GameTooltip:AddLine("Click to mark as " .. (pin.found and "not found" or "found"), 1, 1, 1)
            GameTooltip:Show()
        end)
        
        pin:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Mark chest as found/not found on click
        pin:SetScript("OnClick", function()
            pin.found = not pin.found
            
            -- Update database
            local key = pin.zoneID .. ":" .. pin.x .. ":" .. pin.y
            TreasureMapDB.foundChests[key] = pin.found
            
            -- Update chest in memory
            for _, chest in ipairs(TM.chests[pin.zoneID]) do
                if chest.x == pin.x and chest.y == pin.y then
                    chest.found = pin.found
                    break
                end
            end
            
            -- Update icon
            if pin.found then
                pin:SetNormalTexture("Interface\\AddOns\\TreasureMap\\ChestFound")
            else
                pin:SetNormalTexture("Interface\\AddOns\\TreasureMap\\ChestNotFound")
            end
            
            -- Update tooltip
            GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
            GameTooltip:AddLine(pin.name)
            GameTooltip:AddLine("Click to mark as " .. (pin.found and "not found" or "found"), 1, 1, 1)
            GameTooltip:Show()
            
            -- Refresh minimap icons
            TM:RefreshMinimapIcons()
        end)
    end
    
    pin.x = x
    pin.y = y
    pin.name = name
    pin.found = found
    pin.zoneID = GetCurrentMapZone()
    
    -- Calculate position
    local mapWidth = WorldMapFrame:GetWidth()
    local mapHeight = WorldMapFrame:GetHeight()
    local pinX = (x / 100) * mapWidth
    local pinY = (y / 100) * mapHeight
    
    pin:SetPoint("CENTER", WorldMapFrame, "TOPLEFT", pinX, -pinY)
    
    -- Set appearance based on found status
    if found then
        pin:SetNormalTexture("Interface\\AddOns\\TreasureMap\\ChestFound")
    else
        pin:SetNormalTexture("Interface\\AddOns\\TreasureMap\\ChestNotFound")
    end
    
    pin:Show()
    return pin
end

-- Function to refresh World Map Icons
function TM:RefreshWorldMapIcons()
    -- Hide all existing pins
    for _, pin in pairs(self.pins) do
        pin:Hide()
    end
    
    -- If disabled or no map showing, return
    if not self.showOnWorldMap or not WorldMapFrame:IsVisible() then
        return
    end
    
    -- Get current map zone
    local currentZone = GetCurrentMapZone()
    if not currentZone or not self.chests[currentZone] then
        return
    end
    
    -- Create pins for each chest
    local index = 1
    for _, chest in ipairs(self.chests[currentZone]) do
        local pin = self:CreateWorldMapIcon(index, chest.x, chest.y, chest.name, chest.found)
        self.pins[index] = pin
        index = index + 1
    end
end

-- Function to create Minimap Icons
function TM:CreateMinimapIcon(index, x, y, name, found)
    local pin = getglobal("TreasureMapMiniPin" .. index)
    
    if not pin then
        pin = CreateFrame("Button", "TreasureMapMiniPin" .. index, Minimap)
        pin:SetWidth(12)
        pin:SetHeight(12)
        pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
        
        -- Set tooltip
        pin:SetScript("OnEnter", function()
            GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
            GameTooltip:AddLine(pin.name)
            GameTooltip:AddLine("Coordinates: " .. FormatCoord(pin.x) .. ", " .. FormatCoord(pin.y), 1, 1, 1)
            GameTooltip:Show()
        end)
        
        pin:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    pin.x = x
    pin.y = y
    pin.name = name
    pin.found = found
    
    -- Get minimap size and player position
    local mmWidth = Minimap:GetWidth()
    local mmHeight = Minimap:GetHeight()
    local mapWidth = 100 -- Assuming map coordinates are 0-100
    local mapHeight = 100
    
    -- Get player position and calculate chest position relative to player
    local playerX, playerY = GetPlayerMapPosition("player")
    playerX = playerX * 100
    playerY = playerY * 100
    
    -- Calculate position and distance
    local deltaX = x - playerX
    local deltaY = y - playerY
    
    -- Scale to minimap size (adjust these values for your desired zoom level)
    local scale = 1.5
    deltaX = deltaX * (mmWidth / mapWidth) * scale
    deltaY = deltaY * (mmHeight / mapHeight) * scale
    
    -- Position on minimap
    pin:SetPoint("CENTER", Minimap, "CENTER", deltaX, -deltaY)
    
    -- Set appearance based on found status
    if found then
        pin:SetNormalTexture("Interface\\AddOns\\TreasureMap\\MiniChestFound")
    else
        pin:SetNormalTexture("Interface\\AddOns\\TreasureMap\\MiniChestNotFound")
    end
    
    -- Check if the pin is within minimap bounds
    local distance = sqrt(deltaX * deltaX + deltaY * deltaY)
    if distance < mmWidth / 2 then
        pin:Show()
    else
        pin:Hide()
    end
    
    return pin
end

-- Function to refresh Minimap Icons
function TM:RefreshMinimapIcons()
    -- Hide all existing pins
    for _, pin in pairs(self.miniPins) do
        pin:Hide()
    end
    
    -- If disabled, return
    if not self.showOnMinimap then
        return
    end
    
    -- Get current zone
    local currentZone = GetRealZoneText()
    local zoneID = nil
    
    -- Find zone ID based on name
    for id, chests in pairs(self.chests) do
        local zoneName = GetMapZoneInfo(id)
        if zoneName and zoneName == currentZone then
            zoneID = id
            break
        end
    end
    
    if not zoneID or not self.chests[zoneID] then
        return
    end
    
    -- Create pins for each chest
    local index = 1
    for _, chest in ipairs(self.chests[zoneID]) do
        local pin = self:CreateMinimapIcon(index, chest.x, chest.y, chest.name, chest.found)
        self.miniPins[index] = pin
        index = index + 1
    end
end

-- OnUpdate handler for minimap pins
local updateInterval = 0.2
local timeSinceLastUpdate = 0
local function OnUpdate(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= updateInterval then
        TM:RefreshMinimapIcons()
        timeSinceLastUpdate = 0
    end
end

-- Register the OnUpdate script to update minimap pins
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", OnUpdate)

-- Initialize if ADDON_LOADED has already fired
if IsAddOnLoaded(addonName) then
    TM:Initialize()
end