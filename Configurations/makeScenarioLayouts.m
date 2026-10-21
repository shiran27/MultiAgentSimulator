function makeScenarioLayouts()
% Builds the ready-made map scenarios of scenarioCatalog: for each, a background image
% (Configurations/backgrounds/<Name>.png, drawn here) and a layout file (Configurations/<Name>.mat)
% whose walls come from the same geometry as the picture, so they line up exactly. Run it again
% after editing a scenario:
%   matlab -batch "addpath(genpath(pwd)); makeScenarioLayouts"
% Also records the lab floor plan as the background of ReportLayout.mat.
here = fileparts(mfilename('fullpath'));
bgDir = fullfile(here, 'backgrounds');
if ~isfolder(bgDir), mkdir(bgDir); end
makers = {@cityBlocks, @harborPatrol, @campus};
for k = 1:numel(makers)
    [name, s, drawFcn] = makers{k}();
    s.background = name + ".png";
    render(drawFcn, fullfile(bgDir, name + ".png"));
    save(fullfile(here, name + ".mat"), 's');
    fprintf('%s: %d targets, %d edges, %d walls, %d agents\n', name, size(s.targets, 1), ...
        size(s.edges, 1), size(s.walls, 1), numel(s.agentStarts));
end
tmp = load(fullfile(here, 'ReportLayout.mat'), 's');
s = tmp.s;
s.background = "LabLayout.png";
save(fullfile(here, 'ReportLayout.mat'), 's');
end

%% ---------------------------------------------------------------------------------------------
function [name, s, draw] = cityBlocks()
% Street grid with eight city blocks (obstacles) around a park (open), a river promenade on top
name = "CityBlocks";
X = [6 33 60 87]; Y = [6 31 56 81]; half = 3;            % street centerlines, half width
bx = [X(1:3) + half; X(2:4) - half]';                      % block x ranges (3 x 2)
by = [Y(1:3) + half; Y(2:4) - half]';
park = [2 2];                                              % block (column, row) that is a park
walls = zeros(0, 4);
for i = 1:3
    for j = 1:3
        if isequal([i j], park), continue; end
        walls = [walls; rectWalls(bx(i, 1), by(j, 1), bx(i, 2), by(j, 2))]; %#ok<AGROW>
    end
end
targets = [6 6; 46.5 6; 87 6; 19.5 31; 46.5 43.5; 73.5 56; 6 56; 33 81; 46.5 86; 87 81; 87 31];
names = ["Station", "Market", "Depot", "School", "Park", "Hospital", "Library", "Plaza", ...
    "Pier", "Stadium", "Clinic"];
edges = [1 2; 1 4; 2 3; 2 5; 3 11; 4 5; 4 7; 5 6; 5 8; 6 11; 6 10; 7 8; 8 9; 9 10];
A = ones(numel(names), 1); A(names == "Hospital") = 2; A(names == "Market") = 1.5;
s = layout(targets, edges, walls, [1 3 7 10], 15, A);
draw = @drawCity;

    function drawCity(ax)
        land = [0.949 0.937 0.914]; street = [1 1 1]; avenue = [0.992 0.886 0.576];
        edgeGray = [0.82 0.80 0.76]; bldg = [0.902 0.890 0.863]; bldgEdge = [0.78 0.75 0.70];
        fill(ax, [0 100 100 0], [0 0 100 100], land, 'EdgeColor', 'none');
        fill(ax, [0 100 100 0], [88 88 100 100], [0.667 0.855 1], 'EdgeColor', 'none');   % river
        for w = 89.5:2.5:99, plot(ax, [0 100], [w w], 'Color', [0.78 0.91 1], 'LineWidth', 0.8); end
        fill(ax, [0 100 100 0], [84 84 88 88], [0.97 0.95 0.90], 'EdgeColor', edgeGray);  % promenade
        for x = X                                                       % streets
            c = street; if x == 60, c = avenue; end
            fill(ax, x + [-half half half -half], [0 0 84 84], c, 'EdgeColor', edgeGray);
        end
        for y = Y
            fill(ax, [0 100 100 0], y + [-half -half half half], street, 'EdgeColor', edgeGray);
        end
        fill(ax, 60 + [-half half half -half], [0 0 84 84], avenue, 'EdgeColor', 'none'); % avenue on top
        for y = Y, plot(ax, [60 - half 60 + half], [y y], 'Color', avenue, 'LineWidth', 5); end
        for i = 1:3                                                     % blocks
            for j = 1:3
                x0 = bx(i, 1); x1 = bx(i, 2); y0 = by(j, 1); y1 = by(j, 2);
                if isequal([i j], park)
                    rectangle(ax, 'Position', [x0 y0 x1-x0 y1-y0], 'FaceColor', [0.776 0.902 0.765], ...
                        'EdgeColor', [0.62 0.80 0.60], 'Curvature', 0.05);
                    plot(ax, [x0 x1], [y0 y1], 'Color', [0.95 0.93 0.86], 'LineWidth', 2);
                    plot(ax, [x0 x1], [y1 y0], 'Color', [0.95 0.93 0.86], 'LineWidth', 2);
                    rectangle(ax, 'Position', [44 39 7 5], 'Curvature', 1, 'FaceColor', [0.667 0.855 1], 'EdgeColor', 'none');
                    tree(ax, [39 37; 54 37; 39 50; 54 50; 42 45; 52 41]);
                    continue;
                end
                rectangle(ax, 'Position', [x0 y0 x1-x0 y1-y0], 'FaceColor', [0.93 0.92 0.89], 'EdgeColor', bldgEdge);
                xm = (x0 + x1) / 2; ym = (y0 + y1) / 2; g = 0.8;         % four buildings per block
                for q = [x0 y0 xm y0; xm y0 x1 y0; x0 ym xm ym; xm ym x1 ym]'
                    rectangle(ax, 'Position', [q(1)+g q(2)+g (xm-x0)-2*g (ym-y0)-2*g], ...
                        'FaceColor', bldg, 'EdgeColor', bldgEdge);
                end
            end
        end
        rectangle(ax, 'Position', [68.6 47.2 4 4], 'FaceColor', [0.85 0.2 0.2], 'EdgeColor', 'none');   % hospital
        plot(ax, [70.6 70.6], [47.8 50.6], 'w', 'LineWidth', 3); plot(ax, [69.2 72], [49.2 49.2], 'w', 'LineWidth', 3);
        label(ax, 60, 16, 'Central Ave', 90); label(ax, 47, 31, 'Elm St', 0); label(ax, 20, 56, 'Oak St', 0);
        label(ax, 46.5, 52, 'City Park', 0); label(ax, 76, 92.5, 'River', 0, [0.25 0.45 0.7]);
    end
end

%% ---------------------------------------------------------------------------------------------
function [name, s, draw] = harborPatrol()
% A harbor on the west coast (piers, breakwater) and two islands offshore; boats patrol buoys
name = "HarborPatrol";
coast = [0 0; 16 0; 18 12; 14 22; 19 34; 15 48; 20 60; 16 74; 21 88; 18 100; 0 100];
islandA = [44 64; 47 72; 55 76; 62 71; 61 62; 53 57; 46 59];
islandB = [68 26; 71 33; 78 34; 81 28; 77 22; 71 22];
piers = [17 18 30 18; 16.5 28 30 28];
breakwater = [30 40 44 46];
walls = [polyWalls(coast(2:end-1, :), false); polyWalls(islandA, true); polyWalls(islandB, true); ...
    piers; breakwater];
targets = [33.5 18; 33.5 28; 40 36; 30 80; 38 66; 55 86; 72 66; 60 45; 60 26; 78 12; 90 88; 92 48];
edges = [1 2; 1 3; 2 3; 3 8; 3 5; 5 4; 4 6; 5 6; 6 11; 6 7; 7 11; 7 8; 7 12; 8 9; 9 10; 10 12; 8 12; 11 12; 5 8];
A = ones(size(targets, 1), 1); A([1 2]) = 1.5;              % the port is busier
s = layout(targets, edges, walls, [1 6 10], 15, A);
draw = @drawHarbor;

    function drawHarbor(ax)
        sea = [0.624 0.808 0.937]; shallow = [0.72 0.87 0.96]; sand = [0.93 0.89 0.78];
        land = [0.86 0.90 0.78]; town = [0.88 0.85 0.80];
        fill(ax, [0 100 100 0], [0 0 100 100], sea, 'EdgeColor', 'none');
        for y = 3:6:99, plot(ax, [22 100], [y y + 1], 'Color', [0.67 0.84 0.95], 'LineWidth', 0.6); end
        outline(ax, coast + [3 0], shallow); outline(ax, coast + [1.2 0], sand); outline(ax, coast, land);
        fill(ax, [0 15 13 0], [6 6 40 40], town, 'EdgeColor', 'none');                  % port town
        for r = [1 9; 1 15; 1 21; 6 9; 6 15; 6 21; 1 27; 6 27; 1 33; 6 33]'
            rectangle(ax, 'Position', [r(1) r(2) 4 4], 'FaceColor', [0.80 0.62 0.52], 'EdgeColor', [0.6 0.45 0.38]);
        end
        for k = 1:size(piers, 1)
            p = piers(k, :);
            fill(ax, [p(1) p(3) p(3) p(1)], [p(2)-0.9 p(4)-0.9 p(4)+0.9 p(2)+0.9], [0.62 0.62 0.62], 'EdgeColor', [0.4 0.4 0.4]);
        end
        plot(ax, breakwater([1 3]), breakwater([2 4]), 'Color', [0.45 0.45 0.45], 'LineWidth', 5);
        for isl = {islandA, islandB}
            P = isl{1}; c = mean(P, 1);
            outline(ax, c + 1.25 * (P - c), shallow); outline(ax, c + 1.1 * (P - c), sand); outline(ax, P, land);
        end
        tree(ax, [52 68; 56 70; 50 63; 74 28; 76 31]);
        rectangle(ax, 'Position', [56.5 62.5 2.4 2.4], 'Curvature', 1, 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', [0.7 0.1 0.1], 'LineWidth', 2);
        plot(ax, [30 98], [96 60], '--', 'Color', [0.35 0.55 0.75], 'LineWidth', 1);   % shipping lane
        plot(ax, [36 98], [99 66], '--', 'Color', [0.35 0.55 0.75], 'LineWidth', 1);
        label(ax, 8, 46, 'Port Town', 90); label(ax, 54, 80, 'North Isle', 0); label(ax, 75, 19, 'South Isle', 0);
        label(ax, 83, 82, 'Shipping lane', -28, [0.25 0.45 0.7]);
    end
end

%% ---------------------------------------------------------------------------------------------
function [name, s, draw] = campus()
% A zoomed-out building complex: six buildings and a pond (obstacles), a quad, parking
name = "Campus";
bldgs = [12 60 34 80; 42 66 60 84; 68 58 92 78; 40 34 60 50; 70 20 92 42; 10 18 28 44];
names = ["Library", "Hall A", "Labs", "Student Center", "Gym", "Dorms"];
t = linspace(0, 2*pi, 11)'; t(end) = [];
pond = [47 + 9 * cos(t), 14 + 5 * sin(t)];
walls = zeros(0, 4);
for k = 1:size(bldgs, 1), walls = [walls; rectWalls(bldgs(k, 1), bldgs(k, 2), bldgs(k, 3), bldgs(k, 4))]; end %#ok<AGROW>
walls = [walls; polyWalls(pond, true)];
targets = [23 56; 51 62; 80 54; 50 30; 66 31; 32 31; 38 57; 22 91; 94 88; 47 23; 80 82];
edges = [1 7; 7 2; 2 11; 11 9; 9 3; 3 2; 3 5; 5 4; 4 7; 4 6; 6 1; 1 8; 8 7; 4 10; 10 6; 10 5];
A = ones(size(targets, 1), 1); A([2 3]) = 1.5;              % busy lecture hall and labs
s = layout(targets, edges, walls, [8 3 6 10 2], 15, A);
routes = plannedRoutes(s);                                 % footpaths follow the planned routes
draw = @drawCampus;

    function drawCampus(ax)
        grass = [0.812 0.910 0.722]; walk = [0.95 0.93 0.88]; road = [0.70 0.70 0.70];
        fill(ax, [0 100 100 0], [0 0 100 100], grass, 'EdgeColor', 'none');
        fill(ax, [0 100 100 0], [97 97 100 100], road, 'EdgeColor', 'none');             % campus road
        plot(ax, [0 100], [98.5 98.5], '--', 'Color', [1 1 1], 'LineWidth', 1);
        fill(ax, [97 100 100 97], [0 0 100 100], road, 'EdgeColor', 'none');
        rectangle(ax, 'Position', [4 85 38 11], 'FaceColor', [0.58 0.58 0.60], 'EdgeColor', [0.45 0.45 0.45]);  % parking
        for x = 6:3:40, plot(ax, [x x], [85.5 89], 'w', 'LineWidth', 1); plot(ax, [x x], [92 95.5], 'w', 'LineWidth', 1); end
        rectangle(ax, 'Position', [35.5 52 5 10], 'Curvature', 0.3, 'FaceColor', [0.74 0.86 0.66], 'EdgeColor', walk, 'LineWidth', 2); % quad
        for k = 1:numel(routes)                                                         % footpaths
            plot(ax, routes{k}(:, 1), routes{k}(:, 2), 'Color', walk, 'LineWidth', 6);
        end
        patch(ax, pond(:, 1), pond(:, 2), [0.667 0.855 1], 'EdgeColor', [0.5 0.72 0.9], 'LineWidth', 1.5);
        roofs = [0.73 0.75 0.78; 0.85 0.64 0.54; 0.73 0.75 0.78; 0.85 0.64 0.54; 0.73 0.75 0.78; 0.85 0.64 0.54];
        for k = 1:size(bldgs, 1)
            b = bldgs(k, :);
            rectangle(ax, 'Position', [b(1)+0.6 b(2)-0.6 b(3)-b(1) b(4)-b(2)], 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'none'); % shadow
            rectangle(ax, 'Position', [b(1) b(2) b(3)-b(1) b(4)-b(2)], 'FaceColor', roofs(k, :), 'EdgeColor', [0.45 0.45 0.45]);
            plot(ax, [b(1)+1.5 b(3)-1.5], ([b(2) b(4)] + [1.5 -1.5]) * [0.5; 0.5] * [1 1], 'Color', roofs(k, :) * 0.85, 'LineWidth', 2);
            label(ax, (b(1)+b(3))/2, (b(2)+b(4))/2 + 2, char(names(k)), 0);
        end
        tree(ax, [6 50; 6 70; 38 90; 63 56; 64 88; 95 10; 84 10; 34 44; 64 46; 30 4; 64 6; 8 6]);
        label(ax, 23, 82.5, 'Parking', 0); label(ax, 37.5, 61.5, 'Quad', 0); label(ax, 47, 14, 'Pond', 0, [0.25 0.45 0.7]);
        rectangle(ax, 'Position', [92.5 86.5 3 3], 'FaceColor', [0.2 0.4 0.75], 'EdgeColor', 'w'); % bus stop sign
        label(ax, 92, 84, 'Bus', 0);
    end
end

%% ---------------------------------------------------------------------------------------------
function routes = plannedRoutes(s)
% The edges' paths as the default planner draws them
m = ScenarioModel(DijkstraCornerPlanner());
m.importLayout(s);
routes = arrayfun(@(e) {e.curvePoints}, m.edges);
end

function s = layout(targets, edges, walls, starts, speed, A)
s = struct('targets', targets, 'edges', edges, 'walls', walls, 'agentStarts', starts, ...
    'agentSpeed', speed, 'uncertaintyMode', 'Static Uniform', 'A', A, 'B', 10, ...
    'R0', zeros(size(targets, 1), 1));
end

function w = rectWalls(x0, y0, x1, y1)
w = [x0 y0 x1 y0; x1 y0 x1 y1; x1 y1 x0 y1; x0 y1 x0 y0];
end

function w = polyWalls(P, closed)
if closed, Q = [P; P(1, :)]; else, Q = P; end
w = [Q(1:end-1, :), Q(2:end, :)];
end

function render(drawFcn, file)
% Draws on a 100 x 100 canvas and saves a 1000 x 1000 px image covering exactly [0, 100]^2
fig = figure('Visible', 'off', 'Units', 'pixels', 'Position', [0 0 1000 1000], 'Color', 'w');
ax = axes(fig, 'Position', [0 0 1 1]);
hold(ax, 'on'); axis(ax, 'off');
drawFcn(ax);
set(ax, 'XLim', [0 100], 'YLim', [0 100], 'DataAspectRatio', [1 1 1]);
set(fig, 'PaperUnits', 'inches', 'PaperPosition', [0 0 10 10], 'PaperSize', [10 10]);
print(fig, file, '-dpng', '-r100');
close(fig);
end

function outline(ax, P, color)
patch(ax, P(:, 1), P(:, 2), color, 'EdgeColor', 'none');
end

function tree(ax, P)
for k = 1:size(P, 1)
    rectangle(ax, 'Position', [P(k, :) - 1.3, 2.6, 2.6], 'Curvature', 1, ...
        'FaceColor', [0.42 0.66 0.40], 'EdgeColor', [0.32 0.52 0.30]);
end
end

function label(ax, x, y, txt, rot, color)
if nargin < 6, color = [0.35 0.33 0.30]; end
text(ax, x, y, txt, 'HorizontalAlignment', 'center', 'Rotation', rot, 'FontSize', 11, ...
    'FontWeight', 'bold', 'Color', color, 'FontName', 'Helvetica');
end
