function plotResults(nodes, elements, U, analysisType, plotType, colormap, animate)
% plotResults - Enhanced visualization of analysis results
% Inputs:
%   nodes        - Node coordinates [node_id, x, y]
%   elements     - Element connectivity [elem_id, node1, node2, node3, node4]
%   U            - Results vector (displacements, mode shapes, etc.)
%   analysisType - Type of analysis (1:Static, 2:Buckling, 3:Vibration)
%   plotType     - Type of plot (1:All, 2:Mesh, 3:Deformation, 4:Contour)
%   colormap     - Name of colormap to use
%   animate      - Boolean flag for animation (for buckling/vibration)

    % Set colormap
    colormap(gca, colormap);

    % Extract vertical displacements for deformation plot
    w = U(1:3:end);
    
    % Calculate scale factor for deformation
    maxDefl = max(abs(w));
    L = max(nodes(:,2)) - min(nodes(:,2));
    scaleFactor = 0.2 * L / maxDefl;
    
    % Plot based on type
    switch plotType
        case 2 % Mesh only
            plotMeshOnly(nodes, elements);
            
        case 3 % Deformation
            if animate && (analysisType > 1)
                animateDeformation(nodes, elements, w, scaleFactor);
            else
                plotDeformedShape(nodes, elements, w, scaleFactor);
            end
            
        case 4 % Contour
            plotContourResults(nodes, elements, w);
            
        case 1 % All results
            subplot(2,2,1);
            plotMeshOnly(nodes, elements);
            title('Original Mesh');
            
            subplot(2,2,2);
            plotDeformedShape(nodes, elements, w, scaleFactor);
            title('Deformed Shape');
            
            subplot(2,2,3);
            plotContourResults(nodes, elements, w);
            title('Contour Plot');
            
            subplot(2,2,4);
            switch analysisType
                case 1
                    plotStaticResults(w);
                case 2
                    plotBucklingResults(U);
                case 3
                    plotVibrationResults(U);
            end
    end
end

function plotMeshOnly(nodes, elements)
    hold on;
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        plot([xe; xe(1)], [ye; ye(1)], 'b-', 'LineWidth', 0.5);
    end
    plot(nodes(:,2), nodes(:,3), 'r.', 'MarkerSize', 6);
    xlabel('X (m)'); ylabel('Y (m)');
    grid on; axis equal tight;
end

function plotDeformedShape(nodes, elements, w, scaleFactor)
    hold on;
    for el = 1:size(elements, 1)
        nodeIds = elements(el, 2:5);
        xe = nodes(nodeIds, 2);
        ye = nodes(nodeIds, 3);
        we = w(nodeIds) * scaleFactor;
        
        % Plot original mesh in light gray
        plot3([xe; xe(1)], [ye; ye(1)], zeros(5,1), 'Color', [0.8 0.8 0.8]);
        % Plot deformed shape
        patch(xe, ye, we, we, 'EdgeColor', 'interp', 'FaceColor', 'interp');
    end
    xlabel('X (m)'); ylabel('Y (m)'); zlabel('Displacement (m)');
    view(3); grid on; axis equal tight;
end

function plotContourResults(nodes, elements, w)
    hold on;
    trisurf(elements(:,2:4), nodes(:,2), nodes(:,3), w, ...
        'EdgeColor', 'none', 'FaceColor', 'interp');
    view(2);
    xlabel('X (m)'); ylabel('Y (m)');
    c = colorbar;
    c.Label.String = 'Displacement (m)';
    axis equal tight;
end

function animateDeformation(nodes, elements, w, scaleFactor)
    % Animation parameters
    nFrames = 30;
    period = 2; % seconds for one cycle
    
    % Create animation
    for frame = 1:nFrames
        cla;
        phase = 2*pi * frame/nFrames;
        wAnim = w * scaleFactor * cos(phase);
        
        % Plot deformed shape for this frame
        plotDeformedShape(nodes, elements, wAnim, 1);
        drawnow;
        pause(period/nFrames);
    end
end

function plotStaticResults(w)
    % Create bar chart of max/min displacements
    bar([max(w), min(w)]);
    set(gca, 'XTickLabel', {'Max', 'Min'});
    ylabel('Displacement (m)');
    title('Displacement Extremes');
    grid on;
end

function plotBucklingResults(U)
    % Plot first few buckling factors
    bar(diag(U(1:5,1:5)));
    xlabel('Mode Number');
    ylabel('Buckling Factor');
    title('Critical Buckling Factors');
    grid on;
end

function plotVibrationResults(U)
    % Plot natural frequencies
    freqs = sqrt(diag(U))/(2*pi);
    bar(freqs(1:5));
    xlabel('Mode Number');
    ylabel('Frequency (Hz)');
    title('Natural Frequencies');
    grid on;
end