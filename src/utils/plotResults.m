function plotResults(nodes, elements, U, analysisType, plotType, colormap_name, animate, exportPath)
% Hiển thị kết quả phân tích với các tuỳ chọn trực quan hóa nâng cao
% Đầu vào:
%   nodes, elements, U - dữ liệu lưới và chuyển vị
%   analysisType - loại phân tích (1: tĩnh, 2: ổn định, 3: dao động)
%   plotType - kiểu đồ thị
%   colormap_name - tên bảng màu
%   animate - có hoạt hình không
%   exportPath - đường dẫn xuất file (nếu có)

try
    % Tạo figure mới nếu chưa có
    if isempty(get(0, 'CurrentFigure'))
        figResults = figure('Color', 'w');
    else
        figResults = gcf;
    end

    % Bố cục subplot
    if plotType == 1 % Hiển thị tất cả kết quả
        plotLayout = [2 2];
    else
        plotLayout = [1 1];
    end

    % Vẽ theo loại
    switch plotType
        case 1 % Tất cả kết quả
            subplot(plotLayout(1), plotLayout(2), 1)
            plotMesh(nodes, elements);
            title('Cấu hình lưới', 'FontWeight', 'bold')
            
            subplot(plotLayout(1), plotLayout(2), 2)
            plotDeformedShape(nodes, elements, U, computeScaleFactor(U));
            title('Hình dạng biến dạng', 'FontWeight', 'bold')
            
            subplot(plotLayout(1), plotLayout(2), 3)
            plotContourResults(nodes, elements, U);
            title('Contour chuyển vị', 'FontWeight', 'bold')
            
            subplot(plotLayout(1), plotLayout(2), 4)
            plotAnalysisSpecific(analysisType, U);
            
        case 2 % Chỉ lưới và chất lượng
            plotMeshWithQuality(nodes, elements);
            
        case 3 % Biến dạng có hoạt hình
            if animate
                animateResults(nodes, elements, U, analysisType);
            else
                plotDeformedShape(nodes, elements, U, computeScaleFactor(U));
            end
            
        case 4 % Contour nâng cao
            plotContourResults(nodes, elements, U);
    end

    % Áp dụng bảng màu
    if ~isempty(colormap_name)
        try
            colormap(gca, colormap_name);
        catch
            warning('Không thể áp dụng bảng màu %s. Sử dụng bảng màu mặc định.', colormap_name);
            colormap(gca, 'parula');
        end
    end

    % Xuất file nếu có đường dẫn
    if nargin >= 8 && ~isempty(exportPath)
        exportResults(figResults, exportPath);
    end

catch ME
    % Xử lý lỗi trục đồ thị
    if contains(ME.message, 'matlab.graphics.axis.Axes')
        warning('Lỗi trục đồ thị: %s\nĐang tạo figure mới...', ME.message);
        figure;
        return;
    else
        rethrow(ME);
    end
end
end

function scaleFactor = computeScaleFactor(U)
    maxDefl = max(abs(U));
    if maxDefl > 0
        scaleFactor = 0.2 / maxDefl;
    else
        scaleFactor = 1;
    end
end

function plotMeshWithQuality(nodes, elements)
    % Vẽ lưới với chỉ số chất lượng
    try
        [aspectRatio, skewness] = calculateMeshQuality(nodes, elements);
        qualityMetric = max(aspectRatio, skewness);
        
        % Tạo axes mới nếu chưa có
        if isempty(get(gca, 'Children'))
            ax = gca;
        else
            ax = axes;
        end
        
        hold(ax, 'on');
        patch(ax, 'Faces', elements(:,2:5), ...
              'Vertices', nodes(:,2:3), ...
              'FaceVertexCData', qualityMetric, ...
              'FaceColor', 'flat', ...
              'EdgeColor', 'k');
        colorbar(ax, 'TickLabelInterpreter', 'latex');
        title(ax, 'Phân bố chất lượng lưới', 'FontWeight', 'bold');
        xlabel(ax, 'X (m)');
        ylabel(ax, 'Y (m)');
        axis(ax, 'equal', 'tight');
        hold(ax, 'off');
    catch ME
        warning('Lỗi khi vẽ chất lượng lưới: %s', ME.message);
    end
end

function [aspectRatio, skewness] = calculateMeshQuality(nodes, elements)
    nElements = size(elements, 1);
    aspectRatio = zeros(nElements, 1);
    skewness = zeros(nElements, 1);
    for el = 1:nElements
        nodeIds = elements(el, 2:5);
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        dx = max(xe) - min(xe);
        dy = max(ye) - min(ye);
        aspectRatio(el) = max(dx/dy, dy/dx);
        angles = calculateElementAngles(xe, ye);
        skewness(el) = max(abs(angles - 90)) / 90;
    end
end

function angles = calculateElementAngles(xe, ye)
    angles = zeros(4,1);
    for i = 1:4
        j = mod(i, 4) + 1;
        k = mod(i-2, 4) + 1;
        v1 = [xe(j)-xe(i), ye(j)-ye(i)];
        v2 = [xe(k)-xe(i), ye(k)-ye(i)];
        cos_theta = dot(v1,v2)/(norm(v1)*norm(v2));
        angles(i) = acosd(cos_theta);
    end
end

function animateResults(nodes, elements, U, analysisType)
    % Hoạt hình biến dạng
    nFrames = 30;
    period = 2; % giây cho 1 chu kỳ
    hold on;
    axis equal;
    grid on;
    for frame = 1:nFrames
        cla;
        phase = 2*pi * frame/nFrames;
        switch analysisType
            case 1 % Tĩnh
                scaleFactor = computeScaleFactor(U);
            case {2, 3} % Ổn định hoặc Dao động
                scaleFactor = 0.2 * cos(phase);
        end
        plotDeformedShape(nodes, elements, U * scaleFactor, 1);
        drawnow;
        pause(period/nFrames);
    end
end

function exportResults(fig, exportPath)
    % Xuất hình ra nhiều định dạng
    [path, name] = fileparts(exportPath);
    if ~exist(path, 'dir')
        mkdir(path);
    end
    print(fig, fullfile(path, [name '_fig.png']), '-dpng', '-r300');
    print(fig, fullfile(path, [name '_fig.pdf']), '-dpdf', '-bestfit');
    savefig(fig, fullfile(path, [name '_fig.fig']));
    results = struct();
    results.nodes = evalin('base', 'nodes');
    results.elements = evalin('base', 'elements');
    results.displacement = evalin('base', 'U');
    save(fullfile(path, [name '_data.mat']), 'results');
end

function plotAnalysisSpecific(analysisType, U)
    switch analysisType
        case 1 % Tĩnh
            plotStaticSummary(U);
        case 2 % Ổn định
            plotBucklingSummary(U);
        case 3 % Dao động
            plotVibrationSummary(U);
    end
end

function plotStaticSummary(U)
    % Biểu đồ cột chuyển vị lớn nhất/nhỏ nhất
    bar([max(U), min(U)]);
    set(gca, 'XTickLabel', {'Max', 'Min'});
    ylabel('Chuyển vị (m)');
    title('Giá trị chuyển vị cực trị');
    grid on;
end

function plotBucklingSummary(U)
    % Biểu đồ hệ số tới hạn
    bar(diag(U(1:5,1:5)));
    xlabel('Mode');
    ylabel('Hệ số tới hạn');
    title('Các hệ số tới hạn chính');
    grid on;
end

function plotVibrationSummary(U)
    % Biểu đồ tần số riêng
    freqs = sqrt(diag(U))/(2*pi);
    bar(freqs(1:5));
    xlabel('Mode');
    ylabel('Tần số (Hz)');
    title('Tần số dao động riêng');
    grid on;
end