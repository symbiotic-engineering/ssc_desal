clear;clc;close all;
% Copyright 2021-2026 Professor Maha N. Haji, director of the Symbiotic Engineering of Analysis Lab
% Authored by: Nate DeGoede and Maha N. Haji
% For questions or concerns, please email: degoeden@umich.edu and mhaji@umich.edu

% Membrane Parameters
A_m = 7.4; length = 0.9626;
h_ch = 28*0.0254; eps_sp = 0.89;
W = A_m/length;
D_feed =  4*eps_sp / (2/h_ch + (1-eps_sp)*8/h_ch);
area_feed = W*1e3*h_ch*eps_sp;
D_perm = 99;
N_units = 10;

% Operating Conditions
P_const = 600/145.037738;
x_feed = 37.8;

% Preload the Simulink model to reduce loading time
load_system('variable_transport_membrane_test');

x0 =  1.2891;
recovery_difference(x0)

options = optimset('Display', 'iter');
%R_b = fzero(@recovery_difference,x0,options)

function y = recovery_difference(x)
    global sim_cache
    target_recovery = 0.066;
    [m_p, m_f] = run_sim_once(x);
    y = m_p/m_f - target_recovery;
end

function [m_p, m_f] = run_sim_once(x)
    R_b = x*1e10;
    
    set_param('variable_transport_membrane_test/Resistance', 'R', num2str(R_b));
    
    simOut = sim('variable_transport_membrane_test', 'ReturnWorkspaceOutputs', 'on');
    mdot_W_perm = simOut.simout.mdot_W_perm;
    m_p = trapz(mdot_W_perm.time, mdot_W_perm.Data);

    mdot_W_feed = simOut.simout.mdot_W_feed;  
    m_f = trapz(mdot_W_feed.time, mdot_W_feed.Data);
end