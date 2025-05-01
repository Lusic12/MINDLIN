function [K, F] = assembleSystem(nodes, elements, E, nu, h, q, varargin)
    % assembleSystem - Assembles global stiffness matrix and load vector
    % Inputs:
    %   nodes    - Node coordinates [node_id, x, y]
    %   elements - Element connectivity [elem_id, node1, node2, node3, node4]
    %   E        - Young's modulus
    %   nu       - Poisson's ratio
    %   h        - Plate thickness
    %   q        - Distributed load
    % Optional inputs:
    %   dT       - Temperature change across thickness
    %   alpha    - Thermal expansion coefficient
    
    % Parse optional thermal inputs
    p = inputParser;
    addOptional(p, 'dT', 0);
    addOptional(p, 'alpha', 0);
    parse(p, varargin{:});
    
    nNodes = size(nodes, 1);
    nDOF = 3 * nNodes;
    
    % Initialize global matrices
    K = sparse(nDOF, nDOF);
    F = zeros(nDOF, 1);
    
    % Material stiffness matrix
    D = (E * h^3) / (12 * (1 - nu^2)) * [1, nu, 0;
                                         nu, 1, 0;
                                         0, 0, (1-nu)/2];
    
    % Assembly loop over elements
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        
        % Get nodal coordinates
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        
        % Calculate element matrices with thermal effects if specified
        if p.Results.dT ~= 0
            [Ke, Fe] = elementStiffness(xe, ye, D, h, q, 'dT', p.Results.dT, ...
                                      'alpha', p.Results.alpha);
        else
            [Ke, Fe] = elementStiffness(xe, ye, D, h, q);
        end
        
        % Global DOF indices for this element
        dof = zeros(12, 1);
        for i = 1:4
            n = nodeIds(i);
            dof(3*i-2:3*i) = [3*n-2; 3*n-1; 3*n];
        end
        
        % Assemble into global system
        K(dof, dof) = K(dof, dof) + Ke;
        F(dof) = F(dof) + Fe;
    end
end