-- Point types: near a surface point whose two principal curvatures have one sign the surface stays strictly on one side of its tangent plane, near a point where they have opposite signs it crosses that plane, and every knife cut bends at Euler's rate κ₁ cos²θ + κ₂ sin²θ, with the pasta ring's exact curvatures checked.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Order.Filter.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Mul

open Filter Topology

/-! The card's Step 0 sets up the chart used here: move the point `p` to the
origin, lay the tangent plane flat, and measure the surface as a height `f (x, y)`
along the normal `n`.  The glass touches at `p`, so `f 0 = 0` and the first
derivative of `f` at `0` is zero.  Turning the `x` and `y` axes to the principal
directions makes the second derivative (the shape operator) diagonal with entries
`κ₁` and `κ₂`, the two principal curvatures.  The surface being smooth at `p`
with continuous second derivatives is `ContDiffAt ℝ 2 f 0`; the graph patch
`(x, y) ↦ (x, y, f (x, y))` is always regular. -/

lemma surf_sq_norm_le (q : ℝ × ℝ) : ‖q‖ ^ 2 ≤ q.1 ^ 2 + q.2 ^ 2 := by
  rw [Prod.norm_def, Real.norm_eq_abs, Real.norm_eq_abs]
  rcases max_cases |q.1| |q.2| with ⟨h, _⟩ | ⟨h, _⟩ <;> rw [h, sq_abs] <;> nlinarith [sq_nonneg q.1, sq_nonneg q.2]

lemma surf_quad (L : (ℝ × ℝ) →L[ℝ] (ℝ × ℝ) →L[ℝ] ℝ) (κ₁ κ₂ : ℝ)
    (h11 : L (1, 0) (1, 0) = κ₁) (h12 : L (1, 0) (0, 1) = 0)
    (h21 : L (0, 1) (1, 0) = 0) (h22 : L (0, 1) (0, 1) = κ₂) (q : ℝ × ℝ) :
    L q q = κ₁ * q.1 ^ 2 + κ₂ * q.2 ^ 2 := by
  have hq : q = q.1 • ((1 : ℝ), (0 : ℝ)) + q.2 • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  rw [hq]
  simp only [map_add, map_smul, add_apply, smul_apply,
    smul_eq_mul, h11, h12, h21, h22]
  simp only [Prod.fst_add, Prod.snd_add, Prod.smul_mk, smul_eq_mul]
  ring

lemma surf_symm (f : ℝ × ℝ → ℝ) (hf : ContDiffAt ℝ 2 f 0) (v w : ℝ × ℝ) :
    fderiv ℝ (fderiv ℝ f) 0 v w = fderiv ℝ (fderiv ℝ f) 0 w v :=
  hf.isSymmSndFDerivAt (by simp) v w

lemma surf_hasFDeriv2 (f : ℝ × ℝ → ℝ) (hf : ContDiffAt ℝ 2 f 0) :
    HasFDerivAt (fderiv ℝ f) (fderiv ℝ (fderiv ℝ f) 0) 0 :=
  ((hf.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)).hasFDerivAt

lemma surf_eventually_diff (f : ℝ × ℝ → ℝ) (hf : ContDiffAt ℝ 2 f 0) :
    ∀ᶠ z in 𝓝 (0 : ℝ × ℝ), DifferentiableAt ℝ f z := by
  filter_upwards [hf.eventually (by simp)] with z hz
  exact hz.differentiableAt (by norm_num)

lemma surf_taylor (f : ℝ × ℝ → ℝ) (hf : ContDiffAt ℝ 2 f 0)
    (hflat : fderiv ℝ f 0 = 0) (c : ℝ) (hc : 0 < c) :
    ∀ᶠ q in 𝓝 (0 : ℝ × ℝ),
      |f q - f 0 - (1 / 2) * fderiv ℝ (fderiv ℝ f) 0 q q| ≤ c * ‖q‖ ^ 2 := by
  set L := fderiv ℝ (fderiv ℝ f) 0 with hLdef
  have hL := surf_hasFDeriv2 f hf
  rw [← hLdef] at hL
  have hsym : ∀ v w, L v w = L w v := surf_symm f hf
  have ho := (hasFDerivAt_iff_isLittleO_nhds_zero.mp hL)
  have ho' := ho.def hc
  simp only [zero_add, hflat, sub_zero] at ho'
  have hev := (surf_eventually_diff f hf).and ho'
  obtain ⟨δ, hδ, hball⟩ := Metric.eventually_nhds_iff_ball.mp hev
  filter_upwards [Metric.ball_mem_nhds (0 : ℝ × ℝ) hδ] with q hq
  set g : ℝ × ℝ → ℝ := fun z => f z - (1 / 2) * L z z with hg
  have hsub : Metric.closedBall (0 : ℝ × ℝ) ‖q‖ ⊆ Metric.ball 0 δ := by
    intro z hz
    rw [Metric.mem_closedBall, dist_zero_right] at hz
    rw [Metric.mem_ball, dist_zero_right] at hq ⊢
    linarith
  have hderiv : ∀ z ∈ Metric.closedBall (0 : ℝ × ℝ) ‖q‖,
      HasFDerivWithinAt g (fderiv ℝ f z - (1 / 2 : ℝ) • ((L z).comp (ContinuousLinearMap.id ℝ _)
        + L.flip z)) (Metric.closedBall 0 ‖q‖) z := by
    intro z hz
    have h1 := ((hball z (hsub hz)).1).hasFDerivAt
    have h2 : HasFDerivAt (fun y => L y y) ((L z).comp (ContinuousLinearMap.id ℝ _) + L.flip z) z :=
      L.hasFDerivAt.clm_apply (hasFDerivAt_id z)
    exact (h1.sub (h2.const_smul (1 / 2 : ℝ))).hasFDerivWithinAt
  have hbound : ∀ z ∈ Metric.closedBall (0 : ℝ × ℝ) ‖q‖,
      ‖fderiv ℝ f z - (1 / 2 : ℝ) • ((L z).comp (ContinuousLinearMap.id ℝ _) + L.flip z)‖
        ≤ c * ‖q‖ := by
    intro z hz
    have heq : (1 / 2 : ℝ) • ((L z).comp (ContinuousLinearMap.id ℝ _) + L.flip z) = L z := by
      refine ContinuousLinearMap.ext (fun w => ?_)
      simp [hsym w z]
      ring
    rw [heq]
    have := (hball z (hsub hz)).2
    rw [Metric.mem_closedBall, dist_zero_right] at hz
    calc _ ≤ c * ‖z‖ := this
      _ ≤ c * ‖q‖ := by gcongr
  have hmv := (convex_closedBall (0 : ℝ × ℝ) ‖q‖).norm_image_sub_le_of_norm_hasFDerivWithin_le
    (x := 0) (y := q) hderiv hbound (Metric.mem_closedBall_self (norm_nonneg q))
    (by rw [Metric.mem_closedBall, dist_zero_right])
  have hg0 : g 0 = f 0 := by simp [hg]
  rw [hg0, sub_zero, Real.norm_eq_abs] at hmv
  have : f q - f 0 - 1 / 2 * L q q = g q - f 0 := by simp [hg]; ring
  rw [this]
  calc _ ≤ c * ‖q‖ * ‖q‖ := hmv
    _ = c * ‖q‖ ^ 2 := by ring


lemma surf_norm_axis1 (t : ℝ) : ‖((t, 0) : ℝ × ℝ)‖ ^ 2 = t ^ 2 := by
  rw [Prod.norm_def]; simp

lemma surf_norm_axis2 (t : ℝ) : ‖((0, t) : ℝ × ℝ)‖ ^ 2 = t ^ 2 := by
  rw [Prod.norm_def]; simp

/-- Along an axis-type curve: if `f (γ t) ≈ (k/2) t²` with `k > 0`, then `f (γ t) > 0` for
small `t ≠ 0`. -/
lemma surf_axis_pos (f : ℝ × ℝ → ℝ) (hf : ContDiffAt ℝ 2 f 0) (h0 : f 0 = 0)
    (hflat : fderiv ℝ f 0 = 0) (γ : ℝ → ℝ × ℝ) (hγ : Continuous γ) (hγ0 : γ 0 = 0)
    (k : ℝ) (hk : 0 < k)
    (hq : ∀ t, fderiv ℝ (fderiv ℝ f) 0 (γ t) (γ t) = k * t ^ 2)
    (hn : ∀ t, ‖γ t‖ ^ 2 = t ^ 2) :
    ∃ᶠ q in 𝓝 (0 : ℝ × ℝ), 0 < f q := by
  have ht0 : Tendsto γ (𝓝 (0 : ℝ)) (𝓝 0) := hγ0 ▸ hγ.tendsto 0
  have ht : Tendsto γ (𝓝[≠] (0 : ℝ)) (𝓝 0) := ht0.mono_left nhdsWithin_le_nhds
  refine ht.frequently (Eventually.frequently ?_)
  have hT := ht0.eventually (surf_taylor f hf hflat (k / 4) (by linarith))
  filter_upwards [nhdsWithin_le_nhds hT, self_mem_nhdsWithin] with t h1 h2
  rw [h0, sub_zero, hq t, hn t] at h1
  have ht2 : 0 < t ^ 2 := by have : t ≠ 0 := h2; positivity
  have := (abs_le.mp h1).1
  nlinarith

lemma surf_axis_neg (f : ℝ × ℝ → ℝ) (hf : ContDiffAt ℝ 2 f 0) (h0 : f 0 = 0)
    (hflat : fderiv ℝ f 0 = 0) (γ : ℝ → ℝ × ℝ) (hγ : Continuous γ) (hγ0 : γ 0 = 0)
    (k : ℝ) (hk : k < 0)
    (hq : ∀ t, fderiv ℝ (fderiv ℝ f) 0 (γ t) (γ t) = k * t ^ 2)
    (hn : ∀ t, ‖γ t‖ ^ 2 = t ^ 2) :
    ∃ᶠ q in 𝓝 (0 : ℝ × ℝ), f q < 0 := by
  have ht0 : Tendsto γ (𝓝 (0 : ℝ)) (𝓝 0) := hγ0 ▸ hγ.tendsto 0
  have ht : Tendsto γ (𝓝[≠] (0 : ℝ)) (𝓝 0) := ht0.mono_left nhdsWithin_le_nhds
  refine ht.frequently (Eventually.frequently ?_)
  have hT := ht0.eventually (surf_taylor f hf hflat (-k / 4) (by linarith))
  filter_upwards [nhdsWithin_le_nhds hT, self_mem_nhdsWithin] with t h1 h2
  rw [h0, sub_zero, hq t, hn t] at h1
  have ht2 : 0 < t ^ 2 := by have : t ≠ 0 := h2; positivity
  have := (abs_le.mp h1).2
  nlinarith

#print axioms surf_sq_norm_le
#print axioms surf_quad
#print axioms surf_symm
#print axioms surf_hasFDeriv2
#print axioms surf_eventually_diff
#print axioms surf_taylor
#print axioms surf_norm_axis1
#print axioms surf_norm_axis2
#print axioms surf_axis_pos
#print axioms surf_axis_neg

/-- Dome point: if the two principal curvatures `κ₁`, `κ₂` at `p` have one sign
(`κ₁ κ₂ > 0`, Gaussian curvature positive), then near `p` the surface lies strictly on
one side of its tangent plane: the height is either positive at every nearby point
other than `p`, or negative at every such point. -/
theorem dome_point_lies_on_one_side_of_tangent_plane
    (f : ℝ × ℝ → ℝ) (κ₁ κ₂ : ℝ)
    (hf : ContDiffAt ℝ 2 f 0)
    (h0 : f 0 = 0) (hflat : fderiv ℝ f 0 = 0)
    (h11 : fderiv ℝ (fderiv ℝ f) 0 (1, 0) (1, 0) = κ₁)
    (h12 : fderiv ℝ (fderiv ℝ f) 0 (1, 0) (0, 1) = 0)
    (h22 : fderiv ℝ (fderiv ℝ f) 0 (0, 1) (0, 1) = κ₂)
    (hK : 0 < κ₁ * κ₂) :
    (∀ᶠ q in 𝓝[≠] (0 : ℝ × ℝ), 0 < f q) ∨ (∀ᶠ q in 𝓝[≠] (0 : ℝ × ℝ), f q < 0) := by
  have h21 : fderiv ℝ (fderiv ℝ f) 0 (0, 1) (1, 0) = 0 := by rw [surf_symm f hf]; exact h12
  have hQ := surf_quad _ κ₁ κ₂ h11 h12 h21 h22
  rcases lt_or_gt_of_ne (show κ₁ ≠ 0 by rintro rfl; simp at hK) with h1 | h1
  · have h2 : κ₂ < 0 := by nlinarith
    right
    set m := min (-κ₁) (-κ₂) with hm
    have hm0 : 0 < m := lt_min (by linarith) (by linarith)
    filter_upwards [nhdsWithin_le_nhds (surf_taylor f hf hflat (m / 4) (by linarith)),
      self_mem_nhdsWithin] with q hT hne
    rw [h0, sub_zero, hQ] at hT
    have hq0 : 0 < ‖q‖ := norm_pos_iff.mpr hne
    have hn := surf_sq_norm_le q
    have ha : m ≤ -κ₁ := min_le_left _ _
    have hb : m ≤ -κ₂ := min_le_right _ _
    have := (abs_le.mp hT).2
    nlinarith [sq_nonneg q.1, sq_nonneg q.2, pow_pos hq0 2,
      mul_le_mul_of_nonneg_right ha (sq_nonneg q.1), mul_le_mul_of_nonneg_right hb (sq_nonneg q.2)]
  · have h2 : 0 < κ₂ := by nlinarith
    left
    set m := min κ₁ κ₂ with hm
    have hm0 : 0 < m := lt_min h1 h2
    filter_upwards [nhdsWithin_le_nhds (surf_taylor f hf hflat (m / 4) (by linarith)),
      self_mem_nhdsWithin] with q hT hne
    rw [h0, sub_zero, hQ] at hT
    have hq0 : 0 < ‖q‖ := norm_pos_iff.mpr hne
    have hn := surf_sq_norm_le q
    have ha : m ≤ κ₁ := min_le_left _ _
    have hb : m ≤ κ₂ := min_le_right _ _
    have := (abs_le.mp hT).1
    nlinarith [sq_nonneg q.1, sq_nonneg q.2, pow_pos hq0 2,
      mul_le_mul_of_nonneg_right ha (sq_nonneg q.1), mul_le_mul_of_nonneg_right hb (sq_nonneg q.2)]

/-- Saddle point: if the two principal curvatures `κ₁`, `κ₂` at `p` have opposite signs
(`κ₁ κ₂ < 0`, Gaussian curvature negative), then the surface crosses its tangent plane
at `p`: arbitrarily close to `p` there are points of the surface above the plane and
points below it. -/
theorem saddle_point_crosses_tangent_plane
    (f : ℝ × ℝ → ℝ) (κ₁ κ₂ : ℝ)
    (hf : ContDiffAt ℝ 2 f 0)
    (h0 : f 0 = 0) (hflat : fderiv ℝ f 0 = 0)
    (h11 : fderiv ℝ (fderiv ℝ f) 0 (1, 0) (1, 0) = κ₁)
    (h12 : fderiv ℝ (fderiv ℝ f) 0 (1, 0) (0, 1) = 0)
    (h22 : fderiv ℝ (fderiv ℝ f) 0 (0, 1) (0, 1) = κ₂)
    (hK : κ₁ * κ₂ < 0) :
    (∃ᶠ q in 𝓝 (0 : ℝ × ℝ), 0 < f q) ∧ (∃ᶠ q in 𝓝 (0 : ℝ × ℝ), f q < 0) := by
  have h21 : fderiv ℝ (fderiv ℝ f) 0 (0, 1) (1, 0) = 0 := by rw [surf_symm f hf]; exact h12
  have hQ := surf_quad _ κ₁ κ₂ h11 h12 h21 h22
  have c1 : Continuous (fun t : ℝ => ((t, 0) : ℝ × ℝ)) := by fun_prop
  have c2 : Continuous (fun t : ℝ => ((0, t) : ℝ × ℝ)) := by fun_prop
  have q1 : ∀ t : ℝ, fderiv ℝ (fderiv ℝ f) 0 (t, 0) (t, 0) = κ₁ * t ^ 2 := by
    intro t; rw [hQ]; simp
  have q2 : ∀ t : ℝ, fderiv ℝ (fderiv ℝ f) 0 (0, t) (0, t) = κ₂ * t ^ 2 := by
    intro t; rw [hQ]; simp
  rcases lt_or_gt_of_ne (show κ₁ ≠ 0 by rintro rfl; simp at hK) with h1 | h1
  · have h2 : 0 < κ₂ := by nlinarith
    exact ⟨surf_axis_pos f hf h0 hflat _ c2 rfl κ₂ h2 q2 surf_norm_axis2,
      surf_axis_neg f hf h0 hflat _ c1 rfl κ₁ h1 q1 surf_norm_axis1⟩
  · have h2 : κ₂ < 0 := by nlinarith
    exact ⟨surf_axis_pos f hf h0 hflat _ c1 rfl κ₁ h1 q1 surf_norm_axis1,
      surf_axis_neg f hf h0 hflat _ c2 rfl κ₂ h2 q2 surf_norm_axis2⟩

/-- Euler's formula, as the card's Step 3 derives it from the height: the knife cut at
angle `θ` from the `κ₁` direction is the curve `t ↦ f (t cos θ, t sin θ)`, which has
slope 0 at `p`, so its curvature there is its second derivative, and that equals
`κ₁ cos² θ + κ₂ sin² θ`. -/
theorem euler_normal_curvature_formula
    (f : ℝ × ℝ → ℝ) (κ₁ κ₂ θ : ℝ)
    (hf : ContDiffAt ℝ 2 f 0)
    (h0 : f 0 = 0) (hflat : fderiv ℝ f 0 = 0)
    (h11 : fderiv ℝ (fderiv ℝ f) 0 (1, 0) (1, 0) = κ₁)
    (h12 : fderiv ℝ (fderiv ℝ f) 0 (1, 0) (0, 1) = 0)
    (h22 : fderiv ℝ (fderiv ℝ f) 0 (0, 1) (0, 1) = κ₂) :
    deriv (fun t : ℝ => f (t * Real.cos θ, t * Real.sin θ)) 0 = 0 ∧
    deriv (deriv (fun t : ℝ => f (t * Real.cos θ, t * Real.sin θ))) 0
      = κ₁ * Real.cos θ ^ 2 + κ₂ * Real.sin θ ^ 2 := by
  have h21 : fderiv ℝ (fderiv ℝ f) 0 (0, 1) (1, 0) = 0 := by rw [surf_symm f hf]; exact h12
  have hQ := surf_quad _ κ₁ κ₂ h11 h12 h21 h22
  set v : ℝ × ℝ := (Real.cos θ, Real.sin θ) with hv
  have hφ : (fun t : ℝ => f (t * Real.cos θ, t * Real.sin θ)) = fun t => f (t • v) := by
    funext t; simp [hv]
  rw [hφ]
  have hpath : ∀ t : ℝ, HasDerivAt (fun t : ℝ => t • v) v t := by
    intro t; simpa using (hasDerivAt_id t).smul_const v
  have hcont : Tendsto (fun t : ℝ => t • v) (𝓝 0) (𝓝 0) := by
    have : Continuous (fun t : ℝ => t • v) := by fun_prop
    simpa using this.tendsto 0
  have hd : ∀ᶠ t in 𝓝 (0 : ℝ), deriv (fun t => f (t • v)) t = fderiv ℝ f (t • v) v := by
    filter_upwards [hcont.eventually (surf_eventually_diff f hf)] with t ht
    exact (ht.hasFDerivAt.comp_hasDerivAt t (hpath t)).deriv
  refine ⟨?_, ?_⟩
  · rw [hd.self_of_nhds, zero_smul, hflat]; rfl
  · rw [Filter.EventuallyEq.deriv_eq hd]
    have hL := surf_hasFDeriv2 f hf
    have hL' : HasFDerivAt (fderiv ℝ f) (fderiv ℝ (fderiv ℝ f) 0) ((0 : ℝ) • v) := by
      simpa using hL
    have h1 := hL'.comp_hasDerivAt (0 : ℝ) (hpath 0)
    have h2 := h1.clm_apply (hasDerivAt_const (0 : ℝ) v)
    have h3 : deriv (fun x : ℝ => (fderiv ℝ f (x • v)) v) 0
        = fderiv ℝ (fderiv ℝ f) 0 v v := by
      simpa [Function.comp] using h2.deriv
    rw [h3, hQ]

/-! The card's worked numbers for the pasta ring, tube radius `a = 3/2` mm and ring
radius `b = 4` mm, as exact fractions: `κ₁ = 1/a`, `κ₂ = cos v / (b + a cos v)`. -/

-- Tube rate at every point: 1/1.5 = 2/3 per mm (0.666667).
example : (1 : ℚ) / (3 / 2) = 2 / 3 := by norm_num
-- Outer edge, v = 0: ring rate 1/(4 + 1.5) = 2/11 per mm (0.181818).
example : (1 : ℚ) / (4 + 3 / 2 * 1) = 2 / 11 := by norm_num
-- Outer edge: K = (2/3)(2/11) = 4/33 per mm² (0.121212), positive, so a dome.
example : (2 / 3 : ℚ) * (2 / 11) = 4 / 33 ∧ (0 : ℚ) < 4 / 33 := by norm_num
-- Top, v = 90°: ring rate 0/(4 + 0) = 0, so K = 0 and exactly one rate is 0: a trough.
example : (2 / 3 : ℚ) * (0 / (4 + 3 / 2 * 0)) = 0 ∧ (2 / 3 : ℚ) ≠ 0 := by norm_num
-- Hole edge, v = 180°: ring rate -1/(4 - 1.5) = -2/5 per mm (-0.4).
example : (-1 : ℚ) / (4 + 3 / 2 * (-1)) = -2 / 5 := by norm_num
-- Hole edge: K = (2/3)(-2/5) = -4/15 per mm² (-0.266667), negative, so a saddle.
example : (2 / 3 : ℚ) * (-2 / 5) = -4 / 15 ∧ (-4 / 15 : ℚ) < 0 := by norm_num
-- Hole edge: H = (2/3 - 2/5)/2 = 2/15 per mm (0.133333) is positive, yet the point is a saddle.
example : ((2 / 3 : ℚ) + (-2 / 5)) / 2 = 2 / 15 ∧ (0 : ℚ) < 2 / 15 := by norm_num
-- Straight cuts at the hole edge: tan² θ = (2/3)/(2/5) = 5/3.
example : (2 / 3 : ℚ) / (2 / 5) = 5 / 3 := by norm_num
-- Farthest point 5.5 mm from the centre: 1/5.5 = 2/11, exactly the outer-edge ring rate, and 2/3 > 2/11.
example : (1 : ℚ) / (11 / 2) = 2 / 11 ∧ (2 / 11 : ℚ) < 2 / 3 := by norm_num
-- Ring 2(4 + 1.5) = 11 mm across, hole 2(4 - 1.5) = 5 mm across.
example : 2 * ((4 : ℚ) + 3 / 2) = 11 ∧ 2 * ((4 : ℚ) - 3 / 2) = 5 := by norm_num

#print axioms dome_point_lies_on_one_side_of_tangent_plane
#print axioms saddle_point_crosses_tangent_plane
#print axioms euler_normal_curvature_formula
