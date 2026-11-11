-- Deforming a loop: for a function holomorphic except at finitely many holes, the integral round any closed piecewise smooth loop that misses the holes is the sum over the holes of the loop's winding number times a small circle's integral, the winding number is always a whole number, and a small circle round a hole of strength c gives 2πi c.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib

open Complex MeasureTheory Set

/-- The winding number n(γ, a) of a loop γ(t), 0 ≤ t ≤ T, with velocity γ'(t), round the point a:
the integral of dz/(z − a) once round the loop, divided by 2πi. -/
noncomputable def windingNumber (γ γ' : ℝ → ℂ) (T : ℝ) (a : ℂ) : ℂ :=
  (2 * Real.pi * I)⁻¹ * ∫ t in (0 : ℝ)..T, γ' t / (γ t - a)

section Helpers

open Metric

lemma ftc_off_finset {F F' : ℝ → ℂ} {T : ℝ} (E : Finset ℝ) (hT : 0 ≤ T)
    (hc : ContinuousOn F (Icc 0 T)) (hd : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt F (F' t) t)
    (hi : IntervalIntegrable F' volume 0 T) :
    ∫ t in (0 : ℝ)..T, F' t = F T - F 0 :=
  integral_eq_of_hasDerivAt_off_countable_of_le F F' hT E.countable_toSet hc hd hi

lemma winding_const (γ γ' : ℝ → ℂ) (T : ℝ) (E : Finset ℝ) (hT : 0 ≤ T) (hγ : Continuous γ)
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T) (b z : ℂ)
    (hz : ∀ t, ‖z - b‖ < ‖γ t - b‖) :
    ∫ t in (0:ℝ)..T, γ' t / (γ t - z) = ∫ t in (0:ℝ)..T, γ' t / (γ t - b) := by
  have hb : ∀ t, γ t - b ≠ 0 := fun t h => by
    have := hz t; rw [h, norm_zero] at this; exact (norm_nonneg _).not_gt this
  have hzz : ∀ t, γ t - z ≠ 0 := fun t h => by
    have := hz t
    rw [show γ t - b = (γ t - z) + (z - b) by ring, h, zero_add] at this
    exact lt_irrefl _ this
  have hint : ∀ c : ℂ, (∀ t, γ t - c ≠ 0) →
      IntervalIntegrable (fun t => γ' t / (γ t - c)) volume 0 T := by
    intro c hc
    have : ContinuousOn (fun t => (γ t - c)⁻¹) (uIcc 0 T) :=
      ((hγ.sub continuous_const).inv₀ hc).continuousOn
    simpa [div_eq_mul_inv] using hγ'.mul_continuousOn this
  have hslit : ∀ t, (γ t - z) / (γ t - b) ∈ slitPlane := by
    intro t
    have h1 : (γ t - z) / (γ t - b) = 1 + (b - z) / (γ t - b) := by
      field_simp [hb t]; ring
    rw [h1]
    apply mem_slitPlane_of_norm_lt_one
    rw [norm_div, div_lt_one (norm_pos_iff.mpr (hb t)), norm_sub_rev]
    exact hz t
  have key : ∫ t in (0:ℝ)..T, (γ' t / (γ t - z) - γ' t / (γ t - b)) = 0 := by
    rw [ftc_off_finset (F := fun t => log ((γ t - z) / (γ t - b))) E hT ?_ ?_
      ((hint z hzz).sub (hint b hb))]
    · simp [hclosed]
    · exact fun t _ => (((hγ.sub continuous_const).div (hγ.sub continuous_const)
        hb).continuousAt.clog (hslit t)).continuousWithinAt
    · intro t ht
      have hd : HasDerivAt (fun t => (γ t - z) / (γ t - b))
          ((γ' t * (γ t - b) - (γ t - z) * γ' t) / (γ t - b) ^ 2) t :=
        ((hderiv t ht).sub_const z).div ((hderiv t ht).sub_const b) (hb t)
      convert hd.clog_real (hslit t) using 1
      field_simp [hb t, hzz t]
  rw [intervalIntegral.integral_sub (hint z hzz) (hint b hb)] at key
  exact sub_eq_zero.mp key

lemma sphere_sub_punctured {a : ℂ} {r R : ℝ} (hr : 0 < r) (hrR : r ≤ R) :
    sphere a r ⊆ closedBall a R \ {a} := by
  intro z hz
  rw [mem_sphere_iff_norm] at hz
  refine ⟨mem_closedBall_iff_norm.mpr (hz.le.trans hrR), ?_⟩
  rintro rfl
  simp at hz
  linarith

lemma kernel_indep {f : ℂ → ℂ} {U : Set ℂ} (hU : IsOpen U) (hf : DifferentiableOn ℂ f U)
    {a w : ℂ} {ρ₁ ρ₂ R : ℝ} (h1 : 0 < ρ₁) (h12 : ρ₁ ≤ ρ₂) (h2w : ρ₂ < ‖w - a‖) (hR : ρ₂ ≤ R)
    (hsub : closedBall a R \ {a} ⊆ U) :
    ∮ z in C(a, ρ₂), (z - w)⁻¹ • f z = ∮ z in C(a, ρ₁), (z - w)⁻¹ • f z := by
  have hmem : ∀ z ∈ closedBall a ρ₂ \ ball a ρ₁, z ∈ U ∧ z - w ≠ 0 := by
    rintro z ⟨hz1, hz2⟩
    rw [mem_closedBall_iff_norm] at hz1
    rw [mem_ball_iff_norm, not_lt] at hz2
    refine ⟨hsub ⟨mem_closedBall_iff_norm.mpr (by linarith), ?_⟩, ?_⟩
    · rintro rfl
      simp at hz2
      linarith
    · intro h
      rw [sub_eq_zero.mp h] at hz1
      linarith
  apply circleIntegral_eq_of_differentiable_on_annulus_off_countable h1 h12 countable_empty
  · intro z hz
    obtain ⟨hzU, hzw⟩ := hmem z hz
    exact (((continuousAt_id.sub continuousAt_const).inv₀ hzw).smul
      (hf.continuousOn.continuousAt (hU.mem_nhds hzU))).continuousWithinAt
  · intro z hz
    obtain ⟨hzU, hzw⟩ := hmem z ⟨ball_subset_closedBall hz.1.1,
      fun h => hz.1.2 (ball_subset_closedBall h)⟩
    exact ((differentiableAt_id.sub_const w).inv hzw).smul
      (hf.differentiableAt (hU.mem_nhds hzU))

lemma annulus_cauchy {f : ℂ → ℂ} {U : Set ℂ} (hU : IsOpen U) (hf : DifferentiableOn ℂ f U)
    {a w : ℂ} {ρ R : ℝ} (hρ : 0 < ρ) (hρw : ρ < ‖w - a‖) (hwR : ‖w - a‖ < R)
    (hsub : closedBall a R \ {a} ⊆ U) :
    (∮ z in C(a, R), (z - w)⁻¹ • f z) - (∮ z in C(a, ρ), (z - w)⁻¹ • f z)
      = (2 * Real.pi * I) * f w := by
  have hwa : w ≠ a := by
    rintro rfl; simp at hρw; linarith
  have hwU : w ∈ U := hsub ⟨mem_closedBall_iff_norm.mpr hwR.le, hwa⟩
  have hd : DifferentiableOn ℂ (dslope f w) U := (differentiableOn_dslope (hU.mem_nhds hwU)).mpr hf
  have hR : 0 < R := hρ.trans (hρw.trans hwR)
  have hannU : closedBall a R \ ball a ρ ⊆ U := by
    rintro z ⟨hz1, hz2⟩
    refine hsub ⟨hz1, ?_⟩
    rintro rfl
    exact hz2 (mem_ball_self hρ)
  have hann := circleIntegral_eq_of_differentiable_on_annulus_off_countable (f := dslope f w) hρ
    (hρw.le.trans hwR.le) countable_empty (hd.continuousOn.mono hannU)
    (fun z hz => hd.differentiableAt (hU.mem_nhds (hannU ⟨ball_subset_closedBall hz.1.1,
      fun h => hz.1.2 (ball_subset_closedBall h)⟩)))
  have e : ∀ r, 0 < r → r ≤ R → r ≠ ‖w - a‖ → EqOn (dslope f w)
      (fun z => (z - w)⁻¹ • f z - (z - w)⁻¹ • f w) (sphere a r) := by
    intro r _ _ hr z hz
    have hzw : z ≠ w := by
      rintro rfl; rw [mem_sphere_iff_norm] at hz; exact hr hz.symm
    simp only
    rw [dslope_of_ne _ hzw, slope_def_module, smul_sub]
  have hc : ∀ r, 0 < r → r ≤ R → r ≠ ‖w - a‖ →
      ContinuousOn (fun z => (z - w)⁻¹) (sphere a r) ∧ ContinuousOn f (sphere a r) := by
    intro r hr hrR hrw
    refine ⟨fun z hz => ?_, hf.continuousOn.mono ((sphere_sub_punctured hr hrR).trans hsub)⟩
    have hzw : z - w ≠ 0 := by
      intro h; rw [sub_eq_zero.mp h, mem_sphere_iff_norm] at hz; exact hrw hz.symm
    exact ((continuousAt_id.sub continuousAt_const).inv₀ hzw).continuousWithinAt
  obtain ⟨hcR1, hcR2⟩ := hc R hR le_rfl hwR.ne'
  obtain ⟨hcρ1, hcρ2⟩ := hc ρ hρ (hρw.le.trans hwR.le) hρw.ne
  have i1 : CircleIntegrable (fun z => (z - w)⁻¹ • f z) a R :=
    (hcR1.smul hcR2).circleIntegrable hR.le
  have i2 : CircleIntegrable (fun z => (z - w)⁻¹ • f w) a R :=
    (hcR1.smul continuousOn_const).circleIntegrable hR.le
  have i3 : CircleIntegrable (fun z => (z - w)⁻¹ • f z) a ρ :=
    (hcρ1.smul hcρ2).circleIntegrable hρ.le
  have i4 : CircleIntegrable (fun z => (z - w)⁻¹ • f w) a ρ :=
    (hcρ1.smul continuousOn_const).circleIntegrable hρ.le
  rw [circleIntegral.integral_congr hR.le (e R hR le_rfl hwR.ne'),
    circleIntegral.integral_congr hρ.le (e ρ hρ (hρw.le.trans hwR.le) hρw.ne),
    circleIntegral.integral_sub i1 i2, circleIntegral.integral_sub i3 i4,
    circleIntegral.integral_smul_const, circleIntegral.integral_smul_const,
    circleIntegral.integral_sub_inv_of_mem_ball (mem_ball_iff_norm.mpr hwR)] at hann
  have h0 : ∮ z in C(a, ρ), (z - w)⁻¹ = 0 := by
    apply circleIntegral_eq_zero_of_differentiable_on_off_countable hρ.le countable_empty
    · intro z hz
      have hzw : z - w ≠ 0 := by
        intro h; rw [sub_eq_zero.mp h, mem_closedBall_iff_norm] at hz; linarith
      exact ((continuousAt_id.sub continuousAt_const).inv₀ hzw).continuousWithinAt
    · intro z hz
      have hzw : z - w ≠ 0 := by
        intro h; rw [sub_eq_zero.mp h] at hz; have := mem_ball_iff_norm.mp hz.1; linarith
      exact (differentiableAt_id.sub_const w).inv hzw
  rw [h0, zero_smul, sub_zero, smul_eq_mul] at hann
  linear_combination hann

lemma ppart_eq {f : ℂ → ℂ} {U : Set ℂ} (hU : IsOpen U) (hf : DifferentiableOn ℂ f U)
    {a w : ℂ} {ρ R : ℝ} (hρ : 0 < ρ) (hρR : ρ ≤ R) (hρw : ρ < ‖w - a‖)
    (hsub : closedBall a R \ {a} ⊆ U) :
    ∮ z in C(a, min R ‖w - a‖ / 2), (z - w)⁻¹ • f z = ∮ z in C(a, ρ), (z - w)⁻¹ • f z := by
  have hR : 0 < R := hρ.trans_le hρR
  have hwa : 0 < ‖w - a‖ := hρ.trans hρw
  have hm : 0 < min R ‖w - a‖ := lt_min hR hwa
  have h1 : 0 < min R ‖w - a‖ / 2 := half_pos hm
  have h2 : min R ‖w - a‖ / 2 ≤ R := (half_le_self hm.le).trans (min_le_left _ _)
  have h3 : min R ‖w - a‖ / 2 < ‖w - a‖ := (half_lt_self hm).trans_le (min_le_right _ _)
  rcases le_total ρ (min R ‖w - a‖ / 2) with h | h
  · exact kernel_indep hU hf hρ h h3 h2 hsub
  · exact (kernel_indep hU hf h1 h hρw hρR hsub).symm

lemma ppart_differentiableAt {f : ℂ → ℂ} {U : Set ℂ} (hU : IsOpen U)
    (hf : DifferentiableOn ℂ f U) {a w₀ : ℂ} {R : ℝ} (hR : 0 < R) (hw₀ : w₀ ≠ a)
    (hsub : closedBall a R \ {a} ⊆ U) :
    DifferentiableAt ℂ (fun w => ∮ z in C(a, min R ‖w - a‖ / 2), (z - w)⁻¹ • f z) w₀ := by
  have hwa : 0 < ‖w₀ - a‖ := norm_pos_iff.mpr (sub_ne_zero.mpr hw₀)
  have hm : 0 < min R ‖w₀ - a‖ := lt_min hR hwa
  have h1 : 0 < min R ‖w₀ - a‖ / 2 := half_pos hm
  have h2 : min R ‖w₀ - a‖ / 2 ≤ R := (half_le_self hm.le).trans (min_le_left _ _)
  have h3 : min R ‖w₀ - a‖ / 2 < ‖w₀ - a‖ := (half_lt_self hm).trans_le (min_le_right _ _)
  have hev : (fun w => ∮ z in C(a, min R ‖w - a‖ / 2), (z - w)⁻¹ • f z) =ᶠ[nhds w₀]
      fun w => ∮ z in C(a, min R ‖w₀ - a‖ / 2), (z - w)⁻¹ • f z := by
    have : {w : ℂ | min R ‖w₀ - a‖ / 2 < ‖w - a‖} ∈ nhds w₀ :=
      (isOpen_lt continuous_const (continuous_id.sub continuous_const).norm).mem_nhds h3
    filter_upwards [this] with w hw
    exact ppart_eq hU hf h1 h2 hw hsub
  have hci : CircleIntegrable f a (min R ‖w₀ - a‖ / 2) :=
    ContinuousOn.circleIntegrable h1.le
      (hf.continuousOn.mono ((sphere_sub_punctured h1 h2).trans hsub))
  have hns : w₀ ∉ sphere a |min R ‖w₀ - a‖ / 2| := by
    rw [abs_of_pos h1, mem_sphere_iff_norm]; exact h3.ne'
  exact (hasDerivAt_circleIntegral_sub_inv_smul hci hns).differentiableAt.congr_of_eventuallyEq hev
lemma fubini_curve_circle (γ γ' : ℝ → ℂ) (T : ℝ) (hT : 0 ≤ T) (hγ : Continuous γ)
    (hγ' : IntervalIntegrable γ' volume 0 T) (f : ℂ → ℂ) (b : ℂ) (ρ : ℝ)
    (hfc : Continuous (fun θ => f (circleMap b ρ θ)))
    (hsep : ∀ t θ, circleMap b ρ θ - γ t ≠ 0) :
    ∫ t in (0:ℝ)..T, (∮ z in C(b, ρ), (z - γ t)⁻¹ • f z) * γ' t
      = ∮ z in C(b, ρ), (∫ t in (0:ℝ)..T, γ' t / (z - γ t)) • f z := by
  set K : ℝ → ℝ → ℂ := fun t θ =>
    (circleMap 0 ρ θ * I) * ((circleMap b ρ θ - γ t)⁻¹ * f (circleMap b ρ θ)) with hKdef
  have hK : Continuous (Function.uncurry K) := by
    have h1 : Continuous fun p : ℝ × ℝ => circleMap b ρ p.2 - γ p.1 :=
      ((continuous_circleMap b ρ).comp continuous_snd).sub (hγ.comp continuous_fst)
    have h2 := h1.inv₀ (fun p => hsep p.1 p.2)
    exact (((continuous_circleMap 0 ρ).comp continuous_snd).mul continuous_const).mul
      (h2.mul (hfc.comp continuous_snd))
  have lhs : ∀ t, (∮ z in C(b, ρ), (z - γ t)⁻¹ • f z) * γ' t
      = ∫ θ in (0:ℝ)..2 * Real.pi, K t θ * γ' t := by
    intro t
    rw [circleIntegral, ← intervalIntegral.integral_mul_const]
    simp [deriv_circleMap, hKdef]
  have rhs : (∮ z in C(b, ρ), (∫ t in (0:ℝ)..T, γ' t / (z - γ t)) • f z)
      = ∫ θ in (0:ℝ)..2 * Real.pi, ∫ t in (0:ℝ)..T, K t θ * γ' t := by
    rw [circleIntegral]
    refine intervalIntegral.integral_congr (fun θ _ => ?_)
    have : ∀ t, K t θ * γ' t = (circleMap 0 ρ θ * I * f (circleMap b ρ θ)) *
        (γ' t / (circleMap b ρ θ - γ t)) := fun t => by simp only [hKdef]; ring
    simp only [this, intervalIntegral.integral_const_mul, deriv_circleMap, smul_eq_mul]
    ring
  rw [intervalIntegral.integral_congr (fun t _ => lhs t), rhs]
  simp_rw [intervalIntegral.integral_of_le hT, intervalIntegral.integral_of_le Real.two_pi_pos.le]
  apply integral_integral_swap
  have hg : Integrable (fun p : ℝ × ℝ => γ' p.1)
      ((volume.restrict (Ioc 0 T)).prod (volume.restrict (Ioc 0 (2 * Real.pi)))) :=
    (hγ'.1).comp_fst _
  obtain ⟨C, hC⟩ := (isCompact_Icc.prod isCompact_Icc).exists_bound_of_continuousOn
    (hK.continuousOn (s := Icc 0 T ×ˢ Icc 0 (2 * Real.pi)))
  refine hg.bdd_mul (c := C) hK.aestronglyMeasurable ?_
  rw [Measure.prod_restrict]
  exact ae_restrict_of_forall_mem (measurableSet_Ioc.prod measurableSet_Ioc)
    (fun x hx => hC x ⟨Ioc_subset_Icc_self hx.1, Ioc_subset_Icc_self hx.2⟩)

lemma isSimplyConnected_univ_real : IsSimplyConnected (univ : Set ℝ) := by
  have : ContractibleSpace (univ : Set ℝ) := convex_univ.contractibleSpace univ_nonempty
  exact SimplyConnectedSpace.ofContractible _

/-- derivative of a continuous logarithm of a differentiable nonvanishing function -/
lemma hasDerivAt_of_exp_eq {ℓ h : ℝ → ℂ} {t : ℝ} {h' : ℂ} (hℓ : ContinuousAt ℓ t)
    (hexp : ∀ s, exp (ℓ s) = h s) (hh : HasDerivAt h h' t) (h0 : h t ≠ 0) :
    HasDerivAt ℓ (h' / h t) t := by
  have hev : ∀ᶠ s in nhds t, ℓ s = ℓ t + log (h s / h t) := by
    have hc : Filter.Tendsto (fun s => (ℓ s - ℓ t).im) (nhds t) (nhds 0) := by
      have h2 : ContinuousAt (fun s => (ℓ s - ℓ t).im) t :=
        Complex.continuous_im.continuousAt.comp (hℓ.sub continuousAt_const)
      simpa using h2.tendsto
    have hpi : (0:ℝ) ∈ Ioo (-Real.pi) Real.pi := ⟨by linarith [Real.pi_pos], Real.pi_pos⟩
    filter_upwards [hc (Ioo_mem_nhds hpi.1 hpi.2)] with s hs
    have : h s / h t = exp (ℓ s - ℓ t) := by
      rw [← hexp, ← hexp, exp_sub]
    rw [this, log_exp hs.1 hs.2.le]; ring
  have hq : HasDerivAt (fun s => h s / h t) (h' / h t) t := hh.div_const _
  have hq1 : h t / h t ∈ slitPlane := by rw [div_self h0]; exact one_mem_slitPlane
  have := (hq.clog_real hq1).const_add (ℓ t)
  rw [div_self h0, div_one] at this
  exact this.congr_of_eventuallyEq hev

lemma loop_aux (f : ℂ → ℂ) (S : Finset ℂ) (hf : DifferentiableOn ℂ f (↑S)ᶜ)
    (γ γ' : ℝ → ℂ) (T : ℝ) (E : Finset ℝ) (hT : 0 ≤ T) (hγ : Continuous γ)
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T)
    (hrange : ∀ t, ∃ s ∈ Icc 0 T, γ t = γ s)
    (hoff : ∀ t, γ t ∉ S)
    (r : ℂ → ℝ) (hr : ∀ a ∈ S, 0 < r a)
    (halone : ∀ a ∈ S, ∀ b ∈ S, b ≠ a → r a < ‖b - a‖) :
    ∫ t in (0 : ℝ)..T, f (γ t) * γ' t
      = ∑ a ∈ S, windingNumber γ γ' T a * ∮ z in C(a, r a), f z := by
  classical
  set U : Set ℂ := (↑S)ᶜ with hUdef
  have hU : IsOpen U := S.finite_toSet.isClosed.isOpen_compl
  have hsub : ∀ a ∈ S, closedBall a (r a) \ {a} ⊆ U := by
    rintro a ha z ⟨hz1, hz2⟩ hzS
    have := halone a ha z hzS hz2
    rw [mem_closedBall_iff_norm] at hz1
    linarith
  have h2pi : (2 * Real.pi * I : ℂ) ≠ 0 := by simp [Real.pi_ne_zero, I_ne_zero]
  set P : ℂ → ℂ → ℂ := fun a w =>
    -(2 * Real.pi * I)⁻¹ * ∮ z in C(a, min (r a) ‖w - a‖ / 2), (z - w)⁻¹ • f z with hP
  have hPd : ∀ a ∈ S, ∀ w, w ≠ a → DifferentiableAt ℂ (P a) w := fun a ha w hw =>
    (ppart_differentiableAt hU hf (hr a ha) hw (hsub a ha)).const_mul _
  set K : ℂ → ℂ → ℂ := fun a w => (2 * Real.pi * I)⁻¹ * ∮ z in C(a, r a), (z - w)⁻¹ • f z
    with hKdef
  have hK : ∀ a ∈ S, ∀ w ∈ ball a (r a), w ≠ a → f w - P a w = K a w := by
    intro a ha w hw hwa
    have hwa' : 0 < ‖w - a‖ := norm_pos_iff.mpr (sub_ne_zero.mpr hwa)
    have hm : 0 < min (r a) ‖w - a‖ := lt_min (hr a ha) hwa'
    have := annulus_cauchy hU hf (half_pos hm) ((half_lt_self hm).trans_le (min_le_right _ _))
      (mem_ball_iff_norm.mp hw) (hsub a ha)
    simp only [hP, hKdef]
    have hf' : f w = (2 * Real.pi * I)⁻¹ * ((∮ z in C(a, r a), (z - w)⁻¹ • f z) -
        ∮ z in C(a, min (r a) ‖w - a‖ / 2), (z - w)⁻¹ • f z) := by
      rw [this, ← mul_assoc, inv_mul_cancel₀ h2pi, one_mul]
    rw [hf']
    ring
  have hKd : ∀ a ∈ S, DifferentiableAt ℂ (K a) a := by
    intro a ha
    have hci : CircleIntegrable f a (r a) := ContinuousOn.circleIntegrable (hr a ha).le
      (hf.continuousOn.mono ((sphere_sub_punctured (hr a ha) le_rfl).trans (hsub a ha)))
    have hns : a ∉ sphere a |r a| := by
      rw [abs_of_pos (hr a ha), mem_sphere_iff_norm, sub_self, norm_zero]
      exact (hr a ha).ne
    exact (hasDerivAt_circleIntegral_sub_inv_smul hci hns).differentiableAt.const_mul _
  set G : ℂ → ℂ := fun w =>
    if w ∈ S then K w w - ∑ b ∈ S.erase w, P b w else f w - ∑ b ∈ S, P b w with hGdef
  have hGd : Differentiable ℂ G := by
    intro w
    by_cases hw : w ∈ S
    · have hev : G =ᶠ[nhds w] fun v => K w v - ∑ b ∈ S.erase w, P b v := by
        filter_upwards [ball_mem_nhds w (hr w hw)] with v hv
        by_cases hvw : v = w
        · subst hvw; simp [hGdef, hw]
        · have hvS : v ∉ S := fun hvS => by
            have := halone w hw v hvS hvw
            rw [mem_ball_iff_norm] at hv
            linarith
          simp only [hGdef, hvS, ite_false]
          rw [← Finset.add_sum_erase S _ hw, ← hK w hw v hv hvw]
          ring
      refine DifferentiableAt.congr_of_eventuallyEq ?_ hev
      exact (hKd w hw).sub (DifferentiableAt.fun_sum fun b hb =>
        hPd b (Finset.mem_of_mem_erase hb) w (Finset.ne_of_mem_erase hb).symm)
    · have hev : G =ᶠ[nhds w] fun v => f v - ∑ b ∈ S, P b v := by
        filter_upwards [hU.mem_nhds hw] with v hv
        have hv' : v ∉ S := hv
        simp [hGdef, hv']
      refine DifferentiableAt.congr_of_eventuallyEq ?_ hev
      exact (hf.differentiableAt (hU.mem_nhds hw)).sub (DifferentiableAt.fun_sum fun b hb =>
        hPd b hb w (fun h => hw (h ▸ hb)))
  have hcomp : ∀ φ : ℂ → ℂ, (∀ t, ContinuousAt φ (γ t)) →
      IntervalIntegrable (fun t => φ (γ t) * γ' t) volume 0 T := fun φ hφ =>
    hγ'.continuousOn_mul
      (continuous_iff_continuousAt.mpr (fun t => (hφ t).comp hγ.continuousAt)).continuousOn
  obtain ⟨Φ, hΦ⟩ := hGd.isExactOn_univ
  have hG0 : ∫ t in (0:ℝ)..T, G (γ t) * γ' t = 0 := by
    rw [ftc_off_finset (F := fun t => Φ (γ t)) E hT ?_ ?_
      (hcomp G fun t => (hGd _).continuousAt)]
    · simp [hclosed]
    · exact (continuous_iff_continuousAt.mpr fun t =>
        (hΦ (γ t) (mem_univ _)).differentiableAt.continuousAt.comp hγ.continuousAt).continuousOn
    · intro t ht
      exact (hΦ (γ t) (mem_univ _)).comp t (hderiv t ht)
  have hPc : ∀ b ∈ S, IntervalIntegrable (fun t => P b (γ t) * γ' t) volume 0 T :=
    fun b hb => hcomp (P b) fun t => (hPd b hb (γ t) (fun h => hoff t (h ▸ hb))).continuousAt
  have hdecomp : ∀ t, f (γ t) * γ' t = G (γ t) * γ' t + ∑ b ∈ S, P b (γ t) * γ' t := by
    intro t
    simp only [hGdef, hoff t, ite_false]
    rw [← Finset.sum_mul]
    ring
  rw [intervalIntegral.integral_congr (fun t _ => hdecomp t),
    intervalIntegral.integral_add (hcomp G fun t => (hGd _).continuousAt)
      (by convert IntervalIntegrable.sum S hPc using 1; ext t; simp [Finset.sum_apply]),
    intervalIntegral.integral_finsetSum hPc, hG0, zero_add]
  refine Finset.sum_congr rfl fun b hb => ?_
  obtain ⟨t₀, -, hmin⟩ := isCompact_Icc.exists_isMinOn (nonempty_Icc.mpr hT)
    (hγ.sub continuous_const).norm.continuousOn (f := fun t => ‖γ t - b‖)
  have hδpos : 0 < ‖γ t₀ - b‖ := norm_pos_iff.mpr (sub_ne_zero.mpr (fun h => hoff t₀ (h ▸ hb)))
  have hδ : ∀ t, ‖γ t₀ - b‖ ≤ ‖γ t - b‖ := fun t => by
    obtain ⟨s, hs, hts⟩ := hrange t
    rw [hts]
    exact hmin hs
  set ρ := min (r b) (‖γ t₀ - b‖ / 2) with hρdef
  have hρpos : 0 < ρ := lt_min (hr b hb) (half_pos hδpos)
  have hρr : ρ ≤ r b := min_le_left _ _
  have hρδ : ρ < ‖γ t₀ - b‖ := (min_le_right _ _).trans_lt (half_lt_self hδpos)
  have hPγ : ∀ t, P b (γ t) = -(2 * Real.pi * I)⁻¹ * ∮ z in C(b, ρ), (z - γ t)⁻¹ • f z := by
    intro t
    simp only [hP]
    rw [ppart_eq hU hf hρpos hρr (hρδ.trans_le (hδ t)) (hsub b hb)]
  have hfc : Continuous fun θ => f (circleMap b ρ θ) :=
    hf.continuousOn.comp_continuous (continuous_circleMap b ρ) (fun θ =>
      (sphere_sub_punctured hρpos hρr).trans (hsub b hb) (circleMap_mem_sphere b hρpos.le θ))
  have hsep : ∀ t θ, circleMap b ρ θ - γ t ≠ 0 := by
    intro t θ h
    have h1 : ‖circleMap b ρ θ - b‖ = ρ :=
      mem_sphere_iff_norm.mp (circleMap_mem_sphere b hρpos.le θ)
    rw [sub_eq_zero.mp h] at h1
    linarith [hδ t]
  have hfub := fubini_curve_circle γ γ' T hT hγ hγ' f b ρ hfc hsep
  have hW : ∀ z ∈ sphere b ρ, (∫ t in (0:ℝ)..T, γ' t / (z - γ t))
      = -(2 * Real.pi * I * windingNumber γ γ' T b) := by
    intro z hz
    have e1 : (∫ t in (0:ℝ)..T, γ' t / (z - γ t)) = -∫ t in (0:ℝ)..T, γ' t / (γ t - z) := by
      rw [← intervalIntegral.integral_neg]
      refine intervalIntegral.integral_congr (fun t _ => ?_)
      rw [← neg_sub, div_neg]
    rw [e1, winding_const γ γ' T E hT hγ hderiv hγ' hclosed b z (fun t => by
      rw [mem_sphere_iff_norm.mp hz]; exact hρδ.trans_le (hδ t)), windingNumber]
    field_simp
  have hann : (∮ z in C(b, r b), f z) = ∮ z in C(b, ρ), f z := by
    have hannU : closedBall b (r b) \ ball b ρ ⊆ U := by
      rintro z ⟨hz1, hz2⟩
      refine hsub b hb ⟨hz1, ?_⟩
      rintro rfl
      exact hz2 (mem_ball_self hρpos)
    exact circleIntegral_eq_of_differentiable_on_annulus_off_countable hρpos hρr countable_empty
      (hf.continuousOn.mono hannU)
      (fun z hz => hf.differentiableAt (hU.mem_nhds (hannU ⟨ball_subset_closedBall hz.1.1,
        fun h => hz.1.2 (ball_subset_closedBall h)⟩)))
  calc ∫ t in (0:ℝ)..T, P b (γ t) * γ' t
      = -(2 * Real.pi * I)⁻¹ * ∫ t in (0:ℝ)..T, (∮ z in C(b, ρ), (z - γ t)⁻¹ • f z) * γ' t := by
        simp_rw [hPγ, mul_assoc]
        rw [intervalIntegral.integral_const_mul]
    _ = -(2 * Real.pi * I)⁻¹ * ∮ z in C(b, ρ), (-(2 * Real.pi * I * windingNumber γ γ' T b)) • f z := by
        rw [hfub, circleIntegral.integral_congr hρpos.le (fun z hz => by rw [hW z hz])]
    _ = windingNumber γ γ' T b * ∮ z in C(b, r b), f z := by
        rw [circleIntegral.integral_smul, smul_eq_mul, hann]
        field_simp

end Helpers

#print axioms ftc_off_finset
#print axioms winding_const
#print axioms sphere_sub_punctured
#print axioms kernel_indep
#print axioms annulus_cauchy
#print axioms ppart_eq
#print axioms ppart_differentiableAt
#print axioms fubini_curve_circle
#print axioms isSimplyConnected_univ_real
#print axioms hasDerivAt_of_exp_eq
#print axioms loop_aux

/-- A loop may be slid anywhere without crossing a hole, so its integral is the sum over the holes
of a small circle's integral times the winding number. Let f be holomorphic everywhere in the plane
except at finitely many holes (the finite set S). Let γ(t), 0 ≤ t ≤ T, be a loop made of finitely
many smooth pieces (velocity γ' off a finite set of corners), closed (it ends where it began), and
passing through no hole. For each hole a, let C(a, r a) be an anticlockwise circle round a alone:
radius r a > 0, and every other hole lies farther from a than r a. Then the integral of f round γ
equals the sum, over the holes a, of n(γ, a) times the integral of f round C(a, r a). -/
theorem loop_integral_eq_sum_winding_number_mul_small_circle
    (f : ℂ → ℂ) (S : Finset ℂ) (hf : DifferentiableOn ℂ f (↑S)ᶜ)
    (γ γ' : ℝ → ℂ) (T : ℝ) (E : Finset ℝ) (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T)
    (hclosed : γ 0 = γ T)
    (hoff : ∀ t ∈ Icc 0 T, γ t ∉ S)
    (r : ℂ → ℝ) (hr : ∀ a ∈ S, 0 < r a)
    (halone : ∀ a ∈ S, ∀ b ∈ S, b ≠ a → r a < ‖b - a‖) :
    ∫ t in (0 : ℝ)..T, f (γ t) * γ' t
      = ∑ a ∈ S, windingNumber γ γ' T a * ∮ z in C(a, r a), f z := by
  set γ₁ : ℝ → ℂ := fun s => γ (projIcc 0 T hT s) with hγ₁
  have hγ₁c : Continuous γ₁ := hγ.comp_continuous
    (continuous_subtype_val.comp continuous_projIcc) (fun s => (projIcc 0 T hT s).2)
  have hγ₁I : ∀ s ∈ Icc 0 T, γ₁ s = γ s := fun s hs => by simp [hγ₁, projIcc_of_mem hT hs]
  have hderiv' : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ₁ (γ' t) t := fun t ht =>
    (hderiv t ht).congr_of_eventuallyEq (by
      filter_upwards [Ioo_mem_nhds ht.1.1 ht.1.2] with s hs
      exact hγ₁I s (Ioo_subset_Icc_self hs))
  have hclosed' : γ₁ 0 = γ₁ T := by
    rw [hγ₁I 0 ⟨le_rfl, hT⟩, hγ₁I T ⟨hT, le_rfl⟩, hclosed]
  have hrange : ∀ t, ∃ s ∈ Icc 0 T, γ₁ t = γ₁ s := fun t =>
    ⟨projIcc 0 T hT t, (projIcc 0 T hT t).2, by rw [hγ₁I _ (projIcc 0 T hT t).2]⟩
  have hoff' : ∀ t, γ₁ t ∉ S := fun t => hoff _ (projIcc 0 T hT t).2
  have e1 : ∫ t in (0:ℝ)..T, f (γ t) * γ' t = ∫ t in (0:ℝ)..T, f (γ₁ t) * γ' t :=
    intervalIntegral.integral_congr (fun t ht => by
      rw [uIcc_of_le hT] at ht
      simp only [hγ₁I t ht])
  have e2 : ∀ a, windingNumber γ γ' T a = windingNumber γ₁ γ' T a := fun a => by
    unfold windingNumber
    congr 1
    exact intervalIntegral.integral_congr (fun t ht => by
      rw [uIcc_of_le hT] at ht
      simp only [hγ₁I t ht])
  rw [e1, loop_aux f S hf γ₁ γ' T E hT hγ₁c hderiv' hγ' hclosed' hrange hoff' r hr halone]
  simp_rw [e2]

/-- The winding number is a whole number. For a closed loop γ(t), 0 ≤ t ≤ T, made of finitely many
smooth pieces and never passing through the point a, the integral of dz/(z − a) round it, divided
by 2πi, is an integer. -/
theorem winding_number_is_whole
    (γ γ' : ℝ → ℂ) (T : ℝ) (E : Finset ℝ) (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T)
    (hclosed : γ 0 = γ T)
    (a : ℂ) (hoff : ∀ t ∈ Icc 0 T, γ t ≠ a) :
    ∃ n : ℤ, windingNumber γ γ' T a = n := by
  set g : ℝ → ℂ := fun s => γ (projIcc 0 T hT s) - a with hg
  have hgc : Continuous g := by
    have : Continuous fun s => γ (projIcc 0 T hT s) :=
      hγ.comp_continuous (continuous_subtype_val.comp continuous_projIcc)
        (fun s => (projIcc 0 T hT s).2)
    exact this.sub continuous_const
  have hg0 : ∀ s, g s ≠ 0 := fun s => sub_ne_zero.mpr (hoff _ (projIcc 0 T hT s).2)
  obtain ⟨ℓ, hℓc, hℓe⟩ := exists_continuousOn_eqOn_exp_comp isSimplyConnected_univ_real
    isOpen_univ hgc.continuousOn (by rintro ⟨x, -, hx⟩; exact hg0 x hx)
  have hℓc' : Continuous ℓ := continuousOn_univ.mp hℓc
  have hexp : ∀ s, exp (ℓ s) = g s := fun s => hℓe (mem_univ s)
  have hgI : ∀ s ∈ Icc 0 T, g s = γ s - a := fun s hs => by
    simp [hg, projIcc_of_mem hT hs]
  have hint : ∫ t in (0 : ℝ)..T, γ' t / (γ t - a) = ℓ T - ℓ 0 := by
    apply ftc_off_finset E hT hℓc'.continuousOn
    · intro t ht
      have htI : t ∈ Ioo 0 T := ht.1
      have hgd : HasDerivAt g (γ' t) t := by
        have hev : g =ᶠ[nhds t] fun s => γ s - a := by
          filter_upwards [Ioo_mem_nhds htI.1 htI.2] with s hs
          exact hgI s (Ioo_subset_Icc_self hs)
        exact ((hderiv t ht).sub_const a).congr_of_eventuallyEq hev
      have := hasDerivAt_of_exp_eq hℓc'.continuousAt hexp hgd (hg0 t)
      rwa [hgI t (Ioo_subset_Icc_self htI)] at this
    · have : ContinuousOn (fun t => (γ t - a)⁻¹) (uIcc 0 T) := by
        rw [uIcc_of_le hT]
        exact (hγ.sub continuousOn_const).inv₀ (fun t ht => sub_ne_zero.mpr (hoff t ht))
      simpa [div_eq_mul_inv] using hγ'.mul_continuousOn this
  have h1 : exp (ℓ T - ℓ 0) = 1 := by
    rw [exp_sub, hexp, hexp, hgI T ⟨hT, le_rfl⟩, hgI 0 ⟨le_rfl, hT⟩, hclosed,
      div_self (sub_ne_zero.mpr (hoff T ⟨hT, le_rfl⟩))]
  obtain ⟨n, hn⟩ := exp_eq_one_iff.mp h1
  refine ⟨n, ?_⟩
  rw [windingNumber, hint, hn]
  field_simp [Real.pi_ne_zero, I_ne_zero]

/-- One lap of a small circle gives 2πi times the strength. For a building block c/(z − a) with
strength c, one anticlockwise lap of the circle of radius r > 0 round a gives 2πi c, whatever r is. -/
theorem small_circle_integral_eq_two_pi_I_mul_strength (a c : ℂ) (r : ℝ) (hr : 0 < r) :
    (∮ z in C(a, r), c / (z - a)) = 2 * Real.pi * I * c := by
  have h : (fun z => c / (z - a)) = fun z => (z - a)⁻¹ • c := by
    ext z; rw [smul_eq_mul, div_eq_mul_inv, mul_comm]
  rw [h, circleIntegral.integral_smul_const,
    circleIntegral.integral_sub_inv_of_mem_ball (Metric.mem_ball_self hr), smul_eq_mul]

/-! The card's worked numbers, checked exactly. -/

-- the double roundabout's function splits: (4z + 10)/(z^2 − 25) = 3/(z − 5) + 1/(z + 5) off the holes
example (z : ℂ) (h5 : z - 5 ≠ 0) (hm5 : z + 5 ≠ 0) :
    (4 * z + 10) / (z ^ 2 - 25) = 3 / (z - 5) + 1 / (z + 5) := by
  have h : z ^ 2 - 25 = (z - 5) * (z + 5) := by ring
  rw [h, div_add_div _ _ h5 hm5]
  congr 1
  ring
-- the strengths: drop z − 5 and put z = 5, 30/10 = 3; drop z + 5 and put z = −5, −10/−10 = 1
example : ((4 * 5 + 10 : ℚ) / (5 + 5) = 3) ∧ ((4 * (-5) + 10 : ℚ) / (-5 - 5) = 1) := by norm_num
-- two laps and the wrong way: 2 × 2πi and −2πi, divided by 2πi, give 2 and −1
example : (2 * (2 * Real.pi * I)) / (2 * Real.pi * I) = 2 ∧
    (-(2 * Real.pi * I)) / (2 * Real.pi * I) = -1 := by
  have h : (2 * Real.pi * I) ≠ 0 := by
    simp [Real.pi_ne_zero, I_ne_zero]
  exact ⟨by field_simp, by field_simp⟩
-- figure-eight: (+1)(2πi · 3) + (−1)(2πi · 1) = 4πi
example : (1 : ℂ) * (2 * Real.pi * I * 3) + (-1) * (2 * Real.pi * I * 1) = 4 * Real.pi * I := by ring
-- the oval lane round both holes: (+1)(2πi · 3) + (+1)(2πi · 1) = 8πi
example : (1 : ℂ) * (2 * Real.pi * I * 3) + 1 * (2 * Real.pi * I * 1) = 8 * Real.pi * I := by ring
-- the same sums as multiples of 2πi: the figure-eight gives 2, the oval 4, half the big loop's value
example : (1 : ℤ) * 3 + (-1) * 1 = 2 ∧ (1 : ℤ) * 3 + 1 * 1 = 4 ∧ (2 : ℤ) * 2 = 4 := by decide
-- the mistakes: direction ignored gives 4 (8πi), not 2 (4πi); two laps read as once give 1, not 2
example : (1 : ℤ) * 3 + 1 * 1 ≠ 1 * 3 + (-1) * 1 ∧ (1 : ℤ) ≠ 2 := by decide

#print axioms loop_integral_eq_sum_winding_number_mul_small_circle
#print axioms winding_number_is_whole
#print axioms small_circle_integral_eq_two_pi_I_mul_strength
