function cond = paperConditions(name)
% Conditions of the simulator paper's experiments (Sec. IV), as input to paperRuns. Each
% condition overrides paperDefaults (ED-RHC, Dijkstra Corners, Physical Agent):
%   "policy"   Table II, Figs. 10-11: Random Walk vs ED-RHC
%   "planner"  Table III, Fig. 12: Dijkstra Corners vs Energy Efficient (ED-RHC)
%   "battery"  Table IV, Fig. 13: as "planner" (every agent now carries a battery)
% (The draft compared Random Walk with Gabriel's Battery Efficient heuristic, retired on
% 2026-10-21; ED-RHC takes its place.)
arguments
    name (1,1) string
end
switch name
    case "policy"
        labels = ["Random Walk", "ED-RHC"];
        params = {struct('Policy', "Random Walk"), struct('Policy', "ED-RHC")};
    case "planner"
        labels = ["Dijkstra", "Energy Efficient"];
        params = {struct('Planner', "Dijkstra Corners"), struct('Planner', "Energy Efficient")};
    case "battery"
        labels = ["Dijkstra", "Energy Efficient"];
        params = {struct('Planner', "Dijkstra Corners", 'AgentType', "Physical Agent"), ...
                  struct('Planner', "Energy Efficient", 'AgentType', "Physical Agent")};
    otherwise
        error('paperConditions:UnknownName', 'Unknown experiment "%s"', name);
end
cond = struct('Label', num2cell(labels), 'Params', params);
end
