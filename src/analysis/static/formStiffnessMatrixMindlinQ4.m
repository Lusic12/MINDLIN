function [K] = formStiffnessMatrixMindlinQ4(GDof, numberElements, elementNodes, numberNodes, nodeCoordinates, C_shear, C_bending, thickness, I)
% Lắp ráp ma trận độ cứng toàn cục cho tấm Mindlin
% Đầu vào:
%   GDof             - Số bậc tự do toàn cục
%   numberElements   - Số phần tử
%   elementNodes     - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   numberNodes      - Số nút
%   nodeCoordinates  - Tọa độ các nút [node_id, x, y]
%   C_shear         - Ma trận độ cứng cắt
%   C_bending       - Ma trận độ cứng uốn
%   thickness       - Chiều dày tấm
%   I               - Moment quán tính

% Add input validation
validateattributes(thickness, {'numeric'}, {'positive', 'scalar'});
validateattributes(I, {'numeric'}, {'positive', 'scalar'});

try
    % Initialize progress tracking
    h = waitbar(0, 'Assembling stiffness matrix...'); 

    % Khởi tạo ma trận độ cứng toàn cục
    K = sparse(GDof, GDof);

    % Điểm và trọng số Gauss cho phần uốn
    [gaussWeights, gaussLocations] = gaussQuadrature('complete');

    % Vòng lặp qua từng phần tử
    for e = 1:numberElements       
        % Chỉ số nút và bậc tự do của phần tử
        indice = elementNodes(e,:);
        elementDof = [indice indice+numberNodes indice+2*numberNodes];
        ndof = length(indice);
        
        % Lấy tọa độ nút của phần tử
        xe = nodeCoordinates(indice,1);
        ye = nodeCoordinates(indice,2);

        % Tích phân Gauss cho phần uốn
        for q = 1:size(gaussWeights,1)
            GaussPoint = gaussLocations(q,:);
            xi = GaussPoint(1);
            eta = GaussPoint(2);

            % Hàm dạng và đạo hàm
            [shapeFunction, naturalDerivatives] = shapeFunctionQ4(xi, eta);

            % Ma trận Jacobi và đạo hàm
            [Jacob, invJacobian, XYderivatives] = ...
                Jacobian(nodeCoordinates(indice,:), naturalDerivatives);

            % Ma trận B cho uốn (từ code gốc)
            B_b = zeros(3, 3*ndof);
            B_b(1,ndof+1:2*ndof) = XYderivatives(:,1)';
            B_b(2,2*ndof+1:3*ndof) = XYderivatives(:,2)';
            B_b(3,ndof+1:2*ndof) = XYderivatives(:,2)';
            B_b(3,2*ndof+1:3*ndof) = XYderivatives(:,1)';

            % Cập nhật ma trận độ cứng uốn
            K(elementDof,elementDof) = K(elementDof,elementDof) + ...
                B_b'*C_bending*B_b*gaussWeights(q)*det(Jacob);
        end
    end

    % Tích phân Gauss cho phần cắt (sử dụng tích phân suy giảm)
    [gaussWeights, gaussLocations] = gaussQuadrature('reduced');

    % Vòng lặp qua từng phần tử cho phần cắt
    for e = 1:numberElements
        % Chỉ số nút và bậc tự do của phần tử
        indice = elementNodes(e,:);
        elementDof = [indice indice+numberNodes indice+2*numberNodes];
        ndof = length(indice);

        % Tích phân Gauss cho phần cắt
        for q = 1:size(gaussWeights,1)
            GaussPoint = gaussLocations(q,:);
            xi = GaussPoint(1);
            eta = GaussPoint(2);

            % Hàm dạng và đạo hàm
            [shapeFunction, naturalDerivatives] = shapeFunctionQ4(xi, eta);

            % Ma trận Jacobi và đạo hàm
            [Jacob, invJacobian, XYderivatives] = ...
                Jacobian(nodeCoordinates(indice,:), naturalDerivatives);

            % Ma trận B cho cắt (từ code gốc)
            B_s = zeros(2, 3*ndof);
            B_s(1,1:ndof) = XYderivatives(:,1)';
            B_s(2,1:ndof) = XYderivatives(:,2)';
            B_s(1,ndof+1:2*ndof) = shapeFunction';
            B_s(2,2*ndof+1:3*ndof) = shapeFunction';

            % Cập nhật ma trận độ cứng cắt
            K(elementDof,elementDof) = K(elementDof,elementDof) + ...
                B_s'*C_shear*B_s*gaussWeights(q)*det(Jacob);
        end
    end

    % Add mesh quality check
    for e = 1:numberElements
        aspectRatio = computeElementAspectRatio(nodeCoordinates(elementNodes(e,:),:));
        if aspectRatio > 5
            warning('Element %d has high aspect ratio: %.2f', e, aspectRatio);
        end
    end

    % Add matrix condition check 
    condK = condest(K);
    if condK > 1e8
        warning('Stiffness matrix poorly conditioned: %.2e', condK);
    end

    % Kiểm tra tính đúng đắn của ma trận độ cứng toàn cục
    validateStiffnessMatrix(K);

    close(h);
catch ME
    if exist('h', 'var'), close(h); end
    error('Lỗi trong lắp ráp ma trận độ cứng: %s', ME.message);
end
end

function ratio = computeElementAspectRatio(nodes)
    % Compute element aspect ratio
    edges = [norm(nodes(2,:) - nodes(1,:));
             norm(nodes(3,:) - nodes(2,:));
             norm(nodes(4,:) - nodes(3,:));
             norm(nodes(1,:) - nodes(4,:))];
    ratio = max(edges)/min(edges);
end

%................................................................
% Hàm kiểm tra ma trận độ cứng
function validateStiffnessMatrix(K)
    % Kiểm tra tính đối xứng
    if ~issparse(K)
        K = sparse(K);
    end
    if norm(K - K',1) / (norm(K,1) + eps) > 1e-10
        warning('Ma trận độ cứng toàn cục không đối xứng');
    end

    % Kiểm tra các phần tử đường chéo
    if any(diag(K) <= 0)
        warning('Có phần tử đường chéo không dương trong ma trận độ cứng');
    end

    % Kiểm tra điều kiện số
    if condest(K) > 1e8
        warning('Điều kiện số của ma trận độ cứng lớn, có thể gặp vấn đề về độ ổn định số');
    end
end