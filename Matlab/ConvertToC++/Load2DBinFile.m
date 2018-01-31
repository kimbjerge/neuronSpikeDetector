function [ Data2D ] = Load2DBinFile( FileName, surfPlotName )

fileID = fopen(FileName);
TestData = fread(fileID, 'float');
fclose(fileID);

chs = 32;
len = length(TestData);
Data2D = zeros(len/chs,chs);
si = 1;
for i=1:chs:len
  Data2D(si,:) = TestData(i:i-1+chs);
  si = si +1;
end
clear TestData;

if( strcmp(surfPlotName, 'NO') == 0)
    figure, surf(Data2D);
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    title(['Unfiltered Raw Data : ' surfPlotName]);
end

end

