
cd('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/Code')
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/MRIPhantomv0-8'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/tightfig'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/WaveLab850'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/sparseMRI_v0.2'))

clear all; close all; clc;
MR=MRecon('/home/jschoormans/lood_storage/divi/Ima/parrec/Jasper/cs_highres_noisy/20_30052016_1952515_3_2_wipmprageadnisenseV4.raw')
MR.Parameter.Parameter2Read.typ = 1;
MR.Parameter.Parameter2Read.dyn = [0 1 2 3 4]';
MR.Parameter.Parameter2Read.chan=[5 6 7 8 9]'
% Produce k-space Data (using existing MRecon functions)
MR.ReadData;
MR.DcOffsetCorrection;
MR.PDACorrection;
MR.RandomPhaseCorrection;
MR.MeasPhaseCorrection;
MR.SortData;
MR.K2I;

%% sample from data
acc=6;
[pdf,val] = genPDF(size(MR.Data(1,:,:)),5,1/acc,2,0,0);
Mfull=genEllipse(size(MR.Data,1),size(MR.Data,2));
Mfull=repmat(Mfull,[size(MR.Data,1) 1 1]); %add coils
M=repmat(genSampling(pdf,10,100),[size(MR.Data,1) 1 1]).*Mfull;

jjj=4 %option to try different averaging approaches
if jjj==1
    MNSA=ceil(1./pdf);
elseif jjj==2
    MNSA=ceil(pdf*acc);
elseif jjj==3
    MNSA=acc*ones(size(pdf));
elseif jjj==4 %extreme center-heavy
    MNSA=ones(size(pdf));
    MNSA(1+ny/4:3*ny/4,1+nz/4:3*nz/4)=100*ones(ny/2,nz/2);
elseif jjj==5 %extreme outside-heavy
    MNSA=100*ones(size(pdf));
    MNSA(1+ny/4:3*ny/4,1+nz/4:3*nz/4)=ones(ny/2,nz/2);

end


for iii=1:max(MNSA(:)) %Matrix of NSA values
Ku_N1=repmat(squeeze(M(:,:,1).*(MNSA(:,:)>=iii)),[1 1 size(MR.Data,3)]).*MR.Data(:,:,:,1,iii);
Ku_N2(1,:,:,:,1,iii)=permute(Ku_N1,[1,2,3,5,4]);
end
Ku_Nvar1=squeeze(sum(Ku_N2,6)./permute(repmat(MNSA,[1 1 size(MR.Data,3)]),[4 1 2 3]));


%%
Ku_Nvar1_FT=fftshift(fft(Ku_Nvar1,[],1));
Ku_Nvar1_FT=Ku_Nvar1_FT(206,:,:);
%% Recons
param.data=squeeze(Ku_Nvar1_FT)
N=size(param.data)
M1=squeeze(M(1,:,:))

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
xfmWeight = 0.0002;	% Weight for Transform L1 penalty

param.xfmWeight=xfmWeight
im_dc2 = FT'*(param.data.*M1./pdf); %linear recon; scale data to prevent low-pass filtering
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
param.xfmWeight=xfmWeight*(mean(param.V(M~=0)))

for n=1:4
	res = fnlCg_test(res,param);
	R5{jjj} = XFM'*res;
end
R5{jjj}=R5{jjj}./max(R5{jjj}(:));

%% VISUALIZATION 

figure(100);
imshow(abs(cat(2,R4{jjj},R5{jjj})),[])
