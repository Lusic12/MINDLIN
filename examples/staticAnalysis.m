% Ví dụ phân tích tĩnh tấm Mindlin với các tính năng nâng cao
% Script này minh họa phân tích tĩnh, đánh giá chất lượng lưới,
% tinh chỉnh lưới thích nghi và trực quan hóa kết quả

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
q = -1000;    % Tải phân bố đều (N/m²)

% Thông số lưới
nx = 10; % Số phần tử ban đầu theo x
ny = 10; % Số phần tử ban đầu theo y

% Điều kiện biên (S = Đỡ đơn, C = Ngàm, F = Tự do)
bcString = 'SSSS'; % Đỡ đơn toàn bộ biên

% Tham số lưới thích nghi
useAdaptive = true;
errorTol = 0.1;
maxRefinements = 3;

% Sinh lưới ban đầu
fprintf('Đang sinh lưới ban đầu...\n');
[nodes, elements] = generateMesh(L, W, nx, ny);

% Hiển thị chất lượng lưới ban đầu
figure('Name', 'Chất lượng lưới ban đầu');
plotMeshWithQuality(nodes, elements);
title('Đánh giá chất lượng lưới ban đầu');

% Vòng lặp phân tích thích nghi
for iter = 1:maxRefinements
    fprintf('\nLần tinh chỉnh lưới %d\n', iter);
    
    % Lắp ráp hệ phương trình
    fprintf('Đang lắp ráp hệ phương trình...\n');
    [K, F] = assembleSystem(nodes, elements, E, nu, h, q);
    
    % Áp dụng điều kiện biên
    fprintf('Đang áp dụng điều kiện biên...\n');
    [K_mod, F_mod] = applyBoundaryConditions(K, F, nodes, bcString);
    
    % Giải hệ phương trình
    fprintf('Đang giải hệ...\n');
    U = K_mod\F_mod;
    
    % Vẽ kết quả hiện tại
    figure('Name', sprintf('Kết quả phân tích - Lần %d', iter));
    
    % Hình dạng biến dạng
    subplot(2,2,1);
    plotDeformedShape(nodes, elements, U, 0.2);
    title('Hình dạng biến dạng');
    
    % Tính và vẽ ứng suất
    [Mx, My, Mxy, Qx, Qy] = computeStresses(nodes, elements, U, E, nu, h);
    
    subplot(2,2,2);
    plotResults(nodes, elements, Mx, 1, 4, 'jet', false);
    title('Mô men uốn Mx');
    
    subplot(2,2,3);
    plotResults(nodes, elements, Qx, 1, 4, 'jet', false);
    title('Lực cắt Qx');
    
    subplot(2,2,4);
    plotMesh(nodes, elements);
    title('Lưới hiện tại');
    
    % Kiểm tra có cần tinh chỉnh lưới không
    if useAdaptive && iter < maxRefinements
        fprintf('Đang tinh chỉnh lưới thích nghi...\n');
        [nodes_new, elements_new] = adaptiveMesh(nodes, elements, U, E, nu, h, errorTol, ...
            @(progress) fprintf('Tiến độ tinh chỉnh: %.0f%%\n', progress*100));
        
        % Nếu lưới không thay đổi thì dừng
        if size(nodes_new,1) == size(nodes,1)
            fprintf('Lưới đã hội tụ\n');
            break;
        end
        
        nodes = nodes_new;
        elements = elements_new;
        fprintf('Số phần tử mới: %d\n', size(elements,1));
    end
end

% Tính và hiển thị ứng suất cuối cùng
[Mx, My, Mxy, Qx, Qy] = computeStresses(nodes, elements, U, E, nu, h);

% Vẽ kết quả cuối cùng
figure('Name', 'Kết quả phân tích cuối cùng');
subplot(2,2,1);
plotDeformedShape(nodes, elements, U, 0.2);
title('Hình dạng biến dạng');

subplot(2,2,2);
plotResults(nodes, elements, Mx, 1, 4, 'jet', false);
title('Mô men uốn Mx');

subplot(2,2,3);
plotResults(nodes, elements, Qx, 1, 4, 'jet', false);
title('Lực cắt Qx');

subplot(2,2,4);
plotMeshWithQuality(nodes, elements);
title('Chất lượng lưới cuối cùng');

% Hiển thị kết quả số
fprintf('\nHoàn thành phân tích\n');
fprintf('Tổng số phần tử cuối: %d\n', size(elements,1));
fprintf('Chuyển vị lớn nhất: %.3e m\n', max(abs(U(1:3:end))));
fprintf('Mô men uốn lớn nhất: %.3e N⋅m/m\n', max(abs(Mx)));
fprintf('Lực cắt lớn nhất: %.3e N/m\n', max(abs(Qx)));

% Lưu kết quả
results = struct('nodes', nodes, 'elements', elements, ...
                'displacement', U, 'Mx', Mx, 'My', My, 'Mxy', Mxy, ...
                'Qx', Qx, 'Qy', Qy, 'parameters', struct(...
                'E', E, 'nu', nu, 'h', h, 'q', q, ...
                'L', L, 'W', W, 'bcString', bcString));
            
save('static_analysis_results.mat', 'results');
fprintf('\nĐã lưu kết quả vào static_analysis_results.mat\n');