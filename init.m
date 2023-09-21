% Obtain the current system path
currentPath = getenv('PATH');

% Specify the path to the directory containing ffmpeg
ffmpegPath = '/usr/local/bin/'; % Replace this with your actual path
ffmpegPathTara = '/opt/homebrew/bin/'; % Replace this with your actual path
% Check if the ffmpeg path is already in the system path
if isempty(strfind(currentPath, ffmpegPath))
    % If not, add it
    setenv('PATH', [currentPath ':' ffmpegPath]);
end

if isempty(strfind(currentPath, ffmpegPath))
    % If not, add it
    setenv('PATH', [currentPath ':' ffmpegPath]);
   
end



if isempty(strfind(currentPath, ffmpegPathTara))
    % If not, add it
    setenv('PATH', [currentPath ':' ffmpegPathTara]);
   
end

