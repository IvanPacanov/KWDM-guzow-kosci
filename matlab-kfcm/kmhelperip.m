function IP = kmhelperip(MATRIX1, MATRIX2, diagonal)
%function IP = kmhelperip(MATRIX1, MATRIX2, diagonal)
%
% i.e. kernel matrix helper for inner products
%
% INPUTS: 
% =======
% MATRIX1, MATRIX2: each row represents one elements described by features
%                   in following columns
%                   size(MATRIX2, 2) must match size(MATRIX1, 2)
% diagonal = false/true (request full matrix or only diagonal elements)
%
% OUTPUT:
% =======
% 1. size(IP) == [size(MATRIX1, 1) size(MATRIX2, 1)]
% 2. IP contains inner product of each two elements of M1, M2
%
%        i.e. ip_{xy} = \sum_{k=1}^n m1_{xk}*m2_{yk} 
%
% if diagonal == true:
%   only diagonal of above matrices are returned as a column vectors
%
% see kmhelperdist
%
% Jacek Kawa, jkawa@polsl.pl, 2007.02.12, v.0.2


[r1 c1] = size(MATRIX1);
[r2 c2] = size(MATRIX2);

if (c1 ~= c2), error('kmhi:nof', 'Numbef of feature does not match'); end

if (diagonal)
    if (r1 ~= r2), 
        warning('kmhi:wrn', 'size does not much and output will be truncated'); 
    end

    %diagonal is always a column vector, so compute it directly
    rn = min(r1, r2);

    IP = MATRIX1(1:rn, :) .* MATRIX2(1 : rn, :);
    IP = sum(IP, 2);

else %if (diagonal)
    %IP ma mieć tyle wierszy co M1 i tyle kolumn, co M2, oraz:
    %
    %       ip_{xy} = \sum_{k=1}^n m1_{xk}*m2_{yk} 
    %
    %zatem wystarczy transponować M2 i wykorzystać mnożenie
    IP = MATRIX1 * MATRIX2';
end
            
return;