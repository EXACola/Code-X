
local RunService = game:GetService('RunService')

local code = {}
local PublicRendering = {};
local ThreadCheck = {}

setmetatable(ThreadCheck,{
    __index = function(self,key)
        self[tostring(key)] = 0;
        return 0;
    end,
})

--getrenv().getfenv = false;
code.cleaning = function(env)
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

code.secure_call = function(Function,fromscript,...)
    if (not Function or not fromscript) then 
        warn('code.secure_call Error..')
        return 
    end;

    local old_traceback = getrenv().debug.traceback;
    local old_getexecutorname = getgenv().getexecutorname;

    setreadonly(getrenv().debug,false);

    getgenv().getexecutorname = nil;
    getrenv().debug.traceback = function()
        return tostring(fromscript:GetFullName());
    end;
    
    local Calling = Function(...)

    getrenv().debug.traceback = old_traceback;
    getgenv().getexecutorname = old_getexecutorname;
    setreadonly(getrenv().debug,true);

    return Calling;
end;

code.sleep = function(time)
    return task.wait(time);
end;

code.secure_require = function(Module)
    if (not Module or not Module:IsA('ModuleScript')) then 
        return 
    end;

    local env = require(Module)
    local mt = getrawmetatable(env);

    if (not mt) then 
        return env;
    end;

    if (mt.__tostring) then 
        mt.__tostring = nil;    
    end;

    return env;
end;

code.rendering = function(Function,Mode)
    if (not Function or type(Function) ~= 'function') then 
        warn('args 1 is not function', type(Function))
        return;
    end;

    local InProgress;
    local rendering = RunService.Heartbeat:Connect(function()
        if (not InProgress and not Mode) then 
            InProgress = true;
            Function();
            InProgress = false;
        end;
        
        if Mode then 
            Function();
        end;
    end);

    return rendering;
end;

code.public_rendering = function(Function,mode)
    if (not Function or type(Function) ~= 'function') then 
        warn('args 1 is not function')
        return;
    end;

    local newTask = {
        Thread = Function,
        Mode = mode,
        Running = true;  
    }

    table.insert(PublicRendering,newTask);

    if (not code.main_rendering) then 
        local MyThread = 1;
        code.main_rendering = RunService.Heartbeat:Connect(function()
            if (MyThread > #PublicRendering) then 
                MyThread = 1;
            end;
            
            local threadnumber = MyThread;
            MyThread+=1;

            local asset = PublicRendering[threadnumber];
            
            if (not asset) then 
                return;
            end;

            if (not asset.Running) then 
                table.remove(PublicRendering,table.find(PublicRendering,asset))
            end;

            if (asset.Mode) then 
                asset.Thread();
                return;
            end;

            if (ThreadCheck[threadnumber] == 0) then 
                ThreadCheck[threadnumber] = 1;
                asset.Thread();
                ThreadCheck[threadnumber] = 0;
            end;
        end);
    end;

    return newTask;
end;

code.public_rendering_clear = function()
    if (code.main_rendering) then 
        code.main_rendering:Disconnect();
        code.main_rendering = nil;
    end;

    return true;
end;

code.secure_thread = function(func,...)
    local args = { ... };
    if not type(func) == 'function' then return end;

    local success,errorcode = pcall(func,...);
    return success,errorcode;
end;

code.protect_call = function(...)
    return pcall(...);
end;

return code;
