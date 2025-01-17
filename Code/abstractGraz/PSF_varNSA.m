% CALCULATE POINT-SPREAD FUNCTIONS OF NOISE
addpath(genpath('L:\basic\divi\Projects\cosart\CS_simulations/'))
[pdf,~] = genPDF([512 512],4,1/5,2,0,0);
M=genSampling(pdf,10,100);
%%
clear Incoherence
noisevector=[0:5e-1:15]
noisecounter=0
for noise=noisevector
    noise
    noisecounter=noisecounter+1;
Mnoise=M.*ones(size(M))+M.*randn(size(M)).*noise;
Inoise=fftshift(fftshift(fft2(Mnoise),1),2);
Inoise=Inoise./max(Inoise(:));
S=sort(abs(Inoise(:)),'descend');
Incoherence(noisecounter)=S(2);
end

%%
clear IncoherenceC IncoherenceB
noisecounter=0
for noise=noisevector
    noise
    noisecounter=noisecounter+1;
%     Mnoise=M.*ones(size(M))+(M.*randn(size(M)).*noise.*(pdf<0.239)*sqrt(2))+(M.*randn(size(M)).*noise.*(pdf>0.239)./(sqrt(3)/sqrt(2))); %change this!
    Mnoise=M.*ones(size(M))+(M.*randn(size(M)).*noise.*(pdf<0.239)*sqrt(2)); %change this!


Inoise=fftshift(fftshift(fft2(Mnoise),1),2);
Inoise=Inoise./max(Inoise(:));
S=sort(abs(Inoise(:)),'descend');
IncoherenceC(noisecounter)=S(2);
end
noisecounter=0
for noise=noisevector
    noise
    noisecounter=noisecounter+1;
%     Mnoise=M.*ones(size(M))+(M.*randn(size(M)).*noise.*(pdf<0.239)*sqrt(2))+(M.*randn(size(M)).*noise.*(pdf>0.239)./(sqrt(3)/sqrt(2))); %change this!
    Mnoise=M.*ones(size(M))+(M.*randn(size(M)).*noise.*(pdf>0.239)*sqrt(2)); %change this!


Inoise=fftshift(fftshift(fft2(Mnoise),1),2);
Inoise=Inoise./max(Inoise(:));
S=sort(abs(Inoise(:)),'descend');
IncoherenceB(noisecounter)=S(2);
end

%%
figure(500)
hold on
plot(noisevector,Incoherence,'r+');
hold off
set(gcf,'Color','white');
xlabel('noise level')
ylabel('Incoherence')

figure(501)
hold on
plot(noisevector,IncoherenceC,'r+');
plot(noisevector,IncoherenceB,'b+');
hold off
set(gcf,'Color','white');
xlabel('noise level')
ylabel('Incoherence')
