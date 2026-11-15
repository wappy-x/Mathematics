-- The delta: read on smooth probes, the step's derivative is the delta at the switch, a jump of size J adds J times a delta at the jump to the ordinary slope, and the derivative of ln|t| is the principal value of 1/t.
import Mathlib.Analysis.Distribution.Distribution
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.Integrability.Basic
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Tactic.NormNum

/-! Setting, in the card's notation, using Mathlib's own distributions.
* A test function (the card's probe `φ`) is an element of `𝓓(⊤, ℝ)`: a real function on the
  whole line `⊤ : Opens ℝ` that is infinitely smooth and zero outside a bounded interval.
* A distribution `T` is an element of `𝓓'(⊤, ℝ)`: a continuous linear rule `φ ↦ T φ`.
* An ordinary locally integrable function `f` gives the distribution
  `Distribution.ofFun ⊤ f volume ⊤`, which reads `φ` as `∫ t, φ t * f t`.
* The derivative of a distribution is Mathlib's `∂_{1} T`, defined by moving the derivative onto
  the probe with a minus sign: `(∂_{1} T) φ = T (-φ')` (`Distribution.lineDerivOp_apply_apply`).
* `Distribution.delta a` is the card's `δ_a`: it reads a probe's value `φ a`.
* The step `H` is `Set.indicator (Set.Ici 0) 1`: 0 for `t < 0`, 1 for `t ≥ 0`.
* "From the left of `a`" and "from the right of `a`" are the filters `𝓝[<] a` and `𝓝[>] a`;
  `ε → 0` from above is `𝓝[>] 0`.
* `{f'}`, the ordinary slope away from the jump, is `deriv f` (its value at the single point
  `a` does not change any integral). -/

open MeasureTheory Filter Topology Set TopologicalSpace
open scoped Distributions LineDeriv ContDiff

namespace DiracDeltaJumps

/-- The card's step `H(t)`: 0 for `t < 0` and 1 for `t ≥ 0`. -/
noncomputable def step : ℝ → ℝ := (Ici (0 : ℝ)).indicator 1

lemma probe_deriv_apply (φ : 𝓓((⊤ : Opens ℝ), ℝ)) (x : ℝ) :
    (∂_{(1 : ℝ)} φ : 𝓓((⊤ : Opens ℝ), ℝ)) x = deriv φ x := by
  rw [TestFunction.lineDerivOp_eq_lineDerivCLM ℝ, TestFunction.lineDerivCLM_apply_of_le (by simp)]
  rw [(φ.contDiff.differentiable (by simp)).differentiableAt.lineDeriv_eq_fderiv]
  simp

lemma probe_hasDerivAt (φ : 𝓓((⊤ : Opens ℝ), ℝ)) (x : ℝ) :
    HasDerivAt φ ((∂_{(1 : ℝ)} φ : 𝓓((⊤ : Opens ℝ), ℝ)) x) x := by
  rw [probe_deriv_apply]
  exact ((φ.contDiff.differentiable (by simp)) x).hasDerivAt

lemma probe_eventually_zero_atTop (φ : 𝓓((⊤ : Opens ℝ), ℝ)) :
    ∀ᶠ x in atTop, φ x = 0 := by
  obtain ⟨R, hR⟩ := φ.hasCompactSupport.isCompact.bddAbove
  filter_upwards [eventually_gt_atTop R] with x hx
  exact image_eq_zero_of_notMem_tsupport fun h => absurd (hR h) (not_le.mpr hx)

lemma probe_eventually_zero_atBot (φ : 𝓓((⊤ : Opens ℝ), ℝ)) :
    ∀ᶠ x in atBot, φ x = 0 := by
  obtain ⟨R, hR⟩ := φ.hasCompactSupport.isCompact.bddBelow
  filter_upwards [eventually_lt_atBot R] with x hx
  exact image_eq_zero_of_notMem_tsupport fun h => absurd (hR h) (not_le.mpr hx)

lemma locInt_of_pieces (g : ℝ → ℝ) (a l r : ℝ) (hc : ContinuousOn g {a}ᶜ)
    (hl : Tendsto g (𝓝[<] a) (𝓝 l)) (hr : Tendsto g (𝓝[>] a) (𝓝 r)) :
    LocallyIntegrable g volume := by
  have hmeas : AEStronglyMeasurable g volume := by
    have := hc.aestronglyMeasurable (μ := volume) (measurableSet_singleton a).compl
    rwa [restrict_compl_singleton] at this
  have hbd : ∀ x, ∃ M, ∀ᶠ y in 𝓝 x, y ≠ a → ‖g y‖ ≤ M := by
    intro x
    by_cases hx : x = a
    · subst hx
      refine ⟨max (‖l‖ + 1) (‖r‖ + 1), ?_⟩
      have h1 : ∀ᶠ y in 𝓝[<] x, ‖g y‖ ≤ max (‖l‖ + 1) (‖r‖ + 1) :=
        (hl.norm.eventually (gt_mem_nhds (lt_add_one _))).mono
          fun y hy => hy.le.trans (le_max_left _ _)
      have h2 : ∀ᶠ y in 𝓝[>] x, ‖g y‖ ≤ max (‖l‖ + 1) (‖r‖ + 1) :=
        (hr.norm.eventually (gt_mem_nhds (lt_add_one _))).mono
          fun y hy => hy.le.trans (le_max_right _ _)
      have h3 := eventually_sup.mpr ⟨h1, h2⟩
      rw [nhdsLT_sup_nhdsGT] at h3
      exact eventually_nhdsWithin_iff.mp h3
    · refine ⟨‖g x‖ + 1, ?_⟩
      have hca : ContinuousAt g x := hc.continuousAt (isOpen_compl_singleton.mem_nhds hx)
      exact (hca.norm.eventually (gt_mem_nhds (lt_add_one _))).mono fun y hy _ => hy.le
  intro x
  obtain ⟨M, hM⟩ := hbd x
  obtain ⟨U, hU, hUo, hxU⟩ := eventually_nhds_iff.mp hM
  refine ⟨U ∩ Ioo (x - 1) (x + 1), inter_mem (hUo.mem_nhds hxU) (Ioo_mem_nhds (by linarith) (by linarith)), ?_⟩
  refine Measure.integrableOn_of_bounded (M := M) ?_ hmeas ?_
  · exact ((measure_mono inter_subset_right).trans_lt measure_Ioo_lt_top).ne
  · have hs : MeasurableSet (U ∩ Ioo (x - 1) (x + 1)) := hUo.measurableSet.inter measurableSet_Ioo
    rw [ae_restrict_iff' hs]
    filter_upwards [(countable_singleton a).ae_notMem volume] with y hy hyU
    exact hU y hyU.1 hy


lemma jump_aux (f : ℝ → ℝ) (a fl fr dl dr : ℝ)
    (hleft : ContDiffOn ℝ ∞ f (Iio a)) (hright : ContDiffOn ℝ ∞ f (Ioi a))
    (hfl : Tendsto f (𝓝[<] a) (𝓝 fl)) (hfr : Tendsto f (𝓝[>] a) (𝓝 fr))
    (hdl : Tendsto (deriv f) (𝓝[<] a) (𝓝 dl)) (hdr : Tendsto (deriv f) (𝓝[>] a) (𝓝 dr)) :
    (∂_{(1 : ℝ)} (Distribution.ofFun (⊤ : Opens ℝ) f volume ⊤) : 𝓓'((⊤ : Opens ℝ), ℝ)) =
      Distribution.ofFun (⊤ : Opens ℝ) (deriv f) volume ⊤ + (fr - fl) • Distribution.delta a := by
  have pieces : ∀ g : ℝ → ℝ, ContinuousOn g (Iio a) → ContinuousOn g (Ioi a) →
      ContinuousOn g {a}ᶜ := by
    intro g h1 h2 y hy
    rcases lt_or_gt_of_ne hy with h | h
    · exact (h1.continuousAt (Iio_mem_nhds h)).continuousWithinAt
    · exact (h2.continuousAt (Ioi_mem_nhds h)).continuousWithinAt
  have hcf : ContinuousOn f {a}ᶜ := pieces f hleft.continuousOn hright.continuousOn
  have hcd : ContinuousOn (deriv f) {a}ᶜ :=
    pieces _ (hleft.continuousOn_deriv_of_isOpen isOpen_Iio (by simp))
      (hright.continuousOn_deriv_of_isOpen isOpen_Ioi (by simp))
  have hfΩ : LocallyIntegrableOn f ((⊤ : Opens ℝ) : Set ℝ) volume := by
    simpa using (locInt_of_pieces f a fl fr hcf hfl hfr).locallyIntegrableOn univ
  have hdΩ : LocallyIntegrableOn (deriv f) ((⊤ : Opens ℝ) : Set ℝ) volume := by
    simpa using (locInt_of_pieces _ a dl dr hcd hdl hdr).locallyIntegrableOn univ
  ext φ
  rw [Distribution.lineDerivOp_apply_apply, Distribution.ofFun_apply hfΩ,
    add_apply, Distribution.ofFun_apply hdΩ,
    smul_apply, Distribution.delta_apply]
  set ψ : 𝓓((⊤ : Opens ℝ), ℝ) := ∂_{(1 : ℝ)} φ with hψ
  have hv : ∀ x, HasDerivAt φ (ψ x) x := probe_hasDerivAt φ
  have hI1 : Integrable (f * ⇑ψ) volume :=
    (ψ.integrable_smul hfΩ).congr (ae_of_all _ fun x => by simp [mul_comm])
  have hI2 : Integrable (deriv f * ⇑φ) volume :=
    (φ.integrable_smul hdΩ).congr (ae_of_all _ fun x => by simp [mul_comm])
  have hφc : ∀ x, Tendsto φ (𝓝 x) (𝓝 (φ x)) := fun x => φ.continuous.tendsto x
  have hR := integral_Ioi_mul_deriv_eq_deriv_mul (a := a) (u := f) (v := φ) (u' := deriv f)
    (v' := ψ) (a' := fr * φ a) (b' := 0)
    (fun x hx => (((hright.differentiableOn (by simp)) x hx).differentiableAt
      (isOpen_Ioi.mem_nhds hx)).hasDerivAt) (fun x _ => hv x) hI1.integrableOn hI2.integrableOn
    (hfr.mul ((hφc a).mono_left nhdsWithin_le_nhds))
    (tendsto_const_nhds.congr' (by
      filter_upwards [probe_eventually_zero_atTop φ] with x hx
      simp [hx]))
  have hL := integral_Iic_mul_deriv_eq_deriv_mul (a := a) (u := f) (v := φ) (u' := deriv f)
    (v' := ψ) (a' := fl * φ a) (b' := 0)
    (fun x hx => (((hleft.differentiableOn (by simp)) x hx).differentiableAt
      (isOpen_Iio.mem_nhds hx)).hasDerivAt) (fun x _ => hv x) hI1.integrableOn hI2.integrableOn
    (hfl.mul ((hφc a).mono_left nhdsWithin_le_nhds))
    (tendsto_const_nhds.congr' (by
      filter_upwards [probe_eventually_zero_atBot φ] with x hx
      simp [hx]))
  have e1 : ∫ x, (-ψ) x • f x = -∫ x, f x * ψ x := by
    rw [← integral_neg]; congr 1; ext x; simp [mul_comm]
  have e2 : ∫ x, φ x • deriv f x = ∫ x, deriv f x * φ x := by
    congr 1; ext x; simp [mul_comm]
  rw [e1, e2, ← intervalIntegral.integral_Iic_add_Ioi (f := fun x => f x * ψ x) (b := a)
      hI1.integrableOn hI1.integrableOn,
    ← intervalIntegral.integral_Iic_add_Ioi (f := fun x => deriv f x * φ x) (b := a)
      hI2.integrableOn hI2.integrableOn, hL, hR, smul_eq_mul]
  ring

/-- The step's derivative is the delta. Read on smooth probes, the derivative of the step
`H` (taken by moving the derivative onto the probe with a minus sign) is the delta at 0: it reads
every probe `φ` as `φ(0)`, the probe's value at the switch. -/
theorem step_derivative_eq_delta :
    (∂_{(1 : ℝ)} (Distribution.ofFun (⊤ : Opens ℝ) step volume ⊤) : 𝓓'((⊤ : Opens ℝ), ℝ)) =
      Distribution.delta 0 := by
  have hneg : ∀ x ∈ Iio (0 : ℝ), step x = 0 := fun x hx =>
    indicator_of_notMem (fun h : x ∈ Ici 0 => absurd (mem_Ici.mp h) (not_le.mpr hx)) _
  have hpos : ∀ x ∈ Ioi (0 : ℝ), step x = 1 := fun x (hx : 0 < x) => by
    simp [step, le_of_lt hx]
  have hd : ∀ x ≠ (0 : ℝ), deriv step x = 0 := by
    intro x hx
    rcases lt_or_gt_of_ne hx with h | h
    · have : step =ᶠ[𝓝 x] fun _ => 0 := eventually_of_mem (Iio_mem_nhds h) hneg
      rw [this.deriv_eq, deriv_const]
    · have : step =ᶠ[𝓝 x] fun _ => 1 := eventually_of_mem (Ioi_mem_nhds h) hpos
      rw [this.deriv_eq, deriv_const]
  have hdl : Tendsto (deriv step) (𝓝[<] 0) (𝓝 0) :=
    tendsto_const_nhds.congr' (eventually_of_mem self_mem_nhdsWithin
      fun x (hx : x < 0) => (hd x hx.ne).symm)
  have hdr : Tendsto (deriv step) (𝓝[>] 0) (𝓝 0) :=
    tendsto_const_nhds.congr' (eventually_of_mem self_mem_nhdsWithin
      fun x (hx : 0 < x) => (hd x hx.ne').symm)
  rw [jump_aux step 0 0 1 0 0 (contDiffOn_const.congr hneg) (contDiffOn_const.congr hpos)
    (tendsto_const_nhds.congr' (eventually_of_mem self_mem_nhdsWithin fun x hx => (hneg x hx).symm))
    (tendsto_const_nhds.congr' (eventually_of_mem self_mem_nhdsWithin fun x hx => (hpos x hx).symm))
    hdl hdr]
  have hae : deriv step =ᵐ[volume.restrict ((⊤ : Opens ℝ) : Set ℝ)] (0 : ℝ → ℝ) := by
    refine ae_restrict_of_ae ?_
    filter_upwards [(countable_singleton (0 : ℝ)).ae_notMem volume] with x hx
    exact hd x hx
  rw [Distribution.ofFun_congr_ae hae, Distribution.ofFun_zero]
  simp

/-- The jump rule. Let `f` be smooth on each side of a point `a`, with `f` and its slope `f'`
both having one-sided limits at `a`; write `f(a⁻)` and `f(a⁺)` for the limits of `f` from the
left and from the right. Then, read on smooth probes, the derivative of `f` is its ordinary slope
plus the jump's size `J = f(a⁺) - f(a⁻)` times the delta at the jump:
`f' = {f'} + J δ_a`. -/
theorem jump_rule (f : ℝ → ℝ) (a fl fr dl dr : ℝ)
    (hleft : ContDiffOn ℝ ∞ f (Iio a)) (hright : ContDiffOn ℝ ∞ f (Ioi a))
    (hfl : Tendsto f (𝓝[<] a) (𝓝 fl)) (hfr : Tendsto f (𝓝[>] a) (𝓝 fr))
    (hdl : Tendsto (deriv f) (𝓝[<] a) (𝓝 dl)) (hdr : Tendsto (deriv f) (𝓝[>] a) (𝓝 dr)) :
    (∂_{(1 : ℝ)} (Distribution.ofFun (⊤ : Opens ℝ) f volume ⊤) : 𝓓'((⊤ : Opens ℝ), ℝ)) =
      Distribution.ofFun (⊤ : Opens ℝ) (deriv f) volume ⊤ + (fr - fl) • Distribution.delta a := by
  exact jump_aux f a fl fr dl dr hleft hright hfl hfr hdl hdr

/-- The principal value is a derivative too. Read on any smooth probe `φ`, the derivative of
`ln|t|` equals the principal value of `1/t`: the integral of `φ(t)/t` with an equal gap
`(-ε, ε)` cut out around 0 tends to that reading as the gap closes. -/
theorem log_abs_derivative_eq_principal_value (φ : 𝓓((⊤ : Opens ℝ), ℝ)) :
    Tendsto (fun ε : ℝ => ∫ t in {t : ℝ | ε < |t|}, φ t / t) (𝓝[>] 0)
      (𝓝 ((∂_{(1 : ℝ)} (Distribution.ofFun (⊤ : Opens ℝ) (fun t : ℝ => Real.log |t|) volume ⊤)
        : 𝓓'((⊤ : Opens ℝ), ℝ)) φ)) := by
  have hlog : (fun t : ℝ => Real.log |t|) = Real.log := funext fun t => Real.log_abs t
  have hlocΩ : LocallyIntegrableOn Real.log ((⊤ : Opens ℝ) : Set ℝ) volume := by
    have : LocallyIntegrable Real.log volume := fun x =>
      ⟨Icc (x - 1) (x + 1), Icc_mem_nhds (by linarith) (by linarith),
        (intervalIntegrable_iff_integrableOn_Icc_of_le (by linarith)).mp intervalIntegral.intervalIntegrable_log'⟩
    simpa using this.locallyIntegrableOn univ
  rw [hlog, Distribution.lineDerivOp_apply_apply, Distribution.ofFun_apply hlocΩ]
  set ψ : 𝓓((⊤ : Opens ℝ), ℝ) := ∂_{(1 : ℝ)} φ with hψ
  have hv : ∀ x, HasDerivAt φ (ψ x) x := probe_hasDerivAt φ
  have hφc : ∀ x, Tendsto φ (𝓝 x) (𝓝 (φ x)) := fun x => φ.continuous.tendsto x
  have hIψ : Integrable (Real.log * ⇑ψ) volume :=
    (ψ.integrable_smul hlocΩ).congr (ae_of_all _ fun x => by simp [mul_comm])
  have hφint : Integrable φ volume := φ.continuous.integrable_of_hasCompactSupport φ.hasCompactSupport
  have hSm : ∀ ε : ℝ, MeasurableSet {t : ℝ | ε < |t|} := fun ε =>
    measurableSet_lt measurable_const continuous_abs.measurable
  have key : ∀ ε : ℝ, 0 < ε → ∫ t in {t : ℝ | ε < |t|}, φ t / t =
      Real.log ε * (φ (-ε) - φ ε) - ∫ t in {t : ℝ | ε < |t|}, Real.log t * ψ t := by
    intro ε hε
    have hIS : IntegrableOn ((fun t : ℝ => t⁻¹) * ⇑φ) {t : ℝ | ε < |t|} volume := by
      refine Integrable.bdd_mul (c := ε⁻¹) hφint.integrableOn
        measurable_inv.aestronglyMeasurable ?_
      rw [ae_restrict_iff' (hSm ε)]
      refine ae_of_all _ fun t (ht : ε < |t|) => ?_
      rw [norm_inv, Real.norm_eq_abs]
      exact inv_anti₀ hε ht.le
    have hS : {t : ℝ | ε < |t|} = Iio (-ε) ∪ Ioi ε := by
      ext t; simp only [mem_ofPred_eq, mem_union, mem_Iio, mem_Ioi, lt_abs]; constructor <;>
        rintro (h | h) <;> [right; left; right; left] <;> linarith
    have hIo : Ioi ε ⊆ {t : ℝ | ε < |t|} := fun t (ht : ε < t) =>
      show ε < |t| from ht.trans_le (le_abs_self t)
    have hIi : Iic (-ε) ⊆ {t : ℝ | ε < |t|} ∪ {-ε} := by
      intro t (ht : t ≤ -ε)
      rcases ht.lt_or_eq with h | h
      · left; show ε < |t|; rw [abs_of_neg (by linarith)]; linarith
      · right; exact h
    have hIic : IntegrableOn ((fun t : ℝ => t⁻¹) * ⇑φ) (Iic (-ε)) volume := by
      refine (integrableOn_Iic_iff_integrableOn_Iio enorm_ne_top).mpr (hIS.mono_set fun t (ht : t < -ε) => ?_)
      show ε < |t|; rw [abs_of_neg (by linarith)]; linarith
    have hR := integral_Ioi_mul_deriv_eq_deriv_mul (a := ε) (u := Real.log) (v := φ)
      (u' := fun t => t⁻¹) (v' := ψ) (a' := Real.log ε * φ ε) (b' := 0)
      (fun x (hx : ε < x) => Real.hasDerivAt_log (by linarith)) (fun x _ => hv x)
      hIψ.integrableOn (hIS.mono_set hIo)
      (((Real.continuousAt_log hε.ne').tendsto.mul (hφc ε)).mono_left nhdsWithin_le_nhds)
      (tendsto_const_nhds.congr' (by
        filter_upwards [probe_eventually_zero_atTop φ] with x hx
        simp [hx]))
    have hL := integral_Iic_mul_deriv_eq_deriv_mul (a := -ε) (u := Real.log) (v := φ)
      (u' := fun t => t⁻¹) (v' := ψ) (a' := Real.log (-ε) * φ (-ε)) (b' := 0)
      (fun x (hx : x < -ε) => Real.hasDerivAt_log (by linarith)) (fun x _ => hv x)
      hIψ.integrableOn hIic
      (((Real.continuousAt_log (by linarith)).tendsto.mul (hφc (-ε))).mono_left
        nhdsWithin_le_nhds)
      (tendsto_const_nhds.congr' (by
        filter_upwards [probe_eventually_zero_atBot φ] with x hx
        simp [hx]))
    rw [integral_Iic_eq_integral_Iio, integral_Iic_eq_integral_Iio] at hL
    have hdisj : Disjoint (Iio (-ε)) (Ioi ε) :=
      Set.disjoint_left.mpr fun t (h1 : t < -ε) (h2 : ε < t) => by linarith
    have e1 : ∫ t in {t : ℝ | ε < |t|}, φ t / t =
        (∫ t in Iio (-ε), t⁻¹ * φ t) + ∫ t in Ioi ε, t⁻¹ * φ t := by
      rw [hS] at hIS ⊢
      simp_rw [div_eq_inv_mul]
      exact setIntegral_union (f := fun t => t⁻¹ * φ t) hdisj measurableSet_Ioi
        (hIS.mono_set subset_union_left) (hIS.mono_set subset_union_right)
    have e2 : ∫ t in {t : ℝ | ε < |t|}, Real.log t * ψ t =
        (∫ t in Iio (-ε), Real.log t * ψ t) + ∫ t in Ioi ε, Real.log t * ψ t := by
      rw [hS]
      exact setIntegral_union (f := fun t => Real.log t * ψ t) hdisj measurableSet_Ioi
        hIψ.integrableOn hIψ.integrableOn
    rw [e1, e2, hL, hR, Real.log_neg_eq_log]
    ring
  -- the boundary term tends to 0
  have hslope := hasDerivAt_iff_tendsto_slope_zero.mp (hv 0)
  simp only [zero_add, smul_eq_mul] at hslope
  have hs1 : Tendsto (fun ε : ℝ => ε⁻¹ * (φ ε - φ 0)) (𝓝[>] 0) (𝓝 (ψ 0)) :=
    hslope.mono_left (nhdsWithin_mono _ fun x (hx : 0 < x) => ne_of_gt hx)
  have hs2 : Tendsto (fun ε : ℝ => (-ε)⁻¹ * (φ (-ε) - φ 0)) (𝓝[>] 0) (𝓝 (ψ 0)) := by
    refine hslope.comp (tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within _ ?_ ?_)
    · have : Tendsto (fun ε : ℝ => -ε) (𝓝 0) (𝓝 (-0)) := tendsto_id.neg
      simpa using this.mono_left nhdsWithin_le_nhds
    · exact eventually_of_mem self_mem_nhdsWithin fun x (hx : 0 < x) => by
        simp only [mem_compl_iff, mem_singleton_iff, neg_eq_zero]; exact hx.ne'
  have hlm : Tendsto (fun ε : ℝ => Real.log ε * ε) (𝓝[>] 0) (𝓝 0) := by
    simpa using tendsto_log_mul_rpow_nhdsGT_zero zero_lt_one
  have hB : Tendsto (fun ε : ℝ => Real.log ε * (φ (-ε) - φ ε)) (𝓝[>] 0) (𝓝 0) := by
    have := hlm.mul ((hs1.add hs2).neg)
    rw [zero_mul] at this
    refine this.congr' (eventually_of_mem self_mem_nhdsWithin fun ε (hε : 0 < ε) => ?_)
    field_simp
    ring
  -- the remaining integral converges by dominated convergence
  have hA : Tendsto (fun ε : ℝ => ∫ t in {t : ℝ | ε < |t|}, Real.log t * ψ t) (𝓝[>] 0)
      (𝓝 (∫ t, Real.log t * ψ t)) := by
    simp_rw [← integral_indicator (hSm _)]
    refine tendsto_integral_filter_of_dominated_convergence (fun t => ‖Real.log t * ψ t‖)
      (Eventually.of_forall fun ε => hIψ.aestronglyMeasurable.indicator (hSm ε))
      (Eventually.of_forall fun ε => ae_of_all _ fun t => norm_indicator_le_norm_self _ _)
      hIψ.norm ?_
    filter_upwards [(countable_singleton (0 : ℝ)).ae_notMem volume] with t ht
    refine tendsto_const_nhds.congr' ?_
    have hpos : 0 < |t| := abs_pos.mpr ht
    filter_upwards [nhdsWithin_le_nhds (gt_mem_nhds hpos)] with ε hε
    exact (indicator_of_mem (show t ∈ {t : ℝ | ε < |t|} from hε) (fun t => Real.log t * ψ t)).symm
  have hval : ∫ x, (-ψ) x • Real.log x = 0 - ∫ t, Real.log t * ψ t := by
    rw [zero_sub, ← integral_neg]; congr 1; ext x; simp [mul_comm]
  rw [hval]
  exact (hB.sub hA).congr' (eventually_of_mem self_mem_nhdsWithin fun ε hε => (key ε hε).symm)

-- The switch's jump: 12 V after, 0 V before, so J = 12 V.
example : (12 : ℤ) - 0 = 12 := by norm_num
-- Charge taken at the switch: 100 µF × 12 V = 1200 µC, which is 1.2 mC.
example : (100 : ℕ) * 12 = 1200 := by norm_num
-- Peak current at a 1 µs rise: 1200 µC over 1 µs is 1200 A; at a 1 ms rise, 1200 µC / 1000 µs.
example : (1200 : ℚ) / 1000 = 6 / 5 := by norm_num
-- The probe at the switch: u = (0 - 2)/4 = -1/2, and 1/(1 - u²) = 4/3, so φ(0) = e^(-4/3).
example : ((0 : ℚ) - 2) / 4 = -1 / 2 := by norm_num
example : (1 : ℚ) / (1 - (-1 / 2) ^ 2) = 4 / 3 := by norm_num
-- Squaring the ramp's slope: (12/ε)² times the width ε is 144/ε, which has no limit.
example : (12 / (1 : ℚ)) ^ 2 * 1 = 144 := by norm_num
example : (12 / (1 / 10 : ℚ)) ^ 2 * (1 / 10) = 1440 := by norm_num
example : (12 / (1 / 100 : ℚ)) ^ 2 * (1 / 100) = 14400 := by norm_num
example : (12 / (1 / 1000 : ℚ)) ^ 2 * (1 / 1000) = 144000 := by norm_num

#print axioms probe_deriv_apply
#print axioms probe_hasDerivAt
#print axioms probe_eventually_zero_atTop
#print axioms probe_eventually_zero_atBot
#print axioms locInt_of_pieces
#print axioms jump_aux
#print axioms step_derivative_eq_delta
#print axioms jump_rule
#print axioms log_abs_derivative_eq_principal_value

end DiracDeltaJumps
