function movementMatrix = quantifyFrameMovement(videoMatrix)
    % quantifyFramewiseMovement  Computes per-pixel movement as absolute difference
    %                            between successive frames in a grayscale video.
    %
    %   movementMatrix = quantifyFramewiseMovement(videoMatrix)
    %
    % INPUT:
    %   videoMatrix - 3D array of size (height x width x nFrames), grayscale.
    %                 Can be uint8/double/etc.
    %
    % OUTPUT:
    %   movementMatrix - 3D array of the same size, where movementMatrix(:,:,k)
    %                    is the per-pixel absolute difference between frame k
    %                    and frame k-1. The first frame has no previous frame, so
    %                    movementMatrix(:,:,1) will be all zeros (by convention).
    %
    % EXAMPLE USAGE:
    %   movementMatrix = quantifyFramewiseMovement(myVideo);
    %   % Then, for each frame k, you can sum up movementMatrix(:,:,k) to get
    %   % a scalar measure of how much movement occurred in that frame.
    
        [vidHeight, vidWidth, nFrames] = size(videoMatrix);
    
        % Preallocate output of the same type as input
        movementMatrix = zeros(size(videoMatrix), 'like', videoMatrix);
    
        % Loop from 2nd frame onward
        for frameIndex = 2:nFrames
            % Current frame
            currentFrame = videoMatrix(:,:,frameIndex);
            % Previous frame
            prevFrame    = videoMatrix(:,:,frameIndex - 1);
    
            % Convert to double if needed, for difference
            % (This step is optional if your input is already double.)
            currentFrameD = im2double(currentFrame);
            prevFrameD    = im2double(prevFrame);
    
            % Absolute difference
            frameDiff = abs(currentFrameD - prevFrameD);
    
            % Convert back to original type if you want to keep movementMatrix 
            % consistent. Or just store it in double.
            movementMatrix(:,:,frameIndex) = cast(frameDiff, 'like', videoMatrix);
        end
    end
    