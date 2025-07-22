---
title: "Solution Domain: Status Update"
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

# The Motivation
The goal of this project is to develop a Simscape toolbox for modeling solution dynamics. One major application of this domain is in modeling reverse/forward osmosis, with reverse osmosis being important in desalination. This fills a major gap in available desalination modeling software. While models like WAVE and WaterTap can model steady state desalination, this Simscape tool is capable of modeling transient desalination dynamics. Transient behavior has been avoided in the past, but is a growing area of interest in research. A experimental study has shown that unsteady operation is not as detrimental to the membrane as previously thought, and can even improve performance in some cases. Additionally as the need for desalination increases, more innovative solutions will be required to meet the demand. This will lead to increased interest in novel technologies like wave-driven desalination, which will require transient modeling capabilities.

# Current Status
Currently, the basic membrane functionality is complete. There is a solution domain that builds upon the thermal liquid domain, but adds an additional state variable for concentration. We've created the solution domain, reservoirs, flow resistance blocks, modified constant volume chambers, and a membrane transport modeling block. These components are capable of modeling membrane behavior and have been validated against WaterTap for steady state operation. The blocks ensure mass conservation of both the solvent and solute separately enabling proper evaluation of the brine and permeate concentrations. 

## Reservoirs, and Flow Resistances
These elements don't include any new functionality beyond what is available in the thermal liquid domain. But were needed to be rewritten to support the new solution domain and were necessary to model the membrane transport behavior. 

## Membrane Transport and Constant Volume Chamber
These two elements capture the new functionality of the solution domain. A single membrane unit is modeled through the combination of two constant volume chambers and one membrane transport block as shown in the figure below. Putting membrane units together in series can be done by connecting the downstream ports of one unit to the upstream ports of the next.
![implementation schematic](../figs/schematic.svg){fig-align=center width=230}

The membrane transport block models how the solute, solvent, and energy flow across the membrane. It takes inputs on the pressure, temperature, and concentration of the upstream and downstream sides of the membrane. Using these inputs, it calculates the flow rates of the solvent, solute, and energy across the membrane. These calculated flow rates are then fed back into the two constant volume chambers to adjust the states in those chambers. The constant volume chambers don't conserve mass and energy in isolation, because of these inputs, but by ensuring the mass and energy sent to one membrane is multiplied by -1 to get the mass and energy sent to the other side, the system as a whole conserves mass and energy.

## Results


# Next Steps
