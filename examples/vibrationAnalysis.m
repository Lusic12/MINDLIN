% Ví dụ phân tích dao động tự do của tấm Mindlin
% Script này minh họa cách thực hiện phân tích dao động cho tấm chữ nhật

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
rho = 7850;   % Khối lượng riêng (kg/m³)

% Thông số lưới
nx = 10; % Số phần tử theo x
ny = 10; % Số phần tử theo y

% Add progress bar
h = waitbar(0, 'Initializing...', 'Name', 'Vibration Analysis');

try
    % Sinh lưới
    waitbar(0.2, h, 'Generating mesh...');
    [nodes, elements] = generateMesh(L, W, nx, ny);

    % Lắp ráp ma trận độ cứng
    waitbar(0.4, h, 'Assembling stiffness matrix...');
    [K, ~] = assembleSystem(nodes, elements, E, nu, h, 0);

    % Lắp ráp ma trận khối lượng
    waitbar(0.6, h, 'Assembling mass matrix...');
    M = assembleMassMatrix(nodes, elements, rho, h);

    % Áp dụng điều kiện biên
    waitbar(0.8, h, 'Applying boundary conditions...');
    [K_mod, M_mod] = applyVibrationBoundaryConditions(K, M, nodes, 'SSSS');

    % Giải bài toán giá trị riêng
    waitbar(0.9, h, 'Solving eigenvalue problem...');
    [V, D] = eigs(K_mod, M_mod, 5, 'smallestabs');  
    frequencies = sqrt(diag(D))/(2*pi);

    % Enhanced visualization
    waitbar(1, h, 'Creating visualizations...');
    figure('Name', 'Vibration Analysis Results');
    
    % Mode shapes subplot
    for i = 1:min(4,length(frequencies))
        subplot(2,2,i);
        plotDeformedShape(nodes, elements, V(:,i), 0.2);
        title(sprintf('Mode %d: %.2f Hz', i, frequencies(i)));
        colorbar;
    end

    % Save results
    results = struct('nodes', nodes, 'elements', elements, ...
                    'modes', V, 'frequencies', frequencies, ...
                    'parameters', struct('E',E, 'nu',nu, 'h',h, 'rho',rho));
    save('vibration_results.mat', 'results');
    
catch ME
    delete(h);
    errordlg(['Analysis failed: ' ME.message], 'Error');
    rethrow(ME);
end

delete(h);

disp('Đã hoàn thành phân tích!');