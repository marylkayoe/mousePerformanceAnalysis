function newFilePath = convertToMP4(fullFilePath, DOWNSAMPLERATIO, CROPVIDEO)

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end

if ~exist('CROPVIDEO', 'var')
    CROPVIDEO = 0;
end
CROPOFFSETADJ = 0; % if cropping ends up too high, increase this(eg 0.05)

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



%%
if CROPVIDEO
    cropHeight = floor(height / 2);  % retain the middle 50% of the video vertically
    yOffset = floor((height - cropHeight) / 2) + floor((height - cropHeight) / 2 * CROPOFFSETADJ); % Adjust this to change the vertical start point of the crop
    newHeight = floor(cropHeight / DOWNSAMPLERATIO); % compensate for downscaling
    if mod(cropHeight, 2) ~= 0
        cropHeight = cropHeight - 1;
    end
else
    cropHeight = height;
    yOffset = 0;
    newHeight = floor(height / DOWNSAMPLERATIO); % here we get the newHeight if CROPVIDEO is false
    if mod(newHeight, 2) ~= 0
        newHeight = newHeight - 1;
    end
end 

% Defining the new width values
cropWidth = width; % retain 100% of the video horizontally
newWidth = floor(width / DOWNSAMPLERATIO); 
if mod(newWidth, 2) ~= 0
    newWidth = newWidth - 1;
end

newHeight = floor(cropHeight / DOWNSAMPLERATIO);
if mod(newHeight, 2) ~= 0
    newHeight = newHeight + 1;
end


cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -crf 0 -preset veryslow -vf "crop=%d:%d:0:%d,scale=%d:%d" -an -vsync 0 "%s">/dev/null 2>&1', ...
    fullFilePath, cropWidth, cropHeight, yOffset, newWidth, newHeight, newFilePath);

% cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -crf 0 -preset veryslow -vf "crop=%d:%d:0:%d,scale=%d:%d" -an -vsync 0 "%s"', ...
%     fullFilePath, cropWidth, cropHeight, yOffset, newWidth, newHeight, newFilePath);


    [failed] = system(cmd);
    if failed
        disp('Conversion failed, aborting');
        newFilePath = [];
        return;
    else
        [status, cmdout] = system(sprintf('ffmpeg -i "%s" -hide_banner', newFilePath));
        framerate = regexp(cmdout, '(\d+(?:\.\d+)?) fps', 'tokens');
            [status, cmdout] = system(sprintf('ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "%s"', newFilePath));
 resolution = strsplit(cmdout, 'x');
        width = str2double(resolution{1});
        height = str2double(resolution{2});
        fprintf('New resolution: %dx%d\n', width, height);
        disp(["Conversion completed, new frame rate " framerate]);
    end
else
    disp('Found existing .mp4 file, using it');
end


