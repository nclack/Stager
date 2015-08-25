function out=aoguitest

device=createDevice();
configs=struct('jim',[],'bob',[]);

% function out=aogui(getRoiNames,getConfigForROIByName,setConfigForROIByName,start,stop,varargin)
gui=aogui(...
    @() fieldnames(configs),...
    @get,...
    @set,...
    @start,...
    @stop);

out=struct(...
    'gui',gui,...
    'pushDataForROIByName',@pushDataForROIByName);

    %% bindings for gui
    function value=get(key)
        if isfield(configs,key)
            value=configs.(key);
        else
            value=[];
        end
    end

    function set(key,value)
        configs.(key)=value;
    end

    function start
        disp('start')
        for key=fieldnames(configs)'
            c=get(key{1});
            if isempty(c),c=gui.getDefaultConfig(); end;
            for name = fieldnames(c)
                for o=c.ao(find(c.ao(:).Enable)) %#ok<FNDSB>
                    device.createAOChannel(o.ChannelName,0)
                end
                for o=c.do(find(c.do(:).Enable)) %#ok<FNDSB>
                    initialState=strcmpi(o.TriggeredState,'low');
                    device.createDOChannel(o.ChannelName,initialState);
                end
            end
        end
        device.start();
        gui.notifyIsRunning(device.isRunning());
    end

    function stop
        device.stop(); % should release all channels
        disp('stop')
    end

    %% interface for pushing data        
    function pushDataForROIByName(key,v)
        if(device.isRunning())
            c=get(key);
            if isempty(c),c=gui.getDefaultConfig();end;
            MasterTransform=eval(c.MasterTransform);
            for o=c.ao(find(c.ao(:).Enable)) %#ok<FNDSB>
                ChannelTransform=eval(o.Transform);
                vv=ChannelTransform(MasterTransform(v));
                disp(['Output analog ',num2str(vv),' Volts for ', o.ChannelName]);
            end
            for o=c.do(find(c.do(:).Enable)) %#ok<FNDSB>
                ChannelTransform=eval(o.Transform);
                vv=ChannelTransform(MasterTransform(v));
                if strcmpi(o.TriggeredState,'high')
                    vv=vv>o.Threshold;
                else
                    vv=vv<=o.Threshold;
                end
                disp(['Output digital ',num2str(vv),' for ', o.ChannelName]);
            end                
        end
    end

    %% Device interface
    function d=createDevice
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
end

%{
    TODO

        
        [x]. Enable a value to be pushed for an roi.
        []. Implement the pipeline that:
            [x]. transforms the value for each channel
            [x]. applies a threshold if neccessary
            []. generates some output
        []. Create all the channels on start and begin the tasks.

    NOTES
 
        Required device interface 

            device.createAOChannel(channelName,initialVoltage)
            device.createDOChannel(channelName,initialState)
            device.start();
            device.stop();
            device.isRunning();

            probably also needs to be a construct/destruct...or maybe that
            can just be part of start/stop.

                init can not be part of start.  Must do 
                    1. init
                    2. add channels
                    3. start
                    
%}