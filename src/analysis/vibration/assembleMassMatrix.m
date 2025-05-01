function M = assembleMassMatrix(nodes, elements, rho, h)
    % assembleMassMatrix - Assembles global mass matrix for vibration analysis
    % Inputs:
    %   nodes    - Node coordinates [node_id, x, y]
    %   elements - Element connectivity [elem_id, node1, node2, node3, node4]
    %   rho      - Material density
    %   h        - Plate thickness
    
    nNodes = size(nodes, 1);
    nDOF = 3 * nNodes;
    
    % Initialize global mass matrix
    M = sparse(nDOF, nDOF);
    
    % Gauss quadrature points and weights
    gp = [-1/sqrt(3), 1/sqrt(3)];
    w = [1, 1];
    
    % Rotary inertia factor
    I = h^3/12;
    
    % Assembly loop over elements
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        
        % Get nodal coordinates
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        
        % Initialize element mass matrix
        Me = zeros(12, 12);
        
        % Loop over Gauss points
        for i = 1:2
            for j = 1:2
                xi = gp(i);
                eta = gp(j);
                
                % Shape functions
                N = [(1-xi)*(1-eta)/4, (1+xi)*(1-eta)/4, (1+xi)*(1+eta)/4, (1-xi)*(1+eta)/4];
                
                % Jacobian
                dNdxi = [-(1-eta)/4, (1-eta)/4, (1+eta)/4, -(1+eta)/4];
                dNdeta = [-(1-xi)/4, -(1+xi)/4, (1+xi)/4, (1-xi)/4];
                J = [dNdxi*xe, dNdxi*ye;
                     dNdeta*xe, dNdeta*ye];
                detJ = det(J);
                
                % Mass matrix contributions
                for ni = 1:4
                    for nj = 1:4
                        % Indices for DOFs
                        i1 = 3*(ni-1) + 1;
                        j1 = 3*(nj-1) + 1;
                        
                        % Translational mass terms
                        Me(i1,j1) = Me(i1,j1) + rho*h*N(ni)*N(nj)*detJ*w(i)*w(j);
                        
                        % Rotational mass terms (including rotary inertia)
                        Me(i1+1:i1+2,j1+1:j1+2) = Me(i1+1:i1+2,j1+1:j1+2) + ...
                            rho*I*eye(2)*N(ni)*N(nj)*detJ*w(i)*w(j);
                    end
                end
            end
        end
        
        % Assemble into global mass matrix
        dof = zeros(12, 1);
        for i = 1:4
            n = nodeIds(i);
            dof(3*i-2:3*i) = [3*n-2; 3*n-1; 3*n];
        end
        M(dof, dof) = M(dof, dof) + Me;
    end
end