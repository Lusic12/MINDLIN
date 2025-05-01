function [Ke] = elementStiffness(nodeCoordinates, C_shear, C_bending, thickness)
% Tính ma trận độ cứng phần tử tấm Mindlin Q4
% Đầu vào:
%   nodeCoordinates - Tọa độ nút của phần tử [node_id, x, y]
%   C_shear        - Ma trận độ cứng cắt
%   C_bending      - Ma trận độ cứng uốn
%   thickness      - Chiều dày tấm

try
    % Kiểm tra đầu vào
    validateInputs(nodeCoordinates, C_shear, C_bending, thickness);

    % Số nút của phần tử
    numberNodes = size(nodeCoordinates, 1);
    
    % Khởi tạo ma trận độ cứng phần tử
    Ke = zeros(3*numberNodes, 3*numberNodes);

    % Tích phân Gauss cho phần uốn (đầy đủ)
    [gaussWeights1, gaussLocations1] = gaussQuadrature('complete');

    % Tích phân cho phần uốn
    for q = 1:size(gaussWeights1,1)
        GaussPoint = gaussLocations1(q,:);
        xi = GaussPoint(1);
        eta = GaussPoint(2);

        % Hàm dạng và đạo hàm
        [shapeFunction, naturalDerivatives] = shapeFunctionQ4(xi, eta);

        % Ma trận Jacobi và đạo hàm
        [Jacob, invJacobian, XYderivatives] = ...
            Jacobian(nodeCoordinates, naturalDerivatives);

        % Ma trận B cho uốn (từ code gốc)
        B_b = zeros(3, 3*numberNodes);
        B_b(1,numberNodes+1:2*numberNodes) = XYderivatives(:,1)';
        B_b(2,2*numberNodes+1:3*numberNodes) = XYderivatives(:,2)';
        B_b(3,numberNodes+1:2*numberNodes) = XYderivatives(:,2)';
        B_b(3,2*numberNodes+1:3*numberNodes) = XYderivatives(:,1)';

        % Cập nhật ma trận độ cứng uốn
        Ke = Ke + B_b'*C_bending*B_b*gaussWeights1(q)*det(Jacob);
    end

    % Tích phân Gauss cho phần cắt (suy giảm)
    [gaussWeights2, gaussLocations2] = gaussQuadrature('reduced');

    % Tích phân cho phần cắt
    for q = 1:size(gaussWeights2,1)
        GaussPoint = gaussLocations2(q,:);
        xi = GaussPoint(1);
        eta = GaussPoint(2);

        % Hàm dạng và đạo hàm
        [shapeFunction, naturalDerivatives] = shapeFunctionQ4(xi, eta);

        % Ma trận Jacobi và đạo hàm
        [Jacob, invJacobian, XYderivatives] = ...
            Jacobian(nodeCoordinates, naturalDerivatives);

        % Ma trận B cho cắt (từ code gốc)
        B_s = zeros(2, 3*numberNodes);
        B_s(1,1:numberNodes) = XYderivatives(:,1)';
        B_s(2,1:numberNodes) = XYderivatives(:,2)';
        B_s(1,numberNodes+1:2*numberNodes) = shapeFunction';
        B_s(2,2*numberNodes+1:3*numberNodes) = shapeFunction';

        % Cập nhật ma trận độ cứng cắt
        Ke = Ke + B_s'*C_shear*B_s*gaussWeights2(q)*det(Jacob);
    end

    % Kiểm tra tính chất của ma trận độ cứng phần tử
    validateElementStiffness(Ke);

catch ME
    error('Lỗi trong tính toán ma trận độ cứng phần tử: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra đầu vào
function validateInputs(nodeCoordinates, C_shear, C_bending, thickness)
    % Kiểm tra kích thước ma trận tọa độ nút
    if size(nodeCoordinates,2) ~= 3
        error('Ma trận tọa độ nút phải có 3 cột [node_id, x, y]');
    end
    
    % Kiểm tra kích thước ma trận độ cứng cắt
    if ~all(size(C_shear) == [2,2])
        error('Ma trận độ cứng cắt phải có kích thước 2x2');
    end
    
    % Kiểm tra kích thước ma trận độ cứng uốn
    if ~all(size(C_bending) == [3,3])
        error('Ma trận độ cứng uốn phải có kích thước 3x3');
    end
    
    % Kiểm tra chiều dày
    if thickness <= 0
        error('Chiều dày tấm phải dương');
    end
    
    % Kiểm tra tính xác định dương của ma trận độ cứng
    if any(eig(C_shear) <= 0) || any(eig(C_bending) <= 0)
        warning('Ma trận độ cứng vật liệu có thể không xác định dương');
    end
end

%................................................................
% Hàm kiểm tra ma trận độ cứng phần tử
function validateElementStiffness(Ke)
    % Kiểm tra tính đối xứng
    if norm(Ke - Ke', 1) / (norm(Ke, 1) + eps) > 1e-10
        warning('Ma trận độ cứng phần tử không đối xứng');
    end
    
    % Kiểm tra tính xác định không âm
    if any(eig(Ke) < -eps)
        warning('Ma trận độ cứng phần tử có thể không xác định không âm');
    end
    
    % Kiểm tra điều kiện số
    if cond(Ke) > 1e8
        warning('Điều kiện số của ma trận độ cứng phần tử lớn');
    end
    
    % Kiểm tra cân bằng tĩnh (tổng các hàng/cột phải bằng 0)
    if any(abs(sum(Ke,1)) > 1e-10) || any(abs(sum(Ke,2)) > 1e-10)
        warning('Ma trận độ cứng phần tử có thể không thỏa mãn điều kiện cân bằng');
    end
end

%................................................................
% Hàm dạng và đạo hàm cho phần tử Q4 (từ code gốc)
function [shapeFunction, naturalDerivatives] = shapeFunctionQ4(xi, eta)
    % Hàm dạng
    shapeFunction = 1/4*[ ...
        (1-xi)*(1-eta);
        (1+xi)*(1-eta);
        (1+xi)*(1+eta);
        (1-xi)*(1+eta)];
    
    % Đạo hàm theo tọa độ tự nhiên
    naturalDerivatives = 1/4*[ ...
        -(1-eta), -(1-xi);
        1-eta, -(1+xi);
        1+eta, 1+xi;
        -(1+eta), 1-xi];
end

%................................................................
% Ma trận Jacobi (từ code gốc)
function [Jacob, invJacobian, XYderivatives] = ...
    Jacobian(nodeCoordinates, naturalDerivatives)
    
    Jacob = [nodeCoordinates(:,2)'; nodeCoordinates(:,3)']*naturalDerivatives;
    invJacobian = inv(Jacob);
    XYderivatives = naturalDerivatives*invJacobian;
end