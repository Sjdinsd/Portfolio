--[=[
	@class InputController
    
	Public class representing the Input Controller
]=]
local Private = {}
local InputController = {}
InputController.__index = InputController

--[=[
	Sets the current input context to be used

	@param context string -- The name of the context to activate
	@return bool, string -- Returns whether or not it was successful and if not an error message
]=]
function InputController.ActivateInputContext(context: string)
	-- Set the current activated input context to false
	-- Set the specified one to true
	-- Hope ts works its in beta
end

-- Loads from replicated storage to player ui
function Private.LoadInputActionConexts() end

return InputController
