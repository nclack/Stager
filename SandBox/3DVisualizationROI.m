hFig = figure;
set(hFig, 'renderer', 'opengl');
hold on;
surf(1*ones(size(TheImage)),double(TheImage),'EdgeColor','none')
surf(2*ones(size(TheImage)),double(TheImage),'EdgeColor','none')
surf(3*ones(size(TheImage)),double(TheImage),'EdgeColor','none')
alpha .3