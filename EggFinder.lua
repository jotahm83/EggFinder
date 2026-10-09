
-- EGG FINDER V14
-- BUSCADOR DE TEXTOS DE HUEVOS

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.42, 0, 0.68, 0)
frame.Position = UDim2.new(0.55, 0, 0.16, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
title.TextColor3 = Color3.fromRGB(0, 255, 120)
title.Text = "EGG FINDER V14"
title.TextSize = 16
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -35, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "X"
close.TextSize = 20
close.Parent = frame

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 1000)
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1, -12, 0, 1000)
output.BackgroundTransparency = 1
output.TextColor3 = Color3.fromRGB(0, 255, 120)
output.TextSize = 12
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.Text = "Buscando textos..."
output.Parent = scroll

local lines = {"EGG FINDER V14", ""}
local matches = 0
local inspected = 0

local keywords = {
    "secret", "secreto",
    "eternal", "eterno",
    "divine", "divino",
    "/s", "/sec",
    "b/s", "m/s",
    "egg", "huevo"
}

local function add(s)
    table.insert(lines, tostring(s))
end

local function interesting(text)
    local lower = string.lower(text)

    for _, word in ipairs(keywords) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end

    return false
end

local ok, err = pcall(function()
    for _, root in ipairs({
        workspace,
        pg
    }) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextLabel")
                or obj:IsA("TextButton") then

                inspected = inspected + 1

                local text = obj.Text

                if text ~= ""
                    and interesting(text) then

                    matches = matches + 1

                    if matches <= 60 then
                        add("[" .. matches .. "] " .. text)
                        add("Objeto: " .. obj.Name)
                        add("Ruta: " .. obj.Parent.Name)
                        add("")
                    end
                end
            end
        end
    end

    add("----------------")
    add("Textos revisados: " .. inspected)
    add("Coincidencias: " .. matches)
end)

if not ok then
    add("ERROR: " .. tostring(err))
end

output.Text = table.concat(lines, "\n")

local height = math.max(1000, #lines * 45)
output.Size = UDim2.new(1, -12, 0, height)
scroll.CanvasSize = UDim2.new(0, 0, 0, height + 30)
