function plotMesh(nodes, elements, options)
% Vẽ lưới phần tử hữu hạn
% Đầu vào:
%   nodes    - Tọa độ các nút [node_id, x, y]
%   elements - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   options  - Cấu hình vẽ (tùy chọn)
%             .showNodeNumbers: hiển thị số thứ tự nút
%             .showElementNumbers: hiển thị số thứ tự phần tử
%             .fontSize: cỡ chữ cho nhãn
%             .lineWidth: độ dày đường vẽ
%             .markerSize: kích thước điểm nút

try
    % Xử lý tham số tùy chọn
    if nargin < 3
        options = struct();
    end
    
    % Thiết lập giá trị mặc định
    if ~isfield(options, 'showNodeNumbers')
        options.showNodeNumbers = false;
    end
    if ~isfield(options, 'showElementNumbers')
        options.showElementNumbers = false;
    end
    if ~isfield(options, 'fontSize')
        options.fontSize = 10;
    end
    if ~isfield(options, 'lineWidth')
        options.lineWidth = 1;
    end
    if ~isfield(options, 'markerSize')
        options.markerSize = 6;
    end

    % Tạo figure mới nếu chưa có
    if isempty(get(0,'CurrentFigure'))
        figure;
    end
    
    % Giữ trạng thái plot hiện tại
    hold on;
    
    % Vẽ các phần tử
    for i = 1:size(elements,1)
        nodeIds = elements(i,2:5);
        x = nodes(nodeIds,2);
        y = nodes(nodeIds,3);
        
        % Vẽ phần tử
        plot([x; x(1)], [y; y(1)], 'b-', 'LineWidth', options.lineWidth);
        
        % Hiển thị số thứ tự phần tử
        if options.showElementNumbers
            xc = mean(x);
            yc = mean(y);
            text(xc, yc, num2str(elements(i,1)), ...
                'HorizontalAlignment', 'center', ...
                'Color', 'blue', ...
                'FontSize', options.fontSize);
        end
    end
    
    % Vẽ các nút
    plot(nodes(:,2), nodes(:,3), 'ro', ...
        'MarkerSize', options.markerSize, ...
        'MarkerFaceColor', 'r');
    
    % Hiển thị số thứ tự nút
    if options.showNodeNumbers
        for i = 1:size(nodes,1)
            text(nodes(i,2), nodes(i,3), num2str(nodes(i,1)), ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'right', ...
                'Color', 'red', ...
                'FontSize', options.fontSize);
        end
    end
    
    % Thiết lập thuộc tính đồ thị
    axis equal;
    grid on;
    xlabel('x');
    ylabel('y');
    title('Lưới phần tử hữu hạn');
    
    % Kết thúc giữ plot
    hold off;

catch ME
    error('Lỗi trong vẽ lưới: %s', ME.message);
end

% Kiểm tra và cập nhật kích thước vùng vẽ
adjustPlotLimits(nodes);
end

%................................................................
% Hàm điều chỉnh giới hạn vùng vẽ
function adjustPlotLimits(nodes)
    % Tính khoảng cách lề
    xRange = max(nodes(:,2)) - min(nodes(:,2));
    yRange = max(nodes(:,3)) - min(nodes(:,3));
    margin = 0.1;
    
    % Thiết lập giới hạn trục với lề
    xlim([min(nodes(:,2)) - margin*xRange, max(nodes(:,2)) + margin*xRange]);
    ylim([min(nodes(:,3)) - margin*yRange, max(nodes(:,3)) + margin*yRange]);
end