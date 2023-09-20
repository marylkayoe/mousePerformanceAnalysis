function frameRate = getFrameRateForVideo(dataFolder, fileName)

if iscell(fileName)
    fileName = fileName{1};
end
filePath = fullfile(dataFolder, fileName);

% form the command
cmd = sprintf('ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate %s', filePath);

% call the command
[status, frameRate] = system(cmd);
