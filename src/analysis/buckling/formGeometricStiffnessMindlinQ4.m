function [KG] = formGeometricStiffnessMindlinQ4(GDof, numberElements, elementNodes, numberNodes, nodeCoordinates, sigmaMatrix, thickness)
% Tính ma trận độ cứng hình học cho phân tích ổn định tấm Mindlin
% Đầu vào:
%   GDof             - Số bậc tự do toàn cục
%   numberElements   - Số phần tử
%   elementNodes     - Ma trận liên kết phần tử [elem_id, node1, node2, node3, node4] 
%   numberNodes      - Số nút
%   nodeCoordinates  - Tọa độ các nút [node_id, x, y]
%   sigmaMatrix      - Ma trận ứng suất ban đầu [sigmaX sigmaXY; sigmaXY sigmaY]
%   thickness        - Chiều dày tấm

try
    % Khởi tạo ma trận độ cứng hình học
    KG = sparse(GDof, GDof);

    % Điểm và trọng số Gauss cho phần uốn
    [gaussWeights, gaussLocations] = gaussQuadrature('reduced');

    % Vòng lặp qua từng phần tử
    for e = 1:numberElements
        % Chỉ số nút và bậc tự do của phần tử 
        indice = elementNodes(e,:);
        elementDof = [indice indice+numberNodes indice+2*numberNodes];
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

            % Ma trận G cho phần dọc (từ code gốc)
            G_b = zeros(2, 3*ndof);
            G_b(1,1:ndof) = XYderivatives(:,1)';
            G_b(2,1:ndof) = XYderivatives(:,2)';

            % Cập nhật ma trận độ cứng hình học
            KG(elementDof,elementDof) = KG(elementDof,elementDof) + ...
                G_b'*sigmaMatrix*thickness*G_b*gaussWeights(q)*det(Jacob);
        end
    end

    % Ma trận độ cứng hình học cho phần xoay
    for e = 1:numberElements
        % Chỉ số nút và bậc tự do của phần tử
        indice = elementNodes(e,:);
        elementDof = [indice indice+numberNodes indice+2*numberNodes];
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

            % Ma trận G cho xoay θx (từ code gốc)
            G_s1 = zeros(2, 3*ndof);
            G_s1(1,ndof+1:2*ndof) = XYderivatives(:,1)';
            G_s1(2,ndof+1:2*ndof) = XYderivatives(:,2)';

            % Ma trận G cho xoay θy (từ code gốc) 
            G_s2 = zeros(2, 3*ndof);
            G_s2(1,2*ndof+1:3*ndof) = XYderivatives(:,1)';
            G_s2(2,2*ndof+1:3*ndof) = XYderivatives(:,2)';

            % Cập nhật ma trận độ cứng hình học cho xoay
            KG(elementDof,elementDof) = KG(elementDof,elementDof) + ...
                G_s1'*sigmaMatrix*thickness^3/12*G_s1*gaussWeights(q)*det(Jacob);
            KG(elementDof,elementDof) = KG(elementDof,elementDof) + ...
                G_s2'*sigmaMatrix*thickness^3/12*G_s2*gaussWeights(q)*det(Jacob);
        end
    end

    % Kiểm tra tính đúng đắn của ma trận độ cứng hình học
    validateGeometricStiffness(KG);

catch ME
    error('Lỗi trong tính toán ma trận độ cứng hình học: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra ma trận độ cứng hình học
function validateGeometricStiffness(KG)
    % Kiểm tra tính đối xứng
    if ~issparse(KG)
        KG = sparse(KG);
    end
    if norm(KG - KG',1) / (norm(KG,1) + eps) > 1e-10
        warning('Ma trận độ cứng hình học không đối xứng');
    end
    
    % Kiểm tra điều kiện số
    if condest(KG) > 1e8
        warning('Điều kiện số của ma trận độ cứng hình học lớn');
    end
end