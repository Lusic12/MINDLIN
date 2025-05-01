function plotDeformation(nodes, elements, U)
    % plotDeformation - Plots the deformed shape of the plate
    % Inputs:
    %   nodes    - Node coordinates [node_id, x, y]
    %   elements - Element connectivity [elem_id, node1, node2, node3, node4]
    %   U        - Displacement vector [w1, θx1, θy1, w2, θx2, θy2, ...]
    
    % Extract vertical displacements
    w = U(1:3:end);
    
    % Create figure
    figure;
    hold on;
    
    % Plot each element
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        
        % Get node coordinates and displacements for this element
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        we = w(nodeIds);
        
        % Plot deformed element surface
        patch(xe, ye, we, 'FaceColor', 'interp', 'EdgeColor', 'k');
    end
    
    % Set view and labels
    view(3);
    xlabel('X');
    ylabel('Y');
    zlabel('Displacement');
    colorbar;
    title('Plate Deformation');
    axis equal;
    grid on;
end