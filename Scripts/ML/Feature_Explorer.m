%% Load Tabel **************************************
Dirpwd=pwd;
slashesindx=find(Dirpwd=='\');
CurrentPathOK=[Dirpwd(1:slashesindx(end))]; % Finder Spiker Main Folder
% Load File 
[FileName,PathName,MoreFiles] = uigetfile({'*.csv';'*.xlsx'},' Dataset file of ALL Features',...
    'MultiSelect', 'off',CurrentPathOK);
Xraw=readtable([PathName,FileName]);                % Table
Y=categorical(table2array( Xraw(:,1)) );            % Labels
EXPIDs=table2array( Xraw(:,2));                     % Cell of Strings
X=table2array( Xraw(:,3:end) );                     % Dataset
FeatureNames=Xraw.Properties.VariableNames(3:end);  % Feature Names
%% Feature Explorer ********************************

%% Correlation among Features
FeaturesCorr=corr(X);
figure; imagesc(FeaturesCorr)

%% p-values: statistical tests: ttest
Nfeat=numel(FeatureNames);
Labels=unique(Y);
Nconditions=numel(Labels);
HypTest=zeros(Nfeat,Nconditions);
for f=1:Nfeat
    pMatrix=ones(Nconditions);
    for c=1:Nconditions
        elseCond=setdiff(1:Nconditions,c);
        for e=1:numel(elseCond)
            fprintf('>>Testing %s @ Conditions:\n   %s vs %s p=',FeatureNames{f},char(Labels(c)),char(Labels(elseCond(e))));
            Aindx=find(Y==Labels(c));
            Bindx=find(Y==Labels(elseCond(e)));
            A=X(Aindx,f);
            B=X(Bindx,f);
            % [h,p]=ttest2(A,B);
            [h,p]=kstest2(A,B);
            if h
                HypTest(f,[c,elseCond(e)])=1;
            end
            pMatrix(c,elseCond(e))=p;
            %p=kruskalwallis([A;B],[Y(Aindx);Y(Bindx)])
            fprintf('%3.2f\n',p);
        end
    end
    pause;
end
%% For paired Experiments: Delta Features
% find and compare paired Features
% Loop for unique Expeiment IDs: if more than 1-> paired experiment

Labels=unique(Y);
PairedExps=cell(numel(Labels));
for lrow=1:numel(Labels)
    for lcol=lrow+1:numel(Labels)
        % List of Experiments for Condition A
        ActualLabel=Labels(lrow);
        IndxConditionA=find(Y==ActualLabel);
        EXPlistA=unique(EXPIDs(IndxConditionA));
        % List of Experiments for Condition B
        NextLabel=Labels(lcol);
        IndxConditionB=find(Y==NextLabel);
        EXPlistB=unique(EXPIDs(IndxConditionB));
        % Intersection of Experiments for Condition A & B
        PairedAB=intersect(EXPlistA,EXPlistB);
        if ~isempty(PairedAB)
            fprintf('>>Paired Experiments for %s & %s:\n',char(ActualLabel),...
                char(NextLabel))
            disp(PairedAB)
        else
            fprintf('>>No Paired Experiments for %s & %s:\n',char(ActualLabel),...
                char(NextLabel))
        end
        PairedExps{lrow,lcol}=PairedAB;
    end
end

%% Calculate Deltas ******************************************************
DeltaExps=cell(numel(Labels));
ReferenceCondition={};
for lrow=1:numel(Labels)
    for lcol=lrow+1:numel(Labels)
        if ~isempty(PairedExps{lrow,lcol})
            EXPlist=PairedExps{lrow,lcol};
            LabelsDelta={char(Labels(lcol));char(Labels(lrow))};
            % Select Conditions in Order To Calculate Deltas
            for c=1:2
                [index_var(c),~] = listdlg('PromptString',...
                    ['Set Condition in Order: ',num2str(c)],...
                    'SelectionMode','single',...
                    'ListString',LabelsDelta);
            end
            DeltaCondition=LabelsDelta(index_var);
            % Save Reference Condition
            ReferenceCondition=[ReferenceCondition;DeltaCondition(1)]
            % For every Experiment:
            DeltaAllFeature=[];
            for e=1:numel(EXPlist)
                IndxTable=find(ismember(EXPIDs,EXPlist{e}));
                % Cond_A - Cond_B: COND_B/COND_A
                RowA=IndxTable(Y(IndxTable)==DeltaCondition(1));
                RowB=IndxTable(Y(IndxTable)==DeltaCondition(2));
                % Relative Changes
                DeltaFeature(X(RowB,:)~=0)=X(RowB,X(RowB,:)~=0)./X(RowA,X(RowB,:)~=0);
                DeltaFeature(X(RowB,:)==0)=X(RowA,X(RowB,:)==0)-X(RowB,X(RowB,:)==0);
                DeltaAllFeature=[DeltaAllFeature;100*DeltaFeature];
            end
            DeltaExps{lrow,lcol}=DeltaAllFeature;
        else
            disp('No Paired Conditions')
        end
    end
end
ReferenceCondition=unique(ReferenceCondition); % Condition as References
%% Show Results
RefIndex=[];
for c=1:numel(ReferenceCondition)
    RefIndex=[RefIndex;find(Labels==ReferenceCondition{c})];
end

for c=1:numel(ReferenceCondition)
    TitleFig=Labels(RefIndex(c));
    DeltaNum=[]; ConditionLabel={}; % To Make Boxplots
    for r=1:numel(Labels)
        if ~isempty(DeltaExps{RefIndex(c),r})
           % Gather All The Deltas 
           VersusCondition=Labels(r);
           Nexps=size(DeltaExps{RefIndex(c),r},1);
           for e=1:Nexps
                ConditionLabel=[ConditionLabel;['+ ',char(VersusCondition)]];
           end
           DeltaNum=[DeltaNum;DeltaExps{RefIndex(c),r}];
        end
    end
    figure;
    for IndexFeat=1:size(DeltaNum,2)
        boxplot(DeltaNum(:,IndexFeat),ConditionLabel);
        ylab=ylabel(['%\Delta',FeatureNames{IndexFeat}]);
        ylab.Interpreter='tex';
        title(['Reference: ',char(TitleFig)])
        pause;
    end
end
