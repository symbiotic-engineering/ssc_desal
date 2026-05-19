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
R_b =  62e8;

P_const = 900/145.037738;
x_feed = 37.8;

