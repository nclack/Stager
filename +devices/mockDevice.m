function d=mockDevice

is_running=0;
active_channels=containers.Map();
d=struct(...
    'createAOChannel',@testDeviceCreateAOChannel,...
    'createDOChannel',@testDeviceCreateDOChannel,...
    'start',          @testDeviceStart,...
    'stop',           @testDeviceStop,...
    'isRunning',      @testDeviceIsRunning);

    function testDeviceCreateAOChannel(name,initialVoltage)
        if isKey(active_channels,name)
            error(['AO Channel conflict: ',name,' is already used.']);
        end
        active_channels(name)=initialVoltage;
        disp(['Added AO channel: ' name]);
    end
    function testDeviceCreateDOChannel(name,initialState)
        if isKey(active_channels,name)
            error(['DO Channel conflict: ',name,' is already used.']);
        end
        active_channels(name)=initialState;
        disp(['Added DO channel: ' name]);
    end
    function testDeviceStart
        if isempty(active_channels), return; end
        is_running=1;
        pause(0.5);
    end
    function testDeviceStop
        is_running=0;
        active_channels=containers.Map();
    end
    function tf=testDeviceIsRunning
        tf=is_running;
    end
end