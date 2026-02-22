--!strict
local TestService = game:GetService("TestService")

export type Phase = "Init"|"Ready"

type RequiredModule = {
    [Phase]:() -> ()?
}

type ModuleThing = {
    [string]:RequiredModule
}

local Recycler = require("./ThreadRecycler")

local RequiredModules:{[number]:ModuleThing} = {}
local PriorityTable:{number} = {}

local verbosePrints = false

local function verbose(...)
	if verbosePrints == true then
		warn(...)
	end
end

local function RequireModules(ModuleParent:Instance)

    for _, Module in ModuleParent:QueryDescendants("ModuleScript") ::{ModuleScript} do
		if Module:GetAttribute("Disabled") == true then continue end
		
        local Success, Result = pcall(require, Module)
        
        if Success == true then
            local Priority = Module:GetAttribute("Priority") :: number
            if typeof(Priority) ~= "number" then 
                warn("[ModuleLoader] priority isn't a number for: ",Module.Name)
                Priority = 1
            end
            if RequiredModules[Priority] == nil then
                RequiredModules[Priority] = {}
                table.insert(PriorityTable, Priority)
            end

            RequiredModules[Priority][Module.Name] = Result
        else
            warn("[ModuleLoader] failed to require: ", Module.Name, Result)
        end
        
    end
    table.sort(PriorityTable, function(a:number, b:number)
        return a < b
    end)
end 

local function StartPhase(Phase:Phase)

	local running = 0

    for _, Priority in PriorityTable  do
        local ModuleTable = RequiredModules[Priority]

        if ModuleTable == nil then continue end

        for _, Module in ModuleTable do

			local PhaseFunction = Module[Phase]

			if PhaseFunction and typeof(PhaseFunction) == "function" then

				running += 1

				Recycler.Defer(function()
					local Success, Err = pcall(PhaseFunction)
					if Success == false then
						warn(`[ModuleLoader] error in {Phase}:`, Err)
					end
					running -= 1
				end)
			end
		end
		while running > 0 do
			task.wait()
		end
	end
	
	

end



local function LoadModules(ModulesToRequire:Instance, prettyPrint:boolean?)


    RequireModules(ModulesToRequire)
    
    local StartTimeForPhase = os.clock()
    
	verbose("<- Initialising modules ->")
    StartPhase("Init")
    
	verbose("-> Took ", os.clock() - StartTimeForPhase, " seconds to Initialise modules <-")
	verbose("<- Readying modules ->")
    
    StartTimeForPhase = os.clock()
    StartPhase("Ready")
    
    verbose("-> Took ", os.clock() - StartTimeForPhase, " seconds to readying modules <-")
	
	
	table.clear(RequiredModules)
	table.clear(PriorityTable)
	
	if prettyPrint == true then
		TestService:Message("Successfuly compiled No Pain, No Gain framework")
	end
	
end



return LoadModules
