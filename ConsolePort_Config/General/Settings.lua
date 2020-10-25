local db, _, env, L = ConsolePort:DB(), ...; L = db('Locale');
local ConfigMixin, Widgets = {}, env.Widgets;

---------------------------------------------------------------
-- General settings
---------------------------------------------------------------
local SHORTCUT_WIDTH, GENERAL_WIDTH, FIXED_OFFSET = 284, 700, 8;
local Field = CreateFromMixins(CPIndexButtonMixin, env.ScaleToContentMixin)

function Field:OnLoad()
	self:SetWidth(GENERAL_WIDTH - 32)
	self:SetMeasurementOrigin(self, self.Content, self:GetWidth(), 40)
	self:SetScript('OnEnter', CPIndexButtonMixin.OnIndexButtonEnter)
	self:SetScript('OnLeave', CPIndexButtonMixin.OnIndexButtonLeave)
end

function Field:Construct(name, varID, field, newObj)
	if newObj then
		self:SetText(L(name))
		local constructor = Widgets[varID] or Widgets[field[1]:GetType()];
		if constructor then
			constructor(self, varID, field)
		end
	end
	self:Hide()
	self:Show()
end

---------------------------------------------------------------
-- Shortcuts
---------------------------------------------------------------
local Shortcut, Shortcuts = {}, CreateFromMixins(CPFocusPoolMixin)

function Shortcut:OnLoad()
	self:SetWidth(SHORTCUT_WIDTH - FIXED_OFFSET * 2)
	self:SetScript('OnClick', self.OnClick)
	self:SetDrawOutline(true)
end

function Shortcut:OnClick()
	self:SetChecked(false)
	self:OnChecked(false)
	self.General:ScrollToOffset(self.General:GetElementPosition(self.reference))
end

function Shortcuts:OnLoad()
	CPFocusPoolMixin.OnLoad(self)
	env.OpaqueMixin.OnLoad(self)
	self:CreateFramePool('IndexButton',
		'CPIndexButtonBindingHeaderTemplate', Shortcut, nil, self.Child)
	Mixin(self.Child, env.ScaleToContentMixin)
	self.Child:SetAllPoints()
	self.Child:SetMeasurementOrigin(self, self.Child, SHORTCUT_WIDTH, FIXED_OFFSET)
end

function Shortcuts:OnHide()
	self:ReleaseAll()
	self.lastWidget = nil;
end

function Shortcuts:Create(name, ref)
	local widget, newObj = self:TryAcquireRegistered(name)
	local anchor = self.lastWidget;
	if newObj then
		widget.General = self.General;
		widget:OnLoad()
	end
	if anchor then
		widget:SetAttribute('nodepriority', nil)
		widget:SetPoint('TOP', anchor, 'BOTTOM', 0, -FIXED_OFFSET)
	else
		widget:SetAttribute('nodepriority', 1)
		widget:SetPoint('TOP', 0, -FIXED_OFFSET)
	end
	widget:Show()
	widget:SetText(L(name))
	widget.reference = ref;
	self.lastWidget = widget;
end

---------------------------------------------------------------
-- General
---------------------------------------------------------------
local General = CreateFromMixins(CPFocusPoolMixin)

function General:CreateHeader(group, anchor)
	local header = self.headerPool:Acquire()
	header:SetText(L(group))
	header:Show()
	if anchor then
		header:SetPoint('TOP', anchor, 'BOTTOM', 0, -FIXED_OFFSET * 2)
	else
		header:SetPoint('TOP', 0, -FIXED_OFFSET)
	end
	self.Shortcuts:Create(group, header)
	return header;
end

function General:DrawOptions(showAdvanced)
	self.headerPool:ReleaseAll()

	-- sort settings by group
	local sorted = {};
	foreach(db('Variables'), function(var, data)
		local group = data.head or OTHER;
		if not sorted[group] then
			sorted[group] = {};
		end
		sorted[group][data.name] = {
			varID = var;
			field = data;
		};
	end)

	-- sort groups by display order first, key second
	local function displaysort(t, a, b)
		local iA, iB = t[a].field.sort, t[b].field.sort;
		if iA and not iB then
			return true;
		elseif iB and not iA then
			return false;
		elseif iA and iB then
			return iA < iB;
		else
			return a < b;
		end
	end

	local prev;
	for group, set in db.table.spairs(sorted) do
		-- render the header
		prev = self:CreateHeader(group, prev)

		-- render the options
		for name, data in db.table.spairs(set, displaysort) do
			local widget, newObj = self:TryAcquireRegistered(name)
			if newObj then
				widget.Label:ClearAllPoints()
				widget.Label:SetPoint('LEFT', 16, 0)
				widget.Label:SetJustifyH('LEFT')
				widget.Label:SetTextColor(1, 1, 1)
				widget:SetDrawOutline(true)
				widget:OnLoad()
			end
			widget:Construct(name, data.varID, data.field, newObj)
			widget:SetPoint('TOP', prev, 'BOTTOM', 0, -FIXED_OFFSET)
			prev = widget;
		end
	end
	self.Child:SetHeight(nil)
end

function General:OnShow()
	self:DrawOptions()
end

function General:OnLoad()
	CPFocusPoolMixin.OnLoad(self)
	env.OpaqueMixin.OnLoad(self)
	self.headerPool = CreateFramePool('Frame', self.Child, 'CPConfigHeaderTemplate')
	self:CreateFramePool('IndexButton',
		'CPIndexButtonBindingHeaderTemplate', Field, nil, self.Child)
	Mixin(self.Child, env.ScaleToContentMixin)
	self.Child:SetAllPoints()
	self.Child:SetMeasurementOrigin(self, self.Child, GENERAL_WIDTH, FIXED_OFFSET)
end

---------------------------------------------------------------
-- Panel
---------------------------------------------------------------
function ConfigMixin:OnFirstShow()
	local shortcuts = self:CreateScrollableColumn('Shortcuts', {
		_Mixin = Shortcuts;
		_Width = SHORTCUT_WIDTH;
		_Setup = {'CPSmoothScrollTemplate', 'BackdropTemplate'};
		_Backdrop = CPAPI.Backdrops.Opaque;
		_Points = {
			{'TOPLEFT', 0, 1};
			{'BOTTOMLEFT', 0, -1};
		};
	})
	local general = self:CreateScrollableColumn('General', {
		_Mixin = General;
		_Width = GENERAL_WIDTH;
		_Setup = {'CPSmoothScrollTemplate', 'BackdropTemplate'};
		_Backdrop = CPAPI.Backdrops.Opaque;
		_Points = {
			{'TOPLEFT', '$parent.Shortcuts', 'TOPRIGHT', 0, 0};
			{'BOTTOMLEFT', '$parent.Shortcuts', 'BOTTOMRIGHT', 0, 0};
		};
	})
	general.Shortcuts = shortcuts;
	shortcuts.General = general;
end

env.General = ConsolePortConfig:CreatePanel({
	name  = SETTINGS;
	mixin = ConfigMixin;
	scaleToParent = true;
	forbidRecursiveScale = true;
})