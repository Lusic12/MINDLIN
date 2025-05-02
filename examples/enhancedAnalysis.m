% Ví dụ phân tích nâng cao tấm Mindlin
% Script này minh họa các tính năng:
% - Tinh chỉnh lưới thích nghi
% - Ảnh hưởng nhiệt
% - Tính toán và trực quan hóa ứng suất

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
alpha = 12e-6; % Hệ số giãn nở nhiệt (1/K)
dT = 100;     % Chênh lệch nhiệt độ (K)

% Thông số lưới ban đầu
nx = 8;  % Số phần tử theo x ban đầu
ny = 8;  % Số phần tử theo y ban đầu

% Thông số tải
q = -1000;    % Áp suất đều (N/m²)

% Tham số tinh chỉnh lưới
maxRefinements = 3;
errorTol = 0.1;

% Add progress tracking
h = waitbar(0, 'Initializing...', 'Name', 'Enhanced Analysis');

try
    % Sinh lưới ban đầu
    waitbar(0.1, h, 'Generating initial mesh...');
    [nodes, elements] = generateMesh(L, W, nx, ny);

    % Vòng lặp tinh chỉnh lưới thích nghi
    for iter = 1:maxRefinements
        waitbar(iter/maxRefinements, h, sprintf('Refinement iteration %d/%d', iter, maxRefinements));
        fprintf('Lần tinh chỉnh %d\n', iter);
        
        % Lắp ráp hệ có xét đến nhiệt
        [K, F] = assembleSystem(nodes, elements, E, nu, h, q, 'dT', dT, 'alpha', alpha);
        
        % Áp dụng điều kiện biên (đỡ đơn toàn bộ biên)
        [K_mod, F_mod] = applyBoundaryConditions(K, F, nodes, 'SSSS');
        
        % Giải hệ
        U = K_mod\F_mod;
        
        % Enhanced visualization with error indicators
        figure('Name', sprintf('Analysis Results - Iteration %d', iter));
        [errorIndicators] = computeErrorIndicators(nodes, elements, U, E, nu, h);
        
        subplot(2,2,1);
        plotDeformedShape(nodes, elements, U, 0.2);
        title('Deformed Shape');
        
        subplot(2,2,2);
        plotErrorDistribution(nodes, elements, errorIndicators);
        title('Error Distribution');
        
        subplot(2,2,3);
        plotStressContours(nodes, elements, U, E, nu, h);
        title('von Mises Stress');
        
        subplot(2,2,4);
        plotMeshQuality(nodes, elements);
        title('Mesh Quality');
        
        % Kiểm tra có cần tinh chỉnh tiếp không
        if max(errorIndicators) < errorTol
            break;
        end
        
        % Tinh chỉnh lưới thích nghi
        [nodes, elements] = adaptiveMesh(nodes, elements, errorIndicators, errorTol);
        fprintf('Số phần tử mới: %d\n', size(elements,1));
    end
    
    % Hiển thị kết quả cuối cùng
    fprintf('\nHoàn thành phân tích\n');
    fprintf('Tổng số phần tử cuối: %d\n', size(elements,1));
    fprintf('Chuyển vị lớn nhất: %.3e m\n', max(abs(U(1:3:end))));
    fprintf('Mô men uốn lớn nhất: %.3e N⋅m/m\n', max(abs(Mx)));
    fprintf('Lực cắt lớn nhất: %.3e N/m\n', max(abs(Qx)));
    
    % Lưu kết quả
    waitbar(1, h, 'Saving results...');
    results = struct('nodes', nodes, 'elements', elements, ...
                    'displacement', U, 'parameters', struct(...
                    'E',E, 'nu',nu, 'h',h, 'dT',dT, 'alpha',alpha));
    save('enhanced_results.mat', 'results');

catch ME
    delete(h);
    errordlg(['Analysis failed: ' ME.message], 'Error');
    rethrow(ME);
end

delete(h);