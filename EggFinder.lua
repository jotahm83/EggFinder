
-- EGG FINDER V18
-- DATOS REPLICADOS Y OBJETOS DINAMICOS

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
title.Text = "EGG FINDER V18"
title.Parent = frame

local function makeButton(txt,x,w,color)
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

local copy = makeButton(
    "COPIAR TODO",0,0.49,
    Color3.fromRGB(25,110,65)
)

local refresh = makeButton(
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
local running = false
local generation = 0
local eventCount = 0
local maxEvents = 100

local keywords = {
    "egg","huevo","pet","beast",
    "animal","rarity","secret",
    "eternal","divine","weight",
    "income","reward","spawn",
    "hatch","monster","creature"
}

local function relevant(value)
    local s = string.lower(tostring(value))
    for _,word in ipairs(keywords) do
        if string.find(s,word,1,true) then
            return true
        end
    end
    return false
end

local function redraw()
    local report = table.concat(lines,"\n")
    output.Text = report
    local height = math.max(1000,#lines*38)
    output.Size = UDim2.new(1,-12,0,height)
    scroll.CanvasSize = UDim2.new(0,0,0,height+30)
end

local function add(s)
    table.insert(lines,tostring(s))
    redraw()
end

local function stop()
    running = false
    generation = generation + 1

    for _,c in ipairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    connections = {}
end

local function attributes(obj)
    local data = {}
    local ok,attrs = pcall(function()
        return obj:GetAttributes()
    end)

    if ok then
        for key,value in pairs(attrs) do
            table.insert(
                data,
                tostring(key).."="..tostring(value)
            )
        end
    end

    table.sort(data)
    return data
end

local function describe(obj)
    local result = obj:GetFullName()
        .." ["..obj.ClassName.."]"

    local attrs = attributes(obj)

    if #attrs > 0 then
        result = result
            .."\n  ATTR: "
            ..table.concat(attrs,", ")
    end

    if obj:IsA("ValueBase") then
        local ok,value = pcall(function()
            return tostring(obj.Value)
        end)

        if ok then
            result = result.."\n  VALUE: "..value
        end
    end

    return result
end

local function start()
    stop()
    running = true
    local thisRun = generation
    lines = {}
    eventCount = 0

    add("EGG FINDER V18")
    add("FASE 1: REPLICATED STORAGE")
    add("")

    local found = 0
    local inspected = 0

    for _,obj in ipairs(RS:GetDescendants()) do
        inspected = inspected + 1

        if relevant(obj.Name) then
            found = found + 1

            if found <= 100 then
                add(describe(obj))
                add("")
            end
        end
    end

    add("Objetos revisados: "..inspected)
    add("Coincidencias: "..found)
    add("")
    add("FASE 2: MONITOREO (90 SEGUNDOS)")
    add("Espera a que aparezcan huevos.")
    add("")

    local function logEvent(kind,obj)
        if not running or thisRun ~= generation then
            return
        end

        if eventCount >= maxEvents then
            return
        end

        eventCount = eventCount + 1

        add("["..eventCount.."] "..kind)
        add(describe(obj))
        add("")
    end

    local roots = {workspace,RS}

    for _,root in ipairs(roots) do
        local c = root.DescendantAdded:Connect(
            function(obj)
                if relevant(obj.Name) then
                    logEvent("OBJETO NUEVO",obj)
                end
            end
        )

        table.insert(connections,c)
    end

    -- Vigilar atributos de objetos relacionados
    -- que ya existen al iniciar la prueba.
    local watched = 0

    for _,root in ipairs(roots) do
        for _,obj in ipairs(root:GetDescendants()) do
            if relevant(obj.Name) and watched < 150 then
                watched = watched + 1

                local c = obj.AttributeChanged:Connect(
                    function(attr)
                        if running then
                            logEvent(
                                "ATRIBUTO CAMBIO: "..attr,
                                obj
                            )
                        end
                    end
                )

                table.insert(connections,c)
            end
        end
    end

    add("Objetos vigilados: "..watched)

    task.delay(90,function()
        if running and thisRun == generation then
            add("")
            add("MONITOREO FINALIZADO")
            add("Eventos detectados: "..eventCount)
            stop()
        end
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


