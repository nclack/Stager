function out=aoguitest

device=devices.nidaqmxDevice();
configs=struct('jim',[],'bob',[]);
cache=struct(); % keys are roi names


% function out=aogui(getRoiNames,getConfigForROIByName,setConfigForROIByName,start,stop,varargin)
gui=aogui(...
    @() fieldnames(configs),...
    @get,...
    @set,...
    @start,...
    @stop);

out=struct(...
    'gui',gui,...
    'pushDataForROIByName',@pushDataForROIByName,...
    'stop',@stop);

    %% bindings for gui
    function value=get(key)
        if isfield(configs,key)
            value=configs.(key);
        else
            value=[];
        end
    end

    function set(key,value)        
        if device.isRunning()
            if changeRequiresRestart(key,value)
                disp('Changed requires restarting the device.');
                setChannelsToInitialState();
                configs.(key)=value;
                softstop()
                start();
            elseif changeRequiresDeviceUpdate(key,value)
                disp('Changed requires updating the output values.');
                configs.(key)=value;
                if isfield(cache,key)
                    disp('Pushing cached value');
                    pushDataForROIByName(key,cache.(key));
                end
            end
        end     
        configs.(key)=value;
        
        function tf=changeRequiresRestart(key,value)
            % presumes device is running
            if ~isfield(configs,key)
                tf=anyChannelIsEnabled(value); % a new roi: are any channels enabled?
            else                                
                original=get(key);                
                if isempty(original),original=gui.getDefaultConfig(); end;
                for type={'ao','do'}
                    for i=1:length(original.(type{1}))
                        if ~isequal(original.(type{1})(i).Enable,value.(type{1})(i).Enable), tf=1; return ; end
                        if value.(type{1})(i).Enable && ~isequal(original.(type{1})(i).ChannelName,value.(type{1})(i).ChannelName)
                            tf=1; return; 
                        end
                    end                
                end
                tf=0;
            end
        end                
        
        function tf=changeRequiresDeviceUpdate(key,value)
            % presumes change does not require restart
            original=get(key);     
            if isempty(original),original=gui.getDefaultConfig(); end;
            if ~isequal(original.MasterTransform,value.MasterTransform)
                tf=1; return;
            end
            for type={'ao','do'}
                for i=1:length(original.(type{1}))
                    if value.(type{1})(i).Enable 
                        for field={'Transform','Threshold','TriggeredState'}
                            if isfield(original.(type{1})(i),field{1})
                                if ~isequal(original.(type{1})(i).(field{1}),value.(type{1})(i).(field{1}))
                                    tf=1; return; 
                                end
                            end
                        end                        
                    end
                end                
            end
            tf=0;
        end
        
        function tf=anyChannelIsEnabled(cfg)
            tf=0;
            for c=cfg.ao, tf=tf||c.Enable; end
            for c=cfg.do, tf=tf||c.Enable; end            
        end        
    end

    function start
        disp('start')
        for key=fieldnames(configs)'
            c=get(key{1});
            if isempty(c),c=gui.getDefaultConfig(); end;
            for name = fieldnames(c)                
                for o=c.ao(find(c.ao(:).Enable)) %#ok<FNDSB>
                    device.createAOChannel(o.ChannelName,0);
                end
                for o=c.do(find(c.do(:).Enable)) %#ok<FNDSB>
                    initialState=strcmpi(o.TriggeredState,'low');
                    device.createDOChannel(o.ChannelName,initialState);
                end
            end
        end
        device.start();
        for key=fieldnames(configs)'
            if isfield(cache,key{1})
                disp('Pushing cached value');
                pushDataForROIByName(key{1},cache.(key{1}));
            end
        end
        gui.notifyIsRunning(device.isRunning());
    end

    function softstop        
        device.stop(); % should release all channels
        disp('soft stop (keeps cached values)')
    end

    function stop    
        try
            setChannelsToInitialState();
        catch
            warning('There was a problem resetting channels.');
        end
        device.stop(); % should release all channels
        cache=struct(); % clear cache
        disp('stop')
    end

    %% interface for pushing data        
    function pushDataForROIByName(key,v)
        if(device.isRunning())
            cache.(key)=v; % remember the last pushed value
            
            c=get(key);
            if isempty(c),c=gui.getDefaultConfig();end;
            MasterTransform=eval(c.MasterTransform);
            for o=c.ao(find(c.ao(:).Enable)) %#ok<FNDSB>
                ChannelTransform=eval(o.Transform);
                vv=ChannelTransform(MasterTransform(v));                
                device.writeAO(o.ChannelName,vv);
            end
            for o=c.do(find(c.do(:).Enable)) %#ok<FNDSB>
                ChannelTransform=eval(o.Transform);
                vv=ChannelTransform(MasterTransform(v));
                if strcmpi(o.TriggeredState,'high')
                    vv=vv>o.Threshold;
                else
                    vv=vv<=o.Threshold;
                end                
                device.writeDO(o.ChannelName,vv);
            end                
        end
    end

    function setChannelsToInitialState
        for key=fieldnames(configs)'
            c=get(key{1});
            if isempty(c),c=gui.getDefaultConfig(); end;
            for name = fieldnames(c)                
                for o=c.ao(find(c.ao(:).Enable)) %#ok<FNDSB>
                    device.writeAO(o.ChannelName,0);
                end
                for o=c.do(find(c.do(:).Enable)) %#ok<FNDSB>
                    initialState=strcmpi(o.TriggeredState,'low');
                    device.writeDO(o.ChannelName,initialState);
                end
            end
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
            device.writeAO(channelName,value);
            device.writeDO(channelName,value);            
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