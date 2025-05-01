function [K_mod, F_mod] = applyBoundaryConditions(K, F, nodes, bcString)
    % applyBoundaryConditions - Applies boundary conditions for static analysis
    % Inputs:
    %   K        - Stiffness matrix
    %   F        - Force vector
    %   nodes    - Node coordinates [node_id, x, y]
    %   bcString - Four-character string specifying boundary conditions
    %             for Left, Right, Top, Bottom edges (e.g., 'SSSS', 'CFSC')
    
    % Find nodes on each edge
    tol = 1e-6;
    xmin = min(nodes(:,2));
    xmax = max(nodes(:,2));
    ymin = min(nodes(:,3));
    ymax = max(nodes(:,3));
    
    % Get nodes on each edge
    leftNodes = find(abs(nodes(:,2) - xmin) < tol);
    rightNodes = find(abs(nodes(:,2) - xmax) < tol);
    bottomNodes = find(abs(nodes(:,3) - ymin) < tol);
    topNodes = find(abs(nodes(:,3) - ymax) < tol);
    
    % Initialize constrained DOFs
    constrainedDOFs = [];
    
    % Process each edge
    edges = {leftNodes, rightNodes, topNodes, bottomNodes};
    for i = 1:4
        switch bcString(i)
            case 'C'  % Clamped
                % Constrain all DOFs (w, θx, θy)
                for node = edges{i}
                    constrainedDOFs = [constrainedDOFs; 
                                     3*node-2;  % w
                                     3*node-1;  % θx
                                     3*node];   % θy
                end
            case 'S'  % Simply supported
                % Constrain only displacement (w)
                for node = edges{i}
                    constrainedDOFs = [constrainedDOFs; 
                                     3*node-2]; % w only
                end
            case 'F'  % Free
                % No constraints
                continue
        end
    end
    
    % Remove duplicates (nodes at corners)
    constrainedDOFs = unique(constrainedDOFs);
    
    % Apply constraints using the penalty method
    K_mod = K;
    F_mod = F;
    penalty = 1e15;
    
    for i = 1:length(constrainedDOFs)
        dof = constrainedDOFs(i);
        K_mod(dof,dof) = K_mod(dof,dof) + penalty;
        F_mod(dof) = 0;
    end
end