%% PERMANTENT NOTES # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
% Manual Mode is divideed in two parts->
% Necessary to know the statistical power of the Automatic Mode:
% of the automatic method by dividing in -+ and -- (false+ & false-)
% Old Version Manual Mode:
%   Manual_Driver_Raster_Magic.m (becoming unnecessary)

% Features  of Experiments:  
% >Rasters,             MATLAB script
% >Ensembles general    MATLAB script
% >Ensembles details    MATLAB script
% >Networks             from Gephi

%% FIXED  READY TO GO @ GIT
% >Bug @ Ensemble Details table Visualizer: Experiment IDs
% Integrate all Features in single Datasets for each Category
% RASTER|ENSEMBLES|ENSEMBLESdetailed|NETWORK (MANUALLY)
% Load and Classify Set Of Features with Naive Bayes Classifier
% >bug at Raster_Act_Features-> From Only Active Selected Cells & Indexes
% Bug At Cycles Retrieveing (!)
% ReSAVE Ensembles Features !!!
% Bug @ NBC and Best Subset Features
%% Bugs & New Functions NOW

% Sort Experiment IDs accroding to condition
% Merge & Classify ALL features: raster/ensemble/ network

% Get best subset of features that best classify vs PCA

% For Results Visualization
% All-Features->PCA (dim red)-> SVM

% Save .mat File even when if it was analyzed at NeuralNetwork GUI

% Test Mike's Clsutering Algorithm 4 CoActivity (transposed matrix)and save as weel

% SIGNAL PROCESSING RELATED
%   Somee offset at detrending algorithm 
%   Spurious Drivers
%       Lone Drivers: check clean signal's samples around if they're above noise
%   Check at Signals with Huge Valley (synaptic like)

% RETRIEVE SIGNALS & RECONSTRUCT VIDEO
% retreive of Original Signals, coordinates, etc:
% Re make clean video

%%% MAKE ALGORITHMIA

% delete Plot_Raster_V.m

% Test Visualizer of CDF for (+)and (-) colocated cells

% Add button to save Zoom image (MERGED MAGIC)
% Save Selected Points SELECTED-> add to file .mat
% Add Highlight Neuron Using Mouse at Plot_Raster
% and other colors in the MERGE script : MAGENTA

% Inspection for Each ROI...

% Detect when its empty detected or undetected at :
%   Undetected_Visual_Inspection


%% FUTURE **********************************
% Figure: reason whi mean(ROI) withput distortion
% Load Raw FLuorescenc vs F_0 distortion
% Analyze Rejects Ones Anyway to infer Artifacts
% Processing Times/Detections/etc from log files
% Automatize MERGE SELECTOR
% Setup Intel/Info .mat File-> Default User Directory to save info
% Setup Script: deconvolution parameters

%% STEPS GUIDE *********************************************************
% SIGNAL PROCESSING: Detect Calcium Transients Events
% >>Finder_Spiker_Calcium
% >>Detected_Visual_Inspection
% >>Undetected_Visual_Inspection
% >>Save_and_Plot

% RASTER SELECTION
% ACTUAL MODE: @ Original Coordiantes Order
% >>Select_Rasters

% RETRIEVE RASTER for ANALYSIS
% >>R=RASTER_Selected_Clean'; % ALL CONDITIONS
% >>R_CONDITION1=R_Condition{1}; % Cells x Frames (dim)
% ...
% >>R_CONDITIONi=R_Condition{i};

% CLUSTERING NEURONAL ENSEMBLES
% AUTOMATIC
% >>R_CONDITIONi_Analysis=get_bayes_ensembles(R_CONDTIONi);
% MANUAL GUI: Neural_Networks


% DISPLAY AND SAVE RESULTS OF ENSEMBLES DISPLAY AND SAVE (GUI)
% Neural ensemble and Functional Network Features Extraction
% >> Ensemble_Sorting

% PLOT ENSEMBLES FAST
% >> ImageEnsembles(R_ConditionNamej_Analysis);

% COLOCALIZATION OF MARKED CELLS
% >>Merge_Finder_Magic

% INSPECTION to RETRIEVE ORIGINAL SIGNALS from RASTER SELECTION
% 1) Plot Raster (without sorting) from:
% >>[Rsel,IndexSorted]=Retrieve_Selected_Signal(Onsets,R_Condition,RASTER,XY_merged,XY);
% Each Rsel{n} is the selected raster
% >>Rjunto=[Rsel{1},Rsel{2},Rsel{3}]; Plot_Raster_Ensembles(Rjunto);
% Find Cell of Interest: Ci
% >>[XS,IndexSorted]=Retrieve_Selected_Signal(Onsets,R_Condition,SIGNALSclean,XY_merged,XY);
% >>figure; plot(XS{c}(Ci,:))

% N-EXPERIMENTS RESULTS ###################################################

% LOAD & GET FEATURES FOR A SET OF EXPERIMENTS*****************************
% These scripts save feature tables 
% for Machine Learning or Statistical Analysis

% RASTER FEATURES
% Choose All CSV files at once
% >>Raster_Features_Display
% ENSEMBLES GENERAL FEATURES 
% >>Ensembles_Features_Display
% ENSEMBLES DETAILED FEATURES 
% >>Ensembles_Features_Detailed_Display
% Script to Merged them and make a DATASET for Machine Learning:
% >>Merge_Feature_Datasets

% IGNORE EXPERIMENTS:
% >>Check_Data_Dyskinesia % (user defined)

% MACHINE LEARNING: choose a Dataset:
% >>Features_Datasets_NBC

% ACCUMULATE FEATURES FROM SEVERAL EXPERIMENTS ****************************
% Choose One-by-One .mat Files
% >>Accumulate_RoA_IEI_ED
% >>Accumulate_Ensembles_RoEn_IEnI_EnD
% >>Accumulate_Simm_Matrix

%% END ####################################################################