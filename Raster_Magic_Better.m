% Main script to Load & Process Calcium Fluorescence Signals
% It detects Calcium Transients from VIDEOS of a single slice (EXPERIMENT)
% Sugggested Directorie's Strcuture:
% NAME_EXPERIMENT/ {VIDEOS & Coordinates from fSIENN):
% Input (same directory): 
%   ALL (XY).csv        Coordinates from 4th row x,y,r
%   Condition_A_00.avi
%   Condition_A_01.avi
%   ...
%   Condition_B_00.avi
%   ... 
%   Condition_Z_##.avi
% Output
%   ExperimentID.mat @ cd ..\Processed Data: Useful Workspace Variables
%   ExperimentID.csv @ cd ..\Features Tables:Processing Signal Features
%   ExperimentID.csv @ cd ..\Resume Tables:  Experiment Resume Features
%   Using GitHub                    19/01/2017
%% Global Setup ***********************************************************
clc
clear;
close all;

%% ADDING ALLSCRIPTS
Update_Directory

%% Set Default Directory of Experiments
DefaultPath='C:\Users\Vladimir\Documents\Doctorado\Experimentos\'; % Load from DEFAULT
if exist(DefaultPath,'dir')==0
    DefaultPath=pwd;
end
%% Read Sampling Frequency
fs=NaN; % To read fs to get into the following loop:
while isnan(fs) % Interface error user reading fs
    fs = inputdlg('Sampling Frequency [Hz] : ',...
                 'VIDEOS', [1 50]);
    fs = str2double(fs{:});
end
% Read Fluorophore DYe
dyename = inputdlg('Fluorophore : ',...
             'DYE', [1 150]);
% fs = str2double(fs{:});

%% Read Names, Path and Coordinates***********************************
[Names_Conditions,NumberofVideos,FN,PathName,XY,r]=Read_Videos(DefaultPath);
for v=1:length(NumberofVideos)
    NVal(v)=round(str2double(NumberofVideos(v)));
end
NV=max(NVal);   % Max N of Videos
[~,NC]=size(FN);                                % N Conditions
%% Initalization Data Output
SIGNALS=cell(NV,NC);
DETSIGNALS=cell(NV,NC);
ESTSIGNALS=cell(NV,NC);
SNRwavelet=cell(NV,NC);
Responses=cell(NV,NC);
preDRIVE=cell(NV,NC);
preLAMBDAS=cell(NV,NC);
TAUSall=cell(NV,NC);
SIGNALSclean=cell(NV,NC);
RASTER=cell(NV,NC);
isSIGNALS=cell(NV,NC);
LAMBDASpro=cell(NV,NC);
SNRs=cell(NV,NC);
DRIVERs=cell(NV,NC);

%% Load Data *********************************************************
% For each CONDITION and VIDEO
for i=1:NC
    for j=1:str2double(NumberofVideos{i})
        FileName=FN{j,i};
        [mov]=Video_Load(FileName,PathName);    % Load Video
        [FS]=Fluorescence_Load(mov,XY,r);       % Load Fluorescence
        SIGNALS{j,i}=FS;
    end
    disp('***')
end
[H,W]=size(mov(1).cdata);   % Height & Width
clear mov;                  % Clear Video Structure
%% Save(1) RAW Data * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
% Direcotry to Save: Up from  this one (pwd)
FileDirSave=pwd;
slashes=find(FileDirSave=='\');
FileDirSave=FileDirSave(1:slashes(end));
%% Save data
% Get the Experiment ID:
slashes=find(PathName=='\');
Experiment=PathName(slashes(end-1):slashes(end)-1); % Experiment ID
if isdir([FileDirSave,'\Processed Data'])
    save([FileDirSave,'\Processed Data',Experiment,'.mat'],'Experiment','SIGNALS',...
    'Names_Conditions','NumberofVideos','XY','fs','r');
    disp('SAVED RAW DATA')
else % Create Directory
    disp('Directory >Processed Data< created')
    mkdir([FileDirSave,'\Processed Data']);
    save([FileDirSave,'\Processed Data',Experiment,'.mat'],'Experiment','SIGNALS',...
    'Names_Conditions','NumberofVideos','XY','fs','r');
    disp('SAVED RAW DATA')
end

%% SETUP PROCESSING PARAMTERS ******************************
% Setup for Auto Regressive Process Estimation
L=30;              % seconds  of the Fluorophore Response
p=3;               % AR(p) initial AR order        
taus_0= [.75,2,1]; % starting values for taus

%% DETRENDING AND SPARSE DECONVOLVE DETECTION
[NV,NC]=size(SIGNALS);
ColumnNames={'Fluo_Dye','f_s','DetectedCells','Frames',...
        'minSNR','minSkewness','TimeProcessing'};
disp('**************** +++[Processing]+++ *************************')
for i=1:NC
% for i=2:NC
    auxj=0;
    for j=1:str2double(NumberofVideos{i})
%     for j=2:str2double(NumberofVideos{i})
        X=SIGNALS{j,i};
        % Display Info **********************
        disp(['               [>> Condition: ',num2str(i),'/',num2str(NC),']']);
        disp(['               [>> Video    : ',num2str(j),'/',NumberofVideos{i},']']);
        tic
        % Detrending ******************************************************
        [Ns,Frames] = size(X);
        XD=only_detrending(X);
        %%% Denoising ******************************************************
        % Main Features to Detect Signal or Noise:
        % [Xest,SNRbyWT,SkewSignal,ABratio,SkewNoise]=denoise_wavelet(XD,X);
        % isempty(setdiff(preAccepted_index,Accepted_index))
        [Xest,SNRbyWT,SkewSignal,~,SkewNoise,XDupdate]=denoise_wavelet(XD);
        %% DRIVER ANALYSIS
        IndexesFix=1;       % TO enter to the WhileLoop
        FixedSignals=[];    % 
        FixedNOSignals=[];  % 
        aux=0;
        while and(~isempty(IndexesFix),aux<2)
            aux=aux+1;
            if ~isempty(FixedSignals);
                SkewSignal(FixedSignals)=Features(:,1);
                SkewNoise(FixedSignals)=Features(:,2);
                SNRbyWT(FixedSignals)=Features(:,3);
            end
            if ~isempty(FixedNOSignals)
                SkewSignal(FixedNOSignals)=FeaturesR(:,1);
                SkewNoise(FixedNOSignals)=FeaturesR(:,2);
                SNRbyWT(FixedNOSignals)=FeaturesR(:,3);
            end
            %%% Decision Features
            % SNR >0 *******************************************
            SNRindx=find(SNRbyWT>0);
            % Skew PDFs ****************************************
            % [skew'noise PDF is VERY like RANDN(Ns;Frames)]
            Th_Skew=max(SkewNoise);
            indxSKEW=find(SkewSignal>Th_Skew);
            % indxSKEW=find(skewness(XDupdate')>Th_Skew);
            indxSkewness=makerowvector(indxSKEW);
            % Peaks Ratio of the positive skew signals *********
            % indxPeakRatio=find(ABratio>1); %!!!!!!!!! [ IGNORED ]
            % Make Row Vectors [1xN]:-------------------------
            SNRindx=makerowvector(SNRindx);
            % indxPeakRatio=makerowvector(indxPeakRatio);
            % Get Non-repeated indexes:
            Accepted_index=unique([SNRindx,indxSkewness]);
            Rejected_index=setdiff(1:Ns,Accepted_index);
            if isempty(Rejected_index)
                fprintf('\n\n\n\n > > > > Artifacts Distortion ALERT\n\n\n\n')
            end
            %%% Reject Som False Positives: **************************************
            if ~isempty(Accepted_index)
                % Get Threshold
                Th_SNR =get_threshold_pdf(SNRbyWT,Accepted_index,Rejected_index);
                Accepted_index=find(SNRbyWT>=Th_SNR); % UPDATE ACCEPTED
                Th_Skew=get_threshold_pdf(SkewSignal,Accepted_index,Rejected_index);
                % Apply Threshold
                AcceptedINDX=unique([makerowvector(Accepted_index(SNRbyWT(Accepted_index)>Th_SNR)),...
                    makerowvector(Accepted_index(SkewSignal(Accepted_index)>Th_Skew))]);
                RejectedINDX=setdiff(1:Ns,AcceptedINDX);


        %%% Response Funtion ***********************************************
                [FR,~,TAUS]=AR_Estimation(XDupdate(AcceptedINDX,:),p,fs,L,taus_0);
                for k=1:length(AcceptedINDX)
                    if isempty(findpeaks( FR(k,:) ) )
                        FR(k,:)=-FR(k,:);
                        disp('WARNING: Response Function Missestimation')
                    end
                end
                %%% Sparse Deconvolution *******************************************
                [DRIVER,LAMBDASS]=maxlambda_finder(XDupdate(AcceptedINDX,:),FR);
                % Ignore Drivers with bigger Negative Drivers than positive ones
                % Dindex=find( abs(min(DRIVER'))<abs(max(DRIVER')) );
                % KEEP SNR>0 and High+Skewed Signals
                % ActiveNeurons=unique([AcceptedINDX(Dindex),makerowvector(Accepted_index)]);
                % InactiveNeurons=setdiff(1:Ns,ActiveNeurons);
                % Update Variables:
                % [~,okINDX]=intersect(AcceptedINDX,ActiveNeurons);
                % D=DRIVER(okINDX,:);
                % FR=FR(okINDX,:);
                % LAMBDASS=LAMBDASS(okINDX);
                % Check Driver
                [Dfix,XDfix,Xestfix,LambdasFix,IndexesFix,Features]=analyze_driver_signal(DRIVER,FR,XDupdate(AcceptedINDX,:),Xest(AcceptedINDX,:));
                if ~isempty(IndexesFix)
                    FixedSignals=AcceptedINDX(IndexesFix);
                    LAMBDASS(IndexesFix)=LambdasFix;
                    DRIVER=Dfix;
                    XDupdate(AcceptedINDX,:)=XDfix;
                    Xest(AcceptedINDX,:)=Xestfix;
                    fprintf('\n\n\n > >   Updated Values   < < \n\n\n')
                    % Process NOT OK#######################################
                    [FRr,~,~]=AR_Estimation(XDupdate(RejectedINDX,:),p,fs,L,taus_0);
                    for k=1:length(RejectedINDX)
                        if isempty(findpeaks( FRr(k,:) ) )
                            FRr(k,:)=-FRr(k,:);
                            disp('WARNING: Response Function Missestimation')
                        end
                    end
                    [DRIVERr,LAMBDASSr]=maxlambda_finder(XDupdate(RejectedINDX,:),FRr,1);
                    [~,XDRfix,XestRfix,~,IndexesFixR,FeaturesR]=analyze_driver_signal(DRIVERr,FRr,XDupdate(RejectedINDX,:),Xest(RejectedINDX,:));
                    if ~isempty(IndexesFixR)
                        FixedNOSignals=RejectedINDX(IndexesFixR);
                        % LAMBDASS(IndexesFix)=LambdasFix;
                        % DRIVER=Dfix;
                        XDupdate(RejectedINDX,:)=XDRfix;
                        Xest(RejectedINDX,:)=XestRfix;
                    end
                end
            % Negative Threshold to clean Drivers ****************************
            % ThDriver=abs(min(D'));
            % Clean Drivers (only +++Drivers) ALREADY CLEANE
                % [Nd,~]=size(D);
                % for n=1:Nd
                %    D(n,D(n,:)<=0)=0; % JUST + + + driver
                % end
                % Check if zero drivers & Update DATA
                ActiveNeurons=AcceptedINDX( sum(DRIVER,2)~=0 );
                InactiveNeurons=setdiff(1:Ns,ActiveNeurons);
                LAMBDASS=LAMBDASS( sum(DRIVER,2)~=0 );
                DRIVER=DRIVER(sum(DRIVER,2)~=0, :);
                FR=FR(sum(DRIVER,2)~=0,:);
            else
                AcceptedINDX=[];
                RejectedINDX=setdiff(1:Ns,AcceptedINDX);
                DRIVER=[];
                ActiveNeurons=[];
                FR=[];
                LAMBDASS=[];
%% plot to monitor results
%             figure; 
%             subplot(211)
%             [pO,binO]=ksdensity(SNRbyWT,linspace(min(SNRbyWT),max(SNRbyWT),100));
%             plot(binO,pO,'.k','LineWidth',1)
%             axis tight; grid on;
%             title('SNR pdf')
%             subplot(212)
%             [pO,binO]=ksdensity(SkewSignal,linspace(min(SkewSignal),max(SkewSignal),100));
%             plot(binO,pO,'.k','LineWidth',1)
%             axis tight; grid on;
%             title('Skewness pdf')
                disp('             *********************' )
                disp('             *********************' )
                disp('             ******PURE NOISE ****' )
                disp('             *********************' )
                disp('             *********************' )
            end
        end % END WHILE of IndexesFix
        
        
        %% GET RASTER *****************************************************
        TotalCells=length(XY);
        Raster=get_raster(1,DRIVER,ActiveNeurons,TotalCells); % DRIVER
        % Examples---------------------------------------------------------
        % DRIVER:
        % R1=get_raster(1,Dfix,ActiveNeurons,TotalCells); 
        % OOPSI:
        % R2=get_raster(2,XDupdate(ActiveNeurons,:),ActiveNeurons,TotalCells,TAUS,fs,Xest(ActiveNeurons,:));
        % DERIVATIVE (cleaned up signal)
        % R3=get_raster(3,Dfix,ActiveNeurons,TotalCells,FR);
        % _________________________________________________________________
        % Results Monitor Figure ******************************************
        % figureMonitor=gcf;
        % figureMonitor.Name=[Experiment(2:end),' ',Names_Conditions{i},' vid:',num2str(j)];
        % drawnow;
        % Cells to save PREPROCESSING ####################################
        DETSIGNALS{j,i}=XDupdate;       % Detrended Signals         *
        ESTSIGNALS{j,i}=Xest;           % Wavelet Denoised          *
        SNRwavelet{j,i}=SNRbyWT;        % Empirical SNR             
        Responses{j,i}=FR;              % Fluorophore Responses     
        TAUSall{j,i}=TAUS;              % [taus {rise, fall},gain]  
        preDRIVE{j,i}=DRIVER;                % Preliminar Drives (+ & -) 
        preLAMBDAS{j,i}=LAMBDASS;       % lambda Parameter          
        isSIGNALS{j,i}=ActiveNeurons;   % Signal Indicator          
        RASTER{j,i}=Raster;             % Preliminar Raster         
        % Table Data For Processing Log Details ##########################
        TimeProcessing=toc;             % Processing Latency [s]
        T=table( dyename,{num2str(fs)},{num2str(length(ActiveNeurons))},...
            {num2str(Frames)},{num2str(Th_SNR)},{num2str(Th_Skew)},...
            {num2str(TimeProcessing,2)} );

        T.Properties.VariableNames=ColumnNames;
        % Save Table in Resume Tables of the Algorithm Latency*********
        if isdir([FileDirSave,'\Resume Tables'])
            writetable(T,[FileDirSave,'\Resume Tables',[Experiment,'-',Names_Conditions{i}],'.csv'],...
                'Delimiter',',','QuoteStrings',true);
            disp(['Saved Table Resume: ',Experiment,'-',Names_Conditions{i}])
        else % Create Directory
            disp('Directory >Resume Tables< created')
            mkdir([FileDirSave,'\Resume Tables']);
            writetable(T,[FileDirSave,'\Resume Tables',[Experiment,'-',Names_Conditions{i}],'.csv'],...
                'Delimiter',',','QuoteStrings',true);
            disp('Resume Tables Direcotry Created');
            disp(['Saved Table Resume: ',Experiment,'-',Names_Conditions{i}])
        end
        % ARcoeffcients{j,i}=ARc;                 % Autoregressive Coefficients
        % SIGNALSclean{j,i}=X_SPARSE;             % Cleansignals
        % LAMBDASpro{j,i}=LAMBDASproc;            % Sparse Parameter              * To Datasheet
        % SNRs{j,i}=SNRbySD;                      % Signal to Noise Ratio [dB]    * To Datasheet lambdas<1
        % DRIVERs{j,i}=DRIVERSpro;                % Driver Signals
        % QoVid{j,i}=QoV;                         % QUality of Videos  
    end
    disp(' |0|||||||||||||||||||||0||||||||||||||||||||||||0||||||||||||||| ')
    disp(' |||||0||||||||||||||||0||||DATA PROCESSED|||||||||||||||||0||||| ')
    disp(' |||0||||||||||||0||||||||||||||||0|||||||||||||||||||||||||||||| ')
end
 %% SAVING(2) Processed Data & Feature Extraction |  Resume Table 
% Save Auto-Processed DATA * * * * * * * * * * * * * * * * * * * * * * * * 
save([FileDirSave,'\Processed Data',Experiment,'.mat'],'DETSIGNALS','ESTSIGNALS','SNRwavelet',...
    'preDRIVE','preLAMBDAS','TAUSall','RASTER','isSIGNALS','Responses','dyename','-append');
disp('Updated Feature - Extraction DATA')
%% Save Resume Table
% okindxname=[];
% for n=1:length(Experiment)
%     if isalpha_num(Experiment(n))
%         okindxname=[okindxname,n];
%     end
% end
% ColumnNames={'Fluo_Dye','Experiment','f_s','Condition','Cells','Frames',...
%     'minSNR','minSKEW','TimeProcessing'};
% Tresume.Properties.VariableNames=ColumnNames;
% 
% if isdir([FileDirSave,'\Resume Tables'])
%     writetable(Tresume,[FileDirSave,'\Resume Tables',Experiment,'.csv'],...
%         'Delimiter',',','QuoteStrings',true);
%     disp('Saved Table Resume')
% else % Create Directory
%     disp('Directory >Resume Tables< created')
%     mkdir([FileDirSave,'\Resume Tables']);
%     writetable(Tresume,[FileDirSave,'\Resume Tables',Experiment,'.csv'],...
%         'Delimiter',',','QuoteStrings',true);
%     disp('Saved Table Resume')
% end
%% Sort & Clean Rasters ***************************************************
% make it nested function--->
% Sort by Activation in each Condition:
[New_Index,Raster_Condition,RASTER_WHOLE]=SortNeuronsCondition(RASTER);
% Plot_Raster_V(RASTER_WHOLE(New_Index,:),fs);
RASTER_WHOLE_Clean=RASTER_WHOLE(New_Index,:);
XY_clean=XY(New_Index,:);
% Clean Raster and Coordinates
ActiveNeurons=find(sum(RASTER_WHOLE_Clean,2)>0);                % INDEX of Active NEURONS only
RASTER_WHOLE_Clean=RASTER_WHOLE_Clean(ActiveNeurons,:);
XY_clean=XY_clean(ActiveNeurons,:);                             % Clean Coordinates
%% PLOT RESULTS
Plot_Raster_V(RASTER_WHOLE_Clean,fs);                           % Clean Whole Raster
set(gcf,'Name',['ID: ',Experiment(2:end),' pre-processing'],'NumberTitle','off')

Label_Condition_Raster(Names_Conditions,Raster_Condition,fs);   % Labels
%% SAVE ReSULTS
save([FileDirSave,'\Processed Data',Experiment,'.mat'],'New_Index','Raster_Condition',...
    'RASTER_WHOLE_Clean','XY_clean','-append');
disp('Saved Sorted Raster Intel')

%% Visual Inpspection & Manual Processing ********************************* GREAT!
% Ask if so
button = questdlg('Results Inspection?');
if strcmp('Yes',button)
    [NV,NC]=size(isSIGNALS);
    preisSIGNALS=isSIGNALS;
    [isSIGNALSOK,SIGNALSclean,DRIVEROK,RASTEROK,...
    LAMBDASSpro,SNRlambda,OddsMatrix]=Manual_Driver_Raster_Magic(isSIGNALS,SIGNALS,...
    DETSIGNALS,preDRIVE,preLAMBDAS,RASTER,Responses,Names_Conditions,fs);
    
    % Re-Sort WHOLE RASTER 
    [New_Index,Raster_Condition,RASTER_WHOLE]=SortNeuronsCondition(RASTEROK);
    RASTER_WHOLE_Clean=RASTER_WHOLE(New_Index,:);
    XY_clean=XY(New_Index,:);
    % Clean Raster and Coordinates
    TotalActiveNeurons=find(sum(RASTER_WHOLE_Clean,2)>0);                % INDEX of Active NEURONS
    QoE=round(100*length(TotalActiveNeurons)/length(XY),2);
    fprintf('Actual Active Neurons: %d %%\n',round(QoE));
    % Whole Raster
    RASTER_WHOLE_Clean=RASTER_WHOLE_Clean(TotalActiveNeurons,:);
    XY_clean=XY_clean(TotalActiveNeurons,:);                        % Clean Coordinates
    New_Index_Active=New_Index(TotalActiveNeurons);
    % SEE RESULTS ################################################
    Plot_Raster_V(RASTER_WHOLE_Clean,fs);                           % Clean Whole Raster
    set(gcf,'Name',['ID: ',Experiment(2:end)],'NumberTitle','off')
    Label_Condition_Raster(Names_Conditions,Raster_Condition,fs);   % Labels    
    % Update Results                [ok] ----------------------------------
    % Ask for Directory to save & MAT file to update
    checkname=1;
    while checkname==1
        DefaultPath='C:\Users\Vladimir\Documents\Doctorado\Software\GetTransitum\Calcium Imaging Signal Processing\FinderSpiker\Processed Data';
            if exist(DefaultPath,'dir')==0
                DefaultPath=pwd; % Current Diretory of MATLAB
            end

        [FileName,PathNamePro] = uigetfile('*.mat',[' Pick the Analysis File ',Experiment],...
            'MultiSelect', 'off',DefaultPath);
        dotindex=find(FileName=='.');
        if strcmp(FileName(1:dotindex-1),Experiment(2:end))
            checkname=0;
            % SAVE DATA
            save([PathNamePro,FileName],'isSIGNALSOK','SIGNALSclean','DRIVEROK','SNRlambda','LAMBDASSpro',...
                'New_Index','Raster_Condition','RASTER_WHOLE_Clean','XY_clean','RASTEROK','OddsMatrix','-append');
            disp([Experiment,'   -> UPDATED: Visual Review'])

        else
            disp('Not the same Experiment!')
            disp('Try again!')
        end
     end    
    %% Save Processing-Features of RASTER Activity: p(++), p(-+), p(--),p(+-)
    % Get N videos and N conditions
    [Nv,Nc]=size(ESTSIGNALS);
    NNeurons=length(XY);
    % SETUP ACCUMULATIVE ARRAYS
    %EXPNAME=[];
    FLUOROPHORE=[];
    CONDNAME={};
    COORD=[];
    RAD=[];
    SNRW=[];
    SNRL=[];
    SKEWDEN=[];
    LAMB=[];
    ODDS=[];
    for c=1:Nc
        for v=1:Nv
            if ~isempty(ESTSIGNALS{v,c})
                %EXPNAME=[EXPNAME;repmat(Experiment,NNeurons,1)];
                FLUOROPHORE=[FLUOROPHORE;repmat(dyename{1},NNeurons,1)];
                % CONDNAME=[CONDNAME;repmat(Names_Conditions{c},NNeurons,1)];
                LWord=length(Names_Conditions{c});
                CONDNAME=[CONDNAME;mat2cell(repmat(Names_Conditions{c},NNeurons,1),...
                    ones(NNeurons,1),LWord)];
                COORD=[COORD;XY];
                RAD=[RAD;r];
                SNRW=[SNRW;SNRwavelet{v,c}];
                SNRL=[SNRL;makerowvector(SNRlambda{v,c})'];
                Xden=ESTSIGNALS{v,c}; 
                SKEWDEN=[SKEWDEN;skewness(Xden')']; % Tranpose it to make it row vector
                LAMB=[LAMB;makerowvector(LAMBDASSpro{v,c})']; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ManualMode
                % Odds Matrix Treatment
                Detection=categorical;
                OM=OddsMatrix{v,c};
                Detection(OM.TruePositive)='++';
                Detection(OM.TrueNegative)='+-';
                Detection(OM.FalsePositive)='-+';
                Detection(OM.FalseNegative)='--';
                ODDS=[ODDS;Detection'];     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ManualMode
            end
        end
    end
    Tfeat=table(FLUOROPHORE,CONDNAME,COORD,RAD,SNRW,SNRL,SKEWDEN,LAMB,ODDS);
    Tfeat.Properties.VariableNames={'Dye','Condition','ROIcoordinates',...
        'ROIradius','SNRwavelet','SNRdeconv','SignalSkewness','lambda','Detection'};
    disp('Saving...')
    summary(Tfeat)
    FileProcessingFeatures=[Experiment,'-Features.csv'];
    if isdir([FileDirSave,'\Features Tables'])
        writetable(Tfeat,[FileDirSave,'\Features Tables',FileProcessingFeatures],...
            'Delimiter',',','QuoteStrings',true);
        disp('Saved Table Features')
    else % Create Directory
        disp('Directory >Resume Tables< created')
        mkdir([FileDirSave,'\Features Tables']);
        writetable(Tfeat,[FileDirSave,'\Features Tables',FileProcessingFeatures],...
            'Delimiter',',','QuoteStrings',true);
        disp('Saved Table Features')
    end
    
    disp('saved.')
end
%% END OF THE WORLD**************************************************   