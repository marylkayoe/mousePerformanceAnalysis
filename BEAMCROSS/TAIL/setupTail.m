function setupTail
% Add only the package parent; do not recursively add historical scripts.
addpath(fileparts(mfilename('fullpath')));
fprintf('Tail-motion package ready: %s\n',bbtail.repositoryRoot());
end
