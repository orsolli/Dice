Script.frequency=10--int "Frequency" 0 10000
Script.strength=0.5--float "Strength" 0 1
Script.Recursive=true--bool

function Script:Start()
	self:SaveIntensity(self.entity,self.Recursive)
end

--Store the original intensity values
function Script:SaveIntensity(entity,recursive)
	entity:SetKeyValue("Flicker_Intensity",entity:GetIntensity())
	if recursive then
		local n
		for n=0,entity:CountChildren()-1 do
			self:SaveIntensity(entity:GetChild(n),true)
		end
	end
end

--Apply a modified intensity value
function Script:ApplyIntensity(entity,intensity,recursive)
	local i = entity:GetKeyValue("Flicker_Intensity")
	if i~="" then
		entity:SetIntensity(tonumber(i) * intensity)
	end
	if recursive then
		local n
		for n=0,entity:CountChildren()-1 do
			self:ApplyIntensity(entity:GetChild(n),intensity,true)
		end
	end
end

function Script:Draw()
	if self.color==nil then
		self.color = self.entity:GetColor()
	end
	local t = Time:GetCurrent()
	local pulse = Math:Sin(t/100.0*self.frequency)*0.5*self.strength+(1.0-self.strength*0.5)
	self:ApplyIntensity(self.entity,pulse,self.Recursive)
end
