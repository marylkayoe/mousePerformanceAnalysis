function plotBBtrial( ...
    movementTrace, FRAMERATE, ...
    slipEventStarts, slipEventAreas, ...
    mouseCentroids, forwardSpeeds, ...
    meanSpeed, traverseDuration, meanPosturalHeight, ...
    fileName)
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
% NOTE: This function does not strictly need the entire videoMatrix if you only
%       want to show the movement trace + 2D positions. But you can certainly
%       modify it to show frames or other details.

    % -- Create a time axis from frames if desired --
    nFrames = length(movementTrace);
    timeAxis = (0 : nFrames-1) / FRAMERATE;  % in seconds

    % -- Create figure and subplots --
    % figure name should be the file name cleaned up from underscores
    figTitle = cleanUnderscores(fileName);
    figure('Name', figTitle, 'Color', 'w');
    
    % =========== SUBPLOT #1: Movement Trace ===========================
    subplot(2,1,1);  % top subplot
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
    legend('Slip events (size indicates magnitude)', 'Location', 'best');

    title('Movement detected under bar, with detected slips','FontSize',12);
    xlabel('Time (s)');
    ylabel('Movement (pixels)');
    grid on;

    % =========== SUBPLOT #2: Mouse 2D Position ========================
    subplot(2,1,2);  
    hold on;
    
    % Plot the mouse XY path
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
    ylim([0, 30]);  % assuming 20 is the max height

    % Adjust color limits to highlight speed range
    caxis([0, max(forwardSpeeds)]);

    % legend for the markers
    legend('Slip events (size indicates magnitude)', 'Location', 'best');

 
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
end
