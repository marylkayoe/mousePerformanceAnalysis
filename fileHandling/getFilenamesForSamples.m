function fileNames = getFilenamesForSamples(dataFolder, EXPID, SAMPLEIDS, TASKID, TIMEPOINT, TRIALID, CAMID, USERID, VIDEOTYPE)
% returns cell array with filenames matching the specs 
% dataFolder: folder where the data is stored, without the last separator
% EXPID: experiment ID such as "GMD2"
% SAMPLEIDS: cell array with sample IDs such as {'S1', 'S2'}, or one 'S1'
% TASKID: task ID such as 'BB' (Balance Beam ), 'RR' (rightning reflex), 'OF' (open field)
% CAMID: string  used to select camera when there are more than one, such as 'CAM1'
% USERID: the experimenter's initials ('THT')
% TRIALID: string denoting the trial. Such as, 'Trial1'
% TIMEPOINT: string denoting the experimental timepoint, e.g. D21


if ~exist('TASKID', 'var')
    TASKID = 'OF';
    disp('No task ID given, defaulting to OF');
end

if ~exist('CAMID', 'var') 
    CAMID = '';
end

if ~exist('TRIALID', 'var')
    TRIALID = '';
end

if ~exist('TIMEPOINT', 'var')
    TIMEPOINT = '';
end

if ~exist('USERID', 'var')
    USERID = '';
end

if ~exist('VIDEOTYPE', 'var')
    VIDEOTYPE = '.avi';
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
    IDstring = [EXPID '_' sampleID '_' TASKID '_'] ;
    if ~isempty(TIMEPOINT)
        IDstring = [IDstring TIMEPOINT];
    end
    if ~isempty(CAMID)
        IDstring = [IDstring '_' CAMID];
    end
    if ~isempty(TRIALID)
        IDstring = [IDstring '_' TRIALID];
    end
        if ~isempty(USERID)
        IDstring = [IDstring '*' USERID];
    end

    IDstring = [IDstring VIDEOTYPE];
    searchString =  [dataFolder separator IDstring TRIALID];
    dirlist = dir (searchString);
    fileNames = [fileNames dirlist.name];
end

if isempty(fileNames)
    warning(strjoin({'No file found for',IDstring }));
end
