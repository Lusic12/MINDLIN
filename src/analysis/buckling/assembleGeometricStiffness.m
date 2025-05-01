function Kg = assembleGeometricStiffness(nodes, elements, Nx)
    % assembleGeometricStiffness - Assembles geometric stiffness matrix for buckling
    % Inputs:
    %   nodes    - Node coordinates [node_id, x, y]
    %   elements - Element connectivity [elem_id, node1, node2, node3, node4]
    %   Nx       - In-plane compressive load in x-direction
    
    nNodes = size(nodes, 1);
    nDOF = 3 * nNodes;
    
    % Initialize global geometric stiffness matrix
    Kg = sparse(nDOF, nDOF);
    
    % Gauss quadrature points and weights
    gp = [-1/sqrt(3), 1/sqrt(3)];
    w = [1, 1];
    
    % Assembly loop over elements
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        
        % Get nodal coordinates
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        
        % Initialize element geometric stiffness
        Kge = zeros(12, 12);
        
        % Loop over Gauss points
        for i = 1:2
            for j = 1:2
                xi = gp(i);
                eta = gp(j);
                
                % Shape function derivatives
                dNdxi = [-(1-eta)/4, (1-eta)/4, (1+eta)/4, -(1+eta)/4];
                dNdeta = [-(1-xi)/4, -(1+xi)/4, (1+xi)/4, (1-xi)/4];
                
                % Jacobian
                J = [dNdxi*xe, dNdxi*ye;
                     dNdeta*xe, dNdeta*ye];
                detJ = det(J);
                invJ = inv(J);
                
                % Compute derivatives of shape functions w.r.t. x and y
                dNdx = zeros(1,4);
                dNdy = zeros(1,4);
                for n = 1:4
                    dNdx(n) = invJ(1,1)*dNdxi(n) + invJ(1,2)*dNdeta(n);
                    dNdy(n) = invJ(2,1)*dNdxi(n) + invJ(2,2)*dNdeta(n);
                end
                
                % Compute geometric stiffness contribution
                for ni = 1:4
                    for nj = 1:4
                        % Indices for DOFs
                        i1 = 3*(ni-1) + 1;
                        i2 = i1 + 2;
                        j1 = 3*(nj-1) + 1;
                        j2 = j1 + 2;
                        
                        % Add contribution to element geometric stiffness
                        Kge(i1:i2,j1:j2) = Kge(i1:i2,j1:j2) + ...
                            Nx * [dNdx(ni)*dNdx(nj), 0, 0;
                                 0, 0, 0;
                                 0, 0, 0] * detJ * w(i) * w(j);
                    end
                end
            end
        end
        
        % Assemble into global geometric stiffness matrix
        dof = zeros(12, 1);
        for i = 1:4
            n = nodeIds(i);
            dof(3*i-2:3*i) = [3*n-2; 3*n-1; 3*n];
        end
        Kg(dof, dof) = Kg(dof, dof) + Kge;
    end
end