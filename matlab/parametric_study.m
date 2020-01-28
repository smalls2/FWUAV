function parametric_study
% Simulate the effects on aerodynamic forces when changing wing kinematic
% parameters considering just the position dynamics

evalin('base','clear all');
close all;
addpath('./modules', './sim_data');
load('sim_QS_x_hover.mat',...
    'INSECT', 'WK', 'X0');
filename='parametric_study';

N=501;
T=1/WK.f;
t=linspace(0,T,N);

% N_params = 1;
N_params = 10;
eps = logspace(log10(0.0001), log10(0.1), N_params);
f_aero = zeros(3, 3, N, N_params);
f_a_m = zeros(3, 3, N_params, 2);

parfor i=1:N_params
    f_aero(:, :, :, i) = param_study(INSECT, WK, eps, i, t, X0, N);
    f_aero1 = f_aero(:, :, :, i); f_aero2 = f_aero(:, :, :, i);
    f_aero1(f_aero1 < 0) = 0;
    f_aero2(f_aero2 > 0) = 0;
    
    f_a_m_temp = zeros(size(f_a_m(:, :, i, :)));
    f_a_m_temp(:, :, 1, 1) = mean(f_aero1, 3);
    f_a_m_temp(:, :, 1, 2) = mean(f_aero2, 3);
    f_a_m(:, :, i, :) = f_a_m_temp;
end
f_a_m = abs(f_a_m);

%%
h_f_a = figure;
h_f_a.PaperUnits = 'inches';
h_f_a.PaperPosition = [0 0 12 9];
%
subplot(3,3,1);
plot(eps, squeeze(f_a_m(1,1,:,1)));
hold on;
plot(eps, squeeze(f_a_m(1,1,:,2)), 'r');
legend('Positive component', 'Negative component');
% scatter(eps, squeeze(f_a_m(1,1,:,1)), 10, 'k', 'filled');
ylabel('mean $f_a(1)$','interpreter','latex');

subplot(3,3,4);
plot(eps, squeeze(f_a_m(1,2,:,1)));
hold on;
plot(eps, squeeze(f_a_m(1,2,:,2)), 'r');
ylabel('mean $f_a(2)$','interpreter','latex');

subplot(3,3,7);
% plot(eps, squeeze(f_a_m(1,3,:,1)));
% hold on;
plot(eps, squeeze(f_a_m(1,3,:,2)), 'r');
xlabel('$\epsilon\ \vert\ \Delta\phi_{m, R} = \epsilon, \Delta\phi_{m, L} = \epsilon$','interpreter','latex');
ylabel('mean $f_a(3)$','interpreter','latex');
%
subplot(3,3,2);
plot(eps, squeeze(f_a_m(2,1,:,1)));
hold on;
plot(eps, squeeze(f_a_m(2,1,:,2)), 'r');
legend('Positive component', 'Negative component');

subplot(3,3,5);
plot(eps, squeeze(f_a_m(2,2,:,1)));
hold on;
plot(eps, squeeze(f_a_m(2,2,:,2)), 'r');

subplot(3,3,8);
plot(eps, squeeze(f_a_m(2,3,:,2)), 'r');
xlabel('$\epsilon\ \vert\ \Delta\theta_{m, R} = \epsilon, \Delta\theta_{m, L} = \epsilon$','interpreter','latex');
%
subplot(3,3,3);
plot(eps, squeeze(f_a_m(3,1,:,1)));
hold on;
plot(eps, squeeze(f_a_m(3,1,:,2)), 'r');
legend('Positive component', 'Negative component');

subplot(3,3,6);
plot(eps, squeeze(f_a_m(3,2,:,1)));
hold on;
plot(eps, squeeze(f_a_m(3,2,:,2)), 'r');

subplot(3,3,9);
plot(eps, squeeze(f_a_m(3,3,:,2)), 'r');
% xlabel('$\epsilon\ \vert\ \Delta\psi_{m, R} = \epsilon, \Delta\psi_{m, L} = -\epsilon$','interpreter','latex');
xlabel('$\epsilon\ \vert\ \Delta\phi_{m, R} = \epsilon, \Delta\phi_{m, L} = -\epsilon$','interpreter','latex');
%
% print(h_f_a, 'hover_param_study', '-depsc', '-r0');

% Get a list of all variables
allvars = whos;
% Identify the variables that ARE NOT graphics handles. This uses a regular
% expression on the class of each variable to check if it's a graphics object
tosave = cellfun(@isempty, regexp({allvars.class}, '^matlab\.(ui|graphics)\.'));
% Pass these variable names to save
save(filename, allvars(tosave).name)
evalin('base',['load ' filename]);
end

function f_aero = param_study(INSECT, WK, eps, i, t, X0, N)
%%
    f_aero = zeros(3, 3, N);
    %
    WK_R = WK;  WK_L = WK;
    WK_R.phi_m = WK_R.phi_m + eps(i);
    WK_L.phi_m = WK_L.phi_m + eps(i);
    f_aero(1, :, :) = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N);
    %
    WK_R = WK;  WK_L = WK;
    WK_R.theta_m = WK_R.theta_m + eps(i);
    WK_L.theta_m = WK_L.theta_m + eps(i);
    f_aero(2, :, :) = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N);
    %
    WK_R = WK;  WK_L = WK;
%     WK_R.psi_0 = WK_R.psi_0 + eps(i);
%     WK_L.psi_0 = WK_L.psi_0 - eps(i);
    WK_R.phi_m = WK_R.phi_m + eps(i);
    WK_L.phi_m = WK_L.phi_m - eps(i);
    f_aero(3, :, :) = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N);
end

function f_aero = aerodynamic_force(INSECT, WK_R, WK_L, t, X0, N)
%%
    [t,X]=ode45(@(t,X) eom(INSECT, WK_R, WK_L, t, X), t, X0, odeset('AbsTol',1e-6,'RelTol',1e-6));

%     x=X(:,1:3)';
%     x_dot=X(:,4:6)';

    for k=1:N    
        [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, f_a(:,k)]= eom(INSECT, WK_R, WK_L, t(k), X(k,:)');
    end
    f_aero = f_a(1:3, :);
end

function [X_dot R Q_R Q_L Q_A theta_B theta_A W W_dot W_R W_R_dot W_L W_L_dot W_A W_A_dot F_R F_L M_R M_L f_a f_g f_tau tau]= eom(INSECT, WK_R, WK_L, t, X)
%%
x=X(1:3);
x_dot=X(4:6);

% wing/abdoment attitude and aerodynamic force/moment
[Euler_R, Euler_R_dot, Euler_R_ddot] = wing_kinematics(t,WK_R);
[Euler_L, Euler_L_dot, Euler_L_ddot] = wing_kinematics(t,WK_L);
[Q_R Q_L W_R W_L W_R_dot W_L_dot] = wing_attitude(WK_R.beta, Euler_R, Euler_L, Euler_R_dot, Euler_L_dot, Euler_R_ddot, Euler_L_ddot);

[R W W_dot theta_B] = body_attitude(t, WK_R.f, WK_R); % body
[Q_A W_A W_A_dot theta_A] = abdomen_attitude(t, WK_R.f, WK_R); % abdomen

[L_R L_L D_R D_L M_R M_L ...
    F_rot_R F_rot_L M_rot_R M_rot_L]=wing_QS_aerodynamics(INSECT, W_R, W_L, W_R_dot, W_L_dot, x_dot, R, W, Q_R, Q_L);
F_R=L_R+D_R+F_rot_R;
F_L=L_L+D_L+F_rot_L;
M_R=M_R+M_rot_R;
M_L=M_L+M_rot_L;
M_A=zeros(3,1);

f_a=[R*Q_R*F_R + R*Q_L*F_L;
    hat(INSECT.mu_R)*Q_R*F_R + hat(INSECT.mu_L)*Q_L*F_L;
    M_R;
    M_L;
    M_A];
f_a_1=f_a(1:3);
f_a_2=f_a(4:15);

% gravitational force and moment
[~, dU]=potential(INSECT,x,R,Q_R,Q_L,Q_A);
f_g=-dU;
f_g_1=f_g(1:3);
f_g_2=f_g(4:15);

% Euler-Lagrange equation
xi_1=[x_dot]; 
xi_2=[W; W_R; W_L; W_A];
xi_2_dot=[W_dot; W_R_dot; W_L_dot; W_A_dot];

[JJ KK] = inertia(INSECT, R, Q_R, Q_L, Q_A, x_dot, W, W_R, W_L, W_A);
LL = KK - 0.5*KK';
co_ad=blkdiag(zeros(3,3), -hat(W), -hat(W_R), -hat(W_L), -hat(W_A));

[JJ_11 JJ_12 JJ_21 JJ_22] = inertia_sub_decompose_3_12(JJ);
[LL_11 LL_12 LL_21 LL_22] = inertia_sub_decompose_3_12(LL);
[co_ad_11, ~, ~, co_ad_22] = inertia_sub_decompose_3_12(co_ad);

xi_1_dot = JJ_11\( -JJ_12*xi_2_dot -LL_11*xi_1 - LL_12*xi_2 + f_a_1 + f_g_1);

f_tau_2 = JJ_21*xi_1_dot + JJ_22*xi_2_dot - co_ad_22*(JJ_21*xi_1 + JJ_22*xi_2) ...
    + LL_21*xi_1 + LL_22*xi_2 - f_a_2 - f_g_2;
f_tau = [zeros(3,1); f_tau_2];
tau = blkdiag(zeros(3), Q_R, Q_L, Q_A)*f_tau_2;

X_dot=[xi_1; xi_1_dot];
end
