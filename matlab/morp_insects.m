clear all;
close all;

scale = 1e-2;

m_total = 1648*1e-6;
m_R = 47*1e-6;
R = 51.9*1e-3 / scale;
c_bar = 18.26*1e-3 / scale;

freq = 26.3;
C_T = 1.678;
C_D_0 = 0.07;
C_D_pi2 = 3.06;

m_monarch = 3.0790e-04;
len_ratio = (m_total / m_monarch)^(1/3);

m_B = 3/5 * (m_total - 2*m_R);
h_B = 1.463e-2 * len_ratio;
w_B = 5.680e-3 * len_ratio;
m_A = 2/5 * (m_total - 2*m_R);
h_A = 1.738e-2 * len_ratio; 
w_A = 3.710e-3 * len_ratio;

N = 15;
span_wholewing = linspace(0, R, N);
chord_wholewing = 4*c_bar/pi * sqrt(1 - span_wholewing.^2 / R^2);
chord_LE = 2*c_bar/pi * sqrt(1 - span_wholewing.^2 / R^2);
chord_TE = -2*c_bar/pi * sqrt(1 - span_wholewing.^2 / R^2);
cr_poly = polyfit(span_wholewing,chord_wholewing,6);
cr_LE_poly = polyfit(span_wholewing,chord_LE,6);
cr_TE_poly = polyfit(span_wholewing,chord_TE,6);

%% compute area / volume moment
% definite integral of a polynomial over an interval
polyint_def=@(poly, interval) diff(polyval(polyint(poly), interval));

l=max(span_wholewing) % right wing length
S = polyint_def(cr_poly, [0 l]) % right wing area
AR = l^2/S
c_bar = S / l

cr_bar_poly = cr_poly.*(l.^(length(cr_poly)-1:-1:0)) /c_bar;

S_1 = polyint_def( conv(cr_poly,[1 0]), [0 l])
tilde_r_1 = S_1/S/l
disp('err');
disp(S_1/S/l- polyint_def( conv(cr_bar_poly,[1 0]), [0 1]))

S_2 = polyint_def( conv(cr_poly,[1 0 0]), [0 l])
tilde_r_2 = (S_2/S/l^2)^(1/2)
disp(tilde_r_2 - (polyint_def( conv(cr_bar_poly,[1 0 0]) ,[0 1]))^(1/2))

S_3 = polyint_def( conv(cr_poly,[1 0 0 0]), [0 l])
tilde_r_3 = (S_3/S/l^3)^(1/3)
disp(tilde_r_3 - (polyint_def( conv(cr_bar_poly,[1 0 0 0]) ,[0 1]))^(1/3))

tilde_v = polyint_def( conv(cr_bar_poly,cr_bar_poly) ,[0 1])
tilde_r_v_1 = 1/tilde_v* polyint_def( conv(conv(cr_bar_poly,cr_bar_poly),[1 0]), [0 1])
disp('err');
disp(polyint_def( conv(conv(cr_poly,cr_poly),[1 0]), [0 l]) /l^2 /c_bar^2 /tilde_v - tilde_r_v_1)
tilde_r_v_2 = (1/tilde_v* polyint_def( conv(conv(cr_bar_poly,cr_bar_poly),[1 0 0]), [0 1]))^(1/2)
disp('err');
disp(polyint_def( conv(conv(cr_poly,cr_poly),[1 0 0]), [0 l]) /l^3 /c_bar^2 /tilde_v - tilde_r_v_2^2)

%% compute momnet of inertia

J_R_xx = m_R/S * polyint_def( conv(cr_LE_poly-cr_TE_poly,[1 0 0]), [0 l]) * scale^2;
cr_LE_poly_pow2 = conv(cr_LE_poly,cr_LE_poly);
cr_TE_poly_pow2 = conv(cr_TE_poly,cr_TE_poly);
J_R_xy = - m_R/S * polyint_def( 0.5* conv(cr_LE_poly_pow2 - cr_TE_poly_pow2, [1 0]), [0 l])* scale^2;
cr_LE_poly_pow3 = conv(cr_LE_poly_pow2,cr_LE_poly);
cr_TE_poly_pow3 = conv(cr_TE_poly_pow2,cr_TE_poly);
J_R_yy = m_R/S * polyint_def( 1/3* (cr_LE_poly_pow3 - cr_TE_poly_pow3), [0 l])* scale^2;
J_R_zz = J_R_xx + J_R_yy;

nu_R_x = 1/S * polyint_def( 0.5* (cr_LE_poly_pow2 - cr_TE_poly_pow2), [0 l])* scale
nu_R_y = 1/S * polyint_def( 0.5* conv(cr_LE_poly - cr_TE_poly, [1 0]), [0 l])* scale
nu_R = [nu_R_x nu_R_y 0]';
nu_L = [nu_R_x -nu_R_y 0]';
nu_A = [-h_A/2, 0, 0]';

J_R = [J_R_xx J_R_xy 0;
    J_R_xy J_R_yy 0
    0 0 J_R_zz];

J_L = [J_R_xx -J_R_xy 0;
    -J_R_xy J_R_yy 0
    0 0 J_R_zz];

J_B_xx = 1/8*m_B*w_B^2;
J_B_yy = m_B*(1/16*w_B^2 + 1/12*h_B^2);
J_B_zz = J_B_yy;
J_B = diag([J_B_xx J_B_yy J_B_zz]);

J_A_xx = 1/8*m_A*w_A^2;
J_A_yy = m_A*(1/16*w_A^2 + 1/3*h_A^2);
J_A_zz = J_A_yy;
J_A = diag([J_A_xx J_A_yy J_A_zz]);

% N=5000;
% ys=linspace(0,l,N);
% Dy=ys(2)-ys(1);
% tmp=zeros(3,1);
% for k=1:N        
%     c_LE=polyval(cr_LE_poly,ys(k));
%     c_TE=polyval(cr_TE_poly,ys(k));
%     y=ys(k);
%     tmp(1)=tmp(1)+y^2*(c_LE-c_TE)*Dy;
%     tmp(2)=tmp(2)+-0.5*y*(c_LE^2-c_TE^2)*Dy;
%     tmp(3)=tmp(3)+1/3*(c_LE^3-c_TE^3)*Dy;
% end
% tmp*m_R*scale^2/S  

%% plot chord
figure;
N=501;
r=linspace(0,l,N);
cr=polyval(cr_poly,r);
c_LE=polyval(cr_LE_poly,r);
c_TE=polyval(cr_TE_poly,r);
r_bar=linspace(0,1,N);
cr_bar=polyval(cr_bar_poly*c_bar,r_bar);
plot(r,cr,'r',span_wholewing,chord_wholewing,'r.');
hold on;
plot(r,cr_bar,'b:');
xlabel('$r\;(\mathrm{cm})$','interpreter','latex');
ylabel('$c\;(\mathrm{cm})$','interpreter','latex');

figure;
plot(r,c_LE,'r', span_wholewing,chord_LE,'r.');
hold on;
plot(r,c_TE,'b', span_wholewing,chord_TE,'b.');
xlabel('$r\;(\mathrm{cm})$','interpreter','latex');
ylabel('$c_{LE}, c_{TE}\;(\mathrm{cm})$','interpreter','latex');
axis equal;

bool_print=0;
if bool_print
    figure(1);print('MONARCH_c','-depsc');
    figure(2);print('MONARCH_c_LE_TE','-depsc');
    !cp *.eps ../doc/Figs
end

%% save the computed morphological parameters into a structure variable

HAWKMOTH.scale = scale;
HAWKMOTH.f = freq;
HAWKMOTH.C_T = C_T;
HAWKMOTH.C_D_0 = C_D_0;
HAWKMOTH.C_D_pi2 = C_D_pi2;

HAWKMOTH.rho = 1.225; % air density (kg/m^3)
HAWKMOTH.g = 9.81; % air density (kg/m^3)
HAWKMOTH.l = l*scale; % span of the right wing (m)
HAWKMOTH.S = S*scale^2; % area of the right wing (m^2)
HAWKMOTH.c_bar = HAWKMOTH.S / HAWKMOTH.l; % mean chord (m)
HAWKMOTH.AR = AR;

HAWKMOTH.m_B = m_B; % mass of body/thorax
HAWKMOTH.h_B = h_B; % height of body/thorax
HAWKMOTH.w_B = w_B; % width of body/thorax
HAWKMOTH.m_A = m_A; % mass of abdomen
HAWKMOTH.h_A = h_A; % height of abdomen
HAWKMOTH.w_A = w_A; % width of abdomen
HAWKMOTH.m_R = m_R; % mass of right wing
HAWKMOTH.m_L = m_R; % mass of left wing
HAWKMOTH.m = m_B + m_A + 2*m_R;

HAWKMOTH.J_B = J_B;
HAWKMOTH.J_R = J_R;
HAWKMOTH.J_A = J_A;
HAWKMOTH.J_L = J_L;

HAWKMOTH.nu_R = nu_R;
HAWKMOTH.nu_A = nu_A;
HAWKMOTH.nu_L = nu_L;

HAWKMOTH.mu_R = [0, w_B/2, 0]';
HAWKMOTH.mu_L = [0, -w_B/2, 0]';
HAWKMOTH.mu_A = [-h_B/2, 0, 0]';

HAWKMOTH.tilde_r_1 = tilde_r_1; % non-dimensional radius of the first moment of wing area
HAWKMOTH.tilde_r_2 = tilde_r_2; % non-dimensional radius of the second moment of wing area
HAWKMOTH.tilde_r_3 = tilde_r_3; % non-dimensional radius of the thrid moment of wing area 
HAWKMOTH.r_cp = HAWKMOTH.l * HAWKMOTH.tilde_r_3 / HAWKMOTH.tilde_r_2; % CP of the translational force (lift and drag) (m)

HAWKMOTH.tilde_v = tilde_v; % non-dimensional virtual mass 
HAWKMOTH.tilde_r_v_1 = tilde_r_v_1; % non-dimensional radius of the first moment of wing volume 
HAWKMOTH.tilde_r_v_2 = tilde_r_v_2; % non-dimensional radius of the second moment of wing volume 
HAWKMOTH.r_rot = HAWKMOTH.l * HAWKMOTH.tilde_r_v_2^2 / HAWKMOTH.tilde_r_v_1; % CP of the rotational force (m)

HAWKMOTH.cr_poly = cr_poly;
HAWKMOTH.cr_LE_poly = cr_LE_poly;
HAWKMOTH.cr_TE_poly = cr_TE_poly;
disp(HAWKMOTH);

save('morp_others','HAWKMOTH');
