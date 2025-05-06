function annotatedVideo = annotateVideoMatrix(videoMatrix, eventStarts1, eventDurations1, varargin)
    % ANNOTATEVIDEOMATRIX overlays shapes and labels for two event types on video frames.

    % Input parser setup
    p = inputParser;
    p.FunctionName = mfilename;

    % Required arguments
    addRequired(p, 'videoMatrix', @(x) isnumeric(x) && ndims(x)==3);
    addRequired(p, 'eventStarts1', @isnumeric);
    addRequired(p, 'eventDurations1', @isnumeric);

    % Optional parameters (event type 1)
    addParameter(p, 'ShapeType',    'filled-rectangle',  @ischar);
    addParameter(p, 'ShapePosition',[20 10 20 10],@isnumeric);
    addParameter(p, 'ShapeColor',   'red');
    addParameter(p, 'LineWidth',    3, @isnumeric);
    addParameter(p, 'Opacity',      1, @isnumeric);
    addParameter(p, 'EventLabel1',  'EVENT1', @ischar);

    % Optional parameters for second event type
    addParameter(p, 'EventStarts2', [], @isnumeric);
    addParameter(p, 'EventDurations2', [], @isnumeric);
    addParameter(p, 'ShapePosition2', [50 10 20 10], @isnumeric);
    addParameter(p, 'ShapeColor2', 'blue');
    addParameter(p, 'EventLabel2',  'EVENT2', @ischar);

    % Parse input arguments
    parse(p, videoMatrix, eventStarts1, eventDurations1, varargin{:});

    % Extract parameters
    shapeType1     = p.Results.ShapeType;
    shapePosition1 = p.Results.ShapePosition;
    shapeColor1    = p.Results.ShapeColor;
    lineWidth      = p.Results.LineWidth;
    opacity        = p.Results.Opacity;
    eventLabel1    = p.Results.EventLabel1;

    % Second event parameters
    eventStarts2     = p.Results.EventStarts2;
    eventDurations2  = p.Results.EventDurations2;
    shapePosition2   = p.Results.ShapePosition2;
    shapeColor2      = p.Results.ShapeColor2;
    eventLabel2      = p.Results.EventLabel2;

    % Dimensions
    [H, W, nFrames] = size(videoMatrix);
    annotatedVideo = zeros(H, W, 3, nFrames, 'like', videoMatrix);

    % Create event masks
    eventMask1 = false(1, nFrames);
    for i = 1:numel(eventStarts1)
        idxRange = eventStarts1(i):min(eventStarts1(i)+eventDurations1(i)-1, nFrames);
        eventMask1(idxRange) = true;
    end

    eventMask2 = false(1, nFrames);
    if ~isempty(eventStarts2)
        for i = 1:numel(eventStarts2)
            idxRange = eventStarts2(i):min(eventStarts2(i)+eventDurations2(i)-1, nFrames);
            eventMask2(idxRange) = true;
        end
    end

    % Calculate label positions (just below shapes)
    labelOffsetY = 5; % pixels below shape
    labelPos1 = [shapePosition1(1), shapePosition1(2)+shapePosition1(4)+labelOffsetY];
    labelPos2 = [shapePosition2(1), shapePosition2(2)+shapePosition2(4)+labelOffsetY];

    % Loop frames and draw shapes & labels
    for f = 1:nFrames
        % Grayscale to RGB
        rgbFrame = repmat(videoMatrix(:,:,f), [1,1,3]);

        % Overlay event 1 shape & label
        if eventMask1(f)
            rgbFrame = insertShape(rgbFrame, shapeType1, shapePosition1, ...
                'Color', shapeColor1, 'LineWidth', lineWidth, 'Opacity', opacity);

            if ~isempty(eventLabel1)
                rgbFrame = insertText(rgbFrame, labelPos1, eventLabel1, ...
                    'FontSize',12,  'TextColor',shapeColor1);
            end
        end

        % Overlay event 2 shape & label
        if eventMask2(f)
            rgbFrame = insertShape(rgbFrame, shapeType1, shapePosition2, ...
                'Color', shapeColor2, 'LineWidth', lineWidth, 'Opacity', opacity);

            if ~isempty(eventLabel2)
                rgbFrame = insertText(rgbFrame, labelPos2, eventLabel2, ...
                    'FontSize',12, 'BoxColor','black', 'TextColor',shapeColor2, 'BoxOpacity',0.6);
            end
        end

        % Store frame
        annotatedVideo(:,:,:,f) = rgbFrame;
    end
end
