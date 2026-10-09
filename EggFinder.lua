
--[[
 EGG FINDER V26
 Roblox: Roba un Huevo
 Objetivo: encontrar huevos especiales GRANDES
 Zonas: Cherry Blossom, Titan Temple,
        Demons / Angels / Light Dark,
        Enchanted Forest

 IMPORTANTE:
 - La rareza se estima por efectos visuales.
 - No lee resultados secretos del servidor.
 - El cambio automatico depende de Delta,
   de Roblox y de los permisos del juego.
]]

if getgenv().EggFinderV26Stop then
    pcall(getgenv().EggFinderV26Stop)
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local CONFIG = {
    Minimum = 10,
    AutoHop = true,
    ScanInterval = 2,
    LoadWait = 12,
    EmptyWait = 20,
    HopDelay = 4,
    MaxPages = 5,
    EffectThreshold = 3
}

local LOADER_URL =
    "https://raw.githubusercontent.com/jotahm83/EggFinder/main/EggFinder.lua"

local running = true
local found = false
local hopping = false
local visited = {}
local scannedServers = 0
local startedAt = os.clock()
local currentCandidates = {}
local currentEggCount = 0
local lastLog = ""
local scanBusy = false

local oldGui = pg:FindFirstChild("EggFinderV26")
if oldGui then oldGui:Destroy() end

local function new(class, properties, parent)
    local obj = Instance.new(class)
    for k, v in pairs(properties or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local gui = new("ScreenGui", {
    Name = "EggFinderV26",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999
}, pg)

local panel = new("Frame", {
    Name = "Panel",
    Size = UDim2.fromOffset(330, 455),
    Position = UDim2.new(0.5, -165, 0.5, -227),
    BackgroundColor3 = Color3.fromRGB(18, 22, 33),
    BorderSizePixel = 0,
    Active = true
}, gui)

new("UICorner", {CornerRadius = UDim.new(0, 12)}, panel)

new("UIStroke", {
    Color = Color3.fromRGB(60, 110, 180),
    Thickness = 1.5
}, panel)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 43),
    BackgroundColor3 = Color3.fromRGB(27, 40, 63),
    BorderSizePixel = 0,
    Active = true
}, panel)

new("UICorner", {
    CornerRadius = UDim.new(0, 12)
}, header)

local title = new("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "EGG FINDER V26",
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextColor3 = Color3.fromRGB(115, 210, 255),
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local function makeButton(text, x, y, w, h, parent, color)
    local b = new("TextButton", {
        Text = text,
        Size = UDim2.fromOffset(w, h),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = color or Color3.fromRGB(43, 72, 110),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
        AutoButtonColor = true
    }, parent)
    new("UICorner", {
        CornerRadius = UDim.new(0, 7)
    }, b)
    return b
end

local close = makeButton(
    "X", 295, 7, 28, 28, header,
    Color3.fromRGB(155, 48, 55)
)

local function makeLabel(text, x, y, w, h, size, color)
    return new("TextLabel", {
        Text = text,
        Size = UDim2.fromOffset(w, h),
        Position = UDim2.fromOffset(x, y),
        BackgroundTransparency = 1,
        TextColor3 = color or Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = size or 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, panel)
end

local status = makeLabel(
    "Preparando detector...", 12, 51, 306, 35,
    13, Color3.fromRGB(255, 220, 120)
)

makeLabel(
    "ALTURA MINIMA (STUDS)",
    12, 92, 250, 20, 12,
    Color3.fromRGB(180, 195, 215)
)

local presetValues = {6, 8, 10, 12, 15}
local presetButtons = {}

local minimumBox = new("TextBox", {
    Position = UDim2.fromOffset(12, 153),
    Size = UDim2.fromOffset(306, 32),
    Text = tostring(CONFIG.Minimum),
    PlaceholderText = "Escribe un minimo personalizado",
    BackgroundColor3 = Color3.fromRGB(34, 43, 60),
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    ClearTextOnFocus = false,
    BorderSizePixel = 0
}, panel)

new("UICorner", {
    CornerRadius = UDim.new(0, 7)
}, minimumBox)

local function updatePresetColors()
    for i, b in ipairs(presetButtons) do
        if CONFIG.Minimum == presetValues[i] then
            b.BackgroundColor3 = Color3.fromRGB(32, 150, 104)
        else
            b.BackgroundColor3 = Color3.fromRGB(43, 72, 110)
        end
    end
end

for i, value in ipairs(presetValues) do
    local b = makeButton(
        tostring(value),
        12 + (i - 1) * 62,
        116, 58, 30, panel
    )
    presetButtons[i] = b
    b.MouseButton1Click:Connect(function()
        CONFIG.Minimum = value
        minimumBox.Text = tostring(value)
        updatePresetColors()
    end)
end

updatePresetColors()

minimumBox.FocusLost:Connect(function()
    local n = tonumber(minimumBox.Text)
    if n and n > 0 and n <= 1000 then
        CONFIG.Minimum = n
    else
        minimumBox.Text = tostring(CONFIG.Minimum)
    end
    updatePresetColors()
end)

local autoButton = makeButton(
    "AUTO HOP: SI", 12, 195, 148, 33,
    panel, Color3.fromRGB(31, 130, 95)
)

local scanButton = makeButton(
    "ESCANEAR", 170, 195, 148, 33, panel
)

local hopButton = makeButton(
    "OTRO SERVIDOR", 12, 237, 148, 33, panel
)

local pauseButton = makeButton(
    "PAUSAR", 170, 237, 148, 33, panel,
    Color3.fromRGB(130, 95, 35)
)

local stats = makeLabel(
    "Servidor: 1 | Huevos: 0 | Candidatos: 0",
    12, 281, 306, 34, 12,
    Color3.fromRGB(180, 215, 255)
)

local results = makeLabel(
    "Esperando el primer escaneo...",
    12, 317, 306, 72, 12,
    Color3.fromRGB(235, 235, 235)
)
results.TextYAlignment = Enum.TextYAlignment.Top

local copyButton = makeButton(
    "COPIAR RESUMEN", 12, 399, 148, 34, panel
)

local restartButton = makeButton(
    "REINICIAR", 170, 399, 148, 34, panel,
    Color3.fromRGB(105, 65, 130)
)

-- Arrastre compatible con mouse y pantalla tactil.
do
    local dragging = false
    local dragStart
    local startPosition
    local activeInput

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
            activeInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input == activeInput then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input == activeInput
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function setStatus(message, color)
    status.Text = message
    if color then status.TextColor3 = color end
end

local function log(message)
    print("[EGG FINDER V26] " .. tostring(message))
    lastLog = tostring(message)
end

local function normalize(s)
    return tostring(s or ""):lower()
        :gsub("[^%w]", "")
end

local zonePatterns = {
    {name = "Cherry Blossom", aliases = {
        "cherryblossom", "cherry"
    }},
    {name = "Titan Temple", aliases = {
        "titantemple", "titan"
    }},
    {name = "Demons/Angels", aliases = {
        "lightdark", "demons", "angels",
        "demon", "angel"
    }},
    {name = "Enchanted Forest", aliases = {
        "enchantedforest", "enchanted"
    }}
}

local function matchZone(s)
    local n = normalize(s)
    if n == "" then return nil end

    for _, zone in ipairs(zonePatterns) do
        for _, alias in ipairs(zone.aliases) do
            if n:find(alias, 1, true) then
                return zone.name
            end
        end
    end

    return nil
end

local function objectPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        local ok, cf = pcall(function()
            return obj:GetPivot()
        end)
        if ok then return cf.Position end
    end

    return nil
end

local function zoneFromObject(obj)
    local node = obj

    while node and node ~= workspace do
        local z = matchZone(node.Name)
        if z then return z end

        for _, attr in ipairs({
            "Area", "AreaName", "Zone",
            "ZoneName", "Biome", "BiomeName"
        }) do
            local ok, value = pcall(function()
                return node:GetAttribute(attr)
            end)
            if ok and value then
                z = matchZone(value)
                if z then return z end
            end
        end

        node = node.Parent
    end

    return nil
end

local function getEggFolder()
    return workspace:FindFirstChild("AreaEggSlotsClient")
end

local function getGuardAreas()
    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    return areas and areas:FindFirstChild("GuardAreas")
end

local function collectNests()
    local folder = getGuardAreas()
    local nests = {}

    if not folder then return nests end

    for _, obj in ipairs(folder:GetDescendants()) do
        if obj.Name == "EggFitBounds"
        and obj:IsA("BasePart") then
            local zone = zoneFromObject(obj)

            table.insert(nests, {
                position = obj.Position,
                zone = zone,
                path = obj:GetFullName()
            })
        end
    end

    return nests
end

local function findEggZone(egg, nests)
    local direct = zoneFromObject(egg)
    if direct then return direct, true end

    local pos = objectPosition(egg)
    if not pos then return nil, false end

    local nearest
    local distance = math.huge

    for _, nest in ipairs(nests) do
        local d = (nest.position - pos).Magnitude
        if d < distance then
            distance = d
            nearest = nest
        end
    end

    if nearest and distance <= 35 then
        return nearest.zone, nearest.zone ~= nil
    end

    return nil, false
end

-- Se mide la altura usando partes fisicas,
-- no el tamaño de los emisores de particulas.
local function measureEgg(egg)
    local minY = math.huge
    local maxY = -math.huge
    local count = 0

    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj.Transparency < 0.98
            and obj.Size.Magnitude > 0.05 then
                local cf = obj.CFrame
                local size = obj.Size

                local halfY =
                    math.abs(cf.RightVector.Y) * size.X / 2
                    + math.abs(cf.UpVector.Y) * size.Y / 2
                    + math.abs(cf.LookVector.Y) * size.Z / 2

                minY = math.min(minY, cf.Position.Y - halfY)
                maxY = math.max(maxY, cf.Position.Y + halfY)
                count = count + 1
            end
        end
    end

    if count > 0 then
        return maxY - minY
    end

    if egg:IsA("Model") then
        local ok, _, size = pcall(function()
            return egg:GetBoundingBox()
        end)
        if ok then return size.Y end
    end

    return 0
end

local function inspectEffects(egg)
    local particles = 0
    local highlights = 0
    local beams = 0
    local trails = 0
    local lights = 0
    local strongRate = 0
    local pinkOutline = false

    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            if obj.Enabled then
                particles = particles + 1
                strongRate = strongRate + math.min(obj.Rate, 100)
            end

        elseif obj:IsA("Highlight") then
            if obj.Enabled then
                highlights = highlights + 1

                local c = obj.OutlineColor
                if c.R > 0.65
                and c.B > 0.3
                and c.G < 0.55
                and obj.OutlineTransparency < 0.8 then
                    pinkOutline = true
                end
            end

        elseif obj:IsA("Beam") then
            if obj.Enabled then
                beams = beams + 1
            end

        elseif obj:IsA("Trail") then
            if obj.Enabled then
                trails = trails + 1
            end

        elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
            if obj.Enabled then
                lights = lights + 1
            end
        end
    end

    local score =
        particles * 2
        + highlights * 3
        + beams * 3
        + trails * 2
        + lights * 2
        + math.min(strongRate / 25, 8)

    -- Filtro conservador contra huevos normales
    -- que solo tienen una particula decorativa.
    local special =
        particles >= 3
        or (highlights >= 1 and particles >= 2)
        or (beams + trails >= 2 and particles >= 1)
        or (lights >= 2 and particles >= 2)

    local rarity = "ESPECIAL (sin confirmar)"

    if special and pinkOutline then
        rarity = "POSIBLE ETERNAL"
    end

    return {
        special = special,
        rarity = rarity,
        score = score,
        particles = particles,
        highlights = highlights,
        beams = beams,
        trails = trails,
        lights = lights,
        pink = pinkOutline
    }
end

local function playAlert()
    pcall(function()
        local sound = new("Sound", {
            SoundId = "rbxasset://sounds/electronicpingshort.wav",
            Volume = 1.5
        }, SoundService)

        sound:Play()

        task.delay(4, function()
            if sound then sound:Destroy() end
        end)
    end)
end

local alertGui

local function showAlert(candidate)
    if alertGui then alertGui:Destroy() end

    alertGui = new("Frame", {
        Size = UDim2.new(0.9, 0, 0, 165),
        Position = UDim2.new(0.05, 0, 0.08, 0),
        BackgroundColor3 = Color3.fromRGB(20, 85, 52),
        BorderSizePixel = 0,
        ZIndex = 50
    }, gui)

    new("UICorner", {
        CornerRadius = UDim.new(0, 12)
    }, alertGui)

    new("UIStroke", {
        Color = Color3.fromRGB(75, 255, 145),
        Thickness = 3
    }, alertGui)

    local text = new("TextLabel", {
        Size = UDim2.new(1, -20, 1, -45),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Text = string.format(
            "¡HUEVO ENCONTRADO!\n%s\nAltura: %.2f studs | Minimo: %.2f\n%s\nBUSQUEDA DETENIDA",
            candidate.zone,
            candidate.height,
            CONFIG.Minimum,
            candidate.rarity
        ),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextWrapped = true,
        ZIndex = 51
    }, alertGui)

    local dismiss = new("TextButton", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 1, -36),
        BackgroundColor3 = Color3.fromRGB(40, 130, 80),
        Text = "CERRAR AVISO (SIN REANUDAR)",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 51
    }, alertGui)

    new("UICorner", {
        CornerRadius = UDim.new(0, 7)
    }, dismiss)

    dismiss.MouseButton1Click:Connect(function()
        alertGui:Destroy()
        alertGui = nil
    end)

    pcall(function()
        SG:SetCore("SendNotification", {
            Title = "¡HUEVO ENCONTRADO!",
            Text = candidate.zone
                .. " | " .. string.format("%.1f", candidate.height)
                .. " studs. Busqueda detenida.",
            Duration = 20
        })
    end)

    for i = 1, 3 do
        task.delay((i - 1) * 0.65, playAlert)
    end
end

local function getEggs()
    local folder = getEggFolder()
    if not folder then return {} end

    local eggs = {}

    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            table.insert(eggs, obj)
        end
    end

    return eggs
end

local function scan()
    if scanBusy or found or not running then return end
    scanBusy = true

    local ok, err = pcall(function()
        local eggs = getEggs()
        local nests = collectNests()

        currentEggCount = #eggs
        currentCandidates = {}

        local unknownSpecial = 0
        local targetSpecial = 0
        local best

        for _, egg in ipairs(eggs) do
            local effects = inspectEffects(egg)

            if effects.special then
                local zone, mapped = findEggZone(egg, nests)
                local height = measureEgg(egg)

                if not mapped then
                    unknownSpecial = unknownSpecial + 1
                elseif zone then
                    targetSpecial = targetSpecial + 1

                    local candidate = {
                        zone = zone,
                        height = height,
                        rarity = effects.rarity,
                        score = effects.score,
                        egg = egg
                    }

                    table.insert(currentCandidates, candidate)

                    if height >= CONFIG.Minimum then
                        if not best or height > best.height then
                            best = candidate
                        end
                    end
                end
            end
        end

        stats.Text = string.format(
            "Servidor: %d | Huevos: %d | Especiales: %d",
            scannedServers + 1,
            currentEggCount,
            targetSpecial
        )

        if best then
            found = true
            CONFIG.AutoHop = false

            setStatus(
                "¡HUEVO ENCONTRADO! NO CAMBIAR",
                Color3.fromRGB(90, 255, 150)
            )

            results.Text = string.format(
                "ZONA: %s\nALTURA: %.2f studs\n%s",
                best.zone,
                best.height,
                best.rarity
            )

            log(string.format(
                "ENCONTRADO | Zona=%s | Altura=%.2f | Minimo=%.2f | Rareza=%s | JobId=%s",
                best.zone,
                best.height,
                CONFIG.Minimum,
                best.rarity,
                game.JobId
            ))

            showAlert(best)
            return
        end

        table.sort(currentCandidates, function(a, b)
            return a.height > b.height
        end)

        if #currentCandidates > 0 then
            local largest = currentCandidates[1]

            results.Text = string.format(
                "Especiales en zonas objetivo: %d\nMayor: %s | %.2f studs\nMinimo requerido: %.2f studs",
                #currentCandidates,
                largest.zone,
                largest.height,
                CONFIG.Minimum
            )
        else
            results.Text =
                "Sin huevos especiales confirmados\n"
                .. "en las cuatro zonas prioritarias."
        end

        if unknownSpecial > 0 then
            results.Text = results.Text
                .. "\nSin zona identificada: "
                .. unknownSpecial
        end

        setStatus(
            "Escaneando | Minimo: "
            .. tostring(CONFIG.Minimum),
            Color3.fromRGB(255, 220, 120)
        )

        log(string.format(
            "ESCANEO | Huevos=%d | Candidatos=%d | ZonaDesconocida=%d | Minimo=%.2f",
            currentEggCount,
            #currentCandidates,
            unknownSpecial,
            CONFIG.Minimum
        ))
    end)

    scanBusy = false

    if not ok then
        warn("[EGG FINDER V26] Error: " .. tostring(err))
        setStatus("Error de escaneo; reintentando...")
    end
end

local function httpGet(url)
    local requestFunction =
        (syn and syn.request)
        or http_request
        or request

    if requestFunction then
        local ok, response = pcall(function()
            return requestFunction({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json"
                }
            })
        end)

        if ok and response
        and (response.StatusCode == 200 or response.Success)
        and response.Body then
            return response.Body
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)

    if ok then return body end
    return nil
end

local function getServerList()
    local servers = {}
    local cursor = nil

    for page = 1, CONFIG.MaxPages do
        local url =
            "https://games.roblox.com/v1/games/"
            .. tostring(game.PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor then
            url = url .. "&cursor=" .. HS:UrlEncode(cursor)
        end

        local body = httpGet(url)
        if not body then
            return nil, "No se pudo consultar la lista de servidores"
        end

        local ok, data = pcall(function()
            return HS:JSONDecode(body)
        end)

        if not ok or type(data) ~= "table" then
            return nil, "Respuesta de servidores no valida"
        end

        for _, server in ipairs(data.data or {}) do
            if server.id
            and server.id ~= game.JobId
            and not visited[server.id]
            and server.playing
            and server.maxPlayers
            and server.playing < server.maxPlayers then
                table.insert(servers, server.id)
            end
        end

        cursor = data.nextPageCursor
        if not cursor or #servers >= 25 then
            break
        end
    end

    return servers
end

local function queueNextRun()
    local queueFunction =
        queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    if not queueFunction then
        return false
    end

    local ids = {}

    for id in pairs(visited) do
        table.insert(ids, id)
        if #ids >= 150 then break end
    end

    local saved = HS:JSONEncode({
        minimum = CONFIG.Minimum,
        auto = CONFIG.AutoHop,
        visited = ids,
        servers = scannedServers
    })

    local code =
        "getgenv().EggFinderV26Resume = "
        .. string.format("%q", saved)
        .. "\nloadstring(game:HttpGet("
        .. string.format("%q", LOADER_URL)
        .. "))()"

    local ok = pcall(function()
        queueFunction(code)
    end)

    return ok
end

local function hopServer(force)
    if hopping or found or not running then return end
    if not force and not CONFIG.AutoHop then return end

    hopping = true
    setStatus("Buscando otro servidor...")

    local servers, err = getServerList()

    if not servers then
        hopping = false
        CONFIG.AutoHop = false
        autoButton.Text = "AUTO HOP: NO"
        autoButton.BackgroundColor3 =
            Color3.fromRGB(120, 65, 65)

        setStatus("AUTO HOP DETENIDO: error de servidores")
        results.Text = tostring(err)
        log(err)
        return
    end

    if #servers == 0 then
        hopping = false
        CONFIG.AutoHop = false
        autoButton.Text = "AUTO HOP: NO"
        autoButton.BackgroundColor3 =
            Color3.fromRGB(120, 65, 65)

        setStatus("No hay servidores nuevos disponibles")
        return
    end

    local target = servers[math.random(1, #servers)]
    visited[game.JobId] = true
    visited[target] = true

    scannedServers = scannedServers + 1

    local queued = queueNextRun()

    setStatus("Cambiando de servidor...")
    log("TELEPORT | Destino=" .. target
        .. " | AutoReinicio=" .. tostring(queued))

    if not queued then
        results.Text =
            "Aviso: Delta no confirmo queue_on_teleport.\n"
            .. "Puede ser necesario ejecutar V26 de nuevo."
    end

    local ok, teleportError = pcall(function()
        TS:TeleportToPlaceInstance(
            game.PlaceId,
            target,
            player
        )
    end)

    if not ok then
        hopping = false
        scannedServers = math.max(0, scannedServers - 1)
        visited[target] = nil

        setStatus("Error al cambiar de servidor")
        results.Text = tostring(teleportError)
        log("ERROR TELEPORT: " .. tostring(teleportError))
    else
        task.delay(15, function()
            if running and not found then
                hopping = false
            end
        end)
    end
end

local function updateAutoButton()
    autoButton.Text =
        CONFIG.AutoHop and "AUTO HOP: SI" or "AUTO HOP: NO"

    autoButton.BackgroundColor3 =
        CONFIG.AutoHop
        and Color3.fromRGB(31, 130, 95)
        or Color3.fromRGB(120, 65, 65)
end

autoButton.MouseButton1Click:Connect(function()
    if found then
        setStatus("Huevo encontrado: busqueda detenida")
        return
    end

    CONFIG.AutoHop = not CONFIG.AutoHop
    updateAutoButton()
end)

scanButton.MouseButton1Click:Connect(function()
    if not found then
        task.spawn(scan)
    end
end)

hopButton.MouseButton1Click:Connect(function()
    if not found then
        task.spawn(function()
            hopServer(true)
        end)
    end
end)

pauseButton.MouseButton1Click:Connect(function()
    if found then return end

    CONFIG.AutoHop = false
    updateAutoButton()
    setStatus("Busqueda automatica pausada")
end)

copyButton.MouseButton1Click:Connect(function()
    local lines = {
        "EGG FINDER V26",
        "PlaceId: " .. tostring(game.PlaceId),
        "JobId: " .. tostring(game.JobId),
        "Minimo: " .. tostring(CONFIG.Minimum),
        "Huevos: " .. tostring(currentEggCount),
        "Servidores revisados: "
            .. tostring(scannedServers + 1),
        "Encontrado: " .. tostring(found),
        "Ultimo registro: " .. lastLog
    }

    for _, c in ipairs(currentCandidates) do
        table.insert(lines, string.format(
            "%s | %.2f studs | %s | Score %.1f",
            c.zone, c.height, c.rarity, c.score
        ))
    end

    local clipboard = setclipboard or toclipboard

    if clipboard then
        local ok = pcall(function()
            clipboard(table.concat(lines, "\n"))
        end)

        setStatus(
            ok and "Resumen enviado al portapapeles"
            or "Error al copiar"
        )
    else
        setStatus("Portapapeles no disponible")
    end
end)

local function stop()
    running = false
    CONFIG.AutoHop = false
end

getgenv().EggFinderV26Stop = stop

close.MouseButton1Click:Connect(function()
    stop()
    gui:Destroy()
end)

restartButton.MouseButton1Click:Connect(function()
    found = false
    hopping = false
    CONFIG.AutoHop = false
    currentCandidates = {}

    if alertGui then
        alertGui:Destroy()
        alertGui = nil
    end

    updateAutoButton()
    setStatus("Reiniciado: escaneo manual")
    task.spawn(scan)
end)

-- Recuperar configuracion tras cambiar de servidor.
do
    local saved = getgenv().EggFinderV26Resume

    if type(saved) == "string" then
        local ok, data = pcall(function()
            return HS:JSONDecode(saved)
        end)

        if ok and type(data) == "table" then
            CONFIG.Minimum = tonumber(data.minimum) or 10
            CONFIG.AutoHop = data.auto == true
            scannedServers = tonumber(data.servers) or 0

            for _, id in ipairs(data.visited or {}) do
                visited[id] = true
            end

            minimumBox.Text = tostring(CONFIG.Minimum)
            updatePresetColors()
            updateAutoButton()
        end

        getgenv().EggFinderV26Resume = nil
    end
end

-- Evitar volver al servidor actual.
visited[game.JobId] = true

-- Bucle principal.
task.spawn(function()
    setStatus("Esperando carga de huevos...")

    local firstScan = true
    local noEggsSince = nil
    local lastScan = 0

    while running do
        if not found and not hopping then
            if os.clock() - lastScan >= CONFIG.ScanInterval then
                scan()
                lastScan = os.clock()
            end

            if currentEggCount == 0 then
                noEggsSince = noEggsSince or os.clock()
            else
                noEggsSince = nil
            end

            if firstScan then
                task.wait(CONFIG.LoadWait)
                firstScan = false
                scan()
            end

            if CONFIG.AutoHop and not found then
                local elapsed = os.clock() - startedAt

                if currentEggCount >= 60 then
                    -- Si hay candidatos sin zona identificada,
                    -- no abandonar el servidor a ciegas.
                    local uncertain = lastLog:match(
                        "ZonaDesconocida=(%d+)"
                    )

                    if tonumber(uncertain or 0) > 0 then
                        CONFIG.AutoHop = false
                        updateAutoButton()

                        setStatus(
                            "REVISION NECESARIA: zona desconocida"
                        )
                    else
                        task.wait(CONFIG.HopDelay)

                        if running and not found
                        and CONFIG.AutoHop then
                            hopServer(false)
                        end
                    end

                elseif noEggsSince
                and os.clock() - noEggsSince >= CONFIG.EmptyWait then
                    CONFIG.AutoHop = false
                    updateAutoButton()

                    setStatus(
                        "No cargaron los huevos: revisar servidor"
                    )

                elseif elapsed > 45 and currentEggCount > 0
                and currentEggCount < 60 then
                    setStatus(
                        "Esperando carga completa de huevos..."
                    )
                end
            end
        end

        task.wait(1)
    end
end)

log("V26 iniciado | Minimo=" .. CONFIG.Minimum)
