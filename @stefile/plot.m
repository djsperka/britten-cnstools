function varargout = plot(p, varargin)
% PLOT   Plot stefile data. 
disp(varargin);
allowedUnits = {'ms', 'milliseconds', 'seconds', 'sec', 'frames'};
parser = inputParser;
parser.FunctionName = 'stefile.plot';
parser.addParamValue('Units', 'Milliseconds', @(x)any(strcmpi(x, allowedUnits)));
parser.parse(varargin{:});

% fetch data from stefile object
data = get(p, 'Data');


switch (lower(parser.Results.Units))
    case {'ms', 'milliseconds'}
        timevec = data(:, 1);
    case {'seconds', 'sec'}
        timevec = data(:, 1)/1000;
    case 'frames'
        timevec = [1:size(data, 1)]';
    otherwise
        error 'Unknown units type!';
end

% axes limits init value = entire timevec
limx = [timevec(1) timevec(length(timevec))];



f = figure();
f = gcf;
if strcmp(get(f,'NextPlot'),'add')
    if isempty(get(f,'CurrentAxes'))
        set(f,'DefaultTextInterpreter','none');
        axHT = axes('parent',f);        
    else
        axHT = get(f,'CurrentAxes');
    end
else
    set(f,'nextplot','replace','DefaultTextInterpreter','none');
    axHT = axes('parent',f);
end
set(axHT, 'xlim', limx);

% Now that we have axes, add another axes object to the parent. 
    
% Not sure what all that 'DefaultTextInterpreter' stuff was. 
% Anyways, 'ax' is the axis where we're going to plot the heading and target. 
%I'd like to set up a
% key press function.......
set(f, 'KeyPressFcn', @localKeyPress);

lsHead = plot(axHT, timevec, data(:, 3), 'color', 'r'); % heading
hold(axHT);
lsTarg = plot(axHT, timevec, data(:, 4), 'Color', 'k');
hold off;

axJoy = axes('Parent', get(axHT, 'Parent'), ...
           'Position',get(axHT,'Position'),...
           'XAxisLocation','top',...
           'YAxisLocation','right',...
           'Color','none',...
           'XColor','k','YColor','k', 'XLim', limx);
hold(axJoy);
lsJoy = plot(axJoy, timevec, data(:, 2), 'color', 'b');
hold off;
axCam = axes('Parent', get(axHT, 'Parent'), ...
           'Position',get(axHT,'Position'),...
           'XLim', limx);
hold(axCam);
lsCam = plot(axCam, timevec, data(:, 4)-data(:, 3), 'color', 'g');
hold off;

% logicals that tell us when heading, target are visible (h/t). Camera visible toggles h/t off. 
flHeadVis=true;
flTargVis = true;
flCamVis = false;
flJoyVis = true;
localUpdateVis();

    function localUpdateVis()
        % Check if cam vis or not
        if flCamVis
            set(axCam, 'visible', 'on');
            set(lsCam, 'visible', 'on');
            set(axHT, 'visible', 'off');
            set(lsHead, 'visible', 'off');
            set(lsTarg, 'visible', 'off');

            if flJoyVis
                set(axJoy, 'visible', 'on');
                set(lsJoy, 'visible', 'on');
            else
                set(axJoy, 'visible', 'off');
                set(lsJoy, 'visible', 'off');
            end

        
        
        else
            set(axCam, 'visible', 'off');
            set(lsCam, 'visible', 'off');
            set(axJoy, 'visible', 'off');
            set(lsJoy, 'visible', 'off');
            set(axHT, 'visible', 'on');
            if flHeadVis
                set(lsHead, 'visible', 'on');
            else
                set(lsHead, 'visible', 'off');
            end
            if flTargVis
                set(lsTarg, 'visible', 'on');
            else
                set(lsTarg, 'visible', 'off');
            end
        end

    end
    function localKeyPress(src, evnt)

        lVisFlag = false;
        lDrawFlag = false;
        
        % src should be the figure which generated the event. We want to get
        % the axes, then get the x limits. 
        diff = limx(1, 2) - limx(1, 1);
        midx = limx(1, 1) + diff/2;
        if length(evnt.Modifier) == 1 & strcmp(evnt.Modifier{:},'control'),
            if evnt.Key == 'r',
                limx(1, 1) = midx - 3*diff/8;
                limx(1, 2) = midx + 3*diff/8;
                set(axHT, 'XLim', limx);
                set(axJoy, 'XLim', limx);
                set(axCam, 'XLim', limx);
                lDrawFlag = true;
            elseif evnt.Key == 'e',
                limx(1, 1) = midx - 2*diff/3;
                limx(1, 2) = midx + 2*diff/3;
                set(axHT, 'XLim', limx);
                set(axJoy, 'XLim', limx);
                set(axCam, 'XLim', limx);
                lDrawFlag = true;
            end
        else
%            fprintf(1, 'Char %s %d\n', evnt.Character, int32(evnt.Character));
            switch (int32(evnt.Character))
                case 29
                    limx = limx + diff/5;
                    set(axHT, 'XLim', limx);
                    set(axJoy, 'XLim', limx);
                    set(axCam, 'XLim', limx);
                    lDrawFlag = true;
                case 28
                    limx = limx - diff/5;
                    set(axHT, 'XLim', limx);
                    set(axJoy, 'XLim', limx);
                    set(axCam, 'XLim', limx);
                    lDrawFlag = true;
                case 106    % 'j'
                    flJoyVis = ~flJoyVis;
                    lVisFlag = true;
                case 104    % 'h'
                    flHeadVis = ~flHeadVis;
                    lVisFlag = true;
                case 116    % 't'
                    flTargVis = ~flTargVis;
                    lVisFlag = true;
                case 99     % 'c'
                    flCamVis = ~flCamVis;
                    lVisFlag = true;
            end
                    
        end


        if lVisFlag
            localUpdateVis();
        end
                
        if lDrawFlag || lVisFlag
            drawnow;
        end
    end





return;
end


