function newFrame = removeBlueGloveFromFrame(frame, varargin)
    % Remove blue glove from frame
    % Should be called within the readVideoIntoMatrix function
    % Output: returns the frame without the blue glove
    % parameters:
    % frame: image, RGB (acquired with readFrame)
    % varargin: optional parameters
    % 'replaceWith' - 'black', 'white' or 'transparent' (default: 'black')
    % 'fillImage' - grayscale image from which pixels are taken to fill the glove area
    % Parse optional parameters

    p = inputParser;
    addParameter(p, 'replaceWith', 'black', @(x) ischar(x) && (strcmp(x, 'black') || strcmp(x, 'white')));
    addParameter(p, 'fillImage', [], @(x) isnumeric(x) && size(x, 3) == 1);
    
    parse(p, varargin{:});

    % Extract parameters
    replaceWith = p.Results.replaceWith;
    fillImage = p.Results.fillImage;

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
switch replaceWith
    case 'black'
        newFrame(repmat(mask, [1, 1, 3])) = 0;
    case 'white'
        newFrame(repmat(mask, [1, 1, 3])) = 255;
        case 'transparent'
            % we copy the pixels from the fillImage to all color channels of the frame
            newFrame(repmat(mask, [1, 1, 3])) = fillImage(repmat(mask, [1, 1, 3]));
end


    if strcmp(replaceWith, 'black')
        newFrame(repmat(mask, [1, 1, 3])) = 0;
    else
        newFrame(repmat(mask, [1, 1, 3])) = 255;
    end
end





