% COMPARING MMV MODEL TO OTHER TYPES OF RECONSTRUCTION
% FOR UNIFORM NSA CS ACQUISITIONS 

cd('/scratch/jschoormans/saved_K');
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/Code/implementingTFOCS'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations/Code'))

load('K_r_15092016_2117252_20_2_wipcstfe3fv3dyn3senseV4_noVC_grapefruit.mat')
disp('Loading finished!')
Korig=K;
%% get operators and parameters
[nx,n1,n2,ncoils,nave]=size(K); 
mat = @(x) reshape(x,n1,n2,ncoils);             % function that reshapes vector to matrix 
mat2d = @(x) reshape(x,n1,n2*ncoils);           % functions that reshapes in 2d matrix for visualization purposes 
matcc =@(x) reshape(x,n1,n2);                   % function that reshapes vector to matrix 

[Ku,KuNSA,E4,W,R,Filt,S2,MNSA,mask,pdf,sensmaps,linear_recon_s]=createSPOTops(K,1,1);

FASTA_linear_scaled=abs(matcc(linear_recon_s))./max(abs(linear_recon_s(:)));

%% FASTA CS 
opts = [];
opts.recordObjective = true;                    % Record the objective function so we can plot it
opts.verbose = true;
opts.stringHeader='    ';                       % Append a tab to all text output from FISTA.  This option makes formatting look a bit nicer. 
opts.accelerate = true;
opts.tol=1e-4; 
% opts.maxIters=50

A=@(x) E4*x;                                    % convert operator to function form 
AT=@(x) E4'*x;

mu=0.1                                          % control parameter

[sol, outs_adapt] = fasta_sparseLeastSquares(A,AT,Ku,mu,W*linear_recon_s, opts);
FASTA_CS_scaled=abs(matcc(W'*sol))./max(max(abs(matcc(W'*sol))));
figure(5); imshow([FASTA_linear_scaled,FASTA_CS_scaled],[])

%% cs not averaging (operator concatenated)

E5=vertcat(E4,E4,E4);
A2=@(x) E5*x;                                    % convert operator to function form 
A2T=@(x) E5'*x;

opts.maxIters=150;
mu2=mu*3;
[solCS2, outs_adapt] = fasta_sparseLeastSquares(A2,A2T,vec(KuNSA),mu2,W*linear_recon_s, opts);
FASTA_CS2_scaled=abs(matcc(W'*solCS2))./max(max(abs(matcc(W'*solCS2))));
figure(5); imshow([FASTA_linear_scaled,FASTA_CS_scaled,FASTA_CS2_scaled],[])


%% PICS CS
disp('to do ')
% bartRecon=bart('rsense -l1 -r0.01 -d5',permute(mean(Korig,5),[4 1 2 3]),fftshift(fftshift(sensmaps,2),3));


%%  FASTA MMV  
opts.maxIters=100
matnsa = @(x) reshape(x,n1,n2*nave);
mu=0.5                    %0.4 did well (2,0.1 way too high) (0.01 bit too low)
opt.tau=0.1           %0.1 did well 
opts.verbose=true; 
opts.maxIters=300


[solMMV, outs_adapt] = fasta_mmv(A,AT,KuNSA,mu,ones(size(E4'*KuNSA)), opts);

figure(10); imshow(abs(matnsa(W'*solMMV)),[])

FASTA_MMV_scaled=mean(W'*solMMV,2); %averaging in wavelet domain or image?
FASTA_MMV_scaled=abs(matcc(FASTA_MMV_scaled))./max(max(abs(matcc(FASTA_MMV_scaled))));
figure(5); imshow([FASTA_linear_scaled,FASTA_CS_scaled,FASTA_MMV_scaled],[])
 %% FASTA MMV RANDPERM (ONLY RELEVANT IN VIVO) 
 %{
tic
for i=1:length(KuNSA);
   KuNSAPerm(i,:)=KuNSA(i,randperm(6)); 
end
toc
 
[solMMV, outs_adapt] = fasta_mmv(A,AT,KuNSA,mu,ones(size(E4'*KuNSA)), opts);
figure(11); imshow(abs(matnsa(W'*solMMV)),[])

FASTA_MMV_R_scaled=mean(W'*solMMV,2); %averaging in wavelet domain or image?
FASTA_MMV_R_scaled=abs(matcc(FASTA_MMV_R_scaled))./max(max(abs(matcc(FASTA_MMV_R_scaled))));
figure(5); imshow([FASTA_linear_scaled,3*FASTA_CS_scaled,FASTA_MMV_scaled,FASTA_MMV_R_scaled],[0 1])
%}
 %%  FASTA MMV  WITH CS AS INPUT  
mu=0.5                    %0.4 did well (2,0.1 way too high) (0.01 bit too low)
% opt.tau=0.1           %0.1 did well 

[solCSMMV, outs_adapt] = fasta_mmv(A,AT,KuNSA,mu,repmat(sol,[1 nave]), opts);

figure(10); imshow(abs(matnsa(P'*W'*solMMV)),[])

FASTA_MMV_CS_scaled=mean(W'*solCSMMV,2); %averaging in wavelet domain or image?
FASTA_MMV_CS_scaled=abs(matcc(FASTA_MMV_CS_scaled))./max(max(abs(matcc(FASTA_MMV_CS_scaled))));
figure(5); imshow([FASTA_linear_scaled,FASTA_CS_scaled,FASTA_MMV_scaled,FASTA_MMV_CS_scaled],[])
 

%%  FASTA CS  WITH MMV AS INPUT  
mu=0.2                    %0.4 did well (2,0.1 way too high) (0.01 bit too low)
% opt.tau=0.1           %0.1 did well 

[solMMVCS, outs_adapt] = fasta_sparseLeastSquares(A,AT,Ku,mu,mean(solMMV,2), opts);

FASTA_CS_MMV_scaled=mean(W'*solMMVCS,2); %averaging in wavelet domain or image?
FASTA_CS_MMV_scaled=abs(matcc(FASTA_CS_MMV_scaled))./max(max(abs(matcc(FASTA_CS_MMV_scaled))));
figure(5); imshow([FASTA_linear_scaled,FASTA_CS_scaled,FASTA_MMV_scaled,FASTA_MMV_CS_scaled,FASTA_CS_MMV_scaled],[])
 
 
%% FASTA MMV COIL BY COIL 

coilK=reshape(Ku,[6160 ncoils]);

ECC=R*W';

AC=@(x) ECC*x;                                    % convert operator to function form
ACT=@(x) ECC'*x;

mu=3
[solMMVc, outs_adapt] = fasta_mmv(AC,ACT,reshape(Ku,[6160 ncoils]),mu,ones([25600 ncoils]),opts);
FASTA_MMVc=abs(matcc(S2*vec(W'*solMMVc)))./max(max(abs(matcc(S2*vec(W'*solMMVc)))));

 
figure(6); imshow(abs(mat2d(W'*solMMVc)),[])
figure(7); imshow(abs(matcc(S2*vec(W'*solMMVc))),[])

 %% FASTA MMV COIL AND AVERAGING SEPARATE
coilaveK=reshape(vec(KuNSA),[6160 ncoils*nave]);
mu=0.5

[solMMVca, outs_adapt] = fasta_mmv(AC,ACT,coilaveK,mu,ones([25600 ncoils*nave]),opts);

mat2coilave = @(x) reshape(x,n1,n2*ncoils*nave);           % functions that reshapes in 2d matrix for visualization purposes 

figure(8); imshow(abs(mat2coilave(W'*solMMVca)),[])

S3=horzcat(S2,S2,S2);
figure(9); imshow(abs(matcc(S3*vec(W'*solMMVca))),[])

FASTA_MMVcoilave=abs(matcc(S3*vec(W'*solMMVca)))./max(max(abs(matcc(S3*vec(W'*solMMVca)))));
figure(5); imshow([FASTA_linear_scaled,FASTA_CS_scaled,FASTA_MMV_scaled,FASTA_MMVc,4*FASTA_MMVcoilave],[])

 
 
 
 
 