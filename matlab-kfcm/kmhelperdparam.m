function varargout = kmhelperdparam(parameters, varargin)
%function varargout = kmhelperdparam(parameters, varargin)
%
% override default parameter values (as in varargin) by supplied in the 
% cell parameter array; leave all the rest untouched

    np = length(parameters);
    P = varargin;
    [P{1 : np}] = deal(parameters{:});
    varargout(1 : nargout) = {[]};
    for i = 1 : nargout
        varargout(i) = {P{i}};
    end
    return

