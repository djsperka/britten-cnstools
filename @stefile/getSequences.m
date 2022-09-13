function varargout = getSequences(this, varargin)
%  GETSEQUENCES  Returns a set of data sequences from a stefile object.
%
%  [seq, events] = getSequences(p, datatype, ...)
%
%  datatype can be one of
%  'joy': raw joystick readings
%  'heading': camera direction (degrees)
%  'target': target direction (degrees)
%  'steeringError': difference 'target' - 'heading'
%  'steer': same as 'steeringError'
%  'response': 'joy' value, converted to degrees/second
%  'horiz_eye': eye position, in degrees 
%  'vert_eye': y eye position , in degrees
%  'horiz_joy'" horizontal joystick value, but converted to something I
%  don't understand. Looks like its converted to visual degrees, we'll have
%  to decipher this. TODO. 
%  'jittertraj': delta added to trajectory in jitter-type paradigms 
%  'jittertarg': delta added to target bearing (non-integrated) in jitter-type paradigms
%  'meandertarg': delta added to target bearing (integrated)
%  'diffusiontarg': delta added to target (non-integrated) 
%
%  There are four ways to specify the sequences you want. 
%  CenterEvent: You can supply a list of event types (all events of that
%                type are found) and find sequences around them
%  CenterTime:  You can provide an array of times and find sequences around 
%               them
%  BetweenTimes:You can provide a two element cell array. Each element is
%               an array of time values. The two arrays must be of equal
%               length.
%               The parameters NBefore/TBefore/NAfter/TAfter are ignored
%               when using 'BetweenTimes'. 
%  Pattern/Filter: You can provide a pattern (and an optional filter).
%                  These are used in a call to getEvents. The times from 
%                  the first and last event in each set of events matching 
%                  the pattern are used to get sequences. 
%  
%  Notes:
%
%  The CenterEvents parameter should be a char array of event types. All occurrences 
%  of that event are found, and the times of those events are used to find
%  the center of the sequence. If 'CenterTime' is used, then that array of
%  times is used. 
%
%  Once the center(s) of the sequences are found, we locate the data point
%  (of the type requested) that matches (***) the times. The size of the
%  sequence is determined by 'NBefore'/'TBefore' and 'NAfter'/'TAfter'. 
% 
%  You can also specify event types which must be included
%  ('IncludeEvents') or excluded ('ExcludeEvents') from the returned
%  sequences. 
%
%  The returned sequences come in an Mx1 cell array, where M depends on 
%  the input criteria. If Pattern/Filter are used, then M is the same as
%  the number of patterns found in the data. If CenterEvents is used, then
%  M is the number of such events found. If CenterTime or BetweenTimes is
%  used, then M is the number of elements in the arrays. 
%
%  The individual elements of the cell array are 2 column arrays. The first
%  column is the time, and the second column is the data type requested. It
%  is possible that there are empty sequences -- and so you may have empty
%  matrices as some or all elements of the cell array.
%
%  'BetweenTimes'
%
%  The parameter should be a 2 element cell, where each element is an array
%  of time values. Note that NBefore/TBefore/NAfter/TAfter are ignored when
%  using 'BetweenTimes'. 
%
%  Return values
%
%  The first return value is a cell array. Each element of the cell array
%  is an nx2 matrix - the first column is the time, second column is the
%  requested data value. When using CenterEvents the size of the output cell array is
%  the same as the number of events found. When using either CenterTime or
%  BetweenTimes the size of the cell array is the same as the size of the
%  input arrays of times. 
%
%  An element of the cell array may be an empty matrix if that sequence was
%  excluded by ExcludeEvents, NOT included by IncludeEvents, or if one of
%  the Before/After parameters makes the array go beyond the end of the
%  available data. 

    % Check output arguments
    error(nargoutchk(1, 4, nargout, 'struct'))

    % These tell us what rows to pull for the sequences
    row1 = [];              % start row for sequences
    row2 = [];              % end row for sequences

    % Set up input parser and parse input arguments. 
    p = inputParser;
    p.FunctionName = 'getSequences';
    p.addRequired('DataType', @(x)any(strcmpi(x,{'joy','heading','target','steeringError','steer','response', 'horiz_eye', 'vert_eye', 'horiz_joy', 'jittertraj', 'jittertarg', 'meandertarg', 'diffusiontarg'})));
    p.addParamValue('CenterEvent', [], @(x) (iscell(x) || isa(x, 'tsdata.event') || (ischar(x) && ~isempty(regexpi(x, '^[BYZJLRMPTE]*$')))));
    p.addParamValue('CenterTime', [], @(x) isnumeric(x));
    p.addParamValue('NBefore', 0, @isnumeric);
    p.addParamValue('NAfter', 0, @isnumeric);
    p.addParamValue('TBefore', 0, @isnumeric);
    p.addParamValue('TAfter', 0, @isnumeric);
    p.addParamValue('ExcludeEvents', '', @(x) (isa(x, 'tsdata.event') || (ischar(x) && ~isempty(regexpi(x, '^[BYZJLRMPTEFG]*$')))) || isempty(x));
    p.addParamValue('IncludeEvents', '', @(x) (ischar(x) && ~isempty(regexpi(x, '^[BYZJLRMPTEFG]*$'))) || isempty(x));
    p.addParamValue('ContainedEvents', '', @(x) (ischar(x) && ~isempty(regexpi(x, '^[BYZJLRMPTEFG]*$'))) || isempty(x));
    p.addParamValue('BetweenTimes', {}, @(x) iscell(x) && isnumeric(x{1}) && isnumeric(x{2}) && length(x{1})==length(x{2}));
    p.addParamValue('NotBetweenTimes', {}, @(x) isempty(x) || (iscell(x) && isnumeric(x{1}) && isnumeric(x{2}) && length(x{1})==length(x{2})) || (isnumeric(x) && size(x, 2)==2));
    p.addParamValue('Pattern', '', @(x) ischar(x));
    p.addParamValue('Filter', '', @(x) ischar(x));

    %disp 'The input parameters for this program are';
    %disp(p.Parameters);
    p.parse(varargin{:});
    %disp 'The results of parsing are:';
    %disp(p.Results);


    % useNBefore is 1 (0) when we should use NBefore (TBefore)
    % useNAfter is 1 (0) when we should use NAfter (TAfter)

    useNBefore = 1;
    useNAfter = 1;

    if ~any(strcmp('NBefore', p.UsingDefaults)) && ~any(strcmp('TBefore', p.UsingDefaults))
        error('Cannot specify both NBefore and TBefore');
    elseif ~any(strcmp('TBefore', p.UsingDefaults))
        useNBefore = 0;
    end

    if ~any(strcmp('NAfter', p.UsingDefaults)) && ~any(strcmp('TAfter', p.UsingDefaults))
        error('Cannot specify both NAfter and TAfter');
    elseif ~any(strcmp('TAfter', p.UsingDefaults))
        useNAfter = 0;
    end

    
% 
%   Use the DataType to set flags indicating where to fetch data from.
%   Events always come from the same place, but data may come from a
%   different location, depending on what's desired. The times column of
%   the data is used to pin down where particular events fall. See
%   localGetEventInd(). 
%

    switch (lower(p.Results.DataType))
        case 'joy'
            d = get(this, 'Data');
            data = d(:, 2);
            datatimes = d(:, 1);
        case 'response'
            d = get(this, 'Data');
            data = (d(:, 2) - 1024)/1024 * get(this, 'SteerMax') * get(this, 'FPS');
            datatimes = d(:, 1);
        case 'heading'
            d = get(this, 'Data');
            data = d(:, 3);
            datatimes = d(:, 1);
        case 'target'
            d = get(this, 'Data');
            data = d(:, 4);
            datatimes = d(:, 1);
        case {'steeringerror', 'steer'}
            d = get(this, 'Data');
            data = d(:, 4) - d(:, 3);
            datatimes = d(:, 1);
        case 'horiz_eye'
            d=get(this, 'Adata');
            data=d(:, 2);
            datatimes = d(:, 1);
        case 'vert_eye'
            d=get(this, 'Adata');
            data=d(:, 3);
            datatimes = d(:, 1);
        case 'horiz_joy'
            d=get(this, 'Adata');
            data=d(:, 4);
            datatimes = d(:, 1);
        case 'jittertraj'
            d = get(this, 'Data');
            if size(d, 2) < 7
                error('no jitter data in data stream');
            else
                data=d(:, 5);
                datatimes = d(:, 1);
            end
        case 'jittertarg'
            d = get(this, 'Data');
            if size(d, 2) < 7
                error('no jitter data in data stream');
            else
                data=d(:, 6);
                datatimes = d(:, 1);
            end
        case 'meandertarg'
            d = get(this, 'Data');
            if size(d, 2) < 7
                error('no jitter data in data stream');
            else
                data=d(:, 7);
                datatimes = d(:, 1);
            end
        case 'diffusiontarg'
            d = get(this, 'Data');
            if size(d, 2) < 8
                error('no diffusion data in data stream');
            else
                data=d(:, 8);
                datatimes = d(:, 1);
            end
        otherwise
            error('Unknown data type!');
    end

    %
    % Now start the actual work. The input parameters CenterEvent 
    % and BetweenTimes tell us how to choose the data sequences. Can only have
    % one of these parameters! 
    % 
    % When CenterEvent is chosen, the input should be
    % a string of event types. We get the times of all events with those types,
    % then use those times to find the points in the data stream where they
    % lie. NBefore and NAfter are then used to determine the extent of the
    % sequences. 
    %
    % When BetweenTimes is chosen we get the points in the data stream where
    % the start and end times lie. NBefore and NAfter are used just as for
    % CenterEvent above. 

    if isempty(p.Results.CenterEvent)+isempty(p.Results.BetweenTimes)+isempty(p.Results.CenterTime)+isempty(p.Results.Pattern) < 2
        error('Can have just one of ''CenterEvent'', ''CenterTime'', ''BetweenTimes'' and ''Pattern''');
    elseif ~isempty(p.Results.CenterEvent) || ~isempty(p.Results.CenterTime)
    
        % Get events and times for the center events, and for exclude/include
        % events, if there are any. 
        if ~isempty(p.Results.CenterEvent)
            centerEvents = getEvents(this, 'EventTypes', p.Results.CenterEvent);
            centerEventsTimes = centerEvents(:, 2);
        else
            centerEventsTimes = p.Results.CenterTime;
            centerEvents = [];
        end

        excludeEventsTimes = [];
        includeEventsTimes = [];
        if ~isempty(p.Results.ExcludeEvents)
            excludeEvents = getEvents(this, 'EventTypes', p.Results.ExcludeEvents);
            if ~isempty(excludeEvents)
                excludeEventsTimes = excludeEvents(:, 2);
            end
        end
        if ~isempty(p.Results.IncludeEvents)
            includeEvents = getEvents(this, 'EventTypes', p.Results.IncludeEvents);
            if ~isempty(includeEvents)
                includeEventsTimes = includeEvents(:, 2);
            end
        end
        
        % The centerEventsInd is the index in the datastream for each of the resulting
        % timeseries. A 0 value indicates that the event isn't within the
        % data sequence (TODO within some as-yet-undefined criteria for doing
        % this TODO). 
        %
        % Now I take the first index where the event time is <= the data
        % time. 

        centerEventsInd = localGetInd(centerEventsTimes, datatimes);

        
        % Determine the extents of the sequences. User can ask for a number
        % of samples before (NBefore) or an amount of time before
        % (TBefore). Similarly for after (NAfter, TAfter). Remember that
        % centerEventsInd can have zero values - skip over those. 
        
        beginInd = [];
        beginTimes = [];
        endInd = [];
        endTimes = [];
        if ~isempty(centerEventsInd)
            if useNBefore
                % TODO Make this same fix to the endInd line below.
                % Previously the line had only the max(1, ...) part. The
                % problem was that if p.Results.NBefore is negative, and
                % we're near the end of the array, then the max might go
                % off the END of the array. The enclosing min() takes care
                % of that. In the endInd case below there's a similar
                % problem. 
                beginInd = min(max(1, centerEventsInd - p.Results.NBefore), length(datatimes));     % make sure all values are valid indices
                beginTimes = datatimes(beginInd);
            else
                beginTimes = max(datatimes(1), centerEventsTimes - p.Results.TBefore);
                beginInd = localGetInd(beginTimes, datatimes);
            end

            if useNAfter
                endInd = min(length(datatimes), centerEventsInd + p.Results.NAfter);     % make sure all values are valid indices
                endTimes = datatimes(endInd);
            else
                endTimes = min(datatimes(end), centerEventsTimes + p.Results.TAfter);
                endInd = localGetInd(endTimes, datatimes);
            end

            % check inclusions and exclusions. The arrays includeEventsTimes
            % and excludeEventsTimes are the times of particular events which
            % MUST fall within a sequence (includeEventsTimes) or MUST NOT fall
            % within a sequence (excludeEventsTimes). 
            
            if ~isempty(excludeEventsTimes)
                for i=1:size(centerEventsInd)
                    % Make sure that there are no times in
                    % excludeEventsTimes that fall between begTimes and
                    % endTimes.
                    if beginInd(i) && endInd(i)
                        if any([excludeEventsTimes >= beginTimes(i)] .* [excludeEventsTimes <= endTimes(i)])
                            beginInd(i) = 0;
                            endInd(i) = 0;
                        end
                    end
                end
            end
            
            if ~isempty(includeEventsTimes)
                for i=1:size(centerEventsInd)
                    % Similar to exclude case. Here, make sure that there
                    % is at least one time from includeEventsTimes that
                    % falls between beginTimes and endTimes. 
                    if beginInd(i) && endInd(i)
                        if ~any([includeEventsTimes >= beginTimes(i)] .* [includeEventsTimes <= endTimes(i)])
                            beginInd(i) = 0;
                            endInd(i) = 0;
                        end
                    end
                end
            end
        end
        row1 = beginInd;
        row2 = endInd;
        

    elseif ~isempty(p.Results.BetweenTimes)
        % BetweenTimes should be a 2 element cell array. Each element is an
        % array of times. 
        %
        % Hack! Result can have empty arrays - I'll set row1/row2=0.
        % BetweenTimes{1} and BetweenTimes{2}
        row1 = zeros(length(p.Results.BetweenTimes{1}), 1);
        row2 = zeros(length(p.Results.BetweenTimes{2}), 1);
        for i=1:length(p.Results.BetweenTimes{1})
            r1 = find(p.Results.BetweenTimes{1}(i)<= datatimes, 1);
            r2 = find(p.Results.BetweenTimes{2}(i)>= datatimes, 1, 'last' );
            if ~isempty(r1) && ~isempty(r2)
                row1(i) = r1;
                row2(i) = r2;
            end
        end
        centerEvents = [];
    elseif ~isempty(p.Results.Pattern)
        % Pattern and Filter (if non-null) are fed to getMatches. The
        % begin and end points of the resulting matches are used in the
        % same way as BetweenTimes. 
        if ~isempty(p.Results.Filter)
            centerEvents = getEvents(this, 'Pattern', p.Results.Pattern, 'Filter', p.Results.Filter);
        else
            centerEvents = getEvents(this, 'Pattern', p.Results.Pattern);
        end
        
        % ev is a cell array, where each element of the array is a set of
        % events (in a mx4 matrix) matching the pattern (and filter, if
        % supplied).
        row1 = zeros(length(centerEvents), 1);
        row2 = zeros(length(centerEvents), 1);
        for i=1:length(centerEvents)
            r1 = find(centerEvents{i}(1, 2)<= datatimes, 1);
            r2 = find(centerEvents{i}(end, 2)>= datatimes, 1, 'last');
            if ~isempty(r1) && ~isempty(r2)
                row1(i) = r1;
                row2(i) = r2;
            end
        end
            
    end

    % Take care of NotBetweenTimes here. 
    % Modified - allow empty NotBetweenTimes matrix or cell array as input.
    if ~any(strcmp('NotBetweenTimes', p.UsingDefaults)) && ~isempty(p.Results.NotBetweenTimes)
        if iscell(p.Results.NotBetweenTimes)
            b1 = p.Results.NotBetweenTimes{1};
            b2 = p.Results.NotBetweenTimes{2};
        else
            b1 = p.Results.NotBetweenTimes(:, 1);
            b2 = p.Results.NotBetweenTimes(:, 2);
        end

        for i=1:length(row1)
            if row1(i)>0 && row2(i)>0
                if any([b2 > datatimes(row1(i))] .* [b1 < datatimes(row2(i))])
                    row1(i) = 0;
                    row2(i) = 0;
                end
            end
        end
    end
    
    

    
    
    x = cell(length(row1), 1);
    for i=1:length(row1)
        if row1(i)==0 || row2(i)==0
            y=[];
        else
            y = zeros(row2(i)-row1(i)+1, 2);
            y(:, 1) = datatimes(row1(i):row2(i));
            y(:, 2) = data(row1(i):row2(i));
        end
        x{i} = y;
    end

    varargout(1) = {x};
    if nargout >= 2, 
        varargout(2) = {centerEvents}; 
    end
    
    return;
end


function [ind] = localGetInd(times, alltimes)

    if isempty(times) || isempty(alltimes)
        ind = [];
    else
        ind = zeros(length(times), 1);
        for i=1:length(times)
            r = find(times(i) <= alltimes, 1);
            if ~isempty(r)
                ind(i) = r;
            end
        end
    end
    return;

end


