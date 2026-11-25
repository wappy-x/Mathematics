-- Darboux's theorem: the file proves that a graph p = β(q) is Lagrangian exactly when the one-form β is closed, that u = x + x³/3 turns the rain form (1 + x²) dx ∧ dy into du ∧ dv, and that Moser's flow for the rain undoes u.
import Mathlib.Analysis.Calculus.DifferentialForm.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.ContinuousAlternatingMap
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

noncomputable section

/-! ### The graph test for Lagrangian submanifolds -/

/-- The standard symplectic form `ω = dq₁ ∧ dp₁ + ⋯ + dqₙ ∧ dpₙ` on two arrows of position–momentum
space `ℝⁿ × ℝⁿ`: `ω(ξ, η) = Σᵢ (ξ.qᵢ η.pᵢ - ξ.pᵢ η.qᵢ)`. -/
def omegaStd {n : ℕ} (ξ η : (Fin n → ℝ) × (Fin n → ℝ)) : ℝ :=
  ∑ i, (ξ.1 i * η.2 i - ξ.2 i * η.1 i)

/-- The graph map `s_β(q) = (q, β(q))` of a one-form `β = β₁ dq₁ + ⋯ + βₙ dqₙ` on `ℝⁿ`:
its momentum `pᵢ` is `βᵢ(q) = β(q)(∂_{qᵢ})`. -/
def graphMap {n : ℕ} (β : (Fin n → ℝ) → (Fin n → ℝ) [⋀^Fin 1]→L[ℝ] ℝ) (q : Fin n → ℝ) :
    (Fin n → ℝ) × (Fin n → ℝ) :=
  (q, fun i => β q ![Pi.single i 1])

theorem oneForm_sum {n : ℕ} (f : (Fin n → ℝ) [⋀^Fin 1]→L[ℝ] ℝ) (v : Fin n → ℝ) :
    ∑ i, v i * f ![Pi.single i 1] = f ![v] := by
  classical
  let L : (Fin n → ℝ) →ₗ[ℝ] ℝ := f.toMultilinearMap.toLinearMap (fun _ => 0) 0
  have hL : ∀ x, L x = f ![x] := by
    intro x
    have hu : Function.update (fun _ => (0 : Fin n → ℝ)) (0 : Fin 1) x = ![x] := by
      funext j; fin_cases j; simp
    simp only [L, MultilinearMap.toLinearMap_apply, hu]
    rfl
  rw [← hL, LinearMap.pi_apply_eq_sum_univ L v]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← hL, smul_eq_mul]
  congr 2
  ext j
  simp [Pi.single_apply, eq_comm]

theorem graphMap_fderiv {n : ℕ}
    (β : (Fin n → ℝ) → (Fin n → ℝ) [⋀^Fin 1]→L[ℝ] ℝ) (hβ : Differentiable ℝ β) (q v : Fin n → ℝ) :
    fderiv ℝ (graphMap β) q v = (v, fun i => fderiv ℝ β q v ![Pi.single i 1]) := by
  have h : HasFDerivAt (graphMap β)
      ((ContinuousLinearMap.id ℝ _).prod
        (ContinuousLinearMap.pi fun i =>
          (ContinuousAlternatingMap.apply ℝ (Fin n → ℝ) ℝ ![Pi.single i 1]).comp
            (fderiv ℝ β q))) q := by
    apply (hasFDerivAt_id q).prodMk
    rw [hasFDerivAt_pi]
    intro i
    exact (ContinuousAlternatingMap.apply ℝ (Fin n → ℝ) ℝ ![Pi.single i 1]).hasFDerivAt.comp q
      (hβ q).hasFDerivAt
  rw [h.fderiv]
  rfl

theorem extDeriv_two {n : ℕ}
    (β : (Fin n → ℝ) → (Fin n → ℝ) [⋀^Fin 1]→L[ℝ] ℝ) (q v w : Fin n → ℝ) :
    extDeriv β q ![v, w] = fderiv ℝ β q v ![w] - fderiv ℝ β q w ![v] := by
  rw [extDeriv, ContinuousAlternatingMap.alternatizeUncurryFin_apply, Fin.sum_univ_two]
  have hr : Fin.removeNth 1 ![v, w] = ![v] := by
    funext j; fin_cases j; rfl
  simp [hr, sub_eq_add_neg]

/-- The graph test, `s_β^* ω = -dβ`: the graph `p = β(q)` of a smooth one-form `β` is Lagrangian
(`ω` is zero on every two arrows tangent to it; the graph already has dimension `n`, half of `2n`)
exactly when `β` is closed, `dβ = 0`. -/
theorem graph_lagrangian_iff_closed {n : ℕ}
    (β : (Fin n → ℝ) → (Fin n → ℝ) [⋀^Fin 1]→L[ℝ] ℝ) (hβ : Differentiable ℝ β) :
    (∀ q v w, omegaStd (fderiv ℝ (graphMap β) q v) (fderiv ℝ (graphMap β) q w) = 0) ↔
      ∀ q, extDeriv β q = 0 := by
  have key : ∀ q v w, omegaStd (fderiv ℝ (graphMap β) q v) (fderiv ℝ (graphMap β) q w) =
      - extDeriv β q ![v, w] := by
    intro q v w
    rw [graphMap_fderiv β hβ, graphMap_fderiv β hβ, extDeriv_two, omegaStd]
    simp only [Finset.sum_sub_distrib]
    rw [oneForm_sum]
    simp only [mul_comm _ (w _)]
    rw [oneForm_sum]
    ring
  constructor
  · intro h q
    ext m
    have hm : m = ![m 0, m 1] := by
      ext j; fin_cases j <;> rfl
    rw [hm]
    have := key q (m 0) (m 1)
    rw [h] at this
    simp
    linarith
  · intro h q v w
    rw [key, h]
    simp

/-! ### The rain: a Darboux chart for `(1 + x²) dx ∧ dy` -/

/-- The rain-equal coordinate across the valley, `u = x + x³/3`, with `x` in km from the river. -/
def u (x : ℝ) : ℝ := x + x ^ 3 / 3

/-- The chart `(x, y) ↦ (u, v) = (x + x³/3, y)`. -/
def darbouxChart (z : ℝ × ℝ) : ℝ × ℝ := (u z.1, z.2)

/-- A two-form `dx ∧ dy` on two arrows of the plane: their signed area. -/
def area2 (ξ η : ℝ × ℝ) : ℝ := ξ.1 * η.2 - ξ.2 * η.1

theorem u_hasDerivAt (x : ℝ) : HasDerivAt u (1 + x ^ 2) x := by
  have h := ((hasDerivAt_id x).add ((hasDerivAt_pow 3 x).div_const 3))
  convert h using 1
  · funext y; simp [u]
  · norm_num

theorem u_strictMono : StrictMono u := by
  intro a b hab
  simp only [u]
  nlinarith [sq_nonneg (a - b), sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]

theorem darbouxChart_fderiv (z ξ : ℝ × ℝ) :
    fderiv ℝ darbouxChart z ξ = ((1 + z.1 ^ 2) * ξ.1, ξ.2) := by
  have h : HasFDerivAt darbouxChart
      (((ContinuousLinearMap.smulRight (1 : ℝ →L[ℝ] ℝ) (1 + z.1 ^ 2)).comp
        (ContinuousLinearMap.fst ℝ ℝ ℝ)).prod (ContinuousLinearMap.snd ℝ ℝ ℝ)) z := by
    apply HasFDerivAt.prodMk
    · exact (u_hasDerivAt z.1).hasFDerivAt.comp z hasFDerivAt_fst
    · exact hasFDerivAt_snd
  rw [h.fderiv]
  simp [mul_comm]

/-- `u = x + x³/3`, `v = y` is a chart on the whole plane (one-to-one), and it pulls `du ∧ dv`
back to the rain form `(1 + x²) dx ∧ dy` on every two arrows at every point, because
`du = (1 + x²) dx`. -/
theorem rain_darboux_chart :
    Function.Injective darbouxChart ∧
      ∀ z ξ η : ℝ × ℝ,
        area2 (fderiv ℝ darbouxChart z ξ) (fderiv ℝ darbouxChart z η) = (1 + z.1 ^ 2) * area2 ξ η := by
  refine ⟨?_, ?_⟩
  · intro a b hab
    simp only [darbouxChart, Prod.mk.injEq] at hab
    exact Prod.ext (u_strictMono.injective hab.1) hab.2
  · intro z ξ η
    rw [darbouxChart_fderiv, darbouxChart_fderiv, area2, area2]
    ring

/-- Moser's field for the rain at path time `t`: `X_t = -x³ / (3 (1 + t x²)) ∂ₓ`. -/
def moserField (t x : ℝ) : ℝ := -(x ^ 3 / (3 * (1 + t * x ^ 2)))

/-- Moser's trick for the rain. The field solves Moser's equation `ι_X ω_t = -α` for
`ω_t = (1 + t x²) dx ∧ dy` and `α = (x³/3) dy` (its `dy` part reads `(1 + t x²) Xˣ = -x³/3`), and any
solution of `dx/dt = X_t(x)` on path times `0` to `1` lands at the point with `u(x(1)) = x(0)`:
the flow `φ₁` undoes the Darboux coordinate `u`. -/
theorem moser_flow_lands :
    (∀ t x : ℝ, 0 ≤ t → (1 + t * x ^ 2) * moserField t x = -(x ^ 3 / 3)) ∧
      ∀ x : ℝ → ℝ, (∀ t ∈ Set.Icc (0 : ℝ) 1, HasDerivAt x (moserField t (x t)) t) →
        u (x 1) = x 0 := by
  have hm : ∀ t x : ℝ, 0 ≤ t → (1 + t * x ^ 2) * moserField t x = -(x ^ 3 / 3) := by
    intro t x ht
    have hpos : 0 < 1 + t * x ^ 2 := by positivity
    unfold moserField
    field_simp
  refine ⟨hm, ?_⟩
  intro x hx
  let F : ℝ → ℝ := fun t => x t + t * x t ^ 3 / 3
  have hF : ∀ t ∈ Set.Icc (0 : ℝ) 1, HasDerivAt F 0 t := by
    intro t ht
    have h1 := hx t ht
    have h2 := h1.add (((hasDerivAt_id t).mul (h1.pow 3)).div_const 3)
    refine h2.congr_deriv ?_
    have := hm t (x t) ht.1
    simp only [id, Nat.cast_ofNat, Nat.reduceSub, Pi.pow_apply]
    linear_combination this
  have hc : ContinuousOn F (Set.Icc 0 1) := fun t ht => (hF t ht).continuousAt.continuousWithinAt
  have := constant_of_has_deriv_right_zero hc
    (fun t ht => (hF t (Set.Ico_subset_Icc_self ht)).hasDerivWithinAt) 1 (by simp)
  simp only [F] at this
  simp only [u]
  linarith

/-! ### The card's worked whole-number examples -/

/-- The magnetic form `dq₁∧dp₁ + dq₂∧dp₂ + b dq₁∧dq₂`, order `(q₁, q₂, p₁, p₂)`. -/
def magnetic (b : ℝ) : Matrix (Fin 4) (Fin 4) ℝ :=
  !![0, b, 1, 0; -b, 0, 0, 1; -1, 0, 0, 0; 0, -1, 0, 0]

/-- The Pfaffian of a 4 × 4 antisymmetric matrix, `a₁₂a₃₄ - a₁₃a₂₄ + a₁₄a₂₃`. -/
def pf (A : Matrix (Fin 4) (Fin 4) ℝ) : ℝ := A 0 1 * A 2 3 - A 0 2 * A 1 3 + A 0 3 * A 1 2

-- rain depth 2, 5 and 10 mm at 1, 2 and 3 km
example : ((1 : ℝ) + 1 ^ 2, (1 : ℝ) + 2 ^ 2, (1 : ℝ) + 3 ^ 2) = (2, 5, 10) := by norm_num
-- Darboux coordinate u(1) = 4/3, u(2) = 14/3; rain in the strip 1 to 2 km out is 10/3
example : u 1 = 4 / 3 ∧ u 2 = 14 / 3 := by norm_num [u]
example : u 2 - u 1 = 10 / 3 := by norm_num [u]
-- the pullback check (1 + 1²) × 1/2 = 1
example : ((1 : ℝ) + 1 ^ 2) * (1 / 2) = 1 := by norm_num
-- the magnetic form with b = 2 has Pfaffian -1, so it is nondegenerate
example : pf (magnetic 2) = -1 := by norm_num [pf, magnetic]
-- plane of q₁, q₂: ω = 0 (Lagrangian); plane of q₁, p₁: ω = 1 (not)
example : omegaStd ((![1, 0] : Fin 2 → ℝ), ![0, 0]) (![0, 1], ![0, 0]) = 0 := by
  norm_num [omegaStd, Fin.sum_univ_two]
example : omegaStd ((![1, 0] : Fin 2 → ℝ), ![0, 0]) (![0, 0], ![1, 0]) = 1 := by
  norm_num [omegaStd, Fin.sum_univ_two]
-- S = q₁² q₂: p = grad S = (2 q₁ q₂, q₁²) = (4, 1) at q = (1, 2)
example : ((2 : ℝ) * 1 * 2, (1 : ℝ) ^ 2) = (4, 1) := by norm_num
-- on that graph at q = (1, 2), the tangent arrows (1, 0, 4, 2) and (0, 1, 2, 0) give ω = 0
example : omegaStd ((![1, 0] : Fin 2 → ℝ), ![4, 2]) (![0, 1], ![2, 0]) = 0 := by
  norm_num [omegaStd, Fin.sum_univ_two]
-- β = q₁ dq₂, graph p = (0, q₁): tangent arrows (1, 0, 0, 1) and (0, 1, 0, 0) give ω = -1
example : omegaStd ((![1, 0] : Fin 2 → ℝ), ![0, 1]) (![0, 1], ![0, 0]) = -1 := by
  norm_num [omegaStd, Fin.sum_univ_two]

#print axioms oneForm_sum
#print axioms graphMap_fderiv
#print axioms extDeriv_two
#print axioms u_hasDerivAt
#print axioms u_strictMono
#print axioms darbouxChart_fderiv
#print axioms graph_lagrangian_iff_closed
#print axioms rain_darboux_chart
#print axioms moser_flow_lands
