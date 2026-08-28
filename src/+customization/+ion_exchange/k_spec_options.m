classdef k_spec_options < int32
% Enumeration class for choosing which adsorption constant the user
% specifies directly in the ion_exchange block. The other constants are
% derived from selectivities anchored to the specified k.

enumeration
    k_x(1)
    k_y(2)
    k_z(3)
end

methods (Static, Hidden)
    function map = displayText()
        map = containers.Map;
        map('k_x') = 'Specify k_x';
        map('k_y') = 'Specify k_y';
        map('k_z') = 'Specify k_z';
     end
end
end
