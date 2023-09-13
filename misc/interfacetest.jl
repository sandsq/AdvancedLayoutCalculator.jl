module IGeneric
    export logic

    function dosomething(gen, i) end

    function logic(gen, i)
        sum = 0.0
        v = dosomething(gen, i)
        for count in 1:10000
            for count2 in 1:100
                sum *= v[1]
            end
        end
    end
end

using BenchmarkTools
using .IGeneric

struct Generic end
IGeneric.dosomething(gen::Generic, i) = [i / 1.00001]
@btime IGeneric.logic(Generic(), 1.0)
@code_llvm IGeneric.logic(Generic(), 1.0)
IGeneric.dosomething(gen::Generic, i::Float32) = [i / 1.00001]
@btime IGeneric.logic(Generic(), 1.0)
@code_llvm IGeneric.logic(Generic(), 1.0)
function logic2(gen::Generic, i::Float32)
    sum = 0.0
    v = [i / 1.00001]
    for count in 1:10000
        for count2 in 1:100
            sum *= v[1]
        end
    end
end
@btime logic2(Generic(), 1.0)
@code_llvm logic2(Generic(), 1.0)