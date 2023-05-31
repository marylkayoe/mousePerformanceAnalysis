function xAx = makexAxisFromFrames(nSamples, FRAMERATE)

xAx = linspace(1, floor(nSamples/FRAMERATE), nSamples);