function newFilePath = convertToMP4(fullFilePath, DOWNSAMPLERATIO)

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 4;
end



[pathstr, name, ext] = fileparts(fullFilePath);
newFilePath = fullfile(pathstr, [name '.mp4']);
newFileExists = dir(newFilePath);
if isempty(newFileExists)

    % Get frame rate of the original video
    [status, cmdout] = system(sprintf('ffmpeg -i "%s" -hide_banner', fullFilePath));
    framerate = regexp(cmdout, '(\d+(?:\.\d+)?) fps', 'tokens');
    if ~isempty(framerate)
        framerate = str2double(framerate{1}{1});
        fprintf('Original framerate: %.2f fps\n', framerate);
    else
        warning('Could not determine framerate. Proceeding without framerate information.');
    end
    fprintf('Converting %s to mp4... %d x spatial downsample, original framerate \n', fullFilePath, DOWNSAMPLERATIO);
    %cmd = sprintf('ffmpeg -i %s -c:v libx264 -crf 19 -preset slow -vf scale=iw/4:-1 -an -vsync 0 %s', fullFilePath, newFilePath);
    cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -crf 0 -preset veryslow -vf scale=iw/%d:-1 -an -vsync 0 "%s" >/dev/null 2>&1', fullFilePath, DOWNSAMPLERATIO, newFilePath);

    [failed] = system(cmd);
    if failed
        disp('Conversion failed, aborting');
        newFilePath = [];
        return;
    else
        [status, cmdout] = system(sprintf('ffmpeg -i "%s" -hide_banner', newFilePath));
        framerate = regexp(cmdout, '(\d+(?:\.\d+)?) fps', 'tokens');
        disp(["Conversion completed, new frame rate " framerate]);
    end
else
    disp('Found existing .mp4 file, using it');
end


