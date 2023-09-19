function CAMID = getCAMIDfromFilename(fileName)
    CAMIDPOS = strfind(fileName, 'Cam');
    CAMID = fileName(CAMIDPOS:CAMIDPOS+3);
    