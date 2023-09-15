function fileID = getFileIDfromFilename (filename)
% neat formatting of file ID based on filename

filename = replace(filename,'_','-'); % underscores look bad in matlab plotting, replacing with -

% WIN or MAC compatible file naming
if(contains(filename, '/'))
    separator = '/';
else
    separator = '\';
end

%if filename contains separators (usually folder path info), exclude them
%from file name (take characters after the last separator)
sepPos = contains(filename, separator);
if (sepPos) 
fileID = filename(sepPos(end)+1:end);
else 
    fileID = filename; % if no separators, it's plain filename
end

% extracts the beginning of a file name that should have the main info for
% the material
% this is build on template name such as
% INH1A_S1_M1_MC6_FL2_17_04_2019_proc_bij_6_08_19_A
% we use characters up to third dash (-)
delimitpos = strfind(fileID, '-');
fileID = fileID(1:delimitpos(4)-1);