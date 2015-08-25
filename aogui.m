function out=aogui(getRoiNames,getConfigForROIByName,setConfigForROIByName,start,stop,varargin)
    
    heightHint=25;    
    is_running=false;
    config=validateConfig([]);
    statecontrol=[];
    
    assert(nargin>=3);
    
    h=uipanel('title','Signal generation',varargin{:});
    names=getRoiNames();
    if ~isempty(names)
        config=validateConfig(getConfigForROIByName(names{1}));            
    end
    draw;
    
    % FIXME: make sure first is selected
    
    out=struct(...
        'getDefaultConfig',@() validateConfig([]),...
        'notifyConfigUpdatedForROI',@onConfigUpdatedForROI,...
        'notifyIsRunning',@onNotifyIsRunning,...
        'updateROINames',@onUpdateROINames,...
        'redraw',@draw);
    
    %% interface    
    function draw
        clo(h);
        l0=uiflowcontainer('v0','Parent',h,'FlowDirection','TopDown');    
        if isempty(getRoiNames())
            uicontrol('style','text','String','','parent',l0);
            uicontrol('style','text','String','Add ROIs to setup AO/DO output.','parent',l0);
        else            
            addrow('ROI',@roiSelector,'parent',l0,'tag','roiSelector');
            addrow('Transform',@transformField,'parent',l0);

            l1=uitabgroup(l0);
            aoPanel('parent',uitab('parent',l1,'title','AO'));
            doPanel('parent',uitab('parent',l1,'title','DO'));

            statePanel('parent',l0);
        end
    end

    function onConfigUpdatedForROI(roiname)
        % Could be a new roi, or just updating an existing roi
        if countofROIs()<1 % then set selected and update
            error('TODO'); % first, need to do the logic for updating when something is selected
        end
        if ~isCurrentROI(roiname), return; end;        
        onSelectionChange(); % update view
    end    

    %% small controls/fields
    function out=roiSelector(varargin)        
        out=uicontrol('Style','popupmenu',...
            'String',getRoiNames(),'Value',1,...
            'Callback',@(~,~) onSelectionChange,varargin{:});
    end

    function out=transformField(varargin)
        % See Todo (1)
        out=uicontrol('style','edit','string',config.MasterTransform,'Callback',@(~,~) update,varargin{:});
        function update
            config.MasterTransform=get(out,'String');
            onUpdate;
        end
    end

    function out=channelNameField(varargin)
        out=uicontrol('style','edit','tooltipstring','National instruments DAQmx channel name identifier',varargin{:});
    end

    function out=thresholdField(varargin)        
        out=uicontrol('style','edit','tooltipstring','Trigger threshold in Volts',varargin{:});
    end

    function out=notField(varargin)
        out=uicontrol('style','popupmenu','String',{'High','Low'},varargin{:});
    end

    function out=enableField(varargin)
        out=uicontrol('style','checkbox',varargin{:});
    end

    %% panels                
    function aoPanel(varargin)
        % See Todo (2)
        L=uiflowcontainer('v0','FlowDirection','TopDown',varargin{:});
        hname=addrow('Channel Name',@channelNameField,...
            'string',config.ao(1).ChannelName,...
            'Callback',@(~,~) update,...
            'parent',L);
        henable=addrow('Enable',@enableField,...
            'Value',config.ao(1).Enable,...
            'Callback',@(~,~) update,...
            'parent',L);
        function update
            config.ao(1).ChannelName=get(hname,'String');
            config.ao(1).Enable=get(henable,'Value');
            onUpdate;
        end
    end

    function doPanel(varargin)
        % See Todo (2)
        L=uiflowcontainer('v0','FlowDirection','TopDown',varargin{:});
        hname   = addrow('Channel Name',@channelNameField,'string',config.do(1).ChannelName,'Callback',@(~,~) update,'parent',L);
        hthresh = addrow('Threshold',@thresholdField,'string',config.do(1).Threshold,'Callback',@(~,~) update,'parent',L);
        hstate  = addrow('Triggered state',@notField,'Callback',@(~,~) update,'parent',L);
        henable = addrow('Enable',@enableField,'Value',config.do(1).Enable,'Callback',@(~,~) update,'parent',L);
        set(hstate,'Value',find(cellfun(@(s) strcmpi(config.do(1).TriggeredState,s),get(hstate,'String'))));
        function update
            config.do(1).ChannelName=get(hname,'String');
            t=str2double(get(hthresh,'String'));
            if ~isnan(t), config.do(1).Threshold=t; end
            states=get(hstate,'String');
            i=get(hstate,'Value');           
            config.do(1).TriggeredState=lower(states{i});
            config.do(1).Enable=get(henable,'Value');
            onUpdate;
        end
    end
    
    function statePanel(varargin)        
        L=uiflowcontainer('v0','FlowDirection','LeftToRight',varargin{:});
        statecontrol=struct(...
            'button',uicontrol('style','pushbutton','parent',L),...
            'label',uicontrol('style','text','parent',L));
        set(L,'HeightLimits',[heightHint,heightHint]);
        
        updateStateControl();
        set(statecontrol.button,'callback',@(~,~) toggleState());
    end      

    %% control
    function updateStateControl()
        if is_running
            set(statecontrol.button,'String','Stop');            
        else
            set(statecontrol.button,'String','Start');
            set(statecontrol.label,'String','');
        end
    end

    function onNotifyIsRunning(is_running_)
        if is_running_            
            set(statecontrol.label,'String','Running');
        end
        is_running=is_running_;
        updateStateControl();
    end
       
    function onUpdateROINames(names)
        getRoiNames=@() names;
        % see if the selected item in the selection drop down match, and try to
        % maintain the selection
        cur=selectedROIName();
        i=find(cellfun(@(x) strcmp(cur,x),names));        
        if isempty(i),i=1; end
        set(findobj(h,'tag','roiSelector'),'Value',i);
        onSelectionChange();
    end

    function toggleState()
        if is_running
            stop();
            is_running=0;
        else
            set(statecontrol.label,'String','Starting...');
           try
                start(); % relies on caller to notify when actually running.
            catch e
                stop();
                out.notifyIsRunning(0);
                rethrow(e);
            end
          
        end        
        updateStateControl();
    end    

    function config_=validateConfig(config_)
        %{
        c.MasterTransform
        c.ao(:).ChannelName
               .Transform
               .Enable                
        c.do(:).ChannelName
               .Transform
               .Threshold
               .TriggeredState        
               .Enable
        %}        
        aoDefaults={...
            'ChannelName','Dev1/ao0',...
            'Transform','@(x) x',...
            'Enable',false}; % it's probably important that channels are created off by default.
        doDefaults={...
                'ChannelName','Dev1/port0/line0',...
                'Transform','@(x) x',...
                'Threshold',0.0,...
                'TriggeredState','high',...
                'Enable',false}; % it's probably important that channels are created off by default.
        config_=optional(config_,...
            'ao',optional(struct(),aoDefaults{:}),...
            'do',optional(struct(),doDefaults{:}),...
            'MasterTransform','@(x) x');
        for i=1:numel(config_.ao)
            config_.ao(i)=optional(config_.ao(i),aoDefaults{:});                
        end
        for i=1:numel(config_.do)
            config_.do(i)=optional(config_.do(i),doDefaults{:});
        end
        function c=optional(c,varargin)
            vs=reshape(varargin,2,[]);
            for v=vs
                [field,default]=deal(v{:});
                if ~isfield(c,field), c.(field)=default; end
            end            
        end
    end

    function n=countofROIs
        n=numel(get(findobj(h,'tag','roiSelector'),'String'));
    end

    function name=selectedROIName
        H=findobj(h,'tag','roiSelector');
        i=get(H,'Value');
        s=get(H,'String');
        if isempty(s)
            name=[];
        else            
            name=s{i};
        end
    end

    function tf=isCurrentROI(roiname)        
        tf=strcmp(selectedROIName(),roiname);
    end        

    function onSelectionChange
        i=get(findobj(h,'tag','roiSelector'),'Value'); % findobj will not find the roiSelector if no rois have been added yet.       
        if isempty(i),i=1;end
        config=validateConfig(getConfigForROIByName(selectedROIName()));
        draw;
        H=findobj(h,'tag','roiSelector');
        i=min(i,numel(get(H,'string')));
        set(H,'Value',i);
    end

    function onUpdate
        dbstack;
        disp(config);
        disp(config.ao(:));
        disp(config.do(:));
        setConfigForROIByName(selectedROIName(),config);
    end

    %% utilities
    
    function out=addrow(label,controlConstructor,varargin)
        % This is inspired by QFormLayout::addRow in Qt.
        %
        % Returns a handle to the constructed control.
        %
        % FIXME: doesn't really get vertical text placement correct
        %        (centered)
        % TODO: set width of text elements to max width from all rows
        
        [parent,args]=pickparent_(varargin{:});
        H=uiflowcontainer('v0','Parent',parent,'FlowDirection','LeftToRight');
        set(H,'HeightLimits',[heightHint,heightHint]);
        L=uicontrol('parent',H,'Style','text','String',label);
        extent=get(L,'Extent');
        set(L,'WidthLimits',[extent(3) extent(3)]);
        out=controlConstructor(args{:},'parent',H);
    end

    function [parent,rest]=pickparent_(varargin)
        % picks the 'Parent' field out of varargin.
        % Returns the parent and the 'rest' is varargin but without the 
        % parent field.
        [a,b]=parseparams(cellfun(@wrap,varargin,'UniformOutput',false));
        c=struct(b{:});
        if(isfield(c,'parent'))
            field='parent';           
        elseif(isfield(c,'Parent'))
            field='parent'; 
        else
            parent=[];
            rest=varargin{:};
            return
        end
        parent=c.(field);
        rest=[a(:); invstruct(rmfield(c,field))];
        function y=invstruct(x)
            y=[fieldnames(x) struct2cell(x)]';
            y=y(:);
        end
        function y=wrap(x)
            if(iscell(x)), y={x}; else y=x; end
        end
                
    end
        
        
end

%{

    NOTES

    Data flow

        ROI -> transform -> AO/DO

        AO: -> (optional per channel transform) -> volts

        DO: -> (optional per channel transform) -> threshold -> maybe not -> state

    getROINames

        This probably should be a cell-array of strings (a plain value).
        I didn't start that way though.  Instead, I made it a function.
        The idea was that maybe it would query a handle graphics thing 
        and I don't know what.

    
    TODO

    1. transform

    Spec is to have this transform individual values, but I might change it
    once things are working 

    2. multiple channel support

    Get things working for individual channels first, and then maybe add
    support for output across multiple channels, each with their own xfrom.

    3. plotting

    4. save and load

    5. For transform fields, provide some feedback about whether the input 
       expression is evaluable.

       Add tooltip to say Transform must be a function handle

%}