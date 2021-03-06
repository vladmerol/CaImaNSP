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
            LAMB=[LAMB;makerowvector(preLAMBDAS{v,c})']; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ManualMode
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
FileDirSave=pwd;
Slashes=find(FileDirSave=='\');
FileDirSave=FileDirSave(1:Slashes(end)-1);
if isdir([FileDirSave,'\Features Tables'])
    writetable(Tfeat,[FileDirSave,'\Features Tables\',FileProcessingFeatures],...
        'Delimiter',',','QuoteStrings',true);
    disp('Saved Table Features')
else % Create Directory
    disp('Directory >Resume Tables< created')
    mkdir([FileDirSave,'\Features Tables\']);
    writetable(Tfeat,[FileDirSave,'\Features Tables',FileProcessingFeatures],...
        'Delimiter',',','QuoteStrings',true);
    disp('Saved Table Features')
end

disp('saved.')