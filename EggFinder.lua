
local player = game:GetService("Players").LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.6, 0, 0.2, 0)
label.Position = UDim2.new(0.2, 0, 0.4, 0)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.TextScaled = true
label.Text = "EGG FINDER - CONEXION EXITOSA"
label.Parent = gui
