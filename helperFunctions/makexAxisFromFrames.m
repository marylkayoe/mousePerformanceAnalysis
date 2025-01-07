function xAx = makexAxisFromFrames(nSamples, FRAMERATE)

xAx = linspace(0, floor(nSamples/FRAMERATE), nSamples);