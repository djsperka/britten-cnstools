

% Load and parse data files. 
% ecad is an ECAData object.
% When saving any derived MappedECAData objects, this object must also be
% saved!
ecad = bhx('/home/dan/Desktop/bhdata/jbh001f');
%ecad = bhx('d:/work/rextools/data/jbh001f');

% the helper method bcodes has all the codes used in the paradigm. 
% help bcodes will list them and give a short explanation of each.
% calling the function returns the channel numbers and the letters they
% will be mapped to.
[channels, letters] = bcodes();

% Now do the mapping. The MappedECAData object refers to the underlying
% ECAData object, but does not make a copy of it. You have to have the
% ECAData object in your workspace when you use the MappedECAData object.
mappedEcad = MappedECAData(channels, letters, ecad);

% Match patterns that pick out successful trials. In this expt, a
% successful trial starts with a 'T' and ends with a 'Y'. The regex below
% looks for a little more, though its not all necessary. The codes a-h are
% dropped into the efile whenever the trial starts, so 'Tabcdefgh' is
% present whenever 'T' is. The expression [^XTM]* matches any character
% that is NOT one of 'X', 'T' or 'M'. The 'X' is issued when fixation is
% broken, the 'M' is for missed frames (from render). The 'Y' indicates the
% end of a successful trial. 
% 
% When called without additional arguments, the match() method returns an
% array of MappedECAData objects, each containing a single match. Thus, the
% array returned contains a MappedECADAta object for each trial found.
trials = mappedEcad.match('(Tabcdefgh)[^XTM]*(Y)');

% Create an array containing trial information. The columns of this array
% are the same as the members of the struct returned by bhtrialsinfo() -
% see the help for bhtrialsinfo() for more info.

f = ECAMatchFormat;
f.addColumn(1, 2, 'value');
f.addColumn(1, 3, 'value');
f.addColumn(1, 4, 'value');
f.addColumn(1, 5, 'value');
f.addColumn(1, 6, 'value');
f.addColumn(1, 7, 'value');
f.addColumn(1, 8, 'value');
f.addColumn(1, 9, 'value');
trialsinfo = mappedEcad.match('(Tabcdefgh)[^XTM]*(Y)', 'Format', f);



% Now set up a format object. The use of a format object modifies what is
% returned by the match() method. When used, the format object specifies
% the layout of a row in the result. The result will be NxM array, where N
% is the number of matches (one match per row of the result), and M is the
% number of columns added to the format object. 
% Each call to addColumn specifies the token, position within the token,
% and the type of output ('time', 'value', 'char', or 'channel'). 
f = ECAMatchFormat;
f.addColumn(1, 1, 'time');
f.addColumn(2, 1, 'time');
f.addColumn(3, 1, 'time');
f.addColumn(4, 1, 'time');
f.addColumn(5, 1, 'time');

% Now call match using the first trial found above, trials(1). 
% The regex looks for the key frame events in a pursuit trial. The format
% object asks for the time value on each of these events. The result here
% will be a single row, with 5 columns. Columns 4 and 5 are the time values
% of interest - the start and end of the pursuit period.
pst1 = trials(1).match('(T).*(A).*(C).*(P).*(Y)', 'Format', f);

% Now get the analog data for 'eyeh' and 'eyev' that cover the pursuit
% period. The 'Limits' arg to analog() is a 2-element vector with the start
% and end times of the analog data desired. Leaving this out gets the
% entire analog record contained in mappedEcad.
pst1_eyeh = mappedEcad.analog('eyeh', 'Limits', pst1(4:5));
pst1_eyev = mappedEcad.analog('eyev', 'Limits', pst1(4:5));

clear f letters channels pst1
