%% Function to load fluorescence signals from videos
%  using the ring acquisition method
% Input
%   mov: video of grayscale pixels
%   XY: Coordinates of active signals
% If ImPatch/fSIENN ROI File
%   r: vector array of circle's radius 
% If ImageJ ROI File
%   r:  cell of pixels in ellyptical ROIs 
% Output
%   FluoSignals: Matrix of Fluorescence Signals
function [FS]=Fluorescence_Load(mov,XY,r)
%% Start
FS=[];                          % Fluorescence Signals
F=length(mov);                  % Number of frames
[H,W]=size(mov(1).cdata);       % Size of the frames
[NS,~]=size(XY);                % Number of Signals
if iscell(r)
    fprintf('>>ImageJ ROI setlist\n')
    circleROI=false;
else
    fprintf('>>ImPatch ROI setlist\n')
    circleROI=true;
end
%% MAIN LOOP
for n=1:NS      % for every coordinate
    fprintf('Signal: %i/%i: ',n,NS)
    if circleROI
        % Circle's Area Pixels ***************************************
        Mx=XY(n,1)-(r):XY(n,1)+(r); % range in x of square
        My=XY(n,2)-(r):XY(n,2)+(r); % range in y of square
        Mesh_XY=[]; aux1=1;
        for i=1:length(Mx)
            % chech if it's in image's limits Xaxis
            if Mx(i)>0 && Mx(i)<=W 
                for j=1: length(My)
                    % chech if it's in image's limits Yaxis
                    if My(j)>0 && My(j)<=H 
                        % check if it's in circle
                        if (Mx(i)-XY(n,1))^2+(My(j)-XY(n,2))^2<=r(n)^2
                            Mesh_XY(aux1,:)=[Mx(i),My(j)];
                            aux1=aux1+1;
                        end
                    end
                end
            end
        end
    else
        % Ellipse's Area Pixels ***************************************
        Mesh_XY=r{n};
        % X-Coordinates in Width
        xokindex=find(Mesh_XY(:,2)<=W);
        % Y-Coordinates in Height
        yokindex=find(Mesh_XY(:,1)<=H);
        OKindx=intersect(xokindex,yokindex);
        Mesh_XY=[Mesh_XY(OKindx,2),Mesh_XY(OKindx,1)];
    end
    % Fluorescence ***********************************************
    FluorSignal=zeros(1,F);
    for f=1:F   % for every frame
        % Frame Size: H x W: [rows x columns]
        Fdata=mov(f).cdata(Mesh_XY(:,2),Mesh_XY(:,1));
        FluorSignal(f)=mean(Fdata(:));
    end
    FS=[FS;FluorSignal];
    fprintf('loaded\n');
end
