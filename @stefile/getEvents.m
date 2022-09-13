function varargout = getEvents(this, varargin)
% GETEVENTS  Returns a set of events with given type(s). The return value
% is actually a matrix. Each row represents a single event. The column
% values are as follows:
% 
% 1: double(letter) - the event's char representation, converted to double
% 2: time
% 3: event data 1 or NaN
% 4: event data 2 or NaN
%
% There are two ways to fetch events: by event type(s) or by specifying a filter
% string and regular expression pattern. 
%
% In either case you can specify an AcceptFcn. The function should take two
% arguments and return 1 if the event is accepted, 0 otherwise. The first
% arg is the stefile object, and the second is an array holding the event
% (see above). Each event of a type listed in EventTypes is tested. When a
% filter/pattern are used, each event set that matches the pattern is
% tested (not implemented TODO). In the latter case, the second arg is an
% nxm matrix, where n is the number of events and m is the number of
% columns per event (4 in the example above). 
% 
% Use EventTypes when you want all events of a certain type. The use of
% 'BeforeEvents' and 'AfterEvents' isn't implemented - the same thing can
% be achieved with a filter/pattern. 
% 
% When using a filter/pattern, you must provide a regular expression
% pattern. Each match is returned (TODO: Allow spec of submatch index;
% default = 1). The filter arg 'Filter' should be a string array. The
% events of each type in the array are filtered and the resulting list
% sorted (on time). The regular expression pattern 'Pattern' is matched against the 
% resulting string array.
%
% events = getEvents(sfile, eventtypes);
% events = getEvents(sfile, eventtypes, 'AcceptFcn', @(s, ev));
% events = getEvents(sfile, eventtypes, 'AcceptFcn', @func);
% events = getEvents(sfile, eventtypes, 'BeforeEvent', events);
% events = getEvents(sfile, eventtypes, 'AfterEvent', events);
%
% This function returns a cell array of tsdata.event objects whose members have
% one of the event types in 'eventtypes'. The types of events are
% BYZLRMPTE - see stefile for details. 
% 
% If an accept function is provided in the 'AcceptFcn' parameter, it
% should return 1 for events which are accepted, 0 otherwise. The accept function
% should take two arguments, the first being the stefile object from which
% the list of events is requested, and the second being an array containing 
% stuff about the event (NOT an event object, even though that's what is 
% returned). The first element of the array is the event character convered
% to an int (test it using char(arr(1)) == 'B', for example), the second
% element is the time of the event, and any remaining elements are event
% data. Note that the size of the array is dictated by the event type that 
% holds the MOST event data. Other events that have less event data will
% have event data elements with NaN in them. There is a syntax shown above 
% for providing an inline accept function: e.g. @(s, ev)ev.EventData(1)<0.
%
% blipPositive = getEvents(sfile, 'B', 'AcceptFcn', @(s, ev)ev(3)>0);
%
% Here, 'sfile' is the stefile object. Next we want the jump event prior to
% each of these blips. We use 'blipPositive' as the 'BeforeEvent'
% parameter. I also add the second return var to get the index difference
% between the returned events and their reference events. 
%
% [jumps jumpdiff] = getEvents(sfile, 'LR', 'BeforeEvent', blipPositive);
%
% The return values are both cell arrays, each with the same dimension as
% the array 'blipPositive'. 
%

% Check output arguments
error(nargoutchk(1, 2, nargout, 'struct'));

% Parse input
p = inputParser;
p.FunctionName = 'getEvents';
% djs remove check on event types - users beware!
% p.addOptional('EventTypes', '', @(x) (ischar(x) && ~isempty(regexpi(x, '^[BCYZJLRMPTE]*$'))));
p.addOptional('EventTypes', '');
p.addParamValue('BetweenTimes', {}, @(x) iscell(x) && isnumeric(x{1}) && isnumeric(x{2}) && length(x{1})==length(x{2}));
p.addParamValue('NotBetweenTimes', {}, @(x) isempty(x) || (iscell(x) && isnumeric(x{1}) && isnumeric(x{2}) && length(x{1})==length(x{2})) || (isnumeric(x) && size(x, 2)==2));
p.addParamValue('BeforeEvent', [], @(x) isa(x, 'cell') && isa(x{1}, 'tsdata.event'));
p.addParamValue('AfterEvent', [], @(x) isa(x, 'cell') && isa(x{1}, 'tsdata.event'));
%p.addParamValue('Quantity', 'first', @(x) (ischar(x) && any(strcmpi(x,{'one','first','all'}))));
p.addOptional('AcceptFcn', @localDefaultAcceptFcn, @(x) isa(x, 'function_handle'));
p.addOptional('Pattern', '', @(x) ischar(x));
p.addOptional('Filter', '', @(x) ischar(x));
%p.addParamValue('AcceptFcn', @(x,y)1 , @(x) isa(x, 'function_handle'));



% perform the parse. If both BeforeEvent and AfterEvent parameters were
% given, verify that they are the same size. 
p.parse(varargin{:});
%disp 'The input parameters for this program are';
%disp(p.Parameters);
%disp 'The input parameters using defaults are';
%disp(p.UsingDefaults);

if ~isempty(p.Results.EventTypes) && ~isempty(p.Results.Pattern)
    error('Cannot use both EventTypes and Pattern in the same call.');
end


% Fetch event info. Remember that the elements of eventind are indices into
% data() -- they point to the positions in the timeseries data where the
% events themselves lie. 
ze = get(this, 'Events');
eventtypes = char(ze(:, 1)');

% user asks for a list of event types, specified e.g. 'B' or 'LR'. 
if ~isempty(p.Results.EventTypes)

    if ~isempty(p.Results.BeforeEvent) && ~isempty(p.Results.AfterEvent)
        error('Cannot use both BeforeEvents and AfterEvents');
    end

    % iterate over each char in EventTypes, for each one gather indices of
    % all events with that char. If an accept function was specified on
    % input, apply it to each and only save the indices of those for wich 
    % AcceptFcn(this, ze(index)) returns nonzero. Once that's all done,
    % sort the resulting index array (on index, not time, column). 
    % In the end 'ind' will 
    % be used to generate the return array of events. 
    
    ind = [];
    ind1 = [];
    for i=1:length(p.Results.EventTypes),
        ind1 = [ind1 sort(find(eventtypes == p.Results.EventTypes(i)))];
    end

    if ~any(strcmp('AcceptFcn', p.UsingDefaults)), 
        ind2 = [];
        for i=1:length(ind1),
            if (p.Results.AcceptFcn(this, ze(ind1(i), :))),
                ind2 = [ind2 ind1(i)];
            end
        end
        ind1 = ind2;
    end
    ind = sort(ind1);

    % There are three cases to cover. 
    % 1. Both BeforeEvents and AfterEvents are empty. In this case we just 
    % return a big old cell array of events of the types contained in EventTypes. 
    % 2. BeforeEvents not empty, AfterEvents empty. In this case we use each
    % event in BeforeEvents as a reference point. Looking backwards, find the
    % first event of the types found in EventTypes and return that. If Quantity
    % is 'all', then return all events before the reference event. 
    % 3. AfterEvents is not empty, BeforeEvents is empty. Similar to (2). 

    % TODO: Ignoring Quantity, assuming 'first' always.



    if isempty(p.Results.BeforeEvent) && isempty(p.Results.AfterEvent)
        result=ze(ind, :);
    % original 11-19-08
    %     result = cell(1, length(ind));
    %     resultdiff = [];
    %     for i=1:length(ind)
    %         result{i} = tsdata.event(eventtypes(ind(i)), eventtimes(ind(i)));
    %         result{i}.EventData = [ze(ind(i), 3) ze(ind(i), 4)];
    %     end
    elseif ~isempty(p.Results.BeforeEvent) && isempty(p.Results.AfterEvent)
        error('Use a pattern/filter instead.');
    %original 11-19-08
    %     afterind = getEventIndices(this, p.Results.BeforeEvent);
    %     result = cell(1, length(p.Results.BeforeEvent));
    %     resultdiff = zeros(1, length(p.Results.BeforeEvent));
    %     for i=1:length(p.Results.BeforeEvent)
    %         lessind = find(indtimes < p.Results.BeforeEvent{i}.Time, 1, 'last');
    %         if ~isempty(lessind)
    %             resultind = ind(lessind);
    %             resultdiff(i) = afterind{i} - eventind(resultind);  
    %             result{i} = events(resultind);
    %         else
    %             warning('Event %d: cannot find events before this!\n', i);
    %         end
    %     end
    elseif isempty(p.Results.BeforeEvent) && ~isempty(p.Results.AfterEvent)
        error('Use a pattern/filter instead.');
    %     beforeind = getEventIndices(this, p.Results.AfterEvent);
    %     result = cell(1, length(p.Results.AfterEvent));
    %     resultdiff = zeros(1, length(p.Results.AfterEvent));
    %     for i=1:length(p.Results.AfterEvent)
    %         moreind = find(indtimes > p.Results.AfterEvent{i}.Time, 1, 'first');
    %         if ~isempty(moreind)
    %             resultind = ind(find(indtimes > p.Results.AfterEvent{i}.Time, 1, 'first'));
    %             resultdiff(i) = eventind(resultind) - beforeind{i};
    %             result{i} = events(resultind);
    %         else
    %             warning('Event %d: Cannot find events after this!\n', i);
    %         end
    %     end
    else
        error('Cannot specify both BeforeEvents and AfterEvents. Might work with a pattern/filter');
    end

    varargout(1) = {result};
    if nargout >= 2, varargout(2) = {resultdiff}; end

elseif ~isempty(p.Results.Pattern)
    % option b - filter and pattern. 
    % GetMatches takes care of most everything.
    [first, last, ind] = getMatches(this, p.Results.Pattern, 'Filter', p.Results.Filter);
    result = cell(length(first), 1);
    for i=1:length(first)
        result{i} = ze(ind(first(i):last(i)), :);
    end
    varargout(1) = {result};
end
return;
end

function a = localDefaultAcceptFcn(x, y)
a=1;
return;
end
