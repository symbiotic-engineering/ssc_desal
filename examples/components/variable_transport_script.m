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
x_feed = 37.8;

% Preload the Simulink model to reduce loading time
load_system('tVariableTransportMembrane');

%set_param('tVariableTransportMembrane/Membrane', 'boundary_layer', 'true');
%set_param('tVariableTransportMembrane/Membrane', 'boundary_height', '0.07'); % mm
%set_param('tVariableTransportMembrane/Membrane', 'custom_ports', 'true');
%set_param('tVariableTransportMembrane/Membrane', 'boundary_port_length', '0.07'); % mm

x0 =  3.1295;

% Experimental Data
pressures = [500,600,700,800,900];
recovery_ratios = [0.03,0.066,0.096,0.120,0.142];

options = optimset('Display', 'iter');
obj = @(x) mean_squared_error(x,pressures,recovery_ratios);
%R_b = fminsearch(obj,x0,options)
for i=1:5
    recovery_difference(x0,pressures(i),recovery_ratios(i))
end

function mse = mean_squared_error(x,pressures,recovery_ratios)
    for i=1:length(pressures)
        error(i) = recovery_difference(x,pressures(i),recovery_ratios(i))*100;
    end
    mse = mean(error.^2);
end

function y = recovery_difference(x,p_applied,target_recovery)
    global sim_cache
    set_param('tVariableTransportMembrane/Feed','reservoir_pressure',num2str(p_applied/145.037738));
    set_param('tVariableTransportMembrane/Membrane','P0_feed',num2str(p_applied/145.037738));
    [m_p, m_f] = run_sim_once(x);
    y = m_p/m_f - target_recovery;
end

function [m_p, m_f] = run_sim_once(x)
    R_b = x*1e10;
    
    set_param('tVariableTransportMembrane/Resistance', 'R', num2str(R_b));
    
    simOut = sim('tVariableTransportMembrane', 'ReturnWorkspaceOutputs', 'on');
    mdot_W_perm = simOut.simout.mdot_W_perm;
    m_p = trapz(mdot_W_perm.time, mdot_W_perm.Data);

    mdot_W_feed = simOut.simout.mdot_W_feed;  
    m_f = trapz(mdot_W_feed.time, mdot_W_feed.Data);
    disp(m_p/mdot_W_feed.time(end))
end