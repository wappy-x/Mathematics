-- Lagrange multipliers: at a best point of a smooth function on a regular rule in the plane, its gradient is a multiple of the rule's gradient, that multiple is the rate at which the best value grows as the rule is loosened, and the card's 40 m fence is best as a 10 m square.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.LagrangeMultipliers
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.Order.LocalExtr
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open scoped Gradient

/-- Helper: the derivative form of the multiplier rule. -/
theorem lagrange_fderiv_helper
    {f g : EuclideanSpace ℝ (Fin 2) → ℝ} {p : EuclideanSpace ℝ (Fin 2)} {c : ℝ}
    (hf : ContDiffAt ℝ 1 f p) (hg : ContDiffAt ℝ 1 g p)
    (hp : g p = c) (hreg : ∇ g p ≠ 0)
    (hbest : IsLocalExtrOn f {x | g x = c} p) :
    ∃ lam : ℝ, fderiv ℝ f p = lam • fderiv ℝ g p := by
  have hf' := hf.hasStrictFDerivAt one_ne_zero
  have hg' := hg.hasStrictFDerivAt one_ne_zero
  subst hp
  obtain ⟨a, b, hab, h⟩ := hbest.exists_multipliers_of_hasStrictFDerivAt_1d hg' hf'
  have hg0 : fderiv ℝ g p ≠ 0 := by
    intro h0
    apply hreg
    rw [← toDual_gradient (𝕜 := ℝ)] at h0
    exact (InnerProductSpace.toDual ℝ _).map_eq_zero_iff.mp h0
  by_cases hb : b = 0
  · subst hb
    have ha : a ≠ 0 := by
      intro ha; exact hab (by simp [ha])
    simp only [zero_smul, add_zero] at h
    exact absurd ((smul_eq_zero.mp h).resolve_left ha) hg0
  · refine ⟨-a / b, ?_⟩
    have : b • fderiv ℝ f p = -(a • fderiv ℝ g p) := eq_neg_of_add_eq_zero_right h
    have h2 := congrArg (fun L => b⁻¹ • L) this
    simp only [smul_smul, inv_mul_cancel₀ hb, one_smul, smul_neg] at h2
    rw [h2, neg_div, div_eq_inv_mul, neg_smul]

#print axioms lagrange_fderiv_helper

/-- Lagrange multipliers in the plane. Let `f` and the rule's function `g` be smooth (continuous
partial rates) near the point `p`, let `p` obey the rule `g p = c`, let the rule be regular there
(the gradient of `g` at `p` is not the zero arrow), and let `p` be a local best point (largest or
smallest) of `f` among nearby points that obey the rule. Then the gradient of `f` at `p` is some
number `lam` times the gradient of `g` at `p`. -/
theorem gradients_line_up_at_constrained_best_point
    {f g : EuclideanSpace ℝ (Fin 2) → ℝ} {p : EuclideanSpace ℝ (Fin 2)} {c : ℝ}
    (hf : ContDiffAt ℝ 1 f p) (hg : ContDiffAt ℝ 1 g p)
    (hp : g p = c) (hreg : ∇ g p ≠ 0)
    (hbest : IsLocalExtrOn f {x | g x = c} p) :
    ∃ lam : ℝ, ∇ f p = lam • ∇ g p := by
  obtain ⟨lam, h⟩ := lagrange_fderiv_helper hf hg hp hreg hbest
  refine ⟨lam, ?_⟩
  apply (InnerProductSpace.toDual ℝ _).injective
  rw [toDual_gradient, map_smulₛₗ, toDual_gradient, h]
  simp

/-- The multiplier is the price of the rule. Let the allowed amount `P` vary, and let the best
point `x P` move smoothly with it, always obeying the rule `g (x P) = P`. If at `P₀` the point
`x P₀` is a local best point of the smooth `f` on the regular rule `g = P₀`, then there is a
multiplier `lam` with `∇ f = lam • ∇ g` at `x P₀`, and the best value `f (x P)` grows at the rate
`lam` per unit of `P` at `P₀`. -/
theorem multiplier_is_price_of_rule
    {f g : EuclideanSpace ℝ (Fin 2) → ℝ} {x : ℝ → EuclideanSpace ℝ (Fin 2)} {P₀ : ℝ}
    (hf : ContDiffAt ℝ 1 f (x P₀)) (hg : ContDiffAt ℝ 1 g (x P₀))
    (hx : ContDiffAt ℝ 1 x P₀) (hon : ∀ P, g (x P) = P)
    (hreg : ∇ g (x P₀) ≠ 0)
    (hbest : IsLocalExtrOn f {y | g y = P₀} (x P₀)) :
    ∃ lam : ℝ, ∇ f (x P₀) = lam • ∇ g (x P₀) ∧
      HasDerivAt (fun P => f (x P)) lam P₀ := by
  obtain ⟨lam, h⟩ := lagrange_fderiv_helper hf hg (hon P₀) hreg hbest
  have hxd := (hx.differentiableAt one_ne_zero).hasDerivAt
  have hfd := (hf.differentiableAt one_ne_zero).hasFDerivAt
  have hgd := (hg.differentiableAt one_ne_zero).hasFDerivAt
  have H1 := hfd.comp_hasDerivAt P₀ hxd
  have H2 := hgd.comp_hasDerivAt P₀ hxd
  have hid : (g ∘ x) = id := funext hon
  rw [hid] at H2
  have H3 := H2.unique (hasDerivAt_id P₀)
  refine ⟨lam, ?_, ?_⟩
  · have : ∇ f (x P₀) = lam • ∇ g (x P₀) := by
      apply (InnerProductSpace.toDual ℝ _).injective
      rw [toDual_gradient, map_smulₛₗ, toDual_gradient, h]
      simp
    exact this
  · rw [h, smul_apply, H3, smul_eq_mul, mul_one] at H1
    exact H1

/-- The paddock (Step 5): every rectangle with sides `x` and `y` that uses 40 m of fence,
`2x + 2y = 40`, holds at most 100 square metres, and only the 10 m by 10 m square holds exactly
100. -/
theorem fence_forty_best_is_ten_square (x y : ℝ) (hfence : 2 * x + 2 * y = 40) :
    x * y ≤ 100 ∧ (x * y = 100 ↔ x = 10 ∧ y = 10) := by
  have hy : y = 20 - x := by linarith
  subst hy
  refine ⟨by nlinarith [sq_nonneg (x - 10)], ⟨fun h => ?_, fun ⟨h1, h2⟩ => by subst h1; norm_num⟩⟩
  have : (x - 10) ^ 2 = 0 := by nlinarith
  have hx : x = 10 := by nlinarith [pow_eq_zero_iff (n := 2) (a := x - 10) two_ne_zero |>.mp this]
  exact ⟨hx, by linarith⟩

-- Worked numbers, by hand.
-- Area along the four-side fence, x = 0, 2, ..., 20: 0 36 64 84 96 100 96 84 64 36 0.
example : ((List.range 11).map (fun k => (2 * k) * (20 - 2 * k))) =
    [0, 36, 64, 84, 96, 100, 96, 84, 64, 36, 0] := by decide
-- The three pens in the overview: 18 by 2, 15 by 5, 10 by 10, all on 40 m of fence.
example : 2 * 18 + 2 * 2 = 40 ∧ 18 * 2 = 36 ∧ 2 * 15 + 2 * 5 = 40 ∧ 15 * 5 = 75 ∧
    2 * 10 + 2 * 10 = 40 ∧ 10 * 10 = 100 := by decide
-- Multiplier equations y = 2 lam, x = 2 lam, 2x + 2y = 40 hold at x = y = 10, lam = 5.
example : (10 : ℤ) = 2 * 5 ∧ (10 : ℤ) = 2 * 5 ∧ 2 * (10 : ℤ) + 2 * 10 = 40 := by decide
-- Step 5's identity: 100 - x(20 - x) = (x - 10)^2 for every real x.
example (x : ℝ) : 100 - x * (20 - x) = (x - 10) ^ 2 := by ring
-- Steps 1 and 2: the step t = (1, -1) uses no fence; at the 15 by 5 pen the area's rate along it
-- is 5 - 15 = -10, and at the 10 by 10 square it is 0.
example : 2 * 1 + 2 * (-1 : ℤ) = 0 ∧ (5 : ℤ) * 1 + 15 * (-1) = -10 ∧
    (10 : ℤ) * 1 + 10 * (-1) = 0 := by decide
-- From 15 by 5 to 14 by 6 the area rises from 75 to 84.
example : 15 * 5 = 75 ∧ 14 * 6 = 84 ∧ 2 * 14 + 2 * 6 = 40 := by decide
-- The price: best area P^2 / 16 has rate 2P / 16 = 40 / 8 = 5 at P = 40.
example : (40 : ℚ) ^ 2 / 16 = 100 ∧ 2 * (40 : ℚ) / 16 = 5 := by norm_num
-- A 41 m fence: a 41/4 m square holds 1681/16 m^2, a gain of 81/16 over 100.
example : (41 / 4 : ℚ) * (41 / 4) = 1681 / 16 ∧ (1681 / 16 : ℚ) - 100 = 81 / 16 := by norm_num
-- River: y = lam, x = 2 lam, x + 2y = 40 gives 20 by 10, 200 m^2, lam = 10.
example : (10 : ℤ) = 10 ∧ (20 : ℤ) = 2 * 10 ∧ (20 : ℤ) + 2 * 10 = 40 ∧ (20 : ℤ) * 10 = 200 := by
  decide
-- River with 41 m: best x = 41/2, y = 41/4, area 1681/8, a gain of 81/8 over 200.
example : (41 / 2 : ℚ) * (41 / 4) = 1681 / 8 ∧ (1681 / 8 : ℚ) - 200 = 81 / 8 := by norm_num
-- Mistake 2: lam = 6 with no fence gives 12 by 12, 48 m of fence, 144 m^2.
example : 2 * 6 = 12 ∧ 2 * 12 + 2 * 12 = 48 ∧ 12 * 12 = 144 := by decide
-- Mistake 3: the squared rule (2x + 2y - 40)^2 has gradient 2(2x + 2y - 40)(2, 2) = (0, 0) at (10, 10).
example : 2 * (2 * 10 + 2 * 10 - 40 : ℤ) * 2 = 0 := by decide

#print axioms gradients_line_up_at_constrained_best_point
#print axioms multiplier_is_price_of_rule
#print axioms fence_forty_best_is_ten_square
