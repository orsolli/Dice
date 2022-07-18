function Script:Start()
	local pos = self.entity:GetPosition(true)
	self.joint = Joint:Ball(pos.x, pos.y, pos.z, self.entity, self.entity:GetParent())
	self.joint:SetFriction(0)
	self.entity:SetDamping(0,0)
end
