% Ví dụ phân tích ổn định (buckling) tấm Mindlin
% Script này minh họa cách thực hiện phân tích ổn định cho tấm chữ nhật

% Xóa workspace và đóng các cửa sổ hình
clear all;
close all;
clc;

% Thông số tấm
L = 1.0;  % Chiều dài theo phương x (m)
W = 1.0;  % Chiều rộng theo phương y (m)
h = 0.01; % Chiều dày (m)
E = 210e9;    % Mô đun Young (Pa)
nu = 0.3;     % Hệ số Poisson
Nx = -1000;   % Lực nén theo phương x (N/m)

% Thông số lưới
nx = 10; % Số phần tử theo x
ny = 10; % Số phần tử theo y

% Add progress bar
h = waitbar(0, 'Initializing...', 'Name', 'Buckling Analysis');

try
    % Sinh lưới
    waitbar(0.2, h, 'Generating mesh...');
    [nodes, elements] = generateMesh(L, W, nx, ny);

    % Lắp ráp ma trận
    waitbar(0.4, h, 'Assembling material stiffness...');
    [K, ~] = assembleSystem(nodes, elements, E, nu, h, 0);

    waitbar(0.6, h, 'Assembling geometric stiffness...');
    Kg = assembleGeometricStiffness(nodes, elements, Nx);

    % Áp dụng điều kiện biên
    waitbar(0.8, h, 'Applying boundary conditions...');
    [K_mod, Kg_mod] = applyBucklingBoundaryConditions(K, Kg, nodes, 'SSSS');

    % Giải bài toán
    waitbar(0.9, h, 'Solving eigenvalue problem...');
    [V, D] = eigs(K_mod, Kg_mod, 5, 'smallestabs');
    lambdas = diag(D);

    % Enhanced visualization
    waitbar(1, h, 'Creating visualizations...');
    figure('Name', 'Buckling Analysis Results');
    
    % Plot multiple buckling modes
    for i = 1:min(4,length(lambdas))
        subplot(2,2,i);
        plotDeformedShape(nodes, elements, V(:,i), 0.2);
        title(sprintf('Mode %d: λ = %.2f', i, lambdas(i)));
        colorbar;
    end

    % Save results
    results = struct('nodes', nodes, 'elements', elements, ...
                    'modes', V, 'lambdas', lambdas, ...
                    'parameters', struct('E',E, 'nu',nu, 'h',h, 'Nx',Nx));
    save('buckling_results.mat', 'results');

catch ME
    delete(h);
    errordlg(['Analysis failed: ' ME.message], 'Error');
    rethrow(ME);
end

delete(h);

disp('Đã hoàn thành phân tích!');