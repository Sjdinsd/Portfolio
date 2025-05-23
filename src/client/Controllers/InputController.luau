--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local GUI = Player.PlayerGui

local unloadedInputContexts = ReplicatedStorage.Assets.ActionMaps:GetChildren()
local loadedInputContexts: { [string]: InputContext }

local DEFAULT_ACTIVE_INPUT_CONTEXT = "UI"

local _activeInputContext: InputContext

--[=[
    @type PackagedInputContext {Name: string,Actions : { [string]: { number } }}
    @within InputController
    A packaged input context used for input handling
]=]
export type PackagedInputContext = {
	Name: string,
	Actions: { [string]: { [number]: boolean } }, -- {[ActionName]: {[KeyCode]: true}}
}

--[=[
    @class InputController
    
    Client Input Controller using the (as of now) beta [IAS](https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214?u=kaister70000)
]=]
-- local Private = {}
local InputController = {}
InputController.__index = InputController

--[=[
	Sets the current [InputContext] to be used.

	@param context string -- The name of the context to activate
	@return bool, any -- Returns whether or not it was successful and if not an error message
]=]
function InputController.ActivateInputContext(context: string)
	-- Set the current activated input context to false
	-- Set the specified one to true
	-- Hope ts works, its in beta
	if _activeInputContext then
		_activeInputContext.Enabled = false
	end
	_activeInputContext = loadedInputContexts[context]
	_activeInputContext.Enabled = true
end

--[=[
	Returns a dictionary of [InputAction] from the current [InputContext] 

	@return {} : {[number] : InputAction}
]=]
function InputController.GetActiveActions()
	local activeActions = {}

	for _, inputAction: Instance in _activeInputContext:GetChildren() do
		if inputAction.ClassName ~= "InputAction" then
			continue
		end
		table.insert(activeActions, inputAction)
	end

	return activeActions
end

function InputController.GetActionFromActiveContext(action: string): InputAction | nil
	if not _activeInputContext[action] then
		warn(`ACTION: {action} DOES NOT EXIST IN: {_activeInputContext.Name}`)
		return false
	end

	return _activeInputContext[action]
end

function InputController.GetActionFromContext(context: string | InputContext, action: string): InputAction | nil
	local targetContext = typeof(context) == "string" and loadedInputContexts[context] or context
	if not targetContext then
		warn(`CONTEXT: {context} DOES NOT EXIST OR IS NOT LOADED`)
		return false
	end

	if not targetContext[action] then
		warn(`ACTION: {action} DOES NOT EXIST IN: {targetContext.Name}`)
		return false
	end

	return targetContext[action]
end

--[=[
	Adds a new [InputBinding] to a specified [InputAction] of the current [InputContext]

	@param action string -- Name of the [InputAction]
	@param bindKeyCode Enum.KeyCode -- The [KeyCode] to bind
	@return boolean
]=]
function InputController.AddBindToActiveContext(action: string, bindKeyCode: Enum.KeyCode)
	if not _activeInputContext[action] then
		warn(`ACTION: {action} DOES NOT EXIST IN: {_activeInputContext.Name}`)
		return false
	end

	local newBind = Instance.new("InputBinding")
	newBind.Name = bindKeyCode.Name
	newBind.KeyCode = bindKeyCode
	newBind.Parent = _activeInputContext[action]

	return true
end

--[=[
	Adds a new [InputBinding] to a specified [InputAction] of a specified [InputContext]

	@param context string | InputContext -- Name of the context, or the context itself to bind to
	@param action string -- Name of the [InputAction]
	@param bindKeyCode Enum.KeyCode -- The [KeyCode] to bind
	@return boolean
]=]
function InputController.AddBindToContext(context: string | InputContext, action: string, bindKeyCode: Enum.KeyCode): boolean
	local targetContext = typeof(context) == "string" and loadedInputContexts[context] or context
	if not targetContext then
		warn(`CONTEXT: {context} DOES NOT EXIST OR IS NOT LOADED`)
		return false
	end

	local targetAction = targetContext:FindFirstChild(action) -- Assuming actions are children of the context
	if not targetAction or targetAction:IsA("InputAction") == false then
		warn(`ACTION: {action} DOES NOT EXIST IN: {typeof(context) == "string" and context or targetContext.Name}`)
		return false
	end

	local newBind = Instance.new("InputBinding")
	newBind.Name = bindKeyCode.Name
	newBind.KeyCode = bindKeyCode
	newBind.Parent = targetAction
	return true
end

--[=[
	Adds a new [InputAction] to the active [InputContext] with optional binds

	@param actionName string -- Name of the [InputAction]
	@param enabled boolean?
	@param actionType Enum.InputActionType? 
	@param suppliedBinds { [number]: Enum.KeyCode }? -- Binds to parent to the action
	@return boolean
]=]
function InputController.AddActionToActiveContext(
	actionName: string,
	enabled: boolean?,
	actionType: Enum.InputActionType?,
	suppliedBinds: { [number]: Enum.KeyCode }?
)
	if not actionName then
		warn("ACTION NEEDS NAME")
		return
	end

	local newAction = Instance.new("InputAction")
	newAction.Name = actionName
	newAction.Type = actionType or Enum.InputActionType.Bool
	newAction.Enabled = enabled or true
	newAction.Parent = _activeInputContext

	if suppliedBinds then
		for _, keyCode in pairs(suppliedBinds) do
			InputController.AddBindToActiveContext(actionName, keyCode)
		end
	end

	return true
end

--[=[
	Adds a new [InputAction] to a specified [InputContext] with optional binds

	@param context string | InputContext -- Name of the context, or the context itself
	@param actionName string -- Name of the [InputAction]
	@param enabled boolean?
	@param actionType Enum.InputActionType? 
	@param suppliedBinds { [number]: Enum.KeyCode }? -- Binds to parent to the action
	@return boolean
]=]
function InputController.AddActionToContext(
	context: string | InputContext,
	actionName: string,
	enabled: boolean?,
	actionType: Enum.InputActionType?,
	suppliedBinds: { [number]: Enum.KeyCode }?
)
	local targetContext = typeof(context) == "string" and loadedInputContexts[context] or context
	if not targetContext then
		warn(`CONTEXT: {context} DOES NOT EXIST OR IS NOT LOADED`)
		return false
	end
	if not actionName then
		warn("ACTION NEEDS NAME")
		return false
	end

	local newAction = Instance.new("InputAction")
	newAction.Name = actionName
	newAction.Type = actionType or Enum.InputActionType.Bool
	newAction.Enabled = enabled or true
	newAction.Parent = targetContext

	if suppliedBinds then
		for _, keyCode in pairs(suppliedBinds) do
			InputController.AddBindToContext(context, actionName, keyCode)
		end
	end

	return true
end

--[=[
	Loads a [InputContext] to the [InputController]

	@param context InputContext -- The context itself to load
	@return boolean
]=]
function InputController.LoadContext(context: InputContext)
	context.Enabled = false
	context.Parent = GUI.Input

	loadedInputContexts[context.Name] = context
end

--[=[
	Packages the active [InputContext] to be saved for input mapping

	@return PackagedInputContext
]=]
function InputController.PackageActiveContext(): PackagedInputContext
	local packagedContext: PackagedInputContext = {}

	local unprocessedActions: { [number]: InputAction } = _activeInputContext:GetChildren()
	local actions: { [string]: number } = {}

	for _, action: InputAction in unprocessedActions do
		if action.ClassName ~= "InputAction" then
			continue
		end

		actions[action.Name] = {}

		for bind in action:GetChildren() do
			if bind.ClassName ~= "InputBinding" then
				continue
			end
			table.insert(actions[action.Name], bind.KeyCode.Value)
		end
	end

	packagedContext.Name = _activeInputContext.Name
	packagedContext.Actions = actions

	return packagedContext
end

--[=[
	Packages a specified [InputContext] to be saved for input mapping

	@param context string | InputContext -- Name of the context, or the context
	@return PackagedInputContext
]=]
function InputController.PackageContext(context: string | InputContext): PackagedInputContext
	local packagedContext: PackagedInputContext = {}
	local targetContext = typeof(context) == "string" and loadedInputContexts[context] or context

	if not targetContext then
		warn(`CONTEXT: {context} DOES NOT EXIST OR IS NOT LOADED`)
		return false
	end

	local unprocessedActions: { [number]: InputAction } = targetContext:GetChildren()
	local actions: { [string]: number } = {}

	for _, action: InputAction in unprocessedActions do
		if action.ClassName ~= "InputAction" then
			continue
		end

		actions[action.Name] = {}

		for bind in action:GetChildren() do
			if bind.ClassName ~= "InputBinding" then
				continue
			end
			table.insert(actions[action.Name], bind.KeyCode.Value)
		end
	end

	packagedContext.Name = targetContext.Name
	packagedContext.Actions = actions

	return packagedContext
end

-- Loads from InputContexts to player ui
function InputController.setup()
	loadedInputContexts = {}
	for _, inputContext: InputContext in unloadedInputContexts do
		InputController.LoadContext(inputContext)
	end
end

-- set the active input context and go
function InputController.start()
	InputController.ActivateInputContext(DEFAULT_ACTIVE_INPUT_CONTEXT)
end

return InputController
