function load_real_data_example()
% 加载真实测量数据的示例
% 此函数展示如何将真实的坐标测量机(CMM)或其他测量设备的数据
% 转换为适合圆柱度评定的格式

    fprintf('=== 真实测量数据加载示例 ===\n\n');
    
    % 方法1: 从CSV文件加载数据
    % 假设CSV文件格式为: X, Y, Z (每行一个测量点)
    csv_file = 'measurement_points.csv';
    if exist(csv_file, 'file')
        fprintf('从CSV文件加载数据: %s\n', csv_file);
        data = readmatrix(csv_file);
        x = data(:, 1);
        y = data(:, 2);
        z = data(:, 3);
        save('measurement_data.mat', 'x', 'y', 'z');
        fprintf('数据已转换并保存为measurement_data.mat\n');
    else
        fprintf('CSV文件不存在，创建示例文件...\n');
        create_sample_csv();
    end
    
    % 方法2: 从Excel文件加载数据
    excel_file = 'measurement_points.xlsx';
    if exist(excel_file, 'file')
        fprintf('从Excel文件加载数据: %s\n', excel_file);
        data = readmatrix(excel_file);
        x = data(:, 1);
        y = data(:, 2);
        z = data(:, 3);
        save('measurement_data.mat', 'x', 'y', 'z');
        fprintf('数据已转换并保存为measurement_data.mat\n');
    end
    
    % 方法3: 从文本文件加载数据
    txt_file = 'measurement_points.txt';
    if exist(txt_file, 'file')
        fprintf('从文本文件加载数据: %s\n', txt_file);
        data = load(txt_file);
        x = data(:, 1);
        y = data(:, 2);
        z = data(:, 3);
        save('measurement_data.mat', 'x', 'y', 'z');
        fprintf('数据已转换并保存为measurement_data.mat\n');
    end
    
    fprintf('\n数据格式说明:\n');
    fprintf('- 每个测量点需要包含X, Y, Z三个坐标值\n');
    fprintf('- 坐标单位建议使用毫米(mm)\n');
    fprintf('- 数据应该是在圆柱表面上的测量点\n');
    fprintf('- 建议在圆柱的不同高度和角度位置进行测量\n');
    
end

function create_sample_csv()
% 创建示例CSV文件
    
    % 生成示例数据
    [x, y, z] = generate_sample_data();
    
    % 保存为CSV文件
    data = [x, y, z];
    writematrix(data, 'measurement_points.csv');
    
    % 添加表头
    header = {'X_mm', 'Y_mm', 'Z_mm'};
    T = array2table(data, 'VariableNames', header);
    writetable(T, 'measurement_points_with_header.csv');
    
    fprintf('已创建示例CSV文件:\n');
    fprintf('- measurement_points.csv (无表头)\n');
    fprintf('- measurement_points_with_header.csv (有表头)\n');
end

function [x, y, z] = generate_sample_data()
% 生成示例测量数据（模拟真实测量情况）
    
    % 圆柱参数
    center = [0, 0];
    radius = 25;  % 25mm半径
    height = 100; % 100mm高度
    
    % 测量点分布
    n_levels = 10;  % 高度方向10个层次
    n_points_per_level = 12; % 每层12个点
    
    x = []; y = []; z = [];
    
    for i = 1:n_levels
        z_level = (i-1) * height / (n_levels-1);
        
        for j = 1:n_points_per_level
            angle = (j-1) * 2*pi / n_points_per_level;
            
            % 基础圆柱坐标
            x_base = center(1) + radius * cos(angle);
            y_base = center(2) + radius * sin(angle);
            
            % 添加形状误差
            % 椭圆度
            ellipse_error = 0.05 * cos(2*angle);
            % 锥度
            taper_error = 0.02 * z_level / height;
            % 波纹度
            waviness = 0.01 * sin(6*angle);
            
            r_actual = radius + ellipse_error + taper_error + waviness;
            
            x_actual = center(1) + r_actual * cos(angle);
            y_actual = center(2) + r_actual * sin(angle);
            z_actual = z_level;
            
            % 添加测量噪声
            x_actual = x_actual + 0.002 * randn();
            y_actual = y_actual + 0.002 * randn();
            z_actual = z_actual + 0.001 * randn();
            
            x = [x; x_actual];
            y = [y; y_actual];
            z = [z; z_actual];
        end
    end
end