function out=aogui(getRoiNames,varargin)
    
    heightHint=22;
    
    is_running=false;

    
    h=uipanel('title','Signal generation',varargin{:});    
    draw;
    
    out=struct('redraw',@draw);
    
    function draw
        clo(h); % (ngc) if I have to guess, which I do, this is 'clear object'.  I wish I could find documentation though.
        l0=uiflowcontainer('v0','Parent',h,'FlowDirection','TopDown');    
    
        addrow('ROI',@roiSelector,getRoiNames,'parent',l0);
        addrow('Transform',@transformField,'parent',l0);
        
        l1=uitabgroup(l0);
        aoPanel('parent',uitab('parent',l1,'title','AO'));
        doPanel('parent',uitab('parent',l1,'title','DO'));
        
        statePanel('parent',l0);
    end
    
    %% small controls/fields

    function roiSelector(getRoiNames,varargin)        
        uicontrol('Style','popupmenu','String',getRoiNames(),'Value',1,varargin{:});        
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
        H=uicontrol('style','text','string','V','parent',L);
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
        rest=[a invstruct(rmfield(c,field))];
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