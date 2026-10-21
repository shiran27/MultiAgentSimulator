function extensionTest()
% Headless test of the extension points a new user builds on. Run from the repo root:
%   matlab -batch "addpath(genpath(pwd)); extensionTest"
%
% 1. Target types: setTargetType rebuilds the scenario with targets of the new class and keeps
%    positions, edges, walls and agents; layouts store the type.
% 2. Metrics: the default objective is J(t) (AverageUncertainty), equal to the integral the
%    model keeps; setMetrics changes the objective; runTrial returns metricValues.
% 3. The event-detection example (Examples/EventDetection): EventTarget, SimpleAgent,
%    ChaseEventsPolicy and MissedEvents run on the Museum layout; events are detected and
%    missed; Chase Events misses fewer events than Random Walk.
% 4. Grid A*: paths start and end at the targets, never cross a wall, and are no longer than
%    the Dijkstra Corners paths by more than 5% on any map.
% Prints one line per check and errors at the end (non-zero exit under -batch) if any failed.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));
rmpath(genpath(fullfile(root, 'Old_Design')));
failures = strings(0); nChecks = 0;
warning('off', 'runTrial:AgentPolicyFit');
museum = load(fullfile(root, 'Configurations', 'Museum.mat'), 's');
museum = museum.s;

% ---- 1. Target types ----
m = ScenarioModel();
m.importLayout(museum);
check(all(arrayfun(@(t) isa(t, 'EventTarget'), m.targets)), 'Museum layout loads event targets (stored targetType)');
nE = numel(m.edges); nW = size(m.walls, 1); nA = numel(m.agents); P = reshape([m.targets.position], 2, []).';
m.setTargetType("Uncertainty Target");
check(all(arrayfun(@(t) strcmp(class(t), 'Target'), m.targets)), 'setTargetType switches every target to the new class');
check(numel(m.edges) == nE && size(m.walls, 1) == nW && numel(m.agents) == nA ...
    && isequal(reshape([m.targets.position], 2, []).', P), 'setTargetType keeps positions, edges, walls and agents');
s = m.exportLayout();
check(s.targetType == "Uncertainty Target", 'exportLayout stores the target type');

% ---- 2. Metrics ----
out = runTrial(struct('Layout', "ReportLayout.mat", 'Policy', "Random Walk", 'AgentStarts', "layout", ...
    'UncertaintyMode', "Static Uniform", 'EndTime', 20, 'Seed', 1));
check(abs(out.metricValues.AverageUncertainty - out.finalJ) < 1e-12, 'default objective is J(t) (AverageUncertainty = finalJ)');
m = ScenarioModel();
m.setMetrics(["Missed Events (example)", "Average Uncertainty J(t)"]);
check(isa(m.metrics{1}, 'MissedEvents') && isa(m.metrics{2}, 'AverageUncertainty'), 'setMetrics sets the objective first');

% ---- 3. Event-detection example ----
missed = zeros(2, 3);
policies = ["Chase Events (example)", "Random Walk"];
for i = 1:2
    for seed = 1:3
        out = runTrial(struct('Layout', "Museum.mat", 'Policy', policies(i), 'AgentStarts', "layout", ...
            'AgentType', "Simple Agent (example)", 'AgentSpeed', 4, 'EndTime', 300, 'Seed', seed, ...
            'Metrics', ["Missed Events (example)", "Average Uncertainty J(t)"]));
        missed(i, seed) = out.metricValues.MissedEvents;
        if i == 1 && seed == 1
            check(isfinite(out.finalJ) && out.finalJ == out.metricValues.MissedEvents, ...
                'runTrial: finalJ is the first metric (share of events missed)');
        end
    end
end
check(all(missed(:) >= 0 & missed(:) <= 1), 'MissedEvents is a share in [0, 1]');
check(mean(missed(1, :)) < mean(missed(2, :)), sprintf('Chase Events misses fewer events than Random Walk (%.2f vs %.2f)', ...
    mean(missed(1, :)), mean(missed(2, :))));
m = ScenarioModel(); m.importLayout(museum); m.setActivePolicy('Chase Events (example)');
for a = m.agents, a.state.maxSpeed = 4; end
m.resetSimulationState(); rng(2);
clock = SimulationClock(200, 0.05);
while ~clock.isFinished()
    dt = clock.tick(); m.step(dt, clock.currentTime); m.updateTargetsAndLogObjective(clock.currentTime, dt);
end
check(sum([m.targets.detected]) > 0 && sum([m.targets.missed]) >= 0 && all([m.targets.R] >= 0), ...
    sprintf('event targets detect events (%d detected, %d missed in 200 s)', sum([m.targets.detected]), sum([m.targets.missed])));
moved = arrayfun(@(a) norm(a.state.pos - a.initialPosition) > 0 || a.current_target_idx ~= a.initialTargetIdx, m.agents);
check(any(moved), 'Chase Events moves the agents');

% ---- 4. Grid A* ----
cat = scenarioCatalog();
cat = cat(~startsWith(cat.Name, "JS:"), :);
for k = 1:height(cat)
    tmp = load(cat.File(k), 's');
    a = ScenarioModel(GridAStarPlanner()); a.importLayout(tmp.s);
    d = ScenarioModel(DijkstraCornerPlanner()); d.importLayout(tmp.s);
    ends = true; cross = 0; longer = 0;
    for e = 1:numel(a.edges)
        Pa = a.edges(e).curvePoints; Pd = d.edges(e).curvePoints;
        ends = ends && norm(Pa(1, :) - a.edges(e).targets(1).position) < 1e-9 ...
            && norm(Pa(end, :) - a.edges(e).targets(2).position) < 1e-9;
        for i = 1:size(Pa, 1) - 1
            for w = 1:size(a.walls, 1)
                cross = cross + crosses(Pa(i, :), Pa(i + 1, :), a.walls(w, 1:2), a.walls(w, 3:4));
            end
        end
        longer = max(longer, sum(vecnorm(diff(Pa), 2, 2)) / sum(vecnorm(diff(Pd), 2, 2)) - 1);
    end
    check(ends && cross == 0 && longer <= 0.05, sprintf('Grid A* on "%s": ends at the targets, %d wall crossings, at most %.1f%% longer than Dijkstra Corners', ...
        cat.Name(k), cross, 100 * longer));
end

if isempty(failures)
    fprintf('\nextensionTest PASSED: %d checks\n', nChecks);
else
    error('extensionTest:Failed', 'extensionTest FAILED %d of %d checks:\n  %s', ...
        numel(failures), nChecks, strjoin(failures, newline + "  "));
end

    function check(ok, label)
        nChecks = nChecks + 1;
        if ok
            fprintf('PASS  %s\n', label);
        else
            fprintf('FAIL  %s\n', label);
            failures(end+1) = string(label);
        end
    end
end

function h = crosses(a, b, c, d)
% Do segments ab and cd cross (end points excluded)?
den = (d(2)-c(2))*(b(1)-a(1)) - (d(1)-c(1))*(b(2)-a(2));
if abs(den) < 1e-12, h = false; return; end
ua = ((d(1)-c(1))*(a(2)-c(2)) - (d(2)-c(2))*(a(1)-c(1))) / den;
ub = ((b(1)-a(1))*(a(2)-c(2)) - (b(2)-a(2))*(a(1)-c(1))) / den;
h = ua > 1e-9 && ua < 1-1e-9 && ub > 1e-9 && ub < 1-1e-9;
end
