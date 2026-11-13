-- L2 as a Hilbert space: on the real L2 space of any measure space, the closest point in a closed subspace exists, is unique and is a perpendicular drop, every continuous linear rule is the inner product with one function, and the inner product is the integral of the product.
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.InnerProductSpace.Projection.Minimal
import Mathlib.Analysis.InnerProductSpace.Projection.Basic
import Mathlib.Analysis.InnerProductSpace.Dual

open MeasureTheory
open scoped InnerProductSpace

/-- The projection theorem on L2: for any measure space and any closed subspace `M` of the
real L2 space, every `f` in L2 has a member `fhat` of `M` that is closest to `f`, the miss
`f - fhat` is perpendicular to every member of `M`, no other member of `M` is that close, and
the length splits like a right triangle: `‖f‖² = ‖fhat‖² + ‖f - fhat‖²`. -/
theorem closest_point_in_closed_subspace_is_perpendicular_drop
    {α : Type*} [MeasurableSpace α] (μ : Measure α)
    (M : Submodule ℝ (Lp ℝ 2 μ)) (hM : IsClosed (M : Set (Lp ℝ 2 μ)))
    (f : Lp ℝ 2 μ) :
    ∃ fhat ∈ M,
      (∀ h ∈ M, ‖f - fhat‖ ≤ ‖f - h‖) ∧
      (∀ h ∈ M, ⟪f - fhat, h⟫_ℝ = 0) ∧
      (∀ g ∈ M, (∀ h ∈ M, ‖f - g‖ ≤ ‖f - h‖) → g = fhat) ∧
      ‖f‖ ^ 2 = ‖fhat‖ ^ 2 + ‖f - fhat‖ ^ 2 := by
  obtain ⟨v, hvM, hv⟩ := M.exists_norm_eq_iInf_of_complete_subspace hM.isComplete f
  have hbdd : BddBelow (Set.range fun w : (M : Set (Lp ℝ 2 μ)) => ‖f - w‖) :=
    ⟨0, by rintro _ ⟨w, rfl⟩; exact norm_nonneg _⟩
  have hmin : ∀ h ∈ M, ‖f - v‖ ≤ ‖f - h‖ := by
    intro h hh
    rw [hv]
    exact ciInf_le hbdd (⟨h, hh⟩ : (M : Set (Lp ℝ 2 μ)))
  have horth : ∀ h ∈ M, ⟪f - v, h⟫_ℝ = 0 :=
    (Submodule.norm_eq_iInf_iff_real_inner_eq_zero M hvM).1 hv
  refine ⟨v, hvM, hmin, horth, ?_, ?_⟩
  · intro g hgM hg
    have hgeq : ‖f - g‖ = ⨅ w : (M : Set (Lp ℝ 2 μ)), ‖f - w‖ := by
      apply le_antisymm
      · have : Nonempty (M : Set (Lp ℝ 2 μ)) := ⟨⟨0, M.zero_mem⟩⟩
        exact le_ciInf fun w => hg w w.2
      · exact ciInf_le hbdd (⟨g, hgM⟩ : (M : Set (Lp ℝ 2 μ)))
    have horth' : ∀ h ∈ M, ⟪f - g, h⟫_ℝ = 0 :=
      (Submodule.norm_eq_iInf_iff_real_inner_eq_zero M hgM).1 hgeq
    have hd : g - v ∈ M := M.sub_mem hgM hvM
    have h1 := horth (g - v) hd
    have h2 := horth' (g - v) hd
    have h3 : ⟪g - v, g - v⟫_ℝ = 0 := by
      have : g - v = (f - v) - (f - g) := by abel
      calc ⟪g - v, g - v⟫_ℝ = ⟪(f - v) - (f - g), g - v⟫_ℝ := by rw [← this]
        _ = 0 := by rw [inner_sub_left, h1, h2, sub_zero]
    rw [real_inner_self_eq_norm_sq] at h3
    have : ‖g - v‖ = 0 := by simpa using h3
    exact sub_eq_zero.1 (norm_eq_zero.1 this)
  · have hperp : ⟪v, f - v⟫_ℝ = 0 := by rw [real_inner_comm]; exact horth v hvM
    have := norm_add_sq_eq_norm_sq_add_norm_sq_real hperp
    rw [add_sub_cancel] at this
    nlinarith [this]

/-- The Riesz representation theorem on L2: for any measure space, every linear rule `φ` on
the real L2 space that is continuous (some constant `C` has `|φ f| ≤ C ‖f‖` for every `f`) is
the inner product with one function `g`; the rule's size, the least such `C ≥ 0`, is the length of
`g`; and `g` is the only function that reproduces the rule. -/
theorem continuous_linear_rule_is_inner_product
    {α : Type*} [MeasurableSpace α] (μ : Measure α)
    (φ : Lp ℝ 2 μ →ₗ[ℝ] ℝ) (hφ : ∃ C : ℝ, ∀ f : Lp ℝ 2 μ, |φ f| ≤ C * ‖f‖) :
    ∃ g : Lp ℝ 2 μ,
      (∀ f : Lp ℝ 2 μ, φ f = ⟪f, g⟫_ℝ) ∧
      (∀ f : Lp ℝ 2 μ, |φ f| ≤ ‖g‖ * ‖f‖) ∧
      (∀ C : ℝ, 0 ≤ C → (∀ f : Lp ℝ 2 μ, |φ f| ≤ C * ‖f‖) → ‖g‖ ≤ C) ∧
      (∀ g' : Lp ℝ 2 μ, (∀ f : Lp ℝ 2 μ, φ f = ⟪f, g'⟫_ℝ) → g' = g) := by
  obtain ⟨C₀, hC₀⟩ := hφ
  let ψ : StrongDual ℝ (Lp ℝ 2 μ) := φ.mkContinuous C₀ (fun f => by
    simpa [Real.norm_eq_abs] using hC₀ f)
  let g : Lp ℝ 2 μ := (InnerProductSpace.toDual ℝ (Lp ℝ 2 μ)).symm ψ
  have hg : ∀ f, φ f = ⟪f, g⟫_ℝ := by
    intro f
    have : ⟪g, f⟫_ℝ = ψ f := by
      rw [← InnerProductSpace.toDual_apply_apply, LinearIsometryEquiv.apply_symm_apply]
    rw [real_inner_comm, this]
    rfl
  have hnorm : ‖g‖ = ‖ψ‖ := by
    simp [g]
  refine ⟨g, hg, ?_, ?_, ?_⟩
  · intro f
    rw [hg, ← Real.norm_eq_abs]
    calc ‖⟪f, g⟫_ℝ‖ ≤ ‖f‖ * ‖g‖ := norm_inner_le_norm f g
      _ = ‖g‖ * ‖f‖ := mul_comm _ _
  · intro C hC hCf
    rw [hnorm]
    refine ContinuousLinearMap.opNorm_le_bound _ hC fun f => ?_
    simpa [ψ, Real.norm_eq_abs] using hCf f
  · intro g' hg'
    have h0 : ∀ f, ⟪f, g' - g⟫_ℝ = 0 := by
      intro f; rw [inner_sub_right, ← hg, ← hg', sub_self]
    have := h0 (g' - g)
    rw [real_inner_self_eq_norm_sq] at this
    have : ‖g' - g‖ = 0 := by simpa using this
    exact sub_eq_zero.1 (norm_eq_zero.1 this)

/-- Functions in L2 have lengths and angles: the inner product of two functions in L2 is the
integral of their product, and the length of a function is the square root of its inner
product with itself. -/
theorem l2_inner_is_integral_of_product
    {α : Type*} [MeasurableSpace α] (μ : Measure α) (f g : Lp ℝ 2 μ) :
    ⟪f, g⟫_ℝ = ∫ a, f a * g a ∂μ ∧ ‖f‖ = Real.sqrt ⟪f, f⟫_ℝ := by
  refine ⟨?_, ?_⟩
  · rw [L2.inner_def]
    congr 1
    funext a
    simp [mul_comm]
  · rw [real_inner_self_eq_norm_sq, Real.sqrt_sq (norm_nonneg f)]

/-! ### The card's worked numbers: the wind week 3, 5, 8, 2, 6, 4, 7 under counting measure -/

-- squared length of the week
example : (3 : ℚ)^2 + 5^2 + 8^2 + 2^2 + 6^2 + 4^2 + 7^2 = 203 := by norm_num
-- best constant: ⟨f, 1⟩ / ⟨1, 1⟩ = 35/7 = 5
example : ((3 : ℚ) + 5 + 8 + 2 + 6 + 4 + 7) / 7 = 5 := by norm_num
-- the miss -2, 0, 3, -3, 1, -1, 2 is perpendicular to the constant 1
example : (-2 : ℚ) + 0 + 3 + (-3) + 1 + (-1) + 2 = 0 := by norm_num
-- squared miss of the constant fit
example : (3 - 5 : ℚ)^2 + (5 - 5)^2 + (8 - 5)^2 + (2 - 5)^2 + (6 - 5)^2 + (4 - 5)^2
    + (7 - 5)^2 = 28 := by norm_num
-- Pythagoras for the constant fit: 7 × 5² + 28 = 203
example : (7 : ℚ) * 5^2 + 28 = 203 := by norm_num
-- the constant 4 is farther: 35 = 28 + 7 × 1²
example : (3 - 4 : ℚ)^2 + (5 - 4)^2 + (8 - 4)^2 + (2 - 4)^2 + (6 - 4)^2 + (4 - 4)^2
    + (7 - 4)^2 = 35 ∧ (35 : ℚ) = 28 + 7 * 1^2 := by norm_num
-- weekday level 24/5 and weekend level 11/2
example : ((3 : ℚ) + 5 + 8 + 2 + 6) / 5 = 24/5 ∧ ((4 : ℚ) + 7) / 2 = 11/2 := by norm_num
-- squared miss of the two-level fit
example : (203 : ℚ) - (5 * (24/5)^2 + 2 * (11/2)^2) = 273/10 := by norm_num
example : (3 - 24/5 : ℚ)^2 + (5 - 24/5)^2 + (8 - 24/5)^2 + (2 - 24/5)^2 + (6 - 24/5)^2
    + (4 - 11/2)^2 + (7 - 11/2)^2 = 273/10 := by norm_num
-- Pythagoras for the two-level fit: 203 = 1757/10 + 273/10
example : (5 : ℚ) * (24/5)^2 + 2 * (11/2)^2 = 1757/10 ∧ (203 : ℚ) = 1757/10 + 273/10 := by
  norm_num
-- the two-level miss is perpendicular to 1 and to the weekend indicator
example : (3 - 24/5 : ℚ) + (5 - 24/5) + (8 - 24/5) + (2 - 24/5) + (6 - 24/5)
    + (4 - 11/2) + (7 - 11/2) = 0 ∧ (4 - 11/2 : ℚ) + (7 - 11/2) = 0 := by norm_num
-- gain from the second level: 5 × (1/5)² + 2 × (1/2)² = 7/10 = 28 − 273/10
example : (5 : ℚ) * (1/5)^2 + 2 * (1/2)^2 = 7/10 ∧ (28 : ℚ) - 273/10 = 7/10 := by norm_num
-- the rule "weekend mean minus weekday mean" gives 7/10 on the week
example : (11/2 : ℚ) - 24/5 = 7/10 := by norm_num
-- its representer g (-1/5 on weekdays, 1/2 at the weekend) reproduces 7/10, and ‖g‖² = 7/10
example : (-1/5 : ℚ) * (3 + 5 + 8 + 2 + 6) + 1/2 * (4 + 7) = 7/10 := by norm_num
example : (5 : ℚ) * (-1/5)^2 + 2 * (1/2)^2 = 7/10 := by norm_num
-- under the uniform probability the representer is -7/5 and 7/2, and still gives 7/10
example : (1/7 : ℚ) * ((-7/5) * (3 + 5 + 8 + 2 + 6) + 7/2 * (4 + 7)) = 7/10 := by norm_num
-- using the counting-measure representer under the uniform probability gives 1/10
example : (1/7 : ℚ) * ((-1/5) * (3 + 5 + 8 + 2 + 6) + 1/2 * (4 + 7)) = 1/10 := by norm_num
-- the two-level fit is exactly 5 + g
example : (5 : ℚ) + (-1/5) = 24/5 ∧ (5 : ℚ) + 1/2 = 11/2 := by norm_num
-- at p = 1 the constants 4, 5, 11/2, 6, 7 all sit at distance 3 from the weekend readings 4, 7
example : ∀ c ∈ ({4, 5, 11/2, 6, 7} : Finset ℚ), |4 - c| + |7 - c| = 3 := by
  intro c hc
  simp only [Finset.mem_insert, Finset.mem_singleton] at hc
  rcases hc with rfl | rfl | rfl | rfl | rfl <;> norm_num [abs_of_nonneg, abs_of_nonpos]
-- adding the separate projections onto 1 and the weekend indicator: 5 + 11/2 = 21/2
example : (5 : ℚ) + 11/2 = 21/2 := by norm_num

#print axioms closest_point_in_closed_subspace_is_perpendicular_drop
#print axioms continuous_linear_rule_is_inner_product
#print axioms l2_inner_is_integral_of_product
