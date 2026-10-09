
-- EGG FINDER V12
-- DIAGNOSTICO DE OBJETOS

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(0.85, 0, 0.75, 0)
frame.Position = UDim2.new(0.075, 0, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.ScrollBarThickness = 8
frame.CanvasSize = UDim2.new(0, 0, 0, 2500)
frame.Parent = gui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 0, 2500)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(0, 255, 120)
label.Font = Enum.Font.Code
label.TextSize = 16
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = "EGG FINDER V12\nBuscando..."
label.Parent = frame

local paths = {
    {"Stands", "Models"},
    {"Stands", "Prompts"},
    {"Stands", "Pads"},
    {"World", "Areas"},
    {"World", "Machines"},
    {"Plots"},
    {"Eggs"}
}

local lines = {"EGG FINDER V12", ""}

local function add(s)
    table.insert(lines, s)
end

local ok, err = pcall(function()
    for _, path in ipairs(paths) do
        local obj = workspace
        local name = ""

        for _, part in ipairs(path) do
            name = name .. "/" .. part
            obj = obj and obj:FindFirstChild(part)
        end

        add("=== " .. name .. " ===")

        if obj then
            local children = obj:GetChildren()
            add("Total: " .. #children)

            for i = 1, math.min(#children, 15) do
                local child = children[i]
                add(child.Name .. " [" .. child.ClassName .. "]")
            end
        else
            add("No encontrada")
        end

        add("")
    end
end)

if not ok then
    add("ERROR: " .. tostring(err))
end

label.Text = table.concat(lines, "\n")
local height = math.max(2500, #lines * 22)
label.Size = UDim2.new(1, -20, 0, height)
frame.CanvasSize = UDim2.new(0, 0, 0, height + 40)
