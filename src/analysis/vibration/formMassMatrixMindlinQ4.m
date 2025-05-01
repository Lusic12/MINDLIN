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
    % Khởi tạo ma trận khối lượng
    mass = sparse(GDof, GDof);

    % Điểm và trọng số Gauss cho tích phân đầy đủ
    [gaussWeights, gaussLocations] = gaussQuadrature('complete');

    % Vòng lặp qua từng phần tử
    for e = 1:numberElements
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
            mass(indice,indice) = mass(indice,indice) + ...
                shapeFunction*shapeFunction'*thickness*rho*...
                gaussWeights(q)*det(Jacob);

            % Ma trận khối lượng cho xoay θx
            mass(indice+numberNodes,indice+numberNodes) = ...
                mass(indice+numberNodes,indice+numberNodes) + ...
                shapeFunction*shapeFunction'*I*rho*...
                gaussWeights(q)*det(Jacob);

            % Ma trận khối lượng cho xoay θy
            mass(indice+2*numberNodes,indice+2*numberNodes) = ...
                mass(indice+2*numberNodes,indice+2*numberNodes) + ...
                shapeFunction*shapeFunction'*I*rho*...
                gaussWeights(q)*det(Jacob);
        end
    end

    % Kiểm tra tính đúng đắn của ma trận khối lượng
    validateMassMatrix(mass);

catch ME
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