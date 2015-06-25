classdef TimeSeries < handle
    
    properties
        header;                 %Tif header info
        frameArray;             %Array for storing individual frames of the stack
        pixRange;               %Lowest and highest pixel value for the stack; Array: [2 x 1]
        dataType;               %This could be binary
        registerFrames;         %If true, frames are registered to the template image registered before being added to the time series
    end
    
    %Constructor
    methods
        function obj = ZPlaneTimeSeries(header,frameTimeSeries,pixRange)
            if nargin > 0
                obj.header = header;
                obj.pixRange = pixRange;
                obj.frameArray = stager.stack.Frame.empty();
                numFrames = size(frameTimeSeries,3);
                
                for frameNum=1:numFrames
                    newFrame = stager.stack.Frame(frameTimeSeries(:,:,frameNum));
                    obj.frameArray(frameNum) = newFrame;
                end
            end
        end
    end
    
    %Public Methods
    methods
        function addFrame(obj,frame)
            if nargin>1    
                obj.frameArray(frameNum) = frame;
            elseif nargin==1
                newFrame = Frame();
                obj.frameArray(frameNum) = newFrame;
            end
        end
        
        function frameArray = generateReference(obj)
            % heirarchical referencing method - reference pairs of adjacent frames
            % average them together and repeat until only one frame left - this is
            % master image
            num_ims = size(obj.frameArray,2);
            num_heirarch = floor(log2(num_ims));
            im_stack_raw = obj.frameArray(1:2^num_heirarch);
            num_ims = 2^num_heirarch;
            display = 0;
            
            for ik = 1:num_heirarch
                %fprintf('Pyramid Registration: level %d of %d...\n',ik,num_heirarch);
                frameArray = stager.stack.Frame.empty(0,num_ims/2);
                num_ims = size(frameArray,2);
                for ih = 1:num_ims
                    tic
                    im_A = im_stack_raw(1+2*(ih-1)).frameData;
                    im_B = im_stack_raw(2+2*(ih-1)).frameData;
                    [corr_offset] = stager.stack.Frame.gcorr(im_A,im_B);
                    im_A_shift = stager.stack.Frame.func_im_shift(im_A,corr_offset);
                    frameArray(ih) = (im_A_shift + im_B)/2;
                    toc
                    if display
                        imagesc(frameArray(ih).frameData);
                        pause(.1);
                    end
                end
            end
            fprintf('Done.\n');
        end
    end
end

