
-- EGG FINDER V13
-- VENTANA COMPACTA + EXPLORADOR DE PLOTS

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local box = Instance.new("Frame")
box.Size = UDim2.new(0.48, 0, 0.68, 0)
box.Position = UDim2.new(0.49, 0, 0.16, 0)
box.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
box.Active = true
box.Draggable = true
box.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
title.TextColor3 = Color3.fromRGB(0, 255, 120)
title.Text = "EGG FINDER V13"
title.TextSize = 16
title.Parent = box

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -35, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "X"
close.TextSize = 20
close.Parent = box

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 2500)
scroll.Parent = box

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1, -10, 0, 2500)
output.BackgroundTransparency = 1
output.TextColor3 = Color3.fromRGB(0, 255, 120)
output.TextSize = 12
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.Text = "Analizando bases..."
output.Parent = scroll

local lines = {"EGG FINDER V13", ""}

local function add(s)
    table.insert(lines, tostring(s))
end

local ok, err = pcall(function()
    local plots = workspace:FindFirstChild("Plots")

    if not plots then
        add("No existe Workspace.Plots")
        return
    end

    local bases = plots:GetChildren()
    add("Bases encontradas: " .. #bases)
    add("")

    for _, base in ipairs(bases) do
        add("=== BASE " .. base.Name .. " ===")

        local children = base:GetChildren()
        add("Objetos: " .. #children)

        for i = 1, math.min(#children, 25) do
            local obj = children[i]

            add(obj.Name .. " [" .. obj.ClassName .. "]")
        end

        add("")
    end
end)

if not ok then
    add("ERROR: " .. tostring(err))
end

output.Text = table.concat(lines, "\n")

local height = math.max(2500, #lines * 18)
output.Size = UDim2.new(1, -10, 0, height)
scroll.CanvasSize = UDim2.new(0, 0, 0, height + 20)

