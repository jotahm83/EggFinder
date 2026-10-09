
-- EGG FINDER V17 - INSPECTOR DE NIDOS

local Players = game:GetService("Players")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.46,0,0.70,0)
frame.Position = UDim2.new(0.51,0,0.14,0)
frame.BackgroundColor3 = Color3.fromRGB(15,15,25)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-35,0,34)
title.BackgroundColor3 = Color3.fromRGB(35,35,55)
title.TextColor3 = Color3.fromRGB(0,255,120)
title.TextSize = 15
title.Text = "EGG FINDER V17 - NIDOS"
title.Parent = frame

local function makeButton(text,x,width,color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(width,0,0,34)
    b.Position = UDim2.new(x,0,0,36)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Text = text
    b.Parent = frame
    return b
end

local close = Instance.new("TextButton")
close.Size = UDim2.new(0,35,0,34)
close.Position = UDim2.new(1,-35,0,0)
close.BackgroundColor3 = Color3.fromRGB(170,40,40)
close.TextColor3 = Color3.new(1,1,1)
close.Text = "X"
close.Parent = frame

local copy = makeButton(
    "COPIAR TODO",0,0.49,
    Color3.fromRGB(25,110,65)
)

local refresh = makeButton(
    "ACTUALIZAR",0.51,0.49,
    Color3.fromRGB(35,85,150)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-10,1,-80)
scroll.Position = UDim2.new(0,5,0,75)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1,-12,0,1000)
output.BackgroundTransparency = 1
output.TextColor3 = Color3.fromRGB(0,255,120)
output.TextSize = 12
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.Text = "Analizando..."
output.Parent = scroll

local report = ""

local function analyze()
    local lines = {"EGG FINDER V17",""}
    local function add(s)
        table.insert(lines,tostring(s))
    end

    local ok,err = pcall(function()
        local areas = workspace
            :WaitForChild("World")
            :WaitForChild("Areas")
            :WaitForChild("GuardAreas")

        for _,zone in ipairs(areas:GetChildren()) do
            add("=== "..zone.Name.." ===")

            local nests = zone:FindFirstChild("Nests")
            if not nests then
                add("Sin carpeta Nests")
            else
                local models = nests:GetChildren()
                add("Nidos: "..#models)

                -- Revisar hasta 2 nidos por zona
                for i = 1,math.min(#models,2) do
                    local nest = models[i]
                    add("")
                    add("NIDO "..i)
                    add("Nombre: "..nest.Name)
                    add("Clase: "..nest.ClassName)

                    local objects = {nest}
                    for _,obj in ipairs(nest:GetDescendants()) do
                        table.insert(objects,obj)
                    end

                    add("Objetos: "..#objects)

                    -- Limitar detalles por nido
                    for j = 1,math.min(#objects,35) do
                        local obj = objects[j]

                        add("["..j.."] "
                            ..obj.Name.." ["
                            ..obj.ClassName.."]")

                        local attrs = obj:GetAttributes()
                        for key,value in pairs(attrs) do
                            add("  ATTR "..tostring(key)
                                .." = "..tostring(value))
                        end

                        if obj:IsA("ValueBase") then
                            add("  VALUE = "
                                ..tostring(obj.Value))
                        end

                        if obj:IsA("Model") then
                            local primary = obj.PrimaryPart
                            if primary then
                                add("  PrimaryPart: "
                                    ..primary.Name)
                            end
                        end
                    end
                end
            end
            add("")
        end
    end)

    if not ok then
        add("ERROR: "..tostring(err))
    end

    report = table.concat(lines,"\n")
    output.Text = report

    local height = math.max(1000,#lines*34)
    output.Size = UDim2.new(1,-12,0,height)
    scroll.CanvasSize = UDim2.new(
        0,0,0,height+40
    )
    scroll.CanvasPosition = Vector2.new(0,0)
end

copy.MouseButton1Click:Connect(function()
    local fn = setclipboard or toclipboard
    if fn then
        local ok = pcall(function()
            fn(report)
        end)
        copy.Text = ok and "COPIADO!" or "ERROR"
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

