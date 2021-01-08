function idx = CurPoint2xy(CurrentPosition)
    %as it's a flat image, third column and second row are irrelevant
    idx = ceil(CurrentPosition([3 1])); 
    return
