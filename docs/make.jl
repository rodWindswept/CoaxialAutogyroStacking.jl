using Documenter
using CoaxialAutogyroStacking

DocMeta.setdocmeta!(
    CoaxialAutogyroStacking,
    :DocTestSetup,
    :(using CoaxialAutogyroStacking);
    recursive = true,
)

makedocs(;
    modules = [CoaxialAutogyroStacking],
    authors = "Rod Read <rod@windswept.energy>",
    sitename = "CoaxialAutogyroStacking.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://OWNER.github.io/CoaxialAutogyroStacking.jl",
    ),
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
)

# Uncomment and set OWNER once a GitHub remote exists, to publish to gh-pages:
# deploydocs(;
#     repo = "github.com/OWNER/CoaxialAutogyroStacking.jl",
#     devbranch = "master",
# )
