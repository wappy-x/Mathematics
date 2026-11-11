-- Laurent series: a function with a complex derivative on an open ring round a centre equals exactly one series in positive and negative powers of z minus the centre, its coefficients are loop integrals, and 1/(z(z - 1)) has different series inside and outside the unit circle.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open Complex Real
open scoped ENNReal

open Metric Set Filter MeasureTheory in
theorem laurentAux_coeff {f : ℂ → ℂ} {a : ℂ} {c : ℤ → ℂ} {ρ : ℝ} (hρ : 0 < ρ)
    (hc : ∀ z : ℂ, ‖z - a‖ = ρ → HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z)) (n : ℤ) :
    c n = (2 * π * I)⁻¹ * ∮ ζ in C(a, ρ), f ζ / (ζ - a) ^ (n + 1) := by
  have hsum : Summable (fun k : ℤ => ‖c k‖ * ρ ^ k) := by
    have h0 := hc (a + ρ) (by simp [abs_of_pos hρ])
    have := summable_norm_iff.mpr h0.summable
    simpa [norm_zpow, abs_of_pos hρ] using this
  have hne : ∀ θ, circleMap a ρ θ - a ≠ 0 := fun θ =>
    sub_ne_zero.2 (circleMap_ne_center hρ.ne')
  have hcont : Continuous (fun θ => circleMap a ρ θ - a) := by fun_prop
  have key : HasSum (fun k : ℤ => ∮ ζ in C(a, ρ), c k * (ζ - a) ^ k / (ζ - a) ^ (n + 1))
      (∮ ζ in C(a, ρ), f ζ / (ζ - a) ^ (n + 1)) := by
    unfold circleIntegral
    refine intervalIntegral.hasSum_integral_of_dominated_convergence
      (fun k _ => ρ * (‖c k‖ * ρ ^ k) / ρ ^ (n + 1)) (fun k => ?_) (fun k => ?_) ?_ ?_ ?_
    · apply Continuous.aestronglyMeasurable
      simp only [deriv_circleMap]
      have h1 := hcont.zpow₀ k (fun θ => Or.inl (hne θ))
      have h2 := hcont.zpow₀ (n + 1) (fun θ => Or.inl (hne θ))
      exact (by fun_prop : Continuous fun θ => circleMap 0 ρ θ * I).smul
        ((continuous_const.mul h1).div h2 (fun θ => zpow_ne_zero _ (hne θ)))
    · refine Eventually.of_forall fun θ _ => le_of_eq ?_
      simp [deriv_circleMap, norm_zpow, circleMap_sub_center, abs_of_pos hρ]
      ring
    · exact Eventually.of_forall fun _ _ => (hsum.mul_left ρ).div_const _
    · exact intervalIntegrable_const
    · refine Eventually.of_forall fun θ _ => ?_
      have := (hc (circleMap a ρ θ) (by simp [abs_of_pos hρ])).div_const ((circleMap a ρ θ - a) ^ (n + 1))
      exact this.const_smul (deriv (circleMap a ρ) θ)
  have hterm : ∀ k : ℤ, (∮ ζ in C(a, ρ), c k * (ζ - a) ^ k / (ζ - a) ^ (n + 1)) =
      if k = n then c k * (2 * π * I) else 0 := by
    intro k
    have : (∮ ζ in C(a, ρ), c k * (ζ - a) ^ k / (ζ - a) ^ (n + 1)) =
        c k * ∮ ζ in C(a, ρ), (ζ - a) ^ (k - (n + 1)) := by
      rw [← circleIntegral.integral_const_mul]
      refine circleIntegral.integral_congr hρ.le fun ζ hζ => ?_
      have hz : ζ - a ≠ 0 := by
        rw [sub_ne_zero]; rintro rfl; simp at hζ; linarith
      rw [zpow_sub₀ hz, mul_div_assoc]
    rw [this]
    split_ifs with h
    · subst h
      have : k - (k + 1) = -1 := by ring
      simp only [this, zpow_neg_one]
      rw [circleIntegral.integral_sub_center_inv _ hρ.ne']
    · rw [circleIntegral.integral_sub_zpow_of_ne (by omega), mul_zero]
  simp only [hterm] at key
  have h2 : HasSum (fun k : ℤ => if k = n then c k * (2 * π * I) else 0) (c n * (2 * π * I)) := by
    convert hasSum_ite_eq n (c n * (2 * π * I)) using 2 with k
    split_ifs with h <;> simp [h]
  rw [key.unique h2]
  field_simp [two_pi_I_ne_zero]

#print axioms laurentAux_coeff

open Metric Set Filter MeasureTheory in
theorem laurentAux_neg {f : ℂ → ℂ} {a w : ℂ} {r₁ : ℝ} (hf : CircleIntegrable f a r₁)
    (h0 : 0 < r₁) (hw : r₁ < ‖w‖) :
    HasSum (fun m : ℕ => ∮ ζ in C(a, r₁), ((ζ - a) / w) ^ m • w⁻¹ • f ζ)
      (-∮ ζ in C(a, r₁), (ζ - (a + w))⁻¹ • f ζ) := by
  have hw0 : 0 < ‖w‖ := h0.trans hw
  have hwne : w ≠ 0 := norm_pos_iff.1 hw0
  have hwR : r₁ / ‖w‖ ∈ Ico (0 : ℝ) 1 := ⟨by positivity, (div_lt_one hw0).2 hw⟩
  unfold circleIntegral
  rw [← intervalIntegral.integral_neg]
  refine intervalIntegral.hasSum_integral_of_dominated_convergence
      (fun n θ => r₁ * ‖w‖⁻¹ * ‖f (circleMap a r₁ θ)‖ * (r₁ / ‖w‖) ^ n)
      (fun n => ?_) (fun n => ?_) ?_ ?_ ?_
  · simp only [deriv_circleMap]
    exact ((by fun_prop : Continuous fun θ => circleMap 0 r₁ θ * I).aestronglyMeasurable).smul
      (((by fun_prop : Continuous fun θ => ((circleMap a r₁ θ - a) / w) ^ n).aestronglyMeasurable).smul
        (hf.def'.1.const_smul w⁻¹))
  · refine Eventually.of_forall fun θ _ => le_of_eq ?_
    simp [deriv_circleMap, circleMap_sub_center, abs_of_pos h0, div_pow]
    ring
  · exact Eventually.of_forall fun _ _ => (summable_geometric_of_lt_one hwR.1 hwR.2).mul_left _
  · simpa only [tsum_mul_left, tsum_geometric_of_lt_one hwR.1 hwR.2] using
      (hf.norm.const_mul (r₁ * ‖w‖⁻¹)).mul_continuousOn continuousOn_const
  · refine Eventually.of_forall fun θ _ => ?_
    have hξ : ‖(circleMap a r₁ θ - a) / w‖ < 1 := by
      simpa [circleMap_sub_center, abs_of_pos h0, norm_div] using hwR.2
    have h1 : (1 : ℂ) - (circleMap a r₁ θ - a) / w ≠ 0 := by
      intro h; rw [sub_eq_zero] at h; rw [← h] at hξ; simp at hξ
    have h2 : circleMap a r₁ θ - (a + w) ≠ 0 := by
      intro h; apply h1; field_simp; linear_combination -h
    have := ((hasSum_geometric_of_norm_lt_one hξ).mul_right (w⁻¹ * f (circleMap a r₁ θ))).const_smul
      (deriv (circleMap a r₁) θ)
    have e : (1 - (circleMap a r₁ θ - a) / w)⁻¹ * w⁻¹ = -(circleMap a r₁ θ - (a + w))⁻¹ := by
      rw [← mul_inv, sub_mul, div_mul_cancel₀ _ hwne, one_mul, ← inv_neg]; congr 1; ring
    convert this using 1
    simp only [smul_eq_mul]
    rw [← mul_assoc ((1 - (circleMap a r₁ θ - a) / w)⁻¹), e]; ring

#print axioms laurentAux_neg

open Metric Set Filter MeasureTheory in
theorem laurentAux_cauchy {f : ℂ → ℂ} {a z : ℂ} {r₁ R₁ : ℝ} (h0 : 0 < r₁)
    (h1 : r₁ < ‖z - a‖) (h2 : ‖z - a‖ < R₁)
    (hf : ∀ ζ ∈ closedBall a R₁ \ ball a r₁, DifferentiableAt ℂ f ζ) :
    (∮ ζ in C(a, R₁), (ζ - z)⁻¹ • f ζ) - (∮ ζ in C(a, r₁), (ζ - z)⁻¹ • f ζ) =
      (2 * π * I) * f z := by
  set K := closedBall a R₁ \ ball a r₁
  have hR0 : 0 < R₁ := h0.trans (h1.trans h2)
  have hzK' : z ∈ ball a R₁ \ closedBall a r₁ := by
    simp [dist_eq_norm, h2, h1]
  have hKn : K ∈ nhds z :=
    mem_of_superset ((isOpen_ball.sdiff isClosed_closedBall).mem_nhds hzK')
      (sdiff_subset_sdiff ball_subset_closedBall ball_subset_closedBall)
  have hfc : ContinuousOn f K := fun ζ hζ => (hf ζ hζ).continuousAt.continuousWithinAt
  set G := dslope f z
  have hcG : ContinuousOn G K := (continuousOn_dslope hKn).2 ⟨hfc, hf z (mem_of_mem_nhds hKn)⟩
  have hdG : ∀ w ∈ (ball a R₁ \ closedBall a r₁) \ {z}, DifferentiableAt ℂ G w := by
    intro w hw
    exact (differentiableAt_dslope_of_ne hw.2).2
      (hf w (sdiff_subset_sdiff ball_subset_closedBall ball_subset_closedBall hw.1))
  have hG := circleIntegral_eq_of_differentiable_on_annulus_off_countable h0
    (h1.trans h2).le (countable_singleton z) hcG hdG
  -- G on the two circles
  have hsph : ∀ ρ : ℝ, (ρ = r₁ ∨ ρ = R₁) → EqOn G (fun ζ => (ζ - z)⁻¹ • f ζ - (ζ - z)⁻¹ • f z)
      (sphere a ρ) := by
    intro ρ hρ ζ hζ
    have hne : ζ ≠ z := by
      rintro rfl; simp at hζ; rcases hρ with rfl | rfl <;> linarith
    simp only [G, dslope_of_ne _ hne, slope_def_module, smul_sub]
  have hint : ∀ ρ : ℝ, (ρ = r₁ ∨ ρ = R₁) → 0 < ρ →
      CircleIntegrable (fun ζ => (ζ - z)⁻¹ • f ζ) a ρ ∧
      CircleIntegrable (fun ζ => (ζ - z)⁻¹ • f z) a ρ := by
    intro ρ hρ hρ0
    have hne : ∀ ζ ∈ sphere a ρ, ζ - z ≠ 0 := by
      intro ζ hζ h; rw [sub_eq_zero] at h; subst h
      simp at hζ; rcases hρ with rfl | rfl <;> linarith
    have hc' : ContinuousOn (fun ζ => (ζ - z)⁻¹) (sphere a ρ) :=
      (continuousOn_id.sub continuousOn_const).inv₀ hne
    have hsK : sphere a ρ ⊆ K := by
      intro ζ hζ; simp [K, dist_eq_norm] at hζ ⊢
      rcases hρ with rfl | rfl <;> constructor <;> linarith
    exact ⟨(hc'.smul (hfc.mono hsK)).circleIntegrable hρ0.le,
      (hc'.smul continuousOn_const).circleIntegrable hρ0.le⟩
  rw [circleIntegral.integral_congr hR0.le (hsph R₁ (Or.inr rfl)),
    circleIntegral.integral_congr h0.le (hsph r₁ (Or.inl rfl)),
    circleIntegral.integral_sub (hint R₁ (Or.inr rfl) hR0).1 (hint R₁ (Or.inr rfl) hR0).2,
    circleIntegral.integral_sub (hint r₁ (Or.inl rfl) h0).1 (hint r₁ (Or.inl rfl) h0).2,
    circleIntegral.integral_smul_const, circleIntegral.integral_smul_const,
    circleIntegral.integral_sub_inv_of_mem_ball (by simpa [dist_eq_norm] using h2)] at hG
  have hzero : (∮ ζ in C(a, r₁), (ζ - z)⁻¹) = 0 := by
    have hne : ∀ ζ ∈ closedBall a r₁, ζ - z ≠ 0 := by
      intro ζ hζ h; rw [sub_eq_zero] at h; subst h
      simp [dist_eq_norm] at hζ; linarith
    refine circleIntegral_eq_zero_of_differentiable_on_off_countable h0.le countable_empty
      ((continuousOn_id.sub continuousOn_const).inv₀ hne) ?_
    intro ζ hζ
    exact ((differentiableAt_id.sub_const z).inv (hne ζ (ball_subset_closedBall hζ.1)))
  rw [hzero, zero_smul, sub_zero, smul_eq_mul] at hG
  linear_combination hG

#print axioms laurentAux_cauchy

open Metric Set Filter MeasureTheory in
theorem laurentAux_diffAt {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) (m : ℤ) {ζ : ℂ}
    (hζ : ζ ∈ {z | r < edist z a ∧ edist z a < R}) :
    DifferentiableAt ℂ (fun ζ => f ζ / (ζ - a) ^ m) ζ := by
  have hS : IsOpen {z : ℂ | r < edist z a ∧ edist z a < R} :=
    (isOpen_lt continuous_const (continuous_id.edist continuous_const)).inter
      (isOpen_lt (continuous_id.edist continuous_const) continuous_const)
  have hne : ζ - a ≠ 0 := by
    rw [sub_ne_zero]; rintro rfl; simp at hζ
  exact (hf.differentiableAt (hS.mem_nhds hζ)).div
    ((differentiableAt_id.sub_const a).zpow (Or.inl hne)) (zpow_ne_zero _ hne)

#print axioms laurentAux_diffAt

open Metric Set Filter MeasureTheory in
theorem laurentAux_indep {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) (n : ℤ) {ρ₁ ρ₂ : ℝ}
    (h1r : r < ENNReal.ofReal ρ₁) (h1R : ENNReal.ofReal ρ₁ < R)
    (h2r : r < ENNReal.ofReal ρ₂) (h2R : ENNReal.ofReal ρ₂ < R) :
    (∮ ζ in C(a, ρ₁), f ζ / (ζ - a) ^ (n + 1)) = ∮ ζ in C(a, ρ₂), f ζ / (ζ - a) ^ (n + 1) := by
  wlog h : ρ₁ ≤ ρ₂ generalizing ρ₁ ρ₂
  · exact (this h2r h2R h1r h1R (le_of_not_ge h)).symm
  have hρ0 : 0 < ρ₁ := ENNReal.ofReal_pos.1 (pos_of_gt h1r)
  have hsub : closedBall a ρ₂ \ ball a ρ₁ ⊆ {z | r < edist z a ∧ edist z a < R} := by
    intro ζ hζ
    simp only [Set.mem_sdiff, mem_closedBall, mem_ball, not_lt] at hζ
    simp only [mem_ofPred_eq, edist_dist]
    exact ⟨h1r.trans_le (ENNReal.ofReal_le_ofReal hζ.2),
      (ENNReal.ofReal_le_ofReal hζ.1).trans_lt h2R⟩
  refine (circleIntegral_eq_of_differentiable_on_annulus_off_countable hρ0 h
    countable_empty ?_ ?_).symm
  · exact fun ζ hζ => (laurentAux_diffAt hf _ (hsub hζ)).continuousAt.continuousWithinAt
  · intro ζ hζ
    exact laurentAux_diffAt hf _
      (hsub (sdiff_subset_sdiff ball_subset_closedBall ball_subset_closedBall hζ.1))

#print axioms laurentAux_indep

open Metric Set Filter MeasureTheory in
theorem laurentAux_exists {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hrR : r < R) (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) :
    ∃ c : ℤ → ℂ, ∀ z : ℂ, r < edist z a → edist z a < R →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z) := by
  obtain ⟨ρ₀, -, h0r, h0R⟩ := ENNReal.lt_iff_exists_real_btwn.1 hrR
  set J : ℤ → ℂ := fun n => ∮ ζ in C(a, ρ₀), f ζ / (ζ - a) ^ (n + 1) with hJ
  refine ⟨fun n => (2 * π * I)⁻¹ * J n, fun z hzr hzR => ?_⟩
  have hS : IsOpen {z : ℂ | r < edist z a ∧ edist z a < R} :=
    (isOpen_lt continuous_const (continuous_id.edist continuous_const)).inter
      (isOpen_lt (continuous_id.edist continuous_const) continuous_const)
  have hfint : ∀ ρ : ℝ, 0 < ρ → r < ENNReal.ofReal ρ → ENNReal.ofReal ρ < R →
      CircleIntegrable f a ρ := by
    intro ρ hρ h1 h2
    refine ContinuousOn.circleIntegrable hρ.le (hf.continuousOn.mono fun ζ hζ => ?_)
    simp only [mem_sphere] at hζ
    simp only [Set.mem_ofPred_eq, edist_dist, hζ]
    exact ⟨h1, h2⟩
  rw [edist_dist, dist_eq_norm] at hzr hzR
  obtain ⟨r₁, -, h1r, h1d⟩ := ENNReal.lt_iff_exists_real_btwn.1 hzr
  obtain ⟨R₁, -, h2d, h2R⟩ := ENNReal.lt_iff_exists_real_btwn.1 hzR
  have hr₁ : 0 < r₁ := ENNReal.ofReal_pos.1 (pos_of_gt h1r)
  have hR₁ : 0 < R₁ := ENNReal.ofReal_pos.1 (pos_of_gt h2d)
  have hd : 0 < ‖z - a‖ := ENNReal.ofReal_pos.1 (pos_of_gt hzr)
  have hlt1 : r₁ < ‖z - a‖ := (ENNReal.ofReal_lt_ofReal_iff hd).1 h1d
  have hlt2 : ‖z - a‖ < R₁ := (ENNReal.ofReal_lt_ofReal_iff hR₁).1 h2d
  have h1R : ENNReal.ofReal r₁ < R := h1d.trans hzR
  have h2r : r < ENNReal.ofReal R₁ := hzr.trans h2d
  have hKS : closedBall a R₁ \ ball a r₁ ⊆ {z | r < edist z a ∧ edist z a < R} := by
    intro ζ hζ
    simp only [Set.mem_sdiff, mem_closedBall, mem_ball, not_lt] at hζ
    simp only [Set.mem_ofPred_eq, edist_dist]
    exact ⟨h1r.trans_le (ENNReal.ofReal_le_ofReal hζ.2),
      (ENNReal.ofReal_le_ofReal hζ.1).trans_lt h2R⟩
  have hC := laurentAux_cauchy hr₁ hlt1 hlt2
    (fun ζ hζ => hf.differentiableAt (hS.mem_nhds (hKS hζ)))
  have hpos := hasSum_two_pi_I_cauchyPowerSeries_integral (hfint R₁ hR₁ h2r h2R) hlt2
  simp only [add_sub_cancel] at hpos
  have hpos' : HasSum (fun n : ℕ => J n * (z - a) ^ (n : ℤ))
      (∮ ζ in C(a, R₁), (ζ - z)⁻¹ • f ζ) := by
    convert hpos using 1
    funext n
    rw [hJ]
    simp only
    rw [laurentAux_indep hf n h0r h0R h2r h2R, mul_comm, ← circleIntegral.integral_const_mul]
    refine circleIntegral.integral_congr hR₁.le fun ζ hζ => ?_
    have hne : ζ - a ≠ 0 := by
      rw [sub_ne_zero]; rintro rfl; simp at hζ; linarith
    simp only [smul_eq_mul]
    rw [← Nat.cast_succ, zpow_natCast, zpow_natCast, div_pow, pow_succ]
    field_simp
  have hneg := laurentAux_neg (w := z - a) (hfint r₁ hr₁ h1r h1R) hr₁ hlt1
  simp only [add_sub_cancel] at hneg
  have hneg' : HasSum (fun m : ℕ => J (-((m : ℤ) + 1)) * (z - a) ^ (-((m : ℤ) + 1)))
      (-∮ ζ in C(a, r₁), (ζ - z)⁻¹ • f ζ) := by
    convert hneg using 1
    funext m
    rw [hJ]
    simp only
    rw [laurentAux_indep hf _ h0r h0R h1r h1R, mul_comm, ← circleIntegral.integral_const_mul]
    refine circleIntegral.integral_congr hr₁.le fun ζ hζ => ?_
    have hne : ζ - a ≠ 0 := by
      rw [sub_ne_zero]; rintro rfl; simp at hζ; linarith
    have hne' : z - a ≠ 0 := norm_pos_iff.1 hd
    simp only [smul_eq_mul]
    rw [show -((m : ℤ) + 1) + 1 = -(m : ℤ) by ring, zpow_neg, zpow_neg, ← Nat.cast_succ,
      zpow_natCast, zpow_natCast, div_pow, pow_succ]
    field_simp
  have htot : HasSum (fun n : ℤ => J n * (z - a) ^ n)
      ((∮ ζ in C(a, R₁), (ζ - z)⁻¹ • f ζ) + -∮ ζ in C(a, r₁), (ζ - z)⁻¹ • f ζ) :=
    HasSum.of_nat_of_neg_add_one hpos' hneg'
  rw [← sub_eq_add_neg, hC] at htot
  convert htot.mul_left (2 * π * I)⁻¹ using 1
  · funext n; ring
  · field_simp [two_pi_I_ne_zero]

#print axioms laurentAux_exists

/-- A function holomorphic (with a complex derivative) at every point of the open ring
`r < |z - a| < R` round the centre `a` equals exactly one series in positive and negative
powers of `z - a` on that ring: there is one and only one choice of coefficients `c n`,
`n` any whole number, with `∑ c n (z - a)ⁿ = f z` at every point `z` of the ring.
The radii may be `0` inside and `∞` outside. -/
theorem holomorphic_on_annulus_has_unique_laurent_series {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hrR : r < R) (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) :
    ∃! c : ℤ → ℂ, ∀ z : ℂ, r < edist z a → edist z a < R →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z) := by
  obtain ⟨c, hc⟩ := laurentAux_exists hrR hf
  refine ⟨c, hc, fun c' hc' => funext fun n => ?_⟩
  obtain ⟨ρ, -, hρr, hρR⟩ := ENNReal.lt_iff_exists_real_btwn.1 hrR
  have hρ : 0 < ρ := ENNReal.ofReal_pos.1 (pos_of_gt hρr)
  have hsph : ∀ z : ℂ, ‖z - a‖ = ρ → r < edist z a ∧ edist z a < R := by
    intro z hz
    rw [edist_dist, dist_eq_norm, hz]
    exact ⟨hρr, hρR⟩
  rw [laurentAux_coeff hρ (fun z hz => hc' z (hsph z hz).1 (hsph z hz).2) n,
    laurentAux_coeff hρ (fun z hz => hc z (hsph z hz).1 (hsph z hz).2) n]

/-- The coefficients are loop integrals: if `f` is holomorphic on the ring `r < |z - a| < R`
and equals `∑ c n (z - a)ⁿ` there, then for every circle radius `ρ` between `r` and `R`,
`c n = (1 / 2πi) ∮_{|ζ - a| = ρ} f ζ / (ζ - a)^(n + 1) dζ`. -/
theorem laurent_coeff_eq_circle_integral {f : ℂ → ℂ} {a : ℂ} {r R : ℝ≥0∞}
    (hf : DifferentiableOn ℂ f {z | r < edist z a ∧ edist z a < R}) {c : ℤ → ℂ}
    (hc : ∀ z : ℂ, r < edist z a → edist z a < R →
      HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    {ρ : ℝ} (hρr : r < ENNReal.ofReal ρ) (hρR : ENNReal.ofReal ρ < R) (n : ℤ) :
    c n = (2 * π * I)⁻¹ * ∮ ζ in C(a, ρ), f ζ / (ζ - a) ^ (n + 1) := by
  have hρ : 0 < ρ := ENNReal.ofReal_pos.1 (pos_of_gt hρr)
  refine laurentAux_coeff hρ (fun z hz => hc z ?_ ?_) n
  · rw [edist_dist, dist_eq_norm, hz]; exact hρr
  · rw [edist_dist, dist_eq_norm, hz]; exact hρR

/-- One function, two rings: about 0, `1/(z(z - 1))` equals `-1/z - 1 - z - z² - …`
(every coefficient from `c₋₁` up is `-1`) when `0 < |z| < 1`, and equals
`1/z² + 1/z³ + …` (every coefficient from `c₋₂` down is `1`, so `c₋₁ = 0`) when `|z| > 1`. -/
theorem laurent_series_of_inv_z_mul_z_sub_one_inside_and_outside :
    (∀ z : ℂ, 0 < ‖z‖ → ‖z‖ < 1 →
      HasSum (fun n : ℤ ↦ (if -1 ≤ n then (-1 : ℂ) else 0) * z ^ n) (1 / (z * (z - 1)))) ∧
    (∀ z : ℂ, 1 < ‖z‖ →
      HasSum (fun n : ℤ ↦ (if n ≤ -2 then (1 : ℂ) else 0) * z ^ n) (1 / (z * (z - 1)))) := by
  constructor
  · intro z hz0 hz1
    have hz : z ≠ 0 := norm_pos_iff.1 hz0
    have h1 : z - 1 ≠ 0 := by
      intro h; rw [sub_eq_zero] at h; subst h; simp at hz1
    have hg : Function.Injective (fun m : ℕ => (m : ℤ) - 1) := fun x y h => by simpa using h
    rw [← hg.hasSum_iff]
    · have := (hasSum_geometric_of_norm_lt_one hz1).mul_left (-z⁻¹)
      convert this using 1
      · funext m
        simp only [Function.comp, show -1 ≤ (m : ℤ) - 1 by omega, ite_true]
        rw [zpow_sub_one₀ hz, zpow_natCast]; ring
      · have h2 : (1:ℂ) - z ≠ 0 := by
          rw [sub_ne_zero]; exact fun h => h1 (by rw [← h]; ring)
        field_simp
        ring
    · intro n hn
      have : ¬ (-1 ≤ n) := fun h => hn ⟨(n + 1).toNat, by simp; omega⟩
      simp [this]
  · intro z hz1
    have hz : z ≠ 0 := by rintro rfl; simp at hz1; linarith
    have h1 : z - 1 ≠ 0 := by
      intro h; rw [sub_eq_zero] at h; subst h; simp at hz1
    have hzi : ‖z⁻¹‖ < 1 := by rw [norm_inv]; exact inv_lt_one_of_one_lt₀ hz1
    have hg : Function.Injective (fun m : ℕ => -((m : ℤ) + 2)) := fun x y h => by simpa using h
    rw [← hg.hasSum_iff]
    · have := (hasSum_geometric_of_norm_lt_one hzi).mul_left (z⁻¹ ^ 2)
      convert this using 1
      · funext m
        simp only [Function.comp, show -((m : ℤ) + 2) ≤ -2 by omega, ite_true]
        rw [zpow_neg, ← inv_zpow, show (m : ℤ) + 2 = ((m + 2 : ℕ) : ℤ) by push_cast; ring,
          zpow_natCast]
        ring
      · have h2 : 1 - z⁻¹ ≠ 0 := by
          rw [sub_ne_zero]; intro h; rw [eq_comm, inv_eq_one] at h; subst h; simp at hz1
        field_simp
    · intro n hn
      have : ¬ (n ≤ -2) := fun h => hn ⟨(-n - 2).toNat, by simp; omega⟩
      simp [this]

-- f(z) = 1/(z(z - 1)): at z = 1/2 it is -4, at z = 2 it is 1/2.
example : (1 : ℚ) / ((1 / 2) * (1 / 2 - 1)) = -4 := by norm_num
example : (1 : ℚ) / (2 * (2 - 1)) = 1 / 2 := by norm_num

-- Partial fractions at z = 2: 1/(z - 1) - 1/z = 1 - 1/2 = 1/2.
example : (1 : ℚ) / (2 - 1) - 1 / 2 = 1 / 2 := by norm_num

-- Inner series at 1/2, five terms: -2 - 1 - 1/2 - 1/4 - 1/8 = -31/8 (-3.875);
-- the tail -z^4/(1 - z) = -(1/16)/(1/2) = -1/8 closes the gap to -4.
example : (-2 : ℚ) - 1 - 1 / 2 - 1 / 4 - 1 / 8 = -31 / 8 := by norm_num
example : -((1 / 2 : ℚ) ^ 4) / (1 - 1 / 2) = -1 / 8 := by norm_num
example : (-31 / 8 : ℚ) + (-1 / 8) = -4 := by norm_num

-- Outer series at 2, five terms: 1/4 + 1/8 + 1/16 + 1/32 + 1/64 = 31/64 (0.484375);
-- the tail 2^(-7)/(1 - 1/2) = 1/64 closes the gap to 1/2.
example : (1 / 4 : ℚ) + 1 / 8 + 1 / 16 + 1 / 32 + 1 / 64 = 31 / 64 := by norm_num
example : ((1 : ℚ) / 2 ^ 7) / (1 - 1 / 2) = 1 / 64 := by norm_num
example : (31 / 64 : ℚ) + 1 / 64 = 1 / 2 := by norm_num

-- Mistake 1: five inner terms at z = 2 give -1/2 - 1 - 2 - 4 - 8 = -31/2 (-15.5), not 1/2.
example : (-1 / 2 : ℚ) - 1 - 2 - 4 - 8 = -31 / 2 := by norm_num
-- Mistake 2: five outer terms at z = 1/2 give 4 + 8 + 16 + 32 + 64 = 124, not -4.
example : (4 : ℚ) + 8 + 16 + 32 + 64 = 124 := by norm_num

-- e^z/z^3: the 1/z coefficient is 1/2! = 1/2, not 1/3! = 1/6 (mistake 3).
example : (1 : ℚ) / (Nat.factorial 2) = 1 / 2 := by norm_num [Nat.factorial]
example : (1 : ℚ) / (Nat.factorial 3) = 1 / 6 := by norm_num [Nat.factorial]

#print axioms holomorphic_on_annulus_has_unique_laurent_series
#print axioms laurent_coeff_eq_circle_integral
#print axioms laurent_series_of_inv_z_mul_z_sub_one_inside_and_outside
