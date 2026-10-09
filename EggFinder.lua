
-- EGG FINDER V16
-- EXPLORADOR DE ZONAS Y DATOS INTERNOS

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
frame.Size = UDim2.new(0.43, 0, 0.7, 0)
frame.Position = UDim2.new(0.54, 0, 0.14, 0)
frame.BackgroundColor3 = Color3.fromRGB(15,15,25)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local function button(name, x, w, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(w,0,0,34)
    b.Position = UDim2.new(x,0,0,36)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Text = name
    b.Parent = frame
    return b
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-35,0,34)
title.BackgroundColor3 = Color3.fromRGB(35,35,55)
title.TextColor3 = Color3.fromRGB(0,255,120)
title.TextSize = 16
title.Text = "EGG FINDER V16"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0,35,0,34)
close.Position = UDim2.new(1,-35,0,0)
close.BackgroundColor3 = Color3.fromRGB(180,45,45)
close.TextColor3 = Color3.new(1,1,1)
close.Text = "X"
close.TextSize = 20
close.Parent = frame

local copy = button(
    "COPIAR TODO",0,0.49,
    Color3.fromRGB(25,110,65)
)

local refresh = button(
    "ACTUALIZAR",0.51,0.49,
    Color3.fromRGB(35,85,150)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-10,1,-80)
scroll.Position = UDim2.new(0,5,0,75)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0,0,0,1000)
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1,-12,0,1000)
output.BackgroundTransparency = 1
output.TextColor3 = Color3.fromRGB(0,255,120)
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.Text = "Preparando..."
output.Parent = scroll

local report = ""
local keywords = {
    "egg","huevo","spawn","pet","beast",
    "rarity","rare","secret","eternal",
    "divine","weight","money","income",
    "reward","drop","chance","animal"
}

local function relevant(s)
    s = string.lower(tostring(s))
    for _, word in ipairs(keywords) do
        if string.find(s,word,1,true) then
            return true
        end
    end
    return false
end

local function analyze()
    output.Text = "Analizando zonas..."
    local lines = {"EGG FINDER V16",""}
    local count = 0

    local function add(s)
        table.insert(lines,tostring(s))
    end

    local function inspect(obj)
        local found = relevant(obj.Name)
        local details = {}

        for key,value in pairs(obj:GetAttributes()) do
            table.insert(
                details,
                tostring(key).." = "..tostring(value)
            )
            if relevant(key) then found = true end
        end

        if obj:IsA("ValueBase") then
            local value = tostring(obj.Value)
            table.insert(details,"Value = "..value)
            if relevant(value) then found = true end
        end

        if found then
            count = count + 1

            if count <= 100 then
                add(obj.Name.." ["..obj.ClassName.."]")
                add("Ruta: "..obj:GetFullName())

                for i = 1, math.min(#details,8) do
                    add("  "..details[i])
                end

                add("")
            end
        end
    end

    local ok,err = pcall(function()
        local world = workspace:FindFirstChild("World")
        local areas = world and
            world:FindFirstChild("Areas")

        if not areas then
            add("No se encontro World.Areas")
            return
        end

        local zones = areas:GetChildren()
        add("Objetos en Areas: "..#zones)
        add("")

        for _,zone in ipairs(zones) do
            add("=== ZONA: "..zone.Name.." ===")

            local descendants = zone:GetDescendants()
            add("Objetos internos: "..#descendants)

            inspect(zone)

            for _,obj in ipairs(descendants) do
                inspect(obj)
            end

            add("")
        end
    end)

    if not ok then
        add("ERROR: "..tostring(err))
    end

    add("----------------------")
    add("Objetos relevantes: "..count)
    add("Mostrados: "..math.min(count,100))

    report = table.concat(lines,"\n")
    output.Text = report

    local height = math.max(1000,#lines*48)
    output.Size = UDim2.new(1,-12,0,height)
    scroll.CanvasSize = UDim2.new(0,0,0,height+30)
end

copy.MouseButton1Click:Connect(function()
    local fn = setclipboard or toclipboard

    if fn then
        local ok = pcall(function()
            fn(report)
        end)

        copy.Text = ok and
            "COPIADO!" or "ERROR"
    else
        copy.Text = "NO DISPONIBLE"
    end
end)

refresh.MouseButton1Click:Connect(function()
    copy.Text = "COPIAR TODO"
    task.spawn(analyze)
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

task.spawn(analyze)
