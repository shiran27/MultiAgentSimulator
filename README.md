# MultiAgentSimulator

A MATLAB simulator for experimenting with multi-agent path planning, navigation policies, and agent behavior. Agents move between targets on a user-drawn graph, avoiding walls, while an objective function tracks how well the swarm covers the environment over time.

The project is designed around five **modular areas** so new algorithms can be dropped in and compared side-by-side from the UI:

- **Path Planner** — how a path between two targets is computed (Dijkstra Corners, Energy Efficient, Grid A*).
- **Agent Policy** — how an agent decides which target to go to next (base class `Policy`).
- **Agent Type** — the agent class itself (its dynamics, state, energy model, rendering, etc.; base class `Agent`).
- **Target Type** — what a target's state is and how it evolves (base class `Target`).
- **Metric** — how a run is scored; the first one is the objective plotted over time (base class `Metric`).

New to the simulator? `Examples/EventDetection/` sets up a new monitoring problem from scratch (see [Getting started](#getting-started-a-new-monitoring-problem)).

## Examples

### Main UI
The application on launch — Modular Components bar on top, Tools panel on the left, Time Control below, canvas on the right.

![Main UI overview](screenshots/overview.png)

### Building a scenario
Targets, edges, and walls drawn on the canvas before running the simulation.

![Scenario with targets, edges, and walls](screenshots/scenario.png)

### Simulation running
Agents following their paths mid-simulation. The Modular Components dropdowns are locked while the sim is active.

![Simulation in progress](screenshots/running.png)

### Objective plot
The objective function `J(t)` tracked over the course of a run.

![Objective function over time](screenshots/objective.png)

## Running the project

1. Open MATLAB and set the working directory to the repo root (`MultiAgentSimulator`).
2. In the Command Window, run:
   ```matlab
   runMainUI
   ```
   This adds all subfolders to the path and opens the UI. `runMainUI('Monitor', 2)` opens the windows on
   another monitor (a row of `get(groot, 'MonitorPositions')`), sized to fit it.
3. Pick a ready-made scenario from the **Scenario** dropdown (see [Scenarios](#scenarios)), or build your own. Use the dropdowns in the **Tools** panel to pick a Path Planner, Agent Policy, Agent Type, and Uncertainty mode. These can only be changed while the simulation is **not** running.
4. Use the **Tools** panel to add targets, agents, edges, and walls. **Agent Speed**, **Agent Accel** and **Speed Profile** set the next agents you place (see [Agent types](#agent-types)). Use the **Time Control** panel to play/pause the simulation.

## Scenarios

The **Scenario** dropdown (top of the Tools panel; `MainUI.loadScenario(name)` in code) loads a ready-made scenario in one click: background map, targets, edges, walls and agents. The agents take the selected **Agent Type**, so every scenario runs with either agent type and any policy. When the agents do not suit the policy (see the compatibility table below), the status line says what to expect.

| Scenario | Layout | What it is |
|---|---|---|
| Lab floor (Stevens) | `ReportLayout.mat` | Stevens lab floor plan; 11 targets, 5 agents; the simulator paper's reference scenario |
| Office floor | `OfficeFloor.mat` | One floor of an office and lab building: eight rooms with doors (gaps in the walls), a hall and a lobby; 14 targets in rooms and halls, 3 robots |
| Office floor with charging dock | `OfficeDock.mat` | The office floor with a charging station (300 W dock by the lobby) and small batteries (2.5 Wh, about four minutes of operation; the robots stop when empty): the scenario of [Battery-aware ED-RHC](#battery-aware-ed-rhc-and-charging-stations) |
| City patrol | `CityPatrol.mat` | Police patrol on a street grid: 16 intersections and 5 sites (police HQ, bank, school, mall, hospital); every edge runs along a road, so the 4 patrol cars stay on the roads; the nine blocks are obstacles |
| Harbor patrol | `HarborPatrol.mat` | Coast with a port, piers and a breakwater, two islands; 12 buoys and berths, 3 boats |
| Campus | `Campus.mat` | Zoomed-out building complex: six buildings and a pond (obstacles), quad, parking; 11 sites, 5 agents |
| Museum (event detection example) | `Museum.mat` | The beginner's example: four galleries around a hall, event targets (`SimpleTarget`), 3 robots at speed 4; every wall and target on the GUI's click grid |
| JS: ... | `Legacy/JS_*.mat` | The eight presets of the legacy JS simulator (RHC papers), scaled to the canvas |

`Configurations/scenarioCatalog.m` lists them. `Configurations/makeScenarioLayouts.m` draws the maps (`Configurations/backgrounds/*.png`) and writes their layouts from the same geometry, so walls line up with the drawn walls, buildings, coasts and piers. It also restyles the lab floor plan (`LabLayout.png`) in the same palette as `backgrounds/LabFloor.png`. Edit it to change a scenario, or add a row to the catalog for a new layout file.

## Target uncertainty and defaults

Each target's uncertainty follows `dR_i/dt = (A_i - B_i N_i) v_i`, where `N_i` is the number of agents at rest at the target (see [Agent types](#agent-types)) and `v_i` keeps `R_i >= 0`. The defaults match the simulator paper:

| Parameter | Default |
|---|---|
| Uncertainty mode | `Static Uniform` (constant `A_i`) |
| Growth rate `A_i` | 1 for every target |
| Decay rate `B_i` (per agent) | 10 |
| Initial uncertainty `R_i(0)` | 0 |

The other modes are opt-in from the **Uncertainty** dropdown:
- `Static Priority Target` — target 1 grows at `A = 5`, the rest at their `A_i`.
- `Dynamic Uncertainty` — as above, plus periodic spikes: every target's rate jumps to `A_spike = 14` for 10 s every 250 s, staggered by 50 s from one target to the next. With `B = 10`, one agent cannot bring a spiking target down (`14 - 10 > 0`) but two can (`14 - 2*10 < 0`).

The experiment harness (`Experiments/runTrial`, `Experiments/trialDefaults.m`) sets its own uncertainty parameters for every trial (by default `Dynamic Uncertainty` with `B = 20` and `A_spike = 28`, the same one-agent/two-agent balance), so its results do not depend on these GUI defaults.

## Layout files

**Save Layout...** / **Load Layout...** (and `ScenarioModel.exportLayout` / `importLayout`) use a `.mat` file holding a struct `s`:

| Field | Meaning |
|---|---|
| `targets` | `n x 2` target positions |
| `edges` | `m x 2` target index pairs |
| `walls` | `k x 4` wall segments `[x1 y1 x2 y2]` |
| `agentStarts` | start target index of each agent |
| `agentSpeed` | maximum speed of each agent (or one value for all) |
| `agentAccel` | maximum acceleration of each agent (or one value for all) |
| `agentProfile` | speed profile of each agent: `"constant"`, `"SO"` or `"FO"` |
| `agentBatteryWh` | battery capacity of each agent [Wh] (or one value for all) |
| `agentStopWhenEmpty` | 1 if an agent stops when its battery is empty (or one value for all) |
| `chargers`, `chargePower` | targets that are charging stations (`ChargingStation`), and their charging power [W] |
| `background` | background image (a file in `Configurations/backgrounds/`, the project root, or a full path) |
| `uncertaintyMode` | one of the modes above |
| `A`, `B`, `R0` | per-target `A_i`, `B_i`, `R_i(0)` (`n x 1`, or one value for all) |

Only `targets` and `edges` are required, so files saved by older versions still load: missing fields keep the defaults above (agents take the GUI's Agent Accel and Speed Profile) and no agents are placed. Loaded agents use the Agent Type selected in the dropdown. `runTrial` ignores stored agents and places its own from the `AgentStarts` parameter.

`Configurations/ReportLayout.mat` is the reference scenario of the simulator paper (Stevens Smart Lab, background `LabFloor.png`: `LabLayout.png` recolored, without the diamond-shaped block in the middle): 11 targets, 10 edges, 92 walls (3 placed by hand plus 89 traced from the floor plan by `makeScenarioLayouts`, so routes stay on the open floor), and 5 agents at speed 15 starting on targets **1, 6, 2, 3, 5** (agent 1 on target 1, agent 2 on target 6, and so on), in `Static Uniform` mode with `A = 1`, `B = 10`, `R(0) = 0`.

## Smoke test

Run from the repo root before opening a pull request:
```
matlab -batch "addpath(genpath(pwd)); smokeTest"
```
`tests/smokeTest.m` checks the defaults and the layout file round trip, then runs every registered policy x path planner x agent type for 20 s on `ReportLayout.mat` and checks that each run finishes with a finite objective `J`. It also checks the agent types (older names, every speed profile, service only at rest, Physical Agents arriving when planned, smooth heading), that William's Joint RHC harness runs, every catalog scenario, and the battery model (predicted transit energy, Battery-Aware ED-RHC recharging in time while ED-RHC runs out). It prints one line per check and exits with an error if any check fails (about 20 s). New components registered in `ComponentRegistry` are picked up automatically.

`tests/guiTest.m` drives the real GUI with MATLAB's App Testing Framework: it loads `ReportLayout.mat` over the lab background and runs to the end, plays, pauses and resets, saves, clears and reloads a layout, builds a small scenario by clicking, and checks that a GUI run and a headless `runTrial` give the same `J`. It needs a display; the windows open on a secondary monitor if there is one and close when it finishes (about 50 s):
```
matlab -batch "addpath(genpath(pwd)); assertSuccess(runtests('guiTest'))"
```
Screenshots of each stage are written to `results/gui/` (git-ignored).

`tests/extensionTest.m` checks the extension points: switching target types, the metrics and `runTrial`'s `metricValues`, the event-detection example, and the Grid A* planner on every map (no wall crossings):
```
matlab -batch "addpath(genpath(pwd)); extensionTest"
```

## Agent types

There are two agent types (`Components/AgentTypes/`): the **Abstract Agent**, an idealized model that executes its plan exactly (the agents of the RHC papers), and the **Physical Agent**, which executes the same plan through feedback control and actuator limits. Both follow the path the planner draws, carry a battery (power model in `Agent.m`, reported as SOC), and record their energy `J_e`, peak speed and peak acceleration.

| | Abstract Agent (`AbstractAgent`) | Physical Agent (`PhysicalAgent`) |
|---|---|---|
| Motion | Follows its speed profile exactly along the path (arc length), at rest on the targets | Double integrator (speed and acceleration saturate at `maxSpeed` and `maxAccel`) with a PD law and feedforward tracking a reference it can follow: the path with its corners rounded, and a speed profile within `planMargin` (0.8) of both limits that slows down for turns |
| Timing | Every transit takes exactly the planned time | Arrives within a step or two of the planned time, if the plan is at least its `shortestTransit(path)`; otherwise it takes `shortestTransit`. The RHC policies plan with it |
| Model of | The event-driven RHC papers: first-order agent (`"constant"` profile) or energy-optimal second-order agent (`"SO"`, `"FO"`) | A physical robot executing the same plan with feedback |
| `J_e` | Tangential acceleration only (NaN with `"constant"`: impulses) | Full commanded acceleration |

**Speed profiles** (`SpeedProfile.m`, from the agent's `profile` or handed over per transit by a planning policy):
- `"constant"`: constant speed.
- `"SO"`: minimum energy.
- `"FO"`: minimum-energy trapezoid.

Without a planned transit time an Abstract Agent crosses an edge of length `y` in `y/maxSpeed` (`"constant"`) or `1.5 y/maxSpeed` (`"SO"`, `"FO"`, peak speed `maxSpeed`). On curved paths its profile depends on the path length only; the heading follows the path and turns at `omega = kappa * v` (`state.omega`), as in Theorem 2 of the energy-aware paper.

A Physical Agent follows the planned profile when that profile keeps within its reference limits on the path (`"SO"` and `"FO"` usually do on straight edges). Otherwise, it follows its fastest profile within those limits (full acceleration and braking, slower through corners, where the turn takes acceleration too), slowed down uniformly to the planned time. `"constant"` never fits, since it jumps to its speed, so with `"constant"` a Physical Agent moves at its own fastest pace, `shortestTransit(path)`. Its feedforward is the reference's own change of velocity over each step, so an agent on the reference stays on it.

**Spawning and customizing.** Agents are spawned from an `AgentSpec` (`Components/AgentTypes/AgentSpec.m`):
- the type (a registered name);
- `maxSpeed`, `maxAccel`;
- `profile`;
- the tracking gains `kp` and `kd` (Physical Agents);
- `batteryWh`.

Unset settings keep the type's defaults. One spec serves every place that creates agents:
- **In the GUI:** **Agent Type**, **Agent Speed**, **Agent Accel** and **Speed Profile** form `ScenarioModel.agentSpec`, applied to the next agents placed.
- **Layouts:** a layout stores each agent's speed, acceleration and profile. The type is always the current selection.
- **In `runTrial`:**
  - `AgentType` and `AgentSpeed` set the type and speed.
  - `Agent_<setting>` sets a spec setting (`'Agent_profile', "SO"`, `'Agent_maxAccel', 10`, `'Agent_kp', 16`, `'Agent_batteryWh', 50`).
  - Any other `Agent_<property>` is set on every agent, its state or controller (e.g. `'Agent_stopWhenEmpty', true`).
- **In code:** `spec = AgentSpec(Type="Physical Agent", MaxSpeed=10, Profile="SO"); agent = spec.spawn(index, position)`.

**Parts held by every agent, swappable without subclassing:**
- **Speed profile** (`SpeedProfile`): chosen per transit by a planning policy, or the agent's own `profile`.
- **Controller** (`TrackingController`): PD tracking with acceleration feedforward. Physical Agents use it; replace `agent.controller` to try another law.
- **Battery** (`Battery`): capacity and power model, `agent.battery`. Reported as SOC; with `stopWhenEmpty` the agent stops when it is empty.

New agent types are subclasses for different platforms (dynamics, limits, sensing), not for profiles; see [New Agent Type](#3-new-agent-type).

**Service.** A target is serviced only by agents at rest there: arrived (no path) or waiting to leave. Agents in transit service nothing, even when they pass close to a target. `ScenarioModel.detectionRadius` (1.2) is only the tolerance for "at the target".

**Older names.** `"Linear Agent"` (= Abstract, `"constant"`), `"Second-Order Agent"` (= Abstract, `"SO"`), `"Default Agent"` and `"Energy Agent"` (= Physical) still work in scripts and layouts, but are not listed in the GUI.

**Policies and agent types.** Each policy states what it assumes of the agents' motion: `agentAssumption` on the policy, or `ComponentRegistry.assumptions` for policies that do not declare it.
- `"any"`: no timing assumption.
- `"plans transit"`: hands each transit's time (and profile) to the agent, no shorter than the agent's `shortestTransit(path)` (0 for an Abstract Agent).
- `"constant speed"`: transit = path length / `maxSpeed`, not handed over.

`ScenarioModel.checkAgentFit` turns this into a note in the GUI status line and a warning in `runTrial`.
- ✓ = works as designed.
- ≈ = runs, but the agent's transit times differ from what the policy plans.

| Policy | Abstract | Physical | Notes |
|---|---|---|---|
| Random Walk | ✓ | ✓ | No timing assumptions; dwell from the current `R` at arrival. Each agent moves at its own pace (a Physical Agent: `shortestTransit`) |
| Battery-Aware ED-RHC | ✓ | ✓ | As ED-RHC; predicts each plan's battery energy with the agent's own `transitEnergy` |
| ED-RHC | ✓ | ✓ | Hands the agent its planned transit: `y/maxSpeed`, or the agent's `shortestTransit` if longer (a Physical Agent's own pace). `"constant"` is the Automatica model; `"SO"` runs it with the SO shape (the JS SO#) |
| ED-ORHC-SO / -FO | ✓ | ✓ | Hands over the optimal transit time (no shorter than the agent's `shortestTransit`), profile and limits. A Physical Agent keeps the time; its profile is the planned one where that fits its limits, so its energy can differ from the plan's |
| Classical RHC [1], Divergent RHC, Joint RHC, Joint RHC N | ✓ with `"constant"`; ≈ with `"SO"`/`"FO"` (1.5× slower than planned) | ≈ | Plan transits as path length / `maxSpeed`, which a Physical Agent cannot keep (it takes its `shortestTransit`). Joint RHC needs exactly 2 agents |

## Random Walk

`Random Walk` (`Components/AgentPolicy/RandomWalkPolicy.m`) is the baseline policy. It uses the same event-driven structure as ED-RHC, but an agent acts only at two of its own events:
- **On arrival**, it dwells for a uniform random time between 0.8 and 1.2 times the time to empty its target, `R_i / (N_i B_i - A_i)`. Here `N_i` counts the agents already there, which are assumed to stay; they keep their own plans.
- **When the dwell ends**, it moves to a neighbor chosen uniformly at random.

Agents may share targets. During a spike that the agents present cannot overcome, the target's baseline growth rate is used instead. The parameters are `dwellSpread` (default 0.2) and `dwellScale` (default 1; 0 means no dwell).

## Event-driven receding horizon control (ED-RHC)

`ED-RHC` (`Components/AgentPolicy/EDRHCPolicy.m`) implements the distributed event-driven receding horizon controller of S. Welikala and C. G. Cassandras, "Event-driven receding horizon control for distributed persistent monitoring in network systems", *Automatica* 127 (2021) 109519.

- **Local and event-driven.** Each agent decides on its own, using only its target `i` and the 1-hop neighbors of `i`: their `R`, `A`, `B`, the edges `(i, j)`, and whether each neighbor is covered.
  - It solves RHCP1 on arrival (active time `u_i`), RHCP2 when `R_i` reaches 0 (inactive time `v_i`), and RHCP3 when it leaves (next target `j`).
  - It re-solves RHCP1/RHCP2 when a neighbor becomes covered or uncovered.
- **Agents avoid each other.** A target is covered while another agent is at it or on its way to it. Covered neighbors are left out, so two agents never share a target.
- **Variable horizon.** Each RHCP plans `[u_i, v_i]` at `i`, the transit to `j`, and `[u_j, v_j]` at `j` over a horizon `w <= H` (`H = 250` by default). It minimizes the neighborhood cost `(1/w) * sum of the integrals of R`.
- **alpha** (a parameter). RHCP3 weights the next target's cost by `alpha` and the others' by `1 - alpha`.
  - The default `"nominal"` is the paper's `alpha = 1/|N_i|^2` (Sec. IV-A, the RHC-alpha method; `N_i` includes `i`), as in the JS simulator.
  - `alpha = 0.5` gives the paper's unweighted RHC method (Sec. III).
  - Set it with `'Policy_alpha'` in `runTrial`.
- **Solver.** The RHCPs are solved numerically (grid search plus `fmincon` on each smooth case) instead of with the paper's closed forms.
- **Agents.** The method assumes first-order agents moving at constant speed: use the **Abstract Agent** with the `"constant"` profile (the default), whose transit times equal path length / speed. See the compatibility table under [Agent types](#agent-types) for the others.

`Experiments/validation/validateEDRHC` compares `alpha = 0.5` and the nominal alpha with the legacy JavaScript simulator on its presets (`Configurations/Legacy/`).

### Energy-aware ED-RHC (ED-ORHC-SO, ED-ORHC-FO)

`ED-ORHC-SO` and `ED-ORHC-FO` (`EDRHCPolicy` with `transit = "SO"` or `"FO"`) implement the energy-aware variant of S. Welikala and C. G. Cassandras, "Event-driven receding horizon control of energy-aware dynamic agents for distributed persistent monitoring", arXiv 2102.12963 (IEEE CDC 2021). Use them with the **Abstract Agent**; the policy hands each transit's profile, time and limits to the agent, whatever its own profile.

- **Objective.** `J_T = energyWeight * J_e + J_s`. Here `J_e` is the integral of the squared tangential acceleration `u(t)^2` over all agents, and `J_s` is the usual sensing objective.
  - The default `energyWeight = 7.68e-3` is the paper's `213.3e-6` (for a 600 x 600 space) rescaled to the 100 x 100 canvas. Energy grows with length squared, so the factor is 36.
  - `EDRHCPolicy.weightFromBeta(beta, model)` gives the paper's App. A rule, eq. (77): `beta/(1 - beta) * ybar^2 / vmax^4`, where `ybar` is the mean edge length and `vmax` the agents' `maxSpeed`. With `"accel"` as a third argument it gives `beta/(1 - beta) / umax^2`.
  - In `runTrial`, `'EnergyBeta', beta` (optionally with `'EnergyBound', "accel"`) applies this rule.
- **Transit time as a decision.** Events, locality, covering and alpha are as in ED-RHC. In addition, each RHCP chooses the transit time `rho_ij` and adds the energy `E(rho)` of the speed profile on that edge. In RHCP3 the alpha-weighted sensing cost is doubled, so that `alpha = 0.5` gives the paper's objective.
- **Speed and acceleration limits** (parameters `speedLimit` and `accelLimit`, `Inf` by default; `'Policy_speedLimit'` and `'Policy_accelLimit'` in `runTrial`). The agent uses the minimum-energy profile of the method's family for the planned `y` and `rho`, rest to rest:
  - **SO** (any profile). Without limits, `v(t) = 6 y t (rho - t)/rho^3` with `E = 12 y^2/rho^3` (Theorem 3).
    - Under a speed limit, `u` falls linearly to 0 as the speed reaches the limit, then the agent cruises.
    - Under an acceleration limit, `u` is held at the limit, then falls linearly (the paper's SO-A).
    - Under both, it accelerates at the limit, ramps `u` down to 0 as it reaches the speed limit, cruises, and mirrors this at the end.
  - **FO** (trapezoids, the paper's FO-3). Without limits, the trapezoid accelerates for `rho/3`, cruises at `3y/(2 rho)`, brakes for `rho/3`, and has `E = 27 y^2/(2 rho^3)` (Theorem 5). With limits, the cruise speed is clamped to what they allow (the paper's FO-V and FO-A).
  - The RHCP never plans a transit shorter than the limits allow: `y/v + v/u`, or `2 sqrt(y/u)` on short edges.
  - These profiles generalize the paper's Apps. D-E to both limits at once. The speed-limited SO keeps `u` continuous, which uses 2-6% less energy than the paper's SO-V profile.
- **Agents.** The Abstract Agent follows each planned transit exactly and accumulates `J_e` exactly. Under `ED-RHC` it runs each fixed transit `y/maxSpeed` with its own profile (`"SO"`: the JS simulator's SO#). The Physical Agent tracks the same plans with feedback.
- **Metrics.** `runTrial` also returns `out.Je`, `out.JT`, `out.vmax` and `out.umax` (paper eqs. 3 and 73), and `out.log.Je` holds the per-step energy.
- **`clearFirst`** (default `false`, which follows the paper). Set it to `true` for the JS simulator's energy-aware convention: every visit clears the target, there is no RHCP1 on arrival, and plans only include visits that clear `j`.

`Experiments/validation/validateEDORHC` compares both methods (without limits) with the JS simulator (methods 9 and 11) under the JS conventions.

### Battery-aware ED-RHC and charging stations

`Battery-Aware ED-RHC` (`Components/AgentPolicy/BatteryAwareRHCPolicy.m`, a subclass of `EDRHCPolicy`) keeps every agent able to reach a charging station. It replaces Gabriel's `Battery Efficient` heuristic (nearest-neighbor moves with short random dwells, longer at low SOC, never recharging), retired on 2026-10-21; its code is kept in `Old_Design/` for reference, and old scripts that ask for it get an error naming the replacements.

- **Charging stations** (`Components/ChargingStation.m`, a `Target` subclass). A station has no uncertainty (`R = A = 0`) and is drawn as a yellow square. Every agent at rest there recharges at `chargePower` (W) until full; the agent still draws its idle power. Layouts place stations by target index (fields `chargers`, `chargePower`). Other policies treat a station as an ordinary node.
- **Energy of a plan.** Each agent predicts its battery energy from the battery's power model (`Battery`):
  - at rest: `idlePower` per second;
  - a transit of length `y` in time `rho`: `Agent.transitEnergy(path, rho)` = `movePower * rho + (alphaVel * y + gammaAcc * int |a|^2 dt) / eta`. The speed term integrates to `alphaVel * y` for any speed profile. A Physical Agent computes `int |a|^2 dt` from the reference it will follow.
  - The prediction matches the energy drawn to 0.1% on a wall-routed edge (smoke test).
- **Terminal SOC constraint.** Every RHCP plan `[u_i v_i rho_ij u_j v_j]` must end, at `j`, with enough energy for three things: the cheapest route from `j` to the nearest station, the wait there while every other agent using that station charges fully once (the worst case, when they all arrive together), and a reserve `socMin` (5%) of the capacity:
  `idlePower * (u_i + v_i + u_j + v_j) + E_ij <= E_left - socMin * capacity - E_station(j)`.
  The constraint is linear in the plan, so it is added as one more row to the constraints of each RHCP case (`EDRHCPolicy.planConstraint`). It caps the dwells of RHCP1 and RHCP2, and RHCP3 drops the neighbors the agent cannot afford. Stations are never planned as monitoring visits.
- **Recharging.** When the agent cannot afford any uncovered neighbor, even without dwelling (or cannot afford to wait while every neighbor is covered), it goes to the nearest station along its cheapest route, one edge per decision. It waits (`queueWait`, 1 s) while another agent is at or heading to the station, charges until full, and then resumes ED-RHC with RHCP3. Agents on their way to a station do not block the targets they pass, so an agent leaving a station can always get out.
- **Parameters.** `socMin` (0.05), `queueWait` (1 s), and everything of ED-RHC (`alpha`, `H`, `transit`, ...). `charges` counts the charging sessions; each station records `energyDelivered` and `busyTime`.
- **Metric.** `Minimum SOC` (`MinimumSOC`) is the lowest SOC of any agent so far. Use it with `setMetrics` or `runTrial`'s `Metrics` parameter.
- **Without stations** the policy is ED-RHC. With unlimited batteries on the dock scenario it never charges, and its J is 2% above ED-RHC's (140.6 vs 137.6): it never plans a visit to the station, and its RHCPs carry the extra, inactive constraint.

On **Office floor with charging dock** (1500 s, seed 1):

| Policy | Agent | J | Lowest SOC | Charges | Batteries empty |
|---|---|---|---|---|---|
| ED-RHC, unlimited batteries | Abstract | 137.6 | 100% | 0 | none |
| Battery-Aware ED-RHC | Abstract | 255.2 | 9.9% | 19 (dock busy 32% of the time) | none |
| ED-RHC | Abstract | 8786 | 0 | 0 | all three, at about 225 s |
| Battery Efficient (retired) | Abstract | 10233 | 0 | 0 | two, at about 243 s |
| Random Walk | Abstract | 9093 | 0 | 0 | all three, at 214-230 s |
| ED-RHC, unlimited batteries | Physical | 272.7 | 100% | 0 | none |
| Battery-Aware ED-RHC | Physical | 688.2 | 12.4% | 25 | none |
| ED-RHC | Physical | 10038 | 0 | 0 | all three, at about 145 s |

A station must charge faster than its agents draw on average. Here the three robots draw about 40 W each and the dock charges at 300 W. At 100 W even the battery-aware policy cannot keep them all going.

## Headless experiments

`Experiments/runTrial(params)` runs one simulation without the GUI. Unset parameters take the values in `Experiments/trialDefaults.m`; component parameters take any `ComponentRegistry` name:

```matlab
out = runTrial(struct('Layout', "ReportLayout.mat", 'AgentStarts', "layout", ...
    'Policy', "ED-RHC", 'Planner', "Energy Efficient", 'AgentType', "Physical Agent", ...
    'UncertaintyMode', "Static Uniform", 'A_base', 1, 'B', 10, 'EndTime', 500, 'Seed', 1, 'Log', true));
```

- `AgentStarts`: `"auto"` (spread evenly), `"layout"` (the start targets stored in the layout file), or target indices such as `[1 5]`.
- `Seed`: the `rng` seed set before simulating (`-1`, the default, leaves `rng` as it is).
- `Policy_<property>`: sets a property of the active policy, e.g. `'Policy_dwellScale', 0` turns off the Random Walk dwell and `'Policy_alpha', 0.5` sets ED-RHC's alpha.
- `Log = true`: `out.log` holds the per-step time, `J(t)`, agent positions, velocities, accelerations, headings, SOC, battery energy and `J_e`; `out.metrics` holds per-agent path length `L`, heading change `Θ`, integrated squared acceleration `E_a`, final SOC and energy (`Experiments/metrics/`).

`Experiments/runSweep(grid)` runs every combination of parameter values, and `analyzeResults` compares the variants.

## Paper results

`PaperResults.mlx` (repository root) regenerates every result of the simulator paper: Table I from the code, Tables II–IV and Figs. 10–13 from headless runs, and the GUI figures (Figs. 2, 3, 5–9 and 12) from `MainUI`. Open it and click **Run All**, or run it without the Live Editor to get a PDF report of everything:
```
matlab -batch "addpath(genpath(pwd)); exportPaperResults"
matlab -batch "addpath(genpath(pwd)); exportPaperResults(Quick=true)"
```
The full run (500 s runs, 4 seeds) takes about ten minutes and writes to `results/paper/`; `Quick=true` (60 s runs, 2 seeds, about 80 s) writes to `results/paper_quick/`. The output folder holds `PaperResults.pdf`, `runs.csv` (every run), LaTeX tables and `macros.tex` for the paper to `\input`, and `figures/` (PNG; the plots also as PDF).

The experiments are defined in `Experiments/paper/paperDefaults.m` (the reference scenario) and `Experiments/paper/paperConditions.m` (what each experiment varies). The live script is binary, so it is built from a plain-text source: edit `Experiments/paper/paperResultsSource.m` and run `buildPaperResults`.

## Path planners

Every edge's path is planned once, when the edge is added (and again when walls or the planner change). Agents follow it; the policies use its length.

| Planner | Method |
|---|---|
| Dijkstra Corners | Shortest path over the wall end points pushed out by `cornerBuffer` (a visibility graph), smoothed by pchip interpolation |
| Energy Efficient | As Dijkstra Corners, with a penalty on heading changes |
| Grid A* | A* on an 8-connected occupancy grid (cell 0.5; cells closer than `clearance` = 1.2 to a wall are blocked), octile heuristic, then line-of-sight shortcuts; the standard grid-based baseline |

## Getting started: a new monitoring problem

`Examples/EventDetection/` builds a different persistent monitoring problem from scratch: security robots patrol a small museum, incidents occur at random at the targets and expire, and a robot at a target detects the incidents in progress. Four small classes define it, one per extension point:

| Class | Base class | What it does |
|---|---|---|
| `SimpleTarget` | `Target` | Events arrive at random (rate `eventRate`) and last `lifetime` s; an agent at the target detects those in progress; `R` = events in progress |
| `SimpleAgent` | `Agent` | Moves at its top speed from path point to path point |
| `SimplePolicy` | `Policy` | Goes to the free neighbor with the most events in progress (else the one visited longest ago) |
| `SimpleMetric` | `Metric` | Share of the events that ended before an agent detected them |

Each is one line in `ComponentRegistry`, so it appears in the GUI's dropdowns (Target Type, Agent Type, Active Policy, Objective) and in `runTrial` (`TargetType`, `AgentType`, `Policy`, `Metrics`). `eventDetectionExample.m` walks through the whole process in seven sections, each doing what the named GUI clicks do: import the floor plan, draw the walls, mark the targets, add the edges (the planner routes them around the walls), choose the new classes and place the robots, run, and compare policies headless with `runTrial`. It saves what the canvas shows after each step to `results/example/`. On the museum, SimplePolicy misses about 15% of the events and Random Walk about 45% (10 runs of 600 s).

## Adding a new modular class

Each area has a dedicated folder under `Components/`. Creating a new algorithm takes two steps:

1. Create a new `.m` class file in the matching folder.
2. Register it in `Components/ComponentRegistry.m` — this makes it appear in the UI dropdown automatically.

### 1. New Path Planner

Folder: `Components/PathPlanner/`

Create a class that inherits from `PathPlanner` and implements `plan`:

```matlab
classdef MyPlanner < PathPlanner
    methods
        function path = plan(obj, pStart, pEnd, walls, bounds)
            % Return an Nx2 matrix of [x y] waypoints from pStart to pEnd.
            path = [pStart; pEnd];
        end
    end
end
```

Register it in `ComponentRegistry.m`:
```matlab
obj.pathPlanners('My Planner') = @() MyPlanner();
```

### 2. New Agent Policy

Folder: `Components/AgentPolicy/`

Subclass `Policy` and implement `plan`, which returns a move command struct:

```matlab
classdef MyPolicy < Policy
    methods
        function cmd = plan(obj, agent, model, adj, curIdx, simTime)
            cmd = struct();
            nbrs = find(adj(curIdx, :));
            if isempty(nbrs), return; end
            cmd.kind = "move";
            cmd.targetIdx = nbrs(1);          % index of the target to move to
            cmd.dwellSeconds = 0.5;           % optional: wait at the current target before leaving
        end
    end
end
```

Returning `struct()` (no `kind`) leaves the agent where it is; it asks again on the next step. Instead of `dwellSeconds`, a policy may set `agent.dwellRemaining` itself, as the RHC policies do. Optional: `onStep(agent, model, simTime)` (called every step, to react to events during a dwell), `resetReservations()` (called on reset), and a constant `agentAssumption` (see the agent types section).

Register it:
```matlab
obj.policies('My Policy') = @() MyPolicy();
```

### 3. New Agent Type

Folder: `Components/AgentTypes/`

Subclass `Agent` and implement `update(dt)`:

```matlab
classdef MyAgent < Agent
    methods
        function obj = MyAgent(index, position, maxSpeed)
            obj@Agent(index, position, maxSpeed);
        end

        function update(obj, dt)
            % Move obj.state along obj.path (N x 2 waypoints from the path planner) for dt
            % seconds; set obj.path = [] once the last waypoint is reached.
        end
    end
end
```

`Agent` holds what every agent shares:
- the state (`state`, a `KinematicState`), `path`, `dwellRemaining` and the start target;
- the speed `profile` and the transit plan a policy may hand over (`transitTime`, `transitProfile`, `transitLimits`);
- the battery (`battery`, a `Battery`; `soc`, `e_total`) and the metrics `Je`, `peakSpeed`, `peakAccel`;
- `resetToInitial`, `draw` and `updateVisuals`.

Helpers for path-following agents:
- `beginLeg()` gives the arc-length parametrized path and the speed profile of the transit starting now.
- `pointAt` and `headingAt` give position, tangent, heading and curvature along it.

Override `resetToInitial` (calling `resetToInitial@Agent(obj)` first) to reset extra state, or `label` to change the text drawn on the agent. `AbstractAgent` is the simplest complete example; `PhysicalAgent` adds feedback control with saturation. Agents of different types can be mixed in one scenario.

Register it:
```matlab
obj.agentTypes('My Agent') = @(idx, pos, sp) MyAgent(idx, pos, sp);
```

That's it — restart `runMainUI` and the new component will appear in its dropdown.

### 4. New Target Type

Folder: anywhere on the path (the example is in `Examples/EventDetection/`)

Subclass `Target` and override `updateUncertainty(dt, simTime, mode)`; `R` is what the target's bar shows and what `J(t)` averages. `residingAgents` lists the agents at rest at the target.

```matlab
classdef MyTarget < Target
    methods
        function obj = MyTarget(index, position)
            obj@Target(index, position);
        end

        function updateUncertainty(obj, dt, simTime, ~)
            if isempty(obj.residingAgents), obj.R = obj.R + dt; else, obj.R = 0; end   % idleness
        end
    end
end
```

Override `reset` (calling `reset@Target(obj)` first) to clear extra state. Register it:
```matlab
obj.targetTypes('My Target') = @(idx, pos) MyTarget(idx, pos);
```
The Target Type dropdown (or `model.setTargetType(name)`) rebuilds the scenario with targets of that type; layouts store it (`targetType`).

### 5. New Metric

Subclass `Metric` and implement `value(model, simTime)`; implement `update(model, simTime, dt)` too if the metric accumulates over the run (it is called after every step), and `reset(model)` to clear it.

```matlab
classdef PeakUncertainty < Metric
    properties
        peak = 0
    end
    methods
        function obj = PeakUncertainty(), obj.label = "Largest R so far"; end
        function reset(obj, ~), obj.peak = 0; end
        function update(obj, model, ~, ~), obj.peak = max([obj.peak, model.targets.R]); end
        function v = value(obj, ~, ~), v = obj.peak; end
    end
end
```

Register it:
```matlab
obj.metrics('Peak Uncertainty') = @() PeakUncertainty();
```
The Objective dropdown plots it over time; `runTrial` returns the final value of every metric named in `Metrics` (`out.metricValues.PeakUncertainty`).
