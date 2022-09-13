function t = getTimevec(this, varargin)
% GETTIMEVEC  Returns a (column) time vector that can be used with sequences
% returned by GETSEQUENCES. There will be 'nbefore' ('nafter') time points
% before (after) the zero point. By default, units are in ms, but you can
% get seconds or frames by supplying the 'Units' parameter and the value
% 'Seconds', 'Milliseconds' or 'Frames'. 
%
% EXAMPLES
%
% t = getTimevec(stefile, 10, 10);
% t = getTimevec(stefile, 10, 10, 'Units', 'ms');
% t = getTimevec(stefile, 10, 10, 'Units', 'milliseconds');
% t = getTimevec(stefile, 10, 10, 'Units', 'seconds');
% t = getTimevec(stefile, 10, 10, 'Units', 'sec');
% t = getTimevec(stefile, 10, 10, 'Units', 'frames');
%

    allowedUnits = {'ms', 'milliseconds', 'seconds', 'sec', 'frames'};
    p = inputParser;
    p.FunctionName = 'getTimevec';
    p.addRequired('NBefore', @isnumeric);
    p.addRequired('NAfter', @isnumeric);
    p.addParamValue('Units', 'Milliseconds', @(x)any(strcmpi(x, allowedUnits)));
    p.parse(varargin{:});
    
    switch (lower(p.Results.Units))
        case {'ms', 'milliseconds'}
            stepsz = 1000/get(this, 'FPS');
        case {'seconds', 'sec'}
            stepsz = 1/get(this, 'FPS');
        case 'frames'
            stepsz = 1;
        otherwise
            error 'Unknown units type!';
    end
    
    t = [ -stepsz*p.Results.NBefore:stepsz:stepsz*p.Results.NAfter ]';

    return;
end