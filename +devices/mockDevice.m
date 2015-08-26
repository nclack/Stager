function d=mockDevice

is_running=0;
active_channels=containers.Map();
d=struct(...
    'createAOChannel',@testDeviceCreateAOChannel,...
    'createDOChannel',@testDeviceCreateDOChannel,...
    'writeAO',        @testWriteAO,...
    'writeDO',        @testWriteDO,...
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
    function testWriteAO(name,value)
        assert(active_channels.isKey(name));
        disp(['Output analog ',num2str(value),' Volts for ', name]);
    end
    function testWriteDO(name,value)
        assert(active_channels.isKey(name));
        disp(['Output digital ',num2str(value),' for ', name]);
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