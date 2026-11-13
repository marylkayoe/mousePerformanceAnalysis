function varargout = extract_tail_height(varargin)
% Compatibility entry point; maintained implementation: BEAMCROSS/TAIL/+bbtail/extractTailHeight.m
addpath(fullfile(fileparts(mfilename('fullpath')),'../../../../BEAMCROSS/TAIL'));
if nargout
 [varargout{1:nargout}] = bbtail.extractTailHeight(varargin{:});
else
 bbtail.extractTailHeight(varargin{:});
end
end
