function resultImageMatrix = extractColorChannel(imageMatrix, colorname)

    % colorname should be a string, either "blue" or "yellow"
    % this function will return a mask of the pixels that are in the specified color range

    % Convert image to HSV
    imageHSV = rgb2hsv(imageMatrix);

    % Define color range
    if strcmp(colorname, 'blue')
        colorHue = [0.5, 0.7];
        colorSaturation = [0.5, 1];
        colorValue = [0.2, 1];
    elseif strcmp(colorname, 'yellow')
        colorHue = [0.1, 0.35];
        colorSaturation = [0.2, 1];
        colorValue = [0.4, 0.9];
    else
        error('Color name not recognized');
    end 

    % Define mask for color
    mask = (imageHSV(:, :, 1) >= colorHue(1)) & (imageHSV(:, :, 1) <= colorHue(2)) & ...
        (imageHSV(:, :, 2) >= colorSaturation(1)) & (imageHSV(:, :, 2) <= colorSaturation(2)) & ...
        (imageHSV(:, :, 3) >= colorValue(1)) & (imageHSV(:, :, 3) <= colorValue(2));

    resultImageMatrix = mask;
end
