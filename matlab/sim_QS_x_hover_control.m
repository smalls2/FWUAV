function sim_QS_x_hover_control
% simulate the thorax (x) trajectory along with a controller for
% given thorax attiude, wing kinematics, abdomen attitude.

evalin('base','clear all');
close all;
addpath('./modules', './sim_data', './plotting');
des=load('sim_QS_x_hover.mat',...
    'INSECT', 't', 'N', 'x', 'x_dot', 'R', 'Q_R', 'Q_L', 'W_R', 'W_L', 'f_tau',...
    'x0', 'x_dot0', 'Q_A', 'WK', 'x_ddot', 'f_a');

filename='sim_QS_x_hover_control';
INSECT = des.INSECT;
WK = des.WK;
des.x_fit = cell(3, 1); des.x_dot_fit = cell(3, 1); des.f_a_fit = cell(3, 1);
% 'fourier8', 'cubicinterp'
for i=1:3
    des.x_fit{i} = fit(des.t, des.x(i, :)', 'fourier8');
    des.x_dot_fit{i} = fit(des.t, des.x_dot(i, :)', 'fourier8');
    des.f_a_fit{i} = fit(des.t, des.f_a(i, :)', 'fourier8');
end

% Values obtained from parametric study
des.df_a_1_by_dphi_m = 0.54e-3 / 0.1; % dphi_m_R > 0, dphi_m_L > 0
des.df_a_1_by_dtheta_m = -0.6e-3 / 0.1; % dtheta_m_R > 0, dtheta_m_L > 0
des.df_a_2_by_dpsi_m = 0.3e-3 / 0.1; % dpsi_m_R > 0, dpsi_m_L < 0
des.df_a_3_by_dphi_m = 0.47e-3 / 0.1; % dphi_m_R > 0, dphi_m_L > 0
des.df_a_2_by_dphi_m = 3.5e-4 / 0.1; % dphi_m_R > 0, dphi_m_L < 0

eps1 = 1e-3; eps2 = 1e-2;
x0 = des.x0 + rand(3,1)*eps1;
x_dot0 = des.x_dot0 + rand(3,1)*eps2;
X0 = [x0; x_dot0;];
N = 2001;
N_period = 10;
N_single = round((N-1)/N_period);
T = N_period/WK.f;
t = linspace(0,T,N);

%% Optimization
% g0 = [gains.Kp_pos, gains.Kd_pos, gains.Ki_pos];
% lb = [-1000, -1000, -100];
% ub = [1000, 1000, 100];
% tic;
% % rng default; % For reproducibility
% options = optimoptions(@surrogateopt, 'InitialPoints', g0,...
%     'MaxFunctionEvaluations', 50000, 'MaxTime', 10000, ...
%     'PlotFcn', @surrogateoptplot);
% [gs, fval, exitflag, output] = surrogateopt(@(gs) obtain_err_gains(gs, WK, INSECT, des, X0, N, t), lb, ub, options);
% fprintf('Optimization has been completed\n');
% disp(fval);
% disp(output);
% toc;
gs = [427.1529   15.6076  13.4983];

%% Simulation
pol = poly([-7.8 + 19i, -7.8 - 19i, -0.003]);
if ~all(real(roots(pol)) < 0)
    error('The chosen gains are not suitable');
end
gains.Kp_pos = pol(3); gains.Kd_pos = pol(2); gains.Ki_pos = pol(4);

% [t, X]=ode45(@(t,X) eom(INSECT, WK, WK, t, X, des, gains, i), t, X0, odeset('AbsTol',1e-6,'RelTol',1e-6));

X = zeros(N, 9);
X(1, :) = [X0; zeros(3, 1)];
dt = t(2) - t(1);
% % Explicit RK4
for i=1:(N-1)
%     if mod(i-1, N_single) == 0
%         x0 = X(i, 1:3)';
%     end
    if i == 1
        f_a_im1 = zeros(3, 1);
    else
        f_a_im1 = f_a(1:3, i-1);
    end
    %
    [X_dot(:,i), R(:,:,i) Q_R(:,:,i) Q_L(:,:,i) Q_A(:,:,i) theta_B(i) theta_A(i) ...
        W(:,i) W_dot(:,i) W_R(:,i) W_R_dot(:,i) W_L(:,i) W_L_dot(:,i) W_A(:,i) ...
        W_A_dot(:,i) F_R(:,i) F_L(:,i) M_R(:,i) M_L(:,i) f_a(:,i) f_g(:,i) ...
        f_tau(:,i) tau(:,i) Euler_R(:,i) Euler_R_dot(:,i) pos_err(:, i)]... 
        = eom(INSECT, WK, WK, t(i), X(i,:)', des, gains, i, x0, f_a_im1);
    X(i+1, :) = X(i, :) + dt * X_dot(:, i)';
end
i = i + 1;
[X_dot(:,i), R(:,:,i) Q_R(:,:,i) Q_L(:,:,i) Q_A(:,:,i) theta_B(i) theta_A(i) ...
        W(:,i) W_dot(:,i) W_R(:,i) W_R_dot(:,i) W_L(:,i) W_L_dot(:,i) W_A(:,i) ...
        W_A_dot(:,i) F_R(:,i) F_L(:,i) M_R(:,i) M_L(:,i) f_a(:,i) f_g(:,i) ...
        f_tau(:,i) tau(:,i) Euler_R(:,i) Euler_R_dot(:,i) pos_err(:, i)]... 
        = eom(INSECT, WK, WK, t(i), X(i,:)', des, gains, i, x0, f_a_im1);

x=X(:,1:3)';
x_dot=X(:,4:6)';

%%
% Get a list of all variables
allvars = whos;
% Identify the variables that ARE NOT graphics handles. This uses a regular
% expression on the class of each variable to check if it's a graphics object
tosave = cellfun(@isempty, regexp({allvars.class}, '^matlab\.(ui|graphics)\.'));
% Pass these variable names to save
save(filename, allvars(tosave).name)
evalin('base',['load ' filename]);

end

function err =  obtain_err_gains(gs, WK, INSECT, des, X0, N, t)
%%
    gains.Kp_pos = gs(1);
    gains.Kd_pos = gs(2);
    gains.Ki_pos = gs(3);

    X = zeros(N, 9);
    X(1, :) = [X0; zeros(3, 1)];
    dt = t(2) - t(1);
    for i=1:(N-1)
        if i == 1
            f_a_im1 = zeros(3, 1);
        else
            f_a_im1 = f_a(1:3, i-1);
        end
        [X_dot(:,i), R(:,:,i) Q_R(:,:,i) Q_L(:,:,i) Q_A(:,:,i) theta_B(i) theta_A(i) ...
            W(:,i) W_dot(:,i) W_R(:,i) W_R_dot(:,i) W_L(:,i) W_L_dot(:,i) W_A(:,i) ...
            W_A_dot(:,i) F_R(:,i) F_L(:,i) M_R(:,i) M_L(:,i) f_a(:,i) f_g(:,i) ...
            f_tau(:,i) tau(:,i) Euler_R(:,i) Euler_R_dot(:,i) pos_err(:, i)]... 
            = eom(INSECT, WK, WK, t(i), X(i,:)', des, gains, i, X0(1:3), f_a_im1);
        X(i+1, :) = X(i, :) + dt * X_dot(:, i)';
    end

    x=X(:,1:3)';
    x_dot=X(:,4:6)';

    err_pos = zeros(N, 3); err_vel = zeros(N, 3);
    for j=1:3
        err_pos(:, j) = des.x_fit{j}(t) - x(j, :)';
        err_vel(:, j) = des.x_dot_fit{j}(t) - x_dot(j, :)';
    end
    err_pos = vecnorm(err_pos, 2, 2);
    err_vel = vecnorm(err_vel, 2, 2);
    err_pos_dot = diff(err_pos)./diff(t');
    err_pos_dot = [err_pos_dot; err_pos_dot(end);];
    err_vel_dot = diff(err_vel)./diff(t');
    err_vel_dot = [err_vel_dot; err_vel_dot(end);];
    err_pos_dot = trapz(t', abs(err_pos_dot)) / max(t);
    err_vel_dot = trapz(t', abs(err_vel_dot)) / max(t);
    err_pos = trapz(t((N-1)/2:end)', err_pos((N-1)/2:end)) / max(t);
    err_vel = trapz(t((N-1)/2:end)', err_vel((N-1)/2:end)) / max(t);
    err = (1000*err_pos + 100*err_vel) + 0.01*(1000*err_pos_dot + 100*err_vel_dot);
    if isnan(err)
        err = 1e10;
    end
end

function [X_dot R Q_R Q_L Q_A theta_B theta_A W W_dot W_R W_R_dot W_L W_L_dot W_A W_A_dot F_R F_L M_R M_L f_a f_g f_tau tau Euler_R Euler_R_dot pos_err]= eom(INSECT, WK_R, WK_L, t, X, des, gains, i, x0, f_a_im1)
%% Dynamics along with the designed control

x=X(1:3);
x_dot=X(4:6);
int_d_x=X(7:9);

% Control design
d_x = zeros(3, 1); d_x_dot = zeros(3, 1);
for j=1:3
%     d_x(j) = des.x_fit{j}(t) - (x(j) - x0(j));
    d_x(j) = des.x_fit{j}(t) - x(j);
    d_x_dot(j) = des.x_dot_fit{j}(t) - x_dot(j);
end
pos_err = INSECT.m*(gains.Kp_pos * d_x + gains.Kd_pos * d_x_dot + gains.Ki_pos * int_d_x);
% dphi_m = sign(f_a_im1(3)) *  pos_err(3) / des.df_a_3_by_dphi_m;
% dtheta_m = sign(f_a_im1(1)) * (pos_err(1) - sign(f_a_im1(1)) * dphi_m * des.df_a_1_by_dphi_m) / des.df_a_1_by_dtheta_m;
% dpsi_m = sign(f_a_im1(2)) * pos_err(2) / des.df_a_2_by_dpsi_m;
dphi_m_R = sign(f_a_im1(3)) *  pos_err(3) / des.df_a_3_by_dphi_m + sign(f_a_im1(2)) * pos_err(2) / des.df_a_2_by_dphi_m;
dphi_m_L = sign(f_a_im1(3)) *  pos_err(3) / des.df_a_3_by_dphi_m - sign(f_a_im1(2)) * pos_err(2) / des.df_a_2_by_dphi_m;
dtheta_m = sign(f_a_im1(1)) * (pos_err(1) - sign(f_a_im1(1)) * (dphi_m_R+dphi_m_L)/2 * des.df_a_1_by_dphi_m) / des.df_a_1_by_dtheta_m;

WK_R.phi_m = WK_R.phi_m + dphi_m_R;
WK_L.phi_m = WK_L.phi_m + dphi_m_L;
WK_R.theta_m = WK_R.theta_m + dtheta_m;
WK_L.theta_m = WK_L.theta_m + dtheta_m;

X = X(1:6);
[X_dot, R, Q_R, Q_L, Q_A, theta_B, theta_A, W, W_dot, W_R, ...
    W_R_dot, W_L, W_L_dot, W_A, W_A_dot, F_R, F_L, M_R, M_L, f_a, f_g, ...
    f_tau, tau, Euler_R, Euler_R_dot] = eom_QS_x(INSECT, WK_R, WK_L, t, X);

X_dot=[X_dot; d_x;];

end