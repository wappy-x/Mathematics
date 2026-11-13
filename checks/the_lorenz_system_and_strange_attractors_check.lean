-- The Lorenz system: every path is eventually trapped in one fixed ball, the flow's divergence is the constant -(σ + 1 + β), and the resting points are the origin and the two lobe centres.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Fin.VecNotation
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Mul

/-- The Lorenz rate laws on a point `p = (x, y, z)`:
`x' = σ (y - x)`, `y' = x (ρ - z) - y`, `z' = x y - β z`. -/
def lorenzField (σ ρ β : ℝ) (p : Fin 3 → ℝ) : Fin 3 → ℝ :=
  ![σ * (p 1 - p 0), p 0 * (ρ - p 2) - p 1, p 0 * p 1 - β * p 2]

/-- Every path is trapped: for positive `σ` and `β` (and any heating `ρ`) there is one fixed
ball such that every path of the Lorenz system enters it in finite time and stays inside
from then on. -/
theorem lorenz_paths_eventually_trapped (σ ρ β : ℝ) (hσ : 0 < σ) (hβ : 0 < β) :
    ∃ R : ℝ, ∀ γ : ℝ → (Fin 3 → ℝ),
      (∀ t : ℝ, 0 ≤ t → HasDerivAt γ (lorenzField σ ρ β (γ t)) t) →
      ∃ T : ℝ, ∀ t : ℝ, T ≤ t → ‖γ t‖ ≤ R := by
  set s := σ + ρ with hs
  set c := min (min (2 * σ) 2) β with hc
  have hc0 : 0 < c := lt_min (lt_min (by linarith) (by norm_num)) hβ
  have hc1 : c ≤ 2 * σ := le_trans (min_le_left _ _) (min_le_left _ _)
  have hc2 : c ≤ 2 := le_trans (min_le_left _ _) (min_le_right _ _)
  have hc3 : c ≤ β := min_le_right _ _
  set K := β * s ^ 2 with hK
  set B := K / c + 1 with hB
  have hB0 : 0 ≤ B := by positivity
  refine ⟨|s| + Real.sqrt B, ?_⟩
  intro γ hγ
  set V : ℝ → ℝ := fun t => (γ t 0) ^ 2 + (γ t 1) ^ 2 + (γ t 2 - s) ^ 2 with hV
  set W : ℝ → ℝ := fun t => Real.exp (c * t) * (V t - K / c) with hW
  -- derivative of V
  have hVd : ∀ t, 0 ≤ t → HasDerivAt V
      (2 * γ t 0 * (σ * (γ t 1 - γ t 0)) + 2 * γ t 1 * (γ t 0 * (ρ - γ t 2) - γ t 1)
        + 2 * (γ t 2 - s) * (γ t 0 * γ t 1 - β * γ t 2)) t := by
    intro t ht
    have h := hasDerivAt_pi.mp (hγ t ht)
    have h0 := h 0
    have h1 := h 1
    have h2 := h 2
    simp only [lorenzField, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two,
      Matrix.head_cons, Matrix.tail_cons] at h0 h1 h2
    have := ((h0.pow 2).add (h1.pow 2)).add ((h2.sub_const s).pow 2)
    convert this using 1
    simp
  have hWd : ∀ t, 0 ≤ t → HasDerivAt W
      (Real.exp (c * t) * (c * (V t - K / c) +
        (2 * γ t 0 * (σ * (γ t 1 - γ t 0)) + 2 * γ t 1 * (γ t 0 * (ρ - γ t 2) - γ t 1)
        + 2 * (γ t 2 - s) * (γ t 0 * γ t 1 - β * γ t 2)))) t := by
    intro t ht
    have he : HasDerivAt (fun t => Real.exp (c * t)) (Real.exp (c * t) * c) t := by
      have := ((hasDerivAt_id t).const_mul c).exp
      simpa using this
    have := he.mul ((hVd t ht).sub_const (K / c))
    convert this using 1
    ring
  have hWn : ∀ t, 0 ≤ t →
      Real.exp (c * t) * (c * (V t - K / c) +
        (2 * γ t 0 * (σ * (γ t 1 - γ t 0)) + 2 * γ t 1 * (γ t 0 * (ρ - γ t 2) - γ t 1)
        + 2 * (γ t 2 - s) * (γ t 0 * γ t 1 - β * γ t 2))) ≤ 0 := by
    intro t ht
    apply mul_nonpos_of_nonneg_of_nonpos (Real.exp_pos _).le
    have hcK : c * (K / c) = K := by field_simp
    have e : c * (V t - K / c) = c * V t - K := by rw [mul_sub, hcK]
    rw [e]
    simp only [hV]
    set x := γ t 0
    set y := γ t 1
    set z := γ t 2
    have hx : (c - 2 * σ) * x ^ 2 ≤ 0 :=
      mul_nonpos_of_nonpos_of_nonneg (by linarith) (sq_nonneg _)
    have hy : (c - 2) * y ^ 2 ≤ 0 :=
      mul_nonpos_of_nonpos_of_nonneg (by linarith) (sq_nonneg _)
    have hz : (c - β) * (z - s) ^ 2 ≤ 0 :=
      mul_nonpos_of_nonpos_of_nonneg (by linarith) (sq_nonneg _)
    have hz2 : 0 ≤ β * z ^ 2 := by positivity
    rw [hK]
    rw [hs] at hz ⊢
    nlinarith
  have hanti : AntitoneOn W (Set.Ici 0) := by
    apply antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ici 0)
    · intro t ht
      exact (hWd t ht).continuousAt.continuousWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      exact (hWd t (le_of_lt ht)).hasDerivWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      exact hWn t (le_of_lt ht)
  refine ⟨max 0 (Real.log (|W 0| + 1) / c), ?_⟩
  intro t ht
  have ht0 : 0 ≤ t := le_trans (le_max_left _ _) ht
  have htl : Real.log (|W 0| + 1) / c ≤ t := le_trans (le_max_right _ _) ht
  have hWt : W t ≤ W 0 := hanti (Set.mem_Ici.mpr le_rfl) (Set.mem_Ici.mpr ht0) ht0
  have hexp : |W 0| + 1 ≤ Real.exp (c * t) := by
    have h1 : Real.log (|W 0| + 1) ≤ c * t := by
      rw [div_le_iff₀ hc0] at htl; linarith
    have h2 := Real.exp_le_exp.mpr h1
    rwa [Real.exp_log (by positivity)] at h2
  have hVt : V t ≤ B := by
    have h3 : Real.exp (c * t) * (V t - K / c) ≤ Real.exp (c * t) * 1 := by
      have : W 0 ≤ |W 0| := le_abs_self _
      simp only [hW] at hWt
      linarith
    have h4 := le_of_mul_le_mul_left h3 (Real.exp_pos _)
    rw [hB]; linarith
  have hx2 : (γ t 0) ^ 2 ≤ B := by
    simp only [hV] at hVt; nlinarith [sq_nonneg (γ t 1), sq_nonneg (γ t 2 - s)]
  have hy2 : (γ t 1) ^ 2 ≤ B := by
    simp only [hV] at hVt; nlinarith [sq_nonneg (γ t 0), sq_nonneg (γ t 2 - s)]
  have hz2 : (γ t 2 - s) ^ 2 ≤ B := by
    simp only [hV] at hVt; nlinarith [sq_nonneg (γ t 1), sq_nonneg (γ t 0)]
  have hsq : 0 ≤ Real.sqrt B := Real.sqrt_nonneg _
  rw [pi_norm_le_iff_of_nonneg (by positivity)]
  intro i
  rw [Real.norm_eq_abs]
  fin_cases i
  · have := Real.abs_le_sqrt hx2
    simp only [Fin.zero_eta]
    linarith [abs_nonneg s]
  · have := Real.abs_le_sqrt hy2
    simp only [Fin.mk_one]
    linarith [abs_nonneg s]
  · have := Real.abs_le_sqrt hz2
    have h5 : |γ t 2| ≤ |γ t 2 - s| + |s| := by
      have := abs_add_le (γ t 2 - s) s
      simpa using this
    show |γ t 2| ≤ |s| + Real.sqrt B
    linarith

/-- The divergence of the Lorenz flow (the trace of its Jacobian) is `-(σ + 1 + β)` at every
point, so the flow shrinks every volume at the same constant rate. -/
theorem lorenz_divergence_constant (σ ρ β : ℝ) (p : Fin 3 → ℝ) :
    LinearMap.trace ℝ (Fin 3 → ℝ)
        ((fderiv ℝ (lorenzField σ ρ β) p : (Fin 3 → ℝ) →L[ℝ] (Fin 3 → ℝ)) :
          (Fin 3 → ℝ) →ₗ[ℝ] (Fin 3 → ℝ)) = -(σ + 1 + β) := by
  set P : Fin 3 → ((Fin 3 → ℝ) →L[ℝ] ℝ) := fun i => ContinuousLinearMap.proj i with hP
  set D : (Fin 3 → ℝ) →L[ℝ] (Fin 3 → ℝ) := ContinuousLinearMap.pi
    ![σ • (P 1 - P 0), (ρ - p 2) • P 0 - p 0 • P 2 - P 1, p 1 • P 0 + p 0 • P 1 - β • P 2] with hD
  have hc : ∀ i : Fin 3, HasFDerivAt (fun q : Fin 3 → ℝ => q i) (P i) p :=
    fun i => hasFDerivAt_apply i p
  have h : HasFDerivAt (lorenzField σ ρ β) D p := by
    rw [hasFDerivAt_pi']
    intro i
    fin_cases i
    · have := ((hc 1).sub (hc 0)).const_mul σ
      convert this using 1 <;> ext v <;> simp [lorenzField, D, P]
    · have := (((hc 0).mul ((hasFDerivAt_const ρ p).sub (hc 2))).sub (hc 1))
      convert this using 1 <;> ext v <;> simp [lorenzField, D, P]
      ring
    · have := (((hc 0).mul (hc 1)).sub ((hc 2).const_mul β))
      convert this using 1 <;> ext v <;> simp [lorenzField, D, P]
      ring
  rw [h.fderiv, LinearMap.trace_eq_matrix_trace ℝ (Pi.basisFun ℝ (Fin 3)), Matrix.trace,
    Fin.sum_univ_three]
  simp [D, P]
  ring

/-- The resting points, where all three rates vanish, are exactly the origin and the two lobe
centres `(±√(β(ρ - 1)), ±√(β(ρ - 1)), ρ - 1)`. -/
theorem lorenz_resting_points (σ ρ β : ℝ) (hσ : 0 < σ) (hβ : 0 < β) (hρ : 1 < ρ)
    (p : Fin 3 → ℝ) :
    lorenzField σ ρ β p = 0 ↔
      p = ![0, 0, 0] ∨
      p = ![Real.sqrt (β * (ρ - 1)), Real.sqrt (β * (ρ - 1)), ρ - 1] ∨
      p = ![-Real.sqrt (β * (ρ - 1)), -Real.sqrt (β * (ρ - 1)), ρ - 1] := by
  have hpos : 0 ≤ β * (ρ - 1) := by nlinarith
  have hs := Real.sq_sqrt hpos
  have hs' := Real.mul_self_sqrt hpos
  constructor
  · intro h
    have e0 := congrFun h 0
    have e1 := congrFun h 1
    have e2 := congrFun h 2
    simp [lorenzField] at e0 e1 e2
    have hyx : p 1 = p 0 := by
      rcases e0 with h0 | h0
      · exact absurd h0 hσ.ne'
      · linarith
    rw [hyx] at e1 e2
    have hx : p 0 * (ρ - 1 - p 2) = 0 := by linarith
    rcases mul_eq_zero.mp hx with h0 | h0
    · left
      have : p 2 = 0 := by
        rw [h0] at e2
        have : β * p 2 = 0 := by linarith
        rcases mul_eq_zero.mp this with h | h
        · exact absurd h hβ.ne'
        · exact h
      ext i; fin_cases i <;> simp [*]
    · right
      have hz : p 2 = ρ - 1 := by linarith
      rw [hz] at e2
      have hx2 : p 0 * p 0 = Real.sqrt (β * (ρ - 1)) * Real.sqrt (β * (ρ - 1)) := by
        rw [hs']; linarith
      rcases mul_self_eq_mul_self_iff.mp hx2 with h | h
      · left; ext i; fin_cases i <;> simp [*]
      · right; ext i; fin_cases i <;> simp [*]
  · rintro (h | h | h) <;> subst h <;> ext i <;> fin_cases i <;> simp [lorenzField] <;> nlinarith

-- Lorenz's values σ = 10, ρ = 28, β = 8/3: lobe height ρ - 1 = 27 and lobe width squared β (ρ - 1) = 72.
example : (28 : ℚ) - 1 = 27 := by norm_num
example : (8 / 3 : ℚ) * (28 - 1) = 72 := by norm_num
-- Origin eigenvalues: λ² + (σ + 1) λ - σ (ρ - 1) = λ² + 11 λ - 270.
example : (10 : ℚ) + 1 = 11 ∧ (10 : ℚ) * (28 - 1) = 270 := by norm_num
-- Lobe-centre cubic: constant term 2 σ β (ρ - 1) = 1440, so the Jacobian's determinant is -1440.
example : 2 * (10 : ℚ) * (8 / 3) * (28 - 1) = 1440 := by norm_num
-- Heating threshold σ (σ + β + 3) / (σ - β - 1) = 470/19 (printed 24.736842), and 28 lies above it.
example : (10 : ℚ) * (10 + 8 / 3 + 3) / (10 - 8 / 3 - 1) = 470 / 19 ∧ (470 / 19 : ℚ) < 28 := by norm_num

#print axioms lorenz_paths_eventually_trapped
#print axioms lorenz_divergence_constant
#print axioms lorenz_resting_points
