export type Thread<A = any> = {
	Spawn: (Function:(...A) -> (), ...A) -> thread,
	Defer: (Function:(...A) -> (), ...A) -> thread,
	Delay: (Duration:number,Function:(...A) -> (), ...A) -> thread,
}

local Threads = {} ::{thread}

local function _ThreadMaker3000(Function:(...any) -> (), thread:thread, ...:any)
	Function(...)
	table.insert(Threads, thread)
end

local function _Yield()
	while true do _ThreadMaker3000(coroutine.yield()) end
end

local function GetThread():thread
	local Length, Thread = #Threads, nil
	if Length == 0 then
		Thread = coroutine.create(_Yield)
		coroutine.resume(Thread)
		return Thread
	else
		Thread = Threads[Length]
		Threads[Length] = nil
		if coroutine.status(Thread) ~= "suspended" then return GetThread() end
	end
	return Thread
end

local Module = {} :: Thread<any>

function Module.Spawn(Function, ...)
	local Thread = GetThread()
	return task.spawn(Thread, Function,Thread, ...)
end

function Module.Defer(Function, ...)
	local Thread = GetThread()
	return task.defer(Thread, Function,Thread, ...)
end

function Module.Delay(Duration, Function, ...)
	local Thread = GetThread()
	return task.delay(Duration, Thread, Function,Thread, ...)
end

return Module
