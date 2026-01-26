--!strict
export type Phase = "Init"|"Ready"

type RequiredModule = {
    [Phase]:() -> ()?
}

type ModuleThing = {
    [string]:RequiredModule
}


local RequiredModules:{[number]:ModuleThing} = {}
local PriorityTable:{number} = {}
local Recycler = require(script.Parent.MantisThreadRecycler)

local function RequireModules(ModuleParent:Instance)


    for _, Module:ModuleScript? in ModuleParent:GetDescendants() do
        if not Module:IsA("ModuleScript") then continue end

        local Success, Result = pcall(require, Module)
        
        if Success then
            local Priority = Module:GetAttribute("Priority") :: number
            if type(Priority) ~= "number" then 
                warn("[ModuleLoader] priority isn't a number for: ",Module.Name)
                Priority = 1
            end
            if not RequiredModules[Priority] then
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
    
    for _, Priority in PriorityTable  do
        local ModuleTable = RequiredModules[Priority]

        if not ModuleTable then continue end
        
        for _, Module in ModuleTable do
            
            local PhaseFunction = Module[Phase]
            
			if PhaseFunction and type(PhaseFunction) == "function" then
				Recycler.Defer(function()
					local Success, Err = pcall(PhaseFunction)
					if not Success then
						warn(`[ModuleLoader] error in {Phase}:`, Err)
					end
				end)
            end
            
        end
    end

end



local function LoadModules(ModulesToRequire:Instance)


    RequireModules(ModulesToRequire)
    
    print(RequiredModules)
    
    local StartTimeForPhase = os.clock()
    
    warn("<- Initialising modules ->")
    StartPhase("Init")
    
    warn("-> Took ", os.clock() - StartTimeForPhase, " seconds to Initialise modules <-")
    warn("<- Readying modules ->")
    
    StartTimeForPhase = os.clock()
    StartPhase("Ready")
    
    warn("-> Took ", os.clock() - StartTimeForPhase, " seconds to readying modules <-")
    
end



return LoadModules
