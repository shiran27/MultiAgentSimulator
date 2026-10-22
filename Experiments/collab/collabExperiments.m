function out = collabExperiments(mode, opts)
% Experiments of the collaboration paper (W. Getts and S. Welikala, "Collaborative persistent
% monitoring", in preparation): Collab-ED-RHC (CollabEDRHCPolicy) against ED-RHC and ED-RHC-alpha
% (EDRHCPolicy) on the benchmark configurations of Welikala and Cassandras, Automatica 2021
% (Configurations/Legacy, the JavaScript presets), on targets that only a group of agents can
% clear (A_i > B_i), and with growing team sizes.
%   collabExperiments("list")                  the runs (one row each)
%   collabExperiments("run", Part=k, Parts=P)  runs the runs with mod(id, P) == k - 1 and saves
%                                              each one to results/collab/runs/<id>.mat
%   collabExperiments("collect")               builds the tables (LaTeX) and figures in
%                                              results/collab/ from the saved runs
% Settings (all runs): first-order agents (Linear Agent) at the preset's speed, A_i = 1 and
% B_i = 10 unless stated, R_i(0) = 0.5, T = 500 s, dt = 0.02 s, H = 250, service only at the target.
arguments
    mode string {mustBeMember(mode, ["list", "run", "collect"])} = "list"
    opts.Part (1,1) double = 1
    opts.Parts (1,1) double = 1
    opts.Dt (1,1) double = 0.02
    opts.EndTime (1,1) double = 500
end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
resDir = fullfile(root, 'results', 'collab');
runDir = fullfile(resDir, 'runs');
L = runList(opts);
switch mode
    case "list"
        out = L;
    case "run"
        if ~isfolder(runDir), mkdir(runDir); end
        for id = find(mod((1:height(L))' - 1, opts.Parts) == opts.Part - 1)'
            file = fullfile(runDir, sprintf('%03d.mat', id));
            if isfile(file), continue; end
            p = L.Params{id};
            tic; o = runTrial(p); sec = toc;
            r = struct('id', id, 'study', L.Study(id), 'scenario', L.Scenario(id), ...
                'method', L.Method(id), 'J', o.finalJ, 'seconds', sec, 'peakR', o.peakR, ...
                'coLocation', o.coLocationTime, 't', o.log.t(1:50:end), 'Jt', o.log.J(1:50:end), ...
                'R', o.log.R(1:50:end, :));
            r.stats = struct();
            if isprop(o.policy, 'stats') && isstruct(o.policy.stats), r.stats = o.policy.stats; end
            save(file, 'r');
            fprintf('%3d %-8s %-22s %-24s J = %9.3f  %6.0f s\n', id, L.Study(id), L.Scenario(id), L.Method(id), o.finalJ, sec);
        end
        out = [];
    case "collect"
        out = collect(L, runDir, resDir);
end
end

function L = runList(opts)
presets = ["JS_1Agent_3T", "JS_1Agent_4T", "JS_1Agent_5T", "JS_2Agent_5T", ...
    "JS_3Agent_9T", "JS_3Agent_Maze", "JS_3Agent_General", "JS_3Agent_Room"];
main = methods(["ED-RHC", "ED-RHC-alpha", "Collab-A", "Collab-B"]);
ablation = methods(["Collab-B-noterminal", "Collab-B-history", "Collab-A-noshare"]);
rows = {};
for k = 1:numel(presets)
    for m = [main, ablation]
        rows(end+1, :) = {"bench", presets(k), m.label, params(presets(k), m.params, opts)}; %#ok<AGROW>
    end
end
% targets that only a group of agents can clear: A = 12 > B = 10 at two targets
group = struct('JS_2Agent_5T', 3, 'JS_3Agent_General', [3 8]);
for name = string(fieldnames(group))'
    for m = main
        p = params(name, m.params, opts);
        A = ones(1, numTargets(name)); A(group.(name)) = 12;
        p.TargetA = A;
        rows(end+1, :) = {"group", name, m.label, p}; %#ok<AGROW>
    end
end
% team size: the 10-target General configuration with N = 2..6 agents spread over the targets
for n = 2:6
    for m = methods(["ED-RHC", "ED-RHC-alpha", "Collab-B"])
        p = params("JS_3Agent_General", m.params, opts);
        p.AgentStarts = "auto"; p.NumAgents = n;
        rows(end+1, :) = {"scale", "General_N" + n, m.label, p}; %#ok<AGROW>
    end
end
L = cell2table(rows, 'VariableNames', {'Study', 'Scenario', 'Method', 'Params'});
end

function M = methods(labels)
all = struct( ...
    'ED_RHC', struct('Policy', "ED-RHC", 'Policy_alpha', 0.5), ...
    'ED_RHC_alpha', struct('Policy', "ED-RHC", 'Policy_alpha', "nominal"), ...
    'Collab_A', struct('Policy', "Collab-ED-RHC", 'Policy_coordination', "A"), ...
    'Collab_B', struct('Policy', "Collab-ED-RHC", 'Policy_coordination', "B"), ...
    'Collab_B_noterminal', struct('Policy', "Collab-ED-RHC", 'Policy_coordination', "B", 'Policy_terminal', "none"), ...
    'Collab_B_history', struct('Policy', "Collab-ED-RHC", 'Policy_coordination', "B", 'Policy_deltaRule', "history"), ...
    'Collab_A_noshare', struct('Policy', "Collab-ED-RHC", 'Policy_coordination', "A", 'Policy_sharing', false));
M = struct('label', {}, 'params', {});
for l = labels
    M(end+1) = struct('label', l, 'params', all.(strrep(l, '-', '_'))); %#ok<AGROW>
end
end

function p = params(preset, extra, opts)
s = load(fullfile(fileparts(which('MainUI')), 'Configurations', 'Legacy', preset + ".mat"), 's');
p = struct('Layout', fullfile("Legacy", preset + ".mat"), 'AgentStarts', "layout", ...
    'Planner', "Dijkstra Corners", 'AgentType', "Linear Agent", ...
    'UncertaintyMode', "Static Uniform", 'A_base', 1, 'B', 10, 'EndTime', opts.EndTime, ...
    'Dt', opts.Dt, 'DetectionRadius', 1e-6, 'Policy_H', 250, 'AgentSpeed', s.s.agentSpeed(1), ...
    'Log', true);
f = fieldnames(extra);
for q = 1:numel(f), p.(f{q}) = extra.(f{q}); end
end

function n = numTargets(preset)
s = load(fullfile(fileparts(which('MainUI')), 'Configurations', 'Legacy', preset + ".mat"), 's');
n = size(s.s.targets, 1);
end

function T = collect(L, runDir, resDir)
rows = {};
for id = 1:height(L)
    file = fullfile(runDir, sprintf('%03d.mat', id));
    if ~isfile(file), continue; end
    S = load(file); r = S.r;
    st = r.stats;
    get = @(f) ifelse(isfield(st, f), st, f);
    rows(end+1, :) = {id, L.Study(id), L.Scenario(id), L.Method(id), r.J, r.seconds, r.peakR, ...
        r.coLocation, get('solves'), get('cpu'), get('shiftEvents'), get('shifts'), eventsOf(st)}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'Id', 'Study', 'Scenario', 'Method', 'J', 'Seconds', 'PeakR', ...
    'CoLocation', 'Solves', 'SolveCPU', 'ShiftEvents', 'Shifts', 'Events'});
writetable(T, fullfile(resDir, 'runs.csv'));
writeTables(T, resDir);
makeFigures(L, T, runDir, resDir);
end

function writeTables(T, resDir)
% LaTeX tables: J_T of the benchmark configurations (main methods; ablations), the group study,
% and the team-size study
presets = ["JS_1Agent_3T", "JS_1Agent_4T", "JS_1Agent_5T", "JS_2Agent_5T", "JS_3Agent_9T", ...
    "JS_3Agent_Maze", "JS_3Agent_General", "JS_3Agent_Room"];
names = ["1A-3T", "1A-4T", "1A-5T", "2A-5T", "3A-9T", "3A-Maze", "3A-General", "3A-Room"];
tab(fullfile(resDir, 'tab_bench.tex'), T(T.Study == "bench", :), presets, names, ...
    ["ED-RHC", "ED-RHC-alpha", "Collab-A", "Collab-B"], ...
    ["ED-RHC", "ED-RHC-$\alpha$", "Collab (A)", "Collab (B)"]);
tab(fullfile(resDir, 'tab_ablation.tex'), T(T.Study == "bench", :), presets, names, ...
    ["Collab-B", "Collab-B-noterminal", "Collab-B-history", "Collab-A-noshare"], ...
    ["(B)", "(B), $\hat h\equiv 0$", "(B), $\delta_k=\bar\delta_k$", "(A), no sharing"]);
tab(fullfile(resDir, 'tab_group.tex'), T(T.Study == "group", :), ["JS_2Agent_5T", "JS_3Agent_General"], ...
    ["2A-5T", "3A-General"], ["ED-RHC", "ED-RHC-alpha", "Collab-A", "Collab-B"], ...
    ["ED-RHC", "ED-RHC-$\alpha$", "Collab (A)", "Collab (B)"]);
S = T(T.Study == "scale", :);
fid = fopen(fullfile(resDir, 'tab_scale.tex'), 'w');
fprintf(fid, '%% generated by collabExperiments("collect")\n');
for n = 2:6
    r = @(m) S(S.Scenario == "General_N" + n & S.Method == m, :);
    e = r("ED-RHC"); a = r("ED-RHC-alpha"); c = r("Collab-B");
    if isempty(e) || isempty(a) || isempty(c), continue; end
    fprintf(fid, '%d & %.1f & %.1f & %.1f & %.1f & %.0f & %.0f \\\\ \\hline\n', n, e.J, a.J, c.J, ...
        100 * (c.J - e.J) / e.J, 1000 * c.SolveCPU / c.Solves, c.ShiftEvents);
end
fclose(fid);
end

function tab(file, T, presets, names, methods, heads)
fid = fopen(file, 'w');
fprintf(fid, '%% generated by collabExperiments("collect")\n');
fprintf(fid, 'Config. & %s \\\\ \\hline\n', strjoin(heads, ' & '));
for k = 1:numel(presets)
    v = nan(1, numel(methods));
    for m = 1:numel(methods)
        r = T(T.Scenario == presets(k) & T.Method == methods(m), :);
        if ~isempty(r), v(m) = r.J(1); end
    end
    [~, b] = min(v);
    cells = arrayfun(@(x) sprintf('%.1f', x), v, 'UniformOutput', false);
    cells{b} = ['\textbf{' cells{b} '}'];
    fprintf(fid, '%s & %s \\\\ \\hline\n', names(k), strjoin(cells, ' & '));
end
fclose(fid);
end

function makeFigures(L, T, runDir, resDir)
% Fig. A: J(t) on 2A-5T and 3A-General under the four main methods; Fig. B: R_i(t) of the group targets on
% 3A-General under ED-RHC and Collab (B); Fig. C: J_T and CPU per solve against the team size
methods = ["ED-RHC", "ED-RHC-alpha", "Collab-A", "Collab-B"];
labels = ["ED-RHC", "ED-RHC-$\alpha$", "Collab (A)", "Collab (B)"];
colors = [0.0 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19; 0.49 0.18 0.56];
f = figure('Visible', 'off', 'Units', 'inches', 'Position', [0 0 3.5 2.5]);
tl = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for sc = ["JS_2Agent_5T", "JS_3Agent_General"]
    nexttile; hold on; grid on; box on;
    for m = 1:numel(methods)
        r = loadRun(L, runDir, "bench", sc, methods(m));
        if isempty(r), continue; end
        plot(r.t, r.Jt, 'LineWidth', 1.1, 'Color', colors(m, :), 'DisplayName', labels(m));
    end
    title(replace(sc, ["JS_2Agent_5T", "JS_3Agent_General"], ["2A-5T", "3A-General"]), ...
        'Interpreter', 'latex', 'FontWeight', 'normal');
    xlabel('Time: $t$ [s]', 'Interpreter', 'latex');
    set(gca, 'FontSize', 8, 'TickLabelInterpreter', 'latex');
    if sc == "JS_3Agent_General"
        legend('Interpreter', 'latex', 'Location', 'southeast', 'Box', 'on', 'FontSize', 7);
    end
end
ylabel(tl, 'Objective: $J(t)$', 'Interpreter', 'latex', 'FontSize', 9);
exportgraphics(f, fullfile(resDir, 'fig_J_general.pdf'), 'ContentType', 'vector'); close(f);

f = figure('Visible', 'off', 'Units', 'inches', 'Position', [0 0 3.5 2.4]);
tl = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for m = ["ED-RHC", "Collab-B"]
    nexttile; hold on; grid on; box on;
    r = loadRun(L, runDir, "group", "JS_3Agent_General", m);
    if isempty(r), continue; end
    plot(r.t, r.R(:, [3 8]), 'LineWidth', 1.1);
    title(strrep(strrep(m, "Collab-B", "Collab (B)"), "-", "-"), 'Interpreter', 'latex', 'FontWeight', 'normal');
    xlabel('Time: $t$ [s]', 'Interpreter', 'latex');
    set(gca, 'FontSize', 9, 'TickLabelInterpreter', 'latex');
end
ylabel(tl, 'Uncertainty: $R_i(t)$, $i\in\{3,8\}$', 'Interpreter', 'latex', 'FontSize', 9);
exportgraphics(f, fullfile(resDir, 'fig_R_group.pdf'), 'ContentType', 'vector'); close(f);
end

function r = loadRun(L, runDir, study, scenario, method)
r = [];
id = find(L.Study == study & L.Scenario == scenario & L.Method == method, 1);
file = fullfile(runDir, sprintf('%03d.mat', id));
if ~isempty(id) && isfile(file), S = load(file); r = S.r; end
end

function v = ifelse(ok, st, f)
if ok, v = st.(f); else, v = NaN; end
end

function e = eventsOf(st)
if isfield(st, 'events'), e = sum(st.events); else, e = NaN; end
end
