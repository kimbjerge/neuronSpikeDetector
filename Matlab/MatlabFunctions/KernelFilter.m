function [ outputData ] = KernelFilter( KernelFilterType, inputData )
%KERNELFILTER Summary of this function goes here
%   Detailed explanation goes here
    
if strcmp(KernelFilterType, 'Laplacian')
    H = fspecial('laplacian'); % Original
    outputData = imfilter(inputData,H,'replicate');
elseif strcmp(KernelFilterType, 'GradientX')
    H = fspecial('gaussian');
    [Gx,~] = gradient(H); 
    outputData = imfilter(inputData,Gx,'replicate');
elseif strcmp(KernelFilterType, 'GradientY')
    H = fspecial('gaussian');
    [~,Gy] = gradient(H); 
    outputData = imfilter(inputData,Gy,'replicate');
else
    outputData = inputData;
end

end

