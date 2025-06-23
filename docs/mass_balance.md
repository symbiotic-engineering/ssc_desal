---
title: "Solution Domain Task 1: Species Balance"
subtitle: Nate DeGoede
format:
  pdf:
    pdf-engine: pdflatex
    fontfamily: anttor
    svg-to-pdf: inkscape
    toc: false
    number-sections: true
    colorlinks: true
---

# Problem to Solve
This looks to build off the idea presented in the custom TL domain tutorial, but also accounts for species balance. This will allow for modeling brine. Additionally, this problem aims to measure the density of the solution, accounting for the solute in the calculation. Here is a schematic of the problem:
![Mass Balance Schematic](figs/mass_balance_problem.svg){fig-align=center width=190}

For this problem, I will start by assuming no volume in the membrane. This means that we use a mass balance approach. If we assumed volume in the membrane component, there would be an additional set of states required to track the composition of the fluid in the membrane component, which would add a couple of equations. I'll note them at the end.

## Variables
Variables are defined in the table below:

| Variable | Symbol | Type| Units |
|:--------:|:-:|:----------:|:--:|
| Concentration | $x$| State Variable | kg/m³ |
| Pressure | $P$ | Reservoir Parameter | Pa |
| Temperature | $T$ | Reservoir Parameter | K |
| Flow Rate | $Q$ | State Variable | m³/s |
| Density | $\rho$ | Intermediate Variable | kg/m³ |
| Membrane Permeability | $A_w$ | Membrane Parameter (TLU later)  | m³/(N·s) |
| Solute Transport Parameter | $B_s$ | Membrane Parameter (TLU later)  | m/s |
| Membrane Area | $A_m$ | Membrane Parameter | m² |
| Brine Resistance | $R_B$ | Membrane Parameter | Pa·s/m³ |
| Osmotic Pressure | $\pi$ | Intermediate Variable | Pa |
| Ion count | $i$ | Fluid Parameter | - |
| Solute molar mass | $M$ | Fluid Parameter | kg/mol |
| Density of Water | $\rho_w$ | Fluid TLU | kg/m³ |
| Ideal Gas Constant | $R$ | Fluid Property? | J/(mol·K) |

Subscript $A$ refers to the feed, $B$ refers to the brine, and $C$ refers to the permeate. 

## Assumptions
We assume that the system is at steady state, that the mixing is perfect, and no gradient of salt concentration. We assume we know the concentration of the feed ($x_A$).

# Equations

## Density Calculation
The density for each fluid is defined as:
$$\rho = \rho_w(T,P) + x$$
This allows us to calculate the density of the solution, provided we have 3 state variables: temperature, pressure, and concentration. Density probably makes most sense as an intermediate variable, so I won't include it in my equation and variable count.

## Species Conservation
The governing mass flow balance equation is shown below:
$$\rho_A Q_A + \rho_A Q_B + \rho_A Q_C = 0$$ 
we show how we can calculate the density as an intermediate variable in the density calculation above, so those can be excluded from the variable count. This leaves us with 3 unknowns: $Q_A$, $Q_B$, and $Q_C$. 

The governing solute flow balance equation is shown below:
$$x_A Q_A + x_B Q_B + x_C Q_C = 0$$
This ensures that the mass of the solute is conserved in addition to the entire solution mass. When combined with the total mass balance equation earlier it ensures that the mass of the solvent is conserved as well, so a separate solvent mass balance equation is not needed. It also leaves us with 2 more unknowns: $x_B$ and $x_C$, remember we assume we know $x_A$.

## Membrane Equations
The governing membrane transport equations are shown below:
$$A_w A_m \big((P_C-P_A) - (\pi_C - \pi_A)\big) + Q_c = 0$$
$$B_s A_m \big( x_A - x_C \big) + Q_c x_C = 0$$
The first equation describes the solvent transport through the membrane, while the second describes the solute transport through the membrane. Both equations require the osmotic pressure of the feed and permeate, which we can calculate as follows:
$$\pi = i \frac{x}{M}RT$$
Osmotic pressure will be defined as an intermediate variable, so we won't include it in the variable count. In this problem we assume we know the pressures $P_A$ and $P_C$. So no new variables are introduced by these equations.

## Brine Resistance
At this point we have 5 unknowns, $Q_A$, $Q_B$, $Q_C$, $x_B$, and $x_C$, but only 4 equations (total mass balance, solute mass balance, solvent transport, and solute transport). The final required equation is the brine side pressure balance equation. Without some sort of resistance to flow on the brine side, there would be no flow through the membrane. Plus it would cause solver issues then if $P_A$ and $P_B$ were inequal. This pressure balance equation related to the brine side resistance is shown below:
$$ P_A - P_B + Q_B R_B = 0 $$
With this equation, we now have 5 equations and 5 unknowns, so we can solve the system.

# Implementation Plan

## Domain Parameters
For a given fluid, the user would need to define the following parameters:

| Parameter | Symbol |
|----------|:---:|
| Density of Solvent Table | $\rho_w$ |
| Ion Count | $i$ |
| Solute Molar Mass | $M$ |
| Ideal Gas Constant | $R$ |

## Membrane Parameters
For a given membrane, the user would need to define the following parameters:

| Parameter | Symbol |
|----------|:---:|
| Water Permeability | $A_w$ |
| Solute Permeability | $B_s$ |
| Membrane Area | $A_m$ |

## Node Variables
We have three nodes: feed, brine, and permeate, and each node will have the following variables:

| Variable | Symbol |
|----------|:---:|
| Concentration | $x$ |
| Pressure | $P$ |
| Temperature | $T$ |
| Flow Rate | $Q$ |

## Intermediate Variables
I'm less confident here, but my first instinct would be to set these as intermediate variables:

| Variable | Symbol |
|----------|:---:|
| Osmotic Pressure | $\pi$ |
| Density | $\rho$ |

# What if we assume volume in the membrane?
If we assume volume in the membrane, we need to find 2 new variables, the pressure in the membrane ($P_I$) and the concentration of the solute in the membrane ($x_I$). The mass balance equations would then be modified to look like this:
$$\rho_A Q_A + \rho_A Q_B + \rho_A Q_C + \dot{\rho}_IV_I = 0$$
$$x_A Q_A + x_B Q_B + x_C Q_C + \dot{x}_I = 0$$
where $V_I$ represents the volume in the membrane. I believe then to help reduce the number of unknowns we would set $P_I$ to $P_A$. Similar logic here to the brine resistance, except instead of adding a resistance, I'm just assuming the pressure is equal for simplicity. We could easily have a resistance though, which would just add another resistance style pressure balance equation.

This still leaves us with 6 unknowns: $Q_A$, $Q_B$, $Q_C$, $x_B$, $x_C$, and $x_I$, but still only 5 equations.