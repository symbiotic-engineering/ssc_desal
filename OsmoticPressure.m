%[text] # Modeling Osmotic Pressure in Simscape
%[text] Osmotic pressure is a fundamental concept in chemistry and biology, describing the force required to prevent the flow of solvent molecules through a semipermeable membrane separating two solutions of different concentrations. This phenomenon is driven by the natural tendency of solvent molecules (often water) to move from a region of lower solute concentration to one of higher solute concentration, aiming to equalize concentrations on both sides of the membrane.
%[text] 
%[text] Mathematically, osmotic pressure, $\\Pi${"editStyle":"visual"}, for dilute solutions can be described by the van 't Hoff equation:
%[text] $\\Pi =i\\;M\\;R\\;T${"editStyle":"visual"}
%[text] where:
%[text] - $i${"editStyle":"visual"} is the van 't Hoff factor (number of particles the solute splits into),
%[text] - $M${"editStyle":"visual"} is the molar concentration of the solute,
%[text] - $R${"editStyle":"visual"} is the universal gas constant,
%[text] - $T${"editStyle":"visual"} is the absolute temperature (in Kelvin). \
%[text] 
%[text] Osmotic pressure plays a crucial role in biological systems, industrial processes, and laboratory techniques such as dialysis and reverse osmosis. Understanding this concept helps in predicting the movement of fluids across membranes, designing separation processes, and explaining cellular behavior in different environments.
%[text] ## Manometer with Semipermeable Membrane
%[text] 
A = 1/100^2;          % [m^2] Cross sectional area
h0 = 0.5;               % [m] Initial column height
ii = 2;               % [1] Charge for NaCl -- there are 2 ions
c = 0.05;             % [kg/m^3] Salt mass concentration in solution
m0 = c*A*h0;          % [kg] Salt mass in salty column
M_NaCl = 0.05844;     % [kg/mol] Molar mass of NaCl
M = c/M_NaCl;         % [mol/m^3] Molar concentration of NaCl    
R = 8.314;            % [J/(mol*K)]
T = 293.15;           % [K] Temperature

% Osmotic Pressure via van 't Hoff:
pi_os = ii*M*R*T        % [Pa]  %[output:2fce8b33]
% Fluid properties
rho = 998.2;         % [kg/m^3] Water density (approximate)
g = 9.81;            % [m/s^2] Gravitational acceleration

% Approximate column height difference 
% Assumes height change is even on both sides (it isn't)
fg = @(x)rho*g*x;
fpo = @(x)ii*m0/M_NaCl/A/(x/2+h0)*R*T;
fnc = @(x)ii*m0/M_NaCl/A/(x/2+h0)*R*T - rho*g*x;
xf = fzero(fnc, 0.0) %[output:29504609]
open_system("simple_manometer");
out1 = sim("simple_manometer");
h_s1 = out1.simlog.Salt.h.series.values("m");
h_p1 = out1.simlog.Pure.h.series.values("m");
h_sim1 = h_s1(end)-h_p1(end) %[output:0e815f6f]

open_system("manometer");
out2 = sim("manometer");
h_s2 = out2.simlog.h_salty.x.series.values("m");
h_p2 = out2.simlog.h_pure.x.series.values("m");
h_sim = h_s2(end)-h_p2(end) %[output:61850a17]

%[text] ## Appendix 1: Derivation of van 't Hoff's Equation 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:2fce8b33]
%   data: {"dataType":"textualVariable","outputData":{"name":"pi_os","value":"4.1705e+03"}}
%---
%[output:29504609]
%   data: {"dataType":"textualVariable","outputData":{"name":"xf","value":"0.3221"}}
%---
%[output:0e815f6f]
%   data: {"dataType":"textualVariable","outputData":{"name":"h_sim1","value":"0.3221"}}
%---
%[output:61850a17]
%   data: {"dataType":"textualVariable","outputData":{"name":"h_sim","value":"0.3212"}}
%---
