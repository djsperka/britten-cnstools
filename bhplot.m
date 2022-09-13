function [ h ] = bhplot( varargin )
%bhplot Plot eyeh,eyev for pursuit period of a bighead trial.
%   Given input 'trial' (MappedECAData object), find the pursuit key
%   frames and plot eyeh and eyev for the pursuit period. Also computes the 
%   velocity and plots it in the lower plot.
%   Other events recorded (see bcodes('ijklmnopqrstuv') can be plotted as
%   well. For example:
%   bhplot(trial, 'Extra', 'uv'); 
%   plots the eye position and velocity, as well as the azimuth and
%   elevation corrections during retinal stabilization. Similarly, 
%   bhplot(trial, 'Extra', 'uv', 'Labels', {'AZcorr', 'ELcorr'});
%   plots the same, with y-axis labels 'AZcorr' on 'u', and 'ELcorr' on
%   'v'.
%   Returns the graphic handle of the plot.



p = inputParser;
p.FunctionName = 'bhplot';
p.addRequired('TrialMecad', @(x) isa(x, 'MappedECAData'));
p.addParamValue('Extra', '', @(x) ischar(x));
p.addParamValue('Labels', {}, @(x) iscellstr(x));
p.parse(varargin{:});

trial = p.Results.TrialMecad;
nplots = 2+length(p.Results.Extra);

% for convenience, find pursuit key frames:
% T - start of trial
% A - pursuit pause
% C - pursuit pre-start ("epsilon" period)
% P - pursuit start
% Y - trial end (success)

f = ECAMatchFormat;
f.addColumn(1, 1, 'time');  % column 1 of output will be trial start time
f.addColumn(2, 1, 'time');  % column 2 is pursuit pause time
f.addColumn(3, 1, 'time');  % column 3 is pre-start time
f.addColumn(4, 1, 'time');  % column 4 is pursuit start time
f.addColumn(5, 1, 'time');  % column 5 is trial end time (pursuit stops)

% Calling match() with format arg will return an array formatted according
% to the ECAMatchFormat object, NOT a MappedECAData object! We will use
% columns 4 and 5 as the limits of the analog data we want.
keyframes = trial.match('(T).*(A).*(C).*(P).*(Y)', 'Format', f);

% now get analog data. This data is returned as a timeseries object. 
eyeh = trial.analog('eyeh', 'Limits', keyframes(4:5));
eyev = trial.analog('eyev', 'Limits', keyframes(4:5));

% start times from 0....
eyeh.Time = eyeh.Time-eyeh.Time(1);
eyev.Time = eyev.Time-eyev.Time(1);

% get velocity
eyevel = bheyevel(eyeh, eyev);
eyevel.Time = eyevel.Time-eyevel.Time(1);

% now plot
h = subplot(nplots, 1, 1);
plot(eyeh);
hold on;
plot(eyev);
hold off;
subplot(nplots, 1, 2);
plot(eyevel);
ylim([0 50]);
ylabel('deg/sec');

% extra plots
for i=1:length(p.Results.Extra)
    ff=ECAMatchFormat;
    ff.addColumn(1, 1, 'time');
    ff.addColumn(1, 1, 'value');
    
    tt=trial.match(strcat('(', p.Results.Extra(i), ')'), 'Format', ff, 'Timeseries', 1);
    tt.Time = tt.Time-tt.Time(1);
    subplot(nplots, 1, 2+i);
    plot(tt);
    
    if length(p.Results.Labels) > 0
        if length(p.Results.Labels)==length(p.Results.Extra)
            ylabel(p.Results.Labels{i});
        else
            warn('Need one label for each extra char.');
        end
    end
end
    
end

