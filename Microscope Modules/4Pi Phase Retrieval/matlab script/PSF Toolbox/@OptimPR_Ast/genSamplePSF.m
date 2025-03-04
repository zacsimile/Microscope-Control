function genSamplePSF(obj)
% genSamplePSF - generate sample PSFs used for 3D localization. 
%   The sample PSFs are a 3D stack of PSF images with finer sampling size
%   than measured PSFs. It is generated by calling the mexfunction
%   GPUgen_Ast_PSFv2, given a set of zernike coefficients from the phase
%   retrieval results.
[PSFst,sz]=GenSamplePSFsV1(obj.PRobj,obj.SampleS);
% OTF rescale
obj.OTFobj.SigmaX=obj.PRobj.PRstruct.SigmaX;
obj.OTFobj.SigmaY=obj.PRobj.PRstruct.SigmaY;
obj.OTFobj.Pixelsize=obj.SampleS.PixelSizeFine;
obj.OTFobj.PSFs=PSFst;
obj.OTFobj.scaleRspace();
samplepsfo=obj.OTFobj.Modpsfs;

obj.SamplePSF=single(samplepsfo);
obj.SamplePSFsize=sz;
obj.SampleSpacingXY=obj.SampleS.PixelSize/4;% um
obj.SampleSpacingZ=obj.SampleS.Devz;% um
xo = (sz(1) / 2 - 1)*obj.SampleS.PixelSizeFine;
obj.SampleS.StartX=-xo;% um
obj.SampleS.StartY=-xo;% um
obj.SampleS.StartZ=obj.SampleS.Dlimz(1);% 

end

function [PSFst,sz,xi,yi,zi,x0]=GenSamplePSFsV1(obj,sampleS)
pr=obj.PRstruct;
Nzern=(obj.ZernikeorderN+1)^2;
thresh=0;
zernc=GenZCoeffv1(obj,sampleS,thresh);
pxszCCD=sampleS.PixelSizeFine;
% generate simulate data
Num=numel(sampleS.Zstack);
x=(floor(sampleS.PsfSizeFine/2)-1.00001).*ones(Num,1);
y=x;
z=sampleS.Zstack; %um
Bg=zeros(Num,1);
Photon=ones(Num,1);
maxNum=100;
x0=cat(2,x,y,Photon,Bg,z);
VecA=[(1:maxNum:Num),Num+1];
PSFst=[];
Magnify=1;
for ii=1:length(VecA)-1
    Numi=diff(VecA(ii:ii+1));
    x0i=single(reshape(x0(VecA(ii):VecA(ii+1)-1,:)',Numi*sampleS.x0Size,1));
    [simPSF1]=GPUgen_Ast_PSFv2(x0i,...
        zernc.pCZ1_real,zernc.pCZ1_imag,...
        sampleS.OTFparam1,...
        int32(zernc.IndN1),int32(zernc.IndM1),...
        int32(zernc.IndZern1),...
        pxszCCD,Magnify,...
        pr.NA,pr.Lambda,pr.RefractiveIndex,...
        sampleS.PsfSizeFine,Numi,Nzern);
    
    PSFst=cat(3,PSFst,reshape(simPSF1,sampleS.PsfSizeFine,sampleS.PsfSizeFine,Numi));
end

sz=size(PSFst);

[xs,ys,zs]=meshgrid([0:sz(1)-1].*sampleS.PixelSizeFine,[0:sz(1)-1].*sampleS.PixelSizeFine,sampleS.Zstack);
Numi=numel(xs);
xi=single(reshape(xs,Numi,1));
yi=single(reshape(ys,Numi,1));
zi=single(reshape(zs,Numi,1));
PSFsi=single(reshape(PSFst,Numi,1));
sz=sz';
end
