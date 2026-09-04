%% Fix int64 fields from hydro struct for R2025b compatibility
%hydro.properties.dof = double(hydro.properties.dof);
%hydro.properties.dofStart = double(hydro.properties.dofStart);
%hydro.properties.dofEnd = double(hydro.properties.dofEnd);
piston_area = 0.26;     % [m^2]     Piston Area
piston_stroke = 12;     % [m]       Piston Stroke Length
piston_stroke_buffer = piston_stroke + 2;

%% Simulation Data
simu = simulationClass();                       % Initialize Simulation Class
simu.simMechanicsFile = 'examples/wave_driven_desal/waveDrivenDesal.slx';    % Specify Simulink Model File
%simu.mode = 'normal';                          % Specify Simulation Mode ('normal','accelerator','rapid-accelerator')
%simu.simMechanicsFile = 'examples\wave_driven_desal\YJpto.slx';
simu.explorer = 'off';                           % Turn SimMechanics Explorer (on/off)
simu.startTime = 0;                             % Simulation Start Time [s]
simu.rampTime = 0;                              % Wave Ramp Time [s]
simu.endTime = 300;                             % Simulation End Time [s]        
simu.solver = 'daessc';                          % simu.solver = 'ode4' for fixed step & simu.solver = 'ode45' for variable step - that's what WEC-Sim thinks...
simu.dt = 0.1;                                  % Simulation Time-Step [s]
simu.cicEndTime = 10;                           % Specify CI Time [s]
simu.saveWorkspace = 0;                         % I don't want WEC-Sim to save my workspace for me, I can do it myself

%% Wave Information

% Regular Waves 
% waves = waveClass('regular');           % Initialize Wave Class and Specify Type                                 
% waves.height = 2.5;                     % Wave Height [m]
% waves.period = 8;                       % Wave Period [s]

% Irregular Waves using PM Spectrum
waves = waveClass('irregular');         % Initialize Wave Class and Specify Type
waves.height = 9.86; % Significant Wave Height [m]
waves.period = 2.64;             % Peak Period [s]
waves.spectrumType = 'PM';              % Specify Spectrum Type
waves.phaseSeed = 1;

%waves.direction = [0,30,90];            % Wave Directionality [deg]
%waves.spread = [0.1,0.2,0.7];           % Wave Directional Spreading [%]

%% Body Data
% Flap
body(1) = bodyClass('../WEC-Sim/examples/OSWEC/hydroData/oswec.h5');     % Initialize bodyClass for Flap
body(1).geometryFile = '../WEC-Sim/examples/OSWEC/geometry/flap.stl';   % Geometry File
body(1).mass = 127000;         % User-Defined mass [kg]
body(1).inertia = [1.85e6 1.85e6 1.85e6];   % Moment of Inertia [kg-m^2]

% Base
body(2) = bodyClass('../WEC-Sim/examples/OSWEC/hydroData/oswec.h5');     % Initialize bodyClass for Base
body(2).geometryFile = '../WEC-Sim/examples/OSWEC/geometry/base.stl';   % Geometry File
body(2).mass = 999;             % Placeholder mass for a fixed body
body(2).inertia = [999 999 999];% Placeholder inertia for a fixed body

%% PTO and Constraint Parameters
% Fixed
constraint(1)= constraintClass('Constraint1'); % Initialize ConstraintClass 
constraint(1).location = [0 0 -10];

% Rotationals
constraint(2)= constraintClass('Constraint2'); % Initialize ConstraintClass 
constraint(2).location = [0 0 -8.9];

constraint(3)= constraintClass('Constraint3'); % Initialize ConstraintClass 
constraint(3).location =  [4.7021271782+0.9 0 -8.7];

constraint(4)= constraintClass('Constraint4'); % Initialize ConstraintClass 
constraint(4).location = [0+0.9 0 -7];

% Translational PTO
pto(1) = ptoClass('PTO1');                          % Initialize ptoClass for PTO1
pto(1).stiffness = 0;                               % PTO Stiffness Coeff [N/m] - we use our own
pto(1).damping = 0;                                 % PTO Damping Coeff [Ns/m]  - we use our own
pto(1).location =  [2.35106397378+0.9 0 -7.849998936];  % PTO Global Location [m]
pto(1).orientation.z = [-4.7021271782/5 0 1.7/5];       % PTO orientation

% PTO Motion Limits
%pto(1).hardStops.lowerLimitSpecify = 'on';              % Turn Motion Limits On/Off
%pto(1).hardStops.upperLimitSpecify = 'on';              % Turn Motion Limits On/Off
%pto(1).hardStops.lowerLimitBound = -piston_stroke/2;    % Lower Limit [m]
%pto(1).hardStops.upperLimitBound = piston_stroke/2;     % Upper Limit [m]
%pto(1).hardStops.lowerLimitStiffness = 1e20;            % Lower Limit Stiffness [N/m]
%pto(1).hardStops.upperLimitStiffness = 1e20;            % Upper Limit Stiffness [N/m]
%pto(1).hardStops.lowerLimitDamping = 1e10;              % Lower Limit Damping [Ns/m]
%pto(1).hardStops.upperLimitDamping = 1e10;              % Upper Limit Damping [Ns/m]
%pto(1).hardStops.lowerLimitTransitionRegionWidth = 5e-3;% Lower Limit Transition Width [m]
%pto(1).hardStops.upperLimitTransitionRegionWidth = 5e-3;% Upper Limit Transition Width [m]
%ptolowerbound = -piston_stroke/2;                       % Lower Limit [m]
%ptoupperbound = piston_stroke/2;                        % Upper Limit [m]
%boundstiffness = 1e9;                                   % Limit Stiffness [N/m]
%bounddamping = 1e6;                                     % Limit Damping [Ns/m]
%hardstopwidth = 5e-3;                                   % Limit Transition Width [m]
%piston_stroke_buffer = piston_stroke + 2;

% Ocean Pressure
P_ocean = (1025*9.1*9.81 + 101325)/1e6;