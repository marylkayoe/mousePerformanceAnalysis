function uniqueToolboxDependencies = getProjectDependencies()
project = currentProject;
projectFiles = project.Files;
allToolboxDependencies = {};

for i = 1:numel(projectFiles)
    if ~isempty(projectFiles(i).Labels)
        fullFilePath = projectFiles(i).Labels.File;
        if strfind(fullFilePath, '.m')
            if exist(fullFilePath, 'file') == 2
                [~, products] = matlab.codetools.requiredFilesAndProducts(fullFilePath);
                if ~isempty(products)
                    allToolboxDependencies = [allToolboxDependencies, {products.Name}];
                end
            end
        end
    end
end

% Get unique toolbox dependencies
uniqueToolboxDependencies = unique(allToolboxDependencies);
end
