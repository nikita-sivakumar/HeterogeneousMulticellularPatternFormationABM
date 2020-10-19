clear all; close all; clc;
delete('*.xlsx')
exps = dir('Data*');
for i = 1:length(exps)
    curDir = exps(i).name
    copyfile('CalcFeatures.m', curDir);
    copyfile('findregionboundary.m', curDir);
    
    cd(curDir)
    delete('*.xlsx')
    pars = split(curDir+"",'-');
    pars = pars(2:end);
    head_1 = ["ratio",pars',"Feature","Value"];
    feature_name = ["a-count"; "b-count";"c-color-count"; "c-express-count"; "d-color-count"; "d-express-count";"cell-count"; 
    "num_green_regions"; "num_lone_green_regions"; "green_avg_regionArea_fract"; "green_area_fract"; "green_avg_cent_dist";"green_region_width";"green_region_height"; "green_region_aspect_ratio";
    "num_red_regions"; "num_red_lone"; "red_avg_regionArea_fract"; "red_area_fract"; "red_avg_cent_dist";"red_region_width";"red_region_height"; "red_region_aspect_ratio";
    "num_blue_regions"; "num_blue_lone"; "blue_avg_regionArea_fract"; "blue_area_fract"; "blue_avg_cent_dist"
    "contiguous_area"];
    head_2 = ["file-path" "ratio" pars' feature_name'];
    
    conditions = dir('*A|*');
    all_features_ratios = [];
    all_features_ratios_horz = [];

    for k = 1:length(conditions)
        curFile = conditions(k).name;
        copyfile('CalcFeatures.m', curFile);
        copyfile('findregionboundary.m', curFile);
        
        cd(curFile)
        delete('*.xlsx')
        
        [features_vert, features_horz] = CalcFeatures(curFile,pars);
        all_features_ratios = [all_features_ratios; features_vert];
        all_features_ratios_horz = [all_features_ratios_horz; features_horz];
        disp(curFile + " done");
        cd ..
    end
    
    disp(curDir + "-- all conditions processed")
    all_features_ratios = [head_1;all_features_ratios];
    all_features_ratios_horz = [head_2; all_features_ratios_horz];
    cd ..
    filename1 = join(pars,'-') + "_graphing_features_ratios.xlsx";
    writematrix(all_features_ratios, filename1);
    filename2 = join(pars,'-') + "_clustering_features_ratios.xlsx";
    writematrix(all_features_ratios_horz, filename2);
end