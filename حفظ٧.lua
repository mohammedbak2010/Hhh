-- H2N | Ultimate Edition | Optimized for Weak Devices | FIXED SAVE + FLOAT CONTROLS
repeat task.wait() until game:IsLoaded()
if not game.PlaceId then repeat task.wait(1) until game.PlaceId end

pcall(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name and (v.Name:find("H2N_WP_") or v.Name:find("H2N_Duel_")) then
            v:Destroy()
        end
    end
end)

local Players        = game:GetService("Players")
local UIS            = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")
local TweenService   = game:GetService("TweenService")
local Lighting       = game:GetService("Lighting")
local LP             = Players.LocalPlayer
local Char, HRP, Hum

local function Setup(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
    pcall(function() HRP:SetNetworkOwner(LP) end)
end

if LP.Character then Setup(LP.Character) end
LP.CharacterAdded:Connect(function(c) task.wait(0.1); Setup(c) end)

-- ====== STATE ======
local State = {
    AutoPlayLeft=false, AutoPlayRight=false, AutoTrack=false,
    AutoGrab=false, AntiRagdoll=false, InfiniteJump=false,
    XrayBase=false, ESP=false, AntiSentry=false,
    SpinBody=false, FloatEnabled=false, AntiLag=false,
}

-- ====== SPEED BOOST SYSTEM ======
local SpeedSettings = {
    NormalSpeed = 52,
    HoldingSpeed = 27,
}
local DETECTION_THRESHOLD = 27
local IsHoldingBrainrot = false
local isSpeedBoostEnabled = false
local speedConn = nil

local function isHoldingBrainrot()
    local char = LP.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and (child.Name:lower():find("brainrot") or child.Name:lower():find("brain")) then
            return true
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed < DETECTION_THRESHOLD then return true end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("brainrot") or obj.Name:lower():find("brain")) then
            return true
        end
    end
    return false
end

local function updateCarryStatus()
    local newState = isHoldingBrainrot()
    if newState ~= IsHoldingBrainrot then
        IsHoldingBrainrot = newState
    end
end

local function startSpeedBoost()
    if isSpeedBoostEnabled then return end
    isSpeedBoostEnabled = true
    updateCarryStatus()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not isSpeedBoostEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        updateCarryStatus()
        local targetSpeed = IsHoldingBrainrot and SpeedSettings.HoldingSpeed or SpeedSettings.NormalSpeed
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * targetSpeed, hrp.AssemblyLinearVelocity.Y, moveDir.Z * targetSpeed)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        end
    end)
    if Hum then
        Hum.UseJumpPower = true
        Hum.JumpPower = 45
    end
    Save()
    Notify("⚡ Speed Boost ON")
end

local function stopSpeedBoost()
    if not isSpeedBoostEnabled then return end
    isSpeedBoostEnabled = false
    if speedConn then speedConn:Disconnect() end
    speedConn = nil
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        end
    end
    Save()
    Notify("⚡ Speed Boost OFF")
end

-- ====== ANTI-LAG (نسخة خفيفة جداً) ======
local isAntiLagEnabled = false
local originalLighting = {}

local function saveLightingSettings()
    originalLighting.GlobalShadows = Lighting.GlobalShadows
    originalLighting.Technology = Lighting.Technology
    originalLighting.Brightness = Lighting.Brightness
end

local function enableAntiLag()
    if isAntiLagEnabled then return end
    isAntiLagEnabled = true
    
    saveLightingSettings()
    Lighting.GlobalShadows = false
    Lighting.Technology = Enum.Technology.Compatibility
    Lighting.Brightness = 1
    
    task.spawn(function()
        while isAntiLagEnabled do
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or
                       obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                        obj.Enabled = false
                    end
                end
            end)
            task.wait(2)
        end
    end)
    
    Save()
    Notify("🎮 Anti-Lag ON | Shadows & Effects OFF")
end

local function disableAntiLag()
    if not isAntiLagEnabled then return end
    isAntiLagEnabled = false
    
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.Technology = originalLighting.Technology
    Lighting.Brightness = originalLighting.Brightness
    
    Save()
    Notify("🎮 Anti-Lag OFF")
end

-- ====== FLOAT (مطور بالكامل) ======
local FloatHeight = 11          -- ارتفاع التحليق
local FloatUpSpeed = 20         -- سرعة الصعود
local FloatDownSpeed = 15       -- سرعة النزول (قوة الدفع للأسفل)
local FloatConn = nil

local function startFloat()
    if State.FloatEnabled then return end
    State.FloatEnabled = true
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
    FloatConn = RunService.Heartbeat:Connect(function()
        if not State.FloatEnabled or not HRP then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = { char }
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rayParams)
        local groundY = result and result.Position.Y or (hrp.Position.Y - FloatHeight)
        local targetY = groundY + FloatHeight
        local diff = targetY - hrp.Position.Y
        if diff > 0.3 then
            local upSpeed = math.min(diff * 12, FloatUpSpeed)
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, upSpeed, hrp.AssemblyLinearVelocity.Z)
        elseif diff < -0.3 then
            local downSpeed = math.max(diff * 8, -FloatDownSpeed)
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, downSpeed, hrp.AssemblyLinearVelocity.Z)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end)
    Save()
    Notify("🕊️ Float ON | Height: "..FloatHeight.." | Up Speed: "..FloatUpSpeed)
end

local function stopFloat()
    State.FloatEnabled = false
    if FloatConn then
        FloatConn:Disconnect()
        FloatConn = nil
    end
    Save()
    Notify("🕊️ Float OFF")
end

-- ====== WAYPOINTS ======
local L1 = Vector3.new(-476, -6, 93)
local L2 = Vector3.new(-483, -4, 94)
local R1 = Vector3.new(-477, -6, 27)
local R2 = Vector3.new(-483, -4, 26)

local LEFT_ROUTE  = {"L1", "L2", "L1", "R1", "R2"}
local RIGHT_ROUTE = {"R1", "R2", "R1", "L1", "L2"}

local WP_PARTS = {}
local WP_COLORS = {
    L1=Color3.fromRGB(0,120,255), L2=Color3.fromRGB(0,220,255),
    R1=Color3.fromRGB(255,130,0), R2=Color3.fromRGB(255,50,50),
}

local function createWPPart(name, pos, color)
    local old = workspace:FindFirstChild("H2N_WP_"..name)
    if old then old:Destroy() end
    local part = Instance.new("Part")
    part.Name="H2N_WP_"..name; part.Size=Vector3.new(1.5,1.5,1.5)
    part.Position=pos; part.Anchored=true; part.CanCollide=false
    part.CanQuery=false; part.CastShadow=false
    part.Material=Enum.Material.Neon; part.Color=color; part.Transparency=0.1
    local bg=Instance.new("BillboardGui",part)
    bg.Size=UDim2.new(0,60,0,24); bg.StudsOffset=Vector3.new(0,1.8,0)
    bg.AlwaysOnTop=true; bg.LightInfluence=0
    local lbl=Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundColor3=Color3.fromRGB(0,0,0)
    lbl.BackgroundTransparency=0.3; lbl.Text=name
    lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.Font=Enum.Font.GothamBold; lbl.TextSize=16
    Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,4)
    part.Parent=workspace; WP_PARTS[name]=part; return part
end

local function initWPParts()
    createWPPart("L1",L1,WP_COLORS.L1); createWPPart("L2",L2,WP_COLORS.L2)
    createWPPart("R1",R1,WP_COLORS.R1); createWPPart("R2",R2,WP_COLORS.R2)
end

local function getWP(name)
    local p=WP_PARTS[name]; if p and p.Parent then return p.Position end
    if name=="L1" then return L1 elseif name=="L2" then return L2
    elseif name=="R1" then return R1 else return R2 end
end

-- ====== KEYBINDS ======
local Keys = {
    InfJump       = Enum.KeyCode.J,
    AutoPlayLeft  = Enum.KeyCode.G,
    AutoPlayRight = Enum.KeyCode.H,
    AutoTrack     = Enum.KeyCode.T,
    AntiRagdoll   = Enum.KeyCode.K,
    Float         = Enum.KeyCode.F,
    SpeedBoost    = Enum.KeyCode.B,
    AntiLag       = Enum.KeyCode.L,
}
local KeyEnabled = {
    InfJump       = true,
    AutoPlayLeft  = true,
    AutoPlayRight = true,
    AutoTrack     = true,
    AntiRagdoll   = true,
    Float         = true,
    SpeedBoost    = true,
    AntiLag       = true,
}

-- ====== CONFIG VARIABLES ======
local TRACK_SPEED      = 55
local GRAB_RATE        = 0.17
local GRAB_RADIUS      = 11
local SideButtonSize   = 80
local menuW, menuH     = 350, 350
local StealBarVisible  = true
local ButtonPositions  = {}
local sideHiddenMap    = {}
local SPIN_SPEED       = 25
local XRAY_TRANSPARENCY = 0.68
local DETECTION_DISTANCE = 60
local PULL_DISTANCE    = -5
local DUEL_APPROACH_SPD = 48
local DUEL_RETURN_SPD  = 26
local menu             = nil

-- ====== SAVE SYSTEM (تم الإصلاح) ======
local CFG = "H2N_Config.json"

local function Save()
    local menuPos = {X=0.5, XO=0, Y=0.52, YO=0}
    if menu then
        menuPos = {
            X  = menu.Position.X.Scale,
            XO = menu.Position.X.Offset,
            Y  = menu.Position.Y.Scale,
            YO = menu.Position.Y.Offset,
        }
    end
    local data = {
        -- أرقام
        TRACK_SPEED      = TRACK_SPEED,
        GRAB_RATE        = GRAB_RATE,
        GRAB_RADIUS      = GRAB_RADIUS,
        SideButtonSize   = SideButtonSize,
        menuW            = menuW,
        menuH            = menuH,
        menuPos          = menuPos,
        DUEL_APPROACH_SPD = DUEL_APPROACH_SPD,
        DUEL_RETURN_SPD  = DUEL_RETURN_SPD,
        FloatHeight      = FloatHeight,
        FloatUpSpeed     = FloatUpSpeed,
        FloatDownSpeed   = FloatDownSpeed,
        NormalSpeed      = SpeedSettings.NormalSpeed,
        HoldingSpeed     = SpeedSettings.HoldingSpeed,
        -- احداثيات
        L1 = {X=L1.X, Y=L1.Y, Z=L1.Z},
        L2 = {X=L2.X, Y=L2.Y, Z=L2.Z},
        R1 = {X=R1.X, Y=R1.Y, Z=R1.Z},
        R2 = {X=R2.X, Y=R2.Y, Z=R2.Z},
        -- مفاتيح
        Keys = {
            InfJump       = Keys.InfJump.Name,
            AutoPlayLeft  = Keys.AutoPlayLeft.Name,
            AutoPlayRight = Keys.AutoPlayRight.Name,
            AutoTrack     = Keys.AutoTrack.Name,
            AntiRagdoll   = Keys.AntiRagdoll.Name,
            Float         = Keys.Float.Name,
            SpeedBoost    = Keys.SpeedBoost.Name,
            AntiLag       = Keys.AntiLag.Name,
        },
        KeyEnabled = {
            InfJump       = KeyEnabled.InfJump,
            AutoPlayLeft  = KeyEnabled.AutoPlayLeft,
            AutoPlayRight = KeyEnabled.AutoPlayRight,
            AutoTrack     = KeyEnabled.AutoTrack,
            AntiRagdoll   = KeyEnabled.AntiRagdoll,
            Float         = KeyEnabled.Float,
            SpeedBoost    = KeyEnabled.SpeedBoost,
            AntiLag       = KeyEnabled.AntiLag,
        },
        -- حالات ON/OFF
        ST_AutoTrack     = State.AutoTrack,
        ST_AutoGrab      = State.AutoGrab,
        ST_AntiSentry    = State.AntiSentry,
        ST_SpinBody      = State.SpinBody,
        ST_AntiRagdoll   = State.AntiRagdoll,
        ST_InfiniteJump  = State.InfiniteJump,
        ST_FloatEnabled  = State.FloatEnabled,
        ST_AntiLag       = isAntiLagEnabled,
        ST_XrayBase      = State.XrayBase,
        ST_ESP           = State.ESP,
        ST_SpeedBoost    = isSpeedBoostEnabled,
        -- إعدادات أخرى
        StealBarVisible  = StealBarVisible,
        sideHiddenMap    = sideHiddenMap,
        ButtonPositions  = ButtonPositions,
    }
    pcall(function() writefile(CFG, HttpService:JSONEncode(data)) end)
end

local function Load()
    local ok, raw = pcall(readfile, CFG)
    if not ok or not raw or raw == "" then return end
    local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(d) ~= "table" then return end

    -- أرقام
    if d.TRACK_SPEED       then TRACK_SPEED       = d.TRACK_SPEED       end
    if d.GRAB_RATE         then GRAB_RATE         = d.GRAB_RATE         end
    if d.GRAB_RADIUS       then GRAB_RADIUS       = d.GRAB_RADIUS       end
    if d.SideButtonSize    then SideButtonSize    = d.SideButtonSize    end
    if d.menuW             then menuW             = d.menuW             end
    if d.menuH             then menuH             = d.menuH             end
    if d.DUEL_APPROACH_SPD then DUEL_APPROACH_SPD = d.DUEL_APPROACH_SPD end
    if d.DUEL_RETURN_SPD   then DUEL_RETURN_SPD   = d.DUEL_RETURN_SPD   end
    if d.FloatHeight       then FloatHeight       = d.FloatHeight       end
    if d.FloatUpSpeed      then FloatUpSpeed      = math.clamp(d.FloatUpSpeed, 5, 50) end
    if d.FloatDownSpeed    then FloatDownSpeed    = math.clamp(d.FloatDownSpeed, 5, 50) end
    if d.NormalSpeed       then SpeedSettings.NormalSpeed  = d.NormalSpeed  end
    if d.HoldingSpeed      then SpeedSettings.HoldingSpeed = d.HoldingSpeed end

    -- احداثيات
    if d.L1 then L1 = Vector3.new(d.L1.X, d.L1.Y, d.L1.Z) end
    if d.L2 then L2 = Vector3.new(d.L2.X, d.L2.Y, d.L2.Z) end
    if d.R1 then R1 = Vector3.new(d.R1.X, d.R1.Y, d.R1.Z) end
    if d.R2 then R2 = Vector3.new(d.R2.X, d.R2.Y, d.R2.Z) end

    -- مفاتيح
    if type(d.Keys) == "table" then
        for k, v in pairs(d.Keys) do
            local e = Enum.KeyCode[v]
            if e and Keys[k] ~= nil then Keys[k] = e end
        end
    end
    if type(d.KeyEnabled) == "table" then
        for k, v in pairs(d.KeyEnabled) do
            if KeyEnabled[k] ~= nil then KeyEnabled[k] = v end
        end
    end

    -- حالات ON/OFF (تم الإصلاح)
    if d.ST_AutoTrack    ~= nil then State.AutoTrack    = d.ST_AutoTrack    end
    if d.ST_AutoGrab     ~= nil then State.AutoGrab     = d.ST_AutoGrab     end
    if d.ST_AntiSentry   ~= nil then State.AntiSentry   = d.ST_AntiSentry   end
    if d.ST_SpinBody     ~= nil then State.SpinBody     = d.ST_SpinBody     end
    if d.ST_AntiRagdoll  ~= nil then State.AntiRagdoll  = d.ST_AntiRagdoll  end   -- تم الإصلاح: استخدام State.AntiRagdoll
    if d.ST_InfiniteJump ~= nil then State.InfiniteJump = d.ST_InfiniteJump end
    if d.ST_FloatEnabled ~= nil then State.FloatEnabled = d.ST_FloatEnabled end
    if d.ST_AntiLag      ~= nil then isAntiLagEnabled   = d.ST_AntiLag      end
    if d.ST_XrayBase     ~= nil then State.XrayBase     = d.ST_XrayBase     end
    if d.ST_ESP          ~= nil then State.ESP          = d.ST_ESP          end
    if d.ST_SpeedBoost   ~= nil then isSpeedBoostEnabled = d.ST_SpeedBoost  end

    -- إعدادات أخرى
    if d.StealBarVisible ~= nil            then StealBarVisible = d.StealBarVisible end
    if type(d.sideHiddenMap) == "table"    then sideHiddenMap   = d.sideHiddenMap   end
    if type(d.ButtonPositions) == "table"  then ButtonPositions  = d.ButtonPositions  end

    if type(d.menuPos) == "table" then
        task.defer(function()
            if menu then
                menu.Position = UDim2.new(d.menuPos.X, d.menuPos.XO, d.menuPos.Y, d.menuPos.YO)
            end
        end)
    end
end

-- ====== AUTO DUEL ======
local aplConn, aprConn = nil, nil
local aplPhase, aprPhase = 1, 1

local function getHRP2() 
    local char = LP.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function MoveToPoint(hrp, targetPos, speed)
    if not hrp or not targetPos then return true end
    local myPos = hrp.Position
    local xzDist = Vector2.new(targetPos.X - myPos.X, targetPos.Z - myPos.Z).Magnitude
    if xzDist < 1.2 then
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        return true
    end
    local direction = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z).Unit
    hrp.AssemblyLinearVelocity = Vector3.new(direction.X * speed, hrp.AssemblyLinearVelocity.Y, direction.Z * speed)
    return false
end

local function StopAutoPlayLeft()
    if not State.AutoPlayLeft then return end
    State.AutoPlayLeft = false
    if aplConn then aplConn:Disconnect() end
    aplConn = nil
    aplPhase = 1
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
end

local function StopAutoPlayRight()
    if not State.AutoPlayRight then return end
    State.AutoPlayRight = false
    if aprConn then aprConn:Disconnect() end
    aprConn = nil
    aprPhase = 1
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
end

local function updateAutoPlayLeft()
    if not State.AutoPlayLeft then
        if aplConn then aplConn:Disconnect(); aplConn = nil end
        return
    end
    local h = getHRP2()
    if not h then return end
    local target = LEFT_ROUTE[aplPhase]
    if not target then StopAutoPlayLeft(); return end
    local targetPos = getWP(target)
    if not targetPos then return end
    local spd = (aplPhase <= 2) and DUEL_APPROACH_SPD or DUEL_RETURN_SPD
    local reached = MoveToPoint(h, targetPos, spd)
    if reached then
        aplPhase = aplPhase + 1
        if aplPhase > #LEFT_ROUTE then StopAutoPlayLeft() end
    end
end

local function updateAutoPlayRight()
    if not State.AutoPlayRight then
        if aprConn then aprConn:Disconnect(); aprConn = nil end
        return
    end
    local h = getHRP2()
    if not h then return end
    local target = RIGHT_ROUTE[aprPhase]
    if not target then StopAutoPlayRight(); return end
    local targetPos = getWP(target)
    if not targetPos then return end
    local spd = (aprPhase <= 2) and DUEL_APPROACH_SPD or DUEL_RETURN_SPD
    local reached = MoveToPoint(h, targetPos, spd)
    if reached then
        aprPhase = aprPhase + 1
        if aprPhase > #RIGHT_ROUTE then StopAutoPlayRight() end
    end
end

local function StartAutoPlayLeft()
    if State.AutoPlayLeft then StopAutoPlayLeft() end
    if State.AutoPlayRight then StopAutoPlayRight() end
    State.AutoPlayLeft = true
    aplPhase = 1
    if Hum then Hum.AutoRotate = false end
    if aplConn then aplConn:Disconnect() end
    aplConn = RunService.Heartbeat:Connect(updateAutoPlayLeft)
    Notify("▶ Auto Play Left: L1→L2→L1→R1→R2")
end

local function StartAutoPlayRight()
    if State.AutoPlayRight then StopAutoPlayRight() end
    if State.AutoPlayLeft then StopAutoPlayLeft() end
    State.AutoPlayRight = true
    aprPhase = 1
    if Hum then Hum.AutoRotate = false end
    if aprConn then aprConn:Disconnect() end
    aprConn = RunService.Heartbeat:Connect(updateAutoPlayRight)
    Notify("▶ Auto Play Right: R1→R2→R1→L1→L2")
end

-- ====== AUTO TRACK ======
local trackConn = nil
local trackAlignOri = nil
local trackAttachment = nil

local function GetClosestPlayer()
    if not HRP then return nil end
    local closest, best = nil, 9999
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local d = (HRP.Position - root.Position).Magnitude
                if d < best then best = d; closest = root end
            end
        end
    end
    return closest
end

local function setupTrackAlign()
    if not HRP then return false end
    if trackAlignOri then pcall(function() trackAlignOri:Destroy() end); trackAlignOri = nil end
    if trackAttachment then pcall(function() trackAttachment:Destroy() end); trackAttachment = nil end
    trackAttachment = Instance.new("Attachment")
    trackAttachment.Name = "H2N_Track_Att"
    trackAttachment.Parent = HRP
    trackAlignOri = Instance.new("AlignOrientation")
    trackAlignOri.Name = "H2N_Track_Align"
    trackAlignOri.Attachment0 = trackAttachment
    trackAlignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    trackAlignOri.RigidityEnabled = true
    trackAlignOri.MaxTorque = 1000000
    trackAlignOri.Responsiveness = 200
    trackAlignOri.Enabled = false
    trackAlignOri.Parent = HRP
    return true
end

local function StartAutoTrack()
    State.AutoTrack = true
    setupTrackAlign()
    if trackConn then trackConn:Disconnect() end
    trackConn = RunService.Heartbeat:Connect(function()
        if not State.AutoTrack or not HRP then
            if trackAlignOri then trackAlignOri.Enabled = false end
            return
        end
        local target = GetClosestPlayer()
        if target then
            local dir = Vector3.new(target.Position.X - HRP.Position.X, 0, target.Position.Z - HRP.Position.Z)
            if dir.Magnitude > 1 then
                HRP.AssemblyLinearVelocity = dir.Unit * TRACK_SPEED
            else
                HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
            end
            if trackAlignOri then
                trackAlignOri.Enabled = true
                local lookPos = Vector3.new(target.Position.X, HRP.Position.Y, target.Position.Z)
                trackAlignOri.CFrame = CFrame.lookAt(HRP.Position, lookPos)
            end
            if Hum then Hum.AutoRotate = false end
        else
            HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
            if trackAlignOri then trackAlignOri.Enabled = false end
            if Hum then Hum.AutoRotate = true end
        end
    end)
    Save()
    Notify("Auto Track ON")
end

local function StopAutoTrack()
    State.AutoTrack = false
    if trackConn then trackConn:Disconnect(); trackConn = nil end
    if trackAlignOri then trackAlignOri:Destroy() end
    if trackAttachment then trackAttachment:Destroy() end
    if HRP then HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
    Save()
    Notify("Auto Track OFF")
end

-- ====== ANTI RAGDOLL (نسخة متطورة) ======
local antiRagdollConn = nil
local isRagdollRecovering = false

local function StartAntiRagdoll()
    if State.AntiRagdoll then return end
    State.AntiRagdoll = true
    if antiRagdollConn then antiRagdollConn:Disconnect() end
    
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not State.AntiRagdoll then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.Health <= 0 then return end
        
        local state = hum:GetState()
        local isRagdoll = (state == Enum.HumanoidStateType.Physics or 
                           state == Enum.HumanoidStateType.Ragdoll or 
                           state == Enum.HumanoidStateType.FallingDown)
        
        if isRagdoll and not isRagdollRecovering then
            isRagdollRecovering = true
            
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then
                    pcall(function() obj:Destroy() end)
                elseif obj:IsA("Motor6D") and obj.Enabled == false then
                    obj.Enabled = true
                end
            end
            
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
            
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CameraSubject = hum
            end
            
            pcall(function()
                if LP.Character then
                    local playerModule = LP.PlayerScripts:FindFirstChild("PlayerModule")
                    if playerModule then
                        local controls = require(playerModule:FindFirstChild("ControlModule"))
                        controls:Enable()
                    end
                end
            end)
            
            task.wait(0.1)
            isRagdollRecovering = false
        end
    end)
    
    Save()
    Notify("🛡️ Anti Ragdoll ON")
end

local function StopAntiRagdoll()
    if not State.AntiRagdoll then return end
    State.AntiRagdoll = false
    if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
    isRagdollRecovering = false
    Save()
    Notify("🛡️ Anti Ragdoll OFF")
end

-- ====== INFINITE JUMP ======
local jumpConn = nil
local function StartInfiniteJump()
    if State.InfiniteJump then return end
    State.InfiniteJump = true
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    jumpConn = UIS.JumpRequest:Connect(function()
        if not State.InfiniteJump or not HRP or not Hum then return end
        if Hum:GetState() == Enum.HumanoidStateType.Dead then return end
        local v = HRP.AssemblyLinearVelocity
        HRP.AssemblyLinearVelocity = Vector3.new(v.X, 50, v.Z)
    end)
    Save()
    Notify("Infinite Jump ON")
end

local function StopInfiniteJump()
    State.InfiniteJump = false
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    Save()
    Notify("Infinite Jump OFF")
end

-- ====== ANTI DIE ======
local antiDieConn = nil
local function startPermanentAntiDie()
    if antiDieConn then antiDieConn:Disconnect() end
    antiDieConn = RunService.Heartbeat:Connect(function()
        if not Hum or not Hum.Parent then return end
        if Hum.Health <= 0 then pcall(function() Hum.Health = Hum.MaxHealth * 0.9 end) end
        pcall(function() Hum.RequiresNeck = false end)
        if HRP and HRP.Position.Y < -10 then HRP.CFrame = CFrame.new(HRP.Position.X, -4, HRP.Position.Z) end
    end)
end
task.spawn(function() task.wait(0.5); startPermanentAntiDie() end)

-- ====== AUTO GRAB ======
local grabBarRef = {fill=nil, pct=nil, radiusLbl=nil, rateLbl=nil}
local grabMainConn = nil; local grabTimer = 0; local stealCache = {}

local function UpdateGrabBar(pct)
    if grabBarRef.fill then grabBarRef.fill.Size = UDim2.new(math.clamp(pct/100,0,1),0,1,0) end
    if grabBarRef.pct then grabBarRef.pct.Text = math.floor(pct).."%" end
    if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = GRAB_RADIUS.."st" end
    if grabBarRef.rateLbl then grabBarRef.rateLbl.Text = string.format("%.3f",GRAB_RATE).."s" end
end

local function IsOwnPrompt(p) return Char and p:IsDescendantOf(Char) end

local function GetPromptPos(prompt)
    local pos
    pcall(function()
        local par = prompt.Parent
        if par:IsA("BasePart") then pos = par.Position
        elseif par:IsA("Attachment") then pos = par.WorldPosition
        elseif par:IsA("Model") then
            local pp = par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
            if pp then pos = pp.Position end
        else
            local bp = par:FindFirstChildWhichIsA("BasePart", true)
            if bp then pos = bp.Position end
        end
    end)
    return pos
end

local function buildCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = {holdCBs={}, triggerCBs={}, ready=true}
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1)=="table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function)=="function" then table.insert(data.holdCBs, conn.Function) end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2)=="table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function)=="function" then table.insert(data.triggerCBs, conn.Function) end
        end
    end
    if #data.holdCBs > 0 or #data.triggerCBs > 0 then stealCache[prompt] = data end
end

local function execSteal(prompt)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    task.spawn(function()
        for _, fn in ipairs(data.holdCBs) do task.spawn(fn) end
        task.wait(0.1)
        for _, fn in ipairs(data.triggerCBs) do task.spawn(fn) end
        task.wait(0.01); data.ready = true
    end)
    return true
end

local function firePrompt(prompt)
    local fired = false
    pcall(function()
        if fireproximityprompt then prompt.HoldDuration = 0; fireproximityprompt(prompt,0,0); fired = true end
    end)
    if fired then return end
    local ok, conns = pcall(getconnections, prompt.Triggered)
    if ok and type(conns)=="table" then
        for _, c in ipairs(conns) do if c.Function then task.spawn(c.Function) end end; return
    end
    pcall(function() prompt:InputHoldBegin(); task.delay(0.05, function() pcall(function() prompt:InputHoldEnd() end) end) end)
end

local function StartAutoGrab()
    if State.AutoGrab then return end
    State.AutoGrab = true; grabTimer = 0; stealCache = {}; UpdateGrabBar(0)
    if grabMainConn then grabMainConn:Disconnect() end
    grabMainConn = RunService.Heartbeat:Connect(function(dt)
        if not State.AutoGrab then grabMainConn:Disconnect(); grabMainConn = nil; UpdateGrabBar(0); return end
        if not HRP then return end
        local bestPrompt, bestDist = nil, GRAB_RADIUS
        local plots = workspace:FindFirstChild("Plots")
        if plots then
            for _, plot in pairs(plots:GetChildren()) do
                for _, desc in pairs(plot:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled and not IsOwnPrompt(desc) then
                        local pos = GetPromptPos(desc)
                        if pos then
                            local d = (HRP.Position - pos).Magnitude
                            if d < bestDist then bestDist = d; bestPrompt = desc end
                        end
                    end
                end
            end
        end
        if bestPrompt then
            grabTimer = grabTimer + dt; UpdateGrabBar((grabTimer/GRAB_RATE)*100)
            if grabTimer >= GRAB_RATE then
                grabTimer = 0; buildCallbacks(bestPrompt)
                if not execSteal(bestPrompt) then firePrompt(bestPrompt) end
            end
        else grabTimer = 0; UpdateGrabBar(0) end
    end)
    Save()
    Notify("Auto Grab ON")
end

local function StopAutoGrab()
    if not State.AutoGrab then return end
    State.AutoGrab = false
    if grabMainConn then grabMainConn:Disconnect(); grabMainConn = nil end
    UpdateGrabBar(0)
    Save()
    Notify("Auto Grab OFF")
end

-- ====== XRAY ======
local baseOT = {}; local plotConns = {}; local xrayCon = nil
local function applyXray(plot)
    if baseOT[plot] then return end; baseOT[plot] = {}
    for _, p in ipairs(plot:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 0.6 then baseOT[plot][p] = p.Transparency; p.Transparency = XRAY_TRANSPARENCY end
    end
    plotConns[plot] = plot.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.Transparency < 0.6 then baseOT[plot][d] = d.Transparency; d.Transparency = XRAY_TRANSPARENCY end
    end)
end
local function StartXrayBase()
    if State.XrayBase then return end
    State.XrayBase = true
    local plots = workspace:FindFirstChild("Plots"); if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do applyXray(plot) end
    xrayCon = plots.ChildAdded:Connect(function(p) task.wait(0.2); applyXray(p) end)
    Save()
    Notify("Xray Base ON")
end
local function StopXrayBase()
    if not State.XrayBase then return end
    State.XrayBase = false
    for _, conn in pairs(plotConns) do conn:Disconnect() end; plotConns = {}
    if xrayCon then xrayCon:Disconnect(); xrayCon = nil end
    for _, parts in pairs(baseOT) do
        for part, orig in pairs(parts) do if part and part.Parent then part.Transparency = orig end end
    end
    baseOT = {}
    Save()
    Notify("Xray Base OFF")
end

-- ====== ESP ======
local espHL = {}
local function ClearESP() for _, h in pairs(espHL) do if h and h.Parent then h:Destroy() end end; espHL = {} end
local function StartESP()
    if State.ESP then return end
    State.ESP = true; Save(); Notify("ESP ON")
end
local function StopESP()
    if not State.ESP then return end
    State.ESP = false; ClearESP(); Save(); Notify("ESP OFF")
end
local function updateESP()
    if not State.ESP then return end
    for player, h in pairs(espHL) do
        if not player or not player.Character then if h and h.Parent then h:Destroy() end; espHL[player] = nil end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and (not espHL[p] or not espHL[p].Parent) then
            local h = Instance.new("Highlight")
            h.FillColor = Color3.fromRGB(255,0,0); h.OutlineColor = Color3.fromRGB(255,255,255)
            h.FillTransparency = 0.5; h.OutlineTransparency = 0; h.Adornee = p.Character; h.Parent = p.Character
            espHL[p] = h
        end
    end
end

-- ====== ANTI SENTRY ======
local antiSentryTarget = nil
local function findSentryTarget()
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPos = char.HumanoidRootPart.Position
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:find("Sentry") and not obj.Name:lower():find("bullet") then
            local ownerId = obj.Name:match("Sentry_(%d+)")
            if ownerId and tonumber(ownerId) == LP.UserId then continue end
            local part = (obj:IsA("BasePart") and obj) or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
            if part and (rootPos - part.Position).Magnitude <= DETECTION_DISTANCE then return obj end
        end
    end
end
local function moveSentry(obj)
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, p in pairs(obj:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    local root = char.HumanoidRootPart; local cf = root.CFrame * CFrame.new(0,0,PULL_DISTANCE)
    if obj:IsA("BasePart") then obj.CFrame = cf
    elseif obj:IsA("Model") then local m = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if m then m.CFrame = cf end end
end
local function getWeapon()
    local char = LP.Character; if not char then return nil end
    return LP.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
end
local function attackSentry()
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local weapon = getWeapon(); if not weapon then return end
    if weapon.Parent == LP.Backpack then hum:EquipTool(weapon); task.wait(0.1) end
    pcall(function() weapon:Activate() end)
    for _, r in pairs(weapon:GetDescendants()) do if r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end end
end
local function StartAntiSentry()
    if State.AntiSentry then return end
    State.AntiSentry = true; Save(); Notify("Anti Sentry ON")
end
local function StopAntiSentry()
    if not State.AntiSentry then return end
    State.AntiSentry = false; antiSentryTarget = nil; Save(); Notify("Anti Sentry OFF")
end
local function updateAntiSentry()
    if not State.AntiSentry then return end
    if antiSentryTarget and antiSentryTarget.Parent == workspace then moveSentry(antiSentryTarget); attackSentry()
    else antiSentryTarget = findSentryTarget() end
end

-- ====== SPIN BODY ======
local spinForce = nil
local function StartSpinBody()
    if State.SpinBody then return end
    State.SpinBody = true
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root or spinForce then return end
    spinForce = Instance.new("BodyAngularVelocity")
    spinForce.Name = "SpinForce"; spinForce.AngularVelocity = Vector3.new(0,SPIN_SPEED,0)
    spinForce.MaxTorque = Vector3.new(0,math.huge,0); spinForce.P = 1250; spinForce.Parent = root
    Save()
    Notify("Spin Body ON")
end
local function StopSpinBody()
    if not State.SpinBody then return end
    State.SpinBody = false; if spinForce then spinForce:Destroy(); spinForce = nil end
    Save()
    Notify("Spin Body OFF")
end

-- ====== Speed Display ======
local speedBB = nil
local function CreateSpeedBillboard()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    if speedBB then speedBB:Destroy() end
    speedBB = Instance.new("BillboardGui")
    speedBB.Name = "H2N_SpeedDisplay"
    speedBB.Adornee = head
    speedBB.Size = UDim2.new(0, 100, 0, 24)
    speedBB.StudsOffset = Vector3.new(0, 2, 0)
    speedBB.AlwaysOnTop = true
    speedBB.Parent = head
    local label = Instance.new("TextLabel", speedBB)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Speed: 0"
    label.TextColor3 = Color3.fromRGB(255, 50, 50)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Name = "SpeedLabel"
end

local function UpdateSpeedDisplay()
    if not speedBB then return end
    local label = speedBB:FindFirstChild("SpeedLabel")
    if not label then return end
    if not HRP then return end
    local vel = HRP.AssemblyLinearVelocity
    local horizontalSpeed = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
    label.Text = string.format("Speed: %d", horizontalSpeed)
end

CreateSpeedBillboard()
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    CreateSpeedBillboard()
end)

-- ====== GUI ======
local gui = Instance.new("ScreenGui")
gui.Name = "H2N"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP:WaitForChild("PlayerGui")

-- Steal Bar
local stealBarFrame = Instance.new("Frame", gui)
stealBarFrame.Name = "StealBar"
stealBarFrame.Size = UDim2.new(0,340,0,36)
stealBarFrame.Position = UDim2.new(0.5,-170,1,-55)
stealBarFrame.BackgroundColor3 = Color3.fromRGB(15,0,0)
stealBarFrame.ZIndex = 8
stealBarFrame.Visible = StealBarVisible
stealBarFrame.Active = true
Instance.new("UICorner", stealBarFrame).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", stealBarFrame).Color = Color3.fromRGB(220,0,0)

do
    local sbDrag, sbDS, sbPS = false, nil, nil
    stealBarFrame.InputBegan:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            sbDrag = true; sbDS = inp.Position; sbPS = stealBarFrame.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not sbDrag then return end
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local d = inp.Position - sbDS
            stealBarFrame.Position = UDim2.new(sbPS.X.Scale, sbPS.X.Offset + d.X, sbPS.Y.Scale, sbPS.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then sbDrag = false end
    end)
end

local sbLabel = Instance.new("TextLabel", stealBarFrame)
sbLabel.Size = UDim2.new(0,48,1,0)
sbLabel.BackgroundTransparency = 1
sbLabel.Text = "GRAB"
sbLabel.TextColor3 = Color3.fromRGB(255,50,50)
sbLabel.Font = Enum.Font.GothamBold
sbLabel.TextSize = 12
sbLabel.ZIndex = 9

local sbBG = Instance.new("Frame", stealBarFrame)
sbBG.Size = UDim2.new(1,-160,0,14)
sbBG.Position = UDim2.new(0,48,0.5,-7)
sbBG.BackgroundColor3 = Color3.fromRGB(40,0,0)
sbBG.ZIndex = 9
Instance.new("UICorner", sbBG).CornerRadius = UDim.new(0,6)

local sbFill = Instance.new("Frame", sbBG)
sbFill.Size = UDim2.new(0,0,1,0)
sbFill.BackgroundColor3 = Color3.fromRGB(255,0,0)
sbFill.ZIndex = 10
Instance.new("UICorner", sbFill).CornerRadius = UDim.new(0,6)

local sbPct = Instance.new("TextLabel", stealBarFrame)
sbPct.Size = UDim2.new(0,34,1,0)
sbPct.Position = UDim2.new(1,-110,0,0)
sbPct.BackgroundTransparency = 1
sbPct.Text = "0%"
sbPct.TextColor3 = Color3.fromRGB(255,255,255)
sbPct.Font = Enum.Font.GothamBold
sbPct.TextSize = 11
sbPct.ZIndex = 9

local sbRadius = Instance.new("TextLabel", stealBarFrame)
sbRadius.Size = UDim2.new(0,38,1,0)
sbRadius.Position = UDim2.new(1,-76,0,0)
sbRadius.BackgroundTransparency = 1
sbRadius.Text = GRAB_RADIUS .. "st"
sbRadius.TextColor3 = Color3.fromRGB(255,160,0)
sbRadius.Font = Enum.Font.GothamBold
sbRadius.TextSize = 11
sbRadius.ZIndex = 9

local sbRate = Instance.new("TextLabel", stealBarFrame)
sbRate.Size = UDim2.new(0,50,1,0)
sbRate.Position = UDim2.new(1,-50,0,0)
sbRate.BackgroundTransparency = 1
sbRate.Text = string.format("%.3f", GRAB_RATE) .. "s"
sbRate.TextColor3 = Color3.fromRGB(100,255,100)
sbRate.Font = Enum.Font.GothamBold
sbRate.TextSize = 10
sbRate.ZIndex = 9

grabBarRef.fill = sbFill
grabBarRef.pct = sbPct
grabBarRef.radiusLbl = sbRadius
grabBarRef.rateLbl = sbRate

-- Menu Button
local menuBtn = Instance.new("TextButton", gui)
menuBtn.Size = UDim2.new(0,90,0,40)
menuBtn.Position = UDim2.new(0.5,-45,0.07,0)
menuBtn.BackgroundColor3 = Color3.fromRGB(15,0,0)
menuBtn.Text = "H2N"
menuBtn.TextColor3 = Color3.fromRGB(255,40,40)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 18
menuBtn.Active = true
menuBtn.Draggable = true
menuBtn.ZIndex = 10
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", menuBtn).Color = Color3.fromRGB(220,0,0)

-- Menu Frame
menu = Instance.new("Frame", gui)
menu.Size = UDim2.new(0, menuW, 0, menuH)
menu.Position = UDim2.new(0.5,0,0.52,0)
menu.AnchorPoint = Vector2.new(0.5,0.5)
menu.BackgroundColor3 = Color3.fromRGB(10,0,0)
menu.Visible = false
menu.Active = true
menu.Draggable = false
menu.ZIndex = 9
Instance.new("UICorner", menu).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke", menu).Color = Color3.fromRGB(220,0,0)

menuBtn.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)

-- Header
local header = Instance.new("Frame", menu)
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(20,0,0)
header.BackgroundTransparency = 0.8
header.BorderSizePixel = 0
header.ZIndex = 10
Instance.new("UICorner", header).CornerRadius = UDim.new(0,12)

local tl = Instance.new("TextLabel", header)
tl.Size = UDim2.new(1,-20,0,30)
tl.Position = UDim2.new(0,10,0,3)
tl.BackgroundTransparency = 1
tl.Text = "H2N"
tl.TextColor3 = Color3.fromRGB(255,40,40)
tl.Font = Enum.Font.GothamBold
tl.TextSize = 17
tl.TextXAlignment = Enum.TextXAlignment.Left

local dragging = false
local dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = menu.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                Save()
            end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Tabs
local tabBar = Instance.new("Frame", menu)
tabBar.Size = UDim2.new(0,110,1,-44)
tabBar.Position = UDim2.new(0,8,0,44)
tabBar.BackgroundColor3 = Color3.fromRGB(20,0,0)
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0,10)

local tabNames = {"Combat", "Protect", "Visual", "Settings"}
local tabFrames = {}
local tabBtns = {}

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton", tabBar)
    tb.Size = UDim2.new(1,-12,0,38)
    tb.Position = UDim2.new(0,6,0,(i-1)*44+8)
    tb.BackgroundColor3 = Color3.fromRGB(40,0,0)
    tb.Text = name
    tb.TextColor3 = Color3.fromRGB(255,40,40)
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 14
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,8)
    tabBtns[name] = tb

    local sf = Instance.new("ScrollingFrame", menu)
    sf.Size = UDim2.new(1,-128,1,-44)
    sf.Position = UDim2.new(0,122,0,44)
    sf.BackgroundTransparency = 1
    sf.Visible = (i == 1)
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(220,0,0)
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabFrames[name] = sf

    tb.MouseButton1Click:Connect(function()
        for _, f in pairs(tabFrames) do f.Visible = false end
        for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(40,0,0) end
        sf.Visible = true
        tb.BackgroundColor3 = Color3.fromRGB(130,0,0)
    end)
end
tabBtns["Combat"].BackgroundColor3 = Color3.fromRGB(130,0,0)

local function Notify(txt)
    local f = Instance.new("Frame", gui)
    f.Size = UDim2.new(0,270,0,42)
    f.Position = UDim2.new(1,-290,1,-100)
    f.AnchorPoint = Vector2.new(0,1)
    f.BackgroundColor3 = Color3.fromRGB(15,0,0)
    f.ZIndex = 25
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", f).Color = Color3.fromRGB(220,0,0)
    local fl = Instance.new("TextLabel", f)
    fl.Size = UDim2.new(1,0,1,0)
    fl.BackgroundTransparency = 1
    fl.Text = txt
    fl.TextColor3 = Color3.fromRGB(255,255,255)
    fl.Font = Enum.Font.GothamBold
    fl.TextSize = 14
    task.spawn(function() task.wait(3); f:Destroy() end)
end

-- ====== MAKE TOGGLE ======
local toggleUpdaters = {}

local function MakeToggle(parent, text, order, cb, getState, featureName)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.60,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0.34,0,0.75,0)
    btn.Position = UDim2.new(0.63,0,0.12,0)
    btn.BackgroundColor3 = Color3.fromRGB(50,0,0)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(180,0,0)
    
    local function UpdateButton()
        if getState() then
            btn.Text = "ON"
            btn.BackgroundColor3 = Color3.fromRGB(180,0,0)
        else
            btn.Text = "OFF"
            btn.BackgroundColor3 = Color3.fromRGB(50,0,0)
        end
    end
    UpdateButton()
    
    btn.MouseButton1Click:Connect(function()
        local newState = not getState()
        cb(newState)
        UpdateButton()
        Save()
    end)

    RunService.RenderStepped:Connect(UpdateButton)
    
    if featureName then
        toggleUpdaters[featureName] = function(state)
            if state then cb(true) else cb(false) end
            UpdateButton()
        end
    end
    
    return btn
end

local function MakeNumberBox(parent, text, default, order, cb, minVal, maxVal)
    minVal = minVal or 1
    maxVal = maxVal or 200
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.36,0,0.75,0)
    box.Position = UDim2.new(0.60,0,0.12,0)
    box.BackgroundColor3 = Color3.fromRGB(10,0,0)
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 16
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(220,0,0)
    
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then 
            n = math.clamp(n, minVal, maxVal)
            cb(n) 
            box.Text = tostring(n)
        else 
            box.Text = tostring(default) 
        end
        Save()
    end)
    return box
end

-- ====== KEYBIND ======
local function MakeKeybind(parent, labelText, keyName, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.45,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0.2,0,0.75,0)
    keyBtn.Position = UDim2.new(0.45,0,0.12,0)
    keyBtn.BackgroundColor3 = Color3.fromRGB(10,0,0)
    keyBtn.Text = Keys[keyName] and Keys[keyName].Name or "?"
    keyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 12
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", keyBtn).Color = Color3.fromRGB(220,0,0)
    
    local enableBtn = Instance.new("TextButton", row)
    enableBtn.Size = UDim2.new(0.2,0,0.75,0)
    enableBtn.Position = UDim2.new(0.68,0,0.12,0)
    enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Color3.fromRGB(60,180,60) or Color3.fromRGB(180,60,60)
    enableBtn.Text = KeyEnabled[keyName] and "ON" or "OFF"
    enableBtn.TextColor3 = Color3.fromRGB(255,255,255)
    enableBtn.Font = Enum.Font.GothamBold
    enableBtn.TextSize = 12
    Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", enableBtn).Color = Color3.fromRGB(220,0,0)
    
    local listening = false
    local listenConn
    
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = Color3.fromRGB(60,20,0)
        if listenConn then listenConn:Disconnect() end
        listenConn = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Keys[keyName] = input.KeyCode
                keyBtn.Text = input.KeyCode.Name
                keyBtn.BackgroundColor3 = Color3.fromRGB(10,0,0)
                listening = false
                listenConn:Disconnect()
                Notify("Key " .. labelText .. " = " .. input.KeyCode.Name)
                Save()
            end
        end)
    end)
    
    enableBtn.MouseButton1Click:Connect(function()
        KeyEnabled[keyName] = not KeyEnabled[keyName]
        enableBtn.Text = KeyEnabled[keyName] and "ON" or "OFF"
        enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Color3.fromRGB(60,180,60) or Color3.fromRGB(180,60,60)
        Save()
    end)
end

-- ====== COMBAT TAB ======
local ci = 0
local combat = tabFrames["Combat"]
MakeToggle(combat, "Auto Track", ci, function(s) if s then StartAutoTrack() else StopAutoTrack() end end, function() return State.AutoTrack end, "AutoTrack"); ci = ci + 1
MakeNumberBox(combat, "Track Speed", TRACK_SPEED, ci, function(v) TRACK_SPEED = math.clamp(v,10,200); Notify("Track Speed = "..TRACK_SPEED) end, 10, 200); ci = ci + 1
MakeToggle(combat, "Auto Play Left", ci, function(s) if s then StartAutoPlayLeft() else StopAutoPlayLeft() end end, function() return State.AutoPlayLeft end, "AutoPlayLeft"); ci = ci + 1
MakeToggle(combat, "Auto Play Right", ci, function(s) if s then StartAutoPlayRight() else StopAutoPlayRight() end end, function() return State.AutoPlayRight end, "AutoPlayRight"); ci = ci + 1
MakeToggle(combat, "Auto Grab", ci, function(s) if s then StartAutoGrab() else StopAutoGrab() end end, function() return State.AutoGrab end, "AutoGrab"); ci = ci + 1
MakeNumberBox(combat, "Grab Radius", GRAB_RADIUS, ci, function(v) GRAB_RADIUS = math.clamp(v,1,100); if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = GRAB_RADIUS.."st" end; if State.AutoGrab then StopAutoGrab(); task.wait(0.05); StartAutoGrab() end end, 1, 100); ci = ci + 1
MakeNumberBox(combat, "Grab Rate(s)", GRAB_RATE, ci, function(v) GRAB_RATE = math.max(v,0.001); if grabBarRef.rateLbl then grabBarRef.rateLbl.Text = string.format("%.3f",GRAB_RATE).."s" end; if State.AutoGrab then StopAutoGrab(); task.wait(0.05); StartAutoGrab() end; Notify("Grab Rate = "..string.format("%.3f",GRAB_RATE).."s") end, 0.001, 5); ci = ci + 1
MakeNumberBox(combat, "Duel Approach Spd", DUEL_APPROACH_SPD, ci, function(v) DUEL_APPROACH_SPD = math.clamp(v,1,300); Notify("Approach = "..DUEL_APPROACH_SPD) end, 1, 300); ci = ci + 1
MakeNumberBox(combat, "Duel Return Spd", DUEL_RETURN_SPD, ci, function(v) DUEL_RETURN_SPD = math.clamp(v,1,300); Notify("Return = "..DUEL_RETURN_SPD) end, 1, 300); ci = ci + 1
MakeToggle(combat, "Anti Sentry", ci, function(s) if s then StartAntiSentry() else StopAntiSentry() end end, function() return State.AntiSentry end, "AntiSentry"); ci = ci + 1
MakeToggle(combat, "Spin Body", ci, function(s) if s then StartSpinBody() else StopSpinBody() end end, function() return State.SpinBody end, "SpinBody"); ci = ci + 1
MakeToggle(combat, "Speed Boost", ci, function(s) if s then startSpeedBoost() else stopSpeedBoost() end end, function() return isSpeedBoostEnabled end, "SpeedBoost"); ci = ci + 1
MakeNumberBox(combat, "Normal Speed (No Brainrot)", SpeedSettings.NormalSpeed, ci, function(v) SpeedSettings.NormalSpeed = math.clamp(v,1,200); Notify("Normal Speed = "..SpeedSettings.NormalSpeed) end, 1, 200); ci = ci + 1
MakeNumberBox(combat, "Steal Speed (With Brainrot)", SpeedSettings.HoldingSpeed, ci, function(v) SpeedSettings.HoldingSpeed = math.clamp(v,1,200); Notify("Steal Speed = "..SpeedSettings.HoldingSpeed) end, 1, 200); ci = ci + 1

-- ====== PROTECT TAB ======
local pi = 0
local protect = tabFrames["Protect"]
MakeToggle(protect, "Anti Ragdoll", pi, function(s) if s then StartAntiRagdoll() else StopAntiRagdoll() end end, function() return State.AntiRagdoll end, "AntiRagdoll"); pi = pi + 1
MakeToggle(protect, "Infinite Jump", pi, function(s) if s then StartInfiniteJump() else StopInfiniteJump() end end, function() return State.InfiniteJump end, "InfiniteJump"); pi = pi + 1
MakeToggle(protect, "FLOAT", pi, function(s) if s then startFloat() else stopFloat() end end, function() return State.FloatEnabled end, "FloatEnabled"); pi = pi + 1

-- إعدادات Float الجديدة
MakeNumberBox(protect, "Float Height", FloatHeight, pi, function(v) FloatHeight = math.clamp(v, 3, 50); if State.FloatEnabled then stopFloat(); task.wait(0.1); startFloat() end; Notify("Float Height = "..FloatHeight) end, 3, 50); pi = pi + 1
MakeNumberBox(protect, "Float Up Speed", FloatUpSpeed, pi, function(v) FloatUpSpeed = math.clamp(v, 5, 50); Notify("Float Up Speed = "..FloatUpSpeed) end, 5, 50); pi = pi + 1
MakeNumberBox(protect, "Float Down Speed", FloatDownSpeed, pi, function(v) FloatDownSpeed = math.clamp(v, 5, 50); Notify("Float Down Speed = "..FloatDownSpeed) end, 5, 50); pi = pi + 1

MakeToggle(protect, "ANTI-LAG (Clean Visuals)", pi, function(s) if s then enableAntiLag() else disableAntiLag() end end, function() return isAntiLagEnabled end, "AntiLag"); pi = pi + 1

-- ====== VISUAL TAB ======
local vi = 0
local visual = tabFrames["Visual"]
MakeToggle(visual, "ESP", vi, function(s) if s then StartESP() else StopESP() end end, function() return State.ESP end, "ESP"); vi = vi + 1
MakeToggle(visual, "Xray Base", vi, function(s) if s then StartXrayBase() else StopXrayBase() end end, function() return State.XrayBase end, "XrayBase"); vi = vi + 1

local hideAllState = false
MakeToggle(visual, "Hide All Side Btns", vi, function(state)
    hideAllState = state
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local id = b:GetAttribute("ID")
            if state then b.Visible = false; sideHiddenMap[id.."_all"] = true
            else if not sideHiddenMap[id.."_individual"] then b.Visible = true end; sideHiddenMap[id.."_all"] = false end
        end
    end
    Save()
end, function() return hideAllState end); vi = vi + 1

local sideNames = {"AUTO PLAY LEFT", "AUTO PLAY RIGHT", "AUTO TRACK", "FLOAT", "SPEED BOOST", "ANTI-LAG"}
for _, nm in ipairs(sideNames) do
    MakeToggle(visual, "Hide "..nm, vi, function(state)
        sideHiddenMap[nm.."_individual"] = state
        for _, b in pairs(gui:GetChildren()) do
            if b:IsA("Frame") and b.Name == "SideButton" and b:GetAttribute("ID") == nm then b.Visible = not state end
        end
        Save()
    end, function() return sideHiddenMap[nm.."_individual"] == true end); vi = vi + 1
end

MakeToggle(visual, "Show Steal Bar", vi, function(s) StealBarVisible = s; stealBarFrame.Visible = s; Save() end, function() return StealBarVisible end); vi = vi + 1
MakeNumberBox(visual, "Side Btn Size", SideButtonSize, vi, function(val) SideButtonSize = val; for _, b in pairs(gui:GetChildren()) do if b:IsA("Frame") and b.Name == "SideButton" then b.Size = UDim2.new(0,SideButtonSize,0,SideButtonSize) end end end, 40, 150); vi = vi + 1
MakeNumberBox(visual, "Menu Width", menuW, vi, function(v) menuW = math.clamp(v,200,750); menu.Size = UDim2.new(0,menuW,0,menuH) end, 200, 750); vi = vi + 1
MakeNumberBox(visual, "Menu Height", menuH, vi, function(v) menuH = math.clamp(v,200,750); menu.Size = UDim2.new(0,menuW,0,menuH) end, 200, 750); vi = vi + 1

-- ====== SETTINGS TAB ======
local si = 0
local sTab = tabFrames["Settings"]

local copyBtn = Instance.new("TextButton", sTab)
copyBtn.Size = UDim2.new(1, -10, 0, 40)
copyBtn.Position = UDim2.new(0, 5, 0, si * 44 + 4)
copyBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
copyBtn.Text = "📋 COPY DISCORD LINK"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
copyBtn.MouseButton1Click:Connect(function()
    setclipboard("discord.gg/UeKPQC7fq")
    copyBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
    task.wait(0.5)
    copyBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    Notify("Discord link copied!")
end)
si = si + 1

local wpSep = Instance.new("TextLabel", sTab)
wpSep.Size = UDim2.new(1,-10,0,20)
wpSep.Position = UDim2.new(0,5,0,si*44+4)
wpSep.BackgroundTransparency = 1
wpSep.Text = "─── DUEL COORDS (NEW POS) ───"
wpSep.TextColor3 = Color3.fromRGB(0,200,255)
wpSep.Font = Enum.Font.GothamBold
wpSep.TextSize = 12
si = si + 1

local WPS = {
    {name="L1",label="L1 pos",color=Color3.fromRGB(0,120,255)},
    {name="L2",label="L2 pos",color=Color3.fromRGB(0,220,255)},
    {name="R1",label="R1 pos",color=Color3.fromRGB(255,130,0)},
    {name="R2",label="R2 pos",color=Color3.fromRGB(255,50,50)},
}
for _, wp in ipairs(WPS) do
    local fr = Instance.new("Frame", sTab)
    fr.Size = UDim2.new(1,-10,0,40)
    fr.Position = UDim2.new(0,5,0,si*44+4)
    fr.BackgroundTransparency = 1
    local setBtn = Instance.new("TextButton", fr)
    setBtn.Size = UDim2.new(1,0,0.8,0)
    setBtn.Position = UDim2.new(0,0,0.1,0)
    setBtn.BackgroundColor3 = Color3.fromRGB(8,8,8)
    setBtn.Font = Enum.Font.GothamBold
    setBtn.TextSize = 13
    setBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", setBtn).CornerRadius = UDim.new(0,8)
    local bs = Instance.new("UIStroke", setBtn)
    bs.Color = wp.color
    bs.Thickness = 1.5
    local inner = Instance.new("TextLabel", setBtn)
    inner.Size = UDim2.new(1,-10,1,0)
    inner.Position = UDim2.new(0,10,0,0)
    inner.BackgroundTransparency = 1
    inner.Font = Enum.Font.GothamBold
    inner.TextSize = 13
    inner.TextColor3 = Color3.fromRGB(255,255,255)
    inner.TextXAlignment = Enum.TextXAlignment.Left
    inner.Text = wp.label
    local wn = wp.name
    local wc = wp.color
    setBtn.MouseButton1Click:Connect(function()
        if not HRP then Notify("No character!"); return end
        local pos = HRP.Position
        if wn == "L1" then L1 = pos
        elseif wn == "L2" then L2 = pos
        elseif wn == "R1" then R1 = pos
        elseif wn == "R2" then R2 = pos end
        local part = WP_PARTS[wn]
        if part and part.Parent then part.Position = pos
        else createWPPart(wn, pos, wc) end
        setBtn.BackgroundColor3 = Color3.fromRGB(0,50,0)
        task.spawn(function() task.wait(1.5); setBtn.BackgroundColor3 = Color3.fromRGB(8,8,8) end)
        Notify(wn.." set to: "..math.floor(pos.X)..", "..math.floor(pos.Y)..", "..math.floor(pos.Z))
        Save()
    end)
    si = si + 1
end

local sep = Instance.new("TextLabel", sTab)
sep.Size = UDim2.new(1,-10,0,20)
sep.Position = UDim2.new(0,5,0,si*44+4)
sep.BackgroundTransparency = 1
sep.Text = "───────── KEYBINDS ─────────"
sep.TextColor3 = Color3.fromRGB(0,170,255)
sep.Font = Enum.Font.GothamBold
sep.TextSize = 12
si = si + 1

MakeKeybind(sTab, "Inf Jump Key (J)", "InfJump", si); si = si + 1
MakeKeybind(sTab, "Auto Left Key (G)", "AutoPlayLeft", si); si = si + 1
MakeKeybind(sTab, "Auto Right Key (H)", "AutoPlayRight", si); si = si + 1
MakeKeybind(sTab, "Auto Track Key (T)", "AutoTrack", si); si = si + 1
MakeKeybind(sTab, "Anti Ragdoll Key (K)", "AntiRagdoll", si); si = si + 1
MakeKeybind(sTab, "Float Key (F)", "Float", si); si = si + 1
MakeKeybind(sTab, "Speed Boost Key (B)", "SpeedBoost", si); si = si + 1
MakeKeybind(sTab, "Anti-Lag Key (L)", "AntiLag", si); si = si + 1

-- ====== KEYBINDS INPUT ======
UIS.InputBegan:Connect(function(input, gpe)
    if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode
    
    if KeyEnabled["InfJump"] and k == Keys.InfJump then
        if State.InfiniteJump then StopInfiniteJump() else StartInfiniteJump() end
    elseif KeyEnabled["AutoPlayLeft"] and k == Keys.AutoPlayLeft then
        if State.AutoPlayLeft then StopAutoPlayLeft() else StartAutoPlayLeft() end
    elseif KeyEnabled["AutoPlayRight"] and k == Keys.AutoPlayRight then
        if State.AutoPlayRight then StopAutoPlayRight() else StartAutoPlayRight() end
    elseif KeyEnabled["AutoTrack"] and k == Keys.AutoTrack then
        if State.AutoTrack then StopAutoTrack() else StartAutoTrack() end
    elseif KeyEnabled["AntiRagdoll"] and k == Keys.AntiRagdoll then
        if State.AntiRagdoll then StopAntiRagdoll() else StartAntiRagdoll() end
    elseif KeyEnabled["Float"] and k == Keys.Float then
        if State.FloatEnabled then stopFloat() else startFloat() end
    elseif KeyEnabled["SpeedBoost"] and k == Keys.SpeedBoost then
        if isSpeedBoostEnabled then stopSpeedBoost() else startSpeedBoost() end
    elseif KeyEnabled["AntiLag"] and k == Keys.AntiLag then
        if isAntiLagEnabled then disableAntiLag() else enableAntiLag() end
    end
end)

-- ====== SIDE BUTTONS ======
local activeTouchForDrag = nil

local function CreateSideButton(text, side, index, getState, startFn, stopFn)
    local btn = Instance.new("Frame", gui)
    btn.Name = "SideButton"
    btn:SetAttribute("ID", text)
    btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
    btn.BackgroundColor3 = Color3.fromRGB(40,0,0)
    btn.Active = true
    btn.ZIndex = 5
    btn.Visible = not (sideHiddenMap[text.."_individual"] == true)

    local sp = ButtonPositions[text]
    if sp then
        btn.Position = UDim2.new(sp.X, sp.XO, sp.Y, sp.YO)
    elseif side == "left" then
        btn.Position = UDim2.new(0,10,0.22+index*0.19,0)
    else
        btn.Position = UDim2.new(1,-(SideButtonSize+10),0.22+index*0.19,0)
    end

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,14)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(220,0,0)
    stroke.Thickness = 2

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1,-4,0.55,0)
    lbl.Position = UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextWrapped = true

    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0,10,0,10)
    dot.Position = UDim2.new(0.5,-5,1,-13)
    dot.BackgroundColor3 = Color3.fromRGB(80,0,0)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local function RefreshVisual()
        if getState() then
            dot.BackgroundColor3 = Color3.fromRGB(220,0,0)
            btn.BackgroundColor3 = Color3.fromRGB(120,0,0)
        else
            dot.BackgroundColor3 = Color3.fromRGB(80,0,0)
            btn.BackgroundColor3 = Color3.fromRGB(40,0,0)
        end
    end

    local pressing, hasMoved, dragStart, btnStart, activeInput = false, false, nil, nil, nil

    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if activeTouchForDrag ~= nil then return end
        if pressing then return end
        pressing = true
        hasMoved = false
        activeInput = input
        activeTouchForDrag = input
        dragStart = input.Position
        btnStart = btn.Position
    end)

    UIS.InputChanged:Connect(function(input)
        if not pressing or input ~= activeInput then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement then return end
        if not dragStart then return end
        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then
            hasMoved = true
            btn.Position = UDim2.new(btnStart.X.Scale, btnStart.X.Offset + delta.X, btnStart.Y.Scale, btnStart.Y.Offset + delta.Y)
        end
    end)

    btn.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if not pressing or input ~= activeInput then return end
        pressing = false
        activeInput = nil
        activeTouchForDrag = nil

        if not hasMoved then
            task.spawn(function()
                btn.Size = UDim2.new(0, SideButtonSize * 0.88, 0, SideButtonSize * 0.88)
                task.wait(0.07)
                btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
            end)
            if getState() then stopFn() else startFn() end
            RefreshVisual()
        elseif hasMoved then
            local p = btn.Position
            ButtonPositions[text] = {X = p.X.Scale, XO = p.X.Offset, Y = p.Y.Scale, YO = p.Y.Offset}
            Save()
        end
        hasMoved = false
        dragStart = nil
    end)

    RunService.RenderStepped:Connect(function()
        if not pressing then RefreshVisual() end
    end)
end

-- الجانب الأيسر (Left Side) - 3 أزرار
CreateSideButton("AUTO PLAY LEFT", "left", 0, function() return State.AutoPlayLeft end, StartAutoPlayLeft, StopAutoPlayLeft)
CreateSideButton("AUTO PLAY RIGHT", "left", 1, function() return State.AutoPlayRight end, StartAutoPlayRight, StopAutoPlayRight)
CreateSideButton("AUTO TRACK", "left", 2, function() return State.AutoTrack end, StartAutoTrack, StopAutoTrack)

-- الجانب الأيمن (Right Side) - 3 أزرار
CreateSideButton("FLOAT", "right", 0, function() return State.FloatEnabled end, startFloat, stopFloat)
CreateSideButton("SPEED BOOST", "right", 1, function() return isSpeedBoostEnabled end, startSpeedBoost, stopSpeedBoost)
CreateSideButton("ANTI-LAG", "right", 2, function() return isAntiLagEnabled end, enableAntiLag, disableAntiLag)

-- ====== MAIN HEARTBEAT ======
RunService.Heartbeat:Connect(function(dt)
    if State.AutoPlayLeft then updateAutoPlayLeft() end
    if State.AutoPlayRight then updateAutoPlayRight() end
    if State.AntiSentry then updateAntiSentry() end
    if State.ESP then updateESP() end
    UpdateSpeedDisplay()
end)

-- ====== INIT ======
Load()
initWPParts()
stealBarFrame.Visible = StealBarVisible
menu.Size = UDim2.new(0, menuW, 0, menuH)

for _, b in pairs(gui:GetChildren()) do
    if b:IsA("Frame") and b.Name == "SideButton" then
        b.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
        local id = b:GetAttribute("ID")
        local sp = ButtonPositions[id]
        if sp then
            b.Position = UDim2.new(sp.X, sp.XO, sp.Y, sp.YO)
        end
        if sideHiddenMap[id.."_individual"] == true then
            b.Visible = false
        end
    end
end

-- تفعيل الميزات المحفوظة (تم الإصلاح)
task.spawn(function()
    while not (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character:FindFirstChildOfClass("Humanoid")) do
        task.wait(0.2)
    end
    task.wait(0.5)
    
    -- حفظ القيم الحالية قبل التعطيل المؤقت
    local savedTrack    = State.AutoTrack
    local savedGrab     = State.AutoGrab
    local savedSentry   = State.AntiSentry
    local savedSpin     = State.SpinBody
    local savedRagdoll  = State.AntiRagdoll
    local savedJump     = State.InfiniteJump
    local savedFloat    = State.FloatEnabled
    local savedXray     = State.XrayBase
    local savedESP      = State.ESP
    local savedAntiLag  = isAntiLagEnabled
    local savedSpeed    = isSpeedBoostEnabled
    
    -- تعطيل الكل مؤقتاً لتجنب التداخل
    State.AutoTrack    = false
    State.AutoGrab     = false
    State.AntiSentry   = false
    State.SpinBody     = false
    State.InfiniteJump = false
    State.FloatEnabled = false
    State.XrayBase     = false
    State.ESP          = false
    State.AntiRagdoll  = false
    isAntiLagEnabled    = false
    isSpeedBoostEnabled = false
    
    local function safeStart(fn, name)
        task.spawn(function()
            pcall(function()
                fn()
                print("✅ تم تفعيل تلقائياً: " .. name)
            end)
        end)
        task.wait(0.05)
    end
    
    if savedTrack   then safeStart(StartAutoTrack, "Auto Track") end
    if savedGrab    then safeStart(StartAutoGrab, "Auto Grab") end
    if savedSentry  then safeStart(StartAntiSentry, "Anti Sentry") end
    if savedSpin    then safeStart(StartSpinBody, "Spin Body") end
    if savedRagdoll then safeStart(StartAntiRagdoll, "Anti Ragdoll") end
    if savedJump    then safeStart(StartInfiniteJump, "Infinite Jump") end
    if savedFloat   then safeStart(startFloat, "Float") end
    if savedXray    then safeStart(StartXrayBase, "Xray Base") end
    if savedESP     then safeStart(StartESP, "ESP") end
    if savedAntiLag then safeStart(enableAntiLag, "Anti Lag") end
    if savedSpeed   then safeStart(startSpeedBoost, "Speed Boost") end
    
    task.wait(0.3)
    -- تحديث مظهر الأزرار الجانبية
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local id = b:GetAttribute("ID")
            if id == "AUTO PLAY LEFT" then
                b.BackgroundColor3 = State.AutoPlayLeft and Color3.fromRGB(120,0,0) or Color3.fromRGB(40,0,0)
            elseif id == "AUTO PLAY RIGHT" then
                b.BackgroundColor3 = State.AutoPlayRight and Color3.fromRGB(120,0,0) or Color3.fromRGB(40,0,0)
            elseif id == "AUTO TRACK" then
                b.BackgroundColor3 = State.AutoTrack and Color3.fromRGB(120,0,0) or Color3.fromRGB(40,0,0)
            elseif id == "FLOAT" then
                b.BackgroundColor3 = State.FloatEnabled and Color3.fromRGB(120,0,0) or Color3.fromRGB(40,0,0)
            elseif id == "SPEED BOOST" then
                b.BackgroundColor3 = isSpeedBoostEnabled and Color3.fromRGB(120,0,0) or Color3.fromRGB(40,0,0)
            elseif id == "ANTI-LAG" then
                b.BackgroundColor3 = isAntiLagEnabled and Color3.fromRGB(120,0,0) or Color3.fromRGB(40,0,0)
            end
        end
    end
    
    -- تحديث الأزرار في تبويب Protect بعد التحميل
    task.wait(0.2)
    if toggleUpdaters["AntiRagdoll"] then toggleUpdaters["AntiRagdoll"](State.AntiRagdoll) end
    if toggleUpdaters["InfiniteJump"] then toggleUpdaters["InfiniteJump"](State.InfiniteJump) end
    if toggleUpdaters["FloatEnabled"] then toggleUpdaters["FloatEnabled"](State.FloatEnabled) end
    if toggleUpdaters["AntiLag"] then toggleUpdaters["AntiLag"](isAntiLagEnabled) end
    if toggleUpdaters["SpeedBoost"] then toggleUpdaters["SpeedBoost"](isSpeedBoostEnabled) end
    if toggleUpdaters["AutoTrack"] then toggleUpdaters["AutoTrack"](State.AutoTrack) end
    if toggleUpdaters["AutoGrab"] then toggleUpdaters["AutoGrab"](State.AutoGrab) end
    if toggleUpdaters["AntiSentry"] then toggleUpdaters["AntiSentry"](State.AntiSentry) end
    if toggleUpdaters["SpinBody"] then toggleUpdaters["SpinBody"](State.SpinBody) end
    if toggleUpdaters["XrayBase"] then toggleUpdaters["XrayBase"](State.XrayBase) end
    if toggleUpdaters["ESP"] then toggleUpdaters["ESP"](State.ESP) end
    if toggleUpdaters["AutoPlayLeft"] then toggleUpdaters["AutoPlayLeft"](State.AutoPlayLeft) end
    if toggleUpdaters["AutoPlayRight"] then toggleUpdaters["AutoPlayRight"](State.AutoPlayRight) end
end)

Notify("H2N Ultimate | Optimized for Weak Devices | All Features Auto-Save")

print("=" .. string.rep("=", 65))
print("📌 التحديثات الجديدة:")
print("=" .. string.rep("=", 65))
print("1. ✅ تم إصلاح حفظ Anti Ragdoll (يتم حفظ حالته الآن)")
print("2. ✅ تم إصلاح حفظ Auto Grab (يتم حفظ حالته الآن)")
print("3. ✅ تم إضافة التحكم بارتفاع Float (3-50)")
print("4. ✅ تم إضافة التحكم بسرعة صعود Float (5-50)")
print("5. ✅ تم إضافة التحكم بسرعة نزول Float (5-50)")
print("6. ✅ تم تحسين سرعة استجابة Float")
print("=" .. string.rep("=", 65))
print("⌨️ KEYBINDS:")
print("✓ G=AutoLeft | H=AutoRight | T=AutoTrack | F=Float")
print("✓ B=SpeedBoost | L=AntiLag | J=InfJump | K=AntiRagdoll")
print("=" .. string.rep("=", 65))