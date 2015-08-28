%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HHMI - Janelia Farms Research Campus 2015
% Author: Arunesh Mittal
% Email : mittala@janelia.hhmi.org
%
% Registration code :  Sofroniew, Nick <sofroniewn@janelia.hhmi.org>
%                      https://github.com/sofroniewn/wgnr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Stager < handle
    %% Public/Private Properties
    properties(SetObservable)
        %Handles
        hServer;                % Handle to sever object
        hFrameListener;         % Handle to 'frameReceived' listener
        hROISelector;           % Handle to roiSelector object
        hHiddenFig;             % Setting colormap launches new figure; Set this to hidden and set to it as gcf;
        hTracer;                % Handle to tsTracer object (gui time series display)
        
        %Tiff stack properties
        hTiffStack;             % Struct which holds the loaded stack array and header data
        hTiffStackRegistered;   % Struct which holds the registered stack array
        hTiffStackTemplates;    % Struct which hold the template for each zPlane
        
        %Time-Series tracer props
        hTSTracer;              % Handle to TSTracer object
        
        roiArray;               % Array of roi objects
        maskArray;              % Arrray of masks (MxN matrices) to apply to incoming frames
        
        frameProcessMode='roi'; % One of {'roi','acq'} 'roi' indicates appropriate roi is applied to incoming frame,
                                % 'acq' indicates a new stack is acquired from scanimage.  
        currentFrameIdx=1;      % Keeps track of number of frames processed
        acqFrameBuffer;          % Array to store all frames for a new 'acq' from scanimage
    end
   
    %% Constructor
    methods
        function obj = Stager()
            %Create frame server and register frame received event
            obj.hServer = stager.components.Server(obj);
            obj.hFrameListener = event.listener(obj.hServer,'frameReceived',@(~,~)obj.processFrame);
            
            %Launch guis
            obj.startROISelectorGUI();
            obj.startTSTracerGUI();
            
            %Create roi array
            obj.roiArray = stager.stack.Roi.empty();
        end
    end 
    
    %% Process Frame Methods
    methods
        %Process frame received and add to appropriate time series
        function processFrame(obj,~,~)
            fprintf('FrameReceived!\n');
            tempFrame = obj.hServer.hFrame.clone();
            
            %Acquire a new stack
            if strcmp(obj.frameProcessMode,'acq')
                obj.acqFrameBuffer(obj.currentFrameIdx) = tempFrame; 
                obj.currentFrameIdx = obj.currentFrameIdx+1;
            end
            
            %set(obj.hROISelector.hImage,'CData',tempFrame.frameData,'CDataMapping','scaled');
            
            %Register Image
            %obj.hTiffStack.Aout(:,:,align_chan,ij)= tempFrame;
            
            %Apply Masks
            %for i=1:obj.maskArray
            %    maskedImage = mask.*double(tempFrame.frameData);
            %    (cumsum(maskedImage))/(cumsum(mask)); %Remove use of cumsum
            %end
        end
        
        function set.frameProcessMode(obj,val)
            if strcmp(val,'roi')
            
            elseif strcmp(val,'acq')
                obj.flushAcqBuffer;
                obj.frameProcessMode = val;
            end
        end
        
        function flushAcqBuffer(obj)
            obj.acqFrameBuffer = stager.stack.Frame.empty(); 
            obj.currentFrameIdx = 1;
        end
    end
    
    %% ROI Selector methods
    methods
        function startROISelectorGUI(obj)
            obj.hROISelector = stager.components.ROISelector(obj);
        end
    end
    %% Stack methods
    methods
        %Load tiff stack
        function loadStack(obj,varargin)
            obj.hTiffStack = stager.stack.Stack;
            
            if nargin>1
                obj.hTiffStack.loadTiff(varargin(2));
            else
                obj.hTiffStack.loadTiff();
            end
        end
        
        function loadAcqStack(obj)
            obj.hTiffStackRegistered = stager.stack.Stack.empty(0);   
            obj.hTiffStackTemplates = stager.stack.Stack.empty(0);      
            
            obj.hTiffStack = stager.stack.Stack;
            if length(obj.acqFrameBuffer)>=1
                obj.hTiffStack.loadStagerAcq(obj.acqFrameBuffer);
            end
        end
        
        %Generate template images for registration
        function generateTemplates(obj)
            obj.hTiffStackTemplates = obj.hTiffStack.clone();
            
            nchans = obj.hTiffStack.numChans;
            numPlanes = obj.hTiffStack.numZPlanes;
            
            hWaitBar = waitbar(0,'Processing...','Name','Generating Templates');
            waitIdx = 0;
            
            gcorr_fast = @stager.stack.Frame.gcorr_fast;
            func_im_shift = @stager.stack.Frame.func_im_shift;
            
            % Heirarchical referencing method - reference pairs of adjacent frames
            % average them together and repeat until only one frame left - this is
            % master image
            % stack: m*n*t
            
            for align_chan=1:nchans
                im = obj.hTiffStack.Aout;
                im = im(:,:,align_chan:nchans:end);
                for ij = 1:numPlanes
                    im_stack_raw = im(:,:,ij:numPlanes:end);
                    num_ims = size(im_stack_raw,3);
                    num_heirarch = floor(log2(num_ims));
                    im_stack_raw = im_stack_raw(:,:,1:2^num_heirarch);
                    for ik = 1:num_heirarch
                        num_ims = size(im_stack_raw,3);
                        im_stack_tmp = zeros(size(im_stack_raw,1),size(im_stack_raw,2),num_ims/2,'uint16');
                        waitIdx = waitIdx+1;
                        waitbar((waitIdx)/(nchans*numPlanes*num_heirarch),hWaitBar,...
                            sprintf('Channel: (%1.0f of %1.0f); ZPlane: (%1.0f of %1.0f); Level: (%1.0f of %1.0f)',align_chan,nchans,ij,numPlanes,ik,num_heirarch));
                        for ih = 1:num_ims/2
                            im_A = im_stack_raw(:,:,1+2*(ih-1));
                            im_B = im_stack_raw(:,:,2+2*(ih-1));
                            [corr_offset] = gcorr_fast(double(im_A),double(im_B));
                            im_A_shift = func_im_shift(im_A,corr_offset);
                            im_stack_tmp(:,:,ih) = (int16(im_A_shift) + int16(im_B))/2;
                        end
                        im_stack_raw = im_stack_tmp;
                    end
                    obj.hTiffStackTemplates.Aout(:,:,align_chan,ij)= im_stack_raw;
                end
            end
            
            waitbar(100,hWaitBar,'Done.');
            close(hWaitBar);
        end
        
        %Register stack using generated templates
        function registerStack(obj)
            %Generate Templates
            obj.generateTemplates();
            
            %Create and copy stack properties
            obj.hTiffStackRegistered = obj.hTiffStack.clone();
            
            numChans = obj.hTiffStackRegistered.numChans;
            numZPlanes = obj.hTiffStackRegistered.numZPlanes;
            numFrames =  obj.hTiffStackRegistered.numFrames;
            
            hWaitBar = waitbar(0,'Processing...','Name','Registering Stack');
            waitIdx = 0;
            
            gcorr_fast = @stager.stack.Frame.gcorr_fast;
            func_im_shift = @stager.stack.Frame.func_im_shift;
            
            %Register Stack
            for chanIdx=1:numChans
                for zPlaneIdx=1:numZPlanes
                    im_B = obj.hTiffStackRegistered.Aout(:,:,chanIdx,zPlaneIdx);
                    waitbar(waitIdx/(numChans*numZPlanes*numFrames),hWaitBar,...
                        sprintf('Chan: (%1.0f of %1.0f); ZPlane: (%1.0f of %1.0f)',chanIdx,numChans,zPlaneIdx,numZPlanes));
                    for frameIdx=1:numFrames
                        waitIdx = waitIdx+1;
                        im_A = obj.hTiffStack.Aout(:,:,chanIdx,zPlaneIdx+((frameIdx-1)*numZPlanes));
                        [corr_offset] = gcorr_fast(double(im_A),double(im_B));
                        im_A_shift = func_im_shift(im_A,corr_offset);
                        obj.hTiffStackRegistered.Aout(:,:,chanIdx,zPlaneIdx+((frameIdx-1)*numZPlanes)) = (int16(im_A_shift));
                    end
                end
            end
            
            waitbar(100,hWaitBar,'Done.');
            close(hWaitBar)
        end
        
        %Load/Save selected rois to json file
        function saveROIs(obj)
            [FileName,PathName,~] = uiputfile({'rois.json'});
            numRois = length(obj.roiArray);
            
            if (numRois >= 1)
                roiStruct([]) = struct;
            
                for i=1:numRois
                    %Compute array of all x,y values
                    pos =  obj.roiArray(i).position;
                    xcoords = pos(1):pos(1)+pos(3)-1;
                    ycoords = (pos(2):pos(2)+pos(4)-1);
                    ynew = reshape(repmat(ycoords,length(xcoords),1),[],1);
                    xnew = repmat(xcoords',length(ycoords),1);

                    roiStruct(i).coordinates = [xnew ynew];
                    roiStruct(i).values = reshape(obj.roiArray(i).mask,1,[]); 
                    roiStruct(i).bbox = [pos(1) pos(2) pos(1)+pos(3) pos(2)+pos(4)];
                    
                    roiStruct(i).zPlane = obj.roiArray(i).zPlane;
                    roiStruct(i).channel = obj.roiArray(i).channel;
                end
            
                %Save to json file
                savejson('',roiStruct,fullfile(PathName,FileName));
            end
        end
        
        function loadROIs(obj)
            [FileName,PathName,~] = uigetfile({'*.json'});
            roiStructArray = loadjson(fullfile(PathName,FileName)); 
            numRois = length(roiStructArray);
            
            if (numRois >= 1)
                %For simplicity over write all rois
                %In the future allow to overwrite or append
                obj.clearROIArray();
            end
            
            for i=1:numRois
                roiStruct = roiStructArray{i};
                
                zPlane = roiStruct.zPlane;
                position = [roiStruct.bbox(1),roiStruct.bbox(2),roiStruct.bbox(3)-roiStruct.bbox(1),roiStruct.bbox(4)-roiStruct.bbox(2)];  
                channel = roiStruct.channel;
                
                hAn = annotation('rectangle','color','yellow'); 
                set(hAn,'Parent',obj.hROISelector.hDispAx);
                set(hAn,'Position',position);
                set(hAn,'Visible','off')
                
                xcoords = roiStruct.coordinates(:,1);
                ycoords = roiStruct.coordinates(:,2);
                xcoords = xcoords - min(xcoords)+1;
                ycoords = ycoords - min(ycoords)+1;
                
                iVals = roiStruct.values;
                
                mask = nan(length(unique(xcoords)),length(unique(ycoords)));
                valIdx = 1;
                
                for j=1:length(xcoords)
                    mask(xcoords(j),ycoords(j)) = iVals(valIdx);
                    valIdx = valIdx+1;
                end
                
                %TODO Display wighted ROIs not just bbox
                obj.roiArray(i) = stager.stack.Roi(hAn,zPlane,channel,position,mask);  
                obj.hROISelector.updateView();
             end
        end
        
        function clearROIArray(obj)
            numRois = length(obj.roiArray);
            
            %Delete all annotations
            for i=1:numRois
                delete(obj.roiArray(i).hAnnotation)
            end
            
            %Overwrite Array
            obj.roiArray = stager.stack.Roi.empty();
        end
    end
    
    %% Time-Series Tracer Methods
    methods
        function startTSTracerGUI(obj)
            obj.hTSTracer = stager.components.TSTracer(obj);
        end
        
        function plotStackROI(obj)
            numChans = obj.hROISelector.hDispTiffStack.numChans;
            numZPlanes = obj.hROISelector.hDispTiffStack.numZPlanes;
            numFrames =  obj.hROISelector.hDispTiffStack.numFrames;
            
            obj.flushROIs();
            j=1; t(1)=0;
            for i=1:10
            if ~isempty(obj.roiArray)
                if ~isempty(obj.hTiffStackRegistered)
                    obj.hTSTracer.initializePlot(numFrames,length(obj.roiArray));
                    for frameIdx=1:numFrames
                        for chanIdx=1:numChans
                            for zPlaneIdx=1:numZPlanes
                                tic;
                                im_A = obj.hTiffStackRegistered.Aout(:,:,chanIdx,zPlaneIdx+((frameIdx-1)*numZPlanes));
                                obj.applyROIs(im_A,chanIdx,zPlaneIdx);
                                obj.updateTSPlotData();
                                obj.hTSTracer.updatePlot();
                                drawnow;
                                t(j) = toc;
                                j=j+1;
                                %pause(.03);
                            end
                        end
                    end
                else
                    hqdlg = questdlg('Plotting stack traces requires registerd image. Register current stack?','Plot ROIs','Yes','Cancel','Cancel');
                    if strcmp(hqdlg,'Yes')
                        obj.registerStack();
                        obj.hROISelector.updateModel();
                        obj.plotStackROI();
                    end
                end
            else
                warndlg('No ROIs have been selected or loaded');
            end
            end
            figure(obj.hTSTracer.hMainGui);
        end
        
        function flushROIs(obj)
            for i=1:length(obj.roiArray)
                obj.roiArray(i).flushBuffer;
            end
        end
        
        function applyROIs(obj,frame,fchan,fzPlane)
            numRois = length(obj.roiArray);
            for i=1:numRois
                pos = obj.roiArray(i).position;
                chan = obj.roiArray(i).channel;
                zPlane = obj.roiArray(i).zPlane;
                if (fchan == chan && fzPlane == zPlane)
                    xMin = pos(1);
                    xMax = pos(1)+pos(3);
                    yMin = pos(2);
                    yMax = pos(2)+pos(4);
                    val  = sum(sum(frame(yMin:yMax,xMin:xMax)));
                    obj.roiArray(i).addVal(val);
                end
            end
        end
        
        function updateTSPlotData(obj)
            numRois = length(obj.roiArray);
            maxIdx = min(length(obj.roiArray(1).iValArray),obj.hTSTracer.numTimePts);
            
            for i=1:numRois
                obj.hTSTracer.tsData(1:maxIdx,i) = obj.roiArray(i).iValArrayDFOF(end-maxIdx+1:end);
            end
        end
    end
    
    %% ScanImage control methods
    methods
        %Connect to scanimage
        function siConnect(obj)
            obj.hServer.connect();
        end
        
        %Grab a stack from scanimage
        function siGrabStack(obj)
            obj.hServer.stop();
            obj.hServer.start();
            obj.frameProcessMode = 'acq';
            obj.siSendCmd('hSI.startGrab');
            obj.hROISelector.updateView();
        end
        
        %Abort current scanimage acq
        function siAbort(obj)
            obj.siSendCmd('hSI.abort');
            obj.hServer.stop();
        end
        
        function siViewStack(obj)
            obj.hServer.stop();
            obj.loadAcqStack();
            obj.hROISelector.initialize();
            obj.hROISelector.updateView();
        end
        
        function siSendCmd(obj,str)
            obj.hServer.sendCmd(str);
        end
        
        function flag = siConnected(obj)
            flag = obj.hServer.tcpConnected;
        end
    end
end
