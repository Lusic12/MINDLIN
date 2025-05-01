function [K_mod, KG_mod, activeDof] = applyBucklingBoundaryConditions(K, KG, nodes, boundaryConditions)
% Áp đặt điều kiện biên cho bài toán ổn định tấm Mindlin
% Đầu vào:
%   K           - Ma trận độ cứng toàn cục
%   KG          - Ma trận độ cứng hình học toàn cục
%   nodes       - Tọa độ các nút [node_id, x, y]
%   boundaryConditions - Cấu trúc chứa thông tin điều kiện biên
%       .type  - Loại điều kiện biên ('ssss','cccc','scsc','cccf')

try
    % Tính số bậc tự do và số nút
    GDof = size(K,1);
    numberNodes = size(nodes,1);
    
    % Lấy tọa độ các nút
    xx = nodes(:,2);
    yy = nodes(:,3);

    % Xác định các nút bị ràng buộc theo loại điều kiện biên
    switch boundaryConditions.type
        case 'ssss' % Kê đơn giản 4 cạnh
            fixedNodeW = find(xx == max(nodes(:,2)) | ...
                            xx == min(nodes(:,2)) | ...
                            yy == min(nodes(:,3)) | ...
                            yy == max(nodes(:,3)));
            fixedNodeTX = find(yy == max(nodes(:,3)) | ...
                             yy == min(nodes(:,3)));
            fixedNodeTY = find(xx == max(nodes(:,2)) | ...
                             xx == min(nodes(:,2)));
            
        case 'cccc' % Ngàm 4 cạnh
            fixedNodeW = find(xx == max(nodes(:,2)) | ...
                            xx == min(nodes(:,2)) | ...
                            yy == min(nodes(:,3)) | ...
                            yy == max(nodes(:,3)));
            fixedNodeTX = fixedNodeW;
            fixedNodeTY = fixedNodeTX;
            
        case 'scsc' % Ngàm-kê đơn giản xen kẽ
            fixedNodeW = find(xx == max(nodes(:,2)) | ...
                            xx == min(nodes(:,2)) | ...
                            yy == min(nodes(:,3)) | ...
                            yy == max(nodes(:,3)));
            fixedNodeTX = find(xx == max(nodes(:,2)) | ...
                             xx == min(nodes(:,2)));
            fixedNodeTY = [];
            
        case 'cccf' % Ngàm 3 cạnh, tự do 1 cạnh
            fixedNodeW = find(xx == min(nodes(:,2)) | ...
                            yy == min(nodes(:,3)) | ...
                            yy == max(nodes(:,3)));
            fixedNodeTX = fixedNodeW;
            fixedNodeTY = fixedNodeTX;
            
        otherwise
            error('Loại điều kiện biên không hợp lệ');
    end

    % Tổng hợp tất cả các bậc tự do bị ràng buộc
    prescribedDof = [fixedNodeW; 
                     fixedNodeTX + numberNodes;
                     fixedNodeTY + 2*numberNodes];
    
    % Tìm các bậc tự do hoạt động (không bị ràng buộc)
    activeDof = setdiff(1:GDof, prescribedDof);

    % Kiểm tra tính hợp lệ của điều kiện biên
    validateBucklingBoundaryConditions(prescribedDof, GDof);

    % Lọc bỏ các hàng và cột bị ràng buộc khỏi ma trận độ cứng và độ cứng hình học
    K_mod = K(activeDof, activeDof);
    KG_mod = KG(activeDof, activeDof);
    
    % Kiểm tra tính chất của các ma trận sau khi lọc
    validateModifiedMatrices(K_mod, KG_mod);

catch ME
    error('Lỗi trong áp đặt điều kiện biên ổn định: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra tính hợp lệ của điều kiện biên cho bài toán ổn định
function validateBucklingBoundaryConditions(prescribedDof, GDof)
    % Kiểm tra chỉ số bậc tự do
    if any(prescribedDof < 1) || any(prescribedDof > GDof)
        error('Chỉ số bậc tự do bị ràng buộc nằm ngoài phạm vi hợp lệ');
    end
    
    % Kiểm tra tính duy nhất
    if length(unique(prescribedDof)) ~= length(prescribedDof)
        warning('Có bậc tự do bị ràng buộc trùng lặp');
    end
    
    % Kiểm tra số lượng ràng buộc
    if length(prescribedDof) < 3
        warning('Số lượng ràng buộc có thể không đủ để ngăn chuyển động cứng');
    end
    if length(prescribedDof) > GDof/2
        warning('Số lượng ràng buộc có thể quá nhiều, ảnh hưởng đến kết quả ổn định');
    end
end

%................................................................
% Hàm kiểm tra tính chất của các ma trận sau khi lọc
function validateModifiedMatrices(K_mod, KG_mod)
    % Kiểm tra tính đối xứng
    if ~issparse(K_mod)
        K_mod = sparse(K_mod);
    end
    if ~issparse(KG_mod)
        KG_mod = sparse(KG_mod);
    end
    
    if norm(K_mod - K_mod',1) / (norm(K_mod,1) + eps) > 1e-10
        warning('Ma trận độ cứng sau khi lọc không đối xứng');
    end
    if norm(KG_mod - KG_mod',1) / (norm(KG_mod,1) + eps) > 1e-10
        warning('Ma trận độ cứng hình học sau khi lọc không đối xứng');
    end
    
    % Kiểm tra tính xác định dương của ma trận độ cứng
    if any(diag(K_mod) <= 0)
        warning('Ma trận độ cứng sau khi lọc có phần tử đường chéo không dương');
    end
    
    % Kiểm tra điều kiện số
    if condest(K_mod) > 1e8
        warning('Điều kiện số của ma trận độ cứng sau khi lọc lớn');
    end
    if condest(KG_mod) > 1e8
        warning('Điều kiện số của ma trận độ cứng hình học sau khi lọc lớn');
    end
end