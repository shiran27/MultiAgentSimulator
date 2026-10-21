function T = scenarioCatalog()
% Ready-made scenarios for the GUI's Scenario dropdown (and MainUI.loadScenario): name, layout
% file and a one-line description. Each layout holds the targets, edges, walls and agent starts;
% the maps also name a background image (Configurations/backgrounds/, drawn by
% makeScenarioLayouts). Agents take the selected Agent Type, so every scenario runs with either
% agent type and any policy.
here = fileparts(mfilename('fullpath'));
rows = {
    "Lab floor (Stevens)", "ReportLayout.mat",  "Stevens lab floor plan: 11 targets, 5 agents (the simulator paper's reference scenario)."
    "City blocks",         "CityBlocks.mat",    "Street grid with eight city blocks and a park: 11 sites, 4 agents."
    "Harbor patrol",       "HarborPatrol.mat",  "Harbor, piers, breakwater and two islands: 12 buoys and berths, 3 boats."
    "Campus",              "Campus.mat",        "Building complex with a pond, quad and parking: 11 sites, 5 agents."
    "JS: 1 agent, 3 targets",  "Legacy/JS_1Agent_3T.mat",      "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    "JS: 1 agent, 4 targets",  "Legacy/JS_1Agent_4T.mat",      "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    "JS: 1 agent, 5 targets",  "Legacy/JS_1Agent_5T.mat",      "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    "JS: 2 agents, 5 targets", "Legacy/JS_2Agent_5T.mat",      "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    "JS: 3 agents, 9 targets", "Legacy/JS_3Agent_9T.mat",      "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    "JS: 3 agents, maze",      "Legacy/JS_3Agent_Maze.mat",    "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    "JS: 3 agents, general",   "Legacy/JS_3Agent_General.mat", "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    "JS: 3 agents, room",      "Legacy/JS_3Agent_Room.mat",    "Preset of the legacy JS simulator (RHC papers), scaled to the canvas."
    };
T = table([rows{:, 1}]', fullfile(here, [rows{:, 2}]'), [rows{:, 3}]', ...
    'VariableNames', {'Name', 'File', 'Description'});
end
