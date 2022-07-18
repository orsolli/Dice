Script.teamid=1
Script.health=100--int "Health"
Script.teamid=1--choice "Team" "Neutral,Good,Bad"
Script.grippadding=0.02

function Script:Hurt(damage)
	self.health = self.health - damage
end

function Script:Start()
	self.entity:SetPickMode(0)

	--Initialize VR
	if VR:Enable()==false then
		System:Print("Error: Failed to initialize VR environment.")	
	else
		VR:SetTrackingSpace(VR.Roomspace)
	end
	
	--Make model invisible but not hidden
	local mtl = Material:Create()
	mtl:SetBlendMode(Blend.Invisible)
	self.entity:SetMaterial(mtl)
	mtl:Release()
	mtl = nil

	--Create the player camera
	self.camera = Camera:Create()
	self.camera:SetPosition(self.entity:GetPosition(true))
	self.camera:Translate(0,1.6,0)
	self.camera:SetRotation(self.entity:GetRotation(true))
	local aamode = tonumber((System:GetProperty("antialias")))
	if aamode ~= nil then
		self.camera:SetMultisampleMode(aamode)
	end
	
	Listener:Create(self.camera)
	
	--Create teleporter beam
	local beam = Sprite:Create()
	beam:SetViewMode(6)
	beam:SetSize(0.05,20)
	beam:SetColor(1,2,1)
	mtl = Material:Load("Models/VR/teleport3.mat")
	if mtl~=nil then
		beam:SetMaterial(mtl)
		mtl:Release()
		mtl = nil
	end
	beam:Hide()
	
	--Create beam segments
	self.maxbeamsteps=32
	self.beam = {}
	self.beam[1] = beam
	local n
	for n=2,self.maxbeamsteps do
		self.beam[n] = tolua.cast(self.beam[1]:Instance(),"Sprite")
	end
	
	--Load the teleport indicator prefab
	self.teleportindicator = Prefab:Load("Models/VR/teleport.pfb")
	self.teleportindicator:SetColor(1,2,1)
	self.teleportindicator:Hide()
	
	--Initialize offset
	self.targetoffset = self.entity:GetPosition(true)
	VR:SetOffset(self.targetoffset)
	
	self.handjoint = {}
	self.heldobject = {}
	self.heldobjectrelpos = {}
	self.heldobjectrelrot = {}
	self.heldobjectrelrot = {}
	self.handeffector = {}
	self.handballandsocket = {}
	self.handconnector = {}
end

function VRPlayer_SelectItems(entity,extra)
	if entity==extra then return end
	local self = tolua.cast(extra,"Entity").script
	if self.heldobject[self.currentcontrollerindex]~=nil then return end
	
	--System:Print(self.currentcontrollerindex)
		
	local mass = entity:GetMass()
	if mass>0 and mass<10 then
		local pos = self.currentcontroller:GetPosition(true)
		local d = entity:GetDistance(pos,true)
		if d <= self.grippadding then
			self.heldobject[self.currentcontrollerindex] = entity
			entity:SetSweptCollisionMode(false)
			
			local useball=false
			local n
			for n=0,entity:CountJoints()-1 do
				local joint = entity:GetJoint(n)
				local a = joint:GetEntity(0)
				local b = joint:GetEntity(1)
				if a==nil or b==nil then
					useball=true
					break
				end
				if a~=entity then
					if a:GetMass()==0 then
						useball=true
						break
					end
				end
				if b~=entity then
					if b:GetMass()==0 then
						useball=true
						break
					end
				end
			end
			
			if useball then
				local p = self.currentcontroller:GetPosition(true)
				
				--Create connector
				self.handconnector[self.currentcontrollerindex] = Pivot:Create()
				self.handconnector[self.currentcontrollerindex]:SetMass(1)
				self.handconnector[self.currentcontrollerindex]:SetGravityMode(false)
				self.handconnector[self.currentcontrollerindex]:SetPosition(p)
				
				--Create effector			
				self.handeffector[self.currentcontrollerindex] = Joint:Kinematic(p.x,p.y,p.z,self.handconnector[self.currentcontrollerindex])
				self.heldobjectrelpos[self.currentcontrollerindex] = Transform:Point(entity:GetPosition(true),nil,self.currentcontroller)
				self.heldobjectrelrot[self.currentcontrollerindex] = Transform:Rotation(entity:GetQuaternion(true),nil,self.currentcontroller)
				
				--Create ball and socket joint
				self.handballandsocket[self.currentcontrollerindex] = Joint:Ball(p.x,p.y,p.z,entity,self.handconnector[self.currentcontrollerindex])
				
			else
				local p = entity:GetPosition(true)
				
				--Create simple effector
				self.handeffector[self.currentcontrollerindex] = Joint:Kinematic(p.x,p.y,p.z,entity)
				self.handeffector[self.currentcontrollerindex]:SetFriction(1000,1000)
				self.heldobjectrelpos[self.currentcontrollerindex] = Transform:Point(entity:GetPosition(true),nil,self.currentcontroller)
				self.heldobjectrelrot[self.currentcontrollerindex] = Transform:Rotation(entity:GetQuaternion(true),nil,self.currentcontroller)
				
			end
			return
		end
	end
	
	--Perform function recursively if the subhierarchy has any visible objects
	if entity:CountVisibleChildren()>0 then
		local n
		for n=0,entity:CountChildren()-1 do
			VRPlayer_SelectItems(entity:GetChild(n),extra)
		end
	end

end

function Script:DropObject(n)
	self.heldobject[n]=nil
	if self.handeffector[n]~=nil then
		self.handeffector[n]:Release()
		self.handeffector[n]=nil
	end
	if self.handballandsocket[n]~=nil then
		self.handballandsocket[n]:Release()
		self.handballandsocket[n] = nil
	end
	if self.handconnector[n]~=nil then
		self.handconnector[n]:Release()
		self.handconnector[n]=nil
	end
end

function Script:UpdatePhysics()
	
	self.entity:SetPosition(VR:GetOffset()*Vec3(0,1,0) + self.camera:GetPosition(true) * Vec3(1,0,1))
	
	--Pick up objects
	local n
	local aabb = nil
	for n=0,1 do
		
		local controller = VR:GetControllerModel(VR.Left+n)
		
		--Drop held object
		if VR:GetControllerButtonDown(VR.Left + n, VR.TriggerButton)==false then
			self:DropObject(n)
		end
		
		--Update kinematic joints
		if self.handeffector[n]~=nil and controller~=nil then
			if self.handconnector[n]~=nil then
				self.handeffector[n]:SetTargetMatrix(controller:GetMatrix())
			else
				local v = Transform:Point(self.heldobjectrelpos[n],controller,nil)
				self.handeffector[n]:SetTargetPosition(v,1)
				local q = Transform:Rotation(self.heldobjectrelrot[n],controller,nil)
				self.handeffector[n]:SetTargetRotation(q,1)
			end
		end
		
		if VR:GetControllerButtonHit(VR.Left + n, VR.TriggerButton)==true then
			if self.heldobject[n]==nil then
				--local controller = VR:GetControllerModel(VR.Left+n)
				if controller~=nil then
					local aabb = AABB()	
					aabb.min = controller:GetPosition(true)
					aabb.max = aabb.min
					aabb.min = aabb.min - Vec3(self.grippadding)
					aabb.max = aabb.max + Vec3(self.grippadding)
					aabb:Update()
					self.currentcontroller = controller
					self.currentcontrollerindex = n
					world:ForEachEntityInAABBDo(aabb,"VRPlayer_SelectItems",self.entity)
				end
			end
		end
	end
	
end

function Script:UpdateWorld()
	
	--Check if teleporter is active and the button was released
	if self.teleportindicator:Hidden()==false then
		if VR:GetControllerButtonDown(VR.Right,VR.TouchpadButton)==false then
			local offset = VR:GetOffset()
			local pos = self.teleportindicator:GetPosition()
			local campos = self.camera:GetPosition(true)
			pos.x = pos.x - campos.x + offset.x
			pos.y = pos.y - 0.05
			pos.z = pos.z - campos.z + offset.z
			self.targetoffset = pos
		end
	end
	
	--Hide beam and indicator
	self.teleportindicator:Hide()
	for n=1,self.maxbeamsteps do
		self.beam[n]:Hide()
		self.beam[n]:SetColor(2,1,1)
	end
	
	local controller = VR:GetControllerModel(VR.Right)
	if controller~=nil then
		
		--Activate teleporter
		if VR:GetControllerButtonDown(VR.Right,VR.TouchpadButton)==true then
			local world = self.entity.world
			local pickinfo = PickInfo()
			
			local p0 = controller:GetPosition(true)
			local velocity = Transform:Normal(0,0,-1,controller,nil)
			local speed = 1
			local n
			local gravity = -0.1
			
			--Loop through segments making an arc
			for n=1,self.maxbeamsteps do
				
				p1 = p0 + velocity * speed
				velocity.y = velocity.y + gravity
				
				self.beam[n]:Show()
				self.beam[n]:SetPosition((p0+p1)*0.5,true)
				self.beam[n]:AlignToVector(p1-p0,2)
				self.beam[n]:SetSize(0.05,p0:DistanceToPoint(p1)+0.02)
				
				if world:Pick(p0, p1, pickinfo, 0, true)==true then
					
					--Correct the length of the last beam segment	
					self.beam[n]:SetSize(0.05,p0:DistanceToPoint(pickinfo.position)+0.02)
					self.beam[n]:SetPosition((p0+pickinfo.position)*0.5,true)
					
					--Cancel if slope is too steep
					local slope = 90 - Math:ASin(pickinfo.normal.y)
					if slope>35 then break end
					
					--Show the indicator
					self.teleportindicator:SetPosition(pickinfo.position)
					self.teleportindicator:Translate(0,0.05,0)
					self.teleportindicator:Show()
					
					--Recolor the beam
					for n=1,self.maxbeamsteps do
						self.beam[n]:SetColor(1,2,1)
					end
					
					break
				end
				
				p0 = p1				
			end
		end		
	end
	
	--Update offset position
	local pos = VR:GetOffset()
	local d = self.targetoffset:DistanceToPoint(pos)
	local speed = 2.0
	if speed>d then speed=d end
	pos = pos + (self.targetoffset - pos):Normalize() * speed
	VR:SetOffset(pos)
	
end

function Script:Detach()
	self:DropObject(0)
	self:DropObject(1)
	self.teleportindicator:Release()
	self.teleportindicator = nil
	for n=1,self.maxbeamsteps do
		self.beam[n]:Release()
	end
	self.beam = nil
	self.camera:Release()
	self.camera = nil
end
