--[[
	Displays an animated SelectionBox adornment on the hovered Workspace object.
]]

-- Services
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local DraggerFramework = script.Parent.Parent
local Packages = DraggerFramework.Parent
local Roact = require(Packages.Roact)

local ANIMATED_HOVER_BOX_UPDATE_BIND_NAME = "AnimatedHoverBoxUpdate"
local MODEL_LINE_THICKNESS_SCALE = 2.5

local getFFlagDraggerFrameworkFixes = require(DraggerFramework.Flags.getFFlagDraggerFrameworkFixes)

--[[
	Return a hover color that is a blend between the Studio settings HoverOverColor
	and SelectColor, based on the current time and HoverAnimateSpeed.
]]
local function getHoverColorForTime(color1, color2, animatePeriod, currentTime)
	local alpha = 0.5 + 0.5 * math.sin(currentTime / animatePeriod * math.pi)
	return color2:lerp(color1, alpha)
end

local AnimatedHoverBox = Roact.PureComponent:extend("AnimatedHoverBox")

function AnimatedHoverBox:init(initialProps)
	assert(initialProps.HoverTarget, "Missing required property 'HoverTarget'.")
	assert(initialProps.SelectColor, "Missing required property 'SelectColor'.")
	assert(initialProps.HoverColor, "Missing required property 'HoverColor'.")
	assert(initialProps.LineThickness, "Missing required property 'LineThickness'.")
	assert(initialProps.SelectionBoxComponent, "Missing required property 'SelectionBoxComponent'.")

	self:setState({
		currentColor = getHoverColorForTime(
			self.props.SelectColor, self.props.HoverColor, self.props.AnimatePeriod or math.huge, 0),
	})

	self._isMounted = false
	self._startTime = 0

	if getFFlagDraggerFrameworkFixes() then
		local guid = HttpService:GenerateGUID(false)
		self._bindName = ANIMATED_HOVER_BOX_UPDATE_BIND_NAME .. "_" .. guid
	end
end

function AnimatedHoverBox:didMount()
	self._isMounted = true
	self._startTime = tick()

	local bindName = getFFlagDraggerFrameworkFixes() and self._bindName or ANIMATED_HOVER_BOX_UPDATE_BIND_NAME
	RunService:BindToRenderStep(bindName, Enum.RenderPriority.First.Value, function()
		if self._isMounted then
			local deltaT = tick() - self._startTime
			self:setState({
				currentColor = getHoverColorForTime(
					self.props.SelectColor, self.props.HoverColor, self.props.AnimatePeriod or math.huge, deltaT)
			})
		end
	end)
end

function AnimatedHoverBox:willUnmount()
	self._isMounted = false

	local bindName = getFFlagDraggerFrameworkFixes() and self._bindName or ANIMATED_HOVER_BOX_UPDATE_BIND_NAME
	RunService:UnbindFromRenderStep(bindName)
end

function AnimatedHoverBox:render()
	if not self.props.HoverTarget then
		return nil
	end

	local lineThickness = self.props.LineThickness
	if self.props.HoverTarget:IsA("Model") then
		lineThickness = lineThickness * MODEL_LINE_THICKNESS_SCALE
	end

	--return Roact.createElement(self.props.SelectionBoxComponent, {
	--	Adornee = self.props.HoverTarget,
	--	Color3 = self.state.currentColor,
	--	LineThickness = lineThickness,
	--})
	return Roact.createElement("Highlight", {
		Adornee = self.props.HoverTarget,
		OutlineColor = self.state.currentColor,
		OutlineTransparency = 0,
		FillColor = self.state.currentColor,
		FillTransparency = 1,
	})
end

return AnimatedHoverBox
