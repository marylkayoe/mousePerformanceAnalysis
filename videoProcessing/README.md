# Video processing-related functions in the Mouse Performance Analysis toolbox
This folder contains functions that are used to process video files in the Mouse Performance Analysis toolbox. 

## Functions
- **convertAviToMP4**: Converts an AVI video file to an MP4 video file using FFmpeg. Optional arguments relate to scaling and cropping the video.
- **saveVideoMatrixMP4**: Saves a video matrix as an MP4 video file using FFmpeg. 
- **readVideoIntoMatrix**: Reads a video file into a 3D matrix. If the video is RGB, it is converted to grayscale. Optional arguments relate to scaling the video and removing blue elements (glove) from the video and replacing them with white.
- **removeBlueGloveFromFrame**: Removes blue elements (glove) from a frame and replaces them with white (default, works if the mouse is black)
- **findCropRectangle**: Finds the coordinates of a brightly colored rectangle (e.g. made by masking tape) in a frame. This is used to crop the video to the region of interest.
- **extractColorChannel**: Extracts a color channel from an RGB image. So far only "blue" for the blue glove and "yellow-ish" for the yellow tape are implemented; feel free to implement more as needed. Returns a binary mask of the specified color.
  