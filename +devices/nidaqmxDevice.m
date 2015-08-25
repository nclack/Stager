function d=nidaqmxDevice

is_running=0;
active_channels=containers.Map();
d=struct(...
    'createAOChannel',@nidaqmxDeviceCreateAOChannel,...
    'createDOChannel',@nidaqmxDeviceCreateDOChannel,...
    'start',          @nidaqmxDeviceStart,...
    'stop',           @nidaqmxDeviceStop,...
    'isRunning',      @nidaqmxDeviceIsRunning);

    function nidaqmxDeviceCreateAOChannel(name,initialVoltage)
        if isKey(active_channels,name)
            error(['AO Channel conflict: ',name,' is already used.']);
        end
        try
            active_channels(name)=addAO(name,initialVoltage);
            disp(['Added AO channel: ' name]);
        catch e
            active_channels.remove(name);
            rethrow(e);
        end
    end

    function nidaqmxDeviceCreateDOChannel(name,initialState)
        if isKey(active_channels,name)
            error(['DO Channel conflict: ',name,' is already used.']);
        end
        try
            active_channels(name)=addDO(name,initialState);
            disp(['Added DO channel: ' name]);
        catch e
            active_channels.remove(name);
            rethrow(e);
        end        
    end

    function nidaqmxDeviceStart
        if isempty(active_channels), return; end
        is_running=1;
    end

    function nidaqmxDeviceStop        
        is_running=0;        
        active_channels=containers.Map();
        for task=active_channels.values()
            destroy(task{1});
        end       
    end
    function tf=nidaqmxDeviceIsRunning
        tf=is_running;
    end
end