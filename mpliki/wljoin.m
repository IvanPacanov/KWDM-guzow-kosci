function [Y] = wljoinm(IMAGE, MASK, COEFF, options, filename)
%
%function [Y] = wljoinm(IMAGE, MASK, COEFF, options, filename);
%
% 2nd generation of wljoin() 
%
% options - one or more letter:
%  1. mask applying modes 
%    % applied with MASK = ceil(MASK - 0.05)
%     m -> multiply -> IMAGE(find(MASK)) = COEFF[RGB] .* IMAGE; (default)
%     a -> add -> IMAGE(find(MASK)) = IMAGE + COEFF[RGB] .* IMAGE; 
%     o -> substract -> IMAGE(find(MASK)) = IMAGE - COEFF .* IMAGE [prev. default
%          in wljoin.1 ]
%     s -> solid ->  IMAGE(find(MASK)) = COEFF;
%
%    can be mixed with above:
%     f -> full (whole mask is considered) [default]
%     b -> boundary -> only boundaries of the obejcts are taken
%
%    %applied _without_ MASK = ceil(...
%     d -> direct mask -> IMAGE(find(MASK)) = MASK .* COEFF;
%     e -> as 'd', but the mask is scaled to max(IMAGE(:))
%
%  2. viewing modes
%     n -> normal (masked image only, default)
%     c -> comparission (original image + masked image)
%
%  3. file types (if filename present)
%     p -> create png   (default)
%     i -> create dicom
%
%
% IMAGE - obraz (raczej 0 do 1), albo (potem!) zostanie znormowany
% MASK  - maska (raczej 0 do 1)
% COEFF - wsp
% filename - nazwa pliku, do którego zapisac efekt
%
% ex -> dla falek
%imagesc(wljoin([IM(:,size(IM, 2)/2+1:size(IM,2)) IM(:,1:size(IM,2)/2)], wlbd2(IM, F1{1, 2}, F1{1, 3}, 1, 'abs(HL+i*LH)', 'i', 'test.dicom'), [-1 0 0], 'i', 'test2.dicom'))
%
% Jacek Kawa, 2007.03.21, v.1.0a
% Jacek Kawa, 2007.04.16, v.1.0b

%       v.1.0.a -> add 'b' mode and rename old substract 'b' to 'o'
%                  as it was not used anywhere anyway;
%               -> correct some lint warnings
%       v.1.0.b -> add 'e' mode


if (~exist('options', 'var')), options = ''; end

masking = 'multiply'; %default
if (strfind(options, 'm')), masking = 'multiply'; end %oh well
if (strfind(options, 'a')), masking = 'add'; end 
if (strfind(options, 'o')), masking = 'substract'; end
if (strfind(options, 's')), masking = 'solid'; end
if (strfind(options, 'd')), masking = 'direct'; scale = false; end
if (strfind(options, 'e')), masking = 'direct'; scale = true; end

maskmode = 'full';
if (strfind(options, 'f')), maskmode = 'full'; end
if (strfind(options, 'b')), maskmode = 'boundaries'; end

viewing = 'normal';
if (strfind(options, 'n')), viewing = 'normal'; end
if (strfind(options, 'c')), viewing = 'compare'; end

ft = 'png';
if (strfind(options, 'p')), ft = 'png'; end
if (strfind(options, 'i')), ft = 'dicom'; end

IMD = zeros([1 3]);
[IMD(1) IMD(2) IMD(3)] = size(IMAGE);

if (IMD(3) ~= 1 && IMD(3) ~= 3)
    error(['wrong number of layers: ' num2str(IMD(3))])
end

%FIXME ? progowanie na bardzo niskim poziomie -> z wyjątkiem trybu direct
if (~strcmp(masking, 'direct'))
    %warning('buu');
    MASK = ceil(MASK - 0.05);
    MASK = logical(MASK);
    if (strcmp(maskmode, 'boundaries'))
        MASK = bwmorph(MASK, 'remove');
    end
else %dla trybu direct
    m = max(MASK(:));
    if (scale && m ~= 0) 
        MASK = MASK .* max(IMAGE(:)) / m;
    end
    if (strcmp(maskmode, 'boundaries'))
        M = bwmorph(~~MASK, 'remove');
        MASK(~M) = 0;
        clear M
    end
end

%musimy mieć orbazek 3d...
switch (viewing)
    
    case 'compare', 
        if (IMD(3) == 1)
            Y = repmat(IMAGE, [1 2 3]);
        else
            Y = repmat(IMAGE, [1 2 1]);
        end

        %trzeba podwoić też maskę...
        if (strcmp(masking, 'direct')) %wtedy zerami, żeby nie zakłócić
            MASK = [zeros(size(MASK)) MASK]; 
        else  %wtedy lepiej logiczne
            MASK = [false(size(MASK)) MASK];
        end
        
    case 'normal',
        if (IMD(3) == 3)
            Y = IMAGE;
        else
            Y = repmat(IMAGE, [1 1 3]);
        end
        
    otherwise,
        error('wrong viewing mode');
end
    
if (strcmp(masking, 'add')), masking = 'substract'; COEFF = -COEFF; end

for i = 1 : min(length(COEFF), 3)

    YY = Y(:, :, i);
    
    switch (masking)
        
        case 'multiply',  
            YY(MASK) = COEFF(i) .* YY(MASK);
            Y(:, :, i) = YY;
            
        case 'substract', % & add
            Y(:, :, i) = YY - COEFF(i) * (YY .* MASK);
            
        case 'solid', 
            YY(MASK) = COEFF(i);
            Y(:, :, i) = YY;
            
        case 'direct', 
            YY(~~MASK) = MASK(~~MASK) .* COEFF(i);
            Y(:, :, i) = YY;
            
        otherwise, 
            error('wrong masking mode')
    end
    
end

if (max(Y(:)) > 1 || min(Y(:)) < 0)
 %   warning('Image contains values out of RGB range 0 = 1; normalized')
    Y = Y - min(Y(:));
    Y = Y ./ max(Y(:));
end

if (exist('filename', 'var'))
    switch (ft)
        case 'dicom',
            dicomwrite(Y, filename);
        case 'png',
            imwrite(Y, filename, 'png');
        otherwise,
            error(['>filetype< type: ' filetype ' not supported']);
    end
end

return