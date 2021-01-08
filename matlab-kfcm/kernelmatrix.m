function K = kernelmatrix(MATRIX1, MATRIX2, kparam, dia)
%
%function K = kernelmatrix(MATRIX1, MATRIX2, kparam, dia)
%
% coputes inner product of every element of matrix1 and matrix2 in H space 
% due to kernel computation in L space
%
% kparam={ktype,{parameters}}
%  while ktype='{_linear_|rbf|poly|tanh} {TODO: |dilrecht}'
%
% {parameters} is a cell matrix containing parameters for a specific 
% kernel computations. I.e.:
% linear   : {} [note: linear=={'poly',{0 1}}]
% rbf      : {deviation,a,b} exp((-.5/deviation^2)*(|X-Y|^a)^b) [ex:offset]
% poly     : {offset, power}
% tanh     : {kapa,delta} [tanh(kX*Y+delta)
% dlirecht : {TODO}
% 
% matrix1, matrix2 should be x by y, where every row represents
% feature vector of y distinct features, eg.:
% 
% x_1 x_2 x_3
% y_1 y_2 y_3
% ..........
%
% obviously size(matrix1,2)==size(matrix2,2), while size(matrix_i,1) may
% vary; 
%
% dia= [_0_|1]; when dia, only diagonal elements as a signle column vector
%               are returned. Else: resulting kernelmatrix C is of size: 
%               size(matrix1,1) x size(matrix2,1)
%
% EXAMPLE: C=kernelmatrix([0 1 ; 1 0],[0 1; 1 1; 1 2], {'poly' {1 2}});
%
% Jacek Kawa, jkawa@polsl.pl, v. 0.95, 2007.02.23

% v.0.95 rewrite tu use kernelmatrixhelpers* (10x speedup) and clean up a lot
% v.0.9a (lint corrections, fix tanh kernel (+delta, not -delta), 
%         remove quasi sinx kernel, add 'doublerbf')
% v.0.9 2005.11.27 <- initial version

if (nargin < 2), error('km2:inp', 'Insufficient number of parameters'); end
if (nargin < 4), dia=0; else dia = readdia(dia); end

%default type and parameters
ktype = 'linear';
parameters = {};
if (~exist('kparam','var'))
    warning('km:tl', 'assumed ktype linear');
else 
    if (length(kparam)>=1), ktype = kparam{1}; end
    if (length(kparam)>=2), parameters  = kparam{2}; end
end

%check sizes
if (size(MATRIX1,2) ~= size(MATRIX2,2))
    error('km2:inof', 'size (col. number) does not match');
end

%IF ktype is a handle, exec another function
if (isa(ktype, 'function_handle'))
    K = ktype(MATRIX1, MATRIX2, dia, parameters{:});
    return %------------------------------------------------------>
end

%this function has been moved into separate file
dparam = @kmhelperdparam;

%decode parameters
switch (ktype)
    case 'linear',
        ktype ='poly';
        offset = 0;
        power = 1;
    case 'rbf',
        deviation = 1;
        a = 2; 
        b = 1;
        offset = 0;
        [deviation a b offset] = dparam(parameters, deviation, a, b, offset);
    case 'drbf',
        dev1 = 1;
        dev2 = 1;
        [dev1 dev2] = dparam(parameters, dev1, dev2);
    case {'doublerbf', 'murbf'},
        dev1 = 1;
        dev2 = 1;
        a = 2;
        [dev1 dev2 a] = dparam(parameters, dev1, dev2, a);
    case 'poly',
        offset = 0;
        power = 2;
        [offset power] = dparam(parameters, offset, power);
    case 'doublepoly'
        offset1 = 0;
        offset2 = 0;
        power1 = 1;
        power2 = 1;
        [offset1 offset2 power1 power2] = dparam(parameters, offset1, ...
                                                 offset2, power1, power2);
    case 'vovk',
         p = 0;
         p = dparam(parameters, p);
    case 'vovki',   %just an alias
        ktype = 'vovk';
        p = 0;
    case 'tanh',
        kappa = 1;
        delta = 1;
        [kappa delta] = dparam(parameters, kappa, delta);
    case 'rbfmupoly',
        a = 2;
        dev = 1;
        offset = 0;
        power = 2;
        [dev offset power] = dparam(parameters,dev, offset, power);
    otherwise,
        error('undefined kernel type');

end

%linear = <X,Y>
%poly   = (<X,Y>+offset)^power
%rbf    = exp(-0.5|X,Y|^a/deviation)^b

switch (ktype)
    case 'poly', %linear is already defined as a special case of poly!
        K = kmhelperip(MATRIX1, MATRIX2, dia);
        K = K + offset;
        K = K .^ power;
    case 'doublepoly'
        K = kmhelperip(MATRIX1, MATRIX2, dia);
        D = K + offset2;
        D = D .^ power2;
        K = K + offset1;
        K = K .^ power1;
        K = K + D;
        clear D
    case 'vovk',
        K = kmhelperip(MATRIX1, MATRIX2, dia);
        K = 1 - K;
        if (p == 0) %opt.
            K = 1 ./ K;
        else
            D = K;  %opt.
            K = 1 + K .^ p;
            K = K ./ D;
            clear D;
        end
    case'tanh',
        K = kmhelperip(MATRIX1, MATRIX2, dia);
        K = kappa * K;
        K = tanh(K + delta);
    case 'rbf',
        K = kmhelperdist(MATRIX1, MATRIX2, dia, a);
        K = (K - offset) .^ b;
        K = -K / (2 * deviation^2);
        K = exp(K);
    case 'drbf',
        %0.2 0.2 wydaje się bezpieczne
        K = kmhelperdist(MATRIX1, MATRIX2, dia, 2);
        K = -K / (2 * dev1^2);
        K = exp(K);
        K = 2 - K; %odległość
        K = -K / (2 * dev2^2);
        K = exp(K);
%        if (~dia), figure; imagesc(K); drawnow; end
    case 'doublerbf',
        K = kmhelperdist(MATRIX1, MATRIX2, dia, a);
        C1 = K;
        C1 = -C1 / (2 * dev1^2);
        C1 = exp(C1);
        K = -K / (2 * dev2^2);
        K = exp(K);
        K = K + C1;
        clear C1
    case 'murbf'
        K = kmhelperdist(MATRIX1, MATRIX2, dia, a);
        C1 = K;
        C1 = -C1 / (2 * dev1 ^ 2);
        C1 = exp(C1);
        K = -K / (2 * dev2 ^ 2);
        K = exp(K);
        K = K .* C1;
        clear C1
    case 'rbfmupoly'
        K = kmhelperdist(MATRIX1, MATRIX2, dia, a);
        K = -K / (2 * dev^2);
        K = exp(K);
        K1 = kmhelperip(MATRIX1, MATRIX2, dia);
        K1 = (K1 + offset).^power;
        K = K .* K1;
    otherwise,
        error('impossible error condition has just occured');
end


return;

%override default parameter values by supplied in the cell
%parameter array
% function varargout = dparam(parameters, varargin)
%     np = length(parameters);
%     P = varargin;
%     [P{1 : np}] = deal(parameters{:});
%     varargout(1 : nargout) = {[]};
%     for i = 1 : nargout
%         varargout(i) = {P{i}};
%     end
%     return

%decode diagonal parameter
function dia = readdia(dia)
    switch (dia)
        case {'dia', 'diag'},
            dia=1;
        case 'nodia',
            dia=0;
        otherwise,
            dia = ~~dia;
    end

    