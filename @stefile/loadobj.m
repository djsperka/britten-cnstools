function b = loadobj(a)
% loadobj for portfolio class
if isa(a,'stefile')
    b = a;
elseif isstruct(a)
   names = fieldnames(a);
   c = a;
   % hack
   % check for afile, efile, adata fields. 
   if isempty(strmatch('adata', names))
       c.adata=[];
   end
   if isempty(strmatch('efile', names))
       c.efile='';
   end
   if isempty(strmatch('afile', names))
       c.afile='';
   end
   b = class(c, 'stefile');
else
   b = stefile();
   warning('Cannot load this object as an stefile!');
end