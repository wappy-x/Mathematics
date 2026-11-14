-- Whose risk is it: for any risk measure that scales with the book, position times slope summed over the lines gives back the whole risk, and for delta-normal VaR the component VaRs add up exactly and selling a line saves at most its component.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Add

open Matrix

theorem quadForm_symm_aux {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (hS : S.IsSymm)
    (v w : Fin n → ℝ) : v ⬝ᵥ S *ᵥ w = w ⬝ᵥ S *ᵥ v := by
  rw [dotProduct_mulVec, ← mulVec_transpose, hS, dotProduct_comm]

theorem quadForm_line_aux {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (a b : Fin n → ℝ)
    (α β : ℝ) :
    (α • a + β • b) ⬝ᵥ S *ᵥ (α • a + β • b)
      = α ^ 2 * (a ⬝ᵥ S *ᵥ a) + α * β * (a ⬝ᵥ S *ᵥ b + b ⬝ᵥ S *ᵥ a)
        + β ^ 2 * (b ⬝ᵥ S *ᵥ b) := by
  simp only [mulVec_add, mulVec_smul, add_dotProduct, dotProduct_add, smul_dotProduct,
    dotProduct_smul, smul_eq_mul]
  ring

#print axioms quadForm_symm_aux
#print axioms quadForm_line_aux

/-- Euler's rule: if a risk measure `V` on books of `n` positions scales with the book
(`V (c • y) = c * V y` for every book `y` and every factor `c > 0`) and has slopes at the
book `x`, then each position times the slope of `V` in its direction (the component), added
over all lines, is exactly `V x`. -/
theorem euler_rule_components_sum_to_var {n : ℕ} (V : (Fin n → ℝ) → ℝ)
    (hV : ∀ (y : Fin n → ℝ) (c : ℝ), 0 < c → V (c • y) = c * V y)
    (x : Fin n → ℝ) (hx : DifferentiableAt ℝ V x) :
    ∑ i, x i * fderiv ℝ V x (Pi.single i 1) = V x := by
  have hline : HasDerivAt (fun c : ℝ => c • x) x 1 := by
    simpa using (hasDerivAt_id (1:ℝ)).smul_const x
  have hf : HasFDerivAt V (fderiv ℝ V x) ((1:ℝ) • x) := by
    rw [one_smul]; exact hx.hasFDerivAt
  have h1 : HasDerivAt (fun c : ℝ => V (c • x)) (fderiv ℝ V x x) 1 :=
    hf.comp_hasDerivAt (x := (1:ℝ)) hline
  have h2' : HasDerivAt (fun c : ℝ => c * V x) (V x) 1 := by
    simpa using (hasDerivAt_id (1:ℝ)).mul_const (V x)
  have h2 : HasDerivAt (fun c : ℝ => V (c • x)) (V x) 1 := by
    apply h2'.congr_of_eventuallyEq
    filter_upwards [Ioi_mem_nhds (one_pos : (0:ℝ) < 1)] with c hc
    exact hV x c hc
  have hxsum : ∑ i, x i • (Pi.single i 1 : Fin n → ℝ) = x := by
    funext j; simp [Finset.sum_apply, Pi.single_apply]
  calc ∑ i, x i * fderiv ℝ V x (Pi.single i 1)
      = fderiv ℝ V x (∑ i, x i • (Pi.single i 1 : Fin n → ℝ)) := by
        rw [map_sum]; simp [map_smul]
    _ = V x := by rw [hxsum]; exact h1.unique h2

/-- Delta-normal VaR `V y = z * √(yᵀ Σ y)` with a symmetric covariance table `Σ`: at a book
with spread `σ_p = √(xᵀ Σ x) > 0`, the marginal VaR of line `i` (the slope of `V` in that
line's direction) is `z * (Σ x)_i / σ_p`, and the components `x_i * M_i` add up to `V x`. -/
theorem delta_normal_marginal_var_and_components_sum {n : ℕ}
    (S : Matrix (Fin n) (Fin n) ℝ) (hS : S.IsSymm) (z : ℝ) (x : Fin n → ℝ)
    (hσ : 0 < x ⬝ᵥ S *ᵥ x) :
    (∀ i, fderiv ℝ (fun y : Fin n → ℝ => z * Real.sqrt (y ⬝ᵥ S *ᵥ y)) x (Pi.single i 1)
        = z * (S *ᵥ x) i / Real.sqrt (x ⬝ᵥ S *ᵥ x)) ∧
    ∑ i, x i * (z * (S *ᵥ x) i / Real.sqrt (x ⬝ᵥ S *ᵥ x))
        = z * Real.sqrt (x ⬝ᵥ S *ᵥ x) := by
  have hsq : 0 < Real.sqrt (x ⬝ᵥ S *ᵥ x) := Real.sqrt_pos.mpr hσ
  have hQ : (fun y : Fin n → ℝ => y ⬝ᵥ S *ᵥ y) = fun y => ∑ i, y i * ∑ j, S i j * y j := by
    funext y; simp [dotProduct, mulVec]
  have hdiff : DifferentiableAt ℝ (fun y : Fin n → ℝ => z * Real.sqrt (y ⬝ᵥ S *ᵥ y)) x := by
    have hq' : Differentiable ℝ (fun y : Fin n → ℝ => y ⬝ᵥ S *ᵥ y) := by rw [hQ]; fun_prop
    exact ((hq' x).sqrt hσ.ne').const_mul z
  refine ⟨fun i => ?_, ?_⟩
  · set e : Fin n → ℝ := Pi.single i 1 with he
    have hline : HasDerivAt (fun t : ℝ => x + t • e) e 0 := by
      have h := (hasDerivAt_id (0:ℝ)).smul_const e
      rw [one_smul] at h
      exact h.const_add x
    have hf : HasFDerivAt (fun y : Fin n → ℝ => z * Real.sqrt (y ⬝ᵥ S *ᵥ y))
        (fderiv ℝ (fun y : Fin n → ℝ => z * Real.sqrt (y ⬝ᵥ S *ᵥ y)) x) (x + (0:ℝ) • e) := by
      rw [zero_smul, add_zero]; exact hdiff.hasFDerivAt
    have h1 := hf.comp_hasDerivAt (x := (0:ℝ)) hline
    have hex : e ⬝ᵥ S *ᵥ x = (S *ᵥ x) i := by simp [he, single_dotProduct]
    have hpoly : ∀ t : ℝ, (x + t • e) ⬝ᵥ S *ᵥ (x + t • e)
        = x ⬝ᵥ S *ᵥ x + t * (2 * (S *ᵥ x) i) + t ^ 2 * (e ⬝ᵥ S *ᵥ e) := by
      intro t
      have h := quadForm_line_aux S x e 1 t
      simp only [one_smul, one_pow, one_mul] at h
      rw [h, quadForm_symm_aux S hS x e, hex]; ring
    have hp : HasDerivAt (fun t : ℝ => x ⬝ᵥ S *ᵥ x + t * (2 * (S *ᵥ x) i)
        + t ^ 2 * (e ⬝ᵥ S *ᵥ e)) (2 * (S *ᵥ x) i) 0 := by
      have h1a : HasDerivAt (fun t : ℝ => x ⬝ᵥ S *ᵥ x + t * (2 * (S *ᵥ x) i))
          (1 * (2 * (S *ᵥ x) i)) 0 :=
        HasDerivAt.const_add _ (HasDerivAt.mul_const (hasDerivAt_id (0:ℝ)) _)
      have h1b := HasDerivAt.mul_const (hasDerivAt_pow 2 (0:ℝ)) (e ⬝ᵥ S *ᵥ e)
      exact HasDerivAt.congr_deriv (HasDerivAt.add h1a h1b) (by simp)
    have h2 := (hp.sqrt (by simpa using hσ.ne')).const_mul z
    have h1' : HasDerivAt (fun t : ℝ => z * Real.sqrt (x ⬝ᵥ S *ᵥ x + t * (2 * (S *ᵥ x) i)
        + t ^ 2 * (e ⬝ᵥ S *ᵥ e)))
        (fderiv ℝ (fun y : Fin n → ℝ => z * Real.sqrt (y ⬝ᵥ S *ᵥ y)) x e) 0 := by
      have heq : (fun t : ℝ => z * Real.sqrt (x ⬝ᵥ S *ᵥ x + t * (2 * (S *ᵥ x) i)
          + t ^ 2 * (e ⬝ᵥ S *ᵥ e)))
          = (fun y : Fin n → ℝ => z * Real.sqrt (y ⬝ᵥ S *ᵥ y)) ∘ (fun t : ℝ => x + t • e) := by
        funext t; simp only [Function.comp, hpoly]
      rw [heq]; exact h1
    rw [h1'.unique h2]
    simp only [zero_mul, add_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true,
      zero_pow]
    field_simp
  · have hs2 : Real.sqrt (x ⬝ᵥ S *ᵥ x) ^ 2 = x ⬝ᵥ S *ᵥ x := Real.sq_sqrt hσ.le
    have hsum : ∑ i, x i * (z * (S *ᵥ x) i / Real.sqrt (x ⬝ᵥ S *ᵥ x))
        = z / Real.sqrt (x ⬝ᵥ S *ᵥ x) * ∑ i, x i * (S *ᵥ x) i := by
      rw [Finset.mul_sum]; exact Finset.sum_congr rfl (fun i _ => by ring)
    have hdot : ∑ i, x i * (S *ᵥ x) i = x ⬝ᵥ S *ᵥ x := rfl
    rw [hsum, hdot, div_mul_eq_mul_div, div_eq_iff hsq.ne', mul_assoc,
      Real.mul_self_sqrt hσ.le]

/-- Selling a line entirely saves at most its component: for delta-normal VaR with a
covariance table `Σ` (positive semidefinite), a nonnegative `z` and a book with
`σ_p > 0`, the drop in VaR from setting line `i` to zero is at most
`x_i * z * (Σ x)_i / σ_p`, because VaR is convex and lies above its tangent. -/
theorem selling_a_line_saves_at_most_its_component {n : ℕ}
    (S : Matrix (Fin n) (Fin n) ℝ) (hS : S.PosSemidef) (z : ℝ) (hz : 0 ≤ z)
    (x : Fin n → ℝ) (hσ : 0 < x ⬝ᵥ S *ᵥ x) (i : Fin n) :
    z * Real.sqrt (x ⬝ᵥ S *ᵥ x)
        - z * Real.sqrt (Function.update x i 0 ⬝ᵥ S *ᵥ Function.update x i 0)
      ≤ x i * (z * (S *ᵥ x) i / Real.sqrt (x ⬝ᵥ S *ᵥ x)) := by
  have hsym : S.IsSymm := by
    have h := hS.1
    unfold IsHermitian at h
    rw [conjTranspose_eq_transpose_of_trivial] at h
    exact h
  have hpsd : ∀ v : Fin n → ℝ, 0 ≤ v ⬝ᵥ S *ᵥ v := fun v => by
    simpa using hS.dotProduct_mulVec_nonneg v
  have hu' : Function.update x i 0 = x - x i • Pi.single i 1 := by
    funext j; by_cases h : j = i
    · subst h; simp
    · simp [h]
  have hss : Real.sqrt (x ⬝ᵥ S *ᵥ x) ^ 2 = x ⬝ᵥ S *ᵥ x := Real.sq_sqrt hσ.le
  have hss' : Real.sqrt (Function.update x i 0 ⬝ᵥ S *ᵥ Function.update x i 0) ^ 2
      = Function.update x i 0 ⬝ᵥ S *ᵥ Function.update x i 0 := Real.sq_sqrt (hpsd _)
  have hxu : x ⬝ᵥ S *ᵥ Function.update x i 0 = Function.update x i 0 ⬝ᵥ S *ᵥ x :=
    quadForm_symm_aux S hsym _ _
  have hB : x i * (S *ᵥ x) i = x ⬝ᵥ S *ᵥ x - Function.update x i 0 ⬝ᵥ S *ᵥ x := by
    rw [hu', sub_dotProduct, smul_dotProduct, single_dotProduct, smul_eq_mul]; ring
  set u := Function.update x i 0 with hu
  set B := u ⬝ᵥ S *ᵥ x with hBdef
  set s := Real.sqrt (x ⬝ᵥ S *ᵥ x) with hsdef
  set s' := Real.sqrt (u ⬝ᵥ S *ᵥ u) with hs'def
  have hs : 0 < s := Real.sqrt_pos.mpr hσ
  have hs' : 0 ≤ s' := Real.sqrt_nonneg _
  have key : B ≤ s * s' := by
    rcases hs'.lt_or_eq with h | h
    · have h3 := hpsd (s' • x + (-s) • u)
      rw [quadForm_line_aux, hxu, ← hss, ← hss'] at h3
      nlinarith [mul_pos hs h]
    · have h0 : u ⬝ᵥ S *ᵥ u = 0 := by rw [← hss', ← h]; ring
      by_contra hcon
      rw [not_le] at hcon
      rw [← h, mul_zero] at hcon
      have h3 := hpsd ((1:ℝ) • x + (-(s ^ 2 / B)) • u)
      rw [quadForm_line_aux, hxu, ← hss, h0] at h3
      have h4 : (1:ℝ) ^ 2 * s ^ 2 + 1 * -(s ^ 2 / B) * (B + B) + (-(s ^ 2 / B)) ^ 2 * 0
          = -s ^ 2 := by field_simp; ring
      nlinarith [pow_pos hs 2]
  rw [show x i * (z * (S *ᵥ x) i / s) = z * (s ^ 2 - B) / s by rw [hss, ← hB]; ring]
  rw [le_div_iff₀ hs]
  nlinarith [mul_le_mul_of_nonneg_left key hz]

#print axioms euler_rule_components_sum_to_var
#print axioms delta_normal_marginal_var_and_components_sum
#print axioms selling_a_line_saves_at_most_its_component
