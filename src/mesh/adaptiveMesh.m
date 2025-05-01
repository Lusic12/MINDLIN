function [nodes_new, elements_new] = adaptiveMesh(nodes, elements, U, E, nu, h, errorTol)
    % adaptiveMesh - Performs adaptive mesh refinement based on error estimates
    % Inputs:
    %   nodes     - Node coordinates [node_id, x, y]
    %   elements  - Element connectivity [elem_id, node1, node2, node3, node4]
    %   U         - Global displacement vector
    %   E         - Young's modulus
    %   nu        - Poisson's ratio
    %   h         - Plate thickness
    %   errorTol  - Relative error tolerance for refinement
    
    % Compute element error indicators
    [elementErrors, avgError] = computeElementErrors(nodes, elements, U, E, nu, h);
    
    % Mark elements for refinement
    elementsToRefine = find(elementErrors > errorTol * avgError);
    
    if isempty(elementsToRefine)
        nodes_new = nodes;
        elements_new = elements;
        return;
    end
    
    % Initialize new mesh arrays
    nNodes = size(nodes, 1);
    nElements = size(elements, 1);
    newNodes = nodes;
    newElements = [];
    
    % Edge midpoint map to avoid duplicate nodes
    edgeMidpoints = containers.Map('KeyType', 'char', 'ValueType', 'double');
    
    % Process each element
    nextNodeId = nNodes + 1;
    nextElemId = 1;
    
    for el = 1:nElements
        if ismember(el, elementsToRefine)
            % Get element nodes
            nodeIds = elements(el, 2:5);
            
            % Create midpoint nodes if they don't exist
            midNodes = zeros(4, 1);
            for i = 1:4
                n1 = nodeIds(i);
                n2 = nodeIds(mod(i,4) + 1);
                edgeKey = sprintf('%d_%d', min(n1,n2), max(n1,n2));
                
                if ~isKey(edgeMidpoints, edgeKey)
                    % Create new midpoint node
                    x1 = nodes(n1, 2); y1 = nodes(n1, 3);
                    x2 = nodes(n2, 2); y2 = nodes(n2, 3);
                    newNodes(nextNodeId,:) = [nextNodeId, (x1+x2)/2, (y1+y2)/2];
                    edgeMidpoints(edgeKey) = nextNodeId;
                    midNodes(i) = nextNodeId;
                    nextNodeId = nextNodeId + 1;
                else
                    midNodes(i) = edgeMidpoints(edgeKey);
                end
            end
            
            % Create center node
            centerX = mean(nodes(nodeIds, 2));
            centerY = mean(nodes(nodeIds, 3));
            newNodes(nextNodeId,:) = [nextNodeId, centerX, centerY];
            centerNode = nextNodeId;
            nextNodeId = nextNodeId + 1;
            
            % Create four new elements
            % Element 1: bottom-left
            newElements(nextElemId,:) = [nextElemId, nodeIds(1), midNodes(1), centerNode, midNodes(4)];
            nextElemId = nextElemId + 1;
            
            % Element 2: bottom-right
            newElements(nextElemId,:) = [nextElemId, midNodes(1), nodeIds(2), midNodes(2), centerNode];
            nextElemId = nextElemId + 1;
            
            % Element 3: top-right
            newElements(nextElemId,:) = [nextElemId, centerNode, midNodes(2), nodeIds(3), midNodes(3)];
            nextElemId = nextElemId + 1;
            
            % Element 4: top-left
            newElements(nextElemId,:) = [nextElemId, midNodes(4), centerNode, midNodes(3), nodeIds(4)];
            nextElemId = nextElemId + 1;
            
        else
            % Keep original element
            newElements(nextElemId,:) = [nextElemId, elements(el, 2:5)];
            nextElemId = nextElemId + 1;
        end
    end
    
    % Return refined mesh
    nodes_new = newNodes;
    elements_new = newElements;
end

function [elementErrors, avgError] = computeElementErrors(nodes, elements, U, E, nu, h)
    % Compute element error indicators based on moment jumps
    
    % Get stress resultants
    [Mx, My, Mxy, ~, ~] = computeStresses(nodes, elements, U, E, nu, h);
    
    nElements = size(elements, 1);
    elementErrors = zeros(nElements, 1);
    
    % Element patch assembly
    for el = 1:nElements
        % Get neighboring elements
        neighbors = findNeighbors(elements, el);
        
        % Compute moment jumps across edges
        jumpMx = 0;
        jumpMy = 0;
        jumpMxy = 0;
        
        for nb = neighbors
            if nb > 0
                jumpMx = jumpMx + (Mx(el) - Mx(nb))^2;
                jumpMy = jumpMy + (My(el) - My(nb))^2;
                jumpMxy = jumpMxy + (Mxy(el) - Mxy(nb))^2;
            end
        end
        
        % Compute error indicator
        elementErrors(el) = sqrt(jumpMx + jumpMy + jumpMxy);
    end
    
    % Compute average error
    avgError = mean(elementErrors);
end

function neighbors = findNeighbors(elements, elementId)
    % Find neighboring elements sharing nodes
    nodeList = elements(elementId, 2:5);
    neighbors = [];
    
    for el = 1:size(elements,1)
        if el ~= elementId
            % Check if elements share at least 2 nodes
            sharedNodes = intersect(nodeList, elements(el, 2:5));
            if length(sharedNodes) >= 2
                neighbors = [neighbors, el];
            end
        end
    end
end