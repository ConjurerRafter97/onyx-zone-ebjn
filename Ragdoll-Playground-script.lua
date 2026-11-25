local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local ENV = getgenv and getgenv() or _G

local state = {
	premium = false,
	ids = 0,
	pos = nil,
}

local orig = {}
local M = {}
local refreshButton
local conns = {}
local btn

local function say(fmt, ...)
	local s = string.format(fmt, ...)
	print("[TTO-PREM] " .. s)
	return s
end

local function mod(name)
	local ps = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerScripts")
	local root = ps and ps:FindFirstChild("TTOClient")
	if not root then return nil end
	local inst = root:FindFirstChild(name)
	if not inst then return nil end
	local ok, res = pcall(require, inst)
	if not ok then
		say("require %s failed: %s", name, tostring(res))
		return nil
	end
	return res
end

local function premiumIds()
	local ids = {}
	local Tools = M.Tools
	if Tools and Tools.LIST then
		for _, item in pairs(Tools.LIST) do
			if type(item) == "table" and item.premium and item.id then
				table.insert(ids, item.id)
			end
		end
	end
	return ids
end

local function realOwns(id)
	local P = M.Passes
	if not P then return false end
	if RunService:IsStudio() and P.studioUnlock then
		return true
	end
	local v1 = P.ALIAS[id] or id
	local cat = P.CAT[v1]
	if P.owned[v1] or P.packOwned.bundle or P.freeItems[v1] then
		return true
	end
	if not cat then
		return false
	end
	if P.trialOn then
		return true
	end
	if P.tryItem == v1 and os.clock() < (P.tryEnd or 0) then
		return true
	end
	if cat == "tools" or cat == "powers" then
		return P.packOwned[cat] == true
	end
	return false
end

local function realOwnsSkin(id, sub)
	local P = M.Passes
	return P.freeSkins[tostring(id) .. "/" .. tostring(sub)] == true
end

local function realIsVip()
	local P = M.Passes
	return P.packOwned.vip == true
end

local function realOwnsPack(pack)
	local P = M.Passes
	if pack == "vip" then
		return P.packOwned.vip == true
	end
	if P.packOwned[pack] == true then
		return true
	end
	return P.packOwned.bundle == true
end

local function truePackFlags()
	local flags = {}
	local mms = game:GetService("MarketplaceService")
	local uid = Players.LocalPlayer and Players.LocalPlayer.UserId
	local ids = (M.Passes and M.Passes.PACK_IDS) or {}
	for name, id in pairs(ids) do
		if type(id) == "number" and id ~= 0 and uid then
			local ok, has = pcall(function()
				return mms:UserOwnsGamePassAsync(uid, id)
			end)
			if ok and has == true then
				flags[name] = true
			end
		end
	end
	return flags
end

local function serverTrialLeft()
	local Products = M.Products
	if Products and Products.state then
		return tonumber(Products.state.trialLeft) or 0
	end
	return 0
end

local function setPremium(on)
	local P = M.Passes
	if not P then
		say("Passes module missing")
		return false
	end

	if on then
		if not orig.pack then
			orig.pack = {}
			for k, v in pairs(P.packOwned or {}) do
				orig.pack[k] = v
			end
			orig.trialOn = P.trialOn
			orig.studioUnlock = P.studioUnlock
		end

		P.owns = function(_)
			return true
		end
		P.ownsSkin = function()
			return true
		end
		P.isVip = function()
			return true
		end
		P.ownsPack = function(_)
			return true
		end
		P.trialOn = true
		P.studioUnlock = true
		P.packOwned = P.packOwned or {}
		P.packOwned.bundle = true
		P.packOwned.tools = true
		P.packOwned.powers = true
		P.packOwned.vip = true
		P.owned = P.owned or {}
		P.freeItems = P.freeItems or {}

		local ids = premiumIds()
		for _, id in ipairs(ids) do
			P.owned[id] = true
			P.freeItems[id] = true
			P.CAT = P.CAT or {}
			P.CAT[id] = P.CAT[id] or "tools"
		end
		state.ids = #ids
		state.premium = true
		say("premium ON: %d ids", #ids)
	else
		P.owns = realOwns
		P.ownsSkin = realOwnsSkin
		P.isVip = realIsVip
		P.ownsPack = realOwnsPack
		P.trialOn = serverTrialLeft() > 0
		P.studioUnlock = orig.studioUnlock
		local real = truePackFlags()
		for k in pairs(P.packOwned or {}) do
			P.packOwned[k] = nil
		end
		for k, v in pairs(real) do
			P.packOwned[k] = v
		end
		for _, id in ipairs(premiumIds()) do
			if P.owned then P.owned[id] = nil end
			if P.freeItems then P.freeItems[id] = nil end
		end
		state.premium = false
		say("premium OFF")
	end

	refreshButton()
	return true
end

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function moveTo(center)
	if not btn then return end
	local v = viewport()
	local ins = GuiService:GetGuiInset()
	local half = btn.AbsoluteSize * 0.5
	local cx = math.clamp(center.X, half.X, math.max(half.X, v.X - half.X))
	local cy = math.clamp(center.Y, half.Y, math.max(half.Y, v.Y - half.Y))
	btn.Position = UDim2.fromOffset(cx + ins.X, cy + ins.Y)
	state.pos = Vector2.new(cx, cy)
end

local function placeButton()
	if not btn then return end
	local v = viewport()
	local compact = v.X < 900 or v.Y < 620
	local w = compact and 104 or 118
	local h = compact and 26 or 30
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Size = UDim2.fromOffset(w, h)
	btn.TextSize = compact and 12 or 13
	if state.pos then
		moveTo(state.pos)
	else
		btn.Position = UDim2.new(0.5, 0, 0.5, GuiService:GetGuiInset().Y)
	end
end

refreshButton = function()
	if not btn then return end
	btn.Text = state.premium and ("PREMIUM ON " .. state.ids) or "PREMIUM OFF"
	btn.BackgroundColor3 = state.premium and Color3.fromRGB(38, 120, 74) or Color3.fromRGB(74, 44, 48)
end

local function destroyButton()
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(conns)
	if btn then
		pcall(function()
			btn:Destroy()
		end)
	end
	btn = nil
end

local function buildButton()
	destroyButton()

	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, c in pg:GetChildren() do
		if c:IsA("ScreenGui") and c.Name == "TTOPremium" then
			pcall(function()
				c:Destroy()
			end)
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "TTOPremium"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	gui.Parent = pg

	btn = Instance.new("TextButton")
	btn.Name = "PremiumToggle"
	btn.Text = ""
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(240, 244, 250)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 98, 120)
	stroke.Thickness = 1
	stroke.Parent = btn

	local drag = {
		active = false,
		moved = false,
		startPos = Vector2.zero,
		startCenter = Vector2.zero,
	}

	local function isPointer(t)
		return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
	end

	btn.InputBegan:Connect(function(input)
		if not isPointer(input.UserInputType) then return end
		drag.active = true
		drag.moved = false
		drag.startPos = Vector2.new(input.Position.X, input.Position.Y)
		drag.startCenter = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
	end)

	conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
		if not drag.active then return end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
		local p = Vector2.new(input.Position.X, input.Position.Y)
		local delta = p - drag.startPos
		if delta.Magnitude > 4 then
			drag.moved = true
		end
		if drag.moved then
			moveTo(drag.startCenter + delta)
		end
	end)

	conns[#conns + 1] = UserInputService.InputEnded:Connect(function(input)
		if not isPointer(input.UserInputType) then return end
		drag.active = false
	end)

	btn.Activated:Connect(function()
		if drag.moved then
			drag.moved = false
			return
		end
		setPremium(not state.premium)
	end)

	placeButton()
	refreshButton()
end

local function teardown()
	setPremium(false)
	destroyButton()
	state.premium = false
	rawset(ENV, "TTO", nil)
	say("torn down")
end

local function main()
	local prev = rawget(ENV, "TTO")
	if prev and type(prev.teardown) == "function" then
		pcall(prev.teardown)
	end

	M.Passes = mod("Passes")
	M.Tools = mod("Tools")
	M.Products = mod("Products")

	buildButton()
	setPremium(true)

	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			placeButton()
		end)
	end

	ENV.TTO = {
		state = state,
		modules = M,
		premium = setPremium,
		toggle = function()
			return setPremium(not state.premium)
		end,
		move = moveTo,
		teardown = teardown,
	}
	say("ready")
end

task.spawn(main)