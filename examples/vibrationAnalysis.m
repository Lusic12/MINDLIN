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

% Sinh lưới
disp('Đang sinh lưới...');
[nodes, elements] = generateMesh(L, W, nx, ny);

% Lắp ráp ma trận độ cứng
disp('Đang lắp ráp ma trận độ cứng...');
[K, ~] = assembleSystem(nodes, elements, E, nu, h, 0);

% Lắp ráp ma trận khối lượng
disp('Đang lắp ráp ma trận khối lượng...');
M = assembleMassMatrix(nodes, elements, rho, h);

% Áp dụng điều kiện biên (đỡ đơn toàn bộ biên)
disp('Đang áp dụng điều kiện biên...');
[K_mod, M_mod] = applyVibrationBoundaryConditions(K, M, nodes, 'SSSS');

% Giải bài toán giá trị riêng để tìm tần số riêng
disp('Đang giải bài toán giá trị riêng...');
[V, D] = eigs(K_mod, M_mod, 5, 'smallestabs');  % Lấy 5 tần số thấp nhất
frequencies = sqrt(diag(D))/(2*pi);  % Đổi sang Hz

% Hiển thị tần số riêng
disp('Các tần số dao động riêng (Hz):');
disp(frequencies);

% Vẽ mode dao động đầu tiên
disp('Vẽ mode dao động đầu tiên...');
plotDeformedShape(nodes, elements, V(:,1), 0.2);
title('Mode dao động thứ nhất');

disp('Đã hoàn thành phân tích!');