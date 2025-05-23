SWEP.PrintName = "The Slabshot"
SWEP.Author	= "ArtificialBakingTrays"
SWEP.Instructions = "Also known as: The Slopshot, Dexter's own design, a charged sniper rifle that packs a punch."
SWEP.Category = "Artificial Weaponry"
SWEP.IconOverride = "vgui/weaponvgui/slabshot_generi.png"

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.DrawCrosshair = false
SWEP.ViewModel	= "models/weapons/c_crossbow.mdl"
SWEP.WorldModel	= "models/weapons/w_crossbow.mdl"
SWEP.DrawAmmo = true
SWEP.UseHands = true
SWEP.HoldType = "ar2"
SWEP.Slot = 3
SWEP.BobScale = 1.15

SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic	= true
SWEP.Primary.Ammo = "AR2"
SWEP.Primary.Force = 160

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

function SWEP:SetChargeStart( time ) self:SetDTFloat( 0, time ) end
function SWEP:GetChargeStart() return self:GetDTFloat( 0 ) end

function SWEP:SetScoped( bool ) self:SetDTBool( 0, bool ) end
function SWEP:GetScoped() return self:GetDTBool( 0 ) end

function SWEP:PrimaryAttack()
	if self:Clip1() <= 0 then return end
	if self:GetChargeStart() ~= 0 then return end

	self:EmitSound( "tray_sounds/chargebegin.mp3", 75, 105 )
	self:SetChargeStart( CurTime() )
end

function SWEP:ChargeAttack( charge )
	if self:Clip1() <= 0 then return end
	if charge > 1 then charge = 1 end

	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self:TakePrimaryAmmo( 1 )

	self:SetNextPrimaryFire( CurTime() + 0.65 )

	self:EmitSound( "tray_sounds/basicfire.mp3", 75, math.random(100.5, 105.5), 0.7, 1 )
	self:EmitSound( "npc/sniper/echo1.wav", 75, math.random(105.5, 110), 0.7, 6 )

	local owner = self:GetOwner()
	owner:LagCompensation( true )

	owner:FireBullets {
		Src = owner:GetShootPos(),
		Dir = owner:GetAimVector(),
		Attacker = owner,
		Damage = 30 + charge * 110,
	}

	owner:LagCompensation( false )
end

function SWEP:Reload()
	if ( not self:HasAmmo() ) or ( CurTime() < self:GetNextPrimaryFire() ) then return end

	if self:Clip1() < self.Primary.ClipSize and self:Ammo1() > 0 then
		self:DefaultReload( ACT_VM_RELOAD )
		self:EmitSound("tray_sounds/reloadonce.mp3", 100 )

		self:SetScoped( false )
	end
end

function SWEP:SecondaryAttack()
	self:SetScoped( not self:GetScoped() )
	self:EmitSound("weapons/sniper/sniper_zoomin.wav", 75, math.random(95, 105), 100, 6 )
end

function SWEP:TranslateFOV( fov )
	self.LastFOV = fov

	if self:GetScoped() then
		return 25
	end
end

function SWEP:AdjustMouseSensitivity()
	if self:GetScoped() then
		return 25 / self.LastFOV
	end
end

local singleplayer = game.SinglePlayer()
function SWEP:Think()
	if CLIENT and singleplayer then return end
	local start = self:GetChargeStart()
	if start == 0 then return end

	if not self:GetOwner():KeyDown( IN_ATTACK ) then
		self:SetChargeStart( 0 )
		self:ChargeAttack( CurTime() - start )
	end
end

local function drawCircle(x, y, sx, sy, itr)
	for i = 0, (itr - 1) do
		local delta = (i / itr) * (math.pi * 2)

		local deltaPrev = ((i - 1) / itr) * (math.pi * 2)

		local x1 = x + math.cos(delta) * sx
		local y1 = y + math.sin(delta) * sy

		local x2 = x + math.cos(deltaPrev) * sx
		local y2 = y + math.sin(deltaPrev) * sy

		surface.DrawLine(x1, y1, x2, y2)
	end
end

local c_Start = Color(255, 255, 255)
local c_plyclr = Color(0, 0, 0)

local function lerpColorVarArg(t, a, b)
	return Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b)
end

local scope = surface and surface.GetTextureID("vgui/hud/xbox_reticle")
function SWEP:DrawHUD()
	local delta = self:GetDTFloat( 0 )
	if delta ~= 0 then
		delta = CurTime() - delta
		if delta > 1 then delta = 1 end
	end

	local PlyClr = self:GetOwner():GetWeaponColor()
	c_plyclr:SetUnpacked(PlyClr[1] * 255, PlyClr[2] * 255, PlyClr[3] * 255, 255)

	local r, g, b = lerpColorVarArg(delta, c_Start, c_plyclr)
	surface.SetDrawColor(c_plyclr)
	render.SetColorMaterialIgnoreZ()

	local h = ScrH()
	local w = ScrW()
	local RectSize = 100
	local RectSizeHalf = RectSize / 2
	local Speed = 100

	drawCircle(w * .5, h * .5, 5.5, 5.5,  24)

	--Attempting to draw the hud for scoping in
	if self:GetScoped() then
		local colour = HSVToColor( CurTime() *  Speed, 0.7, 1 )
		surface.SetDrawColor(colour)
		surface.DrawRect(w * .555 - RectSizeHalf, h * .485 - RectSizeHalf, RectSize / 6, (RectSize * 1) * self:Clip1() / 2)

		surface.SetTexture(scope)
		surface.SetDrawColor(r, g, b, 255)
		surface.DrawTexturedRectRotated( w / 2, h / 2, (w / 2) / 4, (w / 2) / 4, 0 )

		draw.SimpleText("Ammo: " .. self:Clip1(), "HudDefault", w * .555, h * .45, Color(255, 255, 255) )

		local dist = LocalPlayer():GetEyeTrace().Fraction * 32768
		draw.SimpleText("Distance: " .. math.floor(dist), "HudDefault", w * .555, h * .475, Color(255, 255, 255) )
	end
end