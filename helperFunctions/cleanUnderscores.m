function R = cleanUnderscores(inputString)
    % replaces underscores with hyphens so the latex interpreter doesn't
    % interpret them as subscripts

    R = strrep(inputString, '_', '-');

end