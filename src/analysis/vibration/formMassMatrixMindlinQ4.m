function [mass] = formMassMatrixMindlinQ4(GDof, numberElements, elementNodes, numberNodes, nodeCoordinates, thickness, rho, I)
% Tính ma trận khối lượng cho phân tích dao động tấm Mindlin
% Đầu vào:
%   GDof             - Số bậc tự do toàn cục
%   numberElements   - Số phần tử
%   elementNodes     - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4]
%   numberNodes      - Số nút
%   nodeCoordinates  - Tọa độ các nút [node_id, x, y]
%   thickness        - Chiều dày tấm
%   rho             - Khối lượng riêng
%   I               - Moment quán tính

try
    % Initialize progress
    h = waitbar(0, 'Assembling mass matrix...');

    % Use sparse matrix for better performance
    mass = spalloc(GDof, GDof, 20*numberElements);

    % Pre-allocate matrices
    Me = zeros(12,12);
    dof = zeros(12,1);

    % Điểm và trọng số Gauss cho tích phân đầy đủ
    [gaussWeights, gaussLocations] = gaussQuadrature('complete');

    % Vòng lặp qua từng phần tử
    for e = 1:numberElements
        waitbar(e/numberElements, h);

        % Chỉ số nút của phần tử
        indice = elementNodes(e,:);
        ndof = length(indice);

        % Tích phân Gauss
        for q = 1:size(gaussWeights,1)
            GaussPoint = gaussLocations(q,:);
            xi = GaussPoint(1);
            eta = GaussPoint(2);

            % Hàm dạng và đạo hàm
            [shapeFunction, naturalDerivatives] = shapeFunctionQ4(xi, eta);

            % Ma trận Jacobi và đạo hàm
            [Jacob, invJacobian, XYderivatives] = ...
                Jacobian(nodeCoordinates(indice,:), naturalDerivatives);

            % Ma trận khối lượng cho chuyển vị dọc (từ code gốc)
            Me(1:4,1:4) = Me(1:4,1:4) + ...
                shapeFunction*shapeFunction'*thickness*rho*...
                gaussWeights(q)*det(Jacob);

            % Ma trận khối lượng cho xoay θx
            Me(5:8,5:8) = Me(5:8,5:8) + ...
                shapeFunction*shapeFunction'*I*rho*...
                gaussWeights(q)*det(Jacob);

            % Ma trận khối lượng cho xoay θy
            Me(9:12,9:12) = Me(9:12,9:12) + ...
                shapeFunction*shapeFunction'*I*rho*...
                gaussWeights(q)*det(Jacob);
        end

        % Add lumped mass option
        if useLumpedMass
            Me = diagLumpMassMatrix(Me);
        end

        % Assembly using sparse indexing
        dof = computeDofIndices(elementNodes(e,:), numberNodes);
        mass = assembleElementMatrix(mass, Me, dof);
    end

    close(h);

    % Kiểm tra tính đúng đắn của ma trận khối lượng
    validateMassMatrix(mass);

catch ME
    if exist('h','var'), close(h); end
    error('Lỗi trong tính toán ma trận khối lượng: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra ma trận khối lượng
function validateMassMatrix(mass)
    % Kiểm tra tính đối xứng
    if ~issparse(mass)
        mass = sparse(mass);
    end
    if norm(mass - mass',1) / (norm(mass,1) + eps) > 1e-10
        warning('Ma trận khối lượng không đối xứng');
    end
    
    % Kiểm tra các phần tử không âm
    if any(diag(mass) < 0)
        warning('Ma trận khối lượng có phần tử đường chéo âm');
    end
    
    % Kiểm tra điều kiện số
    if condest(mass) > 1e8
        warning('Điều kiện số của ma trận khối lượng lớn');
    end
end

%................................................................
% Hàm tạo ma trận khối lượng dạng chéo
function M = diagLumpMassMatrix(M)
    % Row-sum lumping technique
    for i = 1:size(M,1)
        rowSum = sum(M(i,:));
        M(i,:) = 0;
        M(i,i) = rowSum;
    end
end