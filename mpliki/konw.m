function [A]=konw(B,MDIM,toc)
%A=konw(B,MDIM,type);
%
% B    - coordinates (either column or xy)
%                     if column: B is a column or row (*) vector
%                     if xy    : B contains one set of coordinates
%                                  in a single row
%
% MDIM - dimensions of matrix (MDIM=size(MATRIX))
%
% toc (type of conversion) ['c2xy'|'xy2c']; (*)
%
% (*) type may be omitted, but autodetecion won't work correctly when
% B is a row vector with 'column' coordinates
%
%             -->C   o Z 
%             |
%             v R
% v
% | /| /|  column indicies go up-down, left-right, top-bottom
% |/ |/ v  
% 
% Jacek Kawa, jkawa@polsl.pl, v.1.0 2005.04.02
%                             v.1.0a 2007.02.19 (small cleanup)
%                             v.1.0b 2007.02.22 instead of producing
%                             doubles when c2xy, mimic the class of 
%                             input matrix
%         


if (~exist('toc','var'))
    if (size(B,2)==1)
        toc='c2xy';
    else
        toc='xy2c';
    end
end

if (isempty(B))
    A=[];
    return
end

if (strcmp(toc,'xy2c') && length(MDIM)~=size(B,2))
    error('width of MDIM and B differ')
    %return
end

switch (toc)
    case 'c2xy',
        %1. odwróć B, jeśli wektor wierszowy
        if (size(B,2)~=1)
            B=B';
        end
        if (size(B,2)~=1)   %jeśli dalej jest nie tak...
            error('wrong parameter >B< given')
            %return
        end
        
        L=length(MDIM);

        %sprawdzamy, czy indeksy nie wskazują poza tablicę
        VOL=prod(double(MDIM));
        if max(B)>VOL
            warning('konw:w', 'some index exceeds matrix dimension! continuing anyway')
        end
        
        A=zeros([size(B,1),L], class(B));
        
        for i=1:L
            if (i>1), B=floor((B-1)./MDIM(i-1))+1;end
            A(:,i)=rem(B,MDIM(i));
            T_= (A(:,i)==0); %bo mod(3,3)=0
            A(T_,i)=MDIM(i);
        end
        
    case 'xy2c',
        L=length(MDIM);
        
        for i=1:L
            if (i==1)
                A=B(:,1);
                VOL=1;
            else
                VOL=VOL*MDIM(i-1);
                A=A+VOL*(B(:,i)-1);
            end
        end

    otherwise,
        error('bad type given. Try: xy2c, c2xy');
end

