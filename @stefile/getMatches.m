function [firstind lastind ind] = getMatches(this, varargin)
% GETMATCHES  Finds matches to a pattern (expressed as a regular
% expression) of events. 
%
% [firstind lastind ind] = getMatches(stefile, 'pattern');
% Treats the sequence of events (get(stefile, 'EventTypes')) as a string
% and 'pattern' as a regular expression. See regexp in Matlab docs. The
% return values are the first and last indices (in the EventTypes string)
% of each match found. Remember that those indices will refer to the
% indices of particular events in get(stefile, 'Events'). 
%

% Check output arguments
error(nargoutchk(3, 3, nargout, 'struct'));

% Parse input
p = inputParser;
p.FunctionName = 'getMatches';
p.addRequired('Pattern', @(x) ischar(x));
p.addParamValue('Filter', '', @(x) ischar(x));


%disp 'The input parameters for this program are';
%disp(p.Parameters);
p.parse(varargin{:});

% Filter string if necessary. 
% 'filtered' will be an nx1 matrix, first col is indices, second col is the
% char itself, for convenience. Probably don't really need that. 
ze = get(this, 'Events');
if ~any(strcmp('Filter', p.UsingDefaults)), 
    % Filter, accepting only those char in the filter string. 
    % For convenience, convert filter string to ints...
    f = double(p.Results.Filter);
    filtered = [];
    for i=1:length(f), 
        ind = find(ze(:, 1) == f(i));
        if ~isempty(ind), 
            ftemp = zeros(length(ind), 2);
            ftemp(:, 1) = ind;
            ftemp(:, 2) = f(i);
            filtered = vertcat(filtered, ftemp);
        end
    end
    filtered = sortrows(filtered, 1);
else
    filtered = zeros(length(ze(:, 1)), 2);
    filtered(:, 1) = [1:length(ze(:, 1))]';
    filtered(:, 2) = ze(:, 1);
end

% Now we have a filtered list of chars (converted to int) and their
% corresponding indices. We convert that char list to a string and perform 
% the match on it. 

str = char(filtered(:, 2))';
[firstind lastind] = regexp(str, p.Results.Pattern);
ind = filtered(:, 1);

return;