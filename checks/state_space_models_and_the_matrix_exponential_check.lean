-- State space: for constant matrices A and B and a continuous input u, every solution of x' = Ax + Bu satisfies x(t) = e^(At)x(0) + ∫₀ᵗ e^(A(t−τ)) B u(τ) dτ; for the cart and rod, e^(At) is the cosh and sinh matrix and the push-to-tilt transfer function is (−1/l)/(s² − g/l).
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.Matrix.Normed
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic

open Matrix

/-! The state `x t` is a vector in `Fin n → ℝ`, the input `u t` a vector in `Fin m → ℝ`.
The rate matrix `A` (n × n) and the input matrix `B` (n × m) are constant real matrices,
and `M *ᵥ v` is the matrix `M` applied to the vector `v`. The matrix `e^(At)` is Mathlib's
matrix exponential `NormedSpace.exp (t • A)`, the series `I + At + (At)²/2! + ⋯`.
The rule of motion `x' = Ax + Bu` is `∀ t, HasDerivAt x (A *ᵥ x t + B *ᵥ u t) t`. The input
is taken continuous, so the integral of past inputs is an ordinary integral. -/

set_option backward.isDefEq.respectTransparency false in
theorem exp_smul_entry_hasDerivAt {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (r : ℝ) (i j : Fin n) :
    HasDerivAt (fun r : ℝ => NormedSpace.exp (r • A) i j)
      ((NormedSpace.exp (r • A) * A) i j) r := by
  open scoped Matrix.Norms.Operator in
  have h := hasDerivAt_exp_smul_const (𝕂 := ℝ) A r
  open scoped Matrix.Norms.Operator in
  let L : Matrix (Fin n) (Fin n) ℝ →L[ℝ] ℝ :=
    LinearMap.toContinuousLinearMap (Matrix.entryLinearMap ℝ ℝ i j)
  open scoped Matrix.Norms.Operator in
  exact L.hasFDerivAt.comp_hasDerivAt r h


theorem exp_smul_continuous {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) :
    Continuous (fun r : ℝ => NormedSpace.exp (r • A)) :=
  continuous_pi fun i => continuous_pi fun j =>
    continuous_iff_continuousAt.2 fun r => (exp_smul_entry_hasDerivAt A r i j).continuousAt

theorem variation_of_constants {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (f : ℝ → Fin n → ℝ)
    (hf : Continuous f) (x : ℝ → Fin n → ℝ)
    (hx : ∀ s, HasDerivAt x (A *ᵥ x s + f s) s) (t : ℝ) :
    x t = NormedSpace.exp (t • A) *ᵥ x 0 +
      ∫ τ in (0 : ℝ)..t, NormedSpace.exp ((t - τ) • A) *ᵥ f τ := by
  have hz : ∀ s, HasDerivAt (fun s => NormedSpace.exp ((t - s) • A) *ᵥ x s)
      (NormedSpace.exp ((t - s) • A) *ᵥ f s) s := by
    intro s
    rw [hasDerivAt_pi]
    intro i
    have hE : ∀ j, HasDerivAt (fun s => NormedSpace.exp ((t - s) • A) i j)
        ((NormedSpace.exp ((t - s) • A) * A) i j * (-1)) s := fun j =>
      (exp_smul_entry_hasDerivAt A (t - s) i j).comp s ((hasDerivAt_id s).const_sub t)
    have hX : ∀ j, HasDerivAt (fun s => x s j) ((A *ᵥ x s + f s) j) s := fun j =>
      (hasDerivAt_pi.1 (hx s)) j
    have hsum : HasDerivAt (fun s => ∑ j, NormedSpace.exp ((t - s) • A) i j * x s j)
        (∑ j, ((NormedSpace.exp ((t - s) • A) * A) i j * (-1) * x s j +
          NormedSpace.exp ((t - s) • A) i j * (A *ᵥ x s + f s) j)) s :=
      HasDerivAt.fun_sum (u := Finset.univ) (fun j _ => (hE j).mul (hX j))
    refine hsum.congr_deriv ?_
    have key : -((NormedSpace.exp ((t - s) • A) * A) *ᵥ x s) +
        NormedSpace.exp ((t - s) • A) *ᵥ (A *ᵥ x s + f s) =
        NormedSpace.exp ((t - s) • A) *ᵥ f s := by
      rw [mulVec_add, ← mulVec_mulVec]; abel
    rw [← key]
    simp only [Pi.add_apply, Pi.neg_apply, mulVec, dotProduct, ← Finset.sum_neg_distrib,
      ← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun j _ => by ring
  have hcont : Continuous (fun s => NormedSpace.exp ((t - s) • A) *ᵥ f s) :=
    Continuous.matrix_mulVec ((exp_smul_continuous A).comp (continuous_const.sub continuous_id)) hf
  have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt (a := 0) (b := t)
    (fun s _ => hz s) (hcont.intervalIntegrable _ _)
  rw [hftc]
  simp [NormedSpace.exp_zero]


theorem cart_rod_exp_of_rate (w t : ℝ) (hw : w ≠ 0) :
    NormedSpace.exp (t • !![0, 1, 0, 0;
                             0, 0, 0, 0;
                             0, 0, 0, 1;
                             0, 0, w * w, 0]) =
      !![1, t, 0, 0;
         0, 1, 0, 0;
         0, 0, Real.cosh (w * t), Real.sinh (w * t) / w;
         0, 0, w * Real.sinh (w * t), Real.cosh (w * t)] := by
  set A : Matrix (Fin 4) (Fin 4) ℝ := !![0, 1, 0, 0; 0, 0, 0, 0; 0, 0, 0, 1; 0, 0, w * w, 0] with hA
  set G : ℝ → Matrix (Fin 4) (Fin 4) ℝ := fun s => !![1, s, 0, 0;
         0, 1, 0, 0;
         0, 0, Real.cosh (w * s), Real.sinh (w * s) / w;
         0, 0, w * Real.sinh (w * s), Real.cosh (w * s)] with hG
  show NormedSpace.exp (t • A) = G t
  have hc : ∀ s, HasDerivAt (fun s => Real.cosh (w * s)) (Real.sinh (w * s) * w) s := fun s => by
    simpa using ((hasDerivAt_id s).const_mul w).cosh
  have hs : ∀ s, HasDerivAt (fun s => Real.sinh (w * s)) (Real.cosh (w * s) * w) s := fun s => by
    simpa using ((hasDerivAt_id s).const_mul w).sinh
  ext i j
  have hcol := variation_of_constants A (fun _ => 0) continuous_const (fun s k => G s k j) (by
    intro s
    rw [hasDerivAt_pi]
    intro k
    fin_cases j <;> fin_cases k <;> simp [hG, hA, mulVec, dotProduct]
    · exact hasDerivAt_const s 1
    · exact hasDerivAt_const s 0
    · exact hasDerivAt_const s 0
    · exact hasDerivAt_const s 0
    · exact hasDerivAt_id s
    · exact hasDerivAt_const s 1
    · exact hasDerivAt_const s 0
    · exact hasDerivAt_const s 0
    · exact hasDerivAt_const s 0
    · exact hasDerivAt_const s 0
    · exact (hc s).congr_deriv (by ring)
    · exact ((hs s).const_mul w).congr_deriv (by ring)
    · exact hasDerivAt_const s 0
    · exact hasDerivAt_const s 0
    · exact ((hs s).div_const w).congr_deriv (by field_simp)
    · exact (hc s).congr_deriv (by field_simp)) t
  simp only [mulVec_zero, intervalIntegral.integral_zero, add_zero] at hcol
  rw [show G t i j = (fun k => G t k j) i from rfl, hcol]
  fin_cases i <;> fin_cases j <;> simp [hG, mulVec, dotProduct, Fin.sum_univ_four]

#print axioms exp_smul_entry_hasDerivAt
#print axioms exp_smul_continuous
#print axioms variation_of_constants
#print axioms cart_rod_exp_of_rate

/-- **The state is the start carried forward plus every past input carried forward.** Let the
rate matrix `A` and the input matrix `B` be fixed (they do not change with time), and let the
input `u` be continuous. If the state `x` obeys `x' = Ax + Bu`, then at every time `t` the
state is `x(t) = e^(At) x(0) + ∫₀ᵗ e^(A(t−τ)) B u(τ) dτ`. -/
theorem state_is_start_carried_forward_plus_past_inputs
    {n m : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (B : Matrix (Fin n) (Fin m) ℝ)
    (u : ℝ → Fin m → ℝ) (hu : Continuous u) (x : ℝ → Fin n → ℝ)
    (hx : ∀ t, HasDerivAt x (A *ᵥ x t + B *ᵥ u t) t) :
    ∀ t, x t = NormedSpace.exp (t • A) *ᵥ x 0 +
      ∫ τ in (0 : ℝ)..t, NormedSpace.exp ((t - τ) • A) *ᵥ (B *ᵥ u τ) := by
  intro t
  exact variation_of_constants A (fun τ => B *ᵥ u τ)
    (Continuous.matrix_mulVec continuous_const hu) x hx t

/-- **The cart and rod's `e^(At)` in closed form** (Step 2). With gravity `g > 0`, rod length
`l > 0`, state `(p, v, θ, ω)` and `A` the card's rate matrix, write `w = √(g/l)` for the rod's
growth rate. The cart's block carries forward as `[[1, t], [0, 1]]` and the rod's block as
`[[cosh wt, (1/w) sinh wt], [w sinh wt, cosh wt]]`. -/
theorem cart_and_rod_matrix_exponential (g l t : ℝ) (hg : 0 < g) (hl : 0 < l) :
    NormedSpace.exp (t • !![0, 1, 0, 0;
                             0, 0, 0, 0;
                             0, 0, 0, 1;
                             0, 0, g / l, 0]) =
      !![1, t, 0, 0;
         0, 1, 0, 0;
         0, 0, Real.cosh (Real.sqrt (g / l) * t), Real.sinh (Real.sqrt (g / l) * t) / Real.sqrt (g / l);
         0, 0, Real.sqrt (g / l) * Real.sinh (Real.sqrt (g / l) * t), Real.cosh (Real.sqrt (g / l) * t)] := by
  have hw : Real.sqrt (g / l) ≠ 0 := (Real.sqrt_pos.2 (div_pos hg hl)).ne'
  have h := cart_rod_exp_of_rate (Real.sqrt (g / l)) t hw
  rwa [Real.mul_self_sqrt (div_pos hg hl).le] at h

/-- **The transfer function falls out** (Step 5). For the cart and rod, with `g > 0`, `l > 0`,
`B = (0, 1, 0, −1/l)`, `C = (0, 0, 1, 0)` and `D = 0`, at any rate `s` where `sI − A` is
invertible (`s ≠ 0` and `s² ≠ g/l`), `G(s) = C (sI − A)⁻¹ B + D = (−1/l)/(s² − g/l)`. -/
theorem cart_and_rod_transfer_function (g l s : ℝ) (hg : 0 < g) (hl : 0 < l)
    (hs0 : s ≠ 0) (hs : s ^ 2 ≠ g / l) :
    (![0, 0, 1, 0] : Fin 4 → ℝ) ⬝ᵥ
        ((s • (1 : Matrix (Fin 4) (Fin 4) ℝ) - !![0, 1, 0, 0;
                                                  0, 0, 0, 0;
                                                  0, 0, 0, 1;
                                                  0, 0, g / l, 0])⁻¹ *ᵥ ![0, 1, 0, -1 / l]) + 0 =
      (-1 / l) / (s ^ 2 - g / l) := by
  set k := g / l with hkdef
  have hk : s ^ 2 - k ≠ 0 := sub_ne_zero.2 hs
  have hl0 : l ≠ 0 := hl.ne'
  have hinv : (s • (1 : Matrix (Fin 4) (Fin 4) ℝ) - !![0, 1, 0, 0;
                                                  0, 0, 0, 0;
                                                  0, 0, 0, 1;
                                                  0, 0, k, 0])⁻¹ =
      !![1 / s, 1 / s ^ 2, 0, 0;
         0, 1 / s, 0, 0;
         0, 0, s / (s ^ 2 - k), 1 / (s ^ 2 - k);
         0, 0, k / (s ^ 2 - k), s / (s ^ 2 - k)] := by
    apply Matrix.inv_eq_left_inv
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [Matrix.mul_apply, Fin.sum_univ_four, Matrix.one_apply] <;> field_simp <;> ring
  rw [hinv]
  simp [mulVec, dotProduct, Fin.sum_univ_four]
  field_simp

/-! The card's exact checks. -/

-- g/l = 9.81 / 0.613125 = 16 per s², exactly.
example : ((981 / 100 : ℚ)) / (613125 / 1000000) = 16 := by norm_num
-- The rod's growth rate: √16 = 4 per s.
example : Real.sqrt 16 = 4 := by
  rw [show (16 : ℝ) = 4 ^ 2 by norm_num]; exact Real.sqrt_sq (by norm_num)
-- The cart's block squares to zero, so its series stops after two terms.
example : (!![0, 1; 0, 0] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 1; 0, 0] = 0 := by decide
-- The rod's block squares to g/l = 16 times the identity.
example : (!![0, 1; 16, 0] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 1; 16, 0] = 16 • 1 := by decide
-- The steady push that only holds the lean: 0.05 g = 0.05 × 9.81 = 0.4905 m/s².
example : (5 / 100 : ℚ) * (981 / 100) = 4905 / 10000 := by norm_num
-- Per 1 m/s² of push over 0.5 s the cart moves 0.5²/2 = 0.125 m and gains 0.5 m/s.
example : (1 : ℚ) * (1 / 2) ^ 2 / 2 = 1 / 8 ∧ (1 : ℚ) * (1 / 2) = 1 / 2 := by norm_num

#print axioms state_is_start_carried_forward_plus_past_inputs
#print axioms cart_and_rod_matrix_exponential
#print axioms cart_and_rod_transfer_function
