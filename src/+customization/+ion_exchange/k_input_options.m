classdef k_input_options < int32
% Enumeration class for choosing which adsorption constant the user
% specifies directly in the ion_exchange block. The other constant is
% derived from the selectivity K = k_x / k_y.

% Copyright 2026 The MathWorks, Inc.

enumeration
    k_x(1)
    k_y(2)
end

methods (Static, Hidden)
    function map = displayText()
        map = containers.Map;
        map('k_x') = 'Specify k_x';
        map('k_y') = 'Specify k_y';
     end
end
end
