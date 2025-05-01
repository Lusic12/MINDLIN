function [nodes, elements] = generateMesh(L, W, nx, ny)
    % generateMesh - Creates a rectangular mesh for plate analysis
    % Inputs:
    %   L  - Length in x-direction
    %   W  - Width in y-direction
    %   nx - Number of elements in x-direction
    %   ny - Number of elements in y-direction
    % Outputs:
    %   nodes    - Node coordinates [node_id, x, y]
    %   elements - Element connectivity [elem_id, node1, node2, node3, node4]
    
    % Generate node coordinates
    x = linspace(0, L, nx+1);
    y = linspace(0, W, ny+1);
    [X, Y] = meshgrid(x, y);
    
    nodes = zeros((nx+1)*(ny+1), 3);
    nodes(:,1) = 1:size(nodes,1);  % Node ID
    nodes(:,2) = X(:);             % X coordinates
    nodes(:,3) = Y(:);             % Y coordinates
    
    % Generate element connectivity
    elements = zeros(nx*ny, 5);
    elem = 1;
    for j = 1:ny
        for i = 1:nx
            n1 = i + (j-1)*(nx+1);
            n2 = n1 + 1;
            n3 = n2 + (nx+1);
            n4 = n1 + (nx+1);
            elements(elem,:) = [elem, n1, n2, n3, n4];
            elem = elem + 1;
        end
    end
end