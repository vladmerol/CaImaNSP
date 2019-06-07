% Function to Select frames per Condition Manually
% Extract Descriptive RasterFeatures and seve the, @
% ...\FinderSpiker\Raster Features
% Run After Finder_Spiker_Calcium.m and Detected & Undetected Scripts
% Load Saved Data in the EXPERIMENT_DATE.mat Files
% It runs until selection is OK (according to the user)
% Input
%   fs:                 Sampling Frequency
%   Raster_Condition:   Separated Raster in Cells   NOT condition SORTED
%   XY:                 Original Coordinates        NOT condition SORTED
%   Names_Conditions:   Names of Conditions
%   Experiment:         Name of the Experiment
%   checkname           if it's specified->OMITS SAVING
% Ouput
%   RASTER_Selected_Clean   Matrix (ONLY ACTIVE cells)
%   XY_selected:            Selected ACtive Cells
%   R_Condition:            Cell of Raster for each COndition
%   Onsets:                 Selected Starting Point
%   New_indexes:            Sleected & Sorted Indexes of the Cells
function [RASTER_Selected_Clean,XY_selected,R_Condition,Onsets,New_Index]= Select_Raster_for_NN(fs,Raster_Condition,XY,Names_Conditions,Experiment,varargin)
%% Setup
if numel(varargin)==1
    checkname=0;
else
    checkname=1;
end
FileDirSave=pwd;
Experiment=Experiment(Experiment~='\'); % PATCH
slashes=find(FileDirSave=='\');
FileDirSave=FileDirSave(1:slashes(end));
okbutton='No';
while ~strcmp('Yes',okbutton)
     %% Show Raster per condition
    [~,NC]=size(Raster_Condition);
    Raster_Selecter={};
    Onsets=cell(NC,1);
    for c=1:NC
        R=Raster_Condition{c};
        [~,FramesSize]=size(R);
        Plot_Raster_Ensembles(R,fs);
        figure_raster=gcf;
        figure_raster.Name=['Raster ',Names_Conditions{c}];
        % Read Selection
        prompt = {'Start @ min:','Finish @ min:'};
        dlg_title = 'Select Raster ';
        num_lines = 1;
        defaultans = {'0',num2str(ceil(FramesSize/fs/60))};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        Minute_Start=str2double(answer{1});
        Minute_End=str2double(answer{2});
        Frame_A=round(Minute_Start*60*fs+1);
        Frame_B=round(Minute_End*60*fs);
        Onsets{c,1}=Frame_A;
        if Frame_B>FramesSize
            Frame_B=FramesSize;
        end
        % Selection:
        R=R(:,Frame_A:Frame_B);
        Raster_Selecter{c}=R;    
        % Show Selected Raster
        close(figure_raster);
        NVaux{c,1}='1'; % Number of "Videos" or Records
    end
    %% Ignore NonActive Coordinates in the Selection and Sort per Condition
    % Sort Neurons by Activation in Each Condition:
    [New_Index,Raster_Condition_Sel,RASTER_WHOLE]=SortNeuronsCondition(Raster_Selecter);
    % Plot Whole Sorted Raster:
    RASTER_Selected_Clean=RASTER_WHOLE(New_Index,:);
    XY_selected=XY(New_Index,:);
    % Clean Raster and Coordinates
    % INDEX of SORTED Active NEURONS during the WHOLE experiment
    ActiveNeurons=find(sum(RASTER_Selected_Clean,2)>0);                 
    New_Index(ActiveNeurons)
    RASTER_Selected_Clean=RASTER_Selected_Clean(ActiveNeurons,:);
    XY_selected=XY_selected(ActiveNeurons,:);                           % Clean Coordinates
    Plot_Raster_Ensembles(RASTER_Selected_Clean,fs);                            % Clean Whole Raster
    set(gcf,'Name',['ID: ',Experiment,' selected '],'NumberTitle','off')
    Label_Condition_Raster(Names_Conditions,Raster_Condition_Sel,fs);       % Labels
    % To Save active and Sorted:
    R_Condition={};

    %% Feature Table Column Names
    HeadersFeatures={'RateNeurons','ActivityTimeFraction','ActiveRatioCAG','EffectiveActivity',...
        'ISImean','ISImode','ISImedian','ISIvar','ISIskew','ISIkurt',...
        'Lengthmean','Lengthmode','Lengthmedian','Lengthvar','Lengthskew','Lengthkurt',...
        'CAGmean','CAGmode','CAGmedian','CAGvar','CAGskew','CAGkurt',...
        'RoAmean','RoAmode','RoAmedian','RoAvar','RoAskew','RoAkurt',...
        'RoTmean','RoTmode','RoTmedian','RoTvar','RoTskew','RoTkurt'};
    %% FEATURES EXTRACTION and plot
    for c=1:NC
        % Read Original Raster (UNSORTED!!!)
        R=Raster_Condition_Sel{c};
        % Raster (SORTED!!!)
        R=R(New_Index,:);
        % Raster (JUST ACTIVE!!!)
        R_Condition{c}=R(ActiveNeurons,:);
        % XY_Condition{c}=XY_selected;
        % Activity Indexes:*******************************************
        % Feature of ALL Rows of the SELECTED RASTER (BETTER OFF!)
        [Descriptive,AI_1(c,1),AI_2(c,1)]=get_general_features(R_Condition{c});
        AN=Descriptive.AN;
        DurAc=Descriptive.DurAc; % Number of Active Frames
        CAG=Descriptive.CAG;
        RoA=Descriptive.RoA;
        RAN=Descriptive.RAN;
        % Stats...
        RoAstats=[mean(RoA),mode(RoA),median(RoA),var(RoA),skewness(RoA),kurtosis(RoA)];
        CAGstats=[mean(CAG),mode(CAG),median(CAG),var(CAG),skewness(CAG),kurtosis(CAG)];
        % Statistics from pdfs*******************************************
        % Inter Transients Interval pdf &
        % Transient Length pdf
        [~,~,~,~,StatsFeatures]=get_iti_pdf(R_Condition{c},fs);
        % CoActivityGram Statistics & pdf: IMPORTANT!!!!
        if or(max(CAG)==0,min(CAG)==max(CAG))
            CAGbin=linspace(min(CAG),max(CAG),100);
            CAGp=zeros(size(CAGbin));
        else
            [~,~]=ksdensity(CAG,linspace(min(CAG),max(CAG),100));
        end
        % Feature Table *******************************************
        % 'RateofNeurons','ActivityDuration','MeanActivity','EffectiveActivity',...
        % 'ISImean','ISImode','ISImedian','ISIvar','ISIskew','ISIkurt',...
        % 'Lengthmean','Lengthmode','Lengthmedian','Lengthvar','Lengthskew','Lengthkurt',...
        % 'CAGmean','CAGmode','CAGmedian','CAGvar','CAGskew','CAGkurt',...
        % 'RoAmean','RoAmode','RoAmedian','RoAvar','RoAskew','RoAkurt',...
        % 'RoTmean','RoTmode','RoTmedian','RoTvar','RoTskew','RoTkurt']
        Trasterfeatures=table(RAN,DurAc,AI_1(c,1),AI_2(c,1),...
            StatsFeatures(1),StatsFeatures(2),StatsFeatures(3),StatsFeatures(4),StatsFeatures(5),StatsFeatures(6),...
            StatsFeatures(7),StatsFeatures(8),StatsFeatures(9),StatsFeatures(10),StatsFeatures(11),StatsFeatures(12),...
            CAGstats(1),CAGstats(2),CAGstats(3),CAGstats(4),CAGstats(5),CAGstats(6),...
            RoAstats(1),RoAstats(2),RoAstats(3),RoAstats(4),RoAstats(5),RoAstats(6),...
            StatsFeatures(13),StatsFeatures(14),StatsFeatures(15),StatsFeatures(16),StatsFeatures(17),StatsFeatures(18),...
            'VariableNames',HeadersFeatures);
        disp('>>Raster Features Table: Done.');
        % Saving CSV - - - - - - - - - - - - - - - - - - - - - - - - -
        if checkname
            NameDir='Raster Features\';
            Experiment=Experiment(Experiment~='\');
            if isdir([FileDirSave,'\Raster Features'])
                writetable(Trasterfeatures,[FileDirSave,NameDir,Experiment,'_',Names_Conditions{c},'Raster_Features.csv'],...
                    'Delimiter',',','QuoteStrings',true);
                disp(['Saved Raster Features: ',Experiment,'-',Names_Conditions{c}])
            else % Create Directory
                disp('Directory >Raster Features< created')
                mkdir([FileDirSave,NameDir]);
                writetable(Trasterfeatures,[FileDirSave,NameDir,Experiment,'_',Names_Conditions{c},'Raster_Features.csv'],...
                    'Delimiter',',','QuoteStrings',true);
                disp('Resume Tables Directory Created');
                disp(['Saved Raster Features: ',Experiment,'-',Names_Conditions{c}])
            end
        end
        % PLOTS *************************************
        % PDFs
%         plot(h1,ISIbin,ISIp,'LineWidth',2)
%         plot(h2,Lengthbin,Lengthp,'LineWidth',2)
%         plot(h3,CAGbin,CAGp,'LineWidth',2)
    end
    %% Ending PLot
%     xlabel(h1,'t[s]'); xlabel(h2,'t[s]'); xlabel(h3,'Coactive Neurons');
%     axis(h1,'tight'), axis(h2,'tight'); axis(h3,'tight');
%     grid(h1,'on'); grid(h2,'on'); grid(h3,'on');
%     hold(h1,'off'); hold(h2,'off'); hold(h3,'off');
%     legend(h1,Names_Conditions);
%     set(h1, 'YScale', 'log'); set(h2, 'YScale', 'log');
    okbutton = questdlg('Selection Alright?');
    %% SAVE OUTPUT DATASET (.m file)
    %checkname=1; % USE AS INPUT
    while checkname==1
        
        DefaultPath=pwd; % Current Diretory of FinderSpiker
        slashes=find(DefaultPath=='\');
        DefaultPath=[DefaultPath(1:slashes(end)),'\Processed Data'];
        
        [FileName,PathName] = uigetfile('*.mat',[' Pick the Analysis File ',Experiment],...
            'MultiSelect', 'off',DefaultPath);
        % dotindex=find(FileName=='.');
        if strcmp(FileName(1:end-4),Experiment)
            checkname=0;
            % SAVE DATA
            save([PathName,FileName],'RASTER_Selected_Clean','XY_selected',...
                'R_Condition','New_Index','Onsets','-append');
            disp([Experiment,'   -> UPDATED (Selected Data)'])
        elseif FileName==0
            checkname=0;
            disp('*************DISCARDED************')
        else
            disp('Not the same Experiment!')
            disp('Try again!')
        end
    end    
end
%% END OF THE WORLD