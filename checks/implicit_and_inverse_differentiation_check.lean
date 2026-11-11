-- Implicit and inverse differentiation: the undo g of a function f that is one-to-one and continuous on an open interval has rate 1/f'(a) at b = f(a) whenever f'(a) is not 0, a differentiable branch of the circle x^2 + y^2 = R^2 has slope -x/y wherever y is not 0, and arcsin has rate 1/cos(arcsin u) = 1/√(1 - u^2) for -1 < u < 1.
import Mathlib.Analysis.Calculus.Deriv.Inverse
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.Trigonometric.InverseDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open Filter Topology

theorem image_Ioo_mem_nhds_of_injOn (f : ℝ → ℝ) (c d a : ℝ) (ha : a ∈ Set.Ioo c d)
    (hcont : ContinuousOn f (Set.Ioo c d)) (hinj : Set.InjOn f (Set.Ioo c d)) :
    f '' Set.Ioo c d ∈ 𝓝 (f a) := by
  obtain ⟨hca, had⟩ := ha
  obtain ⟨c', hc1, hc2⟩ := exists_between hca
  obtain ⟨d', hd1, hd2⟩ := exists_between had
  have hsub : Set.Icc c' d' ⊆ Set.Ioo c d := fun x hx => ⟨by linarith [hx.1], by linarith [hx.2]⟩
  have hcd : c' ≤ d' := by linarith
  have hIVT : Set.uIcc (f c') (f d') ⊆ f '' Set.Icc c' d' := by
    have := intermediate_value_uIcc (f := f) (a := c') (b := d')
      (by rw [Set.uIcc_of_le hcd]; exact hcont.mono hsub)
    rwa [Set.uIcc_of_le hcd] at this
  have himg : Set.uIcc (f c') (f d') ⊆ f '' Set.Ioo c d :=
    hIVT.trans (Set.image_mono hsub)
  apply Filter.mem_of_superset _ himg
  rcases hcont.strictMonoOn_of_injOn_Ioo (by linarith) hinj with h | h
  · have h1 : f c' < f a := h ⟨hc1, by linarith⟩ ⟨hca, had⟩ hc2
    have h2 : f a < f d' := h ⟨hca, had⟩ ⟨by linarith, hd2⟩ hd1
    apply Filter.mem_of_superset (Ioo_mem_nhds h1 h2)
    intro y hy
    rw [Set.uIcc_of_le (by linarith)]
    exact ⟨hy.1.le, hy.2.le⟩
  · have h1 : f a < f c' := h ⟨hc1, by linarith⟩ ⟨hca, had⟩ hc2
    have h2 : f d' < f a := h ⟨hca, had⟩ ⟨by linarith, hd2⟩ hd1
    apply Filter.mem_of_superset (Ioo_mem_nhds h2 h1)
    intro y hy
    rw [Set.uIcc_of_ge (by linarith)]
    exact ⟨hy.1.le, hy.2.le⟩

#print axioms image_Ioo_mem_nhds_of_injOn

/-- The inverse rule. Let f be one-to-one and continuous on an open interval (l, r) containing a,
let g be the undo of f there (g(f(x)) = x for every x in the interval), and let f have rate f'
at a with f' not 0. Then the undo g has rate 1 / f' at the matching output b = f(a): one over the
original rate, read at the input that produced b. -/
theorem inverse_rate_is_reciprocal_of_forward_rate (f g : ℝ → ℝ) (l r a f' : ℝ)
    (ha : a ∈ Set.Ioo l r) (hcont : ContinuousOn f (Set.Ioo l r))
    (hinj : Set.InjOn f (Set.Ioo l r)) (hundo : ∀ x ∈ Set.Ioo l r, g (f x) = x)
    (hf : HasDerivAt f f' a) (hf' : f' ≠ 0) :
    HasDerivAt g (1 / f') (f a) := by
  have hga : g (f a) = a := hundo a ha
  have hg : ContinuousAt g (f a) := by
    rw [ContinuousAt, hga, (nhds_basis_Ioo_pos a).tendsto_right_iff]
    intro ε hε
    have hsub : Set.Ioo (max l (a - ε)) (min r (a + ε)) ⊆ Set.Ioo l r := fun x hx =>
      ⟨lt_of_le_of_lt (le_max_left _ _) hx.1, lt_of_lt_of_le hx.2 (min_le_left _ _)⟩
    have haI : a ∈ Set.Ioo (max l (a - ε)) (min r (a + ε)) :=
      ⟨max_lt ha.1 (by linarith), lt_min ha.2 (by linarith)⟩
    have hN := image_Ioo_mem_nhds_of_injOn f _ _ a haI (hcont.mono hsub) (hinj.mono hsub)
    filter_upwards [hN] with y hy
    obtain ⟨x, hx, rfl⟩ := hy
    rw [hundo x (hsub hx)]
    exact ⟨lt_of_le_of_lt (le_max_right _ _) hx.1, lt_of_lt_of_le hx.2 (min_le_right _ _)⟩
  have hfg : ∀ᶠ y in 𝓝 (f a), f (g y) = y := by
    filter_upwards [image_Ioo_mem_nhds_of_injOn f l r a ha hcont hinj] with y hy
    obtain ⟨x, hx, rfl⟩ := hy
    rw [hundo x hx]
  rw [one_div]
  exact HasDerivAt.of_local_left_inverse hg (by rw [hga]; exact hf) hf' hfg

/-- Implicit differentiation on a circle of radius R. Suppose a branch y of the curve
x^2 + y^2 = R^2 exists near x₀: y is differentiable at x₀ with rate y', and x^2 + y(x)^2 = R^2
for every x near x₀. If y(x₀) is not 0, the slope is forced: y' = -x₀ / y(x₀). -/
theorem circle_branch_slope_is_neg_x_div_y (R x₀ y' : ℝ) (y : ℝ → ℝ)
    (hy : HasDerivAt y y' x₀) (hrel : ∀ᶠ x in 𝓝 x₀, x ^ 2 + (y x) ^ 2 = R ^ 2)
    (hy0 : y x₀ ≠ 0) :
    y' = -x₀ / y x₀ := by
  have h1 : HasDerivAt (fun x => x ^ 2 + (y x) ^ 2)
      (↑(2:ℕ) * x₀ ^ (2 - 1) * 1 + ↑(2:ℕ) * (y x₀) ^ (2 - 1) * y') x₀ :=
    ((hasDerivAt_id x₀).pow 2).add (hy.pow 2)
  have h2 : HasDerivAt (fun x => x ^ 2 + (y x) ^ 2) 0 x₀ :=
    (hasDerivAt_const x₀ (R ^ 2)).congr_of_eventuallyEq hrel
  have h3 := h1.unique h2
  norm_num at h3
  field_simp
  linarith

/-- The arcsin rate. For every u strictly between -1 and 1, arcsin has rate 1 / cos(arcsin u),
and on arcsin's window cosine is not negative, so that rate is 1 / √(1 - u^2). -/
theorem arcsin_rate_is_one_div_sqrt_one_sub_sq (u : ℝ) (h₁ : -1 < u) (h₂ : u < 1) :
    HasDerivAt Real.arcsin (1 / Real.cos (Real.arcsin u)) u ∧
      Real.cos (Real.arcsin u) = Real.sqrt (1 - u ^ 2) := by
  rw [Real.cos_arcsin]
  exact ⟨Real.hasDerivAt_arcsin (by linarith) (by linarith), rfl⟩

-- The post is on the shore: 3 × 3 + 4 × 4 = 25 = 5 × 5.
example : (3 * 3 + 4 * 4 : ℕ) = 25 ∧ (5 * 5 : ℕ) = 25 := by decide
-- Differentiate the relation at the post: 6 + 8y' = 0 gives y' = -6/8 = -3/4 (the card's -0.75).
example : (2 * 3 + 2 * 4 * (-3 / 4) : ℚ) = 0 ∧ (-6 / 8 : ℚ) = -3 / 4 := by norm_num
-- At (3, -4) on the southern shore the same formula -x/y gives +3/4.
example : (-3 / -4 : ℚ) = 3 / 4 := by norm_num
-- Road 3: the radius slope 4/3 times the tangent slope -3/4 is -1.
example : (4 / 3 : ℚ) * (-3 / 4) = -1 := by norm_num
-- Sine's rate at the bearing: √(1 - (3/5)^2) = 4/5 (the card's 0.8), so arcsin's rate at 3/5 is 5/4.
example : Real.sqrt (1 - (3 / 5) ^ 2) = 4 / 5 := by
  rw [show (1 : ℝ) - (3 / 5) ^ 2 = (4 / 5) ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
example : (1 : ℚ) / (4 / 5) = 5 / 4 := by norm_num
-- Per metre east: 1.25 / 5 = 1/4 radian.
example : (5 / 4 : ℚ) / 5 = 1 / 4 := by norm_num
-- The arctan rate 1/(1 + u^2) at u = 1 is 1/2.
example : (1 : ℚ) / (1 + 1 ^ 2) = 1 / 2 := by norm_num
-- Mistake: the chain factor dropped on y^2 gives 2 × 3 + 2 × 4 = 14, not 0.
example : (2 * 3 + 2 * 4 : ℕ) = 14 := by decide
-- Cubing undone at 0: the quotients h / h^3 are 100 at h = 1/10 and 10000 at h = 1/100.
example : ((1 / 10 : ℚ) / (1 / 10) ^ 3) = 100 ∧ ((1 / 100 : ℚ) / (1 / 100) ^ 3) = 10000 := by
  norm_num

#print axioms inverse_rate_is_reciprocal_of_forward_rate
#print axioms circle_branch_slope_is_neg_x_div_y
#print axioms arcsin_rate_is_one_div_sqrt_one_sub_sq
