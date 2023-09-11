function newFilePath = convertToMP4(fullFilePath)

[pathstr, name, ext] = fileparts(fullFilePath);
newFilePath = fullfile(pathstr, [name '.mp4']);
newFileExists = dir(newFilePath);
if isempty(newFileExists)
    fprintf('Converting %s to mp4... 4x spatial downsample \n', fullFilePath);
    cmd = sprintf('ffmpeg -i %s -c:v libx264 -crf 19 -preset slow -vf scale=iw/4:-1 -an -vsync 0 %s', fullFilePath, newFilePath);
    [failed] = system(cmd);
    if failed
        disp('Conversion failed, aborting');
        newFilePath = [];
        return;
    end
else
    disp('Found existing .mp4 file, using it');
end


