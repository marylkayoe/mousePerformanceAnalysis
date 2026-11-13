function root = repositoryRoot
% Resolve this checkout without depending on pwd or a user-specific path.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
assert(isfolder(fullfile(root,'BEAMCROSS'))&&isfolder(fullfile(root,'assets')), ...
    'bbtail:RepositoryLayout','Expected BEAMCROSS and assets under repository root.');
end
