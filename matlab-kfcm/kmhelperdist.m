function DIST = kmhelperdist(MATRIX1, MATRIX2, diagonal, power)
%function DIST = kmhelperdist(MATRIX1, MATRIX2, diagonal, power)
%
% i.e. kernel matrix helper for distances
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
% 1. size(DIST) == [size(MATRIX1, 1) size(MATRIX2, 1)]
% 2. 
%       dist_{xy} = \sum_{k=1}^n abs(m1_{xk}-m2_{yk}).^power
%
% if diagonal == true:
%   only diagonal of above matrices are returned as a column vectors
%
% see kmhelperip
%
% Jacek Kawa, jkawa@polsl.pl, 2007.02.12, v.0.2

if (nargin < 4), power = 2; end % dla obliczeń odległości...

[r1 c1] = size(MATRIX1);
[r2 c2] = size(MATRIX2);

if (c1 ~= c2), error('kmhd:nof', 'Numbef of feature does not match'); end

if (diagonal)
    if (r1 ~= r2), 
        warning('kmhd:wrn', 'size does not much and output will be truncated'); 
    end

    %diagonal is always a column vector, so compute it directly
    rn = min(r1, r2);

    DIST = MATRIX1(1:rn, :) - MATRIX2(1:rn, :);
    DIST = DIST .^ power;
    DIST = sum(DIST, 2);

else %if (diagonal)
    % macierze mają cechy w kolumnach; poszczególne wiersze to
    % elementy, oraz
    %
    % dist_{xy} = \sum_{k=1}^n (m1_{xk}-m2_{yk}).^2
    %
    % czyli pierwszy wiersz nowej macierzy, to odległość pierwszego
    % elementu M1 od wszystkich elementów M2; ponieważ Matlab indeksuje
    % kolumnami, to być może szybciej będzie porównwywać też kolumnami
    % stąd za każdym razem obliczymy jedną kolumnę macierzy wynikowej

    DIST = nan([r1 r2]);
    c = 0;
    for W1 = MATRIX2' %czyli kolejne elementy M2
        c = c + 1;
        TEMP = MATRIX1 - repmat(W1', [r1 1]); %odejmij od wszystkich na raz
        %if (isodd(power)), 
            TEMP = abs(TEMP); 
        %end
        TEMP = TEMP .^ power;
        DIST(:, c) = sum(TEMP, 2);
    end

end

            
return;