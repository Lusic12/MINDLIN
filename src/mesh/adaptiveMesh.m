function [nodes, elements] = adaptiveMesh(nodes, elements, errorIndicator, targetError)
% Tinh chỉnh lưới tự động dựa trên chỉ số lỗi
% Đầu vào:
%   nodes          - Tọa độ các nút [node_id, x, y]  
%   elements       - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   errorIndicator - Chỉ số lỗi cho từng phần tử
%   targetError    - Giá trị lỗi mục tiêu

try
    % Kiểm tra đầu vào
    validateInputs(nodes, elements, errorIndicator, targetError);

    % Tính toán lỗi trung bình và độ lệch chuẩn
    meanError = mean(errorIndicator);
    stdError = std(errorIndicator);
    
    % Xác định phần tử cần chia nhỏ (lỗi > meanError + 0.5*stdError)
    elementsToRefine = find(errorIndicator > meanError + 0.5*stdError);
    
    % Nếu không có phần tử nào cần chia nhỏ, thoát
    if isempty(elementsToRefine)
        return;
    end

    % Khởi tạo mảng lưu trữ nút mới
    newNodes = nodes;
    newElements = elements;
    
    % Số nút và phần tử ban đầu
    numberNodes = size(nodes,1);
    numberElements = size(elements,1);
    
    % Chia nhỏ từng phần tử được chọn
    for i = 1:length(elementsToRefine)
        elementId = elementsToRefine(i);
        
        % Lấy tọa độ các nút của phần tử
        nodeIds = elements(elementId,2:5);
        x = nodes(nodeIds,2);
        y = nodes(nodeIds,3);
        
        % Tạo nút trung điểm cho các cạnh
        midNodes = zeros(4,1);
        for edge = 1:4
            node1 = nodeIds(edge);
            node2 = nodeIds(mod(edge,4)+1);
            
            % Tính tọa độ điểm giữa
            xMid = (nodes(node1,2) + nodes(node2,2))/2;
            yMid = (nodes(node1,3) + nodes(node2,3))/2;
            
            % Thêm nút mới
            newNodes = [newNodes; size(newNodes,1)+1, xMid, yMid];
            midNodes(edge) = size(newNodes,1);
        end
        
        % Tạo nút trung tâm phần tử
        xCenter = mean(x);
        yCenter = mean(y);
        newNodes = [newNodes; size(newNodes,1)+1, xCenter, yCenter];
        centerNode = size(newNodes,1);
        
        % Tạo 4 phần tử mới
        newElements = [newElements;
            numberElements+4*i-3, nodeIds(1), midNodes(1), centerNode, midNodes(4);
            numberElements+4*i-2, midNodes(1), nodeIds(2), midNodes(2), centerNode;
            numberElements+4*i-1, centerNode, midNodes(2), nodeIds(3), midNodes(3);
            numberElements+4*i, midNodes(4), centerNode, midNodes(3), nodeIds(4)];
    end
    
    % Xóa các phần tử cũ đã được chia nhỏ
    newElements(elementsToRefine,:) = [];
    
    % Cập nhật lại chỉ số phần tử
    newElements(:,1) = 1:size(newElements,1);
    
    % Kiểm tra chất lượng lưới mới
    validateMesh(newNodes, newElements);
    
    % Gán kết quả
    nodes = newNodes;
    elements = newElements;

catch ME
    error('Lỗi trong tinh chỉnh lưới: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra đầu vào
function validateInputs(nodes, elements, errorIndicator, targetError)
    % Kiểm tra kích thước dữ liệu
    if size(nodes,2) ~= 3
        error('Ma trận nodes phải có 3 cột [node_id, x, y]');
    end
    
    if size(elements,2) ~= 5
        error('Ma trận elements phải có 5 cột [elem_id, node1, node2, node3, node4]');
    end
    
    % Kiểm tra kích thước chỉ số lỗi
    if length(errorIndicator) ~= size(elements,1)
        error('Kích thước vector chỉ số lỗi không khớp với số phần tử');
    end
    
    % Kiểm tra giá trị lỗi mục tiêu
    if targetError <= 0
        error('Giá trị lỗi mục tiêu phải dương');
    end
    
    % Kiểm tra tính hợp lệ của chỉ số nút
    if any(any(elements(:,2:5) > size(nodes,1)))
        error('Phát hiện chỉ số nút không hợp lệ trong ma trận elements');
    end
end

%................................................................
% Hàm kiểm tra chất lượng lưới
function validateMesh(nodes, elements)
    % Kiểm tra tỷ lệ cạnh của phần tử
    maxAspectRatio = calculateMaxAspectRatio(nodes, elements);
    if maxAspectRatio > 5
        warning('Phát hiện phần tử có tỷ lệ cạnh lớn (>5)');
    end
    
    % Kiểm tra góc nhỏ nhất và lớn nhất
    [minAngle, maxAngle] = calculateElementAngles(nodes, elements);
    if minAngle < 30 || maxAngle > 150
        warning('Phát hiện góc không tốt trong lưới (<%d° hoặc >%d°)', 30, 150);
    end
    
    % Kiểm tra liên thông của lưới
    if ~isMeshConnected(elements)
        warning('Lưới có thể không liên thông');
    end
end

%................................................................
% Hàm tính tỷ lệ cạnh lớn nhất
function maxAspectRatio = calculateMaxAspectRatio(nodes, elements)
    maxAspectRatio = 0;
    for e = 1:size(elements,1)
        nodeIds = elements(e,2:5);
        x = nodes(nodeIds,2);
        y = nodes(nodeIds,3);
        
        % Tính độ dài các cạnh
        edges = [sqrt((x(2)-x(1))^2 + (y(2)-y(1))^2);
                sqrt((x(3)-x(2))^2 + (y(3)-y(2))^2);
                sqrt((x(4)-x(3))^2 + (y(4)-y(3))^2);
                sqrt((x(1)-x(4))^2 + (y(1)-y(4))^2)];
        
        % Tỷ lệ cạnh = cạnh dài nhất / cạnh ngắn nhất
        aspectRatio = max(edges)/min(edges);
        maxAspectRatio = max(maxAspectRatio, aspectRatio);
    end
end

%................................................................
% Hàm tính góc nhỏ nhất và lớn nhất
function [minAngle, maxAngle] = calculateElementAngles(nodes, elements)
    minAngle = 180;
    maxAngle = 0;
    
    for e = 1:size(elements,1)
        nodeIds = elements(e,2:5);
        x = nodes(nodeIds,2);
        y = nodes(nodeIds,3);
        
        % Tính vector cạnh
        v1 = [x(2)-x(1), y(2)-y(1)];
        v2 = [x(3)-x(2), y(3)-y(2)];
        v3 = [x(4)-x(3), y(4)-y(3)];
        v4 = [x(1)-x(4), y(1)-y(4)];
        
        % Tính góc giữa các vector
        angles = zeros(4,1);
        angles(1) = acosd(dot(v1,-v4)/(norm(v1)*norm(v4)));
        angles(2) = acosd(dot(v2,-v1)/(norm(v2)*norm(v1)));
        angles(3) = acosd(dot(v3,-v2)/(norm(v3)*norm(v2)));
        angles(4) = acosd(dot(v4,-v3)/(norm(v4)*norm(v3)));
        
        minAngle = min(minAngle, min(angles));
        maxAngle = max(maxAngle, max(angles));
    end
end

%................................................................
% Hàm kiểm tra tính liên thông của lưới
function isConnected = isMeshConnected(elements)
    % Tạo đồ thị kết nối
    edges = [];
    for e = 1:size(elements,1)
        nodeIds = elements(e,2:5);
        edges = [edges; 
                nodeIds(1), nodeIds(2);
                nodeIds(2), nodeIds(3);
                nodeIds(3), nodeIds(4);
                nodeIds(4), nodeIds(1)];
    end
    
    % Tìm các nút đã thăm
    visited = zeros(max(max(edges)),1);
    visited(edges(1,1)) = 1;
    stack = edges(1,1);
    
    % Duyệt đồ thị theo chiều sâu
    while ~isempty(stack)
        node = stack(end);
        stack(end) = [];
        
        % Tìm các nút kề
        neighbors = unique([edges(edges(:,1)==node,2); edges(edges(:,2)==node,1)]);
        
        % Thêm các nút chưa thăm vào stack
        unvisited = neighbors(visited(neighbors)==0);
        stack = [stack; unvisited];
        visited(unvisited) = 1;
    end
    
    % Kiểm tra xem đã thăm tất cả các nút chưa
    isConnected = all(visited(unique([edges(:,1); edges(:,2)])));
end