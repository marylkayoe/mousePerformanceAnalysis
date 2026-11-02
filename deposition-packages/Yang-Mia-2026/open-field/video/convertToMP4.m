function newFilePath = convertToMP4(fullFilePath, DOWNSAMPLERATIO)
% convert an AVI video to MP4 using FFmpeg, as a separate preparation step
% FFmpeg must be installed and available in the system path used by MATLAB
%
% fullFilePath: full path to the AVI file
% DOWNSAMPLERATIO: spatial reduction factor, default 2; use 1 for no downsampling
% newFilePath: MP4 saved beside the AVI, or [] if conversion fails
% an existing MP4 with the same name is used without converting again
%
% uses the 2023 settings: libx264, CRF 0, veryslow, no audio or cropping
% timestamps are passed through, without forcing a frame rate
% after 2x downsampling, mm/pixel must be doubled for physical calibration
%
% Example:
% newFilePath = convertToMP4('/path/to/recording.avi', 2);

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end

if ~exist(fullFilePath, 'file')
    warning('File does not exist: %s', fullFilePath);
    newFilePath = [];
    return;
end

[pathstr, name, ~] = fileparts(fullFilePath);
newFilePath = fullfile(pathstr, [name '.mp4']);
if exist(newFilePath, 'file')
    disp(['Found existing MP4, using it: ' newFilePath]);
    return;
end

% historical command (2023); -vsync 0 is no longer available in FFmpeg 9
% cmd = sprintf('ffmpeg -i "%s" -c:v libx264 -crf 0 -preset veryslow -vf scale=iw/%d:-1 -an -vsync 0 "%s"', fullFilePath, DOWNSAMPLERATIO, newFilePath);

% -fps_mode passthrough replaces -vsync 0, with the other settings retained
% -nostdin and -n avoid prompts and overwriting existing output
cmd = sprintf(['ffmpeg -nostdin -n -hide_banner -loglevel error -i "%s" ' ...
    '-c:v libx264 -crf 0 -preset veryslow -vf scale=iw/%d:-1 ' ...
    '-an -fps_mode passthrough "%s" 2>&1'], ...
    fullFilePath, DOWNSAMPLERATIO, newFilePath);

fprintf('Converting with %d x spatial downsampling: %s\n', DOWNSAMPLERATIO, fullFilePath);
[failed, cmdout] = system(cmd);
if failed
    warning('Conversion failed: %s', cmdout);
    newFilePath = [];
    return;
end

disp(['Conversion completed: ' newFilePath]);
end
