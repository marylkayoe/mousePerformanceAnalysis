function stdDiffs = getHighProbFrameDifferences(videoMatrix, probValMatrix, SMOOTHWIN, ZTHRESHOLD)

if ~exist('ZTHRESHOLD', 'var')
    ZTHRESHOLD = 2.5;
end

[imHeight imWidth nFRAMES] = size(videoMatrix); 

frameDiffs = zeros(nFRAMES,1);

diffImages = diff(videoMatrix, 1, 3);
absDiffImages = abs(diffImages);
columnDiffs = squeeze(sum(absDiffImages, 1))';
columnDiffs = cat(1, columnDiffs, zeros(1, imWidth));

% Get the dimensions of columnDiffs and probValMatrix
[sizeRowColDiffs, sizeColColDiffs] = size(columnDiffs);
[sizeRowProbVal, sizeColProbVal] = size(probValMatrix);

% Check if the dimensions match
if sizeRowColDiffs ~= sizeRowProbVal || sizeColColDiffs ~= sizeColProbVal
    % If not, transpose probValMatrix
    probValMatrix = probValMatrix';
end

% Now perform the element-wise multiplication
probDiffs = columnDiffs .* probValMatrix;
probDiffsFrames = sum(probDiffs, 2, 'omitnan');
smoothDiffs = smooth(probDiffsFrames,SMOOTHWIN);
stdDiffs = zscore(smoothDiffs);
stdDiffs(stdDiffs<ZTHRESHOLD) = 0;
% normFrameDiffs = smoothDiffs ./ max(smoothDiffs);
% 
% normFrameDiffs(normFrameDiffs<0.1)= 0;

