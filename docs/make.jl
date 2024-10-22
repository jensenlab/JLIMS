push!(LOAD_PATH,"../src/")


using Documenter, JLIMS

makedocs(sitename="JLIMS.jl",
pages = [ 
    "Home" => "index.md"
]
)