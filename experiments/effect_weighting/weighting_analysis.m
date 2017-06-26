
clear all; close all
varsVNSA
if ispc()
    folder=('L:\basic\divi\Ima\parrec\Jasper\VNSA\VNSA_71\2017_06_16\VN_5469\' )
    cd('L:\basic\divi\Projects\cosart\CS_simulations\experiments\effect_weighting')
else
    folder=('/home/jschoormans/lood_storage/divi/ima/parrec/jasper/VNSA/VNSA_71/2017_06_16/VN_5469/' )
    cd('L:\basic\divi\Projects\cosart\CS_simulations\experiments\effect_weighting') % to change 
end
files=dir([folder,'/*.raw'])
filenumber=5;
%%
MR=Recon_varNSA_CS(strcat(folder,files(filenumber).name));
MR.Perform1;

%% figure
TVWeight=3e-6
xfmWeight=2*TVWeight;
MR.P.TVWeight=TVWeight
MR.P.xfmWeight=xfmWeight

slices=[20,150]
for nslices=1:2
    
MR.P.reconslices=[slices(nslices)];
MR.P.WeightedL2=1;
MR.P.VNSAlambdaCorrection=1;
MR.ReconCS
R11{nslices}=MR.P.Recon;

MR.P.WeightedL2=1;
MR.P.VNSAlambdaCorrection=0;
MR.ReconCS
R10{nslices}=MR.P.Recon;

MR.P.WeightedL2=0;
MR.P.VNSAlambdaCorrection=0;
MR.ReconCS
R00{nslices}=MR.P.Recon;

Nfactor=4;
MR.P.TVWeight=TVWeight*Nfactor;
MR.P.xfmWeight=xfmWeight*Nfactor;
MR.P.WeightedL2=0;
MR.P.VNSAlambdaCorrection=0;

MR.ReconCS
RN{nslices}=MR.P.Recon;
end
% calculate noise spectrum II
ACF = @(x) conv(x,-x)
PSD = @(x) fftshift(fft(ifftshift(ACF(x))))
nn=18;

for ii=1:nn
PSD00(:,ii)=PSD(squeeze(R00{1}(1,:,ii)));
PSD11(:,ii)=PSD(squeeze(R11{1}(1,:,ii)));
PSD10(:,ii)=PSD(squeeze(R10{1}(1,:,ii)));
PSDN(:,ii)=PSD(squeeze(RN{1}(1,:,ii)));
end
%% figures 
close all
figure(1);
imshow(abs(cat(2,squeeze(R00{2}),squeeze(R10{2}),squeeze(R11{2}),squeeze(RN{2}))),[])
title('no W ,\lambda_0  |   W, \lambda_0  |  W, \lambda_c  |  no W,\lambda_N,')
export_fig '1.eps' -eps

figure(3); imshow(squeeze(R00{1}(1,:,1:nn)),[]); title('image section used for calculating noise spectral density')

figure(4); hold on;
plot(sum(abs(PSD00),2),'k');
plot(sum(abs(PSD10),2),'c')
plot(sum(abs(PSD11),2),'g')
plot(sum(abs(PSDN),2),'y')
hold off
title('PSD'); 
legend('no W ,\lambda_0','W, \lambda_0','W, \lambda_c','W, \lambda_N')
%
freqs=linspace(-1,1,599)
x10=100*((sum(abs(PSD00),2))-(sum(abs(PSD10),2)))./(sum(abs(PSD00),2))
x11=100*((sum(abs(PSD00),2))-(sum(abs(PSD11),2)))./(sum(abs(PSD00),2))
xN=100*((sum(abs(PSD00),2))-(sum(abs(PSDN),2)))./(sum(abs(PSD00),2))

figure(5); 
hold on 
plot(freqs,(x10),'g','LineWidth',1.5)
plot(freqs,(x11),'r','LineWidth',1.5)
plot(freqs,(xN),'k','LineWidth',1.5)

xlabel('spatial frequency')
ylabel('difference (%)')
title('ratio of  Weightedl2 norm and normal l2 norm')
legend('same \lambda','adapted \lambda','extra \lambda')
%% compare quality by line plots
y=40;
figure(6); clf
plot(abs(squeeze(R00{2}(1,:,y))),'k');
hold on; 
plot(abs(squeeze(R11{2}(1,:,y))),'g');
% plot(abs(squeeze(R11(1,:,y))),'r');
% plot(abs(squeeze(RN(1,:,y))),'b');

%% PART 2: no lambda
%% figure
MR.P.TVWeight=0
MR.P.xfmWeight=0

slices=[20,150]
for nslices=1:2
    
MR.P.reconslices=[slices(nslices)];
MR.P.WeightedL2=1;
MR.P.VNSAlambdaCorrection=1;
MR.ReconCS
R11_noL{nslices}=MR.P.Recon;

MR.P.WeightedL2=0;
MR.P.VNSAlambdaCorrection=0;
MR.ReconCS
R00_noL{nslices}=MR.P.Recon;

end
% calculate noise spectrum II
ACF = @(x) conv(x,-x)
PSD = @(x) fftshift(fft(ifftshift(ACF(x))))
nn=18;

for ii=1:nn
PSD00_noL(:,ii)=PSD(squeeze(R00_noL{1}(1,:,ii)));
PSD11_noL(:,ii)=PSD(squeeze(R11_noL{1}(1,:,ii)));
end
%% figures 
figure(11);
imshow(abs(cat(2,squeeze(R00_noL{2}),squeeze(R11_noL{2}))),[])

figure(14); hold on;
plot(sum(abs(PSD00_noL),2),'k');
plot(sum(abs(PSD11_noL),2),'c')
hold off
title('PSD'); 

x11=100*((sum(abs(PSD00_noL),2))-(sum(abs(PSD11_noL),2)))./(sum(abs(PSD00_noL),2))

figure(15); 
plot(freqs,(x11),'r','LineWidth',1.5)
xlabel('spatial frequency')
ylabel('difference (%)')
title('ratio of  Weightedl2 norm and normal l2 norm')
legend('same \lambda','adapted \lambda','extra \lambda')


figure(16) % mask 
imshow(abs(MR.P.MNSA),[])




