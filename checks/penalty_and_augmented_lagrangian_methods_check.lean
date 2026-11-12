-- Penalties and augmented Lagrangians: for a positive definite quadratic cost with straight-line rules, one augmented-Lagrangian round multiplies the price error by (I + ρS)⁻¹ and so shrinks it by at least 1/(1 + ρσ) with the fine weight held fixed; a quadratic-penalty minimiser obeys the KKT equation with stand-in prices ρh and ρ·max(0, g); S is positive definite when the rules' gradients are independent; and the card's pump numbers check exactly.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Topology.Order.LocalExtr
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
import Mathlib.Algebra.Order.Star.Real
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.FDeriv.Pow
import Mathlib.Analysis.Asymptotics.Lemmas

open Matrix

/-! ### How the card's objects are written here

Plans are lists of `n` real numbers, `Fin n → ℝ`; price lists are `Fin m → ℝ`, one price per
active rule. `v ⬝ᵥ w` is the dot product, `A *ᵥ v` a matrix times a list, `Aᵀ` the transpose.

The proof setting of Step 4: the cost is `f x = ½ xᵀ H x + qᵀ x` with `H` (the card's `∇²f`)
positive definite; the active rules are `J x + e = 0`, with prices `y`. The true plan and prices
`(xs, ys)` satisfy KKT: `H xs + q + Jᵀ ys = 0` and `J xs + e = 0`. Round `k` minimises
`f x + ykᵀ (J x + e) + ρ/2 ‖J x + e‖²` exactly, giving `xk`, and corrects the prices to
`yk + ρ (J xk + e)`. `S = J H⁻¹ Jᵀ`, and `σ` is its smallest eigenvalue, written as the
Rayleigh bound `σ ‖v‖² ≤ vᵀ S v` for every `v` (the smallest eigenvalue is the largest such `σ`). -/

lemma dot_self_nonneg_real {k : ℕ} (v : Fin k → ℝ) : 0 ≤ v ⬝ᵥ v :=
  Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)

lemma dot_transpose_mulVec_real {n m : ℕ} (J : Matrix (Fin m) (Fin n) ℝ) (x : Fin n → ℝ)
    (v : Fin m → ℝ) : x ⬝ᵥ (Jᵀ *ᵥ v) = (J *ᵥ x) ⬝ᵥ v := by
  rw [dotProduct_mulVec, vecMul_transpose]

lemma grad_zero_of_quadratic_min {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : Aᵀ = A)
    (hpsd : ∀ d : Fin n → ℝ, 0 ≤ d ⬝ᵥ (A *ᵥ d)) (b xk : Fin n → ℝ)
    (h : ∀ x : Fin n → ℝ, 1 / 2 * (xk ⬝ᵥ (A *ᵥ xk)) + b ⬝ᵥ xk ≤ 1 / 2 * (x ⬝ᵥ (A *ᵥ x)) + b ⬝ᵥ x) :
    A *ᵥ xk + b = 0 := by
  set g := A *ᵥ xk + b with hgdef
  have hsym : xk ⬝ᵥ (A *ᵥ g) = g ⬝ᵥ (A *ᵥ xk) := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hA, dotProduct_comm]
  have hg : g ⬝ᵥ g = g ⬝ᵥ (A *ᵥ xk) + b ⬝ᵥ g := by
    conv_lhs => rw [hgdef]
    rw [dotProduct_add, dotProduct_comm g b]
  have key : ∀ t : ℝ, 0 ≤ t * (g ⬝ᵥ g) + t ^ 2 * (1 / 2 * (g ⬝ᵥ (A *ᵥ g))) := by
    intro t
    have := h (xk + t • g)
    simp only [mulVec_add, mulVec_smul, dotProduct_add, add_dotProduct, dotProduct_smul,
      smul_dotProduct, smul_eq_mul, hsym] at this
    rw [hg]
    linarith
  set a := g ⬝ᵥ g
  set c := 1 / 2 * (g ⬝ᵥ (A *ᵥ g))
  have hc : 0 ≤ c := by have := hpsd g; positivity
  set s := 1 / (c + 1)
  have hs : 0 < s := by positivity
  have h1 : s * c = 1 - s := by
    simp only [s]; field_simp; ring
  have e : (-a * s) * a + (-a * s) ^ 2 * c = -((a * s) ^ 2) := by
    linear_combination (a ^ 2 * s) * h1
  have k := key (-a * s)
  rw [e] at k
  have has : a * s = 0 := by nlinarith [sq_nonneg (a * s)]
  have ha : a = 0 := by
    rcases mul_eq_zero.1 has with h | h
    · exact h
    · exact absurd h hs.ne'
  exact dotProduct_self_eq_zero.1 ha

lemma sq_pos_part_bound (s t : ℝ) :
    ‖max 0 s ^ 2 - max 0 t ^ 2 - (s - t) * (2 * max 0 t)‖ ≤ ‖s - t‖ ^ 2 := by
  rw [Real.norm_eq_abs, Real.norm_eq_abs, sq_abs, abs_le]
  rcases le_total 0 s with hs | hs <;> rcases le_total 0 t with ht | ht <;>
    simp only [max_eq_right, max_eq_left, hs, ht] <;> constructor <;> nlinarith

lemma hasDerivAt_sq_pos_part (t : ℝ) :
    HasDerivAt (fun s : ℝ => max 0 s ^ 2) (2 * max 0 t) t := by
  rw [hasDerivAt_iff_isLittleO]
  refine Asymptotics.IsBigO.trans_isLittleO ?_ (Asymptotics.isLittleO_pow_sub_sub t one_lt_two)
  refine Asymptotics.IsBigO.of_bound 1 (Filter.Eventually.of_forall fun s => ?_)
  simp only [one_mul, norm_pow, norm_norm, smul_eq_mul]
  exact sq_pos_part_bound s t

#print axioms dot_self_nonneg_real
#print axioms dot_transpose_mulVec_real
#print axioms grad_zero_of_quadratic_min
#print axioms sq_pos_part_bound
#print axioms hasDerivAt_sq_pos_part

/-- Step 4, the card's main theorem: each round shrinks the price error by a fixed factor.
For a quadratic cost with positive definite curvature `H` and straight-line rules `J x + e = 0`
that have true prices `ys` at the answer `xs`, run one augmented-Lagrangian round with any fixed
fine weight `ρ > 0`: minimise the augmented Lagrangian exactly at the current prices `yk`, then
raise the prices by `ρ` times the breach left. Then
* the plan error obeys `(H + ρ JᵀJ)(xk - xs) = -Jᵀ(yk - ys)`;
* the new price error is exactly `(I + ρS)⁻¹` times the old one, with `S = J H⁻¹ Jᵀ`;
* so its length shrinks by at least the factor `1/(1 + ρσ)`, where `σ ≥ 0` bounds `S` below. -/
theorem augmented_lagrangian_round_shrinks_price_error {n m : ℕ}
    (H : Matrix (Fin n) (Fin n) ℝ) (hH : H.PosDef) (q : Fin n → ℝ)
    (J : Matrix (Fin m) (Fin n) ℝ) (e : Fin m → ℝ)
    (xs : Fin n → ℝ) (ys : Fin m → ℝ)
    (hkkt_stat : H *ᵥ xs + q + Jᵀ *ᵥ ys = 0) (hkkt_feas : J *ᵥ xs + e = 0)
    (ρ : ℝ) (hρ : 0 < ρ) (yk : Fin m → ℝ) (xk : Fin n → ℝ)
    (hround : ∀ x : Fin n → ℝ,
      1 / 2 * (xk ⬝ᵥ (H *ᵥ xk)) + q ⬝ᵥ xk + yk ⬝ᵥ (J *ᵥ xk + e)
          + ρ / 2 * ((J *ᵥ xk + e) ⬝ᵥ (J *ᵥ xk + e)) ≤
        1 / 2 * (x ⬝ᵥ (H *ᵥ x)) + q ⬝ᵥ x + yk ⬝ᵥ (J *ᵥ x + e)
          + ρ / 2 * ((J *ᵥ x + e) ⬝ᵥ (J *ᵥ x + e)))
    (σ : ℝ) (hσ0 : 0 ≤ σ) (hσ : ∀ v : Fin m → ℝ, σ * (v ⬝ᵥ v) ≤ v ⬝ᵥ ((J * H⁻¹ * Jᵀ) *ᵥ v)) :
    (H + ρ • (Jᵀ * J)) *ᵥ (xk - xs) = -(Jᵀ *ᵥ (yk - ys)) ∧
      (yk + ρ • (J *ᵥ xk + e)) - ys = (1 + ρ • (J * H⁻¹ * Jᵀ))⁻¹ *ᵥ (yk - ys) ∧
      ((yk + ρ • (J *ᵥ xk + e)) - ys) ⬝ᵥ ((yk + ρ • (J *ᵥ xk + e)) - ys) ≤
        (1 / (1 + ρ * σ)) ^ 2 * ((yk - ys) ⬝ᵥ (yk - ys)) := by
  -- symmetry of H
  have hHsym : Hᵀ = H := by
    have := hH.1
    rwa [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
  have hHpsd : ∀ d : Fin n → ℝ, 0 ≤ d ⬝ᵥ (H *ᵥ d) := by
    intro d; simpa using hH.posSemidef.dotProduct_mulVec_nonneg d
  -- the augmented Lagrangian as a quadratic
  set A := H + ρ • (Jᵀ * J) with hAdef
  set b := q + Jᵀ *ᵥ yk + ρ • (Jᵀ *ᵥ e) with hbdef
  have hAsym : Aᵀ = A := by
    simp [hAdef, transpose_add, transpose_smul, transpose_mul, hHsym]
  have hAx : ∀ x : Fin n → ℝ, x ⬝ᵥ (A *ᵥ x) = x ⬝ᵥ (H *ᵥ x) + ρ * ((J *ᵥ x) ⬝ᵥ (J *ᵥ x)) := by
    intro x
    rw [hAdef, add_mulVec, smul_mulVec, ← mulVec_mulVec, dotProduct_add, dotProduct_smul,
      dot_transpose_mulVec_real, smul_eq_mul]
  have hApsd : ∀ d : Fin n → ℝ, 0 ≤ d ⬝ᵥ (A *ᵥ d) := by
    intro d; rw [hAx]
    have := hHpsd d; have := dot_self_nonneg_real (J *ᵥ d); positivity
  have hrep : ∀ x : Fin n → ℝ,
      1 / 2 * (x ⬝ᵥ (H *ᵥ x)) + q ⬝ᵥ x + yk ⬝ᵥ (J *ᵥ x + e)
          + ρ / 2 * ((J *ᵥ x + e) ⬝ᵥ (J *ᵥ x + e)) =
        1 / 2 * (x ⬝ᵥ (A *ᵥ x)) + b ⬝ᵥ x + (yk ⬝ᵥ e + ρ / 2 * (e ⬝ᵥ e)) := by
    intro x
    rw [hAx, hbdef]
    simp only [dotProduct_add, add_dotProduct, smul_dotProduct, smul_eq_mul]
    rw [dotProduct_comm (Jᵀ *ᵥ yk) x, dotProduct_comm (Jᵀ *ᵥ e) x,
      dot_transpose_mulVec_real, dot_transpose_mulVec_real,
      dotProduct_comm (J *ᵥ x) yk, dotProduct_comm e (J *ᵥ x)]
    ring
  have hgrad : A *ᵥ xk + b = 0 := by
    apply grad_zero_of_quadratic_min A hAsym hApsd b xk
    intro x
    have := hround x
    rw [hrep, hrep] at this
    linarith
  -- componentwise facts
  have hgrad' : H *ᵥ xk + ρ • (Jᵀ *ᵥ (J *ᵥ xk)) + q + Jᵀ *ᵥ yk + ρ • (Jᵀ *ᵥ e) = 0 := by
    rw [← hgrad, hAdef, hbdef, add_mulVec, smul_mulVec, ← mulVec_mulVec]
    abel
  have hfeasT : Jᵀ *ᵥ (J *ᵥ xs) = -(Jᵀ *ᵥ e) := by
    rw [← mulVec_neg, eq_neg_of_add_eq_zero_left hkkt_feas]
  -- conjunct 1
  have c1 : (H + ρ • (Jᵀ * J)) *ᵥ (xk - xs) = -(Jᵀ *ᵥ (yk - ys)) := by
    rw [add_mulVec, smul_mulVec, ← mulVec_mulVec, mulVec_sub, mulVec_sub, mulVec_sub, mulVec_sub,
      hfeasT]
    ext i
    have h1 := congrFun hgrad' i
    have h2 := congrFun hkkt_stat i
    simp only [Pi.add_apply, Pi.sub_apply, Pi.neg_apply, Pi.smul_apply, smul_eq_mul,
      Pi.zero_apply] at h1 h2 ⊢
    linarith
  refine ⟨c1, ?_⟩
  -- notation
  set S := J * H⁻¹ * Jᵀ with hSdef
  set u := yk - ys with hudef
  set δ := xk - xs with hδdef
  set w := (yk + ρ • (J *ᵥ xk + e)) - ys with hwdef
  have hdetH : IsUnit H.det := (isUnit_iff_isUnit_det H).1 hH.isUnit
  have hw : w = u + ρ • (J *ᵥ δ) := by
    rw [hwdef, hudef, hδdef, mulVec_sub]
    ext i
    have h1 := congrFun hkkt_feas i
    simp only [Pi.add_apply, Pi.sub_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply] at h1 ⊢
    linear_combination ρ * h1
  have hHδ : H *ᵥ δ = -(Jᵀ *ᵥ w) := by
    have := c1
    rw [add_mulVec, smul_mulVec, ← mulVec_mulVec] at this
    rw [hw, mulVec_add, mulVec_smul]
    ext i
    have h1 := congrFun this i
    simp only [Pi.add_apply, Pi.neg_apply, Pi.smul_apply, smul_eq_mul] at h1 ⊢
    linarith
  have hinv : H⁻¹ *ᵥ (Jᵀ *ᵥ w) = -δ := by
    have : H⁻¹ *ᵥ (H *ᵥ δ) = δ := by
      rw [mulVec_mulVec, nonsing_inv_mul _ hdetH, one_mulVec]
    rw [hHδ, mulVec_neg] at this
    rw [← this, neg_neg]
  have hSw : S *ᵥ w = -(J *ᵥ δ) := by
    rw [hSdef, ← mulVec_mulVec, ← mulVec_mulVec, hinv, mulVec_neg]
  have hMw : (1 + ρ • S) *ᵥ w = u := by
    rw [add_mulVec, one_mulVec, smul_mulVec, hSw, hw]
    ext i
    simp only [Pi.add_apply, Pi.neg_apply, Pi.smul_apply, smul_eq_mul]
    ring
  -- 1 + ρS is invertible
  have hSpsd : S.PosSemidef := by
    have := hH.posSemidef.inv.mul_mul_conjTranspose_same J
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  have hMpd : (1 + ρ • S).PosDef := PosDef.one.add_posSemidef (hSpsd.smul hρ.le)
  have hdetM : IsUnit (1 + ρ • S).det := (isUnit_iff_isUnit_det _).1 hMpd.isUnit
  have c2 : w = (1 + ρ • S)⁻¹ *ᵥ u := by
    rw [← hMw, mulVec_mulVec, nonsing_inv_mul _ hdetM, one_mulVec]
  refine ⟨c2, ?_⟩
  -- conjunct 3
  have hwu : w ⬝ᵥ u = w ⬝ᵥ w + ρ * (w ⬝ᵥ (S *ᵥ w)) := by
    rw [← hMw, add_mulVec, one_mulVec, smul_mulVec, dotProduct_add, dotProduct_smul, smul_eq_mul]
  have hσw := hσ w
  set c := 1 + ρ * σ with hcdef
  have hc : 0 < c := by positivity
  have hww := dot_self_nonneg_real w
  have hcw : c * (w ⬝ᵥ w) ≤ w ⬝ᵥ u := by
    rw [hwu, hcdef]; nlinarith
  have hexp : (c • w - u) ⬝ᵥ (c • w - u) = c ^ 2 * (w ⬝ᵥ w) - 2 * c * (w ⬝ᵥ u) + u ⬝ᵥ u := by
    simp only [sub_dotProduct, dotProduct_sub, smul_dotProduct, dotProduct_smul, smul_eq_mul,
      dotProduct_comm u w]
    ring
  have hnn := dot_self_nonneg_real (c • w - u)
  rw [hexp] at hnn
  have hfin : c ^ 2 * (w ⬝ᵥ w) ≤ u ⬝ᵥ u := by nlinarith
  rw [one_div, inv_pow, inv_mul_eq_div, le_div_iff₀ (by positivity)]
  linarith

/-- Step 1: a penalty minimiser is a KKT point with stand-in prices. Let the cost `f`, the
shortfall `h` (must be 0) and the overpressure `g` (must be at most 0) be differentiable at
`xρ`, and let `xρ` minimise the quadratic penalty `f + ρ/2 (h² + max(0, g)²)` near itself, with
`ρ > 0`. Then `xρ` obeys the KKT stationarity equation `∇f + ν ∇h + λ ∇g = 0` with the stand-in
prices `ν = ρ h(xρ)` and `λ = ρ max(0, g(xρ))`, which is `ρ g(xρ)` while the cap is breached,
and the ceiling's stand-in price is never negative. -/
theorem penalty_minimiser_is_kkt_point_with_stand_in_prices {n : ℕ}
    (f h g : (Fin n → ℝ) → ℝ) (ρ : ℝ) (hρ : 0 < ρ) (xρ : Fin n → ℝ)
    (hf : DifferentiableAt ℝ f xρ) (hh : DifferentiableAt ℝ h xρ) (hg : DifferentiableAt ℝ g xρ)
    (hmin : IsLocalMin (fun x => f x + ρ / 2 * (h x ^ 2 + max 0 (g x) ^ 2)) xρ) :
    fderiv ℝ f xρ + (ρ * h xρ) • fderiv ℝ h xρ + (ρ * max 0 (g xρ)) • fderiv ℝ g xρ = 0 ∧
      0 ≤ ρ * max 0 (g xρ) := by
  refine ⟨?_, mul_nonneg hρ.le (le_max_left _ _)⟩
  have h2 := hh.hasFDerivAt.pow 2
  have g2 := (hasDerivAt_sq_pos_part (g xρ)).comp_hasFDerivAt xρ hg.hasFDerivAt
  have F := hf.hasFDerivAt.add ((h2.add g2).const_mul (ρ / 2))
  have := hmin.hasFDerivAt_eq_zero F
  rw [← this]
  ext v
  simp
  ring

/-- From the proof of Step 4: when the rules' gradients (the rows of `J`) are independent, which
is LICQ, the matrix `S = J H⁻¹ Jᵀ` is symmetric and positive definite for any positive definite
`H`, so its smallest eigenvalue `σ` is positive and the shrink factor `1/(1 + ρσ)` is below 1. -/
theorem schur_matrix_pos_def_of_independent_rules {n m : ℕ}
    (H : Matrix (Fin n) (Fin n) ℝ) (hH : H.PosDef) (J : Matrix (Fin m) (Fin n) ℝ)
    (hLICQ : LinearIndependent ℝ (fun i => J i)) :
    (J * H⁻¹ * Jᵀ).PosDef := by
  have hB : Function.Injective J.vecMul := Matrix.vecMul_injective_iff.2 hLICQ
  have := hH.inv.mul_mul_conjTranspose_same hB
  rwa [conjTranspose_eq_transpose_of_trivial] at this

/-! ### The card's pump numbers, checked exactly

Costs per pump `0.02 = 1/50`, `0.03 = 3/100`, `0.05 = 1/20` kW per (L/s)²; the gradient of the
shortfall is `(-1, -1, -1)` and of the overpressure `(1/2, 0, 0)`. -/

/-- Without the cap: flows in proportion to `1/0.02 : 1/0.03 : 1/0.05` meet demand, draw
`6750/31 ≈ 217.7419` kW, and put `1125/31 ≈ 36.2903` m on the low district, `350/31 ≈ 11.2903`
m over its 25 m rating. -/
example :
    (2250 : ℚ) / 31 + 1500 / 31 + 900 / 31 = 150 ∧
      2 * (1 / 50) * (2250 / 31 : ℚ) = 2 * (3 / 100) * (1500 / 31) ∧
      2 * (3 / 100) * (1500 / 31 : ℚ) = 2 * (1 / 20) * (900 / 31) ∧
      1 / 50 * (2250 / 31 : ℚ) ^ 2 + 3 / 100 * (1500 / 31) ^ 2 + 1 / 20 * (900 / 31) ^ 2 = 6750 / 31 ∧
      1 / 2 * (2250 / 31 : ℚ) = 1125 / 31 ∧ (1125 : ℚ) / 31 - 25 = 350 / 31 := by
  norm_num

/-- The answer `x* = (50, 62.5, 37.5)` with prices `ν* = 3.75`, `λ* = 3.5` has zero KKT residuals:
stationarity in each flow, no shortfall, cap exactly met, and `λ* > 0`. -/
example :
    2 * (1 / 50) * (50 : ℚ) + (15 / 4) * (-1) + (7 / 2) * (1 / 2) = 0 ∧
      2 * (3 / 100) * (125 / 2 : ℚ) + (15 / 4) * (-1) = 0 ∧
      2 * (1 / 20) * (75 / 2 : ℚ) + (15 / 4) * (-1) = 0 ∧
      (150 : ℚ) - 50 - 125 / 2 - 75 / 2 = 0 ∧ (1 / 2 : ℚ) * 50 - 25 = 0 ∧ (0 : ℚ) < 7 / 2 := by
  norm_num

/-- The power at the answer: pump powers 50, 117.1875 and 70.3125 kW, total 237.5 kW, £47.50 an
hour at £0.20 per kWh; the cap costs `237.5 - 6750/31 = 1225/62 ≈ 19.7581` kW. -/
example :
    1 / 50 * (50 : ℚ) ^ 2 = 50 ∧ 3 / 100 * (125 / 2 : ℚ) ^ 2 = 1875 / 16 ∧
      1 / 20 * (75 / 2 : ℚ) ^ 2 = 1125 / 16 ∧
      (50 : ℚ) + 1875 / 16 + 1125 / 16 = 475 / 2 ∧ (1 / 5 : ℚ) * (475 / 2) = 95 / 2 ∧
      (475 : ℚ) / 2 - 6750 / 31 = 1225 / 62 ∧
      (1 / 5 : ℚ) * (15 / 4) = 3 / 4 ∧ (1 / 5 : ℚ) * (7 / 2) = 7 / 10 := by
  norm_num

/-- Step 4's matrix for the pumps: with `∇²f = diag(0.04, 0.06, 0.10)`, whose inverse is
`diag(25, 50/3, 10)`, and `J = [[-1, -1, -1], [1/2, 0, 0]]`,
`S = J (∇²f)⁻¹ Jᵀ = [[155/3, -25/2], [-25/2, 25/4]] ≈ [[51.6667, -12.5], [-12.5, 6.25]]`. -/
example :
    (!![1 / 25, 0, 0; 0, 3 / 50, 0; 0, 0, 1 / 10] : Matrix (Fin 3) (Fin 3) ℚ) *
        (!![25, 0, 0; 0, 50 / 3, 0; 0, 0, 10] : Matrix (Fin 3) (Fin 3) ℚ) = 1 ∧
      (!![-1, -1, -1; 1 / 2, 0, 0] : Matrix (Fin 2) (Fin 3) ℚ) *
          (!![25, 0, 0; 0, 50 / 3, 0; 0, 0, 10] : Matrix (Fin 3) (Fin 3) ℚ) *
          (!![-1, -1, -1; 1 / 2, 0, 0] : Matrix (Fin 2) (Fin 3) ℚ)ᵀ =
        (!![155 / 3, -25 / 2; -25 / 2, 25 / 4] : Matrix (Fin 2) (Fin 2) ℚ) := by
  constructor
  · ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_succ]
  · ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_succ] <;> norm_num

/-- What breaks: drop the clamp with a slack 40 m cap. The cap is treated as a target: pump A is
pulled to 80 L/s (40 m of head), B and C share the other 70 L/s as 43.75 and 26.25, the cap's
price comes out at `λ = -1.15 < 0`, and the power is `219.875` kW against `6750/31 ≈ 217.7419`. -/
example :
    (80 : ℚ) + 175 / 4 + 105 / 4 = 150 ∧ (1 / 2 : ℚ) * 80 = 40 ∧
      2 * (3 / 100) * (175 / 4 : ℚ) = 21 / 8 ∧ 2 * (1 / 20) * (105 / 4 : ℚ) = 21 / 8 ∧
      2 * (1 / 50) * (80 : ℚ) - 21 / 8 + (-23 / 20) * (1 / 2) = 0 ∧ (-23 / 20 : ℚ) < 0 ∧
      1 / 50 * (80 : ℚ) ^ 2 + 3 / 100 * (175 / 4) ^ 2 + 1 / 20 * (105 / 4) ^ 2 = 1759 / 8 ∧
      (6750 : ℚ) / 31 < 1759 / 8 := by
  norm_num

#print axioms augmented_lagrangian_round_shrinks_price_error
#print axioms penalty_minimiser_is_kkt_point_with_stand_in_prices
#print axioms schur_matrix_pos_def_of_independent_rules
