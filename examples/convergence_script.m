clear;clc;close all;

% Membrane Parameters
A_w = 2.57e-12; B_s = 2.30e-8;
A_m = 6300; length = 10;
h_ch = 0.7112; eps_sp = 0.85;
W = A_m/length;
D_feed =  4*eps_sp / (2/h_ch + (1-eps_sp)*8/h_ch);
area_feed = W*1e3*h_ch*eps_sp;
D_perm = 29;

% Feedflow Conditions
P_feed = 7; x_feed = 50;

start_units = 21;
max_units =  50;
mdot_W_perm = zeros(max_units-start_units+1, 1);
x_perm = zeros(max_units-start_units+1, 1);
for N_units = start_units:max_units
    disp(N_units)
    out = sim('examples/membrane_convergence.slx');
    mdot_W_perm(N_units-start_units+1) = out.simout.mdot_W_perm.Data(end);
    x_perm(N_units-start_units+1) = out.simout.x_perm.Data(end);
end

figure(1)
line(start_units:max_units, x_perm, linewidth=2)
xlabel('Number of Units')
ylabel('Concentration of Permeate [kg/m^3]')

figure(2)
line(start_units:max_units, mdot_W_perm, linewidth=2)
xlabel('Number of Units')
ylabel('Mass flow of Permeate Solvent [kg/s]')