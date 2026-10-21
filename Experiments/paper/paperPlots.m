function f = paperPlots(kind, R, file)
% Result plots of the simulator paper, sized for one IEEE column and saved as file.png/.pdf:
%   paperPlots("objectives", R, file)  Fig. 9: J(t) of every policy, with Abstract Agents (a) and
%                                      Physical Agents (b); Random Walk as the mean over its
%                                      seeds with the range shaded
%   paperPlots("tradeoff", R, file)    Fig. 11: J(T) against J_e for ED-ORHC-SO as the energy
%                                      weight grows (beta values marked)
%   paperPlots("soc", R, file)         Fig. 12: SOC(t) of every agent under Battery-Aware ED-RHC
%                                      (a) and ED-RHC (b), Physical Agents on the charging-dock
%                                      scenario
% R is the output of paperRuns. The figure opens on the secondary monitor when there is one.
arguments
    kind (1,1) string
    R (1,1) struct
    file (1,1) string
end
switch kind
    case "objectives"
        f = paperFigure(3.5, 4.2);
        t = tiledlayout(f, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
        for g = ["Abstract", "Physical"]
            ax = nexttile(t); hold(ax, 'on');
            idx = find(endsWith(R.Labels, "/ " + g));
            for c = idx
                name = extractBefore(R.Labels(c), " /");
                curves = R.Curves(c, ~cellfun(@isempty, R.Curves(c, :)));
                tt = curves{1}.t;
                J = cell2mat(cellfun(@(cv) cv.J(:), curves, 'UniformOutput', false));
                if size(J, 2) > 1
                    fill(ax, [tt; flipud(tt)], [min(J, [], 2); flipud(max(J, [], 2))], [0.7 0.7 0.7], ...
                        'EdgeColor', 'none', 'FaceAlpha', 0.4, 'HandleVisibility', 'off');
                end
                plot(ax, tt, mean(J, 2), 'LineWidth', 1.2, 'DisplayName', char(name));
            end
            ylabel(ax, 'Objective: $J(t)$', 'Interpreter', 'latex');
            title(ax, sprintf('(%s) %s Agents', char('a' + (g == "Physical")), g), 'FontWeight', 'normal', ...
                'Interpreter', 'latex', 'FontSize', 9);
            style(ax);
            set(ax, 'YScale', 'log');
            xlim(ax, [0 tt(end)]);
            if g == "Abstract", legend(ax, 'Location', 'northeast', 'Interpreter', 'latex', 'Box', 'on', 'FontSize', 7); end
        end
        xlabel(ax, 'Time: $t$ [s]', 'Interpreter', 'latex');
    case "tradeoff"
        f = paperFigure(3.5, 2.5);
        ax = axes(f); hold(ax, 'on');
        T = paperTables("tradeoff", R);
        plot(ax, T.Je, T.J, '-o', 'LineWidth', 1.2, 'MarkerSize', 4, 'MarkerFaceColor', 'w');
        for k = 1:height(T)
            text(ax, T.Je(k), T.J(k), sprintf('  %g', T.Beta(k)), 'FontSize', 7, 'Interpreter', 'latex', ...
                'VerticalAlignment', 'bottom');
        end
        set(ax, 'XScale', 'log');
        xlabel(ax, 'Energy objective: $J_e$', 'Interpreter', 'latex');
        ylabel(ax, 'Objective: $J(T)$', 'Interpreter', 'latex');
        style(ax);
    case "soc"
        f = paperFigure(3.5, 4.0);
        t = tiledlayout(f, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
        picks = ["Battery-Aware ED-RHC / Physical", "ED-RHC / Physical"];
        for k = 1:2
            ax = nexttile(t); hold(ax, 'on');
            c = find(R.Labels == picks(k), 1);
            cv = R.Curves{c, 1};
            for a = 1:size(cv.SOCs, 2)
                plot(ax, cv.t, cv.SOCs(:, a), 'LineWidth', 1.1, 'DisplayName', sprintf('Agent %d', a));
            end
            ylabel(ax, 'SOC$(t)$ [\%]', 'Interpreter', 'latex');
            title(ax, sprintf('(%s) %s', char('a' + k - 1), extractBefore(picks(k), " /")), ...
                'FontWeight', 'normal', 'Interpreter', 'latex', 'FontSize', 9);
            style(ax);
            ylim(ax, [0 100]); xlim(ax, [0 cv.t(end)]);
            if k == 1, legend(ax, 'Location', 'southeast', 'Interpreter', 'latex', 'Box', 'on', 'FontSize', 7); end
        end
        xlabel(ax, 'Time: $t$ [s]', 'Interpreter', 'latex');
    otherwise
        error('paperPlots:UnknownKind', 'Unknown plot "%s"', kind);
end
saveFigure(f, file);
end

function style(ax)
set(ax, 'FontSize', 8, 'TickLabelInterpreter', 'latex', 'Box', 'on');
grid(ax, 'on');
ax.GridAlpha = 0.15;
end

function saveFigure(f, file)
[d, ~] = fileparts(file);
if d ~= "" && ~isfolder(d), mkdir(d); end
exportgraphics(f, file + ".png", 'Resolution', 300);
exportgraphics(f, file + ".pdf", 'ContentType', 'vector');
end
