% prewhiten data test; 
cd('/home/jschoormans/lood_storage/divi/Projects/cosart/CS_simulations')
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/MRIPhantomv0-8'))
addpath(genpath('/home/jschoormans/lood_storage/divi/Projects/cosart/Matlab_Collection/tightfig'))

clear all; close all; clc;


%simulate k-space
[K,sens]=genPhantomKspace(512,1);
sens=permute(sens,[1 2 4 3]);
% P=phantom('Shepp-Logan',512);
% K=ifft2(P);

ny=size(K,2);
nz=size(K,1);
% sens=ones(ny,nz); %change to sense based on phantoms...

%%

acc=5
%sampling pattern
[pdf,val] = genPDF(size(K(:,:,1)),5,1/acc,2,0,0);
Mfull=genEllipse(size(K,1),size(K,2));
Mfull=repmat(Mfull,[1 1 size(K,3)]); %add coils

M=genSampling(pdf,10,100).*Mfull;


for jjj=1:3
    if jjj==1
        MNSA=ceil(1./pdf);
    elseif jjj==2
        MNSA=ceil(pdf*acc);

    else
        MNSA=acc*ones(size(MNSA));
    end

%% add noise to kspace
clear Ku_N2
NoiseLevel=5e-4;
for iii=1:max(MNSA(:)) %Matrix of NSA values
K_N=addNoise(K,NoiseLevel);
Ku_N1=repmat(squeeze(M(:,:).*(MNSA(:,:)>=iii)),[1 1 size(K,3)]).*K_N;
Ku_N2(1,:,:,:,1,iii)=permute(Ku_N1,[1,2,3,4]);
end
Ku_Nvar1=sum(Ku_N2,6)./permute(repmat(MNSA,[1 1 size(K,3)]),[4 2 1 3]);
disp('check dimensions')

sum(MNSA(:).*M(:))
sum(Mfull(:))
%% RECONS 
% ORDINARY RECON
reg=0.05
R1{jjj}=bart(['pics -RW:7:0:',num2str(reg),' -S -e -i20 -d5'],K_N.*Mfull,sens(end:-1:1,end:-1:1,:,:));
figure(99); imshow(abs(R1{jjj}),[])
%% RECON R2: WITHOUT PREAVERAGING
clear traj2;
[kspace, traj]=calctrajBART(permute(Ku_N2,[1 2 3 4 6 5])); 
traj2(1,1,:)=traj(3,1,:); traj2(2,1,:)=traj(2,1,:); traj2(3,1,:)=traj(1,1,:); %FOR 2D signals; when we do not want ANY frequency encoding!
R2{jjj}=bart(['pics -RW:7:0:0.02 -S -m -i50 -d5 -t'],traj2,kspace,sens);

%% RECON R3: same traj, with preaveraging
 clear traj2;
[kspace, traj]=calctrajBART((Ku_Nvar1)); 
traj2(1,1,:)=traj(3,1,:); traj2(2,1,:)=traj(2,1,:); traj2(3,1,:)=traj(1,1,:); %FOR 2D signals; when we do not want ANY frequency encoding!
R3{jjj}=bart('pics -RW:7:0:0.02 -S -m -i50 -d5 -t',traj2,kspace,sens);

end


%%
% VISUALIZATION

hfig=figure(1)

for jjj=1:3
subplot(3,3,1+(jjj-1)*3)
imshow(abs(squeeze(R1{jjj})),[])
axis off

subplot(3,3,2+(jjj-1)*3)
imshow(abs(squeeze(R2{jjj})),[])
axis off

subplot(3,3,3+(jjj-1)*3)
imshow(abs(squeeze(R3{jjj})),[])
axis off
end
tightfig(hfig);

%%
R_baseline=bart(['pics -RW:7:0:',num2str(reg),' -S  -e -i100'],K,sens);

figure(3)
hold on
plot(abs(squeeze(R2{3}(98,:))),'k')
plot(abs(squeeze(R2{2}(98,:))),'r')
% plot(abs(squeeze(R{3}(98,:))),'b')
plot(abs(squeeze(R_baseline(98,:))),'y')
legend('pre-av','no pre-av')
hold off
%%
for jjj=1:3
    F{1,jjj}=ssim(abs(R1{jjj})./max(abs(R1{jjj}(:))),abs(R_baseline)./max(abs(R_baseline(:))))
    F{2,jjj}=ssim(abs(R2{jjj})./max(abs(R2{jjj}(:))),abs(R_baseline)./max(abs(R_baseline(:))))
    F{3,jjj}=ssim(abs(R3{jjj})./max(abs(R3{jjj}(:))),abs(R_baseline)./max(abs(R_baseline(:))))
end
