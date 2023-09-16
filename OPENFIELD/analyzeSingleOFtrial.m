function  [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, centerFraction, instSpeeds] = analyzeSingleOFtrial(dataFolder,EXPID, SAMPLEID, TASKID,TIMEPOINT, TRIALID, CAMID, USERID, PIXELSIZE, BORDERLIMIT, MAKEPLOTS, DOWNSAMPLERATIO )
% runs the analysis for single trial based on experimental identifiers
% this function finds the right filename and then calls analyzeSingleOFfile
% 
% TASKID: should be "OF" (default) 
% TIMEPOINT: which timepoint is used. eg. "D07".
% PIXELSIZE = how many mm one pixel is
% BORDERLIMIT : what fraction of the arena is considered to be "border" (default: 0.15)
% MAKEPLOTS : if 0, no figures are made, only results returned
% DOWNSAMPLERATIO : for situations when you want to test different
% compression factors. OMIT unless you know what you are doing.
% filenamestructure should be: EXPID_SAMPLEID_TRIALID_CAMID_DATE_USERID.avi
% CAMID TRIALID USERID DATE are currently ignored

% all output variables are single values except instSpeeds that returns a
% vector with instantaneous speeds during the trial

if ~exist('CAMID', 'var') % CAMID is used when there are more than one camera file
    CAMID = '*';
end

if ~exist('TRIALID', 'var')
    TRIALID = '*';
end

if ~exist('TIMEPOINT', 'var')
    TIMEPOINT = '*';
end

if ~exist('TASKID', 'var')
    TASKID = 'OF';
end

if ~exist('USERID', 'var')
    USERID = '*';
end

if ~exist('VIDEOTYPE', 'var')
    VIDEOTYPE = '.avi';
end


if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end


if ~exist('BORDERLIMIT', 'var')
    BORDERLIMIT = 0.15;
end


if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end

PIXELSIZE = PIXELSIZE * DOWNSAMPLERATIO;


if (isunix)
    separator = '/';
else
    separator = '\';
end

%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, TRIALID, CAMID, USERID, VIDEOTYPE);
if isempty(fileName)
    coordData = [];
    warning('No video loaded');
    return;
end

if iscell(fileName)
    fileName = fileName{1};
end

 [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, centerFraction, instSpeeds] = analyzeSingleOFfile(dataFolder, fileName, PIXELSIZE, MAKEPLOTS,BORDERLIMIT, DOWNSAMPLERATIO );

