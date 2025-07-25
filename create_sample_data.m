function create_sample_data()
    % 创建示例测量数据CSV文件
    % 用于测试实际数据处理功能
    
    fprintf('正在创建示例测量数据文件...\n');
    
    % 生成示例数据
    points = generate_realistic_measurement_data();
    
    % 保存为CSV文件
    filename = 'measurement_data.csv';
    
    % 创建表头
    header = {'X_mm', 'Y_mm', 'Z_mm', 'Point_ID', 'Section'};
    
    % 添加点编号和截面信息
    n_points = size(points, 1);
    point_ids = (1:n_points)';
    sections = ceil((1:n_points)' / 20); % 假设每20个点为一个截面
    
    % 组合数据
    data_table = table(points(:,1), points(:,2), points(:,3), point_ids, sections, ...
                      'VariableNames', header);
    
    % 写入CSV文件
    writetable(data_table, filename);
    
    fprintf('示例数据文件已创建: %s\n', filename);
    fprintf('数据包含 %d 个测量点\n', n_points);
    fprintf('数据范围:\n');
    fprintf('  X: %.3f ~ %.3f mm\n', min(points(:,1)), max(points(:,1)));
    fprintf('  Y: %.3f ~ %.3f mm\n', min(points(:,2)), max(points(:,2)));
    fprintf('  Z: %.3f ~ %.3f mm\n', min(points(:,3)), max(points(:,3)));
    
    % 显示前几行数据
    fprintf('\n前5行数据预览:\n');
    disp(data_table(1:5, :));
    
    fprintf('\n现在可以运行 load_real_data_example() 来处理这个数据文件。\n');
end

function points = generate_realistic_measurement_data()
    % 生成更真实的测量数据
    % 模拟实际的三坐标测量机或激光扫描仪数据
    
    % 真实圆柱参数
    true_center = [0.12, -0.08];     % 中心偏移（模拟装夹误差）
    true_axis = [0.015, -0.008, 1];  % 轴线倾斜（模拟装夹倾斜）
    true_axis = true_axis / norm(true_axis);
    true_radius = 12.5;              % 12.5mm标准半径
    
    % 测量参数
    n_sections = 10;                 % 10个截面
    n_points_per_section = 24;       % 每个截面24个点（15度间隔）
    z_range = [0, 60];               % 60mm长度
    
    points = [];
    
    for section = 1:n_sections
        z = z_range(1) + (z_range(2) - z_range(1)) * (section-1) / (n_sections-1);
        
        for point = 1:n_points_per_section
            theta = 2 * pi * (point-1) / n_points_per_section;
            
            % 理想圆上的点
            x_ideal = true_center(1) + true_radius * cos(theta);
            y_ideal = true_center(2) + true_radius * sin(theta);
            
            % 考虑轴线倾斜
            x = x_ideal + true_axis(1) * z;
            y = y_ideal + true_axis(2) * z;
            
            % 添加各种误差
            
            % 1. 测量系统误差（高精度测量机约1-2μm）
            measurement_accuracy = 0.001;
            x = x + measurement_accuracy * randn();
            y = y + measurement_accuracy * randn();
            z = z + measurement_accuracy * randn();
            
            % 2. 工件形状误差
            
            % 椭圆度误差（2次谐波）
            ellipticity_amplitude = 0.005;
            ellipticity_phase = pi/6; % 椭圆长轴方向
            ellipticity_error = ellipticity_amplitude * cos(2*theta + ellipticity_phase);
            x = x + ellipticity_error * cos(theta);
            y = y + ellipticity_error * sin(theta);
            
            % 三角度误差（3次谐波）
            triangularity_amplitude = 0.002;
            triangularity_error = triangularity_amplitude * cos(3*theta);
            x = x + triangularity_error * cos(theta);
            y = y + triangularity_error * sin(theta);
            
            % 锥度误差（线性变化）
            taper_rate = 0.0002; % 0.02% 锥度
            radius_at_z = true_radius * (1 - taper_rate * z / z_range(2));
            scale_factor = radius_at_z / true_radius;
            x = true_center(1) + (x - true_center(1)) * scale_factor;
            y = true_center(2) + (y - true_center(2)) * scale_factor;
            
            % 鼓形误差（二次变化）
            barrel_amplitude = 0.003;
            z_normalized = (z - mean(z_range)) / (z_range(2) - z_range(1));
            barrel_factor = 1 + barrel_amplitude * (1 - 4 * z_normalized^2);
            x = true_center(1) + (x - true_center(1)) * barrel_factor;
            y = true_center(2) + (y - true_center(2)) * barrel_factor;
            
            % 3. 表面粗糙度和波纹度
            
            % 表面粗糙度（高频随机）
            surface_roughness = 0.0005;
            x = x + surface_roughness * randn();
            y = y + surface_roughness * randn();
            
            % 加工波纹（中频周期性）
            waviness_amplitude = 0.001;
            waviness_frequency = 8; % 8个波纹/圈
            waviness_error = waviness_amplitude * sin(waviness_frequency * theta);
            x = x + waviness_error * cos(theta);
            y = y + waviness_error * sin(theta);
            
            % 4. 系统性测量偏差
            
            % 温度影响（热膨胀）
            temp_coefficient = 11.5e-6; % 钢的线膨胀系数
            temp_variation = 2; % 2度温差
            thermal_expansion = 1 + temp_coefficient * temp_variation;
            x = x * thermal_expansion;
            y = y * thermal_expansion;
            
            % 探头半径补偿误差
            probe_radius_error = 0.0005;
            distance_from_center = sqrt((x - true_center(1))^2 + (y - true_center(2))^2);
            if distance_from_center > 0
                compensation_factor = (distance_from_center + probe_radius_error) / distance_from_center;
                x = true_center(1) + (x - true_center(1)) * compensation_factor;
                y = true_center(2) + (y - true_center(2)) * compensation_factor;
            end
            
            % 5. 偶然的大误差点（模拟测量异常）
            if rand() < 0.02 % 2%的概率出现异常点
                outlier_magnitude = 0.05;
                x = x + outlier_magnitude * (rand() - 0.5);
                y = y + outlier_magnitude * (rand() - 0.5);
            end
            
            points = [points; x, y, z];
        end
    end
    
    % 添加一些额外的随机分布点（模拟不规则测量）
    n_random_points = 20;
    for i = 1:n_random_points
        z = z_range(1) + (z_range(2) - z_range(1)) * rand();
        theta = 2 * pi * rand();
        
        % 在圆柱面附近生成点
        r = true_radius + 0.01 * randn(); % 半径有小的变化
        x = true_center(1) + r * cos(theta) + true_axis(1) * z;
        y = true_center(2) + r * sin(theta) + true_axis(2) * z;
        
        % 添加测量噪声
        x = x + 0.001 * randn();
        y = y + 0.001 * randn();
        z = z + 0.001 * randn();
        
        points = [points; x, y, z];
    end
    
    fprintf('生成了 %d 个测量点\n', size(points, 1));
    fprintf('包含以下误差类型:\n');
    fprintf('  - 测量系统误差 (±1μm)\n');
    fprintf('  - 椭圆度误差 (±5μm)\n');
    fprintf('  - 三角度误差 (±2μm)\n');
    fprintf('  - 锥度误差 (0.02%%)\n');
    fprintf('  - 鼓形误差 (±3μm)\n');
    fprintf('  - 表面粗糙度 (±0.5μm)\n');
    fprintf('  - 加工波纹 (±1μm)\n');
    fprintf('  - 热膨胀影响\n');
    fprintf('  - 探头补偿误差\n');
    fprintf('  - 随机异常点 (2%%)\n');
end