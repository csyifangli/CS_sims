function [PFCE,PFCE_alpha,PFOB,PFOB_alpha]=calcspectra_BW(ppm_hz,BW_pix)
%inputs:
%Gx: gradient strength (in T) 
%Nx: number of pixels in FOV
%Lx: size of FOV (in m) 

%outputs: 
% PFCE,PFCE_alpha,PFOB,PFOB_alpha:locations (pixels) and intensities (A.U.) of chemical shift peaks  

%% FOR PFCE
PFCE=0;
PFCE_alpha=20;
%% FOR PFOB
df=[26.7,8.6,-27.1,-31.6,-36.2] %ppm

dx=(ppm_hz.*df)./BW_pix;

PFOB=dx; % in pixels
PFOB_alpha=[2,6,2,3,2];
% PFOB_alpha=[2,2.8,1.76,3.8,1.68];
PFOB_alpha=[1.68,3.8,1.76,2.8,2];


figure(100); 
hold on
stem(PFCE,PFCE_alpha)
stem(PFOB,PFOB_alpha)
hold off
xlabel('pixels')
title('PSF of PFCD and PFOB')
end