-- SteepFlight v4 - Deteccion bajo tus pies (Raycast) + Soporte Modelo y Pieza
-- Para Delta (telefono).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local VELOCIDAD = 16
local volando = false
local escalera = nil
local subir = false
local bajar = false
local conexion = nil

-- Funcion para anclar/desanclar piezas o Modelos enteros
local function setAnchored(obj, estado)
	if not obj then return end
	if obj:IsA("BasePart") then
		obj.Anchored = estado
	elseif obj:IsA("Model") then
		for _, p in ipairs(obj:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = estado
			end
		end
	end
end

-- Buscar la escalera: detecta lo que tienes exactamente bajo tus pies
local function buscarMiEscalera()
	local char = player.Character
	if not char then return nil, "Sin personaje" end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil, "Sin HumanoidRootPart" end

	-- 1. Raycast hacia abajo: detecta lo que estas pisando
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = RaycastFilterType.Exclude
	params.IgnoreWater = true

	local rayo = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params)
	if rayo and rayo.Instance and rayo.Instance ~= workspace.Terrain then
		local hit = rayo.Instance
		-- Si forma parte de un modelo (la escalera entera)
		local model = hit:FindFirstAncestorOfClass("Model")
		if model and model ~= workspace and not model:FindFirstChildOfClass("Humanoid") then
			return model, model.Name
		end
		return hit, hit.Name
	end

	-- 2. Si no estas parado encima, busca por proximidad (radio 15 studs)
	local masCercano = nil
	local menorDist = 15
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj:IsDescendantOf(char) and obj ~= workspace.Terrain then
			local n = string.lower(obj.Name)
			if string.find(n, "ladder") or string.find(n, "escalera") or string.find(n, "step") or string.find(n, "rung") then
				local dist = (obj.Position - root.Position).Magnitude
				if dist < menorDist then
					menorDist = dist
					local model = obj:FindFirstAncestorOfClass("Model")
					if model and model ~= workspace and not model:FindFirstChildOfClass("Humanoid") then
						masCercano = model
					else
						masCercano = obj
					end
				end
			end
		end
	end

	if masCercano then
		return masCercano, masCercano.Name
	end

	return nil, "No se detecto nada bajo tus pies"
end

-- Interfaz en pantalla
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
aviso.Size = UDim2.new(0, 280, 0, 32)
aviso.Position = UDim2.new(0.5, -140, 0, 10)
aviso.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aviso.TextColor3 = Color3.new(1, 1, 1)
aviso.Text = "SteepFlight v4 listo"
aviso.Font = Enum.Font.GothamBold
aviso.TextSize = 13
aviso.Parent = gui
local ac = Instance.new("UICorner")
ac.CornerRadius = UDim.new(0, 8)
ac.Parent = aviso

local function mensaje(t)
	aviso.Text = tostring(t)
	task.delay(2.5, function()
		if volando then
			aviso.Text = "VOLANDO"
		else
			aviso.Text = "SteepFlight v4"
		end
	end)
end

local bVolar = boton("VOLAR", -200, -120, Color3.fromRGB(0, 170, 80))
local bSubir = boton("SUBIR", -105, -180, Color3.fromRGB(60, 60, 200))
local bBajar = boton("BAJAR", -105, -60, Color3.fromRGB(60, 60, 200))
local bMas = boton("+", -200, -180, Color3.fromRGB(90, 90, 90))
local bMenos = boton("-", -200, -60, Color3.fromRGB(90, 90, 90))

-- Bucle de vuelo
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
		if delta.Magnitude > 0 then
			escalera:PivotTo(escalera:GetPivot() + delta)
			root.CFrame = root.CFrame + delta
		end
	end)
end

bVolar.MouseButton1Click:Connect(function()
	if not volando then
		local obj, nombre = buscarMiEscalera()
		if not obj then
			mensaje("ERROR: " .. (nombre or "No encontrada"))
			return
		end
		escalera = obj
		setAnchored(escalera, true)
		volando = true
		bVolar.Text = "ATERRIZAR"
		bVolar.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		empezarVuelo()
		mensaje("CONECTADO A: " .. tostring(nombre))
	else
		volando = false
		if escalera and escalera.Parent then
			setAnchored(escalera, false)
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
