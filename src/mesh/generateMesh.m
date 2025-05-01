function [nodes, elements] = generateMesh(L, W, nx, ny)
% Tạo lưới tấm chữ nhật với phần tử Q4
% Đầu vào:
%   L  - Chiều dài tấm
%   W  - Chiều rộng tấm
%   nx - Số phần tử theo chiều dài
%   ny - Số phần tử theo chiều rộng

try
    % Kiểm tra đầu vào
    validateInputs(L, W, nx, ny);

    % Tạo lưới nút
    dx = L/nx;
    dy = W/ny;
    [X, Y] = meshgrid(0:dx:L, 0:dy:W);
    
    % Tạo ma trận nodes [node_id, x, y]
    nodes = [(1:numel(X))', X(:), Y(:)];
    
    % Tạo ma trận elements [elem_id, node1, node2, node3, node4]
    elements = zeros(nx*ny, 5);
    elemId = 1;
    
    for j = 1:ny
        for i = 1:nx
            % Tính chỉ số nút cho phần tử hiện tại
            n1 = i + (j-1)*(nx+1);
            n2 = n1 + 1;
            n3 = n2 + (nx+1);
            n4 = n1 + (nx+1);
            
            % Thêm phần tử vào ma trận elements
            elements(elemId,:) = [elemId, n1, n2, n3, n4];
            elemId = elemId + 1;
        end
    end
    
    % Kiểm tra chất lượng lưới ban đầu
    validateMesh(nodes, elements);

catch ME
    error('Lỗi trong tạo lưới: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra đầu vào
function validateInputs(L, W, nx, ny)
    % Kiểm tra kích thước tấm
    if L <= 0 || W <= 0
        error('Kích thước tấm phải dương');
    end
    
    % Kiểm tra số phần tử
    if nx < 1 || ny < 1 || ~isnumeric(nx) || ~isnumeric(ny) ...
            || floor(nx) ~= nx || floor(ny) ~= ny
        error('Số phần tử phải là số nguyên dương');
    end
    
    % Kiểm tra tỷ lệ cạnh tổng thể
    aspectRatio = (L/nx)/(W/ny);
    if aspectRatio > 5 || aspectRatio < 0.2
        warning('Tỷ lệ cạnh của lưới có thể quá lớn (>5) hoặc quá nhỏ (<0.2)');
    end
end

%................................................................
% Hàm kiểm tra chất lượng lưới
function validateMesh(nodes, elements)
    % Kiểm tra sự tồn tại của các nút
    if any(any(elements(:,2:5) > size(nodes,1)))
        error('Phát hiện chỉ số nút không hợp lệ trong ma trận elements');
    end
    
    % Kiểm tra thứ tự nút ngược chiều kim đồng hồ
    for e = 1:size(elements,1)
        nodeIds = elements(e,2:5);
        coords = nodes(nodeIds,2:3);
        
        % Tính diện tích phần tử bằng tích có hướng
        area = 0;
        for i = 1:4
            j = mod(i,4) + 1;
            area = area + (coords(i,1)*coords(j,2) - coords(j,1)*coords(i,2));
        end
        
        if area <= 0
            error('Phát hiện phần tử có thứ tự nút không đúng hoặc suy biến');
        end
    end
    
    % Kiểm tra phần tử trùng
    elementSets = sort(elements(:,2:5), 2);
    if size(unique(elementSets, 'rows'), 1) < size(elements, 1)
        warning('Phát hiện phần tử có thể bị trùng');
    end
    
    % Kiểm tra nút trùng
    coords = nodes(:,2:3);
    if size(unique(coords, 'rows'), 1) < size(nodes, 1)
        warning('Phát hiện nút có thể bị trùng');
    end
end