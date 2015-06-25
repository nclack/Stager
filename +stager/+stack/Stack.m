%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HHMI - Janelia Farms Research Campus 2015 
% Author: Arunesh Mittal
% Email : mittala@janelia.hhmi.org 
% Tiff Reader Code: Vijay Iyer <vijay@vidriotech.com>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Stack < handle
    %% Public/Private Properties
    properties
        header;             % Header data from scim_openTif
        Aout;               % Tiff stack data MxMxZ, where Z is the number of slices
        numChans;           % Num chans in loaded tiff stack
        numZPlanes;         % Num of planes in the loaded tiff stack
        numFrames;          % Num of frames in the loaded tiff stack
        frameHeight;        % Frame height for the loaded tiff stack
        frameWidth;         % Frame width for the loaded tiff stack
    end
    
    %% Constructor
    methods
        function obj = Stack() 
            
        end
    end
    
    %% Public Methods
    methods
        function loadTiff(obj,inFilePath)
            if nargin < 2
                [FileName,PathName,~] = uigetfile( '*.tif');
                inFilePath = fullfile(PathName,FileName);
            end
            
            [obj.header, obj.Aout, ~] = stager.util.scim_openTif(inFilePath);
            obj.numChans    = size(obj.Aout,3);
            obj.numZPlanes  = obj.header.SI4.stackNumSlices;
            obj.numFrames   = size(obj.Aout,4)/obj.numZPlanes;
            obj.frameHeight = size(obj.Aout,1);
            obj.frameWidth  = size(obj.Aout,2);
        end
        
        function loadStagerAcq(obj,frameArray)
            nFrames = length(frameArray);
            chans = zeros(nFrames,1);
            zPlanes = zeros(nFrames,1);
            
            for i=1:nFrames
                chans(i) = frameArray(i).channel;
                zPlanes(i) = frameArray(i).zPlane;
            end
            
            obj.numChans = length(unique(chans));
            obj.numZPlanes = length(unique(zPlanes));
            obj.frameWidth = size(frameArray(i).frameData,2);
            obj.frameHeight = size(frameArray(i).frameData,1);
            obj.numFrames = floor(nFrames/obj.numZPlanes);
            
            obj.Aout = zeros(obj.frameHeight,obj.frameWidth,obj.numChans,obj.numFrames);
            
            frameIdx = 1;
            for i=1:obj.numChans
                for j=1:obj.numFrames
                    obj.Aout(:,:,i,j) = frameArray(frameIdx).frameData;
                    frameIdx = frameIdx+1;
                end
            end
        end
    end
    
    methods 
        function objClone = clone(obj)
            objClone = stager.stack.Stack();
            objMeta = ?stager.stack.Stack;
            for i=1:length(objMeta.PropertyList)
                propName = objMeta.PropertyList(i).Name;
                objClone.(propName) = obj.(propName);   
            end
        end
    end
end

