function [stresses, strains] = computeStresses(nodes, elements, displacements, material, thickness)
% Tính toán ứng suất và biến dạng cho tấm Mindlin
% Đầu vào:
%   nodes        - Tọa độ các nút [node_id, x, y]
%   elements     - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   displacements- Vector chuyển vị nút
%   material     - Các thông số vật liệu (E, nu)
%   thickness    - Chiều dày tấm

try
    % Kiểm tra đầu vào
    validateInputs(nodes, elements, displacements, material, thickness);

    % Số phần tử
    numberElements = size(elements, 1);
    
    % Khởi tạo ma trận kết quả
    stresses = zeros(numberElements, 5); % [Mx, My, Mxy, Qx, Qy]
    strains = zeros(numberElements, 5);  % [kx, ky, kxy, gamma_xz, gamma_yz]
    
    % Ma trận độ cứng vật liệu cho uốn
    D = material.E*thickness^3/(12*(1-material.nu^2)) * ...
        [1, material.nu, 0;
         material.nu, 1, 0;
         0, 0, (1-material.nu)/2];
     
    % Ma trận độ cứng vật liệu cho cắt
    kappa = 5/6; % Hệ số hiệu chỉnh cắt
    G = material.E/(2*(1+material.nu));
    Ds = kappa*G*thickness * eye(2);

    % Tính toán ứng suất và biến dạng cho từng phần tử
    for e = 1:numberElements
        % Lấy chỉ số nút của phần tử
        nodeIds = elements(e,2:5);
        
        % Lấy tọa độ nút
        elementNodes = nodes(nodeIds,:);
        
        % Lấy chuyển vị của phần tử
        elementDOF = zeros(1,15);
        for i = 1:4
            n = nodeIds(i);
            elementDOF(3*i-2:3*i) = [3*n-2, 3*n-1, 3*n];
        end
        elementDisp = displacements(elementDOF);
        
        % Tính toán ứng suất và biến dạng tại điểm Gauss
        [B_b, B_s] = formStrainDisplacementMatrix(elementNodes);
        
        % Tính biến dạng uốn và cắt
        bendingStrain = B_b*elementDisp';  % [kx; ky; kxy]
        shearStrain = B_s*elementDisp';    % [gamma_xz; gamma_yz]
        
        % Tính mô men và lực cắt
        moments = D*bendingStrain;         % [Mx; My; Mxy]
        shears = Ds*shearStrain;          % [Qx; Qy]
        
        % Lưu kết quả
        stresses(e,:) = [moments', shears'];
        strains(e,:) = [bendingStrain', shearStrain'];
    end

catch ME
    error('Lỗi trong tính toán ứng suất: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra đầu vào
function validateInputs(nodes, elements, displacements, material, thickness)
    % Kiểm tra kích thước ma trận nodes và elements
    if size(nodes,2) ~= 3
        error('Ma trận nodes phải có 3 cột [node_id, x, y]');
    end
    if size(elements,2) ~= 5
        error('Ma trận elements phải có 5 cột [elem_id, node1, node2, node3, node4]');
    end
    
    % Kiểm tra vector chuyển vị
    if length(displacements) ~= 3*size(nodes,1)
        error('Kích thước vector chuyển vị không khớp với số bậc tự do');
    end
    
    % Kiểm tra thông số vật liệu
    if ~isfield(material, 'E') || ~isfield(material, 'nu')
        error('Thông số vật liệu phải có E và nu');
    end
    if material.E <= 0 || material.nu < 0 || material.nu >= 0.5
        error('Thông số vật liệu không hợp lệ');
    end
    
    % Kiểm tra chiều dày
    if thickness <= 0
        error('Chiều dày tấm phải dương');
    end
end

%................................................................
% Hàm tính ma trận quan hệ biến dạng - chuyển vị
function [B_b, B_s] = formStrainDisplacementMatrix(elementNodes)
    % Điểm Gauss trung tâm
    xi = 0;
    eta = 0;
    
    % Tính hàm dạng và đạo hàm
    [~, dN] = shapeFunctionQ4(xi, eta);
    
    % Tính ma trận Jacobi
    J = [elementNodes(:,2)'; elementNodes(:,3)'] * dN;
    invJ = inv(J);
    
    % Đạo hàm theo tọa độ tổng thể
    dNdx = invJ * dN;
    
    % Số nút
    numberNodes = size(elementNodes,1);
    
    % Khởi tạo ma trận B
    B_b = zeros(3, 3*numberNodes);
    B_s = zeros(2, 3*numberNodes);
    
    % Lắp ghép ma trận B
    for i = 1:numberNodes
        % Ma trận biến dạng uốn
        B_b(1,3*i-1) = dNdx(1,i);      % dtheta_x/dx
        B_b(2,3*i) = dNdx(2,i);        % dtheta_y/dy
        B_b(3,3*i-1) = dNdx(2,i);      % dtheta_x/dy
        B_b(3,3*i) = dNdx(1,i);        % dtheta_y/dx
        
        % Ma trận biến dạng cắt
        B_s(1,3*i-2) = dNdx(1,i);      % dw/dx
        B_s(1,3*i-1) = -1;             % -theta_x
        B_s(2,3*i-2) = dNdx(2,i);      % dw/dy
        B_s(2,3*i) = -1;               % -theta_y
    end
end

%................................................................
% Hàm tính hàm dạng và đạo hàm
function [N, dN] = shapeFunctionQ4(xi, eta)
    % Hàm dạng
    N = 1/4*[(1-xi)*(1-eta);
             (1+xi)*(1-eta);
             (1+xi)*(1+eta);
             (1-xi)*(1+eta)];
    
    % Đạo hàm hàm dạng theo tọa độ tự nhiên
    dN = 1/4*[-(1-eta), -(1-xi);
               1-eta, -(1+xi);
               1+eta, 1+xi;
              -(1+eta), 1-xi]';
end