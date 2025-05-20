local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local _isServer = RunService:IsServer()
local _root = _isServer and ServerScriptService.Singletons or Players.LocalPlayer.PlayerScripts.Controllers
local _instance --to be singleton

local loadedPackages: { [string]: Package }

local Private = {}
local Public = {}
Public.__index = Public

type Package = {
	Name: string,
	Setup: () -> nil,
	Start: () -> nil,
	Contents: { [any]: any },
}

--Get the module loader
function Public.Get()
	if not _instance then
		_instance = setmetatable({}, Public)
	end
	return _instance
end

function Public.Import(package: string)
	return loadedPackages[package].Contents
end

function Public.Export(pkgName: string, contents: any)
	Private._loadPackage(pkgName, contents)
end

function Private._loadPackage(pkgName: string, contents: any)
	Public.InfoLog = `Loading package: {pkgName}`

	local s, result = pcall(require, contents) -- use pcall to avoid halting runtime

	if s then
		local _setup = result.setup
		local _start = result.start

		result.setup = nil
		result.start = nil

		local package: Package = {
			Name = pkgName,
			Setup = (type(_setup) == "function") and _setup,
			Start = (type(_start) == "function") and _start,
			Contents = result,
		}

		loadedPackages[pkgName] = package

		Public.InfoLog = `Successfully loaded package: {pkgName}`
	else
		Public.InfoLog = `Failed loading package: {pkgName}`
		warn(`Failed loading {_isServer and "' SERVER '" or "' CLIENT '"} PACKAGE: {pkgName}; {result}`)
	end
end

function Private._loadStartup()
	-- Shit for loading purposes
	Public.InfoLog = ""
	Public.RunContext = _isServer and "SERVER" or "CLIENT"

	local unloadedPackages = _root:GetChildren()
	loadedPackages = {}

	for _, unloadedPackage in unloadedPackages do
		if unloadedPackage.ClassName ~= "ModuleScript" then
			continue
		end
		Private._loadPackage(unloadedPackage.Name, unloadedPackage)
	end

	-- Setup phase
	for _: string, package in loadedPackages do
		package.Setup()
	end

	-- Start phase
	for _: string, package in loadedPackages do
		package.Start()
	end
end

Private._loadStartup()

return Public.Get
