Script.pin = Vec3(0,0,1) --Vec3 "Pin"
Script.limitsenabled=false--bool "Enable limits"
Script.limits = Vec2(-0.5,0.5) --Vec2 "Limits"
Script.spring = 0--float "Spting"

function Script:Start()
	local pos = self.entity:GetPosition(true)
	self.joint = Joint:Slider(pos.x, pos.y, pos.z, self.pin.x, self.pin.y, self.pin.z, self.entity, self.entity:GetParent())
	if self.limitsenabled then self.joint:EnableLimits() end
	self.joint:SetLimits(self.limits.x,self.limits.y)
	self.joint:SetFriction(0)
	self.joint:SetSpring(self.spring)
	self.entity:SetDamping(0,0)
end
