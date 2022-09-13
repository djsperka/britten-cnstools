function [ts] = getRexTimeseries(adata, varargin)
%getRexTimeseries Returns timeseries for specified signal(s), with optional
%start/end time. 

    % Check output arguments
    nargoutchk(1, 1);

    % Parse input.
    p = inputParser;
    p.FunctionName = 'getRexTimeseries';
    p.addRequired('adata', @(x) isstruct(x));
    p.addOptional('Name', '', @(x) ischar(x));
    p.addOptional('Signals', [1 2], @(x) isnumeric(x));


    %disp 'The input parameters for this program are';
    %disp(p.Parameters);
    p.parse(adata, varargin{:});

    % get individual trials, as determined by the rex extraction.
    trials=Trial(adata);

    % Number of data points in trial
    % trialSize = aEndTime(trials(1))-aStartTime(trials(1))+1;

    nsignals = length(p.Results.Signals);
    npts = 0;
    for i=1:length(trials)
        
        s=Signals(trials(i));
        % occasionally we have trials with no signals. Not sure why, but we
        % should account for them... by just skipping over them. 
        if length(s) > 0
            nt = aEndTime(trials(i))-aStartTime(trials(i))+1;
        end

        % tally
        npts = npts + nt;

    end
    
    % Now allocate the matrix
    a=zeros(npts, nsignals+1);
    
    % loop again, this time grabbing adata and assigning time values
    npts = 0;
    for i=1:length(trials)
        s=Signals(trials(i));
        % watch out for  signal-less trials...
        if length(s) > 0
            nt = aEndTime(trials(i))-aStartTime(trials(i))+1;
            %fprintf(1, 'trial %d nt %d start time %d end %d\n', i, nt, aStartTime(trials(i)), aEndTime(trials(i)));
            a(npts+1:npts+nt, 1) = [aStartTime(trials(i)):aEndTime(trials(i))]';
            for j=1:nsignals            
                a(npts+1:npts+nt, j+1) = s(p.Results.Signals(j)).Signal(1:end);
            end
            npts = npts+nt;
        end
    end
    
    ts = timeseries(a(:,2:end), a(:, 1));
    ts.Name = p.Results.Name;
    ts.TimeInfo.Units='milliseconds';
    ts.DataInfo.Units='degrees';
    return;
end