function plotDeformation(nodes, elements, U)
    % Vẽ hình dạng biến dạng của tấm (deformation)
    % Đầu vào:
    %   nodes    - Tọa độ các nút [node_id, x, y]
    %   elements - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
    %   U        - Vector chuyển vị [w1, θx1, θy1, w2, θx2, θy2, ...]
    
    % Trích xuất chuyển vị theo phương z tại các nút
    w = U(1:3:end);
    
    % Tạo figure mới
    figure;
    hold on;
    
    % Vẽ từng phần tử
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        
        % Lấy tọa độ và chuyển vị các nút của phần tử
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        we = w(nodeIds);
        
        % Vẽ bề mặt biến dạng của phần tử
        patch(xe, ye, we, 'FaceColor', 'interp', 'EdgeColor', 'k');
    end
    
    % Thiết lập góc nhìn và nhãn
    view(3);
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Chuyển vị (m)');
    colorbar;
    title('Biến dạng tấm');
    axis equal;
    grid on;
end