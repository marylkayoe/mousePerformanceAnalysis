function [normMouseProbVals, mouseProbMatrix ]= getMouseProbOnBeam(mouseMaskMatrix)

[imHeight,imWidth, nFRAMES] = size(mouseMaskMatrix);
%CROPEDGE = floor(imWidth / 10); % cropping edges
% CROPEDGE = 1;
% mouseMaskMatrix  = mouseMaskMatrix(:, CROPEDGE:end-CROPEDGE, :);
% [imHeight,imWidth, nFRAMES] = size(mouseMaskMatrix);

mouseProbMatrix = zeros(size(mouseMaskMatrix));
mouseProbFrame = zeros(imHeight, imWidth);
disp('Calculating mouse probability density ...');
% loop through all frames
xInd = 1:nFRAMES;
for frame = 1:nFRAMES
    currFrame = mouseMaskMatrix(:, :, frame);
    mouseProbFrame = zeros(size(currFrame));
    mousePosVerticalSum = sum(currFrame, 1)';

    normMouseProbVals(:, frame) = (mousePosVerticalSum ./ (imHeight / 100));

    % Ensure no index is zero
    validIndices = mousePosVerticalSum > 0;

    % Get valid x indices and mousePosVerticalSum values
    if isempty(validIndices)
        warning('empty');
    else
    validXInd = xInd(validIndices);
 
    validXInd = validXInd';
    validMousePosVerticalSum = mousePosVerticalSum(validIndices);

    end
    if isempty(validXInd)
    else

        % Convert subscript indices to linear indices
        linearIndices = sub2ind(size(mouseProbFrame), validMousePosVerticalSum, validXInd);

        % Set the respective pixels to 1
        mouseProbFrame(linearIndices) = 1;
        mouseProbMatrix(:, :, frame) = flipud(mouseProbFrame);

    end


end