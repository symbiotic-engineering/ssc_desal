classdef polarization_options < int32
% Enumeration class for the polarization options in the membrane and 
% scaling blocks (SS).

% Copyright 2026 The MathWorks, Inc.

enumeration
    none(1)
    discrete(2)
    modifier(3)
end

methods (Static, Hidden)
    function map = displayText()
        map = containers.Map;
        map('none') = 'None';
        map('discrete') = 'Boundary Layer';
        map('modifier') = 'Exponential Modifier';
     end
end
end