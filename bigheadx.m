function [timeseries, trials, events, spikes, idata] = bigheadx(varargin)

% BIGHEADX extracts useful data from the E and A-files collected in the
% bighead paradigm. 
%
% [timeseries, trials, events, spikes, idata]=bigheadx('path_to_Efile', 'path_to_Afile');
% [timeseries, trials, events, spikes, idata]=bigheadx('path_to_Efile_base');
%
% The Efile is read and certain ecodes are converted to characters. The
% resulting string is then searched for patterns which correspond to
% complete trials and spikes. The Afile is read and eye position data for
% each trial is extracted. 
%
% The second form of the command requires a full path and the E file base -
% that is, the efile name without the trailing E. It is assumed that the
% A-file is in the same directory.
%
% The 'spikes' array is Nx1 list of spike times (all times are absolute, 
% meaning they are the same as the times recorded in the Efile) -- spikes 
% are taken as ecode 601. 
% 
% The 'trials' array is nx10, where n is the number of complete trials
% found. Complete trials are those that run to completion, with a reward
% given. Trials where fixation is broken are not included. Trials with 
% any dropped frames are also NOT included. 
% The 10 columns are as follows:
% 
% 1: trials tart time
% 2: trial type index (0, 1, 2, ... depends on how many trial types)
% 3: translation azimuth (degrees)
% 4: translation elevation (degrees)
% 5: translation speed (units/frame)
% 6: pursuit angle (degrees)
% 7: pursuit speed (degrees/frame)
% 8: translation type (0=no trans; 1=trans; frozen dots is trans with v=0)
% 9: pursuit type (0=no pursuit; 1=pursuit; 2=simulated pursuit; 3=pursuit
%                  with retinal stabilization)
% 10: trial end time
%
%
% The 'timeseries' matrix is nx16. Each row represents the parameters set
% for a single video frame. The rows are not separated into trials; use the
% time value to get frame series for an individual trial. 
%
% The columns of the timeseries are as follows:
%
% 1: time of WENT (when frame drawing began)
% 2: eye/camera position X
% 3: eye/camera position Y
% 4: eye/camera position Z
% 5: eye/camera looking dir a0 (see below)
% 6: eye/camera looking dir a1 (see below)
% 7: eye/camera looking dir a2 (see below)
% 8: eye/camera looking dir flag (see below)
% 9: dot position phi (see below)
% 10: dot position beta (see below)
% 11: dot position rho (see below)
% 12: eye velocity OK
% 13: eye velocity X
% 14: eye velocity Y
% 15: azimuth correction (for retinal stabilization)
% 16: elevation correction (for retinal stabilization)
%
% The 'idata' matrix is nx3xM, where n is the number of trials and M is the
% maximum number of eye position samples taken during each of the pursuit
% periods. All eye position values between the trial start and end times
% are extracted. There are usually small variations in the number of 
% readings during this period. Extra values are padded with NaN. 
% Column 1,2,3 are eyeX, eyeY, time. For
% example, idata(10, 1, :) is the array of all eyeX values from trial 10;
% idata(10, 3, :) is the array of all time values for those eyeX values. 

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


% Get spikes first
spike_letters='S';
spike_codes=int32([601]);
[spike_str, spike_ind] = ecencode(int32(get(e, 'Channels')), spike_codes, spike_letters);

clear s;
s=struct;
s(1).a=0;
s(1).b=-1;
s(1).c='s';

spikes = makeseries(struct(e), spike_str, spike_ind-1, 'S', s);


% Get trials

letters = 'WMDSACPBGTEXYFRabcdefghijklmnopqrstuvw';
codes = int32([1509 1505 1560 1561 1562 1563 1564 1565 1566 1166 1167 1180 1181 1184 1030 1 2 3 4 5 6 7 8 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35]);
[str, strind] = ecencode(int32(get(e, 'Channels')), codes, letters);


strials=struct;
strials(1).a=1;
strials(1).b=-1;
strials(1).c='T';
strials(2).a=1;
strials(2).b=1;
strials(2).c='a';
strials(3).a=1;
strials(3).b=2;
strials(3).c='b';
strials(4).a=1;
strials(4).b=3;
strials(4).c='c';
strials(5).a=1;
strials(5).b=4;
strials(5).c='d';
strials(6).a=1;
strials(6).b=5;
strials(6).c='e';
strials(7).a=1;
strials(7).b=6;
strials(7).c='f';
strials(8).a=1;
strials(8).b=7;
strials(8).c='g';
strials(9).a=1;
strials(9).b=8;
strials(9).c='h';
strials(10).a=2;
strials(10).b=-1;
strials(10).c='Y';

trials = makeseries(struct(e), str, strind-1, '(Tabcdefgh)[^XTM]*(Y)', strials);


% timeseries - settings in place at each WENT
ss=struct;
ss(1).a = 2;
ss(1).b = -1;
ss(1).c = 'T';
ss(2).a = 1;
ss(2).b = 0;
ss(2).c = 'i';
ss(3).a = 1;
ss(3).b = 1;
ss(3).c = 'j';
ss(4).a = 1;
ss(4).b = 2;
ss(4).c = 'k';
ss(5).a = 1;
ss(5).b = 3;
ss(5).c = 'l';
ss(6).a = 1;
ss(6).b = 4;
ss(6).c = 'm';
ss(7).a = 1;
ss(7).b = 5;
ss(7).c = 'n';
ss(8).a = 1;
ss(8).b = 6;
ss(8).c = 'o';
ss(9).a = 1;
ss(9).b = 7;
ss(9).c = 'p';
ss(10).a = 1;
ss(10).b = 8;
ss(10).c = 'q';
ss(11).a = 1;
ss(11).b = 9;
ss(11).c = 'r';
ss(12).a = 1;
ss(12).b = 10;
ss(12).c = 's';
ss(13).a = 1;
ss(13).b = 11;
ss(13).c = 't';
ss(14).a = 1;
ss(14).b = 12;
ss(14).c = 'u';
ss(15).a = 1;
ss(15).b = 13;
ss(15).c = 'v';
ss(16).a = 1;
ss(16).b = 14;
ss(16).c = 'w';

timeseries = makeseries(struct(e), str, strind-1, '(ijklmnopqrstuvw)(W)', ss);




% lw events
slw = struct;
slw(1).a = 1;
slw(1).b = -1;
slw(1).c = ' ';
slw(2).a = 1;
slw(2).b = -2;
slw(2).c = ' ';
slw(3).a = 1;
slw(3).b = 1;
slw(3).c = ' ';
slw(4).a = 1;
slw(4).b = 2;
slw(4).c = ' ';

events = makeseries(struct(e), str, strind-1, '([DSACPBGR])', slw);

% extract adata
adata=mrdr('-c', '-a', '-d', AFILE, '-s', '1166');
atrials=Trial(adata);

% 
found=0;
maxsize=0;
startIndex=zeros(1, length(trials(:, 1)));
endIndex=zeros(1, length(trials(:, 1)));
whichTrial=zeros(1, length(trials(:, 1)));
for i=1:length(trials(:, 1))
%for i=1:10
%    fprintf('trial %d period %d-%d\n', i, trials(i, 6), trials(i, 8));
    found = 0;
    j = 1;
    while found==0 && j <=length(atrials)
%    for j=1:length(atrials)
        if trials(i, 1)<aEndTime(atrials(j)) && trials(i, 10)>aStartTime(atrials(j))
%            fprintf('this fix period is in atrial %d\n', j);
            found = 1;
            
            whichTrial(i) = j;
            startIndex(i) = trials(i,1)-aStartTime(atrials(j))+1;
            endIndex(i) = trials(i,10)-aStartTime(atrials(j))+1;
            thissize = endIndex(i)-startIndex(i)+1;
            if thissize>maxsize
                maxsize = thissize;
            end
%            fprintf('trial %d indices %d-%d\n', j, startIndex(i), endIndex(i));
        end
        j = j + 1;
    end
    if found == 0 
        fprintf('warning! fix period for trial %d not contained in a (rex)trial!\n', i);
    end
    
end


%fprintf('Max size is %d\n', maxsize);

% idata: column 1, 2, 3 is x, y, t. 
% idata(:, :, 1) is for trial 1, ...
idata = zeros(maxsize, 3, length(trials(:, 1)));
for i=1:length(startIndex)
%for i=1:10
    if whichTrial(i) > 0
        signals = Signals(atrials(whichTrial(i)));
%        fprintf('%d max %d this %d, t %d\n', i, maxsize, endIndex(i)-startIndex(i)+1, length([aStartTime(atrials(whichTrial(i)))+startIndex(i)-1:aStartTime(atrials(whichTrial(i)))+endIndex(i)-1]));
        len = endIndex(i)-startIndex(i)+1;
        idata(1:len, 1, i) = signals(1).Signal(startIndex(i):endIndex(i))';
        idata(1:len, 2, i) = signals(2).Signal(startIndex(i):endIndex(i))';
        idata(1:len, 3, i) = [aStartTime(atrials(whichTrial(i)))+startIndex(i)-1:aStartTime(atrials(whichTrial(i)))+endIndex(i)-1]';
    else
        idata(:, :, i) = nan;
    end
end



return;
