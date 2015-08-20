function out=aogui(getRoiNames,getConfigForROIByName,setConfigForROIByName,varargin)
    
    heightHint=22;    
    is_running=false;
    config=[]; 

    
    h=uipanel('title','Signal generation',varargin{:});
    names=getRoiNames();
    if ~isempty(names)
        config=getConfigForROIByName(names{1});
    end
    draw;
    % FIXME: make sure first is selected
    
    out=struct(...
        'notifyConfigUpdatedForROI',@onConfigUpdatedForROI,...
        'redraw',@draw);
    
    %% interface
    
    function draw
        clo(h);
        l0=uiflowcontainer('v0','Parent',h,'FlowDirection','TopDown');    
    
        addrow('ROI',@roiSelector,getRoiNames,'parent',l0,'tag','roiSelector');
        addrow('Transform',@transformField,'parent',l0);
        
        l1=uitabgroup(l0);
        aoPanel('parent',uitab('parent',l1,'title','AO'));
        doPanel('parent',uitab('parent',l1,'title','DO'));
        
        statePanel('parent',l0);
    end

    function onConfigUpdatedForROI(roiname)
        % Could be a new roi, or just updating an existing roi
        if countofROIs()<1 % then set selected and update
            error('TODO'); % first, need to do the logic for updating when something is selected
        end
        if ~isCurrentROI(roiname), return; end;
        % update view
        config=validateConfig(getConfigForROIByName(roiname));
        draw;
        % FIXME: make sure same roi is selected
    end    

    %% small controls/fields

    function roiSelector(getRoiNames,varargin)        
        uicontrol('Style','popupmenu',...
            'String',getRoiNames(),'Value',1,...
            'Callback',@(~,~) onSelectionChange,varargin{:});
    end

    function transformField(varargin)
        % See Todo (1)
        uicontrol('style','edit','string','@(x) x',varargin{:});
    end

    function channelNameField(varargin)
        uicontrol('style','edit','tooltipstring','National instruments DAQmx channel name identifier',varargin{:});
    end

    function thresholdField(varargin)
        L=uiflowcontainer('v0','FlowDirection','LeftToRight',varargin{:});
        uicontrol('style','edit','string','0.5','tooltipstring','Trigger threshold in Volts','parent',L);
        H=uicontrol('style','text','string','Volts','parent',L);
        extent=get(H,'Extent');
        set(H,'WidthLimits',[extent(3) extent(3)]);
    end

    function notField(varargin)
        uicontrol('style','popupmenu','String',{'High','Low'},varargin{:});
    end

    %% panels                
    function aoPanel(varargin)
        % See Todo (2)
        L=uiflowcontainer('v0','FlowDirection','TopDown',varargin{:});
        addrow('Channel Name',@channelNameField,'string','Dev1/ao0','parent',L);
    end

    function doPanel(varargin)
        % See Todo (2)
        L=uiflowcontainer('v0','FlowDirection','TopDown',varargin{:});
        addrow('Channel Name',@channelNameField,'string','Dev1/port0/line0','parent',L);
        addrow('Threshold',@thresholdField,'parent',L);
        addrow('Triggered state',@notField,'parent',L);
    end

    function statePanel(varargin)        
        L=uiflowcontainer('v0','FlowDirection','LeftToRight',varargin{:});
        C=struct(...
            'button',uicontrol('style','pushbutton','parent',L),...
            'label',uicontrol('style','text','parent',L));
        set(L,'HeightLimits',[heightHint,heightHint]);
        
        updateStateControl(C);
        set(C.button,'callback',@(~,~) toggleState(C));
    end
      

    %% control
    function updateStateControl(control)
        if is_running
            set(control.button,'String','Stop');
            set(control.label,'String','Running');
        else
            set(control.button,'String','Start');
            set(control.label,'String','');
        end        
    end
        
    function toggleState(statecontrol)
        if is_running
            stop;
        else
            start;
        end
        is_running=~is_running;
        updateStateControl(statecontrol);
    end    
    
    function start
        dbstack;
    end
    
    function stop
        dbstack;
    end

    function config_=validateConfig(config_)
        %{
        c.MasterTransform
        c.ao(:).ChannelName
               .Transform
        c.do(:).ChannelName
               .Transform
               .Threshold
               .TriggeredState        
        %}        
        aoDefaults={...
            'ChannelName','Dev1/ao0',...
            'Transform','@(x) x'};
        doDefaults={...
                'ChannelName','Dev1/port0/line0',...
                'Transform','@(x) x',...
                'Threshold',0.0,...
                'TriggeredState','low'};
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
        name=s{i};
    end

    function tf=isCurrentROI(roiname)        
        tf=strcmp(selectedROIName(),roiname)==0;
    end        

    function onSelectionChange
        config=validateConfig(getConfigForROIByName(selectedROIName()));
        draw;
    end

    function onUpdate
        dbstack;
        setConfigForROIByName(selectedROIName(),config);
    end

    %% utilities
    
    function addrow(label,controlConstructor,varargin)
        % This is supposed to work like QFormLayout::addRow in Qt.
        % FIXME: doesn't really get vertical text placement correct
        %        (centered)
        
        [parent,args]=pickparent_(varargin{:});
        H=uiflowcontainer('v0','Parent',parent,'FlowDirection','LeftToRight');
        set(H,'HeightLimits',[heightHint,heightHint]);
        L=uicontrol('parent',H,'Style','text','String',label);
        extent=get(L,'Extent');
        set(L,'WidthLimits',[extent(3) extent(3)]);
        controlConstructor(args{:},'parent',H);
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
    
    TODO

    1. transform

    Spec is to have this transform individual values, but I might change it
    once things are working 

    2. multiple channel support

    Get things working for individual channels first, and then maybe add
    support for output across multiple channels, each with their own xfrom.

    3. plotting

%}