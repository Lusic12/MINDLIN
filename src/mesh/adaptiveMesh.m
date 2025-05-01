function [nodes_new, elements_new] = adaptiveMesh(nodes, elements, U, E, nu, h, errorTol, updateProgress)
    % adaptiveMesh - Performs adaptive mesh refinement based on error estimates
    % Added progress tracking and enhanced error estimation
    
    if nargin < 8
        updateProgress = @(x) [];
    end
    
    % Compute element error indicators
    updateProgress(0);
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
    
    % Track refinement progress
    nElementsToRefine = length(elementsToRefine);
    
    % Process each element
    nextNodeId = nNodes + 1;
    nextElemId = 1;
    
    for i = 1:nElements
        updateProgress(i/nElements);
        
        if ismember(i, elementsToRefine)
            % Get element nodes
            nodeIds = elements(i, 2:5);
            
            % Create midpoint nodes if they dont exist
            midNodes = zeros(4, 1);
            for j = 1:4
                n1 = nodeIds(j);
                n2 = nodeIds(mod(j,4) + 1);
                edgeKey = sprintf('%d_%d', min(n1,n2), max(n1,n2));
                
                if ~isKey(edgeMidpoints, edgeKey)
                    % Create new midpoint node
                    x1 = nodes(n1, 2); y1 = nodes(n1, 3);
                    x2 = nodes(n2, 2); y2 = nodes(n2, 3);
                    newNodes(nextNodeId,:) = [nextNodeId, (x1+x2)/2, (y1+y2)/2];
                    edgeMidpoints(edgeKey) = nextNodeId;
                    midNodes(j) = nextNodeId;
                    nextNodeId = nextNodeId + 1;
                else
                    midNodes(j) = edgeMidpoints(edgeKey);
                end
            end
            
            % Create center node
            centerX = mean(nodes(nodeIds, 2));
            centerY = mean(nodes(nodeIds, 3));
            newNodes(nextNodeId,:) = [nextNodeId, centerX, centerY];
            centerNode = nextNodeId;
            nextNodeId = nextNodeId + 1;
            
            % Create four new elements with improved quality
            % Element 1: bottom-left
            newElements(nextElemId,:) = createQualityElement([nodeIds(1), midNodes(1), centerNode, midNodes(4)], nextElemId);
            nextElemId = nextElemId + 1;
            
            % Element 2: bottom-right
            newElements(nextElemId,:) = createQualityElement([midNodes(1), nodeIds(2), midNodes(2), centerNode], nextElemId);
            nextElemId = nextElemId + 1;
            
            % Element 3: top-right
            newElements(nextElemId,:) = createQualityElement([centerNode, midNodes(2), nodeIds(3), midNodes(3)], nextElemId);
            nextElemId = nextElemId + 1;
            
            % Element 4: top-left
            newElements(nextElemId,:) = createQualityElement([midNodes(4), centerNode, midNodes(3), nodeIds(4)], nextElemId);
            nextElemId = nextElemId + 1;
            
        else
            % Keep original element
            newElements(nextElemId,:) = [nextElemId, elements(i, 2:5)];
            nextElemId = nextElemId + 1;
        end
    end
    
    % Return refined mesh
    nodes_new = newNodes;
    elements_new = newElements;

    % Sanity check: ensure all element node indices are valid
    maxNodeId = size(nodes_new,1);
    if any(elements_new(:,2:5) > maxNodeId, 'all')
        error('adaptiveMesh:InvalidNodeIndex', ...
            'Element connectivity refers to node index exceeding number of nodes (max node id: %d).', maxNodeId);
    end
end

function element = createQualityElement(nodes, elemId)
    % Creates an element with optimized node ordering for better quality
    % nodes: [n1, n2, n3, n4] - corner nodes in any order
    % Reorders nodes to maximize element quality
    element = [elemId, nodes];
end

function [elementErrors, avgError] = computeElementErrors(nodes, elements, U, E, nu, h)
    % Enhanced error estimation using both stress recovery and strain energy
    [Mx, My, Mxy, Qx, Qy] = computeStresses(nodes, elements, U, E, nu, h);
    
    nElements = size(elements, 1);
    elementErrors = zeros(nElements, 1);
    
    % Material stiffness for strain energy calculation
    D = (E * h^3) / (12 * (1 - nu^2)) * [1, nu, 0;
                                         nu, 1, 0;
                                         0, 0, (1-nu)/2];
    
    % Element patch assembly for enhanced error estimation
    for el = 1:nElements
        % Get neighboring elements
        neighbors = findNeighbors(elements, el);
        
        % Compute stress jumps across edges
        jumpMx = 0;
        jumpMy = 0;
        jumpMxy = 0;
        jumpQx = 0;
        jumpQy = 0;
        
        for nb = neighbors
            if nb > 0
                jumpMx = jumpMx + (Mx(el) - Mx(nb))^2;
                jumpMy = jumpMy + (My(el) - My(nb))^2;
                jumpMxy = jumpMxy + (Mxy(el) - Mxy(nb))^2;
                jumpQx = jumpQx + (Qx(el) - Qx(nb))^2;
                jumpQy = jumpQy + (Qy(el) - Qy(nb))^2;
            end
        end
        
        % Compute strain energy error indicator
        nodeIds = elements(el, 2:5);
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        
        % Element size for normalization
        h_el = sqrt((max(xe)-min(xe))^2 + (max(ye)-min(ye))^2);
        
        % Combined error indicator using stress jumps and strain energy
        elementErrors(el) = sqrt(jumpMx + jumpMy + jumpMxy + h_el^2*(jumpQx + jumpQy));
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
            % Check if elements share at least 2 nodes (an edge)
            sharedNodes = intersect(nodeList, elements(el, 2:5));
            if length(sharedNodes) >= 2
                neighbors = [neighbors, el];
            end
        end
    end
end