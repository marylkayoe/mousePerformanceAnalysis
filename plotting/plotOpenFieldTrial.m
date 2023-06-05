function f = plotOpenFieldTrial(coordData,speedArray, centerFrames, BORDERLIMIT, FRAMERATE, XYSCALE)
% a plot to show the trajectory. return handle to the plot
% speedArray - inst speed of mouse in the frame
% centerFrames - the frames in which themouse is in center
% SCALE - how many mm per pixel
% FRAMERATE of recording. default 25

%% Checking input variables amd setting defaults
[nRows, nCols] = size(coordData);
if nCols ~= 2
    warning(['Expecting a 2-column matrix, got a ' num2str(nRows) '-by-' num2str(nCols) 'data']);
    f = [];
    return;
end

if (~exist('XYSCALE', 'var'))
    warning('SCALE missing - defaulting to 1');
    XYSCALE = 1;
end

if (~exist('FRAMERATE', 'var'))
    warning('FRAMERATE missing - defaulting to 25');
    FRAMERATE = 25;
end

if (~exist('BORDERLIMIT', 'var'))
    BORDERLIMIT = 0.15;
    return
end


 figure; hold on;
coordData = coordData ./ XYSCALE; % scaling in xy
colormap(hot);
patch(coordData(:, 1), coordData(:, 2),speedArray,'EdgeColor','interp', 'FaceColor','none', 'LineWidth', 3, 'HandleVisibility', 'off');
set(gca,'Color', [0.7 0.7 0.7]);
caxis([0 400]);
c = colorbar;
c.Label.String = 'mouse speed mm/sec';

scatter(coordData(centerFrames, 1), coordData(centerFrames, 2), 'o');
legend('in center', 'Location', 'northeastoutside');
xlabel ('X (mm)');
ylabel ('Y (mm)');

axis tight;
f = gca;
end

