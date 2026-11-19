-- Riemannian metric: on the round globe of radius R the shortest path between two places has length R times their central angle, the metric in the chart (φ, θ) is ds² = R² dφ² + R² sin²φ dθ², and a change of chart changes the table g to Jᵀ g J without changing any length.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Geometry.Euclidean.Angle.Unoriented.TriangleInequality
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Prod

open Matrix

/-- Chord against angle: on a sphere of radius `R`, two points at angle `θ` have chord at least
`R θ (1 - θ²/24)`. -/
theorem angle_mul_le_chord (R : ℝ) (hR : 0 < R) (x y : EuclideanSpace ℝ (Fin 3))
    (hx : ‖x‖ = R) (hy : ‖y‖ = R) :
    InnerProductGeometry.angle x y * (1 - InnerProductGeometry.angle x y ^ 2 / 24) ≤
      ‖x - y‖ / R := by
  set θ := InnerProductGeometry.angle x y with hθ
  have h0 : 0 ≤ θ := InnerProductGeometry.angle_nonneg x y
  have hpi : θ ≤ Real.pi := InnerProductGeometry.angle_le_pi x y
  have hin : inner ℝ x y = Real.cos θ * (R * R) := by
    rw [← InnerProductGeometry.cos_angle_mul_norm_mul_norm, hx, hy]
  have hcos : Real.cos θ = 1 - 2 * Real.sin (θ / 2) ^ 2 := by
    have := Real.cos_two_mul (θ / 2)
    have h2 := Real.sin_sq_add_cos_sq (θ / 2)
    rw [show 2 * (θ / 2) = θ by ring] at this
    linarith
  have hs0 : 0 ≤ Real.sin (θ / 2) :=
    Real.sin_nonneg_of_nonneg_of_le_pi (by linarith) (by linarith)
  have hchord : ‖x - y‖ = 2 * R * Real.sin (θ / 2) := by
    have hsq : ‖x - y‖ ^ 2 = (2 * R * Real.sin (θ / 2)) ^ 2 := by
      rw [norm_sub_sq_real, hin, hx, hy, hcos]; ring
    exact (pow_left_inj₀ (norm_nonneg _) (by positivity) two_ne_zero).mp hsq
  rw [hchord, show 2 * R * Real.sin (θ / 2) / R = 2 * Real.sin (θ / 2) by field_simp]
  rcases h0.eq_or_lt with h | h
  · rw [← h]; simp
  · have := Real.sin_gt_sub_cube (x := θ / 2) (by linarith)
    nlinarith

open Filter Topology in
/-- The lower bound: a `C¹` path on the sphere of radius `R` starting at `p` has length at least
`R` times the angle from `p` to its end. -/
theorem radius_mul_angle_le_length (R : ℝ) (hR : 0 < R) (p : EuclideanSpace ℝ (Fin 3))
    (γ : ℝ → EuclideanSpace ℝ (Fin 3)) (hγ : ContDiff ℝ 1 γ) (h0 : γ 0 = p)
    (hS : ∀ t ∈ Set.Icc (0 : ℝ) 1, ‖γ t‖ = R) :
    R * InnerProductGeometry.angle p (γ 1) ≤ ∫ t in (0 : ℝ)..1, ‖deriv γ t‖ := by
  have hd : Differentiable ℝ γ := hγ.differentiable one_ne_zero
  have hcd : Continuous (deriv γ) := (contDiff_one_iff_deriv.mp hγ).2
  have hc : Continuous γ := hd.continuous
  have hne : ∀ t ∈ Set.Icc (0 : ℝ) 1, γ t ≠ 0 := by
    intro t ht h; have := hS t ht; rw [h, norm_zero] at this; linarith
  have hp : p ≠ 0 := h0 ▸ hne 0 ⟨le_rfl, zero_le_one⟩
  set f : ℝ → ℝ := fun t => InnerProductGeometry.angle p (γ t) with hf
  set B : ℝ → ℝ := fun t => (∫ s in (0 : ℝ)..t, ‖deriv γ s‖) / R with hB
  have hcn : Continuous fun s => ‖deriv γ s‖ := hcd.norm
  have hBd : ∀ x, HasDerivAt B (‖deriv γ x‖ / R) x := fun x =>
    ((hcn.integral_hasStrictDerivAt 0 x).hasDerivAt).div_const R
  have key : ∀ ⦃x⦄, x ∈ Set.Icc (0 : ℝ) 1 → f x ≤ B x := by
    refine image_le_of_liminf_slope_right_le_deriv_boundary (B' := fun x => ‖deriv γ x‖ / R)
      ?_ ?_ ?_ ?_ ?_
    · intro t ht
      have : ContinuousAt (fun t => InnerProductGeometry.angle p (γ t)) t :=
        ContinuousAt.comp (g := fun y : EuclideanSpace ℝ (Fin 3) × EuclideanSpace ℝ (Fin 3) =>
            InnerProductGeometry.angle y.1 y.2) (f := fun t => (p, γ t))
          (InnerProductGeometry.continuousAt_angle (x := (p, γ t)) hp (hne t ht))
          (continuousAt_const.prodMk hc.continuousAt)
      exact this.continuousWithinAt
    · simp [hf, hB, h0, InnerProductGeometry.angle_self hp]
    · intro t _; exact (hBd t).continuousAt.continuousWithinAt
    · intro t _; exact (hBd t).hasDerivWithinAt
    · intro x hx r hr
      apply Eventually.frequently
      have hxS : ‖γ x‖ = R := hS x (Set.Ico_subset_Icc_self hx)
      have hx0 : γ x ≠ 0 := hne x (Set.Ico_subset_Icc_self hx)
      -- slope of γ tends to γ'(x)
      have hsl : Tendsto (fun z => ‖slope γ x z‖ / R) (𝓝[>] x) (𝓝 (‖deriv γ x‖ / R)) :=
        ((((hd x).hasDerivAt.tendsto_slope).mono_left
          (nhdsWithin_mono _ (fun z hz => Set.mem_compl_singleton_iff.mpr (ne_of_gt hz)))).norm).div_const R
      -- the angle from γ x to γ z tends to 0
      have hang : Tendsto (fun z => InnerProductGeometry.angle (γ x) (γ z)) (𝓝[>] x) (𝓝 0) := by
        have : ContinuousAt (fun z => InnerProductGeometry.angle (γ x) (γ z)) x :=
          ContinuousAt.comp (g := fun y : EuclideanSpace ℝ (Fin 3) × EuclideanSpace ℝ (Fin 3) =>
            InnerProductGeometry.angle y.1 y.2) (f := fun z => (γ x, γ z))
          (InnerProductGeometry.continuousAt_angle (x := (γ x, γ x)) hx0 hx0)
          (continuousAt_const.prodMk hc.continuousAt)
        have := this.tendsto
        rw [InnerProductGeometry.angle_self hx0] at this
        exact this.mono_left nhdsWithin_le_nhds
      have hfac : Tendsto (fun z => 1 - InnerProductGeometry.angle (γ x) (γ z) ^ 2 / 24)
          (𝓝[>] x) (𝓝 1) := by
        have := ((hang.pow 2).div_const 24).const_sub 1
        simpa using this
      have hQ : Tendsto (fun z => ‖slope γ x z‖ / R /
          (1 - InnerProductGeometry.angle (γ x) (γ z) ^ 2 / 24)) (𝓝[>] x)
          (𝓝 (‖deriv γ x‖ / R)) := by
        have := hsl.div hfac one_ne_zero
        rw [div_one] at this
        exact this
      have e1 : ∀ᶠ z in 𝓝[>] x, ‖slope γ x z‖ / R /
          (1 - InnerProductGeometry.angle (γ x) (γ z) ^ 2 / 24) < r :=
        hQ.eventually (gt_mem_nhds hr)
      have e2 : ∀ᶠ z in 𝓝[>] x, 1 / 2 < 1 - InnerProductGeometry.angle (γ x) (γ z) ^ 2 / 24 :=
        hfac.eventually (lt_mem_nhds (by norm_num))
      have e3 : ∀ᶠ z in 𝓝[>] x, z ∈ Set.Ioo x 1 := Ioo_mem_nhdsGT hx.2
      filter_upwards [e1, e2, e3] with z hz1 hz2 hz3
      have hzS : ‖γ z‖ = R := hS z ⟨by linarith [hx.1, hz3.1], hz3.2.le⟩
      have hzx : 0 < z - x := sub_pos.mpr hz3.1
      set θ := InnerProductGeometry.angle (γ x) (γ z)
      have htri : f z - f x ≤ θ := by
        have := InnerProductGeometry.angle_le_angle_add_angle p (γ x) (γ z)
        simp only [hf]; linarith
      have hch := angle_mul_le_chord R hR (γ x) (γ z) hxS hzS
      have hnorm : ‖slope γ x z‖ = ‖γ z - γ x‖ / (z - x) := by
        rw [slope_def_module, norm_smul, norm_inv, Real.norm_of_nonneg hzx.le, div_eq_inv_mul]
      rw [hnorm] at hz1
      rw [slope_def_field]
      have hpos : 0 < 1 - θ ^ 2 / 24 := by linarith
      have hθle : θ ≤ ‖γ x - γ z‖ / R / (1 - θ ^ 2 / 24) := by
        rw [le_div_iff₀ hpos]; exact hch
      rw [norm_sub_rev] at hθle
      calc (f z - f x) / (z - x) ≤ θ / (z - x) := div_le_div_of_nonneg_right htri hzx.le
        _ ≤ (‖γ z - γ x‖ / R / (1 - θ ^ 2 / 24)) / (z - x) :=
            div_le_div_of_nonneg_right hθle hzx.le
        _ = ‖γ z - γ x‖ / (z - x) / R / (1 - θ ^ 2 / 24) := by ring
        _ < r := hz1
  have := key (x := 1) ⟨zero_le_one, le_rfl⟩
  simp only [hf, hB] at this
  rw [le_div_iff₀ hR] at this
  linarith

/-- A vector of length `R` at right angles to a given nonzero vector of space. -/
theorem exists_orthogonal_of_norm (R : ℝ) (hR : 0 < R) (p : EuclideanSpace ℝ (Fin 3))
    (hp : p ≠ 0) : ∃ e : EuclideanSpace ℝ (Fin 3), inner ℝ p e = 0 ∧ ‖e‖ = R := by
  have : Fact (Module.finrank ℝ (EuclideanSpace ℝ (Fin 3)) = 2 + 1) :=
    ⟨finrank_euclideanSpace_fin⟩
  have hfr := Submodule.finrank_orthogonal_span_singleton (𝕜 := ℝ) (n := 2) hp
  have hne : (ℝ ∙ p)ᗮ ≠ ⊥ := by
    intro h; rw [h, finrank_bot] at hfr; norm_num at hfr
  obtain ⟨w, hw, hw0⟩ := Submodule.exists_mem_ne_zero_of_ne_bot hne
  have hwi : inner ℝ p w = 0 := Submodule.mem_orthogonal_singleton_iff_inner_right.mp hw
  refine ⟨(R / ‖w‖) • w, ?_, ?_⟩
  · rw [inner_smul_right, hwi, mul_zero]
  · rw [norm_smul, Real.norm_of_nonneg (by positivity), div_mul_cancel₀ _ (norm_ne_zero_iff.mpr hw0)]

/-- The great-circle arc: a `C¹` path on the sphere of radius `R` from `p` to `q` of length
`R` times the angle between them. -/
theorem exists_arc (R : ℝ) (hR : 0 < R) (p q : EuclideanSpace ℝ (Fin 3)) (hp : ‖p‖ = R)
    (hq : ‖q‖ = R) :
    ∃ γ : ℝ → EuclideanSpace ℝ (Fin 3), ContDiff ℝ 1 γ ∧ γ 0 = p ∧ γ 1 = q ∧
        (∀ t ∈ Set.Icc (0 : ℝ) 1, ‖γ t‖ = R) ∧
        R * InnerProductGeometry.angle p q = ∫ t in (0 : ℝ)..1, ‖deriv γ t‖ := by
  set θ := InnerProductGeometry.angle p q with hθ
  have hp0 : p ≠ 0 := by intro h; rw [h, norm_zero] at hp; linarith
  have hin : inner ℝ p q = Real.cos θ * (R * R) := by
    rw [← InnerProductGeometry.cos_angle_mul_norm_mul_norm, hp, hq]
  have hsq : ‖q - Real.cos θ • p‖ ^ 2 = R ^ 2 * Real.sin θ ^ 2 := by
    rw [norm_sub_sq_real, inner_smul_right, real_inner_comm, hin, norm_smul, hq, hp,
      Real.norm_eq_abs, mul_pow, sq_abs]
    have := Real.sin_sq_add_cos_sq θ
    linear_combination (-R ^ 2) * this
  obtain ⟨e, hpe, he, hqe⟩ : ∃ e : EuclideanSpace ℝ (Fin 3), inner ℝ p e = 0 ∧ ‖e‖ = R ∧
      q = Real.cos θ • p + Real.sin θ • e := by
    by_cases hs : Real.sin θ = 0
    · obtain ⟨e, h1, h2⟩ := exists_orthogonal_of_norm R hR p hp0
      refine ⟨e, h1, h2, ?_⟩
      rw [hs, zero_smul, add_zero]
      rw [hs] at hsq
      have : ‖q - Real.cos θ • p‖ = 0 := by
        have h' : ‖q - Real.cos θ • p‖ ^ 2 = 0 := by rw [hsq]; ring
        exact pow_eq_zero_iff (two_ne_zero) |>.mp h'
      exact sub_eq_zero.mp (norm_eq_zero.mp this)
    · refine ⟨(Real.sin θ)⁻¹ • (q - Real.cos θ • p), ?_, ?_, ?_⟩
      · rw [inner_smul_right, inner_sub_right, inner_smul_right, hin,
          real_inner_self_eq_norm_sq, hp]
        ring
      · have h1 : ‖(Real.sin θ)⁻¹ • (q - Real.cos θ • p)‖ ^ 2 = R ^ 2 := by
          rw [norm_smul, mul_pow, hsq, norm_inv, Real.norm_eq_abs, inv_pow, sq_abs]
          field_simp
        exact (pow_left_inj₀ (norm_nonneg _) hR.le two_ne_zero).mp h1
      · rw [smul_smul, mul_inv_cancel₀ hs, one_smul]; abel
  have hθ0 : 0 ≤ θ := InnerProductGeometry.angle_nonneg p q
  set γ : ℝ → EuclideanSpace ℝ (Fin 3) :=
    fun t => Real.cos (t * θ) • p + Real.sin (t * θ) • e with hγ
  have hder : ∀ t, HasDerivAt γ ((-Real.sin (t * θ) * θ) • p + (Real.cos (t * θ) * θ) • e) t := by
    intro t
    have h1 : HasDerivAt (fun t : ℝ => t * θ) θ t := by
      simpa using (hasDerivAt_id t).mul_const θ
    exact (h1.cos.smul_const p).add (h1.sin.smul_const e) |>.congr_deriv (by ring_nf)
  have hnorm : ∀ a b : ℝ, ‖a • p + b • e‖ ^ 2 = R ^ 2 * (a ^ 2 + b ^ 2) := by
    intro a b
    rw [norm_add_sq_real, inner_smul_left, inner_smul_right, hpe, norm_smul, norm_smul, hp, he,
      Real.norm_eq_abs, Real.norm_eq_abs, mul_pow, mul_pow, sq_abs, sq_abs]
    simp; ring
  have hspeed : ∀ t, ‖deriv γ t‖ = R * θ := by
    intro t
    rw [(hder t).deriv]
    have h := hnorm (-Real.sin (t * θ) * θ) (Real.cos (t * θ) * θ)
    have h2 : ‖(-Real.sin (t * θ) * θ) • p + (Real.cos (t * θ) * θ) • e‖ ^ 2 = (R * θ) ^ 2 := by
      rw [h]
      have := Real.sin_sq_add_cos_sq (t * θ)
      linear_combination (R ^ 2 * θ ^ 2) * this
    exact (pow_left_inj₀ (norm_nonneg _) (by positivity) two_ne_zero).mp h2
  refine ⟨γ, ?_, ?_, ?_, ?_, ?_⟩
  · simp only [hγ]; fun_prop
  · simp [hγ]
  · simp [hγ, hqe]
  · intro t _
    have h := hnorm (Real.cos (t * θ)) (Real.sin (t * θ))
    have h2 : ‖γ t‖ ^ 2 = R ^ 2 := by
      simp only [hγ]; rw [h, Real.cos_sq_add_sin_sq, mul_one]
    exact (pow_left_inj₀ (norm_nonneg _) hR.le two_ne_zero).mp h2
  · simp only [hspeed]
    simp

/-- The point of the globe of radius `R` at angle `φ` down from the North Pole and longitude
`θ` east, in kilometres in space: `r(φ, θ) = R (sin φ cos θ, sin φ sin θ, cos φ)`. -/
noncomputable def globePoint (R φ θ : ℝ) : EuclideanSpace ℝ (Fin 3) :=
  !₂[R * Real.sin φ * Real.cos θ, R * Real.sin φ * Real.sin θ, R * Real.cos φ]

/-- The great-circle distance. On the round globe of radius `R > 0`, take two places `p` and
`q` (points of space at distance `R` from the centre). Among all `C¹` paths `γ` from `p` to `q`
that stay on the globe, run over the times `0 ≤ t ≤ 1`, the length `∫ ‖γ'(t)‖ dt` is never less
than `R c`, where `c` is the central angle between `p` and `q`, and some path (the great-circle
arc) has length exactly `R c`. So the distance `d(p, q)` is `R c`. -/
theorem sphere_distance_eq_radius_mul_central_angle (R : ℝ) (hR : 0 < R)
    (p q : EuclideanSpace ℝ (Fin 3)) (hp : ‖p‖ = R) (hq : ‖q‖ = R) :
    IsLeast
      {L : ℝ | ∃ γ : ℝ → EuclideanSpace ℝ (Fin 3), ContDiff ℝ 1 γ ∧ γ 0 = p ∧ γ 1 = q ∧
        (∀ t ∈ Set.Icc (0 : ℝ) 1, ‖γ t‖ = R) ∧ L = ∫ t in (0 : ℝ)..1, ‖deriv γ t‖}
      (R * InnerProductGeometry.angle p q) := by
  refine ⟨exists_arc R hR p q hp hq, ?_⟩
  rintro L ⟨γ, hγ, h0, h1, hS, rfl⟩
  have := radius_mul_angle_le_length R hR p γ hγ h0 hS
  rwa [h1] at this

/-- The globe's metric in the chart `(φ, θ)`: a path that moves through the chart as
`(φ(t), θ(t))` moves through space at speed squared `R² φ'² + R² sin² φ θ'²`. This is
`ds² = R² dφ² + R² sin²φ dθ²`, the metric table `g₁₁ = R²`, `g₁₂ = 0`, `g₂₂ = R² sin² φ`
got as dot products of the chart's step arrows. -/
theorem globe_speed_sq_eq_metric (R : ℝ) (φ θ : ℝ → ℝ) (t : ℝ)
    (hφ : DifferentiableAt ℝ φ t) (hθ : DifferentiableAt ℝ θ t) :
    ‖deriv (fun s => globePoint R (φ s) (θ s)) t‖ ^ 2 =
      R ^ 2 * deriv φ t ^ 2 + R ^ 2 * Real.sin (φ t) ^ 2 * deriv θ t ^ 2 := by
  have h1 := hφ.hasDerivAt
  have h2 := hθ.hasDerivAt
  set a := deriv φ t
  set b := deriv θ t
  have hc : HasDerivAt (fun s => (![R * Real.sin (φ s) * Real.cos (θ s),
      R * Real.sin (φ s) * Real.sin (θ s), R * Real.cos (φ s)] : Fin 3 → ℝ))
      ![R * (Real.cos (φ t) * a) * Real.cos (θ t) + R * Real.sin (φ t) * (-Real.sin (θ t) * b),
        R * (Real.cos (φ t) * a) * Real.sin (θ t) + R * Real.sin (φ t) * (Real.cos (θ t) * b),
        R * (-Real.sin (φ t) * a)] t := by
    rw [hasDerivAt_pi]
    intro i
    fin_cases i
    · exact ((h1.sin.const_mul R).mul h2.cos)
    · exact ((h1.sin.const_mul R).mul h2.sin)
    · exact (h1.cos.const_mul R)
  have hd := (EuclideanSpace.equiv (Fin 3) ℝ).symm.hasFDerivAt.comp_hasDerivAt t hc
  have : (fun s => globePoint R (φ s) (θ s)) =
      (EuclideanSpace.equiv (Fin 3) ℝ).symm ∘ (fun s => (![R * Real.sin (φ s) * Real.cos (θ s),
      R * Real.sin (φ s) * Real.sin (θ s), R * Real.cos (φ s)] : Fin 3 → ℝ)) := by
    funext s; rfl
  rw [this, hd.deriv, EuclideanSpace.real_norm_sq_eq]
  simp [Fin.sum_univ_three, EuclideanSpace.equiv]
  have e1 := Real.sin_sq_add_cos_sq (φ t)
  have e2 := Real.sin_sq_add_cos_sq (θ t)
  linear_combination (R^2 * a^2 * Real.cos (φ t)^2 + R ^ 2 * Real.sin (φ t) ^ 2 * b ^ 2) * e2 + R^2*a^2 * e1

/-- The chart does not matter. If a change of chart has Jacobian table `J`, so that velocities
change as `u = J ũ`, and the metric's table changes as `g̃ = Jᵀ g J`, then the metric gives the
same number `g(u, v) = ũᵀ g̃ ṽ` for the same two steps in either chart. -/
theorem metric_unchanged_by_change_of_chart {n : ℕ} (g J : Matrix (Fin n) (Fin n) ℝ)
    (u' v' : Fin n → ℝ) :
    (J *ᵥ u') ⬝ᵥ (g *ᵥ (J *ᵥ v')) = u' ⬝ᵥ ((Jᵀ * g * J) *ᵥ v') := by
  rw [← mulVec_mulVec, ← mulVec_mulVec, dotProduct_mulVec u' Jᵀ, vecMul_transpose]

/-- `g₁₁` at London: `6371² = 40589641` km² per radian². -/
example : (6371 : ℕ) ^ 2 = 40589641 := by norm_num

#print axioms angle_mul_le_chord
#print axioms radius_mul_angle_le_length
#print axioms exists_orthogonal_of_norm
#print axioms exists_arc
#print axioms sphere_distance_eq_radius_mul_central_angle
#print axioms globe_speed_sq_eq_metric
#print axioms metric_unchanged_by_change_of_chart
