-- MatchaGUI
-- First-party Drawing-based GUI foundation for Matcha LuaVM scripts.
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Aughhhhhhh/MyUI/refs/heads/main/UI.lua"))()

local MatchaGUI = {}

local Drawing_new = Drawing.new
local Vector2_new = Vector2.new
local Color3_fromRGB = Color3.fromRGB
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local string_format = string.format
local os_clock = os.clock

local FONT = Drawing.Fonts.Monospace
local FONT_BOLD = FONT

local KEY_NAMES = {
    [0x01] = "LMB",
    [0x02] = "RMB",
    [0x08] = "Back",
    [0x09] = "Tab",
    [0x0D] = "Enter",
    [0x10] = "Shift",
    [0x11] = "Ctrl",
    [0x12] = "Alt",
    [0x14] = "Caps",
    [0x1B] = "Esc",
    [0x20] = "Space",
    [0x2D] = "Insert",
    [0x2E] = "Delete",
    [0x6B] = "Num+",
    [0x6D] = "Num-",
    [0x6E] = "Num.",
    [0xBB] = "+",
    [0xBD] = "-",
    [0xBE] = ".",
    [0x70] = "F1",
    [0x71] = "F2",
    [0x72] = "F3",
    [0x73] = "F4",
    [0x74] = "F5",
    [0x75] = "F6",
    [0x76] = "F7",
    [0x77] = "F8",
    [0x78] = "F9",
    [0x79] = "F10",
    [0x7A] = "F11",
    [0x7B] = "F12",
}

for i = 0x41, 0x5A do
    KEY_NAMES[i] = string.char(i)
end

for i = 0x30, 0x39 do
    KEY_NAMES[i] = string.char(i)
end

for i = 0x60, 0x69 do
    KEY_NAMES[i] = "Num" .. tostring(i - 0x60)
end

local KEY_SCAN = {
    0x08, 0x09, 0x0D, 0x10, 0x11, 0x12, 0x14, 0x1B, 0x20, 0x2D, 0x2E,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
    0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6B, 0x6D, 0x6E,
    0xBB, 0xBD, 0xBE,
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B,
}

local TEXT_BLOCK_KEYS = {
    0x20, 0x25, 0x26, 0x27, 0x28,
    0x41, 0x44, 0x53, 0x57,
}

local DEFAULT_THEME = {
    bg = Color3_fromRGB(12, 12, 12),
    panel = Color3_fromRGB(20, 20, 20),
    panel2 = Color3_fromRGB(30, 30, 30),
    hover = Color3_fromRGB(38, 38, 38),
    stroke = Color3_fromRGB(0, 0, 0),
    stroke2 = Color3_fromRGB(50, 50, 50),
    text = Color3_fromRGB(244, 244, 244),
    muted = Color3_fromRGB(144, 144, 144),
    accent = Color3_fromRGB(69, 23, 255),
    accent2 = Color3_fromRGB(69, 23, 255),
    danger = Color3_fromRGB(233, 0, 0),
    control = Color3_fromRGB(35, 35, 35),
    control2 = Color3_fromRGB(24, 24, 24),
    white = Color3_fromRGB(255, 255, 255),
    shadow = Color3_fromRGB(0, 0, 0),
}

local COLOR_PALETTE = {
    Color3_fromRGB(255, 255, 255),
    Color3_fromRGB(69, 23, 255),
    Color3_fromRGB(255, 92, 92),
    Color3_fromRGB(43, 214, 158),
    Color3_fromRGB(255, 210, 84),
    Color3_fromRGB(240, 142, 214),
}

local NOTIFY_COLORS = {
    info    = Color3_fromRGB(80, 145, 255),
    success = Color3_fromRGB(64, 205, 132),
    warning = Color3_fromRGB(255, 188, 58),
    error   = Color3_fromRGB(233, 70, 70),
}

local NOTIFY_TITLES = {
    info    = "Info",
    success = "Success",
    warning = "Warning",
    error   = "Error",
}

local NOTIFY_WIDTH    = 280
local NOTIFY_HEIGHT   = 56
local NOTIFY_MARGIN   = 14
local NOTIFY_GAP      = 8
local NOTIFY_ENTER    = 0.28
local NOTIFY_EXIT     = 0.22
local NOTIFY_Z_BASE   = 200

local function copyTheme(overrides)
    local theme = {}
    for k, v in pairs(DEFAULT_THEME) do
        theme[k] = v
    end
    if overrides then
        for k, v in pairs(overrides) do
            theme[k] = v
        end
    end
    return theme
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function inside(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function keyName(vk)
    if type(vk) ~= "number" then vk = 0 end
    return KEY_NAMES[vk] or ("0x" .. string_format("%X", vk or 0))
end

local function readKey(vk)
    if not vk or not iskeypressed then return false end
    local ok, down = pcall(iskeypressed, vk)
    return ok and down == true
end

local function releaseKey(vk)
    if not vk or not keyrelease then return false end
    local ok = pcall(keyrelease, vk)
    return ok == true
end

local function releaseTextBlockKeys()
    for _, vk in ipairs(TEXT_BLOCK_KEYS) do
        if readKey(vk) then
            releaseKey(vk)
        end
    end
end

local function charFromKey(vk)
    if vk >= 0x41 and vk <= 0x5A then
        if readKey(0x10) then
            return string.char(vk)
        end
        return string.char(vk + 32)
    end
    if vk >= 0x30 and vk <= 0x39 then
        return string.char(vk)
    end
    if vk >= 0x60 and vk <= 0x69 then
        return tostring(vk - 0x60)
    end
    if vk == 0x6E or vk == 0xBE then
        return "."
    end
    if vk == 0x6D or vk == 0xBD then
        return "-"
    end
    if vk == 0x6B or vk == 0xBB then
        return "+"
    end
    if vk == 0x20 then
        return " "
    end
    return nil
end

local function numericCharFromKey(vk)
    if vk >= 0x30 and vk <= 0x39 then
        return string.char(vk)
    end
    if vk >= 0x60 and vk <= 0x69 then
        return tostring(vk - 0x60)
    end
    if vk == 0x6E or vk == 0xBE then
        return "."
    end
    if vk == 0x6D or vk == 0xBD then
        return "-"
    end
    if vk == 0x6B or vk == 0xBB then
        return "+"
    end
    return nil
end

local function readMouseDown()
    if not ismouse1pressed then return false end
    local ok, down = pcall(ismouse1pressed)
    return ok and down == true
end

local function readMouse2Down()
    if not ismouse2pressed then return false end
    local ok, down = pcall(ismouse2pressed)
    return ok and down == true
end

local function robloxActive()
    if not isrbxactive then return true end
    local ok, active = pcall(isrbxactive)
    if not ok then return true end
    return active == true
end

local function createDrawing(owner, typ, props)
    local obj = Drawing_new(typ)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    table.insert(owner._drawings, obj)
    return obj
end

local function setVisible(obj, visible)
    if obj then obj.Visible = visible end
end

local function removeAll(drawings)
    for _, obj in ipairs(drawings) do
        pcall(function() obj:Remove() end)
    end
    table.clear(drawings)
end

local function asText(value)
    local valueType = type(value)
    if valueType == "string" then return value end
    if valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end
    return ""
end

local function asNumber(value, fallback)
    if type(value) == "number" then return value end
    return fallback
end

local function sliderLimits(widget)
    local minValue = asNumber(widget.min, 0)
    local maxValue = asNumber(widget.max, minValue + 1)
    if maxValue <= minValue then maxValue = minValue + 1 end
    return minValue, maxValue
end

local function normalizeSliderValue(widget, value)
    value = tonumber(value)
    if not value then return nil end

    local minValue, maxValue = sliderLimits(widget)
    local nextValue = clamp(value, minValue, maxValue)
    local step = widget.step or 1

    if step > 0 then
        nextValue = math_floor((nextValue / step) + 1 / 2) * step
    end

    nextValue = clamp(nextValue, minValue, maxValue)
    if widget.format == "%d" then
        nextValue = math_floor(nextValue + 1 / 2)
    end

    return nextValue
end

local function formatSliderValue(widget, value)
    local ok, text = pcall(string_format, widget.format or "%.2f", value)
    if ok then return text end
    return tostring(value)
end

local function applySliderValue(window, widget, value)
    local nextValue = normalizeSliderValue(widget, value)
    if nextValue == nil then return false end

    if nextValue ~= widget.value then
        widget.value = nextValue
        window._values[widget.id] = nextValue
        if widget.callback then
            widget.callback(nextValue, widget)
        end
    else
        window._values[widget.id] = nextValue
    end

    return true, nextValue
end

local function normalizeItems(items)
    local out = {}
    if type(items) ~= "table" then return out end
    for _, item in ipairs(items) do
        local text = asText(item)
        if text ~= "" then
            table.insert(out, text)
        end
    end
    return out
end

local function cleanName(name)
    name = asText(name)
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[^%w _%-]", "_")
    if name == "" then return "default" end
    return name
end

local function joinPath(a, b)
    if not a or a == "" then return b end
    return a .. "/" .. b
end

local function stripExt(name)
    return (name:gsub("%.json$", ""):gsub("%.cfg$", ""))
end

local function fileName(path)
    path = tostring(path or ""):gsub("\\", "/")
    return path:match("([^/]+)$") or path
end

local function ensureFolderPath(path)
    if not path or path == "" then return false, "missing folder" end
    if not isfolder or not makefolder then return false, "filesystem unavailable" end

    local built = ""
    for part in string.gmatch(path:gsub("\\", "/"), "[^/]+") do
        built = joinPath(built, part)
        local okFolder, exists = pcall(isfolder, built)
        if not okFolder then return false, "isfolder failed" end
        if exists ~= true then
            local okMake = pcall(makefolder, built)
            if not okMake then return false, "makefolder failed" end
        end
    end

    return true
end

local function getHttpService()
    local ok, http = pcall(function()
        return game:GetService("HttpService")
    end)
    if ok and http then return http end
    return nil
end

local function isColor(value)
    if value == nil then return false end
    local valueType = type(value)
    if valueType == "boolean" or valueType == "number" or valueType == "string" then
        return false
    end
    local ok, r, g, b = pcall(function()
        return value.R, value.G, value.B
    end)
    return ok and r ~= nil and g ~= nil and b ~= nil
end

local function encodeValue(widget)
    if widget.skipConfig then return nil end
    if widget.kind == "button" or widget.kind == "text" then return nil end
    if widget.kind == "keybind" then
        return { type = "keybind", key = widget.key, active = widget.value == true }
    end
    if widget.kind == "menu_keybind" then
        return { type = "menu_keybind", key = widget.key or widget.value }
    end
    if widget.kind == "color_picker" then
        if not isColor(widget.value) then return nil end
        local color = widget.value
        return { type = "color", r = color.R, g = color.G, b = color.B }
    end
    if isColor(widget.value) then
        local color = widget.value
        return { type = "color", r = color.R, g = color.G, b = color.B }
    end
    return { type = widget.kind, value = widget.value }
end

local function decodeValue(widget, packed)
    if not packed then return nil, false end
    if widget.kind == "keybind" then
        widget.key = asNumber(packed.key, widget.key)
        return packed.active == true, true
    end
    if widget.kind == "menu_keybind" then
        local key = asNumber(packed.key, asNumber(packed.value, widget.key))
        return key, key ~= nil
    end
    if widget.kind == "color_picker" then
        if type(packed.r) == "number" and type(packed.g) == "number" and type(packed.b) == "number" then
            return Color3.new(packed.r, packed.g, packed.b), true
        end
        if isColor(packed.value) then
            return packed.value, true
        end
        return nil, false
    end
    if widget.kind == "input_text" then
        if packed.value ~= nil then
            return asText(packed.value), true
        end
        return asText(packed), true
    end
    if widget.kind == "combo" then
        local index = asNumber(packed.value, asNumber(packed, nil))
        return index, index ~= nil
    end
    if packed.value ~= nil then
        return packed.value, true
    end
    return packed, true
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function makeText(owner, text, size, color, z)
    return createDrawing(owner, "Text", {
        Text = asText(text),
        Size = size or 13,
        Font = FONT,
        Color = color or owner.theme.text,
        Center = false,
        Outline = false,
        Visible = true,
        ZIndex = z or 54,
        Position = Vector2_new(0, 0),
    })
end

local function makeBox(owner, color, z)
    return createDrawing(owner, "Square", {
        Color = color,
        Filled = true,
        Visible = true,
        Thickness = 1,
        ZIndex = z or 50,
        Position = Vector2_new(0, 0),
        Size = Vector2_new(1, 1),
    })
end

local function makeLineBox(owner, color, z)
    return createDrawing(owner, "Square", {
        Color = color,
        Filled = false,
        Visible = true,
        Thickness = 1,
        ZIndex = z or 51,
        Position = Vector2_new(0, 0),
        Size = Vector2_new(1, 1),
    })
end

function MatchaGUI.Create(opts)
    opts = opts or {}

    local self = setmetatable({}, Window)
    self.title = asText(opts.Title or opts.title)
    if self.title == "" then
        self.title = "Matcha GUI"
    end
    self.x = opts.X or opts.x or 260
    self.y = opts.Y or opts.y or 160
    self.w = opts.Width or opts.width or 485
    self.h = opts.Height or opts.height or 630
    self.toggleKey = opts.ToggleKey or opts.toggleKey or 0x70
    self.configFolder = opts.ConfigFolder or opts.configFolder or joinPath("MatchaGUI", cleanName(self.title))
    self.visible = opts.Visible
    if self.visible == nil then self.visible = true end

    self.theme = copyTheme(opts.Theme or opts.theme)
    self._drawings = {}
    self._tabs = {}
    self._values = {}
    self._widgetsById = {}
    self._activeTab = nil
    self._mouse = {
        x = 0,
        y = 0,
        px = 0,
        py = 0,
        down = false,
        clicked = false,
        released = false,
        rightDown = false,
        rightClicked = false,
        rightReleased = false,
    }
    self._dragging = false
    self._dragOffsetX = 0
    self._dragOffsetY = 0
    self._activeSlider = nil
    self._activeText = nil
    self._activeCombo = nil
    self._listeningBind = nil
    self._textLastKeys = {}
    self._lastToggleKey = false
    self._running = false
    self._connection = nil
    self._destroyed = false
    self._notifications = {}
    self._notifyDrawings = {}

    self.shadow = makeBox(self, self.theme.shadow, 45)
    self.root = makeBox(self, self.theme.bg, 50)
    self.border = makeLineBox(self, self.theme.stroke, 51)
    self.innerBorder = makeLineBox(self, self.theme.stroke2, 52)
    self.header = makeBox(self, self.theme.panel, 52)
    self.accent = makeBox(self, self.theme.accent, 53)
    self.body = makeBox(self, self.theme.panel, 50)
    self.bodyBorder = makeLineBox(self, self.theme.stroke2, 51)
    self.titleText = makeText(self, self.title, 15, self.theme.text, 54)
    self.titleText.Font = FONT_BOLD

    return self
end

function Window:Tab(name)
    local tab = setmetatable({}, Tab)
    tab.window = self
    tab.name = name or ("Tab " .. tostring(#self._tabs + 1))
    tab.sections = {}
    tab.button = makeBox(self, self.theme.panel2, 55)
    tab.label = makeText(self, tab.name, 13, self.theme.muted, 56)
    tab.marker = makeBox(self, self.theme.accent, 57)

    table.insert(self._tabs, tab)
    if not self._activeTab then
        self._activeTab = tab
    end
    return tab
end

function Window:SetTab(nameOrIndex)
    for i, tab in ipairs(self._tabs) do
        if tab.name == nameOrIndex or i == nameOrIndex then
            self._activeTab = tab
            return true
        end
    end
    return false
end

function Tab:Section(name, side)
    local section = setmetatable({}, Section)
    section.tab = self
    section.window = self.window
    section.name = asText(name)
    if section.name == "" then
        section.name = "Section"
    end
    section.side = side == "Right" and "Right" or "Left"
    section.widgets = {}
    section.box = makeBox(self.window, self.window.theme.panel, 50)
    section.border = makeLineBox(self.window, self.window.theme.accent, 51)
    section.titleBack = makeBox(self.window, self.window.theme.panel, 52)
    section.header = makeText(self.window, section.name, 13, self.window.theme.text, 54)
    section.header.Font = FONT_BOLD
    section.accent = makeBox(self.window, self.window.theme.accent, 53)

    table.insert(self.sections, section)
    return section
end

function Section:_addWidget(kind, id, label, opts)
    opts = opts or {}
    id = id or (self.name .. "_" .. kind .. "_" .. tostring(#self.widgets + 1))

    local win = self.window
    local widget = {
        kind = kind,
        id = id,
        label = asText(label),
        section = self,
        window = win,
        callback = opts.callback,
        value = opts.value,
        skipConfig = opts.skipConfig == true,
        min = opts.min,
        max = opts.max,
        step = opts.step,
        format = opts.format,
        mode = opts.mode,
        items = opts.items or {},
        key = opts.key,
        lastKeyDown = false,
        listening = false,
        paletteIndex = opts.paletteIndex or 1,
        x = 0,
        y = 0,
        w = 1,
        h = opts.h or 20,
    }

    if widget.label == "" then
        widget.label = id
    end

    widget.bg = makeBox(win, win.theme.panel2, 52)
    widget.labelText = makeText(win, widget.label, 13, win.theme.text, 54)

    if kind == "toggle" then
        widget.track = makeBox(win, win.theme.stroke, 53)
        widget.knob = makeBox(win, win.theme.muted, 54)
    elseif kind == "slider" then
        widget.h = 38
        widget.valueText = makeText(win, "", 12, win.theme.muted, 54)
        widget.track = makeBox(win, win.theme.stroke, 53)
        widget.fill = makeBox(win, win.theme.accent, 54)
        widget.knob = makeBox(win, win.theme.text, 55)
        widget.editBox = makeBox(win, win.theme.control2, 56)
        widget.editBorder = makeLineBox(win, win.theme.accent, 57)
        widget.editBox.Visible = false
        widget.editBorder.Visible = false
    elseif kind == "button" then
        widget.border = makeLineBox(win, win.theme.stroke, 54)
        widget.labelText.Center = true
    elseif kind == "keybind" or kind == "menu_keybind" then
        widget.valueText = makeText(win, "", 12, win.theme.muted, 54)
        widget.keyBox = makeBox(win, win.theme.bg, 53)
        widget.keyBorder = makeLineBox(win, win.theme.stroke, 54)
    elseif kind == "input_text" then
        widget.h = 38
        widget.inputBox = makeBox(win, win.theme.control, 53)
        widget.inputBorder = makeLineBox(win, win.theme.stroke, 54)
        widget.valueText = makeText(win, "", 12, win.theme.text, 55)
    elseif kind == "combo" then
        widget.h = 38
        widget.open = false
        widget.comboBox = makeBox(win, win.theme.control, 53)
        widget.comboBorder = makeLineBox(win, win.theme.stroke, 54)
        widget.valueText = makeText(win, "", 12, win.theme.text, 72)
        widget.arrowText = makeText(win, "v", 12, win.theme.muted, 72)
        widget.arrowText.Center = true
        widget.optionBoxes = {}
        widget.optionTexts = {}
        for i = 1, 6 do
            widget.optionBoxes[i] = makeBox(win, win.theme.control2, 70)
            widget.optionTexts[i] = makeText(win, "", 12, win.theme.text, 72)
        end
    elseif kind == "color_picker" then
        widget.swatch = makeBox(win, opts.color or win.theme.white, 53)
        widget.swatchBorder = makeLineBox(win, win.theme.stroke, 54)
    elseif kind == "text" then
        widget.h = opts.h or 18
        widget.bg.Visible = false
        widget.labelText.Color = win.theme.muted
    end

    table.insert(self.widgets, widget)
    win._widgetsById[id] = widget
    win._values[id] = widget.value

    if kind == "combo" then
        function widget:SetItems(items)
            self.items = normalizeItems(items)
            if type(self.value) ~= "number" then
                self.value = 0
            end
            if #self.items <= 0 then
                self.value = -1
            elseif self.value == nil or self.value < 0 then
                self.value = 0
            elseif self.value > #self.items - 1 then
                self.value = #self.items - 1
            end
            self.window._values[self.id] = self.value
            return self
        end

        function widget:GetItems()
            return self.items
        end

        function widget:GetText()
            if not self.items then return "" end
            return asText(self.items[(self.value or -1) + 1])
        end

        function widget:SetValue(index)
            if type(index) ~= "number" then
                index = 0
            end
            if #self.items <= 0 then
                self.value = -1
            else
                self.value = clamp(index or 0, 0, #self.items - 1)
            end
            self.window._values[self.id] = self.value
            if self.callback then
                self.callback(self.value, self:GetText(), self)
            end
            return self
        end

        widget:SetItems(widget.items)
    end
    return widget
end

function Section:Toggle(id, label, default, callback)
    return self:_addWidget("toggle", id, label, {
        value = default == true,
        callback = callback,
    })
end

function Section:SliderInt(id, label, minValue, maxValue, default, callback)
    return self:_addWidget("slider", id, label, {
        min = minValue or 0,
        max = maxValue or 100,
        value = default or minValue or 0,
        step = 1,
        format = "%d",
        callback = callback,
    })
end

function Section:SliderFloat(id, label, minValue, maxValue, default, format, callback)
    return self:_addWidget("slider", id, label, {
        min = minValue or 0,
        max = maxValue or 1,
        value = default or minValue or 0,
        step = 1 / 100,
        format = format or "%.2f",
        callback = callback,
    })
end

function Section:Combo(id, label, items, defaultIndex, callback, options)
    options = options or {}
    return self:_addWidget("combo", id, label, {
        value = defaultIndex or 0,
        items = items or {},
        callback = callback,
        skipConfig = options.skipConfig == true,
    })
end

function Section:Dropdown(id, label, items, defaultIndex, callback, options)
    return self:Combo(id, label, items, defaultIndex, callback, options)
end

function Section:Button(label, callback)
    return self:_addWidget("button", nil, label, {
        value = false,
        callback = callback,
    })
end

function Section:Keybind(id, label, defaultKey, mode, callback)
    return self:_addWidget("keybind", id, label, {
        value = false,
        key = defaultKey or 0x46,
        mode = mode or "toggle",
        callback = callback,
    })
end

function Section:MenuKeybind(id, label, defaultKey, callback)
    local key = defaultKey or self.window.toggleKey or 0x70
    self.window:SetMenuKey(key)

    return self:_addWidget("menu_keybind", id, label or "Menu key", {
        value = key,
        key = key,
        mode = "menu",
        callback = callback,
    })
end

function Section:InputText(id, label, default, callback, options)
    options = options or {}
    return self:_addWidget("input_text", id, label, {
        value = asText(default),
        callback = callback,
        skipConfig = options.skipConfig == true,
    })
end

function Section:ColorPicker(id, label, r, g, b, a, callback)
    local color = Color3_fromRGB(r or 255, g or 255, b or 255)
    return self:_addWidget("color_picker", id, label, {
        value = color,
        color = color,
        callback = callback,
    })
end

function Section:Text(text)
    return self:_addWidget("text", nil, text, {
        value = asText(text),
    })
end

function Window:GetValue(id)
    local widget = self._widgetsById[id]
    if widget then return widget.value end
    return self._values[id]
end

function Window:SetValue(id, value)
    local widget = self._widgetsById[id]
    if not widget then
        self._values[id] = value
        return false
    end
    if widget.kind == "menu_keybind" then
        self:SetMenuKey(value)
        if widget.callback then
            widget.callback(value, widget)
        end
        return true
    end
    if widget.kind == "combo" then
        widget:SetValue(value)
        return true
    end
    if widget.kind == "input_text" then
        value = asText(value)
    end
    widget.value = value
    self._values[id] = value
    if widget.callback then
        widget.callback(value, widget)
    end
    return true
end

function Window:GetConfigData()
    local data = {
        version = 1,
        values = {},
    }

    for id, widget in pairs(self._widgetsById) do
        local packed = encodeValue(widget)
        if packed ~= nil then
            data.values[id] = packed
        end
    end

    return data
end

function Window:ApplyConfigData(data)
    if not data or not data.values then return false, "invalid config" end

    for id, packed in pairs(data.values) do
        local widget = self._widgetsById[id]
        if widget and not widget.skipConfig then
            local value, ok = decodeValue(widget, packed)
            if ok then
                if widget.kind == "menu_keybind" then
                    self:SetMenuKey(value)
                    if widget.callback then
                        widget.callback(value, widget)
                    end
                elseif widget.kind == "combo" then
                    widget:SetValue(value)
                else
                    widget.value = value
                    self._values[id] = value
                    if widget.kind == "keybind" and packed.key then
                        widget.key = packed.key
                    end
                    if widget.callback then
                        widget.callback(value, widget)
                    end
                end
            end
        end
    end

    return true
end

function Window:ConfigPath(name)
    return joinPath(self.configFolder, cleanName(name) .. ".json")
end

function Window:SaveConfig(name)
    name = cleanName(name)
    local okFolder, folderErr = ensureFolderPath(self.configFolder)
    if not okFolder then return false, folderErr end
    if not writefile then return false, "writefile unavailable" end

    local http = getHttpService()
    if not http then return false, "HttpService unavailable" end

    local okEncode, encoded = pcall(function()
        return http:JSONEncode(self:GetConfigData())
    end)
    if not okEncode or not encoded then return false, "encode failed" end

    local okWrite = pcall(writefile, self:ConfigPath(name), encoded)
    if not okWrite then return false, "write failed" end
    return true, name
end

function Window:LoadConfig(name)
    name = cleanName(name)
    if not readfile or not isfile then return false, "readfile unavailable" end

    local path = self:ConfigPath(name)
    local okExists, exists = pcall(isfile, path)
    if not okExists or exists ~= true then return false, "config not found" end

    local okRead, raw = pcall(readfile, path)
    if not okRead or not raw then return false, "read failed" end

    local http = getHttpService()
    if not http then return false, "HttpService unavailable" end

    local okDecode, data = pcall(function()
        return http:JSONDecode(raw)
    end)
    if not okDecode or not data then return false, "decode failed" end

    return self:ApplyConfigData(data)
end

function Window:DeleteConfig(name)
    name = cleanName(name)
    if not delfile or not isfile then return false, "delfile unavailable" end

    local path = self:ConfigPath(name)
    local okExists, exists = pcall(isfile, path)
    if okExists and exists == true then
        local okDelete = pcall(delfile, path)
        if okDelete then return true, name end
        return false, "delete failed"
    end

    return false, "config not found"
end

function Window:ListConfigs()
    local out = {}
    ensureFolderPath(self.configFolder)
    if not listfiles then return out end

    local okList, files = pcall(listfiles, self.configFolder)
    if okList and files then
        for _, path in ipairs(files) do
            local name = fileName(path)
            if name:match("%.json$") or name:match("%.cfg$") then
                table.insert(out, stripExt(name))
            end
        end
    end

    table.sort(out)
    return out
end

function Window:IsKeyActive(id)
    local widget = self._widgetsById[id]
    if not widget or widget.kind ~= "keybind" then return false end
    return widget.value == true
end

function Window:SetMenuKey(vk)
    vk = asNumber(vk, nil)
    if not vk then return false end
    self.toggleKey = vk
    self._lastToggleKey = readKey(vk)

    for _, tab in ipairs(self._tabs) do
        for _, section in ipairs(tab.sections) do
            for _, widget in ipairs(section.widgets) do
                if widget.kind == "menu_keybind" then
                    widget.key = vk
                    widget.value = vk
                    self._values[widget.id] = vk
                end
            end
        end
    end

    return true
end

function Window:SetVisible(visible)
    self.visible = visible == true
    self:_applyVisibility()
end

function Window:Toggle()
    self.visible = not self.visible
    self:_applyVisibility()
end

function Window:Start()
    if self._destroyed then return self end
    if self._running then return self end
    self._running = true
    if self._connection then return self end

    local ok, rs = pcall(function() return game:GetService("RunService") end)
    if ok and rs and rs.RenderStepped then
        self._connection = rs.RenderStepped:Connect(function(dt)
            if self._running then
                self:Step(dt)
            end
        end)
    else
        task.spawn(function()
            while self._running do
                self:Step(0)
                task.wait()
            end
        end)
    end

    return self
end

function Window:Stop()
    self._running = false
end

function Window:Disconnect()
    self._running = false
    if self._connection then
        local conn = self._connection
        self._connection = nil
        task.defer(function()
            pcall(function() conn:Disconnect() end)
        end)
    end
end

function Window:Destroy()
    self._running = false
    self._destroyed = true
    if self._connection then
        local conn = self._connection
        self._connection = nil
        task.defer(function()
            pcall(function() conn:Disconnect() end)
        end)
    end
    if self._notifications then
        table.clear(self._notifications)
    end
    if self._notifyDrawings then
        removeAll(self._notifyDrawings)
    end
    removeAll(self._drawings)
end

function Window:_readMouse()
    local mx, my = self._mouse.x, self._mouse.y

    local ok, player = pcall(function()
        local players = game:GetService("Players")
        return players and players.LocalPlayer
    end)

    if ok and player then
        local okMouse, mouse = pcall(function() return player:GetMouse() end)
        if okMouse and mouse then
            mx = mouse.X or mx
            my = mouse.Y or my
        end
    end

    local active = robloxActive()
    local down = false
    local rightDown = false
    if active then
        down = readMouseDown()
        rightDown = readMouse2Down()
    end

    local wasDown = self._mouse.down
    local wasRightDown = self._mouse.rightDown
    self._mouse.px = self._mouse.x
    self._mouse.py = self._mouse.y
    self._mouse.x = mx
    self._mouse.y = my
    self._mouse.down = down
    self._mouse.clicked = down and not wasDown
    self._mouse.released = (not down) and wasDown
    self._mouse.rightDown = rightDown
    self._mouse.rightClicked = rightDown and not wasRightDown
    self._mouse.rightReleased = (not rightDown) and wasRightDown
end

function Window:_beginSliderEdit(widget)
    if not widget or widget.kind ~= "slider" then return end

    local minValue = sliderLimits(widget)
    local value = normalizeSliderValue(widget, widget.value or minValue) or minValue

    if self._activeCombo then
        self._activeCombo.open = false
        self._activeCombo = nil
    end
    if self._listeningBind then
        self._listeningBind.listening = false
        self._listeningBind = nil
    end

    self._activeSlider = nil
    self._activeText = widget
    self._textLastKeys = {}
    widget.editText = formatSliderValue(widget, value)
    widget.editInvalid = false
end

function Window:_clearSliderEdit(widget)
    if widget and widget.kind == "slider" then
        widget.editText = nil
        widget.editInvalid = false
    end
    if self._activeText == widget then
        self._activeText = nil
    end
    self._textLastKeys = {}
end

function Window:_handleHotkeys()
    local active = robloxActive()
    local down = false
    if active then
        down = readKey(self.toggleKey)
    end
    if down and not self._lastToggleKey and not self._listeningBind and not self._activeText then
        self:Toggle()
    end
    self._lastToggleKey = down

    if not active then return end

    if self._activeText then
        local widget = self._activeText

        if widget.kind == "slider" then
            local changed = false
            local value = asText(widget.editText)

            for _, vk in ipairs(KEY_SCAN) do
                local keyDown = readKey(vk)
                local wasDown = self._textLastKeys[vk] == true
                if keyDown and not wasDown then
                    if vk == 0x0D then
                        local ok = applySliderValue(self, widget, tonumber(value))
                        if ok then
                            self:_clearSliderEdit(widget)
                            break
                        end
                        widget.editInvalid = true
                    elseif vk == 0x1B then
                        self:_clearSliderEdit(widget)
                        break
                    elseif vk == 0x08 then
                        if #value > 0 then
                            value = string.sub(value, 1, #value - 1)
                            changed = true
                        end
                    elseif vk == 0x2E then
                        value = ""
                        changed = true
                    else
                        local ch = numericCharFromKey(vk)
                        if ch and #value < 18 then
                            if ch == "." then
                                if not string.find(value, ".", 1, true) then
                                    value = value .. ch
                                    changed = true
                                end
                            elseif ch == "-" or ch == "+" then
                                if #value == 0 then
                                    value = value .. ch
                                    changed = true
                                end
                            else
                                value = value .. ch
                                changed = true
                            end
                        end
                    end
                end
                self._textLastKeys[vk] = keyDown
            end

            if changed then
                widget.editText = value
                widget.editInvalid = false
            end
            releaseTextBlockKeys()
            return
        end

        local changed = false
        local value = asText(widget.value)

        for _, vk in ipairs(KEY_SCAN) do
            local keyDown = readKey(vk)
            local wasDown = self._textLastKeys[vk] == true
            if keyDown and not wasDown then
                if vk == 0x0D or vk == 0x1B then
                    self._activeText = nil
                    self._textLastKeys = {}
                    break
                elseif vk == 0x08 then
                    if #value > 0 then
                        value = string.sub(value, 1, #value - 1)
                        changed = true
                    end
                else
                    local ch = charFromKey(vk)
                    if ch and #value < 64 then
                        value = value .. ch
                        changed = true
                    end
                end
            end
            self._textLastKeys[vk] = keyDown
        end

        if changed then
            widget.value = value
            self._values[widget.id] = value
            if widget.callback then
                widget.callback(value, widget)
            end
        end
        releaseTextBlockKeys()
        return
    end

    if self._listeningBind then
        local target = self._listeningBind
        for _, vk in ipairs(KEY_SCAN) do
            if readKey(vk) then
                if target.kind == "menu_keybind" then
                    self:SetMenuKey(vk)
                    if target.callback then
                        target.callback(vk, target)
                    end
                else
                    target.key = vk
                end
                target.listening = false
                self._listeningBind = nil
                break
            end
        end
    end

    for _, tab in ipairs(self._tabs) do
        for _, section in ipairs(tab.sections) do
            for _, widget in ipairs(section.widgets) do
                if widget.kind == "keybind" and widget.key then
                    local keyDown = readKey(widget.key)
                    local old = widget.value

                    if widget.mode == "hold" then
                        widget.value = keyDown
                    elseif keyDown and not widget.lastKeyDown then
                        widget.value = not widget.value
                    end

                    if old ~= widget.value then
                        self._values[widget.id] = widget.value
                        if widget.callback then
                            widget.callback(widget.value, widget.key, widget)
                        end
                    end
                    widget.lastKeyDown = keyDown
                end
            end
        end
    end
end

function Window:_applyVisibility()
    if self.visible then return end
    for _, obj in ipairs(self._drawings) do
        setVisible(obj, false)
    end
end

function Window:_layoutShell()
    local x, y, w, h = self.x, self.y, self.w, self.h
    setVisible(self.shadow, false)
    setVisible(self.root, self.visible)
    setVisible(self.border, self.visible)
    setVisible(self.innerBorder, self.visible)
    setVisible(self.header, self.visible)
    setVisible(self.accent, self.visible)
    setVisible(self.body, self.visible)
    setVisible(self.bodyBorder, self.visible)
    setVisible(self.titleText, self.visible)

    self.root.Position = Vector2_new(x, y)
    self.root.Size = Vector2_new(w, h)
    self.root.Color = self.theme.bg

    self.border.Position = Vector2_new(x, y)
    self.border.Size = Vector2_new(w, h)
    self.border.Color = self.theme.stroke

    self.innerBorder.Position = Vector2_new(x + 3, y + 3)
    self.innerBorder.Size = Vector2_new(w - 6, h - 6)
    self.innerBorder.Color = self.theme.stroke2

    self.header.Position = Vector2_new(x + 4, y + 4)
    self.header.Size = Vector2_new(w - 8, 22)
    self.header.Color = self.theme.panel

    self.accent.Position = Vector2_new(x + 8, y + 24)
    self.accent.Size = Vector2_new(w - 16, 1)
    self.accent.Color = self.theme.accent

    self.body.Position = Vector2_new(x + 8, y + 52)
    self.body.Size = Vector2_new(w - 16, h - 60)
    self.body.Color = self.theme.panel

    self.bodyBorder.Position = Vector2_new(x + 7, y + 51)
    self.bodyBorder.Size = Vector2_new(w - 14, h - 58)
    self.bodyBorder.Color = self.theme.stroke2

    self.titleText.Text = self.title
    self.titleText.Size = 13
    self.titleText.Color = self.theme.text
    self.titleText.Position = Vector2_new(x + 12, y + 7)
end

function Window:_layoutTabs()
    local count = #self._tabs
    if count <= 0 then return end

    local pad = 8
    local gap = 0
    local x = self.x + pad
    local y = self.y + 26
    local available = self.w - pad * 2 - gap * (count - 1)
    local tabW = math_floor(available / count)
    local mx, my = self._mouse.x, self._mouse.y

    for i, tab in ipairs(self._tabs) do
        local tx = x + (i - 1) * (tabW + gap)
        local hover = inside(mx, my, tx, y, tabW, 24)
        if self.visible and self._mouse.clicked and hover then
            self._activeTab = tab
        end

        local active = self._activeTab == tab
        setVisible(tab.button, self.visible)
        setVisible(tab.label, self.visible)
        setVisible(tab.marker, self.visible)

        tab.button.Position = Vector2_new(tx, y)
        tab.button.Size = Vector2_new(tabW, 24)
        tab.button.Color = self.theme.panel
        tab.label.Text = tab.name
        tab.label.Color = active and self.theme.text or self.theme.muted
        tab.label.Center = true
        tab.label.Size = 13
        tab.label.Position = Vector2_new(tx + math_floor(tabW / 2), y + 12)
        tab.marker.Position = Vector2_new(tx + 2, y + 23)
        tab.marker.Size = Vector2_new(tabW - 4, 1)
        tab.marker.Color = active and self.theme.accent or self.theme.panel
    end
end

function Window:_layoutSections()
    local tab = self._activeTab
    local bodyX = self.x + 16
    local bodyY = self.y + 66
    local bodyW = self.w - 32
    local gap = 8
    local colW = math_floor((bodyW - gap) / 2)
    local nextY = { Left = bodyY, Right = bodyY }

    for _, otherTab in ipairs(self._tabs) do
        for _, section in ipairs(otherTab.sections) do
            local activeTab = otherTab == tab and self.visible
            local side = section.side
            local sx = bodyX
            if side == "Right" then
                sx = bodyX + colW + gap
            end
            local sy = nextY[side]
            local sectionH = 13

            for _, widget in ipairs(section.widgets) do
                sectionH = sectionH + widget.h
            end
            sectionH = sectionH + 8

            section.box.Position = Vector2_new(sx, sy)
            section.box.Size = Vector2_new(colW, sectionH)
            section.box.Color = self.theme.panel
            section.border.Position = Vector2_new(sx, sy)
            section.border.Size = Vector2_new(colW, sectionH)
            section.border.Color = self.theme.accent
            section.titleBack.Position = Vector2_new(sx + 12, sy - 2)
            section.titleBack.Size = Vector2_new((#section.name * 8) + 12, 5)
            section.titleBack.Color = self.theme.panel
            section.header.Text = section.name
            section.header.Size = 13
            section.header.Position = Vector2_new(sx + 18, sy - 7)
            section.accent.Position = Vector2_new(sx + 1, sy + 1)
            section.accent.Size = Vector2_new(colW - 2, 1)
            section.accent.Color = self.theme.stroke

            setVisible(section.box, activeTab)
            setVisible(section.border, activeTab)
            setVisible(section.titleBack, activeTab)
            setVisible(section.header, activeTab)
            setVisible(section.accent, activeTab)

            local wy = sy + 8
            for _, widget in ipairs(section.widgets) do
                widget.x = sx + 6
                widget.y = wy
                widget.w = colW - 12
                self:_layoutWidget(widget, activeTab)
                wy = wy + widget.h
            end

            if otherTab == tab then
                nextY[side] = nextY[side] + sectionH + gap + 6
            end
        end
    end
end

function Window:_setWidgetVisible(widget, visible)
    local showBg = visible and (widget.kind == "button" or widget.kind == "slider")
    setVisible(widget.bg, showBg)
    setVisible(widget.border, visible)
    setVisible(widget.labelText, visible)
    setVisible(widget.track, visible)
    setVisible(widget.knob, visible)
    setVisible(widget.valueText, visible)
    setVisible(widget.fill, visible)
    setVisible(widget.editBox, false)
    setVisible(widget.editBorder, false)
    setVisible(widget.keyBox, visible)
    setVisible(widget.keyBorder, visible)
    setVisible(widget.inputBox, visible)
    setVisible(widget.inputBorder, visible)
    setVisible(widget.comboBox, visible)
    setVisible(widget.comboBorder, visible)
    setVisible(widget.arrowText, visible)
    setVisible(widget.swatch, visible)
    setVisible(widget.swatchBorder, visible)
    if widget.optionBoxes then
        local showOptions = visible and widget.open == true
        for _, obj in ipairs(widget.optionBoxes) do
            setVisible(obj, showOptions)
        end
        for _, obj in ipairs(widget.optionTexts) do
            setVisible(obj, showOptions)
        end
    end
end

function Window:_layoutWidget(widget, visible)
    self:_setWidgetVisible(widget, visible)
    if not visible then return end

    local mx, my = self._mouse.x, self._mouse.y
    local hover = inside(mx, my, widget.x, widget.y, widget.w, widget.h)
    local clicked = self._mouse.clicked and hover
    local theme = self.theme

    if widget.bg then
        widget.bg.Position = Vector2_new(widget.x, widget.y)
        widget.bg.Size = Vector2_new(widget.w, widget.h)
        widget.bg.Color = hover and theme.hover or theme.panel2
    end

    if widget.kind == "toggle" then
        if clicked then
            widget.value = not widget.value
            self._values[widget.id] = widget.value
            if widget.callback then
                widget.callback(widget.value, widget)
            end
        end

        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Position = Vector2_new(widget.x + 22, widget.y + 4)
        widget.labelText.Color = widget.value and theme.text or theme.muted

        local tx = widget.x + 4
        local ty = widget.y + 5
        widget.track.Position = Vector2_new(tx, ty)
        widget.track.Size = Vector2_new(12, 12)
        widget.track.Color = theme.stroke

        widget.knob.Position = Vector2_new(tx + 2, ty + 2)
        widget.knob.Size = Vector2_new(8, 8)
        widget.knob.Color = widget.value and theme.accent or theme.control
    elseif widget.kind == "slider" then
        local minValue, maxValue = sliderLimits(widget)

        local trackX = widget.x + 4
        local trackY = widget.y + 24
        local trackW = widget.w - 8
        local trackH = 9
        local rowHit = inside(mx, my, widget.x, widget.y, widget.w, widget.h)
        local editingSlider = self._activeText == widget

        if self._mouse.rightClicked and rowHit then
            self:_beginSliderEdit(widget)
            editingSlider = true
        elseif self._mouse.clicked and editingSlider and not rowHit then
            self:_clearSliderEdit(widget)
            editingSlider = false
        end

        if self._mouse.clicked and not editingSlider and inside(mx, my, trackX, trackY - 6, trackW, 18) then
            self._activeSlider = widget
        end
        if self._mouse.released and self._activeSlider == widget then
            self._activeSlider = nil
        end
        if self._activeSlider == widget and self._mouse.down then
            local pct = clamp((mx - trackX) / trackW, 0, 1)
            local raw = minValue + (maxValue - minValue) * pct
            applySliderValue(self, widget, raw)
        end

        local value = normalizeSliderValue(widget, widget.value or minValue) or minValue
        local pct = (value - minValue) / (maxValue - minValue)
        local fillW = math_floor(trackW * pct)
        local editW = 72
        local editX = widget.x + widget.w - editW - 4
        local displayValue = formatSliderValue(widget, value)

        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Position = Vector2_new(widget.x + 4, widget.y + 3)
        widget.labelText.Color = theme.text
        widget.valueText.Size = 12
        widget.valueText.ZIndex = editingSlider and 58 or 54
        if editingSlider then
            widget.valueText.Text = asText(widget.editText) .. "|"
            widget.valueText.Color = widget.editInvalid and theme.danger or theme.text
            widget.valueText.Position = Vector2_new(editX + 5, widget.y + 3)
            widget.editBox.Position = Vector2_new(editX, widget.y + 1)
            widget.editBox.Size = Vector2_new(editW, 16)
            widget.editBox.Color = theme.control2
            widget.editBorder.Position = Vector2_new(editX, widget.y + 1)
            widget.editBorder.Size = Vector2_new(editW, 16)
            widget.editBorder.Color = widget.editInvalid and theme.danger or theme.accent
            setVisible(widget.editBox, true)
            setVisible(widget.editBorder, true)
        else
            widget.valueText.Text = displayValue
            widget.valueText.Color = theme.muted
            widget.valueText.Position = Vector2_new(widget.x + widget.w - 54, widget.y + 3)
            setVisible(widget.editBox, false)
            setVisible(widget.editBorder, false)
        end

        widget.track.Position = Vector2_new(trackX, trackY)
        widget.track.Size = Vector2_new(trackW, trackH)
        widget.track.Color = theme.stroke2
        widget.fill.Position = Vector2_new(trackX + 1, trackY + 1)
        widget.fill.Size = Vector2_new(math_max(fillW - 2, 1), trackH - 2)
        widget.fill.Color = theme.accent
        widget.knob.Position = Vector2_new(trackX + fillW - 2, trackY - 2)
        widget.knob.Size = Vector2_new(4, trackH + 4)
        widget.knob.Color = theme.text
    elseif widget.kind == "button" then
        if clicked and widget.callback then
            widget.callback(widget)
        end
        widget.bg.Position = Vector2_new(widget.x + 4, widget.y + 2)
        widget.bg.Size = Vector2_new(widget.w - 8, 17)
        widget.bg.Color = hover and theme.hover or theme.control
        widget.border.Position = Vector2_new(widget.x + 4, widget.y + 2)
        widget.border.Size = Vector2_new(widget.w - 8, 17)
        widget.border.Color = theme.stroke
        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Color = theme.text
        widget.labelText.Position = Vector2_new(widget.x + math_floor(widget.w / 2), widget.y + 10)
    elseif widget.kind == "keybind" or widget.kind == "menu_keybind" then
        if clicked then
            if self._listeningBind then
                self._listeningBind.listening = false
            end
            self._listeningBind = widget
            widget.listening = true
        end

        local boxW = 70
        local boxX = widget.x + widget.w - boxW - 4
        local boxY = widget.y + 3
        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Color = theme.text
        widget.labelText.Position = Vector2_new(widget.x + 2, widget.y + 4)
        widget.keyBox.Position = Vector2_new(boxX, boxY)
        widget.keyBox.Size = Vector2_new(boxW, 14)
        widget.keyBox.Color = widget.listening and theme.hover or theme.control2
        widget.keyBorder.Position = Vector2_new(boxX, boxY)
        widget.keyBorder.Size = Vector2_new(boxW, 14)
        if widget.kind == "menu_keybind" then
            widget.keyBorder.Color = widget.listening and theme.accent or theme.stroke
        else
            widget.keyBorder.Color = widget.value and theme.accent or theme.stroke
        end
        widget.valueText.Text = widget.listening and "..." or keyName(widget.key)
        widget.valueText.Center = true
        widget.valueText.Size = 12
        widget.valueText.Position = Vector2_new(boxX + math_floor(boxW / 2), boxY + 7)
        if widget.kind == "menu_keybind" then
            widget.valueText.Color = widget.listening and theme.accent2 or theme.muted
        else
            widget.valueText.Color = widget.value and theme.accent2 or theme.muted
        end
    elseif widget.kind == "input_text" then
        local inputX = widget.x + 2
        local inputY = widget.y + 18
        local inputW = widget.w - 4
        local activeText = self._activeText == widget

        if clicked or (self._mouse.clicked and inside(mx, my, inputX, inputY, inputW, 17)) then
            self._activeText = widget
            self._textLastKeys = {}
        elseif self._mouse.clicked and activeText then
            self._activeText = nil
            self._textLastKeys = {}
        end

        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Color = theme.text
        widget.labelText.Position = Vector2_new(widget.x + 2, widget.y + 1)
        widget.inputBox.Position = Vector2_new(inputX, inputY)
        widget.inputBox.Size = Vector2_new(inputW, 17)
        widget.inputBox.Color = activeText and theme.hover or theme.control
        widget.inputBorder.Position = Vector2_new(inputX, inputY)
        widget.inputBorder.Size = Vector2_new(inputW, 17)
        widget.inputBorder.Color = activeText and theme.accent or theme.stroke
        widget.valueText.Text = asText(widget.value)
        widget.valueText.Center = false
        widget.valueText.Size = 12
        widget.valueText.Color = theme.text
        widget.valueText.Position = Vector2_new(inputX + 4, inputY + 2)
    elseif widget.kind == "combo" then
        local comboX = widget.x + 2
        local comboY = widget.y + 18
        local comboW = widget.w - 4
        local comboH = 17

        if self._mouse.clicked then
            if inside(mx, my, comboX, comboY, comboW, comboH) then
                if self._activeCombo and self._activeCombo ~= widget then
                    self._activeCombo.open = false
                end
                widget.open = not widget.open
                self._activeCombo = widget.open and widget or nil
            elseif widget.open then
                local picked = false
                local maxRows = math_min(#widget.items, #widget.optionBoxes)
                for i = 1, maxRows do
                    local oy = comboY + comboH + (i - 1) * 17
                    if inside(mx, my, comboX, oy, comboW, 17) then
                        widget:SetValue(i - 1)
                        picked = true
                        break
                    end
                end
                widget.open = false
                self._activeCombo = nil
                if not picked and not inside(mx, my, widget.x, widget.y, widget.w, widget.h + maxRows * 17) then
                    widget.open = false
                end
            elseif self._activeCombo then
                self._activeCombo.open = false
                self._activeCombo = nil
            end
        end

        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Color = theme.text
        widget.labelText.Position = Vector2_new(widget.x + 2, widget.y + 1)
        widget.comboBox.Position = Vector2_new(comboX, comboY)
        widget.comboBox.Size = Vector2_new(comboW, comboH)
        widget.comboBox.Color = widget.open and theme.hover or theme.control
        widget.comboBorder.Position = Vector2_new(comboX, comboY)
        widget.comboBorder.Size = Vector2_new(comboW, comboH)
        widget.comboBorder.Color = widget.open and theme.accent or theme.stroke
        widget.valueText.Text = widget:GetText()
        widget.valueText.Center = false
        widget.valueText.Size = 12
        widget.valueText.Color = theme.text
        widget.valueText.Position = Vector2_new(comboX + 4, comboY + 2)
        widget.arrowText.Text = widget.open and "^" or "v"
        widget.arrowText.Size = 12
        widget.arrowText.Color = theme.muted
        widget.arrowText.Position = Vector2_new(comboX + comboW - 9, comboY + 8)

        local maxRows = math_min(#widget.items, #widget.optionBoxes)
        for i = 1, #widget.optionBoxes do
            local rowVisible = widget.open and i <= maxRows
            setVisible(widget.optionBoxes[i], rowVisible)
            setVisible(widget.optionTexts[i], rowVisible)
            if rowVisible then
                local oy = comboY + comboH + (i - 1) * 17
                local rowHover = inside(mx, my, comboX, oy, comboW, 17)
                widget.optionBoxes[i].Position = Vector2_new(comboX, oy)
                widget.optionBoxes[i].Size = Vector2_new(comboW, 17)
                widget.optionBoxes[i].Color = rowHover and theme.hover or theme.control2
                widget.optionTexts[i].Text = asText(widget.items[i])
                widget.optionTexts[i].Center = false
                widget.optionTexts[i].Size = 12
                widget.optionTexts[i].Color = (widget.value == i - 1) and theme.accent or theme.text
                widget.optionTexts[i].Position = Vector2_new(comboX + 4, oy + 2)
            end
        end
    elseif widget.kind == "color_picker" then
        if clicked then
            widget.paletteIndex = widget.paletteIndex + 1
            if widget.paletteIndex > #COLOR_PALETTE then
                widget.paletteIndex = 1
            end
            widget.value = COLOR_PALETTE[widget.paletteIndex]
            self._values[widget.id] = widget.value
            if widget.callback then
                widget.callback(widget.value, widget)
            end
        end

        local sw = 20
        local sh = 10
        local sx = widget.x + widget.w - sw - 6
        local sy = widget.y + 5
        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Color = theme.text
        widget.labelText.Position = Vector2_new(widget.x + 2, widget.y + 4)
        widget.swatch.Position = Vector2_new(sx, sy)
        widget.swatch.Size = Vector2_new(sw, sh)
        widget.swatch.Color = isColor(widget.value) and widget.value or theme.white
        widget.swatchBorder.Position = Vector2_new(sx, sy)
        widget.swatchBorder.Size = Vector2_new(sw, sh)
        widget.swatchBorder.Color = hover and theme.accent or theme.stroke
    elseif widget.kind == "text" then
        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Position = Vector2_new(widget.x + 2, widget.y + 3)
        widget.labelText.Color = theme.muted
    end
end

function Window:_handleDrag()
    local mx, my = self._mouse.x, self._mouse.y
    local headerHit = inside(mx, my, self.x, self.y, self.w, 26)

    if self.visible and self._mouse.clicked and headerHit then
        self._dragging = true
        self._dragOffsetX = mx - self.x
        self._dragOffsetY = my - self.y
    end

    if self._mouse.released then
        self._dragging = false
    end

    if self._dragging and self._mouse.down then
        self.x = math_floor(mx - self._dragOffsetX)
        self.y = math_floor(my - self._dragOffsetY)
    end
end

function Window:Step(dt)
    if self._destroyed then return end
    self:_readMouse()
    self:_handleHotkeys()
    self:_handleDrag()
    self:_layoutShell()
    self:_layoutTabs()
    self:_layoutSections()
    self:_applyVisibility()
    self:_stepNotifications(dt)
end

function Window:Pulse(seconds)
    local untilTime = os_clock() + (seconds or 2)
    while os_clock() < untilTime do
        self:Step(0)
        task.wait()
    end
end

local function easeOutCubic(t)
    if t <= 0 then return 0 end
    if t >= 1 then return 1 end
    local inv = 1 - t
    return 1 - inv * inv * inv
end

local function easeInCubic(t)
    if t <= 0 then return 0 end
    if t >= 1 then return 1 end
    return t * t * t
end

local function makeNotifyDrawing(window, typ, props, z)
    local obj = Drawing_new(typ)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    if z then obj.ZIndex = z end
    obj.Visible = false
    table.insert(window._notifyDrawings, obj)
    return obj
end

local function getViewportSize(window)
    local w, h = 1920, 1080
    local ok, players = pcall(function()
        return game:GetService("Players")
    end)
    if ok and players then
        local okPlayer, lp = pcall(function() return players.LocalPlayer end)
        if okPlayer and lp then
            local okCam, cam = pcall(function()
                return workspace and workspace.CurrentCamera
            end)
            if okCam and cam then
                local okSize, size = pcall(function() return cam.ViewportSize end)
                if okSize and size and size.X and size.Y then
                    return size.X, size.Y
                end
            end
        end
    end
    if window and window._lastViewport then
        return window._lastViewport.x, window._lastViewport.y
    end
    return w, h
end

function Window:_buildNotificationSlot()
    local accentBar  = makeNotifyDrawing(self, "Square", { Filled = true,  Thickness = 1 }, NOTIFY_Z_BASE + 2)
    local panel      = makeNotifyDrawing(self, "Square", { Filled = true,  Thickness = 1 }, NOTIFY_Z_BASE + 1)
    local outline    = makeNotifyDrawing(self, "Square", { Filled = false, Thickness = 1 }, NOTIFY_Z_BASE + 3)
    local progress   = makeNotifyDrawing(self, "Square", { Filled = true,  Thickness = 1 }, NOTIFY_Z_BASE + 3)
    local titleText  = makeNotifyDrawing(self, "Text",   { Size = 13, Font = FONT_BOLD, Center = false, Outline = false }, NOTIFY_Z_BASE + 4)
    local bodyText   = makeNotifyDrawing(self, "Text",   { Size = 12, Font = FONT,      Center = false, Outline = false }, NOTIFY_Z_BASE + 4)

    return {
        panel = panel,
        accent = accentBar,
        outline = outline,
        progress = progress,
        title = titleText,
        body = bodyText,
    }
end

function Window:_acquireNotificationSlot()
    if not self._notifySlots then self._notifySlots = {} end
    for _, slot in ipairs(self._notifySlots) do
        if not slot.inUse then
            slot.inUse = true
            return slot
        end
    end
    local slot = self:_buildNotificationSlot()
    slot.inUse = true
    table.insert(self._notifySlots, slot)
    return slot
end

local function releaseNotificationSlot(slot)
    if not slot then return end
    slot.inUse = false
    setVisible(slot.panel, false)
    setVisible(slot.accent, false)
    setVisible(slot.outline, false)
    setVisible(slot.progress, false)
    setVisible(slot.title, false)
    setVisible(slot.body, false)
end

function Window:Notify(message, opts)
    if self._destroyed then return end
    opts = opts or {}

    local kind = opts.type or opts.kind or "info"
    if not NOTIFY_COLORS[kind] then kind = "info" end

    local title = opts.title
    if title == nil or title == "" then
        title = NOTIFY_TITLES[kind]
    end

    local duration = tonumber(opts.duration) or 4

    local slot = self:_acquireNotificationSlot()
    local entry = {
        slot = slot,
        kind = kind,
        title = asText(title),
        message = asText(message),
        accent = opts.color or NOTIFY_COLORS[kind],
        duration = duration,
        born = os_clock(),
        dismissAt = os_clock() + duration,
        targetY = 0,
        currentY = nil,
        state = "enter",
        stateStart = os_clock(),
        alpha = 0,
        offsetX = 0,
    }

    table.insert(self._notifications, entry)
    return entry
end

function Window:NotifyInfo(message, opts)
    opts = opts or {}
    opts.type = "info"
    return self:Notify(message, opts)
end

function Window:NotifySuccess(message, opts)
    opts = opts or {}
    opts.type = "success"
    return self:Notify(message, opts)
end

function Window:NotifyWarning(message, opts)
    opts = opts or {}
    opts.type = "warning"
    return self:Notify(message, opts)
end

function Window:NotifyError(message, opts)
    opts = opts or {}
    opts.type = "error"
    return self:Notify(message, opts)
end

function Window:ClearNotifications()
    if not self._notifications then return end
    for _, entry in ipairs(self._notifications) do
        releaseNotificationSlot(entry.slot)
    end
    table.clear(self._notifications)
end

function Window:_stepNotifications(dt)
    if not self._notifications then return end

    local now = os_clock()
    local viewW, viewH = getViewportSize(self)
    self._lastViewport = self._lastViewport or {}
    self._lastViewport.x = viewW
    self._lastViewport.y = viewH

    local theme = self.theme
    local panelColor = theme.panel
    local outlineColor = theme.stroke2
    local titleColor = theme.text
    local bodyColor = theme.muted
    local trackColor = theme.stroke

    -- Update lifecycle (mark expired entries for exit, drop fully gone ones)
    local i = 1
    while i <= #self._notifications do
        local entry = self._notifications[i]

        if entry.state == "enter" and (now - entry.stateStart) >= NOTIFY_ENTER then
            entry.state = "show"
            entry.stateStart = now
        end

        if entry.state ~= "exit" and now >= entry.dismissAt then
            entry.state = "exit"
            entry.stateStart = now
        end

        if entry.state == "exit" and (now - entry.stateStart) >= NOTIFY_EXIT then
            releaseNotificationSlot(entry.slot)
            table.remove(self._notifications, i)
        else
            i = i + 1
        end
    end

    -- Layout from top-right downward
    local baseX = viewW - NOTIFY_WIDTH - NOTIFY_MARGIN
    local baseY = NOTIFY_MARGIN
    local stackY = baseY

    for index, entry in ipairs(self._notifications) do
        entry.targetY = stackY
        if entry.currentY == nil then
            entry.currentY = stackY
        else
            -- Smooth shift toward target when neighbors above leave
            local shift = (entry.targetY - entry.currentY) * 0.25
            if math.abs(shift) < 0.5 then
                entry.currentY = entry.targetY
            else
                entry.currentY = entry.currentY + shift
            end
        end

        local progress
        local exiting = false
        if entry.state == "enter" then
            progress = easeOutCubic((now - entry.stateStart) / NOTIFY_ENTER)
            entry.alpha = progress
            entry.offsetX = math_floor((1 - progress) * (NOTIFY_WIDTH + NOTIFY_MARGIN))
        elseif entry.state == "exit" then
            exiting = true
            local p = easeInCubic((now - entry.stateStart) / NOTIFY_EXIT)
            entry.alpha = 1 - p
            entry.offsetX = math_floor(p * (NOTIFY_WIDTH + NOTIFY_MARGIN))
        else
            entry.alpha = 1
            entry.offsetX = 0
        end

        local x = math_floor(baseX + entry.offsetX)
        local y = math_floor(entry.currentY)

        local slot = entry.slot
        local panel    = slot.panel
        local accent   = slot.accent
        local outline  = slot.outline
        local progBar  = slot.progress
        local title    = slot.title
        local body     = slot.body

        local visible = entry.alpha > 0.02

        setVisible(panel, visible)
        setVisible(accent, visible)
        setVisible(outline, visible)
        setVisible(progBar, visible)
        setVisible(title, visible)
        setVisible(body, visible)

        if visible then
            local trans = entry.alpha
            local zBase = NOTIFY_Z_BASE + (index * 6)

            panel.Position = Vector2_new(x, y)
            panel.Size = Vector2_new(NOTIFY_WIDTH, NOTIFY_HEIGHT)
            panel.Color = panelColor
            panel.Transparency = trans
            panel.ZIndex = zBase + 1

            accent.Position = Vector2_new(x, y)
            accent.Size = Vector2_new(3, NOTIFY_HEIGHT)
            accent.Color = entry.accent
            accent.Transparency = trans
            accent.ZIndex = zBase + 2

            outline.Position = Vector2_new(x, y)
            outline.Size = Vector2_new(NOTIFY_WIDTH, NOTIFY_HEIGHT)
            outline.Color = outlineColor
            outline.Transparency = trans
            outline.ZIndex = zBase + 3

            -- Progress bar (full track + draining fill)
            local trackY = y + NOTIFY_HEIGHT - 2
            local trackW = NOTIFY_WIDTH - 4
            local pct = 0
            if not exiting and entry.duration > 0 then
                local remaining = entry.dismissAt - now
                pct = clamp(remaining / entry.duration, 0, 1)
            end
            local fillW = math_max(2, math_floor(trackW * pct))

            progBar.Position = Vector2_new(x + 2, trackY)
            progBar.Size = Vector2_new(fillW, 2)
            progBar.Color = entry.accent
            progBar.Transparency = trans
            progBar.ZIndex = zBase + 4

            title.Text = entry.title
            title.Position = Vector2_new(x + 12, y + 7)
            title.Color = titleColor
            title.Transparency = trans
            title.ZIndex = zBase + 5

            body.Text = entry.message
            body.Position = Vector2_new(x + 12, y + 26)
            body.Color = bodyColor
            body.Transparency = trans
            body.ZIndex = zBase + 5
        end

        stackY = stackY + NOTIFY_HEIGHT + NOTIFY_GAP
    end
end

function MatchaGUI:Demo(opts)
    opts = opts or {}

    local gui = MatchaGUI.Create({
        Title = opts.Title or "cloud - preview",
        Width = opts.Width or 485,
        Height = opts.Height or 630,
        ToggleKey = opts.ToggleKey or 0x70,
        ConfigFolder = opts.ConfigFolder,
    })

    local legit = gui:Tab("Legit")
    local ragebot = gui:Tab("Ragebot")
    local visuals = gui:Tab("Visuals")
    local misc = gui:Tab("Misc")
    local settings = gui:Tab("Settings")

    local configStatus
    local configDropdown

    local function safeText(value)
        return asText(value)
    end

    local function configName()
        local name = safeText(gui:GetValue("config_name"))
        if not name or name == "" then
            return "default"
        end
        return name
    end

    local function setStatus(text, kind, opts)
        text = safeText(text)
        if configStatus then
            configStatus.label = text
        end
        print(text)
        if gui and gui.Notify then
            gui:Notify(text, {
                type = kind or "info",
                title = (opts and opts.title) or NOTIFY_TITLES[kind or "info"],
                duration = opts and opts.duration or nil,
            })
        end
    end

    local function selectedConfigName()
        if configDropdown then
            local selected = safeText(configDropdown:GetText())
            if selected and selected ~= "" then
                return selected
            end
        end
        return configName()
    end

    local function selectConfig(name)
        if not configDropdown then return end
        local items = configDropdown:GetItems()
        for i, item in ipairs(items) do
            if item == name then
                configDropdown:SetValue(i - 1)
                return
            end
        end
    end

    local function refreshStatus()
        local configs = gui:ListConfigs()
        if configDropdown then
            configDropdown:SetItems(configs)
        end
        if #configs == 0 then
            setStatus("No configs saved")
        else
            setStatus("Selected: " .. selectedConfigName())
        end
    end

    local function changed(label)
        return function(value)
            local kind = "info"
            if type(value) == "boolean" then
                kind = value and "success" or "info"
            end
            setStatus(label .. ": " .. safeText(value), kind)
        end
    end

    local function comboChanged(label)
        return function(index, text)
            setStatus(label .. ": " .. safeText(text), "info")
        end
    end

    local function colorChanged(label)
        return function()
            setStatus(label .. " changed", "info")
        end
    end

    local function keyChanged(label)
        return function(value, key)
            if key then
                setStatus(label .. ": " .. keyName(key), "info")
            else
                setStatus(label .. ": " .. keyName(value), "info")
            end
        end
    end

    local aimAssist = legit:Section("Aim Assist", "Left")
    aimAssist:Toggle("legit_enabled", "Enabled", true, changed("Aim Enabled"))
    aimAssist:SliderInt("legit_fov", "Field Of View", 0, 360, 90, changed("Field Of View"))
    aimAssist:SliderFloat("legit_smooth", "Smoothing", 0, 20, 4, "%.1f", changed("Smoothing"))
    aimAssist:SliderFloat("legit_curve", "Curve", 0, 1, 0, "%.2f", changed("Curve"))
    aimAssist:Combo("legit_hitbox", "Hitbox", { "Head", "Chest", "Closest" }, 0, comboChanged("Hitbox"))

    local trigger = legit:Section("Trigger", "Right")
    trigger:Toggle("trigger_enabled", "Enabled", false, changed("Trigger Enabled"))
    trigger:SliderInt("trigger_delay", "Delay", 0, 1000, 125, changed("Trigger Delay"))
    trigger:SliderFloat("trigger_chance", "Chance", 0, 100, 72, "%.1f", changed("Trigger Chance"))
    trigger:Keybind("trigger_key", "Trigger Key", 0x46, "hold", keyChanged("Trigger Key"))

    local rageMain = ragebot:Section("Core", "Left")
    rageMain:Toggle("rage_enabled", "Enabled", false, changed("Rage Enabled"))
    rageMain:Toggle("rage_silent", "Silent Aim", false, changed("Silent Aim"))
    rageMain:SliderInt("rage_hitchance", "Hit Chance", 0, 100, 75, changed("Hit Chance"))
    rageMain:SliderInt("rage_min_damage", "Min Damage", 0, 130, 35, changed("Min Damage"))
    rageMain:Combo("rage_priority", "Priority", { "Damage", "Accuracy", "Speed" }, 0, comboChanged("Priority"))

    local rageAntiAim = ragebot:Section("Anti Aim", "Right")
    rageAntiAim:Toggle("aa_enabled", "Enabled", false, changed("Anti Aim"))
    rageAntiAim:SliderInt("aa_yaw", "Yaw Offset", -180, 180, 0, changed("Yaw Offset"))
    rageAntiAim:SliderInt("aa_jitter", "Jitter", 0, 90, 20, changed("Jitter"))
    rageAntiAim:SliderFloat("aa_spin", "Spin Speed", 0, 30, 8, "%.1f", changed("Spin Speed"))

    local esp = visuals:Section("ESP", "Left")
    esp:Toggle("esp_enabled", "Enabled", true, changed("ESP Enabled"))
    esp:Toggle("esp_boxes", "Boxes", true, changed("Boxes"))
    esp:Toggle("esp_names", "Names", true, changed("Names"))
    esp:SliderInt("esp_distance", "Max Distance", 100, 10000, 2500, changed("Max Distance"))
    esp:SliderInt("esp_text_size", "Text Size", 8, 32, 13, changed("Text Size"))
    esp:ColorPicker("esp_color", "ESP Color", 255, 255, 255, 255, colorChanged("ESP Color"))

    local world = visuals:Section("World", "Right")
    world:Toggle("world_fullbright", "Fullbright", false, changed("Fullbright"))
    world:Toggle("world_chams", "Chams", false, changed("Chams"))
    world:SliderFloat("world_render_radius", "Render Radius", 0, 5000, 1200, "%.1f", changed("Render Radius"))
    world:SliderInt("world_fov", "Camera FOV", 40, 120, 70, changed("Camera FOV"))
    world:ColorPicker("world_accent", "World Accent", 69, 23, 255, 255, colorChanged("World Accent"))

    local movement = misc:Section("Movement", "Left")
    movement:Toggle("bhop_enabled", "Bunny Hop", false, changed("Bunny Hop"))
    movement:Toggle("auto_strafe", "Auto Strafe", false, changed("Auto Strafe"))
    movement:SliderInt("walk_speed", "Walk Speed", 16, 250, 16, changed("Walk Speed"))
    movement:SliderFloat("jump_power", "Jump Power", 0, 200, 50, "%.1f", changed("Jump Power"))
    movement:Keybind("movement_key", "Movement Key", 0x47, "toggle", keyChanged("Movement Key"))

    local demoTools = misc:Section("Demo Tools", "Right")
    demoTools:Toggle("demo_toggle", "Demo Toggle", true, changed("Demo Toggle"))
    demoTools:InputText("demo_text", "Demo Text", "type here", changed("Demo Text"))
    demoTools:Combo("demo_combo", "Demo Combo", { "First", "Second", "Third" }, 1, comboChanged("Demo Combo"))
    demoTools:Button("Print Values", function()
        setStatus("Values printed", "info")
        print("Aim FOV: " .. safeText(gui:GetValue("legit_fov")))
        print("Walk Speed: " .. safeText(gui:GetValue("walk_speed")))
        print("Demo Text: " .. safeText(gui:GetValue("demo_text")))
    end)
    demoTools:Button("Notify: Info", function()
        gui:NotifyInfo("This is an info notification.")
    end)
    demoTools:Button("Notify: Success", function()
        gui:NotifySuccess("Operation completed.", { title = "All good" })
    end)
    demoTools:Button("Notify: Warning", function()
        gui:NotifyWarning("Heads up — something looks off.")
    end)
    demoTools:Button("Notify: Error", function()
        gui:NotifyError("Something went wrong.", { duration = 6 })
    end)

    local createConfigs = settings:Section("Create Configs", "Left")
    createConfigs:InputText("config_name", "Name", "", nil, { skipConfig = true })
    createConfigs:Button("Create", function()
        local name = configName()
        local ok, msg = gui:SaveConfig(name)
        if ok then
            setStatus("Saved config: " .. msg, "success")
            refreshStatus()
            selectConfig(name)
        else
            setStatus("Save failed: " .. tostring(msg), "error")
        end
    end)

    local configSettings = settings:Section("Config Settings", "Left")
    configDropdown = configSettings:Combo("selected_config", "Saved Configs", {}, 0, function(index, text)
        text = safeText(text)
        if text and text ~= "" then
            gui:SetValue("config_name", text)
            setStatus("Selected: " .. text)
        end
    end, { skipConfig = true })
    configStatus = configSettings:Text("No configs saved")
    configSettings:Button("Load", function()
        local name = selectedConfigName()
        local ok, msg = gui:LoadConfig(name)
        if ok then
            setStatus("Loaded config: " .. name, "success")
        else
            setStatus("Load failed: " .. tostring(msg), "error")
        end
    end)
    configSettings:Button("Update", function()
        local name = selectedConfigName()
        local ok, msg = gui:SaveConfig(name)
        if ok then
            setStatus("Updated config: " .. msg, "success")
            refreshStatus()
            selectConfig(name)
        else
            setStatus("Update failed: " .. tostring(msg), "error")
        end
    end)
    configSettings:Button("Delete", function()
        local name = selectedConfigName()
        local ok, msg = gui:DeleteConfig(name)
        if ok then
            setStatus("Deleted config: " .. msg, "warning")
            refreshStatus()
        else
            setStatus("Delete failed: " .. tostring(msg), "error")
        end
    end)
    configSettings:Button("Refresh", function()
        refreshStatus()
    end)

    local uiSettings = settings:Section("UI Settings", "Right")
    uiSettings:InputText("menu_title", "Menu Title", "cloud")
    uiSettings:InputText("domain", "Domain", "cloud")
    uiSettings:ColorPicker("domain_accent", "Domain Accent", 255, 255, 255)
    uiSettings:ColorPicker("menu_accent", "Menu Accent", 255, 255, 255)

    local other = settings:Section("Other", "Right")
    other:Toggle("show_keybinds", "Show Keybinds", false)
    other:MenuKeybind("menu_key", "Menu Key", 0x70)

    gui:SetTab(opts.Tab or "Legit")
    refreshStatus()

    if opts.Start ~= false then
        gui:Start()
    end

    if opts.Start ~= false and opts.Block ~= false then
        while not gui._destroyed do
            task.wait(60)
        end
    end

    return gui
end

function MatchaGUI:ShowDemoMenu(opts)
    return self:Demo(opts)
end

MatchaGUI.KeyName = keyName
MatchaGUI.Theme = DEFAULT_THEME

cloud = MatchaGUI
Cloud = MatchaGUI
CloudUI = MatchaGUI
_G.cloud = MatchaGUI
_G.Cloud = MatchaGUI
_G.CloudUI = MatchaGUI

return MatchaGUI
