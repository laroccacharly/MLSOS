abstract type LoadingPatternsType end 
struct OriginalLoadingPatterns <: LoadingPatternsType
end 

struct ReducedLoadingPatterns <: LoadingPatternsType
end 

function container_counts_list(::OriginalLoadingPatterns)
    # Copied from paper 
    [
       # [0, 0, 0, 0, 0], Include the empty pattern? 
       [1, 0, 0, 0, 0],
       [2, 0, 0, 0, 0],
       [0, 1, 0, 0, 0],
       [2, 1, 0, 0, 0],
       [2, 0, 1, 0, 0],
       [2, 0, 0, 1, 0],
       [2, 0, 0, 0, 1],
       [0, 2, 0, 0, 0],
       [0, 1, 1, 0, 0],
       [0, 1, 0, 1, 0],
       [0, 1, 0, 0, 1],
   ]
end 

function container_counts_list(::ReducedLoadingPatterns)
    [
        [0, 0, 0],
        [1, 0, 0],
        [2, 0, 0],
        [0, 1, 0],
        [2, 1, 0],
        [0, 2, 0],
        [2, 0, 1],
        [0, 1, 1],
    ]
end 

function get_all_container_length(::OriginalLoadingPatterns)
    ContainerLength.([
        20, 40, 45, 48, 53
    ])
end 

function get_all_container_length(::ReducedLoadingPatterns)
    ContainerLength.([
        20, 40, 53
    ])
end 
