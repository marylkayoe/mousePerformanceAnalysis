function varargout = getTailMotionTrace(varargin)
% Compatibility entry point; maintained implementation: BEAMCROSS/TAIL/+bbtail/getTailMotionTrace.m
addpath(fullfile(fileparts(mfilename('fullpath')),'../BEAMCROSS/TAIL'));
if nargout
 [varargout{1:nargout}] = bbtail.getTailMotionTrace(varargin{:});
else
 bbtail.getTailMotionTrace(varargin{:});
end
end
