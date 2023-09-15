function [videoMatrix filePath frameRate, DOWNSAMPLERATIO] = readBehaviorVideo(filePath, DOWNSAMPLERATIO)
% readBehaviorVideo - read behavior video file
% if filename is not mp4, attempt to find a mp4 version, if such does not
% exist then making a conversion

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 4;
end


if iscell(filePath)
    filePath = filePath{1};
end


% Check if file exists
if ~exist(filePath, 'file')
    error('File %s does not exist.', videoFile);
end

% if the file is an .avi video, call system ffmpeg and convert it to mp4:
% note ffmpeg needs full path to file
if strcmp(filePath(end-3:end), '.avi')
    [pathstr, name, ext] = fileparts(filePath);
    newFilePath = fullfile(pathstr, [name '.mp4']);
    if ~exist(newFilePath, 'file')
        disp('Need to convert .avi to .mp4');
        filePath = convertToMP4(filePath, DOWNSAMPLERATIO);

    end
    filePath = newFilePath;
end

[videoMatrix frameRate] = readVideoIntoMatrix(filePath);
frameRate = floor(frameRate);
end