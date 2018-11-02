% Hierachichal CLustering of Raster Coactivity
% Input
%   Raster
%   CAG_TH
%   Nensembles
%   SimMethod
% Ouput
%   R_Analysis
function R_Analysis = raster_cluster(R,CAG_TH,Nensembles,SimMethod)
    ActiveCells=find(sum(R,2));
    % GET ONLY ACTIVE CELLS!
    Ractive=R(ActiveCells,:);
    CAG=sum(Ractive);
    Rclust=Ractive(:,CAG>=CAG_TH);
    Distance=squareform(pdist(Rclust',SimMethod));
    Sim=1-Distance;
    LinkageMethod=HBestTree_JPplus(Sim);    % Output
    Tree=linkage(squareform(Distance,'tovector'),LinkageMethod);
    frame_ensembles=cluster(Tree,'maxclust',Nensembles); % Output
    % OUTPUT
    R_Analysis.Data.Data=R';  % Frames x Cells (compatibility wit JP's NN)
    R_Analysis.Peaks.Threshold=CAG_TH;
    R_Analysis.Clustering.TotalStates=Nensembles;
    R_Analysis.Clustering.Tree=Tree;
    R_Analysis.Clustering.Linkage=LinkageMethod;
    R_Analysis.Peaks.Index=zeros(1,numel(CAG));
    R_Analysis.Peaks.Index(CAG>=CAG_TH)=1;
    R_Analysis.Clustering.VectorStateIndex=frame_ensembles;  % Sequence of Ensembles: frame_ensembles
end