% VNSA_60 preprocessing: 
% GOAL: CONVERT .RAW in .mat KSPACES

folder='/home/jschoormans/lood_storage/divi/Projects/cosart/scans/VNSA/VNSA60/VN_150604/';
cd(folder);
F=dir('*.raw')

%MRECON VERSION??

for ii=9
    cd(folder);
    file=F(ii).name
    
    MR=MRecon([folder,file]);
    MR.Parameter.Parameter2Read.typ=1;
    MR.Parameter.Recon.ImmediateAveraging='no'
    MR.ReadData;
    MR.RandomPhaseCorrection;
    MR.PDACorrection;
    MR.DcOffsetCorrection;
    MR.MeasPhaseCorrection;
    MR.SortData;
    % MR.Average;
    MR.RemoveOversampling;
    MR.RingingFilter;
    MR.ZeroFill;
    % MR.K2I;
    % MR.ShowData
    K=MR.Data;
    K=squeeze(K);
    K=K./max(K(:)); %normalize kspace
    
    cd('/scratch/jschoormans/VNSA_60')
    filename = strtok(file,'.')
    save(filename,'K','-v7.3');
    
end