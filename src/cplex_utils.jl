
function context_id_to_name(context_id)
    if context_id == CPX_CALLBACKCONTEXT_BRANCHING
        return "CPX_CALLBACKCONTEXT_BRANCHING"
    elseif context_id == CPX_CALLBACKCONTEXT_CANDIDATE
        return "CPX_CALLBACKCONTEXT_CANDIDATE"
    elseif context_id == CPX_CALLBACKCONTEXT_GLOBAL_PROGRESS
        return "CPX_CALLBACKCONTEXT_GLOBAL_PROGRESS"
    elseif context_id == CPX_CALLBACKCONTEXT_LOCAL_PROGRESS
        return "CPX_CALLBACKCONTEXT_LOCAL_PROGRESS"
    elseif context_id == CPX_CALLBACKCONTEXT_RELAXATION
        return "CPX_CALLBACKCONTEXT_RELAXATION"
    elseif context_id == CPX_CALLBACKCONTEXT_THREAD_DOWN
        return "CPX_CALLBACKCONTEXT_THREAD_DOWN"
    elseif context_id == CPX_CALLBACKCONTEXT_THREAD_UP
        return "CPX_CALLBACKCONTEXT_THREAD_UP"
    end 
end 

function context_id_to_small_name(context_id)
    if context_id == CPX_CALLBACKCONTEXT_BRANCHING
        return "branching"
    elseif context_id == CPX_CALLBACKCONTEXT_CANDIDATE
        return "candidate"
    elseif context_id == CPX_CALLBACKCONTEXT_GLOBAL_PROGRESS
        return "global_progress"
    elseif context_id == CPX_CALLBACKCONTEXT_LOCAL_PROGRESS
        return "local_progress"
    elseif context_id == CPX_CALLBACKCONTEXT_RELAXATION
        return "relaxation"
    elseif context_id == CPX_CALLBACKCONTEXT_THREAD_DOWN
        return "thread_down"
    elseif context_id == CPX_CALLBACKCONTEXT_THREAD_UP
        return "thread_up"
    end 
end 


function context_string_to_id(s::String)::Clong 
    id = @eval $(Symbol(s))
    @assert context_id_to_name(id) == s 
    return id 
end 

function get_cplex_int(cb_data, object)
    value = Ref{Cint}()
    ret = CPXcallbackgetinfoint(cb_data, object, value)
    if ret == 0 
        return value[]
    else
        return 0 
    end 
end 

function get_cplex_long(cb_data, object)
    value = Ref{Clong}()
    ret = CPXcallbackgetinfolong(cb_data, object, value)
    if ret == 0 
        return value[]
    else
        return 0 
    end 
end 

function get_cplex_dbl(cb_data, object)
    value = Ref{Cdouble}()
    ret = CPXcallbackgetinfodbl(cb_data, object, value)
    if ret == 0 
        return value[]
    else
        return 0.0
    end 
end 