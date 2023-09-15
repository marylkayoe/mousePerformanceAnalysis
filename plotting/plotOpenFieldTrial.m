function f = plotOpenFieldTrial(coordData,speedArray, centerFrames, BORDERLIMIT, FRAMERATE, XYSCALE, FILEID)
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

if (~exist('FRAMERATE', 'var'))
    warning('FRAMERATE missing - defaulting to 25');
    FRAMERATE = 25;
end

if (~exist('centerFrames', 'var'))
    centerFrames =  [];
    centerFraction = 0;
else
    centerFraction = round((length(centerFrames) * 100) / nRows) ;

end

if (~exist('BORDERLIMIT', 'var'))
    BORDERLIMIT = 0.15;

end


figure; hold on;
coordData = coordData ./ XYSCALE; % scaling in xy
colormap(hot);
if ~isempty(centerFrames)
    scatter(coordData(centerFrames, 1), coordData(centerFrames, 2), 'o');
end
patch(coordData(:, 1), coordData(:, 2),speedArray,'EdgeColor','interp', 'FaceColor','none', 'LineWidth', 3, 'HandleVisibility', 'off');
set(gca,'Color', [0.7 0.7 0.7]);
caxis([0 250]);
c = colorbar;
c.Label.String = 'mouse speed mm/sec';


legend('in center', 'Location', 'northeastoutside', 'FontSize', 12);
xlabel ('X (mm)');
ylabel ('Y (mm)');

axis tight;
f = gca;
title(['Open field trajectory for '  FILEID ', center fraction ' num2str(centerFraction, '%.2d') '%']);
end

