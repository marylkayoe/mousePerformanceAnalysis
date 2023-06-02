function vidObj = readBehaviorVideo(filePath)
% readBehaviorVideo - read behavior video file
if iscell(filePath)
    filePath = filePath{1};
end
% Check if file exists
if ~exist(filePath, 'file')
    error('File %s does not exist.', videoFile);
end

% if the file is an .avi video, call system ffmpeg and convert it to mp4:
if strcmp(filePath(end-3:end), '.avi')
    [pathstr, name, ext] = fileparts(filePath);
    newFilePath = fullfile(pathstr, [name '.mp4']);
    if ~exist(newFilePath, 'file')
        fprintf('Converting %s to mp4...\n', filePath);
        cmd = sprintf('ffmpeg -i %s -c:v libx264 -crf 19 -preset slow -vf scale=iw/4:-1 -an -vsync 0 %s', filePath, newFilePath);
        system(cmd);

    end
    filePath = newFilePath;
end



% Check if it's a valid video file
try
    vidObj = VideoReader(filePath);
catch ME
    error('File %s is not a valid video file. \nError Message: %s', filePath, ME.message);
end

