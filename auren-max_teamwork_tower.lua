-- =============================================
-- Auren MAX - Teamwork Tower v10.0
-- Green-Black Luxury | ESP + Fly | Anti-KB
-- Responsive UI | All Screens | Lua Optimized
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local DESTROYED = false

-- Logo + Flags: load asynchronously so intro appears INSTANTLY
local LOGO_ASSET = nil
local LOGO_URL = "https://i.postimg.cc/TYJ5nqD5/file-000000009f9071fd9e08e99d8439917f.png"
local FLAG_EN_URL = "https://i.postimg.cc/wxSD9xDR/Flag-of-the-United-States.jpg"
local FLAG_TH_URL = "https://i.postimg.cc/1RNN7xbP/Flag-of-Thailand.jpg"
local FLAG_EN_ASSET, FLAG_TH_ASSET = nil, nil

-- Shared HTTP request finder
local function getHttpReq()
    local httpReq = nil
    pcall(function() if syn and syn.request then httpReq = syn.request end end)
    if not httpReq then pcall(function() if http and http.request then httpReq = http.request end end) end
    if not httpReq then pcall(function() if http_request then httpReq = http_request end end) end
    if not httpReq then pcall(function() if request then httpReq = request end end) end
    if not httpReq then pcall(function() if fluxus and fluxus.request then httpReq = fluxus.request end end) end
    return httpReq
end

-- Shared download-and-cache helper
local function downloadAndCache(url, filename)
    local getAsset = getcustomasset or getsynasset
    local writeF = writefile
    if not writeF or not getAsset then return nil end
    -- Check cache first
    if isfile and isfile(filename) then
        local a; pcall(function() a = getAsset(filename) end); if a then return a end
    end
    -- Download
    local httpReq = getHttpReq()
    if httpReq then
        local ok, resp = pcall(function() return httpReq({Url = url, Method = "GET"}) end)
        if ok and resp and resp.Body and #resp.Body > 100 then
            pcall(function() writeF(filename, resp.Body) end)
            local a; pcall(function() a = getAsset(filename) end); return a
        end
    end
    return nil
end

-- Check cached files first (instant, no HTTP)
pcall(function()
    local getAsset = getcustomasset or getsynasset
    if isfile and getAsset then
        if isfile("AurenMAX_logo.png") then LOGO_ASSET = getAsset("AurenMAX_logo.png") end
        if isfile("AurenMAX_flag_en.jpg") then FLAG_EN_ASSET = getAsset("AurenMAX_flag_en.jpg") end
        if isfile("AurenMAX_flag_th.jpg") then FLAG_TH_ASSET = getAsset("AurenMAX_flag_th.jpg") end
    end
end)

-- Download missing assets in background (non-blocking, all in parallel)
task.spawn(function()
    if not LOGO_ASSET then
        local a = downloadAndCache(LOGO_URL, "AurenMAX_logo.png")
        if a then LOGO_ASSET = a end
    end
end)
task.spawn(function()
    if not FLAG_EN_ASSET then
        local a = downloadAndCache(FLAG_EN_URL, "AurenMAX_flag_en.jpg")
        if a then FLAG_EN_ASSET = a end
    end
end)
task.spawn(function()
    if not FLAG_TH_ASSET then
        local a = downloadAndCache(FLAG_TH_URL, "AurenMAX_flag_th.jpg")
        if a then FLAG_TH_ASSET = a end
    end
end)

-- ==================== CONFIG (ALL OFF by default) ====================
local Config = {
    Highlight       = false,
    ShowHealth      = false,
    ShowDistance     = false,
    Noclip          = false,
    Speed           = 16,     -- default WalkSpeed
    JumpPower       = 50,     -- default JumpPower
    Fly             = false,
    FlySpeed        = 80,
    GhostNoclip     = false,
    SpamSlapAll     = false,
    SpamSlapDelay   = 0.05,
    TargetSlapAuto  = false,
    TargetSlapPlr   = nil, -- selected player object
    FlingPlr        = nil, -- selected fling target
    FlingSpam       = false,
    SpamFlingAll    = false,
    SlapPower       = 1,      -- slap force multiplier (1 = normal, up to 100)
    DepthMode       = true,
    FillColor       = Color3.fromRGB(0, 200, 80),
    OutlineColor    = Color3.fromRGB(0, 255, 120),
    FillTransparency    = 0.5,
    OutlineTransparency = 0,
    MaxDistance      = 0,
    UIScale         = 1,
}

local ESP = {}

-- ==================== LUCIDE ICONS ====================
local Ic = {
    -- Tabs
    User      = "rbxassetid://10747373176",   -- Player tab
    Eye       = "rbxassetid://10723346959",   -- Visuals tab / ESP
    Swords    = "rbxassetid://10734975692",   -- Combat tab
    Palette   = "rbxassetid://10734910430",   -- Color tab
    Cog       = "rbxassetid://10709810948",   -- Settings tab
    -- Sections
    Move      = "rbxassetid://10734900011",   -- Movement
    Navigation= "rbxassetid://10734906332",   -- Fly
    Ghost     = "rbxassetid://10723396107",   -- Ghost Noclip
    Heart     = "rbxassetid://10723406885",   -- Health
    Ruler     = "rbxassetid://10734941018",   -- Distance
    Shield    = "rbxassetid://10734951847",   -- Anti-Knockback
    Timer     = "rbxassetid://10734984606",   -- Slap Settings / Delay
    Gauge     = "rbxassetid://10723395708",   -- Slap Power
    Target    = "rbxassetid://10734977012",   -- Target Slap
    Sword     = "rbxassetid://10734975486",   -- Spam Slap All
    Flame     = "rbxassetid://10723376114",   -- Fling
    Users     = "rbxassetid://10747373426",   -- All Players (fling all)
    Scaling   = "rbxassetid://10734942072",   -- UI Scale
    Info      = "rbxassetid://10723415903",   -- Info
    -- UI chrome
    X         = "rbxassetid://10747384394",   -- Close
    Minimize  = "rbxassetid://10734895698",   -- Minimize
}

-- ==================== LANGUAGE SYSTEM ====================
local CurrentLang = "EN"

local Lang = {
    EN = {
        -- Key system
        EnterKey = "Enter your key to continue",
        PasteKey = "Paste key here...",
        GetKey = "GET KEY",
        Enter = "ENTER",
        Copied = "COPIED!",
        InvalidKey = "Invalid key!",
        -- Header
        Subtitle = "Teamwork Tower",
        -- Tabs
        Player = "Player",
        Visuals = "Visuals",
        Combat = "Combat",
        Color = "Color",
        Settings = "Settings",
        -- Player tab
        Movement = "MOVEMENT",
        Speed = "Speed",
        JumpPower = "Jump Power",
        Fly = "FLY",
        EnableFly = "Enable Fly",
        FlySpeed = "Fly Speed",
        FlyTip = "PC: WASD+Space/Shift. Mobile: Thumbstick+Jump=up.",
        GhostNoclip = "GHOST NOCLIP",
        GhostMode = "Ghost Mode",
        GhostTip = "Pass through ALL walls & objects.\nFloor stays solid so you won't fall.",
        -- Visuals tab
        ESP = "ESP",
        EnableHighlight = "Enable Highlight",
        AlwaysOnTop = "Always On Top",
        Distance = "DISTANCE",
        ShowDistance = "Show Distance",
        Health = "HEALTH",
        ShowHealth = "Show Health",
        Full = "FULL", Good = "GOOD", Hurt = "HURT", Low = "LOW", Crit = "CRIT",
        -- Combat tab
        Defense = "ANTI-KNOCKBACK",
        DodgeProjectile = "Reduce Knockback",
        DefenseTip = "Reduces knockback distance from slaps.\nPrevents falling down when hit.\nDoes NOT protect against laser guns.",
        CombatSettings = "SLAP BUTTON SETTINGS",
        SlapDelay = "Slap Delay (ms)",
        SlapDelayTip = "Delay between each slap from buttons below.\nDoes NOT affect slapping with your character manually.",
        SlapPower = "Slap Power",
        SlapPowerTip = "Force multiplier for slaps from buttons below.\nDoes NOT affect slapping with your character manually.",
        SpamSlapAll = "SPAM SLAP ALL",
        SpamSlapToggle = "Spam Slap All Players",
        SlapTip = "Auto-detect best item: GoldSlap > PurpleSlap > SlapHand.",
        Slap = "SLAP",
        TargetPlayer = "Player",
        SelectPlayer = "Select Player",
        NoPlayerSelected = "No player selected",
        SlapOnce = "Slap Once",
        SpamSlapTarget = "Spam Slap Target",
        NoPlayers = "No other players in server",
        TargetTip = "Select a player then slap once or spam.",
        -- Fling
        FlingSection = "FLING",
        FlingPlayer = "Player",
        FlingSelectPlayer = "Select Player",
        FlingOnce = "Fling Once",
        FlingSpamTarget = "Spam Fling Target",
        FlingAll = "Fling All Players",
        SpamFlingAll = "Spam Fling All Players",
        FlingTip = "Sends players flying with extreme force.\nUses best available slap item.",
        -- Color tab
        HighlightColors = "HIGHLIGHT COLORS",
        FillColor = "Fill Color",
        OutlineColor = "Outline Color",
        FillOpacity = "Fill Opacity",
        OutlineOpacity = "Outline Opacity",
        -- Settings tab
        UIScale = "UI SCALE",
        MaxDist = "Max Distance (0=off)",
        Info = "INFO",
        Players = "Players",
        FPS = "FPS",
        Script = "Script",
        -- Language
        LangName = "English",
    },
    TH = {
        EnterKey = "กรอกคีย์เพื่อดำเนินการต่อ",
        PasteKey = "วางคีย์ที่นี่...",
        GetKey = "รับคีย์",
        Enter = "ยืนยัน",
        Copied = "คัดลอกแล้ว!",
        InvalidKey = "คีย์ไม่ถูกต้อง!",
        Subtitle = "Teamwork Tower",
        Player = "ผู้เล่น",
        Visuals = "ภาพ",
        Combat = "ต่อสู้",
        Color = "สี",
        Settings = "ตั้งค่า",
        Movement = "การเคลื่อนไหว",
        Speed = "ความเร็ว",
        JumpPower = "พลังกระโดด",
        Fly = "บิน",
        EnableFly = "เปิดการบิน",
        FlySpeed = "ความเร็วบิน",
        FlyTip = "PC: WASD+Space/Shift. มือถือ: จอยสติ๊ก+ปุ่มกระโดด=ขึ้น",
        GhostNoclip = "โหมดผี",
        GhostMode = "โหมดผี",
        GhostTip = "ทะลุผ่านกำแพงและวัตถุทั้งหมด\nพื้นยังคงแข็งอยู่จะไม่ตกลงไป",
        ESP = "ESP",
        EnableHighlight = "เปิดไฮไลท์",
        AlwaysOnTop = "แสดงทับตลอด",
        Distance = "ระยะทาง",
        ShowDistance = "แสดงระยะทาง",
        Health = "เลือด",
        ShowHealth = "แสดงเลือด",
        Full = "เต็ม", Good = "ดี", Hurt = "บาดเจ็บ", Low = "น้อย", Crit = "วิกฤต",
        Defense = "ลดแรงกระเด็น",
        DodgeProjectile = "ลดแรงกระเด็น",
        DefenseTip = "ลดระยะกระเด็นจากการตบ\nช่วยไม่ให้ล้มเวลาโดนตี\nไม่ช่วยป้องกันปืนเลเซอร์",
        CombatSettings = "ตั้งค่าปุ่มตบ",
        SlapDelay = "ดีเลย์ตบ (ms)",
        SlapDelayTip = "ดีเลย์ระหว่างการตบจากปุ่มด้านล่าง\nไม่มีผลกับการตบด้วยตัวละครเอง",
        SlapPower = "พลังตบ",
        SlapPowerTip = "ตัวคูณแรงตบจากปุ่มด้านล่าง\nไม่มีผลกับการตบด้วยตัวละครเอง",
        SpamSlapAll = "สแปมตบทุกคน",
        SpamSlapToggle = "สแปมตบผู้เล่นทั้งหมด",
        SlapTip = "ตรวจไอเทมอัตโนมัติ: GoldSlap > PurpleSlap > SlapHand",
        Slap = "ตบ",
        TargetPlayer = "ผู้เล่น",
        SelectPlayer = "เลือกผู้เล่น",
        NoPlayerSelected = "ยังไม่ได้เลือก",
        SlapOnce = "ตบ 1 ครั้ง",
        SpamSlapTarget = "สแปมตบเป้าหมาย",
        NoPlayers = "ไม่มีผู้เล่นคนอื่นในเซิร์ฟเวอร์",
        TargetTip = "เลือกผู้เล่นแล้วตบครั้งเดียวหรือสแปม",
        FlingSection = "ฟลิง",
        FlingPlayer = "ผู้เล่น",
        FlingSelectPlayer = "เลือกผู้เล่น",
        FlingOnce = "ฟลิงครั้งเดียว",
        FlingSpamTarget = "สแปมฟลิงเป้าหมาย",
        FlingAll = "ฟลิงทุกคน",
        SpamFlingAll = "สแปมฟลิงทุกคน",
        FlingTip = "ส่งผู้เล่นกระเด็นด้วยแรงสูงสุด\nใช้ไอเทมตบที่ดีที่สุด",
        HighlightColors = "สีไฮไลท์",
        FillColor = "สีเติม",
        OutlineColor = "สีขอบ",
        FillOpacity = "ความทึบสีเติม",
        OutlineOpacity = "ความทึบสีขอบ",
        UIScale = "ขนาด UI",
        MaxDist = "ระยะสูงสุด (0=ปิด)",
        Info = "ข้อมูล",
        Players = "ผู้เล่น",
        FPS = "FPS",
        Script = "สคริปต์",
        LangName = "ภาษาไทย",
    },
}

local function L(key) return Lang[CurrentLang][key] or Lang.EN[key] or key end

-- Track all translatable UI elements for live switching
local TranslatableUI = {}

-- ==================== THEME: GREEN-BLACK LUXURY ====================
local T = {
    Bg  = Color3.fromRGB(8, 12, 8),
    Sf  = Color3.fromRGB(14, 22, 14),
    SfL = Color3.fromRGB(22, 36, 22),
    SfH = Color3.fromRGB(30, 50, 30),
    Ac  = Color3.fromRGB(0, 220, 90),
    AcG = Color3.fromRGB(0, 255, 120),
    AcD = Color3.fromRGB(0, 160, 65),
    Tx  = Color3.fromRGB(210, 240, 215),
    TxS = Color3.fromRGB(90, 140, 100),
    TxD = Color3.fromRGB(45, 75, 50),
    Bd  = Color3.fromRGB(25, 45, 28),
    Rd  = Color3.fromRGB(255, 55, 55),
    -- Health stages
    HF = Color3.fromRGB(0, 255, 120),
    HH = Color3.fromRGB(120, 240, 60),
    HM = Color3.fromRGB(255, 220, 40),
    HL = Color3.fromRGB(255, 140, 30),
    HC = Color3.fromRGB(255, 50, 50),
}

-- ==================== UTIL ====================
local function Tw(o,p,d,s,r) TweenService:Create(o,TweenInfo.new(d or 0.25,s or Enum.EasingStyle.Quart,r or Enum.EasingDirection.Out),p):Play() end
local function Crn(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=p;return c end
local function Stk(p,c,t,tr) local s=Instance.new("UIStroke");s.Color=c or T.Bd;s.Thickness=t or 1;s.Transparency=tr or 0;s.Parent=p;return s end

local function HPCol(r)
    if r > 0.75 then return T.HF elseif r > 0.50 then return T.HH
    elseif r > 0.30 then return T.HM elseif r > 0.15 then return T.HL else return T.HC end
end

-- ==================== CLEANUP OLD INSTANCES ====================
for _,n in ipairs({"NBG_OP","NBG_OP_INTRO","AUREN_MAX","AUREN_MAX_INTRO","AUREN_TRACERS","AUREN_KEY"}) do
    local o = LocalPlayer.PlayerGui:FindFirstChild(n); if o then o:Destroy() end
end
for _,plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        for _,n in ipairs({"NBG","AUREN_HL","AUREN_BB"}) do
            local h = plr.Character:FindFirstChild(n); if h then h:Destroy() end
        end
    end
end
-- Clean old fly instances
pcall(function()
    local ch = LocalPlayer.Character
    if ch then
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, c in ipairs(hrp:GetChildren()) do
                if c.Name == "AUREN_FLY_VEL" or c.Name == "AUREN_FLY_GYRO" then c:Destroy() end
            end
        end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end)
if _G.AUREN_ESP then pcall(function() for _,d in pairs(_G.AUREN_ESP) do end end) end
if _G.AUREN_RENDER then pcall(function() _G.AUREN_RENDER:Disconnect() end) end
if _G.AUREN_ANTIKB then pcall(function() _G.AUREN_ANTIKB:Disconnect() end) end
if _G.AUREN_CHILDADD then for _,c in ipairs(_G.AUREN_CHILDADD) do pcall(function() c:Disconnect() end) end end
if _G.AUREN_HB then pcall(function() _G.AUREN_HB:Disconnect() end) end
if _G.AUREN_CONNS then for _,c in ipairs(_G.AUREN_CONNS) do pcall(function() c:Disconnect() end) end end
-- Also clean old NBG globals
if _G.NBG_RENDER then pcall(function() _G.NBG_RENDER:Disconnect() end) end
if _G.NBG_HEARTBEAT then pcall(function() _G.NBG_HEARTBEAT:Disconnect() end) end
if _G.NBG_ANTIKB then pcall(function() _G.NBG_ANTIKB:Disconnect() end) end

local allConns = {} -- track ALL connections for clean destroy

-- ==================== INTRO ====================
do
local IG = Instance.new("ScreenGui"); IG.Name = "AUREN_MAX_INTRO"; IG.ResetOnSpawn = false
IG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; IG.DisplayOrder = 100; IG.AutoLocalize = false
IG.Parent = LocalPlayer:WaitForChild("PlayerGui")

local OV = Instance.new("Frame"); OV.Size = UDim2.new(1,0,1,0); OV.BackgroundColor3 = Color3.new(0,0,0)
OV.BackgroundTransparency = 0.3; OV.BorderSizePixel = 0; OV.Parent = IG

local IB = Instance.new("Frame"); IB.Size = UDim2.new(0,0,0,0); IB.Position = UDim2.new(0.5,0,0.5,0)
IB.AnchorPoint = Vector2.new(0.5,0.5); IB.BackgroundColor3 = T.Bg; IB.BorderSizePixel = 0
IB.BackgroundTransparency = 1; IB.Parent = IG; Crn(IB,20); Stk(IB,T.Ac,2,0.5)

local IT = Instance.new("TextLabel"); IT.Size = UDim2.new(1,0,0,40); IT.Position = UDim2.new(0.5,0,0.35,0)
IT.AnchorPoint = Vector2.new(0.5,0.5); IT.BackgroundTransparency = 1; IT.Text = "Auren MAX"
IT.TextColor3 = T.Ac; IT.TextSize = 1; IT.Font = Enum.Font.GothamBlack; IT.TextTransparency = 1; IT.Parent = IB

local IS = Instance.new("TextLabel"); IS.Size = UDim2.new(1,0,0,20); IS.Position = UDim2.new(0.5,0,0.55,0)
IS.AnchorPoint = Vector2.new(0.5,0.5); IS.BackgroundTransparency = 1; IS.Text = "Teamwork Tower"
IS.TextColor3 = T.TxD; IS.TextSize = 1; IS.Font = Enum.Font.Gotham; IS.TextTransparency = 1; IS.Parent = IB

local LB = Instance.new("Frame"); LB.Size = UDim2.new(0.6,0,0,4); LB.Position = UDim2.new(0.5,0,0.78,0)
LB.AnchorPoint = Vector2.new(0.5,0.5); LB.BackgroundColor3 = T.SfL; LB.BackgroundTransparency = 1
LB.BorderSizePixel = 0; LB.Parent = IB; Crn(LB,2)
local LF = Instance.new("Frame"); LF.Size = UDim2.new(0,0,1,0); LF.BackgroundColor3 = T.Ac; LF.BorderSizePixel = 0
LF.Parent = LB; Crn(LF,2)
local lg = Instance.new("UIGradient"); lg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,220,90)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,255,180)),
}); lg.Parent = LF

-- INSTANT intro animation (no waiting for HTTP)
Tw(IB,{Size=UDim2.new(0,300,0,200),BackgroundTransparency=0},0.5,Enum.EasingStyle.Back); task.wait(0.3)
Tw(IT,{TextSize=28,TextTransparency=0},0.3,Enum.EasingStyle.Quint); task.wait(0.15)
Tw(IS,{TextSize=12,TextTransparency=0},0.25); task.wait(0.1)
Tw(LB,{BackgroundTransparency=0},0.15); task.wait(0.05)
Tw(LF,{Size=UDim2.new(1,0,1,0)},0.9,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut); task.wait(1.0)
Tw(IB,{BackgroundTransparency=1},0.3)
Tw(IT,{TextTransparency=1},0.2); Tw(IS,{TextTransparency=1},0.2)
Tw(LB,{BackgroundTransparency=1},0.15); Tw(OV,{BackgroundTransparency=1},0.35)
task.wait(0.4); IG:Destroy()
end

-- ==================== KEY SYSTEM ====================
do
-- Key is obfuscated to prevent easy extraction from source
local function _dk()
    local d={27,47,40,63,52,119,23,27,2,119,106,109,104,99,111,105,98}
    local s,x="",90 for i=1,#d do s=s..string.char(bit32.bxor(d[i],x)) end return s
end
local VALID_KEY = _dk()
local keyVerified = false  -- set true ONLY after animation fully completes

local KG = Instance.new("ScreenGui"); KG.Name = "AUREN_KEY"; KG.ResetOnSpawn = false
KG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; KG.DisplayOrder = 99; KG.AutoLocalize = false
KG.Parent = LocalPlayer:WaitForChild("PlayerGui")

local KOV = Instance.new("Frame"); KOV.Size = UDim2.new(1,0,1,0); KOV.BackgroundColor3 = Color3.new(0,0,0)
KOV.BackgroundTransparency = 0.4; KOV.BorderSizePixel = 0; KOV.Parent = KG

local KB = Instance.new("Frame"); KB.Size = UDim2.new(0,0,0,0); KB.Position = UDim2.new(0.5,0,0.5,0)
KB.AnchorPoint = Vector2.new(0.5,0.5); KB.BackgroundColor3 = T.Bg; KB.BorderSizePixel = 0
KB.BackgroundTransparency = 1; KB.Parent = KG; Crn(KB,16); Stk(KB,T.Ac,2,0.5)

-- Title
local KT = Instance.new("TextLabel"); KT.Size = UDim2.new(1,0,0,30); KT.Position = UDim2.new(0,0,0,16)
KT.BackgroundTransparency = 1; KT.Text = "Auren MAX"; KT.TextColor3 = T.Ac
KT.TextSize = 1; KT.Font = Enum.Font.GothamBlack; KT.TextTransparency = 1; KT.Parent = KB

-- Subtitle
local KST = Instance.new("TextLabel"); KST.Size = UDim2.new(1,0,0,16); KST.Position = UDim2.new(0,0,0,48)
KST.BackgroundTransparency = 1; KST.Text = "Enter your key to continue"
KST.TextColor3 = T.TxD; KST.TextSize = 1; KST.Font = Enum.Font.Gotham; KST.TextTransparency = 1; KST.Parent = KB

-- Key input box
local KIB = Instance.new("Frame"); KIB.Size = UDim2.new(1,-40,0,36); KIB.Position = UDim2.new(0,20,0,78)
KIB.BackgroundColor3 = T.SfL; KIB.BorderSizePixel = 0; KIB.BackgroundTransparency = 1; KIB.Parent = KB; Crn(KIB,8)
Stk(KIB, T.Bd, 1, 0.3)

local KInput = Instance.new("TextBox"); KInput.Size = UDim2.new(1,-16,1,0); KInput.Position = UDim2.new(0,8,0,0)
KInput.BackgroundTransparency = 1; KInput.Text = ""; KInput.PlaceholderText = "Paste key here..."
KInput.PlaceholderColor3 = T.TxD; KInput.TextColor3 = T.Tx; KInput.TextSize = 12
KInput.Font = Enum.Font.GothamBold; KInput.ClearTextOnFocus = false; KInput.TextTransparency = 1; KInput.Parent = KIB

-- Error label (hidden by default)
local KErr = Instance.new("TextLabel"); KErr.Size = UDim2.new(1,-40,0,14); KErr.Position = UDim2.new(0,20,0,118)
KErr.BackgroundTransparency = 1; KErr.Text = ""; KErr.TextColor3 = T.Rd
KErr.TextSize = 9; KErr.Font = Enum.Font.GothamBold; KErr.TextTransparency = 1; KErr.Parent = KB

-- Buttons container
local KBtns = Instance.new("Frame"); KBtns.Size = UDim2.new(1,-40,0,36); KBtns.Position = UDim2.new(0,20,0,136)
KBtns.BackgroundTransparency = 1; KBtns.Parent = KB

-- GET KEY button
local GKBtn = Instance.new("TextButton"); GKBtn.Size = UDim2.new(0.48,0,1,0); GKBtn.Position = UDim2.new(0,0,0,0)
GKBtn.BackgroundColor3 = T.SfH; GKBtn.BorderSizePixel = 0; GKBtn.Text = "GET KEY"
GKBtn.TextColor3 = T.Ac; GKBtn.TextSize = 12; GKBtn.Font = Enum.Font.GothamBold
GKBtn.AutoButtonColor = false; GKBtn.BackgroundTransparency = 1; GKBtn.TextTransparency = 1; GKBtn.Parent = KBtns; Crn(GKBtn,8)

-- ENTER button
local ENBtn = Instance.new("TextButton"); ENBtn.Size = UDim2.new(0.48,0,1,0); ENBtn.Position = UDim2.new(0.52,0,0,0)
ENBtn.BackgroundColor3 = T.Ac; ENBtn.BorderSizePixel = 0; ENBtn.Text = "ENTER"
ENBtn.TextColor3 = T.Bg; ENBtn.TextSize = 12; ENBtn.Font = Enum.Font.GothamBlack
ENBtn.AutoButtonColor = false; ENBtn.BackgroundTransparency = 1; ENBtn.TextTransparency = 1; ENBtn.Parent = KBtns; Crn(ENBtn,8)

-- Animate key screen in (smooth)
Tw(KOV,{BackgroundTransparency=0.4},0.4,Enum.EasingStyle.Sine)
Tw(KB,{Size=UDim2.new(0,320,0,190),BackgroundTransparency=0},0.5,Enum.EasingStyle.Quint); task.wait(0.3)
Tw(KT,{TextSize=22,TextTransparency=0},0.3,Enum.EasingStyle.Quint); task.wait(0.1)
Tw(KST,{TextSize=10,TextTransparency=0},0.25,Enum.EasingStyle.Quint); task.wait(0.1)
Tw(KIB,{BackgroundTransparency=0},0.25,Enum.EasingStyle.Sine)
Tw(KInput,{TextTransparency=0},0.25,Enum.EasingStyle.Sine); task.wait(0.15)
Tw(GKBtn,{BackgroundTransparency=0,TextTransparency=0},0.25,Enum.EasingStyle.Sine)
Tw(ENBtn,{BackgroundTransparency=0,TextTransparency=0},0.25,Enum.EasingStyle.Sine)

-- Hover effects
GKBtn.MouseEnter:Connect(function() Tw(GKBtn,{BackgroundColor3=T.Ac},0.15); Tw(GKBtn,{TextColor3=T.Bg},0.15) end)
GKBtn.MouseLeave:Connect(function() Tw(GKBtn,{BackgroundColor3=T.SfH},0.15); Tw(GKBtn,{TextColor3=T.Ac},0.15) end)
ENBtn.MouseEnter:Connect(function() Tw(ENBtn,{BackgroundColor3=T.AcG},0.15) end)
ENBtn.MouseLeave:Connect(function() Tw(ENBtn,{BackgroundColor3=T.Ac},0.15) end)

-- GET KEY: open Discord link
GKBtn.MouseButton1Click:Connect(function()
    -- Show COPIED! INSTANTLY first
    GKBtn.Text = "COPIED!"; GKBtn.BackgroundColor3 = T.Ac; GKBtn.TextColor3 = T.Bg
    task.delay(1.5, function()
        if GKBtn and GKBtn.Parent then
            GKBtn.Text = "GET KEY"
            Tw(GKBtn,{BackgroundColor3=T.SfH},0.15); Tw(GKBtn,{TextColor3=T.Ac},0.15)
        end
    end)
    -- Copy + open browser in background (non-blocking)
    local DISCORD_URL = "https://discord.gg/kNYKh8tT39"
    task.spawn(function()
        -- 1) Copy to clipboard
        pcall(function() if setclipboard then setclipboard(DISCORD_URL) end end)
        -- 2) Try all known methods to open browser automatically
        local opened = false
        -- Fluxus / Delta / Hydrogen
        if not opened then pcall(function() if openurl then openurl(DISCORD_URL); opened = true end end) end
        if not opened then pcall(function() if open_browser then open_browser(DISCORD_URL); opened = true end end) end
        if not opened then pcall(function() if fluxus and fluxus.open_url then fluxus.open_url(DISCORD_URL); opened = true end end) end
        -- Synapse X localhost API
        if not opened then pcall(function()
            local req = (syn and syn.request) or request or http_request
            if req then req({Url = "http://127.0.0.1/open?url=" .. DISCORD_URL, Method = "GET"}); opened = true end
        end) end
    end)
end)

-- Validate key function
local validating = false
local function validateKey()
    if validating or keyVerified then return end
    validating = true
    local input = KInput.Text
    if input == VALID_KEY then
        -- Phase 1: Success glow on input box
        KErr.Text = ""; KErr.TextTransparency = 1
        Tw(KIB,{BackgroundColor3=Color3.fromRGB(0,60,30)},0.2,Enum.EasingStyle.Sine)
        Stk(KIB, T.Ac, 1.5, 0)
        ENBtn.Text = "✓"; Tw(ENBtn,{BackgroundColor3=Color3.fromRGB(0,180,80)},0.2)
        task.wait(0.35)

        -- Phase 2: Fade out all inner elements
        Tw(KT,{TextTransparency=1},0.25,Enum.EasingStyle.Sine)
        Tw(KST,{TextTransparency=1},0.25,Enum.EasingStyle.Sine)
        Tw(KInput,{TextTransparency=1},0.2,Enum.EasingStyle.Sine)
        Tw(GKBtn,{TextTransparency=1,BackgroundTransparency=1},0.2,Enum.EasingStyle.Sine)
        Tw(ENBtn,{TextTransparency=1,BackgroundTransparency=1},0.2,Enum.EasingStyle.Sine)
        Tw(KIB,{BackgroundTransparency=1},0.2,Enum.EasingStyle.Sine)
        task.wait(0.2)

        -- Phase 3: Box morphs into a green accent line then collapses
        Tw(KB,{Size=UDim2.new(0,320,0,4),BackgroundColor3=T.Ac,BackgroundTransparency=0},0.3,Enum.EasingStyle.Quint)
        task.wait(0.25)

        -- Phase 4: Line shrinks to nothing + overlay fades
        Tw(KB,{Size=UDim2.new(0,0,0,4),BackgroundTransparency=1},0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        Tw(KOV,{BackgroundTransparency=1},0.35,Enum.EasingStyle.Sine)
        task.wait(0.4)

        pcall(function() KG:Destroy() end)
        -- NOW signal that key is verified (after animation fully done)
        keyVerified = true
    else
        -- Wrong key - error + shake
        KErr.Text = "Invalid key!"; Tw(KErr,{TextTransparency=0},0.15)
        Tw(KIB,{BackgroundColor3=Color3.fromRGB(60,15,15)},0.1)
        task.delay(0.5, function()
            if KIB and KIB.Parent then Tw(KIB,{BackgroundColor3=T.SfL},0.2) end
        end)
        local origPos = KB.Position
        for i = 1, 3 do
            Tw(KB,{Position=origPos+UDim2.new(0,8,0,0)},0.04); task.wait(0.04)
            Tw(KB,{Position=origPos+UDim2.new(0,-8,0,0)},0.04); task.wait(0.04)
        end
        Tw(KB,{Position=origPos},0.04)
        validating = false
    end
end

ENBtn.MouseButton1Click:Connect(validateKey)
KInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then validateKey() end
end)

-- Wait for key verification before continuing
while not keyVerified and not DESTROYED do task.wait(0.1) end

-- If logo failed to load synchronously, try background retry
if not LOGO_ASSET then
    task.spawn(function()
        -- Try using cached file first
        pcall(function()
            local getAsset = getcustomasset or getsynasset
            if isfile and getAsset and isfile("AurenMAX_logo.png") then
                LOGO_ASSET = getAsset("AurenMAX_logo.png")
                if Lo and Lo.Parent then
                    Lo.Image = LOGO_ASSET
                    Lo.BackgroundColor3 = T.SfL
                    for _, child in ipairs(Lo:GetChildren()) do
                        if child:IsA("TextLabel") then child:Destroy() end
                    end
                end
            end
        end)
        -- If still no logo, retry HTTP
        if not LOGO_ASSET then
            task.wait(2)
            pcall(function()
                local writeF = writefile
                local getAsset = getcustomasset or getsynasset
                if not writeF or not getAsset then return end
                local httpReq = nil
                pcall(function() if syn and syn.request then httpReq = syn.request end end)
                if not httpReq then pcall(function() if request then httpReq = request end end) end
                if not httpReq then pcall(function() if http_request then httpReq = http_request end end) end
                if httpReq then
                    local resp = httpReq({Url = LOGO_URL, Method = "GET"})
                    if resp and resp.Body and #resp.Body > 100 then
                        writeF("AurenMAX_logo.png", resp.Body)
                        LOGO_ASSET = getAsset("AurenMAX_logo.png")
                        if Lo and Lo.Parent then
                            Lo.Image = LOGO_ASSET
                            Lo.BackgroundColor3 = T.SfL
                            for _, child in ipairs(Lo:GetChildren()) do
                                if child:IsA("TextLabel") then child:Destroy() end
                            end
                        end
                    end
                end
            end)
        end
    end)
end
end

-- ==================== RESPONSIVE SYSTEM ====================
local BASE_W = 380
local BASE_H = 520

local function getAutoScale()
    local vp = Camera.ViewportSize
    local w, h = vp.X, vp.Y
    local sw
    if w < 500 then       -- phone portrait
        sw = w / 430
    elseif w < 800 then   -- phone landscape / small tablet
        sw = math.clamp(w / 520, 0.7, 1.0)
    elseif w < 1100 then  -- tablet
        sw = math.clamp(w / 1000, 0.8, 1.05)
    else                  -- desktop
        sw = math.clamp(h / 900, 0.85, 1.2)
    end
    -- Also limit by height so UI never overflows screen vertically
    -- IgnoreGuiInset=true means full screen height; account for 4px top offset + small bottom margin
    local sh = (h - 16) / BASE_H
    return math.min(sw, sh)
end

-- ==================== MAIN GUI ====================
local Gui = Instance.new("ScreenGui"); Gui.Name = "AUREN_MAX"; Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global; Gui.AutoLocalize = false
Gui.IgnoreGuiInset = true  -- UI starts at very top of screen
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main parented directly to ScreenGui — no intermediate ScaleRoot
local Main = Instance.new("Frame"); Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5,0)
Main.Size = UDim2.new(0,BASE_W,0,BASE_H); Main.Position = UDim2.new(0.5,0,0,4)
Main.BackgroundColor3 = T.Bg; Main.BorderSizePixel = 0; Main.BackgroundTransparency = 1
Main.Parent = Gui; Crn(Main,12); Stk(Main,T.Bd,1)
-- UIScale on Main: position stays in screen coords, only Main's visual size scales
local UIScaleObj = Instance.new("UIScale"); UIScaleObj.Scale = getAutoScale() * Config.UIScale; UIScaleObj.Parent = Main
local glowStk = Stk(Main,T.Ac,1.5,0.7)

-- Shadow (parented to Gui, not Main, because Main clips descendants)
local sh = Instance.new("ImageLabel"); sh.BackgroundTransparency = 1; sh.Image = "rbxassetid://5554236805"
sh.ImageColor3 = Color3.fromRGB(0,30,10); sh.ImageTransparency = 0.4; sh.ScaleType = Enum.ScaleType.Slice
sh.SliceCenter = Rect.new(23,23,277,277); sh.Size = UDim2.new(1,30,1,30); sh.Position = UDim2.new(0,-15,0,-15)
sh.ZIndex = -1; sh.Parent = Main

-- Main stays transparent until script finishes building (shown at end of script)

-- ==================== HEADER ====================
local Hdr = Instance.new("Frame"); Hdr.Size = UDim2.new(1,0,0,48); Hdr.BackgroundTransparency = 1
Hdr.BorderSizePixel = 0; Hdr.Active = true; Hdr.Parent = Main

local HdrBg = Instance.new("Frame"); HdrBg.Size = UDim2.new(1,0,1,0); HdrBg.BackgroundColor3 = T.Sf
HdrBg.BorderSizePixel = 0; HdrBg.Parent = Hdr; Crn(HdrBg,12)
local HdrBtm = Instance.new("Frame"); HdrBtm.Size = UDim2.new(1,0,0,14)
HdrBtm.Position = UDim2.new(0,0,1,-14); HdrBtm.BackgroundColor3 = T.Sf; HdrBtm.BorderSizePixel = 0; HdrBtm.Parent = Hdr

-- Accent line (inset so it doesn't touch rounded corners)
local AL = Instance.new("Frame"); AL.Size = UDim2.new(1,-24,0,2)
AL.Position = UDim2.new(0,12,1,-1); AL.BackgroundColor3 = T.Ac; AL.BorderSizePixel = 0; AL.ZIndex = 3; AL.Parent = Hdr; Crn(AL,1)
local ag = Instance.new("UIGradient"); ag.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(0,180,70)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,150)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(0,180,70)),
}); ag.Parent = AL

-- Drag (header only)
local dragging, dragStart, startPos
Hdr.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
table.insert(allConns, UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))

-- Logo
local Lo = Instance.new("ImageLabel"); Lo.Size = UDim2.new(0,32,0,32); Lo.Position = UDim2.new(0,8,0,8)
Lo.BackgroundColor3 = T.SfL; Lo.BorderSizePixel = 0; Lo.Image = LOGO_ASSET or ""
Lo.ScaleType = Enum.ScaleType.Fit; Lo.ZIndex = 2; Lo.Parent = Hdr; Crn(Lo,8)
-- Loading animation fallback: pulsing glow (no text)
if not LOGO_ASSET then
    Lo.BackgroundColor3 = T.Sf
    local loStk = Stk(Lo, T.Ac, 1, 0.4)
    task.spawn(function()
        while Lo and Lo.Parent and not LOGO_ASSET do
            Tw(Lo,{BackgroundTransparency=0.5},0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut); task.wait(0.4)
            Tw(Lo,{BackgroundTransparency=0},0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut); task.wait(0.4)
        end
        if Lo and Lo.Parent then Lo.BackgroundTransparency = 0 end
        if loStk and loStk.Parent then loStk:Destroy() end
    end)
end

local TL = Instance.new("TextLabel"); TL.Size = UDim2.new(0,140,0,18); TL.Position = UDim2.new(0,48,0,8)
TL.BackgroundTransparency = 1; TL.Text = "Auren MAX"; TL.TextColor3 = T.Ac; TL.TextSize = 15
TL.Font = Enum.Font.GothamBlack; TL.TextXAlignment = Enum.TextXAlignment.Left; TL.ZIndex = 2; TL.Parent = Hdr

local SL = Instance.new("TextLabel"); SL.Size = UDim2.new(0,160,0,12); SL.Position = UDim2.new(0,48,0,28)
SL.BackgroundTransparency = 1; SL.Text = "Teamwork Tower"; SL.TextColor3 = T.TxD; SL.TextSize = 9
SL.Font = Enum.Font.Gotham; SL.TextXAlignment = Enum.TextXAlignment.Left; SL.ZIndex = 2; SL.Parent = Hdr

-- Header buttons
local function HBtn(icon,px,hc)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0,28,0,28); b.Position = UDim2.new(1,px,0,10)
    b.BackgroundColor3 = T.SfL; b.Text = ""; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.ZIndex = 5; b.Parent = Hdr; Crn(b,7)
    local i = Instance.new("ImageLabel"); i.Size = UDim2.new(0,16,0,16); i.Position = UDim2.new(0.5,-8,0.5,-8)
    i.BackgroundTransparency = 1; i.Image = icon; i.ImageColor3 = T.TxS; i.ZIndex = 6; i.Parent = b
    b.MouseEnter:Connect(function() Tw(b,{BackgroundColor3=hc or T.Ac},0.15); Tw(i,{ImageColor3=T.Tx},0.15) end)
    b.MouseLeave:Connect(function() Tw(b,{BackgroundColor3=T.SfL},0.15); Tw(i,{ImageColor3=T.TxS},0.15) end)
    return b
end
local MinBtn = HBtn(Ic.Minimize, -66, Color3.fromRGB(55,180,140))
local ClsBtn = HBtn(Ic.X, -34, T.Rd)

-- ==================== LANGUAGE SELECTOR ====================
local langDropOpen = false
local LANG_BTN_W = 100 -- wide enough for flag + "English" / "ภาษาไทย" + arrow
local LANG_DROP_W = 120

local function MakeFlagImg(parent, url, asset, zIdx)
    local fg = Instance.new("ImageLabel"); fg.Name = "FlagIcon"
    fg.Size = UDim2.new(0,20,0,13); fg.Position = UDim2.new(0,5,0.5,-6)
    fg.BackgroundColor3 = T.SfL; fg.BorderSizePixel = 0
    fg.Image = asset or url; fg.ScaleType = Enum.ScaleType.Crop
    fg.ZIndex = zIdx; fg.Parent = parent; Crn(fg,3)
    return fg
end

-- Position: next to MinBtn (which is at 1,-66). LangBtn goes further left.
local LangBtn = Instance.new("TextButton"); LangBtn.Size = UDim2.new(0,LANG_BTN_W,0,28)
LangBtn.Position = UDim2.new(1,-(LANG_BTN_W + 70),0,10)
LangBtn.BackgroundColor3 = T.SfL; LangBtn.BorderSizePixel = 0; LangBtn.Text = ""
LangBtn.AutoButtonColor = false; LangBtn.ZIndex = 10; LangBtn.Parent = Hdr; Crn(LangBtn,7)
Stk(LangBtn, T.Bd, 1, 0.15)

-- Flag icon on the left
local LangFlagImg = MakeFlagImg(LangBtn, FLAG_EN_URL, FLAG_EN_ASSET, 11)
LangFlagImg.Size = UDim2.new(0,20,0,13); LangFlagImg.Position = UDim2.new(0,7,0.5,-6)

-- Language name text in the middle (centered between flag and arrow)
local LangLabel = Instance.new("TextLabel"); LangLabel.Size = UDim2.new(1,-42,1,0)
LangLabel.Position = UDim2.new(0,30,0,0); LangLabel.BackgroundTransparency = 1
LangLabel.Text = "English"; LangLabel.TextColor3 = T.Tx; LangLabel.TextSize = 9
LangLabel.Font = Enum.Font.GothamBold; LangLabel.TextXAlignment = Enum.TextXAlignment.Center
LangLabel.ZIndex = 11; LangLabel.Parent = LangBtn

-- Dropdown arrow (simple "v" text - Gotham renders this cleanly)
local LangArrow = Instance.new("TextLabel"); LangArrow.Size = UDim2.new(0,12,1,0)
LangArrow.Position = UDim2.new(1,-14,0,0); LangArrow.BackgroundTransparency = 1
LangArrow.Text = "v"; LangArrow.TextColor3 = T.TxD; LangArrow.TextSize = 8
LangArrow.Font = Enum.Font.GothamBold; LangArrow.ZIndex = 11; LangArrow.Parent = LangBtn

-- Dropdown panel (parented to Main for proper z-layering above tabs)
local LangDrop = Instance.new("Frame"); LangDrop.Size = UDim2.new(0,LANG_DROP_W,0,0)
LangDrop.Position = UDim2.new(1,-(LANG_DROP_W + 70),0,50)
LangDrop.BackgroundColor3 = T.Sf; LangDrop.BorderSizePixel = 0
LangDrop.ClipsDescendants = true; LangDrop.ZIndex = 50
LangDrop.Visible = false; LangDrop.Parent = Main; Crn(LangDrop,6); Stk(LangDrop, T.Bd, 1, 0.3)

local function makeLangOption(flagUrl, flagAssetRef, name, langCode, order)
    local opt = Instance.new("TextButton"); opt.Size = UDim2.new(1,0,0,30)
    opt.Position = UDim2.new(0,0,0,(order-1)*30); opt.BackgroundColor3 = T.Sf
    opt.BorderSizePixel = 0; opt.Text = ""; opt.AutoButtonColor = false; opt.ZIndex = 51; opt.Parent = LangDrop
    Crn(opt,6)
    local oFlag = MakeFlagImg(opt, flagUrl, flagAssetRef, 52)
    oFlag.Size = UDim2.new(0,22,0,14); oFlag.Position = UDim2.new(0,10,0.5,-7)
    local oLbl = Instance.new("TextLabel"); oLbl.Size = UDim2.new(1,-44,1,0)
    oLbl.Position = UDim2.new(0,36,0,0); oLbl.BackgroundTransparency = 1
    oLbl.Text = name; oLbl.TextColor3 = T.Tx; oLbl.TextSize = 10
    oLbl.Font = Enum.Font.GothamBold; oLbl.TextXAlignment = Enum.TextXAlignment.Center
    oLbl.ZIndex = 52; oLbl.Parent = opt
    opt.MouseEnter:Connect(function() Tw(opt,{BackgroundColor3=T.SfH},0.12) end)
    opt.MouseLeave:Connect(function() Tw(opt,{BackgroundColor3=T.Sf},0.12) end)
    opt.MouseButton1Click:Connect(function()
        CurrentLang = langCode
        -- Update flag + label on button
        LangFlagImg.Image = (langCode == "EN") and (FLAG_EN_ASSET or FLAG_EN_URL) or (FLAG_TH_ASSET or FLAG_TH_URL)
        LangLabel.Text = name
        langDropOpen = false
        LangDrop.Visible = false
        Tw(LangDrop,{Size=UDim2.new(0,LANG_DROP_W,0,0)},0.15)
        Tw(LangArrow,{Rotation=0},0.15)
        Tw(LangBtn,{BackgroundColor3=T.SfL},0.12)  -- reset button color
        -- Update all UI texts
        updateAllLangUI()
    end)
    return opt, oFlag
end

local optEN, optENFlag = makeLangOption(FLAG_EN_URL, FLAG_EN_ASSET, "English", "EN", 1)
local optTH, optTHFlag = makeLangOption(FLAG_TH_URL, FLAG_TH_ASSET, "ภาษาไทย", "TH", 2)

-- Deferred flag asset refresh (in case download finishes after UI was built)
task.spawn(function()
    task.wait(4)
    pcall(function()
        if FLAG_EN_ASSET then
            if CurrentLang == "EN" and LangFlagImg and LangFlagImg.Parent then LangFlagImg.Image = FLAG_EN_ASSET end
            if optENFlag and optENFlag.Parent then optENFlag.Image = FLAG_EN_ASSET end
        end
        if FLAG_TH_ASSET then
            if CurrentLang == "TH" and LangFlagImg and LangFlagImg.Parent then LangFlagImg.Image = FLAG_TH_ASSET end
            if optTHFlag and optTHFlag.Parent then optTHFlag.Image = FLAG_TH_ASSET end
        end
    end)
end)

LangBtn.MouseEnter:Connect(function() Tw(LangBtn,{BackgroundColor3=T.SfH},0.12) end)
LangBtn.MouseLeave:Connect(function() if not langDropOpen then Tw(LangBtn,{BackgroundColor3=T.SfL},0.12) end end)

LangBtn.MouseButton1Click:Connect(function()
    langDropOpen = not langDropOpen
    if langDropOpen then
        LangDrop.Visible = true
        Tw(LangDrop,{Size=UDim2.new(0,LANG_DROP_W,0,60)},0.2,Enum.EasingStyle.Quint)
        Tw(LangArrow,{Rotation=180},0.15)
    else
        Tw(LangDrop,{Size=UDim2.new(0,LANG_DROP_W,0,0)},0.15)
        Tw(LangArrow,{Rotation=0},0.15)
        task.delay(0.15, function() if not langDropOpen then LangDrop.Visible = false end end)
    end
end)

-- ==================== CONTENT ====================
local Content = Instance.new("Frame"); Content.Name = "Content"
Content.Size = UDim2.new(1,0,1,-50); Content.Position = UDim2.new(0,0,0,50)
Content.BackgroundTransparency = 1; Content.BorderSizePixel = 0; Content.ClipsDescendants = true; Content.Parent = Main

-- ==================== TAB BAR ====================
local TB = Instance.new("Frame"); TB.Size = UDim2.new(1,-16,0,32); TB.Position = UDim2.new(0,8,0,2)
TB.BackgroundColor3 = T.Sf; TB.BorderSizePixel = 0; TB.ClipsDescendants = true; TB.Parent = Content; Crn(TB,8)

local TBPad = Instance.new("UIPadding"); TBPad.PaddingLeft = UDim.new(0,4); TBPad.PaddingTop = UDim.new(0,3)
TBPad.PaddingRight = UDim.new(0,4); TBPad.Parent = TB

local TBLay = Instance.new("UIListLayout"); TBLay.FillDirection = Enum.FillDirection.Horizontal
TBLay.HorizontalAlignment = Enum.HorizontalAlignment.Center; TBLay.Padding = UDim.new(0,2); TBLay.Parent = TB

local Pgs = Instance.new("Frame"); Pgs.Size = UDim2.new(1,-16,1,-38); Pgs.Position = UDim2.new(0,8,0,38)
Pgs.BackgroundTransparency = 1; Pgs.BorderSizePixel = 0; Pgs.Parent = Content

local aTab = nil; local tS = {}

local function SwTab(n)
    if aTab == n then return end
    if aTab and tS[aTab] then
        local o = tS[aTab]
        Tw(o.b,{BackgroundColor3=T.SfL},0.2); Tw(o.l,{TextColor3=T.TxS},0.2)
        Tw(o.i,{ImageColor3=T.TxS},0.2); Tw(o.d,{BackgroundTransparency=1},0.15); o.p.Visible = false
    end
    aTab = n; local c = tS[n]
    Tw(c.b,{BackgroundColor3=T.SfH},0.2); Tw(c.l,{TextColor3=T.Tx},0.2)
    Tw(c.i,{ImageColor3=T.Ac},0.2); Tw(c.d,{BackgroundTransparency=0},0.2); c.p.Visible = true
    -- Close any open popups (player list dropdowns)
    if _G.AUREN_CLOSE_PLAYER_LIST then pcall(_G.AUREN_CLOSE_PLAYER_LIST) end
    if _G.AUREN_CLOSE_FLING_LIST then pcall(_G.AUREN_CLOSE_FLING_LIST) end
end

-- Tab sizing: proportional width, icon+text grouped and centered via inner Frame
local TAB_FONT_SZ = 8
local TAB_ICON_SZ = 9
local TAB_GAP = 4

local function MkTab(name,icon)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0.2,-2,0,26)
    b.BackgroundColor3 = T.SfL; b.Text = ""; b.BorderSizePixel = 0; b.AutoButtonColor = false
    b.ZIndex = 3; b.Parent = TB; Crn(b,6)

    -- Inner group frame: auto-sizes to icon+text, centered in button via AnchorPoint
    local grp = Instance.new("Frame"); grp.BackgroundTransparency = 1; grp.BorderSizePixel = 0
    grp.Size = UDim2.new(0,0,0,26); grp.AutomaticSize = Enum.AutomaticSize.X
    grp.Position = UDim2.new(0.5,0,0,0); grp.AnchorPoint = Vector2.new(0.5,0)
    grp.ZIndex = 4; grp.Parent = b
    local gLay = Instance.new("UIListLayout"); gLay.FillDirection = Enum.FillDirection.Horizontal
    gLay.VerticalAlignment = Enum.VerticalAlignment.Center; gLay.Padding = UDim.new(0,TAB_GAP); gLay.Parent = grp

    -- Icon
    local i = Instance.new("ImageLabel"); i.Size = UDim2.new(0,TAB_ICON_SZ,0,TAB_ICON_SZ)
    i.BackgroundTransparency = 1; i.Image = icon; i.ImageColor3 = T.TxS
    i.ZIndex = 4; i.LayoutOrder = 1; i.Parent = grp

    -- Text: auto-width so it always fits the actual text
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(0,0,0,26); l.AutomaticSize = Enum.AutomaticSize.X
    l.BackgroundTransparency = 1; l.Text = L(name); l.TextColor3 = T.TxS
    l.TextSize = TAB_FONT_SZ; l.Font = Enum.Font.GothamBold
    l.ZIndex = 4; l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = 2; l.Parent = grp
    -- Underline at bottom of button
    local d = Instance.new("Frame"); d.Size = UDim2.new(1,0,0,2); d.Position = UDim2.new(0,0,1,-2)
    d.BackgroundColor3 = T.Ac; d.BackgroundTransparency = 1; d.BorderSizePixel = 0; d.ZIndex = 5; d.Parent = b; Crn(d,1)
    local p = Instance.new("ScrollingFrame"); p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1
    p.BorderSizePixel = 0; p.ScrollBarThickness = 3; p.ScrollBarImageColor3 = T.Ac; p.Visible = false
    p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.ScrollingDirection = Enum.ScrollingDirection.Y; p.Parent = Pgs
    local pPad = Instance.new("UIPadding"); pPad.PaddingRight = UDim.new(0,6); pPad.Parent = p
    local pl = Instance.new("UIListLayout"); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Padding = UDim.new(0,6); pl.Parent = p
    tS[name] = {b=b, l=l, i=i, d=d, p=p}
    b.MouseButton1Click:Connect(function() SwTab(name) end)
    return p
end

local pP = MkTab("Player", Ic.User)
local vP = MkTab("Visuals", Ic.Eye)
local cP = MkTab("Combat", Ic.Swords)
local coP = MkTab("Color", Ic.Palette)
local sP = MkTab("Settings", Ic.Cog)
SwTab("Player")

-- ==================== UI BUILDERS ====================
local function Sec(parent,title,icon,order,langKey)
    local s = Instance.new("Frame"); s.Size = UDim2.new(1,0,0,0); s.AutomaticSize = Enum.AutomaticSize.Y
    s.BackgroundColor3 = T.Sf; s.BorderSizePixel = 0; s.LayoutOrder = order; s.Parent = parent; Crn(s,8); Stk(s,T.Bd,1,0.5)
    local ly = Instance.new("UIListLayout"); ly.SortOrder = Enum.SortOrder.LayoutOrder; ly.Parent = s
    local h = Instance.new("Frame"); h.Size = UDim2.new(1,0,0,28); h.BackgroundTransparency = 1; h.LayoutOrder = 0; h.Parent = s
    if icon then
        local ic = Instance.new("ImageLabel"); ic.Size = UDim2.new(0,11,0,11); ic.Position = UDim2.new(0,12,0.5,-5)
        ic.BackgroundTransparency = 1; ic.Image = icon; ic.ImageColor3 = T.Ac; ic.Parent = h
    end
    local lb = Instance.new("TextLabel"); lb.Size = UDim2.new(1,-14,1,0); lb.Position = UDim2.new(0,icon and 27 or 12,0,0)
    lb.BackgroundTransparency = 1; lb.Text = title; lb.TextColor3 = T.TxS; lb.TextSize = 9; lb.Font = Enum.Font.GothamBold
    lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = h
    if langKey then table.insert(TranslatableUI, {obj=lb, key=langKey}) end
    return s
end

local function Tog(parent,text,def,order,cb,langKey)
    local c = Instance.new("Frame"); c.Size = UDim2.new(1,0,0,34); c.BackgroundTransparency = 1; c.LayoutOrder = order; c.Parent = parent
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,-60,1,0); l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = T.Tx; l.TextSize = 11; l.Font = Enum.Font.Gotham
    if langKey then table.insert(TranslatableUI, {obj=l, key=langKey}) end
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    local tk = Instance.new("TextButton"); tk.Size = UDim2.new(0,36,0,18); tk.Position = UDim2.new(1,-48,0.5,-9)
    tk.BackgroundColor3 = def and T.Ac or T.SfL; tk.BorderSizePixel = 0; tk.Text = ""; tk.AutoButtonColor = false
    tk.ZIndex = 3; tk.Parent = c; Crn(tk,9)
    local kn = Instance.new("Frame"); kn.Size = UDim2.new(0,12,0,12)
    kn.Position = def and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)
    kn.BackgroundColor3 = Color3.new(1,1,1); kn.BorderSizePixel = 0; kn.ZIndex = 4; kn.Parent = tk; Crn(kn,6)
    local en = def
    local function setToggle(state)
        en = state
        Tw(tk,{BackgroundColor3 = en and T.Ac or T.SfL},0.2)
        Tw(kn,{Position = en and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)},0.2)
    end
    tk.MouseButton1Click:Connect(function()
        en = not en
        setToggle(en)
        if cb then cb(en) end
    end)
    return setToggle
end

local activeSliderLock = nil  -- only one slider can be dragged at a time
local function Sld(parent,text,mn,mx,def,order,cb,langKey)
    local c = Instance.new("Frame"); c.Size = UDim2.new(1,0,0,44); c.BackgroundTransparency = 1; c.LayoutOrder = order; c.Parent = parent
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.55,-12,0,14); l.Position = UDim2.new(0,12,0,2)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = T.Tx; l.TextSize = 11; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    if langKey then table.insert(TranslatableUI, {obj=l, key=langKey}) end
    local vl = Instance.new("TextLabel"); vl.Size = UDim2.new(0.45,-12,0,14); vl.Position = UDim2.new(0.55,0,0,2)
    vl.BackgroundTransparency = 1; vl.Text = tostring(def); vl.TextColor3 = T.Ac; vl.TextSize = 11; vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = c
    local bg = Instance.new("Frame"); bg.Size = UDim2.new(1,-24,0,5); bg.Position = UDim2.new(0,12,0,24)
    bg.BackgroundColor3 = T.SfL; bg.BorderSizePixel = 0; bg.Parent = c; Crn(bg,3)
    local ir = (def - mn) / math.max(mx - mn, 1)
    local fi = Instance.new("Frame"); fi.Size = UDim2.new(ir,0,1,0); fi.BackgroundColor3 = T.Ac; fi.BorderSizePixel = 0; fi.Parent = bg; Crn(fi,3)
    local kb = Instance.new("Frame"); kb.Size = UDim2.new(0,12,0,12); kb.Position = UDim2.new(ir,-6,0.5,-6)
    kb.BackgroundColor3 = Color3.new(1,1,1); kb.BorderSizePixel = 0; kb.ZIndex = 2; kb.Parent = bg; Crn(kb,6)
    local sliding = false
    local sb = Instance.new("TextButton"); sb.Size = UDim2.new(1,10,1,16); sb.Position = UDim2.new(0,-5,0,-8)
    sb.BackgroundTransparency = 1; sb.Text = ""; sb.ZIndex = 3; sb.Parent = bg
    local function upd(inp)
        local r = math.clamp((inp.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local v = math.floor(mn + (mx - mn) * r)
        vl.Text = tostring(v); fi.Size = UDim2.new(r,0,1,0); kb.Position = UDim2.new(r,-6,0.5,-6)
        if cb then cb(v) end
    end
    sb.InputBegan:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            if activeSliderLock == nil then
                activeSliderLock = sb; sliding = true; upd(i)
            end
        end
    end)
    table.insert(allConns, UserInputService.InputChanged:Connect(function(i)
        if sliding and activeSliderLock == sb and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end
    end))
    table.insert(allConns, UserInputService.InputEnded:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            if activeSliderLock == sb then activeSliderLock = nil end
            sliding = false
        end
    end))
end

local function CPick(parent,text,def,order,cb,langKey)
    local cols = {Color3.fromRGB(0,220,90), Color3.fromRGB(0,255,180), Color3.fromRGB(0,180,255), Color3.fromRGB(255,255,255), Color3.fromRGB(255,0,0), Color3.fromRGB(255,220,50), Color3.fromRGB(255,100,175), Color3.fromRGB(150,75,255), Color3.fromRGB(0,255,255)}
    local c = Instance.new("Frame"); c.Size = UDim2.new(1,0,0,50); c.BackgroundTransparency = 1; c.LayoutOrder = order; c.Parent = parent
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,-12,0,16); l.Position = UDim2.new(0,12,0,1)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = T.Tx; l.TextSize = 11; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    if langKey then table.insert(TranslatableUI, {obj=l, key=langKey}) end
    local rw = Instance.new("Frame"); rw.Size = UDim2.new(1,-24,0,22); rw.Position = UDim2.new(0,12,0,20); rw.BackgroundTransparency = 1; rw.Parent = c
    local rl = Instance.new("UIListLayout"); rl.FillDirection = Enum.FillDirection.Horizontal; rl.Padding = UDim.new(0,4); rl.Parent = rw
    local ss = nil
    for _,co in ipairs(cols) do
        local b = Instance.new("TextButton"); b.Size = UDim2.new(0,22,0,22); b.BackgroundColor3 = co; b.Text = ""; b.AutoButtonColor = false; b.BorderSizePixel = 0; b.ZIndex = 3; b.Parent = rw; Crn(b,5)
        local st = Stk(b,Color3.new(1,1,1),2,1)
        if co == def then st.Transparency = 0; ss = st end
        b.MouseButton1Click:Connect(function() if ss then Tw(ss,{Transparency=1},0.12) end; ss = st; Tw(st,{Transparency=0},0.12); if cb then cb(co) end end)
    end
end

local function IRow(parent,lbl,val,order,langKey)
    local c = Instance.new("Frame"); c.Size = UDim2.new(1,0,0,24); c.BackgroundTransparency = 1; c.LayoutOrder = order; c.Parent = parent
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.5,-12,1,0); l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1; l.Text = lbl; l.TextColor3 = T.TxS; l.TextSize = 10; l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = c
    if langKey then table.insert(TranslatableUI, {obj=l, key=langKey}) end
    local v = Instance.new("TextLabel"); v.Size = UDim2.new(0.5,-12,1,0); v.Position = UDim2.new(0.5,0,0,0)
    v.BackgroundTransparency = 1; v.Text = val; v.TextColor3 = T.Tx; v.TextSize = 10; v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right; v.Parent = c; return v
end

local function Spc(p,o) local s = Instance.new("Frame"); s.Size = UDim2.new(1,0,0,4); s.BackgroundTransparency = 1; s.LayoutOrder = o; s.Parent = p end

-- ==================== PLAYER TAB ====================
do
local s4 = Sec(pP, "MOVEMENT", Ic.Move, 1, "Movement")
Sld(s4, "Speed", 16, 500, 16, 1, function(v)
    Config.Speed = v
    local ch = LocalPlayer.Character
    if ch then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end, "Speed")
Sld(s4, "Jump Power", 50, 500, 50, 2, function(v)
    Config.JumpPower = v
    local ch = LocalPlayer.Character
    if ch then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end, "JumpPower")

local s5 = Sec(pP, "FLY", Ic.Navigation, 2, "Fly")
Tog(s5, "Enable Fly", false, 1, function(v) Config.Fly = v end, "EnableFly")
Sld(s5, "Fly Speed", 10, 500, 80, 2, function(v) Config.FlySpeed = v end, "FlySpeed")

local flyInfo = Instance.new("Frame"); flyInfo.Size = UDim2.new(1,0,0,24); flyInfo.BackgroundTransparency = 1; flyInfo.LayoutOrder = 3; flyInfo.Parent = s5
local flyLbl = Instance.new("TextLabel"); flyLbl.Size = UDim2.new(1,-24,1,0); flyLbl.Position = UDim2.new(0,12,0,0)
flyLbl.BackgroundTransparency = 1; flyLbl.Text = L("FlyTip")
flyLbl.TextColor3 = T.TxD; flyLbl.TextSize = 8; flyLbl.Font = Enum.Font.Gotham; flyLbl.TextXAlignment = Enum.TextXAlignment.Left
flyLbl.TextWrapped = true; flyLbl.Parent = flyInfo
table.insert(TranslatableUI, {obj=flyLbl, key="FlyTip"})

local s6 = Sec(pP, "GHOST NOCLIP", Ic.Ghost, 3, "GhostNoclip")
Tog(s6, "Ghost Mode", false, 1, function(v) Config.GhostNoclip = v end, "GhostMode")

local gnInfo = Instance.new("Frame"); gnInfo.Size = UDim2.new(1,0,0,30); gnInfo.BackgroundTransparency = 1; gnInfo.LayoutOrder = 2; gnInfo.Parent = s6
local gnLbl = Instance.new("TextLabel"); gnLbl.Size = UDim2.new(1,-24,1,0); gnLbl.Position = UDim2.new(0,12,0,0)
gnLbl.BackgroundTransparency = 1; gnLbl.Text = L("GhostTip")
gnLbl.TextColor3 = T.TxD; gnLbl.TextSize = 8; gnLbl.Font = Enum.Font.Gotham; gnLbl.TextXAlignment = Enum.TextXAlignment.Left
gnLbl.TextWrapped = true; gnLbl.Parent = gnInfo
table.insert(TranslatableUI, {obj=gnLbl, key="GhostTip"})

Spc(pP, 99)
end

-- ==================== VISUALS TAB ====================
do
local v1 = Sec(vP, "ESP", Ic.Eye, 1, "ESP")
Tog(v1, "Enable Highlight", false, 1, function(v) Config.Highlight = v; Rebuild() end, "EnableHighlight")
Tog(v1, "Always On Top", true, 2, function(v) Config.DepthMode = v; Rebuild() end, "AlwaysOnTop")

local v4 = Sec(vP, "DISTANCE", Ic.Ruler, 2, "Distance")
Tog(v4, "Show Distance", false, 1, function(v) Config.ShowDistance = v; Rebuild() end, "ShowDistance")
Sld(v4, "Max Distance (0=off)", 0, 2000, 0, 2, function(v) Config.MaxDistance = v end, "MaxDist")

local v5 = Sec(vP, "HEALTH", Ic.Heart, 4, "Health")
Tog(v5, "Show Health", false, 1, function(v) Config.ShowHealth = v; Rebuild() end, "ShowHealth")
-- Health legend
local lg2 = Instance.new("Frame"); lg2.Size = UDim2.new(1,0,0,40); lg2.BackgroundTransparency = 1; lg2.LayoutOrder = 2; lg2.Parent = v5
local healthLangKeys = {"Full","Good","Hurt","Low","Crit"}
local healthLegendLbls = {}
local stgs = {{c=T.HF,n=L("Full")},{c=T.HH,n=L("Good")},{c=T.HM,n=L("Hurt")},{c=T.HL,n=L("Low")},{c=T.HC,n=L("Crit")}}
for i,st in ipairs(stgs) do
    local x = (i-1) / #stgs; local w = 1 / #stgs
    local h = Instance.new("TextLabel"); h.Size = UDim2.new(w,0,0,16); h.Position = UDim2.new(x,0,0,0)
    h.BackgroundTransparency = 1; h.Text = "\226\153\165"; h.TextColor3 = st.c; h.TextSize = 14; h.Font = Enum.Font.GothamBold; h.Parent = lg2
    local lb = Instance.new("TextLabel"); lb.Size = UDim2.new(w,0,0,10); lb.Position = UDim2.new(x,0,0,16)
    lb.BackgroundTransparency = 1; lb.Text = st.n; lb.TextColor3 = st.c; lb.TextSize = 7; lb.Font = Enum.Font.GothamBold; lb.Parent = lg2
    healthLegendLbls[i] = lb
    table.insert(TranslatableUI, {obj=lb, key=healthLangKeys[i]})
end

Spc(vP, 99)
end

-- ==================== COMBAT TAB ====================
do
local cs1 = Sec(cP, "ANTI-KNOCKBACK", Ic.Shield, 1, "Defense")
Tog(cs1, "Reduce Knockback", false, 1, function(v)
    Config.Noclip = v
    if v then
        local ch = LocalPlayer.Character
        if ch then wireChildAdded(ch) end
    else
        unwireChildAdded()
        -- Re-enable states that were disabled
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            end
        end)
    end
end, "DodgeProjectile")

local ncInfo = Instance.new("Frame"); ncInfo.Size = UDim2.new(1,0,0,30); ncInfo.BackgroundTransparency = 1; ncInfo.LayoutOrder = 2; ncInfo.Parent = cs1
local ncLbl = Instance.new("TextLabel"); ncLbl.Size = UDim2.new(1,-24,1,0); ncLbl.Position = UDim2.new(0,12,0,0)
ncLbl.BackgroundTransparency = 1; ncLbl.Text = L("DefenseTip")
ncLbl.TextColor3 = T.TxD; ncLbl.TextSize = 8; ncLbl.Font = Enum.Font.Gotham; ncLbl.TextXAlignment = Enum.TextXAlignment.Left
ncLbl.TextWrapped = true; ncLbl.Parent = ncInfo
table.insert(TranslatableUI, {obj=ncLbl, key="DefenseTip"})

-- Shared slap delay setting (applies to all slap modes)
local csSlapSet = Sec(cP, "SLAP BUTTON SETTINGS", Ic.Timer, 2, "CombatSettings")
Sld(csSlapSet, "Slap Delay (ms)", 10, 500, 50, 1, function(v) Config.SpamSlapDelay = v / 1000 end, "SlapDelay")
Sld(csSlapSet, "Slap Power", 1, 100, 1, 2, function(v) Config.SlapPower = v end, "SlapPower")

local sdInfo = Instance.new("Frame"); sdInfo.Size = UDim2.new(1,0,0,36); sdInfo.BackgroundTransparency = 1; sdInfo.LayoutOrder = 3; sdInfo.Parent = csSlapSet
local sdLbl = Instance.new("TextLabel"); sdLbl.Size = UDim2.new(1,-24,1,0); sdLbl.Position = UDim2.new(0,12,0,0)
sdLbl.BackgroundTransparency = 1; sdLbl.Text = L("SlapDelayTip") .. "\n" .. L("SlapPowerTip")
sdLbl.TextColor3 = T.TxD; sdLbl.TextSize = 8; sdLbl.Font = Enum.Font.Gotham; sdLbl.TextXAlignment = Enum.TextXAlignment.Left
sdLbl.TextWrapped = true; sdLbl.Parent = sdInfo
table.insert(TranslatableUI, {obj=sdLbl, key="SlapDelayTip"})
end

-- ==================== TARGET SLAP (Player Selector) ====================
local cs4 = Sec(cP, "SLAP", Ic.Sword, 3, "Slap")

-- Player dropdown button
local tsDrop = Instance.new("Frame"); tsDrop.Size = UDim2.new(1,0,0,36); tsDrop.BackgroundTransparency = 1
tsDrop.LayoutOrder = 1; tsDrop.Parent = cs4

local tsDropLbl = Instance.new("TextLabel"); tsDropLbl.Size = UDim2.new(0.22,0,1,0); tsDropLbl.Position = UDim2.new(0,12,0,0)
tsDropLbl.BackgroundTransparency = 1; tsDropLbl.Text = L("TargetPlayer"); tsDropLbl.TextColor3 = T.Tx
tsDropLbl.TextSize = 10; tsDropLbl.Font = Enum.Font.GothamBold; tsDropLbl.TextXAlignment = Enum.TextXAlignment.Left
tsDropLbl.ZIndex = 3; tsDropLbl.Parent = tsDrop
table.insert(TranslatableUI, {obj=tsDropLbl, key="TargetPlayer"})

local tsSelBtn = Instance.new("TextButton"); tsSelBtn.Size = UDim2.new(0.72,0,0,26); tsSelBtn.Position = UDim2.new(0.24,0,0.5,-13)
tsSelBtn.BackgroundColor3 = T.SfL; tsSelBtn.BorderSizePixel = 0; tsSelBtn.Text = ""
tsSelBtn.AutoButtonColor = false; tsSelBtn.ZIndex = 3; tsSelBtn.Parent = tsDrop; Crn(tsSelBtn,6); Stk(tsSelBtn, T.Bd, 1, 0.2)

-- Text label inside button (full width, arrow overlaps slightly on right)
local tsSelLbl = Instance.new("TextLabel"); tsSelLbl.Size = UDim2.new(1,0,1,0)
tsSelLbl.Position = UDim2.new(0,0,0,0); tsSelLbl.BackgroundTransparency = 1
tsSelLbl.Text = L("SelectPlayer"); tsSelLbl.TextColor3 = T.TxD; tsSelLbl.TextSize = 9
tsSelLbl.Font = Enum.Font.GothamBold; tsSelLbl.TextXAlignment = Enum.TextXAlignment.Center
tsSelLbl.ZIndex = 4; tsSelLbl.Parent = tsSelBtn
table.insert(TranslatableUI, {obj=tsSelLbl, key="SelectPlayer", resetKey="SelectPlayer"})

-- Dropdown arrow "v" (like language selector)
local tsSelArrow = Instance.new("TextLabel"); tsSelArrow.Size = UDim2.new(0,12,1,0)
tsSelArrow.Position = UDim2.new(1,-14,0,0); tsSelArrow.BackgroundTransparency = 1
tsSelArrow.Text = "v"; tsSelArrow.TextColor3 = T.TxD; tsSelArrow.TextSize = 8
tsSelArrow.Font = Enum.Font.GothamBold; tsSelArrow.ZIndex = 4; tsSelArrow.Parent = tsSelBtn

-- Player list panel: parented to Main so it floats above everything
local tsListOpen = false
local tsListFrame = Instance.new("ScrollingFrame"); tsListFrame.Size = UDim2.new(0,0,0,0)
tsListFrame.BackgroundColor3 = T.Sf; tsListFrame.BorderSizePixel = 0
tsListFrame.ClipsDescendants = true; tsListFrame.ScrollBarThickness = 0; tsListFrame.ScrollBarImageColor3 = T.Ac
tsListFrame.Visible = false; tsListFrame.ZIndex = 60; tsListFrame.CanvasSize = UDim2.new(0,0,0,0)
tsListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; tsListFrame.Parent = Content; Crn(tsListFrame,6); Stk(tsListFrame, T.Bd, 1, 0.3)
local tsListLay = Instance.new("UIListLayout"); tsListLay.SortOrder = Enum.SortOrder.Name; tsListLay.Parent = tsListFrame

-- Slap Once button (declared early so closePlayerList can reference it)
local tsOnceRow = Instance.new("Frame"); tsOnceRow.Size = UDim2.new(1,0,0,36); tsOnceRow.BackgroundTransparency = 1
tsOnceRow.LayoutOrder = 2; tsOnceRow.Parent = cs4
local tsOnceBtn = Instance.new("TextButton"); tsOnceBtn.Size = UDim2.new(1,-24,0,28); tsOnceBtn.Position = UDim2.new(0,12,0.5,-14)
tsOnceBtn.BackgroundColor3 = T.SfL; tsOnceBtn.BorderSizePixel = 0; tsOnceBtn.Text = L("SlapOnce")
tsOnceBtn.TextColor3 = T.Ac; tsOnceBtn.TextSize = 10; tsOnceBtn.Font = Enum.Font.GothamBold
tsOnceBtn.AutoButtonColor = false; tsOnceBtn.ZIndex = 3; tsOnceBtn.Parent = tsOnceRow; Crn(tsOnceBtn,6); Stk(tsOnceBtn, T.Ac, 1, 0.3)
table.insert(TranslatableUI, {obj=tsOnceBtn, key="SlapOnce"})

-- Position list below the select button using AbsolutePosition
local function positionList()
    local absBtn = tsSelBtn.AbsolutePosition
    local absContent = Content.AbsolutePosition
    local btnH = tsSelBtn.AbsoluteSize.Y
    local scale = Content.AbsoluteSize.X / (BASE_W - 0)
    tsListFrame.Position = UDim2.new(0, (absBtn.X - absContent.X) / scale, 0, (absBtn.Y - absContent.Y + btnH + 2) / scale)
end

local tsListPosConn = nil
local function closePlayerList()
    if not tsListOpen then return end
    tsListOpen = false
    if tsListPosConn then tsListPosConn:Disconnect(); tsListPosConn = nil end
    Tw(tsSelArrow,{Rotation=0},0.15)
    -- Instant hide — no animation to avoid green flash
    tsListFrame.Visible = false
    tsListFrame.ScrollBarThickness = 0
    local w = tsSelBtn.AbsoluteSize.X / (Content.AbsoluteSize.X / BASE_W)
    tsListFrame.Size = UDim2.new(0,w,0,0)
    -- Restore Slap Once button + reset its hover state
    tsOnceBtn.BackgroundColor3 = T.SfL; tsOnceBtn.TextColor3 = T.Ac
    tsOnceRow.Visible = true
end
_G.AUREN_CLOSE_PLAYER_LIST = closePlayerList

local function refreshPlayerList()
    for _, ch in ipairs(tsListFrame:GetChildren()) do
        if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
    end
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            count = count + 1
            local opt = Instance.new("TextButton"); opt.Size = UDim2.new(1,0,0,24)
            opt.BackgroundColor3 = T.Sf; opt.BorderSizePixel = 0; opt.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
            opt.TextColor3 = T.Tx; opt.TextSize = 9; opt.Font = Enum.Font.GothamBold
            opt.TextTruncate = Enum.TextTruncate.AtEnd; opt.AutoButtonColor = false; opt.ZIndex = 61; opt.Parent = tsListFrame
            opt.MouseEnter:Connect(function() Tw(opt,{BackgroundColor3=T.SfH},0.1) end)
            opt.MouseLeave:Connect(function() Tw(opt,{BackgroundColor3=T.Sf},0.1) end)
            opt.MouseButton1Click:Connect(function()
                Config.TargetSlapPlr = plr
                tsSelLbl.Text = plr.DisplayName
                tsSelLbl.TextColor3 = T.Ac
                closePlayerList()
            end)
        end
    end
    -- Show "no players" message if empty
    if count == 0 then
        local empty = Instance.new("TextLabel"); empty.Size = UDim2.new(1,0,0,28)
        empty.BackgroundTransparency = 1; empty.Text = L("NoPlayers")
        empty.TextColor3 = T.TxD; empty.TextSize = 8; empty.Font = Enum.Font.Gotham
        empty.ZIndex = 61; empty.Parent = tsListFrame
    end
    return count
end

tsSelBtn.MouseEnter:Connect(function() Tw(tsSelBtn,{BackgroundColor3=T.SfH},0.12) end)
tsSelBtn.MouseLeave:Connect(function() if not tsListOpen then Tw(tsSelBtn,{BackgroundColor3=T.SfL},0.12) end end)
tsSelBtn.MouseButton1Click:Connect(function()
    if tsListOpen then
        closePlayerList()
    else
        tsListOpen = true
        -- Close fling dropdown if open
        if _G.AUREN_CLOSE_FLING_LIST then pcall(_G.AUREN_CLOSE_FLING_LIST) end
        -- Hide Slap Once to prevent hover bleed-through
        tsOnceRow.Visible = false
        local count = refreshPlayerList()
        positionList()
        -- Keep repositioning every frame while open to avoid stale AbsolutePosition
        tsListPosConn = RunService.RenderStepped:Connect(positionList)
        tsListFrame.Visible = true
        local needsScroll = count > 5 -- 5 items * 24px = 120px max
        tsListFrame.ScrollBarThickness = needsScroll and 2 or 0
        Tw(tsSelArrow,{Rotation=180},0.15)
        local h = count > 0 and math.min(count * 24, 120) or 28
        local w = tsSelBtn.AbsoluteSize.X / (Content.AbsoluteSize.X / BASE_W)
        tsListFrame.Size = UDim2.new(0,w,0,0)
        Tw(tsListFrame,{Size=UDim2.new(0,w,0,h)},0.2,Enum.EasingStyle.Quint)
    end
end)

tsOnceBtn.MouseEnter:Connect(function() Tw(tsOnceBtn,{BackgroundColor3=T.Ac},0.15); Tw(tsOnceBtn,{TextColor3=T.Bg},0.15) end)
tsOnceBtn.MouseLeave:Connect(function() Tw(tsOnceBtn,{BackgroundColor3=T.SfL},0.15); Tw(tsOnceBtn,{TextColor3=T.Ac},0.15) end)
-- Find best slap item: GoldSlap > SilverSlap > PurpleSlap > SlapHand
local SLAP_PRIORITY = {"GoldSlap", "SilverSlap", "PurpleSlap", "SlapHand"}
local function findBestSlap()
    local ch = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    -- Try known slaps first (priority order)
    for _, name in ipairs(SLAP_PRIORITY) do
        local tool = ch and ch:FindFirstChild(name)
        if not tool and bp then tool = bp:FindFirstChild(name) end
        if tool then return tool end
    end
    -- Fallback: any tool with an Event child (unknown slap)
    for _, src in ipairs({ch, bp}) do
        if src then
            for _, item in ipairs(src:GetChildren()) do
                if item:IsA("Tool") and item:FindFirstChild("Event") then
                    return item
                end
            end
        end
    end
    return nil
end

tsOnceBtn.MouseButton1Click:Connect(function()
    local plr = Config.TargetSlapPlr
    if not plr or not plr.Parent or not plr.Character then return end
    local slapTool = findBestSlap()
    if slapTool then
        local ev = slapTool:FindFirstChild("Event")
        if ev then
            pcall(function()
                local p = Config.SlapPower
                ev:FireServer("slash", plr.Character, Vector3.new(
                    (math.random() * 10 - 5) * p, (math.random() * 0.001 - 0.0005) * p, (math.random() * 10 - 5) * p
                ))
            end)
        end
    end
    -- Flash feedback
    tsOnceBtn.BackgroundColor3 = T.Ac; tsOnceBtn.TextColor3 = T.Bg
    task.delay(0.15, function()
        if tsOnceBtn and tsOnceBtn.Parent then
            Tw(tsOnceBtn,{BackgroundColor3=T.SfL},0.2); Tw(tsOnceBtn,{TextColor3=T.Ac},0.2)
        end
    end)
end)

-- Auto Slap Target toggle
local setTargetSlapTog = Tog(cs4, "Spam Slap Target", false, 3, function(v) Config.TargetSlapAuto = v end, "SpamSlapTarget")

-- Spam Slap All toggle (inside SLAP section)
Tog(cs4, "Spam Slap All Players", false, 4, function(v) Config.SpamSlapAll = v end, "SpamSlapToggle")

-- Tip
local tsInfo = Instance.new("Frame"); tsInfo.Size = UDim2.new(1,0,0,24); tsInfo.BackgroundTransparency = 1; tsInfo.LayoutOrder = 5; tsInfo.Parent = cs4
local tsLbl = Instance.new("TextLabel"); tsLbl.Size = UDim2.new(1,-24,1,0); tsLbl.Position = UDim2.new(0,12,0,0)
tsLbl.BackgroundTransparency = 1; tsLbl.Text = L("SlapTip")
tsLbl.TextColor3 = T.TxD; tsLbl.TextSize = 8; tsLbl.Font = Enum.Font.Gotham; tsLbl.TextXAlignment = Enum.TextXAlignment.Left
tsLbl.TextWrapped = true; tsLbl.Parent = tsInfo
table.insert(TranslatableUI, {obj=tsLbl, key="SlapTip"})

-- Clean up if selected player leaves — reset config + toggle UI
Players.PlayerRemoving:Connect(function(plr)
    if Config.TargetSlapPlr == plr then
        Config.TargetSlapPlr = nil
        Config.TargetSlapAuto = false
        if setTargetSlapTog then setTargetSlapTog(false) end
        tsSelLbl.Text = L("SelectPlayer")
        tsSelLbl.TextColor3 = T.TxD
        closePlayerList()
    end
    if Config.FlingPlr == plr then
        Config.FlingPlr = nil
        Config.FlingSpam = false
        if _G.AUREN_FLING_RESET then pcall(_G.AUREN_FLING_RESET) end
    end
end)

-- ==================== FLING ====================
local FLING_VEC = Vector3.new(5244532.5, -237196.609375, 4108899)
do -- Fling UI scope (wrapped to reduce top-level local count)
local cs5 = Sec(cP, "FLING", Ic.Flame, 4, "FlingSection")

-- Player dropdown button
local flDrop = Instance.new("Frame"); flDrop.Size = UDim2.new(1,0,0,36); flDrop.BackgroundTransparency = 1
flDrop.LayoutOrder = 1; flDrop.Parent = cs5

local flDropLbl = Instance.new("TextLabel"); flDropLbl.Size = UDim2.new(0.22,0,1,0); flDropLbl.Position = UDim2.new(0,12,0,0)
flDropLbl.BackgroundTransparency = 1; flDropLbl.Text = L("FlingPlayer"); flDropLbl.TextColor3 = T.Tx
flDropLbl.TextSize = 10; flDropLbl.Font = Enum.Font.GothamBold; flDropLbl.TextXAlignment = Enum.TextXAlignment.Left
flDropLbl.ZIndex = 3; flDropLbl.Parent = flDrop
table.insert(TranslatableUI, {obj=flDropLbl, key="FlingPlayer"})

local flSelBtn = Instance.new("TextButton"); flSelBtn.Size = UDim2.new(0.72,0,0,26); flSelBtn.Position = UDim2.new(0.24,0,0.5,-13)
flSelBtn.BackgroundColor3 = T.SfL; flSelBtn.BorderSizePixel = 0; flSelBtn.Text = ""
flSelBtn.AutoButtonColor = false; flSelBtn.ZIndex = 3; flSelBtn.Parent = flDrop; Crn(flSelBtn,6); Stk(flSelBtn, T.Bd, 1, 0.2)

local flSelLbl = Instance.new("TextLabel"); flSelLbl.Size = UDim2.new(1,0,1,0)
flSelLbl.Position = UDim2.new(0,0,0,0); flSelLbl.BackgroundTransparency = 1
flSelLbl.Text = L("FlingSelectPlayer"); flSelLbl.TextColor3 = T.TxD; flSelLbl.TextSize = 9
flSelLbl.Font = Enum.Font.GothamBold; flSelLbl.TextXAlignment = Enum.TextXAlignment.Center
flSelLbl.ZIndex = 4; flSelLbl.Parent = flSelBtn
table.insert(TranslatableUI, {obj=flSelLbl, key="FlingSelectPlayer", resetKey="FlingSelectPlayer"})

local flSelArrow = Instance.new("TextLabel"); flSelArrow.Size = UDim2.new(0,12,1,0)
flSelArrow.Position = UDim2.new(1,-14,0,0); flSelArrow.BackgroundTransparency = 1
flSelArrow.Text = "v"; flSelArrow.TextColor3 = T.TxD; flSelArrow.TextSize = 8
flSelArrow.Font = Enum.Font.GothamBold; flSelArrow.ZIndex = 4; flSelArrow.Parent = flSelBtn

-- Fling player list panel (parented to Main to float above)
local flListOpen = false
local flListFrame = Instance.new("ScrollingFrame"); flListFrame.Size = UDim2.new(0,0,0,0)
flListFrame.BackgroundColor3 = T.Sf; flListFrame.BorderSizePixel = 0
flListFrame.ClipsDescendants = true; flListFrame.ScrollBarThickness = 0; flListFrame.ScrollBarImageColor3 = T.Ac
flListFrame.Visible = false; flListFrame.ZIndex = 60; flListFrame.CanvasSize = UDim2.new(0,0,0,0)
flListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y; flListFrame.Parent = Content; Crn(flListFrame,6); Stk(flListFrame, T.Bd, 1, 0.3)
local flListLay = Instance.new("UIListLayout"); flListLay.SortOrder = Enum.SortOrder.Name; flListLay.Parent = flListFrame

-- Fling Once button (declared early for closePlayerList ref)
local flOnceRow = Instance.new("Frame"); flOnceRow.Size = UDim2.new(1,0,0,36); flOnceRow.BackgroundTransparency = 1
flOnceRow.LayoutOrder = 2; flOnceRow.Parent = cs5
local flOnceBtn = Instance.new("TextButton"); flOnceBtn.Size = UDim2.new(1,-24,0,28); flOnceBtn.Position = UDim2.new(0,12,0.5,-14)
flOnceBtn.BackgroundColor3 = T.SfL; flOnceBtn.BorderSizePixel = 0; flOnceBtn.Text = L("FlingOnce")
flOnceBtn.TextColor3 = T.Ac; flOnceBtn.TextSize = 10; flOnceBtn.Font = Enum.Font.GothamBold
flOnceBtn.AutoButtonColor = false; flOnceBtn.ZIndex = 3; flOnceBtn.Parent = flOnceRow; Crn(flOnceBtn,6); Stk(flOnceBtn, T.Ac, 1, 0.3)
table.insert(TranslatableUI, {obj=flOnceBtn, key="FlingOnce"})

-- Position list below the fling select button
local flListPosConn = nil
local function flPositionList()
    local absBtn = flSelBtn.AbsolutePosition
    local absContent = Content.AbsolutePosition
    local btnH = flSelBtn.AbsoluteSize.Y
    local scale = Content.AbsoluteSize.X / BASE_W
    flListFrame.Position = UDim2.new(0, (absBtn.X - absContent.X) / scale, 0, (absBtn.Y - absContent.Y + btnH + 2) / scale)
end

local function closeFlingList()
    if not flListOpen then return end
    flListOpen = false
    if flListPosConn then flListPosConn:Disconnect(); flListPosConn = nil end
    Tw(flSelArrow,{Rotation=0},0.15)
    flListFrame.Visible = false
    flListFrame.ScrollBarThickness = 0
    local w = flSelBtn.AbsoluteSize.X / (Content.AbsoluteSize.X / BASE_W)
    flListFrame.Size = UDim2.new(0,w,0,0)
    flOnceBtn.BackgroundColor3 = T.SfL; flOnceBtn.TextColor3 = T.Ac
    flOnceRow.Visible = true
end
_G.AUREN_CLOSE_FLING_LIST = closeFlingList

local function refreshFlingList()
    for _, ch in ipairs(flListFrame:GetChildren()) do
        if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
    end
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            count = count + 1
            local opt = Instance.new("TextButton"); opt.Size = UDim2.new(1,0,0,24)
            opt.BackgroundColor3 = T.Sf; opt.BorderSizePixel = 0; opt.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
            opt.TextColor3 = T.Tx; opt.TextSize = 9; opt.Font = Enum.Font.GothamBold
            opt.TextTruncate = Enum.TextTruncate.AtEnd; opt.AutoButtonColor = false; opt.ZIndex = 61; opt.Parent = flListFrame
            opt.MouseEnter:Connect(function() Tw(opt,{BackgroundColor3=T.SfH},0.1) end)
            opt.MouseLeave:Connect(function() Tw(opt,{BackgroundColor3=T.Sf},0.1) end)
            opt.MouseButton1Click:Connect(function()
                Config.FlingPlr = plr
                flSelLbl.Text = plr.DisplayName
                flSelLbl.TextColor3 = T.Ac
                closeFlingList()
            end)
        end
    end
    if count == 0 then
        local empty = Instance.new("TextLabel"); empty.Size = UDim2.new(1,0,0,28)
        empty.BackgroundTransparency = 1; empty.Text = L("NoPlayers")
        empty.TextColor3 = T.TxD; empty.TextSize = 8; empty.Font = Enum.Font.Gotham
        empty.ZIndex = 61; empty.Parent = flListFrame
    end
    return count
end

flSelBtn.MouseEnter:Connect(function() Tw(flSelBtn,{BackgroundColor3=T.SfH},0.12) end)
flSelBtn.MouseLeave:Connect(function() if not flListOpen then Tw(flSelBtn,{BackgroundColor3=T.SfL},0.12) end end)
flSelBtn.MouseButton1Click:Connect(function()
    if flListOpen then
        closeFlingList()
    else
        flListOpen = true
        -- Close target slap dropdown if open
        closePlayerList()
        flOnceRow.Visible = false
        local count = refreshFlingList()
        flPositionList()
        flListPosConn = RunService.RenderStepped:Connect(flPositionList)
        flListFrame.Visible = true
        local needsScroll = count > 5
        flListFrame.ScrollBarThickness = needsScroll and 2 or 0
        Tw(flSelArrow,{Rotation=180},0.15)
        local h = count > 0 and math.min(count * 24, 120) or 28
        local w = flSelBtn.AbsoluteSize.X / (Content.AbsoluteSize.X / BASE_W)
        flListFrame.Size = UDim2.new(0,w,0,0)
        Tw(flListFrame,{Size=UDim2.new(0,w,0,h)},0.2,Enum.EasingStyle.Quint)
    end
end)

-- Fling Once click
flOnceBtn.MouseEnter:Connect(function() Tw(flOnceBtn,{BackgroundColor3=T.Ac},0.15); Tw(flOnceBtn,{TextColor3=T.Bg},0.15) end)
flOnceBtn.MouseLeave:Connect(function() Tw(flOnceBtn,{BackgroundColor3=T.SfL},0.15); Tw(flOnceBtn,{TextColor3=T.Ac},0.15) end)
flOnceBtn.MouseButton1Click:Connect(function()
    local plr = Config.FlingPlr
    if not plr or not plr.Parent or not plr.Character then return end
    local slapTool = findBestSlap()
    if slapTool then
        local ev = slapTool:FindFirstChild("Event")
        if ev then
            pcall(function()
                ev:FireServer("slash", plr.Character, FLING_VEC)
            end)
        end
    end
    flOnceBtn.BackgroundColor3 = T.Ac; flOnceBtn.TextColor3 = T.Bg
    task.delay(0.15, function()
        if flOnceBtn and flOnceBtn.Parent then
            Tw(flOnceBtn,{BackgroundColor3=T.SfL},0.2); Tw(flOnceBtn,{TextColor3=T.Ac},0.2)
        end
    end)
end)

-- Spam Fling Target toggle
local setFlingSpamTog = Tog(cs5, "Spam Fling Target", false, 3, function(v) Config.FlingSpam = v end, "FlingSpamTarget")

-- Fling All Players button (one-shot)
local flAllRow = Instance.new("Frame"); flAllRow.Size = UDim2.new(1,0,0,36); flAllRow.BackgroundTransparency = 1
flAllRow.LayoutOrder = 4; flAllRow.Parent = cs5
local flAllBtn = Instance.new("TextButton"); flAllBtn.Size = UDim2.new(1,-24,0,28); flAllBtn.Position = UDim2.new(0,12,0.5,-14)
flAllBtn.BackgroundColor3 = T.SfL; flAllBtn.BorderSizePixel = 0; flAllBtn.Text = L("FlingAll")
flAllBtn.TextColor3 = T.Ac; flAllBtn.TextSize = 10; flAllBtn.Font = Enum.Font.GothamBold
flAllBtn.AutoButtonColor = false; flAllBtn.ZIndex = 3; flAllBtn.Parent = flAllRow; Crn(flAllBtn,6); Stk(flAllBtn, T.Ac, 1, 0.3)
table.insert(TranslatableUI, {obj=flAllBtn, key="FlingAll"})

flAllBtn.MouseEnter:Connect(function() Tw(flAllBtn,{BackgroundColor3=T.Ac},0.15); Tw(flAllBtn,{TextColor3=T.Bg},0.15) end)
flAllBtn.MouseLeave:Connect(function() Tw(flAllBtn,{BackgroundColor3=T.SfL},0.15); Tw(flAllBtn,{TextColor3=T.Ac},0.15) end)
flAllBtn.MouseButton1Click:Connect(function()
    local slapTool = findBestSlap()
    if not slapTool then return end
    local ev = slapTool:FindFirstChild("Event")
    if not ev then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            pcall(function()
                ev:FireServer("slash", plr.Character, FLING_VEC)
            end)
        end
    end
    flAllBtn.BackgroundColor3 = T.Ac; flAllBtn.TextColor3 = T.Bg
    task.delay(0.15, function()
        if flAllBtn and flAllBtn.Parent then
            Tw(flAllBtn,{BackgroundColor3=T.SfL},0.2); Tw(flAllBtn,{TextColor3=T.Ac},0.2)
        end
    end)
end)

-- Spam Fling All Players toggle
Tog(cs5, "Spam Fling All Players", false, 5, function(v) Config.SpamFlingAll = v end, "SpamFlingAll")

-- Tip
local flInfo = Instance.new("Frame"); flInfo.Size = UDim2.new(1,0,0,28); flInfo.BackgroundTransparency = 1; flInfo.LayoutOrder = 6; flInfo.Parent = cs5
local flLbl = Instance.new("TextLabel"); flLbl.Size = UDim2.new(1,-24,1,0); flLbl.Position = UDim2.new(0,12,0,0)
flLbl.BackgroundTransparency = 1; flLbl.Text = L("FlingTip")
flLbl.TextColor3 = T.TxD; flLbl.TextSize = 8; flLbl.Font = Enum.Font.Gotham; flLbl.TextXAlignment = Enum.TextXAlignment.Left
flLbl.TextWrapped = true; flLbl.Parent = flInfo
table.insert(TranslatableUI, {obj=flLbl, key="FlingTip"})

-- Register fling reset callback (after all fling locals are defined)
_G.AUREN_FLING_RESET = function()
    if setFlingSpamTog then setFlingSpamTog(false) end
    flSelLbl.Text = L("FlingSelectPlayer")
    flSelLbl.TextColor3 = T.TxD
    closeFlingList()
end
end -- end Fling UI scope

Spc(cP, 99)

-- ==================== COLOR TAB ====================
do
local co1 = Sec(coP, "HIGHLIGHT COLORS", Ic.Palette, 1, "HighlightColors")
CPick(co1, "Fill Color", Config.FillColor, 1, function(c) Config.FillColor = c; UpdHLCol() end, "FillColor")
CPick(co1, "Outline Color", Config.OutlineColor, 2, function(c) Config.OutlineColor = c; UpdHLCol() end, "OutlineColor")
Sld(co1, "Fill Opacity", 0, 100, math.floor((1 - Config.FillTransparency) * 100), 3, function(v) Config.FillTransparency = 1 - (v / 100); UpdHLCol() end, "FillOpacity")
Sld(co1, "Outline Opacity", 0, 100, math.floor((1 - Config.OutlineTransparency) * 100), 4, function(v) Config.OutlineTransparency = 1 - (v / 100); UpdHLCol() end, "OutlineOpacity")

Spc(coP, 99)
end

-- ==================== SETTINGS TAB ====================
local sc1 = Sec(sP, "UI SCALE", Ic.Scaling, 1, "UIScale")
do
    local scalePresets = {{label="S", val=0.75}, {label="M", val=1.0}, {label="L", val=1.15}, {label="XL", val=1.35}}
    local scRow = Instance.new("Frame"); scRow.Size = UDim2.new(1,0,0,36); scRow.BackgroundTransparency = 1; scRow.LayoutOrder = 1; scRow.Parent = sc1
    local scBtns = {}
    for i, preset in ipairs(scalePresets) do
        local bw = (1 / #scalePresets)
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(bw, -6, 0, 28)
        btn.Position = UDim2.new((i-1) * bw, 3, 0, 4)
        btn.BackgroundColor3 = (preset.val == 1.0) and T.Ac or T.SfL
        btn.BorderSizePixel = 0; btn.Text = preset.label; btn.TextColor3 = (preset.val == 1.0) and T.Bg or T.Tx
        btn.TextSize = 12; btn.Font = Enum.Font.GothamBold; btn.AutoButtonColor = false
        btn.ZIndex = 3; btn.Parent = scRow; Crn(btn, 6)
        scBtns[i] = btn
        btn.MouseButton1Click:Connect(function()
            Config.UIScale = preset.val
            UIScaleObj.Scale = getAutoScale() * Config.UIScale
            for j, b in ipairs(scBtns) do
                local active = (j == i)
                Tw(b, {BackgroundColor3 = active and T.Ac or T.SfL}, 0.15)
                b.TextColor3 = active and T.Bg or T.Tx
            end
        end)
    end
end

local sc3 = Sec(sP, "INFO", Ic.Info, 2, "Info")
local pcI = IRow(sc3, "Players", tostring(#Players:GetPlayers()), 1, "Players")
local fpI = IRow(sc3, "FPS", "60", 2, "FPS")
IRow(sc3, "Script", "Auren MAX", 3, "Script")
Spc(sP, 99)

-- ==================== LANGUAGE UPDATE FUNCTION ====================
function updateAllLangUI()
    -- Update all registered translatable elements
    for _, entry in ipairs(TranslatableUI) do
        if entry.obj and entry.obj.Parent then
            -- Skip player select labels if a player is currently selected
            if entry.resetKey == "SelectPlayer" and Config.TargetSlapPlr then
                -- Don't overwrite player name
            elseif entry.resetKey == "FlingSelectPlayer" and Config.FlingPlr then
                -- Don't overwrite player name
            else
                entry.obj.Text = L(entry.key)
            end
        end
    end
    -- Update tab labels
    for name, data in pairs(tS) do
        if data.l and data.l.Parent then
            data.l.Text = L(name)
        end
    end
end

-- ==================== ESP CORE ====================
function UpdHLCol()
    for _,d in pairs(ESP) do
        if d.hl and d.hl.Parent then
            d.hl.FillColor = Config.FillColor; d.hl.OutlineColor = Config.OutlineColor
            d.hl.FillTransparency = Config.FillTransparency; d.hl.OutlineTransparency = Config.OutlineTransparency
        end
    end
end


function Build(plr)
    if DESTROYED then return end
    if plr == LocalPlayer or ESP[plr] then return end
    local ch = plr.Character; if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChild("Humanoid")
    local head = ch:FindFirstChild("Head"); if not head then return end
    local cn = {}

    -- Cleanup old
    for _,n in ipairs({"AUREN_HL","AUREN_BB","NBG","NBG_B"}) do
        local old = ch:FindFirstChild(n); if old then old:Destroy() end
    end

    -- Highlight
    local hl = nil
    if Config.Highlight then
        hl = Instance.new("Highlight"); hl.Name = "AUREN_HL"; hl.Adornee = ch
        hl.FillColor = Config.FillColor; hl.OutlineColor = Config.OutlineColor
        hl.FillTransparency = Config.FillTransparency; hl.OutlineTransparency = Config.OutlineTransparency
        hl.DepthMode = Config.DepthMode and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        hl.Parent = ch
    end

    -- Billboard: Distance ABOVE health bar
    local bb, heart, hpFl, dLbl = nil, nil, nil, nil
    if Config.ShowHealth or Config.ShowDistance then
        bb = Instance.new("BillboardGui"); bb.Name = "AUREN_BB"; bb.Adornee = head; bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0,160,0,36); bb.StudsOffset = Vector3.new(0,2.5,0); bb.Parent = ch
        local bL = Instance.new("UIListLayout"); bL.HorizontalAlignment = Enum.HorizontalAlignment.Center
        bL.SortOrder = Enum.SortOrder.LayoutOrder; bL.Parent = bb

        -- Distance FIRST (above health bar) - bright green with black stroke
        if Config.ShowDistance then
            dLbl = Instance.new("TextLabel"); dLbl.Size = UDim2.new(1,0,0,14); dLbl.BackgroundTransparency = 1
            dLbl.Text = "[0m]"; dLbl.TextColor3 = Color3.fromRGB(0,255,120); dLbl.TextSize = 12
            dLbl.Font = Enum.Font.GothamBold; dLbl.TextStrokeTransparency = 0
            dLbl.TextStrokeColor3 = Color3.new(0,0,0); dLbl.LayoutOrder = 1; dLbl.Parent = bb
        end

        -- Health SECOND (below distance)
        if Config.ShowHealth and hum then
            local hr = Instance.new("Frame"); hr.Size = UDim2.new(0.85,0,0,12); hr.BackgroundTransparency = 1
            hr.LayoutOrder = 2; hr.Parent = bb
            heart = Instance.new("TextLabel"); heart.Size = UDim2.new(0,12,1,0); heart.BackgroundTransparency = 1
            heart.Text = "\226\153\165"; heart.TextSize = 11; heart.Font = Enum.Font.GothamBold; heart.Parent = hr
            local hpB = Instance.new("Frame"); hpB.Size = UDim2.new(1,-16,0,6); hpB.Position = UDim2.new(0,15,0.5,-3)
            hpB.BackgroundColor3 = Color3.fromRGB(10,10,10); hpB.BorderSizePixel = 0; hpB.Parent = hr; Crn(hpB,3)
            Stk(hpB, Color3.fromRGB(40,60,40), 1, 0.5)
            local rat = hum.Health / hum.MaxHealth; local hpc = HPCol(rat)
            hpFl = Instance.new("Frame"); hpFl.Size = UDim2.new(rat,0,1,0); hpFl.BackgroundColor3 = hpc
            hpFl.BorderSizePixel = 0; hpFl.Parent = hpB; Crn(hpFl,3)
            local gr = Instance.new("UIGradient"); gr.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(180,180,180))
            }); gr.Rotation = 90; gr.Parent = hpFl
            heart.TextColor3 = hpc
            table.insert(cn, hum.HealthChanged:Connect(function()
                if DESTROYED then return end
                if not hpFl or not hpFl.Parent then return end
                local r2 = hum.Health / hum.MaxHealth; local c2 = HPCol(r2)
                hpFl.Size = UDim2.new(r2,0,1,0); hpFl.BackgroundColor3 = c2
                if heart and heart.Parent then heart.TextColor3 = c2 end
            end))
        end
    end

    ESP[plr] = {hl=hl, bb=bb, cn=cn, dLbl=dLbl, hrp=hrp, ch=ch, heart=heart, hpFl=hpFl}
end

function Clear(plr)
    local d = ESP[plr]; if not d then return end
    if d.hl and d.hl.Parent then d.hl:Destroy() end
    if d.bb and d.bb.Parent then d.bb:Destroy() end
    if d.cn then for _,c in ipairs(d.cn) do c:Disconnect() end end
    ESP[plr] = nil
end

function Rebuild()
    if DESTROYED then return end
    for _,p in ipairs(Players:GetPlayers()) do Clear(p); Build(p) end
end

_G.AUREN_ESP = ESP

-- ==================== ANTI-KB ENGINE (Event-Driven — ZERO FPS cost) ====================
-- Pure event-driven: NO per-frame loops, NO polling, NO velocity clamping.
-- Only fires code when the server actually adds a force or changes humanoid state.
--
-- Strategy:
--   1. DescendantAdded: destroy knockback forces instantly (event fires only when force appears)
--   2. StateChanged: prevent ragdoll/falling (event fires only on state change)
--   → Zero CPU cost when nothing is happening = zero FPS impact

local FORCE_CLASSES = {
    BodyVelocity = true, BodyForce = true, BodyThrust = true,
    BodyAngularVelocity = true, LinearVelocity = true,
    VectorForce = true, BodyPosition = true, BodyGyro = true,
    LineForce = true, AlignPosition = true, AlignOrientation = true,
}

local childAddedConns = {}

local function isToolForce(obj)
    local ancestor = obj.Parent
    while ancestor do
        if ancestor:IsA("Tool") or ancestor:IsA("BackpackItem") then return true end
        ancestor = ancestor.Parent
    end
    return false
end

-- Wire event-driven anti-KB on character
local function wireChildAdded(ch)
    for _, c in ipairs(childAddedConns) do pcall(c.Disconnect, c) end
    childAddedConns = {}

    -- 1) DescendantAdded: destroy knockback forces instantly
    childAddedConns[#childAddedConns + 1] = ch.DescendantAdded:Connect(function(obj)
        if not FORCE_CLASSES[obj.ClassName] then return end
        if obj:GetAttribute("AUREN_SAFE") then return end
        if isToolForce(obj) then return end
        pcall(obj.Destroy, obj)
        -- Only zero velocity + fix state when NOT flying (prevents jitter/drift)
        if flyActive then return end
        pcall(function()
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vy = hrp.AssemblyLinearVelocity.Y
                hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(vy, 0), 0)
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end)

    -- 2) StateChanged: prevent ragdoll/falling states (event-driven, not polled)
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then
        childAddedConns[#childAddedConns + 1] = hum.StateChanged:Connect(function(_, newState)
            if flyActive then return end
            if newState == Enum.HumanoidStateType.Ragdoll
            or newState == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        -- Disable ragdoll states once
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end

    -- Clean existing forces once on enable
    for _, obj in ipairs(ch:GetDescendants()) do
        if FORCE_CLASSES[obj.ClassName] and not obj:GetAttribute("AUREN_SAFE") and not isToolForce(obj) then
            pcall(obj.Destroy, obj)
        end
    end
end

-- Disconnect all anti-KB listeners
local function unwireChildAdded()
    for _, c in ipairs(childAddedConns) do pcall(c.Disconnect, c) end
    childAddedConns = {}
end

-- Re-wire on respawn if enabled
local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(ch)
    task.wait()
    if DESTROYED then return end
    if Config.Noclip then wireChildAdded(ch) end
end)
table.insert(allConns, charAddedConn)

-- ==================== GHOST NOCLIP ====================
do
-- Ghost only: pass through walls but stay on floor (can walk up/down stairs normally)
-- Ghost + Fly: pass through EVERYTHING including floor (full freedom)
local ghostRayParams = RaycastParams.new()
ghostRayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Phase 1: Stepped (before physics) - disable all collision on our character
local ghostSteppedConn = RunService.Stepped:Connect(function()
    if DESTROYED or not Config.GhostNoclip then return end
    local ch = LocalPlayer.Character; if not ch then return end
    for _, part in ipairs(ch:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    -- Ghost+Fly: keep HRP anchored + zero velocity on ALL parts
    if flyActive then
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.new(0, 0, 0)
                pcall(function() part.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                pcall(function() part.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
            end
        end
        -- Re-enforce anchor every frame (game might un-anchor)
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = true end
        -- Kill humanoid movement input
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
    end
end)
table.insert(allConns, ghostSteppedConn)

-- Phase 2: Heartbeat (after physics) - floor protection ONLY when not flying
local ghostHeartbeatConn = RunService.Heartbeat:Connect(function()
    if DESTROYED or not Config.GhostNoclip then return end
    -- Ghost + Fly = full noclip, pass through EVERYTHING, no floor protection
    if flyActive then return end

    local ch = LocalPlayer.Character; if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end

    -- Raycast straight down from current position to find floor
    ghostRayParams.FilterDescendantsInstances = {ch}
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), ghostRayParams)

    if result then
        local floorY = result.Position.Y
        local hipHeight = 3
        local minY = floorY + hipHeight
        -- Only prevent falling THROUGH the floor (not prevent walking down)
        -- Check: are we below the floor AND moving downward?
        if hrp.Position.Y < minY and hrp.Velocity.Y < -1 then
            hrp.CFrame = CFrame.new(hrp.Position.X, minY, hrp.Position.Z) * hrp.CFrame.Rotation
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
        end
    end
end)
table.insert(allConns, ghostHeartbeatConn)
end

-- ==================== SPEED & JUMP ENFORCEMENT ====================
do
-- Continuously apply Speed/JumpPower so server resets don't override them.
local speedJumpConn = RunService.Heartbeat:Connect(function()
    if DESTROYED then return end
    -- Skip when Ghost+Fly is active (WalkSpeed must stay 0 to prevent body movement)
    if ghostFlyFrozen then return end
    local ch = LocalPlayer.Character; if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if Config.Speed ~= 16 then hum.WalkSpeed = Config.Speed end
    if Config.JumpPower ~= 50 then hum.JumpPower = Config.JumpPower end
end)
table.insert(allConns, speedJumpConn)
end

-- ==================== FLY ====================
local flyBodyVel = nil
local flyBodyGyro = nil
local flyActive = false

local ghostFlyFrozen = false
local savedWalkSpeed = 16

local function freezeCharacter(ch, shouldAnchor)
    if ghostFlyFrozen then return end
    ghostFlyFrozen = true
    -- ANCHOR HRP only if requested (Ghost+Fly needs anchor, normal fly does NOT)
    if shouldAnchor ~= false then
        pcall(function()
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = true end
        end)
    end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then
        savedWalkSpeed = hum.WalkSpeed
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.AutoRotate = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
    end
    -- Disable Animate script
    pcall(function()
        local animScript = ch:FindFirstChild("Animate")
        if animScript then animScript.Disabled = true end
    end)
    -- Stop all playing animations
    pcall(function()
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end
        end
    end)
end

local function unfreezeCharacter(ch)
    if not ghostFlyFrozen then return end
    ghostFlyFrozen = false
    -- UN-ANCHOR HRP
    pcall(function()
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false end
    end)
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = savedWalkSpeed
        hum.JumpPower = Config.JumpPower
        hum.AutoRotate = true
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    -- Re-enable Animate script
    pcall(function()
        local animScript = ch:FindFirstChild("Animate")
        if animScript then animScript.Disabled = false end
    end)
end

local function startFly()
    if flyActive then return end
    local ch = LocalPlayer.Character; if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    hrp.Anchored = false
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Name = "AUREN_FLY_VEL"
    flyBodyVel:SetAttribute("AUREN_SAFE", true)
    flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVel.Velocity = Vector3.new(0, 0, 0)
    flyBodyVel.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "AUREN_FLY_GYRO"
    flyBodyGyro:SetAttribute("AUREN_SAFE", true)
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.D = 200
    flyBodyGyro.P = 40000
    flyBodyGyro.Parent = hrp

    flyActive = true

    -- Both fly modes: anchor HRP + CFrame movement (rigid, no jitter, no drift)
    hrp.Velocity = Vector3.new(0, 0, 0)
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
    pcall(function() hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
    freezeCharacter(ch, true) -- anchor=true for all fly modes
end

local function stopFly()
    -- Unfreeze character before stopping
    pcall(function()
        local ch = LocalPlayer.Character
        if ch then unfreezeCharacter(ch) end
    end)
    flyActive = false
    pcall(function() if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end end)
    pcall(function() if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end end)
    pcall(function()
        local ch = LocalPlayer.Character
        if ch then
            -- Cleanup fly state
            local hum = ch:FindFirstChildOfClass("Humanoid")
            -- Clean up any leftover fly instances
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, c in ipairs(hrp:GetChildren()) do
                    if c.Name == "AUREN_FLY_VEL" or c.Name == "AUREN_FLY_GYRO" then c:Destroy() end
                end
            end
        end
    end)
end

local flyConn = RunService.RenderStepped:Connect(function()
    if DESTROYED then return end
    -- Start/stop fly based on Config
    if Config.Fly and not flyActive then
        startFly()
    elseif not Config.Fly and flyActive then
        stopFly()
    end
    -- Update fly movement
    if flyActive then
        local ch = LocalPlayer.Character; if not ch then stopFly(); return end
        local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then stopFly(); return end

        local cam = Camera.CFrame
        local dir = Vector3.new(0, 0, 0)
        local hum = ch:FindFirstChild("Humanoid")

        -- Keyboard (PC): WASD + Space/Shift
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

        -- Thumbstick (Mobile/Tablet): read MoveDirection → camera-relative 3D direction
        if hum and hum.MoveDirection.Magnitude > 0.1 then
            local md = hum.MoveDirection.Unit
            local flatLook = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z)
            if flatLook.Magnitude > 0.001 then flatLook = flatLook.Unit end
            local flatRight = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z)
            if flatRight.Magnitude > 0.001 then flatRight = flatRight.Unit end
            local fwd = md:Dot(flatLook)
            local rgt = md:Dot(flatRight)
            dir = dir + cam.LookVector * fwd + cam.RightVector * rgt
        end
        -- Jump button = fly up (works on mobile jump button too)
        if hum and hum.Jump then
            dir = dir + Vector3.new(0, 1, 0)
            hum.Jump = false
        end

        if dir.Magnitude > 0 then
            dir = dir.Unit * Config.FlySpeed
        end

        -- Ensure character stays frozen + anchored
        if not ghostFlyFrozen then freezeCharacter(ch, true) end

        local dt = 1/60
        if dir.Magnitude > 0 then
            local delta = dir * dt

            -- Normal fly: raycast collision check (don't go through walls)
            if not Config.GhostNoclip then
                local flyRayParams = RaycastParams.new()
                flyRayParams.FilterDescendantsInstances = {ch}
                flyRayParams.FilterType = Enum.RaycastFilterType.Exclude
                flyRayParams.RespectCanCollide = true  -- ignore CanCollide=false parts (doors, triggers)
                local margin = 3
                local result = workspace:Raycast(hrp.Position, delta.Unit * (delta.Magnitude + margin), flyRayParams)
                if result then
                    local maxDist = math.max((result.Position - hrp.Position).Magnitude - margin, 0)
                    if maxDist < 0.01 then
                        delta = Vector3.new(0, 0, 0)
                    else
                        delta = delta.Unit * math.min(delta.Magnitude, maxDist)
                    end
                end
            end
            -- Ghost fly: no collision check (pass through everything)

            if delta.Magnitude > 0.001 then
                hrp.CFrame = CFrame.new(hrp.Position + delta) * cam.Rotation
                Camera.CFrame = Camera.CFrame + delta
            else
                hrp.CFrame = CFrame.new(hrp.Position) * cam.Rotation
            end
        else
            -- Not moving, just lock rotation to camera
            hrp.CFrame = CFrame.new(hrp.Position) * cam.Rotation
        end

        -- Kill ALL physics (prevent any drift)
        hrp.Velocity = Vector3.new(0, 0, 0)
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        pcall(function() hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end)
        if flyBodyVel then flyBodyVel.Velocity = Vector3.new(0, 0, 0) end
        if flyBodyGyro then flyBodyGyro.CFrame = cam end
    end
end)
table.insert(allConns, flyConn)

-- ==================== SPAM SLAP ALL ====================
local slapThread = nil

local function startSpamSlap()
    slapThread = task.spawn(function()
        while Config.SpamSlapAll and not DESTROYED do
            local slapTool = findBestSlap()
            if slapTool then
                local ev = slapTool:FindFirstChild("Event")
                if ev then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if not Config.SpamSlapAll then break end
                        local ch = plr ~= LocalPlayer and plr.Character
                        if ch then
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                pcall(function()
                                    local p = Config.SlapPower
                                    ev:FireServer("slash", ch, Vector3.new(
                                        (math.random() * 10 - 5) * p,
                                        (math.random() * 0.001 - 0.0005) * p,
                                        (math.random() * 10 - 5) * p
                                    ))
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(Config.SpamSlapDelay)
        end
        slapThread = nil
    end)
end

local function stopSpamSlap()
    if slapThread then
        task.cancel(slapThread)
        slapThread = nil
    end
end

local slapWatchConn = RunService.Stepped:Connect(function()
    if DESTROYED then stopSpamSlap(); return end
    if Config.SpamSlapAll and not slapThread then
        startSpamSlap()
    elseif not Config.SpamSlapAll and slapThread then
        stopSpamSlap()
    end
end)
table.insert(allConns, slapWatchConn)

-- ==================== TARGET SLAP ====================
local targetSlapThread = nil

local function startTargetSlap()
    targetSlapThread = task.spawn(function()
        while Config.TargetSlapAuto and not DESTROYED do
            local plr = Config.TargetSlapPlr
            if plr and plr.Parent and plr.Character then
                local slapTool = findBestSlap()
                if slapTool then
                    local ev = slapTool:FindFirstChild("Event")
                    if ev then
                        pcall(function()
                            local p = Config.SlapPower
                            ev:FireServer("slash", plr.Character, Vector3.new(
                                (math.random() * 10 - 5) * p,
                                (math.random() * 0.001 - 0.0005) * p,
                                (math.random() * 10 - 5) * p
                            ))
                        end)
                    end
                end
            end
            task.wait(Config.SpamSlapDelay)
        end
        targetSlapThread = nil
    end)
end

local function stopTargetSlap()
    if targetSlapThread then
        task.cancel(targetSlapThread)
        targetSlapThread = nil
    end
end

local targetSlapConn = RunService.Stepped:Connect(function()
    if DESTROYED then stopTargetSlap(); return end
    if Config.TargetSlapAuto and Config.TargetSlapPlr and not targetSlapThread then
        startTargetSlap()
    elseif (not Config.TargetSlapAuto or not Config.TargetSlapPlr) and targetSlapThread then
        stopTargetSlap()
    end
end)
table.insert(allConns, targetSlapConn)

-- ==================== FLING SPAM ====================
do -- Fling spam scope
local flingThread = nil

local function startFlingSpam()
    flingThread = task.spawn(function()
        while Config.FlingSpam and not DESTROYED do
            local plr = Config.FlingPlr
            if plr and plr.Parent and plr.Character then
                local slapTool = findBestSlap()
                if slapTool then
                    local ev = slapTool:FindFirstChild("Event")
                    if ev then
                        pcall(function()
                ev:FireServer("slash", plr.Character, FLING_VEC)
            end)
                    end
                end
            end
            task.wait(Config.SpamSlapDelay)
        end
        flingThread = nil
    end)
end

local function stopFlingSpam()
    if flingThread then
        task.cancel(flingThread)
        flingThread = nil
    end
end

local flingWatchConn = RunService.Stepped:Connect(function()
    if DESTROYED then stopFlingSpam(); return end
    if Config.FlingSpam and Config.FlingPlr and not flingThread then
        startFlingSpam()
    elseif (not Config.FlingSpam or not Config.FlingPlr) and flingThread then
        stopFlingSpam()
    end
end)
table.insert(allConns, flingWatchConn)
end -- end Fling spam scope

-- ==================== SPAM FLING ALL ====================
do
local flingAllThread = nil

local function startFlingAll()
    flingAllThread = task.spawn(function()
        while Config.SpamFlingAll and not DESTROYED do
            local slapTool = findBestSlap()
            if slapTool then
                local ev = slapTool:FindFirstChild("Event")
                if ev then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if not Config.SpamFlingAll then break end
                        local ch = plr ~= LocalPlayer and plr.Character
                        if ch then
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                pcall(function()
                                    ev:FireServer("slash", ch, FLING_VEC)
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(Config.SpamSlapDelay)
        end
        flingAllThread = nil
    end)
end

local function stopFlingAll()
    if flingAllThread then
        task.cancel(flingAllThread)
        flingAllThread = nil
    end
end

local flingAllWatchConn = RunService.Stepped:Connect(function()
    if DESTROYED then stopFlingAll(); return end
    if Config.SpamFlingAll and not flingAllThread then
        startFlingAll()
    elseif not Config.SpamFlingAll and flingAllThread then
        stopFlingAll()
    end
end)
table.insert(allConns, flingAllWatchConn)
end

-- ==================== RENDER LOOP ====================
do
local renderConn = RunService.RenderStepped:Connect(function()
    if DESTROYED then return end

    local vp = Camera.ViewportSize

    -- Auto-build for new players
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not ESP[plr] and plr.Character and plr.Character:FindFirstChild("Head") then
            Build(plr)
        end
    end

    local myC = LocalPlayer.Character
    local myH = myC and myC:FindFirstChild("HumanoidRootPart")

    for plr, d in pairs(ESP) do
        local ch = d.ch
        if not ch or not ch.Parent then Clear(plr); continue end

        local dist = 0
        if myH and d.hrp and d.hrp.Parent then
            dist = (myH.Position - d.hrp.Position).Magnitude
        end
        local hidden = Config.MaxDistance > 0 and dist > Config.MaxDistance

        if d.hl then d.hl.Enabled = not hidden end
        if d.bb then d.bb.Enabled = not hidden end

        if hidden then continue end

        -- Update distance
        if d.dLbl and d.dLbl.Parent then d.dLbl.Text = "[" .. math.floor(dist) .. "m]" end

    end
end)
_G.AUREN_RENDER = renderConn
table.insert(allConns, renderConn)
end

-- ==================== AUTO-DETECT PLAYERS ====================
do
local paConn = Players.PlayerAdded:Connect(function(plr)
    if DESTROYED then return end
    if pcI and pcI.Parent then pcI.Text = tostring(#Players:GetPlayers()) end
    plr.CharacterAdded:Connect(function()
        if DESTROYED then return end
        task.wait(0.5); Clear(plr); Build(plr)
    end)
end)
table.insert(allConns, paConn)

local prConn = Players.PlayerRemoving:Connect(function(plr)
    Clear(plr)
    task.delay(0.1, function()
        if pcI and pcI.Parent then pcI.Text = tostring(#Players:GetPlayers()) end
    end)
end)
table.insert(allConns, prConn)

for _,plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        local caConn = plr.CharacterAdded:Connect(function()
            if DESTROYED then return end
            task.wait(0.5); Clear(plr); Build(plr)
        end)
        table.insert(allConns, caConn)
    end
end

local lcConn = LocalPlayer.CharacterAdded:Connect(function()
    if DESTROYED then return end
    -- Reset fly on respawn (old BodyVelocity/BodyGyro are gone with old character)
    flyActive = false; flyBodyVel = nil; flyBodyGyro = nil
    -- Character respawned
    task.wait(1); Rebuild()
    -- Re-enable fly if still toggled on
    if Config.Fly then startFly() end
end)
table.insert(allConns, lcConn)

_G.AUREN_CONNS = allConns
end

-- ==================== AUTO RESPONSIVE (screen size change) ====================
do
local vpConn = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if DESTROYED then return end
    UIScaleObj.Scale = getAutoScale() * Config.UIScale
end)
table.insert(allConns, vpConn)
end

-- ==================== HEADER BUTTONS ====================
do
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        -- Close any open dropdowns before minimizing
        if tsListOpen then closePlayerList() end
        pcall(function() if _G.AUREN_CLOSE_FLING_LIST then _G.AUREN_CLOSE_FLING_LIST() end end)
        if langDropOpen then langDropOpen = false; LangDrop.Visible = false; Tw(LangArrow,{Rotation=0},0.1) end
        Content.Visible = false; AL.Visible = false; HdrBtm.Visible = false
        Tw(Main, {Size = UDim2.new(0, BASE_W, 0, 48)}, 0.25, Enum.EasingStyle.Quint)
    else
        Tw(Main, {Size = UDim2.new(0, BASE_W, 0, BASE_H)}, 0.25, Enum.EasingStyle.Quint)
        task.delay(0.2, function() Content.Visible = true; AL.Visible = true; HdrBtm.Visible = true end)
    end
end)

ClsBtn.MouseButton1Click:Connect(function()
    DESTROYED = true
    Config.SpamSlapAll = false
    Config.TargetSlapAuto = false
    Config.FlingSpam = false
    Config.SpamFlingAll = false
    Config.Fly = false
    stopSpamSlap()
    stopTargetSlap()
    stopFly()

    -- Reset speed/jump to defaults
    pcall(function()
        local ch = LocalPlayer.Character
        if ch then
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
        end
    end)

    -- Clear all ESP
    for _,p in ipairs(Players:GetPlayers()) do Clear(p) end

    -- Disconnect ALL connections
    for _,c in ipairs(allConns) do pcall(function() c:Disconnect() end) end

    -- Clean ChildAdded connections
    for _, c in ipairs(childAddedConns) do pcall(c.Disconnect, c) end

    -- Clear globals
    _G.AUREN_ESP = nil; _G.AUREN_RENDER = nil; _G.AUREN_ANTIKB = nil
    _G.AUREN_HB = nil; _G.AUREN_CONNS = nil

    -- Close animation: pure fade out (no movement, no scale, stable)
    local fadeTime = 0.3
    Tw(Main,{BackgroundTransparency=1},fadeTime,Enum.EasingStyle.Sine)
    for _,child in ipairs(Main:GetDescendants()) do
        pcall(function()
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                Tw(child,{TextTransparency=1,BackgroundTransparency=1},fadeTime)
            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                Tw(child,{ImageTransparency=1,BackgroundTransparency=1},fadeTime)
            elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
                Tw(child,{BackgroundTransparency=1},fadeTime)
            end
            if child:IsA("UIStroke") then
                Tw(child,{Transparency=1},fadeTime)
            end
        end)
    end
    task.wait(fadeTime + 0.05)
    Gui:Destroy()
end)
end

-- ==================== FPS COUNTER ====================
do
local fc = 0; local ft = tick()
local hbConn = RunService.Heartbeat:Connect(function()
    if DESTROYED then return end
    fc = fc + 1
    if tick() - ft >= 1 then
        if fpI and fpI.Parent then fpI.Text = tostring(fc) end
        fc = 0; ft = tick()
    end
end)
_G.AUREN_HB = hbConn
table.insert(allConns, hbConn)
end

-- ==================== SHOW MAIN UI (after everything is built) ====================
do
Main.Visible = true; Main.BackgroundTransparency = 1
Main.Size = UDim2.new(0, BASE_W - 20, 0, BASE_H - 20)
Main.Position = UDim2.new(0.5, 0, 0, 4)
Tw(Main, {BackgroundTransparency=0, Size=UDim2.new(0,BASE_W,0,BASE_H)}, 0.6, Enum.EasingStyle.Quint)

print("[Auren MAX] Green-Black Luxury | All features OFF by default. Toggle to enable. Auto-responsive.")
end

-- (Overlord removed)
