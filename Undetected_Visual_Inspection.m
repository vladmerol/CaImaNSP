%% Setup
Import_FinderSpiker;
%% # Check False Negative:
% Rejected and unprocessed Data

[C,V]=size(SIGNALS);
Ndata=0;
Nvidok=0;
for c=1:C
    for v=1:V
        if ~isempty(SIGNALS{c,v})
            Ndata=Ndata+1;
            if isempty(notSIGNALS{c,v})
                Nvidok=Nvidok+1;
            end
        end
    end
end
if Nvidok<Ndata
    indxSIGNALSOK = Calcium_Magic(notSIGNALS);
    VisualInspector(2)=true;
else
    disp('>>No rejected Data: all cell were detected')
end
