-- Tangent planes: a surface whose two slopes exist near a point and are continuous there is differentiable, the two slopes are the only possible plane, and the crease xy/sqrt(x^2+y^2) has both slopes zero yet no tangent plane.
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Filter Topology

/-- The plane's error per metre of step: for a step `(h, k)` from `(a, b)`, the true height minus
the plane `f(a,b) + A h + B k`, divided by the step length `ρ = √(h² + k²)`. -/
noncomputable def planeErrorRatio (f : ℝ × ℝ → ℝ) (a b A B : ℝ) (s : ℝ × ℝ) : ℝ :=
  (f (a + s.1, b + s.2) - (f (a, b) + A * s.1 + B * s.2)) / Real.sqrt (s.1 ^ 2 + s.2 ^ 2)

/-- Continuous slopes guarantee the tangent plane. If the east slope `fx` and the north slope `fy`
exist at every point near `(a, b)` and both are continuous at `(a, b)`, then the plane built from
the two slopes at `(a, b)` passes the test: its error divided by the step length heads for zero
as the step shrinks, from every direction at once. -/
theorem continuous_partials_imp_differentiable (f fx fy : ℝ × ℝ → ℝ) (a b : ℝ)
    (hslopes : ∀ᶠ p in 𝓝 (a, b),
      HasDerivAt (fun x => f (x, p.2)) (fx p) p.1 ∧ HasDerivAt (fun y => f (p.1, y)) (fy p) p.2)
    (hfx : ContinuousAt fx (a, b)) (hfy : ContinuousAt fy (a, b)) :
    Tendsto (planeErrorRatio f a b (fx (a, b)) (fy (a, b))) (𝓝[≠] 0) (𝓝 0) := by
  rw [Metric.tendsto_nhdsWithin_nhds]
  intro ε hε
  obtain ⟨r, hr, hR⟩ := Metric.eventually_nhds_iff.1 hslopes
  obtain ⟨δ1, hδ1, h1⟩ := Metric.continuousAt_iff.1 hfx (ε / 4) (by positivity)
  obtain ⟨δ2, hδ2, h2⟩ := Metric.continuousAt_iff.1 hfy (ε / 4) (by positivity)
  refine ⟨min r (min δ1 δ2), by positivity, ?_⟩
  rintro ⟨h, k⟩ - hs
  have hd : dist (h, k) (0 : ℝ × ℝ) < min r (min δ1 δ2) := hs
  rw [Prod.dist_eq] at hd
  simp only [Real.dist_eq, Prod.fst_zero, Prod.snd_zero, sub_zero] at hd
  have hh : |h| < min r (min δ1 δ2) := lt_of_le_of_lt (le_max_left _ _) hd
  have hk : |k| < min r (min δ1 δ2) := lt_of_le_of_lt (le_max_right _ _) hd
  set δ := min r (min δ1 δ2) with hδ
  have hδr : δ ≤ r := min_le_left _ _
  have hδ1' : δ ≤ δ1 := le_trans (min_le_right _ _) (min_le_left _ _)
  have hδ2' : δ ≤ δ2 := le_trans (min_le_right _ _) (min_le_right _ _)
  -- north leg
  have hA : ‖(f (a + h, b + k) - fy (a, b) * (b + k)) - (f (a + h, b) - fy (a, b) * b)‖
      ≤ ε / 4 * ‖(b + k) - b‖ := by
    apply Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
      (f := fun y => f (a + h, y) - fy (a, b) * y) (f' := fun y => fy (a + h, y) - fy (a, b))
      (s := Metric.ball b δ)
    · intro y hy
      have hy' : |y - b| < δ := by rw [Metric.mem_ball, Real.dist_eq] at hy; exact hy
      have hp : dist (a + h, y) (a, b) < r := by
        rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq]
        simp only [add_sub_cancel_left]
        exact lt_of_lt_of_le (max_lt hh hy') hδr
      have := (hR hp).2
      exact ((this.sub ((hasDerivAt_id y).const_mul (fy (a, b)))).congr_deriv
        (by simp)).hasDerivWithinAt
    · intro y hy
      have hy' : |y - b| < δ := by rw [Metric.mem_ball, Real.dist_eq] at hy; exact hy
      have hp : dist (a + h, y) (a, b) < δ2 := by
        rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq]
        simp only [add_sub_cancel_left]
        exact lt_of_lt_of_le (max_lt hh hy') hδ2'
      have := h2 hp
      rw [Real.dist_eq] at this
      rw [Real.norm_eq_abs]; exact this.le
    · exact convex_ball b δ
    · exact Metric.mem_ball_self (by positivity)
    · rw [Metric.mem_ball, Real.dist_eq]; simpa using hk
  -- east leg
  have hB : ‖(f (a + h, b) - fx (a, b) * (a + h)) - (f (a, b) - fx (a, b) * a)‖
      ≤ ε / 4 * ‖(a + h) - a‖ := by
    apply Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
      (f := fun x => f (x, b) - fx (a, b) * x) (f' := fun x => fx (x, b) - fx (a, b))
      (s := Metric.ball a δ)
    · intro x hx
      have hx' : |x - a| < δ := by rw [Metric.mem_ball, Real.dist_eq] at hx; exact hx
      have hp : dist (x, b) (a, b) < r := by
        rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq]
        simp only [sub_self, abs_zero]
        exact lt_of_lt_of_le (max_lt hx' (by positivity)) hδr
      have := (hR hp).1
      exact ((this.sub ((hasDerivAt_id x).const_mul (fx (a, b)))).congr_deriv
        (by simp)).hasDerivWithinAt
    · intro x hx
      have hx' : |x - a| < δ := by rw [Metric.mem_ball, Real.dist_eq] at hx; exact hx
      have hp : dist (x, b) (a, b) < δ1 := by
        rw [Prod.dist_eq, Real.dist_eq, Real.dist_eq]
        simp only [sub_self, abs_zero]
        exact lt_of_lt_of_le (max_lt hx' (by positivity)) hδ1'
      have := h1 hp
      rw [Real.dist_eq] at this
      rw [Real.norm_eq_abs]; exact this.le
    · exact convex_ball a δ
    · exact Metric.mem_ball_self (by positivity)
    · rw [Metric.mem_ball, Real.dist_eq]; simpa using hh
  simp only [Real.norm_eq_abs, add_sub_cancel_left] at hA hB
  have hnum : |f (a + h, b + k) - (f (a, b) + fx (a, b) * h + fy (a, b) * k)|
      ≤ ε / 4 * |k| + ε / 4 * |h| := by
    have e : f (a + h, b + k) - (f (a, b) + fx (a, b) * h + fy (a, b) * k) =
        ((f (a + h, b + k) - fy (a, b) * (b + k)) - (f (a + h, b) - fy (a, b) * b)) +
        ((f (a + h, b) - fx (a, b) * (a + h)) - (f (a, b) - fx (a, b) * a)) := by ring
    rw [e]
    exact (abs_add_le _ _).trans (add_le_add hA hB)
  have hhρ : |h| ≤ Real.sqrt (h ^ 2 + k ^ 2) := Real.abs_le_sqrt (by nlinarith)
  have hkρ : |k| ≤ Real.sqrt (h ^ 2 + k ^ 2) := Real.abs_le_sqrt (by nlinarith)
  rw [Real.dist_eq, sub_zero]
  unfold planeErrorRatio
  simp only
  rcases (Real.sqrt_nonneg (h ^ 2 + k ^ 2)).eq_or_lt with h0 | hpos
  · rw [← h0, div_zero, abs_zero]; exact hε
  · rw [abs_div, abs_of_pos hpos, div_lt_iff₀ hpos]
    nlinarith [abs_nonneg h, abs_nonneg k]

/-- If a plane works, its slopes are the partial derivatives. If some plane `f(a,b) + A h + B k`
passes the test at `(a, b)`, then the east slope at `(a, b)` exists and equals `A`, and the north
slope exists and equals `B`. -/
theorem tangent_plane_slopes_are_partials (f : ℝ × ℝ → ℝ) (a b A B : ℝ)
    (hplane : Tendsto (planeErrorRatio f a b A B) (𝓝[≠] 0) (𝓝 0)) :
    HasDerivAt (fun x => f (x, b)) A a ∧ HasDerivAt (fun y => f (a, y)) B b := by
  have hx : Tendsto (fun t : ℝ => ((t, 0) : ℝ × ℝ)) (𝓝[≠] 0) (𝓝[≠] 0) := by
    apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
    · have : Tendsto (fun t : ℝ => ((t, 0) : ℝ × ℝ)) (𝓝 0) (𝓝 ((0 : ℝ), (0 : ℝ))) :=
        (continuous_id.prodMk continuous_const).tendsto' _ _ (by simp)
      exact this.mono_left nhdsWithin_le_nhds
    · filter_upwards [self_mem_nhdsWithin] with t ht
      simp only [Set.mem_compl_iff, Set.mem_singleton_iff] at ht ⊢
      intro h; exact ht (congrArg Prod.fst h)
  have hy : Tendsto (fun t : ℝ => ((0, t) : ℝ × ℝ)) (𝓝[≠] 0) (𝓝[≠] 0) := by
    apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
    · have : Tendsto (fun t : ℝ => ((0, t) : ℝ × ℝ)) (𝓝 0) (𝓝 ((0 : ℝ), (0 : ℝ))) :=
        (continuous_const.prodMk continuous_id).tendsto' _ _ (by simp)
      exact this.mono_left nhdsWithin_le_nhds
    · filter_upwards [self_mem_nhdsWithin] with t ht
      simp only [Set.mem_compl_iff, Set.mem_singleton_iff] at ht ⊢
      intro h; exact ht (congrArg Prod.snd h)
  constructor
  · rw [hasDerivAt_iff_tendsto_slope_zero, ← tendsto_sub_nhds_zero_iff]
    apply squeeze_zero_norm' _ ((hplane.comp hx).norm.trans (by simp))
    filter_upwards [self_mem_nhdsWithin] with t ht
    have ht' : t ≠ 0 := ht
    simp only [Function.comp, planeErrorRatio, smul_eq_mul, Real.norm_eq_abs, add_zero,
      mul_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, Real.sqrt_sq_eq_abs]
    rw [abs_div, abs_abs]
    rw [show t⁻¹ * (f (a + t, b) - f (a, b)) - A = (f (a + t, b) - (f (a, b) + A * t)) / t by
      field_simp; ring]
    rw [abs_div]
  · rw [hasDerivAt_iff_tendsto_slope_zero, ← tendsto_sub_nhds_zero_iff]
    apply squeeze_zero_norm' _ ((hplane.comp hy).norm.trans (by simp))
    filter_upwards [self_mem_nhdsWithin] with t ht
    have ht' : t ≠ 0 := ht
    simp only [Function.comp, planeErrorRatio, smul_eq_mul, Real.norm_eq_abs, add_zero,
      mul_zero, zero_add, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow,
      Real.sqrt_sq_eq_abs]
    rw [abs_div, abs_abs]
    rw [show t⁻¹ * (f (a, b + t) - f (a, b)) - B = (f (a, b + t) - (f (a, b) + B * t)) / t by
      field_simp; ring]
    rw [abs_div]

/-- A crease the slopes cannot see. The surface `g(x, y) = xy / √(x² + y²)`, height 0 at the origin,
is continuous and has east and north slopes both 0 at the origin, yet no plane at the origin passes
the test. -/
theorem crease_has_slopes_but_no_tangent_plane :
    let g : ℝ × ℝ → ℝ := fun p => p.1 * p.2 / Real.sqrt (p.1 ^ 2 + p.2 ^ 2)
    Continuous g ∧ HasDerivAt (fun x => g (x, 0)) 0 0 ∧ HasDerivAt (fun y => g (0, y)) 0 0 ∧
      ¬ ∃ A B : ℝ, Tendsto (planeErrorRatio g 0 0 A B) (𝓝[≠] 0) (𝓝 0) := by
  intro g
  have hgx : (fun x => g (x, 0)) = fun _ => (0 : ℝ) := by funext x; simp [g]
  have hgy : (fun y => g (0, y)) = fun _ => (0 : ℝ) := by funext y; simp [g]
  have dx : HasDerivAt (fun x => g (x, 0)) 0 0 := by rw [hgx]; exact hasDerivAt_const _ _
  have dy : HasDerivAt (fun y => g (0, y)) 0 0 := by rw [hgy]; exact hasDerivAt_const _ _
  refine ⟨?_, dx, dy, ?_⟩
  · rw [continuous_iff_continuousAt]
    intro p
    by_cases hp : p = 0
    · subst hp
      have hg0 : g 0 = 0 := by simp [g]
      rw [ContinuousAt, hg0]
      have hfst : Tendsto (fun q : ℝ × ℝ => |q.1|) (𝓝 0) (𝓝 0) :=
        continuous_fst.abs.tendsto' _ _ (by simp)
      refine squeeze_zero_norm (fun q => ?_) hfst
      show |q.1 * q.2 / Real.sqrt (q.1 ^ 2 + q.2 ^ 2)| ≤ |q.1|
      rcases (Real.sqrt_nonneg (q.1 ^ 2 + q.2 ^ 2)).eq_or_lt with h0 | hpos
      · rw [← h0, div_zero, abs_zero]; exact abs_nonneg _
      · rw [abs_div, abs_of_pos hpos, div_le_iff₀ hpos, abs_mul]
        exact mul_le_mul_of_nonneg_left (Real.abs_le_sqrt (by nlinarith [sq_nonneg q.1]))
          (abs_nonneg _)
    · have hS : Real.sqrt (p.1 ^ 2 + p.2 ^ 2) ≠ 0 := by
        intro h0
        rw [Real.sqrt_eq_zero (by positivity)] at h0
        apply hp
        have h1 : p.1 = 0 := by nlinarith [sq_nonneg p.1, sq_nonneg p.2]
        have h2 : p.2 = 0 := by nlinarith [sq_nonneg p.1, sq_nonneg p.2]
        exact Prod.ext h1 h2
      show ContinuousAt (fun p : ℝ × ℝ => p.1 * p.2 / Real.sqrt (p.1 ^ 2 + p.2 ^ 2)) p
      exact ContinuousAt.div (by fun_prop) (by fun_prop) hS
  · rintro ⟨A, B, hT⟩
    obtain ⟨hA, hB⟩ := tangent_plane_slopes_are_partials g 0 0 A B hT
    have hA0 : A = 0 := hA.unique dx
    have hB0 : B = 0 := hB.unique dy
    subst hA0 hB0
    have hd : Tendsto (fun t : ℝ => ((t, t) : ℝ × ℝ)) (𝓝[≠] 0) (𝓝[≠] 0) := by
      apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
      · have : Tendsto (fun t : ℝ => ((t, t) : ℝ × ℝ)) (𝓝 0) (𝓝 ((0 : ℝ), (0 : ℝ))) :=
          (continuous_id.prodMk continuous_id).tendsto' _ _ (by simp)
        exact this.mono_left nhdsWithin_le_nhds
      · filter_upwards [self_mem_nhdsWithin] with t ht
        simp only [Set.mem_compl_iff, Set.mem_singleton_iff] at ht ⊢
        intro h; exact ht (congrArg Prod.fst h)
    have hhalf : Tendsto (planeErrorRatio g 0 0 0 0 ∘ fun t : ℝ => ((t, t) : ℝ × ℝ))
        (𝓝[≠] 0) (𝓝 (1 / 2)) := by
      apply tendsto_const_nhds.congr'
      filter_upwards [self_mem_nhdsWithin] with t ht
      have ht' : t ≠ 0 := ht
      have hpos : 0 < t ^ 2 + t ^ 2 := by positivity
      simp only [Function.comp, planeErrorRatio, g, zero_add, mul_zero, add_zero, zero_mul,
        ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, Real.sqrt_zero, div_zero,
        sub_zero, div_div, Real.mul_self_sqrt hpos.le]
      field_simp
      ring
    have := tendsto_nhds_unique hhalf (hT.comp hd)
    norm_num at this

/-! The card's hill, `f(x, y) = 80 - x²/1000 - xy/2000 - y²/500`, checked with exact fractions. -/

-- height at the surveyor: f(100, 50) = 62.5 m
example : (80 : ℚ) - 100 ^ 2 / 1000 - 100 * 50 / 2000 - 50 ^ 2 / 500 = 125 / 2 := by norm_num
-- slope east: -0.002 × 100 - 0.0005 × 50 = -0.225
example : -(2 : ℚ) / 1000 * 100 - 5 / 10000 * 50 = -225 / 1000 := by norm_num
-- slope north: -0.0005 × 100 - 0.004 × 50 = -0.25
example : -(5 : ℚ) / 10000 * 100 - 4 / 1000 * 50 = -1 / 4 := by norm_num
-- plane at (110, 70): 62.5 + 10 × (-0.225) + 20 × (-0.25) = 55.25 m
example : (125 : ℚ) / 2 + 10 * (-225 / 1000) + 20 * (-1 / 4) = 5525 / 100 := by norm_num
-- hill at (110, 70): f(110, 70) = 54.25 m
example : (80 : ℚ) - 110 ^ 2 / 1000 - 110 * 70 / 2000 - 70 ^ 2 / 500 = 5425 / 100 := by norm_num
-- remainder: -(0.001 × 10² + 0.0005 × 10 × 20 + 0.002 × 20²) = -1.0 m, and hill minus plane agrees
example : -((1 : ℚ) / 1000 * 10 ^ 2 + 5 / 10000 * 10 * 20 + 2 / 1000 * 20 ^ 2) = -1 := by norm_num
example : (5425 : ℚ) / 100 - 5525 / 100 = -1 := by norm_num
-- two legs: east -2.35 = 10 × -0.235 (slope at (105, 50)), north -5.9 = 20 × -0.295 (slope at (110, 60))
example : ((80 : ℚ) - 110 ^ 2 / 1000 - 110 * 50 / 2000 - 50 ^ 2 / 500) - 125 / 2 = -235 / 100 ∧
    (-(2 : ℚ) / 1000 * 105 - 5 / 10000 * 50) * 10 = -235 / 100 := by norm_num
example : (5425 : ℚ) / 100 - (80 - 110 ^ 2 / 1000 - 110 * 50 / 2000 - 50 ^ 2 / 500) = -59 / 10 ∧
    (-(5 : ℚ) / 10000 * 110 - 4 / 1000 * 60) * 20 = -59 / 10 := by norm_num
-- the mistake: dropping the shift gives 62.5 - 0.225 × 110 - 0.25 × 70 = 20.25 m
example : (125 : ℚ) / 2 - 225 / 1000 * 110 - 1 / 4 * 70 = 2025 / 100 := by norm_num

#print axioms continuous_partials_imp_differentiable
#print axioms tangent_plane_slopes_are_partials
#print axioms crease_has_slopes_but_no_tangent_plane
