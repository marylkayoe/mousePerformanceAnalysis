function [normMouseProbVals, mouseProbMatrix] = computeMouseProbabilityMap(mouseMaskMatrix)
    % GETMOUSEPROBONBEAM  Compute how much of each column is occupied by the mouse,
    %   expressed as a fraction of the frame height (a "probability" of the mouse
    %   being present in that column).
    %
    %   [normMouseProbVals, mouseProbMatrix] = getMouseProbOnBeam(mouseMaskMatrix)
    %
    %   INPUT:
    %     mouseMaskMatrix : 3D logical array of size (H x W x N), where
    %                       mouseMaskMatrix(r,c,f) = 1 if pixel(r,c) is mouse
    %                       in frame f, and 0 otherwise.
    %
    %   OUTPUTS:
    %     normMouseProbVals : A 2D numeric array of size (W x N). For each frame f,
    %                         normMouseProbVals(:, f) holds the fraction (0..1)
    %                         of mouse pixels in each column.
    %     mouseProbMatrix   : A 3D numeric array (H x W x N) where each slice f
    %                         is a "probability image": every pixel in column c
    %                         has the fraction of mouse pixels in that column.
    %                         In other words, mouseProbMatrix(r,c,f) = fraction
    %                         of row‐pixels that are mouse in col c of frame f.
    %
    %   EXAMPLE USAGE:
    %     [columnProb, probImages] = getMouseProbOnBeam(myMouseMask);
    %     imshow(probImages(:,:,10), [])  % show the "probability" for frame #10
    %
    %   NOTES:
    %     - If a column c has x mouse pixels out of H total rows, its fraction
    %       is x/H.  That fraction is placed into normMouseProbVals(c,f), and
    %       repeated in every row of probImages(:,:,f).
    %     - This is *not* a strict probability in a Bayesian sense, but rather
    %       “what fraction of the column is mouse?” 
    %
    %   Author: (Your Name / Lab)
    
        [imHeight, imWidth, nFrames] = size(mouseMaskMatrix);
    
        % Pre‐allocate outputs
        normMouseProbVals = zeros(imWidth, nFrames);       % (W x N)
        mouseProbMatrix   = zeros(imHeight, imWidth, nFrames);
    
        for f = 1 : nFrames
            % 1) Extract the mask for frame f
            maskFrame = mouseMaskMatrix(:,:,f);
    
            % 2) Sum mouse‐pixels along rows => how many pixels = 1 per column
            colSum = sum(maskFrame, 1);  % size: [1 x imWidth]
    
            % 3) Convert to fraction of total rows in that column
            colFraction = colSum / imHeight;  % still size: [1 x imWidth]
    
            % Store in normMouseProbVals (make it a column vector in row dimension)
            normMouseProbVals(:, f) = colFraction(:);
    
            % 4) Create a "probability image" slice:
            %    replicate colFraction along rows so each column c has the same value in all rows
            %    i.e., if colFraction(c)=0.3, that entire column c is 0.3 from row=1 to row=H
            probFrame = repmat(colFraction, imHeight, 1);
    
            % 5) Put this 2D probFrame into our output 3D array
            mouseProbMatrix(:,:,f) = probFrame;
        end
    end
    