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

% Sinh lưới ban đầu
[nodes, elements] = generateMesh(L, W, nx, ny);

% Vòng lặp tinh chỉnh lưới thích nghi
for iter = 1:maxRefinements
    fprintf('Lần tinh chỉnh %d\n', iter);
    
    % Lắp ráp hệ có xét đến nhiệt
    [K, F] = assembleSystem(nodes, elements, E, nu, h, q, 'dT', dT, 'alpha', alpha);
    
    % Áp dụng điều kiện biên (đỡ đơn toàn bộ biên)
    [K_mod, F_mod] = applyBoundaryConditions(K, F, nodes, 'SSSS');
    
    % Giải hệ
    U = K_mod\F_mod;
    
    % Tính ứng suất
    [Mx, My, Mxy, Qx, Qy] = computeStresses(nodes, elements, U, E, nu, h);
    
    % Vẽ kết quả hiện tại
    figure(iter);
    
    % Đồ thị chuyển vị
    subplot(2,2,1);
    plotDeformedShape(nodes, elements, U, 0.2);
    title(sprintf('Biến dạng (Lần %d)', iter));
    
    % Đồ thị mô men
    subplot(2,2,2);
    plotResults(nodes, elements, Mx, 1, 4, 'parula', false);
    title('Mô men uốn Mx');
    
    % Đồ thị lực cắt
    subplot(2,2,3);
    plotResults(nodes, elements, Qx, 1, 4, 'parula', false);
    title('Lực cắt Qx');
    
    % Lưới hiện tại
    subplot(2,2,4);
    plotMesh(nodes, elements);
    title(sprintf('Lưới (N = %d)', size(elements,1)));
    
    % Kiểm tra có cần tinh chỉnh tiếp không
    if iter < maxRefinements
        % Tinh chỉnh lưới thích nghi
        [nodes, elements] = adaptiveMesh(nodes, elements, U, E, nu, h, errorTol);
        fprintf('Số phần tử mới: %d\n', size(elements,1));
    end
end

% Hiển thị kết quả cuối cùng
fprintf('\nHoàn thành phân tích\n');
fprintf('Tổng số phần tử cuối: %d\n', size(elements,1));
fprintf('Chuyển vị lớn nhất: %.3e m\n', max(abs(U(1:3:end))));
fprintf('Mô men uốn lớn nhất: %.3e N⋅m/m\n', max(abs(Mx)));
fprintf('Lực cắt lớn nhất: %.3e N/m\n', max(abs(Qx)));

% Lưu kết quả
results = struct('nodes', nodes, 'elements', elements, ...
                'displacement', U, 'Mx', Mx, 'My', My, 'Mxy', Mxy, ...
                'Qx', Qx, 'Qy', Qy);
save('enhanced_analysis_results.mat', 'results');