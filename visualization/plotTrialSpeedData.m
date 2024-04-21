function plotTrialSpeedData(instSpeeds, LOCOTHRESHOLD, FRAMERATE, dataDescriptor)
    % This function plots the instantaneous speeds over time, along with
    % the locomotion threshold as a horizontal dashed line.
    %
    % Inputs:
    % - instSpeeds: a single-column vector containing the instantaneous speeds
    % - LOCOTHRESHOLD: a scalar value representing the threshold for locomotion
    % - FRAMERATE: the framerate of the ''data
    % - dataDescriptor (optional): a string with additional information for the title, e.g., filename

    % Create the time axis using the makexAxisFromFrames function
    xAx = makexAxisFromFrames(length(instSpeeds), FRAMERATE);

    % Create a new figure and plot the instantaneous speeds
    figure;
    plot(xAx, instSpeeds, 'LineWidth', 1);
    hold on;

    % Plot the locomotion threshold as a horizontal dashed line
    h = yline(LOCOTHRESHOLD, '--', 'LOCOTHRESHOLD');

    % Calculate mean speed and locomotion time
    meanSpeed = nanmean(instSpeeds);
    [locoFrames, isLocomoting] = getLocoFrames(instSpeeds, LOCOTHRESHOLD);
    
    locoTime = sum(instSpeeds > LOCOTHRESHOLD) / FRAMERATE;
    totalDistance = nansum(instSpeeds) * (1/FRAMERATE);
    totalDistanceLocomoting = nansum(instSpeeds(isLocomoting)) * (1/FRAMERATE);

    % Add a text box with mean speed and locomotion time information
    infoText = sprintf('Mean Speed: %.1f mm/s\nLoco Time: %.1f s \nLoco distance: %.1f mm', meanSpeed, locoTime, totalDistanceLocomoting);
    annotation('textbox', [0.7, 0.65, 0.2, 0.2], 'String', infoText, 'EdgeColor', 'none');

    % Customize the plot appearance
    xlabel('Time (s)');
    ylabel('Speed (mm/sec)');

    if exist('dataDescriptor', 'var')
        title(['Instantaneous Speeds and Locomotion Threshold - ', dataDescriptor]);
    else
        title('Instantaneous Speeds and Locomotion Threshold');
    end
    grid on;

    % Release the hold on the current figure
    hold off;
end
