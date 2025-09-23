function blkStruct = slblocks
% SLBLOCKS  Defines Simulink library block representation for Customization

blkStruct.Name    = 'Customization';           % Displayed library name
blkStruct.OpenFcn = 'customization_lib';       % Name of the library .slx
blkStruct.MaskDisplay = '';                    % Optional icon text
end
