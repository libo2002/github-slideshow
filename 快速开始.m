%% 圆柱度误差评定算法 - 快速开始指南
% 
% 此脚本提供了程序的快速演示和测试
% 适用于MATLAB 2024a

%% 清理工作空间
clc; clear; close all;

fprintf('=== 圆柱度误差评定算法 - 快速开始 ===\n\n');

%% 第一步：算法验证测试
fprintf('第一步：运行算法验证测试...\n');
try
    test_cylindricity_algorithm();
    fprintf('✅ 算法验证测试完成\n\n');
catch ME
    fprintf('❌ 测试失败: %s\n\n', ME.message);
end

%% 第二步：生成示例数据
fprintf('第二步：生成示例测量数据...\n');
try
    load_real_data_example();
    fprintf('✅ 示例数据生成完成\n\n');
catch ME
    fprintf('❌ 数据生成失败: %s\n\n', ME.message);
end

%% 第三步：运行主程序演示
fprintf('第三步：运行圆柱度评定演示...\n');
fprintf('程序将自动使用模拟数据进行演示...\n\n');

try
    % 自动使用模拟数据运行演示
    demo_cylindricity_evaluation();
    fprintf('✅ 主程序演示完成\n\n');
catch ME
    fprintf('❌ 主程序运行失败: %s\n\n', ME.message);
end

%% 第四步：使用说明
fprintf('=== 使用说明 ===\n');
fprintf('1. 运行主程序: cylindricity_evaluation()\n');
fprintf('2. 测试算法: test_cylindricity_algorithm()\n');
fprintf('3. 生成示例数据: load_real_data_example()\n');
fprintf('4. 查看详细说明: 请阅读 README_圆柱度评定.md\n\n');

fprintf('=== 文件说明 ===\n');
fprintf('主要程序文件:\n');
fprintf('  - cylindricity_evaluation.m (主程序)\n');
fprintf('  - load_real_data_example.m (数据加载示例)\n');
fprintf('  - test_cylindricity_algorithm.m (算法测试)\n');
fprintf('  - README_圆柱度评定.md (详细说明文档)\n\n');

fprintf('输出文件:\n');
fprintf('  - measurement_data.mat (测量数据)\n');
fprintf('  - cylindricity_results.mat (评定结果)\n');
fprintf('  - cylindricity_report.txt (文本报告)\n');
fprintf('  - measurement_points.csv (CSV格式示例数据)\n\n');

fprintf('=== 快速开始完成 ===\n');
fprintf('您现在可以:\n');
fprintf('1. 查看生成的图形结果\n');
fprintf('2. 检查输出的文本报告\n');
fprintf('3. 使用自己的测量数据运行程序\n\n');

%% 演示函数：自动运行主程序
function demo_cylindricity_evaluation()
    % 自动化版本的主程序，用于演示
    
    fprintf('开始圆柱度评定演示...\n');
    
    % 生成模拟测量数据
    [x, y, z] = generate_demo_data();
    fprintf('已生成演示数据：%d个测量点\n', length(x));
    
    % 显示数据信息
    fprintf('Z轴范围: %.3f ~ %.3f mm\n', min(z), max(z));
    
    % 执行最小二乘法圆柱面拟合
    fprintf('正在执行最小二乘法拟合...\n');
    [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq_demo(x, y, z);
    
    % 显示结果
    fprintf('\n=== 演示结果 ===\n');
    fprintf('圆柱轴线通过点: (%.4f, %.4f)\n', axis_params(1), axis_params(2));
    fprintf('轴线方向向量: (%.4f, %.4f, %.4f)\n', axis_params(3), axis_params(4), axis_params(5));
    fprintf('圆柱半径: %.4f mm\n', radius);
    fprintf('圆柱度误差: %.4f mm\n', cylindricity_error);
    
    % 可视化结果
    visualize_demo_results(x, y, z, axis_params, radius, residuals);
    
    % 保存演示结果
    save('demo_results.mat', 'x', 'y', 'z', 'axis_params', 'radius', 'residuals', 'cylindricity_error');
    
    fprintf('演示结果已保存到 demo_results.mat\n');
end

function [x, y, z] = generate_demo_data()
    % 生成演示用的测量数据
    
    % 圆柱参数
    center = [2, -1];
    radius = 15;
    height = 60;
    
    % 测量点分布
    n_sections = 6;
    n_points_per_section = 12;
    
    x = []; y = []; z = [];
    
    for i = 1:n_sections
        z_level = (i-1) * height / (n_sections-1);
        
        for j = 1:n_points_per_section
            angle = (j-1) * 2*pi / n_points_per_section;
            
            % 添加形状误差
            ellipse_error = 0.03 * cos(2*angle);  % 椭圆度
            taper_error = 0.01 * z_level / height; % 锥度
            waviness = 0.005 * sin(8*angle);       % 波纹度
            
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

function visualize_demo_results(x, y, z, axis_params, radius, residuals)
    % 简化的可视化函数
    
    figure('Name', '圆柱度评定演示结果', 'Position', [100, 100, 1000, 700]);
    
    % 3D散点图
    subplot(2, 2, 1);
    scatter3(x, y, z, 50, residuals, 'filled');
    colorbar;
    title('测量点与残差分布');
    xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
    grid on; axis equal;
    
    % 残差直方图
    subplot(2, 2, 2);
    histogram(residuals, 15, 'FaceColor', [0.2, 0.6, 0.8]);
    title('残差分布');
    xlabel('残差 (mm)'); ylabel('频次');
    grid on;
    
    % XY投影
    subplot(2, 2, 3);
    scatter(x, y, 50, residuals, 'filled');
    colorbar;
    title('XY平面投影');
    xlabel('X (mm)'); ylabel('Y (mm)');
    axis equal; grid on;
    
    % 绘制理想圆
    hold on;
    theta = linspace(0, 2*pi, 100);
    x_circle = axis_params(1) + radius * cos(theta);
    y_circle = axis_params(2) + radius * sin(theta);
    plot(x_circle, y_circle, 'r-', 'LineWidth', 2);
    legend('测量点', '理想圆', 'Location', 'best');
    
    % 残差趋势
    subplot(2, 2, 4);
    plot(z, residuals, 'o', 'MarkerSize', 6, 'MarkerFaceColor', [0.8, 0.2, 0.2]);
    title('残差沿Z轴分布');
    xlabel('Z (mm)'); ylabel('残差 (mm)');
    grid on;
    hold on;
    plot([min(z), max(z)], [0, 0], 'k--', 'LineWidth', 1);
    
    sgtitle('圆柱度误差评定演示结果', 'FontSize', 16, 'FontWeight', 'bold');
end

% 简化的拟合函数（用于演示）
function [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq_demo(x, y, z)
    % 初始估计
    center_x = mean(x);
    center_y = mean(y);
    
    % 使用主成分分析估计轴线方向
    points = [x, y, z];
    centered_points = points - mean(points);
    [~, ~, V] = svd(centered_points);
    axis_direction = V(:, 1)';
    
    % 初始参数
    initial_params = [center_x, center_y, axis_direction, 15];
    
    % 优化选项
    options = optimoptions('lsqnonlin', 'Display', 'off', 'MaxIterations', 500);
    
    % 执行优化
    objective_function = @(params) cylinder_residuals_demo(params, x, y, z);
    [optimal_params, ~, residuals] = lsqnonlin(objective_function, initial_params, [], [], options);
    
    % 提取结果
    axis_params = optimal_params(1:5);
    radius = optimal_params(6);
    
    % 归一化轴线方向
    axis_direction_norm = norm(axis_params(3:5));
    axis_params(3:5) = axis_params(3:5) / axis_direction_norm;
    
    % 计算圆柱度误差
    distances = calculate_distances_demo(x, y, z, axis_params, radius);
    cylindricity_error = max(distances) - min(distances);
end

function residuals = cylinder_residuals_demo(params, x, y, z)
    x0 = params(1); y0 = params(2);
    dx = params(3); dy = params(4); dz = params(5);
    r = params(6);
    
    % 归一化
    axis_norm = sqrt(dx^2 + dy^2 + dz^2);
    dx = dx / axis_norm; dy = dy / axis_norm; dz = dz / axis_norm;
    
    n_points = length(x);
    residuals = zeros(n_points, 1);
    
    for i = 1:n_points
        px = x(i) - x0; py = y(i) - y0; pz = z(i);
        t = px*dx + py*dy + pz*dz;
        dist_to_axis = sqrt((px - t*dx)^2 + (py - t*dy)^2 + (pz - t*dz)^2);
        residuals(i) = dist_to_axis - r;
    end
end

function distances = calculate_distances_demo(x, y, z, axis_params, radius)
    x0 = axis_params(1); y0 = axis_params(2);
    dx = axis_params(3); dy = axis_params(4); dz = axis_params(5);
    
    n_points = length(x);
    distances = zeros(n_points, 1);
    
    for i = 1:n_points
        px = x(i) - x0; py = y(i) - y0; pz = z(i);
        t = px*dx + py*dy + pz*dz;
        dist_to_axis = sqrt((px - t*dx)^2 + (py - t*dy)^2 + (pz - t*dz)^2);
        distances(i) = dist_to_axis - radius;
    end
end