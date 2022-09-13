function [ s ] = bhtrialinfo( trial )
%bhtrialinfo Given a bighead trial, returns a struct with trial parameters
%   Assumes that input is a MappedECAData of a bighead trial. Looks for the
%   events 'a'-'h' and returns their values as the fields of a struct. 
%
%   col  evt
%   1     a   Trial condition
%   2     b   heading azimuth
%   3     c   heading elevation
%   4     d   heading speed
%   5     e   pursuit angle
%   6     f   pursuit speed
%   7     g   translation type (0:None, 1:Translation)
%   8     h   pursuit type     (0:None, 1:Pursuit, 2:Simulated, 3:RetStab)

    if ~isa(trial, 'MappedECAData')
        error('Input must be a MappedECAData object.');
    end
    
    f = ECAMatchFormat;
    f.addColumn(1, 1, 'value');
    f.addColumn(1, 2, 'value');
    f.addColumn(1, 3, 'value');
    f.addColumn(1, 4, 'value');
    f.addColumn(1, 5, 'value');
    f.addColumn(1, 6, 'value');
    f.addColumn(1, 7, 'value');
    f.addColumn(1, 8, 'value');

    a = trial.match('(abcdefgh)', 'Format', f);
    s = struct('condition', a(1), 'azimuth', a(2), 'elevation', a(3), 'heading_speed', a(4), 'pursuit_angle', a(5), 'pursuit_speed', a(6)*85, 'ttype', a(7), 'ptype', a(8));
end

