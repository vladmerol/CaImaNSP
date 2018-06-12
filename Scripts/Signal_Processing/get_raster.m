% Function to get Raster choosing Method:
% 1: Driver Seignal by Sparse Deconvolution
% 2: Oopsi algorithm
% 3: Derivative method
% Input
% Method: [1,2,3]->{Sparse,oopsi,derivative}
% VARARGIN: according to the method
% Mode 1: Sparse Deconvolution 
%       Driver Signal
%       ActiveNeurons
%       TotalCells
% Mode 2: Deconvolution
%       Detrended Signal: Only Detected Neurons
%       ActiveNeurons
%       TotalCells
% Mode 3: Derivative of Cleaned Signal
%       Driver Signal
%       ActiveNeurons
%       TotalCells
%       Response Function
% Output
% R:        Raster Row vectors of activity
function R=get_raster(method,varargin)
%% Setup Raster Method
switch method
    case 1  % Sparse Deconvolutoin (the chido one)
        D=varargin{1};
        ActiveNeurons=varargin{2};
        TotalCells=varargin{3};
        [AN,F]=size(D);
        R=zeros(TotalCells,F);
        if ~isempty(ActiveNeurons)
            for n=1:AN
                % [~,Np]=findpeaks(D(n,:)); % way too clean
                R(ActiveNeurons(n),D(n,:)>0)=1;
            end
        end
    case 2  % oopsi method
        XD=varargin{1};
        ActiveNeurons=varargin{2};
        TotalCells=varargin{3};
        TAUS=varargin{4};
        fs=varargin{5};
        Xest=varargin{6};
        [AN,F]=size(XD);
        R=zeros(TotalCells,F);
        V.dt=1/fs;
        V.smc_iter_max = 1;
        if ~isempty(ActiveNeurons)
            for n=1:AN
                xd=XD(n,:);
                xe=Xest(n,:);
                P.sig=std(xd-xe);
                tau=TAUS(n,2);
                P.gam   = 1-V.dt/tau;
                y=fast_oopsi(xd,V,P);
                d=zeros(1,F);
                d(find(y>1))=1;
                R(ActiveNeurons(n),d>0)=1;
            end
        end
        
    case 3  % Derivative Method
        D=varargin{1};
        ActiveNeurons=varargin{2};
        TotalCells=varargin{3};
        FR=varargin{4};
        [AN,F]=size(D);
        R=zeros(TotalCells,F);
        if ~isempty(ActiveNeurons)
            for n=1:AN
                d=D(n,:);
                r=FR(n,:);
                x_sparse=sparse_convolution(d,r);
                dx_sparse=diff(x_sparse);
                R(ActiveNeurons(n),dx_sparse>0)=1;
            end
        end
                
    otherwise
        disp('No method'); % not even happening
end