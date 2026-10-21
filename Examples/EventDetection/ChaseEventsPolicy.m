classdef ChaseEventsPolicy < Policy
    % Go to the neighbor with the largest R (with EventTarget: the most events in progress)
    % that no other agent is at or heading to; if every such neighbor has R = 0, go to the one
    % visited longest ago
    methods
        function cmd = plan(~, agent, model, adj, i, ~)
            cmd = struct();                                  % stay (no free neighbor)
            idx = [model.agents.index];
            others = model.agents(idx ~= agent.index);
            busy = [others.current_target_idx];              % targets other agents hold
            free = setdiff(find(adj(i, :)), busy);
            if isempty(free), return; end
            tg = model.targets(free);
            [R, k] = max([tg.R]);
            if R == 0
                [~, k] = min([tg.lastVisitedTime]);
            end
            cmd.kind = "move";
            cmd.targetIdx = free(k);
        end
    end
end
