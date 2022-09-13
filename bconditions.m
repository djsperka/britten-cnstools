%BCONDITIONS Trial condition/type definitions. 
% Pursuit trials that use the standard range settings in the REX menus
% always use the same trial condition indices for each of the pursuit
% directions. 
%
% Pursuit trials have translation type 0, pursuit type 1.
%
% Condition    Angle
%         0      0
%         1     45
%         2     90
%         3    135
%         4    180
%         5    225
%         6    270
%         7    315
%
% Heading trials that use the standard range settings in the REX menus
% always use the same trial condition indices for the heading and elevation 
% values. For these trials, these are the relationships between the trial
% condition index and heading/elevation. 
%
% Heading trials have translation type 1, pursuit type 0.
% 
% Condition   Heading   Elevation
%         0      0          90
%         1      0          45
%         2     45          45
%         3     90          45
%         4    135          45
%         5    180          45
%         6    225          45
%         7    270          45
%         8    315          45
%         9      0           0
%        10     45           0
%        11     90           0
%        12    135           0
%        13    180           0
%        14    225           0
%        15    270           0
%        16    315           0
%        17      0         -45
%        18     45         -45
%        19     90         -45
%        20    135         -45
%        21    180         -45
%        22    225         -45
%        23    270         -45
%        24    315         -45
%        25      0         -90
%
%
% Test trials can come in 4 varieties. To determine the particular type of
% a given trial you must look at both the translation type and the pursuit
% type. 
%
%  Trans type  Pursuit type      
%      1               1      Heading + Pursuit
%      1               2      Heading + Simulated Pursuit
%      1               3      Heading + Pursuit with retinal stabilization
%      1               4      H0 (frozen dots) + Pursuit with ret. stab.
%
%  Note that in the case of frozen dots the translation type is 1, but the
%  heading speed is specifically set to 0. 
