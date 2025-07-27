using TulipaBuilder
using Documenter

DocMeta.setdocmeta!(TulipaBuilder, :DocTestSetup, :(using TulipaBuilder); recursive = true)

const page_rename = Dict("developer.md" => "Developer docs") # Without the numbers
const numbered_pages = [
    file for file in readdir(joinpath(@__DIR__, "src")) if
    file != "index.md" && splitext(file)[2] == ".md"
]

makedocs(;
    modules = [TulipaBuilder],
    authors = "Abel Soares Siqueira",
    repo = "https://github.com/TulipaEnergy/TulipaBuilder.jl/blob/{commit}{path}#{line}",
    sitename = "TulipaBuilder.jl",
    format = Documenter.HTML(;
        canonical = "https://TulipaEnergy.github.io/TulipaBuilder.jl",
    ),
    pages = ["index.md"; numbered_pages],
)

deploydocs(; repo = "github.com/TulipaEnergy/TulipaBuilder.jl")
