clear;clc;close all;

% Membrane Parameters
A_w = 2.57e-12; B_s = 2.30e-8;
A_m = 35; length = 1;
h_ch = 0.7112; eps_sp = 0.85;
W = A_m/length;
D_feed =  4*eps_sp / (2/h_ch + (1-eps_sp)*8/h_ch);
area_feed = W*1e3*h_ch*eps_sp;
D_perm = 29;
N_units = 10;
R_b =  62e8;

% Feedflow Conditions
P_feed = 5; x_feed = 32;


