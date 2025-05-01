function plotContourResults(nodes, elements, U)
    % Vẽ contour (đường đồng mức) chuyển vị và ứng suất
    % Đầu vào:
    %   nodes    - Tọa độ các nút [node_id, x, y]
    %   elements - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
    %   U        - Vector chuyển vị [w1, θx1, θy1, w2, θx2, θy2, ...]
    
    % Trích xuất chuyển vị theo phương z tại các nút
    w = U(1:3:end);
    
    % Tạo lưới tam giác cho contour mượt hơn
    nElements = size(elements, 1);
    tri = zeros(nElements*2, 3);
    for i = 1:nElements
        nodeIds = elements(i, 2:5);
        % Chia phần tử tứ giác thành 2 tam giác
        tri(2*i-1,:) = nodeIds([1,2,3]);
        tri(2*i,:) = nodeIds([1,3,4]);
    end
    
    % Tạo figure mới nếu chưa có
    if isempty(get(0, 'CurrentFigure'))
        figure;
    end
    
    % Vẽ contour
    trisurf(tri, nodes(:,2), nodes(:,3), w);
    view(2); % Nhìn từ trên xuống
    shading interp;
    colorbar;
    
    % Thiết lập thuộc tính đồ họa
    xlabel('X (m)');
    ylabel('Y (m)');
    title('Contour chuyển vị');
    axis equal;
    grid on;
end