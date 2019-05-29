function [Euler, Euler_dot, Euler_ddot] = wing_kinematics(t,WK)
%wing_kinematics: compute wing Euler angles and their time-derivaties
%
% [Euler, Euler_dot, Euler_ddot] = wing_kinematics(t,WK) computes
%
%       Euler = [phi theta psi]' (flapping, pitch, deviation)
%
%for a given time and a struct variables with the following members
%describing wing kinematics
%
%         WK.f, Wk.beta
%         WK.phi_m, WK.phi_K, WK.phi_0
%         WK.theta_m, WK.theta_C, WK.theta_0, WK.theta_a
%         WK.psi_m, WK.psi_N, WK.psi_a, WK.psi_0
%

switch WK.type
    case 'Monarch'
        
%         % Data constructed by ./exp_data/fit_exp_data.m
%         F_phi.A0=-1.0753;
%         F_phi.AN=[57.7197 4.1946 -1.2126 0.7185 -0.1899];
%         F_phi.BN=[-8.0267 9.8466 -3.3232 -0.7831 0.2093];
%         F_theta.A0=-12.4021;
%         F_theta.AN=[22.1344 -5.9493 1.7797 1.9392 -0.8983];
%         F_theta.BN=[29.7924 7.9076 -8.2981 2.3268 -0.2061];
%         F_psi.A0=11.7597;
%         F_psi.AN=[16.4326 -3.2083 -1.2771 0.1997 -0.1899];
%         F_psi.BN=[-2.1653 -2.0058 -0.7918 0.0527 0.1601];
% 
%         [phi phi_dot phi_ddot]=eval_Fourier(t, WK.f, F_phi);
%         [theta theta_dot theta_ddot]=eval_Fourier(t, WK.f, F_theta);
%         [psi psi_dot psi_ddot]=eval_Fourier(t, WK.f, F_psi);
        
        % Data constructed by ./exp_data/fit_VICON_data.m
        F_phi.f = 10.2247;
        F_phi.A0 = -0.83724;
        F_phi.AN = [59.7558745992612 -0.137466978762473 0.137978226025185 0.433746159939459 -0.074830919096204];
        F_phi.BN = [-6.55441083419535 6.435543953825 -2.05072909120033 0.221239708063663 0.0575790280561444];
        F_theta.f = 10.1838;
        F_theta.A0 = -5.9583;
        F_theta.AN = [24.0863053541935 -4.46860932682531 8.04218451917262 -0.601926108817941 -0.642171907559121];
        F_theta.BN = [30.5848624271628 4.64142325712464 -3.83504323967398 2.01570854870463 -1.70930433046515];
        F_psi.f = 20.2767;
        F_psi.A0 = -1.9753;
        F_psi.AN = -2.063160749463;
        F_psi.BN = -2.60158935092774;
        [phi phi_dot phi_ddot]=eval_Fourier(t, WK.f, F_phi);
        [theta theta_dot theta_ddot]=eval_Fourier(t, WK.f, F_theta);
        [psi psi_dot psi_ddot]=eval_Fourier(t, 2*WK.f, F_psi);

        %case 'BermanWang'
    otherwise
        % phi / flapping
        A=WK.phi_m / asin(WK.phi_K);
        a=WK.phi_K;
        b=2*pi*WK.f;
        
        phi = A*asin( a * cos(b*t)) + WK.phi_0;
        phi_dot = -(A*a*b*sin(b*t))/(1 - a^2*cos(b*t)^2)^(1/2);
        phi_ddot = (A*a*b^2*cos(b*t)*(a^2 - 1))/(1 - a^2*cos(b*t)^2)^(3/2);
        
        % theta / pitching
        A=WK.theta_m / tanh(WK.theta_C);
        a=WK.theta_C;
        b=2*pi*WK.f;
        c=WK.theta_a;
        
        theta = A * tanh( a * sin(b*t + c) ) + WK.theta_0;
        theta_dot = -A*a*b*cos(c + b*t)*(tanh(a*sin(c + b*t))^2 - 1);
        theta_ddot = A*a*b^2*(tanh(a*sin(c + b*t))^2 - 1)*(sin(c + b*t) + 2*a*cos(c + b*t)^2*tanh(a*sin(c + b*t)));
        
        %  psi / deviation
        A=WK.psi_m;
        a=2*pi*WK.psi_N*WK.f;
        b=WK.psi_a;
        
        psi = A * cos( a*t + b ) + WK.psi_0;
        psi_dot  = A * -a * sin(a*t+b);
        psi_ddot = A * -a^2 * cos(a*t+b);
        
        
end

%% return values
Euler=[phi theta psi]';
Euler_dot=[phi_dot theta_dot psi_dot]';
Euler_ddot=[phi_ddot theta_ddot psi_ddot]';
end

function [a a_dot a_ddot]= eval_Fourier(t, f, F)
a=F.A0;
a_dot=0;
a_ddot=0;

for q = 1:length(F.AN)
    a = a + F.AN(q)*cos(2*pi*q*f*t) + F.BN(q)*sin(2*pi*q*f*t);
    a_dot = a_dot -(2*pi*q*f)*F.AN(q)*sin(2*pi*q*f*t) + ...
        (2*pi*q*f)*F.BN(q)*cos(2*pi*q*f*t);
    a_ddot = a_ddot -(2*pi*q*f)^2*F.AN(q)*cos(2*pi*q*f*t) - ...
        (2*pi*q*f)^2*F.BN(q)*sin(2*pi*q*f*t);
    
end

a=a*pi/180;
a_dot=a_dot*pi/180;
a_ddot=a_ddot*pi/180;
end

