classdef SimpleAgent < Agent
    % An agent that moves at its top speed straight from one path point to the next
    methods
        function obj = SimpleAgent(index, position, maxSpeed)
            obj@Agent(index, position, maxSpeed);
            obj.color = [0.15 0.45 0.80];
        end

        function update(obj, dt)
            step = obj.state.maxSpeed * dt;                  % distance to cover in this step
            start = obj.state.pos;
            while step > 0 && ~isempty(obj.path)
                d = obj.path(1, :) - obj.state.pos;
                if norm(d) <= step                           % reach the next path point
                    obj.state.pos = obj.path(1, :);
                    obj.path(1, :) = [];
                    step = step - norm(d);
                else
                    obj.state.pos = obj.state.pos + step * d / norm(d);
                    step = 0;
                end
            end
            obj.state.vel = (obj.state.pos - start) / dt;
            if norm(obj.state.vel) > 0
                obj.state.ori = atan2(obj.state.vel(2), obj.state.vel(1));
                obj.mode = "traveling";
            else
                obj.mode = "idle";
            end
            obj.calculate_energy(dt);                        % battery drain
            obj.updateVisuals();
        end
    end
end
