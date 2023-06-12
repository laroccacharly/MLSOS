abstract type LabelType end
abstract type VarRefLabelType <: LabelType end 
struct VarRefLabel <: VarRefLabelType 
end 

struct ContainerSlotAssignment <: LabelType
end 

struct ContainerPlatformAssignment <: LabelType
end 

struct ContainerRailcarAssignment <: LabelType
end 

struct RailcarLoadingPatternAssignment <: LabelType
end 

struct SlackLabel <: LabelType
end 
is_binary(::SlackLabel) = true 

struct ConsistGap <: LabelType
end 

struct SolutionStability <: LabelType
end 