classdef TSTracer < handle
    properties
        hStager;
        numTimePts = 100;   % Num time points to display
        numRois = 10;       % Num roi objects
        tsData;             % NxT matrix, intensity data for N roi objects for T time pts
        hMainGui;
        hAx;
        hPlot;
        maxYVal;
    end
    
    methods
        function obj = TSTracer(hStager)
            obj.hStager = hStager;
            obj.hMainGui = tsTracer;
            data = guidata(obj.hMainGui);
            obj.hAx = data.ax_tsTrace;
            obj.tsData = zeros(obj.numTimePts, obj.numRois);
            obj.initializePlot();
        end
    end
    
    methods
        function initializePlot(obj,numTimePts,numRois)
            if nargin == 3
                obj.numTimePts = numTimePts;
                obj.numRois = numRois;
            end
            obj.tsData = zeros(obj.numTimePts, obj.numRois);
            obj.hPlot = plot(obj.hAx,obj.tsData);
            obj.updatePlot();
        end
        
        function updatePlot(obj)
            shiftedData = obj.shiftDispPlotData(obj.tsData);
            for i=1:obj.numRois
                set(obj.hPlot(i),'yData',shiftedData(:,i));
            end
            
            YLimMax = obj.maxYVal*obj.numRois;
            set(obj.hAx,'XLim',[1 obj.numTimePts],'YLim',[0 YLimMax],'Color','black','XColor','white','YColor','white');
            set(obj.hAx,'YTickLabel',([repmat([0 .5 ]',obj.numRois,1); 1]));
            set(obj.hAx,'YTick',0:.5:YLimMax);
        end
        
        %Shift the y values for plotting
        function shiftedPlotData = shiftDispPlotData(obj,plotData)
            obj.maxYVal = min(max(max(plotData),1));
            appendMatrix = repmat(obj.maxYVal,size(plotData));
            multMatrix = repmat(0:size(plotData,2)-1,size(plotData,1),1);
            shiftedPlotData = plotData + appendMatrix.*multMatrix;%+.5*obj.maxYVal;
        end
    end
end

