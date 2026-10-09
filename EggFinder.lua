
-- EGG FINDER V19
-- INSPECTOR DE HUEVOS COLOCADOS

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.46,0,0.7,0)
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
title.Text = "EGG FINDER V19"
title.Parent = frame

local function button(txt,x,w,color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(w,0,0,34)
    b.Position = UDim2.new(x,0,0,36)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Text = txt
    b.Parent = frame
    return b
end

local copy = button(
    "COPIAR TODO",0,0.49,
    Color3.fromRGB(25,110,65)
)

local refresh = button(
    "REINICIAR",0.51,0.49,
    Color3.fromRGB(35,85,150)
)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0,35,0,34)
close.Position = UDim2.new(1,-35,0,0)
close.BackgroundColor3 = Color3.fromRGB(170,40,40)
close.TextColor3 = Color3.new(1,1,1)
close.Text = "X"
close.Parent = frame

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
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextWrapped = true
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Parent = scroll

local lines = {}
local connections = {}
local runId = 0
local eventCount = 0

local function add(s)
    table.insert(lines,tostring(s))
end

local function redraw()
    output.Text = table.concat(lines,"\n")
    local h = math.max(1000,#lines*42)
    output.Size = UDim2.new(1,-12,0,h)
    scroll.CanvasSize = UDim2.new(0,0,0,h+30)
end

local function stop()
    runId = runId + 1
    for _,c in ipairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    connections = {}
end

local function describe(obj,indent)
    indent = indent or ""
    add(indent..obj.Name.." ["..obj.ClassName.."]")

    local attrs = obj:GetAttributes()
    local keys = {}

    for k in pairs(attrs) do
        table.insert(keys,k)
    end

    table.sort(keys)

    for _,k in ipairs(keys) do
        add(indent.."  ATTR "
            ..k.." = "..tostring(attrs[k]))
    end

    if obj:IsA("ValueBase") then
        local ok,value = pcall(function()
            return tostring(obj.Value)
        end)
        if ok then
            add(indent.."  VALUE = "..value)
        end
    end

    if obj:IsA("BasePart") then
        local p = obj.Position
        add(indent.."  POS = "
            ..math.floor(p.X)..","
            ..math.floor(p.Y)..","
            ..math.floor(p.Z))
    elseif obj:IsA("Model") then
        local ok,pivot = pcall(function()
            return obj:GetPivot().Position
        end)
        if ok then
            add(indent.."  PIVOT = "
                ..math.floor(pivot.X)..","
                ..math.floor(pivot.Y)..","
                ..math.floor(pivot.Z))
        end
    end
end

local function inspectEgg(obj)
    add("")
    add("=== HUEVO / MODELO ===")
    describe(obj)

    local descendants = obj:GetDescendants()
    add("Descendientes: "..#descendants)

    local shown = 0
    for _,child in ipairs(descendants) do
        if shown >= 45 then break end

        if child:IsA("Model")
            or child:IsA("ValueBase")
            or child:IsA("Folder")
            or child:IsA("BasePart")
            or next(child:GetAttributes()) ~= nil then

            shown = shown + 1
            describe(child,"  ")
        end
    end

    add("Detalles mostrados: "..shown)
end

local function start()
    stop()
    local thisRun = runId
    lines = {"EGG FINDER V19",""}
    eventCount = 0

    local ok,err = pcall(function()
        local root = workspace:FindFirstChild(
            "PlacedEggRenders"
        )

        add("FASE 1: PLACED EGG RENDERS")

        if not root then
            add("Carpeta no encontrada.")
        else
            local eggs = root:GetChildren()
            add("Objetos directos: "..#eggs)

            for i = 1,math.min(#eggs,8) do
                inspectEgg(eggs[i])
            end

            local c = root.ChildAdded:Connect(function(obj)
                if thisRun ~= runId then return end
                if eventCount >= 15 then return end

                eventCount = eventCount + 1
                add("")
                add("NUEVO OBJETO #"..eventCount)
                inspectEgg(obj)
                redraw()
            end)

            table.insert(connections,c)
        end

        add("")
        add("FASE 2: MODULOS IMPORTANTES")

        local paths = {
            {"Client","EggState"},
            {"Client","Notifications","RareSpawnText"},
            {"Data","MonsterEgg"},
            {"Data","Rarity"},
            {"Data","Rarity","Configs","Secret"},
            {"Data","Rarity","Configs","Eternal"},
            {"Data","Rarity","Configs","Divine"}
        }

        for _,path in ipairs(paths) do
            local obj = RS
            for _,name in ipairs(path) do
                obj = obj and obj:FindFirstChild(name)
            end

            if obj then
                add(obj:GetFullName())
                add("Clase: "..obj.ClassName)
                local attrs = obj:GetAttributes()
                for k,v in pairs(attrs) do
                    add("  "..tostring(k)
                        .." = "..tostring(v))
                end
            else
                add("NO ENCONTRADO: "
                    ..table.concat(path,"/"))
            end
        end

        add("")
        add("Monitoreando nuevos objetos 90s...")
    end)

    if not ok then
        add("ERROR: "..tostring(err))
    end

    redraw()

    task.delay(90,function()
        if thisRun ~= runId then return end
        add("")
        add("MONITOREO FINALIZADO")
        add("Nuevos objetos: "..eventCount)
        redraw()
        stop()
    end)
end

copy.MouseButton1Click:Connect(function()
    local fn = setclipboard or toclipboard

    if fn then
        local ok = pcall(function()
            fn(table.concat(lines,"\n"))
        end)
        copy.Text = ok and "COPIADO!" or "ERROR"
    else
        copy.Text = "NO DISPONIBLE"
    end
end)

refresh.MouseButton1Click:Connect(function()
    copy.Text = "COPIAR TODO"
    task.spawn(start)
end)

close.MouseButton1Click:Connect(function()
    stop()
    gui:Destroy()
end)

task.spawn(start)
