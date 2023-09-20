function fileID = getFileIDfromFilename (fileName)
% neat formatting of file ID based on filename
if iscell(fileName)
    fileName = fileName{1};
end
fileName = replace(fileName,'_','-'); % underscores look bad in matlab plotting, replacing with -

% WIN or MAC compatible file naming
if(contains(fileName, '/'))
    separator = '/';
else
    separator = '\';
end

%if filename contains separators (usually folder path info), exclude them
%from file name (take characters after the last separator)
sepPos = contains(fileName, separator);
if (sepPos) 
fileID = fileName(sepPos(end)+1:end);
else 
    fileID = fileName; % if no separators, it's plain filename
end

% extracts the beginning of a file name that should have the main info for
% the material
% this is build on template name such as
% GMD2_A2_OF_D07_17_04_2019_proc_bij_6_08_19_A
% we use characters up to fourth dash (-)
delimitpos = strfind(fileID, '-');
fileID = fileID(1:delimitpos(4)-1);