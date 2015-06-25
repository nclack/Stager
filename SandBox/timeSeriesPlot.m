function [ output_args ] = timeSeriesPlot( input_args )
%TIMESERIESPLOT Summary of this function goes here
%   Detailed explanation goes here

numPoints = 5;
myData = rand(1000,numPoints);
minX = 1;
maxX = 1000;
cmap = hsv(7);
maxValY = max(max(myData));

appendMatrix = repmat(maxValY,size(myData));
multMatrix = repmat([0:size(myData,2)-1],size(myData,1),1);
myData = myData + appendMatrix.*multMatrix;

hTSP = tsTracer;
data = guidata(hTSP);
hAx = data.ax_tsTrace;
hPlot = plot(hAx,myData(1:100,1:5));

for i=1:length(hPlot)
    set(hPlot(i),'Color',cmap(1+i,:),'LineWidth',.5);
end

set(hAx,'XLim',[minX maxX],'YLim',[0 numPoints*maxValY],'Color','black','XColor','white','YColor','white');
set(hAx,'YTickLabel',[0; repmat([.5 1]',numPoints,1)])
%grid(hAx);
end

