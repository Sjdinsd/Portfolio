local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local GUI = Player.PlayerGui

local unloadedInputContexts = ReplicatedStorage.Assets.ActionMaps:GetChildren()
local loadedInputContexts: { [string]: InputContext }

local DEFAULT_ACTIVE_INPUT_CONTEXT = "UI"

local _activeInputContext: InputContext

--[=[
    @class InputController
    
    Client Input Controller using the (as of now) beta [IAS](https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214?u=kaister70000)
]=]
local Private = {}
local InputController = {}
InputController.__index = InputController

--[=[
	Sets the current InputContext to be used.

	@param context string -- The name of the context to activate
	@return bool, any -- Returns whether or not it was successful and if not an error message
]=]
function InputController.ActivateInputContext(context: string)
	-- Set the current activated input context to false
	-- Set the specified one to true
	-- Hope ts works, its in beta
end

--[=[
	Returns a dictionary from the active InputContext with the keycode being the key, and its name being the value.

	@return {} : {[number] : InputBinding}
]=]
function InputController.GetActiveBinds()
	local activeBinds = {}

	for _, inputBinding: Instance in _activeInputContext:GetChildren() do
		if inputBinding.ClassName ~= "InputBinding" then
			continue
		end
		table.insert(activeBinds, inputBinding)
	end

	return activeBinds
end

-- Loads from InputContexts to player ui
function InputController.setup()
	loadedInputContexts = {}
	for _, inputContext: InputContext in unloadedInputContexts do
		inputContext.Enabled = false
		inputContext.Parent = GUI.Input

		loadedInputContexts[inputContext.Name] = inputContext
	end
end

-- set the active input context and go
function InputController.start()
	_activeInputContext = loadedInputContexts[DEFAULT_ACTIVE_INPUT_CONTEXT]
	_activeInputContext.Enabled = true
end

return InputController
