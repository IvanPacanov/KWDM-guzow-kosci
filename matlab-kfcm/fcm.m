function varargout = fcm(varargin)
% [U V OBJ] = fcm(IMAGE, [paramname paramvalue])
%
% outputs:
% U -> x * y * (U)      (memberships of pixels)
% V -> prototypes (as in parameters below)
% OBJ -> object function values for each iteration
%
% parameters:
% c      -> number of clusters (default 3)
% m      -> level of fuzzines  (default 2)
% e      -> stop               (default 0.001)
% v      -> verbose level=[0|1==true|2] (default 0)
% mod    -> modification
%
%            0 full standard 'fcm'
%            1 reduced  'fcmr'
%            2 fast standard 'ffcm'
%
% maxiter -> maximum number of iterations (default 1000)
% V      -> prototypes, matrix (1 x .c x number_of_features)
%                 i.e. earch prototype written into 3d
%
% e.g. IMAGEC = fcm(IMAGE, 'c', 2, 'v', 1)
%
% (c) Jacek Kawa, jkawa@polsl.pl, 13.02.2007, v.0.2

% HISTORY:
%  6.01.2007 v.0.1 initial version with new api
% 13.02.2007 v.0.2 OBJ fix, string 'mod' detection

%---parametery------------------------------------------------------------%

if (nargin < 1); error('fcm:ind', 'no image provided'); end
IMAGE = varargin{1};
varargin(1) = [];

param   =  struct('c', 3, ...           %number of clusters
                  'm', 2, ...           %fuzzyfication level
                  'e', 0.001, ...       %epsilon
                  'v', false, ...       %verbose
                  'mod', 1, ...         %modyfication; 0 = fast fcm; 1 = unique
                  'maxiter', 1000, ...  %max # iterations
                  'V', []);


% MANAGE PARAMETERS
% preserve cell arrays when passing to struct()           
for i = 1:nargin - 1,
    if (iscell(varargin{i})), varargin(i) = {varargin(i)}; end
end
tempparam = struct(varargin{:}); %create temporary struct to hold the parameters
for i = char(fields(param))'
    i = strtrim(i');
    if (isfield(tempparam, i))
        param.(i) = tempparam.(i);
    end
end

c = param.c;
m = param.m;
e = param.e;
v = param.v;
mod = decodemod(param.mod);
maxiter = param.maxiter;
V = param.V; if (isempty(V)), V = prototypes(IMAGE, c); end

clear tempparam param

if (nargin < 1), error('No IMAGE specified'); end

if (v)
    disp([' stopien rozmycia: ' num2str(m)] );
    disp([' liczba klastrow: '  num2str(c)] );
    disp([' warunek stopu: '    num2str(e) ] );
    disp([' modyfikacja: '      num2str(mod)]);
    disp(' prototypy');
    disp(V);
end

[row col nof] = size(IMAGE);  %liczba wierszy, kolumn, cech

%reshape, tak, żeby kolejne elementy w kolejnych wierszach, a cechy w
%kolumnach; 
XL = lrshape(IMAGE);           
V = lrshape(V);

%modyfikacje; 1-> uzyj tylko unikatowych; 2-> emuluj zwyklego FCMa
if (mod), 
    [X I J] = unique(XL, 'rows');  %#ok %clear I;
else
    X = XL;
end
nox = size(X, 1); %liczba elementow

if (mod ==2), 
    %N = hist(XL, X)'; %czyli N zawiera liczbe wystapien poszczegolnych elementow
    N = hist(J, unique(J))'; 
else
    N = ones(nox, 1);
end
clear XL; 


if (v), disp([' ' num2str(nox) ' elementow do grupowania']); end

%inicjalizacja macierzy U (elementy w wierszach, kolejne grupy w kolumnach)

U = zeros([nox c]);
Uold = U; 
df = 2 * e;
OBJ = zeros([1 maxiter]);

itr = 0;

while (true)
    itr = itr + 1;
    if (v && ~rem(itr, 5)), disp([' == iteracja: ' num2str(itr) ' == ']); end
    
    %1. odleglość elementów od prototypów
    D = compnorm(X, V);
    
    OBJ(itr) = sum(sum(D .* (Uold .^ m), 2) .* N);
    
    %2. U
    if (v && ~rem(itr, 5)), disp('    o macierz U'); end
    %2a. pokrywajace sie z prototypami
    
    idx = min(D, [], 2);
    idx = ~~idx; %indeksy tych, w ktorych odleglosc od ktoregos > 0
    zidx = find(~idx);
    U(zidx, :) = ~D(zidx, :); %w ten sposób mamy 1 tam, gdzie któraś odległość od prototypu == 0
    U(zidx, :) = U(zidx, :) ./ (sum(U(zidx, :), 2) * ones(1, c)); %jeśli prototypy się pokrywają
    
    %2b. reszta
    idx = find(idx);
    
    R = D(idx, :) .^ (-1 / (m - 1));
    M = sum(R, 2); %mianownik wspólny dla wszystkich grup
    
    U(idx, :) = R; %licznik l = || x - v_i|| ^(-1 / (m-1))
    for i = 1 : c 
        U(idx, i) = U(idx, i) ./ M; %gotowe U
    end

    clear idx zidex R M
    
    %3. V
    if (v && ~rem(itr, 5)), disp('    o macierz V'); end
    
    cl = 0;
    
    %OBJ(itr) = sum(sum(U .^ m));% HERE
    
    for Um = U .^ m %czyli kolumnami, czyli kolejnymi grupami
        Um = Um .* N; %MODYFIKACJA
        cl = cl + 1;
        TEMP = X .* (Um *ones(1, nof));
        TEMP = sum(TEMP, 1); %czyli sum(u_in^m * \vect{xn})
        V(cl, :) = TEMP / sum(Um); 
    end
    
    
    %4. sprawdzenie warunku; jesli będzie ok, to prototypy też
    %   już są obliczone takie, jak powinny być
    %df = max(max(U - Uold));
    if (itr > 1), df = abs(OBJ(itr) - OBJ(itr - 1)); end
    if (df < e)
        if (v), disp(['    koniec: ' num2str(itr) ' iteracji; roznica: ' num2str(df)]); end
        break
    else
        Uold = U;
%       OBJold = OBJ;
    end
    
    if (itr >= maxiter), 
        warning('fcm:maxiter', ['Przerwane po ' num2str(maxiter) ' iteracjach']);
        break;
    end %if itr
end


% jesli modyfikacja, to przywroc wszystkie elementy
if (mod)
    U = U(J, :);
end

U = reshape(U, [row col c]);
V = reshape(V, [1 c nof]);
OBJ(itr + 1 : maxiter) = [];

varargout(1 : nargout) = {[]};
varargout(1) = {U};    %zawsze
if (nargout > 1), varargout(2) = {V}; end
if (nargout > 2), varargout(3) = {OBJ}; end


return 



%======================== prototypes ==============================%
function D = compnorm(X, V)
    noc = size(V, 1);       %liczba prototypów == c
    nox = size(X, 1);       %liczba elementow
    
    for i = 1 : noc
        TEMP = X;
        TEMP = TEMP - ones(nox, 1) * V(i, :);  % czyli x_j - v_j
        TEMP = TEMP .^ 2;                      % (x_j - v_j) ^2;
        D(:, i) = sum(TEMP, 2);                % ||x - v||
    end
    return


%======================== prototypes ==============================%
function V = prototypes(IMAGE, cl)
%copmputes equaly distributed prototypes; cl : number of clusters

    [r c d ] = size(IMAGE); %#ok
    MINS = min(IMAGE);
    MAXS = max(IMAGE);
    
    if (min([r c]) ~= 1), MINS = min(MINS); MAXS = max(MAXS); end
    
    
    if (cl == 1), V = (MAXS - MINS) /2; return; end                        %---------> ogolnie i tak bez sensu
    if (cl == 2), V = [MAXS MINS]; return; end                             %--------->
    
    STEP = (MAXS - MINS) / (cl - 1);
    
    V = MINS;
    for i = 1 : (cl - 1)
        V = [V (MINS + i * STEP)];
    end
        
    return                                                                 %--------->
    
    
%======================== lrshape ==============================%
    
function RIMAGE = lrshape(IMAGE)
    [r c d] = size(IMAGE);
    RIMAGE = reshape(IMAGE, [r * c d]);
    return
    
%======================== decodemod ==============================%    
function mod = decodemod(modfield)
%           -1 full weighted 'fcmw' (if W not provided == 0)
%            0 full standard 'fcm'
%            1 reduced  'fcmr'
%            2 fast standard 'ffcm'
%            3 fast weighted 'ffcmw' (if W not provieded == 2)
%
        switch class(modfield)
            case 'char'
                switch (modfield)
                    case 'fcmw', mod = -1;
                    case 'fcm', mod = 0;
                    case 'fcmr',mod = 1;
                    case 'ffcm', mod = 2;
                    case 'ffcmw', mod = 3;
                    otherwise
                        error(['unknown mode: ' modfield]);
                end
            otherwise,
                mod = modfield;
        end    