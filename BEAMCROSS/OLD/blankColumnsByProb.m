function newVideoMatrix = blankColumnsByProb(videoMatrix, probValueMatrix)
% loop through all the frames in underBarVideoMatrix
% blank out all COLUMNS where the mouseProbVals are less than mouseProbTH 
[imHeight imWidth nFRAMES] = size(videoMatrix); 


globalThreshold = multithresh(probValueMatrix, 2);
mouseprobTH = globalThreshold(end);
newVideoMatrix = videoMatrix;
for frame = 1:nFRAMES
    currFrame = newVideoMatrix(:, :, frame);
    blankedColumns = find(probValueMatrix(:, frame) < mouseprobTH);
    currFrame(:, blankedColumns) = 0;
    newVideoMatrix(:, :, frame) = currFrame;
end