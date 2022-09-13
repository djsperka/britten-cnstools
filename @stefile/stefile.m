% $Id: stefile.m,v 1.2 2015/05/12 18:18:02 devel Exp $
%
function p = stefile(varargin)
% STEFILE Create a stefile object. 
%
% p = stefile(filename)  Parse the file in filename and generate data
% structures useful for steering analysis. 
% 
% The filename can take a couple of forms...consequences outlined below. 
%
% Give filename (including path) without the trailing E or A. Will check
% for both files. Efile checked first; it it doesn't exist you get an error
% exit. 
% To process both efile (steering vars) and afile (eye data, can also get 
% joystick data, but we don't) data, give 
%


    switch nargin
        case 0
            s = localInitStruct();
            p = class(s, 'stefile');
        case 1
            if (isa(varargin{1}, 'stefile'))
                p = varargin{1};
            elseif (isstruct(varargin{1}))
                s = varargin{1};
                p = class(s, 'stefile');
            elseif (isa(varargin{1}, 'char') && size(varargin{1}, 1)==1)

                % Determine what kind of processing is requested. 
                [efile, afile] = localFilesExist(varargin{1});
                
                % At a minimum the efile must exist. 
                if isempty(efile)
                    error('efile not found.');
                end
                
                % If we made it here then the efile exists. Use it to generate 
                % the ecfile object, and use that object to generate the
                % efile data structs. 
                
                e = ecfile(efile);

                switch get(e, 'ID')
                    case 401
                        s = localGetStruct401(e);
                    case {402, 403, 404}
                        s = localGetStruct402(e);
                    case 405
                        s = localGetStruct405(e);
                    case {407, 408, 409, 3768, 4056, 1488, 3960, 4008, 4032, 4984, 3984, 3840, 8056, 4336}
                        s = localGetStruct407(e);
                    case {410, 411, 412}
                        s = localGetStruct410(e);
                    case 450
                        s = localGetStruct450(e);
                    otherwise
                        fprintf('Paradigm id %d not handled!\n', get(e, 'ID'));
                        error('Unknown paradigm id');
                end

                s.efile = efile;
                s.afile = afile;
                
                % Now attempt to do afile processing if the afile was
                % found. 
                
 %               if ~isempty(afile)
 %                   s.adata = localGetAdata(afile, get(e, 'ID'));
 %               end
                
                p = class(s, 'stefile');

            else
                error('Input arg must be a filename or a stefile object.');
            end
        otherwise
            error('Wrong number of input arguments');
    end


return;
end


% In paradigm 401, st11 and prior, frames were considered "jump" frames or
% "update" frames. Update frames had no jump, and had codes U123, whereas
% jump frames had codes L123 or R123. Blips and blinks came before them.
%
% Extracting the data stream is simple - we need only look for [LRU]123.
% Why incorporate the other events into the regex, then? Well, it seems
% that there are cases where the timestamp on those events may differ from
% the timestamp on the updates. This causes trouble when matching times
% between events and updates. So we include the BCYZ events in the regex
% for the update stream so that we will have the same timestamps on events
% and updates. 
%
function [p] = localGetStruct401(e)
    codes=int32([1003 1501 1502 1503 1505 1506 1508 1509 1510 1512 1513 1514 1515 1516 1517 8192 1 2 3 4 5 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 1030]);
    letters='PITUMEKWJLRBCYZX12345abcdefghijklmnopw';

    % encode the codes and letters above
    [str, strind] = ecencode(int32(get(e, 'Channels')), codes, letters);

    p = localInitStruct();

    % fetch misc properties
    p.fps = bcodeValue(e, strind(find(str=='a', 1)));
    p.speed = bcodeValue(e, strind(find(str == 'b', 1)));
    p.steermaxdeg = bcodeValue(e, strind(find(str == 'g', 1)));

    % regex to find timestream elements and events
    s=struct;
    s(1).a=0;
    s(1).b=-1;
    s(1).c='t';
    s(2).a=6;
    s(2).b=0;
    s(2).c='joy';
    s(3).a=6;
    s(3).b=1;
    s(3).c='heading';
    s(4).a=6;
    s(4).b=2;
    s(4).c='target';
    fprintf(1, 'call makeseries for data stream\n');
    tic
    p.data=makeseries(struct(e), str, strind-1, '((B45)|(C)|(Y)|(Z))?[LRUJ](123)', s);
    toc
    fprintf(1, 'call makeseries for data stream -- done\n');


    % Lone wolf events - events dropped outside of updates. 
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';
    fprintf(1, 'call makeseries for lw events\n');
    tic
    lwevents=makeseries(struct(e), str, strind-1, '([TMEWw])', s);
    toc
    fprintf(1, 'call makeseries for lw events -- done\n');

    % Now get BCYZ events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';

    fprintf(1, 'call makeseries for BCYZ events\n');
    tic
    events=makeseries(struct(e), str, strind-1, '((B45)|(C)|(Y)|(Z))[LRUJ](123)', s);
    toc
    fprintf(1, 'call makeseries for all events -- done\n');

        % Now get BCYZ events
    clear s;
    s = struct;
    s(1).a=6;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=0;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=7;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=7;
    s(4).b=2;
    s(4).c='d2';

    fprintf(1, 'call makeseries for LR events\n');
    tic
    lrevents=makeseries(struct(e), str, strind-1, '((B45)|(C)|(Y)|(Z))?([LR])(123)', s);
    toc
    fprintf(1, 'call makeseries for all events -- done\n');


    % concatenate and sort
    p.events = sortrows(vertcat(events, lwevents, lrevents), 2);

    % find indices of LEFT jumps in the event data
    fprintf(1, 'Find L events\n');
    tic
    b = find(p.events(:, 1) == int32('L'));

    % Now find the corresponding indices in the update data
    fprintf(1, 'Fix %d L events\n', length(b));
    for i=1:length(b),
        % bu1 is the index in z (the update data) where the jump's time is
        % matched
        bu1 = find (p.data(:, 1) == p.events(b(i), 2));
        if isempty(bu1), 
            fprintf(1, 'ERR i=%d b=%d ze(b, 2)=%d\n', i, b(i), p.events(b(i), 2));
        else
            p.events(b(i), 3) = p.data(bu1, 4) - p.data(bu1-1, 4);
        end
    end


    % find indices of RIGHT jumps in the event data
    fprintf(1, 'Find R events\n');
    b = find(p.events(:, 1) == int32('R'));

    % Now find the corresponding indices in the update data
    fprintf(1, 'Fix %d R events\n', length(b));
    for i=1:length(b),
        % bu1 is the index in z (the update data) where the jump's time is
        % matched
        bu1 = find (p.data(:, 1) == p.events(b(i), 2));
        if isempty(bu1), 
            fprintf(1, 'ERR i=%d b=%d ze(b, 2)=%d\n', i, b(i), p.events(b(i), 2));
        else
            p.events(b(i), 3) = p.data(bu1, 4) - p.data(bu1-1, 4);
        end
    end
    toc
    return;
end


% In paradigm 407 the fixation position changes each trial. Channels 8 and
% 9 are used to record the fixation x and y, respectively. 

function [p] = localGetStruct407(e)
    codes=int32([8 9 1003 1501 1502 1503 1505 1506 1508 1509 1510 1512 1513 1514 1515 1516 1517 8192 1184 1180 1 2 3 4 5 6 7 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 1030]);
    letters='xyPITUMEKWJLRBCYZXFG1234567abcdefghijklmnopw';

    % encode the codes and letters above
    [str, strind] = ecencode(int32(get(e, 'Channels')), codes, letters);

    p = localInitStruct();

    % fetch misc properties
    p.fps = bcodeValue(e, strind(find(str=='a', 1)));
    p.speed = bcodeValue(e, strind(find(str == 'b', 1)));
    p.steermaxdeg = bcodeValue(e, strind(find(str == 'g', 1)));

    % regex to find timestream elements and events
    s=struct;
    s(1).a=8;
    s(1).b=-1;
    s(1).c='t';
    s(2).a=8;
    s(2).b=0;
    s(2).c='joy';
    s(3).a=8;
    s(3).b=1;
    s(3).c='heading';
    s(4).a=8;
    s(4).b=2;
    s(4).c='target';
    fprintf(1, 'call makeseries for data stream\n');
    tic
    p.data=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))?U(123)', s);
    toc
    fprintf(1, 'call makeseries for data stream -- done\n');


    % Lone wolf events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';
    fprintf(1, 'call makeseries for lw events\n');
    tic
    lwevents=makeseries(struct(e), str, strind-1, '([TMEWw])', s);
    toc
    fprintf(1, 'call makeseries for lw events -- done\n');

    % xy events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=0;
    s(3).c='x';
    s(4).a=1;
    s(4).b=1;
    s(4).c='y';
    fprintf(1, 'call makeseries for xy events\n');
    tic
    xyevents=makeseries(struct(e), str, strind-1, '(xy)', s);
    toc
    fprintf(1, 'call makeseries for xy events -- done\n');

    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';

    % TODO: The following only applies to id<405!

    fprintf(1, 'call makeseries for all events\n');
    tic
    events=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))U(123)', s);
    toc
    fprintf(1, 'call makeseries for all events -- done\n');


    % concatenate and sort
    p.events = sortrows(vertcat(events, lwevents, xyevents), 2);

    return;
end




% In paradigm 405 the jump magnitude and heading offset are explicitly
% dumped in channels 6 and 7 with each jump code. Otherwise similar to 402.
% As you might expect, this obviates the need for computing the jump
% magnitude. Obviates is a cool word. 
% 

function [p] = localGetStruct405(e)
    codes=int32([1003 1501 1502 1503 1505 1506 1508 1509 1510 1512 1513 1514 1515 1516 1517 8192 1 2 3 4 5 6 7 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 1030]);
    letters='PITUMEKWJLRBCYZX1234567abcdefghijklmnopw';

    % encode the codes and letters above
    [str, strind] = ecencode(int32(get(e, 'Channels')), codes, letters);

    p = localInitStruct();

    % fetch misc properties
    p.fps = bcodeValue(e, strind(find(str=='a', 1)));
    p.speed = bcodeValue(e, strind(find(str == 'b', 1)));
    p.steermaxdeg = bcodeValue(e, strind(find(str == 'g', 1)));

    % regex to find timestream elements and events
    s=struct;
    s(1).a=8;
    s(1).b=-1;
    s(1).c='t';
    s(2).a=8;
    s(2).b=0;
    s(2).c='joy';
    s(3).a=8;
    s(3).b=1;
    s(3).c='heading';
    s(4).a=8;
    s(4).b=2;
    s(4).c='target';
    fprintf(1, 'call makeseries for data stream\n');
    tic
    p.data=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))?U(123)', s);
    toc
    fprintf(1, 'call makeseries for data stream -- done\n');


    % Lone wolf events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';
    fprintf(1, 'call makeseries for lw events\n');
    tic
    lwevents=makeseries(struct(e), str, strind-1, '([TMEWw])', s);
    toc
    fprintf(1, 'call makeseries for lw events -- done\n');

    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';

    % TODO: The following only applies to id<405!

    fprintf(1, 'call makeseries for all events\n');
    tic
    events=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))U(123)', s);
    toc
    fprintf(1, 'call makeseries for all events -- done\n');


    % concatenate and sort
    p.events = sortrows(vertcat(events, lwevents), 2);

    return;
end

% In paradigm 402, which was st12 (and st12a), the U code was passed every
% time the 123 codes were passed (each frame). The LR codes were dropped
% separately on their respective frames. So jump frames would have, e.g.,
% LU123 or RU123

function [p] = localGetStruct402(e)
    codes=int32([1003 1501 1502 1503 1505 1506 1508 1509 1510 1512 1513 1514 1515 1516 1517 8192 1 2 3 4 5 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 1030]);
    letters='PITUMEKWJLRBCYZX12345abcdefghijklmnopw';

    % encode the codes and letters above
    [str, strind] = ecencode(int32(get(e, 'Channels')), codes, letters);

    p = localInitStruct();

    % fetch misc properties
    p.fps = bcodeValue(e, strind(find(str=='a', 1)));
    p.speed = bcodeValue(e, strind(find(str == 'b', 1)));
    p.steermaxdeg = bcodeValue(e, strind(find(str == 'g', 1)));

    % regex to find timestream elements and events
    s=struct;
    s(1).a=8;
    s(1).b=-1;
    s(1).c='t';
    s(2).a=8;
    s(2).b=0;
    s(2).c='joy';
    s(3).a=8;
    s(3).b=1;
    s(3).c='heading';
    s(4).a=8;
    s(4).b=2;
    s(4).c='target';
    fprintf(1, 'call makeseries for data stream\n');
    tic
    p.data=makeseries(struct(e), str, strind-1, '((L)|(R)|(B45)|(C)|(Y)|(Z))?U(123)', s);
    toc
    fprintf(1, 'call makeseries for data stream -- done\n');


    % Lone wolf events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';
    fprintf(1, 'call makeseries for lw events\n');
    tic
    lwevents=makeseries(struct(e), str, strind-1, '([TMEWw])', s);
    toc
    fprintf(1, 'call makeseries for lw events -- done\n');

    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';

    % TODO: The following only applies to id<405!

    fprintf(1, 'call makeseries for all events\n');
    tic
    events=makeseries(struct(e), str, strind-1, '((L)|(R)|(B45)|(C)|(Y)|(Z))U(123)', s);
    toc
    fprintf(1, 'call makeseries for all events -- done\n');


    % concatenate and sort
    p.events = sortrows(vertcat(events, lwevents), 2);

    % find indices of LEFT jumps in the event data
    fprintf(1, 'Find L events\n');
    tic
    b = find(p.events(:, 1) == int32('L'));

    % Now find the corresponding indices in the update data
    fprintf(1, 'Fix %d L events\n', length(b));
    for i=1:length(b),
        % bu1 is the index in z (the update data) where the jump's time is
        % matched
        bu1 = find (p.data(:, 1) == p.events(b(i), 2));
        if isempty(bu1), 
            fprintf(1, 'ERR i=%d b=%d ze(b, 2)=%d\n', i, b(i), p.events(b(i), 2));
        else
            p.events(b(i), 3) = p.data(bu1, 4) - p.data(bu1-1, 4);
        end
    end


    % find indices of RIGHT jumps in the event data
    fprintf(1, 'Find R events\n');
    b = find(p.events(:, 1) == int32('R'));

    % Now find the corresponding indices in the update data
    fprintf(1, 'Fix %d R events\n', length(b));
    for i=1:length(b),
        % bu1 is the index in z (the update data) where the jump's time is
        % matched
        bu1 = find (p.data(:, 1) == p.events(b(i), 2));
        if isempty(bu1), 
            fprintf(1, 'ERR i=%d b=%d ze(b, 2)=%d\n', i, b(i), p.events(b(i), 2));
        else
            p.events(b(i), 3) = p.data(bu1, 4) - p.data(bu1-1, 4);
        end
    end
    toc
    return;
end

% id 450 is steering tuning = steertune paradigm. 

function [p] = localGetStruct450(e)
    codes=int32([1500 1502 1503 1520 1521 1522 1505 1506 1509 601 1 2 3]);
    letters='XTULSFMEWI123';

    % encode the codes and letters above
    [str, strind] = ecencode(int32(get(e, 'Channels')), codes, letters);

    p = localInitStruct();

    % fetch misc properties
%    p.fps = bcodeValue(e, strind(find(str == 'a')));
%    p.speed = bcodeValue(e, strind(find(str == 'b')));
%    p.steermaxdeg = bcodeValue(e, strind(find(str == 'g')));


    % Lone wolf events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=0;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';
    fprintf(1, 'call makeseries for lw events\n');
    tic
    lwevents=makeseries(struct(e), str, strind-1, '([XTULSFMEWI123])', s);
    toc
    fprintf(1, 'call makeseries for lw events -- done\n');

    % concatenate and sort
    p.events = sortrows(lwevents, 2);

    return;
end


% ID 410 is the first paradigm with jitters. 
% Data stream contains the same old elements (joy, heading, target), and 
% three additional values: jittertraj, jittertarg, meandertarg.
% djs: Add S=601 (spikes), N=1161
% djs: Add USTIMON/USTIMOFF = 1550/1551 = A/Q
% djs: Add Fixed looking stuff: 193/18 = D/

function [p] = localGetStruct410(e)
    codes=int32([8 9 12 13 14 15 16 17 1003 1501 1502 1503 1505 1506 1508 1509 1510 1512 1513 1514 1515 1516 1517 8192 1184 1180 1 2 3 4 5 6 7 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 601 1161 1520 1550 1551 192 1030 193 18]);
    letters='xyqrstuvPITUMEKWJLRBCYZXFG1234567abcdefghijklmnopSNOAQzwDH';

    % encode the codes and letters above
    [str, strind] = ecencode(int32(get(e, 'Channels')), codes, letters);

    p = localInitStruct();

    % fetch misc properties
    p.fps = bcodeValue(e, strind(find(str=='a', 1)));
    p.speed = bcodeValue(e, strind(find(str == 'b', 1)));
    p.steermaxdeg = bcodeValue(e, strind(find(str == 'g', 1)));

    % regex to find timestream elements and events
    s=struct;
    s(1).a=8;
    s(1).b=-1;
    s(1).c='t';
    s(2).a=8;
    s(2).b=0;
    s(2).c='joy';
    s(3).a=8;
    s(3).b=1;
    s(3).c='heading';
    s(4).a=8;
    s(4).b=2;
    s(4).c='target';
    s(5).a=8;
    s(5).b=3;
    s(5).c='jittertraj';
    s(6).a=8;
    s(6).b=4;
    s(6).c='jittertarg';
    s(7).a=8;
    s(7).b=5;
    s(7).c='meandertarg';
    fprintf(1, 'call makeseries for data stream\n');
    tic
    switch (get(e, 'ID'))
        case 410
            p.data=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))?U(123qrs)', s);
            p.fixedlooking = 0;
        case 411
            s(8).a=8;
            s(8).b=6;
            s(8).c='diffusiontarg';
            p.data=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))?U(123qrsv)', s);
            p.fixedlooking = 0;
        case 412
            s(8).a=8;
            s(8).b=6;
            s(8).c='diffusiontarg';
            p.data=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))?U(123qrsv)', s);
            p.fixedlooking = bcodeValue(e, strind(find(str == 'D', 1)));
        otherwise
            error 'localGetStruct410: only call this func for ID 410, 411, or 412.';
    end
        
    toc
    fprintf(1, 'call makeseries for data stream -- done\n');


    % Lone wolf events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=0;   % change from 1?
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';
    fprintf(1, 'call makeseries for lw events\n');
    tic
    lwevents=makeseries(struct(e), str, strind-1, '([TMEWGSNOAQzwH])', s);
    toc
    fprintf(1, 'call makeseries for lw events -- done\n');

    % xy events
    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=0;
    s(3).c='x';
    s(4).a=1;
    s(4).b=1;
    s(4).c='y';
    fprintf(1, 'call makeseries for xy events\n');
    tic
    xyevents=makeseries(struct(e), str, strind-1, '(xy)', s);
    toc
    fprintf(1, 'call makeseries for xy events -- done\n');

    clear s;
    s = struct;
    s(1).a=1;
    s(1).b=-2;
    s(1).c='c';
    s(2).a=1;
    s(2).b=-1;
    s(2).c='t';
    s(3).a=1;
    s(3).b=1;
    s(3).c='d1';
    s(4).a=1;
    s(4).b=2;
    s(4).c='d2';

    fprintf(1, 'call makeseries for all events\n');
    tic
    events=makeseries(struct(e), str, strind-1, '((L67)|(R67)|(B45)|(C)|(Y)|(Z))U(123)', s);
    toc
    fprintf(1, 'call makeseries for all events -- done\n');

    
    % concatenate and sort
    p.events = sortrows(vertcat(events, lwevents, xyevents), 2);

    return;
end





function [s] = localInitStruct()
    s = struct;
    s.fps = 0;
    s.speed = 0;
    s.steermaxdeg = 0;
    s.data = [];
    s.events = [];
    s.adata = [];
    s.efile = '';
    s.afile = '';
    s.fixedlooking = 0;
    return;
end

function [s] = localGetAdata(afile)
    s = [];
    return;
end

function [efile, afile] = localFilesExist(ifile)
    efile = '';
    afile = '';
    
    % attempt to append an 'E' and open file. 
    fid = fopen(strcat(ifile, 'E'));
    if fid < 0
        % Maybe the ifile already has the 'E'. 
        fid = fopen(ifile);
        if fid < 0
            return;
        else
            fclose(fid);
            efile = ifile;
            
            % strip off the 'E', append an 'A' and try to open. 
            tfile = ifile;
            tfile(length(tfile)) = 'A';
            fid = fopen(tfile);
            if fid > 0
                fclose(fid);
                afile = tfile(1:length(tfile)-1);
            end
        end
    else
        fclose(fid);
        efile = strcat(ifile, 'E');
        fid = fopen(strcat(ifile, 'A'));
        if fid < 0
            return;
        else
            fclose(fid);
            afile = ifile;
        end
    end
    return;
end

% $Log: stefile.m,v $
% Revision 1.2  2015/05/12 18:18:02  devel
% Disaster recovery, from sake
%
% Revision 1.2  2015/04/13 21:29:28  djsperka
% Add handling for paradigm 412, with fixed looking.
%
% Revision 1.1.1.1  2013/12/04 22:43:48  devel
% Reorganized cns toolbox
%
% Revision 1.23  2012/06/29 22:24:42  djsperka
% Change extraction to always extract reward code 1030 as event type w.
%
% Revision 1.22  2011/11/28 18:17:57  devel
% Add extract code for REWCD(1030)=w for ID 410.
%
% Revision 1.21  2011/08/02 19:03:00  devel
% Add ID 411, which has target diffusion, to extraction. getSequences has a new datatype, diffusiontarg, which may be extracted.
%
% Revision 1.20  2010/09/23 23:42:42  devel
% Add support for ustimon/off codes in ID=410 (ste22) data. Letters are A/Q for ON/OFF.
%
% Revision 1.19  2010-07-12 19:00:38  devel
% Merge uncommitted changs from unagi. Added spikes (S/601) and timing markers (N)/1161/1520)
%
% Revision 1.17  2010-02-08 18:37:44  devel
% Add handling for jitter-type paradigm ID=410
%
% Revision 1.16  2009-12-31 00:21:40  devel
% Add handling for FIXCD and BREAKFIXCD events.
%
% Revision 1.15  2009-12-19 00:43:18  devel
% Added paradigm id 409 (same as 407)
%
% Revision 1.14  2009-09-10 22:15:16  devel
% Add new funny ID codes for paradigm ID mis-identifications. Fix bug in localGetStruct* when more than 1 RESET hit in daq -- which leads to multiple sets of expt conditions. When fetching fps, maxsteerdeg more than one index is found when searching for the bcode. Fixed.
%
% Revision 1.13  2009-08-12 22:44:23  devel
% Add hack for mysterious paradigm ID values.
%
% Revision 1.12  2009-08-04 18:46:15  devel
% Coding efficiencies. Added handling for ID 407 (st20)
%
