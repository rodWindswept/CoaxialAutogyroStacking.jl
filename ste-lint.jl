#!/usr/bin/env julia
# ste-lint.jl — STE lint for Julia source files
#
# Extracts docstrings and line comments from .jl files, strips code blocks,
# and checks prose against ASD-STE100 rules. Output matches ste-lint.py format.
#
# Usage:
#   julia ste-lint.jl src/*.jl
#   julia ste-lint.jl src/rotor.jl test/test_rotor.jl

using Printf

# ── Rule data ──────────────────────────────────────────────────────────────

const MARKETING = [
    "seamless", "seamlessly", "robust", "powerful", "cutting-edge",
    "effortless", "effortlessly", "world-class", "next-generation",
    "revolutionary", "blazing", "lightning-fast", "elegant", "delightful",
    "turnkey", "best-in-class", "state-of-the-art", "game-changing",
    "first-class", "battle-tested", "enterprise-grade", "supercharge",
    "unlock", "unleash", "empower", "empowers",
]

const BANNED = [
    "begin", "begins", "commence", "commences", "initiate", "initiates",
    "originate", "utilize", "utilizes", "utilizing", "leverage", "leverages",
    "leveraging", "facilitate", "facilitates", "ensure", "ensures", "ensuring",
    "prior to", "subsequent to", "obtain", "obtains", "acquire", "acquires",
    "demonstrate", "demonstrates", "additionally", "furthermore", "moreover",
    "comprehensive", "comprehensively", "utilization", "aforementioned",
    "henceforth", "therein", "whilst", "amongst", "numerous", "myriad",
    "plethora", "in order to", "a variety of", "in the event that",
    "due to the fact that", "it is important to note",
]

const PHRASAL = [
    "spin up", "spin down", "reach out", "dive into", "dives into",
    "diving into", "kick off", "kicks off", "roll out", "rolls out",
    "tear down", "ramp up", "circle back", "drill down", "spun up",
    "reaching out",
]

const MODAL_HEDGE = [
    "it is important to note", "it should be noted", "it is worth noting",
    "please note that", "as mentioned", "as noted above",
]

# ── Extraction ─────────────────────────────────────────────────────────────

function extract_prose(path::AbstractString)
    text = read(path, String)
    docstrings = eachmatch(r"\"\"\"(.*?)\"\"\""s, text)
    comments = eachmatch(r"^[ \t]*#[ \t]*(.+)$"m, text)
    parts = String[]
    for m in docstrings
        push!(parts, m.captures[1])
    end
    for m in comments
        push!(parts, m.captures[1])
    end
    return join(parts, "\n")
end

function strip_code(text::AbstractString)
    t = replace(text, r"```.*?```"s => " ")
    t = replace(t, r"`[^`]*`" => " ")
    return t
end

# ── Sentence splitting ─────────────────────────────────────────────────────

function sentences(text::AbstractString)
    out = String[]
    for line in split(text, "\n")
        s = strip(line)
        isempty(s) && continue
        s = replace(s, r"^#{1,6}\s*" => "")
        s = replace(s, r"^\s*(?:[-*+]|\d+[.)])\s+" => "")
        isempty(s) && continue
        parts = split(s, r"(?<=[.!?:])\s+(?=[A-Z0-9\"'\-])")
        for p in parts
            p = strip(p)
            isempty(p) || push!(out, p)
        end
    end
    return out
end

function word_count(s::AbstractString)
    return length(collect(eachmatch(r"[A-Za-z0-9][A-Za-z0-9'\-/]*", s)))
end

# ── Counters ────────────────────────────────────────────────────────────────

function count_ci(text::AbstractString, phrases)
    n = 0
    hits = String[]
    low = lowercase(text)
    for ph in phrases
        pattern = Regex("(?<![a-z])" * escape_string(ph) * "(?![a-z])", "i")
        for m in eachmatch(pattern, low)
            n += 1
            push!(hits, ph)
        end
    end
    return n, hits
end

# ── Main lint ───────────────────────────────────────────────────────────────

function lint(text::AbstractString)
    raw = text
    text = strip_code(text)
    sents = sentences(text)
    words = max(sum(word_count.(sents)), 1)

    v = Dict{String,Int}()

    # Long sentences
    v["long_sentence(>20w)"] = count(s -> word_count(s) > 20, sents)

    # Semicolons
    v["semicolon"] = count(==(';'), text)

    # Contractions
    v["contraction"] = length(collect(eachmatch(r"\b\w+['\u2019](?:t|re|ve|ll|d|s|m)\b", text)))

    # Passive voice: "be" + past participle
    be_pat = r"\b(am|is|are|was|were|be|been|being)\b"
    pp_irreg = r"\w+ed|done|made|sent|read|built|kept|held|set|put|run|written|shown|given|taken|found|got|gotten|seen|known|thrown|drawn"
    pv_regex = Regex("$(be_pat.pattern)\\s+($(pp_irreg.pattern))", "i")
    v["passive_voice"] = length(collect(eachmatch(pv_regex, text)))

    # -ing main verb
    ing_regex = Regex("$(be_pat.pattern)\\s+\\w+ing\\b", "i")
    v["ing_main_verb"] = length(collect(eachmatch(ing_regex, text)))

    # Nominalizations
    nom = 0
    nom += length(collect(eachmatch(
        r"\b(?:perform(?:s|ed)?|conduct(?:s|ed)?|provide(?:s|d)?|carry out|carries out|make use of|makes use of)\b", text)))
    nom += length(collect(eachmatch(r"\b\w{4,}(?:tion|ment|ance|ence)\s+of\b", text)))
    v["nominalization"] = nom

    # Phrasal verbs
    v["phrasal_verb"], _ = count_ci(text, PHRASAL)

    # Banned words
    v["banned_word"], bh = count_ci(text, BANNED)

    # Marketing adjectives
    v["marketing_adjective"], mh = count_ci(text, MARKETING)

    # Modal hedges
    v["modal_hedge"], _ = count_ci(text, MODAL_HEDGE)

    # Long paragraphs
    paragraphs = filter(!isempty, split(raw, r"\n\s*\n"))
    v["long_paragraph(>6s)"] = count(p -> length(sentences(strip_code(p))) > 6, paragraphs)

    total = sum(values(v))
    em = count(==('\u2014'), raw) + count(==('\u2013'), raw)

    longest = maximum(word_count.(sents); init=0)

    return (;
        words, sent_count=length(sents),
        violations=v, total,
        total_per100w=round(total * 100.0 / words, digits=2),
        em_dash=em,
        longest_sentence_words=longest,
        sample_marketing=unique(mh)[1:min(6, end)],
        sample_banned=unique(bh)[1:min(6, end)],
    )
end

# ── CLI ─────────────────────────────────────────────────────────────────────

if abspath(PROGRAM_FILE) == @__FILE__
    if isempty(ARGS)
        r = lint(read(stdin, String))
        println(JSON.json(r))
        exit(0)
    end

    for f in ARGS
        prose = extract_prose(f)
        r = lint(prose)
        @printf("%-32s words=%4d total=%3d per100w=%6.2f em_dash=%2d\n",
                basename(f), r.words, r.total,
                r.total_per100w, r.em_dash)
    end
end
