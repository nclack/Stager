%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HHMI - Janelia Farms Research Campus 2015
% Author: Arunesh Mittal
% Email : mittala@janelia.hhmi.org
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Server < handle
    %% Public/Private Methods
    properties
        %User configurable var
        frameGrabPeriod = .02;                                 % frame grab period for the timer
        linesPerFrame = 512;                                   % number of lines per frame; Frame height in pixels
        pixelsPerLine = 512;                                   % number of pixels per line; Frame width in pixels
        
        %State variables
        stopFrameGrabber = 0;                                  % flag to start/stop importing frames from client
        currentFrameNum = 1;                                   % frame number of most recently acquired frame
        
        %Private
        filepath;                                              % filename for memmap file for most recently acquired frame
        
        %Handles
        hFrameGrabTimerFcn;                                    % time function that imports the frame from client
        hMMapFile;                                             % handle to memmap file for most recently acquired frame
        hFrame;                                                % handle to most recently acquired frame
        hStager;                                               % handle to stager object
        hJtcp;                                                 % handle to jtcp object 
        hJtcpTimer;                                            % handle to timer object which listens to and evalues incoming messages from server
        
        %TCP/IP settings
        portNumber = 21566;                                    % accept connections on this port
        timeout = 20000;                                       % timeout for waiting on client connection 
        jtcpTimePeriod=.25;                                    % timer period for reading and evaluating tcp messages received from server;
        tcpConnected = 0;                                      % flag indicates whether stager is connected to scanimage client of not
    
        %client/server flags
        streamerFlag = 0;                                      % flag indicates wheter streamer has been initialized
        lockTimer;                                             % timer to measure time elapsed since process was locked 
        lockTimeOut = 10;                                      % time to wait before process lock times out
    end
    
    %% Event to process new frame
    events
        frameReceived;
    end
    
    %% Constructor
    methods
        function obj = Server(hStager)
            obj.hStager = hStager;
            
            %Create a timer object
            obj.hFrameGrabTimerFcn = timer('Name','frameGrabber','Period',obj.frameGrabPeriod,...
                'ExecutionMode','fixedRate','TimerFcn',@(~,~)obj.grabFrameFromClient());
        end
    end
    
    %% Public Methods
    methods
        function start(obj)
            %Initialize Memmap by getting new filename from server
            obj.initMemMap();
            
            %Reset frame counter
            obj.currentFrameNum = 0;
            fprintf('Awaiting frames from ScanImage\n');
            obj.stopFrameGrabber = 0;
            
            %Start timer
            start(obj.hFrameGrabTimerFcn);
        end
        
        function stop(obj)
            obj.stopFrameGrabber = 1;
        end
        
        %Start tcp/ip session wait for client
        function connect(obj)
            fprintf('Waiting for client on port %d...\n',obj.portNumber);
            try
                obj.hJtcp = jtcp('accept',obj.portNumber,'timeout',obj.timeout); 
            catch exception;
                fprintf('Unable to connect to client:\n');
                rethrow(exception);
            end
            
            fprintf('Connected.\n');
             
            obj.hJtcpTimer = timer('TimerFcn',@(x,y)obj.readCmd,'ExecutionMode','fixedRate','Period',obj.jtcpTimePeriod); 
            start(obj.hJtcpTimer);
            
            obj.tcpConnected = 1;
        end
        
        %Send cmd to client via tcp/ip
        function resp = sendCmd(obj,str)
            str = sprintf('evalin(''base'',''%s'')',str);
            jtcp('write',obj.hJtcp,str);
            obj.lock();
        end
        
        %Read and evaluate cmd from server
        function resp = readCmd(obj,evt)
            msg = jtcp('read',obj.hJtcp);
            if ~isempty(msg)
                fprintf('Server Cmd: %s\n',msg);
                try
                    %TODO what if resp is not a string?
                    eval(msg);
                catch
                    fprintf('Unable to evaluate command.\n');
                end
            end
        end
    end
    
    %% Private Methods
    methods (Access = private)
        function grabFrameFromClient(obj)
            %Check for interrupt
            if obj.stopFrameGrabber
                stop(obj.hFrameGrabTimerFcn);
            end
            
            if obj.hMMapFile.data(1) == 1
                %Notify if frame dropped
                if (obj.currentFrameNum-obj.hMMapFile.data(4) > 1)
                    obj.currentFrameNum
                    obj.hMMapFile.data(3)
                    fprintf('Dropped Frame!\n');
                end
                
                %Read frame if new frame is available
                if obj.hMMapFile.data(4) > obj.currentFrameNum
                    %byte 1: acqRunning
                    %byte 2: channel
                    %byte 3: zPlane
                    %byte 4: frame number
                    %byte 5: num rows - lines per frame
                    %byte 6: num cols - pixels per line
                    
                    frameData = obj.hMMapFile.Data;
                    obj.hFrame.frameData = reshape(frameData(7:end),frameData(5),frameData(6));
                    obj.hFrame.zPlane = frameData(3);
                    obj.hFrame.channel = frameData(2);
                    
                    %Notify stager
                    notify(obj,'frameReceived');
                    fprintf('Frame # %d\n',frameData(4));
                    obj.currentFrameNum = frameData(4);
                end
            elseif obj.hMMapFile.data(1) == 0
                obj.currentFrameNum = 0;
            end
        end
        
        function initMemMap(obj)
            assert(obj.tcpConnected==1,'Unable to start: Not Connected to Client');
            
            %Reset memmap
            obj.sendCmd('hStreamer.initialize');
            
            %Get filename
            obj.sendCmd('hStreamer.getMemMapFilepath');
            
            %Map the file to memory
            obj.hMMapFile = memmapfile(obj.filepath, 'Writable', true, 'Format', 'uint16');
            
            %Frame object
            obj.hFrame = stager.stack.Frame();
            obj.hFrame.frameData = zeros(obj.linesPerFrame,obj.pixelsPerLine);
        end
        
        function lock(obj)
            obj.streamerFlag = 0;
            obj.lockTimer = tic;
            while obj.streamerFlag ~= 1
                %do nothing
                if toc(obj.lockTimer) > obj.lockTimeOut
                    error('Client Timeout');
                end
            end
        end
    end
end
