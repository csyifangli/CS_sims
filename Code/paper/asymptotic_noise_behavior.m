

n=128;
A=abs(diag([-n:n]));
B=ones(size(A))*(A);
C=sqrt(B'.^2+B.^2);
figure(99); imshow(C,[])
%%
R=randn(size(B));

I=abs(ifft2(R.*(C<20)));
Id=diff(I,1,1);
figure(1);imshow(abs([I;Id]),[]); title('low frequency noise')
sum(abs(Id(:)))

I2=abs(ifft2(R.*(C>125)));
Id2=diff(I2,1,1);
figure(2);imshow(abs([I2;Id2]),[]); title('high frequency noise')
sum(abs(Id2(:)))
%% l1-norm of TV of noise for different frequency bands (width 10)
area=1e3
for fc=10:128
    fw=(1/2)*(area/(2*pi*fc));
    nn=(C>(fc-fw)).*(C<(fc+fw));
    %     figure; imshow(nn,[])    
    I=abs(ifft2(R.*(nn)));
    imshow(abs(I),[]);pause(0.01)

    Id=diff(I,1,1);
    l1(fc)=sum(abs(Id(:)));
end
    figure(99); plot(l1,'.'); title('noise'); xlabel('frequency (levels in kspace)')
    ylabel('l1 norm of sparsity (TV)')
    
    % l1-norm of TV of image for different frequency bands (width 10)
head=imread('head256.jpg');  
head=double(head(:,:,1));
khead=fftshift(fftshift(fft2(head),1),2);

figure;
C2=C(2:257,2:257);
for fc=10:128
    fw=(1/2)*(area/(2*pi*fc));
    nn=(C2>(fc-fw)).*(C2<(fc+fw));
    I=real(ifft2(khead.*(nn)));
    imshow(abs(I),[]);pause(0.01)
    
    Id=diff(I,1,1);
    l1_im(fc)=sum(abs(Id(:)));
end
figure; plot(l1_im); title('image'); xlabel('frequency (levels in kspace)')
ylabel('l1 norm of sparsity (TV)')

    %%
    figure(3);
    hold on
    plot(l1./max(l1(:)),'.-');
    plot(l1_im./max(l1_im(:)),'.-'); 
    title('noise & image'); xlabel('frequency (levels in kspace)')
    ylabel('l1 norm of sparsity (TV)'); legend('noise','image')

    %% EVALUATE AS IN HANSEN
    clear l1 l1_im
    area=150
    tre=4.75;
    
    for fc=10:128
        fw=(1/2)*(area/(2*pi*fc));
        nn=(C>(fc-fw)).*(C<(fc+fw));
        %     figure; imshow(nn,[])
        I=abs(ifft2(R.*(nn)));
        Id=diff(I,1,1);
        threshold=tre*mean(abs(Id(:)))
        l1(fc)=sum(abs(Id(:))>threshold);
    end
    figure; plot(l1,'.'); title('noise'); xlabel('frequency (levels in kspace)')
    ylabel('l1 norm of sparsity (TV)')
    
    % l1-norm of TV of image for different frequency bands (width 10)
    head=imread('head256.jpg');
    head=double(head(:,:,1));
    khead=fftshift(fftshift(fft2(head),1),2);
    
    C2=C(1:256,1:256);
    for fc=10:128
        fw=(1/2)*(area/(2*pi*fc));
        nn=(C2>(fc-fw)).*(C2<(fc+fw));
        I=abs(ifft2(khead.*(nn)));
        Id=diff(I,1,1);
        threshold=tre*mean(abs(Id(:)))
        l1_im(fc)=sum(abs(Id(:))>threshold);
    end
    figure; plot(l1_im); title('image'); xlabel('frequency (levels in kspace)')
    ylabel('l1 norm of sparsity (TV)')
    
    figure; hold on;
    plot(l1_im,'-*');
    plot(l1,'-*');
    
    title('noise & image');xlabel('frequency (levels in kspace)')
    ylabel('l0 norm of sparsity (TV; larger than certain threshold)');legend('noise','image')
