Script.pin = Vec3(0,0,1) --Vec3 "Hinge Pin"
Script.limitsenabled=false--bool "Enable limits"
Script.limits = Vec2(-45,45) --Vec2 "Limits"
Script.friction = 0--float "Friction"

function Script:Start()
	local pos = self.entity:GetPosition(true)
	self.joint = Joint:Hinge(pos.x, pos.y, pos.z, self.pin.x, self.pin.y, self.pin.z, self.entity, self.entity:GetParent())
	if self.limitsenabled then self.joint:EnableLimits() end
	self.joint:SetLimits(self.limits.x,self.limits.y)
	self.joint:SetFriction(self.friction)
	self.entity:SetDamping(0,0)
end
