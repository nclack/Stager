%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HHMI - Janelia Farms Research Campus 2015 
% Author: Arunesh Mittal
% Email : mittala@janelia.hhmi.org 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef ROISelector < handle
    %% Public/Private Properties
    properties
        selectorChan;           % Channel selected in roiSelector GUI      
        selectorZPlane;         % ZPlane selected in roiSelector GUI  
        selectorFrame;          % Frame# selected in roiSelector GUI  
        selectorView;           % View type selected in roiSelector GUI {'template','registered','raw'}  
        
        roiOps;                 % Sturct that hold current operation being performed by cursor
        
        hMainGUI;               % Handle of main figure
        hStager;                % Handle of Stager object
        hHiddenFig;             % Handle of a hidden figure TODO: Currenly a hack to prevent creation of new figure
        
        hTiffDisplayPnl;        % Handle of the panel which contains axis object hDispAx
        hDispAx;                % Handle of axis used for stack display which contains image object hImage
        hImage;                 % Handle of the image object which contains test object hText  
        hText;                  % Handle of the text object
        hDispTiffStack;         % Handle of the tiffStack to display in hTiffDispPnl
        
        hChanSlider;            % Handle of the gui channel slider
        hZPlaneSlider;          % Handle of the gui zPlane slider
        hFrameSlider;           % Handle of the gui frame slider
        
        hRawViewRb;             % Handle of the gui 'Raw' view selector radio button
        hTemplateViewRb;        % Handle of the gui 'Template' view selector radio button
        hRegisteredViewRb;      % Handle of the gui 'Registered' view selector radio button
        
        hSIConnectBtn;          % Handle of the gui 'Connect' scanimage panel push button
        hSIGrabStackBtn;        % Handle of the gui 'Grab Stack' scanimage panel push button
        hSIAbortBtn;            % Handle of the gui 'Abort' scanimage panel push button
        hSIViewStackBtn;        % Handle of the gui 'View Stack' scanimage panel push button
        
        hLoadTiffBtn;           % Handle of the gui 'Load Tiff' push button 
        
        device_controller;
    end
    
    %% Constructor
    methods
        function obj = ROISelector(hStager)
            addpath('Guis');
            obj.hStager = hStager;
            obj.hMainGUI = roiSelector();                        
            
            %Add hStager handle to gui
            handles = guidata(obj.hMainGUI);
            handles.hStager = obj.hStager;
            handles.hROISelector = obj;
            guidata(obj.hMainGUI,handles);                        
            
            %Store gui handles
            obj.hDispAx = findobj(obj.hMainGUI,'Tag','ax_tiffDisplay');
            obj.hHiddenFig = figure('Visible','off');
            colormap(obj.hDispAx,'gray');
            obj.hChanSlider = findobj(obj.hMainGUI,'Tag','sldr_channel');
            obj.hZPlaneSlider = findobj(obj.hMainGUI,'Tag','sldr_zPlane');
            obj.hFrameSlider = findobj(obj.hMainGUI,'Tag','sldr_frame');
            obj.hTiffDisplayPnl = findobj(obj.hMainGUI,'Tag','pnl_tiffDisplay');
            obj.hRawViewRb = findobj(obj.hMainGUI,'Tag','rb_viewRaw');
            obj.hTemplateViewRb = findobj(obj.hMainGUI,'Tag','rb_viewTemplate');
            obj.hRegisteredViewRb = findobj(obj.hMainGUI,'Tag','rb_viewRegistered');
            obj.hImage = image(zeros(512,512),'Parent',obj.hDispAx);
            obj.hText = text(200,15,'Channel:   Z-Plane:   Frame:    ','Parent',obj.hDispAx,'Color','w','FontSize',12.5);
            obj.hLoadTiffBtn = findobj(obj.hMainGUI,'Tag','pb_loadTiff');
            
            %Store gui handles for scanimage control buttons
            obj.hSIConnectBtn = findobj(obj.hMainGUI,'Tag','pb_siConnect');
            obj.hSIGrabStackBtn = findobj(obj.hMainGUI,'Tag','pb_siGrabStack');
            obj.hSIAbortBtn = findobj(obj.hMainGUI,'Tag','pb_siAbort');
            obj.hSIViewStackBtn = findobj(obj.hMainGUI,'Tag','pb_siViewStack');
            
            %Set gui user interaction callbacks
            set(obj.hMainGUI, 'WindowButtonMotionFcn', @(~,~)obj.guiMotionFcn)
            set(obj.hMainGUI, 'WindowButtonDownFcn', @(~,~)obj.guiButtonPrssFcn)
            obj.initialize();
            obj.updateModel();
            
            %Add panel for signal generation
            obj.device_controller=devices.gui.controller(...
                devices.mockDevice(),...
                @devices.gui.view,...
                'parent',handles.panelConfigureOutput);
            obj.hStager.addlistener('roiArray','PostSet',@(~,~) disp('roi set changed'));
            
        end
        
        function initialize(obj)
            if ~isempty(obj.hStager.hTiffStack)
                toggleControls('on');
                obj.hDispTiffStack = obj.hStager.hTiffStack;
                
                %Initialize Sliders
                hChanSldr = obj.hChanSlider;
                hZPlaneSldr = obj.hZPlaneSlider;
                hFrameSldr = obj.hFrameSlider;
                
                numChans = obj.hDispTiffStack.numChans;
                numZPlanes = obj.hDispTiffStack.numZPlanes;
                numFrames = obj.hDispTiffStack.numFrames;
                
                set(hChanSldr,'Value',1);
                set(hZPlaneSldr,'Value',1);
                set(hFrameSldr,'Value',1);
                
                if numChans > 1
                    set(hChanSldr,'Min',1,'Max',numChans)
                    set(hChanSldr,'SliderStep',[1/(numChans-1) 1/(numChans-1)]);
                else
                    set(hChanSldr,'Enable','off');
                end
                
                if numZPlanes > 1
                    set(hZPlaneSldr,'Min',1,'Max',numZPlanes);
                    set(hZPlaneSldr,'SliderStep',[1/(numZPlanes-1) 1/(numZPlanes-1)]);
                else
                    set(hZPlaneSldr,'Enable','off');
                end
                
                if numFrames > 1
                    set(hFrameSldr,'Min',1,'Max',numFrames);
                    set(hFrameSldr,'SliderStep',[1/(numFrames-1) 10/(numFrames-1)]);
                else
                    set(hFrameSldr,'Enable','off');
                end
                
                obj.roiOps.roiDelete = false;
                obj.updateModel();
            else
                toggleControls('off');
            end
            
            %Enable connect button 
            %TODO: Think of better way handling these cases
            if ~obj.hStager.siConnected
                set(obj.hSIConnectBtn,'enable','on');
            end
            set(obj.hLoadTiffBtn,'enable','on');
            
            function toggleControls(str)
                %Disable all uicontrols
                gd = guidata(obj.hMainGUI);
                gdFieldNames = fieldnames(gd);
                
                for i=1:length(gdFieldNames)
                    objHandle = gd.(gdFieldNames{i});
                    if ~isobject(objHandle)  && ~isstruct(objHandle)
                        if strcmp(get(objHandle,'Type'),'uicontrol') 
                            if(sum(strcmp(get(objHandle,'Style'),{'radiobutton','pushbutton','slider'})))
                                set(objHandle,'enable',str);
                            end
                        end
                    end
                end
            end
        end
    end
    
    %% User interaction callbacks (mouse actions)
    methods
        %Mouse move callback updates cursor
        function guiMotionFcn(obj)
            hGui = obj.hMainGUI;
            currentPos = get(hGui,'CurrentPoint');
            axPos = get(obj.hDispAx,'Position');
            pnlPos = get(obj.hTiffDisplayPnl,'Position');
            axPos = axPos + [pnlPos(1:2) pnlPos(1:2)];
            
            if currentPos(1) >= axPos(1) && currentPos(1) <= axPos(1)+axPos(3) && currentPos(2) >= axPos(2) && currentPos(2) <= axPos(2)+axPos(4) 
                set(hGui,'Pointer','crosshair')
            else
                set(hGui,'Pointer','arrow')
            end
        end
        
        %Mouse button callback 
        %TODO: Change delete behavior - the delete button should remain
        %presed which would indicate 'delete mode' all rois selection in
        %this mode are deleted. Current implimentation is a 'one shot
        %delete' mode.
        function guiButtonPrssFcn(obj)
            hGui = obj.hMainGUI;
            currentPos = get(hGui,'CurrentPoint');
            axPos = get(obj.hDispAx,'Position');
            pnlPos = get(obj.hTiffDisplayPnl,'Position');
            currentPos = currentPos - axPos(1:2) - pnlPos(1:2);
            currentPos(2) = 512 - currentPos(2); %TODO: Hard coded
            
            deleteIdx = 0;
            for i=1:length(obj.hStager.roiArray)
               roiPos = obj.hStager.roiArray(i).position;
               if currentPos(1) >= roiPos(1) && currentPos(1) <= roiPos(1)+roiPos(3) && currentPos(2) >= roiPos(2) && currentPos(2) <= roiPos(2)+roiPos(4)
                    if (obj.hStager.roiArray(i).zPlane == obj.selectorZPlane) && (obj.hStager.roiArray(i).channel == obj.selectorChan)
                        if obj.roiOps.roiDelete == true
                            delete(obj.hStager.roiArray(i).hAnnotation);
                            deleteIdx = i;
                        end
                    end
                end
            end
            
            if ~deleteIdx==0
                obj.hStager.roiArray(deleteIdx) = [];
            end
            obj.roiOps.roiDelete = false;
        end
    end
    
    %% Controller Methods
    methods
        function addROI(obj)
            rect = getrect(obj.hDispAx);
            hAn = annotation('rectangle','color','yellow'); 
            set(hAn,'Parent',obj.hDispAx);
            set(hAn,'Position',rect);
            mask = ones(rect(3),rect(4));
            hRoi = stager.stack.Roi(hAn,obj.selectorZPlane,obj.selectorChan,rect,mask);
            obj.hStager.roiArray(end+1) = hRoi;
        end
        
        function removeROI(obj)
            obj.roiOps.roiDelete = true;
        end
    end
    
    %% MVC methods (updateModel/updateView)
    methods
        function updateModel(obj)
            if isempty(obj.hDispTiffStack)
                obj.initialize();
            end
            
            obj.selectorChan = int32(get(obj.hChanSlider,'Value'));   
            obj.selectorZPlane = int32(get(obj.hZPlaneSlider,'Value'));
            obj.selectorFrame = int32(get(obj.hFrameSlider,'Value'));
            
            if get(obj.hTemplateViewRb,'Value')
                obj.selectorView = 'template';
            elseif get(obj.hRegisteredViewRb,'Value')
                obj.selectorView = 'registered';
            else
                set(obj.hRawViewRb,'Value',1)
                obj.selectorView = 'raw';
            end
            
            obj.updateView();
        end
        
        function updateView(obj)
             %Scanimage Control Panel
            if(obj.hStager.siConnected)
                set(obj.hSIGrabStackBtn,'enable','on');
                set(obj.hSIAbortBtn,'enable','on');
                set(obj.hSIConnectBtn,'enable','off');
            else
                set(obj.hSIGrabStackBtn,'enable','off');
                set(obj.hSIAbortBtn,'enable','off');
                set(obj.hSIConnectBtn,'enable','on');
            end
            
            if ~isempty(obj.hStager.acqFrameBuffer)
                set(obj.hSIViewStackBtn,'enable','on'); 
            else
                set(obj.hSIViewStackBtn,'enable','off'); 
            end
            
            hFrameSldr = obj.hFrameSlider;
            
            if ~isempty(obj.hStager.hTiffStackRegistered)
                set(obj.hRegisteredViewRb,'Enable','on');
            else
                set(obj.hRegisteredViewRb,'Enable','off');
            end
            
            if ~isempty(obj.hStager.hTiffStackTemplates)
                set(obj.hTemplateViewRb,'Enable','on');
            else
                set(obj.hTemplateViewRb,'Enable','off');
            end
            
            if strcmp(obj.selectorView,'registered') 
                obj.hDispTiffStack = obj.hStager.hTiffStackRegistered;
                if obj.hDispTiffStack.numFrames > 1
                    set(hFrameSldr,'Enable','on');
                end
            elseif strcmp(obj.selectorView,'template')
                obj.hDispTiffStack = obj.hStager.hTiffStackTemplates;
                set(hFrameSldr,'Enable','off');
                obj.selectorFrame = 1;
            else
                obj.hDispTiffStack = obj.hStager.hTiffStack;
                if ~isempty(obj.hDispTiffStack)
                    if  obj.hDispTiffStack.numFrames > 1
                        set(hFrameSldr,'Enable','on');
                    end
                end
            end
            
            if ~isempty(obj.hDispTiffStack)
                set(obj.hImage,'CData',obj.hDispTiffStack.Aout(:,:,obj.selectorChan,...
                    obj.selectorZPlane+((obj.selectorFrame-1)*obj.hDispTiffStack.numZPlanes)),...
                    'CDataMapping','scaled');

                set(obj.hText,'String',sprintf('Channel: %1.0f   Z-Plane: %1.0f   Frame: %3.0f ',...
                    obj.selectorChan,obj.selectorZPlane,obj.selectorFrame));

                for i=1:length(obj.hStager.roiArray)
                    if obj.hStager.roiArray(i).zPlane == obj.selectorZPlane && ...
                            obj.hStager.roiArray(i).channel == obj.selectorChan
                        set(obj.hStager.roiArray(i).hAnnotation,'visible','on');
                    else
                        set(obj.hStager.roiArray(i).hAnnotation,'visible','off');
                    end
                end
            end
        end
    end
end

