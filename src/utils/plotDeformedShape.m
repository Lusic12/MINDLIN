function plotDeformedShape(nodes, elements, U, scaleFactor)
    % Vẽ hình dạng biến dạng của tấm Mindlin với cải thiện hiển thị
    % 
    % Đầu vào:
    %   nodes       - Tọa độ các nút [node_id, x, y]
    %   elements    - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
    %   U           - Vector chuyển vị [w1, θx1, θy1, w2, θx2, θy2, ...] hoặc vector dạng mode
    %   scaleFactor - Hệ số phóng đại hình dạng (tùy chọn)
    
    % Kiểm tra đầu vào
    validateattributes(nodes, {'numeric'}, {'2d', 'nonempty'}, 'plotDeformedShape', 'nodes');
    validateattributes(elements, {'numeric'}, {'2d', 'nonempty', 'integer'}, 'plotDeformedShape', 'elements');
    validateattributes(U, {'numeric'}, {'nonempty'}, 'plotDeformedShape', 'U');
    
    % Kiểm tra nếu U có kích thước đúng cho vector chuyển vị đầy đủ hoặc vector dạng mode
    numNodes = size(nodes, 1);
    isFullDisplacement = (length(U) == numNodes * 3);
    
    % Xử lý các định dạng vector khác nhau dựa trên kích thước
    if isFullDisplacement
        % Định dạng chuyển vị tiêu chuẩn [w1, θx1, θy1, w2, θx2, θy2, ...]
        w = U(1:3:end);
    else
        % Có thể là vector dạng mode với định dạng khác
        % Đối với vector dạng mode, kiểm tra nếu kích thước chỉ khớp với các DOF theo phương thẳng đứng
        if length(U) == numNodes
            % Ánh xạ trực tiếp: 1 giá trị mỗi nút (chuyển vị thẳng đứng)
            w = U;
        else
            % Đối với các định dạng khác, cố gắng trích xuất sử dụng ID nút
            % Điều này giả định ID nút là tuần tự bắt đầu từ 1
            w = zeros(numNodes, 1);
            % Sử dụng min của độ dài vector và chỉ số tối đa dự kiến để tránh lỗi
            maxIdx = min(length(U), numNodes);
            w(1:maxIdx) = U(1:maxIdx);
            warning('plotDeformedShape:UnknownFormat', ...
                'Định dạng vector chuyển vị không được nhận diện. Hiển thị theo cách tốt nhất có thể.');
        end
    end
    
    if nargin < 4 || isempty(scaleFactor)
        % Hệ số phóng đại mặc định dựa trên chuyển vị lớn nhất
        maxDefl = max(abs(w));
        if maxDefl > 0
            scaleFactor = 0.2 * max(max(nodes(:,2)) - min(nodes(:,2)), ...
                                    max(nodes(:,3)) - min(nodes(:,3))) / maxDefl;
        else
            scaleFactor = 1;
        end
    end
    
    % Tạo figure với giao diện tối ưu
    figure('Color', 'white');
    ax = axes('Box', 'on', 'FontSize', 11);
    hold(ax, 'on');
    
    % --- Kiểm tra phần tử có chỉ số nút không hợp lệ trước khi vẽ ---
    numNodes = size(nodes, 1);
    validElements = all(elements(:,2:5) <= numNodes & elements(:,2:5) >= 1, 2);
    
    if ~all(validElements)
        invalidCount = sum(~validElements);
        warning('plotDeformedShape:InvalidNodeIndices', ...
            'Phát hiện %d phần tử có chỉ số nút không hợp lệ. Các phần tử này sẽ bị bỏ qua.', invalidCount);
    end
    
    % Lấy các phần tử chỉ có chỉ số nút hợp lệ
    validElementsIndices = find(validElements);
    
    % Vẽ lưới chưa biến dạng (màu xám)
    for i = 1:length(validElementsIndices)
        el = validElementsIndices(i);
        nodeIds = elements(el, 2:5);
        
        % Kiểm tra nếu bất kỳ chỉ số nút nào không hợp lệ
        if any(nodeIds > size(nodes, 1))
            continue; % Bỏ qua phần tử này
        end
        
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        % Đóng phần tử bằng cách lặp lại nút đầu tiên
        plot3(ax, [xe; xe(1)], [ye; ye(1)], zeros(5,1), ...
             'Color', [0.7 0.7 0.7], 'LineStyle', ':', 'LineWidth', 0.5);
    end
    
    % Tạo bản đồ màu cho hình dạng biến dạng
    colormap(ax, parula);
    
    % Chuẩn bị dữ liệu vẽ bề mặt
    numValidElements = length(validElementsIndices);
    faceVertices = zeros(numValidElements, 4);
    vertexData = zeros(numNodes, 1);
    
    % Vẽ lưới đã biến dạng và chuẩn bị dữ liệu cho vẽ bề mặt
    for i = 1:numValidElements
        el = validElementsIndices(i);
        nodeIds = elements(el, 2:5);
        
        % Kiểm tra các chỉ số nút trùng lặp trong phần tử
        if numel(unique(nodeIds)) < 4
            continue;
        end
        
        % Kiểm tra nếu bất kỳ nodeIds nào vượt quá giới hạn vector w
        if any(nodeIds > length(w))
            warning('plotDeformedShape:IndexOutOfBounds', ...
                'Phần tử %d có chỉ số nút vượt quá độ dài vector chuyển vị. Bỏ qua.', el);
            continue;
        end
        
        % Lưu mối quan hệ mặt-đỉnh cho patch
        faceVertices(i, :) = nodeIds;
        
        % Lấy tọa độ nút và chuyển vị
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        we = w(nodeIds) * scaleFactor;
        
        % Đặt dữ liệu đỉnh cho tô màu
        vertexData(nodeIds) = w(nodeIds);
        
        % Vẽ cạnh phần tử đã biến dạng
        plot3(ax, [xe; xe(1)], [ye; ye(1)], [we; we(1)], ...
             'Color', 'b', 'LineWidth', 1);
    end
    
    % Tạo vẽ bề mặt cho hình dạng biến dạng
    X = nodes(:, 2);
    Y = nodes(:, 3);
    
    % Đảm bảo vector Z có độ dài đúng
    Z = zeros(size(nodes, 1), 1);
    % Sử dụng chỉ số hợp lệ để gán giá trị
    validIndices = min(length(w), size(nodes, 1));
    Z(1:validIndices) = w(1:validIndices) * scaleFactor;
    
    % Loại bỏ các mặt không hợp lệ (những mặt có bất kỳ đỉnh trùng lặp)
    mask = zeros(numValidElements, 1);
    for i = 1:numValidElements
        mask(i) = numel(unique(faceVertices(i, :))) == 4;
    end
    validFaces = faceVertices(logical(mask), :);
    
    if ~isempty(validFaces)
        h_surf = patch('Vertices', [X, Y, Z], 'Faces', validFaces, ...
                      'FaceColor', 'interp', 'FaceAlpha', 0.7, ...
                      'EdgeColor', 'none', 'FaceVertexCData', vertexData);
    end
    
    % Thiết lập thuộc tính đồ họa
    xlabel(ax, 'X (m)', 'FontWeight', 'bold');
    ylabel(ax, 'Y (m)', 'FontWeight', 'bold');
    zlabel(ax, 'Chuyển vị (m)', 'FontWeight', 'bold');
    title(ax, 'Hình dạng biến dạng của tấm Mindlin', 'FontSize', 13, 'FontWeight', 'bold');
    
    h_cb = colorbar(ax);
    title(h_cb, 'w (m)');
    
    % Thiết lập tỷ lệ và góc nhìn
    axis(ax, 'equal');
    grid(ax, 'on');
    view(ax, 3);
    
    % Thêm chú thích
    h1 = plot3(NaN, NaN, NaN, 'Color', [0.7 0.7 0.7], 'LineStyle', ':', 'LineWidth', 0.5);
    h2 = plot3(NaN, NaN, NaN, 'b-', 'LineWidth', 1);
    h3 = patch('Vertices', [0,0,0; 0,0,0; 0,0,0], 'Faces', [1,2,3], ...
               'FaceColor', 'interp', 'FaceAlpha', 0.7, 'EdgeColor', 'none');
    
    legend([h1, h2, h3], {'Chưa biến dạng', 'Cạnh đã biến dạng', 'Bề mặt đã biến dạng'}, ...
           'Location', 'best', 'FontSize', 10);
       
    % Hiển thị thông tin hệ số phóng đại
    text(0.02, 0.02, sprintf('Hệ số phóng đại: %.2f', scaleFactor), ...
         'Units', 'normalized', 'FontSize', 9, 'Color', [0.3 0.3 0.3]);
         
    % Điều chỉnh ánh sáng để hiển thị 3D tốt hơn
    lighting gouraud
    camlight('headlight');
end