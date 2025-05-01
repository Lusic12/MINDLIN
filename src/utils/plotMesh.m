function plotMesh(nodes, elements)
    % Vẽ lưới phần tử tấm Mindlin
    % Đầu vào:
    %   nodes    - Tọa độ các nút [node_id, x, y]
    %   elements - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
    
    % Tạo figure mới nếu chưa có
    if isempty(get(0, 'CurrentFigure'))
        figure;
    end
    
    hold on;
    
    % Vẽ từng phần tử
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        % Vẽ cạnh phần tử
        plot([xe; xe(1)], [ye; ye(1)], 'b-', 'LineWidth', 0.5);
    end
    
    % Vẽ các nút
    plot(nodes(:,2), nodes(:,3), 'r.', 'MarkerSize', 8);
    
    % Thiết lập thuộc tính đồ họa
    xlabel('X (m)');
    ylabel('Y (m)');
    grid on;
    axis equal;
    title('Cấu hình lưới phần tử');
end