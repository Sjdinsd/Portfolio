local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local _isServer = RunService:IsServer()
local _root = _isServer and ServerScriptService.Singletons or Players.LocalPlayer.PlayerScripts.Controllers
local _instance --to be singleton

local loadedModules: { [string]: Module<any, any> }

--[=[
    @class ModuleLoader
    
    Module loader for both client and server
]=]
local Private = {}
local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

type Module<A, B> = {
	Name: string,
	Setup: A,
	Start: B,
	Contents: { [any]: any },
}

--[=[
	Gets the module loader singleton for imports and exports
    
	@return any -- The required module loader
]=]
function ModuleLoader.Get()
	if not _instance then
		_instance = setmetatable({}, ModuleLoader)
	end
	return _instance
end

--[=[
	Imports module into the current script
    
	@param package : string -- The wanted module's name
	@return any -- The wanted module
]=]
function ModuleLoader.Import(package: string)
	return loadedModules[package].Contents
end

--[=[
	Exports module into the module loader, available for other scripts to access
    
	@param pkgName : string -- The new module's name
	@param contents : any -- The wanted module's content
	@return any -- The wanted module
]=]
function ModuleLoader.Export(pkgName: string, contents: any)
	Private._loadModule(pkgName, contents)
end

function Private._loadModule(pkgName: string, contents: any)
	ModuleLoader.InfoLog = `Loading package: {pkgName}`

	local s, result = pcall(require, contents) -- use pcall to avoid halting runtime

	if s then
		local _setup = result.setup
		local _start = result.start

		result.setup = nil
		result.start = nil

		local package: Module<any, any> = {
			Name = pkgName,
			Setup = (type(_setup) == "function") and _setup or nil,
			Start = (type(_start) == "function") and _start or nil,
			Contents = result,
		}

		loadedModules[pkgName] = package

		ModuleLoader.InfoLog = `Successfully loaded package: {pkgName}`
	else
		ModuleLoader.InfoLog = `Failed loading package: {pkgName}`
		warn(`Failed loading {_isServer and "' SERVER '" or "' CLIENT '"} PACKAGE: {pkgName}; {result}`)
	end
end

function Private._loadStartup()
	-- Shit for loading purposes
	ModuleLoader.InfoLog = ""
	ModuleLoader.RunContext = _isServer and "SERVER" or "CLIENT"
	ModuleLoader.FinishedLoadingModules = false

	local unloadedModules = _root:GetChildren()
	loadedModules = {}

	for _, unloadedModule in unloadedModules do
		if unloadedModule.ClassName ~= "ModuleScript" then
			continue
		end
		Private._loadModule(unloadedModule.Name, unloadedModule)
	end

	-- Setup phase
	for _: string, package in loadedModules do
		ModuleLoader.InfoLog = "Setting up package"
		if package.Setup == nil then
			continue
		end
		package.Setup()
	end

	-- Start phase
	for _: string, module in loadedModules do
		if module.Start == nil then
			continue
		end
		module.Start()
	end
end

Private._loadStartup()

return ModuleLoader.Get
