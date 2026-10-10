
--[[
 EGG FINDER V26.4
 ROBLOX - ROBA UN HUEVO

 MEJORAS:
 1. Deteccion de carga inteligente.
 2. Sin espera fija de 12 segundos.
 3. Sin teletransportes simultaneos.
 4. Reintentos con espera progresiva.
 5. Servidores aleatorios poco poblados.
 6. Historial de servidores fallidos.
 7. Panel compacto y arrastrable.
 8. Boton AUTO reanudable.
 9. Conserva deteccion de especiales.
 10. Alerta al encontrar el tamano minimo.

 LIMITACIONES:
 La rareza se estima por efectos visuales.
 Un timeout no cancela una operacion de Roblox.
 Los errores de conexion pueden requerir
 intervencion manual si Roblox deja de responder.
]]

local G = getgenv()

for _, key in ipairs({
    "EggFinderStop",
    "EggFinderV26Stop",
    "EggFinderV262Stop",
    "EggFinderV263Stop",
    "EggFinderV264Stop"
}) do
    if type(G[key]) == "function" then
        pcall(G[key])
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

local C = {
    minimum = 10,
    auto = true,

    scanEvery = 1.5,
    loadStableTime = 1.5,
    minimumEggs = 60,
    maxLoadTime = 35,

    teleportWarning = 20,

    minimumFree = 5,
    pages = 6,
    candidatePool = 40,

    retryBase = 3,
    retryMax = 15
}

local S = {
    running = true,
    found = false,

    hopping = false,
    teleporting = false,
    stalled = false,

    token = 0,
    checked = 1,
    failures = 0,

    visited = {},
    failed = {},

    candidates = {},
    eggCount = 0,
    unknown = 0,

    scanBusy = false,
    lastScan = 0,
    lastMessage = "",

    target = nil,
    nextHop = 0,

    ready = false,
    firstSeenAt = nil,
    stableSince = nil,
    lastEggCount = -1,

    -- Evita llamar queue_on_teleport
    -- repetidamente en el mismo cliente.
    queuePrepared = false
}

local connections = {}
local alertFrame

local function bind(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
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

local function rounded(obj, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 7)
    }, obj)
end

for _, name in ipairs({
    "EggFinderV26",
    "EggFinderV261",
    "EggFinderV262",
    "EggFinderV263",
    "EggFinderV264"
}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end

-- PANEL COMPACTO

local gui = create("ScreenGui", {
    Name = "EggFinderV264",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999
}, pg)

local panel = create("Frame", {
    Size = UDim2.fromOffset(260, 364),
    Position = UDim2.new(0.5, -130, 0.5, -182),
    BackgroundColor3 = Color3.fromRGB(19, 24, 36),
    BorderSizePixel = 0,
    Active = true
}, gui)

rounded(panel, 10)

create("UIStroke", {
    Color = Color3.fromRGB(55, 125, 190),
    Thickness = 1.2
}, panel)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 33),
    BackgroundColor3 = Color3.fromRGB(29, 44, 70),
    BorderSizePixel = 0,
    Active = true
}, panel)

rounded(header, 10)

create("TextLabel", {
    Text = "EGG FINDER V26.4",
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
    Color3.fromRGB(160, 50, 58),
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
    "Preparando...", 9, 38, 242, 35,
    11, Color3.fromRGB(255, 215, 110)
)

label(
    "ALTURA MINIMA (STUDS)",
    9, 77, 220, 15, 10
)

local presets = {6, 8, 10, 12, 15}
local presetButtons = {}

for i, n in ipairs(presets) do
    presetButtons[i] = button(
        tostring(n),
        9 + (i - 1) * 49,
        97, 45, 25
    )
end

local minimumInput = create("TextBox", {
    Position = UDim2.fromOffset(9, 128),
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
    "AUTO: SI", 9, 163, 116, 27,
    Color3.fromRGB(30, 130, 95)
)

local scanButton = button(
    "ESCANEAR", 135, 163, 116, 27
)

local skipButton = button(
    "SALTAR", 9, 196, 116, 27,
    Color3.fromRGB(100, 80, 145)
)

local pauseButton = button(
    "PAUSAR", 135, 196, 116, 27,
    Color3.fromRGB(130, 90, 40)
)

local stats = label(
    "Servidores: 1 | Huevos: 0",
    9, 232, 242, 23, 10,
    Color3.fromRGB(180, 220, 255)
)

local results = label(
    "Esperando primer escaneo...",
    9, 258, 242, 58, 10
)

results.TextYAlignment = Enum.TextYAlignment.Top

local copyButton = button(
    "COPIAR", 9, 326, 116, 27
)

local restartButton = button(
    "REINICIAR", 135, 326, 116, 27,
    Color3.fromRGB(95, 65, 130)
)

local function setStatus(text, color)
    status.Text = text

    status.TextColor3 =
        color or Color3.fromRGB(255, 215, 110)
end

local function log(text)
    S.lastMessage = tostring(text)
    print("[EGG FINDER V26.4] " .. tostring(text))
end

local function updateAuto()
    autoButton.Text =
        C.auto and "AUTO: SI" or "AUTO: NO"

    autoButton.BackgroundColor3 =
        C.auto
        and Color3.fromRGB(30, 130, 95)
        or Color3.fromRGB(125, 65, 70)
end

local function updatePresets()
    for i, b in ipairs(presetButtons) do
        b.BackgroundColor3 =
            C.minimum == presets[i]
            and Color3.fromRGB(30, 145, 105)
            or Color3.fromRGB(45, 77, 115)
    end
end

for i, n in ipairs(presets) do
    bind(presetButtons[i].MouseButton1Click, function()
        C.minimum = n
        minimumInput.Text = tostring(n)
        updatePresets()
    end)
end

bind(minimumInput.FocusLost, function()
    local n = tonumber(minimumInput.Text)

    if n and n > 0 and n <= 1000 then
        C.minimum = n
    else
        minimumInput.Text = tostring(C.minimum)
    end

    updatePresets()
end)

-- IDENTIFICACION DE ZONAS

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

    for _, z in ipairs(zones) do
        for _, alias in ipairs(z.aliases) do
            if n:find(alias, 1, true) then
                return z.name
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

local function collectNests()
    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")

    local nests = {}

    if not guards then return nests end

    for _, obj in ipairs(guards:GetDescendants()) do
        if obj:IsA("BasePart")
        and obj.Name == "EggFitBounds" then

            table.insert(nests, {
                pos = obj.Position,
                zone = zoneFromTree(obj)
            })
        end
    end

    return nests
end

local function eggZone(egg, nests)
    local direct = zoneFromTree(egg)

    if direct then return direct end

    local pos = objectPosition(egg)

    if not pos then return nil end

    local nearest
    local distance = math.huge

    for _, nest in ipairs(nests) do
        local d = (nest.pos - pos).Magnitude

        if d < distance then
            distance = d
            nearest = nest
        end
    end

    if nearest and distance <= 35 then
        return nearest.zone
    end

    return nil
end

-- ALTURA FISICA VISIBLE ESTIMADA

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

-- DETECTOR DE EFECTOS ESPECIALES
-- MANTIENE LA LOGICA DE V26.3

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

-- ALERTA

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

-- CARGA INTELIGENTE

local function getEggs()
    local folder =
        workspace:FindFirstChild("AreaEggSlotsClient")

    if not folder then
        return {}
    end

    local eggs = {}

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model")
        or egg:IsA("BasePart") then
            table.insert(eggs, egg)
        end
    end

    return eggs
end

local function updateLoading()
    local eggs = getEggs()
    local count = #eggs
    local now = os.clock()

    S.eggCount = count

    if count ~= S.lastEggCount then
        S.lastEggCount = count
        S.stableSince = now
    end

    if count >= C.minimumEggs
    and S.stableSince
    and now - S.stableSince >= C.loadStableTime then
        S.ready = true
        return true
    end

    return false
end

-- ESCANEO

local function scan()
    if not S.running
    or S.found
    or S.hopping
    or S.teleporting
    or S.scanBusy then
        return
    end

    S.scanBusy = true

    local ok, err = pcall(function()
        local eggs = getEggs()
        local nests = collectNests()

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

                    -- UNICAMENTE CUMPLE SI
                    -- ALTURA >= MINIMO

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

        stats.Text = string.format(
            "Servidores: %d | Huevos: %d | Esp.: %d",
            S.checked,
            S.eggCount,
            #candidates
        )

        if best then
            S.found = true
            C.auto = false
            updateAuto()

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
                .. best.height
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
                "Mayor: %s\n%.2f / %.2f studs\nMenor al minimo: continuar",
                largest.zone,
                largest.height,
                C.minimum
            )
        else
            results.Text =
                "Sin especiales validos.\nContinuar buscando..."
        end

        if unknown > 0 then
            results.Text =
                results.Text
                .. "\nSin zona: "
                .. unknown
        end

        setStatus(
            "Buscando | Minimo "
            .. tostring(C.minimum)
        )

        log(string.format(
            "SCAN | Huevos=%d | Especiales=%d | SinZona=%d",
            S.eggCount,
            #candidates,
            unknown
        ))
    end)

    S.scanBusy = false

    if not ok then
        warn("[EGG FINDER V26.4] " .. tostring(err))
        setStatus("Error al escanear")
    end
end

-- CONSULTA DE SERVIDORES

local function httpGet(url)
    local requestFunction =
        (syn and syn.request)
        or http_request
        or request

    if type(requestFunction) == "function" then
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

local function findServers()
    local pool = {}
    local cursor = nil

    for page = 1, C.pages do
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
            return nil, "API de servidores inaccesible"
        end

        local ok, data = pcall(function()
            return HS:JSONDecode(body)
        end)

        if not ok or type(data) ~= "table" then
            return nil, "Lista de servidores invalida"
        end

        for _, server in ipairs(data.data or {}) do
            local free =
                (server.maxPlayers or 0)
                - (server.playing or 0)

            if server.id
            and server.id ~= game.JobId
            and not S.visited[server.id]
            and not S.failed[server.id]
            and free >= C.minimumFree then
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

    return pool
end

-- GUARDAR CONFIGURACION PARA EL SIGUIENTE SERVIDOR

local function queueNext()
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

    local visited = {}
    local failed = {}

    for id in pairs(S.visited) do
        table.insert(visited, id)

        if #visited >= 120 then
            break
        end
    end

    for id in pairs(S.failed) do
        table.insert(failed, id)

        if #failed >= 80 then
            break
        end
    end

    local data = HS:JSONEncode({
        minimum = C.minimum,
        auto = C.auto,
        checked = S.checked,
        visited = visited,
        failed = failed
    })

    local code =
        "getgenv().EggFinderV264Resume="
        .. string.format("%q", data)
        .. "\nloadstring(game:HttpGet("
        .. string.format("%q", LOADER)
        .. "))()"

    local ok = pcall(function()
        queue(code)
    end)

    if ok then
        S.queuePrepared = true
    end

    return ok
end

-- MANEJO DE ERRORES
-- Solo reintenta ante un fallo confirmado.

local function retryDelay()
    local exponent = math.min(S.failures - 1, 4)

    return math.min(
        C.retryBase * (2 ^ math.max(exponent, 0)),
        C.retryMax
    )
end

local function confirmedFailure(reason)
    if not S.running or S.found then
        return
    end

    if S.target then
        S.failed[S.target] = true
    end

    S.token = S.token + 1
    S.teleporting = false
    S.stalled = false
    S.hopping = false

    S.target = nil
    S.failures = S.failures + 1

    local delay = retryDelay()
    S.nextHop = os.clock() + delay

    setStatus(
        "Error de servidor | Reintento "
        .. delay
        .. "s"
    )

    results.Text =
        "Fallo confirmado.\n"
        .. "Se buscara otro servidor."

    log(
        "TELEPORT FALLIDO | "
        .. tostring(reason)
        .. " | Espera="
        .. delay
    )
end

-- TELETRANSPORTE CONTROLADO

local function hop(force)
    if not S.running
    or S.found
    or S.hopping
    or S.teleporting then
        return
    end

    if not force and not C.auto then
        return
    end

    S.hopping = true

    setStatus(
        "Buscando servidor con pocos jugadores..."
    )

    local servers, err = findServers()

    if not S.running then
        S.hopping = false
        return
    end

    if not servers then
        S.hopping = false
        C.auto = false
        updateAuto()

        setStatus(tostring(err))
        log(tostring(err))
        return
    end

    if #servers == 0 then
        S.hopping = false
        C.auto = false
        updateAuto()

        setStatus("No hay servidores nuevos")
        return
    end

    local count = math.min(
        #servers,
        C.candidatePool
    )

    -- Eleccion aleatoria entre servidores
    -- poco poblados y con plazas disponibles.

    local target = servers[math.random(1, count)]

    S.visited[game.JobId] = true
    S.visited[target.id] = true
    S.target = target.id

    local queued = queueNext()

    S.token = S.token + 1
    local token = S.token

    S.hopping = false
    S.teleporting = true
    S.stalled = false

    setStatus(
        "Entrando | "
        .. target.players
        .. " jugadores"
    )

    results.Text =
        "Plazas libres: "
        .. target.free
        .. "\nPreparado tras teleport: "
        .. tostring(queued)

    log(
        "TELEPORT INICIADO | "
        .. target.id
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
        and S.token == token
        and S.teleporting then
            confirmedFailure(errText)
        end
    end)

    -- IMPORTANTE:
    -- A diferencia de V26.3, el temporizador
    -- no habilita otro teletransporte.
    -- Solo muestra una advertencia.

    task.delay(C.teleportWarning, function()
        if not S.running
        or S.found
        or S.token ~= token
        or not S.teleporting then
            return
        end

        S.stalled = true

        setStatus(
            "Teleport demorado (sin duplicar)",
            Color3.fromRGB(255, 175, 90)
        )

        results.Text =
            "Roblox aun procesa el cambio.\n"
            .. "Esperando error confirmado.\n"
            .. "Si queda bloqueado, revisa Roblox."

        log("TELEPORT DEMORADO | " .. target.id)
    end)
end

-- EVENTO DE FALLO OFICIAL

bind(TS.TeleportInitFailed, function(
    failedPlayer,
    result,
    message
)
    if failedPlayer ~= player then
        return
    end

    if not S.running or S.found then
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

-- REANUDAR BUSQUEDA DESPUES DE ENCONTRAR

local function resume()
    if S.teleporting then
        setStatus("Espera a terminar el teletransporte")
        return
    end

    S.found = false

    dismissAlert()

    C.auto = true
    updateAuto()

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
        resume()
        return
    end

    C.auto = not C.auto
    updateAuto()

    if C.auto then
        setStatus("AUTO HOP ACTIVADO")
        S.nextHop = 0

        -- Si ya hay un intento en marcha,
        -- NO se lanza otro.
        if S.ready
        and not S.teleporting
        and not S.hopping then
            task.spawn(function()
                hop(true)
            end)
        end
    else
        setStatus("AUTO HOP PAUSADO")
    end
end)

bind(scanButton.MouseButton1Click, function()
    if not S.found
    and not S.teleporting then
        task.spawn(scan)
    end
end)

bind(skipButton.MouseButton1Click, function()
    if S.found then
        resume()
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
    updateAuto()

    setStatus("BUSQUEDA PAUSADA")
end)

bind(copyButton.MouseButton1Click, function()
    local lines = {
        "EGG FINDER V26.4",
        "JobId: " .. tostring(game.JobId),
        "PlaceId: " .. tostring(game.PlaceId),
        "Minimo: " .. tostring(C.minimum),
        "Auto: " .. tostring(C.auto),
        "Huevos: " .. tostring(S.eggCount),
        "Servidores: " .. tostring(S.checked),
        "Fallos: " .. tostring(S.failures),
        "Teleportando: " .. tostring(S.teleporting),
        "Demorado: " .. tostring(S.stalled),
        "Encontrado: " .. tostring(S.found),
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

    local clipboard = setclipboard or toclipboard

    if type(clipboard) == "function" then
        local ok = pcall(function()
            clipboard(table.concat(lines, "\n"))
        end)

        setStatus(
            ok and "RESUMEN COPIADO"
            or "ERROR AL COPIAR"
        )
    else
        setStatus("PORTAPAPELES NO DISPONIBLE")
    end
end)

bind(restartButton.MouseButton1Click, function()
    if S.teleporting then
        setStatus("No reiniciar durante teleport")
        return
    end

    S.found = false
    S.stalled = false

    dismissAlert()

    C.auto = false
    updateAuto()

    S.ready = false
    S.lastEggCount = -1
    S.stableSince = nil

    setStatus("REINICIADO")

    task.spawn(scan)
end)

local function stop()
    S.running = false
    C.auto = false
    S.token = S.token + 1

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

G.EggFinderStop = stop
G.EggFinderV264Stop = stop

bind(closeButton.MouseButton1Click, function()
    stop()
    gui:Destroy()
end)

-- PANEL ARRASTRABLE

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

-- RECUPERAR DATOS AL CAMBIAR DE SERVIDOR

do
    local saved = G.EggFinderV264Resume

    if type(saved) == "string" then
        local ok, data = pcall(function()
            return HS:JSONDecode(saved)
        end)

        if ok and type(data) == "table" then
            C.minimum =
                tonumber(data.minimum) or 10

            C.auto = data.auto == true

            S.checked =
                (tonumber(data.checked) or 1) + 1

            for _, id in ipairs(data.visited or {}) do
                S.visited[id] = true
            end

            for _, id in ipairs(data.failed or {}) do
                S.failed[id] = true
            end
        end

        G.EggFinderV264Resume = nil
    end
end

S.visited[game.JobId] = true

minimumInput.Text = tostring(C.minimum)
updatePresets()
updateAuto()

log(
    "V26.4 INICIADO | Minimo="
    .. tostring(C.minimum)
)

-- BUCLE PRINCIPAL

task.spawn(function()
    setStatus("Esperando huevos...")

    local loadStarted = os.clock()

    while S.running do
        if not S.found
        and not S.teleporting
        and not S.hopping then

            -- No espera siempre 12 segundos.
            -- Detecta cuando hay suficientes huevos
            -- y su numero permanece estable.

            if not S.ready then
                updateLoading()

                if S.ready then
                    setStatus("Huevos cargados: escaneando")

                    scan()

                    S.lastScan = os.clock()
                    S.nextHop = os.clock() + 1.5

                elseif os.clock() - loadStarted
                    >= C.maxLoadTime then

                    C.auto = false
                    updateAuto()

                    setStatus(
                        "Carga incompleta: revisar"
                    )

                    results.Text =
                        "Huevos: "
                        .. S.eggCount
                        .. "\nEsperando carga completa."

                    -- No desactivar el propio escaneo:
                    -- si luego termina de cargar, S.ready
                    -- pasara a true y podra reactivarse AUTO.
                end

            else
                if os.clock() - S.lastScan
                    >= C.scanEvery then

                    scan()
                    S.lastScan = os.clock()
                end

                if C.auto
                and not S.found
                and not S.hopping
                and not S.teleporting
                and os.clock() >= S.nextHop then

                    S.nextHop = os.clock() + 5

                    task.spawn(function()
                        hop(false)
                    end)
                end
            end
        end

        task.wait(0.5)
    end
end)
