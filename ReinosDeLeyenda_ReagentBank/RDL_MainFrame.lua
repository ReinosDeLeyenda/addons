RDL_GUI = CreateFrame("Frame", "RDL_MainProfessionFrame", UIParent)
local gui = RDL_GUI
gui:SetSize(560, 495) -- +35px de alto para la fila de profesiones superior
gui:SetPoint("CENTER")
gui:SetFrameStrata("HIGH")
gui:SetMovable(true)
gui:EnableMouse(true)
gui:RegisterForDrag("LeftButton")
gui:SetScript("OnDragStart", gui.StartMoving)
gui:SetScript("OnDragStop", gui.StopMovingOrSizing)
gui:Hide()
tinsert(UISpecialFrames, "RDL_MainProfessionFrame")

gui:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 }
})
gui:SetBackdropColor(0.05, 0.06, 0.09, 0.96)

local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 18, -14)
title:SetText("|cff00ccffReinos de leyenda|r - Profesiones")

gui.subTitle = gui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
gui.subTitle:SetPoint("TOPRIGHT", -38, -18)

local closeBtn = CreateFrame("Button", nil, gui, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -6, -6)
closeBtn:SetScript("OnClick", function() CloseTradeSkill(); gui:Hide() end)

-- BARRA DE FILTROS Y DESENCANTAR (Bajados 34px para dejar sitio a los iconos arriba)
local searchBox = CreateFrame("EditBox", "RDL_SearchBox", gui, "InputBoxTemplate")
searchBox:SetSize(165, 22)
searchBox:SetPoint("TOPLEFT", 22, -76)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnTextChanged", function(self) SetTradeSkillItemNameFilter(self:GetText()) end)

gui.onlyMats = CreateFrame("CheckButton", "RDL_OnlyMats", gui, "UICheckButtonTemplate")
gui.onlyMats:SetSize(24, 24)
gui.onlyMats:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
_G["RDL_OnlyMatsText"]:SetText("Con materiales")

gui.deOpenBtn = CreateFrame("Button", "RDL_OpenDEBtn", gui, "UIPanelButtonTemplate")
gui.deOpenBtn:SetSize(95, 22)
gui.deOpenBtn:SetPoint("TOPRIGHT", -18, -76)
gui.deOpenBtn:SetText("Desencantar")
gui.deOpenBtn:SetScript("OnClick", function()
    if RDL_Disenchant then RDL_Disenchant.ToggleSelector() end
end)
gui.onlyMats:SetScript("OnClick", function() RDL_MainFrame_Refresh() end)

-- PANEL IZQUIERDO: LISTA DE RECETAS
local listPanel = CreateFrame("Frame", nil, gui)
listPanel:SetSize(250, 365)
listPanel:SetPoint("TOPLEFT", 16, -106)
listPanel:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
listPanel:SetBackdropColor(0.03, 0.03, 0.05, 0.9)

gui.scrollFrame = CreateFrame("ScrollFrame", "RDL_RecipeScroll", listPanel, "FauxScrollFrameTemplate")
gui.scrollFrame:SetPoint("TOPLEFT", 4, -6)
gui.scrollFrame:SetPoint("BOTTOMRIGHT", -26, 6)

gui.rowButtons = {}
for i = 1, 17 do
    local row = CreateFrame("Button", nil, listPanel)
    row:SetSize(216, 20)
    row:SetPoint("TOPLEFT", 8, -6 - ((i - 1) * 20))
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    gui.rowButtons[i] = row
end

-- PANEL DERECHO: DETALLES DE LA RECETA
local detailPanel = CreateFrame("Frame", nil, gui)
detailPanel:SetSize(270, 365)
detailPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 8, 0)
detailPanel:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
detailPanel:SetBackdropColor(0.04, 0.04, 0.07, 0.9)

gui.itemIcon = CreateFrame("Button", nil, detailPanel)
gui.itemIcon:SetSize(40, 40)
gui.itemIcon:SetPoint("TOPLEFT", 12, -14)
gui.itemIcon.tex = gui.itemIcon:CreateTexture(nil, "ARTWORK")
gui.itemIcon.tex:SetAllPoints()

gui.itemTitle = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
gui.itemTitle:SetPoint("LEFT", gui.itemIcon, "RIGHT", 8, 6)
gui.itemTitle:SetPoint("RIGHT", -10, 6)
gui.itemTitle:SetJustifyH("LEFT")

gui.itemSub = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
gui.itemSub:SetPoint("TOPLEFT", gui.itemTitle, "BOTTOMLEFT", 0, -4)

local reqHeader = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
reqHeader:SetPoint("TOPLEFT", 12, -68)
reqHeader:SetText("Componentes:")

gui.reagentRows = {}
for i = 1, 8 do
    local rb = CreateFrame("Button", nil, detailPanel)
    rb:SetSize(246, 26)
    rb:SetPoint("TOPLEFT", 12, -88 - ((i - 1) * 28))
    rb:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    rb.icon = rb:CreateTexture(nil, "ARTWORK")
    rb.icon:SetSize(22, 22)
    rb.icon:SetPoint("LEFT", 2, 0)
    rb.name = rb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rb.name:SetPoint("LEFT", rb.icon, "RIGHT", 6, 0)
    rb.name:SetWidth(155)
    rb.name:SetJustifyH("LEFT")
    rb.count = rb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rb.count:SetPoint("RIGHT", -2, 0)
    gui.reagentRows[i] = rb
end

gui.qtyBox = CreateFrame("EditBox", "RDL_QtyBox", detailPanel, "InputBoxTemplate")
gui.qtyBox:SetSize(36, 22)
gui.qtyBox:SetPoint("BOTTOM", detailPanel, "BOTTOM", 10, 14)
gui.qtyBox:SetNumeric(true)
gui.qtyBox:SetAutoFocus(false)
gui.qtyBox:SetText("1")

gui.createBtn = CreateFrame("Button", nil, detailPanel, "UIPanelButtonTemplate")
gui.createBtn:SetSize(84, 24)
gui.createBtn:SetPoint("LEFT", gui.qtyBox, "RIGHT", 6, 0)
gui.createBtn:SetText("Crear")

gui.createAllBtn = CreateFrame("Button", nil, detailPanel, "UIPanelButtonTemplate")
gui.createAllBtn:SetSize(110, 24)
gui.createAllBtn:SetPoint("RIGHT", gui.qtyBox, "LEFT", -6, 0)
gui.createAllBtn:SetText("Crear todos")
