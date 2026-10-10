
--[[
 EGG FINDER V26.5
 ROBLOX - ROBA UN HUEVO

 OPTIMIZACIONES:
 - Cache de servidores
 - Carga inteligente
 - Escaneo por cambios
 - Revision periodica de respaldo
 - Un teletransporte activo como maximo
 - Reintentos con espera progresiva
 - Historial de fallos
 - Record de huevo especial
 - Panel compacto y arrastrable
 - AUTO HOP reanudable

 IMPORTANTE:
 - La rareza es estimada mediante efectos.
 - No puede consultar huevos de otros
   servidores sin entrar en ellos.
 - No puede cancelar teletransportes internos
   ni garantizar que Roblox cierre errores.
]]

local G = getgenv()

for _, name in ipairs({
    "EggFinderStop",
    "EggFinderV26Stop",
    "EggFinderV262Stop",
    "EggFinderV263Stop",
    "EggFinderV264Stop",
    "EggFinderV265Stop"
}) do
    if type(G[name]) == "function" then
        pcall(G[name])
    end
end

local Players = game:GetService("Players")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local LOADER =
    "https://raw.githubusercontent.com/jotahm83/EggFinder/main/EggFinder.lua"

local SAVE_FILE = "EggFinderV265_State.json"

local C = {
    minimum = 10,
    auto = true,

    minimumEggs = 60,
    stableSeconds = 1.5,
    effectGrace = 1.0,
    maxLoadSeconds = 35,
    backupScanSeconds = 8,

    minimumFreeSlots = 5,
    serverPages = 4,
    candidatePool = 50,

    teleportWarning = 20,
    retryBase = 3,
    retryMaximum = 18
}

local S = {
    running = true,
    found = false,
    busy = false,
    teleporting = false,
    scanBusy = false,

    attemptToken = 0,
    targetId = nil,

    visited = {},
    failed = {},
    serverPool = {},

    serverCount = 1,
    totalFailures = 0,
    consecutiveFailures = 0,

    eggCount = 0,
    candidates = {},
    unknown = 0,

    record = {
        height = 0,
        zone = "-",
        rarity = "-"
    },

    lastMessage = "",
    lastScan = 0,
    nextHop = 0,

    dirty = true,
    ready = false,
    stableCount = -1,
    stableSince = 0,
    readyAt = 0,

    queuePrepared = false,
    folder = nil,
    folderConnections = {},
    loadStarted = os.clock()
}

local connections = {}
local alertFrame
local hop
local scan

local function bind(signal, callback, collection)
    local connection = signal:Connect(callback)
    table.insert(collection or connections, connection)
    return connection
end

local function create(class, props, parent)
    local obj = Instance.new(class)

    for k, v in pairs(props or {}) do
        obj[k] = v
    end

    obj.Parent = parent
    return obj
end

local function rounded(obj, size)
    create("UICorner", {
        CornerRadius = UDim.new(0, size or 7)
    }, obj)
end

local function log(message)
    S.lastMessage = tostring(message)
    print("[EGG FINDER V26.5] " .. S.lastMessage)
end

-- LIMPIAR INTERFACES ANTERIORES

for _, name in ipairs({
    "EggFinderV26",
    "EggFinderV261",
    "EggFinderV262",
    "EggFinderV263",
    "EggFinderV264",
    "EggFinderV265"
}) do
    local old = pg:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

-- PANEL COMPACTO

local gui = create("ScreenGui", {
    Name = "EggFinderV265",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999
}, pg)

local panel = create("Frame", {
    Size = UDim2.fromOffset(260, 383),
    Position = UDim2.new(0.5, -130, 0.5, -191),
    BackgroundColor3 = Color3.fromRGB(19, 24, 36),
    BorderSizePixel = 0,
    Active = true
}, gui)

rounded(panel, 10)

create("UIStroke", {
    Color = Color3.fromRGB(58, 128, 190),
    Thickness = 1.2
}, panel)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 33),
    BackgroundColor3 = Color3.fromRGB(28, 44, 70),
    BorderSizePixel = 0,
    Active = true
}, panel)

rounded(header, 10)

create("TextLabel", {
    Text = "EGG FINDER V26.5",
    Position = UDim2.fromOffset(9, 0),
    Size = UDim2.new(1, -42, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(115, 220, 255),
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local function button(text, x, y, w, h, color, parent)
    local b = create("TextButton", {
        Text = text,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 =
            color or Color3.fromRGB(45, 77, 115),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 10
    }, parent or panel)

    rounded(b, 6)
    return b
end

local closeButton = button(
    "X", 230, 4, 26, 25,
    Color3.fromRGB(165, 52, 60),
    header
)

local function label(text, x, y, w, h, size, color)
    return create("TextLabel", {
        Text = text,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundTransparency = 1,
        TextColor3 = color or Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = size or 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, panel)
end

local status = label(
    "Iniciando buscador...",
    9, 39, 242, 35, 11,
    Color3.fromRGB(255, 215, 110)
)

label(
    "ALTURA MINIMA (STUDS)",
    9, 78, 220, 15, 10
)

local presets = {6, 8, 10, 12, 15}
local presetButtons = {}

for i, n in ipairs(presets) do
    presetButtons[i] = button(
        tostring(n),
        9 + (i - 1) * 49,
        98, 45, 25
    )
end

local minimumInput = create("TextBox", {
    Position = UDim2.fromOffset(9, 129),
    Size = UDim2.fromOffset(242, 27),
    BackgroundColor3 = Color3.fromRGB(34, 45, 62),
    BorderSizePixel = 0,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Text = "10",
    ClearTextOnFocus = false,
    PlaceholderText = "Minimo personalizado"
}, panel)

rounded(minimumInput, 6)

local autoButton = button(
    "AUTO: SI",
    9, 165, 116, 27,
    Color3.fromRGB(30, 130, 95)
)

local scanButton = button(
    "ESCANEAR",
    135, 165, 116, 27
)

local skipButton = button(
    "SALTAR",
    9, 199, 116, 27,
    Color3.fromRGB(105, 80, 145)
)

local pauseButton = button(
    "PAUSAR",
    135, 199, 116, 27,
    Color3.fromRGB(130, 90, 40)
)

local stats = label(
    "Servidores: 1 | Huevos: 0",
    9, 234, 242, 20, 10,
    Color3.fromRGB(180, 220, 255)
)

local recordLabel = label(
    "Record: 0.00 studs",
    9, 258, 242, 20, 10,
    Color3.fromRGB(255, 210, 115)
)

local results = label(
    "Esperando los huevos...",
    9, 284, 242, 50, 10
)

results.TextYAlignment = Enum.TextYAlignment.Top

local copyButton = button(
    "COPIAR",
    9, 345, 116, 27
)

local restartButton = button(
    "REINICIAR",
    135, 345, 116, 27,
    Color3.fromRGB(95, 65, 130)
)

local function setStatus(text, color)
    status.Text = text
    status.TextColor3 =
        color or Color3.fromRGB(255, 215, 110)
end

local function refreshAuto()
    autoButton.Text = C.auto and "AUTO: SI" or "AUTO: NO"

    autoButton.BackgroundColor3 =
        C.auto
        and Color3.fromRGB(30, 130, 95)
        or Color3.fromRGB(125, 65, 70)
end

local function refreshPresets()
    for i, b in ipairs(presetButtons) do
        b.BackgroundColor3 =
            C.minimum == presets[i]
            and Color3.fromRGB(30, 145, 105)
            or Color3.fromRGB(45, 77, 115)
    end
end

local function refreshRecord()
    recordLabel.Text = string.format(
        "Record: %.2f studs | %s",
        S.record.height,
        S.record.zone
    )
end

for i, n in ipairs(presets) do
    bind(presetButtons[i].MouseButton1Click, function()
        C.minimum = n
        minimumInput.Text = tostring(n)
        refreshPresets()
        S.dirty = true
    end)
end

bind(minimumInput.FocusLost, function()
    local n = tonumber(minimumInput.Text)

    if n and n > 0 and n <= 1000 then
        C.minimum = n
    else
        minimumInput.Text = tostring(C.minimum)
    end

    refreshPresets()
    S.dirty = true
end)

-- ZONAS PRIORITARIAS

local zones = {
    {
        name = "Cherry Blossom",
        aliases = {"cherryblossom", "cherry"}
    },
    {
        name = "Titan Temple",
        aliases = {"titantemple", "titan"}
    },
    {
        name = "Demons/Angels",
        aliases = {
            "lightdark", "demons", "angels",
            "demon", "angel"
        }
    },
    {
        name = "Enchanted Forest",
        aliases = {"enchantedforest", "enchanted"}
    }
}

local function normalize(text)
    return tostring(text or ""):lower():gsub("[^%w]", "")
end

local function matchZone(text)
    local n = normalize(text)

    for _, zone in ipairs(zones) do
        for _, alias in ipairs(zone.aliases) do
            if n:find(alias, 1, true) then
                return zone.name
            end
        end
    end

    return nil
end

local function zoneFromTree(obj)
    local node = obj

    while node and node ~= workspace do
        local z = matchZone(node.Name)
        if z then return z end

        for _, key in ipairs({
            "Area", "AreaName", "Zone",
            "ZoneName", "Biome", "BiomeName"
        }) do
            local ok, value = pcall(function()
                return node:GetAttribute(key)
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

local function positionOf(obj)
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

-- CACHE DE NIDOS
-- Solo se reconstruye cuando es necesario.

local nestCache = {}
local nestCacheAt = 0

local function getNests()
    if #nestCache > 0
    and os.clock() - nestCacheAt < 60 then
        return nestCache
    end

    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")

    local nests = {}

    if guards then
        for _, obj in ipairs(guards:GetDescendants()) do
            if obj:IsA("BasePart")
            and obj.Name == "EggFitBounds" then
                table.insert(nests, {
                    pos = obj.Position,
                    zone = zoneFromTree(obj)
                })
            end
        end
    end

    nestCache = nests
    nestCacheAt = os.clock()

    return nests
end

local function eggZone(egg, nests)
    local direct = zoneFromTree(egg)

    if direct then return direct end

    local pos = positionOf(egg)
    if not pos then return nil end

    local nearest
    local minDistance = math.huge

    for _, nest in ipairs(nests) do
        local d = (nest.pos - pos).Magnitude

        if d < minDistance then
            minDistance = d
            nearest = nest
        end
    end

    if nearest and minDistance <= 35 then
        return nearest.zone
    end

    return nil
end

-- ALTURA VISIBLE ESTIMADA

local function eggHeight(egg)
    local low = math.huge
    local high = -math.huge
    local count = 0

    for _, part in ipairs(egg:GetDescendants()) do
        if part:IsA("BasePart")
        and part.Transparency < 0.98
        and part.Size.Magnitude > 0.05 then

            local cf = part.CFrame
            local size = part.Size

            local half =
                math.abs(cf.RightVector.Y) * size.X / 2
                + math.abs(cf.UpVector.Y) * size.Y / 2
                + math.abs(cf.LookVector.Y) * size.Z / 2

            low = math.min(
                low,
                cf.Position.Y - half
            )

            high = math.max(
                high,
                cf.Position.Y + half
            )

            count = count + 1
        end
    end

    if count > 0 then
        return high - low
    end

    if egg:IsA("Model") then
        local ok, _, size = pcall(function()
            return egg:GetBoundingBox()
        end)

        if ok then return size.Y end
    end

    return 0
end

-- DETECCION DE EFECTOS
-- Conserva los criterios de V26.4.

local function inspectEffects(egg)
    local particles = 0
    local highlights = 0
    local beams = 0
    local trails = 0
    local lights = 0
    local pink = false

    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("ParticleEmitter") and obj.Enabled then
            particles = particles + 1

        elseif obj:IsA("Highlight") and obj.Enabled then
            highlights = highlights + 1

            local c = obj.OutlineColor

            if c.R > 0.65
            and c.B > 0.3
            and c.G < 0.55
            and obj.OutlineTransparency < 0.8 then
                pink = true
            end

        elseif obj:IsA("Beam") and obj.Enabled then
            beams = beams + 1

        elseif obj:IsA("Trail") and obj.Enabled then
            trails = trails + 1

        elseif (
            obj:IsA("PointLight")
            or obj:IsA("SpotLight")
            or obj:IsA("SurfaceLight")
        ) and obj.Enabled then
            lights = lights + 1
        end
    end

    local special =
        particles >= 3
        or (highlights >= 1 and particles >= 2)
        or (beams + trails >= 2 and particles >= 1)
        or (lights >= 2 and particles >= 2)

    local rarity =
        pink and "POSIBLE ETERNAL"
        or "ESPECIAL (SIN CONFIRMAR)"

    return special, rarity
end

-- ALERTA DE HUEVO ENCONTRADO

local function dismissAlert()
    if alertFrame then
        alertFrame:Destroy()
        alertFrame = nil
    end
end

local function playSound()
    pcall(function()
        local sound = create("Sound", {
            SoundId = "rbxasset://sounds/electronicpingshort.wav",
            Volume = 1.5
        }, SoundService)

        sound:Play()

        task.delay(4, function()
            if sound then sound:Destroy() end
        end)
    end)
end

local function showFound(candidate)
    dismissAlert()

    alertFrame = create("Frame", {
        Size = UDim2.new(0.9, 0, 0, 145),
        Position = UDim2.new(0.05, 0, 0.08, 0),
        BackgroundColor3 = Color3.fromRGB(20, 95, 55),
        BorderSizePixel = 0,
        ZIndex = 50
    }, gui)

    rounded(alertFrame, 10)

    create("UIStroke", {
        Color = Color3.fromRGB(75, 255, 150),
        Thickness = 3
    }, alertFrame)

    create("TextLabel", {
        Size = UDim2.new(1, -16, 1, -42),
        Position = UDim2.fromOffset(8, 5),
        BackgroundTransparency = 1,
        Text = string.format(
            "¡HUEVO ENCONTRADO!\n%s\n%.2f studs | Minimo %.2f\n%s\nAUTO HOP DETENIDO",
            candidate.zone,
            candidate.height,
            C.minimum,
            candidate.rarity
        ),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextWrapped = true,
        TextColor3 = Color3.new(1, 1, 1),
        ZIndex = 51
    }, alertFrame)

    local dismiss = create("TextButton", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.new(0, 8, 1, -34),
        Text = "CERRAR AVISO",
        BackgroundColor3 = Color3.fromRGB(45, 145, 85),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ZIndex = 51
    }, alertFrame)

    rounded(dismiss, 6)

    bind(dismiss.MouseButton1Click, dismissAlert)

    pcall(function()
        SG:SetCore("SendNotification", {
            Title = "¡HUEVO ENCONTRADO!",
            Text = string.format(
                "%s | %.2f studs",
                candidate.zone,
                candidate.height
            ),
            Duration = 20
        })
    end)

    for i = 1, 3 do
        task.delay((i - 1) * 0.7, function()
            if S.running and S.found then
                playSound()
            end
        end)
    end
end

-- DETECCION DE CAMBIOS EN HUEVOS

local function clearFolderConnections()
    for _, c in ipairs(S.folderConnections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    S.folderConnections = {}
end

local function getEggFolder()
    return workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )
end

local function watchFolder()
    local folder = getEggFolder()

    if folder == S.folder then
        return
    end

    clearFolderConnections()
    S.folder = folder

    S.ready = false
    S.dirty = true
    S.stableCount = -1
    S.stableSince = os.clock()

    if not folder then return end

    bind(folder.ChildAdded, function()
        S.dirty = true
        S.ready = false
        S.stableSince = os.clock()
    end, S.folderConnections)

    bind(folder.ChildRemoved, function()
        S.dirty = true
        S.ready = false
        S.stableSince = os.clock()
    end, S.folderConnections)

    -- Algunos efectos visuales aparecen
    -- despues de que el modelo ya existe.
    bind(folder.DescendantAdded, function(obj)
        if obj:IsA("ParticleEmitter")
        or obj:IsA("Highlight")
        or obj:IsA("Beam")
        or obj:IsA("Trail")
        or obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
            S.dirty = true
        end
    end, S.folderConnections)
end

local function getEggs()
    local folder = getEggFolder()
    local eggs = {}

    if not folder then return eggs end

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model")
        or egg:IsA("BasePart") then
            table.insert(eggs, egg)
        end
    end

    return eggs
end

local function updateReady()
    watchFolder()

    local eggs = getEggs()
    local count = #eggs
    local now = os.clock()

    S.eggCount = count

    if count ~= S.stableCount then
        S.stableCount = count
        S.stableSince = now
        S.dirty = true
        S.ready = false
    end

    if count >= C.minimumEggs
    and now - S.stableSince >= C.stableSeconds then
        if not S.ready then
            S.ready = true
            S.readyAt = now
            S.dirty = true
        end
    end

    return S.ready
end

-- ESCANEO OPTIMIZADO

scan = function()
    if not S.running
    or S.found
    or S.teleporting
    or S.busy
    or S.scanBusy then
        return
    end

    S.scanBusy = true

    local ok, err = pcall(function()
        local eggs = getEggs()
        local nests = getNests()

        S.eggCount = #eggs

        local candidates = {}
        local unknown = 0
        local best = nil

        for _, egg in ipairs(eggs) do
            local special, rarity = inspectEffects(egg)

            if special then
                local zone = eggZone(egg, nests)

                if zone then
                    local height = eggHeight(egg)

                    local candidate = {
                        zone = zone,
                        height = height,
                        rarity = rarity
                    }

                    table.insert(candidates, candidate)

                    if height > S.record.height then
                        S.record = {
                            height = height,
                            zone = zone,
                            rarity = rarity
                        }
                    end

                    -- SOLO EL MINIMO DETIENE BUSQUEDA.
                    if height >= C.minimum
                    and (
                        not best
                        or height > best.height
                    ) then
                        best = candidate
                    end
                else
                    unknown = unknown + 1
                end
            end
        end

        S.candidates = candidates
        S.unknown = unknown
        S.lastScan = os.clock()
        S.dirty = false

        refreshRecord()

        stats.Text = string.format(
            "Serv: %d | Huevos: %d | Fallos: %d",
            S.serverCount,
            S.eggCount,
            S.totalFailures
        )

        if best then
            S.found = true
            C.auto = false
            refreshAuto()

            setStatus(
                "¡HUEVO ENCONTRADO!",
                Color3.fromRGB(80, 255, 150)
            )

            results.Text = string.format(
                "%s\n%.2f studs | %s",
                best.zone,
                best.height,
                best.rarity
            )

            log(
                "ENCONTRADO | "
                .. best.zone
                .. " | "
                .. tostring(best.height)
            )

            showFound(best)
            return
        end

        table.sort(candidates, function(a, b)
            return a.height > b.height
        end)

        if #candidates > 0 then
            local largest = candidates[1]

            results.Text = string.format(
                "Mayor actual: %.2f studs\n%s\nMinimo: %.2f | CONTINUAR",
                largest.height,
                largest.zone,
                C.minimum
            )
        else
            results.Text =
                "Sin candidatos especiales.\nContinuar buscando..."
        end

        if unknown > 0 then
            results.Text =
                results.Text
                .. "\nSin zona: "
                .. tostring(unknown)
        end

        setStatus(
            "Analizado | Minimo "
            .. tostring(C.minimum)
        )

        log(string.format(
            "SCAN | Huevos=%d | Esp=%d | SinZona=%d",
            S.eggCount,
            #candidates,
            unknown
        ))
    end)

    S.scanBusy = false

    if not ok then
        S.dirty = true
        warn("[EGG FINDER V26.5] " .. tostring(err))
        setStatus("Error de analisis; reintentando")
    end
end

-- HTTP Y CACHE DE SERVIDORES

local function httpGet(url)
    local req =
        (syn and syn.request)
        or http_request
        or request

    if type(req) == "function" then
        local ok, response = pcall(function()
            return req({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json"
                }
            })
        end)

        if ok and response
        and (
            response.StatusCode == 200
            or response.Success
        )
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

local function refillServers()
    local pool = {}
    local cursor = nil

    for page = 1, C.serverPages do
        local url =
            "https://games.roblox.com/v1/games/"
            .. tostring(game.PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor then
            url = url
                .. "&cursor="
                .. HS:UrlEncode(cursor)
        end

        local body = httpGet(url)

        if not body then
            return false, "API de servidores inaccesible"
        end

        local ok, data = pcall(function()
            return HS:JSONDecode(body)
        end)

        if not ok or type(data) ~= "table" then
            return false, "Lista de servidores invalida"
        end

        for _, server in ipairs(data.data or {}) do
            local free =
                (server.maxPlayers or 0)
                - (server.playing or 0)

            if server.id
            and server.id ~= game.JobId
            and not S.visited[server.id]
            and not S.failed[server.id]
            and free >= C.minimumFreeSlots then
                table.insert(pool, {
                    id = server.id,
                    free = free,
                    players = server.playing or 0
                })
            end
        end

        cursor = data.nextPageCursor

        if not cursor
        or #pool >= C.candidatePool then
            break
        end
    end

    table.sort(pool, function(a, b)
        return a.players < b.players
    end)

    -- Mantener un lote razonable.
    local trimmed = {}

    for i = 1, math.min(
        #pool, C.candidatePool
    ) do
        table.insert(trimmed, pool[i])
    end

    S.serverPool = trimmed

    return true
end

local function nextServer()
    if #S.serverPool == 0 then
        local ok, err = refillServers()

        if not ok then
            return nil, err
        end
    end

    while #S.serverPool > 0 do
        local index = math.random(
            1, #S.serverPool
        )

        local target = table.remove(
            S.serverPool,
            index
        )

        if not S.visited[target.id]
        and not S.failed[target.id] then
            return target
        end
    end

    return nil, "No hay servidores nuevos"
end

-- PERSISTENCIA OPCIONAL
-- Algunos executors admiten readfile/writefile.

local function snapshot()
    local visited = {}
    local failed = {}

    for id in pairs(S.visited) do
        table.insert(visited, id)
        if #visited >= 120 then break end
    end

    for id in pairs(S.failed) do
        table.insert(failed, id)
        if #failed >= 80 then break end
    end

    return {
        minimum = C.minimum,
        auto = C.auto,
        checked = S.serverCount,
        failures = S.totalFailures,

        record = S.record,

        visited = visited,
        failed = failed
    }
end

local function saveState()
    if type(writefile) ~= "function" then
        return false
    end

    local ok = pcall(function()
        writefile(
            SAVE_FILE,
            HS:JSONEncode(snapshot())
        )
    end)

    return ok
end

local function prepareQueue()
    -- Se instala una unica cola por sesion.
    -- El cargador intentara recuperar el estado
    -- actualizado desde un archivo, si Delta
    -- dispone de sistema de archivos.

    if S.queuePrepared then
        return true
    end

    local queue =
        queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    if type(queue) ~= "function" then
        return false
    end

    local fallback = HS:JSONEncode(snapshot())

    local code = [[
local g = getgenv()
if g.EFV265QueuedBoot then return end
g.EFV265QueuedBoot = true

local fallback = ]] .. string.format("%q", fallback) .. [[

local saved = fallback

if type(readfile) == "function" then
    local ok, data = pcall(function()
        return readfile("EggFinderV265_State.json")
    end)

    if ok and type(data) == "string" then
        saved = data
    end
end

g.EggFinderV265Resume = saved

loadstring(game:HttpGet(
    ]] .. string.format("%q", LOADER) .. [[
))()
]]

    local ok = pcall(function()
        queue(code)
    end)

    if ok then
        S.queuePrepared = true
    end

    return ok
end

-- ERRORES DE TELETRANSPORTE

local function retryDelay()
    local exponent = math.min(
        math.max(S.consecutiveFailures - 1, 0),
        4
    )

    return math.min(
        C.retryBase * (2 ^ exponent),
        C.retryMaximum
    )
end

local function confirmedFailure(reason)
    if not S.running
    or S.found
    or not S.teleporting then
        return
    end

    if S.targetId then
        S.failed[S.targetId] = true
    end

    S.attemptToken = S.attemptToken + 1

    S.teleporting = false
    S.busy = false
    S.targetId = nil

    S.totalFailures = S.totalFailures + 1
    S.consecutiveFailures =
        S.consecutiveFailures + 1

    local delay = retryDelay()

    S.nextHop = os.clock() + delay

    setStatus(
        "Teleport fallido | Reintento "
        .. tostring(delay)
        .. "s"
    )

    results.Text =
        "Servidor descartado.\n"
        .. "Buscando otro destino..."

    log(
        "FALLO | "
        .. tostring(reason)
        .. " | Reintento="
        .. tostring(delay)
    )

    saveState()
end

-- UN SOLO TELETRANSPORTE A LA VEZ

hop = function(force)
    if not S.running
    or S.found
    or S.busy
    or S.teleporting then
        return
    end

    if not force and not C.auto then
        return
    end

    S.busy = true

    setStatus("Seleccionando servidor...")

    local target, err = nextServer()

    if not S.running then
        S.busy = false
        return
    end

    if not target then
        S.busy = false

        -- No desactivar AUTO ante un problema
        -- temporal de consulta.
        S.nextHop = os.clock() + 15

        setStatus(
            "Esperando nuevos servidores..."
        )

        log("SIN SERVIDORES | " .. tostring(err))
        return
    end

    S.visited[game.JobId] = true
    S.visited[target.id] = true
    S.targetId = target.id

    saveState()

    local queued = prepareQueue()

    S.attemptToken = S.attemptToken + 1
    local token = S.attemptToken

    S.teleporting = true
    S.busy = false

    setStatus(
        "Entrando | "
        .. tostring(target.players)
        .. " jugadores"
    )

    results.Text = string.format(
        "Plazas libres: %d\nReinicio preparado: %s",
        target.free,
        tostring(queued)
    )

    log(
        "TELEPORT | "
        .. target.id
        .. " | Queue="
        .. tostring(queued)
    )

    task.spawn(function()
        local ok, errText = pcall(function()
            TS:TeleportToPlaceInstance(
                game.PlaceId,
                target.id,
                player
            )
        end)

        if not ok
        and S.running
        and S.attemptToken == token
        and S.teleporting then
            confirmedFailure(errText)
        end
    end)

    -- ADVERTENCIA SIN DUPLICAR TELEPORT
    task.delay(C.teleportWarning, function()
        if not S.running
        or S.found
        or S.attemptToken ~= token
        or not S.teleporting then
            return
        end

        setStatus(
            "Teleport demorado: esperando Roblox",
            Color3.fromRGB(255, 175, 90)
        )

        results.Text =
            "Roblox sigue procesando.\n"
            .. "No se lanzara otro teleport\n"
            .. "hasta recibir un fallo."

        log(
            "TELEPORT DEMORADO | "
            .. tostring(target.id)
        )
    end)
end

bind(TS.TeleportInitFailed, function(
    failedPlayer,
    result,
    message
)
    if failedPlayer ~= player then
        return
    end

    if not S.teleporting then
        return
    end

    confirmedFailure(
        tostring(result)
        .. " | "
        .. tostring(message)
    )
end)

-- REANUDAR DESPUES DE ENCONTRAR

local function resumeSearch()
    if S.teleporting then
        setStatus("Teleport activo: esperar")
        return
    end

    S.found = false
    dismissAlert()

    C.auto = true
    refreshAuto()

    S.nextHop = 0

    setStatus(
        "AUTO HOP REANUDADO",
        Color3.fromRGB(90, 235, 165)
    )

    log("BUSQUEDA REANUDADA")

    task.spawn(function()
        hop(true)
    end)
end

-- BOTONES

bind(autoButton.MouseButton1Click, function()
    if S.found then
        resumeSearch()
        return
    end

    C.auto = not C.auto
    refreshAuto()

    if C.auto then
        S.nextHop = 0
        setStatus("AUTO HOP ACTIVADO")

        -- Si el servidor ya fue analizado,
        -- podemos buscar otro inmediatamente.
        if S.ready
        and not S.dirty
        and not S.teleporting then
            task.spawn(function()
                hop(true)
            end)
        end
    else
        setStatus("AUTO HOP PAUSADO")
    end
end)

bind(scanButton.MouseButton1Click, function()
    if not S.found then
        S.dirty = true
        task.spawn(scan)
    end
end)

bind(skipButton.MouseButton1Click, function()
    if S.found then
        resumeSearch()
        return
    end

    if S.teleporting then
        setStatus(
            "Teleport activo: no duplicar",
            Color3.fromRGB(255, 175, 90)
        )
        return
    end

    task.spawn(function()
        hop(true)
    end)
end)

bind(pauseButton.MouseButton1Click, function()
    C.auto = false
    refreshAuto()

    setStatus("BUSQUEDA PAUSADA")
end)

bind(copyButton.MouseButton1Click, function()
    local lines = {
        "EGG FINDER V26.5",
        "JobId: " .. tostring(game.JobId),
        "PlaceId: " .. tostring(game.PlaceId),

        "Minimo: " .. tostring(C.minimum),
        "AUTO: " .. tostring(C.auto),

        "Huevos: " .. tostring(S.eggCount),
        "Servidores: " .. tostring(S.serverCount),
        "Fallos: " .. tostring(S.totalFailures),

        "Teleport activo: "
            .. tostring(S.teleporting),

        "Record: "
            .. string.format("%.2f", S.record.height),

        "Record zona: " .. S.record.zone,
        "Record rareza: " .. S.record.rarity,

        "Sin zona: " .. tostring(S.unknown),
        "Ultimo: " .. S.lastMessage
    }

    for _, c in ipairs(S.candidates) do
        table.insert(lines, string.format(
            "%s | %.2f | %s",
            c.zone,
            c.height,
            c.rarity
        ))
    end

    local clipboard =
        setclipboard or toclipboard

    if type(clipboard) == "function" then
        local ok = pcall(function()
            clipboard(table.concat(lines, "\n"))
        end)

        setStatus(
            ok and "RESUMEN COPIADO"
            or "ERROR AL COPIAR"
        )
    else
        setStatus("SIN PORTAPAPELES")
    end
end)

bind(restartButton.MouseButton1Click, function()
    if S.teleporting then
        setStatus("Teleport activo: esperar")
        return
    end

    S.found = false
    dismissAlert()

    C.auto = false
    refreshAuto()

    S.ready = false
    S.dirty = true
    S.stableCount = -1
    S.stableSince = os.clock()
    S.loadStarted = os.clock()

    setStatus("REINICIADO")

    task.spawn(function()
        updateReady()
        scan()
    end)
end)

local function stop()
    S.running = false
    C.auto = false
    S.attemptToken = S.attemptToken + 1

    clearFolderConnections()

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

G.EggFinderStop = stop
G.EggFinderV265Stop = stop

bind(closeButton.MouseButton1Click, function()
    stop()
    gui:Destroy()
end)

-- ARRASTRAR PANEL

do
    local dragging = false
    local dragStart
    local startPos
    local active

    bind(header.InputBegan, function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
        or input.UserInputType ==
            Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = panel.Position
            active = input
        end
    end)

    bind(UIS.InputChanged, function(input)
        if not dragging then return end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
        or input == active then

            local delta = input.Position - dragStart

            panel.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    bind(UIS.InputEnded, function(input)
        if input == active
        or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- RESTAURAR ESTADO TRAS TELETRANSPORTE

do
    local saved = G.EggFinderV265Resume

    if type(saved) ~= "string"
    and type(readfile) == "function" then
        local ok, data = pcall(function()
            return readfile(SAVE_FILE)
        end)

        if ok and type(data) == "string" then
            saved = data
        end
    end

    if type(saved) == "string" then
        local ok, data = pcall(function()
            return HS:JSONDecode(saved)
        end)

        if ok and type(data) == "table" then
            C.minimum =
                tonumber(data.minimum) or 10

            C.auto = data.auto == true

            S.serverCount =
                (tonumber(data.checked) or 1) + 1

            S.totalFailures =
                tonumber(data.failures) or 0

            if type(data.record) == "table" then
                S.record = {
                    height =
                        tonumber(data.record.height) or 0,
                    zone =
                        tostring(data.record.zone or "-"),
                    rarity =
                        tostring(data.record.rarity or "-")
                }
            end

            for _, id in ipairs(data.visited or {}) do
                S.visited[id] = true
            end

            for _, id in ipairs(data.failed or {}) do
                S.failed[id] = true
            end
        end
    end

    G.EggFinderV265Resume = nil
end

S.visited[game.JobId] = true

minimumInput.Text = tostring(C.minimum)

refreshPresets()
refreshAuto()
refreshRecord()

log(
    "V26.5 INICIADO | Minimo="
    .. tostring(C.minimum)
)

-- BUCLE PRINCIPAL

task.spawn(function()
    setStatus("Cargando huevos...")

    while S.running do
        if not S.found
        and not S.teleporting
        and not S.busy then

            local ready = updateReady()
            local now = os.clock()

            if ready then
                -- Pequeño margen para que terminen
                -- de aparecer los efectos visuales.
                local graceComplete =
                    now - S.readyAt >= C.effectGrace

                if graceComplete then
                    local needScan =
                        S.dirty
                        or now - S.lastScan
                            >= C.backupScanSeconds

                    if needScan then
                        scan()
                    end

                    if C.auto
                    and not S.found
                    and not S.dirty
                    and not S.scanBusy
                    and not S.teleporting
                    and now >= S.nextHop then

                        S.nextHop = now + 5

                        task.spawn(function()
                            hop(false)
                        end)
                    end
                end

            elseif now - S.loadStarted
                >= C.maxLoadSeconds then

                -- No forzar saltos mientras faltan
                -- huevos: puede ser una carga parcial.
                setStatus(
                    "Carga incompleta: "
                    .. tostring(S.eggCount)
                    .. " huevos"
                )

                -- Mantener AUTO seleccionado.
                -- Si completan la carga, continuara.
            else
                setStatus(
                    "Cargando: "
                    .. tostring(S.eggCount)
                    .. " huevos"
                )
            end
        end

        task.wait(0.3)
    end
end)
