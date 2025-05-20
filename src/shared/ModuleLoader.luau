local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local _isServer = RunService:IsServer()
local _root = _isServer and ServerScriptService.Singletons or Players.LocalPlayer.PlayerScripts.Controllers
local _instance --to be singleton

local loadedPackages: { [string]: Package }

local Public = {}
local Private = {}
Private.__index = Private

type Package = {
	Setup: () -> nil,
	Start: () -> nil,
	Contents: { [any]: any },
}

function Public:Import(package: string)
	return loadedPackages[package].Contents
end

function Public:Export(pkgName: string, contents: any)
	Private._loadPackage(pkgName, contents)
end

function Private._loadPackage(pkgName: string, contents: any)
	local s, result = pcall(require, contents) -- use pcall to avoid halting runtime

	if s then
		local _setup = result.setup
		local _start = result.start

		result.setup = nil
		result.start = nil

		local package: Package = {
			Setup = (type(_setup) == "function") and _setup,
			Start = (type(_start) == "function") and _start,
			Contents = result,
		}

		loadedPackages[pkgName] = package
	else
		warn(`FAILED LOADING {_isServer and "' SERVER '" or "' CLIENT '"} PACKAGE: {pkgName}; {result}`)
	end
end

function Private._loadStartup()
	local unloadedPackages = _root:GetChildren()

	loadedPackages = {}

	for _, unloadedPackage in unloadedPackages do
		if unloadedPackage.ClassName ~= "Module" then
			continue
		end

		local s, result = pcall(require, unloadedPackage) -- use pcall to avoid halting runtime

		if s then
			local _setup = result.setup
			local _start = result.start

			result.setup = nil
			result.start = nil

			local package: Package = {
				Setup = (type(_setup) == "function") and _setup,
				Start = (type(_start) == "function") and _start,
				Contents = result,
			}

			loadedPackages[unloadedPackage.Name] = package
		else
			warn(`FAILED LOADING {_isServer and "' SERVER '" or "' CLIENT '"} PACKAGE: {unloadedPackage.Name}`)
		end
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

return setmetatable({}, Public)
