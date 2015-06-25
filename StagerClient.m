function StagerClient(hSI,e,~)

persistent filename frameNum frameLPF framePPL frameData frameMMap dummyData idx acqRunning hStreamer
channel = 1;
testMode = 1;
headerSize = 6; %Number of elements appended to image vector

if testMode && isempty(dummyData)
    filename_ = 'Y:\Code\Analysis_\Simon_Data\data_for_arunesh\data_for_arunesh\an229716_2013_12_02_main_006.tif';
    [header,Aout,cmap] = stager.util.scim_openTif(filename_);
    dummyData = squeeze(Aout(:,:,1,1:header.SI4.stackNumSlices:end));
    idx = (1:83)';
end

switch e.EventName
    case ('acqModeStart')
        %Create memmap file for most recently acquired frame
        frameLPF = hSI.linesPerFrame;
        framePPL = hSI.pixelsPerLine;
        frameData = zeros(1,(frameLPF*framePPL)+headerSize);
        frameNum = 1;
        acqRunning = 1;
        hStreamer = evalin('base','hStreamer');
        filename = hStreamer.filepath;
        
        % Create the communications file.
        if ~exist(filename, 'file')
            [f, msg] = fopen(filename, 'wb');
            if f ~= -1
                fwrite(f, frameData, 'uint16');
                fclose(f);
            else
                error('MATLAB:stager:sendFrameToStager:cannotOpenFile', ...
                    'Cannot open file "%s": %s.', filename, msg);
            end
        end
        
        % Memory map the file.
        frameMMap = memmapfile(filename, 'Writable', true, 'Format', 'uint16');
        frameMMap.Data = uint16(frameData);
        
        % Reset
        frameMMap.Data(1) = acqRunning;
        frameMMap.Data(4) = 0;
        
        
    case ('frameAcquired')
        %byte 1: acqRunning
        %byte 2: channel
        %byte 3: zPlane
        %byte 4: frame number
        %byte 5: num rows - lines per frame
        %byte 6: num cols - pixels per line
        %TODO: Add undefined slots (trial#..acq#)
        
        if testMode
            hSI.acqFrameBuffer{1}{channel} = dummyData(:,:,idx(1));
            idx = circshift(idx,-1);
            drawnow;
        end
        
        zPlane = hSI.stackSlicesDone;
        frameMMap.Data = [uint16([acqRunning, channel, zPlane, frameNum, frameLPF, framePPL]), reshape(dummyData(:,:,idx(1)),1,frameLPF*framePPL)];
        frameNum = frameNum + 1;
    case ('acqModeDone')
        pause(5);
        frameMMap.Data(1) = ~acqRunning;
end
end
