function [Mx, My, Mxy, Qx, Qy] = computeStresses(nodes, elements, U, E, nu, h)
    % Tính mô men uốn và lực cắt tại các điểm Gauss
    % Đầu vào:
    %   nodes    - Tọa độ các nút [node_id, x, y]
    %   elements - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
    %   U        - Vector chuyển vị toàn cục
    %   E        - Mô đun đàn hồi Young
    %   nu       - Hệ số Poisson
    %   h        - Chiều dày tấm
    % Đầu ra:
    %   Mx  - Mô men uốn quanh trục x
    %   My  - Mô men uốn quanh trục y
    %   Mxy - Mô men xoắn
    %   Qx  - Lực cắt theo phương x
    %   Qy  - Lực cắt theo phương y
    
    % Ma trận độ cứng vật liệu
    D = (E * h^3) / (12 * (1 - nu^2)) * [1, nu, 0;
                                         nu, 1, 0;
                                         0, 0, (1-nu)/2];
    % Độ cứng cắt
    G = E / (2 * (1 + nu));
    kappa = 5/6;  % Hệ số hiệu chỉnh cắt
    Ds = kappa * G * h;
    
    % Khởi tạo mảng kết quả ứng suất
    nElements = size(elements, 1);
    Mx = zeros(nElements, 1);
    My = zeros(nElements, 1);
    Mxy = zeros(nElements, 1);
    Qx = zeros(nElements, 1);
    Qy = zeros(nElements, 1);
    
    % Tọa độ điểm Gauss để tính ứng suất (tâm phần tử)
    xi = 0;
    eta = 0;
    
    % Vòng lặp qua từng phần tử
    for el = 1:nElements
        nodeIds = elements(el, 2:5);
        
        % Lấy tọa độ các nút của phần tử
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        
        % Lấy chuyển vị phần tử
        Ue = zeros(12, 1);
        for i = 1:4
            n = nodeIds(i);
            Ue(3*i-2:3*i) = U(3*n-2:3*n);
        end
        
        % Đạo hàm hàm dạng tại tâm phần tử
        dNdxi = [-(1-eta)/4, (1-eta)/4, (1+eta)/4, -(1+eta)/4];
        dNdeta = [-(1-xi)/4, -(1+xi)/4, (1+xi)/4, (1-xi)/4];
        
        % Ma trận Jacobi
        J = [dNdxi*xe, dNdxi*ye;
             dNdeta*xe, dNdeta*ye];
        invJ = inv(J);
        
        % Khởi tạo ma trận B
        Bb = zeros(3, 12);  % Bending
        Bs = zeros(2, 12);  % Shear
        
        % Tính ma trận B
        for n = 1:4
            dNdx = invJ(1,1)*dNdxi(n) + invJ(1,2)*dNdeta(n);
            dNdy = invJ(2,1)*dNdxi(n) + invJ(2,2)*dNdeta(n);
            idx = 3*(n-1) + 1;
            
            % Ma trận biến dạng uốn
            Bb(:, idx:idx+2) = [0, dNdx, 0;
                               0, 0, dNdy;
                               0, dNdy, dNdx];
            
            % Ma trận biến dạng cắt
            Bs(:, idx:idx+2) = [dNdx, 1, 0;
                               dNdy, 0, 1];
        end
        
        % Tính độ cong và biến dạng cắt
        kappa = Bb * Ue;  % [κx; κy; κxy]
        gamma = Bs * Ue;  % [γxz; γyz]
        
        % Tính mô men và lực cắt
        moments = D * kappa;
        shears = Ds * gamma;
        
        % Lưu kết quả
        Mx(el) = moments(1);
        My(el) = moments(2);
        Mxy(el) = moments(3);
        Qx(el) = shears(1);
        Qy(el) = shears(2);
    end
end