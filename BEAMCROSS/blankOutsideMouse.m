function [blankedVideo, blankMatrix] = blankOutsideMouse(videoMatrix, mouseMaskMatrix, blankVal, minFractionOfFrameHeight)
    % BLANKOUTSIDEMOUSE  Retain only columns with enough mouse pixels, and keep
    %                    only the largest continuous block of columns. All others
    %                    are overwritten with blankVal.
    %
    %   blankedVideo = blankOutsideMouse(videoMatrix, mouseMaskMatrix, blankVal, minFractionOfFrameHeight)
    %
    % INPUTS:
    %   videoMatrix    - 3D grayscale video array (height x width x nFrames).
    %                    e.g. size = (H x W x N)
    %   mouseMaskMatrix- 3D logical array (H x W x N) with 1 where the mouse is.
    %   blankVal       - The pixel value used to fill blanked-out columns 
    %                    (0 or 1 if double, 0 or 255 if uint8, etc.)
    %   minFractionOfFrameHeight - fraction of rows that need to be mouse
    %                              for a column to be considered valid. e.g. 0.05
    %
    % OUTPUT:
    %   blankedVideo   - Same size/type as videoMatrix, but columns outside the 
    %                    largest trunk block are overwritten with blankVal.
    
        [vidHeight, vidWidth, nFrames] = size(videoMatrix);
        
        % Preallocate output (same type as input)
        blankedVideo = zeros(size(videoMatrix), 'like', videoMatrix);
        blankMatrix = zeros(size(videoMatrix), 'like', videoMatrix);
    
        for frameIndex = 1:nFrames
            currentFrame = videoMatrix(:,:,frameIndex);
            currentMask  = mouseMaskMatrix(:,:,frameIndex);
            blankFrame = blankMatrix(:,:,frameIndex);
            
    
            % 1) Count how many mouse pixels in each column
            colSum = sum(currentMask, 1);
            
            % 2) Compare to threshold => columns that pass are considered valid
            colFraction = colSum / vidHeight;
            validCols   = (colFraction >= minFractionOfFrameHeight);
    
            % 3) Keep only the largest continuous run of valid columns
            %    We'll treat validCols as a 1D logical and find its connected components.
            cc = bwconncomp(validCols);  % works on logical arrays, even 1D
            if cc.NumObjects > 0
                % Find the connected component with the maximum size
                compSizes = cellfun(@numel, cc.PixelIdxList);
                [~, largestCompIdx] = max(compSizes);
                
                % Create a blank array, then fill in the largest component
                largestComp = false(size(validCols));
                largestComp(cc.PixelIdxList{largestCompIdx}) = true;
                
                % This new largestComp is our final validCols
                validCols = largestComp;
            else
                % If no valid columns at all, then everything is blank
                validCols = false(size(validCols));
            end
    
            % 4) Overwrite invalid columns with blankVal
            outFrame = currentFrame;
            outFrame(:, ~validCols) = blankVal;
    
            % 5) Store
            blankedVideo(:,:,frameIndex) = outFrame;

            % make the columns that are not blanked
            blankFrame(:, validCols) = 1;
            blankMatrix(:,:,frameIndex) = blankFrame;
        end
    end
    