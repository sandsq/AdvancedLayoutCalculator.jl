using BenchmarkTools
randthing = rand(Int, 1000, 1000)

function sum1(randthing::Matrix{Int})
    tot = 0
    for j in axes(randthing, 2)
        for i in axes(randthing, 1)
            # if randthing[i, j] % 3 == 0
                tot += randthing[i, j]
            # end
        end
    end

    for j in axes(randthing, 2)
        for i in axes(randthing, 1)
            # if randthing[i, j] % 3 != 0
                tot += randthing[i, j]
            # end
        end
    end
    return tot
end

function sum2(randthing::Matrix{Int})
    tot = 0
    for j in axes(randthing, 2)
        for i in axes(randthing, 1)
            tot += randthing[i, j]
            tot += randthing[i, j]    
        end
    end
    # for j in axes(randthing, 2)
    #     for i in axes(randthing, 1)
            
    #     end
    # end
    return tot
end

@btime sum1($randthing)
@btime sum2($randthing)
t1 = sum1(randthing)
t2 = sum2(randthing)
# println(t1 == t2)
