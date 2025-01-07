function annotatedVideo = annotateVideoMatrix(videoMatrix, eventStarts, eventDurations, varargin)
    % ANNOTATEVIDEOMATRIX  Overlays a shape in frames where events occur.
    %   Creates an RGB video from a grayscale input, drawing shapes on frames
    %   for each specified event interval.
    %
    % SYNTAX:
    %   annotatedVideo = annotateVideoMatrix(...
    %       videoMatrix, eventStarts, eventDurations, ...
    %       'Name', value, ... );
    %
    % REQUIRED INPUTS:
    %   videoMatrix   : (H x W x nFrames) grayscale array
    %   eventStarts   : vector of frame indices where events begin
    %   eventDurations: vector, same length as eventStarts, how many frames each event lasts
    %
    % OPTIONAL PARAMETERS (Name-Value pairs):
    %   'ShapeType'    : (char) 'Rectangle', 'FilledRectangle', 'Circle', etc.
    %                    Default = 'Rectangle'
    %   'ShapePosition': (1x4 or 1x3 numeric) e.g. [x y width height] for rectangle
    %                    Default = [20 20  50 30]
    %   'ShapeColor'   : (char or 1x3 numeric) e.g. 'red' or [255 0 0]
    %                    Default = 'red'
    %   'LineWidth'    : (scalar) thickness of the outline (if not filled)
    %                    Default = 3
    %   'Opacity'      : (0..1) how opaque the shape is
    %                    Default = 1 (fully opaque)
    %
    % OUTPUT:
    %   annotatedVideo : (H x W x 3 x nFrames) RGB annotated video
    %
    % EXAMPLE:
    %   videoMatrix = rand(240,320,100,'single');  % dummy grayscale
    %   eventStarts = [10, 30, 70];
    %   eventDurations = [5, 10, 8];
    %
    %   annotatedVid = annotateVideoMatrix(...
    %       videoMatrix, eventStarts, eventDurations, ...
    %       'ShapeType','FilledRectangle',...
    %       'ShapePosition',[50,50,40,40],...
    %       'ShapeColor','cyan',...
    %       'LineWidth',4,...
    %       'Opacity',0.7);
    %
    %   implay(annotatedVid);
    
        %------------- Set up inputParser -------------
        p = inputParser;
        p.FunctionName = mfilename;
    
        % Required arguments
        addRequired(p, 'videoMatrix', ...
            @(x) ( isnumeric(x) && ndims(x)==3 ) );
        addRequired(p, 'eventStarts', @isnumeric);
        addRequired(p, 'eventDurations', @isnumeric);
    
        % Optional parameter-value pairs
        addParameter(p, 'ShapeType',    'filled-rectangle',  @ischar);
        addParameter(p, 'ShapePosition',[20 20  50 30],@isnumeric);
        addParameter(p, 'ShapeColor',   'red'); % could be char or numeric
        addParameter(p, 'LineWidth',    3,       @isnumeric);
        addParameter(p, 'Opacity',      1,       @isnumeric);
    
        % Parse
        parse(p, videoMatrix, eventStarts, eventDurations, varargin{:});
    
        % Extract parsed results (for readability)
        shapeType     = p.Results.ShapeType;
        shapePosition = p.Results.ShapePosition;
        shapeColor    = p.Results.ShapeColor;
        lineWidth     = p.Results.LineWidth;
        opacity       = p.Results.Opacity;
    
        % Validate that eventStarts & eventDurations match in length
        if numel(eventStarts) ~= numel(eventDurations)
            error('eventStarts and eventDurations must have the same length.');
        end
    
        %------------- Main Logic -------------
        [H, W, nFrames] = size(videoMatrix);
    
        % Output is an RGB video
        annotatedVideo = zeros(H, W, 3, nFrames, 'like', videoMatrix);
    
        % We'll mark frames in which events occur
        eventMask = false(1, nFrames);  % 1D for nFrames
    
        for i = 1:numel(eventStarts)
            startF = eventStarts(i);
            endF   = startF + eventDurations(i) - 1; 
            endF   = min(endF, nFrames);  % clamp if beyond last frame
            if startF <= nFrames
                eventMask(startF : endF) = true;
            end
        end
    
        % Loop over frames
        for f = 1:nFrames
            % Extract grayscale frame
            grayFrame = videoMatrix(:,:,f);
    
            % Convert to RGB
            rgbFrame = repmat(grayFrame, [1,1,3]);
    
            % If this frame is in an event, overlay shape
            if eventMask(f)
                rgbFrame = insertShape(rgbFrame, shapeType, shapePosition, ...
                    'Color',     shapeColor, ...
                    'LineWidth', lineWidth, ...
                    'Opacity',   opacity );
            end
    
            % Store in output
            annotatedVideo(:,:,:,f) = rgbFrame;
        end
    
    end
    