function newFrame = removeBlueGloveFromFrame(frame, varargin)
    % Remove blue glove from frame
    % Should be called within the readVideoIntoMatrix function
    % Output: returns the frame without the blue glove
    % parameters:
    % frame: image, RGB (acquired with readFrame)
    % varargin: optional parameters
    % 'replaceWith' - 'black' or 'white' (default: 'black')
    % Parse optional parameters

    p = inputParser;
    addParameter(p, 'replaceWith', 'black', @(x) ischar(x) && (strcmp(x, 'black') || strcmp(x, 'white')));
    
    parse(p, varargin{:});

    % Extract parameters
    replaceWith = p.Results.replaceWith;

    newFrame = frame;

    % Convert frame to HSV
    frameHSV = rgb2hsv(frame);

    % Define blue glove color range
    blueGloveHue = [0.5, 0.7];
    blueGloveSaturation = [0.5, 1];
    blueGloveValue = [0.2, 1];

    % Define mask for blue glove
    mask = (frameHSV(:, :, 1) >= blueGloveHue(1)) & (frameHSV(:, :, 1) <= blueGloveHue(2)) & ...
        (frameHSV(:, :, 2) >= blueGloveSaturation(1)) & (frameHSV(:, :, 2) <= blueGloveSaturation(2)) & ...
        (frameHSV(:, :, 3) >= blueGloveValue(1)) & (frameHSV(:, :, 3) <= blueGloveValue(2));

    % adjust the mask shape by removing holes 
    mask = imfill(mask, 'holes');
    % grow the mask to smooth the edges
    mask = imdilate(mask, strel('disk', 5));
        
    % make the pixels matching the glove mask 0 in the RGB image
    if strcmp(replaceWith, 'black')
        newFrame(repmat(mask, [1, 1, 3])) = 0;
    else
        newFrame(repmat(mask, [1, 1, 3])) = 255;
    end
end





