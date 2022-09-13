function [ind] = getEventIndices(this, types_or_events)
% GETEVENTINDICES  Returns the index into the data() array where the events
% fall. If event types are given, then all events of those types are found
% first, then their indices are found. 
%
% The input may be a char string of event types, an array of events or a
% cell whose elements are event arrays. 
    eventind = get(this, 'EventInd');
    eventtypes = get(this, 'EventTypes');
    if ~isempty(types_or_events)
        if ischar(types_or_events)
            ind = [];
            for i=1:length(types_or_events), 
                ind = [ind eventind(eventtypes==types_or_events(i))];
            end
        elseif isa(types_or_events, 'tsdata.event')
            ind = localGetEventIndicesForArray(types_or_events);
        elseif isa(types_or_events, 'cell') 
            % each cell must be an array of events
            ind = cell(1, length(types_or_events));
            for i=1:length(types_or_events)
                if ~isa(types_or_events{i}, 'tsdata.event')
                    error('Cell array must consist of only events.');
                else
                    ind{i} = localGetEventIndicesForArray(this, types_or_events{i});
                end
            end
        end
    end
    return;
end

function [ind] = localGetEventIndicesForArray(this, ev)
    eventind = get(this, 'EventInd');
    eventtimes = get(this, 'EventTimes');
    ind = zeros(1, length(ev));
    for i=1:length(ev),
        ind(i) = eventind(find(eventtimes==ev(i).Time, 1));
    end
    return;
end