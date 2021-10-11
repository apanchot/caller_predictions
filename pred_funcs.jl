
import StatsBase
function textonehot(df,col,delim=";")
	filtermut = [split(i,delim) for i in df[:,col]]
	filtermutect = unique(reduce(vcat,filtermut))
	filtermutectdata = DataFrame(zeros(Float64,nrow(df),length(filtermutect) ),string.(col,"_",filtermutect) )
	for i in 1:length(filtermut)
		for j in 1:length(filtermut[i]) # j is column to be set to 1
			id=findfirst(x->x == filtermut[i][j],filtermutect)
			filtermutectdata[i,id] = 1.0
		end
	end
	return filtermutectdata
end

function sampler(xx2,yy2,train,way,ratio_under_to_over)
	# yv=Array(yv)
    xx=xx2[train,:]
    yy=yy2[train]
	if ratio_under_to_over == 0
		return xx2,yy2,train
	end
    yy = [i==true for i in yy]
	trues = findall(x->x,yy)
	falses = findall(x->!x,yy)
	u = length(trues)
	o = length(falses)
	r =  u/o
    println("ratio: ",r)
	v = []
	if way == "over"
		x = round(Int,ratio_under_to_over * o - u)
        println("number of new: ",x)
		for i in StatsBase.sample(1:u,x,replace=true)
			push!(v, trues[i])
		end
        train = vcat(train,length(yy2)+1:length(yy2)+length(v))
		return vcat(xx2,xx[v,:]),vec(vcat(yy2,yy[v,:])),train
	else
		x = round(Int, u / ratio_under_to_over)
		for i in StatsBase.sample(1:o,x,replace=false)
			push!(v, falses[i])
		end
		
		return vcat(xv[v,:],xv[trues,:]), vcat(yv[v],yv[trues] )
	end
	
end


struct standardizer
    col_names::Vector{String}
    means::Vector{Float64}
    stds::Vector{Float64}
end

struct normalizer
    col_names::Vector{String}
    maxs::Vector{Float64}
    mins::Vector{Float64}
end


function fit_standardizer(df)
	namevec = Vector{String}()
	meanvec = Vector{Float64}()
	stdvec = Vector{Float64}()
	for colname in names(df)
		if length(unique(df[:,colname])) > 2 && typeof(df[findfirst(x->!ismissing(x),df[:,colname]),colname]) <: Union{Float32, Float64}
			push!(namevec,colname)
			push!(meanvec,mean(skipmissing(df[:,colname])) )
			st = std(skipmissing(df[:,colname]))
			if st < eps(Float32)
				if typeof(df[findfirst(x->!ismissing(x),df[:,colname]),colname]) <: Float32
					push!(stdvec, eps(Float32))
				else
					push!(stdvec, eps(Float64))
				end
			else
				push!(stdvec, st)
			end
		end
	end
	return standardizer(namevec,meanvec,stdvec)
end

function transform_standardizer!(df, standardzer)
	for col in 1:length(standardzer.col_names)
		for i in 1:nrow(df)
			df[i,standardzer.col_names[col] ] = ( df[i,standardzer.col_names[col] ] - standardzer.means[col] ) / standardzer.stds[col]
		end
	end
end

function fit_normalizer(df)
	namevec = Vector{String}()
	maxvec = Vector{Float64}()
	minvec = Vector{Float64}()
	for colname in names(df)
		if length(unique(df[:,colname])) > 2 && typeof(df[findfirst(x->!ismissing(x),df[:,colname]),colname]) <: Union{Float32, Float64}
			push!(namevec,colname)
			mx = maximum(skipmissing(df[:,colname]))
			push!(maxvec,mx )
			st = minimum(skipmissing(df[:,colname]))
			if isapprox(mx,st)
				if typeof(df[findfirst(x->!ismissing(x),df[:,colname]),colname]) <: Float32
					push!(minvec, st-eps(Float32))
				else
					push!(minvec, st-eps(Float64))
				end
			else
				push!(minvec, st)
			end
		end
	end
	return normalizer(namevec,maxvec,minvec)

end

function transform_normalizer!(df, normalizer)
	for col in 1:length(normalizer.col_names)
		for i in 1:nrow(df)
			df[i,normalizer.col_names[col] ] = ( df[i,normalizer.col_names[col] ] - normalizer.mins[col] ) / ( normalizer.maxs[col] - normalizer.mins[col]  )
		end
	end
end