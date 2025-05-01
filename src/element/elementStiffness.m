function [Ke, Fe] = elementStiffness(xe, ye, D, h, q)
    % elementStiffness - Calculates element stiffness matrix and load vector
    % Inputs:
    %   xe - x coordinates of element nodes
    %   ye - y coordinates of element nodes
    %   D  - Material stiffness matrix
    %   h  - Plate thickness
    %   q  - Distributed load
    
    % Material properties for shear
    G = D(3,3) * 2 * (1 + D(1,2)/D(1,1));  % Shear modulus
    kappa = 5/6;  % Shear correction factor
    
    % Gauss quadrature points and weights
    gp = [-1/sqrt(3), 1/sqrt(3)];
    w = [1, 1];
    
    % Initialize element matrices
    Ke = zeros(12, 12);
    Fe = zeros(12, 1);
    
    % Loop over Gauss points
    for i = 1:2
        for j = 1:2
            xi = gp(i);
            eta = gp(j);
            
            % Shape functions and derivatives
            N = [(1-xi)*(1-eta)/4, (1+xi)*(1-eta)/4, (1+xi)*(1+eta)/4, (1-xi)*(1+eta)/4];
            dNdxi = [-(1-eta)/4, (1-eta)/4, (1+eta)/4, -(1+eta)/4];
            dNdeta = [-(1-xi)/4, -(1+xi)/4, (1+xi)/4, (1-xi)/4];
            
            % Jacobian matrix
            J = [dNdxi*xe, dNdxi*ye;
                 dNdeta*xe, dNdeta*ye];
            detJ = det(J);
            invJ = inv(J);
            
            % B matrices for bending and shear
            Bb = zeros(3, 12);  % Bending
            Bs = zeros(2, 12);  % Shear
            
            for n = 1:4
                dNdx = invJ(1,1)*dNdxi(n) + invJ(1,2)*dNdeta(n);
                dNdy = invJ(2,1)*dNdxi(n) + invJ(2,2)*dNdeta(n);
                idx = 3*(n-1) + 1;
                
                % Bending strain-displacement matrix
                Bb(:, idx:idx+2) = [0, dNdx, 0;
                                   0, 0, dNdy;
                                   0, dNdy, dNdx];
                                   
                % Shear strain-displacement matrix
                Bs(:, idx:idx+2) = [dNdx, N(n), 0;
                                   dNdy, 0, N(n)];
            end
            
            % Element stiffness contributions
            Ke = Ke + (Bb'*D*Bb + kappa*G*h*Bs'*Bs)*detJ*w(i)*w(j);
            
            % Element load vector contribution
            for n = 1:4
                idx = 3*(n-1) + 1;
                Fe(idx) = Fe(idx) + N(n)*q*detJ*w(i)*w(j);
            end
        end
    end
end