classdef Battery < handle
    % An agent's battery: capacity and power model, and the energy drawn so far.
    %   P = (P_cpu + P_comp + P0 + alphaVel |v| + gammaAcc |a|^2) / eta
    % with the processor and communication loads of a moving or idle agent. Every agent holds
    % one (Agent.battery); different platforms can use different parameters (AgentSpec
    % batteryWh, or set them on agent.battery). The battery is reported (SOC); an agent stops
    % when it is empty only if its stopWhenEmpty is true.
    properties
        capacityWh = 26.0                 % capacity [Wh]
        P0 = 5.82                         % base motion power [W]
        alphaVel = 0.02 * 10 * 9.81       % rolling resistance: power per unit speed
        gammaAcc = 0.5                    % power per unit squared acceleration
        cpuMove = 5.5                     % processor power while moving / idle [W]
        cpuIdle = 4.0
        commActive = 11.7                 % communication power while moving / idle [W]
        commStandby = 11.0
        eta = 0.90                        % converter efficiency
        energyUsed = 0                    % energy drawn so far [J]
    end

    properties (Dependent)
        soc                               % state of charge in [0, 1]
        percentage                        % state of charge in percent, at least 0
    end

    methods
        function obj = Battery(opts)
            arguments
                opts.CapacityWh double = 26.0
            end
            obj.capacityWh = opts.CapacityWh;
        end

        function drain(obj, speed, accel, moving, dt)
            % Energy drawn over dt at the given speed and |acceleration|
            if moving
                pLoad = obj.cpuMove + obj.commActive;
            else
                pLoad = obj.cpuIdle + obj.commStandby;
            end
            pMotion = obj.P0 + obj.alphaVel * speed + obj.gammaAcc * accel^2;
            obj.energyUsed = obj.energyUsed + (pLoad + pMotion) / obj.eta * dt;
        end

        function reset(obj)
            obj.energyUsed = 0;
        end

        function s = get.soc(obj)
            s = 1 - obj.energyUsed / (obj.capacityWh * 3600);
        end

        function p = get.percentage(obj)
            p = max(0, 100 * obj.soc);
        end
    end
end
