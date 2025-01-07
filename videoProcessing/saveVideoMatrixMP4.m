function R = saveVideoMatrixMP4(videoMatrix, fileName)
    % saveVideoMatrixMP4 Save a video matrix (grayscale or RGB) to an MP4 file.
    %
    %   R = saveVideoMatrixMP4(videoMatrix, fileName)
    %
    %   INPUTS:
    %     videoMatrix : 
    %        - 3D array (H x W x nFrames) for grayscale
    %        - 4D array (H x W x 3 x nFrames) for RGB color
    %     fileName    : string, output .mp4 file name
    %
    %   OUTPUT:
    %     R : 1 if successful, 0 otherwise
    %
    % EXAMPLE:
    %   % Grayscale: (H x W x nFrames)
    %   saveVideoMatrixMP4(myGrayVideo, 'grayOutput.mp4');
    %
    %   % RGB: (H x W x 3 x nFrames)
    %   saveVideoMatrixMP4(myColorVideo, 'colorOutput.mp4');
    
        % Create a VideoWriter object
        v = VideoWriter(fileName, 'MPEG-4');
        % Optional: set frame rate, quality, etc. 
        % v.FrameRate = 30;
        % v.Quality   = 95;  % 0..100
    
        % Open the video file for writing
        open(v);
    
        % Determine if grayscale or color based on number of dimensions
        nDims = ndims(videoMatrix);
        if nDims == 3
            % (H x W x nFrames) => Grayscale
            [~, ~, numFrames] = size(videoMatrix);
            isColor = false;
        elseif nDims == 4
            % (H x W x 3 x nFrames) => Color
            [~, ~, numChannels, numFrames] = size(videoMatrix);
            if numChannels ~= 3
                error('For a 4D input, the 3rd dimension must be 3 (RGB).');
            end
            isColor = true;
        else
            error('videoMatrix must be either 3D (H x W x nFrames) or 4D (H x W x 3 x nFrames).');
        end
    
        % Write each frame
        for k = 1 : numFrames
            if isColor
                % Extract the k-th RGB frame
                frame = videoMatrix(:,:,:,k);
            else
                % Extract the k-th grayscale frame
                frame = videoMatrix(:,:,k);
            end
    
            % Write the frame to the file
            writeVideo(v, frame);
        end
    
        % Close the file
        close(v);
    
        disp(['Video saved as: ' fileName]);
        R = 1;  % Indicate success
    end
    