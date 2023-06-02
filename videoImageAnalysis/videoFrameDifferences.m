function diffs = videoFrameDifferences(vidObj)
    
% videoFrameDifferences - calculate the difference between each pair of consecutive frames in a video
    diffs = zeros(vidObj.NumberOfFrames-1, 1);
    
    for i = 2:vidObj.NumberOfFrames
        frame1 = read(vidObj, i-1);
        frame2 = read(vidObj, i);
        diffs(i-1) = sum(abs(frame1(:)-frame2(:)));
    end
    end