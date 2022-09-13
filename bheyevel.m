function [ tsvel ] = bheyevel( tseyeh, tseyev )
%bheyevel compute eye velocity using sliding window
%   Compute eye speed using the eye position h,v values. Return a
%   timeseries of velocities. 

posmask = ones(10,1)/10;
velmask = zeros(11,1);
velmask(1) = -100;
velmask(end) = 100;     % velmask looks like [-100 0 0 ... 0 0 100]

havgpos = conv(tseyeh.Data, posmask, 'same');
vavgpos = conv(tseyev.Data, posmask, 'same');
vh = conv(havgpos, velmask, 'same');
vv = conv(vavgpos, velmask, 'same');
tsvel = timeseries(sqrt(vh.^2 + vv.^2), tseyeh.Time);
tsvel.DataInfo.Units = 'degrees/sec';
tsvel.TimeInfo.Units = 'milliseconds';
tsvel.Name = 'Eye Velocity (sliding window avg)';

end

