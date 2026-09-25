--[[
    ================================================================================
    PiLib - HOSTED LIBRARY (HttpGet version)
    Upload this file to your hosting provider (e.g., GitHub raw), then set
    its URL in PiLib_HttpGet.lua. This returns the PiLib table for loadstring.

    Usage:
        local PiLib = loadstring(game:HttpGet("URL_OF_THIS_FILE", true))()
    ================================================================================
--]]

local PiLib = (function()
--[[
    ================================================================================
    PiLib - Hybrid Roblox UI Library (Fluent x Redz V5 Remake)
    Architected for: Clean Flat Minimalist, Adaptive Motion, Unified Flags & SaveManager, Dual Minimizer
    ================================================================================
--]]

local PiLib = {
    Version = "1.0.0",
    Title = "PiLib",
    Options = {},
    Flags = {},
    Signals = {},
    ThemeObjects = {},
    CurrentTheme = "Dark",
    Window = nil,
    Loaded = false
}

-- [SECTION 1] SERVICES & SAFE FALLBACKS
local cloneref = cloneref or function(...) return ... end
local Services = setmetatable({}, {
    __index = function(self, serviceName)
        local success, service = pcall(game.GetService, game, serviceName)
        if success and service then
            local ref = cloneref(service)
            rawset(self, serviceName, ref)
            return ref
        end
        return nil
    end
})

local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local RunService = Services.RunService
local HttpService = Services.HttpService
local Players = Services.Players
local CoreGui = Services.CoreGui
local Workspace = Services.Workspace

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse() or nil
local CurrentCamera = Workspace.CurrentCamera

-- File System Safe Fallbacks (Compatible across Studio and all Executors)
local isfile = isfile or function(path) return false end
local isfolder = isfolder or function(path) return false end
local makefolder = makefolder or function(path) end
local writefile = writefile or function(path, content) end
local readfile = readfile or function(path) return "" end
local listfiles = listfiles or function(path) return {} end
local delfile = delfile or deletefile or function(path) end
local delfolder = delfolder or deletefolder or function(path) end

-- Device Detection
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ScreenGui Parent (CoreGui with fallbacks)
local function GetGuiParent()
    local gethui = gethui or function()
        if RunService:IsStudio() then
            return LocalPlayer:WaitForChild("PlayerGui")
        end
        return CoreGui
    end
    local target = gethui()
    local protectgui = protectgui or (syn and syn.protect_gui) or function() end
    return target, protectgui
end

-- [SECTION 2] THEMES (Clean Flat Minimalist)
PiLib.Themes = {
    Dark = {
        Name = "Dark",
        Background = Color3.fromRGB(20, 20, 23),
        Header = Color3.fromRGB(16, 16, 18),
        Sidebar = Color3.fromRGB(16, 16, 18),
        Card = Color3.fromRGB(28, 28, 33),
        CardHover = Color3.fromRGB(36, 36, 44),
        CardActive = Color3.fromRGB(42, 42, 52),
        Border = Color3.fromRGB(44, 44, 52),
        BorderFocus = Color3.fromRGB(70, 70, 85),
        Accent = Color3.fromRGB(96, 205, 255),
        AccentDim = Color3.fromRGB(60, 140, 180),
        Text = Color3.fromRGB(245, 245, 245),
        SubText = Color3.fromRGB(155, 155, 165),
        Divider = Color3.fromRGB(34, 34, 40),
        Dialog = Color3.fromRGB(24, 24, 28),
        DialogButton = Color3.fromRGB(32, 32, 38),
        ToggleSlider = Color3.fromRGB(120, 120, 130),
        ToggleTrack = Color3.fromRGB(36, 36, 44),
        ToggleActive = Color3.fromRGB(96, 205, 255),
        FloatingButton = Color3.fromRGB(22, 22, 26)
    },
    Darker = {
        Name = "Darker",
        Background = Color3.fromRGB(12, 12, 14),
        Header = Color3.fromRGB(8, 8, 10),
        Sidebar = Color3.fromRGB(8, 8, 10),
        Card = Color3.fromRGB(18, 18, 22),
        CardHover = Color3.fromRGB(26, 26, 32),
        CardActive = Color3.fromRGB(32, 32, 40),
        Border = Color3.fromRGB(30, 30, 38),
        BorderFocus = Color3.fromRGB(50, 50, 65),
        Accent = Color3.fromRGB(0, 162, 255),
        AccentDim = Color3.fromRGB(0, 110, 180),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(130, 130, 140),
        Divider = Color3.fromRGB(24, 24, 30),
        Dialog = Color3.fromRGB(16, 16, 20),
        DialogButton = Color3.fromRGB(24, 24, 30),
        ToggleSlider = Color3.fromRGB(100, 100, 110),
        ToggleTrack = Color3.fromRGB(26, 26, 32),
        ToggleActive = Color3.fromRGB(0, 162, 255),
        FloatingButton = Color3.fromRGB(14, 14, 16)
    },
    Amethyst = {
        Name = "Amethyst",
        Background = Color3.fromRGB(18, 16, 24),
        Header = Color3.fromRGB(14, 12, 19),
        Sidebar = Color3.fromRGB(14, 12, 19),
        Card = Color3.fromRGB(27, 24, 36),
        CardHover = Color3.fromRGB(36, 32, 48),
        CardActive = Color3.fromRGB(44, 40, 60),
        Border = Color3.fromRGB(48, 42, 64),
        BorderFocus = Color3.fromRGB(75, 65, 100),
        Accent = Color3.fromRGB(175, 105, 255),
        AccentDim = Color3.fromRGB(120, 70, 180),
        Text = Color3.fromRGB(245, 242, 250),
        SubText = Color3.fromRGB(160, 150, 175),
        Divider = Color3.fromRGB(32, 28, 42),
        Dialog = Color3.fromRGB(22, 19, 30),
        DialogButton = Color3.fromRGB(32, 28, 44),
        ToggleSlider = Color3.fromRGB(130, 120, 145),
        ToggleTrack = Color3.fromRGB(34, 30, 46),
        ToggleActive = Color3.fromRGB(175, 105, 255),
        FloatingButton = Color3.fromRGB(20, 18, 26)
    },
    Emerald = {
        Name = "Emerald",
        Background = Color3.fromRGB(16, 22, 18),
        Header = Color3.fromRGB(12, 17, 14),
        Sidebar = Color3.fromRGB(12, 17, 14),
        Card = Color3.fromRGB(23, 32, 26),
        CardHover = Color3.fromRGB(30, 42, 34),
        CardActive = Color3.fromRGB(38, 52, 42),
        Border = Color3.fromRGB(40, 56, 45),
        BorderFocus = Color3.fromRGB(60, 85, 68),
        Accent = Color3.fromRGB(0, 230, 135),
        AccentDim = Color3.fromRGB(0, 160, 95),
        Text = Color3.fromRGB(245, 250, 245),
        SubText = Color3.fromRGB(150, 175, 160),
        Divider = Color3.fromRGB(28, 38, 31),
        Dialog = Color3.fromRGB(19, 27, 21),
        DialogButton = Color3.fromRGB(27, 38, 30),
        ToggleSlider = Color3.fromRGB(115, 140, 125),
        ToggleTrack = Color3.fromRGB(28, 40, 32),
        ToggleActive = Color3.fromRGB(0, 230, 135),
        FloatingButton = Color3.fromRGB(16, 22, 18)
    },
    Rose = {
        Name = "Rose",
        Background = Color3.fromRGB(24, 16, 20),
        Header = Color3.fromRGB(19, 12, 16),
        Sidebar = Color3.fromRGB(19, 12, 16),
        Card = Color3.fromRGB(36, 24, 30),
        CardHover = Color3.fromRGB(48, 32, 40),
        CardActive = Color3.fromRGB(58, 40, 50),
        Border = Color3.fromRGB(60, 40, 50),
        BorderFocus = Color3.fromRGB(90, 60, 75),
        Accent = Color3.fromRGB(255, 95, 140),
        AccentDim = Color3.fromRGB(180, 60, 95),
        Text = Color3.fromRGB(250, 242, 245),
        SubText = Color3.fromRGB(175, 150, 160),
        Divider = Color3.fromRGB(40, 28, 34),
        Dialog = Color3.fromRGB(28, 19, 24),
        DialogButton = Color3.fromRGB(40, 28, 36),
        ToggleSlider = Color3.fromRGB(145, 115, 125),
        ToggleTrack = Color3.fromRGB(42, 30, 38),
        ToggleActive = Color3.fromRGB(255, 95, 140),
        FloatingButton = Color3.fromRGB(24, 16, 20)
    }
}

-- [SECTION 3] ADAPTIVE ANIMATION & CREATOR HELPER
local Creator = {}

function Creator.GetThemeProperty(prop)
    local theme = PiLib.Themes[PiLib.CurrentTheme] or PiLib.Themes.Dark
    return theme[prop] or PiLib.Themes.Dark[prop]
end

function Creator.AddThemeObject(instance, propTable)
    table.insert(PiLib.ThemeObjects, { Instance = instance, Properties = propTable })
    for propName, themeKey in pairs(propTable) do
        local val = Creator.GetThemeProperty(themeKey)
        if val ~= nil then
            instance[propName] = val
        end
    end
    return instance
end

function PiLib:SetTheme(themeName)
    if not self.Themes[themeName] then return end
    self.CurrentTheme = themeName
    for _, item in ipairs(self.ThemeObjects) do
        local inst = item.Instance
        if inst and inst.Parent then
            for propName, themeKey in pairs(item.Properties) do
                local val = Creator.GetThemeProperty(themeKey)
                if val ~= nil then
                    inst[propName] = val
                end
            end
        end
    end
end

function PiLib:GetThemes()
    local list = {}
    for name, _ in pairs(self.Themes) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

function Creator.AdaptiveTween(instance, targetProps, duration, easingStyle, easingDir)
    duration = duration or 0.2
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDir = easingDir or Enum.EasingDirection.Out

    -- On Mobile / Touch, use fast quad tweens to minimize rendering overhead
    if isTouch then
        easingStyle = Enum.EasingStyle.Quad
    end

    local tween = TweenService:Create(instance, TweenInfo.new(duration, easingStyle, easingDir), targetProps)
    tween:Play()
    return tween
end

function Creator.New(className, props, children)
    local inst = Instance.new(className)
    local themeTag = nil
    
    for k, v in pairs(props or {}) do
        if k == "ThemeTag" then
            themeTag = v
        else
            inst[k] = v
        end
    end

    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end

    if themeTag then
        Creator.AddThemeObject(inst, themeTag)
    end

    return inst
end

function Creator.AddSignal(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(PiLib.Signals, connection)
    return connection
end

-- [SECTION 4] EMBEDDED ICONS DATABASE
local IconsMap = {
    accessibility = 10709751939,
    activity = 10709752035,
    airvent = 10709752131,
    airplay = 10709752254,
    alarmcheck = 10709752405,
    alarmclock = 10709752630,
    alarmclockoff = 10709752508,
    alarmminus = 10709752732,
    alarmplus = 10709752825,
    album = 10709752906,
    alertcircle = 10709752996,
    alertoctagon = 10709753064,
    alerttriangle = 10709753149,
    aligncenter = 10709753570,
    aligncenterhorizontal = 10709753272,
    aligncentervertical = 10709753421,
    alignendhorizontal = 10709753692,
    alignendvertical = 10709753808,
    alignhorizontaldistributecenter = 10747779791,
    alignhorizontaldistributeend = 10747784534,
    alignhorizontaldistributestart = 10709754118,
    alignhorizontaljustifycenter = 10709754204,
    alignhorizontaljustifyend = 10709754317,
    alignhorizontaljustifystart = 10709754436,
    alignhorizontalspacearound = 10709754590,
    alignhorizontalspacebetween = 10709754749,
    alignjustify = 10709759610,
    alignleft = 10709759764,
    alignright = 10709759895,
    alignstarthorizontal = 10709760051,
    alignstartvertical = 10709760244,
    alignverticaldistributecenter = 10709760351,
    alignverticaldistributeend = 10709760434,
    alignverticaldistributestart = 10709760612,
    alignverticaljustifycenter = 10709760814,
    alignverticaljustifyend = 10709761003,
    alignverticaljustifystart = 10709761176,
    alignverticalspacearound = 10709761324,
    alignverticalspacebetween = 10709761434,
    anchor = 10709761530,
    angry = 10709761629,
    annoyed = 10709761722,
    aperture = 10709761813,
    apple = 10709761889,
    archive = 10709762233,
    archiverestore = 10709762058,
    armchair = 10709762327,
    arrowbigdown = 10747796644,
    arrowbigleft = 10709762574,
    arrowbigright = 10709762727,
    arrowbigup = 10709762879,
    arrowdown = 10709767827,
    arrowdowncircle = 10709763034,
    arrowdownleft = 10709767656,
    arrowdownright = 10709767750,
    arrowleft = 10709768114,
    arrowleftcircle = 10709767936,
    arrowleftright = 10709768019,
    arrowright = 10709768347,
    arrowrightcircle = 10709768226,
    arrowup = 10709768939,
    arrowupcircle = 10709768432,
    arrowupdown = 10709768538,
    arrowupleft = 10709768661,
    arrowupright = 10709768787,
    asterisk = 10709769095,
    atsign = 10709769286,
    award = 10709769406,
    axe = 10709769508,
    axis3d = 10709769598,
    baby = 10709769732,
    backpack = 10709769841,
    baggageclaim = 10709769935,
    banana = 10709770005,
    banknote = 10709770178,
    barchart = 10709773755,
    barchart2 = 10709770317,
    barchart3 = 10709770431,
    barchart4 = 10709770560,
    barcharthorizontal = 10709773669,
    barcode = 10747360675,
    baseline = 10709773863,
    bath = 10709773963,
    battery = 10709774640,
    batterycharging = 10709774068,
    batteryfull = 10709774206,
    batterylow = 10709774370,
    batterymedium = 10709774513,
    beaker = 10709774756,
    bed = 10709775036,
    beddouble = 10709774864,
    bedsingle = 10709774968,
    beer = 10709775167,
    bell = 10709775704,
    bellminus = 10709775241,
    belloff = 10709775320,
    bellplus = 10709775448,
    bellring = 10709775560,
    bike = 10709775894,
    binary = 10709776050,
    bitcoin = 10709776126,
    bluetooth = 10709776655,
    bluetoothconnected = 10709776240,
    bluetoothoff = 10709776344,
    bluetoothsearching = 10709776501,
    bold = 10747813908,
    bomb = 10709781460,
    bone = 10709781605,
    book = 10709781824,
    bookopen = 10709781717,
    bookmark = 10709782154,
    bookmarkminus = 10709781919,
    bookmarkplus = 10709782044,
    bot = 10709782230,
    box = 10709782497,
    boxselect = 10709782342,
    boxes = 10709782582,
    briefcase = 10709782662,
    brush = 10709782758,
    bug = 10709782845,
    building = 10709783051,
    building2 = 10709782939,
    bus = 10709783137,
    cake = 10709783217,
    calculator = 10709783311,
    calendar = 10709789505,
    calendarcheck = 10709783474,
    calendarcheck2 = 10709783392,
    calendarclock = 10709783577,
    calendardays = 10709783673,
    calendarheart = 10709783835,
    calendarminus = 10709783959,
    calendaroff = 10709788784,
    calendarplus = 10709788937,
    calendarrange = 10709789053,
    calendarsearch = 10709789200,
    calendarx = 10709789407,
    calendarx2 = 10709789329,
    camera = 10709789686,
    cameraoff = 10747822677,
    car = 10709789810,
    carrot = 10709789960,
    cast = 10709790097,
    charge = 10709790202,
    check = 10709790644,
    checkcircle = 10709790387,
    checkcircle2 = 10709790298,
    checksquare = 10709790537,
    chefhat = 10709790757,
    cherry = 10709790875,
    chevrondown = 10709790948,
    chevronfirst = 10709791015,
    chevronlast = 10709791130,
    chevronleft = 10709791281,
    chevronright = 10709791437,
    chevronup = 10709791523,
    chevronsdown = 10709796864,
    chevronsdownup = 10709791632,
    chevronsleft = 10709797151,
    chevronsleftright = 10709797006,
    chevronsright = 10709797382,
    chevronsrightleft = 10709797274,
    chevronsup = 10709797622,
    chevronsupdown = 10709797508,
    chrome = 10709797725,
    circle = 10709798174,
    circledot = 10709797837,
    circleellipsis = 10709797985,
    circleslashed = 10709798100,
    citrus = 10709798276,
    clapperboard = 10709798350,
    clipboard = 10709799288,
    clipboardcheck = 10709798443,
    clipboardcopy = 10709798574,
    clipboardedit = 10709798682,
    clipboardlist = 10709798792,
    clipboardsignature = 10709798890,
    clipboardtype = 10709798999,
    clipboardx = 10709799124,
    clock = 10709805144,
    clock1 = 10709799535,
    clock10 = 10709799718,
    clock11 = 10709799818,
    clock12 = 10709799962,
    clock2 = 10709803876,
    clock3 = 10709803989,
    clock4 = 10709804164,
    clock5 = 10709804291,
    clock6 = 10709804435,
    clock7 = 10709804599,
    clock8 = 10709804784,
    clock9 = 10709804996,
    cloud = 10709806740,
    cloudcog = 10709805262,
    clouddrizzle = 10709805371,
    cloudfog = 10709805477,
    cloudhail = 10709805596,
    cloudlightning = 10709805727,
    cloudmoon = 10709805942,
    cloudmoonrain = 10709805838,
    cloudoff = 10709806060,
    cloudrain = 10709806277,
    cloudrainwind = 10709806166,
    cloudsnow = 10709806374,
    cloudsun = 10709806631,
    cloudsunrain = 10709806475,
    cloudy = 10709806859,
    clover = 10709806995,
    code = 10709810463,
    code2 = 10709807111,
    codepen = 10709810534,
    codesandbox = 10709810676,
    coffee = 10709810814,
    cog = 10709810948,
    coins = 10709811110,
    columns = 10709811261,
    command = 10709811365,
    compass = 10709811445,
    component = 10709811595,
    conciergebell = 10709811706,
    connection = 10747361219,
    contact = 10709811834,
    contrast = 10709811939,
    cookie = 10709812067,
    copy = 10709812159,
    copyleft = 10709812251,
    copyright = 10709812311,
    cornerdownleft = 10709812396,
    cornerdownright = 10709812485,
    cornerleftdown = 10709812632,
    cornerleftup = 10709812784,
    cornerrightdown = 10709812939,
    cornerrightup = 10709813094,
    cornerupleft = 10709813185,
    cornerupright = 10709813281,
    cpu = 10709813383,
    croissant = 10709818125,
    crop = 10709818245,
    cross = 10709818399,
    crosshair = 10709818534,
    crown = 10709818626,
    cupsoda = 10709818763,
    curlybraces = 10709818847,
    currency = 10709818931,
    database = 10709818996,
    delete = 10709819059,
    diamond = 10709819149,
    dice1 = 10709819266,
    dice2 = 10709819361,
    dice3 = 10709819508,
    dice4 = 10709819670,
    dice5 = 10709819801,
    dice6 = 10709819896,
    dices = 10723343321,
    diff = 10723343416,
    disc = 10723343537,
    divide = 10723343805,
    dividecircle = 10723343636,
    dividesquare = 10723343737,
    dollarsign = 10723343958,
    download = 10723344270,
    downloadcloud = 10723344088,
    droplet = 10723344432,
    droplets = 10734883356,
    drumstick = 10723344737,
    edit = 10734883598,
    edit2 = 10723344885,
    edit3 = 10723345088,
    egg = 10723345518,
    eggfried = 10723345347,
    electricity = 10723345749,
    electricityoff = 10723345643,
    equal = 10723345990,
    equalnot = 10723345866,
    eraser = 10723346158,
    euro = 10723346372,
    expand = 10723346553,
    externallink = 10723346684,
    eye = 10723346959,
    eyeoff = 10723346871,
    factory = 10723347051,
    fan = 10723354359,
    fastforward = 10723354521,
    feather = 10723354671,
    figma = 10723354801,
    file = 10723374641,
    filearchive = 10723354921,
    fileaudio = 10723355148,
    fileaudio2 = 10723355026,
    fileaxis3d = 10723355272,
    filebadge = 10723355622,
    filebadge2 = 10723355451,
    filebarchart = 10723355887,
    filebarchart2 = 10723355746,
    filebox = 10723355989,
    filecheck = 10723356210,
    filecheck2 = 10723356100,
    fileclock = 10723356329,
    filecode = 10723356507,
    filecog = 10723356830,
    filecog2 = 10723356676,
    filediff = 10723357039,
    filedigit = 10723357151,
    filedown = 10723357322,
    fileedit = 10723357495,
    fileheart = 10723357637,
    fileimage = 10723357790,
    fileinput = 10723357933,
    filejson = 10723364435,
    filejson2 = 10723364361,
    filekey = 10723364605,
    filekey2 = 10723364515,
    filelinechart = 10723364725,
    filelock = 10723364957,
    filelock2 = 10723364861,
    fileminus = 10723365254,
    fileminus2 = 10723365086,
    fileoutput = 10723365457,
    filepiechart = 10723365598,
    fileplus = 10723365877,
    fileplus2 = 10723365766,
    filequestion = 10723365987,
    filescan = 10723366167,
    filesearch = 10723366550,
    filesearch2 = 10723366340,
    filesignature = 10723366741,
    filespreadsheet = 10723366962,
    filesymlink = 10723367098,
    fileterminal = 10723367244,
    filetext = 10723367380,
    filetype = 10723367606,
    filetype2 = 10723367509,
    fileup = 10723367734,
    filevideo = 10723373884,
    filevideo2 = 10723367834,
    filevolume = 10723374172,
    filevolume2 = 10723374030,
    filewarning = 10723374276,
    filex = 10723374544,
    filex2 = 10723374378,
    files = 10723374759,
    film = 10723374981,
    filter = 10723375128,
    fingerprint = 10723375250,
    fish = 127664059821666,
    flag = 10723375890,
    flagoff = 10723375443,
    flagtriangleleft = 10723375608,
    flagtriangleright = 10723375727,
    flame = 10723376114,
    flashlight = 10723376471,
    flashlightoff = 10723376365,
    flaskconical = 10734883986,
    flaskround = 10723376614,
    fliphorizontal = 10723376884,
    fliphorizontal2 = 10723376745,
    flipvertical = 10723377138,
    flipvertical2 = 10723377026,
    flower = 10747830374,
    flower2 = 10723377305,
    focus = 10723377537,
    folder = 10723387563,
    folderarchive = 10723384478,
    foldercheck = 10723384605,
    folderclock = 10723384731,
    folderclosed = 10723384893,
    foldercog = 10723385213,
    foldercog2 = 10723385036,
    folderdown = 10723385338,
    folderedit = 10723385445,
    folderheart = 10723385545,
    folderinput = 10723385721,
    folderkey = 10723385848,
    folderlock = 10723386005,
    folderminus = 10723386127,
    folderopen = 10723386277,
    folderoutput = 10723386386,
    folderplus = 10723386531,
    foldersearch = 10723386787,
    foldersearch2 = 10723386674,
    foldersymlink = 10723386930,
    foldertree = 10723387085,
    folderup = 10723387265,
    folderx = 10723387448,
    folders = 10723387721,
    forminput = 10723387841,
    forward = 10723388016,
    frame = 10723394389,
    framer = 10723394565,
    frown = 10723394681,
    fuel = 10723394846,
    functionsquare = 10723395041,
    gamepad = 10723395457,
    gamepad2 = 10723395215,
    gauge = 10723395708,
    gavel = 10723395896,
    gem = 10723396000,
    ghost = 10723396107,
    gift = 10723396402,
    giftcard = 10723396225,
    gitbranch = 10723396676,
    gitbranchplus = 10723396542,
    gitcommit = 10723396812,
    gitcompare = 10723396954,
    gitfork = 10723397049,
    gitmerge = 10723397165,
    gitpullrequest = 10723397431,
    gitpullrequestclosed = 10723397268,
    gitpullrequestdraft = 10734884302,
    glass = 10723397788,
    glass2 = 10723397529,
    glasswater = 10723397678,
    glasses = 10723397895,
    globe = 10723404337,
    globe2 = 10723398002,
    grab = 10723404472,
    graduationcap = 10723404691,
    grape = 10723404822,
    grid = 10723404936,
    griphorizontal = 10723405089,
    gripvertical = 10723405236,
    hammer = 10723405360,
    hand = 10723405649,
    handmetal = 10723405508,
    harddrive = 10723405749,
    hardhat = 10723405859,
    hash = 10723405975,
    haze = 10723406078,
    headphones = 10723406165,
    heart = 10723406885,
    heartcrack = 10723406299,
    hearthandshake = 10723406480,
    heartoff = 10723406662,
    heartpulse = 10723406795,
    helpcircle = 10723406988,
    hexagon = 10723407092,
    highlighter = 10723407192,
    history = 10723407335,
    home = 10723407389,
    hourglass = 10723407498,
    icecream = 10723414308,
    image = 10723415040,
    imageminus = 10723414487,
    imageoff = 10723414677,
    imageplus = 10723414827,
    import = 10723415205,
    inbox = 10723415335,
    indent = 10723415494,
    indianrupee = 10723415642,
    infinity = 10723415766,
    info = 10723415903,
    inspect = 10723416057,
    italic = 10723416195,
    japaneseyen = 10723416363,
    joystick = 10723416527,
    key = 10723416652,
    keyboard = 10723416765,
    lamp = 10723417513,
    lampceiling = 10723416922,
    lampdesk = 10723417016,
    lampfloor = 10723417131,
    lampwalldown = 10723417240,
    lampwallup = 10723417356,
    landmark = 10723417608,
    languages = 10723417703,
    laptop = 10723423881,
    laptop2 = 10723417797,
    lasso = 10723424235,
    lassoselect = 10723424058,
    laugh = 10723424372,
    layers = 10723424505,
    layout = 10723425376,
    layoutdashboard = 10723424646,
    layoutgrid = 10723424838,
    layoutlist = 10723424963,
    layouttemplate = 10723425187,
    leaf = 10723425539,
    library = 10723425615,
    lifebuoy = 10723425685,
    lightbulb = 10723425852,
    lightbulboff = 10723425762,
    linechart = 10723426393,
    link = 10723426722,
    link2 = 10723426595,
    link2off = 10723426513,
    list = 10723433811,
    listchecks = 10734884548,
    listend = 10723426886,
    listminus = 10723426986,
    listmusic = 10723427081,
    listordered = 10723427199,
    listplus = 10723427334,
    liststart = 10723427494,
    listvideo = 10723427619,
    listx = 10723433655,
    loader = 10723434070,
    loader2 = 10723433935,
    locate = 10723434557,
    locatefixed = 10723434236,
    locateoff = 10723434379,
    lock = 10723434711,
    login = 10723434830,
    logout = 10723434906,
    luggage = 10723434993,
    magnet = 10723435069,
    mail = 10734885430,
    mailcheck = 10723435182,
    mailminus = 10723435261,
    mailopen = 10723435342,
    mailplus = 10723435443,
    mailquestion = 10723435515,
    mailsearch = 10734884739,
    mailwarning = 10734885015,
    mailx = 10734885247,
    mails = 10734885614,
    map = 10734886202,
    mappin = 10734886004,
    mappinoff = 10734885803,
    maximize = 10734886735,
    maximize2 = 10734886496,
    medal = 10734887072,
    megaphone = 10734887454,
    megaphoneoff = 10734887311,
    meh = 10734887603,
    menu = 10734887784,
    messagecircle = 10734888000,
    messagesquare = 10734888228,
    mic = 10734888864,
    mic2 = 10734888430,
    micoff = 10734888646,
    microscope = 10734889106,
    microwave = 10734895076,
    milestone = 10734895310,
    minimize = 10734895698,
    minimize2 = 10734895530,
    minus = 10734896206,
    minuscircle = 10734895856,
    minussquare = 10734896029,
    monitor = 10734896881,
    monitoroff = 10734896360,
    monitorspeaker = 10734896512,
    moon = 10734897102,
    morehorizontal = 10734897250,
    morevertical = 10734897387,
    mountain = 10734897956,
    mountainsnow = 10734897665,
    mouse = 10734898592,
    mousepointer = 10734898476,
    mousepointer2 = 10734898194,
    mousepointerclick = 10734898355,
    move = 10734900011,
    move3d = 10734898756,
    movediagonal = 10734899164,
    movediagonal2 = 10734898934,
    movehorizontal = 10734899414,
    movevertical = 10734899821,
    music = 10734905958,
    music2 = 10734900215,
    music3 = 10734905665,
    music4 = 10734905823,
    navigation = 10734906744,
    navigation2 = 10734906332,
    navigation2off = 10734906144,
    navigationoff = 10734906580,
    network = 10734906975,
    newspaper = 10734907168,
    octagon = 10734907361,
    option = 10734907649,
    outdent = 10734907933,
    package = 10734909540,
    package2 = 10734908151,
    packagecheck = 10734908384,
    packageminus = 10734908626,
    packageopen = 10734908793,
    packageplus = 10734909016,
    packagesearch = 10734909196,
    packagex = 10734909375,
    paintbucket = 10734909847,
    paintbrush = 10734910187,
    paintbrush2 = 10734910030,
    palette = 10734910430,
    palmtree = 10734910680,
    paperclip = 10734910927,
    partypopper = 10734918735,
    pause = 10734919336,
    pausecircle = 10735024209,
    pauseoctagon = 10734919143,
    pentool = 10734919503,
    pencil = 10734919691,
    percent = 10734919919,
    personstanding = 10734920149,
    phone = 10734921524,
    phonecall = 10734920305,
    phoneforwarded = 10734920508,
    phoneincoming = 10734920694,
    phonemissed = 10734920845,
    phoneoff = 10734921077,
    phoneoutgoing = 10734921288,
    piechart = 10734921727,
    piggybank = 10734921935,
    pin = 10734922324,
    pinoff = 10734922180,
    pipette = 10734922497,
    pizza = 10734922774,
    plane = 10734922971,
    play = 10734923549,
    playcircle = 10734923214,
    plus = 10734924532,
    pluscircle = 10734923868,
    plussquare = 10734924219,
    podcast = 10734929553,
    pointer = 10734929723,
    poundsterling = 10734929981,
    power = 10734930466,
    poweroff = 10734930257,
    printer = 10734930632,
    puzzle = 10734930886,
    quote = 10734931234,
    radio = 10734931596,
    radioreceiver = 10734931402,
    rectanglehorizontal = 10734931777,
    rectanglevertical = 10734932081,
    recycle = 10734932295,
    redo = 10734932822,
    redo2 = 10734932586,
    refreshccw = 10734933056,
    refreshcw = 10734933222,
    refrigerator = 10734933465,
    regex = 10734933655,
    ["repeat"] = 10734933966,
    repeat1 = 10734933826,
    reply = 10734934252,
    replyall = 10734934132,
    rewind = 10734934347,
    rocket = 10734934585,
    rockingchair = 10734939942,
    rotate3d = 10734940107,
    rotateccw = 10734940376,
    rotatecw = 10734940654,
    rss = 10734940825,
    ruler = 10734941018,
    russianruble = 10734941199,
    sailboat = 10734941354,
    save = 10734941499,
    scale = 10734941912,
    scale3d = 10734941739,
    scaling = 10734942072,
    scan = 10734942565,
    scanface = 10734942198,
    scanline = 10734942351,
    scissors = 10734942778,
    screenshare = 10734943193,
    screenshareoff = 10734942967,
    scroll = 10734943448,
    search = 10734943674,
    send = 10734943902,
    separatorhorizontal = 10734944115,
    separatorvertical = 10734944326,
    server = 10734949856,
    servercog = 10734944444,
    servercrash = 10734944554,
    serveroff = 10734944668,
    settings = 10734950309,
    settings2 = 10734950020,
    share = 10734950813,
    share2 = 10734950553,
    sheet = 10734951038,
    shield = 10734951847,
    shieldalert = 10734951173,
    shieldcheck = 10734951367,
    shieldclose = 10734951535,
    shieldoff = 10734951684,
    shirt = 10734952036,
    shoppingbag = 10734952273,
    shoppingcart = 10734952479,
    shovel = 10734952773,
    showerhead = 10734952942,
    shrink = 10734953073,
    shrub = 10734953241,
    shuffle = 10734953451,
    sidebar = 10734954301,
    sidebarclose = 10734953715,
    sidebaropen = 10734954000,
    sigma = 10734954538,
    signal = 10734961133,
    signalhigh = 10734954807,
    signallow = 10734955080,
    signalmedium = 10734955336,
    signalzero = 10734960878,
    siren = 10734961284,
    skipback = 10734961526,
    skipforward = 10734961809,
    skull = 10734962068,
    slack = 10734962339,
    slash = 10734962600,
    slice = 10734963024,
    sliders = 10734963400,
    slidershorizontal = 10734963191,
    smartphone = 10734963940,
    smartphonecharging = 10734963671,
    smile = 10734964441,
    smileplus = 10734964188,
    snowflake = 10734964600,
    sofa = 10734964852,
    sortasc = 10734965115,
    sortdesc = 10734965287,
    speaker = 10734965419,
    sprout = 10734965572,
    square = 10734965702,
    star = 10734966248,
    starhalf = 10734965897,
    staroff = 10734966097,
    stethoscope = 10734966384,
    sticker = 10734972234,
    stickynote = 10734972463,
    stopcircle = 10734972621,
    stretchhorizontal = 10734972862,
    stretchvertical = 10734973130,
    strikethrough = 10734973290,
    subscript = 10734973457,
    sun = 10734974297,
    sundim = 10734973645,
    sunmedium = 10734973778,
    sunmoon = 10734973999,
    sunsnow = 10734974130,
    sunrise = 10734974522,
    sunset = 10734974689,
    superscript = 10734974850,
    swissfranc = 10734975024,
    switchcamera = 10734975214,
    sword = 10734975486,
    swords = 10734975692,
    syringe = 10734975932,
    table = 10734976230,
    table2 = 10734976097,
    tablet = 10734976394,
    tag = 10734976528,
    tags = 10734976739,
    target = 10734977012,
    tent = 10734981750,
    terminal = 10734982144,
    terminalsquare = 10734981995,
    textcursor = 10734982395,
    textcursorinput = 10734982297,
    thermometer = 10734983134,
    thermometersnowflake = 10734982571,
    thermometersun = 10734982771,
    thumbsdown = 10734983359,
    thumbsup = 10734983629,
    ticket = 10734983868,
    timer = 10734984606,
    timeroff = 10734984138,
    timerreset = 10734984355,
    toggleleft = 10734984834,
    toggleright = 10734985040,
    tornado = 10734985247,
    toybrick = 10747361919,
    train = 10747362105,
    trash = 10747362393,
    trash2 = 10747362241,
    treedeciduous = 10747362534,
    treepine = 10747362748,
    trees = 10747363016,
    trendingdown = 10747363205,
    trendingup = 10747363465,
    triangle = 10747363621,
    trophy = 10747363809,
    truck = 10747364031,
    tv = 10747364593,
    tv2 = 10747364302,
    type = 10747364761,
    umbrella = 10747364971,
    underline = 10747365191,
    undo = 10747365484,
    undo2 = 10747365359,
    unlink = 10747365771,
    unlink2 = 10747397871,
    unlock = 10747366027,
    upload = 10747366434,
    uploadcloud = 10747366266,
    usb = 10747366606,
    user = 10747373176,
    usercheck = 10747371901,
    usercog = 10747372167,
    userminus = 10747372346,
    userplus = 10747372702,
    userx = 10747372992,
    users = 10747373426,
    utensils = 10747373821,
    utensilscrossed = 10747373629,
    venetianmask = 10747374003,
    verified = 10747374131,
    vibrate = 10747374489,
    vibrateoff = 10747374269,
    video = 10747374938,
    videooff = 10747374721,
    view = 10747375132,
    voicemail = 10747375281,
    volume = 10747376008,
    volume1 = 10747375450,
    volume2 = 10747375679,
    volumex = 10747375880,
    wallet = 10747376205,
    wand = 10747376565,
    wand2 = 10747376349,
    watch = 10747376722,
    waves = 10747376931,
    webcam = 10747381992,
    wifi = 10747382504,
    wifioff = 10747382268,
    wind = 10747382750,
    wraptext = 10747383065,
    wrench = 10747383470,
    x = 10747384394,
    xcircle = 10747383819,
    xoctagon = 10747384037,
    xsquare = 10747384217,
    zoomin = 10747384552,
    zoomout = 10747384679
}

function PiLib:GetIcon(iconName)
    if not iconName or iconName == "" then return nil end
    -- Normalize Lucide-style names: "layout-dashboard" -> "layoutdashboard"
    iconName = string.lower(iconName):gsub("[%s%-]+", "")
    if IconsMap[iconName] then
        return "rbxassetid://" .. tostring(IconsMap[iconName])
    elseif IconsMap["lucide-" .. iconName] then
        return "rbxassetid://" .. tostring(IconsMap["lucide-" .. iconName])
    elseif string.find(tostring(iconName), "rbxassetid://") or string.find(tostring(iconName), "http") then
        return iconName
    end
    return nil
end

-- [SECTION 5] NOTIFICATION SYSTEM
local NotificationHolder = nil

function PiLib:InitNotificationHolder(screenGui)
    if NotificationHolder then return end
    NotificationHolder = Creator.New("Frame", {
        Name = "PiLib_NotificationHolder",
        Size = UDim2.new(0, 300, 1, -40),
        Position = UDim2.new(1, -20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Parent = screenGui
    }, {
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 10)
        })
    })
end

function PiLib:Notify(config)
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local subContent = config.SubContent or ""
    local duration = config.Duration or 4
    local icon = self:GetIcon(config.Icon or config.Image or "bell")

    if not NotificationHolder then return end

    local notifFrame = Creator.New("Frame", {
        Name = "Notif",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "Card" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            Transparency = 0.5,
            ThemeTag = { Color = "Border" }
        }),
        Creator.New("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12)
        }),
        Creator.New("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(0, 3, 1, 0),
            Position = UDim2.new(0, -12, 0, 0),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Accent" }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) })
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -20, 0, 16),
            BackgroundTransparency = 1,
            ThemeTag = { TextColor3 = "Text" }
        }),
        Creator.New("TextLabel", {
            Name = "Content",
            Text = content,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            ThemeTag = { TextColor3 = "SubText" }
        })
    })

    notifFrame.Position = UDim2.new(1, 40, 0, 0)
    notifFrame.Parent = NotificationHolder

    Creator.AdaptiveTween(notifFrame, { Position = UDim2.new(0, 0, 0, 0) }, 0.25)

    local function close()
        local tw = Creator.AdaptiveTween(notifFrame, { Position = UDim2.new(1, 40, 0, 0) }, 0.2)
        tw.Completed:Connect(function()
            notifFrame:Destroy()
        end)
    end

    if duration then
        task.delay(duration, close)
    end
end

-- [SECTION 6] WINDOW CREATION (Flat Minimalist + Dual Minimizer)
function PiLib:CreateWindow(config)
    assert(config.Title, "PiLib: Window Title is required!")

    -- Auto-Unload previous instance if re-executed
    if self.Window then
        pcall(function() self.Window:Destroy() end)
    end
    if getgenv then
        if getgenv().PiLibInstance and type(getgenv().PiLibInstance.Unload) == "function" then
            pcall(function() getgenv().PiLibInstance:Unload() end)
        end
    end

    local titleText = config.Title
    local subTitleText = config.SubTitle or ""
    local scriptFolder = config.ScriptFolder or "PiLib_Configs"
    local defaultSize = config.Size or (isTouch and UDim2.fromOffset(500, 360) or UDim2.fromOffset(560, 420))
    local minKey = config.MinimizeKey or Enum.KeyCode.LeftControl
    local defaultTheme = config.Theme or "Dark"

    self.CurrentTheme = defaultTheme

    -- ScreenGui Setup
    local targetParent, protect = GetGuiParent()
    if targetParent then
        local oldGui = targetParent:FindFirstChild("PiLib_UI")
        if oldGui then
            pcall(function() oldGui:Destroy() end)
        end
    end

    local screenGui = Creator.New("ScreenGui", {
        Name = "PiLib_UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100
    })
    if type(protect) == "function" then
        pcall(protect, screenGui)
    end
    screenGui.Parent = targetParent

    self:InitNotificationHolder(screenGui)

    -- Window Frame
    local mainFrame = Creator.New("Frame", {
        Name = "MainFrame",
        Size = defaultSize,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
        ThemeTag = { BackgroundColor3 = "Background" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            Transparency = 0.5,
            ThemeTag = { Color = "Border" }
        })
    })

    -- Dragging Logic (Supports PC Mouse and Mobile Touch)
    local isDragging, dragStart, startPos = false, nil, nil
    local topBar = Creator.New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        Parent = mainFrame,
        ThemeTag = { BackgroundColor3 = "Header" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("Frame", { -- Square bottom corners for header
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 1, -8),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Header" }
        }),
        Creator.New("Frame", {
            Name = "HeaderLine",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Divider" }
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Text = titleText,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ThemeTag = { TextColor3 = "Text" }
        }),
        Creator.New("TextLabel", {
            Name = "SubTitle",
            Text = subTitleText ~= "" and (" | " .. subTitleText) or "",
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ThemeTag = { TextColor3 = "SubText" }
        })
    })

    -- Reposition subtitle dynamically next to title
    topBar.Title:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        topBar.SubTitle.Position = UDim2.new(0, 14 + topBar.Title.AbsoluteSize.X + 4, 0, 0)
    end)

    -- TopBar Window Action Buttons (Minimize, Close)
    local buttonContainer = Creator.New("Frame", {
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -64, 0, 0),
        BackgroundTransparency = 1,
        Parent = topBar
    }, {
        Creator.New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6)
        })
    })

    local minimizeBtn = Creator.New("TextButton", {
        Text = "-",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Size = UDim2.fromOffset(26, 26),
        BorderSizePixel = 0,
        Parent = buttonContainer,
        ThemeTag = { BackgroundColor3 = "Card", TextColor3 = "Text" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }) })

    local closeBtn = Creator.New("TextButton", {
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Size = UDim2.fromOffset(26, 26),
        BorderSizePixel = 0,
        Parent = buttonContainer,
        ThemeTag = { BackgroundColor3 = "Card", TextColor3 = "Text" }
    }, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }) })

    -- Drag listeners
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Sidebar (Tabs list with rounded bottom-left corner matching mainFrame)
    local sidebarWidth = 140
    local sidebar = Creator.New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, -41),
        Position = UDim2.new(0, 0, 0, 41),
        BorderSizePixel = 0,
        Parent = mainFrame,
        ThemeTag = { BackgroundColor3 = "Sidebar" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        -- Square top corners of sidebar under the header
        Creator.New("Frame", {
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Sidebar" }
        }),
        -- Square bottom-right corner of sidebar where it meets divider
        Creator.New("Frame", {
            Size = UDim2.new(0, 8, 0, 8),
            Position = UDim2.new(1, -8, 1, -8),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Sidebar" }
        }),
        Creator.New("Frame", {
            Name = "SidebarDivider",
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0),
            BorderSizePixel = 0,
            ThemeTag = { BackgroundColor3 = "Divider" }
        })
    })

    local tabButtonScroll = Creator.New("ScrollingFrame", {
        Name = "TabButtons",
        Size = UDim2.new(1, -4, 1, -10),
        Position = UDim2.new(0, 2, 0, 5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = sidebar
    }, {
        Creator.New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    -- Main Content Area (Container for Tab pages)
    local contentContainer = Creator.New("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -sidebarWidth - 12, 1, -52),
        Position = UDim2.new(0, sidebarWidth + 6, 0, 46),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = mainFrame
    })

    -- Dialog Container
    local dialogOverlay = Creator.New("Frame", {
        Name = "DialogOverlay",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 10,
        Parent = mainFrame
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) })
    })

    local showFloatingBtn = true
    if config.FloatingButton ~= nil then
        showFloatingBtn = config.FloatingButton
    end

    local WindowObj = {
        MainFrame = mainFrame,
        ScreenGui = screenGui,
        Tabs = {},
        SelectedTab = nil,
        ScriptFolder = scriptFolder,
        IsMinimized = false
    }

    -- [DUAL MINIMIZER SETUP]
    -- 1. Mobile Draggable Floating Button
    local mobileBtn = Creator.New("ImageButton", {
        Name = "PiLib_MobileMinimizer",
        Size = UDim2.fromOffset(42, 42),
        Position = UDim2.new(0, 20, 0.5, -21),
        BorderSizePixel = 0,
        Visible = showFloatingBtn,
        Parent = screenGui,
        ThemeTag = { BackgroundColor3 = "FloatingButton" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIStroke", {
            Thickness = 1.5,
            ThemeTag = { Color = "Accent" }
        }),
        Creator.New("ImageLabel", {
            Size = UDim2.fromOffset(22, 22),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://10709752035", -- Lucide Activity / Pulse icon
            ThemeTag = { ImageColor3 = "Accent" }
        })
    })

    -- Draggable logic for Mobile Floating Button
    local mDragging, mStart, mPos = false, nil, nil
    mobileBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mDragging = true
            mStart = input.Position
            mPos = mobileBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mDragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if mDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - mStart
            mobileBtn.Position = UDim2.new(
                mPos.X.Scale,
                mPos.X.Offset + delta.X,
                mPos.Y.Scale,
                mPos.Y.Offset + delta.Y
            )
        end
    end)

    WindowObj.MobileButton = mobileBtn
    WindowObj.MinimizeKey = minKey

    function WindowObj:SetMinimizeKey(newKey)
        if typeof(newKey) == "EnumItem" then
            self.MinimizeKey = newKey
        elseif type(newKey) == "string" and Enum.KeyCode[newKey] then
            self.MinimizeKey = Enum.KeyCode[newKey]
        end
    end

    function WindowObj:Toggle()
        self.IsMinimized = not self.IsMinimized
        mainFrame.Visible = not self.IsMinimized
    end

    function WindowObj:SetFloatingButton(visible)
        mobileBtn.Visible = (visible == true)
    end

    function WindowObj:ToggleFloatingButton()
        mobileBtn.Visible = not mobileBtn.Visible
        return mobileBtn.Visible
    end

    Creator.AddSignal(mobileBtn.Activated, function()
        WindowObj:Toggle()
    end)

    Creator.AddSignal(minimizeBtn.Activated, function()
        WindowObj:Toggle()
    end)

    -- 2. PC Keybind Listener
    Creator.AddSignal(UserInputService.InputBegan, function(input, processed)
        if not processed and (input.KeyCode == WindowObj.MinimizeKey) then
            WindowObj:Toggle()
        end
    end)

    -- Close Button Confirmation Dialog
    closeBtn.Activated:Connect(function()
        WindowObj:Dialog({
            Title = "Unload Interface",
            Content = "Are you sure you want to close the interface?",
            Buttons = {
                {
                    Title = "Cancel"
                },
                {
                    Title = "Confirm",
                    Callback = function()
                        WindowObj:Destroy()
                    end
                }
            }
        })
    end)

    -- Dialog Function
    function WindowObj:Dialog(dialogConfig)
        local dTitle = dialogConfig.Title or "Dialog"
        local dContent = dialogConfig.Content or ""
        local dButtons = dialogConfig.Buttons or { { Title = "OK" } }

        dialogOverlay.Visible = true
        Creator.AdaptiveTween(dialogOverlay, { BackgroundTransparency = 0.5 }, 0.2)

        local dialogBox = Creator.New("Frame", {
            Name = "DialogBox",
            Size = UDim2.fromOffset(320, 150),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            Parent = dialogOverlay,
            ThemeTag = { BackgroundColor3 = "Dialog" }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
            Creator.New("UIStroke", { Thickness = 1, ThemeTag = { Color = "Border" } }),
            Creator.New("TextLabel", {
                Text = dTitle,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 16, 0, 14),
                Size = UDim2.new(1, -32, 0, 16),
                BackgroundTransparency = 1,
                ThemeTag = { TextColor3 = "Text" }
            }),
            Creator.New("TextLabel", {
                Text = dContent,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 16, 0, 36),
                Size = UDim2.new(1, -32, 0, 48),
                BackgroundTransparency = 1,
                ThemeTag = { TextColor3 = "SubText" }
            })
        })

        local btnContainer = Creator.New("Frame", {
            Size = UDim2.new(1, -24, 0, 30),
            Position = UDim2.new(0, 12, 1, -40),
            BackgroundTransparency = 1,
            Parent = dialogBox
        }, {
            Creator.New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 8)
            })
        })

        local function closeDialog()
            local tw = Creator.AdaptiveTween(dialogOverlay, { BackgroundTransparency = 1 }, 0.15)
            tw.Completed:Connect(function()
                dialogBox:Destroy()
                dialogOverlay.Visible = false
            end)
        end

        for _, btnData in ipairs(dButtons) do
            local b = Creator.New("TextButton", {
                Text = btnData.Title or "Button",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Size = UDim2.new(0, 80, 1, 0),
                BorderSizePixel = 0,
                Parent = btnContainer,
                ThemeTag = { BackgroundColor3 = "DialogButton", TextColor3 = "Text" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } })
            })

            b.Activated:Connect(function()
                if btnData.Callback then
                    pcall(btnData.Callback)
                end
                closeDialog()
            end)
        end
    end

    -- Flags API
    function WindowObj:GetFlag(flagName)
        return PiLib.Flags[flagName]
    end

    function WindowObj:SetFlag(flagName, value)
        PiLib.Flags[flagName] = value
        -- If an element matches this flag, update its display value
        if PiLib.Options[flagName] and PiLib.Options[flagName].SetValue then
            PiLib.Options[flagName]:SetValue(value)
        end
    end

    -- Tab API
    function WindowObj:AddTab(tabConfig)
        local tabTitle = tabConfig.Title or "Tab"
        local tabIcon = PiLib:GetIcon(tabConfig.Icon)

        -- Tab Button in Sidebar
        local tabBtn = Creator.New("TextButton", {
            Name = "Tab_" .. tabTitle,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Text = "",
            Parent = tabButtonScroll,
            ThemeTag = { BackgroundColor3 = "Card" }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Creator.New("TextLabel", {
                Name = "Title",
                Text = tabTitle,
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = tabIcon and UDim2.new(0, 30, 0, 0) or UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -35, 1, 0),
                BackgroundTransparency = 1,
                ThemeTag = { TextColor3 = "SubText" }
            })
        })

        if tabIcon then
            Creator.New("ImageLabel", {
                Name = "Icon",
                Image = tabIcon,
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(0, 8, 0.5, -8),
                BackgroundTransparency = 1,
                Parent = tabBtn,
                ThemeTag = { ImageColor3 = "SubText" }
            })
        end

        -- Tab Page Container (Scrolling)
        local tabPage = Creator.New("ScrollingFrame", {
            Name = "Page_" .. tabTitle,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            Visible = false,
            CanvasSize = UDim2.fromScale(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = contentContainer
        }, {
            Creator.New("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            Creator.New("UIPadding", {
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 10)
            })
        })

        local TabObj = {
            Title = tabTitle,
            Page = tabPage,
            Button = tabBtn
        }

        function TabObj:Select()
            for _, t in ipairs(WindowObj.Tabs) do
                t.Page.Visible = false
                Creator.AdaptiveTween(t.Button, { BackgroundTransparency = 1 }, 0.15)
                local txt = t.Button:FindFirstChild("Title")
                if txt then txt.TextColor3 = Creator.GetThemeProperty("SubText") end
                local ic = t.Button:FindFirstChild("Icon")
                if ic then ic.ImageColor3 = Creator.GetThemeProperty("SubText") end
            end

            tabPage.Visible = true
            Creator.AdaptiveTween(tabBtn, { BackgroundTransparency = 0 }, 0.15)
            local activeTxt = tabBtn:FindFirstChild("Title")
            if activeTxt then activeTxt.TextColor3 = Creator.GetThemeProperty("Text") end
            local activeIc = tabBtn:FindFirstChild("Icon")
            if activeIc then activeIc.ImageColor3 = Creator.GetThemeProperty("Accent") end

            WindowObj.SelectedTab = TabObj
        end

        tabBtn.Activated:Connect(function()
            TabObj:Select()
        end)

        table.insert(WindowObj.Tabs, TabObj)

        if #WindowObj.Tabs == 1 then
            TabObj:Select()
        end

        -- [TAB COMPONENT BUILDERS]
        function TabObj:AddSection(sectionTitle)
            local sectionFrame = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Parent = tabPage
            }, {
                Creator.New("TextLabel", {
                    Text = string.upper(sectionTitle),
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Accent" }
                })
            })
            return sectionFrame
        end

        function TabObj:AddParagraph(config)
            local pTitle = type(config) == "table" and config.Title or "Information"
            local pContent = type(config) == "table" and config.Content or tostring(config)

            local titleLabel = Creator.New("TextLabel", {
                Name = "Title",
                Text = pTitle,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                ThemeTag = { TextColor3 = "Text" }
            })

            local contentLabel = Creator.New("TextLabel", {
                Name = "Content",
                Text = pContent,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 0, 0, 18),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ThemeTag = { TextColor3 = "SubText" }
            })

            local card = Creator.New("Frame", {
                Name = "Paragraph",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } }),
                Creator.New("UIPadding", {
                    PaddingTop = UDim.new(0, 8),
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10)
                }),
                titleLabel,
                contentLabel
            })

            local ParagraphObj = {
                Frame = card,
                TitleLabel = titleLabel,
                ContentLabel = contentLabel
            }

            function ParagraphObj:SetTitle(newTitle)
                titleLabel.Text = tostring(newTitle or "")
            end

            function ParagraphObj:SetContent(newContent)
                contentLabel.Text = tostring(newContent or "")
            end

            return ParagraphObj
        end

        function TabObj:AddButton(config)
            local bTitle = config.Title or config.Name or "Button"
            local bDesc = config.Description or config.Desc or ""
            local callback = config.Callback or function() end
            local debounceTime = config.Debounce or 0.2
            local lastClick = 0

            local btnCard = Creator.New("TextButton", {
                Size = UDim2.new(1, 0, 0, bDesc ~= "" and 42 or 34),
                BorderSizePixel = 0,
                Text = "",
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } }),
                Creator.New("TextLabel", {
                    Name = "Title",
                    Text = bTitle,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, bDesc ~= "" and 4 or 0),
                    Size = UDim2.new(1, -40, bDesc ~= "" and 0 or 1, bDesc ~= "" and 16 or 0),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Text" }
                }),
                Creator.New("ImageLabel", {
                    Image = "rbxassetid://10709791437", -- Lucide ChevronRight
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.new(1, -24, 0.5, -8),
                    BackgroundTransparency = 1,
                    ThemeTag = { ImageColor3 = "SubText" }
                })
            })

            if bDesc ~= "" then
                Creator.New("TextLabel", {
                    Text = bDesc,
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 22),
                    Size = UDim2.new(1, -40, 0, 14),
                    BackgroundTransparency = 1,
                    Parent = btnCard,
                    ThemeTag = { TextColor3 = "SubText" }
                })
            end

            btnCard.Activated:Connect(function()
                if tick() - lastClick >= debounceTime then
                    lastClick = tick()
                    Creator.AdaptiveTween(btnCard, { BackgroundColor3 = Creator.GetThemeProperty("CardActive") }, 0.08)
                    task.delay(0.1, function()
                        Creator.AdaptiveTween(btnCard, { BackgroundColor3 = Creator.GetThemeProperty("Card") }, 0.15)
                    end)
                    pcall(callback)
                end
            end)

            return btnCard
        end

        function TabObj:AddToggle(id, config)
            if type(id) == "table" and config == nil then
                config = id
                id = config.Flag or config.Name or ("Toggle_" .. tostring(#tabPage:GetChildren()))
            end

            local tTitle = config.Title or config.Name or "Toggle"
            local tDesc = config.Description or config.Desc or ""
            local defaultVal = config.Default or false
            local flagName = config.Flag or id
            local callback = config.Callback or function() end

            local currentVal = defaultVal
            PiLib.Flags[flagName] = currentVal

            local toggleCard = Creator.New("TextButton", {
                Size = UDim2.new(1, 0, 0, tDesc ~= "" and 42 or 34),
                BorderSizePixel = 0,
                Text = "",
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } }),
                Creator.New("TextLabel", {
                    Text = tTitle,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, tDesc ~= "" and 4 or 0),
                    Size = UDim2.new(1, -60, tDesc ~= "" and 0 or 1, tDesc ~= "" and 16 or 0),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Text" }
                })
            })

            if tDesc ~= "" then
                Creator.New("TextLabel", {
                    Text = tDesc,
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 22),
                    Size = UDim2.new(1, -60, 0, 14),
                    BackgroundTransparency = 1,
                    Parent = toggleCard,
                    ThemeTag = { TextColor3 = "SubText" }
                })
            end

            -- Switch Track & Thumb
            local track = Creator.New("Frame", {
                Size = UDim2.fromOffset(36, 18),
                Position = UDim2.new(1, -46, 0.5, -9),
                BorderSizePixel = 0,
                Parent = toggleCard,
                ThemeTag = { BackgroundColor3 = currentVal and "ToggleActive" or "ToggleTrack" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local thumb = Creator.New("Frame", {
                Size = UDim2.fromOffset(14, 14),
                Position = currentVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = track
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local ToggleObj = {
                Value = currentVal,
                Type = "Toggle"
            }

            function ToggleObj:SetValue(val)
                currentVal = val
                ToggleObj.Value = val
                PiLib.Flags[flagName] = val

                local targetPos = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                local targetColor = val and Creator.GetThemeProperty("ToggleActive") or Creator.GetThemeProperty("ToggleTrack")
                Creator.AdaptiveTween(thumb, { Position = targetPos }, 0.15)
                Creator.AdaptiveTween(track, { BackgroundColor3 = targetColor }, 0.15)

                pcall(callback, val)
            end

            toggleCard.Activated:Connect(function()
                ToggleObj:SetValue(not currentVal)
            end)

            PiLib.Options[id] = ToggleObj
            return ToggleObj
        end

        function TabObj:AddSlider(id, config)
            if type(id) == "table" and config == nil then
                config = id
                id = config.Flag or config.Name or ("Slider_" .. tostring(#tabPage:GetChildren()))
            end

            local sTitle = config.Title or config.Name or "Slider"
            local minVal = config.Min or 0
            local maxVal = config.Max or 100
            local inc = config.Increment or 1
            local defaultVal = config.Default or minVal
            local flagName = config.Flag or id
            local callback = config.Callback or function() end

            local currentVal = math.clamp(defaultVal, minVal, maxVal)
            PiLib.Flags[flagName] = currentVal

            local sliderCard = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 48),
                BorderSizePixel = 0,
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } }),
                Creator.New("TextLabel", {
                    Text = sTitle,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 6),
                    Size = UDim2.new(1, -80, 0, 16),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Text" }
                })
            })

            local valLabel = Creator.New("TextLabel", {
                Text = tostring(currentVal),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(1, -70, 0, 6),
                Size = UDim2.new(0, 60, 0, 16),
                BackgroundTransparency = 1,
                Parent = sliderCard,
                ThemeTag = { TextColor3 = "Accent" }
            })

            local barBackground = Creator.New("TextButton", {
                Name = "SliderTrack",
                Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.new(0, 10, 0, 30),
                Text = "",
                BorderSizePixel = 0,
                Parent = sliderCard,
                ThemeTag = { BackgroundColor3 = "Divider" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local fillPercent = (currentVal - minVal) / (maxVal - minVal)
            local barFill = Creator.New("Frame", {
                Size = UDim2.new(fillPercent, 0, 1, 0),
                BorderSizePixel = 0,
                Parent = barBackground,
                ThemeTag = { BackgroundColor3 = "Accent" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) })
            })

            local SliderObj = {
                Value = currentVal,
                Type = "Slider"
            }

            local function updateSlider(inputX)
                local absWidth = barBackground.AbsoluteSize.X
                local relX = math.clamp(inputX - barBackground.AbsolutePosition.X, 0, absWidth)
                local ratio = relX / absWidth
                local rawVal = minVal + (maxVal - minVal) * ratio
                local stepped = math.floor((rawVal / inc) + 0.5) * inc
                stepped = math.clamp(stepped, minVal, maxVal)

                currentVal = stepped
                SliderObj.Value = stepped
                PiLib.Flags[flagName] = stepped
                valLabel.Text = tostring(stepped)
                barFill.Size = UDim2.new((stepped - minVal) / (maxVal - minVal), 0, 1, 0)
                pcall(callback, stepped)
            end

            function SliderObj:SetValue(val)
                local clamped = math.clamp(val, minVal, maxVal)
                currentVal = clamped
                SliderObj.Value = clamped
                PiLib.Flags[flagName] = clamped
                valLabel.Text = tostring(clamped)
                barFill.Size = UDim2.new((clamped - minVal) / (maxVal - minVal), 0, 1, 0)
                pcall(callback, clamped)
            end

            local sDragging = false
            barBackground.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sDragging = true
                    updateSlider(input.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sDragging = false
                end
            end)

            PiLib.Options[id] = SliderObj
            return SliderObj
        end

        function TabObj:AddDropdown(id, config)
            if type(id) == "table" and config == nil then
                config = id
                id = config.Flag or config.Name or ("Dropdown_" .. tostring(#tabPage:GetChildren()))
            end

            local dTitle = config.Title or config.Name or "Dropdown"
            local optionsList = config.Options or config.Values or {}
            local isMulti = config.Multi or config.MultiSelect or false
            local defaultVal = config.Default or (isMulti and {} or optionsList[1])
            local flagName = config.Flag or id
            local callback = config.Callback or function() end

            local currentVal = defaultVal
            PiLib.Flags[flagName] = currentVal

            local isOpen = false
            local dropCard = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } })
            })

            local headerBtn = Creator.New("TextButton", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundTransparency = 1,
                Text = "",
                Parent = dropCard
            }, {
                Creator.New("TextLabel", {
                    Text = dTitle,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 4),
                    Size = UDim2.new(1, -40, 0, 16),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Text" }
                })
            })

            local selectionLabel = Creator.New("TextLabel", {
                Text = isMulti and "Select options..." or tostring(currentVal or "None"),
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 10, 0, 22),
                Size = UDim2.new(1, -40, 0, 14),
                BackgroundTransparency = 1,
                Parent = headerBtn,
                ThemeTag = { TextColor3 = "Accent" }
            })

            local arrowIcon = Creator.New("ImageLabel", {
                Image = "rbxassetid://10709790948", -- ChevronDown
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(1, -26, 0, 13),
                BackgroundTransparency = 1,
                Parent = headerBtn,
                ThemeTag = { ImageColor3 = "SubText" }
            })

            local listHolder = Creator.New("Frame", {
                Size = UDim2.new(1, -16, 0, 0),
                Position = UDim2.new(0, 8, 0, 44),
                BackgroundTransparency = 1,
                Parent = dropCard
            }, {
                Creator.New("UIListLayout", {
                    Padding = UDim.new(0, 3),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
            })

            local DropObj = {
                Value = currentVal,
                Type = "Dropdown",
                Multi = isMulti
            }

            local optionButtons = {}

            local function updateOptionMarkers()
                for optStr, data in pairs(optionButtons) do
                    local isSelected = false
                    if isMulti then
                        isSelected = (type(currentVal) == "table" and currentVal[optStr] == true)
                    else
                        isSelected = (currentVal == optStr)
                    end

                    data.CheckIcon.Visible = isSelected
                    if isSelected then
                        data.Button.BackgroundColor3 = Creator.GetThemeProperty("CardActive")
                        data.Label.TextColor3 = Creator.GetThemeProperty("Accent")
                    else
                        data.Button.BackgroundColor3 = Creator.GetThemeProperty("CardHover")
                        data.Label.TextColor3 = Creator.GetThemeProperty("Text")
                    end
                end
            end

            local function updateDisplay()
                if isMulti then
                    local keys = {}
                    if type(currentVal) == "table" then
                        for k, v in pairs(currentVal) do
                            if v then table.insert(keys, tostring(k)) end
                        end
                    end
                    selectionLabel.Text = #keys > 0 and table.concat(keys, ", ") or "None selected"
                else
                    selectionLabel.Text = tostring(currentVal or "None")
                end
            end

            local function refreshOptions()
                optionButtons = {}
                for _, c in ipairs(listHolder:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end

                for _, opt in ipairs(optionsList) do
                    local optStr = tostring(opt)
                    local optBtn = Creator.New("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        Text = "",
                        BorderSizePixel = 0,
                        Parent = listHolder,
                        ThemeTag = { BackgroundColor3 = "CardHover" }
                    }, {
                        Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) })
                    })

                    local optLabel = Creator.New("TextLabel", {
                        Text = "  " .. optStr,
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Size = UDim2.new(1, -28, 1, 0),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Parent = optBtn,
                        ThemeTag = { TextColor3 = "Text" }
                    })

                    local checkIcon = Creator.New("ImageLabel", {
                        Name = "CheckIcon",
                        Image = "rbxassetid://10709790644", -- Lucide Check icon
                        Size = UDim2.fromOffset(14, 14),
                        Position = UDim2.new(1, -20, 0.5, -7),
                        BackgroundTransparency = 1,
                        Visible = false,
                        Parent = optBtn,
                        ThemeTag = { ImageColor3 = "Accent" }
                    })

                    optionButtons[optStr] = {
                        Button = optBtn,
                        Label = optLabel,
                        CheckIcon = checkIcon
                    }

                    optBtn.Activated:Connect(function()
                        if isMulti then
                            if type(currentVal) ~= "table" then currentVal = {} end
                            currentVal[optStr] = not currentVal[optStr]
                            DropObj.Value = currentVal
                            PiLib.Flags[flagName] = currentVal
                            updateDisplay()
                            updateOptionMarkers()
                            pcall(callback, currentVal)
                        else
                            currentVal = optStr
                            DropObj.Value = optStr
                            PiLib.Flags[flagName] = optStr
                            updateDisplay()
                            updateOptionMarkers()
                            pcall(callback, optStr)
                            -- Close dropdown
                            isOpen = false
                            Creator.AdaptiveTween(dropCard, { Size = UDim2.new(1, 0, 0, 42) }, 0.2)
                            Creator.AdaptiveTween(arrowIcon, { Rotation = 0 }, 0.2)
                        end
                    end)
                end
                updateOptionMarkers()
            end

            refreshOptions()
            updateDisplay()

            function DropObj:SetValues(newList)
                optionsList = newList or {}
                refreshOptions()
            end

            function DropObj:SetValue(val)
                currentVal = val
                DropObj.Value = val
                PiLib.Flags[flagName] = val
                updateDisplay()
                updateOptionMarkers()
                pcall(callback, val)
            end

            headerBtn.Activated:Connect(function()
                isOpen = not isOpen
                local targetHeight = isOpen and (48 + (#optionsList * 29)) or 42
                Creator.AdaptiveTween(dropCard, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2)
                Creator.AdaptiveTween(arrowIcon, { Rotation = isOpen and 180 or 0 }, 0.2)
            end)

            PiLib.Options[id] = DropObj
            return DropObj
        end

        function TabObj:AddInput(id, config)
            if type(id) == "table" and config == nil then
                config = id
                id = config.Flag or config.Name or ("Input_" .. tostring(#tabPage:GetChildren()))
            end

            local iTitle = config.Title or config.Name or "Input"
            local defaultVal = config.Default or ""
            local placeholder = config.Placeholder or "Type here..."
            local numeric = config.Numeric or false
            local flagName = config.Flag or id
            local callback = config.Callback or function() end

            local currentVal = defaultVal
            PiLib.Flags[flagName] = currentVal

            local inputCard = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BorderSizePixel = 0,
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } }),
                Creator.New("TextLabel", {
                    Text = iTitle,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Text" }
                })
            })

            local textBoxFrame = Creator.New("Frame", {
                Size = UDim2.new(0.46, 0, 0, 26),
                Position = UDim2.new(0.52, 0, 0.5, -13),
                BorderSizePixel = 0,
                Parent = inputCard,
                ThemeTag = { BackgroundColor3 = "Header" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.5, ThemeTag = { Color = "Border" } })
            })

            local textBox = Creator.New("TextBox", {
                Text = tostring(defaultVal),
                PlaceholderText = placeholder,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                ClearTextOnFocus = false,
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Parent = textBoxFrame,
                ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "SubText" }
            })

            local InputObj = {
                Value = currentVal,
                Type = "Input"
            }

            local function applyText(text)
                if numeric then
                    text = text:gsub("%D+", "")
                end
                currentVal = text
                InputObj.Value = text
                PiLib.Flags[flagName] = text
                textBox.Text = text
                pcall(callback, text)
            end

            textBox.FocusLost:Connect(function()
                applyText(textBox.Text)
            end)

            function InputObj:SetValue(val)
                applyText(tostring(val))
            end

            PiLib.Options[id] = InputObj
            return InputObj
        end

        function TabObj:AddKeybind(id, config)
            if type(id) == "table" and config == nil then
                config = id
                id = config.Flag or config.Name or ("Keybind_" .. tostring(#tabPage:GetChildren()))
            end

            local kTitle = config.Title or config.Name or "Keybind"
            local kDesc = config.Description or config.Desc or ""
            local defaultKey = config.Default or Enum.KeyCode.E
            if type(defaultKey) == "string" then
                defaultKey = Enum.KeyCode[defaultKey] or Enum.KeyCode.E
            end
            local flagName = config.Flag or id
            local callback = config.Callback or function() end
            local changedCallback = config.ChangedCallback or function() end

            local currentKey = defaultKey
            PiLib.Flags[flagName] = currentKey

            local keybindCard = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, kDesc ~= "" and 42 or 34),
                BorderSizePixel = 0,
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } }),
                Creator.New("TextLabel", {
                    Text = kTitle,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, kDesc ~= "" and 4 or 0),
                    Size = UDim2.new(1, -110, kDesc ~= "" and 0 or 1, kDesc ~= "" and 16 or 0),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Text" }
                })
            })

            if kDesc ~= "" then
                Creator.New("TextLabel", {
                    Text = kDesc,
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 10, 0, 22),
                    Size = UDim2.new(1, -110, 0, 14),
                    BackgroundTransparency = 1,
                    Parent = keybindCard,
                    ThemeTag = { TextColor3 = "SubText" }
                })
            end

            local bindButton = Creator.New("TextButton", {
                Size = UDim2.new(0, 96, 0, 24),
                Position = UDim2.new(1, -106, 0.5, -12),
                BorderSizePixel = 0,
                Text = "[ " .. tostring(currentKey.Name) .. " ]",
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                Parent = keybindCard,
                ThemeTag = { BackgroundColor3 = "Header", TextColor3 = "Accent" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.5, ThemeTag = { Color = "Border" } })
            })

            local KeybindObj = {
                Value = currentKey,
                Type = "Keybind"
            }

            local isListening = false

            local function setKey(newKey)
                currentKey = newKey
                KeybindObj.Value = newKey
                PiLib.Flags[flagName] = newKey
                bindButton.Text = "[ " .. tostring(newKey.Name) .. " ]"
                bindButton.TextColor3 = Creator.GetThemeProperty("Accent")
                pcall(changedCallback, newKey)
                pcall(callback, newKey)
            end

            function KeybindObj:SetValue(newKey)
                if type(newKey) == "string" and Enum.KeyCode[newKey] then
                    newKey = Enum.KeyCode[newKey]
                end
                if typeof(newKey) == "EnumItem" then
                    setKey(newKey)
                end
            end

            bindButton.Activated:Connect(function()
                if isListening then return end
                isListening = true
                bindButton.Text = "[ ... ]"
                bindButton.TextColor3 = Creator.GetThemeProperty("SubText")

                local conn
                conn = UserInputService.InputBegan:Connect(function(input, processed)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            conn:Disconnect()
                            isListening = false
                            setKey(input.KeyCode)
                        end
                    end
                end)
            end)

            Creator.AddSignal(UserInputService.InputBegan, function(input, processed)
                if not processed and not isListening and input.KeyCode == currentKey then
                    pcall(callback, currentKey)
                end
            end)

            PiLib.Options[id] = KeybindObj
            return KeybindObj
        end

        -- Discord Server Invite Card (Redz V5 feature)
        function TabObj:AddDiscordInvite(config)
            local dTitle = config.Title or "Community Discord"
            local dDesc = config.Description or "Join our community for script news and updates!"
            local inviteLink = config.Invite or "https://discord.gg/"
            local members = config.Members and tostring(config.Members) or nil
            local online = config.Online and tostring(config.Online) or nil

            local discordCard = Creator.New("Frame", {
                Size = UDim2.new(1, 0, 0, 72),
                BorderSizePixel = 0,
                Parent = tabPage,
                ThemeTag = { BackgroundColor3 = "Card" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Creator.New("UIStroke", { Thickness = 1, Transparency = 0.6, ThemeTag = { Color = "Border" } }),
                Creator.New("ImageLabel", {
                    Image = "rbxassetid://10709752906", -- Discord / Group icon
                    Size = UDim2.fromOffset(36, 36),
                    Position = UDim2.new(0, 12, 0, 12),
                    BackgroundTransparency = 1,
                    ThemeTag = { ImageColor3 = "Accent" }
                }),
                Creator.New("TextLabel", {
                    Text = dTitle,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 56, 0, 10),
                    Size = UDim2.new(1, -150, 0, 16),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "Text" }
                }),
                Creator.New("TextLabel", {
                    Text = dDesc,
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.new(0, 56, 0, 28),
                    Size = UDim2.new(1, -150, 0, 24),
                    BackgroundTransparency = 1,
                    ThemeTag = { TextColor3 = "SubText" }
                })
            })

            local copyBtn = Creator.New("TextButton", {
                Size = UDim2.fromOffset(80, 28),
                Position = UDim2.new(1, -90, 0.5, -14),
                Text = "Join / Copy",
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                BorderSizePixel = 0,
                Parent = discordCard,
                ThemeTag = { BackgroundColor3 = "Accent", TextColor3 = "Background" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) })
            })

            copyBtn.Activated:Connect(function()
                local setclipboard = setclipboard or toclipboard or function() end
                pcall(setclipboard, inviteLink)
                PiLib:Notify({
                    Title = "Discord Invite",
                    Content = "Copied invite to clipboard: " .. inviteLink,
                    Duration = 4
                })
            end)

            return discordCard
        end

        return TabObj
    end

    function WindowObj:Destroy()
        for i = #PiLib.Signals, 1, -1 do
            local conn = table.remove(PiLib.Signals, i)
            pcall(function() conn:Disconnect() end)
        end
        pcall(function() screenGui:Destroy() end)
        PiLib.Window = nil
        PiLib.Loaded = false
        PiLib.Unloaded = true
    end

    function WindowObj:Unload()
        self:Destroy()
    end

    self.Window = WindowObj
    self.Loaded = true
    return WindowObj
end

function PiLib:Unload()
    if self.Window then
        self.Window:Destroy()
    end
end

-- [SECTION 7] UNIFIED SAVE MANAGER (Configs & Flags)
local SaveManager = {
    Folder = "PiLibConfigs",
    Library = PiLib,
    AutoloadListeners = {}
}

local function fireAutoloadChanged()
    local currentName = SaveManager:GetAutoload()
    for _, callback in ipairs(SaveManager.AutoloadListeners) do
        pcall(callback, currentName)
    end
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    if not isfolder(self.Folder .. "/settings") then makefolder(self.Folder .. "/settings") end
end

function SaveManager:Save(configName)
    if not configName or configName == "" then return false end
    self:SetFolder(self.Folder)
    local fullPath = self.Folder .. "/settings/" .. configName .. ".json"

    local data = {
        Flags = PiLib.Flags,
        Theme = PiLib.CurrentTheme
    }

    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if success then
        writefile(fullPath, encoded)
        return true
    end
    return false
end

function SaveManager:Load(configName)
    if not configName or configName == "" then return false end
    local fullPath = self.Folder .. "/settings/" .. configName .. ".json"
    if not isfile(fullPath) then return false end

    local content = readfile(fullPath)
    local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
    if success and type(decoded) == "table" then
        if decoded.Theme then
            PiLib:SetTheme(decoded.Theme)
        end
        if decoded.Flags and type(decoded.Flags) == "table" then
            for flagKey, flagVal in pairs(decoded.Flags) do
                if PiLib.Window then
                    PiLib.Window:SetFlag(flagKey, flagVal)
                end
            end
        end
        return true
    end
    return false
end

function SaveManager:Delete(configName)
    if not configName or configName == "" or configName == "None" then return false end
    self:SetFolder(self.Folder)
    local fullPath = self.Folder .. "/settings/" .. configName .. ".json"
    if isfile(fullPath) then
        pcall(function() delfile(fullPath) end)
        -- If the deleted profile was set to autoload, clear autoload as well
        if self:GetAutoload() == configName then
            self:ClearAutoload()
        end
        return true
    end
    return false
end

function SaveManager:GetConfigs()
    self:SetFolder(self.Folder)
    local files = listfiles(self.Folder .. "/settings")
    local list = {}
    for _, f in ipairs(files) do
        if f:sub(-5) == ".json" then
            local cleanName = f:match("([^/\\]+)%.json$")
            if cleanName then
                table.insert(list, cleanName)
            end
        end
    end
    return list
end

function SaveManager:GetAutoload()
    self:SetFolder(self.Folder)
    local autoPath = self.Folder .. "/autoload.txt"
    if isfile(autoPath) then
        local storedName = tostring(readfile(autoPath)):match("^%s*(.-)%s*$")
        if storedName and storedName ~= "" then
            return storedName
        end
    end
    return nil
end

function SaveManager:SetAutoload(configName)
    if not configName or configName == "" or configName == "None" then return false end
    self:SetFolder(self.Folder)
    writefile(self.Folder .. "/autoload.txt", configName)
    fireAutoloadChanged()
    return true
end

function SaveManager:ClearAutoload()
    self:SetFolder(self.Folder)
    local autoPath = self.Folder .. "/autoload.txt"
    if isfile(autoPath) then
        pcall(function() delfile(autoPath) end)
    end
    fireAutoloadChanged()
    return true
end

function SaveManager:RefreshAutoloadStatus()
    fireAutoloadChanged()
end

function SaveManager:OnAutoloadChanged(callback)
    if type(callback) ~= "function" then return false end
    table.insert(self.AutoloadListeners, callback)
    return true
end

function SaveManager:BuildConfigSection(tab)
    local section = tab:AddSection("Configurations")

    local configNameInput = tab:AddInput("SaveManager_ConfigName", {
        Title = "Config Name",
        Placeholder = "Type profile name..."
    })

    local configDropdown = tab:AddDropdown("SaveManager_ConfigList", {
        Title = "Select Profile",
        Options = self:GetConfigs(),
        Default = self:GetConfigs()[1] or "None"
    })

    tab:AddButton({
        Title = "Create / Save Config",
        Callback = function()
            local name = configNameInput.Value
            if name and name ~= "" then
                if SaveManager:Save(name) then
                    local updated = SaveManager:GetConfigs()
                    configDropdown:SetValues(updated)
                    configDropdown:SetValue(name)
                    PiLib:Notify({ Title = "Config Saved", Content = "Saved profile: " .. name })
                end
            end
        end
    })

    tab:AddButton({
        Title = "Load Selected Config",
        Callback = function()
            local selected = configDropdown.Value
            if selected and selected ~= "" and selected ~= "None" then
                if SaveManager:Load(selected) then
                    PiLib:Notify({ Title = "Config Loaded", Content = "Loaded profile: " .. selected })
                end
            end
        end
    })

    tab:AddButton({
        Title = "Delete Selected Config",
        Callback = function()
            local selected = configDropdown.Value
            if selected and selected ~= "" and selected ~= "None" then
                local wasAutoload = SaveManager:GetAutoload() == selected
                if SaveManager:Delete(selected) then
                    local updated = SaveManager:GetConfigs()
                    configDropdown:SetValues(updated)
                    configDropdown:SetValue(updated[1] or "None")
                    local content = "Deleted profile: " .. selected
                    if wasAutoload then
                        content = content .. " (autoload cleared)"
                    end
                    PiLib:Notify({ Title = "Config Deleted", Content = content })
                else
                    PiLib:Notify({ Title = "Delete Failed", Content = "Could not find profile: " .. selected })
                end
            end
        end
    })

    local autoloadButton = tab:AddButton({
        Title = "Set As Autoload",
        Callback = function()
            local selected = configDropdown.Value
            if selected and selected ~= "" and selected ~= "None" then
                if SaveManager:SetAutoload(selected) then
                    PiLib:Notify({ Title = "Autoload Set", Content = "Profile " .. selected .. " will load on start." })
                end
            end
        end
    })

    -- The button title always reflects the current active autoload profile
    local autoloadButtonTitle = autoloadButton:FindFirstChild("Title")

    local function refreshAutoloadButtonTitle(currentName)
        if not autoloadButtonTitle then return end
        local activeName = currentName or SaveManager:GetAutoload()
        autoloadButtonTitle.Text = "Set As Autoload : " .. tostring(activeName or "None")
    end

    SaveManager:OnAutoloadChanged(refreshAutoloadButtonTitle)
    refreshAutoloadButtonTitle()

    tab:AddButton({
        Title = "Refresh Config List",
        Callback = function()
            configDropdown:SetValues(SaveManager:GetConfigs())
            SaveManager:RefreshAutoloadStatus()
        end
    })
end

function SaveManager:LoadAutoloadConfig()
    self:SetFolder(self.Folder)
    local name = self:GetAutoload()
    if name then
        self:Load(name)
    end
end

PiLib.SaveManager = SaveManager

return PiLib

end)()

return PiLib
