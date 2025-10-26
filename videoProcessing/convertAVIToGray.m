function mkvFileName = convertAVIToGray(aviFileName, dataPath, savePath, varargin)
    % reads an avi and converts it into lossless mkv in grayscale format 
    % calls ffmpeg, so make sure it is installed and in your system path
    % Syntax:
    %   mkvFileName = convertAviToGray(aviFileName, dataPath, 'scaleFactor', 0.5);
    % INPUTS:
    %   aviFileName: String, name of the .avi video file.
    %   dataPath: String, path to the directory containing the video file.
    %  savePath: String, path to the directory to save the output .mkv file.
    %   'scaleFactor' (optional): Scalar to spatially downscale the video (default: 1).
    %.  'overwriteExisting' (optional): Boolean to overwrite existing mkv file (default: false).
    % OUTPUTS:
    %   mkvFileName: String, name of the output .mkv video file.
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
        mkvFileName = '';
        return;
    end 

    %% check if FFmpeg is installed*%
    FFfoundVersion = checkFFmpegInstallation();
    if FFfoundVersion == 0
        warning('FFmpeg not found. Please install FFmpeg and add it to the system path.');
        mkvFileName = '';
        return;
    end

    % check if the savePath exists, if not create it
    if ~exist(savePath, 'dir')
        mkdir(savePath);
        disp(['Created directory: ', savePath]);
    end

    % construct output mkv file name
    [~, name, ~] = fileparts(aviFileName);
    mkvFileName = fullfile(savePath, [name, '_gray.mkv']);

    % check if the mkv file already exists
    if exist(mkvFileName, 'file') && ~p.Results.overwriteExisting
        disp(['Output MKV file already exists and overwriteExisting is false: ', mkvFileName]);
        return;
    end 

    % construct ffmpeg command
    scaleFilter = '';
    if scaleFactor < 1
        scaleFilter = sprintf(',scale=iw*%f:ih*%f', scaleFactor, scaleFactor);
    end

    %% FFMPEG COMMAND:
    % we use ffv1 codec for lossless compression, grayscale pixel format, no audio, and set gop size to 1 for intra-frame coding
    ffmpegCmd = sprintf('ffmpeg -i "%s" -vf "format=gray%s" -an -c:v ffv1 -level 3 -g 1 -slicecrc 1 -pix_fmt gray "%s"', ...
        fullAviFilePath, scaleFilter, mkvFileName);
    % execute ffmpeg command
    [status, cmdout] = system(ffmpegCmd);
    if status ~= 0
        warning('FFmpeg command failed: %s', cmdout);
        mkvFileName = '';
        return;
    end

    disp(['Successfully converted AVI to grayscale MKV: ', mkvFileName]);
end



