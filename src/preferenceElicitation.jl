module preferenceElicitation

export prefEl,@addPref

importall Base

using Distributions

# Support for 32 bit machines
F = typeof(1.0)

# Main type to hold all our data
type PrefEl
	data::Array{F,2}
	priors::Array{Distribution}
	strict::Array{Int,2}
	indif::Array{Int,2}
	sense::Symbol
end

# Default constructor)
function prefEl(data; strict = zeros(Int,0,2),
			 indif  = zeros(Int,0,2),
			 priors = [],
             sense  = :Max)

	if isempty(priors) # give them an improper uniform distribution
		n = size(data,2) # each dimension
		priors = Array(Uniform,n)
		for i in 1:size(data,2)
			priors[i].a = -Inf
			priors[i].b = Inf
		end
	end

	return PrefEl(data,priors,strict,indif,sense)
end

# Nice output
function show(io::IO,prefEl::PrefEl)
	println("Preference elicitaton object with:")
	(m,n) = size(prefEl.data)
	println("\tData: $m observations of $n dimensional data")

	println("\tStrict Preferences:")
	n = size(prefEl.strict,1)
	if n > 0 
		for i in 1:n
			a = prefEl.strict[i,1]
			b = prefEl.strict[i,2]
			println("\t\tRow $a > Row $b")
		end
	else
		println("\t\t[None]")
	end

	println("\tIndifference Preferences:")
	n = size(prefEl.indif,1)
	if n > 0 
		for i in 1:n
			a = prefEl.indif[i,1]
			b = prefEl.indif[i,2]
			println("\t\tRow $a == Row $b")
		end
	else
		println("\t\t[None]")
	end

	if prefEl.sense == :Max
		print("\tSense: Maximization") # don't need println because show automatically appends \n
	else
		print("\tSense: Minimization")
	end
end

# Basic interface

macro addPref(p,ex)

	@assert ex.head == :comparison

	one = ex.args[1]
	two = ex.args[3]

	if ex.args[2] == :(==) # indif comparison
		return quote
			$(esc(p)).indif = [$(esc(p)).indif; $(esc(one)) $(esc(two))]
			$(esc(p))
		end
	elseif ex.args[2] == :(>)
		return quote
			if $(esc(p)).sense == :Max 
				$(esc(p)).strict = [$(esc(p)).strict; $(esc(one)) $(esc(two))]
			else
				$(esc(p)).strict = [$(esc(p)).strict; $(esc(two)) $(esc(one))]
			end
			$(esc(p))
		end
	elseif ex.args[2] == :(<)
		return quote
			if $(esc(p)).sense == :Max 
				$(esc(p)).strict = [$(esc(p)).strict; $(esc(two)) $(esc(one))]
			else
				$(esc(p)).strict = [$(esc(p)).strict; $(esc(one)) $(esc(two))]
			end
			$(esc(p))
		end
	else
		error("Unrecognized comparison $(ex.args[2])")
	end

	# return quote
	# 	$(esc(p)).strict = [$one $two]
	# end
end

include("inference.jl")

end