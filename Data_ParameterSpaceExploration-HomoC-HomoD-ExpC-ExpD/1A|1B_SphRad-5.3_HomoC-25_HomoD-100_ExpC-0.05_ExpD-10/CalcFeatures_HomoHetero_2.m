function[features] = CalcFeatures_HomoHetero_2(curDir)
files = dir('*.txt');
features = [];
ratios = [];
radii = [];
homotypic_probs_c = [];
homotypic_probs_d = [];
exp_cs = [];
exp_ds = [];
feature_name = ["a-count"; "b-count";"c-color-count"; "c-express-count"; "d-color-count"; "d-express-count";"cell-count"; 
    "num_green_regions"; "num_lone_green_regions"; "green_avg_regionArea_fract"; "green_area_fract"; "green_avg_cent_dist";"green_region_width";"green_region_height"; "green_region_aspect_ratio";"green_region_circularity";
    "num_red_regions"; "num_red_lone"; "red_avg_regionArea_fract"; "red_area_fract"; "red_avg_cent_dist";"red_region_width";"red_region_height"; "red_region_aspect_ratio";"red_region_circularity";
    "green_red_centroid_dist";"green_region_avg_red_contig"; "red_region_avg_green_contig"; "green_red_contig_dif";
    "num_blue_regions"; "num_blue_lone"; "blue_avg_regionArea_fract"; "blue_area_fract"; "blue_avg_cent_dist"
    "contiguous_area"];
feature_names=[];
filenames = [];

ratio = (curDir(1:5) + "");
index1 = strfind(curDir,'-') + 1;
index2 = strfind(curDir,'_') - 1;

radius = (curDir(index1(1):index2(2)) + "");
homo_c = (curDir(index1(2):index2(3))+ "");
homo_d = (curDir(index1(3):index2(4))+ "");
exp_c = (curDir(index1(4):index2(5)) + "");
exp_d = (curDir(index1(5):end) + "");

for k = 1:length(files)
    curFile = files(k).name;
    A = importdata(curFile,'\n');
    offset = 0;
    for j = 1:length(A)/65
        col_features = [];
        for i = 1+offset:7+offset
            line = split(A{i} + "", ' ');
            col_features = [col_features; line(3)];
        end

        img_blue = zeros(17,17);
        img_green = zeros(17,17);
        img_red = zeros(17,17);
        spheroid_area = 56;
        thresh = 2;

        for i = (8+offset):(63+offset)
            line = split(A{i} + "", ' ');
            color = line(2);
            x = str2num(line(3))+8;
            y = str2num(line(4))+8;
            if color == "105"
                img_blue(x,y) = 1;
            end
            if color == "55"
                img_green(x,y) = 1;
            end
            if color == "15"
                img_red(x,y) = 1;
            end
        end

    %   ----------------------Green Region Data---------------------------
        %counts number of green regions
        CC_green = bwconncomp(img_green,4);
        table_green = regionprops("table",CC_green,"Centroid","Area","PixelList","BoundingBox","Circularity");
        num_green_regions = sum(table_green.Area > thresh);
        num_green_lone = sum(table_green.Area <= thresh);
        col_features = [col_features; num_green_regions; num_green_lone];

        if num_green_regions > 0
            %average green region area
            green_regions = table_green(table_green.Area>thresh,:);
            green_avg_regionArea_fract = mean(green_regions.Area / spheroid_area);
            green_area_fract = sum(table_green.Area) / spheroid_area;

            col_features = [col_features; green_avg_regionArea_fract; green_area_fract];

            %average green region distance to center
            green_regions_dif = (green_regions.Centroid - 9);
            green_regions_dist = sqrt(green_regions_dif(:,1).^2 + green_regions_dif(:,2).^2);
            green_avg_cent_dist = mean(green_regions_dist);
            col_features = [col_features;green_avg_cent_dist];
            
            %average width and height of freen regions
            green_region_width = mean(green_regions.BoundingBox(:,3));
            green_region_height = mean(green_regions.BoundingBox(:,4));
            green_region_aspect_ratio = green_region_width / green_region_height;
            col_features = [col_features; green_region_width; green_region_height; green_region_aspect_ratio];

            green_region_circularity = mean(green_regions.Circularity);
            col_features = [col_features; green_region_circularity];
        else
            col_features = [col_features; 0; 0; 0;0;0;0;0];
        end

    %   ----------------------Red Region Data---------------------------
        %counts number of red regions
        CC_red = bwconncomp(img_red,4);
        table_red = regionprops("table",CC_red,"Centroid","Area","PixelList","BoundingBox","Circularity");
        num_red_regions = sum(table_red.Area > thresh);
        num_red_lone = sum(table_red.Area <= thresh);
        col_features = [col_features; num_red_regions; num_red_lone];

        if num_red_regions > 0
            %average red region area
            red_regions = table_red(table_red.Area>2,:);
            red_avg_regionArea_fract = mean(red_regions.Area / spheroid_area);
            red_area_fract = sum(table_red.Area) / spheroid_area;
            col_features = [col_features;red_avg_regionArea_fract; red_area_fract];

            %average red region distance to center
            red_regions_dif = (red_regions.Centroid - 9);
            red_regions_dist = sqrt(red_regions_dif(:,1).^2 + red_regions_dif(:,2).^2);
            red_avg_cent_dist = mean(red_regions_dist);

            %radius of red core
    %         points = table_red.BoundingBox - length(img)/2;
    %         red_rad = mean((sqrt(points(:,1).^2 + points(:,2).^2)+sqrt(points(3).^2 + points(4).^2))/2);

            col_features = [col_features; red_avg_cent_dist];
            red_region_width = mean(red_regions.BoundingBox(:,3));
            red_region_height = mean(red_regions.BoundingBox(:,4));
            red_region_aspect_ratio = red_region_width / red_region_height;
            col_features = [col_features; red_region_width; red_region_height; red_region_aspect_ratio];
            
            red_region_circularity = mean(red_regions.Circularity);
            col_features = [col_features; red_region_circularity];
        else
            col_features = [col_features; 0; 0;0;0;0;0;0];    
        end
        
        if num_green_regions > 0 && num_red_regions > 0
            green_region_centroid = mean(green_regions.Centroid);
            red_region_centroid = mean(red_regions.Centroid);
            green_red_centroid_dist = sqrt(sum((green_region_centroid-red_region_centroid).^2));
            col_features = [col_features; green_red_centroid_dist]; 
           
            green_contig = [];
            red_contig = [];
            for i=1:height(green_regions)
                green_region_i = green_regions.PixelList(i);
                green_region_i = green_region_i{1,1};
                [green_region_i_boundary,green_diam] = findregionboundary(img_green,green_region_i);
                red_border = sum(green_region_i_boundary & img_red,"All");
                ap = red_border / green_diam;
                green_contig = [green_contig ap];
            end
            green_region_avg_red_contig = mean(green_contig);

            for i=1:height(red_regions)
                red_region_i = red_regions.PixelList(i);
                red_region_i = red_region_i{1,1};
                [red_region_i_boundary,red_diam] = findregionboundary(img_red,red_region_i);
                green_border = sum(red_region_i_boundary & img_green,"All");
                ap = green_border / red_diam;
                red_contig = [red_contig ap];
            end
            red_region_avg_green_contig = mean(red_contig);
            green_red_contig_dif = abs(green_region_avg_red_contig - red_region_avg_green_contig);
            col_features = [col_features; green_region_avg_red_contig; red_region_avg_green_contig; green_red_contig_dif];
        else
            col_features = [col_features; 0; 0;0;0]; 
        end

        %   ----------------------Blue Region Data---------------------------
        %counts number of red regions
        CC_blue = bwconncomp(img_blue,4);
        table_blue = regionprops("table",CC_blue,'Area','Centroid');
        num_blue_regions = sum(table_blue.Area > thresh);
        num_blue_lone = sum(table_blue.Area <= thresh);
        col_features = [col_features; num_blue_regions; num_blue_lone];

        if num_blue_regions > 0
            %average red region area
            blue_regions = table_blue(table_blue.Area>2,:);
            blue_avg_regionArea_fract = mean(blue_regions.Area / spheroid_area);
            blue_area_fract = sum(table_blue.Area) / spheroid_area;
            col_features = [col_features; blue_avg_regionArea_fract; blue_area_fract];

            %average red region distance to center
            blue_regions_dif = (blue_regions.Centroid - 9);
            blue_regions_dist = sqrt(blue_regions_dif(:,1).^2 + blue_regions_dif(:,2).^2);
            blue_avg_cent_dist = mean(blue_regions_dist);

            col_features = [col_features; blue_avg_cent_dist];
        else
            col_features = [col_features; 0; 0; 0];        
        end

        if num_green_regions > 2 & num_red_regions > 2
            col_features = [col_features; 0];
        else
            if max(table_green.Area) > 30
                core = table_green(table_green.Area == max(table_green.Area),:);
                img_core = core.PixelList;
                img_core = img_core{1,1};
                [core_region_boundary,core_diam] = findregionboundary(img_green,img_core);
                red_border = sum(core_region_boundary & img_red,"All");
                contiguous_area = red_border / core_diam;
                col_features = [col_features; contiguous_area];
            elseif max(table_red.Area) > 30
                core = table_red(table_red.Area == max(table_red.Area),:);
                img_core = core.PixelList;
                img_core = img_core{1,1};
                [core_region_boundary,core_diam] = findregionboundary(img_red,img_core);
                green_border = sum(core_region_boundary & img_green,"All");
                contiguous_area = green_border / core_diam;
                col_features = [col_features; contiguous_area];
            else
                col_features = [col_features; 0];
            end 
        end
        
        offset = offset + 65;
        features = vertcat(features, col_features);
        ratios = [ratios; repmat(ratio, length(feature_name), 1)];
        radii = [radii; repmat(radius, length(feature_name), 1)];
        homotypic_probs_c = [homotypic_probs_c; repmat(homo_c, length(feature_name),1)];
        homotypic_probs_d = [homotypic_probs_d; repmat(homo_d, length(feature_name),1)];
        exp_cs = [exp_cs; repmat(exp_c, length(feature_name),1)];
        exp_ds = [exp_ds; repmat(exp_d, length(feature_name),1)];
        feature_names=[feature_names;feature_name];
    end
end
    features = [ratios, radii, homotypic_probs_c, homotypic_probs_d, exp_cs,exp_ds,feature_names, features];
    head = ["Ratio","Radius","Homotypic_Prob_C","Homotypic_Prob_D","Exp_C","Exp_D","Feature","Value"];
    writematrix([head;features], "features_" + curDir + ".xlsx");
end