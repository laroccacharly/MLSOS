abstract type ActionType end

abstract type CallbackActionType end 
struct LazyConstraint <: CallbackActionType end 
JSON.lower(::LazyConstraint) = "lazy_constraint"
# CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE, 
applicable_contexts(::LazyConstraint) = [CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE] 
struct UserCut <: CallbackActionType end 
JSON.lower(::UserCut) = "user_cut"
applicable_contexts(::UserCut) = [CPLEX.CPX_CALLBACKCONTEXT_RELAXATION]

struct AddLazyConstraint <: ActionType
    constraint::LazyConstraintType
end 