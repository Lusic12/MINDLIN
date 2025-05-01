% Add all project directories to MATLAB path
currentDir = fileparts(mfilename('fullpath'));

% Add source code directories with subdirectories
addpath(genpath(fullfile(currentDir, 'src')));

% Add examples directory
addpath(fullfile(currentDir, 'examples'));

% Display confirmation
fprintf('Mindlin Plate Analysis paths have been set up.\n');
fprintf('Type ''MindlinPlateAnalysisHub'' to start the GUI.\n\n');

% Display available analysis types
fprintf('Available analyses:\n');
fprintf('1. Static Analysis - Compute plate deflection under loads\n');
fprintf('2. Buckling Analysis - Find critical buckling loads\n');
fprintf('3. Free Vibration - Calculate natural frequencies\n\n');

fprintf('Boundary condition options for each edge:\n');
fprintf('- F: Free\n');
fprintf('- S: Simply Supported\n');
fprintf('- C: Clamped\n');