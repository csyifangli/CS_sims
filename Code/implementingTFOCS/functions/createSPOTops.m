 function [Ku,KuNSA,E4,W,R,Filt,S2,MNSA,mask,pdf,sensmaps,linear_recon_s]=createSPOTops(K,visualize,phasecorr);
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/solvers'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/spot-master'));
addpath(genpath('/opt/amc/bart')); vars; 
% K : kspace matrix size(nx,ny,nz,ncoils,NSA)
% visualize 1/0

%outputs: 
%E4: encoding operator
% W: wavelet operator
% MNSA: matrix of number of averages per point
%mask 

% in ontwikkeling,,, j schoormans feb 2017 
% TO DO 
% visualize flag

disp('setting up measurement vector')
sl=10;                                           %slice to reconstruct
[nx,n1,n2,ncoils,nave]=size(K);                   %get parameters

[mask,MNSA] = makemasks(K) ; 
%% make data 
KNSA=ifft(K,[],1);
KNSA=squeeze(KNSA(sl,:,:,1:ncoils,:));
for i=1:nave
    KNSAn=KNSA(:,:,:,i);
    KuNSA(:,i)=vec(KNSAn(repmat(mask,[1 1 ncoils])));
end

data=sum(K,5);                                  %sum of data over NSA

K=data./permute(...
    repmat(MNSA,[1 1 nx ncoils]),[3 1 2 4]);    % TAKE MEAN OF MEASURED VALUES
K(isnan(K))=0;                                  % set nans to zero

K=ifft(K,[],1);                                 % FOR NOW: iFFT along read dim
K=squeeze(K(sl,:,:,:));                         % select subset of k-space

Ku=vec(K(repmat(mask,[1 1 ncoils])));           % vectorize measurement data (excluding non-meas values)

figure(1); imshow(abs([K(:,:,1)./max(K(:)),mask]),[0 1]); axis off; title('kspace and mask')

%% make operators 
disp('setting up undersampled Fourier operator')

mat = @(x) reshape(x,n1,n2,ncoils);             % function that reshapes vector to matrix 
mat2d = @(x) reshape(x,n1,n2*ncoils);           % functions that reshapes in 2d matrix for visualization purposes 
matcc =@(x) reshape(x,n1,n2);                   % function that reshapes vector to matrix 

F=opDFT2(n1,n2,1);                              % DFT2 MATRIX

l=[1:n1*n2];
mask2=(l(~mask(:)));                            % indices of rows in FDT2 matrix that should be removed (were not sampled!)
R=opExcise(F,mask2,'rows');                     % remove non-sampled rows from Fourier matrix 
E1=createmulticoilDFT(R,ncoils)                 % make block-diagonal copies, one for each channel 

pdf=estPDF(double(mask));
Filt=opDiag(repmat(1./pdf(mask),[ncoils,1]))       %filter operator 


%% perform linear recon, sensitivity maps 
disp('linear reconstruction')
linear_recon=E1'*Filt*Ku;                            % linear recon (should change to least-squares??)

sensmaps=estSensemaps(K,sl);

figure(2)
imshow(abs([...
    mat2d(linear_recon./max(linear_recon(:)));...
    mat2d(sensmaps./max(sensmaps(:)))]),[]);  axis off;  
title('linear recon for all channnels')

%% estimate phase per channel


S2=createmulticoilSense(sensmaps,ncoils)                      % operator to multiply sens maps with image

E2=E1*S2';                                      % Encoding matrix ; DFT and inverse sense maps 

linear_recon_s=E2'*Filt*Ku;                      % linear recon including coil combination and filtering for undersampling     
figure(3); 
imshow(abs(matcc(linear_recon_s)),[]); axis off; title('coil-combined linear recon')

%% ADD PHASE OPERATOR 
disp('estimating phase, setting up phase correction operator')
if phasecorr==true
phase_est=angle(E2'*Ku);                        % estimate phase image from unfiltered linear recon
P=opDiag(exp(-1i.*phase_est));                  % define phase correction operator 

E3=E1*S2'*P';                                       % add phase corr to encoding matrix
else
    E3=E1*S2';                                       % do not add phase corr to encoding matrix
end

linear_recon_sp=E3'*Ku;                         % phase corrected linear reconstruction 

figure(4); subplot(121);imshow(real(matcc(linear_recon_s)),[]); axis off;
title('linear recon without phase correction')
subplot(122);imshow(real(matcc(linear_recon_sp)),[]); axis off; 
title('linear recon with phase correction')

%% Wavelet operator
disp('setting up wavelet operator')

W=opWavelet2(n1,n2,'daubechies',4,4,0);         % define 2D wavelet operator (unsure about filter and length!)
% FUN{1}= @(x) bartwav(x,n1,n2,1);
% FUN{2}= @(x) bartwav(x,n1,n2,2);
% W=opFunction(n1*n2,n1*n2,FUN);                %define BART wavelet ops;

E4=E3*W';                                       % add inverse wavelet op to encoding matrix



 end

 function E1=createmulticoilDFT(R,ncoils)
BDcommand='E1=opBlockDiag('
for i=1:ncoils-1; 
BDcommand= [BDcommand,'R,']; end
BDcommand=[BDcommand,'R)'];
eval(BDcommand); 
 end

  function S2=createmulticoilSense(sensmaps,ncoils)
  
  for i=1:ncoils; 
    S{i}=opDiag(conj(sensmaps(1,:,:,i)));       % make individual coil multiplication operators (conj because it is actually the inverse op!)
end; 
  
  
BDcommand='S2=horzcat('
for i=1:ncoils; 
BDcommand= [BDcommand,'S{',num2str(i),'}']; 
if i~=ncoils
    BDcommand=[BDcommand,',']; end
end
BDcommand=[BDcommand,')'];
eval(BDcommand); 
  end
 
  function [mask,MNSA] = makemasks(K) 
  Ks=squeeze(K(round(size(K,1)/2),:,:,1,:));      %k-space for one channel and one slice
  fullmask=Ks~=0;                                 %find mask used for scan (nx*ny*NSA)
  MNSA=sum(fullmask,3);                           %find NSA for all k-points in mask
  mask=fullmask(:,:,1);                               % find mask that was used for measurements

  end
  
  function sensmaps=estSensemaps(K,sl)
  disp('estimating sense maps and setting up S operator')
  sensmaps=bart('ecalib -r25 -S -m1 -k5',permute(K,[4 1 2 3]));  %% make sense maps with espirit method
  sensmaps=fftshift(fftshift(sensmaps(1,:,:,:),3),2);
  end
  