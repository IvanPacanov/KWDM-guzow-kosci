function paramstruct = paramhelper(defaults, varargin)
%function paramstruct = paramhelper(defaults, varargin)
%
% decode parameters in varargin into paramstruct using 
% defaults as a template (and ignoring unknown fields)
%
%
% >> a = struct('field1', 1, 'field2', 2);
% >> b = paramhelper(a, 'field2', 42, 'field3', 3);
% >> disp(b)
%
%    field1: 1
%    field2: 42
%
% Jacek Kawa, jkawa@polsl.pl, 2007.02.23, v.0.1a fields -> fieldnames
%                                           0.1 initial


n = nargin - 1;
paramstruct = defaults;

for i = 1 : n
    if (iscell(varargin{i})), varargin(i) = {varargin(i)}; end
end

tempparam = struct(varargin{:}); %create temporary struct for the parameters
for i = char(fieldnames(paramstruct))'
    i = strtrim(i');
    if (isfield(tempparam, i))
        paramstruct.(i) = tempparam.(i);
    end
end
clear testparam

return
