function test_cylindricity_algorithm()
% 测试圆柱度评定算法的正确性
% 使用已知参数的理论数据进行验证

    fprintf('=== 圆柱度评定算法测试 ===\n\n');
    
    % 测试1: 理想圆柱（无误差）
    fprintf('测试1: 理想圆柱数据...\n');
    test_perfect_cylinder();
    
    % 测试2: 已知误差的圆柱
    fprintf('\n测试2: 已知误差圆柱数据...\n');
    test_known_error_cylinder();
    
    % 测试3: 倾斜圆柱
    fprintf('\n测试3: 倾斜圆柱数据...\n');
    test_tilted_cylinder();
    
    fprintf('\n=== 所有测试完成 ===\n');
end

function test_perfect_cylinder()
% 测试理想圆柱（期望误差接近0）
    
    % 理想参数
    true_center = [0, 0];
    true_radius = 20;
    true_axis = [0, 0, 1];
    
    % 生成理想圆柱数据
    [x, y, z] = generate_perfect_cylinder_data(true_center, true_radius, true_axis);
    
    % 执行拟合
    [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq(x, y, z);
    
    % 验证结果
    center_error = norm([axis_params(1) - true_center(1), axis_params(2) - true_center(2)]);
    radius_error = abs(radius - true_radius);
    axis_error = norm(axis_params(3:5) - true_axis);
    
    fprintf('  中心位置误差: %.6f mm\n', center_error);
    fprintf('  半径误差: %.6f mm\n', radius_error);
    fprintf('  轴线方向误差: %.6f\n', axis_error);
    fprintf('  圆柱度误差: %.6f mm\n', cylindricity_error);
    
    % 判断测试结果
    tolerance = 1e-6;
    if center_error < tolerance && radius_error < tolerance && ...
       axis_error < tolerance && cylindricity_error < tolerance
        fprintf('  ✅ 测试通过\n');
    else
        fprintf('  ❌ 测试失败\n');
    end
end

function test_known_error_cylinder()
% 测试已知误差的圆柱
    
    % 理想参数
    true_center = [5, -3];
    true_radius = 15;
    true_axis = [0, 0, 1];
    known_cylindricity = 0.1; % 已知圆柱度误差
    
    % 生成带已知误差的数据
    [x, y, z] = generate_error_cylinder_data(true_center, true_radius, true_axis, known_cylindricity);
    
    % 执行拟合
    [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq(x, y, z);
    
    % 验证结果
    center_error = norm([axis_params(1) - true_center(1), axis_params(2) - true_center(2)]);
    radius_error = abs(radius - true_radius);
    cylindricity_error_ratio = abs(cylindricity_error - known_cylindricity) / known_cylindricity;
    
    fprintf('  中心位置误差: %.6f mm\n', center_error);
    fprintf('  半径误差: %.6f mm\n', radius_error);
    fprintf('  理论圆柱度误差: %.6f mm\n', known_cylindricity);
    fprintf('  计算圆柱度误差: %.6f mm\n', cylindricity_error);
    fprintf('  圆柱度误差相对误差: %.2f%%\n', cylindricity_error_ratio * 100);
    
    % 判断测试结果
    if center_error < 0.01 && radius_error < 0.01 && cylindricity_error_ratio < 0.1
        fprintf('  ✅ 测试通过\n');
    else
        fprintf('  ❌ 测试失败\n');
    end
end

function test_tilted_cylinder()
% 测试倾斜圆柱
    
    % 倾斜圆柱参数
    true_center = [0, 0];
    true_radius = 12;
    true_axis = [0.1, 0.05, 0.995]; % 轻微倾斜
    true_axis = true_axis / norm(true_axis); % 归一化
    
    % 生成倾斜圆柱数据
    [x, y, z] = generate_tilted_cylinder_data(true_center, true_radius, true_axis);
    
    % 执行拟合
    [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq(x, y, z);
    
    % 验证结果
    center_error = norm([axis_params(1) - true_center(1), axis_params(2) - true_center(2)]);
    radius_error = abs(radius - true_radius);
    axis_error = norm(axis_params(3:5) - true_axis);
    angle_with_z = acosd(abs(dot(axis_params(3:5), [0, 0, 1])));
    true_angle = acosd(abs(dot(true_axis, [0, 0, 1])));
    
    fprintf('  中心位置误差: %.6f mm\n', center_error);
    fprintf('  半径误差: %.6f mm\n', radius_error);
    fprintf('  轴线方向误差: %.6f\n', axis_error);
    fprintf('  理论倾斜角: %.2f°\n', true_angle);
    fprintf('  计算倾斜角: %.2f°\n', angle_with_z);
    fprintf('  圆柱度误差: %.6f mm\n', cylindricity_error);
    
    % 判断测试结果
    angle_error = abs(angle_with_z - true_angle);
    if center_error < 0.01 && radius_error < 0.01 && angle_error < 0.5
        fprintf('  ✅ 测试通过\n');
    else
        fprintf('  ❌ 测试失败\n');
    end
end

function [x, y, z] = generate_perfect_cylinder_data(center, radius, axis_direction)
% 生成理想圆柱数据
    
    n_sections = 5;
    n_points_per_section = 12;
    height = 30;
    
    x = []; y = []; z = [];
    
    for i = 1:n_sections
        z_level = (i-1) * height / (n_sections-1);
        
        for j = 1:n_points_per_section
            angle = (j-1) * 2*pi / n_points_per_section;
            
            x_point = center(1) + radius * cos(angle);
            y_point = center(2) + radius * sin(angle);
            z_point = z_level;
            
            x = [x; x_point];
            y = [y; y_point];
            z = [z; z_point];
        end
    end
end

function [x, y, z] = generate_error_cylinder_data(center, radius, axis_direction, cylindricity_error)
% 生成带已知误差的圆柱数据
    
    n_sections = 8;
    n_points_per_section = 16;
    height = 40;
    
    x = []; y = []; z = [];
    
    for i = 1:n_sections
        z_level = (i-1) * height / (n_sections-1);
        
        for j = 1:n_points_per_section
            angle = (j-1) * 2*pi / n_points_per_section;
            
            % 添加椭圆度误差
            ellipse_factor = 1 + (cylindricity_error/2) * cos(2*angle);
            r_local = radius * ellipse_factor;
            
            x_point = center(1) + r_local * cos(angle);
            y_point = center(2) + r_local * sin(angle);
            z_point = z_level;
            
            x = [x; x_point];
            y = [y; y_point];
            z = [z; z_point];
        end
    end
end

function [x, y, z] = generate_tilted_cylinder_data(center, radius, axis_direction)
% 生成倾斜圆柱数据
    
    n_sections = 6;
    n_points_per_section = 12;
    height = 50;
    
    % 构建垂直于轴线的坐标系
    if abs(axis_direction(1)) < 0.9
        u1 = cross(axis_direction, [1, 0, 0]);
    else
        u1 = cross(axis_direction, [0, 1, 0]);
    end
    u1 = u1 / norm(u1);
    u2 = cross(axis_direction, u1);
    u2 = u2 / norm(u2);
    
    x = []; y = []; z = [];
    
    for i = 1:n_sections
        t = (i-1) * height / (n_sections-1);
        
        for j = 1:n_points_per_section
            angle = (j-1) * 2*pi / n_points_per_section;
            
            % 圆柱面上的点（局部坐标）
            local_x = radius * cos(angle);
            local_y = radius * sin(angle);
            
            % 转换到全局坐标
            point = [center(1), center(2), 0] + t * axis_direction + ...
                    local_x * u1 + local_y * u2;
            
            x = [x; point(1)];
            y = [y; point(2)];
            z = [z; point(3)];
        end
    end
end

% 包含原程序中的拟合函数
function [axis_params, radius, residuals, cylindricity_error] = fit_cylinder_lsq(x, y, z)
% 使用最小二乘法拟合圆柱面
    
    n_points = length(x);
    
    % 初始估计
    center_x = mean(x);
    center_y = mean(y);
    
    % 使用主成分分析估计轴线方向
    points = [x, y, z];
    centered_points = points - mean(points);
    [~, ~, V] = svd(centered_points);
    axis_direction = V(:, 1)';
    
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
        px = x(i) - x0;
        py = y(i) - y0;
        pz = z(i);
        
        t = px*dx + py*dy + pz*dz;
        dist_to_axis = sqrt((px - t*dx)^2 + (py - t*dy)^2 + (pz - t*dz)^2);
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
        
        t = px*dx + py*dy + pz*dz;
        dist_to_axis = sqrt((px - t*dx)^2 + (py - t*dy)^2 + (pz - t*dz)^2);
        distances(i) = dist_to_axis - radius;
    end
end