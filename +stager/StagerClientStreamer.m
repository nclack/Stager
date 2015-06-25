%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HHMI - Janelia Farms Research Campus 2015
% Author: Arunesh Mittal
% Email : mittala@janelia.hhmi.org
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef StagerClientStreamer < handle
   properties
        filepath;           %Filepath of memmap file 
        frameNum;           %Current frame num
        frameLPF;           %Frame lines per frame 
        framePPL;           %Frame pixels per line 
        frameData;          %Frame data (MxM)
        frameMMap;          %Handle to memmap object 
        channel;            %Current frame channel 
        zPlane;             %Current frame zPlane
        
        acqRunning;         %Flag: true if streamer is running/updating frames
        headerSize = 6;     %Number of elements appended to image vector
        hTiffStack;         %Handle to tiff stack
        frameRate = 1;      %Num frames to update per second
        
        %TCP/IP settings
        portNumber = 21566; %Accept connections on this port
        timeout = 20000;    %timeout for waiting on client connection 
        hJtcp;              %handle to jtcp object 
        hJtcpTimer;         %handle to timer object which listens to and evalues incoming messages from server
        jtcpTimePeriod=.25; %timer period for reading and evaluating tcp messages received from server;
  
        testMode = 1;       %flag for testing purposes only
        
    end
    %% Constructor
    methods
        function obj = StagerClientStreamer()
            obj.initialize();
        end
        
        function initialize(obj)
            %Create memmap file for most recently acquired frame
            obj.resetFilePath();
            
            if obj.testMode
                obj.initializeTestMode();
            end
            
            % Create the communications file.
            [f, msg] = fopen(obj.filepath, 'wb');
            if f ~= -1
                fwrite(f, obj.frameData, 'uint16');
                fclose(f);
            else
                error('MATLAB:stager:sendFrameToStager:cannotOpenFile', ...
                    'Cannot open file "%s": %s.', obj.filepath, msg);
            end
        
        
            % Memory map the file.
            obj.frameMMap = memmapfile(obj.filepath, 'Writable', true, 'Format', 'uint16');
            obj.frameMMap.Data = uint16(obj.frameData);
            
            % Reset
            obj.frameMMap.Data(1) = obj.acqRunning;
            obj.frameMMap.Data(4) = 0;
        end
        
        function initializeTestMode(obj)
            if isempty(obj.hTiffStack)
                obj.loadStack('Y:\Code\Analysis_\Simon_Data\data_for_arunesh\data_for_arunesh\an229716_2013_12_02_main_009.tif');
            end
            
            im = obj.hTiffStack.Aout(:,:,1,1);
            obj.frameLPF =  size(im,1);
            obj.framePPL = size(im,2);
            obj.frameData = zeros(1,(obj.frameLPF*obj.framePPL)+obj.headerSize);
            obj.frameNum = 1;
            obj.acqRunning = 1;
        end
    end
    
    %% User Methods
    methods
         %Load tiff stack
        function loadStack(obj,varargin)
            obj.hTiffStack = stager.stack.Stack;
            
            if nargin>1
                obj.hTiffStack.loadTiff(varargin{1});
            else
                obj.hTiffStack.loadTiff();
            end
        end
        
        function startStream(obj)
            numChans = obj.hTiffStack.numChans;
            numZPlanes = obj.hTiffStack.numZPlanes;
            numFrames =  obj.hTiffStack.numFrames;
            obj.acqRunning = 1;
            
            hFigure = figure;
            imagesc(zeros(obj.frameLPF,obj.framePPL));
            
            for frameIdx=1:numFrames
                for chanIdx=1%:numChans
                    for zPlaneIdx=1%:numZPlanes
                        im = obj.hTiffStack.Aout(:,:,chanIdx,zPlaneIdx+((frameIdx-1)*numZPlanes));
                        
                        obj.channel = chanIdx;
                        obj.zPlane = zPlaneIdx;
                        obj.frameNum = frameIdx;
                        
                        obj.updateMemMap(im);
                        
                        fprintf('Frame #:%1.0f\n',zPlaneIdx+((frameIdx-1)*numZPlanes));
                        imagesc(im);drawnow;
                        
                        if obj.acqRunning == 0
                            break;
                        end
                        pause(1/30);
                    end
                end
            end
            
            close(hFigure);
        end
        
        function stop(obj)
            obj.acqRunning = 0;
            obj.frameMMap.Data(1) = obj.acqRunning;
        end
        
        %Start tcp/ip session wait for client
        function connect(obj)
            fprintf('Waiting for server on port %d...\n',obj.portNumber);
            try
                obj.hJtcp = jtcp('request','localhost',obj.portNumber,'timeout',obj.timeout);
            catch exception
                fprintf('Unable to connect to client:\n');
                rethrow(exception);
            end
            
            fprintf('Connected.\n');
            
            obj.hJtcpTimer = timer('TimerFcn',@(x,y)obj.readCmd,'ExecutionMode','fixedRate','Period',obj.jtcpTimePeriod); 
            start(obj.hJtcpTimer);
        end
        
        %Send cmd to client via tcp/ip
        function sendCmd(obj,str)
            str = sprintf('evalin(''base'',''%s'')',str);
            jtcp('write',obj.hJtcp,str);
        end
        
        %Read and evaluate cmd from server
        function readCmd(obj,evt)
            msg = jtcp('read',obj.hJtcp);
            if ~isempty(msg)
                fprintf('Server Cmd: %s\n',msg);
                try
                    %TODO what if resp is not a string?
                    eval(msg);
                    sendCmd(obj,'hStager.hServer.streamerFlag = 1');
                    %obj.sendCmd(resp);
                catch
                    fprintf('Unable to evaluate command.\n');
                end
            end
        end
    end
    
    %% Internal Methods
    methods
        function updateMemMap(obj,im)
            %byte 1: acqRunning
            %byte 2: channel
            %byte 3: zPlane
            %byte 4: frame number
            %byte 5: num rows - lines per frame
            %byte 6: num cols - pixels per line
            %TODO: Add undefined slots (trial#..acq#)
            
            obj.frameMMap.Data = [uint16([obj.acqRunning, obj.channel, obj.zPlane, obj.frameNum, obj.frameLPF, obj.framePPL]), reshape(im,1,obj.frameLPF*obj.framePPL)];
            obj.frameNum = obj.frameNum + 1;
        end
        
        function resetFilePath(obj)
            obj.filepath = tempname;
        end
    end
    
    %% Methods invoked by Server Only
    methods
        function getMemMapFilepath(obj)
            %Send server filename
            obj.sendCmd(sprintf('hStager.hServer.filepath = ''''%s''''',obj.filepath));
        end
    end
end


