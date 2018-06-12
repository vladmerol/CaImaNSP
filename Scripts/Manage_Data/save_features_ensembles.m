%% Save DATA: Neural Ensembles Features
% .mat file:
%   Features_Ensemble
%   Features_Condition
% .CSV file
%   N-Ensembles,Dunns Index,RateOfTransitions,RateOfCycles,DominantEnsemble
%   N SimpleCycles, N-ClosedCycles , N-OpenedCycles
%   Ensemble i Rate,...
%   Ensemble i Dominance=%NeuronsOccupance * Rate,...
function save_features_ensembles(Experiment,Names_Conditions,Features_Ensemble,Features_Condition)
% Setup
% Saving Directory: one above where Finder Spiker is..
FileDirSave=pwd;
slashes=find(FileDirSave=='\');
FileDirSave=FileDirSave(1:slashes(end));

%% SAVE OUTPUT DATASET (.m file)
checkname=1;
while checkname==1
    DefaultPath=[FileDirSave,'Processed Data'];
    if exist(DefaultPath,'dir')==0
        DefaultPath=pwd; % Current Diretory of MATLAB
    end
    [FileName,PathName] = uigetfile('*.mat',[' Pick the Analysis File ',Experiment],...
        'MultiSelect', 'off',DefaultPath);
    dotindex=find(FileName=='.');
    if strcmp(FileName(1:dotindex-1),Experiment(2:end))
        checkname=0;
        % SAVE DATA
        save([PathName,FileName],'Features_Ensemble','Features_Condition',...
            '-append');
        disp([Experiment,'   -> UPDATED (Ensembles Features)'])
    elseif FileName==0
        checkname=0;
        disp('*************DISCARDED************')
    else
        disp('Not the same Experiment!')
        disp('Try again!')
    end
end    
%% SAVE CSV FILES
% Direcotry Name
NameDir='Ensemble Features\';
% Number of Condition
if iscell(Names_Conditions)
    C=numel(Names_Conditions);
else
    C=1;
end

for c=1:C
    HeadersFeatures={'Ensembles','Dunns','RateTrans','RateCycles','Dominant',...
    'SimpleCycles','ClosedCycles','OpenedCycles'};
    Tensemblesfeatures=table;
    % Condition Table
    Name=Names_Conditions{c};
    [~,NE]=size(Features_Ensemble.Neurons);             % N ensembles
    DunnIndx=Features_Condition.Dunn(c);                % Dunns Index
    RateTran=Features_Condition.RateTrans(c);           % Rate Transitions
    RateCycl=Features_Condition.RateCycles(c);          % Rate Cycles
    [~,EnseDom]=max(Features_Ensemble.Dominance(c,:));  % Dominant Ensemble
    % Simple Cycles
    Portion_simple=Features_Condition.CyclesType(1,c)/sum(Features_Condition.CyclesType(:,c));
    % Closed Cycles
    Portion_closed=Features_Condition.CyclesType(2,c)/sum(Features_Condition.CyclesType(:,c));
    % Opened Cycles
    Portion_opened=Features_Condition.CyclesType(3,c)/sum(Features_Condition.CyclesType(:,c));
    % INITIALIZE TABLE
    Tensemblesfeatures=table(NE,DunnIndx,RateTran,RateCycl,EnseDom,...
        Portion_simple,Portion_closed,Portion_opened);
    for n=1:NE
        HeadersFeatures{end+1}=['RateEns_',num2str(n)];
        Tensemblesfeatures(1,end+1)=table(Features_Ensemble.Rate(c,n));
    end
    for n=1:NE
        HeadersFeatures{end+1}=['DomEns_',num2str(n)];
        Tensemblesfeatures(1,end+1)=table(Features_Ensemble.Dominance(c,n));
    end
    Tensemblesfeatures.Properties.VariableNames=HeadersFeatures;
    % Save CSV
    if isdir([FileDirSave,NameDir])
        writetable(Tensemblesfeatures,[FileDirSave,NameDir,Experiment(2:end),'_',Name,'_EF.csv'],...
            'Delimiter',',','QuoteStrings',true);
        disp(['Saved Ensemble Features: ',Experiment,'-',Names_Conditions{c}])
    else % Create Directory
        disp('Directory >Ensemble Features< created')
        mkdir([FileDirSave,NameDir]);
        writetable(Tensemblesfeatures,[FileDirSave,NameDir,Experiment(2:end),'_',Name,'_EF.csv'],...
            'Delimiter',',','QuoteStrings',true);
        disp('Ensemble Features Directory Created');
        disp(['Saved Ensemble Features: ',Experiment,'-',Names_Conditions{c}])
    end
    
end