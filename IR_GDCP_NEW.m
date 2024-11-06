clear all; close all;

% 定义拉伸函数
Stretch = @(x) (x-min(x(:))).*(1/(max(x(:))-min(x(:))));
win = 15;
t0 = 0.2;
r0 = t0 * 1.5;
sc = 1;

% 设置输入和输出文件夹
input_folder = uigetdir('', '选择包含图像的文件夹');
output_folder = uigetdir('', '选择保存处理后图像的文件夹');
if isequal(input_folder, 0) || isequal(output_folder, 0)
    disp('未选择文件夹');
    return;
end

% 获取文件夹中所有图片文件
file_list = dir(fullfile(input_folder, '*.bmp'));
file_list = [file_list; dir(fullfile(input_folder, '*.jpg'))];
file_list = [file_list; dir(fullfile(input_folder, '*.png'))];

for i = 1:length(file_list)
    % 读取图像
    file_name = file_list(i).name;
    full_file_path = fullfile(input_folder, file_name);
    im = im2double(imread(full_file_path));
    [~, width, ~] = size(im);
    
    % 调整图像尺寸
    if width ~= 480 
        sc = 480 / width;
    end
    I = im2double(imresize(im, sc));

    % 进行处理
    s = CC(I);
    [DepthMap, GradMap] = GetDepth(I, win);
    A = atmLight(I, DepthMap);

    T = calcTrans(I, A, win);
    maxT = max(T(:));
    minT = min(T(:));
    T_pro  = ((T - minT) / (maxT - minT)) * (maxT - t0) + t0;
    Jc = zeros(size(I));
    for ind = 1:3 
        Am = A(ind) / s(ind);
        Jc(:,:,ind) = Am + (I(:,:,ind) - Am) ./ max(T_pro, r0);
    end
    Jc(Jc < 0) = 0;
    Jc(Jc > 1) = 1;

    % 显示处理后的图像
    % figure, imshow([I Jc]);

    % 保存处理后的图像
    [~, name, ext] = fileparts(file_name);
    output_file_name = fullfile(output_folder, strcat(name, '_processed', ext));
    imwrite(Jc, output_file_name);
end