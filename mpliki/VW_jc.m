function VW_jc(src, evnt, zdarzenie, OBRAZEK)
global mask
% OBRAZEK za pierwszym razem musi być podany (przy SelectMouseDown),
% a przy pozostałych jest już czytany wewnątrz z TEMP.select.OBRAZEK
% więc jest NIEPOTRZEBNY

if (false)
    disp(src)
    disp(evnt)
end

persistent blokada_start_stop;
persistent bloada_mouse_motion;
persistent TEMP;

% obrazek do analizy


% callback na klikniecie
switch (zdarzenie)
    
    case 'SelectMouseDown',
        
        %x = get(gca, 'UserData');
        %if (~isstruct(x) || ~isfield(x, 'VWPicture'))
        %    return
        %end
        %OBRAZEK = x.VWPicture;
        REGION = true(size(OBRAZEK));
        
        % 1. blokada całego narzędzia, żeby nie udało się rozpocząć,
        %    drugi raz zanim ten callback się nie skończy
        seed = rand;
        if (blokada_start_stop == 0)
            blokada_start_stop = seed;
        end
        if (blokada_start_stop ~= seed)
            disp('nieudana próba wywołania MouseDown');
            return % nie udało się,
        end
        
        disp('początek: Mouse Down')
        
        % uchwyt do bieżącego obiektu axes i figure
        fih = gcf;
        axh = gca;
        
        
        
        
        
        
        TEMP.select = struct('point', [], ...
            'basecolor', [], ...
            'scale', [], ...
            'maxINTENSITY', [], ...
            'initshift', [], ...
            'BRUSHMAP', [], ... % aktualny malunek
            'callbacks', struct(), ...
            'color', [1 0 0], ... % czerwony
            'imhandle', [], ...
            ...
            'OBRAZEK', OBRAZEK, ...
            'REGION', REGION);
        
        % współrzędne i kolor punktu; współrzędne 2D!
        point = CurPoint2xy(get(axh, 'CurrentPoint'));
        point = point(1 : 2);
        TEMP.select.point = point;
        TEMP.select.basecolor = OBRAZEK(point(1), point(2));
        
        
        % dobierz skalę do minimalnego z wymiarów obrazka (ale nie mniej niż
        % 256 pikseli);
        sc = min([size(OBRAZEK, 1) size(OBRAZEK, 2)]);
        sc = max(sc, 256);
        TEMP.select.scale = 1/ sc;
        TEMP.select.maxINTENSITY = double(max(OBRAZEK(:)));
        % już w momencie kliknięcia chcemy wywołać efekt; w skali...
        TEMP.select.initshift = ceil([sc sc] / 32);
        
        % wyzeruj mapę namalowanych i domalowanych
        TEMP.select.BRUSHMAP = false(size(OBRAZEK)); % tu malujemy
        
        
        % zapamiętaj callbacki przed nadpisaniem
        WindowButtonDownFcn = get(fih, 'WindowButtonDownFcn');
        WindowButtonUpFcn = get(fih, 'WindowButtonUpFcn');
        WindowButtonMotionFcn = get(fih, 'WindowButtonMotion');
        
        TEMP.select.callbacks = struct('WindowButtonDownFcn', WindowButtonDownFcn, ...
            'WindowButtonUpFcn', WindowButtonUpFcn, ...
            'WindowButtonMotionFcn', WindowButtonMotionFcn);
        
        % podmień callbacki, tak, by obsłużyć ruch myszką i puszczenie
        % klawisza
        set(fih, 'WindowButtonUpFcn', 'VW_jc([], [], ''SelectMouseUp'', [])', ... % restore callbacks and "save" selection
            'WindowButtonMotionFcn', 'VW_jc([], [],''SelectMouseMotion''), []'); % track pointer and update on-line TEMP.brush.BRUSHMASK
        
        
        % ALBO stwórz nowy obrazek, żeby dostać uchwyt do niego
        % i potem przyspieszyć malowanie ALBO znajdź uchwyt już
        % istniejącego
        
        imh = findobj('Parent', axh);
        if (~isempty(imh))
            imh = imh(1);
            imhp = get(imh);
            if (~isfield(imhp, 'CData'))
                imh = [];
            end
        end
        if (isempty(imh))
            imh = imagesc(OBRAZEK);
            axis('ij', 'image');
            axh = get(imh, 'Parent');
        end
        
        TEMP.imhandle = imh;
        
        
        % od razu zasymuluj ruch myszką, żeby zaznaczyć to co wyszło
        % z initshift
        
        
        % ustaw wyjściowe dane (w UserData bieżącego axes)
        retval = get(axh, 'UserData');
        retval.VWMASK = false(size(OBRAZEK));
        set(axh, 'UserData', retval);
        
        return
        
        
    case 'SelectMouseUp', % save TEMP.brush.BRUSHMASK -> s.brushanderaser.* and restore callbacks
        
        disp('Koniec: SelectMouseUp');
        
        % handles
        axh = gca;
        fih = gcf;
        
        % restore callbacks
        WindowButtonUpFcn = TEMP.select.callbacks.WindowButtonUpFcn;
        WindowButtonDownFcn = TEMP.select.callbacks.WindowButtonDownFcn;
        WindowButtonMotionFcn = TEMP.select.callbacks.WindowButtonMotionFcn;
        
        set(fih, 'WindowButtonDownFcn', WindowButtonDownFcn);
        set(fih, 'WindowButtonUpFcn', WindowButtonUpFcn);
        set(fih, 'WindowButtonMotion', WindowButtonMotionFcn);
        
        
        % sprawdź, czy ktoś nie anulował wyboru, jeśli tak, to
        % wyczyść malunek, w UserData, jeśli nie, to wszystko
        % już jest na miejscu (UserData ustawione jest w MouseMotion)
        if (any(CurPoint2xy(get(axh, 'CurrentPoint')) < 0))
            MAP = false(size(TEMP.select.OBRAZEK));
            retval = get(axh, 'UserData');
            retval.VWMASK = MAP;
            set(axh, 'UserData', retval);
        end
        
        % odblokuj narzędzie
        blokada_start_stop = 0;
        
        % bye
        x = get(gca, 'UserData');
        try
            mask = x.VWMASK;
        catch
            mask = [];
        end
        return
        
    case 'SelectMouseMotion'
        
        seed = rand;
        if (bloada_mouse_motion == 0)
            bloada_mouse_motion = seed;
        end
        if (bloada_mouse_motion ~= seed)
            disp('anulowano mouse_motion z powodu blokady')
            return
        end
        
        OBRAZEK = TEMP.select.OBRAZEK;
        REGION = TEMP.select.REGION;
        
        % uchwyty
        axh = gca;
        %fih = gcf;
        
        % pobierz aktualną pozycję kursora
        point = CurPoint2xy(get(axh, 'CurrentPoint'));
        point = point(1 : 2); % tylko 2D!
        
        % przekształć dp postaci kolumnowej
        %cpoint = konw(point, size(OBRAZEK), 'xy2c');
        bpoint = konw(TEMP.select.point, size(OBRAZEK), 'xy2c');
        
        % oblicz odległość od początkowego punktu, ale osobno w pionie
        % i poziomie; uwzględnij initshift, żeby dla pierwszego
        % kliknięcia też wywołać efekt
        
        point;
        TEMP.select.point;
        TEMP.select.initshift;
        amount = (point - TEMP.select.point + TEMP.select.initshift)
        
        if (all(amount > 0)) % only right up is ok
            
            % przeskaluj odległość do rozmiarów obrazka (żeby małe
            % ruchy myszką na dużym obrazie nie były zbyt znaczące
            amount = amount .* TEMP.select.scale;
            
            % wyskaluj do max intensywności
            amount = amount .* TEMP.select.maxINTENSITY;
            
            % określ progi względem pierwszego klikniętego piksela
            t = TEMP.select.basecolor;
            t = [(t - amount(1)), (t + amount(2))];
            
            % stwórz mapę
            MAP = OBRAZEK >= t(1) & OBRAZEK <= t(2);
            MAP(~REGION) = false;
            MAP = bwlabel(MAP);
            
            % zostaw tylko te kliknięte w oryginale
            MAP = ismember(MAP, MAP(bpoint));
        else
            MAP = false(size(OBRAZEK));
        end
        
        
        % zapamiętaj mapę do dalszego przetwarzania
        TEMP.select.BRUSHMAP = MAP;
        
        % pokaż
        IM = wljoin(double(OBRAZEK), double(MAP), TEMP.select.color, 'e');
        set(TEMP.imhandle, 'CData', IM);
        
        % save for later
        retval = get(axh, 'UserData');
        retval.VWMASK = MAP;
        set(axh, 'UserData', retval);
        
        % odblokuj callback
        bloada_mouse_motion = 0;
        
        return
end
