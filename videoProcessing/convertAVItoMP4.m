function currNamePath = convertAVItoMP4(fullFilePath, DOWNSAMPLERATIO, cropVideoVertical, cropVideoHorizontal, verticalOffset, OVERWRITEEXISTING)
    % convertAVIToMP4 - Convert an AVI file to an MP4 file using the H.264 codec
    % and the MPEG-4 container format.

    % note: the conversion is done by operating FFmpeg outside Matlab. This is done
    % by first creating the command as a string and then sending it to the system
    % using the system() - command. It should work both on MacOS and Windows provided that the file paths
    % are correctly formatted.

    % downsampleRatio - The ratio to downsample the video by. For example, if
    % the video is 1920x1080 and downsampleRatio is 2, the video will be
    % downsampled to 960x540

    % fullFilePath - the full path to the AVI file to convert
    % cropVideoVertical (0-40)- percentage of the video to crop from the top and bottom, 0 if no cropping (default)
    % max vertical crop 50 % of the frame height (25% from top and 25% from bottom)
    % cropVideoHorizontal - percentage of the video to crop from the left and right, 0 if no cropping (default)
    % max horizontal crop 50 % of the frame width (25% from left and 25% from right)
    % verticalOffset - the vertical offset (in % of half frame) to apply to the video, 0 if no offset (default);
    % positive values move the video up, negative values move the video down
    % offset 25 means that the video will be moved up by 25% of the frame height
    % offset -25 means that the video will be moved down by 25% of the frame height
    % offset is applied to the cropping operation if cropping is enabled
    % if no cropping is enabled, no offset is applied

    %OVERWRITEEXISTING - if set to 1, the function will overwrite the existing file
    % if set to 0, the function will not overwrite the existing file (default)

    % Example usage: 
    % convertAVItoMP4('C:\Users\user\Documents\video.avi', 2, 10, 10, 25)

    % this will downsample the video by 2, crop 10% from the top and bottom, 
    % 10% from the left and right and move the video up by 25% of the frame height

    % if parameters after filepath are not provided or are 0, no cropping or downsampling will be done

    if ~exist('fullFilePath', 'var')
        warning('No file path provided, aborting conversion');
        currNamePath = '';
        return;
    end

    %check if the original file is avi format:
    [~, ~, ext] = fileparts(fullFilePath);
    if ~strcmp(ext, '.avi')
        warning('The file is not in AVI format, aborting conversion');
        currNamePath = '';
        return;
    end



    %% Setting default values:
    if ~exist('DOWNSAMPLERATIO', 'var')
        DOWNSAMPLERATIO = 1; % no downsampling by default
    end

    if ~exist('cropVideoVertical', 'var')
        cropVideoVertical = 0;
    else

        if cropVideoVertical < 0 || cropVideoVertical > 50
            warning('Vertical cropping must be between 0 and 50, setting to 0.');
            cropVideoVertical = 0;
        end

    end

    if ~exist('cropVideoHorizontal', 'var')
        cropVideoHorizontal = 0;
    else

        if cropVideoHorizontal < 0 || cropVideoHorizontal > 50
            warning('Horizontal cropping must be between 0 and 50, setting to 0.');
            cropVideoHorizontal = 0;
        end

    end

    if ~exist('verticalOffset', 'var')
        verticalOffset = 0;
    end

    if ~exist('OVERWRITEEXISTING', 'var') % do we possibly existing mp4 file?
        OVERWRITEEXISTING = 0;
    end

    if exist(fullFilePath, 'file')
        %check if FFmpeg is installed.

        FFfoundVersion = checkFFmpegInstallation();

        if FFfoundVersion == 0
            error('FFmpeg not found. Please install FFmpeg and add it to the system path.');
        end

        % check the resolution of the video
        [status, cmdout] = system(sprintf('ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "%s"', fullFilePath));

        if status == 0
            resolution = strsplit(cmdout, 'x');
            width = str2double(resolution{1});
            height = str2double(resolution{2});
            fprintf('Original resolution: %dx%d\n', width, height);
        else
            warning('Could not determine resolution. Proceeding without resolution information.');
        end

        % check the framerate of the video
        [status, cmdout] = system(sprintf('ffmpeg -i "%s" -hide_banner', fullFilePath));
        frameRate = regexp(cmdout, '(\d+(?:\.\d+)?) fps', 'tokens');

        if ~isempty(frameRate)
            frameRate = str2double(frameRate{1}{1});
            fprintf('Original framerate: %.2f fps\n', frameRate);
        else
            warning('Could not determine framerate. Proceeding without framerate information.');
        end

        % calculate values for cropping and offset
        if cropVideoVertical > 0
            cropHeight = round(height * cropVideoVertical / 100);
            outputHeight = round(cropHeight / DOWNSAMPLERATIO); % compensate for downscaling
            verticalOffset = round(cropHeight / 2 * verticalOffset / 100);
        else
            cropHeight = height;
            outputHeight = round(cropHeight / DOWNSAMPLERATIO);
        end

        if cropVideoHorizontal > 0
            cropWidth = round(width * cropVideoHorizontal / 100);
            outputWidth = floor(cropWidth / DOWNSAMPLERATIO);
        else
            cropWidth = width;
            outputWidth = floor(cropWidth / DOWNSAMPLERATIO);
        end

        % new file name and path generation:
        [path, name, ext] = fileparts(fullFilePath);
        nameMod = '';

        if (DOWNSAMPLERATIO > 1)
            nameMod = [nameMod '_downsampled'];
        end

        if (cropVideoVertical > 0)
            nameMod = [nameMod '_cropped'];
        end

        if (verticalOffset ~= 0)
            nameMod = [nameMod '_offset'];
        end

        name = [name nameMod];
        %check if file with the same name exists already
        currName = fullfile(path, [name '.mp4']);
        if exist(currName, 'file')
            if OVERWRITEEXISTING
                name = [name];
                warning(['File ' currName ' already exists, overwriting.']);
            else
                name = [name '_new'];
            end
        end

        currNamePath = fullfile(path, [name '.mp4']);



        %% check if we want to overwrite possibly existing file
        % Do the conversion
        fprintf('Converting %s to mp4... %d x spatial downsample, original framerate \n', name, DOWNSAMPLERATIO);
        % description of the ffmpeg command:
        % -i input file
        % -c:v libx264  (H.264 codec)
        % -r framerate  (fps)
        % -crf 1 (constant rate factor, 1 is the highest quality)
        % -preset veryslow (slowest encoding, best quality)
        % -vf "crop=width:height:x:y,scale=width:height" (crop and scale the video: x and y are the top left corner of the crop)
        % scale=width:height (downsample the video to width x height)
        % -an (no audio)

        cmd = sprintf('ffmpeg -y -i "%s" -c:v libx264 -r %d -crf 1 -preset veryslow -vf "crop=%d:%d:0:%d,scale=%d:%d" -an -fps_mode cfr "%s"', fullFilePath, frameRate, cropWidth, cropHeight, verticalOffset, outputWidth, outputHeight, currNamePath);
        failed = system(cmd);

    else
        error(['File' fullFilePath 'does not exist.']);
    end
