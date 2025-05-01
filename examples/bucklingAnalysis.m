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

% Sinh lưới
disp('Đang sinh lưới...');
[nodes, elements] = generateMesh(L, W, nx, ny);

% Lắp ráp ma trận độ cứng vật liệu
disp('Đang lắp ráp ma trận độ cứng vật liệu...');
[K, ~] = assembleSystem(nodes, elements, E, nu, h, 0);

% Lắp ráp ma trận độ cứng hình học
disp('Đang lắp ráp ma trận độ cứng hình học...');
Kg = assembleGeometricStiffness(nodes, elements, Nx);

% Áp dụng điều kiện biên (đỡ đơn toàn bộ biên)
disp('Đang áp dụng điều kiện biên...');
[K_mod, Kg_mod] = applyBucklingBoundaryConditions(K, Kg, nodes, 'SSSS');

% Giải bài toán giá trị riêng
disp('Đang giải bài toán giá trị riêng...');
[V, D] = eigs(K_mod, Kg_mod, 5, 'smallestabs');  % Lấy 5 giá trị riêng nhỏ nhất
lambdas = diag(D);

% Hiển thị hệ số tới hạn
disp('Các hệ số tải tới hạn:');
disp(lambdas);

% Vẽ mode mất ổn định đầu tiên
disp('Vẽ mode mất ổn định đầu tiên...');
plotDeformedShape(nodes, elements, V(:,1), 0.2);
title('Mode mất ổn định thứ nhất');

disp('Đã hoàn thành phân tích!');