
clear all; close all; clc; 
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/spot-master'))
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
disp('making operators')
mat = @(x) reshape(x,n1,n2,ncoils); %function that reshapes vector to matrix 
mat2d = @(x) reshape(x,n1,n2*ncoils); % functions that reshapes in 2d matrix for visualization purposes 
matcc =@(x) reshape(x,n1,n2); %function that reshapes vector to matrix 

AA=opDFT2(n1,n2,1) %DFT2 MATRIX
AA=AA*(1/sqrt(n1*n2))

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
phase_est=angle(linear_recon_s);

figure(3); subplot(121);imshow(abs(matcc(linear_recon_s)),[]); axis off; 
subplot(122);imshow((matcc(phase_est)),[]); axis off; 
%% phase correction
P=opDiag(exp(1i.*phase_est));
E3=E2*P;

linear_recon_sp=E3'*Ku;
figure(4); subplot(121);imshow(real(matcc(linear_recon_s)),[]); axis off; 
subplot(122);imshow(real(matcc(linear_recon_sp)),[]); axis off; 
title('linear recon without and with phase correction')
%% make wavelet operators

% Wavelet operator
W=opWavelet2(n1,n2,'haar',2,5)

E4=E3*W'


wavelet_lin_recon=W*(linear_recon_sp);
if length(wavelet_lin_recon)==224*160
figure(98); imshow((reshape(wavelet_lin_recon,224,160)),[0 0.1])
elseif length(wavelet_lin_recon)==256^2
figure(98); imshow(abs(reshape(wavelet_lin_recon,256,256)),[0 0.1])
else 
    
end
% Wav=Wavelet;
% kernel=[0 -1 0;-1 0 1; 0 1 0]
% % kernel=(1/9)*ones(3,3)
% TV=opConvolve(n1,n2,kernel,[0 0],'cyclic'); 
% E3=E2*TV'
%% ADD TFOCS SOLVER HERE (SAME ISSUES OF NON CONVERGENCE)


%% Call the ADMM SOLVER 

A=E4;
b=Ku; 
lambda_max = norm( A'*b, 'inf' );
lambda = 0.1*lambda_max*1;
mu=1;
rho=1.0; 
[x history]=lassoADMM(A, b, lambda, mu,rho);

im_recon=W'*x;
figure(5); imshow(abs(matcc(im_recon)),[]); axis off; 

figure(6); imshow(abs(reshape(W*im_recon,224,160)),[])
figure(7); imshow(abs(matcc(im_recon-linear_recon_sp)),[])

%% C-SALSA IMPLEMENTATION

y=Ku;
A=E3;
AT=A' ;
lambda=9e-7
invLS = @(x) (x - (1/(1+mu))*ones(length(A'*A),1))/mu;
% Phi_TV = @(x) TVnorm(real(x));
Phi_TV = @(x) W*(real(x));

mu=lambda*100;


[x_salsa, numA, numAt, objective, distance,  times]= ...
         SALSA_v2(y,A,lambda,...
         'AT', AT,...
         'Phi', Phi_TV, ...
         'LS', invLS, ...
         'Verbose', 1);
figure(8);imshow(abs(matcc(x_salsa)),[])










