
clear all; close all; clc; 
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/spot-master'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/Wavelab850'))
addpath /home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/TFOCS-1.4
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/imagine'))
addpath(genpath('/opt/amc/bart/')); vars; 
addpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/Code/ADDMLASSO')


%%
cd('/home/jschoormans/lood_storage/divi/Ima/parrec/Jasper/VNSA/VNSA12')
disp('loading k-space...')
load('K_scan13_nocc')
K_orig=K; 

%% 1: simple 2D example; iFFT in z-direction, one NSA

sl=1

Ks=squeeze(K(round(size(K,1)/2),:,:,1,:)); %k-space for one channel and one slice
fullmask=Ks~=0;             %find mask used for scan (nx*ny*NSA)
MNSA=sum(fullmask,3);       %find NSA for all k-points in mask 

data=sum(K_orig,5);              %sum of data over NSA
[nx,n1,n2,ncoils]=size(data); 

K=data./permute(...
    repmat(MNSA,[1 1 nx ncoils]),[3 1 2 4]);  % TAKE MEAN OF MEASURED VALUES
K(isnan(K))=0;

K=ifft(K,[],1); % FOR NOW: iFFT along read dim
K=squeeze(K(sl,:,:,:));

mask=K(:,:,1)~=0;

figure(1); imshow(abs([K(:,:,1)./max(K(:)),mask]),[0 1]); axis off; title('kspace and mask')

for i=1:ncoils
    Kc=K(:,:,i);
Ku(:,i)=Kc(mask);
end; clear Kc;
Ku=vec(Ku);

%% make operators 

mat = @(x) reshape(x,n1,n2,ncoils); %function that reshapes vector to matrix 
mat2d = @(x) reshape(x,n1,n2*ncoils); % functions that reshapes in 2d matrix for visualization purposes 
matcc =@(x) reshape(x,n1,n2); %function that reshapes vector to matrix 

AA=opDFT2(n1,n2,1) %DFT2 MATRIX

l=[1:n1*n2];
mask2=(l(~mask(:))); %indices of rows in FDT2 matrix that should be removed (were not sampled!)
R=opExcise(AA,mask2,'rows')
E1=opBlockDiag(R,R,R,R,R,R,R,R,R,R,R,R,R) % can this be done easier?

%% perform linear recon 

linear_recon=E1'*Ku;

sensmaps=bart('ecalib -r20 -m1 -k5',permute(K,[4 1 2 3]));  %% make sense maps 
sensmaps=fftshift(fftshift(sensmaps,3),2);
% note: SENSE MAPS LOOK VERY BAD (LOW SNR/ TOO SMALL KERNEL)?


figure(2)
imshow(abs([mat2d(linear_recon./max(linear_recon(:)));mat2d(sensmaps./max(sensmaps(:)))]),[]); % linear recon for all coils apart 


% make sense maps operators 
clear S
for i=1:ncoils; S{i}=opDiag(conj(sensmaps(1,:,:,i))); end; 
S2= horzcat(S{i},S{2},S{3},S{4},S{5},S{6},S{7},S{8},S{9},S{10},S{11},S{12},S{13})

E2=E1*S2'

%linear recon s
linear_recon_s=E2'*Ku;
figure(3); imshow(abs(matcc(linear_recon_s)),[]); axis off; 

%% Wavelet operator

W=opWavelet2(n1,n2,'daubechies')
E3=E2*W'

%% ADD TFOCS SOLVER HERE 
%% Call the ADMM SOLVER 

A=E3;
b=Ku; 
lambda_max = norm( A'*b, 'inf' );
lambda = 0.1*lambda_max;
lambda=lambda*100
mu=1;
rho=1.0; 
[x history]=lassoADMM(A, b, lambda, mu,rho);


im_recon=W'*x;
figure(4); imshow(abs(matcc(im_recon)),[]); axis off; 


