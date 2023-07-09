function gapFilledTrajectory = gapFillTrajectory(traj)
    % Fill gaps (segments of nans) in a trajectory with a simple interpolation
    % works acceptably if the gaps are not longer than 100 ms
    % for more advanced gapfilling, other methods need to be used


    % input argument traj is a matrix with 1d, 2d or 3d coordinates
    % samples are expected to be in rows.

    %% validate input arguments:
    [nSamples nDIMS] = size(traj);

    if ((isempty(traj)) || (nSamples < nDIMS) || all(isnan(traj(:, 1))))
        disp('Please arrange trajectory matrix with samples in rows');
        gapFilledTrajectory = [];
        return;
    end

    %% first, find where gaps are.
    nansInTraj = isnan(traj(:, 1));

    if (find(nansInTraj))
        nonNansInTraj = ~nansInTraj;
        nonNanIndices = find(nonNansInTraj);
        % find first and last non-nan values so we can later clean up the tails
        firstNonNanVal = find(nonNansInTraj, 1, 'first');
        lastNonNanVal = find(nonNansInTraj, 1, 'last');

        % gapfill each dimension independently. More accurate way would be to do in 2 or 3d but for small gaps this is good enough
        for dimension = 1:nDIMS
            gapFilledTrajectory(:, dimension) = interp1(nonNanIndices, traj(nonNansInTraj, dimension), (1:length(traj))', 'makima');
        end

        % removing weird ends due to attempts at interpolating nans:
        %fill empty end and beginning with  constant values
        gfFirstPad = repmat(gapFilledTrajectory(firstNonNanVal, :), firstNonNanVal, 1);
        gapFilledTrajectory(1:firstNonNanVal, :) = gfFirstPad;
        gfLastPad = repmat(gapFilledTrajectory(lastNonNanVal, :), nSamples - lastNonNanVal + 1, 1);
        gapFilledTrajectory(lastNonNanVal:end, :) = gfLastPad;
    else
        gapFilledTrajectory = traj;
    end

end
