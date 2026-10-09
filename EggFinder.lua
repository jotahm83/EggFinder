
-- EGG FINDER V20
-- COMPARADOR DE HUEVOS, NIDOS Y BASES

local Players = game:GetService("Players")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

local previous = pg:FindFirstChild("EggFinder")
if previous then previous:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.48,0,0.72,0)
frame.Position = UDim2.new(0.5,0,0.12,0)
frame.BackgroundColor3 = Color3.fromRGB(15,17,27)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-35,0,34)
title.BackgroundColor3 = Color3.fromRGB(32,38,55)
title.TextColor3 = Color3.fromRGB(0,255,140)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Text = "EGG FINDER V20"
title.Parent = frame

local function makeButton(text,x,width,color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(width,0,0,34)
    b.Position = UDim2.new(x,0,0,36)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = text
    b.Parent = frame
    return b
end

local copy = makeButton(
    "COPIAR TODO",0,0.49,
    Color3.fromRGB(25,110,65)
)

local refresh = makeButton(
    "ACTUALIZAR",0.51,0.49,
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
output.TextColor3 = Color3.fromRGB(0,255,140)
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextWrapped = true
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Parent = scroll

local lines = {}

local function add(s)
    table.insert(lines,tostring(s))
end

local function redraw()
    output.Text = table.concat(lines,"\n")
    local height = math.max(1000,#lines*32)
    output.Size = UDim2.new(1,-12,0,height)
    scroll.CanvasSize = UDim2.new(0,0,0,height+30)
end

local function positionOf(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        local part = obj.PrimaryPart
        if part then
            return part.Position
        end

        local ok,cf = pcall(function()
            return obj:GetBoundingBox()
        end)

        if ok then
            return cf.Position
        end
    end

    return nil
end

local function formatPos(p)
    if not p then return "DESCONOCIDA" end
    return string.format(
        "%.0f, %.0f, %.0f",
        p.X,p.Y,p.Z
    )
end

local function nearest(pos,items)
    local best = nil
    local bestDistance = math.huge

    for _,item in ipairs(items) do
        local d = (pos-item.pos).Magnitude

        if d < bestDistance then
            bestDistance = d
            best = item
        end
    end

    return best,bestDistance
end

local function run()
    lines = {}
    add("EGG FINDER V20")
    add("COMPARACION DE POSICIONES")
    add("")

    local nests = {}
    local zones = {}
    local plots = {}
    local eggs = {}

    local areas = workspace:FindFirstChild("World")
    areas = areas and areas:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")

    add("=== FASE 1: ZONAS Y NIDOS ===")

    if guards then
        for _,zone in ipairs(guards:GetChildren()) do
            local nestFolder = zone:FindFirstChild("Nests")

            if nestFolder then
                local zoneData = {
                    name = zone.Name,
                    nests = {}
                }

                for _,nest in ipairs(nestFolder:GetChildren()) do
                    local pos = positionOf(nest)

                    if pos then
                        local entry = {
                            zone = zone.Name,
                            name = nest.Name,
                            pos = pos
                        }

                        table.insert(nests,entry)
                        table.insert(zoneData.nests,entry)
                    end
                end

                table.insert(zones,zoneData)
            end
        end
    else
        add("NO SE ENCONTRO GuardAreas")
    end

    table.sort(zones,function(a,b)
        return a.name < b.name
    end)

    for _,zone in ipairs(zones) do
        add("")
        add("ZONA: "..zone.name)
        add("Nidos: "..#zone.nests)

        for i,nest in ipairs(zone.nests) do
            add("  Nido "..i..": "
                ..formatPos(nest.pos))
        end
    end

    add("")
    add("TOTAL NIDOS: "..#nests)

    add("")
    add("=== FASE 2: BASES ===")

    local plotFolder = workspace:FindFirstChild("Plots")

    if plotFolder then
        for _,plot in ipairs(plotFolder:GetChildren()) do
            local pos = positionOf(plot)

            if pos then
                table.insert(plots,{
                    name = plot.Name,
                    pos = pos
                })
            end
        end
    end

    table.sort(plots,function(a,b)
        return a.name < b.name
    end)

    for _,plot in ipairs(plots) do
        add("Base "..plot.name..": "
            ..formatPos(plot.pos))
    end

    add("TOTAL BASES: "..#plots)

    add("")
    add("=== FASE 3: HUEVOS ===")

    local eggFolder = workspace:FindFirstChild(
        "PlacedEggRenders"
    )

    if eggFolder then
        for _,obj in ipairs(eggFolder:GetChildren()) do
            local pos = positionOf(obj)

            if pos then
                table.insert(eggs,{
                    name = obj.Name,
                    pos = pos,
                    obj = obj
                })
            end
        end
    else
        add("NO SE ENCONTRO PlacedEggRenders")
    end

    add("TOTAL HUEVOS: "..#eggs)

    local zoneMatches = {}
    local plotMatches = {}
    local unknown = 0

    for _,zone in ipairs(zones) do
        zoneMatches[zone.name] = 0
    end

    for _,plot in ipairs(plots) do
        plotMatches[plot.name] = 0
    end

    for i,egg in ipairs(eggs) do
        add("")
        add("HUEVO "..i)
        add("ID: "..egg.name)
        add("Posicion: "..formatPos(egg.pos))

        local nest,nd = nearest(egg.pos,nests)
        local plot,pd = nearest(egg.pos,plots)

        if nest then
            add("Nido cercano: "..nest.zone)
            add(string.format(
                "Distancia al nido: %.1f studs",nd
            ))
        end

        if plot then
            add("Base cercana: "..plot.name)
            add(string.format(
                "Distancia a base: %.1f studs",pd
            ))
        end

        -- Los umbrales son provisionales.
        -- Una base se compara con su centro.
        local nearNest = nest and nd <= 25
        local nearPlot = plot and pd <= 100

        if nearNest and (not nearPlot or nd < pd) then
            add("CLASIFICACION: POSIBLE HUEVO DE ZONA")
            zoneMatches[nest.zone] =
                zoneMatches[nest.zone]+1

        elseif nearPlot and (not nearNest or pd < nd) then
            add("CLASIFICACION: POSIBLE HUEVO DE BASE")
            plotMatches[plot.name] =
                plotMatches[plot.name]+1

        else
            add("CLASIFICACION: SIN CONFIRMAR")
            unknown = unknown+1
        end
    end

    add("")
    add("=== RESUMEN POR ZONA ===")

    for _,zone in ipairs(zones) do
        add(zone.name
            .." | Nidos: "..#zone.nests
            .." | Huevos cercanos: "
            ..zoneMatches[zone.name])
    end

    add("")
    add("=== RESUMEN POR BASE ===")

    for _,plot in ipairs(plots) do
        add("Base "..plot.name
            .." | Huevos cercanos: "
            ..plotMatches[plot.name])
    end

    add("")
    add("SIN CONFIRMAR: "..unknown)
    add("")
    add("NOTA: Las distancias son aproximadas.")
    add("La clasificacion aun no es definitiva.")
    add("Los nidos sin coincidencia NO se")
    add("consideran vacios automaticamente.")
    add("")
    add("FIN DEL INFORME V20")

    redraw()
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
    local ok,err = pcall(run)

    if not ok then
        add("ERROR: "..tostring(err))
        redraw()
    end
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local ok,err = pcall(run)
if not ok then
    add("ERROR: "..tostring(err))
    redraw()
end
