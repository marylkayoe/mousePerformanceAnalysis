function [normMouseProbVals, mouseProbMatrix] = computeMouseProbabilityMap(mouseMaskMatrix)
    % COMPUTEMOUSEPROBABILITYMAP Efficiently computes mouse pixel fraction per column per frame.
    %
    % INPUT:
    %   mouseMaskMatrix: logical array (height x width x nFrames), indicating mouse pixels.
    %
    % OUTPUTS:
    %   normMouseProbVals : (width x nFrames), fraction of mouse pixels per column.
    %   mouseProbMatrix   : (height x width x nFrames), replicated probability images.
    
    [imHeight, imWidth, nFrames] = size(mouseMaskMatrix);
    
    % 1. Sum mouse-pixels along rows for all frames simultaneously
    colSumAllFrames = squeeze(sum(mouseMaskMatrix, 1)); % size: [imWidth x nFrames]
    
    % 2. Convert column-sums to fractions (dividing by height)
    normMouseProbVals = colSumAllFrames / imHeight; % [imWidth x nFrames]
    
    % 3. Replicate fractions down the rows to create mouse probability matrix
    mouseProbMatrix = repmat(reshape(normMouseProbVals, [1, imWidth, nFrames]), imHeight, 1, 1);
    
    end
    
