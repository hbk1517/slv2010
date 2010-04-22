[y,fs,nbits,opts]=wavread('sample.wav');
fwsample=fopen('sample.hex','wt');
fprintf(fwsample,'%x\n',(y*(2^7))+(y<0)*(2^8));
a=(2^-11)*[8,-25,-84,235,890,890,235,-84,-25,8];
yf=filter(a,1,y);
yf=round(yf*2^7);
fwsampleoutgolden=fopen('sampleoutgolden.hex','wt');
fprintf(fwsampleoutgolden,'%x\n', yf+(yf<0)*(2^8));
wavwrite(yf/(2^7),fs,nbits,'sampleoutgolden.wav');