-- MatchaGUI
-- First-party Drawing-based GUI foundation for Matcha LuaVM scripts.

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

local KEY_SCAN = {
    0x08, 0x09, 0x0D, 0x10, 0x11, 0x12, 0x14, 0x1B, 0x20, 0x2D, 0x2E,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
    0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
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
    if vk == 0x20 then
        return " "
    end
    return nil
end

local function readMouseDown()
    if not ismouse1pressed then return false end
    local ok, down = pcall(ismouse1pressed)
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
    self._mouse = { x = 0, y = 0, px = 0, py = 0, down = false, clicked = false, released = false }
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
    if active then
        down = readMouseDown()
    end

    local wasDown = self._mouse.down
    self._mouse.px = self._mouse.x
    self._mouse.py = self._mouse.y
    self._mouse.x = mx
    self._mouse.y = my
    self._mouse.down = down
    self._mouse.clicked = down and not wasDown
    self._mouse.released = (not down) and wasDown
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
        local minValue = widget.min or 0
        local maxValue = widget.max or 100
        if maxValue <= minValue then maxValue = minValue + 1 end

        local trackX = widget.x + 4
        local trackY = widget.y + 24
        local trackW = widget.w - 8
        local trackH = 9

        if self._mouse.clicked and inside(mx, my, trackX, trackY - 6, trackW, 18) then
            self._activeSlider = widget
        end
        if self._mouse.released and self._activeSlider == widget then
            self._activeSlider = nil
        end
        if self._activeSlider == widget and self._mouse.down then
            local pct = clamp((mx - trackX) / trackW, 0, 1)
            local raw = minValue + (maxValue - minValue) * pct
            local step = widget.step or 1
            local nextValue = raw
            if step > 0 then
                nextValue = math_floor((raw / step) + 1 / 2) * step
            end
            nextValue = clamp(nextValue, minValue, maxValue)
            if widget.format == "%d" then
                nextValue = math_floor(nextValue + 1 / 2)
            end
            if nextValue ~= widget.value then
                widget.value = nextValue
                self._values[widget.id] = nextValue
                if widget.callback then
                    widget.callback(nextValue, widget)
                end
            end
        end

        local value = clamp(widget.value or minValue, minValue, maxValue)
        local pct = (value - minValue) / (maxValue - minValue)
        local fillW = math_floor(trackW * pct)

        widget.labelText.Text = widget.label
        widget.labelText.Size = 13
        widget.labelText.Position = Vector2_new(widget.x + 4, widget.y + 3)
        widget.labelText.Color = theme.text
        widget.valueText.Text = string_format(widget.format or "%.2f", value)
        widget.valueText.Color = theme.muted
        widget.valueText.Size = 12
        widget.valueText.Position = Vector2_new(widget.x + widget.w - 54, widget.y + 3)

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
end

function Window:Pulse(seconds)
    local untilTime = os_clock() + (seconds or 2)
    while os_clock() < untilTime do
        self:Step(0)
        task.wait()
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

    gui:Tab("Legit")
    gui:Tab("Ragebot")
    gui:Tab("Visuals")
    gui:Tab("Misc")
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

    local function setStatus(text)
        text = safeText(text)
        if configStatus then
            configStatus.label = text
        end
        print(text)
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

    local createConfigs = settings:Section("Create Configs", "Left")
    createConfigs:InputText("config_name", "Name", "", nil, { skipConfig = true })
    createConfigs:Button("Create", function()
        local name = configName()
        local ok, msg = gui:SaveConfig(name)
        if ok then
            setStatus("Saved config: " .. msg)
            refreshStatus()
            selectConfig(name)
        else
            setStatus("Save failed: " .. tostring(msg))
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
            setStatus("Loaded config: " .. name)
        else
            setStatus("Load failed: " .. tostring(msg))
        end
    end)
    configSettings:Button("Update", function()
        local name = selectedConfigName()
        local ok, msg = gui:SaveConfig(name)
        if ok then
            setStatus("Updated config: " .. msg)
            refreshStatus()
            selectConfig(name)
        else
            setStatus("Update failed: " .. tostring(msg))
        end
    end)
    configSettings:Button("Delete", function()
        local name = selectedConfigName()
        local ok, msg = gui:DeleteConfig(name)
        if ok then
            setStatus("Deleted config: " .. msg)
            refreshStatus()
        else
            setStatus("Delete failed: " .. tostring(msg))
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

    gui:SetTab("Settings")
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

MatchaGUI.KeyName = keyName
MatchaGUI.Theme = DEFAULT_THEME

cloud = MatchaGUI
Cloud = MatchaGUI
CloudUI = MatchaGUI
_G.cloud = MatchaGUI
_G.Cloud = MatchaGUI
_G.CloudUI = MatchaGUI

return MatchaGUI
