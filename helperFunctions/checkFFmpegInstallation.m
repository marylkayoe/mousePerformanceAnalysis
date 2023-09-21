function FFfound = checkFFmpegInstallation()
    % Check if FFmpeg is installed and accessible from MATLAB
    [status, cmdout] = system('ffmpeg -version');
    
    if status == 0
        disp('FFmpeg is installed correctly.');
         disp('FFmpeg version info:');
         disp(cmdout);
        FFfound =1;
    else
        warning('FFmpeg is not installed or not accessible from MATLAB. Please install FFmpeg and add it to the system path.');
        FFfound = 0;
    end
end
