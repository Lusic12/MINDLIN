function plotDeformedShape(nodes, elements, displacements, options)
% Vẽ hình dạng biến dạng 3D của tấm Mindlin
% Đầu vào:
%   nodes        - Tọa độ các nút [node_id, x, y]
%   elements     - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   displacements- Vector chuyển vị nút [w1 θx1 θy1 w2 θx2 θy2 ...]
%   options      - Cấu hình vẽ (tùy chọn)
%                 .scaleFactor: hệ số phóng đại chuyển vị
%                 .colormap: bảng màu ('jet','parula',...)
%                 .showUndeformed: hiển thị lưới ban đầu
%                 .viewAngle: góc nhìn [az el]
%                 .showColorbar: hiển thị thanh màu
%                 .title: tiêu đề đồ thị

try
    % Xử lý tham số tùy chọn
    if nargin < 4
        options = struct();
    end
    
    % Thiết lập giá trị mặc định
    if ~isfield(options, 'scaleFactor')
        maxDisp = max(abs(displacements(1:3:end)));
        maxDim = max(max(nodes(:,2:3)) - min(nodes(:,2:3)));
        options.scaleFactor = 0.15 * maxDim / maxDisp;
    end
    if ~isfield(options, 'colormap')
        options.colormap = 'jet';
    end
    if ~isfield(options, 'showUndeformed')
        options.showUndeformed = true;
    end
    if ~isfield(options, 'viewAngle')
        options.viewAngle = [-37.5, 30];
    end
    if ~isfield(options, 'showColorbar')
        options.showColorbar = true;
    end
    if ~isfield(options, 'title')
        options.title = '3D Deformed Shape';
    end

    % Tạo figure mới
    figure;
    hold on;

    % Vẽ lưới ban đầu nếu được yêu cầu
    if options.showUndeformed
        surf(reshape(nodes(:,2), [], sqrt(size(nodes,1))), ...
             reshape(nodes(:,3), [], sqrt(size(nodes,1))), ...
             zeros(size(reshape(nodes(:,2), [], sqrt(size(nodes,1))))), ...
             'FaceAlpha', 0.1, 'EdgeColor', [0.7 0.7 0.7], 'FaceColor', 'none');
    end

    % Tính toán tọa độ biến dạng và góc xoay
    numNodes = size(nodes, 1);
    deformedNodes = nodes;
    w = zeros(numNodes, 1);
    
    for i = 1:numNodes
        nodeIdx = 3*i-2;
        w(i) = displacements(nodeIdx);
        theta_x = displacements(nodeIdx + 1);
        theta_y = displacements(nodeIdx + 2);
        
        % Cập nhật tọa độ với chuyển vị và góc xoay
        deformedNodes(i,2:3) = nodes(i,2:3);
    end

    % Tạo lưới cho vẽ surface
    n = sqrt(size(nodes,1));
    X = reshape(deformedNodes(:,2), n, n);
    Y = reshape(deformedNodes(:,3), n, n);
    Z = reshape(w * options.scaleFactor, n, n);

    % Vẽ surface biến dạng
    surf(X, Y, Z, 'EdgeColor', 'interp', 'FaceColor', 'interp');

    % Thiết lập thuộc tính đồ thị
    colormap(options.colormap);
    if options.showColorbar
        c = colorbar;
        ylabel(c, 'Displacement');
    end

    % Thiết lập góc nhìn và các thuộc tính khác
    view(options.viewAngle);
    title(options.title);
    xlabel('x');
    ylabel('y');
    zlabel('z');
    grid on;
    
    % Thêm thông tin hệ số phóng đại
    text(min(nodes(:,2)), min(nodes(:,3)), min(Z(:)), ...
        sprintf('Scale factor: %.2f', options.scaleFactor), ...
        'VerticalAlignment', 'bottom');

    % Thêm đường viền để làm nổi bật biên
    for e = 1:size(elements, 1)
        nodeIds = elements(e, 2:5);
        x = deformedNodes(nodeIds, 2);
        y = deformedNodes(nodeIds, 3);
        z = w(nodeIds) * options.scaleFactor;
        
        % Vẽ đường viền
        line([x; x(1)], [y; y(1)], [z; z(1)], ...
            'Color', 'k', 'LineWidth', 0.5);
    end
    
    % Kết thúc giữ plot
    hold off;

catch ME
    error('Lỗi trong vẽ hình dạng biến dạng: %s', ME.message);
end
end