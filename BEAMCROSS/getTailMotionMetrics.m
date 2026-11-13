function varargout = getTailMotionMetrics(varargin)
% Compatibility entry point; maintained implementation: BEAMCROSS/TAIL/+bbtail/getTailMotionMetrics.m
addpath(fullfile(fileparts(mfilename('fullpath')),'../BEAMCROSS/TAIL'));
if nargout
 [varargout{1:nargout}] = bbtail.getTailMotionMetrics(varargin{:});
else
 bbtail.getTailMotionMetrics(varargin{:});
end
end
