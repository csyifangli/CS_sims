% VARIABLE NSA PHANTOM RECON FILE
%COMBINES CODE FROM PREWHITEN_TEST_VAR_NSA AND
%DEMO_BRAIN_TEST_VARIANCE_MATRIX

%GOAL: COMPARE DIFFERENT APPROACHES OF RECONSTRUCTING A CS -KSPACE WITH A
%NON-UNIFORM NOISE PROFILE; OBTAINED BY VARING THE NUMBER OF SIGNAL
%AVERAGES OVER SPACE

cd('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/Code')
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/MRIPhantomv0-8'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/tightfig'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/WaveLab850'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/sparseMRI_v0.2'))

clear all; close all; clc;


%% simulate k-space
N=[512 512]
[K,sens]=genPhantomKspace(N(1),1);
sens=permute(sens,[1 2 4 3]);
ny=size(K,2);
nz=size(K,1);
acc=5

%sampling pattern
[pdf,val] = genPDF(size(K(:,:,1)),5,1/acc,2,0,0);
Mfull=genEllipse(size(K,1),size(K,2));
Mfull=repmat(Mfull,[1 1 size(K,3)]); %add coils
M=genSampling(pdf,10,100).*Mfull;
%% PARAMETER USED FOR CONJUGATE GRADIENT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% L1 Recon Parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TVWeight = 0; 	% Weight for TV penalty
xfmWeight = 0.00001;	% Weight for Transform L1 penalty
Itnlim = 8;		% Number of iterations

%generate Fourier sampling operator
FT = p2DFT(M, N, 1, 2);

%generate transform operator
XFM = Wavelet('Daubechies',4,4);	% Wavelet

% initialize Parameters for reconstruction
param = init;
param.FT = FT;
param.XFM = XFM;
param.TV = TVOP;
param.TVWeight =0;     % TV penalty 
param.xfmWeight = xfmWeight;  % L1 wavelet penalty
param.Itnlim = Itnlim;





%% SIGNAL AVERAGING APPROACHES
jjj=1; %option to try different averaging approaches
if jjj==1
    MNSA=ceil(1./pdf);
elseif jjj==2
    MNSA=ceil(pdf*acc);
else
    MNSA=acc*ones(size(pdf));
end

%% add noise to kspace
clear Ku_N2
NoiseLevel=1e-4;
for iii=1:max(MNSA(:)) %Matrix of NSA values
K_N=addNoise(K,NoiseLevel);
Ku_N1=repmat(squeeze(M(:,:).*(MNSA(:,:)>=iii)),[1 1 size(K,3)]).*K_N;
Ku_N2(1,:,:,:,1,iii)=permute(Ku_N1,[1,2,3,4]);
end
Ku_Nvar1=sum(Ku_N2,6)./permute(repmat(MNSA,[1 1 size(K,3)]),[4 2 1 3]);

sum(MNSA(:).*M(:)) %number of sampling points
sum(Mfull(:)) %number of sampling points

data=squeeze(Ku_Nvar1); %noisy 2D kspace data


param.data = data;  %give data to parameters.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  RECONS 
%% ORDINARY RECON
reg=0.05
R1{jjj}=bart(['pics -RW:7:0:',num2str(rMNSAeg),' -S -e -i20 -d5'],K_N.*Mfull,sens(end:-1:1,end:-1:1,:,:));
R1{jjj}=R1{jjj}./max(R1{jjj}(:));
%% RECON R2: WITHOUT PREAVERAGING
clear traj2;
ADMMreg=0.5
[kspace, traj]=calctrajBART(permute(Ku_N2,[1 2 3 4 6 5])); 
traj2(1,1,:)=traj(3,1,:); traj2(2,1,:)=traj(2,1,:); traj2(3,1,:)=traj(1,1,:); %FOR 2D signals; when we do not want ANY frequency encoding!
R2{jjj}=bart(['pics -RW:7:0:0.02 -S -u',num2str(ADMMreg),' -m -i30 -d5 -t'],traj2,kspace,sens);
R2{jjj}=R2{jjj}./max(R2{jjj}(:));

%% RECON R3: same traj, with preaveraging
clear traj2;
[kspace, traj]=calctrajBART((Ku_Nvar1)); 
traj2(1,1,:)=traj(3,1,:); traj2(2,1,:)=traj(2,1,:); traj2(3,1,:)=traj(1,1,:); %FOR 2D signals; when we do not want ANY frequency encoding!
R3{jjj}=bart(['pics -RW:7:0:0.02 -S -u',num2str(ADMMreg./mean(sqrt(MNSA(:)).^2)),' -m -i30 -d5 -t'],traj2,kspace,sens);
R3{jjj}=R3{jjj}./max(R3{jjj}(:));

%% RECON R4: conjugate gradient method - with pre-averaging but no variance matrix

xfmWeight = 0.0001;	% Weight for Transform L1 penalty

param.xfmWeight=xfmWeight
im_dc2 = FT'*(param.data.*M./pdf); %linear recon; scale data to prevent low-pass filtering
res_orig = XFM*im_dc2;
for n=1:4
    res_orig = fnlCg(res_orig,param);
	R4{jjj} = XFM'*res_orig;
end
R4{jjj}=R4{jjj}./max(R4{jjj}(:));

%% RECON R5
res = XFM*im_dc2;
param.V=sqrt(MNSA);
param.Debug=0;
param.xfmWeight=xfmWeight*(mean(param.V(:).^2))

for n=1:4
	res = fnlCg_test(res,param);
	R5{jjj} = XFM'*res;
end
R5{jjj}=R5{jjj}./max(R5{jjj}(:));

%% VISUALIZATION 

figure(100);
imshow(abs(cat(2,R1{jjj}./max(R1{jjj}(:)),R2{jjj},R3{jjj},R4{jjj},R5{jjj})),[])



