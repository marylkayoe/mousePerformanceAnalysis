function plotTrialSpeedData(instSpeeds, LOCOTHRESHOLD, FRAMERATE, dataDescriptor)
% Plot whole-mouse speed over time and the locomotion threshold.
% instSpeeds: processed speed estimates in mm/s.
% LOCOTHRESHOLD: locomotion threshold in mm/s.
% FRAMERATE: analysis frame rate in frames/s.
% dataDescriptor: optional title text, such as the video filename.

% Each speed estimate starts one frame after the previous one.
time = (0:length(instSpeeds)-1) / FRAMERATE;
[~, isLocomoting] = getLocoFrames(instSpeeds, LOCOTHRESHOLD);
meanSpeed = mean(instSpeeds, 'omitnan');
locoTime = sum(isLocomoting) / FRAMERATE;
locoDistance = sum(instSpeeds(isLocomoting), 'omitnan') / FRAMERATE;

figure('Color', 'w');
plot(time, instSpeeds, 'Color', [0.15 0.4 0.7], 'LineWidth', 1.2);
hold on;
yline(LOCOTHRESHOLD, '--', sprintf('Threshold: %g mm/s', LOCOTHRESHOLD), ...
    'Color', [0.5 0.3 0.3], 'LineWidth', 1.1);

xlabel('Time (s)');
ylabel('Speed (mm/s)');
title('Open-field speed');
if exist('dataDescriptor', 'var') && ~isempty(dataDescriptor)
    subtitle(dataDescriptor, 'Interpreter', 'none');
end

infoText = sprintf('Mean speed (all): %.1f mm/s\nLocomoting time: %.1f s\nLocomoting distance: %.1f mm', ...
    meanSpeed, locoTime, locoDistance);
text(0.98, 0.98, infoText, 'Units', 'normalized', ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'w', 'Margin', 6);

set(gca, 'Box', 'off', 'TickDir', 'out', 'FontSize', 11);
grid on;
hold off;
end
