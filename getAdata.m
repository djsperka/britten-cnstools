function [a] = getAdata(adata)
    a=[];

    trials=Trial(adata);

    % Number of data points in trial
    % trialSize = aEndTime(trials(1))-aStartTime(trials(1))+1;

    npts = 0;
    for i=1:length(trials)
        signals=Signals(trials(i));
        % occasionally we have trials with no signals. Not sure why, but we
        % should account for them... by just skipping over them. 
        if length(signals) > 0
            nt = aEndTime(trials(i))-aStartTime(trials(i))+1;
            n1 = length(signals(1).Signal);
            n2 = length(signals(2).Signal);
            n7 = length(signals(7).Signal);

            if nt~=n1 || nt~=n2 || nt~=n7
                fprintf('Trial %d ??? nt/n1/n2/n7 %d/%d/%d/%d\n', i, nt, n1, n2, n7);
                break;
            end

            % tally
            npts = npts + nt;
        end
    end
    fprintf(1, 'npts=%d\n', npts);
    
    % Now allocate the matrix
    a=zeros(npts, 4);
    
    % loop again, this time grabbing adata and assigning time values
    npts = 0;
    for i=1:length(trials)
        signals=Signals(trials(i));
        % watch out for  signal-less trials...
        if length(signals) > 0
            nt = aEndTime(trials(i))-aStartTime(trials(i))+1;
            a(npts+1:npts+nt, 1) = [aStartTime(trials(i)):aEndTime(trials(i))]';
            a(npts+1:npts+nt, 2) = signals(1).Signal(1:end);
            a(npts+1:npts+nt, 3) = signals(2).Signal(1:end);
            a(npts+1:npts+nt, 4) = signals(7).Signal(1:end);
            npts = npts+nt;
        end
    end
    return;
end