@testset "Eval code" begin
    # see `converter/md_blocks:convert_code_block`
    # see `converter/lx/resolve_lx_input_*`
    # --------------------------------------------
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.PATHS[:assets], "scripts", "test1.jl")
    @test isfile(spath)
    @test isapproxstr(read(spath, String), """
        # This file was generated by JuDoc, do not modify it. # hide
        a = 5\nprint(a^2)""")

    opath = joinpath(J.PATHS[:assets], "scripts", "output", "test1.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test occursin("code: <pre><code class=\"language-julia\">a = 5\nprint(a^2)</code></pre>", h)
    @test occursin("then: <pre><code>25</code></pre> done.", h)
end

@testset "Eval code (errs)" begin
    # see `converter/md_blocks:convert_code_block`
    # --------------------------------------------
    h = raw"""
        Simple code:
        ```python:scripts/testpy
        a = 5
        print(a**2)
        ```
        done.
        """ * J.EOS |> seval

    @test occursin("code: <pre><code class=\"language-python\">a = 5\nprint(a**2)\n</code></pre> done.", h)
end

@testset "Eval (rel-input)" begin
    h = raw"""
        Simple code:
        ```julia:/scripts/test2
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{/scripts/test2}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.PATHS[:folder], "scripts", "test2.jl")
    @test isfile(spath)
    @test occursin("a = 5\nprint(a^2)", read(spath, String))

    opath = joinpath(J.PATHS[:folder], "scripts", "output", "test2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test occursin("code: <pre><code class=\"language-julia\">a = 5\nprint(a^2)</code></pre>", h)
    @test occursin("then: <pre><code>25</code></pre> done.", h)

    # ------------

    J.CUR_PATH[] = joinpath(J.PATHS[:src], "pages", "pg1.md")[lastindex(J.PATHS[:src])+2:end]

    h = raw"""
        Simple code:
        ```julia:./code/test2
        a = 5
        print(a^2)
        ```
        then:
        \input{output}{./code/test2}
        done.
        """ * J.EOS |> seval

    spath = joinpath(J.PATHS[:assets], "pages", "code", "test2.jl")
    @test isfile(spath)
    @test occursin("a = 5\nprint(a^2)", read(spath, String))

    opath = joinpath(J.PATHS[:assets], "pages", "code", "output" ,"test2.out")
    @test isfile(opath)
    @test read(opath, String) == "25"

    @test occursin("code: <pre><code class=\"language-julia\">a = 5\nprint(a^2)</code></pre>", h)
    @test occursin("then: <pre><code>25</code></pre> done.", h)
end

@testset "Eval code (module)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        using LinearAlgebra
        a = [5, 2, 3, 4]
        print(dot(a, a))
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval
    # dot(a, a) == 54
    @test occursin("then: <pre><code>54</code></pre> done.", h)
end

@testset "Eval code (img)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        write(joinpath(@__DIR__, "output", "test1.png"), "blah")
        ```
        then:
        \input{plot}{scripts/test1}
        done.
        """ * J.EOS |> seval
    @test occursin("then: <img src=\"/assets/scripts/output/test1.png\" alt=\"\"> done.", h)
end

@testset "Eval code (exception)" begin
    h = raw"""
        Simple code:
        ```julia:scripts/test1
        sqrt(-1)
        ```
        then:
        \input{output}{scripts/test1}
        done.
        """ * J.EOS |> seval
    # errors silently
    @test occursin("then: <pre><code>There was an error running the code.</code></pre>", h)
end

@testset "Eval code (no-julia)" begin
    h = raw"""
        Simple code:
        ```python:scripts/test1
        sqrt(-1)
        ```
        done.
        """ * J.EOS

    @test (@test_logs (:warn, "Eval of non-julia code blocks is not supported at the moment") h |> seval) == "<p>Simple code: <pre><code class=\"language-python\">sqrt(-1)\n</code></pre> done.</p>\n"
end