function convertedFileName = convertAVIToGray(aviFileName, dataPath, savePath, varargin)
    % reads an avi and converts it into nearly lossless mp4
    % calls ffmpeg, so make sure it is installed and in your system path
    % Syntax:
    %   convertedFileName = convertAviToGray(aviFileName, dataPath, 'scaleFactor', 0.5);
    % INPUTS:
    %   aviFileName: String, name of the .avi video file.
    %   dataPath: String, path to the directory containing the video file.
    %  savePath: String, path to the directory to save the output .mkv file.
    %   'scaleFactor' (optional): Scalar to spatially downscale the video (default: 1).
    %.  'overwriteExisting' (optional): Boolean to overwrite existing mkv file (default: false).
    % OUTPUTS:
    %   convertedFileName: String, name of the output .mkv video file.
    % 
    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'scaleFactor', 1, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 1);
    addParameter(p, 'overwriteExisting', false, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});
    scaleFactor = p.Results.scaleFactor;    


    % check the folder and file exist
    fullAviFilePath = fullfile(dataPath, aviFileName);
    if ~exist(fullAviFilePath, 'file')
        warning('The specified AVI file does not exist: %s', fullAviFilePath);
        convertedFileName = '';
        return;
    end 

    %% check if FFmpeg is installed*%
    FFfoundVersion = checkFFmpegInstallation();
    if FFfoundVersion == 0
        warning('FFmpeg not found. Please install FFmpeg and add it to the system path.');
        convertedFileName = '';
        return;
    end

    % check if the savePath exists, if not create it
    if ~exist(savePath, 'dir')
        mkdir(savePath);
        disp(['Created directory: ', savePath]);
    end

    % construct output file name
    [~, name, ~] = fileparts(aviFileName);
    convertedFileName = fullfile(savePath, [name, '_gray.mp4']);

    % check if the  file already exists
    if exist(convertedFileName, 'file') && ~p.Results.overwriteExisting
        disp(['Output  file already exists and overwriteExisting is false: ', convertedFileName]);
        return;
    end 

    % construct ffmpeg command
    % ffmpeg -y -i "in.avi" -an -c:v libx264 -crf 0 -preset veryslow -pix_fmt gray "out_gray_lossless.mp4"

    scaleFilter = '';
    if scaleFactor < 1
        scaleFilter = sprintf(',scale=iw*%f:ih*%f', scaleFactor, scaleFactor);
    end

    %% FFMPEG COMMAND:
    % we use mp4 codec, with some compression (-crf 18), grayscale pixel format, no audio, veryslow setting for best quality
   ffmpegCmd = sprintf(['ffmpeg -i "%s" -vf "format=gray%s" ', ...
    '-pix_fmt gray -c:v libx264 -crf 18 -preset veryslow ', ...
    '-tune grain -g 24 -an -y "%s"'], ...
    fullAviFilePath, scaleFilter, convertedFileName);

        disp(['Converting AVI to grayscale MP4: ', convertedFileName]);

    % execute ffmpeg command
    [status, cmdout] = system(ffmpegCmd);
    if status ~= 0
        warning('FFmpeg command failed: %s', cmdout);
        convertedFileName = '';
        return;
    end
    disp(cmdout)

    disp(['Successfully converted AVI to grayscale MKV: ', convertedFileName]);
end



