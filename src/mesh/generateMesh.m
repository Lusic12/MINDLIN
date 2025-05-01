function [nodes, elements] = generateMesh(L, W, nx, ny)
    % Sinh lưới hình chữ nhật cho bài toán tấm
    % Đầu vào:
    %   L  - Chiều dài theo phương x
    %   W  - Chiều rộng theo phương y
    %   nx - Số phần tử theo phương x
    %   ny - Số phần tử theo phương y
    % Đầu ra:
    %   nodes    - Tọa độ các nút [node_id, x, y]
    %   elements - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
    
    % Tạo tọa độ các nút
    x = linspace(0, L, nx+1);
    y = linspace(0, W, ny+1);
    [X, Y] = meshgrid(x, y);
    
    nodes = zeros((nx+1)*(ny+1), 3);
    nodes(:,1) = 1:size(nodes,1);  % ID nút
    nodes(:,2) = X(:);             % Tọa độ X
    nodes(:,3) = Y(:);             % Tọa độ Y
    
    % Tạo ma trận liên kết phần tử
    elements = zeros(nx*ny, 5);
    elem = 1;
    for j = 1:ny
        for i = 1:nx
            n1 = i + (j-1)*(nx+1);
            n2 = n1 + 1;
            n3 = n2 + (nx+1);
            n4 = n1 + (nx+1);
            elements(elem,:) = [elem, n1, n2, n3, n4];
            elem = elem + 1;
        end
    end
end