function  res = MCp2DFT(mask,imSize,sensmaps,phase,mode)

%res = p2DFT(mask,imSize [ ,phase,mode])
%	Implementation of partial Fourier operator.
%	
%	input:
%			mask - 2D matrix with 1 in entries to compute the FT and 0 in ones tha
%				are not computed.
%			imSize - the image size (1x2)
%			phase - Phase of the image for phase correction
%			mode - 1- real, 2-cmplx
%

if nargin <4
	phase = 1;
end
if nargin <5
	mode = 2; % 0 - positive, 1- real, 3-cmplx
end

if ndims(sensmaps)>3;
    error('sense maps should have 3 dimensions')
end

res.sensmaps=sensmaps;
res.nchans=size(sensmaps,3);
res.adjoint = 0;
res.mask = mask;
res.imSize = imSize;
res.dataSize = size(mask);
res.ph = phase;
res.mode = mode;
res = class(res,'MCp2DFT');

