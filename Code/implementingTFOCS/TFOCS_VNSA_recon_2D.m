%{
     Tests total-variation problem and l1 analysis
        on a large-scale example -- VNSA SCANS

    min_x   alpha*||x||_TV + beta*||Wx||_1
s.t.
    || A(x) - b || <= eps

where W is a wavelet operator.
%}

clear all; close all; clc; 
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/spot-master'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/Wavelab850'))
addpath /home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/TFOCS-1.4


%%
cd('/home/jschoormans/lood_storage/divi/Ima/parrec/Jasper/VNSA/VNSA12')
% load('K_n_10022017_1139424_3_2_wipvnsaacc5v1senseV4_VC6')
load('K_n_12022017_1411245_2_2_wipvnsaprescanfullfa2senseV4_noVC')
% load('K_n_12022017_1416122_3_2_wipvnsafa2acc5v1senseV4_noVC')
% load('K_n_12022017_1420335_4_2_wipvnsafa2acc5v3senseV4_noVC')
K_orig=K; 

%% 1: simple 2D example; iFFT in z-direction, one NSA

sl=50

K=K_orig(:,:,:,1); % only take first NSA for now;;;
K=ifft(K,[],1); 
K=squeeze(K(sl,:,:));

mask=K~=0;


figure(1); imshow(abs([K./max(K(:)),mask]),[0 1]); axis off; 

Ku=K(mask);
%% make operators 

[n1,n2]=size(K)
mat = @(x) reshape(x,n1,n2); %function that reshapes vector to matrix 


AA=opDFT2(n1,n2,1) %DFT2 MATRIX

l=[1:n1*n2];
mask2=(l(~mask(:))); %indices of rows in FDT2 matrix that should be removed (were not sampled!)
R=opExcise(AA,mask2,'rows')
E=R;

%% perform linear recon 

linear_recon=E'*Ku;

figure(2); imshow(abs(mat(linear_recon)),[]); axis off;


%% perform optimization algo 


%% Call the TFOCS solver

mu              = 5;
er              = @(x) norm(x(:)-linear_recon(:))/norm(linear_recon(:)); %NOT SURE ABOUT THIS: WE DONT KNOW SOLUTION YET...
opts = [];
opts.errFcn     = @(f,dual,primal) er(primal);
opts.maxIts     = 200;
opts.printEvery = 20;
opts.tol        = 1e-8;
opts.stopcrit   = 4;
opts.alg='GRA'  

x0 = linear_recon;  %first guess
z0  = [];           % we don't have a good guess for the dual (is this true)


a=0;
% build operators:
% A           = linop_handles([N,N], @(x)fft2(x), @(x)ifft2(x),'c2c');
A=linop_spot(E,'c2c')
normA2      = 1;
W_wavelet   = linop_spot(opWavelet2(n1,n2,'daubechies'),'c2c');
normWavelet      = linop_normest( W_wavelet );

contOpts            = [];
contOpts.maxIts     = 4;


EPS=2e3
[x_wavelets,out_wave] = solver_sBPDN_W( A, W_wavelet, double(Ku), EPS, mu, ...
    x0(:), z0, opts, contOpts);


 %possible reweighting here
 
 figure(3); imshow(abs([mat(x_wavelets),mat(linear_recon)]),[])