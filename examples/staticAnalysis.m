% Example Static Analysis of a Mindlin Plate
% This script demonstrates how to perform static analysis of a rectangular plate

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
q = -1000;    % Uniform load (N/m²)

% Mesh parameters
nx = 10; % Number of elements in x-direction
ny = 10; % Number of elements in y-direction

% Create mesh
disp('Generating mesh...');
[nodes, elements] = generateMesh(L, W, nx, ny);

% Assemble stiffness matrix and load vector
disp('Assembling system...');
[K, F] = assembleSystem(nodes, elements, E, nu, h, q);

% Apply boundary conditions (simply supported on all edges)
disp('Applying boundary conditions...');
[K_mod, F_mod] = applyBoundaryConditions(K, F, nodes);

% Solve the system
disp('Solving system...');
U = K_mod\F_mod;

% Post-process results
disp('Post-processing...');
plotDeformation(nodes, elements, U);

disp('Analysis complete!');