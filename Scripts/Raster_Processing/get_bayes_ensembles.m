% Function to Indentify Ensembles in Neural Activity
% by Clustering (hierarchichally) Neural *Coactivity* 
% Applies to the Raster after Selection 
% ***   OUTPUT has to be named with the sufix: _Analysis *****
% Neither need of tangled abstract stuff nor Monte Carlos Simulations
% Input
%   R:          Raster of Neural Activity (Matrix Cells x Frames)
% Output
%   R_Analysis: Raster Structur with Fields:
%       Data.Data=R;  % Frames x Cells (compatibility wit JP's NN)
%       Peaks.Threshold=CAG_TH;
%       Clustering.TotalStates=Nensembles;
%       Clustering.Tree=Tree;
%       Clustering.Linkage=LinkageMethod;
%       Peaks.Index=zeros(1,numel(CAG));
%       Peaks.Index(CAG>=CAG_TH)=1;
%       Clustering.VectorStateIndex=frame_ensembles;  % Sequence of Ensembles: frame_ensembles
%       Classifier.Model=Model;             % Naive Bayes Classifier
%       Classifier.ValidationError=ECV;      % Validation Error
function R_Analysis = get_bayes_ensembles(R)
%% Setup
% About the Raster
disp('> Getting data ...')

[Cells,Frames]=size(R); % Always More Frames than Cells
if Cells>Frames
    R=R';
    [Cells,Frames]=size(R);
    disp('>>Raster Transposed.')
end
ActiveCells=find(sum(R,2));
% GET ONLY ACTIVE CELLS!
Ractive=R(ActiveCells,:);
CAG=sum(Ractive);
MaxCAG=max(CAG);
%% AS IF ITS EMPTY *****??????
% Initialize Output
if MaxCAG==0
    fprintf('\n>> Raster with Zero Activity\n\n');
    R_Analysis.Data.Data=R; % Frames x Cells (compatibility wit JP's NN)
    fprintf('>> Finishing script...');
    Analyze=false;
else
    % Just Initialize:
    R_Analysis.Data.Data=R';  % Frames x Cells (compatibility wit JP's NN)
    R_Analysis.Peaks.Threshold=0;               %CAG_TH
    R_Analysis.Clustering.TotalStates=0;        % Nensemebles
    R_Analysis.Peaks.Index=zeros(1,Frames);     % Set 1 to Frames(CAG=>Threshold)
    R_Analysis.Clustering.VectorStateIndex=[];  % Sequence of Ensembles: frame_ensembles
    R_Analysis.Classifier.Model=[];             % Naive Bayes Classifier
    R_Analysis.Classifier.ValidationError=[];   % Validation Error
    Analyze=true;
end
%% START ANALYSIS
if Analyze
    fprintf('> Maximum Coactive Neurons   %i  \n',MaxCAG);
    % CAGThresholdValues=1:MaxCAG;
    % About the CLustering Method
    SimMethod='hamming'; % From Binary Codes used in Communications
    % This will increase as ensembles ain't a complete subset from another:
    disp('> Analysis Initialized ...')
    %% GLOBAL ANALYSIS SETUP
    tic;
    % GET Possible CAG Thresholds:
    ActiveNeuronsRatio=0.75;    % INPUT
    ActiveTime=0.5;             % INPUT
    CAGwithAN=[];
    for CAGindex=1:MaxCAG
        Rclust=Ractive(:,CAG>=CAGindex);
        ActiveCellsClust=find(sum(Rclust,2));
        PercAN(CAGindex)=numel(ActiveCellsClust)/numel(ActiveCells);
        ActTime(CAGindex)=sum((sum(Rclust)>0))/size(Ractive,2);
        fprintf('For %i CA Neurons-> %3.1f%% Active Neurons %3.1f%% of the Time\n',CAGindex,100*PercAN(CAGindex),100*ActTime(CAGindex));
        if PercAN(CAGindex)>=ActiveNeuronsRatio && ActTime(CAGindex)>=ActiveTime
            CAGwithAN=[CAGwithAN,CAGindex];
        end
    end
    % Corrections --------------------
    if numel(CAGwithAN)==1
        if CAGwithAN==1 && CAGwithAN<MaxCAG
            CAGwithAN=[CAGwithAN,2];
        elseif CAGwithAN<MaxCAG
            CAGwithAN=[CAGwithAN,CAGwithAN+1];
        end
    end
    % If there is not too much active time, use
    % Only Ratio of Active Neurons
    if isempty(CAGwithAN)    
        CAGwithAN=find(PercAN>ActiveNeuronsRatio);
    end
    % If still EMPTY->>Accept ALL
    if isempty(CAGwithAN)
        CAGwithAN=1:MaxCAG;
    end
    
    % Ensembles Setup ************
    % ClassRatio=zeros(numel(CAGwithAN),NensemblesTotal);
    ErrorClass=ones(numel(CAGwithAN),1);
    NensemblesOK=ones(numel(CAGwithAN),1);
    %% MAIN LOOPS
    for CAGindex=1:numel(CAGwithAN)   
        fprintf('>>> Clustering for  %i Coactive Neurons\n',CAGwithAN(CAGindex));
        Rclust=Ractive(:,CAG>=CAGwithAN(CAGindex));
        % [~,ActiveFrames]=size(Rclust);
        [frame_ensembles]=cluster_analyze(Rclust,SimMethod);
        [~,ECV]=Nbayes_Ensembles(Rclust,frame_ensembles);
        ErrorClass(CAGindex)=ECV;
        NensemblesOK(CAGindex)=numel(unique(frame_ensembles));
    end
    DelayTime=toc;
    [~,minErrIndx]=min(ErrorClass);
    disp('Retrieving Cluster Analysis');
    Rclust=Ractive(:,CAG>=CAGwithAN(minErrIndx));
    [ActiveCells,~]=find(sum(Rclust,2));
    % Get the Clustered Frames
    [frame_ensembles]=cluster_analyze(Rclust,SimMethod);
    
    % RE-LABEL Ensembles
    AppearSequence=unique(frame_ensembles,'stable');
    relabel_frame_ensembles=zeros(size(frame_ensembles));
    for n=1:NensemblesOK(minErrIndx)
        relabel_frame_ensembles(frame_ensembles==AppearSequence(n))=n;
    end
    
    % Features of the Ensembles:
    % Nensembles=numel(unique(frame_ensembles));
    NeuroVectors=zeros(numel(ActiveCells),NensemblesOK(minErrIndx));
    EnsembledNeurons={};
    MeanVarIntraDist=[];
    for nn=1:NensemblesOK(minErrIndx)
        EnsembledNeurons{nn}=find(sum(Rclust(:,relabel_frame_ensembles==nn),2));
        NeuroVectors(EnsembledNeurons{nn},nn)=1;
        VectorEnsemble=Rclust(:,relabel_frame_ensembles==nn);
        DhammVectors=pdist(VectorEnsemble',SimMethod);
        MeanVarIntraDist(nn,:)=[mean(DhammVectors),var(DhammVectors)];
    end
    DhammEns=pdist(NeuroVectors',SimMethod);
    [Model,ECV]=Nbayes_Ensembles(Rclust,relabel_frame_ensembles);
    %[label,Posterior]=resubPredict(Model);
    %C=confusionmat(relabel_frame_ensembles,double(label));
    % relabel_frame_ensembles=double(label);
    % ErrorClass(CAGindex)=ECV;
    
    % NensemblesOK(minErrIndx);
    fprintf('>> Analysis lasted %3.1f seconds  \n',DelayTime);
    fprintf('>> Clustering with %i Ensembles & for %i Coactive Neurons\n',NensemblesOK(minErrIndx),CAGwithAN(minErrIndx))
    
    %% Retrieve Ensmeble Cluster Array *********************************
    % OUTPUT
    R_Analysis.Data.Data=R';  % Frames x Cells (compatibility wit JP's NN)
    R_Analysis.Peaks.Threshold=CAGwithAN(minErrIndx);
    R_Analysis.Clustering.TotalStates=NensemblesOK(minErrIndx);
    % R_Analysis.Clustering.Tree=Tree;
    % R_Analysis.Clustering.Linkage=LinkageMethod;
    R_Analysis.Peaks.Index(CAG>=CAGwithAN(minErrIndx))=1;
    R_Analysis.Clustering.VectorStateIndex=relabel_frame_ensembles;  % Sequence of Ensembles: frame_ensembles
    R_Analysis.Classifier.Model=Model;             % Naive Bayes Classifier
    R_Analysis.Classifier.ValidationError=ECV;   
end
% fprintf('>> Clustering with %i Ensembles \n& for %i Coactive Neurons\n',Nensembles,CAG_TH)
fprintf('\n>>Script to search Neural Ensembles has ended.\n')