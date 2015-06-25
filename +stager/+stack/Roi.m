%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HHMI - Janelia Farms Research Campus 2015 
% Author: Arunesh Mittal
% Email : mittala@janelia.hhmi.org 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Roi < handle
    %% Public/Private Properties
    properties
        hAnnotation;            % Handle to associated annotation object for figure overlay diplay 
        zPlane;                 % zPlane of the roi
        channel;                % channel of the roi
        position = [0 0 0 0];   % position relative to display axis ROISelector.hDispAx 
        iValArray;              % intensity value array; iValArray(1) holds the most recent value
        iValArrayDFOF;          % intensity value (Delta F/F) array; iValArrayDFOF(1) holds the most recent value
        bufferSize = 1000;      % valArray buffer size 
        mask;                   % mxn mask matrix applied to a new frame at coordinates specified by 'position' 
    end
    
    %% Constructor
    methods
        function obj = Roi(hAnnotation,zPlane,channel,position,mask)
            obj.hAnnotation = hAnnotation;
            obj.zPlane = zPlane;
            obj.channel = channel;
            obj.position = position;
            obj.iValArray = NaN(obj.bufferSize,1);
            obj.iValArrayDFOF = NaN(obj.bufferSize,1);
            obj.mask = mask;
        end
    end
    
    %% Public Methods
    methods
        function addVal(obj,iVal)
            obj.iValArray = circshift(obj.iValArray,-1);
            obj.iValArray(1) = iVal;
            obj.dFOF();
        end
        
        function flushBuffer(obj)
            obj.iValArray = NaN(obj.bufferSize,1);
             obj.iValArrayDFOF = NaN(obj.bufferSize,1);
        end
        
        %Compute delta F/F
        function dFOF(obj)
            F = obj.iValArray(~isnan(obj.iValArray));
            F_sorted = sort(F);
            F_mean = mean(F_sorted(1:min(ceil((10/100)*length(F)),length(F))));
            obj.iValArrayDFOF(1) = (F(1)-F_mean)./F(1);
            obj.iValArrayDFOF = circshift(obj.iValArrayDFOF,-1);
        end
    end
end

 