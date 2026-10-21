classdef MissedEvents < Metric
    % Share of the events that ended before an agent detected them (NaN without EventTargets)
    methods
        function obj = MissedEvents()
            obj.label = "Share of events missed";
            obj.plotMax = 1;
        end

        function v = value(~, model, ~)
            tg = model.targets(arrayfun(@(t) isa(t, 'EventTarget'), model.targets));
            v = NaN;
            if isempty(tg), return; end
            n = sum([tg.missed]) + sum([tg.detected]);
            v = sum([tg.missed]) / max(n, 1);
        end
    end
end
