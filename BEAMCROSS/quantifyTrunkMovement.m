function movementTrace = quantifyTrunkMovement(videoMatrix, trunkMaskMatrix)
    %QUANTIFYTRUNKMOVEMENT 
    % Computes frame-to-frame movement in columns where the mouse trunk 
    % is present, ignoring everything else.
    %
    % INPUTS:
    %   videoMatrix      - 3D (height x width x nFrames), grayscale
    %   trunkMaskMatrix - 3D logical (height x width x nFrames) 
    %                     1 where trunk is present, 0 otherwise
    %
    % OUTPUT:
    %   movementTrace - 1D array of length nFrames, 
    %                   movementTrace(k) is the motion from frame k-1 to k.
    
        [~, ~, nFrames] = size(videoMatrix);
    
        % We'll store one movement value per frame.
        movementTrace = zeros(nFrames, 1);
    
        % By convention, the first frame has no previous frame to compare to:
        movementTrace(1) = 0;  
    
        for k = 2:nFrames
            % Current and previous frames
            currentFrame  = im2double(videoMatrix(:,:,k));
            previousFrame = im2double(videoMatrix(:,:,k-1));
    
            % Current and previous trunk masks
            currentMask  = trunkMaskMatrix(:,:,k);
            previousMask = trunkMaskMatrix(:,:,k-1);
    
            % Intersection of trunk areas so we don't “see motion” 
            % if the trunk mask changed between frames
            validMask = currentMask & previousMask;
    
            % Compute absolute difference
            frameDiff = abs(currentFrame - previousFrame);
    
            % Zero out any pixels outside the trunk intersection
            frameDiff(~validMask) = 0;
    
            % Sum all differences for a single movement measure
            movementTrace(k) = sum(frameDiff(:));
        end
    end
    