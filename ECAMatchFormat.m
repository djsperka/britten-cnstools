classdef ECAMatchFormat < handle
    %ECAMatchFormat Specifies format for the output of a match.
    %   When used with the method MappedECAData.match('Format',
    %   matchFormat), the match() method returns
    
    properties (SetAccess = private)
        Token = [];
        Position = [];
        Type = {};
        AllowedTypes = {'value', 'time', 'char', 'channel'};
    end
    
    methods
        function n = addColumn(this, varargin)
            p = inputParser;
            p.FunctionName = 'addColumn';
            p.addRequired('Token', @(x) isscalar(x));
            p.addRequired('Position', @(x) isscalar(x));
            p.addOptional('Type', 'value', @(x) strmatch(x, this.AllowedTypes, 'exact'));
            p.parse(varargin{:});            
            this.Token(length(this.Token)+1) = p.Results.Token;
            this.Position(length(this.Position)+1) = p.Results.Position;
            this.Type{length(this.Type)+1} = p.Results.Type;
            n = length(this.Token);
            return;
        end
    end    
end

