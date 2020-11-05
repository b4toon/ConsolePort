local _, env = ...;
local Config = CPAPI.EventHandler(ConsolePortConfig, {
	'PLAYER_REGEN_ENABLED',
	'PLAYER_REGEN_DISABLED'
}); env.Config = Config;

Config:SetMinResize(1000, 700)
Config:SetScript('OnMouseWheel', function(self, delta, ...)
	local f = IsShiftKeyDown() and PixelUtil.SetHeight or IsControlKeyDown() and PixelUtil.SetWidth
	local g = IsShiftKeyDown() and self.GetHeight or IsControlKeyDown() and self.GetWidth
	if f and g then
		f(self, g(self) + (delta * 10))
	end
end)

local db = ConsolePort:DB()

function Config:OnActiveDeviceChanged()
	local hasActiveDevice = db('Gamepad/Active') and true or false;
	self.Header:ToggleEnabled(hasActiveDevice)
end

function Config:ShowAfterCombat()
	self.showAfterCombat = true;
	CPAPI.Log(db('Locale')('Your gamepad configuration will reappear when you leave combat.'))
	self:Hide()
end

function Config:OnShow()
	if InCombatLockdown() then
		return self:ShowAfterCombat()
	end
	self:OnActiveDeviceChanged()
end

function Config:PLAYER_REGEN_DISABLED()
	if self:IsShown() then
		self:ShowAfterCombat()
	end
end

function Config:PLAYER_REGEN_ENABLED()
	if self.showAfterCombat then
		self.showAfterCombat = nil;
		db('Alpha/FadeIn')(self, 1)
		self:Show()
	end
end

CPAPI.Start(Config)
db:RegisterCallback('Gamepad/Active', Config.OnActiveDeviceChanged, Config)