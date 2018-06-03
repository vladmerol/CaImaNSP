%% Function to plot Hebbain Sequences
% INPUT:
%   R_Condition:        from Selected Raster
%   Ensemble_Threshold
%   Ensembled_Labels
%   fs: sampling frequency
% OUTPUT
% Figure of Hebbian Paths
function Plot_Hebbian_Paths(R_Condition,Ensemble_Threshold,Ensembled_Labels,Names_Conditions,ColorState,fs)
%% Setup
% Get Number Of Conditions
[~,C]=size(R_Condition);
% Get Number of Different Ensmebles
Ensambles=[];
for c=1:C
    Ensambles=[Ensambles;unique(Ensembled_Labels{c})];
end
Ensambles =   unique(Ensambles);
Ne=numel(Ensambles); % TOTAL NUMBER OF ENSEMBLES (all experiment)

%% Main LOOP
for c=1:C
    HebbianFig=figure;
    R=R_Condition{c};               % RASTER
    [AN,Frames]=size(R);            % Total Active Neurons [selected]
    RasterDuration=Frames/fs/60;    % MINUTES
    CAG=sum(R);                     % Coactivitygram
    Th=Ensemble_Threshold{c};       % Significant Threshold
    signif_frames=find(CAG>=Th);    % Significatn Frames
    Ensembles_Labels=Ensembled_Labels{c}; % Labels each Frame
    HS=Ensembles_Labels(diff(signif_frames)>1); % For Each Significant Peak
    EnsembleFrames=signif_frames(diff(signif_frames)>1);
    t=linspace(0,RasterDuration,Frames);
    plot(t(EnsembleFrames),HS,'k','LineWidth',1);
    hold on;
    for e=1:numel(HS)
        plot(t(EnsembleFrames(e)),HS(e),'o',...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor',ColorState(HS(e),:),...
            'MarkerSize',12); 
    end
    hold off;
    HebbianFig.Children.XTick=[0:round(RasterDuration)];
    HebbianFig.Children.YTick=[min(HS):max(HS)];
    HebbianFig.Children.YLabel.String='Ensembles';
    HebbianFig.Children.YLim=[min(HS)-0.25,max(HS)+0.25];
    HebbianFig.Name=['Hebbian Paths: ',Names_Conditions{c}];
end