function plotContourResults(nodes, elements, results, resultType, options)
% Vẽ đường đẳng trị cho kết quả phân tích
% Đầu vào:
%   nodes      - Tọa độ các nút [node_id, x, y]
%   elements   - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   results    - Ma trận kết quả theo phần tử
%   resultType - Loại kết quả ('Mx','My','Mxy','Qx','Qy','kx','ky','kxy','gamma_xz','gamma_yz')
%   options    - Cấu hình vẽ (tùy chọn)
%               .colormap: bảng màu ('jet','parula',...)
%               .numContours: số đường đẳng trị
%               .showMesh: hiển thị lưới
%               .showColorbar: hiển thị thanh màu
%               .title: tiêu đề đồ thị

try
    % Xử lý tham số tùy chọn
    if nargin < 5
        options = struct();
    end
    
    % Thiết lập giá trị mặc định
    if ~isfield(options, 'colormap')
        options.colormap = 'jet';
    end
    if ~isfield(options, 'numContours')
        options.numContours = 20;
    end
    if ~isfield(options, 'showMesh')
        options.showMesh = true;
    end
    if ~isfield(options, 'showColorbar')
        options.showColorbar = true;
    end
    if ~isfield(options, 'title')
        options.title = sprintf('Contour plot of %s', resultType);
    end

    % Xác định chỉ số cột kết quả dựa trên loại kết quả
    resultIndex = getResultIndex(resultType);
    plotData = results(:, resultIndex);

    % Tạo figure mới
    figure;
    hold on;

    % Vẽ contour cho từng phần tử
    for e = 1:size(elements, 1)
        nodeIds = elements(e, 2:5);
        x = nodes(nodeIds, 2);
        y = nodes(nodeIds, 3);
        z = repmat(plotData(e), 4, 1);
        
        % Tạo lưới nội suy cho phần tử
        [xi, yi] = meshgrid(linspace(min(x), max(x), 5), ...
                           linspace(min(y), max(y), 5));
        zi = griddata(x, y, z, xi, yi);
        
        % Vẽ contour
        contourf(xi, yi, zi, options.numContours, 'LineStyle', 'none');
    end

    % Vẽ lưới nếu được yêu cầu
    if options.showMesh
        for e = 1:size(elements, 1)
            nodeIds = elements(e, 2:5);
            x = nodes(nodeIds, 2);
            y = nodes(nodeIds, 3);
            plot([x; x(1)], [y; y(1)], 'k-', 'LineWidth', 0.5);
        end
    end

    % Thiết lập thuộc tính đồ thị
    colormap(options.colormap);
    if options.showColorbar
        colorbar;
    end
    
    % Thiết lập tiêu đề và nhãn trục
    title(options.title);
    xlabel('x');
    ylabel('y');
    axis equal;
    grid on;
    
    % Kết thúc giữ plot
    hold off;

catch ME
    error('Lỗi trong vẽ contour: %s', ME.message);
end
end

%................................................................
% Hàm xác định chỉ số cột kết quả
function index = getResultIndex(resultType)
    % Ánh xạ loại kết quả với chỉ số cột
    resultMap = containers.Map( ...
        {'Mx','My','Mxy','Qx','Qy','kx','ky','kxy','gamma_xz','gamma_yz'}, ...
        {1, 2, 3, 4, 5, 1, 2, 3, 4, 5});
    
    % Kiểm tra loại kết quả hợp lệ
    if ~isKey(resultMap, resultType)
        error('Loại kết quả không hợp lệ: %s', resultType);
    end
    
    index = resultMap(resultType);
end