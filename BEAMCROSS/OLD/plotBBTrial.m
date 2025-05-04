function f = plotBBTrial(coordData,colorArray, keyFrames, FRAMERATE, XYSCALE, FILEID, TITLESTRING, COLORLABEL)
% a plot to show the trajectory. return handle to the plot
% speedArray - inst speed of mouse in the frame
% centerFrames - the frames in which themouse is in center
% SCALE - how many mm per pixel
% FRAMERATE of recording. default 25
% FILEID is used for making title in a plot
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

if (~exist('TITLESTRING', 'var'))
    TITLESTRING = 'BB trial: ';

end

if (~exist('COLORLABEL', 'var'))
    COLORLABEL = 'COLOR VALUE ';

end


if (~exist('FRAMERATE', 'var'))
    warning('FRAMERATE missing - defaulting to 100');
    FRAMERATE = 100;
end

if (~exist('keyFrames', 'var'))
    keyFrames =  [];
    nEvents = 0;
else
    nEvents = length(keyFrames);

end

% which direction the mouse is going?

startIndex = find(~isnan(coordData(:, 1)), 1, 'first');
endIndex = find(~isnan(coordData(:, 1)), 1, 'last');
STARTX = coordData(startIndex, 1);
ENDX = coordData(endIndex, 1);
if STARTX > ENDX
    xArrowStart = 0.6;
    xArrowEnd = 0.4;
else
    xArrowStart = 0.4;
    xArrowEnd = 0.6;
end
arrowLabel = 'Mouse Direction';
xArrowYpos =  0.6;

% Get the limits of your x-axis
xLimits = xlim;


figure; hold on;
coordData = coordData * XYSCALE; % scaling in xy
coordData(:, 2) = -coordData(:, 2);
coordData(:, 2) = coordData (:, 2) - mean(coordData(:, 2), 'omitnan');
colormap(hot);

patch(coordData(:, 1), coordData(:, 2),colorArray,'EdgeColor','interp', 'FaceColor','none', 'LineWidth', 3, 'HandleVisibility', 'on');
set(gca,'Color', [0.7 0.7 0.7]);
clim('auto');
c = colorbar;
c.Label.String = COLORLABEL;
legendString = {'centroid'};
if ~isempty(keyFrames)
    scatter(coordData(keyFrames, 1), coordData(keyFrames, 2), 100, 'cyan', 'filled', 'o');
    legendString{2} = 'SLIP';
end
legend(legendString);
legend({'in center', 'END'}, 'Location', 'northeastoutside', 'FontSize', 12);
xlabel ('X (mm)');
ylabel ('Y (mm)');

annotation('arrow', [xArrowStart, xArrowEnd], [xArrowYpos, xArrowYpos], 'LineWidth', 4);
annotation('textbox', [mean([xArrowStart xArrowEnd])-0.05, 0.7, 0.1, 0.03], ...
    'String', arrowLabel, 'FontSize', 15, 'LineStyle', 'none', ...
    'HorizontalAlignment', 'center');
ylim([-5 20]);

f = gca;
title([TITLESTRING ' ' FILEID ', n slips: ' num2str(nEvents, '%d')]);
end

