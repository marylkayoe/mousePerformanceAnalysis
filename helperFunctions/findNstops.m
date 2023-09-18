function [nSTOPS validStopStartIdx]  = findNstops(isLocomoting, FRAMERATE)

% Ensure isLocomoting is a row vector for easy processing
if size(isLocomoting, 1) > 1
    isLocomoting = isLocomoting';
end
minStopDur = FRAMERATE / 20;
% Find the indices where the mouse stops (locomotion ends)
stopStartIdx = find(diff([1, isLocomoting]) == -1);
stopEndIdx = find(diff([isLocomoting, 1]) == 1);

% Find the durations of the stops
stopDurations = stopEndIdx - stopStartIdx + 1;

% Find the valid stop events (those longer than minStopDur)
validStopIdx = find(stopDurations >= minStopDur);

% Get the number of valid stops
nSTOPS = length(validStopIdx);

validStopStartIdx = stopStartIdx(validStopIdx);