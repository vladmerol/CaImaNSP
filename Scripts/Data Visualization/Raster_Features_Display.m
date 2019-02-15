%% Raster Features Display#################################################
% Script that read and plot boxplots of Raster Features: [24]
% between or among Conditions for Several Experiments.
%                                                                      Figs
% 'RateNeurons','ActivityTime','ActiveRatioCAG','EffectiveActivity',... [1]
% 'ISImean','ISImode','ISIvar','ISIskew','ISIkurt',...                  [2]
% 'Lengthmean','Lengthmode','Lengthvar','Lengthskew','Lengthkurt',...   [2]
% 'CAGmean','CAGmode','CAGvar','CAGskew','CAGkurt',...                  [3]
% 'RoAmean','RoAmode','RoAvar','RoAskew','RoAkurt'                      [3]
%% Read CSV Files
NC = inputdlg('Number of Conditions: ',...
             'Raster Features', [1 75]);
NC = str2double(NC{:});    
% Setup Conditions
Conditions_String='Condition_';
n_conditions=[1:NC]';
Conditions=[repmat(Conditions_String,NC,1),num2str(n_conditions)];
Cond_Names=cell(NC,1);
% Names=cell(NC,1);
for i=1:NC
    Cond_Names{i}=Conditions(i,:);
    Names_default{i}=['...'];
end
% 2nd Input Dialogue
name='Names';
numlines=[1 75];
Names_Conditions=inputdlg(Cond_Names,name,numlines,Names_default);
% Directory (default)
CurrentPath=pwd;
Slshes=find(CurrentPath=='\');
% [CurrentPath(1:Slshes(end)),'Raster Features']
CurrentPathOK=[CurrentPath(1:Slshes(end)),'Raster Features'];
%% Condition LOOP
RASTER_FEATURES={};
for i=1:NC
    % Read Names
    [FileName,PathName] = uigetfile('*.csv',['CSV files for: ',Names_Conditions{i}],...
    'MultiSelect', 'on',CurrentPathOK);
    % Loop to Features from read csv
    if iscell(FileName)
        [~,NR]=size(FileName);
    else
        NR=1;
        % FileName=FileName
        FileName=mat2cell(FileName,1);
    end
    Features=[];
    Raster_Names=cell(NR,1);
    for r=1:NR
        LowLine=find(FileName{r}=='_');
        Raster_Names{r}=FileName{r}(1:LowLine(1)-1);
        rowFeatures=csvread([PathName,FileName{r}],1,0);
        Features=[Features;rowFeatures];
    end
    RASTER_FEATURES{i}=Features;
    RASTER_NAMES{i}=Raster_Names;
    CurrentPathOK=PathName;
end

%% Plot Data############################################################
%% 'Active Neurons','Active Time','MeanActivity','EffectiveActivity'
FeaturesA=figure;
FeaturesA.Name='Activity Indexes';
h1=subplot(2,2,1); % Active Neurons
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,1,h1)
title(h1,'Active Neurons')
h2=subplot(2,2,2); % Duration
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,2,h2)
title(h2,'Active Time Fraction')
h3=subplot(2,2,3); % Mean Activity
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,3,h3)
title(h3,'Active CAG Area Ratio')
h4=subplot(2,2,4); % Effective Activity
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,4,h4)
title(h4,'Effective Activity')
%% ITI & LT Statistics Features
% 'ISImean','ISImode','ISIvar','ISIskew','ISIkurt',...
% 'Lengthmean','Lengthmode','Lengthvar','Lengthskew','Lengthkurt'
FeaturesB=figure;
FeaturesB.Name='IEI & ED statistics';
g1=subplot(2,5,1); % ISI mean
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,5,g1)
title(g1,'IEI mean')
h1.YLim=[0,1];grid(h1,'on');

g2=subplot(2,5,2); % ISImode
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,6,g2)
title(g2,'IEI mode')

g3=subplot(2,5,3); % ISIvar
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,7,g3)
title(g3,'IEI variance')

g4=subplot(2,5,4); % ISIskew
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,8,g4)
title(g4,'IEI skewness')

g5=subplot(2,5,5); % ISIkurt
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,9,g5)
title(g5,'IEI kurtosis')

g6=subplot(2,5,6); % Length mean
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,10,g6)
title(g6,'ED mean')

g7=subplot(2,5,7); % Length mode
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,11,g7)
title(g7,'ED mode')

g8=subplot(2,5,8); % Length var
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,12,g8)
title(g8,'ED variance')

g9=subplot(2,5,9); % Length skew
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,13,g9)
title(g9,'ED skewness')

g10=subplot(2,5,10); % Length kurt
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,14,g10)
title(g10,'ED kurtosis')
%% CAG & RoA Features
FeaturesC=figure;
FeaturesC.Name='Raster Features: CAG & RoA Statitics';
j1=subplot(2,5,1); % CAG mean
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,15,j1)
title(j1,'CAG mean')

j2=subplot(2,5,2); % CAG mode
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,16,j2)
title(j2,'CAG mode')

j3=subplot(2,5,3); % CAG var
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,17,j3)
title(j3,'CAG variance')

j4=subplot(2,5,4); % CAG skew
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,18,j4)
title(j4,'CAG skewness')

j5=subplot(2,5,5); % CAG kurt
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,19,j5)
title(j5,'CAG kurtosis')

j6=subplot(2,5,6); % RoA mean
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,20,j6)
title(j6,'RoA mean')

j7=subplot(2,5,7); % RoA mode
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,21,j7)
title(j7,'RoA mode')

j8=subplot(2,5,8); % RoA var
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,22,j8)
title(j8,'RoA variance')

j9=subplot(2,5,9); % RoA skew
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,23,j9)
title(j9,'RoA skewness')

j10=subplot(2,5,10); % RoA kurt
plot_box(RASTER_NAMES,RASTER_FEATURES,Names_Conditions,24,j10)
title(j10,'RoA kurtosis')
%% Make and Save Table
okbutton = questdlg('Make CSV Table?');
waitfor(okbutton); 
if strcmp('Yes',okbutton)
    % Set Save Name
    timesave=clock;
    TS=num2str(timesave(1:5));
    TS=TS(TS~=' ');
    SaveFile=['\Table_Raster_Features_',TS,'.csv'];
    % Select Destiny
    PathSave=uigetdir(CurrentPathOK);
    disp('>>Making CSV table...')
    TableFeatures=maketableraster(RASTER_NAMES,RASTER_FEATURES,Names_Conditions);
    writetable(TableFeatures,[PathSave,SaveFile],...
                    'Delimiter',',','QuoteStrings',true);
    fprintf('>> Data saved @: %s\n',[PathSave,SaveFile])
else
    fprintf('>>Unsaved data.\n')
end
fprintf('>>Cleaning Workspace: ')
clear
fprintf('done\n')