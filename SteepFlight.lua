-- Steep Steps - Script para movil (Delta)
-- Botones: VOLAR, SUBIR, BAJAR, ESCALERA, + y -

-- 1) SERVICIOS: son "herramientas" que Roblox nos da
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- 2) CONFIGURACION: cambia estos numeros a tu gusto
local velocidad = 50        -- velocidad de vuelo
local velocidadMin, velocidadMax = 10, 200
local distanciaEscalera = 15 -- que tan cerca debe estar la escalera para agarrarla

-- 3) VARIABLES DE ESTADO: guardan lo que esta pasando
local volando = false
local subiendo, bajando = false, false
local escaleraAgarrada = nil
local bodyVel, bodyGyro

-- Devuelve las partes del personaje (se vuelve a llamar si mueres)
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	return char, char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
end

-- 4) VOLAR
local function empezarVuelo()
	local _, hum, root = getChar()
	volando = true
	hum.PlatformStand = true -- el personaje deja de caminar/caer

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVel.Velocity = Vector3.zero
	bodyVel.Parent = root

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 9e4
	bodyGyro.Parent = root
end

local function pararVuelo()
	volando = false
	local _, hum = getChar()
	hum.PlatformStand = false
	if bodyVel then bodyVel:Destroy() bodyVel = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

-- 5) ESCALERA: busca la parte con "ladder"/"escalera"/"step" mas cercana
local function buscarEscalera()
	local _, _, root = getChar()
	local mejor, mejorDist = nil, distanciaEscalera
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local n = obj.Name:lower()
			if n:find("ladder") or n:find("escalera") or n:find("step") then
				local d = (obj.Position - root.Position).Magnitude
				if d < mejorDist then mejor, mejorDist = obj, d end
			end
		end
	end
	return mejor
end

local function alternarEscalera()
	if escaleraAgarrada then
		escaleraAgarrada = nil
		return "ESCALERA"
	end
	local e = buscarEscalera()
	if e then
		escaleraAgarrada = e
		if not volando then empezarVuelo() end
		return "SOLTAR"
	end
	return "ESCALERA"
end

-- 6) BOTONES EN PANTALLA
local gui = Instance.new("ScreenGui")
gui.Name = "SteepStepsMovil"
gui.ResetOnSpawn = false
-- En Delta se usa gethui() para que el menu no se borre; si no existe, usamos PlayerGui
local ok, contenedor = pcall(function() return gethui() end)
gui.Parent = (ok and contenedor) or player:WaitForChild("PlayerGui")

local function crearBoton(texto, x, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 80, 0, 50)
	b.Position = UDim2.new(1, x, 1, y) -- esquina inferior derecha
	b.Text = texto
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	b.BackgroundTransparency = 0.3
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end

local btnVolar    = crearBoton("VOLAR",    -180, -300)
local btnEscalera = crearBoton("ESCALERA", -90,  -300)
local btnSubir    = crearBoton("SUBIR",    -180, -240)
local btnBajar    = crearBoton("BAJAR",    -90,  -240)
local btnMas      = crearBoton("+",        -180, -360)
local btnMenos    = crearBoton("-",        -90,  -360)
local etiqueta    = crearBoton("Vel: " .. velocidad, -180, -410)
etiqueta.Size = UDim2.new(0, 170, 0, 40)
etiqueta.AutoButtonColor = false

-- 7) QUE HACE CADA BOTON
btnVolar.Activated:Connect(function()
	if volando then pararVuelo() escaleraAgarrada = nil btnEscalera.Text = "ESCALERA"
	else empezarVuelo() end
	btnVolar.Text = volando and "ATERRIZAR" or "VOLAR"
end)

btnEscalera.Activated:Connect(function()
	btnEscalera.Text = alternarEscalera()
	btnVolar.Text = volando and "ATERRIZAR" or "VOLAR"
end)

-- SUBIR/BAJAR: funcionan mientras mantienes el dedo
btnSubir.MouseButton1Down:Connect(function() subiendo = true end)
btnSubir.MouseButton1Up:Connect(function() subiendo = false end)
btnSubir.MouseLeave:Connect(function() subiendo = false end)
btnBajar.MouseButton1Down:Connect(function() bajando = true end)
btnBajar.MouseButton1Up:Connect(function() bajando = false end)
btnBajar.MouseLeave:Connect(function() bajando = false end)

btnMas.Activated:Connect(function()
	velocidad = math.min(velocidad + 10, velocidadMax)
	etiqueta.Text = "Vel: " .. velocidad
end)
btnMenos.Activated:Connect(function()
	velocidad = math.max(velocidad - 10, velocidadMin)
	etiqueta.Text = "Vel: " .. velocidad
end)

-- 8) BUCLE PRINCIPAL: se ejecuta en cada fotograma
RunService.RenderStepped:Connect(function()
	if not volando or not bodyVel then return end
	local _, hum, root = getChar()
	local cam = workspace.CurrentCamera

	-- MoveDirection = hacia donde empujas el joystick
	local dir = hum.MoveDirection * velocidad
	local y = 0
	if subiendo then y = velocidad end
	if bajando then y = -velocidad end

	-- Si tienes la escalera agarrada, la escalera viaja contigo
	if escaleraAgarrada and escaleraAgarrada.Parent then
		pcall(function()
			escaleraAgarrada.Anchored = true
			escaleraAgarrada.CFrame = root.CFrame * CFrame.new(0, 0, -3)
		end)
	end

	bodyVel.Velocity = Vector3.new(dir.X, y, dir.Z)
	bodyGyro.CFrame = cam.CFrame
end)

-- 9) Si mueres, se reinicia todo
player.CharacterAdded:Connect(function()
	volando, escaleraAgarrada = false, nil
	btnVolar.Text, btnEscalera.Text = "VOLAR", "ESCALERA"
end)

print("Steep Steps movil cargado")
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Steep Steps", Text = "Script cargado", Duration = 5})
end)
