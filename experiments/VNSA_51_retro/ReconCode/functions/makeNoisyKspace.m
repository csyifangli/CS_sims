function [K_N, Ku_Nvar1,Ku_N2,P]=makeNoisyKspace(K,P)
% load k-space data and add noise and stuff
%input: P.acc;  
% P.jjj=1: periphery; 
% 2: center
% 3: uniform
% 4: ones(undersampled)
% P.NoiseLevel

%outputs K_N: noisy full k-space
%Ku_Nvar1: undersampled and averaged k-space
%p.MNSA: matrix of number of averages


%make masks
[pdf,~] = genPDF(size(K(:,:,1)),4,1/P.acc,2,0,0);
Mfull=genEllipse(size(K,1),size(K,2));
Mfull=repmat(Mfull,[1 1 size(K,3)]); %add coils
M=genSampling(pdf,10,100).*Mfull;

% make weighting scheme 
if P.jjj==1
    MNSA=ceil(1./pdf);
elseif P.jjj==2
    MNSA=ceil(pdf*P.acc);
elseif P.jjj==3
    MNSA=P.acc*ones(size(pdf));
elseif P.jjj==4
    MNSA=ones(size(pdf));

end
P.MNSA=MNSA; %export MNSA


%% add noise to kspace
for iii=1:max(MNSA(:)) %Matrix of NSA values
K_N=addNoise(K,P.NoiseLevel);

Ku_N1=repmat(squeeze(M(:,:).*(MNSA(:,:)>=iii)),[1 1 size(K,3)]).*K_N;

Ku_N2(1,:,:,:,1,iii)=permute(Ku_N1,[1,2,3,4]);

end

Ku_Nvar1=sum(Ku_N2,6)./permute(repmat(MNSA,[1 1 size(K,3)]),[4 2 1 3]);



end 