function R = saveVideoMatrixMP4(videoMatrix, fileName)
% saveVideoMatrixMP4 Save a video matrix to an MP4 file
% input: videoMatrix - a 3D matrix representing a video
%        filename - the name of the file to save the video to
% output: R - the result of the operation (1 if successful, 0 otherwise)

% Create a VideoWriter object
v = VideoWriter(fileName, 'MPEG-4');

% Open the video file for writing
open(v);

% Get the number of frames
numFrames = size(videoMatrix, 3);

% Write each frame to the file
for k = 1:numFrames
    % Get the k-th frame
    frame = videoMatrix(:, :, k);
    
    % Write the frame to the file
    writeVideo(v, frame);
end

% Close the file
close(v);