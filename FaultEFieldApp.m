classdef FaultEFieldApp< matlab.apps.AppBase
    % FaultEFieldApp - interactive app to simulate/visualize electric field
    % around a fault in an underground cable.
    % Save this file as FaultEFieldApp.m and run: app = FaultEFieldApp;

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout

        % Left panel: controls
        ControlPanel         matlab.ui.container.Panel
        RunButton            matlab.ui.control.Button
        SaveButton           matlab.ui.control.Button
        ResetButton          matlab.ui.control.Button
        TouchModeToggle      matlab.ui.control.StateButton

        % Numeric inputs
        CableLengthEditLabel matlab.ui.control.Label
        CableLengthEdit      matlab.ui.control.NumericEditField
        CableDepthEditLabel  matlab.ui.control.Label
        CableDepthEdit       matlab.ui.control.NumericEditField
        CableRadiusEditLabel matlab.ui.control.Label
        CableRadiusEdit      matlab.ui.control.NumericEditField
        FaultLocationLabel   matlab.ui.control.Label
        FaultLocationEdit    matlab.ui.control.NumericEditField
        FaultResistanceLabel matlab.ui.control.Label
        FaultResistanceEdit  matlab.ui.control.NumericEditField
        AppliedVoltageLabel  matlab.ui.control.Label
        AppliedVoltageEdit   matlab.ui.control.NumericEditField
        SoilResistivityLabel matlab.ui.control.Label
        SoilResistivityEdit  matlab.ui.control.NumericEditField

        % Right panel: plots
        PlotPanel            matlab.ui.container.Panel
        TabGroup             matlab.ui.container.TabGroup
        MainTab              matlab.ui.container.Tab
        Axes1                matlab.ui.control.UIAxes  % contour
        Axes2                matlab.ui.control.UIAxes  % quiver
        Axes3                matlab.ui.control.UIAxes  % surf
        AnalysisTab          matlab.ui.container.Tab
        Axes4                matlab.ui.control.UIAxes  % axis plot
        Axes5                matlab.ui.control.UIAxes  % potential contour
    end

    properties (Access = private)
        % Data storage
        X
        Y
        Ex
        Ey
        E_magnitude
        V_potential

        % Touch / pointer state
        isTouchMode = false;
        isDragging = false;
    end

    methods (Access = private)

        function runSimulation(app)
            % Read parameters from UI
            cable_length     = app.CableLengthEdit.Value;
            cable_depth      = app.CableDepthEdit.Value;
            cable_radius     = app.CableRadiusEdit.Value;
            fault_location   = app.FaultLocationEdit.Value;
            fault_resistance = app.FaultResistanceEdit.Value;
            applied_voltage  = app.AppliedVoltageEdit.Value;
            soil_resistivity = app.SoilResistivityEdit.Value;

            % Basic input checks
            if fault_resistance <= 0 || soil_resistivity <= 0 || cable_radius <= 0
                uialert(app.UIFigure, 'Fault resistance, soil resistivity and cable radius must be positive.', 'Invalid Parameters');
                return;
            end

            % Ensure fault location inside cable length
            fault_location = max(0, min(cable_length, fault_location));
            app.FaultLocationEdit.Value = fault_location; % keep UI in sync

            % Create grid (centered around fault +/- 5 m by default)
            x_min = max(0, fault_location - 5);
            x_max = min(cable_length, fault_location + 5);
            x = linspace(x_min, x_max, 160);
            y = linspace(0, 3, 160);
            [X, Y] = meshgrid(x, y);

            % Initialize
            Ex = zeros(size(X));
            Ey = zeros(size(X));
            E_magnitude = zeros(size(X));
            V_potential = zeros(size(X));

            % Main calculation (vectorized approach)
            dx = X - fault_location;
            dy = Y - cable_depth;
            r = sqrt(dx.^2 + dy.^2);

            % Prevent r < cable_radius
            r(r < cable_radius) = cable_radius;

% ==============================
% PHYSICALLY CORRECT FAULT MODEL
% ==============================

% Fault current estimation (Ohm's law)
Ifault = applied_voltage / fault_resistance;   % Amps

% Electric field magnitude (V/m) — grounding theory
E_magnitude = (soil_resistivity * Ifault) ./ (2 * pi * r);

% Field components
Ex = E_magnitude .* (dx ./ r);
Ey = E_magnitude .* (dy ./ r);

% Electric potential (V) — logarithmic distribution
V_potential = (soil_resistivity * Ifault ./ (2 * pi)) .* log(r / cable_radius);


            % Store in app properties
            app.X = X; app.Y = Y;
            app.Ex = Ex; app.Ey = Ey;
            app.E_magnitude = E_magnitude;
            app.V_potential = V_potential;

            % Update plots
            plotAll(app, fault_location, cable_depth);
        end

        function plotAll(app, fault_location, cable_depth)
            % Contour magnitude
            ax = app.Axes1;
            cla(ax);
            contourf(ax, app.X, app.Y, app.E_magnitude, 30, 'LineStyle', 'none');
            hold(ax, 'on');
            plot(ax, fault_location, cable_depth, 'r*', 'MarkerSize', 12, 'LineWidth', 1.5);
            colorbar(ax);
            xlabel(ax, 'Distance along cable (m)');
            ylabel(ax, 'Depth (m)');
            title(ax, 'Electric Field Magnitude (V/m)');
            set(ax, 'YDir', 'reverse');
            grid(ax, 'on');
            hold(ax, 'off');

            % Quiver
            ax = app.Axes2;
            cla(ax);
            % choose skip so arrows are not too dense
            skipX = max(1, floor(size(app.X,2)/30));
            skipY = max(1, floor(size(app.X,1)/20));
            quiver(ax, app.X(1:skipY:end,1:skipX:end), app.Y(1:skipY:end,1:skipX:end), ...
                   app.Ex(1:skipY:end,1:skipX:end), app.Ey(1:skipY:end,1:skipX:end), 2, 'AutoScale', 'on');
            hold(ax, 'on');
            plot(ax, fault_location, cable_depth, 'r*', 'MarkerSize', 12, 'LineWidth', 1.5);
            xlabel(ax, 'Distance along cable (m)'); ylabel(ax, 'Depth (m)');
            title(ax, 'Electric Field Vectors');
            set(ax, 'YDir', 'reverse');
            grid(ax, 'on');
            hold(ax, 'off');

            % 3D Surface
            ax = app.Axes3;
            cla(ax);
            surf(ax, app.X, app.Y, app.E_magnitude, 'EdgeColor', 'none');
            shading(ax, 'interp');
            colorbar(ax);
            xlabel(ax, 'Distance (m)'); ylabel(ax, 'Depth (m)'); zlabel(ax, 'E (V/m)');
            title(ax, '3D Electric Field Distribution');
            view(ax, 45, 30);

            % Field along cable axis
            ax = app.Axes4;
            cla(ax);
            [~, rowIdx] = min(abs(app.Y(:,1) - cable_depth)); % row closest to cable depth
            cable_axis_field = app.E_magnitude(rowIdx, :);
            distance_axis = app.X(1,:);
            plot(ax, distance_axis, cable_axis_field, 'b-', 'LineWidth', 1.6);
            hold(ax, 'on');
            [~, colIdx] = min(abs(distance_axis - fault_location));
            plot(ax, distance_axis(colIdx), cable_axis_field(colIdx), 'r*', 'MarkerSize', 10);
            xlabel(ax, 'Distance along cable (m)'); ylabel(ax, 'E (V/m)');
            title(ax, 'Field along cable depth'); grid(ax, 'on'); hold(ax, 'off');

            % Potential contour
            ax = app.Axes5;
            cla(ax);
            contourf(ax, app.X, app.Y, app.V_potential, 30, 'LineStyle', 'none');
            hold(ax, 'on');
            plot(ax, fault_location, cable_depth, 'r*', 'MarkerSize', 12, 'LineWidth', 1.5);
            colorbar(ax);
            xlabel(ax, 'Distance along cable (m)'); ylabel(ax, 'Depth (m)');
            title(ax, 'Electric Potential (approx)');
            set(ax, 'YDir', 'reverse'); grid(ax, 'on'); hold(ax, 'off');
        end

        function saveData(app)
            if isempty(app.X)
                uialert(app.UIFigure, 'No data available. Run the simulation first.', 'No Data');
                return;
            end
            field_data.X = app.X;
            field_data.Y = app.Y;
            field_data.Ex = app.Ex;
            field_data.Ey = app.Ey;
            field_data.E_magnitude = app.E_magnitude;
            field_data.V_potential = app.V_potential;
            % parameters
            params = struct('cable_length', app.CableLengthEdit.Value, ...
                            'cable_depth', app.CableDepthEdit.Value, ...
                            'cable_radius', app.CableRadiusEdit.Value, ...
                            'fault_location', app.FaultLocationEdit.Value, ...
                            'fault_resistance', app.FaultResistanceEdit.Value, ...
                            'applied_voltage', app.AppliedVoltageEdit.Value, ...
                            'soil_resistivity', app.SoilResistivityEdit.Value);
            field_data.parameters = params;

            [file, path] = uiputfile('fault_efield_data.mat', 'Save field data as');
            if isequal(file, 0)
                % user cancelled
                return;
            end
            save(fullfile(path, file), 'field_data');
            uialert(app.UIFigure, sprintf('Data saved to\n%s', fullfile(path, file)), 'Saved');
        end

        function resetDefaults(app)
            % Reset UI values to sensible defaults
            app.CableLengthEdit.Value = 100;
            app.CableDepthEdit.Value = 1.5;
            app.CableRadiusEdit.Value = 0.025;
            app.FaultLocationEdit.Value = 50;
            app.FaultResistanceEdit.Value = 100;
            app.AppliedVoltageEdit.Value = 11000;
            app.SoilResistivityEdit.Value = 100;

            cla(app.Axes1); cla(app.Axes2); cla(app.Axes3);
            cla(app.Axes4); cla(app.Axes5);
            app.X = []; app.Y = []; app.Ex = []; app.Ey = []; app.E_magnitude = []; app.V_potential = [];
        end

        % --- Touch / Pointer handler helpers ---
        function enableTouchMode(app)
            % Attach window pointer callbacks to uifigure
            app.isTouchMode = true;
            % Use WindowButton... on uifigure so both touch and mouse work
            app.UIFigure.WindowButtonDownFcn   = @(src,event) app.pointerDown(src,event);
            app.UIFigure.WindowButtonMotionFcn = @(src,event) app.pointerMotion(src,event);
            app.UIFigure.WindowButtonUpFcn     = @(src,event) app.pointerUp(src,event);

            % Optionally change cursor when supported
            try
                app.UIFigure.Pointer = 'hand';
            catch
            end
            drawnow;
        end

        function disableTouchMode(app)
            app.isTouchMode = false;
            app.isDragging = false;
            % remove callbacks
            app.UIFigure.WindowButtonDownFcn = [];
            app.UIFigure.WindowButtonMotionFcn = [];
            app.UIFigure.WindowButtonUpFcn = [];
            try
                app.UIFigure.Pointer = 'arrow';
            catch
            end
            drawnow;
        end

        function pointerDown(app, ~, ~)
            % Called when user touches / clicks the figure
            if ~app.isTouchMode
                return;
            end
            % We interpret taps in the main contour Axes (Axes1)
            try
                cp = app.Axes1.CurrentPoint; % 2x3 matrix
            catch
                return;
            end
            x = cp(1,1); y = cp(1,2);
            % check inside axes limits
            xl = xlim(app.Axes1); yl = ylim(app.Axes1);
            if x >= xl(1) && x <= xl(2) && y >= yl(1) && y <= yl(2)
                % start dragging and update fault location
                app.isDragging = true;
                % ensure value within cable length
                newFault = min(max(x, 0), app.CableLengthEdit.Value);
                app.FaultLocationEdit.Value = newFault;
                % run simulation
                runSimulation(app);
            end
        end

        function pointerMotion(app, ~, ~)
            % Called during pointer move (drag)
            if ~app.isTouchMode || ~app.isDragging
                return;
            end
            try
                cp = app.Axes1.CurrentPoint;
            catch
                return;
            end
            x = cp(1,1); y = cp(1,2);
            xl = xlim(app.Axes1); yl = ylim(app.Axes1);
            if x >= xl(1) && x <= xl(2) && y >= yl(1) && y <= yl(2)
                newFault = min(max(x, 0), app.CableLengthEdit.Value);
                % update UI value only if changed meaningfully (avoids flooding)
                if abs(newFault - app.FaultLocationEdit.Value) > 1e-3
                    app.FaultLocationEdit.Value = newFault;
                    runSimulation(app);
                end
            end
        end

        function pointerUp(app, ~, ~)
            % End drag
            if ~app.isTouchMode
                return;
            end
            app.isDragging = false;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: RunButton
        function RunButtonPushed(app, ~)
            drawnow;
            try
                runSimulation(app);
            catch ME
                uialert(app.UIFigure, ['Error running simulation: ' ME.message], 'Error');
            end
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, ~)
            saveData(app);
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, ~)
            resetDefaults(app);
        end

        % Touch toggle pushed
        function TouchModeToggled(app, src, ~)
            if src.Value % statebutton value true => ON
                enableTouchMode(app);
                src.Text = 'Touch Mode: ON';
            else
                disableTouchMode(app);
                src.Text = 'Touch Mode: OFF';
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UI components and layout
        function createComponents(app)
            % UIFigure and layout
            app.UIFigure = uifigure('Name', 'Cable Fault Electric Field Simulator', 'Position', [200 100 1200 720]);
            app.GridLayout = uigridlayout(app.UIFigure, [1 2]);
            % Left column fixed 320 pixels, right column flexible
            app.GridLayout.ColumnWidth = {320, '1x'};
            app.GridLayout.RowHeight = {'1x'};

            % Control panel (left)
            app.ControlPanel = uipanel(app.GridLayout, 'Title', 'Controls');
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 1;
            cp = uigridlayout(app.ControlPanel, [16 2]);
            cp.RowHeight = repmat({'fit'}, 1, 16);
            cp.ColumnWidth = {'1x', 110};

            r = 1;
            app.CableLengthEditLabel = uilabel(cp, 'Text', 'Cable length (m):'); app.CableLengthEditLabel.Layout.Row = r; app.CableLengthEditLabel.Layout.Column = 1;
            app.CableLengthEdit = uieditfield(cp, 'numeric', 'Value', 100); app.CableLengthEdit.Layout.Row = r; app.CableLengthEdit.Layout.Column = 2;

            r = r + 1;
            app.CableDepthEditLabel = uilabel(cp, 'Text', 'Cable depth (m):'); app.CableDepthEditLabel.Layout.Row = r; app.CableDepthEditLabel.Layout.Column = 1;
            app.CableDepthEdit = uieditfield(cp, 'numeric', 'Value', 1.5); app.CableDepthEdit.Layout.Row = r; app.CableDepthEdit.Layout.Column = 2;

            r = r + 1;
            app.CableRadiusEditLabel = uilabel(cp, 'Text', 'Cable radius (m):'); app.CableRadiusEditLabel.Layout.Row = r; app.CableRadiusEditLabel.Layout.Column = 1;
            app.CableRadiusEdit = uieditfield(cp, 'numeric', 'Value', 0.025); app.CableRadiusEdit.Layout.Row = r; app.CableRadiusEdit.Layout.Column = 2;

            r = r + 1;
            app.FaultLocationLabel = uilabel(cp, 'Text', 'Fault location (m):'); app.FaultLocationLabel.Layout.Row = r; app.FaultLocationLabel.Layout.Column = 1;
            app.FaultLocationEdit = uieditfield(cp, 'numeric', 'Value', 50); app.FaultLocationEdit.Layout.Row = r; app.FaultLocationEdit.Layout.Column = 2;

            r = r + 1;
            app.FaultResistanceLabel = uilabel(cp, 'Text', 'Fault resistance (Ω):'); app.FaultResistanceLabel.Layout.Row = r; app.FaultResistanceLabel.Layout.Column = 1;
            app.FaultResistanceEdit = uieditfield(cp, 'numeric', 'Value', 100); app.FaultResistanceEdit.Layout.Row = r; app.FaultResistanceEdit.Layout.Column = 2;

            r = r + 1;
            app.AppliedVoltageLabel = uilabel(cp, 'Text', 'Applied voltage (V):'); app.AppliedVoltageLabel.Layout.Row = r; app.AppliedVoltageLabel.Layout.Column = 1;
            app.AppliedVoltageEdit = uieditfield(cp, 'numeric', 'Value', 11000); app.AppliedVoltageEdit.Layout.Row = r; app.AppliedVoltageEdit.Layout.Column = 2;

            r = r + 1;
            app.SoilResistivityLabel = uilabel(cp, 'Text', 'Soil resistivity (Ω·m):'); app.SoilResistivityLabel.Layout.Row = r; app.SoilResistivityLabel.Layout.Column = 1;
            app.SoilResistivityEdit = uieditfield(cp, 'numeric', 'Value', 100); app.SoilResistivityEdit.Layout.Row = r; app.SoilResistivityEdit.Layout.Column = 2;

            % Touch Mode toggle (state button)
            r = r + 1;
            app.TouchModeToggle = uibutton(cp, 'state', 'Text', 'Touch Mode: OFF', 'Value', false, ...
                'ValueChangedFcn', @(btn, ev) TouchModeToggled(app, btn, ev));
            app.TouchModeToggle.Layout.Row = r; app.TouchModeToggle.Layout.Column = [1 2];

            % Buttons
            r = r + 1;
            app.RunButton = uibutton(cp, 'push', 'Text', 'Run Simulation', 'ButtonPushedFcn', @(btn, ev) RunButtonPushed(app, ev));
            app.RunButton.Layout.Row = r; app.RunButton.Layout.Column = [1 2];

            r = r + 1;
            app.SaveButton = uibutton(cp, 'push', 'Text', 'Save Data', 'ButtonPushedFcn', @(btn, ev) SaveButtonPushed(app, ev));
            app.SaveButton.Layout.Row = r; app.SaveButton.Layout.Column = [1 2];

            r = r + 1;
            app.ResetButton = uibutton(cp, 'push', 'Text', 'Reset to Defaults', 'ButtonPushedFcn', @(btn, ev) ResetButtonPushed(app, ev));
            app.ResetButton.Layout.Row = r; app.ResetButton.Layout.Column = [1 2];

            % Plot panel (right)
            app.PlotPanel = uipanel(app.GridLayout, 'Title', 'Plots & Analysis');
            app.PlotPanel.Layout.Row = 1;
            app.PlotPanel.Layout.Column = 2;

            % Use an internal grid so layout scales nicely
            ppGrid = uigridlayout(app.PlotPanel, [1 1]);
            ppGrid.RowHeight = {'1x'}; ppGrid.ColumnWidth = {'1x'};

            % Tab group fills the plot panel
            app.TabGroup = uitabgroup(ppGrid);
            app.TabGroup.Layout.Row = 1; app.TabGroup.Layout.Column = 1;

            % Tabs
            app.MainTab = uitab(app.TabGroup, 'Title', 'Main Views');
            app.AnalysisTab = uitab(app.TabGroup, 'Title', 'Analysis');

            % MainTab layout: 1x3 axes
            mainGrid = uigridlayout(app.MainTab, [1 3]);
            mainGrid.RowHeight = {'1x'};
            mainGrid.ColumnWidth = {'1x', '1x', '1x'};
            app.Axes1 = uiaxes(mainGrid); app.Axes1.Layout.Row = 1; app.Axes1.Layout.Column = 1;
            app.Axes2 = uiaxes(mainGrid); app.Axes2.Layout.Row = 1; app.Axes2.Layout.Column = 2;
            app.Axes3 = uiaxes(mainGrid); app.Axes3.Layout.Row = 1; app.Axes3.Layout.Column = 3;

            % Analysis tab: two stacked axes
            analysisGrid = uigridlayout(app.AnalysisTab, [2 1]);
            analysisGrid.RowHeight = {'1x', '1x'};
            app.Axes4 = uiaxes(analysisGrid); app.Axes4.Layout.Row = 1; app.Axes4.Layout.Column = 1;
            app.Axes5 = uiaxes(analysisGrid); app.Axes5.Layout.Row = 2; app.Axes5.Layout.Column = 1;
        end
    end

    methods (Access = public)

        % Construct app
        function app = FaultEFieldApp
            createComponents(app);
            % initialize empty data
            app.X = []; app.Y = []; app.Ex = []; app.Ey = []; app.E_magnitude = []; app.V_potential = [];
        end

        % Delete app
        function delete(app)
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
