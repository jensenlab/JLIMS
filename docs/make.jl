push!(LOAD_PATH,"../src/")


using Documenter, JLIMS, Unitful,UnitfulParsableString

makedocs(sitename="JLIMS.jl",
format=Documenter.LaTeX(),
pages = [ 
    "Home" => "index.md",
    "Manual" => Any[ 
        "manual/overview.md",
        "manual/ingredients.md",
        "manual/compositions.md"
    ]
]
)