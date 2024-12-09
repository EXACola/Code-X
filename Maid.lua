local Maid = {};
Maid.Cache = {}; 

local function cleaning(env)
    if (not env) then 
        return;
    end;

    if (typeof(env) == 'thread') then 
        task.cancel(env)
    elseif (typeof(env) == 'function') then 
        env = nil;
    elseif (typeof(env) == 'table') then 
        env:Remove()
    elseif (typeof(env) == 'RBXScriptConnection') then 
        env:Disconnect();
    elseif (typeof(env) == 'Instance' or env.Destroy) then 
        env:Destroy();
    end;
end;

function Maid.new()
    local latestCache = #Maid.Cache
    Maid.Cache[latestCache+1] = {_env={}}

    return setmetatable(Maid.Cache[latestCache+1],Maid)
end;

function Maid.__index(self,key)
    if (Maid[key]) then 
        return Maid[key];
    end;

    return self._env[key]
end;

function Maid:GiveTask(thread,key)

    if (not thread) then 
        warn('Please assign me a job...')
    end;

    local latestTask = #self._env

    if (not key) then 
        table.insert(self._env,thread)
        return self._env[latestTask+1] 
    end;

    if (not key or type(key) ~= 'string') then 
        warn('Error: Maid.Order')
        return;
    end;

    self._env[key] = thread;


    return self._env[key];
end;

function Maid:GetTasks()
    return Maid.Cache;
end;

function Maid:ClearTask()
    local myTask = self._env    

    for _,env in next, myTask do 
        cleaning(env);
    end;

    table.clear(myTask);
end;

function Maid.ClearCache()
    for _,cache in next, Maid.Cache do 
        if (cache and type(cache) == 'table' and cache._env) then 
            for __,env in next, cache._env do 
                cleaning(env);
            end;
        end;
    end;

    warn('Maid: ClearCache');
end;

return Maid;
