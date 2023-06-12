mutable struct FcnNet <: ProblemInstance
    graph::MetaDiGraph
    nodes::Array{Node, 1}
    arcs::Array{Arc, 1}
    info::Dict{String, Any}
    FcnNet() = new(MetaDiGraph(0), [], [], Dict())
end 
typedict(net::ProblemInstance) = metrics_dict(net)

abstract type FcnFormulation end 
struct SingleCommodity <: FcnFormulation 
end 
JSON.lower(::SingleCommodity) = "single_commodity"
struct MultiCommodity <: FcnFormulation 
end 
JSON.lower(::MultiCommodity) = "multi_commodity"

struct FcnScenario <: ProblemScenario
    seed::Int 
    name::String 
    size::Int
    formulation::FcnFormulation
end 
FcnScenario() = FcnScenario(0, "default", 1, SingleCommodity())
set_size!(s::FcnScenario, size::Int) = @set s.size = size
get_formulation(s::FcnScenario) = s.formulation

struct FixedChargeLabel <: LabelType 
end 
JSON.lower(::FixedChargeLabel) = "fixed_charge"
get_index_sym(::FixedChargeLabel) = :arc_id
get_symbol(::FixedChargeLabel) = :fixed_charge 
mip_var_sym(::FixedChargeLabel) = :y 
get_objects(instance::FcnNet, ::FixedChargeLabel) = get_arcs(instance)


struct FlowChargeLabel <: LabelType 
end 
JSON.lower(::FlowChargeLabel) = "flow_charge"
get_index_sym(::FlowChargeLabel) = :arc_id
get_symbol(::FlowChargeLabel) = :flow_charge 
mip_var_sym(::FlowChargeLabel) = :x
get_objects(instance::FcnNet, ::FlowChargeLabel) = get_arcs(instance)

get_all_label_types(::FcnNet) = [
    FixedChargeLabel(),
    FlowChargeLabel() 
]