function [normMouseProbVals mouseProbMatrix ]= getMouseProbOnBeam(mouseMaskMatrix)

[imHeight,imWidth, nFRAMES] = size(mouseMaskMatrix);
mouseProbMatrix = zeros(size(mouseMaskMatrix));
mouseProbFrame = zeros(imHeight, imWidth);

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
    validXInd = xInd(validIndices);
    validXInd = validXInd';
    validMousePosVerticalSum = mousePosVerticalSum(validIndices);


  if isempty(validXInd)
  else

    % Convert subscript indices to linear indices
    linearIndices = sub2ind(size(mouseProbFrame), validMousePosVerticalSum, validXInd);
    
    % Set the respective pixels to 1
    mouseProbFrame(linearIndices) = 1;
mouseProbMatrix(:, :, frame) = flipud(mouseProbFrame);

  end


end