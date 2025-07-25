function cylindricity_evaluation()
    % 基于最小二乘法的圆柱度误差评定算法
    % 作者：MATLAB程序
    % 功能：评定圆柱度误差并可视化结果
    
    clear; clc; close all;
    
    % 1. 生成测试数据（模拟实际测量点）
    fprintf('正在生成测试数据...\n');
    [points, true_params] = generate_test_data();
    
    % 2. 使用最小二乘法拟合理想圆柱
    fprintf('正在使用最小二乘法拟合理想圆柱...\n');
    [fitted_params, residuals] = fit_cylinder_least_squares(points);
    
    % 3. 计算圆柱度误差
    fprintf('正在计算圆柱度误差...\n');
    cylindricity_error = calculate_cylindricity_error(points, fitted_params);
    
    % 4. 显示结果
    display_results(true_params, fitted_params, cylindricity_error);
    
    % 5. 可视化结果
    fprintf('正在生成可视化结果...\n');
    visualize_results(points, fitted_params, residuals, cylindricity_error);
    
    fprintf('圆柱度误差评定完成！\n');
end

function [points, true_params] = generate_test_data()
    % 生成模拟的圆柱测量点数据
    % 输出：points - 测量点坐标 [x, y, z]
    %       true_params - 真实圆柱参数 [x0, y0, axis_x, axis_y, axis_z, radius]
    
    % 真实圆柱参数
    true_center = [0, 0];           % 圆柱轴线在xy平面的投影中心
    true_axis = [0.1, 0.05, 1];     % 圆柱轴线方向向量（略有倾斜）
    true_axis = true_axis / norm(true_axis); % 归一化
    true_radius = 10;               % 真实半径
    
    % 生成测量点
    n_sections = 8;     % z方向截面数
    n_points_per_section = 16; % 每个截面的测量点数
    z_range = [0, 50];  % z方向范围
    
    points = [];
    
    for i = 1:n_sections
        z = z_range(1) + (z_range(2) - z_range(1)) * (i-1) / (n_sections-1);
        
        for j = 1:n_points_per_section
            theta = 2 * pi * (j-1) / n_points_per_section;
            
            % 理想圆上的点
            x_ideal = true_center(1) + true_radius * cos(theta);
            y_ideal = true_center(2) + true_radius * sin(theta);
            
            % 考虑轴线倾斜的影响
            x = x_ideal + true_axis(1) * z;
            y = y_ideal + true_axis(2) * z;
            
            % 添加随机误差（模拟测量误差和形状误差）
            noise_level = 0.05;
            x = x + noise_level * randn();
            y = y + noise_level * randn();
            z = z + noise_level * randn();
            
            % 添加系统性形状误差（椭圆度、锥度等）
            ellipticity = 0.02;
            x = x + ellipticity * true_radius * cos(2*theta);
            
            taper = 0.001;
            radius_at_z = true_radius * (1 - taper * z / z_range(2));
            scale_factor = radius_at_z / true_radius;
            x = true_center(1) + (x - true_center(1)) * scale_factor;
            y = true_center(2) + (y - true_center(2)) * scale_factor;
            
            points = [points; x, y, z];
        end
    end
    
    true_params = [true_center, true_axis, true_radius];
end

function [fitted_params, residuals] = fit_cylinder_least_squares(points)
    % 使用最小二乘法拟合圆柱
    % 输入：points - 测量点坐标 [x, y, z]
    % 输出：fitted_params - 拟合的圆柱参数 [x0, y0, axis_x, axis_y, axis_z, radius]
    %       residuals - 各点到拟合圆柱的残差
    
    % 初始参数估计
    x0_init = mean(points(:,1));
    y0_init = mean(points(:,2));
    
    % 使用PCA估计轴线方向
    centered_points = points - mean(points);
    [~, ~, V] = svd(centered_points');
    axis_init = V(:,1)'; % 主成分方向
    
    % 初始半径估计
    distances = sqrt((points(:,1) - x0_init).^2 + (points(:,2) - y0_init).^2);
    radius_init = mean(distances);
    
    % 初始参数向量
    params_init = [x0_init, y0_init, axis_init, radius_init];
    
    % 使用非线性最小二乘法优化
    options = optimoptions('lsqnonlin', 'Display', 'off', 'TolFun', 1e-12, 'TolX', 1e-12);
    
    [fitted_params, ~, residuals] = lsqnonlin(@(params) cylinder_residuals(params, points), ...
                                            params_init, [], [], options);
    
    % 归一化轴线方向向量
    axis_norm = norm(fitted_params(3:5));
    fitted_params(3:5) = fitted_params(3:5) / axis_norm;
end

function residuals = cylinder_residuals(params, points)
    % 计算点到圆柱的残差
    % 输入：params - 圆柱参数 [x0, y0, axis_x, axis_y, axis_z, radius]
    %       points - 测量点
    % 输出：residuals - 残差向量
    
    x0 = params(1);
    y0 = params(2);
    axis = params(3:5);
    axis = axis / norm(axis); % 归一化
    radius = params(6);
    
    n_points = size(points, 1);
    residuals = zeros(n_points, 1);
    
    for i = 1:n_points
        point = points(i, :);
        
        % 计算点到圆柱轴线的距离
        % 圆柱轴线通过点(x0, y0, 0)，方向为axis
        axis_point = [x0, y0, 0];
        
        % 点到直线的距离公式
        AP = point - axis_point;
        proj_length = dot(AP, axis);
        proj_point = axis_point + proj_length * axis;
        distance_to_axis = norm(point - proj_point);
        
        % 残差为实际距离与理想半径的差
        residuals(i) = distance_to_axis - radius;
    end
end

function cylindricity_error = calculate_cylindricity_error(points, fitted_params)
    % 计算圆柱度误差
    % 输入：points - 测量点
    %       fitted_params - 拟合的圆柱参数
    % 输出：cylindricity_error - 圆柱度误差值
    
    residuals = cylinder_residuals(fitted_params, points);
    
    % 圆柱度误差定义为最大残差与最小残差的差值
    cylindricity_error = max(residuals) - min(residuals);
end

function display_results(true_params, fitted_params, cylindricity_error)
    % 显示计算结果
    
    fprintf('\n========== 圆柱度误差评定结果 ==========\n');
    fprintf('真实圆柱参数：\n');
    fprintf('  中心坐标: (%.3f, %.3f)\n', true_params(1), true_params(2));
    fprintf('  轴线方向: (%.3f, %.3f, %.3f)\n', true_params(3), true_params(4), true_params(5));
    fprintf('  半径: %.3f\n', true_params(6));
    
    fprintf('\n拟合圆柱参数：\n');
    fprintf('  中心坐标: (%.3f, %.3f)\n', fitted_params(1), fitted_params(2));
    fprintf('  轴线方向: (%.3f, %.3f, %.3f)\n', fitted_params(3), fitted_params(4), fitted_params(5));
    fprintf('  半径: %.3f\n', fitted_params(6));
    
    fprintf('\n圆柱度误差: %.6f\n', cylindricity_error);
    fprintf('=======================================\n\n');
end

function visualize_results(points, fitted_params, residuals, cylindricity_error)
    % 可视化结果
    
    % 创建图形窗口
    figure('Position', [100, 100, 1200, 800]);
    
    % 子图1：3D点云和拟合圆柱
    subplot(2, 2, 1);
    plot_3d_cylinder(points, fitted_params);
    title('3D点云与拟合圆柱', 'FontSize', 12);
    
    % 子图2：残差分布
    subplot(2, 2, 2);
    plot_residuals_distribution(residuals);
    title('残差分布', 'FontSize', 12);
    
    % 子图3：残差沿z方向的变化
    subplot(2, 2, 3);
    plot_residuals_vs_z(points, residuals);
    title('残差沿轴向的变化', 'FontSize', 12);
    
    % 子图4：圆柱度误差统计
    subplot(2, 2, 4);
    plot_error_statistics(residuals, cylindricity_error);
    title('误差统计信息', 'FontSize', 12);
    
    % 设置整体标题
    sgtitle(sprintf('圆柱度误差评定结果 (圆柱度误差: %.6f)', cylindricity_error), ...
            'FontSize', 14, 'FontWeight', 'bold');
end

function plot_3d_cylinder(points, fitted_params)
    % 绘制3D点云和拟合圆柱
    
    % 绘制测量点
    scatter3(points(:,1), points(:,2), points(:,3), 30, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    
    % 绘制拟合圆柱
    x0 = fitted_params(1);
    y0 = fitted_params(2);
    axis_vec = fitted_params(3:5);
    radius = fitted_params(6);
    
    % 生成圆柱表面
    z_range = [min(points(:,3)), max(points(:,3))];
    z_cyl = linspace(z_range(1), z_range(2), 50);
    theta_cyl = linspace(0, 2*pi, 50);
    
    [Z_cyl, Theta_cyl] = meshgrid(z_cyl, theta_cyl);
    
    % 考虑轴线方向的圆柱面
    X_cyl = zeros(size(Z_cyl));
    Y_cyl = zeros(size(Z_cyl));
    
    for i = 1:length(z_cyl)
        for j = 1:length(theta_cyl)
            % 在垂直于轴线的平面上的圆
            x_local = radius * cos(theta_cyl(j));
            y_local = radius * sin(theta_cyl(j));
            
            % 转换到全局坐标系
            X_cyl(j, i) = x0 + x_local + axis_vec(1) * z_cyl(i);
            Y_cyl(j, i) = y0 + y_local + axis_vec(2) * z_cyl(i);
        end
    end
    
    % 绘制圆柱表面
    surf(X_cyl, Y_cyl, Z_cyl, 'FaceAlpha', 0.3, 'EdgeAlpha', 0.1, 'FaceColor', 'r');
    
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    grid on;
    axis equal;
    view(45, 30);
    legend('测量点', '拟合圆柱', 'Location', 'best');
end

function plot_residuals_distribution(residuals)
    % 绘制残差分布直方图
    
    histogram(residuals, 20, 'FaceColor', 'skyblue', 'EdgeColor', 'black', 'FaceAlpha', 0.7);
    xlabel('残差值');
    ylabel('频次');
    grid on;
    
    % 添加统计信息
    mean_res = mean(residuals);
    std_res = std(residuals);
    
    xline(mean_res, 'r--', 'LineWidth', 2, 'Label', sprintf('均值: %.4f', mean_res));
    xline(mean_res + std_res, 'g--', 'LineWidth', 1, 'Label', sprintf('+1σ: %.4f', mean_res + std_res));
    xline(mean_res - std_res, 'g--', 'LineWidth', 1, 'Label', sprintf('-1σ: %.4f', mean_res - std_res));
end

function plot_residuals_vs_z(points, residuals)
    % 绘制残差沿z方向的变化
    
    scatter(points(:,3), residuals, 50, 'filled', 'MarkerFaceAlpha', 0.6);
    xlabel('Z坐标');
    ylabel('残差值');
    grid on;
    
    % 添加零线
    yline(0, 'k--', 'LineWidth', 1);
    
    % 拟合趋势线
    p = polyfit(points(:,3), residuals, 1);
    z_fit = linspace(min(points(:,3)), max(points(:,3)), 100);
    residuals_fit = polyval(p, z_fit);
    plot(z_fit, residuals_fit, 'r-', 'LineWidth', 2, 'DisplayName', '趋势线');
    
    legend('残差', '零线', '趋势线', 'Location', 'best');
end

function plot_error_statistics(residuals, cylindricity_error)
    % 绘制误差统计信息
    
    % 计算统计量
    stats = [min(residuals), max(residuals), mean(residuals), std(residuals), cylindricity_error];
    labels = {'最小残差', '最大残差', '平均残差', '残差标准差', '圆柱度误差'};
    colors = ['b', 'r', 'g', 'm', 'k'];
    
    bar_handle = bar(1:length(stats), stats, 'FaceAlpha', 0.7);
    
    % 设置颜色
    for i = 1:length(stats)
        bar_handle.CData(i,:) = [colors(i) == 'b', colors(i) == 'g', colors(i) == 'r'];
    end
    
    set(gca, 'XTickLabel', labels);
    xtickangle(45);
    ylabel('数值');
    grid on;
    
    % 在每个柱子上显示数值
    for i = 1:length(stats)
        text(i, stats(i), sprintf('%.4f', stats(i)), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    end
end