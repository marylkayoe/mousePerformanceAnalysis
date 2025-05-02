function plotBBtrial( movementTrace, FRAMERATE, slipEventStarts, slipEventAreas, ...
    mouseCentroids, forwardSpeeds,meanSpeed, traverseDuration, meanPosturalHeight,fileName, LOCOTHRESHOLD)
% PLOTBBTRIAL  Creates a figure with subplots for:
%   1) Movement trace + slip events
%   2) Mouse 2D position, color-coded by forward speed, slip events indicated
%
% SYNTAX:
%   plotBBtrial(movementTrace, FRAMERATE, ...
%               slipEventStarts, slipEventAreas, ...
%               mouseCentroids, forwardSpeeds, ...
%               meanSpeed, traverseDuration, meanPosturalHeight, fileName);
%
% INPUTS:
%   movementTrace     : 1D array of movement values (e.g. detrended + z-scored),
%                       length = nFrames
%   FRAMERATE         : frames per second (numeric)
%   slipEventStarts   : array of frame indices at which slip events start
%   slipEventAreas    : array of slip areas (same length as slipEventStarts),
%                       used to scale the scatter circles
%   mouseCentroids    : (nFrames x 2), each row = [xCoord, yCoord] of the mouse
%   forwardSpeeds     : (nFrames x 1), speed in e.g. pixels/s
%   meanSpeed         : scalar, average speed across the trial
%   traverseDuration  : scalar, how long the mouse took to cross the beam (s)
%   meanPosturalHeight: scalar, average height (pixels) above the bar
%   fileName          : string, name of the video/file (for labeling)
%

if ~exist('LOCOTHRESHOLD', 'var')
    LOCOTHRESHOLD = 100;   % default: 100 pixels/sec
end

    % -- Create a time axis from frames if desired --
    nFrames = length(movementTrace);
    timeAxis = (0 : nFrames-1) / FRAMERATE;  % in seconds

    % -- Create figure and subplots --
    % figure name should be the file name cleaned up from underscores
    figTitle = cleanUnderscores(fileName);
    figure('Name', figTitle, 'Color', 'w');

    % shape of subplot panels
    NROWS = 3;
    NCOLS = 1;

   % LOCOTHRESHOLD = 200; % threshold for stopping; in pixels/sec

    % define periods of stopping, as continuous segments below LOCOTHRESHOLD
    stoppingFrames= forwardSpeeds < LOCOTHRESHOLD;
    % morphological closing to connect small gaps, exclude too short periods
    stoppingFrames = bwareaopen(imclose(stoppingFrames, strel('line', 5, 0)), 10);
    % find contiguous regions of stopping
    cc = bwconncomp(stoppingFrames);
    % get the start and end frames of each stopping period
    stoppingPeriods = cellfun(@(x) [x(1), x(end)], cc.PixelIdxList, 'UniformOutput', false);
    % get the duration of each stopping period
    stoppingDurations = cellfun(@(x) diff(x)+1, stoppingPeriods);

    [stoppingFrames, stoppingPeriods] = detectStoppingOnBeam(forwardSpeeds, LOCOTHRESHOLD);
    
    % =========== SUBPLOT #1: Movement Under Bar Trace ===========================
    subplot(NROWS,NCOLS,1);  % top subplot
    hold on;
    % Plot the movement trace vs time (or vs frame #)
    plot(timeAxis, movementTrace, 'LineWidth',1.2, 'Color',[0 0.45 0.74], 'HandleVisibility','off');
    

    % Overlay slip events (if any)
    if ~isempty(slipEventStarts)
        % Convert slipEventStarts from frames to time if desired
        slipTimes = (slipEventStarts - 1) / FRAMERATE;  % minus 1 for zero-based
        % Scale marker size by slipEventAreas
        markerSizes = slipEventAreas * 20;  
        scatter(slipTimes, movementTrace(slipEventStarts), ...
            markerSizes, 'o', 'filled', 'MarkerFaceColor','r');
    end
    % legend for the markers
     if ~isempty(slipEventStarts)
    legend('Slip events (size indicates magnitude)', 'Location', 'best');
     end

    title('Movement detected under bar, with detected slips','FontSize',12);
    xlabel('Time (s)');
    ylabel('Movement (pixels)');
    grid on;

    % =========== SUBPLOT #2: Mouse 2D Position with speed ========================
    subplot(NROWS,NCOLS,2);  
    hold on;

    % Plot the mouse XY path, note y is with respect to bar
    plot(mouseCentroids(:,1), mouseCentroids(:,2), 'LineWidth',2, ...
         'Color',[0.3 0.3 0.3], 'HandleVisibility','off');
    
    % Color-scatter the centroid positions by forwardSpeeds
    scatter(mouseCentroids(:,1), mouseCentroids(:,2), ...
        50, forwardSpeeds, 'filled', 'HandleVisibility','off');
    colormap('cool'); 
    c = colorbar; 
    c.Label.String = 'Forward speed (pixels/s)';
    
    % Indicate slip events on the 2D path
    if ~isempty(slipEventStarts)
        scatter( mouseCentroids(slipEventStarts,1), ...
                 mouseCentroids(slipEventStarts,2), ...
                 slipEventAreas*20, 'ko', 'filled');
    end

    
    % Some axis labeling
    xlabel('Position along bar (px)');
    ylabel('Height above bar (px)');
    ylim([0, max(mouseCentroids(:, 2))+5]);  

    % Adjust color limits to highlight speed range
    caxis([0, max(forwardSpeeds)]);

    % legend for the markers
    if ~isempty(slipEventStarts)
    legend({'Slip events (size indicates magnitude)'}, 'Location', 'best');
    end

 
    % =========== Add Directional Arro to title ===============
    % Check initial vs final x, decide arrow direction
    
    if mouseCentroids(1,1) < mouseCentroids(end,1)
        % Left-to-right
         titleString = 'Forward \rightarrow';
        else
        titleString = '\leftarrow Forward';
    end

    title (['Mouse centroid trajectory,  ' titleString], 'FontSize', 12);
    % =========== Add Some Text Info (Trial Stats) =====================

    text(0.02, 0.25, sprintf('Mean speed: %.1f px/s', meanSpeed), ...
         'Units','normalized','FontSize',10);
    text(0.02, 0.19, sprintf('Traverse duration: %.2f s', traverseDuration), ...
         'Units','normalized','FontSize',10);
    text(0.02, 0.13, sprintf('Mean posture: %.1f px', meanPosturalHeight), ...
         'Units','normalized','FontSize',10);
    text(0.02, 0.07, ['Total slip magnitude: ', num2str(sum(slipEventAreas))], 'Units', 'normalized', 'FontSize', 10);

    % Done
    hold off;

    % =========== SUBPLOT #3: instantaneous speed profile plot ===============
    subplot(NROWS,NCOLS,3);  % bottom subplot
    hold on;
    % add gray transparent rectangles for stopping periods if any are found
    for i = 1:length(stoppingPeriods)
        % get the start and end times of the stopping period
        startFrame = stoppingPeriods{i}(1);
        endFrame = stoppingPeriods{i}(2);
        startTime = (startFrame - 1) / FRAMERATE;
        endTime = (endFrame - 1) / FRAMERATE;
        % plot a gray rectangle for the stopping period
        rectangle('Position', [startTime, 0, endTime-startTime, max(forwardSpeeds)], ...
            'FaceColor', [0.7, 0.7, 0.7, 0.1], 'FaceAlpha', 0.5, 'EdgeColor', 'k');
    end

     % Plot the forward speed vs time (or vs frame #)
    plot(timeAxis, forwardSpeeds, 'LineWidth',1.2, 'Color',[0.85 0.33 0.1], 'HandleVisibility','off');
   
    % dummy plot for legend for gray rectangles
    plot(NaN, NaN, 'Color', [0.7, 0.7, 0.7], 'LineWidth', 10);

    legend('Stops', 'Location', 'best');
    % Some axis labeling
    xlabel('Time (s)');
    ylabel('Forward speed (pixels/s)');
    title('Forward speed profile','FontSize',12);
    % add text about number and total duration of stops
    text(0.02, 0.3, sprintf('Number of stops: %d', length(stoppingPeriods)), ...
         'Units','normalized','FontSize',10);
    text(0.02, 0.15, sprintf('Total stop duration: %.2f s', sum(stoppingDurations)/FRAMERATE), ...
            'Units','normalized','FontSize',10);
            
    grid on;
    hold off;

    
end
