clear all; close all; clc
if ispc()
    addpath(genpath('L:\basic\divi\Projects\cosart\CS_simulations'))
    addpath(genpath('L:\basic\divi\Projects\cosart\CS_simulations\experiments\VNSA_51_retro')) % for this: only the local code!!
    addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\Wavelab850'))
    addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\exportfig'))
    experimentfolder=['L:\basic\divi\Projects\cosart\CS_simulations\experiments\VNSA_51_retro\',date]
    mkdir(experimentfolder)
    addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\spot-master'))
    addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\Wavelab850\'))
    rmpath(genpath('L:\basic\divi\Projects\cosart\CS_simulations\experiments\VNSA_51_retro\ReconCode'))
    vars
    cd('L:\basic\divi\Ima\parrec\Jasper\VNSA\VNSA_51\VNSA_51')
else
    addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/exportfig'))
        addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/imagine'))
    addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/tightfig/'))
    addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/'))
    addpath(genpath('/opt/amc/bart')); vars
    addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/experiments/VNSA_51_retro' ))
    experimentfolder=['/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/experiments/VNSA_51_retro/',date,'2']
    mkdir(experimentfolder)
    
    cd('/home/jschoormans/lood_storage/divi/Ima/parrec/Jasper/VNSA/VNSA_51/VNSA_51')
end
files=dir('*.mat')
load(files(3).name)
%% FIX CHECKERBOARD ISSUE
%%%%%%%%%%%%%%%%%TEMP TEMP TEMP
rr=mod([1:720],2); rr=double(rr)-double(rr==0);
checkerboard=repmat(rr,[720 1]);
checkerboard=repmat(checkerboard,[1 1 8 100]);
K_ch=checkerboard.*K;
%%%%%%%%%%%%%%%%%%

%% make sense maps
disp('to do: use this in recon- fix checkerboard here as well')
K_ch_crop=K_ch(183:538,183:538,:,:); 

Kref=mean(K_ch_crop,4); %still use coils though
Kref=permute(Kref,[4 1 2 3]);
sens=bart('ecalib -m1 -r20',Kref); %should be [nx,ny,1,nc] ?
% %% Imref
% reg=0.01;
% ImRef=(squeeze(bart(['pics -RW:7:0:',num2str(reg),' -S -e -i100'],Kref,sens))); %to compare image
% ImRef=abs(ImRef);
% ImRef=ImRef./(max(ImRef(:)));
% figure(1); imshow(squeeze(abs(ImRef)),[])

%% RECON HERE
%K should be [kx ky kz ncoils nNSA]
% FOR CERTAIN ACC FACTORS - LOOP OVERNIGHT
PR=struct;
PR.TVWeight=0;
PR.TGVfactor=0;
PR.reconslices=1;
PR.squareksp=false;
PR.resultsfolder=''
PR.sensemaps=squeeze(sens); 
PR.sensemapsprovided=1
PR.visualize_nlcg=0;
PR.debug_nlcg=0;
PR.Scaling=true;
PR.VNorm=1; %power of weighting mat  rix (number of NSA)^p; 

%%
rng('default');
rng(1)
P.usedyns=1; %for example
P.acc=5;
P.jjj=6 % 5 6 7
P.noiselevel=0
[~,~, KD]=makeNoisyKspacefromdynamics(K_ch_crop,P);
rr=1
Ko=KD.Ku_N2;
Ko=permute(Ko,[5 1 2 3 4]);
PR.outeriter=1;
PR.Itnlim=20;
PR.xfmWeight=2e-4;

PR.VNSAlambdaCorrection=1;
PR.WeightedL2=1;
R=reconVarNSA(Ko,PR,rr);
R11=abs(R.recon);

PR.VNSAlambdaCorrection=0;
PR.WeightedL2=1;
R=reconVarNSA(Ko,PR,rr);
R10=abs(R.recon);

PR.VNSAlambdaCorrection=1;
PR.WeightedL2=0;
R=reconVarNSA(Ko,PR,rr);
R00=abs(R.recon);

PR.xfmWeight=PR.xfmWeight*7;
PR.VNSAlambdaCorrection=0;
PR.WeightedL2=0;
R=reconVarNSA(Ko,PR,rr);
RN=abs(R.recon);

PR.xfmWeight=0;
PR.VNSAlambdaCorrection=0;
PR.WeightedL2=0;
R=reconVarNSA(Ko,PR,rr);
R00_noL=abs(R.recon);

PR.xfmWeight=0;
PR.VNSAlambdaCorrection=0;
PR.WeightedL2=1;
R=reconVarNSA(Ko,PR,rr);
R11_noL=abs(R.recon);

%% to do
%{
% % calculate noise power spectra
ACF = @(x) conv(x,-x)
PSD = @(x) abs(fftshift(fft(ifftshift(ACF(x))))).^2
nn=30;

for ii=1:nn
PSD00(:,ii)=PSD(squeeze(R00{1}(1,:,ii)));
PSD11(:,ii)=PSD(squeeze(R11{1}(1,:,ii)));
PSD10(:,ii)=PSD(squeeze(R10{1}(1,:,ii)));
PSDN(:,ii)=PSD(squeeze(RN{1}(1,:,ii)));
end
for ii=1:nn
PSD00_noL(:,ii)=PSD(squeeze(R00_noL{1}(1,:,ii)));
PSD11_noL(:,ii)=PSD(squeeze(R11_noL{1}(1,:,ii)));
end
%}
%%
cd('L:\basic\divi\Projects\cosart\CS_simulations\experiments\effect_weighting\effect_weighting_grapefruit')
% figures 
resolution=0.7; % in mm; 
freqs=linspace(-1,1,599)./resolution; % spatial frequencies'

close all
figure(1);
imshow(abs(cat(1,squeeze(R00).'./max(R00(:)),squeeze(R10).'./max(R10(:)),squeeze(R11).'./max(R11(:)),squeeze(RN).'./max(RN(:)))),[])
% title('no W ,\lambda_0  |   W, \lambda_0  |  W, \lambda_c  |  no W,\lambda_N,')
export_fig '1.eps' -eps
export_fig '1.tiff' -eps

kx=140:190; 
ky=40:70;
figure(2)
imshow(abs(cat(1,squeeze(R00(kx,ky)).'./max(R00(:)),squeeze(R10(kx,ky)).'./max(R10(:)),squeeze(R11(kx,ky)).'./max(R11(:)),squeeze(RN(kx,ky)).'./max(RN(:)))),[])
export_fig '2.eps' -eps
export_fig '2.tiff' -eps

figure(11);
imshow(abs(cat(1,squeeze(R00_noL).',squeeze(R11_noL).')),[])
export_fig '11.eps' -eps
export_fig '11.tiff' -eps

figure(12);
imshow(abs(cat(1,squeeze(R00_noL(kx,ky)).',squeeze(R11_noL(kx,ky)).')),[])
export_fig '12.eps' -eps
export_fig '12.tiff' -eps

figure(16) % mask 
imshow(abs(KD.M.*KD.MNSA),[]); colormap jet
export_fig '16.eps' -eps
export_fig '16.tiff' -tiff

%{
% figure(3); imshow(squeeze(R00(1,:,1:nn)),[]); title('image section used for calculating noise spectral density')
% export_fig '3.eps' -eps

figure(4); hold on;
plot(freqs,log(sum(abs(PSD00),2)),'k');
plot(freqs,log(sum(abs(PSD10),2)),'c')
plot(freqs,log(sum(abs(PSD11),2)),'g')
plot(freqs,log(sum(abs(PSDN),2)),'y')
hold off
title('PSD'); 
xlabel('spatial frequency [mm^{-1}]')
ylabel('log(PSD)')
legend('no W ,\lambda_0','W, \lambda_0','W, \lambda_c','no W, \lambda_N')
export_fig '4.eps' -eps
%}
%%


figure(14); hold on;
plot(freqs,log(sum(abs(PSD00_noL),2)),'k');
plot(freqs,log(sum(abs(PSD11_noL),2)),'c')
hold off
title('PSD'); 
xlabel('spatial frequency [mm^{-1}]')
ylabel('log(PSD)')
legend('unweighted l_2 norm','weighted l_2 norm')
export_fig '14.eps' -eps


%{
x11=100*((sum(abs(PSD00_noL),2))-(sum(abs(PSD11_noL),2)))./(sum(abs(PSD00_noL),2))
figure(15); 
plot(freqs,(x11),'r','LineWidth',1.5)
xlabel('spatial frequency [mm^{-1}]')
ylabel('difference (%)')
title('ratio of  Weightedl2 norm and normal l2 norm')
legend('same \lambda','adapted \lambda','extra \lambda')
export_fig '15.eps' -eps
%}

figure(16) % mask 
imshow(abs(MR.P.MNSA),[])
export_fig '16.eps' -eps
export_fig '16.tiff' -tiff

