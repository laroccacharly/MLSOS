# From Flux.jl 
"""
    throttle(f, timeout; leading=true, trailing=false)
Return a function that when invoked, will only be triggered at most once
during `timeout` seconds.
Normally, the throttled function will run as much as it can, without ever
going more than once per `wait` duration; but if you'd like to disable the
execution on the leading edge, pass `leading=false`. To enable execution on
the trailing edge, pass `trailing=true`.
"""
function throttle(f, timeout; leading=true, trailing=false)
    cooldown = true
    later = nothing
    result = nothing

    function throttled(args...; kwargs...)
    yield()

    if cooldown
    if leading
        result = f(args...; kwargs...)
    else
        later = () -> f(args...; kwargs...)
    end

    cooldown = false
    @async try
        while (sleep(timeout); later != nothing)
        later()
        later = nothing
        end
    finally
        cooldown = true
    end
    elseif trailing
        later = () -> (result = f(args...; kwargs...))
    end

    return result
    end
end
