function [Mx, My, Mxy, Qx, Qy] = computeStresses(nodes, elements, U, E, nu, h)
    % computeStresses - Recovers moments and shear forces at Gauss points
    % Inputs:
    %   nodes    - Node coordinates [node_id, x, y]
    %   elements - Element connectivity [elem_id, node1, node2, node3, node4]
    %   U        - Global displacement vector
    %   E        - Young's modulus
    %   nu       - Poisson's ratio
    %   h        - Plate thickness
    % Outputs:
    %   Mx  - Bending moment about x-axis
    %   My  - Bending moment about y-axis
    %   Mxy - Twisting moment
    %   Qx  - Shear force in x-direction
    %   Qy  - Shear force in y-direction
    
    % Material stiffness matrix
    D = (E * h^3) / (12 * (1 - nu^2)) * [1, nu, 0;
                                         nu, 1, 0;
                                         0, 0, (1-nu)/2];
    % Shear stiffness
    G = E / (2 * (1 + nu));
    kappa = 5/6;  % Shear correction factor
    Ds = kappa * G * h;
    
    % Initialize stress arrays
    nElements = size(elements, 1);
    Mx = zeros(nElements, 1);
    My = zeros(nElements, 1);
    Mxy = zeros(nElements, 1);
    Qx = zeros(nElements, 1);
    Qy = zeros(nElements, 1);
    
    % Gauss point coordinates for stress evaluation
    xi = 0;  % Center of element
    eta = 0;
    
    % Loop over elements
    for el = 1:nElements
        nodeIds = elements(el, 2:5);
        
        % Get nodal coordinates
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        
        % Get element displacements
        Ue = zeros(12, 1);
        for i = 1:4
            n = nodeIds(i);
            Ue(3*i-2:3*i) = U(3*n-2:3*n);
        end
        
        % Shape function derivatives at center point
        dNdxi = [-(1-eta)/4, (1-eta)/4, (1+eta)/4, -(1+eta)/4];
        dNdeta = [-(1-xi)/4, -(1+xi)/4, (1+xi)/4, (1-xi)/4];
        
        % Jacobian
        J = [dNdxi*xe, dNdxi*ye;
             dNdeta*xe, dNdeta*ye];
        invJ = inv(J);
        
        % Initialize B matrices
        Bb = zeros(3, 12);  % Bending
        Bs = zeros(2, 12);  % Shear
        
        % Compute B matrices
        for n = 1:4
            dNdx = invJ(1,1)*dNdxi(n) + invJ(1,2)*dNdeta(n);
            dNdy = invJ(2,1)*dNdxi(n) + invJ(2,2)*dNdeta(n);
            idx = 3*(n-1) + 1;
            
            % Bending strain-displacement matrix
            Bb(:, idx:idx+2) = [0, dNdx, 0;
                               0, 0, dNdy;
                               0, dNdy, dNdx];
            
            % Shear strain-displacement matrix
            Bs(:, idx:idx+2) = [dNdx, 1, 0;
                               dNdy, 0, 1];
        end
        
        % Compute curvatures and shear strains
        kappa = Bb * Ue;  % [κx; κy; κxy]
        gamma = Bs * Ue;  % [γxz; γyz]
        
        % Compute moments and shear forces
        moments = D * kappa;
        shears = Ds * gamma;
        
        % Store results
        Mx(el) = moments(1);
        My(el) = moments(2);
        Mxy(el) = moments(3);
        Qx(el) = shears(1);
        Qy(el) = shears(2);
    end
end