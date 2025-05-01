function [K_mod, F_mod] = applyBoundaryConditions(K, F, nodes, boundaryConditions)
% Áp đặt điều kiện biên cho bài toán tĩnh tấm Mindlin
% Đầu vào:
%   K           - Ma trận độ cứng toàn cục
%   F           - Vector tải toàn cục
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
    validateBoundaryConditions(prescribedDof, GDof);

    % Áp dụng điều kiện biên bằng cách điều chỉnh ma trận và vector
    K_mod = K;
    F_mod = F;
    
    % Đặt các hàng và cột tương ứng với DOF bị ràng buộc về 0
    K_mod(prescribedDof,:) = 0;
    K_mod(:,prescribedDof) = 0;
    
    % Đặt 1 trên đường chéo để đảm bảo điều kiện xác định
    for i = 1:length(prescribedDof)
        K_mod(prescribedDof(i),prescribedDof(i)) = 1;
    end
    
    % Điều chỉnh vector tải
    F_mod(prescribedDof) = 0;

catch ME
    error('Lỗi trong áp đặt điều kiện biên: %s', ME.message);
end
end

%................................................................
% Hàm kiểm tra tính hợp lệ của điều kiện biên
function validateBoundaryConditions(prescribedDof, GDof)
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
        warning('Số lượng ràng buộc có thể quá nhiều');
    end
end