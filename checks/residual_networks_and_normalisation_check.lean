-- Residual connections and normalisation: layer normalisation turns any list with some spread into one with mean 0 and variance 1, a chain of layers that each scale lengths by s shrinks or grows the gradient by exactly s^L, and with skip connections whose side branches have slope at most a the gradient stays between (1 - a)^L and (1 + a)^L of its size.
import Mathlib.Algebra.BigOperators.Expect
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.BigOperators.Expect
import Mathlib.Analysis.Normed.Module.FiniteDimension

open Finset BigOperators

namespace ResNorm

/-- The mean `μ` of a list `x₁, …, x_d` of numbers: their average. -/
noncomputable def mean {d : ℕ} (x : Fin d → ℝ) : ℝ := 𝔼 i, x i

/-- The variance `σ²` of the list: the average squared distance from the mean. -/
noncomputable def var {d : ℕ} (x : Fin d → ℝ) : ℝ := 𝔼 i, (x i - mean x) ^ 2

/-- Layer normalisation with stretch `γ`, shift `β` and safety term `ε`:
`yᵢ = γ (xᵢ - μ) / √(σ² + ε) + β`. -/
noncomputable def layerNorm {d : ℕ} (γ β ε : ℝ) (x : Fin d → ℝ) : Fin d → ℝ :=
  fun i => γ * (x i - mean x) / Real.sqrt (var x + ε) + β

/-- Layer normalisation (with `γ = 1`, `β = 0`, `ε = 0`) of any list that has some spread
(variance not 0) gives a list with mean 0 and variance 1. -/
theorem layerNorm_mean_zero_variance_one {d : ℕ} (x : Fin d → ℝ) (hspread : var x ≠ 0) :
    mean (layerNorm 1 0 0 x) = 0 ∧ var (layerNorm 1 0 0 x) = 1 := by
  rcases Nat.eq_zero_or_pos d with hd | hd
  · subst hd
    exact absurd (by simp [var]) hspread
  have : Nonempty (Fin d) := ⟨⟨0, hd⟩⟩
  have hσ : 0 ≤ var x := Finset.expect_nonneg (fun i _ => sq_nonneg _)
  have hlay : layerNorm 1 0 0 x = fun i => (x i - mean x) / Real.sqrt (var x) := by
    funext i; simp [layerNorm]
  have hc : 𝔼 i, (x i - mean x) = 0 := by
    rw [Finset.expect_sub_distrib, Finset.expect_const Finset.univ_nonempty]
    simp [mean]
  have hm : mean (layerNorm 1 0 0 x) = 0 := by
    rw [hlay]
    show 𝔼 i, ((x i - mean x) / Real.sqrt (var x)) = 0
    rw [← Finset.expect_div, hc, zero_div]
  refine ⟨hm, ?_⟩
  unfold var
  rw [hm, hlay]
  simp only [sub_zero, div_pow, Real.sq_sqrt hσ]
  rw [← Finset.expect_div]
  exact div_self hspread

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]

/-- If a slope table scales every length by `s`, so does its transpose (adjoint). -/
theorem adjoint_norm_of_scale (A : E →L[ℝ] E) (s : ℝ) (h : ∀ x, ‖A x‖ = s * ‖x‖) (x : E) :
    ‖ContinuousLinearMap.adjoint A x‖ = s * ‖x‖ := by
  rcases lt_trichotomy s 0 with hs | hs | hs
  · have hx : x = 0 := by
      have h1 := h x
      have h2 := norm_nonneg (A x)
      have h3 := norm_nonneg x
      have : ‖x‖ = 0 := by nlinarith
      exact norm_eq_zero.mp this
    simp [hx]
  · subst hs
    have hA : A = 0 := by
      ext y
      have := h y
      simpa using this
    simp [hA]
  · set U : E →L[ℝ] E := s⁻¹ • A with hUdef
    have hU : ∀ y, ‖U y‖ = ‖y‖ := by
      intro y
      rw [hUdef, smul_apply, norm_smul, h y, Real.norm_eq_abs,
        abs_inv, abs_of_pos hs, ← mul_assoc, inv_mul_cancel₀ hs.ne', one_mul]
    let li : E →ₗᵢ[ℝ] E := { toLinearMap := U.toLinearMap, norm_map' := hU }
    let e : E ≃ₗᵢ[ℝ] E := li.toLinearIsometryEquiv rfl
    have he : (e : E →L[ℝ] E) = U := by
      ext y; rfl
    have hadjU : ∀ y, ‖ContinuousLinearMap.adjoint U y‖ = ‖y‖ := by
      intro y
      rw [← he, LinearIsometryEquiv.adjoint_eq_symm]
      exact e.symm.norm_map y
    have hAU : A = s • U := by
      rw [hUdef, smul_smul, mul_inv_cancel₀ hs.ne', one_smul]
    rw [hAU, map_smulₛₗ, smul_apply, norm_smul, hadjU, Real.norm_eq_abs,
      starRingEnd_apply, star_trivial, abs_of_pos hs]

#print axioms adjoint_norm_of_scale

/-- Backpropagation through layers `1, …, L` with slope tables `J l`: the gradient `g_L` at the
output is passed back through each transposed slope table, last layer first, giving
`g₀ = J₁ᵀ J₂ᵀ ⋯ J_Lᵀ g_L`. -/
noncomputable def backprop (J : ℕ → E →L[ℝ] E) : ℕ → E → E
  | 0, g => g
  | n + 1, g => backprop J n (ContinuousLinearMap.adjoint (J (n + 1)) g)

/-- The plain chain: if every layer's slope table scales lengths by the same factor `s`, then
after `L` layers the gradient's length is `s ^ L` times its length at the output. -/
theorem backprop_norm_eq_pow (J : ℕ → E →L[ℝ] E) (s : ℝ)
    (hscale : ∀ l x, ‖J l x‖ = s * ‖x‖) (L : ℕ) (g : E) :
    ‖backprop J L g‖ = s ^ L * ‖g‖ := by
  induction L generalizing g with
  | zero => simp [backprop]
  | succ n ih =>
    rw [backprop, ih, adjoint_norm_of_scale (J (n + 1)) s (hscale (n + 1)), pow_succ, mul_assoc]

/-- The residual chain: when layer `l` is `h ↦ h + F_l(h)`, its slope table is `I + F_l'`.
If every side branch's slope table has size at most `a ≤ 1` (the branch is small), the
gradient's length after `L` layers lies between `(1 - a) ^ L` and `(1 + a) ^ L` times its
length at the output. -/
theorem residual_backprop_norm_bounds (F' : ℕ → E →L[ℝ] E) (a : ℝ)
    (hsmall : ∀ l, ‖F' l‖ ≤ a) (ha : a ≤ 1) (L : ℕ) (g : E) :
    (1 - a) ^ L * ‖g‖ ≤ ‖backprop (fun l => ContinuousLinearMap.id ℝ E + F' l) L g‖ ∧
      ‖backprop (fun l => ContinuousLinearMap.id ℝ E + F' l) L g‖ ≤ (1 + a) ^ L * ‖g‖ := by
  have ha0 : 0 ≤ a := le_trans (norm_nonneg _) (hsmall 0)
  have hstep : ∀ l (y : E),
      (1 - a) * ‖y‖ ≤ ‖ContinuousLinearMap.adjoint (ContinuousLinearMap.id ℝ E + F' l) y‖ ∧
        ‖ContinuousLinearMap.adjoint (ContinuousLinearMap.id ℝ E + F' l) y‖ ≤ (1 + a) * ‖y‖ := by
    intro l y
    have hadj : ContinuousLinearMap.adjoint (ContinuousLinearMap.id ℝ E + F' l) y =
        y + ContinuousLinearMap.adjoint (F' l) y := by
      rw [map_add, add_apply]
      congr 1
      have : ContinuousLinearMap.adjoint (ContinuousLinearMap.id ℝ E) = ContinuousLinearMap.id ℝ E :=
        ContinuousLinearMap.adjoint_id
      rw [this]; rfl
    have hF : ‖ContinuousLinearMap.adjoint (F' l) y‖ ≤ a * ‖y‖ := by
      calc ‖ContinuousLinearMap.adjoint (F' l) y‖ ≤ ‖ContinuousLinearMap.adjoint (F' l)‖ * ‖y‖ :=
            (ContinuousLinearMap.adjoint (F' l)).le_opNorm y
        _ = ‖F' l‖ * ‖y‖ := by rw [LinearIsometryEquiv.norm_map]
        _ ≤ a * ‖y‖ := mul_le_mul_of_nonneg_right (hsmall l) (norm_nonneg y)
    rw [hadj]
    constructor
    · have := norm_sub_norm_le y (-ContinuousLinearMap.adjoint (F' l) y)
      rw [sub_neg_eq_add, norm_neg] at this
      linarith
    · have := norm_add_le y (ContinuousLinearMap.adjoint (F' l) y)
      linarith
  induction L generalizing g with
  | zero => simp [backprop]
  | succ n ih =>
    obtain ⟨h1, h2⟩ := ih (ContinuousLinearMap.adjoint (ContinuousLinearMap.id ℝ E + F' (n + 1)) g)
    obtain ⟨k1, k2⟩ := hstep (n + 1) g
    have p1 : 0 ≤ (1 - a) ^ n := pow_nonneg (by linarith) n
    have p2 : 0 ≤ (1 + a) ^ n := pow_nonneg (by linarith) n
    rw [backprop]
    constructor
    · calc (1 - a) ^ (n + 1) * ‖g‖ = (1 - a) ^ n * ((1 - a) * ‖g‖) := by ring
        _ ≤ (1 - a) ^ n * ‖ContinuousLinearMap.adjoint
              (ContinuousLinearMap.id ℝ E + F' (n + 1)) g‖ := mul_le_mul_of_nonneg_left k1 p1
        _ ≤ _ := h1
    · calc _ ≤ (1 + a) ^ n * ‖ContinuousLinearMap.adjoint
              (ContinuousLinearMap.id ℝ E + F' (n + 1)) g‖ := h2
        _ ≤ (1 + a) ^ n * ((1 + a) * ‖g‖) := mul_le_mul_of_nonneg_left k2 p2
        _ = (1 + a) ^ (n + 1) * ‖g‖ := by ring

/-- The card's list `(1, 2, 3, 4)`. -/
def x₀ : Fin 4 → ℚ := ![1, 2, 3, 4]

/-- Its mean is 5/2 (2.5). -/
example : 𝔼 i, x₀ i = 5 / 2 := by
  simp [Finset.expect_univ, Fin.sum_univ_four, x₀, NNRat.smul_def]; norm_num

/-- Its variance is 5/4 (1.25). -/
example : 𝔼 i, (x₀ i - 5 / 2) ^ 2 = 5 / 4 := by
  simp [Finset.expect_univ, Fin.sum_univ_four, x₀, NNRat.smul_def]; norm_num

/-- The first output squared: `y₁² = (-3/2)² / (5/4) = 9/5`, so `y₁ = -1.341641…`. -/
example : (-3 / 2 : ℚ) ^ 2 / (5 / 4) = 9 / 5 := by norm_num

/-- Dividing by `d - 1 = 3` instead of `d = 4`: the output's variance is `(d - 1)/d = 3/4`. -/
example : ((∑ i, (x₀ i - 5 / 2) ^ 2) / ((∑ i, (x₀ i - 5 / 2) ^ 2) / 3)) / 4 = (3 / 4 : ℚ) := by
  simp [Fin.sum_univ_four, x₀]; norm_num

#print axioms layerNorm_mean_zero_variance_one
#print axioms backprop_norm_eq_pow
#print axioms residual_backprop_norm_bounds

end ResNorm
