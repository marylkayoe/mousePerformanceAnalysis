function FFfoundVersion = checkFFmpegInstallation()
% Check if FFmpeg is installed and accessible from MATLAB
[status, cmdout] = system('ffmpeg -version');

if status == 0
    disp('FFmpeg is installed.');
    versionLine = strsplit(cmdout, '\n');
    versionInfo = strsplit(versionLine{1}, ' ');
    ffmpegVersion = versionInfo{3};
    disp(['ffmpeg version : ' ffmpegVersion]);
    FFfoundVersion = str2double(ffmpegVersion(1));
else
    warning('FFmpeg is not installed or not accessible from MATLAB. Please install FFmpeg and add it to the system path.');
    FFfoundVersion = 0;
end
end
