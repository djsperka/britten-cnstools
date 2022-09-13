function [eca] = bhx(varargin)

% BHX extracts raw data from the E and A-files.
%
% [eax]=bhx('path_to_Efile', 'path_to_Afile');
% [eax]=bhx('path_to_Efile_base');
%

parser = inputParser;
parser.addRequired('efile_or_base', @ischar);
parser.addOptional('afile', 'NO_AFILE', @ischar);
parser.parse(varargin{:});

if strcmp(parser.Results.afile, 'NO_AFILE')
    EFILE=strcat(parser.Results.efile_or_base,'E');
    AFILE=strcat(parser.Results.efile_or_base,'A');
else
    EFILE=parser.Results.efile_or_base;
    AFILE=parser.Results.afile;
end
    

% Get ecfile object for EFILE: 
e=ecfile(EFILE);

% create eca object
eca = ECAData(get(e, 'Times'), get(e, 'Channels'), get(e, 'Values'));


% extract adata
adata=mrdr('-c', '-a', '-d', AFILE, '-s', '1166');

% eyeh
ts = getRexTimeseries(adata, 'eyeh', [1]);
ts.Name = 'eyeh';
eca.Adata('eyeh') = ts;

% eyev
ts = getRexTimeseries(adata, 'eyev', [2]);
ts.Name = 'eyev';
eca.Adata('eyev') = ts;


return;
