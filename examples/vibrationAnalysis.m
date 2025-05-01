% Example Vibration Analysis of a Mindlin Plate
% This script demonstrates how to perform vibration analysis of a rectangular plate

% Clear workspace and close figures
clear all;
close all;
clc;

% Plate parameters
L = 1.0;  % Length in x-direction (m)
W = 1.0;  % Width in y-direction (m)
h = 0.01; % Thickness (m)
E = 210e9;    % Young's modulus (Pa)
nu = 0.3;     % Poisson's ratio
rho = 7850;   % Density (kg/m³)

% Mesh parameters
nx = 10; % Number of elements in x-direction
ny = 10; % Number of elements in y-direction

% Create mesh
disp('Generating mesh...');
[nodes, elements] = generateMesh(L, W, nx, ny);

% Assemble stiffness matrix
disp('Assembling stiffness matrix...');
[K, ~] = assembleSystem(nodes, elements, E, nu, h, 0);

% Assemble mass matrix
disp('Assembling mass matrix...');
M = assembleMassMatrix(nodes, elements, rho, h);

% Apply boundary conditions (simply supported on all edges)
disp('Applying boundary conditions...');
[K_mod, M_mod] = applyVibrationBoundaryConditions(K, M, nodes);

% Solve eigenvalue problem for natural frequencies
disp('Solving eigenvalue problem...');
[V, D] = eigs(K_mod, M_mod, 5, 'smallestabs');  % Get 5 lowest frequencies
frequencies = sqrt(diag(D))/(2*pi);  % Convert to Hz

% Display natural frequencies
disp('Natural frequencies (Hz):');
disp(frequencies);

% Plot first mode shape
disp('Plotting first mode shape...');
plotDeformation(nodes, elements, V(:,1));
title('First Mode Shape');

disp('Analysis complete!');