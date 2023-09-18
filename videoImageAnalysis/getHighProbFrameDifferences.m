function normFrameDiffs = getHighProbFrameDifferences(videoMatrix, probValMatrix, SMOOTHWIN)
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
normFrameDiffs = smoothDiffs ./ max(smoothDiffs);

