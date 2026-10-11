-- SteepFlight v3 - Controla TU escalera como plataforma voladora
-- Para Delta (telefono). Pegar y ejecutar.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local VELOCIDAD = 16
local volando = false
local escalera = nil
local subir = false
local bajar = false
local conexion = nil

-- Buscar TU escalera: la que esta dentro de tu personaje o con tu nombre
local function buscarMiEscalera()
	local char = player.Character
	if not char then return nil end
	-- 1. Busca dentro de tu personaje (escalera equipada / backpack / accesorio)
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			local n = string.lower(obj.Name)
			if string.find(n, "ladder") or string.find(n, "escalera") or string.find(n, "step") then
				return obj
			end
		end
	end
	-- 2. Busca en el mapa una pieza que coincida con tu nombre de usuario
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local n = string.lower(obj.Name)
			if (string.find(n, "ladder") or string.find(n, "escalera") or string.find(n, "step"))
				and string.find(n, string.lower(player.Name)) then
				return obj
			end
		end
	end
	return nil
end

-- Interfaz tactil en pantalla
local gui = Instance.new("ScreenGui")
gui.Name = "SteepFlightGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function boton(texto, x, y, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 90, 0, 50)
	b.Position = UDim2.new(1, x, 1, y)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = texto
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	return b
end

local aviso = Instance.new("TextLabel")
aviso.Size = UDim2.new(0, 260, 0, 30)
aviso.Position = UDim2.new(0.5, -130, 0, 10)
aviso.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aviso.TextColor3 = Color3.new(1, 1, 1)
aviso.Text = "SteepFlight cargado"
aviso.Font = Enum.Font.GothamBold
aviso.TextSize = 13
aviso.Parent = gui
local ac = Instance.new("UICorner")
ac.CornerRadius = UDim.new(0, 8)
ac.Parent = aviso

local function mensaje(t)
	aviso.Text = t
	task.delay(2, function()
		aviso.Text = "SteepFlight"
	end)
end

local bVolar = boton("VOLAR", -200, -120, Color3.fromRGB(0, 170, 80))
local bSubir = boton("SUBIR", -105, -180, Color3.fromRGB(60, 60, 200))
local bBajar = boton("BAJAR", -105, -60, Color3.fromRGB(60, 60, 200))
local bMas = boton("+", -200, -180, Color3.fromRGB(90, 90, 90))
local bMenos = boton("-", -200, -60, Color3.fromRGB(90, 90, 90))

-- Movimiento: la escalera se mueve y mueve tu personaje al mismo tiempo
local function empezarVuelo()
	if conexion then conexion:Disconnect() end
	conexion = RunService.Heartbeat:Connect(function()
		if not volando or not escalera or not escalera.Parent then return end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local dir = Vector3.zero
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then dir = hum.MoveDirection end
		local mov = dir * VELOCIDAD
		if subir then mov = mov + Vector3.new(0, VELOCIDAD, 0) end
		if bajar then mov = mov - Vector3.new(0, VELOCIDAD, 0) end
		local delta = mov * (1 / 60)
		escalera.CFrame = escalera.CFrame + delta
		root.CFrame = root.CFrame + delta
	end)
end

bVolar.MouseButton1Click:Connect(function()
	if not volando then
		escalera = buscarMiEscalera()
		if not escalera then
			mensaje("NO ENCONTRE TU ESCALERA")
			return
		end
		escalera.Anchored = true
		volando = true
		bVolar.Text = "ATERRIZAR"
		bVolar.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		empezarVuelo()
		mensaje("VOLANDO CON TU ESCALERA")
	else
		volando = false
		if escalera and escalera.Parent then
			escalera.Anchored = false
		end
		escalera = nil
		bVolar.Text = "VOLAR"
		bVolar.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
		mensaje("ATERRIZASTE")
	end
end)

bSubir.MouseButton1Down:Connect(function() subir = true end)
bSubir.MouseButton1Up:Connect(function() subir = false end)
bBajar.MouseButton1Down:Connect(function() bajar = true end)
bBajar.MouseButton1Up:Connect(function() bajar = false end)

bMas.MouseButton1Click:Connect(function()
	VELOCIDAD = VELOCIDAD + 4
	mensaje("Velocidad: " .. VELOCIDAD)
end)
bMenos.MouseButton1Click:Connect(function()
	VELOCIDAD = math.max(4, VELOCIDAD - 4)
	mensaje("Velocidad: " .. VELOCIDAD)
end)

player.CharacterAdded:Connect(function()
	volando = false
	escalera = nil
	bVolar.Text = "VOLAR"
	bVolar.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
end)