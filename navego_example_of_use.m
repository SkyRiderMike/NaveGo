% Example of use of NAVEGO. 
% Comparison of IMU ADIS16405 and IMU ADIS16488 performances
%
%   Copyright (C) 2014, Rodrigo Gonzalez, all rights reserved. 
%     
%   This file is part of NaveGo, an open-source MATLAB toolbox for 
%   simulation of integrated navigation systems.
%     
%   NaveGo is free software: you can redistribute it and/or modify
%   it under the terms of the GNU Lesser General Public License (LGPL) 
%   version 3 as published by the Free Software Foundation.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU Lesser General Public License for more details.
% 
%   You should have received a copy of the GNU Lesser General Public 
%   License along with this program. If not, see 
%   <http://www.gnu.org/licenses/>.
%
% Reference: 
%           R. Gonzalez, J. Giribet, and H. Patiño. NaveGo: a 
% simulation framework for low-cost integrated navigation systems, 
% Journal of Control Engineering and Applied Informatics, vol. 17, 
% issue 2, pp. 110-120, 2015. Eq. 26.
%
% Version: 001
% Date:    2014/09/18
% Author:  Rodrigo Gonzalez <rodralez@frm.utn.edu.ar>
% URL:     https://github.com/rodralez/navego 

clc
close all 
clear

fprintf('\nStarting simulation ... \n')

%% Global variables
global d2r

%% PARAMETERS

GPS_DATA      = 'ON';
IMU1_DATA     = 'ON';
IMU2_DATA     = 'ON';

IMU1_SINS     = 'ON';
IMU2_SINS     = 'ON';

RMSE          = 'ON';
PLOT          = 'ON';

if (~exist('GPS_DATA','var')),  GPS_DATA  = 'OFF'; end
if (~exist('IMU1_DATA','var')), IMU1_DATA = 'OFF'; end
if (~exist('IMU2_DATA','var')), IMU2_DATA = 'OFF'; end
if (~exist('IMU1_SINS','var')), IMU1_SINS = 'OFF'; end
if (~exist('IMU2_SINS','var')), IMU2_SINS = 'OFF'; end
if (~exist('RMSE','var')), RMSE = 'OFF'; end
if (~exist('PLOT','var')), PLOT = 'OFF'; end

    
%% CONVERSIONS

ms2kmh = 3.6;       % m/s to km/h  
d2r = (pi/180);     % degrees to rad
r2d = (180/pi);     % rad to degrees
mss2g = (1/9.81);   % m/s^2 to g  
g2mss = 9.81;
kt2ms = 0.514444444;% knot to m/s

%% LOAD REF DATA

fprintf('Loading trajectory generator data... \n')

load ref.mat

%% IMU ADIS16405 error profile
    
ADIS16405.arw       = 2   .* ones(1,3);       % deg/root-hour
ADIS16405.vrw       = 0.2 .* ones(1,3);       % m/s/root-hour
ADIS16405.m_psd     = 0.066 .* ones(1,3);     % mgauss/root-Hz
ADIS16405.gb_fix    = 3 .* ones(1,3);         % deg/s
ADIS16405.ab_fix    = 50 .* ones(1,3);        % mg      
ADIS16405.gb_drift  = 0.007 .* ones(1,3);     % deg/s
ADIS16405.ab_drift  = 0.2 .* ones(1,3);       % mg      
ADIS16405.gcorr     = inf;                    % s
ADIS16405.acorr     = inf;                    % s
ADIS16405.freq      = 100;                    % Hz

ref1_i = downsampling (ref, 1/ADIS16405.freq);  

dt = mean(diff(ref1_i.t));                     % Mean period

imu1 = imu_err_profile(ADIS16405, dt);


%% IMU ADIS16488 error profile

ADIS16488.arw = 0.3     .* ones(1,3);       % degrees/root-hour
ADIS16488.vrw = 0.029   .* ones(1,3);       % m/s/root-hour
ADIS16488.m_psd = 0.054 .* ones(1,3);       % mgauss/root-Hz
ADIS16488.gb_fix = 0.2  .* ones(1,3);       % deg/s
ADIS16488.ab_fix = 16   .* ones(1,3);       % mg      
ADIS16488.gb_drift = 6.5/3600  .* ones(1,3);% deg/s
ADIS16488.ab_drift = 0.1  .* ones(1,3);     % mg      
ADIS16488.gcorr = inf;                      % s
ADIS16488.acorr = inf;                      % s
ADIS16488.freq = 100;                       % Hz

ref2_i = downsampling (ref, 1/ADIS16488.freq);  

dt = mean(diff(ref2_i.t));                  % Mean period

imu2 = imu_err_profile(ADIS16488, dt);

%% GPS Garmin 5-18 Hz error profile

gps.stdm  = [5, 5, 10];                 % m
gps.stdv  = 0.1 * kt2ms .* ones(1,3);   % knot -> m/s
gps.larm  = zeros(3,1);                 % Lever arm
gps.freq = 5;                           % Hertz


%% SIMULATE GPS

rng('shuffle')

if strcmp(GPS_DATA, 'ON')

    fprintf('Generating GPS data... \n')

    gps = gps_err_profile(ref.lat(1), ref.h(1), gps); 
    
    [gps, ref_g] = gps_gen(ref, gps);
    
    save gps.mat gps
    save ref_g.mat ref_g
    
else
    
    fprintf('Loading GPS data... \n')
    
    load gps.mat 
    load ref_g.mat    
end

%% SIMULATE imu1

rng('shuffle')

if strcmp(IMU1_DATA, 'ON')

    imu1.t = ref1_i.t;
    imu1.freq = ref1_i.freq;

    fprintf('Generating IMU1 ACCR data... \n')

    fb = acc_gen (ref1_i, imu1);
    imu1.fb = fb;

    fprintf('Generating IMU1 GYRO data... \n')

    wb = gyro_gen (ref1_i, imu1);
    imu1.wb = wb;

    save imu1.mat imu1
    save ref1_i.mat ref1_i

    clear wb fb mb;

else
    fprintf('Loading IMU1 data... \n')
    
    load imu1.mat 
    load ref1_i.mat
end

%% SIMULATE imu2

rng('shuffle')

if strcmp(IMU2_DATA, 'ON')

    imu2.t = ref2_i.t;
    imu2.freq = ref2_i.freq;

    fprintf('Generating IMU2 ACCR data... \n')

    fb = acc_gen (ref2_i, imu2);
    imu2.fb = fb;

    fprintf('Generating IMU2 GYRO data... \n')

    wb = gyro_gen (ref2_i, imu2);
    imu2.wb = wb;

    save imu2.mat imu2
    save ref2_i.mat ref2_i

    clear wb fb mb;

else
    fprintf('Loading IMU2 data... \n')
    
    load imu2.mat 
    load ref2_i.mat
end

%% imu1/GPS INTEGRATION WITH FK

if strcmp(IMU1_SINS, 'ON')
    
    fprintf('SINS/GPS integration using IMU1... \n')

    % Sincronize GPS data with IMU data.
    % Guarantee that gps.t(1) < imu1.t(1) < gps.t(2)
    if (imu1.t(1) < gps.t(1)),    

        igx  = find(imu1.t > gps.t(1), 1, 'first' ); 
     
        imu1.t  = imu1.t  (igx:end, :);
        imu1.fb = imu1.fb (igx:end, :);
        imu1.wb = imu1.wb (igx:end, :);
        
        ref1_i.t     = ref1_i.t    (igx:end, :);
        ref1_i.roll  = ref1_i.roll (igx:end, :);
        ref1_i.pitch = ref1_i.pitch(igx:end, :);
        ref1_i.yaw   = ref1_i.yaw  (igx:end, :);
        ref1_i.lat   = ref1_i.lat  (igx:end, :);
        ref1_i.lon   = ref1_i.lon  (igx:end, :);
        ref1_i.h     = ref1_i.h    (igx:end, :);
        ref1_i.vel   = ref1_i.vel  (igx:end, :); 
    end
    
    % Guarantee that imu1.t(end-1) < gps.t(end) < imu1.t(end)
    if (imu1.t(end) < gps.t(end)), 
        
        fgx  = find(gps.t < imu1.t(end), 1, 'last' );
        
        gps.t   = gps.t  (1:fgx, :);
        gps.lat = gps.lat(1:fgx, :);
        gps.lon = gps.lon(1:fgx, :);
        gps.h   = gps.h  (1:fgx, :);    
        gps.vel = gps.vel(1:fgx, :);
        ref_g.t   = ref_g.t  (1:fgx, :);
        ref_g.lat = ref_g.lat(1:fgx, :);
        ref_g.lon = ref_g.lon(1:fgx, :);
        ref_g.h   = ref_g.h  (1:fgx, :);    
        ref_g.vel = ref_g.vel(1:fgx, :);  
    else
    % Eliminate extra inertial meausurements beginnig at gps.t(end)    
        fgx  = find(imu1.t > gps.t(end), 1, 'first' ); 
        
        imu1.t  = imu1.t  (1:fgx, :);
        imu1.fb = imu1.fb (1:fgx, :);
        imu1.wb = imu1.wb (1:fgx, :);
        
        ref1_i.t     = ref1_i.t    (1:fgx, :);
        ref1_i.roll  = ref1_i.roll (1:fgx, :);
        ref1_i.pitch = ref1_i.pitch(1:fgx, :);
        ref1_i.yaw   = ref1_i.yaw  (1:fgx, :);
        ref1_i.lat   = ref1_i.lat  (1:fgx, :);
        ref1_i.lon   = ref1_i.lon  (1:fgx, :);
        ref1_i.h     = ref1_i.h    (1:fgx, :);
        ref1_i.vel   = ref1_i.vel  (1:fgx, :);         
    end    
    
    [imu1_e] = ins(imu1, gps, ref1_i);
    
    save imu1_e.mat imu1_e    
   
else
    
    fprintf('Loading SINS/GPS integration using IMU1... \n')
    
    load imu1_e.mat
end
    
%% imu2/GPS INTEGRATION WITH FK

if strcmp(IMU2_SINS, 'ON')
    
    fprintf('\nSINS/GPS integration using IMU2... \n')

    % Sincronize GPS data with IMU data.
    % Guarantee that gps.t(1) < imu2.t(1) < gps.t(2)
    if (imu2.t(1) < gps.t(1)),    

        igx  = find(imu2.t > gps.t(1), 1, 'first' ); 
     
        imu2.t  = imu2.t  (igx:end, :);
        imu2.fb = imu2.fb (igx:end, :);
        imu2.wb = imu2.wb (igx:end, :);
        
        ref2_i.t     = ref2_i.t    (igx:end, :);
        ref2_i.roll  = ref2_i.roll (igx:end, :);
        ref2_i.pitch = ref2_i.pitch(igx:end, :);
        ref2_i.yaw   = ref2_i.yaw  (igx:end, :);
        ref2_i.lat   = ref2_i.lat  (igx:end, :);
        ref2_i.lon   = ref2_i.lon  (igx:end, :);
        ref2_i.h     = ref2_i.h    (igx:end, :);
        ref2_i.vel   = ref2_i.vel  (igx:end, :); 
    end
    
    % Guarantee that imu2.t(end-1) < gps.t(end) < imu2.t(end)
    if (imu2.t(end) < gps.t(end)), 
        
        fgx  = find(gps.t < imu2.t(end), 1, 'last' );
        
        gps.t = gps.t(1:fgx, :);
        gps.lat = gps.lat(1:fgx, :);
        gps.lon = gps.lon(1:fgx, :);
        gps.h   = gps.h(1:fgx, :);    
        gps.vel = gps.vel(1:fgx, :);
        ref_g.t   = ref_g.t(1:fgx, :);
        ref_g.lat = ref_g.lat(1:fgx, :);
        ref_g.lon = ref_g.lon(1:fgx, :);
        ref_g.h   = ref_g.h(1:fgx, :);    
        ref_g.vel = ref_g.vel(1:fgx, :);  
    else        
    % Eliminate extra inertial meausurements beginnig at gps.t(end)    
        fgx  = find(imu2.t > gps.t(end), 1, 'first' ); 
        
        imu2.t  = imu2.t  (1:fgx, :);
        imu2.fb = imu2.fb (1:fgx, :);
        imu2.wb = imu2.wb (1:fgx, :);
        
        ref2_i.t     = ref2_i.t    (1:fgx, :);
        ref2_i.roll  = ref2_i.roll (1:fgx, :);
        ref2_i.pitch = ref2_i.pitch(1:fgx, :);
        ref2_i.yaw   = ref2_i.yaw  (1:fgx, :);
        ref2_i.lat   = ref2_i.lat  (1:fgx, :);
        ref2_i.lon   = ref2_i.lon  (1:fgx, :);
        ref2_i.h     = ref2_i.h    (1:fgx, :);
        ref2_i.vel   = ref2_i.vel  (1:fgx, :);  
    end    

    
    [imu2_e] = ins(imu2, gps, ref2_i);
    
    save imu2_e.mat imu2_e
    
else
    
    fprintf('Loading SINS/GPS integration using IMU2... \n')

    load imu2_e.mat
end

%% Print navigation time

to = (ref.t(end) - ref.t(1));  

fprintf('\n>> Navigation time: %4.3f min. or %4.3f sec. \n', (to/60), to)

%% Print RMSE IMU1

fe = max(size(imu1_e.t));
fr = max(size(ref1_i.t));

% Adjust ref size if it is bigger than estimates
if (fe < fr)

    ref1_i.t     = ref1_i.t(1:fe, :);
    ref1_i.roll  = ref1_i.roll(1:fe, :);
    ref1_i.pitch = ref1_i.pitch(1:fe, :);
    ref1_i.yaw   = ref1_i.yaw(1:fe, :);
    ref1_i.vel   = ref1_i.vel(1:fe, :);
    ref1_i.lat   = ref1_i.lat(1:fe, :);
    ref1_i.lon   = ref1_i.lon(1:fe, :);
    ref1_i.h     = ref1_i.h(1:fe, :);
    ref1_i.DCMnb = ref1_i.DCMnb(1:fe, :); 
end

[RN,RE] = radius(imu1_e.lat(1), 'double');
lat2m = (RN + double(imu1_e.h(1))); 
lon2m = (RE + double(imu1_e.h(1))) .* cos(imu1_e.lat(1));         

RMSE_roll   = rmse (imu1_e.roll ,  ref1_i.roll)  .*r2d;
RMSE_pitch  = rmse (imu1_e.pitch,  ref1_i.pitch) .*r2d;
% RMSE_yaw    = rmse (imu1_e.yaw,   ref1_i.yaw).*r2d;

% Only compare those estimates that have a diff. < pi with respect to ref
idx = find ( abs(imu1_e.yaw - ref1_i.yaw) < pi );
RMSE_yaw    = rmse (imu1_e.yaw(idx),   ref1_i.yaw(idx)).*r2d;

RMSE_lat    = rmse (imu1_e.lat, ref1_i.lat) .*lat2m;
RMSE_lon    = rmse (imu1_e.lon, ref1_i.lon) .*lon2m;
RMSE_h      = rmse (imu1_e.h,         ref1_i.h);
RMSE_vn     = rmse (imu1_e.vel(:,1),  ref1_i.vel(:,1));
RMSE_ve     = rmse (imu1_e.vel(:,2),  ref1_i.vel(:,2));
RMSE_vd     = rmse (imu1_e.vel(:,3),  ref1_i.vel(:,3));

[RN,RE] = radius(gps.lat(1), 'double');
lat2m = (RN + double(gps.h(1))); 
lon2m = (RE + double(gps.h(1))) .* cos(gps.lat(1)); 

RMSE_lat_g  = rmse (gps.lat, ref_g.lat) .*lat2m;
RMSE_lon_g  = rmse (gps.lon, ref_g.lon) .*lon2m;
RMSE_h_g    = rmse (gps.h-gps.larm(3), ref_g.h);
RMSE_vn_g   = rmse (gps.vel(:,1),   ref_g.vel(:,1));
RMSE_ve_g   = rmse (gps.vel(:,2),   ref_g.vel(:,2));
RMSE_vd_g   = rmse (gps.vel(:,3),   ref_g.vel(:,3));

% Print RMSE
fprintf( '\n>> RMSE IMU1\n');

fprintf( ' Roll,  IMU1 = %.4e deg.\n', ...
             RMSE_roll);
fprintf( ' Pitch, IMU1 = %.4e deg.\n', ...
             RMSE_pitch);
fprintf( ' Yaw,   IMU1 = %.4e deg.\n\n', ...
             RMSE_yaw);

fprintf( ' Vel. N, IMU1 = %.4e m/s, GPS = %.4e. m/s\n', ...
             RMSE_vn, RMSE_vn_g);
fprintf( ' Vel. E, IMU1 = %.4e m/s, GPS = %.4e. m/s\n', ...
             RMSE_ve, RMSE_ve_g);
fprintf( ' Vel. D, IMU1 = %.4e m/s, GPS = %.4e. m/s\n\n', ...
             RMSE_vd, RMSE_vd_g);

fprintf( ' Latitude,  IMU1 = %.4e m, GPS = %.4e. m\n', ...
             RMSE_lat, RMSE_lat_g);
fprintf( ' Longitude, IMU1 = %.4e m, GPS = %.4e. m\n', ...
             RMSE_lon, RMSE_lon_g);
fprintf( ' Altitude,  IMU1 = %.4e m, GPS = %.4e. m\n', ...
             RMSE_h, RMSE_h_g);
    
%% Print RMSE IMU2

fe = max(size(imu2_e.t));
fr = max(size(ref2_i.t));

% Adjust ref size if it is bigger than estimates
if (fe < fr)

    ref2_i.t     = ref2_i.t(1:fe, :);
    ref2_i.roll  = ref2_i.roll(1:fe, :);
    ref2_i.pitch = ref2_i.pitch(1:fe, :);
    ref2_i.yaw = ref2_i.yaw(1:fe, :);
    ref2_i.vel = ref2_i.vel(1:fe, :);
    ref2_i.lat = ref2_i.lat(1:fe, :);
    ref2_i.lon = ref2_i.lon(1:fe, :);
    ref2_i.h = ref2_i.h(1:fe, :);
    ref2_i.DCMnb = ref2_i.DCMnb(1:fe, :); 
end

[RN,RE] = radius(imu2_e.lat(1), 'double');
lat2m = (RN + double(imu2_e.h(1))); 
lon2m = (RE + double(imu2_e.h(1))) .* cos(imu2_e.lat(1));         

RMSE_roll   = rmse (imu2_e.roll ,     ref2_i.roll)  .*r2d;
RMSE_pitch  = rmse (imu2_e.pitch,     ref2_i.pitch) .*r2d;
% RMSE_yaw    = rmse (imu1_e.yaw,   ref1_i.yaw).*r2d;

% Only compare those estimates that have a diff. < pi with respect to ref
idx = find ( abs(imu2_e.yaw - ref2_i.yaw) < pi );
RMSE_yaw    = rmse (imu2_e.yaw(idx),   ref2_i.yaw(idx)).*r2d;

RMSE_lat    = rmse (imu2_e.lat, ref2_i.lat) .*lat2m;
RMSE_lon    = rmse (imu2_e.lon, ref2_i.lon) .*lon2m;
RMSE_h      = rmse (imu2_e.h,         ref2_i.h);
RMSE_vn     = rmse (imu2_e.vel(:,1),  ref2_i.vel(:,1));
RMSE_ve     = rmse (imu2_e.vel(:,2),  ref2_i.vel(:,2));
RMSE_vd     = rmse (imu2_e.vel(:,3),  ref2_i.vel(:,3));

[RN,RE] = radius(gps.lat(1), 'double');
lat2m = (RN + double(gps.h(1))); 
lon2m = (RE + double(gps.h(1))) .* cos(gps.lat(1)); 

RMSE_lat_g  = rmse (gps.lat, ref_g.lat) .*lat2m;
RMSE_lon_g  = rmse (gps.lon, ref_g.lon) .*lon2m;
RMSE_h_g    = rmse (gps.h-gps.larm(3), ref_g.h); %
RMSE_vn_g   = rmse (gps.vel(:,1),   ref_g.vel(:,1));
RMSE_ve_g   = rmse (gps.vel(:,2),   ref_g.vel(:,2));
RMSE_vd_g   = rmse (gps.vel(:,3),   ref_g.vel(:,3));

% Print into console
fprintf( '\n>> RMSE IMU2\n');

fprintf( ' Roll,  IMU2 = %.4e deg.\n', ...
             RMSE_roll);
fprintf( ' Pitch, IMU2 = %.4e deg.\n', ...
             RMSE_pitch);
fprintf( ' Yaw,   IMU2 = %.4e deg.\n\n', ...
             RMSE_yaw);

fprintf( ' Vel. N, IMU2 = %.4e m/s, GPS = %.4e. m/s\n', ...
             RMSE_vn, RMSE_vn_g);
fprintf( ' Vel. E, IMU2 = %.4e m/s, GPS = %.4e. m/s\n', ...
             RMSE_ve, RMSE_ve_g);
fprintf( ' Vel. D, IMU2 = %.4e m/s, GPS = %.4e. m/s\n\n', ...
             RMSE_vd, RMSE_vd_g);

fprintf( ' Latitude,  IMU2 = %.4e m, GPS = %.4e. m\n', ...
             RMSE_lat, RMSE_lat_g);
fprintf( ' Longitude, IMU2 = %.4e m, GPS = %.4e. m\n', ...
             RMSE_lon, RMSE_lon_g);
fprintf( ' Altitude,  IMU2 = %.4e m, GPS = %.4e. m\n', ...
             RMSE_h, RMSE_h_g);
             
%% PLOT

if (strcmp(PLOT,'ON'))

sig3_rr = abs(imu1_e.PP.^(0.5)).*3;

% TRAJECTORY
figure; 
plot3(ref.lon.*r2d, ref.lat.*r2d, ref.h)
hold on
plot3(ref.lon(1).*r2d, ref.lat(1).*r2d, ref.h(1), 'or', 'MarkerSize', 10, 'LineWidth', 2)
axis tight
title('TRAJECTORY')
xlabel('Longitude [deg.]') 
ylabel('Latitude [deg.]')
zlabel('Altitude [m]')
grid

% ATTITUDE
figure;
subplot(311)
plot(ref1_i.t, r2d.*ref1_i.roll, '--k', imu1_e.t, r2d.*imu1_e.roll,'-b', imu2_e.t, r2d.*imu2_e.roll,'-r');
ylabel('[deg]')
xlabel('Time [s]')
legend('REF', 'IMU1', 'IMU2');
title('ROLL');

subplot(312)
plot(ref1_i.t, r2d.*ref1_i.pitch, '--k', imu1_e.t, r2d.*imu1_e.pitch,'-b', imu2_e.t, r2d.*imu2_e.pitch,'-r');
ylabel('[deg]')
xlabel('Time [s]')
legend('REF', 'IMU1', 'IMU2');
title('PITCH');

subplot(313)
plot(ref1_i.t, r2d.* ref1_i.yaw, '--k', imu1_e.t, r2d.*imu1_e.yaw,'-b', imu2_e.t, r2d.*imu2_e.yaw,'-r');
ylabel('[deg]')
xlabel('Time [s]')
legend('REF', 'IMU1', 'IMU2');
title('YAW');

% ATTITUDE ERRORS
figure; 
subplot(311)
plot(imu1_e.t, (imu1_e.roll-ref1_i.roll).*r2d, '-b', imu2_e.t, (imu2_e.roll-ref2_i.roll).*r2d, '-r');
hold on
plot (gps.t, r2d.*sig3_rr(:,1), '--k', gps.t, -r2d.*sig3_rr(:,1), '--k' )
ylabel('[deg]')
xlabel('Time [s]')
legend('IMU1', 'IMU2', '3\sigma');
title('ROLL ERROR');

subplot(312)
plot(imu1_e.t, (imu1_e.pitch-ref1_i.pitch).*r2d, '-b', imu2_e.t, (imu2_e.pitch-ref2_i.pitch).*r2d, '-r');
hold on
plot (gps.t, r2d.*sig3_rr(:,2), '--k', gps.t, -r2d.*sig3_rr(:,2), '--k' )
ylabel('[deg]')
xlabel('Time [s]')
legend('IMU1', 'IMU2', '3\sigma');
title('PITCH ERROR');

subplot(313)
plot(imu1_e.t, (imu1_e.yaw-ref1_i.yaw).*r2d, '-b', imu2_e.t, (imu2_e.yaw-ref2_i.yaw).*r2d, '-r');
hold on
plot (gps.t, r2d.*sig3_rr(:,3), '--k', gps.t, -r2d.*sig3_rr(:,3), '--k' )
ylabel('[deg]')
xlabel('Time [s]')
legend('IMU1', 'IMU2', '3\sigma');
title('YAW ERROR');

% VELOCITIES
figure;
subplot(311)
plot(ref.t, ref.vel(:,1), '--k', gps.t, gps.vel(:,1),'-c', imu1_e.t, imu1_e.vel(:,1),'-b', imu2_e.t, imu2_e.vel(:,1),'-r');
xlabel('Time [s]')
ylabel('[m/s]')
legend('REF', 'GPS', 'IMU1', 'IMU2');
title('NORTH VELOCITY');

subplot(312)
plot(ref.t, ref.vel(:,2), '--k', gps.t, gps.vel(:,2),'-c', imu1_e.t, imu1_e.vel(:,2),'-b', imu2_e.t, imu2_e.vel(:,2),'-r');
xlabel('Time [s]')
ylabel('[m/s]')
legend('REF', 'GPS', 'IMU1', 'IMU2');
title('EAST VELOCITY');

subplot(313)
plot(ref.t, ref.vel(:,3), '--k', gps.t, gps.vel(:,3),'-c', imu1_e.t, imu1_e.vel(:,3),'-b', imu2_e.t, imu2_e.vel(:,3),'-r');
xlabel('Time [s]')
ylabel('[m/s]')
legend('REF', 'GPS', 'IMU1', 'IMU2');
title('DOWN VELOCITY');

% VELOCITIES ERRORS
figure;
subplot(311)
plot(gps.t, (gps.vel(:,1)-ref_g.vel(:,1)), '-c');
hold on
plot(imu1_e.t, (imu1_e.vel(:,1)-ref1_i.vel(:,1)), '-b', imu2_e.t, (imu2_e.vel(:,1)-ref2_i.vel(:,1)), '-r');
hold on
plot (gps.t, sig3_rr(:,4), '--k', gps.t, -sig3_rr(:,4), '--k' )
xlabel('Time [s]')
ylabel('[m/s]')
legend('GPS', 'IMU1', 'IMU2', '3\sigma');
title('VELOCITY NORTH ERROR');

subplot(312)
plot(gps.t, (gps.vel(:,2)-ref_g.vel(:,2)), '-c');
hold on
plot(imu1_e.t, (imu1_e.vel(:,2)-ref1_i.vel(:,2)), '-b', imu2_e.t, (imu2_e.vel(:,2)-ref2_i.vel(:,2)), '-r');
hold on
plot (gps.t, sig3_rr(:,5), '--k', gps.t, -sig3_rr(:,5), '--k' )
xlabel('Time [s]')
ylabel('[m/s]')
legend('GPS', 'IMU1', 'IMU2', '3\sigma');
title('VELOCITY EAST ERROR');

subplot(313)
plot(gps.t, (gps.vel(:,3)-ref_g.vel(:,3)), '-c');
hold on
plot(imu1_e.t, (imu1_e.vel(:,3)-ref1_i.vel(:,3)), '-b', imu2_e.t, (imu2_e.vel(:,3)-ref2_i.vel(:,3)), '-r');
hold on
plot (gps.t, sig3_rr(:,6), '--k', gps.t, -sig3_rr(:,6), '--k' )
xlabel('Time [s]')
ylabel('[m/s]')
legend('GPS', 'IMU1', 'IMU2', '3\sigma');
title('VELOCITY DOWN ERROR');

% POSITION
figure;
subplot(311)
plot(ref.t, ref.lat .*r2d, '--k', gps.t, gps.lat.*r2d, '-c', imu1_e.t, imu1_e.lat.*r2d, '-b', imu2_e.t, imu2_e.lat.*r2d, '-r');
xlabel('Time [s]')
ylabel('[deg]')
legend('REF', 'GPS', 'IMU1', 'IMU2');
title('LATITUDE');

subplot(312)
plot(ref.t, ref.lon .*r2d, '--k', gps.t, gps.lon.*r2d, '-c', imu1_e.t, imu1_e.lon.*r2d, '-b', imu2_e.t, imu2_e.lon.*r2d, '-r');
xlabel('Time [s]')
ylabel('[deg]')
legend('REF', 'GPS', 'IMU1', 'IMU2');
title('LONGITUDE');

subplot(313)
plot(ref.t, ref.h, '--k', gps.t, gps.h, '-c', imu1_e.t, imu1_e.h, '-b', imu2_e.t, imu2_e.h, '-r');
xlabel('Time [s]')
ylabel('[m]')
legend('REF', 'GPS', 'IMU1', 'IMU2');
title('ALTITUDE');

% POSITION ERRORS
% fh = @radicurv;
% [RNs,REs] = arrayfun(fh, lat_rs);

[RN,RE]  = radius(imu1_e.lat, 'double');
lat2m = RN + imu1_e.h; 
lon2m = (RE + imu1_e.h).*cos(imu1_e.lat);         

[RN,RE]  = radius(gps.lat, 'double');
lat2m_g = RN + gps.h; 
lon2m_g = (RE + gps.h).*cos(gps.lat);

figure;
subplot(311)
plot(gps.t, lat2m_g.*(gps.lat - ref_g.lat), '-c')
hold on
plot(imu1_e.t, lat2m.*(imu1_e.lat - ref1_i.lat), '-b')
hold on
plot(imu2_e.t, lat2m.*(imu2_e.lat - ref2_i.lat), '-r')
hold on
plot (gps.t, lat2m_g.*sig3_rr(:,7), '--k', gps.t, -lat2m_g.*sig3_rr(:,7), '--k' )
xlabel('Time [s]')
ylabel('[m]')
legend('GPS', 'IMU1', 'IMU2', '3\sigma');
title('LATITUDE ERROR');

subplot(312)
plot(gps.t, lon2m_g.*(gps.lon - ref_g.lon), '-c')
hold on
plot(imu1_e.t, lon2m.*(imu1_e.lon - ref1_i.lon), '-b')
hold on
plot(imu2_e.t, lon2m.*(imu2_e.lon - ref2_i.lon), '-r')
hold on
plot(gps.t, lon2m_g.*sig3_rr(:,8), '--k', gps.t, -lon2m_g.*sig3_rr(:,8), '--k' )
xlabel('Time [s]')
ylabel('[m]')
legend('GPS', 'IMU1', 'IMU2', '3\sigma');
title('LONGITUDE ERROR');

subplot(313)
plot(gps.t, (gps.h - ref_g.h), '-c')
hold on
plot(imu1_e.t, (imu1_e.h - ref1_i.h), '-b')
hold on
plot(imu2_e.t, (imu2_e.h - ref2_i.h), '-r')
hold on
plot(gps.t, sig3_rr(:,9), '--k', gps.t, -sig3_rr(:,9), '--k' )
xlabel('Time [s]')
ylabel('[m]')
legend('GPS', 'IMU1', 'IMU2', '3\sigma');
title('ALTITUDE ERROR');

end         
