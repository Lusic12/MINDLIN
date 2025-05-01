function [Ke, Fe] = elementStiffness(xe, ye, D, h, q, varargin)
    % elementStiffness - Calculates element stiffness matrix and load vector
    % Inputs:
    %   xe - x coordinates of element nodes
    %   ye - y coordinates of element nodes
    %   D  - Material stiffness matrix
    %   h  - Plate thickness
    %   q  - Distributed load
    % Optional inputs:
    %   dT - Temperature change across thickness
    %   alpha - Thermal expansion coefficient
    
    % Parse optional thermal inputs
    p = inputParser;
    addOptional(p, 'dT', 0);
    addOptional(p, 'alpha', 0);
    parse(p, varargin{:});
    dT = p.Results.dT;
    alpha = p.Results.alpha;

    % Material properties for shear
    G = D(3,3) * 2 * (1 + D(1,2)/D(1,1));  % Shear modulus
    kappa = 5/6;  % Shear correction factor
    
    % Higher-order Gauss quadrature (3x3) for better accuracy
    gp = [-sqrt(0.6), 0, sqrt(0.6)];
    w = [5/9, 8/9, 5/9];
    
    % Initialize element matrices
    Ke = zeros(12, 12);
    Fe = zeros(12, 1);
    
    % Add thermal load vector if temperature change exists
    if dT ~= 0
        MT = -D(1,1)*alpha*dT*h^2/(1-D(1,2));  % Thermal moment
        FT = zeros(12, 1);
    end

    % Loop over Gauss points
    for i = 1:3
        for j = 1:3
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
                                   
                % Modified shear strain-displacement matrix with assumed strain field
                % This helps prevent shear locking
                Bs(:, idx:idx+2) = [dNdx, N(n)*(1-xi^2), 0;
                                   dNdy, 0, N(n)*(1-eta^2)];
            end
            
            % Selective reduced integration for shear terms to prevent locking
            if i == 2 && j == 2  % Center point
                shearWeight = 4;  % Increased weight for center point
            else
                shearWeight = 1;
            end
            
            % Element stiffness contributions
            Ke = Ke + (Bb'*D*Bb + kappa*G*h*Bs'*Bs/shearWeight)*detJ*w(i)*w(j);
            
            % Element load vector contributions
            for n = 1:4
                idx = 3*(n-1) + 1;
                Fe(idx) = Fe(idx) + N(n)*q*detJ*w(i)*w(j);
                
                if dT ~= 0
                    % Add thermal load contribution
                    FT(idx+1:idx+2) = FT(idx+1:idx+2) + ...
                        MT*[dNdx; dNdy]*detJ*w(i)*w(j);
                end
            end
        end
    end
    
    % Add thermal loads to force vector
    if dT ~= 0
        Fe = Fe + FT;
    end
    
    % Add stabilization term to prevent zero-energy modes
    alpha = 1e-6 * trace(Ke)/12;  % Small stabilization factor
    Ke = Ke + alpha * eye(12);
end