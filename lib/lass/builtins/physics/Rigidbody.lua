local lass = require("lass")
local class = require("lass.class")
local geometry = require("lass.geometry")
local Collider = require("lass.builtins.physics.Collider")

local Rigidbody = class.define(lass.Component, function(self, arguments)

	arguments.velocity = geometry.Vector2(arguments.velocity)

	self.base.init(self, arguments)
end)

local function shapeToPhysicsShape(self, shape, physicsShape, oldTransform)
	-- create or modify a physics shape using a geometry.Shape

	-- only Circle physics shapes can be modified, which makes this function's signature
	-- somewhat complicated:

	-- if physicsShape is not specified, return a new physics shape.
	-- if shape and physicsShape are not the same shape type, return a new physics shape.
	-- if shape and physicsShape are circles, modify physicsShape and return nil.
	-- if shape and physicsShape are polygons, and self.globalTransform == oldTransform,
	-- do nothing and return nil.
	-- if shape and physicsShape are polygons, and self.globalTransform ~= oldTransform,
	-- return a new physics shape.

	-- all of this is to say: if you specify physicsShape and this function returns a new
	-- physics shape, you should destroy the old shape and replace it with the new one.

	local transform = geometry.Transform(self.gameObject.globalTransform)

	-- we want the global size of the shape, but not the global position or rotation
	-- (we will use the rotation for the body, but not the fixture)
	transform.position = geometry.Vector3(0,0,0)
	transform.rotation = 0

	if shape.class == geometry.Rectangle or shape.class == geometry.Polygon then

		if physicsShape and oldTransform then

			-- we can't directly edit the vertices of a PolygonShape.
			-- if we have a reason to change them, create a new PolygonShape.
			-- else, return nothing
			if
				-- oldTransform.r ~= transform.r or
				oldTransform.size.x ~= transform.size.x or
				oldTransform.size.y ~= transform.size.y or
				not physicsShape:typeOf("PolygonShape")
			then
				local verts = shape:globalVertices(transform)
				for i, vert in ipairs(verts) do
					vert.y = vert.y * self.globals.ySign
				end
				return love.physics.newPolygonShape(unpack(geometry.flattenedVector2Array(verts)))
			end
		else
			local verts = shape:globalVertices(transform)
			for i, vert in ipairs(verts) do
				vert.y = vert.y * self.globals.ySign
			end
			return love.physics.newPolygonShape(unpack(geometry.flattenedVector2Array(verts)))
		end

	elseif shape.class == geometry.Circle then
		local cir = shape:globalCircle(transform)

		-- thankfully, we can directly edit the radius and center of a CircleShape
		if physicsShape and physicsShape:typeOf("CircleShape") then
			physicsShape:setRadius(cir.radius)
			physicsShape:setPoint(cir.position.x, cir.position.y * self.globals.ySign)
		else
			return love.physics.newCircleShape(cir.position.x, cir.position.y * self.globals.ySign, cir.radius)
		end
	end
end

-- function Rigidbody:getVelocity()

-- 	local x, y = self.body:getLinearVelocity()
-- 	return geometry.Vector2(x, y)
-- end

-- function Rigidbody:setVelocity(...)

-- 	if not self.body then
-- 		self._velocity = geometry.Vector2(...)
-- 	else
-- 		local v = geometry.Vector2(...)
-- 		self.body:setLinearVelocity(v.x,v.y)
-- 	end
-- end

function Rigidbody.__get.velocity(self)

	local v = geometry.Vector2(self.body:getLinearVelocity())

	v.callback = function(object, key, value)
		local vel = self.velocity

		if key == "x" then
			self.velocity = geometry.Vector2(value, vel.y)
		elseif key == "y" then
			self.velocity = geometry.Vector2(vel.x, value)
		end
	end

	return v
end

function Rigidbody.__set.velocity(self, value)

	if not self.body then
		self._velocity = value
	else
		self.body:setLinearVelocity(value.x, value.y)
	end
end

function Rigidbody.__get.angularVelocity(self)

	local r = self.body:getAngularVelocity()
	return math.deg(r)
end

function Rigidbody.__set.angularVelocity(self, r)

	self.body:setAngularVelocity(math.rad(r))
end

function Rigidbody:awake()

	self.body = love.physics.newBody(self.globals.physicsWorld, 0, 0, "dynamic")

	local p = self.gameObject.globalTransform.position
	self.body:setPosition(p.x, p.y * self.globals.ySign)
	self.body:setAngle(math.rad(self.gameObject.globalTransform.rotation))

	if self._velocity then
		self.velocity = self._velocity
		self._velocity = nil
	end

	local colliders = self.gameObject:getComponents(Collider)
	self.fixtures = {}

	for i, collider in ipairs(colliders) do
		local fix = love.physics.newFixture(self.body, shapeToPhysicsShape(self, collider.shape), 1)
		fix:setRestitution(collider.restitution)
		self.fixtures[fix] = collider
	end

	self.gameScene:addEventListener("physicsPreUpdate", self.gameObject, true)
	self.gameScene:addEventListener("physicsPostUpdate", self.gameObject, true)
end

function Rigidbody:deactivate()

	self.body:destroy()
	self.base.deactivate(self)
end

function Rigidbody:update()

	-- local transform = self.gameObject.globalTransform

	-- if
	-- 	self._oldTransform.position.x ~= transform.x or
	-- 	self._oldTransform.position.y ~= transform.y
	-- then
	-- 	self.body:setPosition(transform.position.x, transform.position.y--[[ / self.globals.pixelsPerMeter]])
	-- end

	for i, fixture in ipairs(self.body:getFixtureList()) do
		local collider = self.fixtures[fixture]

		if not collider then
			fixture:destroy()
		else
			local shape = shapeToPhysicsShape(self, collider.shape, fixture:getShape(), self._oldTransform)

			-- if shape, then we weren't able to modify the existing fixture.
			-- we need to replace it
			if shape then
				self.fixtures[fixture] = nil
				fixture:destroy()
				fixture = love.physics.newFixture(self.body, shape, 6)
				fixture:setRestitution(collider.restitution)
				self.fixtures[fixture] = collider
			end
		end
	end

	-- debug.log(self.gameObject.globalTransform.position)
end

function Rigidbody.events.physicsPreUpdate.play(self, source, data)

	local transform = self.gameObject.globalTransform

	-- if the transform has changed independently of physics transformations,
	-- we need to reset the body position and rotation
	-- (the size is accounted for in the fixture update)
	if
		self._oldTransform and (
			self._oldTransform.position.x ~= transform.position.x or
			self._oldTransform.position.y ~= transform.position.y
		)
	then
		self.body:setPosition(transform.position.x, transform.position.y * self.globals.ySign)
		self.body:setAngle(math.rad(transform.rotation))
		self.body:setAwake(true)
	end
end

function Rigidbody.events.physicsPostUpdate.play(self, source, data)

	local x,y = self.body:getPosition()
	self.gameObject:moveToGlobal(x, y * self.globals.ySign)

	local angle = math.deg(self.body:getAngle())
	self.gameObject.transform.rotation = angle - self.gameObject.parent.globalTransform.rotation

	self._oldTransform = geometry.Transform(self.gameObject.globalTransform)
end

return Rigidbody
