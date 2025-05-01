function [K, F] = assembleSystem(nodes, elements, E, nu, h, q, varargin)
    % Lắp ráp ma trận độ cứng và vector tải toàn cục
    % Đầu vào:
    %   nodes    - Tọa độ các nút [node_id, x, y]
    %   elements - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
    %   E        - Mô đun Young
    %   nu       - Hệ số Poisson
    %   h        - Chiều dày tấm
    %   q        - Tải phân bố
    % Đầu vào tùy chọn:
    %   dT       - Chênh lệch nhiệt độ
    %   alpha    - Hệ số giãn nở nhiệt
    
    try
        % Kiểm tra đầu vào
        validateInput(nodes, elements, E, nu, h, q);
        
        % Xử lý đầu vào nhiệt
        p = inputParser;
        addOptional(p, 'dT', 0);
        addOptional(p, 'alpha', 0);
        parse(p, varargin{:});
        
        nNodes = size(nodes, 1);
        nDOF = 3 * nNodes;
        
        % Khởi tạo ma trận toàn cục
        K = sparse(nDOF, nDOF);
        F = zeros(nDOF, 1);
        
        % Ma trận độ cứng vật liệu
        D = (E * h^3) / (12 * (1 - nu^2)) * [1, nu, 0;
                                             nu, 1, 0;
                                             0, 0, (1-nu)/2];
        
        % Vòng lặp qua từng phần tử
        for el = 1:size(elements, 1)
            nodeIds = elements(el, 2:5);
            
            % Kiểm tra chỉ số nút
            if any(nodeIds > nNodes)
                warning('Phần tử %d có chỉ số nút không hợp lệ, bỏ qua...', el);
                continue;
            end
            
            % Lấy tọa độ các nút
            xe = nodes(nodeIds, 2);
            ye = nodes(nodeIds, 3);
            
            % Tính ma trận độ cứng phần tử và vector tải với hiệu ứng nhiệt nếu có
            if p.Results.dT ~= 0
                [Ke, Fe] = elementStiffness(xe, ye, D, h, q, 'dT', p.Results.dT, ...
                                          'alpha', p.Results.alpha);
            else
                [Ke, Fe] = elementStiffness(xe, ye, D, h, q);
            end
            
            % Tạo vector chỉ số bậc tự do toàn cục
            dof = zeros(12, 1);
            for i = 1:4
                n = nodeIds(i);
                dof(3*i-2:3*i) = [3*n-2; 3*n-1; 3*n];
            end
            
            % Lắp ráp vào hệ toàn cục
            try
                K(dof, dof) = K(dof, dof) + Ke;
                F(dof) = F(dof) + Fe;
            catch ME
                warning('Lỗi khi lắp ráp phần tử %d: %s', el, ME.message);
                continue;
            end
        end
        
        % Kiểm tra tính đúng đắn của ma trận độ cứng
        validateStiffnessMatrix(K);
        
    catch ME
        error('Lỗi trong quá trình lắp ráp hệ: %s', ME.message);
    end
end

function validateInput(nodes, elements, E, nu, h, q)
    % Kiểm tra kích thước ma trận
    if size(nodes, 2) ~= 3
        error('Ma trận nodes phải có 3 cột [node_id, x, y]');
    end
    if size(elements, 2) ~= 5
        error('Ma trận elements phải có 5 cột [elem_id, node1, node2, node3, node4]');
    end
    
    % Kiểm tra các thông số vật liệu
    if E <= 0
        error('Mô đun Young phải dương');
    end
    if nu < -1 || nu > 0.5
        error('Hệ số Poisson phải nằm trong khoảng [-1, 0.5]');
    end
    if h <= 0
        error('Chiều dày tấm phải dương');
    end
    
    % Kiểm tra chỉ số nút
    if any(any(elements(:,2:5) > size(nodes,1)))
        error('Phát hiện chỉ số nút không hợp lệ trong ma trận elements');
    end
    if any(any(elements(:,2:5) < 1))
        error('Phát hiện chỉ số nút âm trong ma trận elements');
    end
    
    % Kiểm tra tính duy nhất của ID nút
    if length(unique(nodes(:,1))) ~= size(nodes,1)
        error('ID nút phải duy nhất');
    end
end

function validateStiffnessMatrix(K)
    % Kiểm tra tính đối xứng
    if ~issymmetric(K)
        warning('Ma trận độ cứng không đối xứng');
    end
    
    % Kiểm tra các phần tử đường chéo
    if any(diag(K) <= 0)
        warning('Phát hiện phần tử đường chéo không dương trong ma trận độ cứng');
    end
end