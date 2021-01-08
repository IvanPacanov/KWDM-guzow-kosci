function varargout = showcl(IMAGE, layers, clusters, picturespercol)
%function varargout = showcl(IMAGE, layers, clusters, picturespercol)
%
% by Jacek Kawa, ; v 0.1b; 28.12.2005
%
% show clusters; IMAGE: case max dimension:
% when 4: show chosen layers and clusters (:,:,layer,clusters)
% when 3: show chosen layers (:,:,layers) duplicated min(length(clusters), 1)
%                                         times
% when 2: show IMAGE duplicated min(1, [length of layers] * [length of clusters])
%                                         times
%
% defualt for clusters is: 4d: size(IMAGE, 4)
%                          3d: 1
%                          2d: 1
% default for layers is: 4d: size(IMAGE, 3)
%                        3d: size(IMAGE, 3)
%                        2d: 1
% picturespercol ---> 
% number of images along x axis: x = picturespercol (if given) or, 
%                           x = ceil(sqrt(length(clusters)*length(layers)));
% number of images along y axis: y = ceil(number_of_pictures_to_print / x);
%
% when output is not assigned, Z is diplayed with imagesc() func.
% 
% empty places are set to NaN

dim = length(size(IMAGE));
if (dim > 4), error('to many dimensions'); end

if (~exist('clusters', 'var') || isempty(clusters))
    switch (dim)
        case {2, 3}, 
            clusters = 1;
        case 4,
            clusters = 1 : size(IMAGE, 4);
        otherwise,
            error('sorry winetou');
    end
end
if (~exist('layers', 'var') || isempty(layers))
    switch (dim)
        case 2,
            layers = 1;
        case {3, 4}, 
            layers = 1 : size(IMAGE, 3);
        otherwise,
            error('sorry winetou');
    end
        
end

if ((dim <= 3) && (max(clusters) ~= 1)), 
    clusters = ones(size(clusters)); 
    warning('clusters set to 1'); 
end
if ((dim == 2) && (max(layers) > 1))
    layers = ones(size(layers));
    warning('layers set to 1');
end


noc = length(clusters);
nol = length(layers); 

nop = noc * nol; 

if (exist('picturespercol', 'var'))
    nocl = picturespercol;
else
    nocl = ceil(sqrt(nop)); %ile kolumn
end
norw = ceil(nop / nocl); %ile wierszy

[r c rest] = size(IMAGE);

Z = nan(r * norw, c * nocl);

cl = 0;
for i = 1 : norw
    R1 = (i - 1) * r + 1;
    R2 = (i * r);
    for j = 1 : nocl
        cl = cl + 1; 
        if (cl > nop), break; end
        S1 = (j - 1) * c + 1;
        S2 = (j * c);
        
        l_ = ceil(cl / noc);
        c_ = rem(cl, noc);
        
        if (~c_), c_ = noc; end %specjalny przypadek
        
        Z(R1:R2, S1:S2) = IMAGE(:, :, layers(l_), clusters(c_));
        
    end
end
if (nargout < 1), imagesc(Z);colormap(gray(256)); else varargout(1) = {Z}; end
return