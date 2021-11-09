using Symbolics

function lotka_volterra!(du, u, p, t)
  x, y = u
  α, β, δ, γ = p
  du[1] = dx = α*x - β*x*y
  du[2] = dy = -δ*y + γ*x*y
end

@variables t du[1:2] u[1:2] p[1:4]
lotka_volterra!(du, u, p, t)
D = Differential(t)
f = build_function((@. D(u) ~ du), u, p, t, target=Symbolics.JuliaTarget())

Base.remove_linenums!(f[1])

