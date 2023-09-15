function [centerFrames borderFrames centerFraction] = getCenterBorderFrames(coordData, BORDERLIMIT)

if (~exist('BORDERLIMIT', 'var'))
    warning('BORDERLIMIT missing - defaulting to 10%');
    BORDERLIMIT = 10;
end

nFRAMES = length(coordData);

xMovementRange = range(coordData(:, 1));
yMovementRange = range(coordData(:, 2));


nearLeftFrames = find(coordData(:, 1) < (min(coordData(:, 1))+xMovementRange*BORDERLIMIT));
nearRightFrames = find(coordData(:, 1) > (max(coordData(:, 1))-xMovementRange*BORDERLIMIT));
nearLRframes = union (nearLeftFrames, nearRightFrames);
nearTopFrames = find(coordData(:, 2) < (min(coordData(:, 2))+yMovementRange*BORDERLIMIT));
nearBottomFrames = find(coordData(:, 2) > (max(coordData(:, 2))-yMovementRange*BORDERLIMIT));
nearTBframes = union (nearTopFrames, nearBottomFrames);
borderFrames = union(nearLRframes, nearTBframes);


% pack results

centerFrames = setdiff(1:nFRAMES, borderFrames);

 centerFraction = round((length(centerFrames) * 100) / nFRAMES) ;
