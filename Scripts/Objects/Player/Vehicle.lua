Script.enabled=true--bool "Enabled"
Script.health=100--float "Health"
Script.teamid=1--choice "Team" "Neutral,Good,Bad"
Script.cameraangle=35--float "Camera Angle"
Script.cameradistance=5--float "Camera Distance"
Script.camerasmoothing=4--float "Cam Smoothing"
Script.acceleration=200--float "Acceleration"
Script.friction=2--float "Tire Friction"
Script.springDamping=10--float "Spring Damping"
Script.spring=300--float "Spring"
Script.springRelaxation=0.1--float "Spring Relaxation"
Script.Brakes=200--float
Script.reverseorientation=false--bool "Reverse Axis"
Script.tiremass=20--float "Tire Mass"

function Script:Enable()
	self.camera:Show()
	self.enabled=true
end

function Script:Hurt(damage)
	self.health = self.health-damage
end

function Script:Disable()
	self.camera:Hide()
	self.enabled=false
	self.started=false
end

function Script:FindTires(entity,tires)
	local n
	local count = entity:CountChildren()
	for n=0,count-1 do
		local child = entity:GetChild(n)
		local name = string.lower(child:GetKeyValue("name"))
		if String:Left(name,5)=="wheel" or String:Left(name,4)=="tire" then
			local model = tolua.cast(child,"Model")
			if model~=nil then
				table.insert(tires,model)
			end
		end
		self:FindTires(child,tires)
	end
end

function Script:Start()
	self.vehicle = Vehicle:Create(self.entity)
	self.camera = Camera:Create()
	if self.enabled==false then
		self.camera:Hide()
	end
	local aamode = tonumber((System:GetProperty("antialias")))
	if aamode ~= nil then
		self.camera:SetMultisampleMode(aamode)
	end
	if self.entity:GetMass()==0 then
		self.entity:SetMass(100)
	end
	self.camera:SetDebugPhysicsMode(true)
	
	local tires={}
	self:FindTires(self.entity,tires)

	local n,tiremesh
	for n,tiremesh in ipairs(tires) do
		local steering=false
		tiremesh:SetSweptCollisionMode(true)
		tiremesh:SetFriction(0.1,self.friction)
		tiremesh:Translate(0,-0.2,0,true)
		local pos = Transform:Point(0,0,0,tiremesh,self.entity)
		if self.reverseorientation==true then
			if pos.z < 0 then steering=true end
		else
			if pos.z > 0 then steering=true end
		end
		tiremesh:SetElasticity(0)
		tiremesh:SetMass(self.tiremass)
		self.vehicle:AddTire(tiremesh,steering,self.spring,self.springRelaxation,self.springDamping)
	end
end

function Script:Collision(entity,position,normal,speed)
	if speed>10 then
		if entity.script ~= nil then
			if type(entity.script.Hurt)=="function" then
				entity.script:Hurt(speed*2,self)
			end
		end
	end
end

function Script:UpdatePhysics()
	if self.enabled==false then return end
	if self.health<=0 then return end	

	local groundspeed = self.entity:GetVelocity()
	groundspeed = groundspeed:xz()
	groundspeed = groundspeed:Length()

	--Acceleration
	local gas = 0
	local window = Window:GetCurrent()
	if window:KeyDown(Key.W) then
		gas = gas + self.acceleration
	end
	if window:KeyDown(Key.S) then
		gas = gas - self.acceleration
	end
	if self.reverseorientation==true then
		gas = -gas
	end
	self.vehicle:SetGas(gas)
	
	--Brakes
	local brakeforce=0
	if window:KeyDown(Key.Space) then
		brakeforce=self.Brakes
	end
	self.vehicle:SetBrakes(brakeforce)

	--Steering
	local angle=0
	if window:KeyDown(Key.D) then
		angle = angle + 35
	end
	if window:KeyDown(Key.A) then
		angle = angle - 35
	end
	local angledamping = Math:Min(1,groundspeed/30.0)
	if brakeforce==0 then
		angledamping = math.sqrt(angledamping)
		angledamping = math.sqrt(angledamping)
	end
	angle = angle * (1 - angledamping)	
	self.vehicle:SetSteering(angle)

end

function Script:UpdateWorld()
	if self.enabled==false then return end
	local currentposition = self.camera:GetPosition(true)
	local currentrotation = self.camera:GetRotation(true)

	self.camera:SetPosition(self.entity:GetPosition(true))

	local modelrotation = self.entity:GetRotation(true)
	modelrotation.z=0	
	self.camera:SetRotation(modelrotation)
--self.camera:SetRotation(0,0,0)

	if self.reverseorientation==true then
		self.camera:Turn(0,180,0)
	end
	self.camera:Turn(self.cameraangle,0,0)
	self.camera:Move(0,0,-self.cameradistance)

	local newposition = self.camera:GetPosition(true)
	local newrotation = self.camera:GetRotation(true)

	if self.started==true then
		self.camera:SetPosition(Math:Curve(newposition.x,currentposition.x,self.camerasmoothing/Time:GetSpeed()),Math:Curve(newposition.y,currentposition.y,self.camerasmoothing/Time:GetSpeed()),Math:Curve(newposition.z,currentposition.z,self.camerasmoothing/Time:GetSpeed()),true)
		self.camera:SetRotation(Math:CurveAngle(newrotation.x,currentrotation.x,self.camerasmoothing/Time:GetSpeed()),Math:CurveAngle(newrotation.y,currentrotation.y,self.camerasmoothing/Time:GetSpeed()),0,true)
	end

	self.started=true
end

--This function will be called when the entity is deleted.
function Script:Detach()
	self.vehicle=nil
	self.camera:Release()
	self.camera = nil
end
