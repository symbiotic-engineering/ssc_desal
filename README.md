[![View on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/182376-simscape-solution-domain)

# ssc_desal
A Simacape domain for modeling solutions.

## Overview
The domain is a customization of the thermal liquid domain, with an added state variable for solute concentration. This enables the modeling of transient dynamics for solution systems. Some example applications are shown in this repository including the classic manometer experiment and unsteady reverse osmosis desalination.

## Getting Started
It is recommended to follow along with the `OsmoticPressure.m` live script to gain an understanding of the functionality of this domain.

## File Organization
Source code for all Simscape components can be found in the `src` folder, with modified thermal liquid components in the `src/+customization/+solution` folder and membrane components in the `src/+customization/+membranes` folder. The `examples` folder contains example models that demonstrate the functionality of the domain including variations of the manometer experiment and an optimization of an unsteady reverse osmosis desalination system. In the `examples/components` folder, the basic functionality of the individual components is demonstrated. The `docs` folder contains documentation on the implementation of this domain and the math behind the membrane modeling.

## Funding Acknowledgment
Funded by MathWorks

## License
This project is licensed under the BSD-3 License - see the LICENSE file for details.
