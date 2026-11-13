function exportSelectedGroupMovieColumns
r=jsondecode(fileread('BEAMCROSS/DRAFTFIGS/slip-movie-example-review/selected_group_movies.json'));
b='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_D0_slip_example_review_20261112/group_presentations';
if ~isfolder(b),mkdir(b);end
addpath('BEAMCROSS');
for i=1:numel(r)
 out=fullfile(b,[r(i).group '_' r(i).day '_inputs']);
 fprintf('Preparing %s\n',r(i).file);exportUnderbarMotionColumns(r(i).file,out);
end
end
