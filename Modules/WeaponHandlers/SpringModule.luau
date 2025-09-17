local SPRING = {}

function SPRING.new(self,constant,mass,velocity,damping,speed,target)
	local spring = {
		Position = Vector3.new(0,0,0);
		Velocity = Vector3.new();
		Target = Vector3.new(0,0,0);
		
		Mass = mass or 1;
		Constant = constant or 10;
		Damping = damping or 4;
		Speed = speed or 4;
	}
	
	function spring.add(self,velocity)
		self.Velocity = self.Velocity + velocity
	end
	
	function spring.move(self,target)
		self.Target = target
	end
	
	function spring.update(self,dt)
		
		local displacement = self.Target- self.Position
		local scalarAcceleration = 0.5 * self.Constant * displacement.Magnitude / self.Mass
		local acceleration
		
		if scalarAcceleration ~= 0 then
			acceleration = displacement.Unit * scalarAcceleration
		else
			acceleration = Vector3.new(0,0,0)
		end
		
		local scaledDeltaTime = (dt*self.Speed)		
		self.Velocity += acceleration * scaledDeltaTime
		self.Position += self.Velocity * scaledDeltaTime
		self.Velocity = self.Velocity - self.Velocity * (self.Damping * scaledDeltaTime) / (dt*60)
		
		return self.Velocity, self.Position
	end
	
	return spring
end

return SPRING