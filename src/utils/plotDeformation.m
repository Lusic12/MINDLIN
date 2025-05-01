function plotDeformation(nodes, elements, displacements, options)
% Vẽ biến dạng của tấm Mindlin
% Đầu vào:
%   nodes        - Tọa độ các nút [node_id, x, y]
%   elements     - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   displacements- Vector chuyển vị nút [w1 θx1 θy1 w2 θx2 θy2 ...]
%   options      - Cấu hình vẽ (tùy chọn)
%                 .scaleFactor: hệ số phóng đại chuyển vị
%                 .showUndeformed: hiển thị lưới ban đầu
%                 .meshColor: màu lưới ['k','b',...]
%                 .deformedColor: màu biến dạng
%                 .title: tiêu đề đồ thị

try
    % Xử lý tham số tùy chọn
    if nargin < 4
        options = struct();
    end
    
    % Thiết lập giá trị mặc định
    if ~isfield(options, 'scaleFactor')
        % Tự động tính hệ số phóng đại
        maxDisp = max(abs(displacements(1:3:end)));
        maxDim = max(max(nodes(:,2:3)) - min(nodes(:,2:3)));
        options.scaleFactor = 0.15 * maxDim / maxDisp;
    end
    if ~isfield(options, 'showUndeformed')
        options.showUndeformed = true;
    end
    if ~isfield(options, 'meshColor')
        options.meshColor = 'k';
    end
    if ~isfield(options, 'deformedColor')
        options.deformedColor = 'b';
    end
    if ~isfield(options, 'title')
        options.title = 'Plate Deformation';
    end

    % Tạo figure mới
    figure;
    hold on;

    % Vẽ lưới ban đầu nếu được yêu cầu
    if options.showUndeformed
        plotMesh(nodes, elements, 'EdgeColor', [0.7 0.7 0.7], 'LineStyle', ':');
    end

    % Tính toán tọa độ biến dạng
    numNodes = size(nodes, 1);
    deformedNodes = nodes;
    
    for i = 1:numNodes
        nodeIdx = 3*i-2;
        w = displacements(nodeIdx);
        theta_x = displacements(nodeIdx + 1);
        theta_y = displacements(nodeIdx + 2);
        
        % Cập nhật tọa độ
        deformedNodes(i,2:3) = nodes(i,2:3) + ...
            options.scaleFactor * [0, w];  % Chỉ xét chuyển vị ngang
    end

    % Vẽ lưới biến dạng
    for e = 1:size(elements, 1)
        nodeIds = elements(e, 2:5);
        
        % Lấy tọa độ nút biến dạng
        x = deformedNodes(nodeIds, 2);
        y = deformedNodes(nodeIds, 3);
        
        % Vẽ phần tử biến dạng
        patch(x, y, options.deformedColor, ...
            'FaceColor', 'none', ...
            'EdgeColor', options.deformedColor, ...
            'LineWidth', 1.5);
    end

    % Thêm chú thích
    if options.showUndeformed
        legend('Undeformed', 'Deformed', 'Location', 'best');
    end

    % Thiết lập thuộc tính đồ thị
    title(options.title);
    xlabel('x');
    ylabel('y');
    axis equal;
    grid on;
    
    % Thêm thông tin hệ số phóng đại
    text(min(nodes(:,2)), min(nodes(:,3)), ...
        sprintf('Scale factor: %.2f', options.scaleFactor), ...
        'VerticalAlignment', 'bottom');
    
    % Kết thúc giữ plot
    hold off;

catch ME
    error('Lỗi trong vẽ biến dạng: %s', ME.message);
end
end