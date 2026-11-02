function gapFilledTrajectory = gapFillTrajectory(traj)
% Fill NaN gaps using modified Akima interpolation (makima).
% traj: samples in rows, with 1-3 coordinate columns; units are preserved.
% Frames-in-columns input is transposed; output samples are in rows.
% Missing frames are identified from the first coordinate, assuming all
% coordinates are missing together.
% Internal gaps are interpolated independently in each coordinate using
% piecewise cubic curves with continuous first derivatives. The makima
% method determines slopes from neighboring valid samples.
% Leading and trailing gaps hold the nearest valid position constant.
% Interpolation requires at least two valid samples.
% Intended for short gaps (about 100 ms or less); no gap-duration limit
% is enforced, and longer gaps need separate assessment.

%% validate input arguments:
if size(traj, 2) > size(traj, 1)
    traj = traj.';
end
[nSamples , ~] = size(traj);

if isempty(traj) || nSamples < 3 || all(isnan(traj(:, 1)))
    warning('Trajectory is empty, shorter than three frames, or has no valid samples.');
    gapFilledTrajectory = [];
    return;
end

%% first, find where gaps are.
nansInTraj = isnan(traj(:, 1));

%for each identified gap, interpolate
if (find(nansInTraj))
    nonNanIndices = find(~nansInTraj);
    firstValid = nonNanIndices(1);
    lastValid = nonNanIndices(end);

    gapFilledTrajectory = interp1(nonNanIndices, ...
        traj(~nansInTraj, :), (1:nSamples)', 'makima');

    % Fill leading and trailing gaps with nearest valid positions.
    gapFilledTrajectory(1:firstValid, :) = ...
        repmat(traj(firstValid, :), firstValid, 1);
    gapFilledTrajectory(lastValid:end, :) = ...
        repmat(traj(lastValid, :), nSamples-lastValid+1, 1);
else
    gapFilledTrajectory = traj;
end

end
