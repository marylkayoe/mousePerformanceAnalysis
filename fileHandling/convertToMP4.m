function newFilePath = convertToMP4(fullFilePath, DOWNSAMPLERATIO)

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end



[pathstr, name, ext] = fileparts(fullFilePath);
newFilePath = fullfile(pathstr, [name '.mp4']);
newFileExists = dir(newFilePath);
if isempty(newFileExists)

    % Get frame rate  and size of the original video

    % Get the resolution of the original video
    [status, cmdout] = system(sprintf('ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "%s"', fullFilePath));

    if status == 0
        resolution = strsplit(cmdout, 'x');
        width = str2double(resolution{1});
        height = str2double(resolution{2});
        fprintf('Original resolution: %dx%d\n', width, height);
    else
        warning('Could not determine resolution. Proceeding without resolution information.');
    end


    [status, cmdout] = system(sprintf('ffmpeg -i "%s" -hide_banner', fullFilePath));
    framerate = regexp(cmdout, '(\d+(?:\.\d+)?) fps', 'tokens');
    if ~isempty(framerate)
        framerate = str2double(framerate{1}{1});
        fprintf('Original framerate: %.2f fps\n', framerate);
    else
        warning('Could not determine framerate. Proceeding without framerate information.');
    end
    fprintf('Converting %s to mp4... %d x spatial downsample, original framerate \n', fullFilePath, DOWNSAMPLERATIO);

    %cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -crf 0 -preset veryslow -vf scale=iw/%d:-1 -an -vsync 0 "%s" >/dev/null 2>&1', fullFilePath, DOWNSAMPLERATIO, newFilePath);

    cropHeight = height / 2;  % retain the middle 50% of the video vertically
    cropWidth = width;  % retain 100% of the video horizontally

    % Creating the ffmpeg command with the crop and scale filters
    cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -crf 0 -preset veryslow -vf "crop=%d:%d:0:%d,scale=iw/%d:-1" -an -vsync 0 "%s" >/dev/null 2>&1', ...
        fullFilePath, cropWidth, cropHeight, height/4, DOWNSAMPLERATIO, newFilePath);






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


