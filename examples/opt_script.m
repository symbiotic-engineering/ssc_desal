clear;clc;close all;
% Copyright 2025 Symbiotic Engineering and Analysis Laboratory
% Membrane Parameters
A_w = 2.57e-12; B_s = 2.30e-8;
A_m = 35; length = 1;
h_ch = 0.7112; eps_sp = 0.85;
W = 35;
D_feed =  4*eps_sp / (2/h_ch + (1-eps_sp)*8/h_ch);
area_feed = W*1e3*h_ch*eps_sp;
D_perm = 29;
N_units = 10;
R_b =  62e8;

% Feedflow Conditions
P_feed = 5; x_feed = 32;

% Pump Signal
mdot_mean = 1;
mdot_amp = 0.25;

% Preload the Simulink model to reduce loading time
load_system('optimization_example');


x0 = [40,62];
lb = [10, 10];             % Lower bounds
ub = [100, 100];           % Upper bounds

options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'StepTolerance', 1e-8, ...
    'OptimalityTolerance', 1e-4, ...
    'FiniteDifferenceStepSize', 1e-3, ...
    'MaxFunctionEvaluations', 500);


[x_opt, fval] = fmincon(@objective, x0, [], [], [], [], lb, ub, @constraint, options);

fprintf('Optimal A_m: %.3f m^2\n', x_opt(1));
fprintf('Optimal R_b: %.3e Pa·s/m^3\n', x_opt(2)*1e8);
fprintf('Max permeate: %.3f kg\n', -fval*x_opt(1));  % Negate because we minimized

close_system('optimization_example', 0);

function neg_f = objective(x)
    global sim_cache
    [m_p, c_val] = run_sim_once(x);
    sim_cache.c_val = c_val;
    neg_f = -m_p/x(1);
end


function [m_p, c_val] = run_sim_once(x)
    A_m = x(1);
    length = A_m / 35;
    R_b = x(2)*1e8;

    set_param('optimization_example/membrane', 'A_m', num2str(A_m));
    set_param('optimization_example/membrane', 'length', num2str(length));
    set_param('optimization_example/Resistance', 'R', num2str(R_b));

    simOut = sim('optimization_example', 'ReturnWorkspaceOutputs', 'on');
    mdot_W_ts = simOut.simout.mdot_W_perm;
    m_p = trapz(mdot_W_ts.time, mdot_W_ts.Data);

    c_ts = simOut.simout.x_perm;  
    c_val = mean(c_ts.Data); 
end

function [c, ceq] = constraint(x)
    global sim_cache
    c_val = sim_cache.c_val;  % Already computed
    c = c_val - 0.250;        % mean(c(x)) ≤ 0.250
    ceq = [];
end
