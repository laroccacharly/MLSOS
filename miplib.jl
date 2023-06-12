ENV["EXPERIMENT_NAME"] = "miplib_all"
using MLSOS 

dataset = [
    ManyAlgorithmsDataset(EasyMiblibDataset(), [
        CPLEXAlgorithm(), 
        PNF(0.2, 1),
        PNF(0.2, 2),
    ]),
    ManyAlgorithmsDataset(MediumMiplibDataset(), [
        CPLEXAlgorithm(), 
        PNF(0.2, 60),
        PNF(0.2, 2*60),
    ]),
    ManyAlgorithmsDataset(HardMiplibDataset(), [
        CPLEXAlgorithm(), 
        PNF(0.2, 5*60),
        PNF(0.2, 10*60),
    ]),
] 

dataset = MergedDataset(dataset)

run_slurm(dataset)