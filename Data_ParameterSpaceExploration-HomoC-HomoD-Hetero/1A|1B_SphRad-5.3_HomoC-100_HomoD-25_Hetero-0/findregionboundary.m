function[img_boundary] = findregionboundary(img,img_region)
    img_boundary = zeros(length(img),length(img));
    for x=1:length(img_region)
        i = img_region(x,2);
        j = img_region(x,1);
        
        bottom = img(i,j+1);
        bottom_left = img(i-1,j+1);
        bottom_right = img(i+1,j+1);
        top = img(i,j-1);
        top_left = img(i-1,j-1);
        top_right = img(i+1,j-1);
        right = img(i+1,j);
        left = img(i-1,j);
        
        if top_left == 0 && bottom_right == 1
            img_boundary(i-1,j-1) = 1;
        end
        if top_left == 1 && bottom_right == 0
            img_boundary(i+1,j+1) = 1;
        end
        if top == 0 && bottom == 1
            img_boundary(i,j-1) = 1;
        end
        if top == 1 && bottom == 0
            img_boundary(i,j+1) = 1;
        end
        if top_right == 0 && bottom_left == 1
            img_boundary(i+1,j-1) = 1;
        end
        if top_right == 1 && bottom_left == 0
            img_boundary(i-1,j+1) = 1;
        end
        if right == 0 && left == 1
            img_boundary(i+1,j) = 1;
        end
        if right == 1 && left == 0
            img_boundary(i-1,j) = 1;
        end
    end
end