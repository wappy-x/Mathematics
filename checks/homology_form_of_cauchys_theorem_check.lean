-- Cauchy's theorem for cycles: if a cycle of closed piecewise smooth loops in an open set U winds zero times round every point outside U, every function holomorphic on U integrates to zero over it, the cycle gives Cauchy's integral formula with its winding number, and on the washer 1 < |z| < 3 the circle of radius 2 minus the circle of radius 1.5 gives 2πi − 2πi = 0 for 1/z.
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.Analysis.Complex.Liouville
import Mathlib.Analysis.Complex.RemovableSingularity
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv

open Complex MeasureTheory Set

/-- The winding number n(γ, a) of a loop γ(t), 0 ≤ t ≤ T, with velocity γ'(t), round the point a:
the integral of dz/(z − a) once round the loop, divided by 2πi. -/
noncomputable def windingNumber (γ γ' : ℝ → ℂ) (T : ℝ) (a : ℂ) : ℂ :=
  (2 * Real.pi * I)⁻¹ * ∫ t in (0 : ℝ)..T, γ' t / (γ t - a)

/-- A cycle σ is m loops γ₁, …, γₘ (loop k runs for 0 ≤ t ≤ T k with velocity γ' k) with
whole-number coefficients n₁, …, nₘ. Its winding number round a adds up each loop's,
times its coefficient: n(σ, a) = Σ nₖ n(γₖ, a). -/
noncomputable def cycleWindingNumber {m : ℕ} (γ γ' : Fin m → ℝ → ℂ) (T : Fin m → ℝ)
    (n : Fin m → ℤ) (a : ℂ) : ℂ :=
  ∑ k, (n k : ℂ) * windingNumber (γ k) (γ' k) (T k) a

/-- The integral of f over the cycle σ adds up each loop's integral, times its coefficient:
∮_σ f(z) dz = Σ nₖ ∮_{γₖ} f(z) dz. -/
noncomputable def cycleIntegral (f : ℂ → ℂ) {m : ℕ} (γ γ' : Fin m → ℝ → ℂ) (T : Fin m → ℝ)
    (n : Fin m → ℤ) : ℂ :=
  ∑ k, (n k : ℂ) * ∫ t in (0 : ℝ)..T k, f (γ k t) * γ' k t

section hc_helpers

open Filter Topology Metric Interval

lemma hc_intInt {γ' φ : ℝ → ℂ} {T : ℝ} (hT : 0 ≤ T) (hγ' : IntervalIntegrable γ' volume 0 T)
    (hφ : ContinuousOn φ (Icc 0 T)) :
    IntervalIntegrable (fun t => φ t * γ' t) volume 0 T :=
  hγ'.continuousOn_mul (by rwa [uIcc_of_le hT])

lemma hc_loop_eq_zero {γ γ' : ℝ → ℂ} {T : ℝ} {E : Finset ℝ} (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T)
    (Φ φ : ℂ → ℂ) (hΦ : ∀ t ∈ Icc 0 T, HasDerivAt Φ (φ (γ t)) (γ t))
    (hφ : ContinuousOn (fun t => φ (γ t)) (Icc 0 T)) :
    ∫ t in (0:ℝ)..T, φ (γ t) * γ' t = 0 := by
  rw [integral_eq_of_hasDerivAt_off_countable_of_le (fun t => Φ (γ t)) _ hT E.countable_toSet
    ?_ ?_ (hc_intInt hT hγ' hφ)]
  · simp [hclosed]
  · intro t ht
    exact (hΦ t ht).continuousAt.comp_continuousWithinAt (hγ t ht)
  · intro t ht
    exact (hΦ t (Ioo_subset_Icc_self ht.1)).comp t (hderiv t ht)

lemma hc_dslope_continuousOn {U : Set ℂ} (hU : IsOpen U) {f : ℂ → ℂ}
    (hf : DifferentiableOn ℂ f U) :
    ContinuousOn (fun p : ℂ × ℂ => dslope f p.1 p.2) (U ×ˢ U) := by
  rintro ⟨a, b⟩ hp
  apply ContinuousAt.continuousWithinAt
  by_cases hab : a = b
  · subst hab
    have hfd : ∀ x ∈ U, HasDerivAt f (deriv f x) x := fun x hx =>
      (hf.differentiableAt (hU.mem_nhds hx)).hasDerivAt
    have hd : ContinuousAt (deriv f) a :=
      ((hf.analyticOnNhd hU) a hp.1).deriv.continuousAt
    show Tendsto _ _ _
    rw [Metric.tendsto_nhds]
    intro ε hε
    obtain ⟨δ, hδ, hδ'⟩ := Metric.continuousAt_iff.1 hd (ε / 2) (by linarith)
    obtain ⟨δ', hδ'pos, hδ'U⟩ := Metric.isOpen_iff.1 hU a hp.1
    set r := min δ δ' with hr
    have hrpos : 0 < r := lt_min hδ hδ'pos
    have hball : ball a r ⊆ U := (ball_subset_ball (min_le_right _ _)).trans hδ'U
    have hdev : ∀ x ∈ ball a r, ‖deriv f x - deriv f a‖ ≤ ε / 2 := by
      intro x hx
      have := hδ' (lt_of_lt_of_le (mem_ball.1 hx) (min_le_left _ _))
      rw [dist_eq_norm] at this
      exact this.le
    filter_upwards [prod_mem_nhds (ball_mem_nhds a hrpos) (ball_mem_nhds a hrpos)] with p hp'
    obtain ⟨x, y⟩ := p
    obtain ⟨hx, hy⟩ := hp'
    simp only [dslope_same]
    rw [dist_eq_norm]
    refine lt_of_le_of_lt ?_ (half_lt_self hε)
    by_cases hxy : y = x
    · subst hxy
      simpa [dslope_same] using hdev y hx
    · rw [dslope_of_ne f hxy, slope_def_field]
      have hg : ∀ z ∈ ball a r, HasDerivWithinAt (fun z => f z - deriv f a * z)
          (deriv f z - deriv f a) (ball a r) z := by
        intro z hz
        have := (hfd z (hball hz)).sub ((hasDerivAt_id' z).const_mul (deriv f a))
        exact (this.congr_deriv (by rw [mul_one])).hasDerivWithinAt
      have hmv := (convex_ball a r).norm_image_sub_le_of_norm_hasDerivWithin_le hg hdev hx hy
      have hne : y - x ≠ 0 := sub_ne_zero.2 hxy
      have heq : (f y - f x) / (y - x) - deriv f a
          = ((f y - deriv f a * y) - (f x - deriv f a * x)) / (y - x) := by
        field_simp; ring
      rw [heq, norm_div]
      rw [div_le_iff₀ (norm_pos_iff.2 hne)]
      exact hmv
  · have hcont : ContinuousAt (fun p : ℂ × ℂ => (f p.2 - f p.1) / (p.2 - p.1)) (a, b) := by
      apply ContinuousAt.div
      · exact ((hf.continuousOn.continuousAt (hU.mem_nhds hp.2)).comp continuousAt_snd).sub
          ((hf.continuousOn.continuousAt (hU.mem_nhds hp.1)).comp continuousAt_fst)
      · exact continuousAt_snd.sub continuousAt_fst
      · exact sub_ne_zero.2 (Ne.symm hab)
    apply hcont.congr
    filter_upwards [(isOpen_ne_fun continuous_fst continuous_snd).mem_nhds hab] with p hp
    rw [dslope_of_ne f (Ne.symm hp), slope_def_field]

lemma hc_wind_zero {γ γ' : ℝ → ℂ} {T : ℝ} {E : Finset ℝ} (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T)
    (a c : ℂ) (h : ∀ t ∈ Icc 0 T, (γ t - a) * c ∈ slitPlane) :
    ∫ t in (0:ℝ)..T, (γ t - a)⁻¹ * γ' t = 0 := by
  have hne : ∀ t ∈ Icc 0 T, γ t - a ≠ 0 ∧ c ≠ 0 := fun t ht =>
    mul_ne_zero_iff.1 (slitPlane_ne_zero (h t ht))
  apply hc_loop_eq_zero hT hγ hderiv hγ' hclosed (fun w => log ((w - a) * c)) (fun w => (w - a)⁻¹)
  · intro t ht
    have := (((hasDerivAt_id' (γ t)).sub_const a).mul_const c).clog (h t ht)
    refine this.congr_deriv ?_
    have := hne t ht
    field_simp [this.1, this.2]
  · exact (hγ.sub continuousOn_const).inv₀ fun t ht => (hne t ht).1

lemma hc_wind_eq {γ γ' : ℝ → ℂ} {T : ℝ} {E : Finset ℝ} (hT : 0 ≤ T)
    (hγ : ContinuousOn γ (Icc 0 T))
    (hderiv : ∀ t ∈ Ioo 0 T \ (E : Set ℝ), HasDerivAt γ (γ' t) t)
    (hγ' : IntervalIntegrable γ' volume 0 T) (hclosed : γ 0 = γ T)
    (a b : ℂ) (h : ∀ t ∈ Icc 0 T, (γ t - a) / (γ t - b) ∈ slitPlane)
    (hb : ∀ t ∈ Icc 0 T, γ t ≠ b) :
    ∫ t in (0:ℝ)..T, (γ t - a)⁻¹ * γ' t = ∫ t in (0:ℝ)..T, (γ t - b)⁻¹ * γ' t := by
  have ha : ∀ t ∈ Icc 0 T, γ t - a ≠ 0 := fun t ht =>
    (div_ne_zero_iff.1 (slitPlane_ne_zero (h t ht))).1
  have hb' : ∀ t ∈ Icc 0 T, γ t - b ≠ 0 := fun t ht => sub_ne_zero.2 (hb t ht)
  have hca : ContinuousOn (fun t => (γ t - a)⁻¹) (Icc 0 T) :=
    (hγ.sub continuousOn_const).inv₀ ha
  have hcb : ContinuousOn (fun t => (γ t - b)⁻¹) (Icc 0 T) :=
    (hγ.sub continuousOn_const).inv₀ hb'
  have key := hc_loop_eq_zero hT hγ hderiv hγ' hclosed (fun w => log ((w - a) / (w - b)))
    (fun w => (w - a)⁻¹ - (w - b)⁻¹) ?_ (hca.sub hcb)
  · rw [← sub_eq_zero, ← intervalIntegral.integral_sub (hc_intInt hT hγ' hca)
      (hc_intInt hT hγ' hcb)]
    rw [← key]
    congr 1; ext t; ring
  · intro t ht
    have := (((hasDerivAt_id' (γ t)).sub_const a).div ((hasDerivAt_id' (γ t)).sub_const b)
      (hb' t ht)).clog (h t ht)
    refine this.congr_deriv ?_
    have h1 := ha t ht
    have h2 := hb' t ht
    simp only [Pi.div_apply]
    field_simp

lemma hc_param_diff {γ γ' : ℝ → ℂ} {T : ℝ} (hT : 0 ≤ T) (hγ : ContinuousOn γ (Icc 0 T))
    (hγ' : IntervalIntegrable γ' volume 0 T) (K : ℂ → ℂ → ℂ) {Ω : Set ℂ} (hΩ : IsOpen Ω)
    (hK : ContinuousOn (fun p : ℂ × ℂ => K p.1 p.2) ((γ '' Icc 0 T) ×ˢ Ω))
    (hKd : ∀ t ∈ Icc 0 T, DifferentiableOn ℂ (K (γ t)) Ω) {z₀ : ℂ} (hz₀ : z₀ ∈ Ω) :
    DifferentiableAt ℂ (fun z => ∫ t in (0:ℝ)..T, K (γ t) z * γ' t) z₀ := by
  obtain ⟨ε, hε, hεΩ⟩ := Metric.isOpen_iff.1 hΩ z₀ hz₀
  set R := ε / 2 with hRdef
  have hR : 0 < R := by positivity
  have hRΩ : closedBall z₀ R ⊆ Ω := (closedBall_subset_ball (half_lt_self hε)).trans hεΩ
  have hS : IsCompact (γ '' Icc 0 T) := isCompact_Icc.image_of_continuousOn hγ
  obtain ⟨M, hM⟩ := (hS.prod (isCompact_closedBall z₀ R)).exists_bound_of_continuousOn
    (hK.mono (prod_mono subset_rfl hRΩ))
  have hcontz : ∀ z ∈ Ω, ContinuousOn (fun t => K (γ t) z) (Icc 0 T) := fun z hz =>
    hK.comp (hγ.prodMk continuousOn_const) (fun t ht => ⟨mem_image_of_mem γ ht, hz⟩)
  have hint : ∀ z ∈ Ω, IntervalIntegrable (fun t => K (γ t) z * γ' t) volume 0 T :=
    fun z hz => hc_intInt hT hγ' (hcontz z hz)
  have hIoc : ∀ t ∈ Ι (0:ℝ) T, t ∈ Icc 0 T := fun t ht => by
    rw [uIoc_of_le hT] at ht; exact Ioc_subset_Icc_self ht
  set r := R / 2 with hrdef
  have hr : 0 < r := by positivity
  have hball : ∀ z ∈ ball z₀ r, closedBall z r ⊆ closedBall z₀ R := fun z hz =>
    closedBall_subset_closedBall' (by rw [mem_ball] at hz; linarith)
  have hballΩ : ball z₀ r ⊆ Ω := fun z hz =>
    hRΩ (hball z hz (mem_closedBall_self hr.le))
  -- measurability of the derivative
  have hF'meas : AEStronglyMeasurable (fun t => deriv (K (γ t)) z₀)
      (volume.restrict (Ι (0:ℝ) T)) := by
    set h : ℕ → ℂ := fun n => ((R * (1 / ((n : ℝ) + 1)) : ℝ) : ℂ) with hhdef
    have hpos : ∀ n : ℕ, 0 < R * (1 / ((n : ℝ) + 1)) := fun n => by positivity
    have hle : ∀ n : ℕ, R * (1 / ((n : ℝ) + 1)) ≤ R := fun n => by
      have : 1 / ((n : ℝ) + 1) ≤ 1 := by
        rw [div_le_one (by positivity)]; linarith [n.cast_nonneg (α := ℝ)]
      nlinarith
    have hmem : ∀ n, z₀ + h n ∈ Ω := fun n => hRΩ (by
      rw [mem_closedBall, dist_eq_norm, add_sub_cancel_left, hhdef]
      simp only [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (hpos n)]
      exact hle n)
    have htend : Tendsto h atTop (𝓝[≠] 0) := by
      apply tendsto_nhdsWithin_iff.2 ⟨?_, Eventually.of_forall fun n => ?_⟩
      · have : Tendsto (fun n : ℕ => R * (1 / ((n : ℝ) + 1))) atTop (𝓝 (R * 0)) :=
          tendsto_one_div_add_atTop_nhds_zero_nat.const_mul R
        rw [mul_zero] at this
        have h2 := (Complex.continuous_ofReal.tendsto 0).comp this
        rw [Complex.ofReal_zero] at h2
        exact h2
      · simp only [mem_compl_iff, mem_singleton_iff, hhdef, Complex.ofReal_eq_zero]
        exact (hpos n).ne'
    refine aestronglyMeasurable_of_tendsto_ae atTop
      (f := fun n t => (h n)⁻¹ • (K (γ t) (z₀ + h n) - K (γ t) z₀)) (fun n => ?_) ?_
    · rw [uIoc_of_le hT]
      have hc : ContinuousOn (fun t => (h n)⁻¹ • (K (γ t) (z₀ + h n) - K (γ t) z₀))
          (Icc 0 T) :=
        (continuousOn_const (c := (h n)⁻¹)).smul ((hcontz _ (hmem n)).sub (hcontz _ hz₀))
      exact (hc.mono Ioc_subset_Icc_self).aestronglyMeasurable measurableSet_Ioc
    · rw [ae_restrict_iff' measurableSet_uIoc]
      refine Eventually.of_forall fun t ht => ?_
      exact ((hKd t (hIoc t ht)).differentiableAt
        (hΩ.mem_nhds hz₀)).hasDerivAt.tendsto_slope_zero.comp htend
  have key := intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le
    (μ := volume) (a := 0) (b := T)
    (F := fun z t => K (γ t) z * γ' t) (F' := fun z t => deriv (K (γ t)) z * γ' t) (x₀ := z₀)
    (bound := fun t => M / r * ‖γ' t‖) (s := ball z₀ r) (ball_mem_nhds z₀ hr)
    (eventually_of_mem (hΩ.mem_nhds hz₀) fun z hz =>
      (intervalIntegrable_iff.1 (hint z hz)).aestronglyMeasurable)
    (hint z₀ hz₀)
    (hF'meas.mul (intervalIntegrable_iff.1 hγ').aestronglyMeasurable) ?_
    (hγ'.norm.const_mul (M / r)) ?_
  · exact key.2.differentiableAt
  · refine Eventually.of_forall fun t ht z hz => ?_
    have htI := hIoc t ht
    rw [norm_mul]
    refine mul_le_mul_of_nonneg_right ?_ (norm_nonneg _)
    refine norm_deriv_le_of_forall_mem_sphere_norm_le hr
      ((hKd t htI).diffContOnCl_ball ((hball z hz).trans hRΩ)) fun ζ hζ => ?_
    exact hM (γ t, ζ) ⟨mem_image_of_mem γ htI, hball z hz (sphere_subset_closedBall hζ)⟩
  · refine Eventually.of_forall fun t ht z hz => ?_
    exact ((hKd t (hIoc t ht)).differentiableAt (hΩ.mem_nhds (hballΩ hz))).hasDerivAt.mul_const _

lemma hc_tendsto_zero {γ γ' : ℝ → ℂ} {T : ℝ} (hT : 0 ≤ T) (hγ : ContinuousOn γ (Icc 0 T))
    (hγ' : IntervalIntegrable γ' volume 0 T) (g : ℂ → ℂ)
    (hg : ContinuousOn (fun t => g (γ t)) (Icc 0 T)) :
    Tendsto (fun z => ∫ t in (0:ℝ)..T, g (γ t) / (γ t - z) * γ' t) (cocompact ℂ) (𝓝 0) := by
  obtain ⟨R₀, hR₀⟩ := isCompact_Icc.exists_bound_of_continuousOn hγ
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hg
  set C := ∫ t in (0:ℝ)..T, ‖γ' t‖
  have hnorm : Tendsto (fun z : ℂ => ‖z‖ + -R₀) (cocompact ℂ) atTop :=
    tendsto_norm_cocompact_atTop.atTop_add tendsto_const_nhds
  refine squeeze_zero_norm' (a := fun z => M * C / (‖z‖ + -R₀)) ?_ ?_
  · filter_upwards [tendsto_norm_cocompact_atTop.eventually_gt_atTop R₀] with z hz
    have hpos : 0 < ‖z‖ + -R₀ := by linarith
    have hb : ∀ t ∈ Icc 0 T, ‖g (γ t) / (γ t - z) * γ' t‖ ≤ M / (‖z‖ + -R₀) * ‖γ' t‖ := by
      intro t ht
      rw [norm_mul, norm_div]
      refine mul_le_mul_of_nonneg_right ?_ (norm_nonneg _)
      have h1 : ‖z‖ + -R₀ ≤ ‖γ t - z‖ := by
        have := norm_sub_norm_le z (γ t)
        rw [norm_sub_rev] at this
        linarith [hR₀ t ht]
      exact div_le_div₀ ((norm_nonneg _).trans (hM t ht)) (hM t ht) hpos h1
    calc ‖∫ t in (0:ℝ)..T, g (γ t) / (γ t - z) * γ' t‖
        ≤ ∫ t in (0:ℝ)..T, M / (‖z‖ + -R₀) * ‖γ' t‖ :=
          intervalIntegral.norm_integral_le_of_norm_le hT
            (Eventually.of_forall fun t ht => hb t (Ioc_subset_Icc_self ht))
            (hγ'.norm.const_mul _)
      _ = M * C / (‖z‖ + -R₀) := by
          rw [intervalIntegral.integral_const_mul]; ring
  · exact hnorm.const_div_atTop _ |>.congr (fun _ => rfl)

lemma hc_loop_decomp {γ γ' : ℝ → ℂ} {T : ℝ} (hT : 0 ≤ T) (hγ : ContinuousOn γ (Icc 0 T))
    (hγ' : IntervalIntegrable γ' volume 0 T) (f : ℂ → ℂ)
    (hfc : ContinuousOn f (γ '' Icc 0 T)) (z : ℂ) (hz : ∀ t ∈ Icc 0 T, γ t ≠ z) :
    ∫ t in (0:ℝ)..T, dslope f (γ t) z * γ' t
      = (∫ t in (0:ℝ)..T, f (γ t) / (γ t - z) * γ' t)
        - f z * ∫ t in (0:ℝ)..T, (γ t - z)⁻¹ * γ' t := by
  have hne : ∀ t ∈ Icc 0 T, γ t - z ≠ 0 := fun t ht => sub_ne_zero.2 (hz t ht)
  have hfγ : ContinuousOn (fun t => f (γ t)) (Icc 0 T) :=
    hfc.comp hγ (fun t ht => mem_image_of_mem γ ht)
  have hinv : ContinuousOn (fun t => (γ t - z)⁻¹) (Icc 0 T) :=
    (hγ.sub continuousOn_const).inv₀ hne
  have hq : ContinuousOn (fun t => f (γ t) / (γ t - z)) (Icc 0 T) :=
    hfγ.div (hγ.sub continuousOn_const) hne
  have h1 := hc_intInt hT hγ' hq
  have h2 := hc_intInt hT hγ' hinv
  have h5 := intervalIntegral.integral_sub h1 (h2.const_mul (f z))
  rw [← intervalIntegral.integral_const_mul]
  refine Eq.trans ?_ h5
  refine intervalIntegral.integral_congr fun t ht => ?_
  rw [uIcc_of_le hT] at ht
  have h3 := hne t ht
  rw [dslope_of_ne f (hz t ht).symm, slope_def_field]
  have h4 : z - γ t ≠ 0 := sub_ne_zero.2 (hz t ht).symm
  field_simp
  ring

lemma hc_main {U : Set ℂ} (hU : IsOpen U) (f : ℂ → ℂ) (hf : DifferentiableOn ℂ f U)
    {m : ℕ} (γ γ' : Fin m → ℝ → ℂ) (T : Fin m → ℝ) (E : Fin m → Finset ℝ)
    (hT : ∀ k, 0 ≤ T k)
    (hγ : ∀ k, ContinuousOn (γ k) (Icc 0 (T k)))
    (hderiv : ∀ k, ∀ t ∈ Ioo 0 (T k) \ (E k : Set ℝ), HasDerivAt (γ k) (γ' k t) t)
    (hγ' : ∀ k, IntervalIntegrable (γ' k) volume 0 (T k))
    (hclosed : ∀ k, γ k 0 = γ k (T k))
    (hin : ∀ k, ∀ t ∈ Icc 0 (T k), γ k t ∈ U)
    (n : Fin m → ℤ)
    (hhom : ∀ a ∉ U, cycleWindingNumber γ γ' T n a = 0) :
    ∀ z ∈ U, ∑ k, (n k : ℂ) * ∫ t in (0:ℝ)..T k, dslope f (γ k t) z * γ' k t = 0 := by
  classical
  set S := ⋃ k, γ k '' Icc 0 (T k) with hSdef
  have hSc : IsCompact S := isCompact_iUnion fun k => isCompact_Icc.image_of_continuousOn (hγ k)
  have hSU : S ⊆ U := iUnion_subset fun k => image_subset_iff.2 (hin k)
  have hmemS : ∀ k, ∀ t ∈ Icc 0 (T k), γ k t ∈ S := fun k t ht =>
    mem_iUnion.2 ⟨k, mem_image_of_mem _ ht⟩
  have hfc : ∀ k, ContinuousOn f (γ k '' Icc 0 (T k)) := fun k =>
    hf.continuousOn.mono (image_subset_iff.2 (hin k))
  set φ : ℂ → ℂ := fun z => ∑ k, (n k : ℂ) * ∫ t in (0:ℝ)..T k, dslope f (γ k t) z * γ' k t
    with hφdef
  set ψ : ℂ → ℂ := fun z => ∑ k, (n k : ℂ) * ∫ t in (0:ℝ)..T k, f (γ k t) / (γ k t - z) * γ' k t
    with hψdef
  set W : ℂ → ℂ := fun z => ∑ k, (n k : ℂ) * ∫ t in (0:ℝ)..T k, (γ k t - z)⁻¹ * γ' k t
    with hWdef
  have hW : ∀ z, cycleWindingNumber γ γ' T n z = (2 * Real.pi * I)⁻¹ * W z := by
    intro z
    simp only [cycleWindingNumber, windingNumber, hWdef, Finset.mul_sum]
    refine Finset.sum_congr rfl fun k _ => ?_
    have : (∫ t in (0:ℝ)..T k, γ' k t / (γ k t - z))
        = ∫ t in (0:ℝ)..T k, (γ k t - z)⁻¹ * γ' k t := by
      congr 1; ext t; rw [div_eq_inv_mul]
    rw [this]; ring
  have hA : ∀ z, z ∉ S → φ z = ψ z - f z * W z := by
    intro z hz
    have hz' : ∀ k, ∀ t ∈ Icc 0 (T k), γ k t ≠ z := fun k t ht h => hz (h ▸ hmemS k t ht)
    simp only [hφdef, hψdef, hWdef, Finset.mul_sum, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [hc_loop_decomp (hT k) (hγ k) (hγ' k) f (hfc k) z (hz' k)]
    ring
  obtain ⟨R, hR⟩ := hSc.isBounded.exists_norm_le
  have hfar : ∀ z : ℂ, max R 0 < ‖z‖ → z ∉ S ∧ W z = 0 := by
    intro z hz
    have hzR : R < ‖z‖ := lt_of_le_of_lt (le_max_left _ _) hz
    have hz0 : z ≠ 0 := norm_pos_iff.1 (lt_of_le_of_lt (le_max_right _ _) hz)
    refine ⟨fun h => absurd (hR z h) (not_le.2 hzR), ?_⟩
    simp only [hWdef]
    refine Finset.sum_eq_zero fun k _ => ?_
    rw [hc_wind_zero (hT k) (hγ k) (hderiv k) (hγ' k) (hclosed k) z (-z⁻¹) ?_, mul_zero]
    intro t ht
    have heq : (γ k t - z) * -z⁻¹ = 1 - γ k t / z := by field_simp; ring
    rw [heq, mem_slitPlane_iff]
    left
    have h1 := re_le_norm (γ k t / z)
    rw [norm_div] at h1
    have h2 : ‖γ k t‖ / ‖z‖ < 1 :=
      (div_lt_one (norm_pos_iff.2 hz0)).2 (lt_of_le_of_lt (hR _ (hmemS k t ht)) hzR)
    simp only [sub_re, one_re]
    linarith
  have hloc : ∀ z₀, z₀ ∉ S → ∀ᶠ z in 𝓝 z₀, W z = W z₀ := by
    intro z₀ hz₀
    obtain ⟨δ, hδ, hδS⟩ := Metric.isOpen_iff.1 hSc.isClosed.isOpen_compl z₀ hz₀
    filter_upwards [ball_mem_nhds z₀ hδ] with z hz
    simp only [hWdef]
    refine Finset.sum_congr rfl fun k _ => ?_
    congr 1
    refine hc_wind_eq (hT k) (hγ k) (hderiv k) (hγ' k) (hclosed k) z z₀ ?_
      (fun t ht h => hz₀ (h ▸ hmemS k t ht))
    intro t ht
    have hw := hmemS k t ht
    have hdist : δ ≤ ‖γ k t - z₀‖ := by
      by_contra hlt
      exact hδS (mem_ball.2 (by rw [dist_eq_norm]; exact not_le.1 hlt)) hw
    have hne : γ k t - z₀ ≠ 0 := norm_pos_iff.1 (lt_of_lt_of_le hδ hdist)
    have heq : (γ k t - z) / (γ k t - z₀) = 1 - (z - z₀) / (γ k t - z₀) := by
      field_simp; ring
    rw [heq, mem_slitPlane_iff]
    left
    have h1 := re_le_norm ((z - z₀) / (γ k t - z₀))
    rw [norm_div] at h1
    have h2 : ‖z - z₀‖ / ‖γ k t - z₀‖ < 1 := by
      rw [div_lt_one (norm_pos_iff.2 hne)]
      rw [mem_ball, dist_eq_norm] at hz
      linarith
    simp only [sub_re, one_re]
    linarith
  have hφd : ∀ z₀ ∈ U, DifferentiableAt ℂ φ z₀ := by
    intro z₀ hz₀
    simp only [hφdef]
    apply DifferentiableAt.fun_sum
    intro k _
    apply DifferentiableAt.const_mul
    exact hc_param_diff (hT k) (hγ k) (hγ' k) (fun w z => dslope f w z) hU
      ((hc_dslope_continuousOn hU hf).mono (prod_mono (image_subset_iff.2 (hin k)) subset_rfl))
      (fun t ht => (differentiableOn_dslope (hU.mem_nhds (hin k t ht))).2 hf) hz₀
  have hψd : ∀ z₀ ∉ S, DifferentiableAt ℂ ψ z₀ := by
    intro z₀ hz₀
    simp only [hψdef]
    apply DifferentiableAt.fun_sum
    intro k _
    apply DifferentiableAt.const_mul
    refine hc_param_diff (hT k) (hγ k) (hγ' k) (fun w z => f w / (w - z))
      hSc.isClosed.isOpen_compl ?_ ?_ hz₀
    · refine ((hfc k).comp continuousOn_fst
        (fun p (hp : p ∈ (γ k '' Icc 0 (T k)) ×ˢ Sᶜ) => hp.1)).div
        (continuousOn_fst.sub continuousOn_snd) ?_
      rintro ⟨w, z⟩ ⟨hw, hz⟩ h
      obtain ⟨t, ht, rfl⟩ := hw
      exact hz (sub_eq_zero.1 h ▸ hmemS k t ht)
    · intro t ht
      refine DifferentiableOn.div (differentiableOn_const _)
        ((differentiableOn_const _).sub differentiableOn_id) ?_
      intro z hz h
      exact hz (sub_eq_zero.1 h ▸ hmemS k t ht)
  set H : ℂ → ℂ := fun z => if z ∈ U then φ z else ψ z with hHdef
  have hHd : Differentiable ℂ H := by
    intro z₀
    by_cases hz₀ : z₀ ∈ U
    · refine (hφd z₀ hz₀).congr_of_eventuallyEq ?_
      filter_upwards [hU.mem_nhds hz₀] with z hz
      simp only [hHdef, hz, ↓reduceIte]
    · have hz₀S : z₀ ∉ S := fun h => hz₀ (hSU h)
      have hW0 : W z₀ = 0 := by
        have := hhom z₀ hz₀
        rw [hW] at this
        simpa [Real.pi_ne_zero, I_ne_zero] using this
      refine (hψd z₀ hz₀S).congr_of_eventuallyEq ?_
      filter_upwards [hloc z₀ hz₀S, hSc.isClosed.isOpen_compl.mem_nhds hz₀S] with z hz hzS
      simp only [hHdef]
      split_ifs
      · rw [hA z hzS, hz, hW0, mul_zero, sub_zero]
      · rfl
  have hHt : Tendsto H (cocompact ℂ) (𝓝 0) := by
    have hψt : Tendsto ψ (cocompact ℂ) (𝓝 0) := by
      have := tendsto_finsetSum (Finset.univ : Finset (Fin m)) fun k _ =>
        (hc_tendsto_zero (hT k) (hγ k) (hγ' k) f
          ((hfc k).comp (hγ k) (fun t ht => mem_image_of_mem _ ht))).const_mul (n k : ℂ)
      simpa [hψdef] using this
    refine hψt.congr' ?_
    filter_upwards [tendsto_norm_cocompact_atTop.eventually_gt_atTop (max R 0)] with z hz
    obtain ⟨hzS, hWz⟩ := hfar z hz
    simp only [hHdef]
    split_ifs
    · rw [hA z hzS, hWz, mul_zero, sub_zero]
    · rfl
  intro z hz
  have := hHd.apply_eq_of_tendsto_cocompact z hHt
  simpa [hHdef, hz] using this

end hc_helpers

#print axioms hc_intInt
#print axioms hc_loop_eq_zero
#print axioms hc_dslope_continuousOn
#print axioms hc_wind_zero
#print axioms hc_wind_eq
#print axioms hc_param_diff
#print axioms hc_tendsto_zero
#print axioms hc_loop_decomp
#print axioms hc_main

/-- Cauchy's theorem for cycles (the homology form). Let U be an open set and f holomorphic on all
of U. Let σ be a cycle: m closed loops γₖ(t), 0 ≤ t ≤ T k, each made of finitely many smooth pieces
(velocity γ' k off a finite set E k of corners), each lying in U, with whole-number coefficients
n k. If the cycle winds zero times round every point outside U, then the integral of f over the
cycle is zero. -/
theorem cycle_integral_eq_zero_of_winding_number_eq_zero_outside
    {U : Set ℂ} (hU : IsOpen U) (f : ℂ → ℂ) (hf : DifferentiableOn ℂ f U)
    {m : ℕ} (γ γ' : Fin m → ℝ → ℂ) (T : Fin m → ℝ) (E : Fin m → Finset ℝ)
    (hT : ∀ k, 0 ≤ T k)
    (hγ : ∀ k, ContinuousOn (γ k) (Icc 0 (T k)))
    (hderiv : ∀ k, ∀ t ∈ Ioo 0 (T k) \ (E k : Set ℝ), HasDerivAt (γ k) (γ' k t) t)
    (hγ' : ∀ k, IntervalIntegrable (γ' k) volume 0 (T k))
    (hclosed : ∀ k, γ k 0 = γ k (T k))
    (hin : ∀ k, ∀ t ∈ Icc 0 (T k), γ k t ∈ U)
    (n : Fin m → ℤ)
    (hhom : ∀ a ∉ U, cycleWindingNumber γ γ' T n a = 0) :
    cycleIntegral f γ γ' T n = 0 := by
  rcases Nat.eq_zero_or_pos m with hm | hm
  · subst hm; simp [cycleIntegral]
  set z := γ ⟨0, hm⟩ 0 with hzdef
  have hz : z ∈ U := hin _ 0 ⟨le_rfl, hT _⟩
  have hF : DifferentiableOn ℂ (fun w => (w - z) * f w) U :=
    (differentiableOn_id.sub_const z).mul hf
  have key := hc_main hU _ hF γ γ' T E hT hγ hderiv hγ' hclosed hin n hhom z hz
  have hds : ∀ w ∈ U, dslope (fun w => (w - z) * f w) w z = f w := by
    intro w hw
    by_cases hwz : z = w
    · rw [← hwz, dslope_same]
      have : HasDerivAt (fun w => (w - z) * f w) (1 * f z + (z - z) * deriv f z) z :=
        ((hasDerivAt_id' z).sub_const z).mul (hf.differentiableAt (hU.mem_nhds hz)).hasDerivAt
      rw [this.deriv]; ring
    · rw [dslope_of_ne _ hwz, slope_def_field]
      have h1 : w - z ≠ 0 := sub_ne_zero.2 (Ne.symm hwz)
      have h2 : z - w ≠ 0 := sub_ne_zero.2 hwz
      field_simp
      ring
  rw [← key]
  unfold cycleIntegral
  refine Finset.sum_congr rfl fun k _ => ?_
  congr 1
  refine intervalIntegral.integral_congr fun t ht => ?_
  rw [uIcc_of_le (hT k)] at ht
  simp only [hds _ (hin k t ht)]

/-- Cauchy's integral formula for cycles. Under the same hypotheses, for every point z of U that
lies on none of the loops, the cycle's winding number round z times f(z) equals 1/(2πi) times the
integral of f(w)/(w − z) over the cycle: n(σ, z) f(z) = (1/2πi) ∮_σ f(w)/(w − z) dw. -/
theorem cycle_winding_number_mul_eq_cauchy_integral
    {U : Set ℂ} (hU : IsOpen U) (f : ℂ → ℂ) (hf : DifferentiableOn ℂ f U)
    {m : ℕ} (γ γ' : Fin m → ℝ → ℂ) (T : Fin m → ℝ) (E : Fin m → Finset ℝ)
    (hT : ∀ k, 0 ≤ T k)
    (hγ : ∀ k, ContinuousOn (γ k) (Icc 0 (T k)))
    (hderiv : ∀ k, ∀ t ∈ Ioo 0 (T k) \ (E k : Set ℝ), HasDerivAt (γ k) (γ' k t) t)
    (hγ' : ∀ k, IntervalIntegrable (γ' k) volume 0 (T k))
    (hclosed : ∀ k, γ k 0 = γ k (T k))
    (hin : ∀ k, ∀ t ∈ Icc 0 (T k), γ k t ∈ U)
    (n : Fin m → ℤ)
    (hhom : ∀ a ∉ U, cycleWindingNumber γ γ' T n a = 0)
    (z : ℂ) (hz : z ∈ U) (hoff : ∀ k, ∀ t ∈ Icc 0 (T k), γ k t ≠ z) :
    cycleWindingNumber γ γ' T n z * f z
      = (2 * Real.pi * I)⁻¹ * cycleIntegral (fun w => f w / (w - z)) γ γ' T n := by
  have key := hc_main hU f hf γ γ' T E hT hγ hderiv hγ' hclosed hin n hhom z hz
  have hdec := fun k => hc_loop_decomp (hT k) (hγ k) (hγ' k) f
    (hf.continuousOn.mono (image_subset_iff.2 (hin k))) z (hoff k)
  simp only [hdec, mul_sub, Finset.sum_sub_distrib, sub_eq_zero] at key
  have hB : ∀ k, (∫ t in (0:ℝ)..T k, γ' k t / (γ k t - z))
      = ∫ t in (0:ℝ)..T k, (γ k t - z)⁻¹ * γ' k t := fun k => by
    congr 1; ext t; rw [div_eq_inv_mul]
  unfold cycleWindingNumber windingNumber cycleIntegral
  simp only [hB]
  rw [key, Finset.sum_mul, Finset.mul_sum]
  refine Finset.sum_congr rfl fun k _ => ?_
  ring

/-- The washer example. Round 0, the circle of radius 2 and the circle of radius 1.5, each run once
anticlockwise, each give 2πi for 1/z, so the cycle C(2) − C(1.5) gives 2πi − 2πi = 0, though
neither circle alone gives 0. -/
theorem washer_cycle_integral_inv_eq_zero :
    (∮ z in C(0, 2), z⁻¹) = 2 * Real.pi * I ∧
    (∮ z in C(0, 3 / 2), z⁻¹) = 2 * Real.pi * I ∧
    (∮ z in C(0, 2), z⁻¹) - (∮ z in C(0, 3 / 2), z⁻¹) = 0 := by
  have h1 : (∮ z in C(0, 2), z⁻¹) = 2 * Real.pi * I := by
    simpa using circleIntegral.integral_sub_inv_of_mem_ball (c := 0) (w := 0) (R := 2)
      (by simp)
  have h2 : (∮ z in C(0, 3 / 2), z⁻¹) = 2 * Real.pi * I := by
    simpa using circleIntegral.integral_sub_inv_of_mem_ball (c := 0) (w := 0) (R := 3 / 2)
      (by simp)
  exact ⟨h1, h2, by rw [h1, h2, sub_self]⟩

/-! The card's worked numbers, checked exactly. -/

-- the cycle C(2) − C(1.5) winds 1 − 1 = 0 times round 0 and 0 − 0 = 0 times beyond radius 3
example : (1 : ℤ) - 1 = 0 ∧ (0 : ℤ) - 0 = 0 := by decide

-- at 1.75 the cycle winds 1 − 0 = 1 time; adding the inner circle instead winds 1 + 1 = 2 times
example : (1 : ℤ) - 0 = 1 ∧ (1 : ℤ) + 1 = 2 := by decide

-- two holes, strengths 1 and 3: the big circle sees 1 + 3 = 4, and 4 − 1 − 3 = 0
example : (1 : ℤ) + 3 = 4 ∧ (4 : ℤ) - 1 - 3 = 0 := by decide

-- the formula at 0 for g: g(0) = −1/1.5 + 3/1.5 = 4/3
example : (-1 : ℚ) / (3 / 2) + 3 / (3 / 2) = 4 / 3 := by norm_num

#print axioms cycle_integral_eq_zero_of_winding_number_eq_zero_outside
#print axioms cycle_winding_number_mul_eq_cauchy_integral
#print axioms washer_cycle_integral_inv_eq_zero
