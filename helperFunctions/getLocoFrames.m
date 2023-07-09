function [locoFrames, isLocomoting] = getLocoFrames(instSpeeds, LOCOTHRESHOLD)
    % This function returns the indexes of frames where the instantaneous
    % speed is above the given LOCOTHRESHOLD, as well as a logical array indicating
    % frames where locomotion was happening.
    %
    % Inputs:
    % - instSpeeds: a single-column vector containing the instantaneous speeds
    % - LOCOTHRESHOLD: a scalar value representing the LOCOTHRESHOLD for locomotion
    %
    % Outputs:
    % - locoFrames: an array containing the indexes of frames where locomotion occurs
    % - isLocomoting: a logical array indicating if locomotion is happening at each frame

     % Validate input arguments
     if ~isvector(instSpeeds)
        error('Invalid input: instSpeeds should be a vector');
    end

    % Set the default LOCOTHRESHOLD value if not provided
    if ~exist('LOCOTHRESHOLD', 'var')
        LOCOTHRESHOLD = 40; % Default LOCOTHRESHOLD value
    elseif ~isscalar(LOCOTHRESHOLD)
        error('Invalid input: LOCOTHRESHOLD should be a scalar value');
    end

    % Determine if the speed is above the LOCOTHRESHOLD for each frame
    isLocomoting = instSpeeds > LOCOTHRESHOLD;

    % Find the indexes of frames where locomotion occurs
    locoFrames = find(isLocomoting);
end
