%% KLADBLOK EXPERIMENT VNSA 51
clear all; close all; clc;

%% load k-space
if ispc()
    rmpath(genpath('L:\basic\divi\Projects\cosart\CS_simulations'))
    addpath(genpath('L:\basic\divi\Projects\cosart\CS_simulations\experiments\VNSA_51_retro')) % for this: only the local code!!
    addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\Wavelab850'))
    addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\exportfig'))
    experimentfolder=['L:\basic\divi\Projects\cosart\CS_simulations\experiments\VNSA_51_retro\',date]
    mkdir(experimentfolder)
    addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\spot-master'))
addpath(genpath('L:\basic\divi\Projects\cosart\Matlab_Collection\Wavelab850\'))

    vars
    cd('L:\basic\divi\Ima\parrec\Jasper\VNSA\VNSA_51\VNSA_51')
else
    addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/exportfig'))
    addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/tightfig/'))
    rmpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/'))
    addpath(genpath('/opt/amc/bart')); vars
    addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/experiments/VNSA_51_retro' ))
    experimentfolder=['/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/experiments/VNSA_51_retro/',date,'2']
    mkdir(experimentfolder)
    
    cd('/home/jschoormans/lood_storage/divi/Ima/parrec/Jasper/VNSA/VNSA_51/VNSA_51')
end
files=dir('*.mat')
load(files(2).name)

 %% FIX CHECKERBOARD ISSUE
 %%%%%%%%%%%%%%%%%TEMP TEMP TEMP
 rr=mod([1:720],2); rr=double(rr)-double(rr==0);
 checkerboard=repmat(rr,[720 1]);
 checkerboard=repmat(checkerboard,[1 1 8 100]);
 K_ch=checkerboard.*K;
 %%%%%%%%%%%%%%%%%%

%% make sense maps
disp('to do: use this in recon- fix checkerboard here as well')
Kref=mean(K_ch,4); %still use coils though
Kref=permute(Kref,[4 1 2 3]);
sens=bart('ecalib -m1 -r20',Kref); %should be [nx,ny,1,nc] ?
imagine(sens)
%% Imref
reg=0.01;
ImRef=(squeeze(bart(['pics -RW:7:0:',num2str(reg),' -S -e -i100'],Kref,sens))); %to compare image
ImRef=abs(ImRef);
ImRef=ImRef./(max(ImRef(:)));
figure(1); imshow(squeeze(abs(ImRef)),[])
%% RESIZE SENSE MAPS 
sensim=bart('fft 7',sens);
sensim=bart( 'resize -c 1 1024 2 1024',sensim);
sensresize=bart('fft -i 7',sensim);
size(sensresize)
%% RECON HERE
%K should be [kx ky kz ncoils nNSA]
% FOR CERTAIN ACC FACTORS - LOOP OVERNIGHT

PR=struct;
PR.outeriter=4;
PR.Itnlim=10;
PR.noNSAcorr=false;
PR.TVWeight=1e-3;
PR.TGVfactor=0;
PR.xfmWeight=2e-3;
PR.reconslices=1;
PR.squareksp=true;
PR.resultsfolder=''
PR.sensemaps=squeeze(sensresize); 
PR.sensemapsprovided=1

accvector=[1,2,3,4,5,6];
nNSA=[1:5];

for kk=1%:nNSA
for jj=1%:3
for ii=1%:length(accvector);
    P.usedyns=kk; %for example
    P.acc=accvector(ii);
    P.jjj=jj+4 % 5 6 7
    P.noiselevel=0
    [~,~, KD]=makeNoisyKspacefromdynamics(K_ch,P);
    
    Ko=KD.Ku_N2;
    Ko=permute(Ko,[5 1 2 3 4]);
   
    R=reconVarNSA51(Ko,PR); 
    %append/save/clear to save memory??
    
    save([experimentfolder,'\R_',num2str(ii),'_',num2str(jj),'_',num2str(kk),'.mat'],'R')
end
end
end

