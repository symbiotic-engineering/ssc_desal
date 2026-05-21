figure('name','mcpherson')
mcpherson_t = linspace(0,1e3,1e3);
mcpherson_m1 = 1.48e-5 + 5.76e-13.*mcpherson_t.^3;
mcpherson_m2 = 1.25e-6.*mcpherson_t - 7e-4;
simlog=out.simlog
simscape_M = simlog.Scaling_EQs.M_scale.series.values;
simscape_t = simlog.Scaling_EQs.M_scale.series.time;
simscape_m = simscape_M/(0.1e-4);

line(mcpherson_t,mcpherson_m1,'linewidth',2,'linestyle','--','color','r','DisplayName','McPherson Early')
line(mcpherson_t,mcpherson_m2,'linewidth',2,'linestyle','--','color','b','DisplayName','McPherson Late')
line(simscape_t,simscape_m,'linewidth',2,'linestyle','-','color','g','DisplayName','Simscape')

ylim([0,6e-4])

xlabel('Time [s]');
ylabel('Scale mass per unit area [kg/m^2]');
legend('show');
grid on;