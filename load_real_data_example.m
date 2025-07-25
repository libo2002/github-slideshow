function load_real_data_example()
    % 使用实际测量数据的示例程序
    % 演示如何将程序应用于真实的测量数据
    
    clear; clc; close all;
    
    fprintf('实际数据处理示例\n');
    fprintf('================\n');
    
    % 方法1：从CSV文件读取数据
    % 假设数据格式为：x, y, z（每行一个测量点）
    try
        % 尝试读取数据文件（如果存在）
        if exist('measurement_data.csv', 'file')
            fprintf('正在从CSV文件读取数据...\n');
            data = readmatrix('measurement_data.csv');
            points = data(:, 1:3); % 假设前三列是x, y, z坐标
        else
            fprintf('未找到measurement_data.csv文件，使用模拟数据...\n');
            points = generate_sample_real_data();
        end
    catch
        fprintf('读取文件出错，使用模拟数据...\n');
        points = generate_sample_real_data();
    end
    
    % 数据预处理
    fprintf('正在进行数据预处理...\n');
    points = preprocess_data(points);
    
    % 使用圆柱度评定算法
    fprintf('正在进行圆柱度误差评定...\n');
    [fitted_params, residuals] = fit_cylinder_least_squares(points);
    cylindricity_error = calculate_cylindricity_error(points, fitted_params);
    
    % 显示结果
    display_real_data_results(fitted_params, cylindricity_error, points);
    
    % 可视化
    visualize_real_data_results(points, fitted_params, residuals, cylindricity_error);
    
    fprintf('实际数据处理完成！\n');
end

function points = generate_sample_real_data()
    % 生成更接近实际测量的样本数据
    % 模拟三坐标测量机的测量模式
    
    fprintf('  生成样本测量数据...\n');
    
    % 真实圆柱参数（更接近实际工件）
    true_center = [0.05, -0.03];    % 中心有偏移
    true_axis = [0.02, -0.01, 1];   % 轴线有微小倾斜
    true_axis = true_axis / norm(true_axis);
    true_radius = 25.0;             % 25mm半径
    
    % 测量模式：螺旋扫描
    n_turns = 3;                    % 螺旋圈数
    points_per_turn = 50;           % 每圈点数
    z_range = [0, 80];              % 80mm长度
    
    points = [];
    total_points = n_turns * points_per_turn;
    
    for i = 1:total_points
        % 螺旋角度
        theta = 2 * pi * n_turns * (i-1) / (total_points-1);
        
        % z坐标
        z = z_range(1) + (z_range(2) - z_range(1)) * (i-1) / (total_points-1);
        
        % 理想圆上的点
        x_ideal = true_center(1) + true_radius * cos(theta);
        y_ideal = true_center(2) + true_radius * sin(theta);
        
        % 考虑轴线倾斜
        x = x_ideal + true_axis(1) * z;
        y = y_ideal + true_axis(2) * z;
        
        % 添加真实的测量误差
        % 1. 随机测量噪声
        measurement_noise = 0.002; % 2μm测量精度
        x = x + measurement_noise * randn();
        y = y + measurement_noise * randn();
        z = z + measurement_noise * randn();
        
        % 2. 系统性形状误差
        % 椭圆度
        ellipticity = 0.008;
        x = x + ellipticity * true_radius * cos(2*theta);
        
        % 锥度
        taper = 0.0001; % 0.01% 锥度
        radius_at_z = true_radius * (1 - taper * z / z_range(2));
        scale_factor = radius_at_z / true_radius;
        x = true_center(1) + (x - true_center(1)) * scale_factor;
        y = true_center(2) + (y - true_center(2)) * scale_factor;
        
        % 3. 表面粗糙度影响
        surface_roughness = 0.001;
        roughness_angle = 20 * theta; % 高频成分
        x = x + surface_roughness * sin(roughness_angle);
        y = y + surface_roughness * cos(roughness_angle);
        
        points = [points; x, y, z];
    end
    
    fprintf('  生成了 %d 个测量点\n', size(points, 1));
end

function points_clean = preprocess_data(points)
    % 数据预处理：去除异常点，数据平滑等
    
    fprintf('  数据预处理...\n');
    
    % 1. 去除明显的异常点（3σ准则）
    center = mean(points);
    distances = sqrt(sum((points - center).^2, 2));
    mean_dist = mean(distances);
    std_dist = std(distances);
    
    % 保留在3σ范围内的点
    valid_indices = abs(distances - mean_dist) <= 3 * std_dist;
    points_clean = points(valid_indices, :);
    
    removed_points = sum(~valid_indices);
    if removed_points > 0
        fprintf('  去除了 %d 个异常点\n', removed_points);
    end
    
    % 2. 数据平滑（可选）
    % 对于高密度数据，可以进行适当的平滑处理
    if size(points_clean, 1) > 200
        % 简单的移动平均平滑
        window_size = 3;
        for dim = 1:3
            points_clean(:, dim) = smooth(points_clean(:, dim), window_size);
        end
        fprintf('  应用了数据平滑处理\n');
    end
    
    fprintf('  预处理后保留 %d 个有效点\n', size(points_clean, 1));
end

function display_real_data_results(fitted_params, cylindricity_error, points)
    % 显示实际数据的分析结果
    
    fprintf('\n========== 实际数据圆柱度评定结果 ==========\n');
    fprintf('测量点数量: %d\n', size(points, 1));
    fprintf('测量范围:\n');
    fprintf('  X: %.3f ~ %.3f mm\n', min(points(:,1)), max(points(:,1)));
    fprintf('  Y: %.3f ~ %.3f mm\n', min(points(:,2)), max(points(:,2)));
    fprintf('  Z: %.3f ~ %.3f mm\n', min(points(:,3)), max(points(:,3)));
    
    fprintf('\n拟合圆柱参数:\n');
    fprintf('  中心坐标: (%.4f, %.4f) mm\n', fitted_params(1), fitted_params(2));
    fprintf('  轴线方向: (%.6f, %.6f, %.6f)\n', fitted_params(3), fitted_params(4), fitted_params(5));
    fprintf('  半径: %.4f mm\n', fitted_params(6));
    
    fprintf('\n圆柱度误差: %.6f mm\n', cylindricity_error);
    
    % 评定等级
    if cylindricity_error <= 0.005
        grade = 'IT6级或更高';
    elseif cylindricity_error <= 0.010
        grade = 'IT7级';
    elseif cylindricity_error <= 0.020
        grade = 'IT8级';
    elseif cylindricity_error <= 0.050
        grade = 'IT9级';
    else
        grade = 'IT10级或更低';
    end
    
    fprintf('精度等级: %s\n', grade);
    fprintf('==========================================\n\n');
end

function visualize_real_data_results(points, fitted_params, residuals, cylindricity_error)
    % 实际数据的可视化（增强版）
    
    figure('Position', [50, 50, 1400, 900]);
    
    % 子图1：3D点云和拟合圆柱
    subplot(2, 3, 1);
    plot_3d_cylinder_enhanced(points, fitted_params);
    title('3D测量点云与拟合圆柱', 'FontSize', 11);
    
    % 子图2：残差分布
    subplot(2, 3, 2);
    plot_residuals_distribution_enhanced(residuals);
    title('残差分布分析', 'FontSize', 11);
    
    % 子图3：残差沿轴向变化
    subplot(2, 3, 3);
    plot_residuals_vs_z_enhanced(points, residuals);
    title('残差轴向变化', 'FontSize', 11);
    
    % 子图4：极坐标残差图
    subplot(2, 3, 4);
    plot_polar_residuals(points, fitted_params, residuals);
    title('极坐标残差分布', 'FontSize', 11);
    
    % 子图5：误差统计
    subplot(2, 3, 5);
    plot_error_statistics_enhanced(residuals, cylindricity_error);
    title('误差统计信息', 'FontSize', 11);
    
    % 子图6：截面圆度分析
    subplot(2, 3, 6);
    plot_section_roundness(points, fitted_params);
    title('截面圆度分析', 'FontSize', 11);
    
    sgtitle(sprintf('实际数据圆柱度评定结果 (误差: %.6f mm)', cylindricity_error), ...
            'FontSize', 14, 'FontWeight', 'bold');
end

function plot_3d_cylinder_enhanced(points, fitted_params)
    % 增强版3D可视化
    scatter3(points(:,1), points(:,2), points(:,3), 20, points(:,3), 'filled');
    colormap(jet);
    colorbar('Label', 'Z坐标 (mm)');
    hold on;
    
    % 绘制拟合圆柱（简化版）
    x0 = fitted_params(1);
    y0 = fitted_params(2);
    radius = fitted_params(6);
    z_range = [min(points(:,3)), max(points(:,3))];
    
    theta = linspace(0, 2*pi, 50);
    z_cyl = linspace(z_range(1), z_range(2), 20);
    
    for i = 1:length(z_cyl)
        x_circle = x0 + radius * cos(theta);
        y_circle = y0 + radius * sin(theta);
        z_circle = z_cyl(i) * ones(size(theta));
        plot3(x_circle, y_circle, z_circle, 'r-', 'LineWidth', 1);
    end
    
    xlabel('X (mm)');
    ylabel('Y (mm)');
    zlabel('Z (mm)');
    grid on;
    axis equal;
    view(45, 30);
end

function plot_residuals_distribution_enhanced(residuals)
    % 增强版残差分布
    histogram(residuals, 30, 'Normalization', 'probability', ...
              'FaceColor', 'skyblue', 'EdgeColor', 'black', 'FaceAlpha', 0.7);
    xlabel('残差 (mm)');
    ylabel('概率密度');
    grid on;
    
    % 添加正态分布拟合
    mu = mean(residuals);
    sigma = std(residuals);
    x_norm = linspace(min(residuals), max(residuals), 100);
    y_norm = normpdf(x_norm, mu, sigma);
    hold on;
    plot(x_norm, y_norm * (max(ylim) / max(y_norm)), 'r-', 'LineWidth', 2, ...
         'DisplayName', '正态分布拟合');
    
    legend('Location', 'best');
end

function plot_residuals_vs_z_enhanced(points, residuals)
    % 增强版轴向残差分析
    scatter(points(:,3), residuals, 30, abs(residuals), 'filled');
    colormap(hot);
    colorbar('Label', '|残差| (mm)');
    xlabel('Z坐标 (mm)');
    ylabel('残差 (mm)');
    grid on;
    
    % 添加零线和趋势线
    yline(0, 'k--', 'LineWidth', 1);
    p = polyfit(points(:,3), residuals, 2); % 二次拟合
    z_fit = linspace(min(points(:,3)), max(points(:,3)), 100);
    residuals_fit = polyval(p, z_fit);
    hold on;
    plot(z_fit, residuals_fit, 'b-', 'LineWidth', 2, 'DisplayName', '趋势线');
    legend('Location', 'best');
end

function plot_polar_residuals(points, fitted_params, residuals)
    % 极坐标残差分布
    x0 = fitted_params(1);
    y0 = fitted_params(2);
    
    % 计算每个点的角度
    angles = atan2(points(:,2) - y0, points(:,1) - x0);
    angles(angles < 0) = angles(angles < 0) + 2*pi; % 转换到0-2π
    
    % 极坐标散点图
    polarscatter(angles, abs(residuals), 30, residuals, 'filled');
    colormap(jet);
    colorbar('Label', '残差 (mm)');
    title('极坐标残差分布');
end

function plot_error_statistics_enhanced(residuals, cylindricity_error)
    % 增强版误差统计
    stats = [min(residuals), max(residuals), mean(residuals), std(residuals), ...
             cylindricity_error, rms(residuals)];
    labels = {'最小', '最大', '均值', '标准差', '圆柱度', 'RMS'};
    
    bar(stats, 'FaceAlpha', 0.7);
    set(gca, 'XTickLabel', labels);
    xtickangle(45);
    ylabel('数值 (mm)');
    grid on;
    
    % 显示数值
    for i = 1:length(stats)
        text(i, stats(i), sprintf('%.4f', stats(i)), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    end
end

function plot_section_roundness(points, fitted_params)
    % 截面圆度分析
    z_sections = linspace(min(points(:,3)), max(points(:,3)), 5);
    roundness_errors = zeros(size(z_sections));
    
    for i = 1:length(z_sections)
        % 找到接近该截面的点
        z_tol = (max(points(:,3)) - min(points(:,3))) / 10;
        section_points = points(abs(points(:,3) - z_sections(i)) < z_tol, :);
        
        if size(section_points, 1) > 3
            % 拟合圆并计算圆度误差
            x0 = fitted_params(1);
            y0 = fitted_params(2);
            distances = sqrt((section_points(:,1) - x0).^2 + (section_points(:,2) - y0).^2);
            roundness_errors(i) = max(distances) - min(distances);
        end
    end
    
    plot(z_sections, roundness_errors * 1000, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('Z坐标 (mm)');
    ylabel('圆度误差 (μm)');
    grid on;
    title('各截面圆度误差分布');
end

% 注意：需要确保主程序中的相关函数可用
% 这个文件展示了如何扩展基本程序来处理实际数据