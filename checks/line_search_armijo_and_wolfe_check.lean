-- Line search: along a downhill direction with a continuous slope, short enough steps pass the Armijo test and backtracking finds one, a whole interval of steps passes both Wolfe tests when the cost is bounded below, and a step passing the curvature test makes s·y positive.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open scoped InnerProductSpace

lemma lineSearch_exists_lt_of_deriv_lt (φ : ℝ → ℝ) {D K : ℝ} (h : HasDerivAt φ D 0)
    (hK : D < K) : ∃ δ > 0, ∀ t ∈ Set.Ioc 0 δ, φ t < φ 0 + K * t := by
  have ht := h.tendsto_slope_zero_right
  have hev : ∀ᶠ t in nhdsWithin (0:ℝ) (Set.Ioi 0), t⁻¹ • (φ (0 + t) - φ 0) < K :=
    ht.eventually (gt_mem_nhds hK)
  obtain ⟨u, hu, hsub⟩ := mem_nhdsGT_iff_exists_Ioc_subset.1 hev
  refine ⟨u, hu, fun t htm => ?_⟩
  have h1 : t⁻¹ * (φ t - φ 0) < K := by simpa using hsub htm
  have htpos : 0 < t := htm.1
  rw [inv_mul_lt_iff₀ htpos] at h1
  linarith

#print axioms lineSearch_exists_lt_of_deriv_lt

/-- **A Wolfe step always exists.** Take a cost `f` on any real normed space, a point `x`
and a direction `d`, and look at the cost along the line, `φ α = f (x + α • d)`.
Suppose the direction points downhill (`φ'(0) < 0`), the cost is smooth along the line
(its slope `φ'` exists and is continuous), the cost is bounded below along the line
(for steps `α ≥ 0`), and `0 < c₁ < c₂ < 1`. Then there is a whole interval of step
lengths `α > 0` that pass both Wolfe tests:
* Armijo (sufficient decrease): `f (x + α • d) ≤ f x + c₁ α φ'(0)`;
* curvature: `φ'(α) ≥ c₂ φ'(0)`;
and they also pass the strong version `|φ'(α)| ≤ c₂ |φ'(0)|`.
Here `φ'(α)` is `∇f(x + α d)ᵀ d`, the slope along the line, written `deriv φ α`. -/
theorem wolfe_steps_exist {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : E → ℝ) (x d : E) {c₁ c₂ : ℝ}
    (hsmooth : ContDiff ℝ 1 (fun α : ℝ => f (x + α • d)))
    (hdown : deriv (fun α : ℝ => f (x + α • d)) 0 < 0)
    (hbdd : BddBelow ((fun α : ℝ => f (x + α • d)) '' Set.Ici 0))
    (hc₁ : 0 < c₁) (hc₁₂ : c₁ < c₂) (hc₂ : c₂ < 1) :
    ∃ a b : ℝ, 0 < a ∧ a < b ∧ ∀ α ∈ Set.Ioo a b,
      f (x + α • d) ≤ f x + c₁ * α * deriv (fun t : ℝ => f (x + t • d)) 0 ∧
      c₂ * deriv (fun t : ℝ => f (x + t • d)) 0 ≤ deriv (fun t : ℝ => f (x + t • d)) α ∧
      |deriv (fun t : ℝ => f (x + t • d)) α| ≤ c₂ * |deriv (fun t : ℝ => f (x + t • d)) 0| := by
  set φ : ℝ → ℝ := fun t => f (x + t • d) with hφ
  set D := deriv φ 0 with hD
  have hdiff : Differentiable ℝ φ := hsmooth.differentiable (by norm_num)
  have hcont : Continuous φ := hdiff.continuous
  have hdcont : Continuous (deriv φ) := hsmooth.continuous_deriv (by norm_num)
  have hφ0 : φ 0 = f x := by simp [hφ]
  -- ψ
  set ψ : ℝ → ℝ := fun t => φ t - f x - c₁ * D * t with hψ
  have hψcont : Continuous ψ := by fun_prop
  have hψ0 : ψ 0 = 0 := by simp [hψ, hφ0]
  have hψderiv : ∀ t, deriv ψ t = deriv φ t - c₁ * D := by
    intro t
    have : HasDerivAt ψ (deriv φ t - c₁ * D) t := by
      have h1 := (hdiff t).hasDerivAt
      have h2 : HasDerivAt (fun y : ℝ => c₁ * D * y) (c₁ * D) t := by
        simpa using (hasDerivAt_id t).const_mul (c₁ * D)
      exact (h1.sub_const (f x)).sub h2
    exact this.deriv
  -- a point where ψ < 0
  have hDK : D < c₁ * D := by nlinarith
  obtain ⟨δ, hδ, hδ'⟩ := lineSearch_exists_lt_of_deriv_lt φ (hdiff 0).hasDerivAt hDK
  have hψδ : ψ δ < 0 := by
    have := hδ' δ ⟨hδ, le_rfl⟩
    simp only [hψ]; rw [hφ0] at this; linarith
  -- a point where ψ > 0
  obtain ⟨L, hL⟩ := hbdd
  have hLφ : ∀ t, 0 ≤ t → L ≤ φ t := fun t ht => hL ⟨t, ht, rfl⟩
  have hcD : 0 < -(c₁ * D) := by nlinarith
  set α₁ : ℝ := max δ ((f x - L + 1) / (-(c₁ * D))) with hα₁
  have hα₁δ : δ ≤ α₁ := le_max_left _ _
  have hα₁pos : 0 < α₁ := lt_of_lt_of_le hδ hα₁δ
  have hψα₁ : 0 < ψ α₁ := by
    have h1 : (f x - L + 1) / (-(c₁ * D)) ≤ α₁ := le_max_right _ _
    rw [div_le_iff₀ hcD] at h1
    have h2 := hLφ α₁ hα₁pos.le
    simp only [hψ]; nlinarith
  -- minimum of ψ on [0, α₁]
  obtain ⟨m, hm, hmin⟩ := isCompact_Icc.exists_isMinOn (Set.nonempty_Icc.2 hα₁pos.le)
    hψcont.continuousOn
  have hψm : ψ m < 0 := lt_of_le_of_lt (hmin ⟨hδ.le, hα₁δ⟩) hψδ
  have hm0 : m ≠ 0 := by rintro rfl; rw [hψ0] at hψm; exact lt_irrefl _ hψm
  have hm1 : m ≠ α₁ := by rintro rfl; linarith
  have hmpos : 0 < m := lt_of_le_of_ne hm.1 (Ne.symm hm0)
  have hmlt : m < α₁ := lt_of_le_of_ne hm.2 hm1
  have hloc : IsLocalMin ψ m := hmin.isLocalMin (Icc_mem_nhds hmpos hmlt)
  have hdm : deriv φ m = c₁ * D := by
    have := hloc.deriv_eq_zero
    rw [hψderiv] at this; linarith
  -- neighborhood
  have hD0 : 0 < |D| := abs_pos.2 hdown.ne
  have hev : ∀ᶠ t in nhds m, ψ t < 0 ∧ c₂ * D < deriv φ t ∧ |deriv φ t| < c₂ * |D| := by
    refine (hψcont.continuousAt.eventually (gt_mem_nhds hψm)).and
      ((hdcont.continuousAt.eventually (lt_mem_nhds ?_)).and
        ((hdcont.abs.continuousAt (x := m)).eventually (gt_mem_nhds ?_)))
    · rw [hdm]; nlinarith
    · show |deriv φ m| < c₂ * |D|
      rw [hdm, abs_mul, abs_of_pos hc₁]; nlinarith
  obtain ⟨ε, hε, hball⟩ := Metric.eventually_nhds_iff.1 hev
  set ε' := min ε (m / 2) with hε'
  have hε'pos : 0 < ε' := lt_min hε (by linarith)
  have hε'le : ε' ≤ ε := min_le_left _ _
  have hε'm : ε' ≤ m / 2 := min_le_right _ _
  refine ⟨m - ε', m + ε', by linarith, by linarith, fun t ht => ?_⟩
  have hdist : dist t m < ε := by
    rw [Real.dist_eq, abs_lt]; constructor <;> linarith [ht.1, ht.2]
  obtain ⟨h1, h2, h3⟩ := hball hdist
  refine ⟨?_, h2.le, h3.le⟩
  have : φ t - f x - c₁ * D * t < 0 := h1
  show φ t ≤ f x + c₁ * t * D
  linarith

/-- **A short enough step always passes Armijo, so backtracking stops.** With the cost
along the line `φ α = f (x + α • d)` having a slope at the start, the direction pointing
downhill (`φ'(0) < 0`), and `0 < c₁ < 1`, there is an `ᾱ > 0` such that every step in
`(0, ᾱ]` passes the Armijo test `f (x + α • d) ≤ f x + c₁ α φ'(0)`; and halving from the
full step `α = 1` reaches a passing step `(1/2)^k` after finitely many halvings `k`. -/
theorem armijo_holds_near_zero_and_backtracking_stops {E : Type*} [NormedAddCommGroup E]
    [NormedSpace ℝ E] (f : E → ℝ) (x d : E) {c₁ : ℝ}
    (hdiff : DifferentiableAt ℝ (fun α : ℝ => f (x + α • d)) 0)
    (hdown : deriv (fun α : ℝ => f (x + α • d)) 0 < 0)
    (hc₁ : 0 < c₁) (hc₁' : c₁ < 1) :
    (∃ αbar > 0, ∀ α ∈ Set.Ioc 0 αbar,
      f (x + α • d) ≤ f x + c₁ * α * deriv (fun t : ℝ => f (x + t • d)) 0) ∧
    ∃ k : ℕ, f (x + ((1 : ℝ) / 2) ^ k • d) ≤
      f x + c₁ * ((1 : ℝ) / 2) ^ k * deriv (fun t : ℝ => f (x + t • d)) 0 := by
  set D := deriv (fun t : ℝ => f (x + t • d)) 0 with hD
  have hDK : D < c₁ * D := by nlinarith
  obtain ⟨δ, hδ, hδ'⟩ := lineSearch_exists_lt_of_deriv_lt (fun α : ℝ => f (x + α • d))
    hdiff.hasDerivAt hDK
  have main : ∀ α ∈ Set.Ioc 0 δ, f (x + α • d) ≤ f x + c₁ * α * D := by
    intro α hα
    have := hδ' α hα
    simp only [zero_smul, add_zero] at this
    linarith
  refine ⟨⟨δ, hδ, main⟩, ?_⟩
  obtain ⟨k, hk⟩ := exists_pow_lt_of_lt_one hδ (by norm_num : (1:ℝ)/2 < 1)
  exact ⟨k, main _ ⟨by positivity, hk.le⟩⟩

/-- **A Wolfe step keeps the quasi-Newton curvature picture positive.** Let `f` be a cost
on a real inner product space, `x` the current point, `d` a downhill direction
(`∇f(x)ᵀ d < 0`), and `α > 0` a step that passes the curvature test
`∇f(x + α d)ᵀ d ≥ c₂ ∇f(x)ᵀ d` with `c₂ < 1`. Let `s = (x + α d) - x` be the step and
`y = ∇f(x + α d) - ∇f(x)` the change in gradient. Then `sᵀ y ≥ α (1 - c₂) |∇f(x)ᵀ d|`,
and in particular `sᵀ y > 0`. -/
theorem curvature_condition_gives_positive_sy {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℝ E] [CompleteSpace E] (f : E → ℝ) (x d : E) {α c₂ : ℝ}
    (hα : 0 < α) (hc₂ : c₂ < 1)
    (hdown : ⟪gradient f x, d⟫_ℝ < 0)
    (hcurv : c₂ * ⟪gradient f x, d⟫_ℝ ≤ ⟪gradient f (x + α • d), d⟫_ℝ) :
    α * (1 - c₂) * (-⟪gradient f x, d⟫_ℝ) ≤
        ⟪(x + α • d) - x, gradient f (x + α • d) - gradient f x⟫_ℝ ∧
      0 < ⟪(x + α • d) - x, gradient f (x + α • d) - gradient f x⟫_ℝ := by
  have key : ⟪(x + α • d) - x, gradient f (x + α • d) - gradient f x⟫_ℝ
      = α * (⟪gradient f (x + α • d), d⟫_ℝ - ⟪gradient f x, d⟫_ℝ) := by
    rw [add_sub_cancel_left, real_inner_smul_left, inner_sub_right,
      real_inner_comm d, real_inner_comm d]
  rw [key]
  have h1 : (1 - c₂) * (-⟪gradient f x, d⟫_ℝ) ≤
      ⟪gradient f (x + α • d), d⟫_ℝ - ⟪gradient f x, d⟫_ℝ := by linarith
  have h2 : 0 < (1 - c₂) * (-⟪gradient f x, d⟫_ℝ) := by
    apply mul_pos <;> linarith
  constructor
  · rw [mul_assoc]; exact mul_le_mul_of_nonneg_left h1 hα.le
  · exact mul_pos hα (lt_of_lt_of_le h2 h1)

-- The card's worked numbers on the Rosenbrock banana f(x, y) = (1 - x)^2 + 100 (y - x^2)^2,
-- start (-1.2, 1) = (-6/5, 1), slopes by the hand formulas
-- ∂f/∂x = -2(1 - x) - 400 x (y - x^2) and ∂f/∂y = 200 (y - x^2), c₁ = 1/10000, c₂ = 9/10.

-- Cost at the start: 24.2.
example : (1 - (-6/5 : ℚ)) ^ 2 + 100 * (1 - (-6/5) ^ 2) ^ 2 = 121/5 := by norm_num
-- Slope in x: -215.60; slope in y: -88.00.
example : -2 * (1 - (-6/5 : ℚ)) - 400 * (-6/5) * (1 - (-6/5) ^ 2) = -1078/5 := by norm_num
example : 200 * (1 - (-6/5 : ℚ) ^ 2) = -88 := by norm_num
-- Slope along the line, φ'(0) = -(215.6^2 + 88^2) = -54227.36.
example : -((1078/5 : ℚ) ^ 2 + 88 ^ 2) = -1355684/25 := by norm_num
-- The full step lands at (214.4, 89.0) with cost 210,482,437,168.52.
example : (-6/5 : ℚ) + 1078/5 = 1072/5 ∧ (1 : ℚ) + 88 = 89 := by norm_num
example : (1 - (1072/5 : ℚ)) ^ 2 + 100 * (89 - (1072/5) ^ 2) ^ 2 = 21048243716852/100 := by
  norm_num
-- After 9 halvings (α = 1/512) Armijo fails: the cost 35.1074 is above the bar 24.1894.
example : (121/5 : ℚ) + 1/10000 * (1/512) * (-1355684/25) <
    (1 - (-6/5 + (1078/5) / 512 : ℚ)) ^ 2 +
      100 * ((1 + 88/512) - (-6/5 + (1078/5) / 512) ^ 2) ^ 2 := by norm_num
-- After 10 halvings (α = 1/1024) Armijo passes: the cost 5.1011 is below the bar 24.1947.
example : (1 - (-6/5 + (1078/5) / 1024 : ℚ)) ^ 2 +
      100 * ((1 + 88/1024) - (-6/5 + (1078/5) / 1024) ^ 2) ^ 2 ≤
    (121/5 : ℚ) + 1/10000 * (1/1024) * (-1355684/25) := by norm_num
-- At α = 1/16384 the curvature test fails: the slope along the line there is below
-- 0.9 × (-54227.36) = -48804.624.
example :
    let px : ℚ := -6/5 + (1078/5) / 16384
    let py : ℚ := 1 + 88/16384
    (-2 * (1 - px) - 400 * px * (py - px ^ 2)) * (1078/5) + (200 * (py - px ^ 2)) * 88 <
      9/10 * (-1355684/25) := by norm_num

#print axioms wolfe_steps_exist
#print axioms armijo_holds_near_zero_and_backtracking_stops
#print axioms curvature_condition_gives_positive_sy
