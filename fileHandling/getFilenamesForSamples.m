function fileNames = getFilenamesForSamples(dataFolder,EXPID, SAMPLEIDS, TASKID, RECORDINGID)
% returns cell array with filenames matching the specs 
% dataFolder: folder where the data is stored, without the last separator
% EXPID: experiment ID such as "GMD2"
% SAMPLEIDS: cell array with sample IDs such as {'S1', 'S2'}
% TASKID: task ID such as 'BB' (Balance Beam ), 'RR' (rightning reflex), 'OF' (open field)
% RECORDINGID: string  used to select recording type, such as '*CAM1*.avi'

if (~exist('EXPID', 'var'))
    EXPID = 'GMD2';
end


if (~exist('TASKID', 'var'))
    TASKID = 'OF';
end

if (~exist('SAMPLEIDS', 'var'))
    SAMPLEIDS = {'A2'};
end




if (isunix)
    separator = '/';
else
    separator = '\';
end


fileNames = {};


if (ischar(SAMPLEIDS))
    nSamples = 1;
    SAMPLEIDS = {SAMPLEIDS};
else
    nSamples = length(SAMPLEIDS);
end

% loop through samples
for sample = 1:nSamples
    sampleID = SAMPLEIDS{sample};
    IDstring = [EXPID '_' sampleID '_' TASKID];
    searchString =  [dataFolder separator IDstring RECORDINGID];
    dirlist = dir (searchString);
    fileNames = [fileNames dirlist.name];
end
