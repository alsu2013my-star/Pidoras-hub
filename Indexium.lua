-- Indexium | TVman Tower Defense
-- Client-side input macro. It records mouse clicks and the E key (upgrade) only.
-- It does NOT call game remotes, modify coins, or guarantee game-specific automation.
-- Executor APIs (VirtualInputManager, gethui, readfile/writefile) may vary.

local TARGET_GAME_ID = 10773112151
if game.GameId ~= TARGET_GAME_ID then
    warn("[Indexium] Open TVman Tower Defense first. GameId: " .. tostring(game.GameId))
    return
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local FILE_NAME = "TVmanTowerDefense_macro.json"
local events = {}
local recording, playing, stopRequested = false, false, false
local autoReplay, autoExecute = false, false
local startedAt = 0
local heldKeys, heldMouse = {}, {}
local gui, panel, statusLabel, countLabel, hintLabel
local accent = Color3.fromRGB(174, 91, 255)

local function notify(msg)
    print("[Indexium] " .. tostring(msg))
end

local function elapsed()
    return math.max(0, os.clock() - startedAt)
end

local function setStatus(text, color)
    if statusLabel then
        statusLabel.Text = text
        statusLabel.TextColor3 = color or Color3.fromRGB(225, 215, 255)
    end
    if countLabel then countLabel.Text = tostring(#events) .. " actions" end
end

local function addEvent(kind, data)
    data.kind = kind
    data.t = elapsed()
    table.insert(events, data)
    if countLabel then countLabel.Text = tostring(#events) .. " actions" end
end

local function saveMacro()
    if type(writefile) ~= "function" then
        notify("Saving is unavailable in this executor; the recording remains in memory.")
        return false
    end
    local ok, err = pcall(function()
        writefile(FILE_NAME, HttpService:JSONEncode(events))
    end)
    if not ok then notify("Save failed: " .. tostring(err)); return false end
    notify("Saved: " .. FILE_NAME)
    return true
end

local function loadMacro()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then
        notify("Loading files is unavailable in this executor.")
        return false
    end
    local ok, result = pcall(function()
        if not isfile(FILE_NAME) then error("No saved recording found") end
        return HttpService:JSONDecode(readfile(FILE_NAME))
    end)
    if not ok or type(result) ~= "table" then
        notify("Could not load recording: " .. tostring(result))
        return false
    end
    events = result
    setStatus("Recording loaded")
    notify("Loaded " .. #events .. " actions.")
    return true
end

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.Parent = obj
end

local function makeLabel(parent, text, size, position, font, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = size
    l.Position = position
    l.Font = font or Enum.Font.Gotham
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(240, 235, 255)
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeButton(parent, text, position, size, color, callback)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(250, 247, 255)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 10)
    stroke(b, Color3.fromRGB(190, 145, 255), 1, 0.72)
    b.MouseButton1Click:Connect(callback)
    return b
end

gui = Instance.new("ScreenGui")
gui.Name = "IndexiumMacroUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parent
pcall(function()
    if type(gethui) == "function" then parent = gethui() end
end)
gui.Parent = parent or game:GetService("CoreGui")

panel = Instance.new("Frame")
panel.Name = "Main"
panel.Size = UDim2.fromOffset(430, 440)
panel.Position = UDim2.new(0, 28, 0.27, 0)
panel.BackgroundColor3 = Color3.fromRGB(15, 13, 27)
panel.Active = true
panel.Draggable = true
panel.Parent = gui
corner(panel, 16)
stroke(panel, accent, 2, 0.12)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 76)
top.BackgroundColor3 = Color3.fromRGB(39, 22, 65)
top.Parent = panel
corner(top, 15)

local title = makeLabel(top, "♛  INDEXIUM", UDim2.new(1, -65, 0, 34), UDim2.fromOffset(18, 9), Enum.Font.GothamBlack, Color3.fromRGB(221, 181, 255))
title.TextSize = 24
local subtitle = makeLabel(top, "TVman Tower Defense  •  PERSONAL MACRO", UDim2.new(1, -25, 0, 20), UDim2.fromOffset(20, 46), Enum.Font.Gotham, Color3.fromRGB(196, 178, 220))
subtitle.TextSize = 10

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -42, 0, 12)
close.BackgroundColor3 = Color3.fromRGB(87, 40, 115)
close.Text = "×"
close.TextColor3 = Color3.new(1,1,1)
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = top
corner(close, 8)
close.MouseButton1Click:Connect(function() gui.Enabled = false end)

local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, -28, 0, 43)
statusCard.Position = UDim2.fromOffset(14, 88)
statusCard.BackgroundColor3 = Color3.fromRGB(31, 26, 47)
statusCard.Parent = panel
corner(statusCard, 10)
statusLabel = makeLabel(statusCard, "●  READY — готов к записи", UDim2.new(0.72, 0, 1, 0), UDim2.fromOffset(12, 0), Enum.Font.GothamBold, Color3.fromRGB(123, 255, 184))
countLabel = makeLabel(statusCard, "0 actions", UDim2.new(0.25, -8, 1, 0), UDim2.new(0.75, 0, 0, 0), Enum.Font.GothamBold, Color3.fromRGB(204, 183, 255))
countLabel.TextXAlignment = Enum.TextXAlignment.Right

makeLabel(panel, "ЗАПИСЬ И ВОСПРОИЗВЕДЕНИЕ", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(16, 143), Enum.Font.GothamBold, Color3.fromRGB(190, 155, 235))

local buttonW = UDim2.new(0.5, -22, 0, 43)
local buttonH = UDim2.new(0.5, -22, 0, 43)
makeButton(panel, "●  RECORD", UDim2.fromOffset(14, 168), buttonW, Color3.fromRGB(126, 42, 83), function()
    if playing then return end
    events = {}
    heldKeys, heldMouse = {}, {}
    recording = true
    startedAt = os.clock()
    setStatus("●  RECORDING — идёт запись", Color3.fromRGB(255, 125, 160))
    if hintLabel then hintLabel.Text = "Выполняй действия в игре, затем нажми STOP + SAVE." end
end)

makeButton(panel, "■  STOP + SAVE", UDim2.new(0.5, 8, 0, 168), buttonH, Color3.fromRGB(83, 48, 128), function()
    if recording then
        local t = elapsed()
        for key, _ in pairs(heldKeys) do addEvent("keyUp", {key=key, t=t}) end
        for _, p in pairs(heldMouse) do addEvent("mouseUp", {x=p.x, y=p.y, t=t}) end
    end
    recording = false
    saveMacro()
    setStatus("✓  RECORDING SAVED", Color3.fromRGB(123, 255, 184))
    if hintLabel then hintLabel.Text = "Запись сохранена. Нажми LOAD, если загружаешь её позже, затем REPLAY." end
end)

makeButton(panel, "LOAD SAVED MACRO", UDim2.fromOffset(14, 220), buttonW, Color3.fromRGB(55, 55, 91), function()
    if loadMacro() then
        setStatus("✓  MACRO LOADED", Color3.fromRGB(123, 255, 184))
        if hintLabel then hintLabel.Text = "Запись загружена. Нажми REPLAY для запуска." end
    end
end)

local replayButton = makeButton(panel, "▶  REPLAY", UDim2.new(0.5, 8, 0, 220), buttonH, Color3.fromRGB(93, 48, 151), function()
    autoReplay = false
    if not playing and not recording and #events > 0 then
        stopRequested = false
        playing = true
        setStatus("▶  PLAYING — воспроизведение", Color3.fromRGB(194, 160, 255))
        task.spawn(function()
            local previous = 0
            for _, e in ipairs(events) do
                if stopRequested then break end
                local t = tonumber(e.t) or previous
                task.wait(math.max(0, t - previous))
                previous = t
                local ok, err = pcall(function()
                    if e.kind == "mouseDown" then
                        VIM:SendMouseButtonEvent(e.x, e.y, 0, true, game, 0)
                    elseif e.kind == "mouseUp" then
                        VIM:SendMouseButtonEvent(e.x, e.y, 0, false, game, 0)
                    elseif e.kind == "keyDown" and Enum.KeyCode[e.key] then
                        VIM:SendKeyEvent(true, Enum.KeyCode[e.key], false, game)
                    elseif e.kind == "keyUp" and Enum.KeyCode[e.key] then
                        VIM:SendKeyEvent(false, Enum.KeyCode[e.key], false, game)
                    end
                end)
                if not ok then notify("Playback error: " .. tostring(err)); break end
            end
            playing = false
            setStatus(stopRequested and "■  STOPPED" or "✓  PLAYBACK FINISHED")
            if autoReplay and not stopRequested then
                task.wait(2)
                if autoReplay and not stopRequested then replayButton:Activate() end
            end
        end)
    end
end)

local autoReplayButton = makeButton(panel, "AUTO REPLAY: OFF", UDim2.fromOffset(14, 272), buttonW, Color3.fromRGB(48, 46, 75), function()
    autoReplay = not autoReplay
    autoReplayButton.Text = "AUTO REPLAY: " .. (autoReplay and "ON" or "OFF")
    if autoReplay and not playing and not recording and #events > 0 then replayButton:Activate() end
end)

local autoExecuteButton = makeButton(panel, "AUTO EXECUTE: OFF", UDim2.new(0.5, 8, 0, 272), buttonH, Color3.fromRGB(48, 46, 75), function()
    autoExecute = not autoExecute
    autoExecuteButton.Text = "AUTO EXECUTE: " .. (autoExecute and "ON" or "OFF")
    if autoExecute then
        if loadMacro() and #events > 0 then replayButton:Activate() end
    end
end)

makeButton(panel, "■  STOP ALL", UDim2.fromOffset(14, 324), UDim2.new(1, -28, 0, 39), Color3.fromRGB(130, 35, 64), function()
    recording, autoReplay, autoExecute = false, false, false
    stopRequested = true
    autoReplayButton.Text = "AUTO REPLAY: OFF"
    autoExecuteButton.Text = "AUTO EXECUTE: OFF"
    setStatus("■  STOPPED", Color3.fromRGB(255, 135, 150))
    if hintLabel then hintLabel.Text = "Все действия остановлены." end
end)

local help = Instance.new("Frame")
help.Size = UDim2.new(1, -28, 0, 57)
help.Position = UDim2.fromOffset(14, 372)
help.BackgroundColor3 = Color3.fromRGB(28, 23, 42)
help.Parent = panel
corner(help, 9)
hintLabel = makeLabel(help, "Записывает клики мыши и E для прокачки. WASD и другие клавиши игнорируются.", UDim2.new(1, -18, 1, -8), UDim2.fromOffset(9, 4), Enum.Font.Gotham, Color3.fromRGB(211, 199, 231))
hintLabel.TextSize = 11
hintLabel.TextWrapped = true

local function inPanel(x, y)
    local p, s = panel.AbsolutePosition, panel.AbsoluteSize
    return x >= p.X and x <= p.X+s.X and y >= p.Y and y <= p.Y+s.Y
end

UIS.InputBegan:Connect(function(input, processed)
    if not recording or processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == "E" and not heldKeys[key] then
            heldKeys[key] = true
            addEvent("keyDown", {key=key})
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        local p = UIS:GetMouseLocation()
        if not inPanel(p.X, p.Y) then
            heldMouse.left = {x=p.X, y=p.Y}
            addEvent("mouseDown", {x=p.X, y=p.Y})
        end
    end
end)

UIS.InputEnded:Connect(function(input, processed)
    if not recording then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode.Name
        if key == "E" and heldKeys[key] then
            heldKeys[key] = nil
            addEvent("keyUp", {key=key})
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and heldMouse.left then
        local p = UIS:GetMouseLocation()
        heldMouse.left = nil
        addEvent("mouseUp", {x=p.X, y=p.Y})
    end
end)

setStatus("●  READY — готов к записи", Color3.fromRGB(123, 255, 184))
notify("Indexium UI loaded. Records mouse clicks + E upgrade key only. Test briefly first.")
