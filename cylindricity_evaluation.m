function cylindricity_evaluation()
% 基于最小二乘法的圆柱度误差评定算法
% 适用于MATLAB 2024a
% 
% 功能：
% 1. 生成或读取实际测量数据
% 2. 使用最小二乘法拟合理想圆柱面
% 3. 计算圆柱度误差
% 4. 可视化结果

    clc; clear; close all;
    
    fprintf('=== 基于最小二乘法的圆柱度误差评定算法 ===\n\n');
    
    % 选择数据来源
    choice = input('选择数据来源 (1-生成模拟数据, 2-从文件读取): ');
    
    if choice == 1
        % 生成模拟测量数据
        [x, y, z] = generate_measurement_data();
        fprintf('已生成模拟测量数据\n');
    else
        % 从文件读取数据
        try
            data = load('measurement_data.mat');
            x = data.x; y = data.y; z = data.z;
            fprintf('已从文件读取测量数据\n');
        catch
            fprintf('文件读取失败，使用模拟数据\n');
            [x, y, z] = generate_measurement_data();
        end
    end
    
    % 显示数据信息
    fprintf('测量点数量: %d\n', length(x));
    fprintf('Z轴范围: %.3f ~ %.3f mm\n', min(z), max(z));
    
    % 执行最小二乘法圆柱面拟合
    fprintf('\n正在执行最小二乘法拟合...\n');
    [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq(x, y, z);
    
    % 显示结果
    display_results(axis_params, radius, cylindricity_error);
    
    % 可视化结果
    visualize_results(x, y, z, axis_params, radius, residuals);
    
    % 保存结果
    save_results(x, y, z, axis_params, radius, residuals, cylindricity_error);
    
    fprintf('\n程序执行完成！\n');
end

function [x, y, z] = generate_measurement_data()
% 生成模拟的圆柱面测量数据
    
    % 理想圆柱参数
    ideal_center = [0, 0];  % 圆心坐标
    ideal_radius = 10;      % 半径 (mm)
    ideal_axis = [0, 0, 1]; % 轴线方向向量
    
    % 测量参数
    n_sections = 8;         % Z方向截面数
    n_points_per_section = 16; % 每个截面的测量点数
    z_range = [0, 50];      % Z轴测量范围 (mm)
    
    % 生成测量点
    z_sections = linspace(z_range(1), z_range(2), n_sections);
    angles = linspace(0, 2*pi, n_points_per_section + 1);
    angles(end) = []; % 移除重复的2π点
    
    x = []; y = []; z = [];
    
    for i = 1:n_sections
        for j = 1:n_points_per_section
            % 理想圆柱面上的点
            x_ideal = ideal_center(1) + ideal_radius * cos(angles(j));
            y_ideal = ideal_center(2) + ideal_radius * sin(angles(j));
            z_ideal = z_sections(i);
            
            % 添加测量误差和形状误差
            % 圆柱度误差（椭圆度、锥度等）
            ellipticity = 0.02; % 椭圆度
            taper = 0.001;      % 锥度
            roughness = 0.005;  % 表面粗糙度
            
            % 椭圆度影响
            r_local = ideal_radius * (1 + ellipticity * cos(2*angles(j)));
            
            % 锥度影响
            r_local = r_local * (1 + taper * z_ideal / z_range(2));
            
            % 计算实际坐标
            x_actual = ideal_center(1) + r_local * cos(angles(j));
            y_actual = ideal_center(2) + r_local * sin(angles(j));
            z_actual = z_ideal;
            
            % 添加随机测量误差
            x_actual = x_actual + roughness * randn();
            y_actual = y_actual + roughness * randn();
            z_actual = z_actual + 0.001 * randn();
            
            x = [x; x_actual];
            y = [y; y_actual];
            z = [z; z_actual];
        end
    end
    
    % 保存生成的数据
    save('measurement_data.mat', 'x', 'y', 'z');
end

function [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq(x, y, z)
% 使用最小二乘法拟合圆柱面
% 输入: x, y, z - 测量点坐标
% 输出: axis_params - 轴线参数 [x0, y0, dx, dy, dz]
%       radius - 圆柱半径
%       residuals - 残差
%       cylindricity_error - 圆柱度误差

    n_points = length(x);
    
    % 初始估计
    % 使用所有点的重心作为轴线上的一点
    center_x = mean(x);
    center_y = mean(y);
    
    % 使用主成分分析估计轴线方向
    points = [x, y, z];
    centered_points = points - mean(points);
    [~, ~, V] = svd(centered_points);
    axis_direction = V(:, 1)'; % 第一主成分作为轴线方向
    
    % 初始参数 [x0, y0, dx, dy, dz, r]
    initial_params = [center_x, center_y, axis_direction, 10];
    
    % 使用非线性最小二乘法优化
    options = optimoptions('lsqnonlin', 'Display', 'off', 'MaxIterations', 1000);
    
    % 定义目标函数
    objective_function = @(params) cylinder_residuals(params, x, y, z);
    
    % 执行优化
    [optimal_params, ~, residuals] = lsqnonlin(objective_function, initial_params, [], [], options);
    
    % 提取结果
    axis_params = optimal_params(1:5);
    radius = optimal_params(6);
    
    % 归一化轴线方向向量
    axis_direction_norm = norm(axis_params(3:5));
    axis_params(3:5) = axis_params(3:5) / axis_direction_norm;
    
    % 计算圆柱度误差
    distances = calculate_distances_to_cylinder(x, y, z, axis_params, radius);
    cylindricity_error = max(distances) - min(distances);
end

function residuals = cylinder_residuals(params, x, y, z)
% 计算点到圆柱面的残差
    
    x0 = params(1); y0 = params(2);
    dx = params(3); dy = params(4); dz = params(5);
    r = params(6);
    
    % 归一化轴线方向向量
    axis_norm = sqrt(dx^2 + dy^2 + dz^2);
    dx = dx / axis_norm;
    dy = dy / axis_norm;
    dz = dz / axis_norm;
    
    n_points = length(x);
    residuals = zeros(n_points, 1);
    
    for i = 1:n_points
        % 点到轴线的距离
        px = x(i) - x0;
        py = y(i) - y0;
        pz = z(i);
        
        % 点在轴线上的投影
        t = px*dx + py*dy + pz*dz;
        
        % 点到轴线的垂直距离
        dist_to_axis = sqrt((px - t*dx)^2 + (py - t*dy)^2 + (pz - t*dz)^2);
        
        % 残差 = 实际距离 - 理想半径
        residuals(i) = dist_to_axis - r;
    end
end

function distances = calculate_distances_to_cylinder(x, y, z, axis_params, radius)
% 计算点到理想圆柱面的距离
    
    x0 = axis_params(1); y0 = axis_params(2);
    dx = axis_params(3); dy = axis_params(4); dz = axis_params(5);
    
    n_points = length(x);
    distances = zeros(n_points, 1);
    
    for i = 1:n_points
        px = x(i) - x0;
        py = y(i) - y0;
        pz = z(i);
        
        % 点在轴线上的投影
        t = px*dx + py*dy + pz*dz;
        
        % 点到轴线的距离
        dist_to_axis = sqrt((px - t*dx)^2 + (py - t*dy)^2 + (pz - t*dz)^2);
        
        % 点到圆柱面的距离（带符号）
        distances(i) = dist_to_axis - radius;
    end
end

function display_results(axis_params, radius, cylindricity_error)
% 显示拟合结果
    
    fprintf('\n=== 拟合结果 ===\n');
    fprintf('圆柱轴线通过点: (%.4f, %.4f)\n', axis_params(1), axis_params(2));
    fprintf('轴线方向向量: (%.4f, %.4f, %.4f)\n', axis_params(3), axis_params(4), axis_params(5));
    fprintf('圆柱半径: %.4f mm\n', radius);
    fprintf('圆柱度误差: %.4f mm\n', cylindricity_error);
    
    % 轴线与Z轴的夹角
    z_axis = [0, 0, 1];
    axis_direction = axis_params(3:5);
    angle_with_z = acosd(abs(dot(axis_direction, z_axis)));
    fprintf('轴线与Z轴夹角: %.2f°\n', angle_with_z);
end

function visualize_results(x, y, z, axis_params, radius, residuals)
% 可视化结果
    
    figure('Position', [100, 100, 1200, 800]);
    
    % 子图1: 3D散点图和拟合圆柱
    subplot(2, 2, 1);
    scatter3(x, y, z, 30, residuals, 'filled');
    colorbar;
    title('测量点与残差分布');
    xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
    axis equal; grid on;
    
    % 绘制理想圆柱面
    hold on;
    draw_cylinder(axis_params, radius, [min(z), max(z)]);
    
    % 子图2: 残差分布直方图
    subplot(2, 2, 2);
    histogram(residuals, 20);
    title('残差分布直方图');
    xlabel('残差 (mm)'); ylabel('频次');
    grid on;
    
    % 子图3: XY平面投影
    subplot(2, 2, 3);
    scatter(x, y, 30, residuals, 'filled');
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
    
    % 子图4: 残差随Z坐标变化
    subplot(2, 2, 4);
    scatter(z, residuals, 30, 'filled');
    title('残差沿Z轴分布');
    xlabel('Z (mm)'); ylabel('残差 (mm)');
    grid on;
    
    % 添加零线
    hold on;
    plot([min(z), max(z)], [0, 0], 'r--', 'LineWidth', 1);
    
    sgtitle('圆柱度误差评定结果', 'FontSize', 14, 'FontWeight', 'bold');
end

function draw_cylinder(axis_params, radius, z_range)
% 绘制理想圆柱面
    
    x0 = axis_params(1); y0 = axis_params(2);
    dx = axis_params(3); dy = axis_params(4); dz = axis_params(5);
    
    % 生成圆柱面网格
    theta = linspace(0, 2*pi, 20);
    z_cyl = linspace(z_range(1), z_range(2), 20);
    [THETA, Z_CYL] = meshgrid(theta, z_cyl);
    
    % 计算圆柱面坐标
    % 需要构建垂直于轴线的坐标系
    axis_vec = [dx, dy, dz];
    
    % 找到两个垂直于轴线的单位向量
    if abs(dx) < 0.9
        u1 = cross(axis_vec, [1, 0, 0]);
    else
        u1 = cross(axis_vec, [0, 1, 0]);
    end
    u1 = u1 / norm(u1);
    u2 = cross(axis_vec, u1);
    u2 = u2 / norm(u2);
    
    X_CYL = zeros(size(THETA));
    Y_CYL = zeros(size(THETA));
    Z_CYL_actual = zeros(size(THETA));
    
    for i = 1:size(THETA, 1)
        for j = 1:size(THETA, 2)
            % 圆柱面上的点
            local_x = radius * cos(THETA(i, j));
            local_y = radius * sin(THETA(i, j));
            
            % 转换到全局坐标系
            point = [x0, y0, 0] + Z_CYL(i, j) * axis_vec + local_x * u1 + local_y * u2;
            X_CYL(i, j) = point(1);
            Y_CYL(i, j) = point(2);
            Z_CYL_actual(i, j) = point(3);
        end
    end
    
    surf(X_CYL, Y_CYL, Z_CYL_actual, 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', 'red');
end

function save_results(x, y, z, axis_params, radius, residuals, cylindricity_error)
% 保存结果到文件
    
    results = struct();
    results.measurement_points = [x, y, z];
    results.axis_params = axis_params;
    results.radius = radius;
    results.residuals = residuals;
    results.cylindricity_error = cylindricity_error;
    results.timestamp = datetime('now');
    
    save('cylindricity_results.mat', 'results');
    
    % 保存为文本文件
    fid = fopen('cylindricity_report.txt', 'w');
    fprintf(fid, '圆柱度误差评定报告\n');
    fprintf(fid, '生成时间: %s\n\n', char(results.timestamp));
    fprintf(fid, '拟合参数:\n');
    fprintf(fid, '  轴线通过点: (%.6f, %.6f)\n', axis_params(1), axis_params(2));
    fprintf(fid, '  轴线方向: (%.6f, %.6f, %.6f)\n', axis_params(3), axis_params(4), axis_params(5));
    fprintf(fid, '  圆柱半径: %.6f mm\n', radius);
    fprintf(fid, '  圆柱度误差: %.6f mm\n', cylindricity_error);
    fprintf(fid, '  最大正偏差: %.6f mm\n', max(residuals));
    fprintf(fid, '  最大负偏差: %.6f mm\n', min(residuals));
    fprintf(fid, '  残差标准差: %.6f mm\n', std(residuals));
    fclose(fid);
    
    fprintf('\n结果已保存到文件:\n');
    fprintf('  - cylindricity_results.mat (MATLAB数据)\n');
    fprintf('  - cylindricity_report.txt (文本报告)\n');
end