classdef EventTarget < Target
    % A target where events (an intrusion, a fault, a customer) occur at random, at eventRate
    % per second, and each lasts lifetime seconds. An agent at the target detects every event
    % in progress; an event that ends first is missed. R, the number of events in progress, is
    % what the target's bar shows and what J(t) averages.
    properties
        eventRate = 0.02   % events per second (a Poisson process)
        lifetime = 25      % seconds an event lasts
        startTimes = []    % start times of the events in progress
        detected = 0       % events detected so far
        missed = 0         % events missed so far
    end

    methods
        function obj = EventTarget(index, position)
            obj@Target(index, position);
        end

        function updateUncertainty(obj, dt, simTime, ~)
            if rand() < obj.eventRate * dt                     % a new event
                obj.startTimes(end+1) = simTime;
            end
            over = simTime - obj.startTimes >= obj.lifetime;   % events that ended undetected
            obj.missed = obj.missed + nnz(over);
            obj.startTimes(over) = [];
            if ~isempty(obj.residingAgents)                    % an agent is here: detect all
                obj.detected = obj.detected + numel(obj.startTimes);
                obj.startTimes = [];
            end
            obj.R = numel(obj.startTimes);
        end

        function reset(obj)
            reset@Target(obj);
            obj.startTimes = []; obj.detected = 0; obj.missed = 0;
            obj.R = 0;
        end
    end
end
