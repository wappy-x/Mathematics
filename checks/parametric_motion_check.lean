-- Parametric motion: velocity is the pair of coordinate rates, speed is the limit of distance over time by Pythagoras, and the path's slope is dy/dt over dx/dt wherever dx/dt is not zero.
import Mathlib.Analysis.Calculus.Darboux
import Mathlib.Analysis.Calculus.Deriv.Inverse
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Filter Topology

/-- The slope rule. Let a point move with across-position `x t` and height `y t`, both with
rates at every time of an open interval, and let the across-rate dx/dt never be zero there.
Then the height is a function `Y` of the across-position alone (y(t) = Y(x(t))), and the
path's slope dY/dx at x(t) is (dy/dt) ÷ (dx/dt). -/
theorem slope_eq_up_rate_div_across_rate (x y : ℝ → ℝ) (a b : ℝ)
    (hx : ∀ t ∈ Set.Ioo a b, DifferentiableAt ℝ x t)
    (hy : ∀ t ∈ Set.Ioo a b, DifferentiableAt ℝ y t)
    (hx0 : ∀ t ∈ Set.Ioo a b, deriv x t ≠ 0) :
    ∃ Y : ℝ → ℝ, (∀ t ∈ Set.Ioo a b, y t = Y (x t)) ∧
      ∀ t ∈ Set.Ioo a b, HasDerivAt Y (deriv y t / deriv x t) (x t) := by
  classical
  have hcont : ContinuousOn x (Set.Ioo a b) :=
    fun t ht => (hx t ht).continuousAt.continuousWithinAt
  have hmono : StrictMonoOn x (Set.Ioo a b) ∨ StrictAntiOn x (Set.Ioo a b) := by
    rcases hasDerivWithinAt_forall_lt_or_forall_gt_of_forall_ne (convex_Ioo a b)
      (fun t ht => (hx t ht).hasDerivAt.hasDerivWithinAt) (m := 0) hx0 with h | h
    · right
      exact strictAntiOn_of_deriv_neg (convex_Ioo a b) hcont (by simpa [interior_Ioo] using h)
    · left
      exact strictMonoOn_of_deriv_pos (convex_Ioo a b) hcont (by simpa [interior_Ioo] using h)
  have hinj : Set.InjOn x (Set.Ioo a b) := hmono.elim (·.injOn) (·.injOn)
  have hg : ∀ u ∈ Set.Ioo a b, Function.invFunOn x (Set.Ioo a b) (x u) = u := fun u hu =>
    hinj (Function.invFunOn_mem ⟨u, hu, rfl⟩) hu (Function.invFunOn_eq ⟨u, hu, rfl⟩)
  have hkey : ∀ t ∈ Set.Ioo a b, ∀ t1 t2, a < t1 → t1 < t → t < t2 → t2 < b →
      x '' Set.Icc t1 t2 ∈ 𝓝 (x t) := by
    intro t ht t1 t2 h1 h2 h3 h4
    have hsub : Set.Icc t1 t2 ⊆ Set.Ioo a b := Set.Icc_subset_Ioo h1 h4
    have hivt : Set.uIcc (x t1) (x t2) ⊆ x '' Set.Icc t1 t2 := by
      have := intermediate_value_uIcc (f := x) (a := t1) (b := t2)
        (by rw [Set.uIcc_of_le (by linarith)]; exact hcont.mono hsub)
      rwa [Set.uIcc_of_le (by linarith : t1 ≤ t2)] at this
    apply Filter.mem_of_superset _ hivt
    have ht1 : t1 ∈ Set.Ioo a b := ⟨h1, by linarith [ht.2]⟩
    have ht2 : t2 ∈ Set.Ioo a b := ⟨by linarith [ht.1], h4⟩
    rcases hmono with hm | hm
    · rw [Set.uIcc_of_le (hm ht1 ht2 (by linarith)).le]
      exact Icc_mem_nhds (hm ht1 ht h2) (hm ht ht2 h3)
    · rw [Set.uIcc_of_ge (hm ht1 ht2 (by linarith)).le]
      exact Icc_mem_nhds (hm ht ht2 h3) (hm ht1 ht h2)
  refine ⟨y ∘ Function.invFunOn x (Set.Ioo a b), fun t ht => by simp [hg t ht], ?_⟩
  intro t ht
  have hev : ∀ᶠ u in 𝓝 (x t), x (Function.invFunOn x (Set.Ioo a b) u) = u := by
    filter_upwards [hkey t ht ((a + t) / 2) ((t + b) / 2) (by linarith [ht.1])
      (by linarith [ht.1]) (by linarith [ht.2]) (by linarith [ht.2])] with u hu
    obtain ⟨r, hr, rfl⟩ := hu
    exact Function.invFunOn_eq ⟨r, ⟨by linarith [hr.1, ht.1], by linarith [hr.2, ht.2]⟩, rfl⟩
  have hgc : ContinuousAt (Function.invFunOn x (Set.Ioo a b)) (x t) := by
    rw [ContinuousAt, hg t ht, Metric.tendsto_nhds]
    intro ε hε
    have hA : a < max (t - ε / 2) ((a + t) / 2) := lt_max_of_lt_right (by linarith [ht.1])
    have hB : max (t - ε / 2) ((a + t) / 2) < t := max_lt (by linarith) (by linarith [ht.1])
    have hC : t < min (t + ε / 2) ((t + b) / 2) := lt_min (by linarith) (by linarith [ht.2])
    have hD : min (t + ε / 2) ((t + b) / 2) < b := min_lt_of_right_lt (by linarith [ht.2])
    filter_upwards [hkey t ht _ _ hA hB hC hD] with u hu
    obtain ⟨r, hr, rfl⟩ := hu
    rw [hg r ⟨by linarith [hr.1], by linarith [hr.2]⟩, Real.dist_eq, abs_sub_lt_iff]
    have := le_max_left (t - ε / 2) ((a + t) / 2)
    have := min_le_left (t + ε / 2) ((t + b) / 2)
    constructor <;> linarith [hr.1, hr.2]
  have hgd : HasDerivAt (Function.invFunOn x (Set.Ioo a b)) (deriv x t)⁻¹ (x t) :=
    HasDerivAt.of_local_left_inverse hgc (by rw [hg t ht]; exact (hx t ht).hasDerivAt)
      (hx0 t ht) hev
  have hy' : HasDerivAt y (deriv y t) (Function.invFunOn x (Set.Ioo a b) (x t)) := by
    rw [hg t ht]; exact (hy t ht).hasDerivAt
  rw [div_eq_mul_inv]
  exact hy'.comp (x t) hgd

/-- Velocity is componentwise: the position pair (x(t), y(t)) has velocity (vx, vy) at time t
exactly when x has rate vx and y has rate vy at t. -/
theorem velocity_iff_componentwise (x y : ℝ → ℝ) (t vx vy : ℝ) :
    HasDerivAt (fun s => (x s, y s)) (vx, vy) t ↔ HasDerivAt x vx t ∧ HasDerivAt y vy t := by
  constructor
  · intro h
    have h1 := (hasFDerivAt_fst (𝕜 := ℝ) (p := (x t, y t))).comp_hasDerivAt t h
    have h2 := (hasFDerivAt_snd (𝕜 := ℝ) (p := (x t, y t))).comp_hasDerivAt t h
    exact ⟨h1, h2⟩
  · rintro ⟨h1, h2⟩
    exact h1.prodMk h2

/-- Speed is the velocity's length: if x has rate vx and y has rate vy at time t, then the
straight-line distance covered in a short time h, divided by the time |h|, tends to
√(vx² + vy²) as h tends to 0. -/
theorem distance_over_time_tendsto_speed (x y : ℝ → ℝ) (t vx vy : ℝ)
    (hx : HasDerivAt x vx t) (hy : HasDerivAt y vy t) :
    Tendsto (fun h => Real.sqrt ((x (t + h) - x t) ^ 2 + (y (t + h) - y t) ^ 2) / |h|)
      (𝓝[≠] 0) (𝓝 (Real.sqrt (vx ^ 2 + vy ^ 2))) := by
  have h1 := hasDerivAt_iff_tendsto_slope_zero.mp hx
  have h2 := hasDerivAt_iff_tendsto_slope_zero.mp hy
  have hc : Tendsto (fun h : ℝ => Real.sqrt ((h⁻¹ • (x (t + h) - x t)) ^ 2
      + (h⁻¹ • (y (t + h) - y t)) ^ 2)) (𝓝[≠] 0) (𝓝 (Real.sqrt (vx ^ 2 + vy ^ 2))) :=
    ((h1.pow 2).add (h2.pow 2)).sqrt
  refine hc.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with h hh
  have hh' : h ≠ 0 := hh
  simp only [smul_eq_mul]
  rw [← Real.sqrt_sq_eq_abs, ← Real.sqrt_div' _ (sq_nonneg h)]
  congr 1
  field_simp

-- Speed at release: 12 across and 16 up give 20, since 12² + 16² = 20².
example : (12 : ℕ) ^ 2 + 16 ^ 2 = 20 ^ 2 := by norm_num
-- Speed at the top: velocity (12, 0) has length 12.
example : (12 : ℕ) ^ 2 + 0 ^ 2 = 12 ^ 2 := by norm_num
-- The mistake of adding the parts: 12 + 16 = 28, not 20.
example : (12 : ℕ) + 16 = 28 ∧ (12 : ℕ) + 16 ≠ 20 := by decide
-- The top's height 256 / 19.6 comes from w² = 16² = 256.
example : (16 : ℕ) ^ 2 = 256 := by norm_num

#print axioms slope_eq_up_rate_div_across_rate
#print axioms velocity_iff_componentwise
#print axioms distance_over_time_tendsto_speed
