-- Compactness in Lp: a bounded family in Lp of the one-second loop, 1 ≤ p < ∞, has convergent subsequences exactly when one small delay moves every member by little, a uniformly integrable family in L1 has weakly convergent subsequences, and the clicks n on [0, 1/n) fail both tests.
import Mathlib
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
import Mathlib.MeasureTheory.Function.LpSpace.Basic
import Mathlib.MeasureTheory.Group.Measure
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Tactic.NormNum

open MeasureTheory Filter Topology
open scoped ENNReal

/-- The delay τ_s on clips in Lp of the one-second loop: (τ_s f)(x) = f(x − s), wrapping round
the loop. It plays the clip s seconds later. -/
noncomputable def delay (p : ℝ≥0∞) (s : ℝ) :
    Lp ℝ p (volume : Measure UnitAddCircle) →+ Lp ℝ p (volume : Measure UnitAddCircle) :=
  Lp.compMeasurePreserving (fun x => x - (s : UnitAddCircle)) (measurePreserving_sub_right volume _)

/-- Click n on the loop: height n on [0, 1/n) and 0 on the rest of the second, repeated every
second. -/
noncomputable def click (n : ℕ) (x : ℝ) : ℝ :=
  if Int.fract x < 1 / (n : ℝ) then (n : ℝ) else 0

-- Helper lemmas for the three proofs below.

instance unitAddCircle_isProbabilityMeasure :
    IsProbabilityMeasure (volume : Measure UnitAddCircle) := ⟨UnitAddCircle.measure_univ⟩

/-- Translation by a point of the circle. -/

noncomputable def shiftL (p : ℝ≥0∞) (a : UnitAddCircle) :
    Lp ℝ p (volume : Measure UnitAddCircle) →+ Lp ℝ p (volume : Measure UnitAddCircle) :=
  Lp.compMeasurePreserving (fun x => x - a) (measurePreserving_sub_right volume a)

theorem delay_eq_shiftL (p : ℝ≥0∞) (s : ℝ) : delay p s = shiftL p (s : UnitAddCircle) := rfl

#print axioms delay_eq_shiftL

theorem norm_shiftL (p : ℝ≥0∞) [Fact (1 ≤ p)] (a : UnitAddCircle)
    (f : Lp ℝ p (volume : Measure UnitAddCircle)) : ‖shiftL p a f‖ = ‖f‖ :=
  Lp.norm_compMeasurePreserving _ _

#print axioms norm_shiftL

theorem exists_rep (a : UnitAddCircle) : ∃ t : ℝ, (t : UnitAddCircle) = a ∧ |t| = ‖a‖ := by
  obtain ⟨t0, rfl⟩ := QuotientAddGroup.mk_surjective a
  refine ⟨t0 - round t0, ?_, ?_⟩
  · have : ((t0 - round t0 : ℝ) : UnitAddCircle) = (t0 : UnitAddCircle) := by
      rw [AddCircle.coe_sub]
      have : ((round t0 : ℝ) : UnitAddCircle) = 0 := by
        rw [AddCircle.coe_eq_zero_iff]; exact ⟨round t0, by simp⟩
      rw [this, sub_zero]
    exact this
  · have := AddCircle.norm_eq (p := (1 : ℝ)) (x := t0)
    simp only [inv_one, one_mul, mul_one] at this
    exact this.symm

#print axioms exists_rep

theorem continuous_delay (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞)
    (f : Lp ℝ p (volume : Measure UnitAddCircle)) : Continuous fun s : ℝ => delay p s f := by
  let g : ℝ → C(UnitAddCircle, UnitAddCircle) := fun s =>
    ⟨fun x => x - (s : UnitAddCircle), by fun_prop⟩
  have hg : Continuous g := by
    apply ContinuousMap.continuous_of_continuous_uncurry
    exact (continuous_snd.sub (continuous_quotient_mk'.comp continuous_fst))
  exact continuous_const.compMeasurePreservingLp hg
    (fun s => measurePreserving_sub_right volume _) hp

#print axioms continuous_delay

theorem delay_zero (p : ℝ≥0∞) [Fact (1 ≤ p)] (f : Lp ℝ p (volume : Measure UnitAddCircle)) :
    delay p 0 f = f := by
  ext1
  filter_upwards [Lp.coeFn_compMeasurePreserving f (measurePreserving_sub_right volume
    ((0 : ℝ) : UnitAddCircle))] with x hx
  exact hx.trans (by simp)

#print axioms delay_zero

theorem forward_dir (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞)
    (𝓕 : Set (Lp ℝ p (volume : Measure UnitAddCircle)))
    (h : ∀ u : ℕ → Lp ℝ p (volume : Measure UnitAddCircle), (∀ n, u n ∈ 𝓕) →
      ∃ g : Lp ℝ p (volume : Measure UnitAddCircle), ∃ φ : ℕ → ℕ, StrictMono φ ∧
        Tendsto (fun k => u (φ k)) atTop (𝓝 g)) :
    ∀ ε > 0, ∃ δ > 0, ∀ f ∈ 𝓕, ∀ s : ℝ, |s| ≤ δ → ‖delay p s f - f‖ ≤ ε := by
  by_contra hne
  push Not at hne
  obtain ⟨ε, hε, hbad⟩ := hne
  have hb : ∀ n : ℕ, ∃ f ∈ 𝓕, ∃ s : ℝ, |s| ≤ 1 / (n + 1) ∧ ε < ‖delay p s f - f‖ :=
    fun n => hbad _ (by positivity)
  choose u hu s hs hus using hb
  obtain ⟨g, φ, hφ, hlim⟩ := h u hu
  have hs0 : Tendsto (fun k => s (φ k)) atTop (𝓝 0) := by
    have h1 : Tendsto (fun n : ℕ => s n) atTop (𝓝 0) := by
      apply squeeze_zero_norm (fun n => (hs n)) tendsto_one_div_add_atTop_nhds_zero_nat
    exact h1.comp hφ.tendsto_atTop
  have hcg : Tendsto (fun k => delay p (s (φ k)) g) atTop (𝓝 g) := by
    have := ((continuous_delay p hp g).tendsto 0).comp hs0
    rwa [delay_zero] at this
  have hA : Tendsto (fun k => ‖u (φ k) - g‖) atTop (𝓝 0) := by
    simpa using (tendsto_iff_norm_sub_tendsto_zero.1 hlim)
  have hB : Tendsto (fun k => ‖delay p (s (φ k)) g - g‖) atTop (𝓝 0) := by
    simpa using (tendsto_iff_norm_sub_tendsto_zero.1 hcg)
  have hC : Tendsto (fun k => 2 * ‖u (φ k) - g‖ + ‖delay p (s (φ k)) g - g‖) atTop (𝓝 0) := by
    simpa using (hA.const_mul 2).add hB
  obtain ⟨k, hk⟩ := (hC.eventually (gt_mem_nhds hε)).exists
  have hle : ‖delay p (s (φ k)) (u (φ k)) - u (φ k)‖ ≤
      2 * ‖u (φ k) - g‖ + ‖delay p (s (φ k)) g - g‖ := by
    have e : delay p (s (φ k)) (u (φ k)) - u (φ k) =
        delay p (s (φ k)) (u (φ k) - g) + (delay p (s (φ k)) g - g) + (g - u (φ k)) := by
      rw [map_sub]; abel
    rw [e]
    have n1 : ‖delay p (s (φ k)) (u (φ k) - g)‖ = ‖u (φ k) - g‖ := norm_shiftL p _ _
    have n2 : ‖g - u (φ k)‖ = ‖u (φ k) - g‖ := norm_sub_rev _ _
    calc _ ≤ ‖delay p (s (φ k)) (u (φ k) - g) + (delay p (s (φ k)) g - g)‖ + ‖g - u (φ k)‖ :=
          norm_add_le _ _
      _ ≤ ‖delay p (s (φ k)) (u (φ k) - g)‖ + ‖delay p (s (φ k)) g - g‖ + ‖g - u (φ k)‖ := by
          gcongr; exact norm_add_le _ _
      _ = _ := by rw [n1, n2]; ring
  linarith [hus (φ k)]

#print axioms forward_dir

theorem avg_eLpNorm_le (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞)
    (f : Lp ℝ p (volume : Measure UnitAddCircle))
    (ν : Measure UnitAddCircle) [IsProbabilityMeasure ν]
    (hνi : ∀ x, Integrable (fun s => f (x - s)) ν) (ε : ℝ)
    (hτ : ∀ᵐ a ∂ν, ‖shiftL p a f - f‖ ≤ ε) :
    eLpNorm (fun x => (∫ s, f (x - s) ∂ν) - f x) p volume ≤ ENNReal.ofReal ε := by
  have hp1 : (1 : ℝ≥0∞) ≤ p := Fact.out
  have hp0 : p ≠ 0 := (zero_lt_one.trans_le hp1).ne'
  set r := p.toReal with hr_def
  have hr : 0 < r := ENNReal.toReal_pos hp0 hp
  have hF : Measurable (f : UnitAddCircle → ℝ) := (Lp.stronglyMeasurable f).measurable
  have hH : Measurable (fun z : UnitAddCircle × UnitAddCircle => f (z.1 - z.2) - f z.1) :=
    (hF.comp (measurable_fst.sub measurable_snd)).sub (hF.comp measurable_fst)
  have hD : ∀ x, (∫ s, f (x - s) ∂ν) - f x = ∫ s, (f (x - s) - f x) ∂ν := by
    intro x
    rw [integral_sub (hνi x) (integrable_const _), integral_const]
    simp
  have hDm : StronglyMeasurable (fun x => (∫ s, f (x - s) ∂ν) - f x) := by
    have : StronglyMeasurable (fun x => ∫ s, f (x - s) ∂ν) :=
      (hF.comp (measurable_fst.sub measurable_snd)).stronglyMeasurable.integral_prod_right'
    exact this.sub (Lp.stronglyMeasurable f)
  have hpt : ∀ x, ‖(∫ s, f (x - s) ∂ν) - f x‖ₑ ^ r ≤ ∫⁻ s, ‖f (x - s) - f x‖ₑ ^ r ∂ν := by
    intro x
    rw [hD x]
    have hm : AEStronglyMeasurable (fun s => f (x - s) - f x) ν :=
      ((hF.comp (measurable_const.sub measurable_id)).sub measurable_const).aestronglyMeasurable
    have h1 := eLpNorm_le_eLpNorm_of_exponent_le (μ := ν) (f := fun s => f (x - s) - f x) hp1
    rw [eLpNorm_one_eq_lintegral_enorm hm, eLpNorm_eq_lintegral_rpow_enorm_toReal hp0 hp hm] at h1
    have h2 : ‖∫ s, (f (x - s) - f x) ∂ν‖ₑ ≤ (∫⁻ s, ‖f (x - s) - f x‖ₑ ^ r ∂ν) ^ (1 / r) :=
      (enorm_integral_le_lintegral_enorm _).trans h1
    calc ‖∫ s, (f (x - s) - f x) ∂ν‖ₑ ^ r ≤ ((∫⁻ s, ‖f (x - s) - f x‖ₑ ^ r ∂ν) ^ (1 / r)) ^ r :=
          ENNReal.rpow_le_rpow h2 hr.le
      _ = _ := by rw [← ENNReal.rpow_mul, one_div_mul_cancel hr.ne', ENNReal.rpow_one]
  have hin : ∀ᵐ s ∂ν, ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ r ∂volume ≤ ENNReal.ofReal ε ^ r := by
    filter_upwards [hτ] with s hs
    have he : eLpNorm (⇑(shiftL p s f - f)) p volume =
        (∫⁻ x, ‖f (x - s) - f x‖ₑ ^ r ∂volume) ^ (1 / r) := by
      have hms : AEStronglyMeasurable (fun x => f (x - s) - f x) volume :=
        ((hF.comp (measurable_id.sub_const s)).sub hF).aestronglyMeasurable
      rw [← eLpNorm_eq_lintegral_rpow_enorm_toReal hp0 hp hms]
      apply eLpNorm_congr_ae
      filter_upwards [Lp.coeFn_sub (shiftL p s f) f,
        Lp.coeFn_compMeasurePreserving f (measurePreserving_sub_right volume s)] with x h1 h2
      rw [h1, Pi.sub_apply]
      exact congrArg (· - f x) h2
    have hle : eLpNorm (⇑(shiftL p s f - f)) p volume ≤ ENNReal.ofReal ε := by
      rw [← ENNReal.ofReal_toReal (Lp.eLpNorm_ne_top _)]
      exact ENNReal.ofReal_le_ofReal (by rwa [Lp.norm_def] at hs)
    rw [he] at hle
    calc ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ r = ((∫⁻ x, ‖f (x - s) - f x‖ₑ ^ r) ^ (1 / r)) ^ r := by
          rw [← ENNReal.rpow_mul, one_div_mul_cancel hr.ne', ENNReal.rpow_one]
      _ ≤ ENNReal.ofReal ε ^ r := ENNReal.rpow_le_rpow hle hr.le
  rw [eLpNorm_eq_lintegral_rpow_enorm_toReal hp0 hp hDm.aestronglyMeasurable]
  have hmain : ∫⁻ x, ‖(∫ s, f (x - s) ∂ν) - f x‖ₑ ^ r ∂volume ≤ ENNReal.ofReal ε ^ r := by
    calc ∫⁻ x, ‖(∫ s, f (x - s) ∂ν) - f x‖ₑ ^ r ∂volume
        ≤ ∫⁻ x, ∫⁻ s, ‖f (x - s) - f x‖ₑ ^ r ∂ν ∂volume := lintegral_mono hpt
      _ = ∫⁻ s, ∫⁻ x, ‖f (x - s) - f x‖ₑ ^ r ∂volume ∂ν := by
          apply lintegral_lintegral_swap
          exact (hH.enorm.pow_const r).aemeasurable
      _ ≤ ∫⁻ s, ENNReal.ofReal ε ^ r ∂ν := lintegral_mono_ae hin
      _ = ENNReal.ofReal ε ^ r := by simp
  calc (∫⁻ x, ‖(∫ s, f (x - s) ∂ν) - f x‖ₑ ^ r ∂volume) ^ (1 / r)
      ≤ (ENNReal.ofReal ε ^ r) ^ (1 / r) := ENNReal.rpow_le_rpow hmain (by positivity)
    _ = ENNReal.ofReal ε := by
        rw [← ENNReal.rpow_mul, mul_one_div_cancel hr.ne', ENNReal.rpow_one]

#print axioms avg_eLpNorm_le

theorem eLpNorm_shiftL_sub (p : ℝ≥0∞) (a : UnitAddCircle)
    (f : Lp ℝ p (volume : Measure UnitAddCircle)) :
    eLpNorm (⇑(shiftL p a f - f)) p volume = eLpNorm (fun x => f (x - a) - f x) p volume := by
  apply eLpNorm_congr_ae
  filter_upwards [Lp.coeFn_sub (shiftL p a f) f,
    Lp.coeFn_compMeasurePreserving f (measurePreserving_sub_right volume a)] with x h1 h2
  rw [h1, Pi.sub_apply]
  exact congrArg (· - f x) h2

#print axioms eLpNorm_shiftL_sub

theorem avg_diff_le (p : ℝ≥0∞) [Fact (1 ≤ p)] (f : Lp ℝ p (volume : Measure UnitAddCircle))
    (ν : Measure UnitAddCircle) (K : ℝ≥0∞)
    (hνK : ∀ φ : UnitAddCircle → ℝ≥0∞, ∫⁻ x, φ x ∂ν ≤ K * ∫⁻ x, φ x)
    (hνi : ∀ x, Integrable (fun s => f (x - s)) ν) (x y : UnitAddCircle) :
    ‖(∫ s, f (y - s) ∂ν) - ∫ s, f (x - s) ∂ν‖ₑ ≤
      K * eLpNorm (⇑(shiftL p (x - y) f - f)) p volume := by
  have hF : Measurable (f : UnitAddCircle → ℝ) := (Lp.stronglyMeasurable f).measurable
  rw [← integral_sub (hνi y) (hνi x)]
  refine (enorm_integral_le_lintegral_enorm _).trans ((hνK _).trans ?_)
  gcongr
  have hcv : ∫⁻ s, ‖f (y - s) - f (x - s)‖ₑ = ∫⁻ u, ‖f (u - (x - y)) - f u‖ₑ := by
    rw [← lintegral_sub_left_eq_self (fun u => ‖f (u - (x - y)) - f u‖ₑ) x]
    congr 1; ext s; congr 3; abel
  rw [hcv]
  have hms : AEStronglyMeasurable (fun u => f (u - (x - y)) - f u) volume :=
    ((hF.comp (measurable_id.sub_const _)).sub hF).aestronglyMeasurable
  rw [← eLpNorm_one_eq_lintegral_enorm hms, eLpNorm_shiftL_sub]
  exact eLpNorm_le_eLpNorm_of_exponent_le Fact.out

#print axioms avg_diff_le

theorem avg_bound_le (p : ℝ≥0∞) [Fact (1 ≤ p)] (f : Lp ℝ p (volume : Measure UnitAddCircle))
    (ν : Measure UnitAddCircle) (K : ℝ≥0∞)
    (hνK : ∀ φ : UnitAddCircle → ℝ≥0∞, ∫⁻ x, φ x ∂ν ≤ K * ∫⁻ x, φ x) (x : UnitAddCircle) :
    ‖∫ s, f (x - s) ∂ν‖ₑ ≤ K * eLpNorm f p volume := by
  refine (enorm_integral_le_lintegral_enorm _).trans ((hνK _).trans ?_)
  gcongr
  rw [lintegral_sub_left_eq_self (fun u => ‖f u‖ₑ) x,
    ← eLpNorm_one_eq_lintegral_enorm (Lp.aestronglyMeasurable f)]
  exact eLpNorm_le_eLpNorm_of_exponent_le Fact.out

#print axioms avg_bound_le

theorem reverse_dir (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞)
    (𝓕 : Set (Lp ℝ p (volume : Measure UnitAddCircle)))
    (hbdd : ∃ B : ℝ, ∀ f ∈ 𝓕, ‖f‖ ≤ B)
    (hEC : ∀ ε > 0, ∃ δ > 0, ∀ f ∈ 𝓕, ∀ s : ℝ, |s| ≤ δ → ‖delay p s f - f‖ ≤ ε) :
    TotallyBounded 𝓕 := by
  obtain ⟨B, hB⟩ := hbdd
  have hEC' : ∀ ε > 0, ∃ δ > 0, ∀ f ∈ 𝓕, ∀ a : UnitAddCircle, ‖a‖ < δ →
      ‖shiftL p a f - f‖ ≤ ε := by
    intro ε hε
    obtain ⟨δ, hδ, h⟩ := hEC ε hε
    refine ⟨δ, hδ, fun f hf a ha => ?_⟩
    obtain ⟨t, rfl, ht⟩ := exists_rep a
    exact h f hf t (by rw [ht]; exact ha.le)
  rw [Metric.totallyBounded_iff]
  intro ε hε
  obtain ⟨δ, hδ, hδf⟩ := hEC' (ε / 3) (by positivity)
  set S := Metric.ball (0 : UnitAddCircle) δ with hS_def
  have hSm : MeasurableSet S := measurableSet_ball
  have hS0 : volume S ≠ 0 := (Metric.measure_ball_pos volume 0 hδ).ne'
  have hSt : volume S ≠ ∞ := measure_ne_top _ _
  set K : ℝ≥0∞ := (volume S)⁻¹ with hK_def
  have hKt : K ≠ ∞ := ENNReal.inv_ne_top.2 hS0
  set ν : Measure UnitAddCircle := K • volume.restrict S with hν_def
  have : IsProbabilityMeasure ν := ⟨by
    simp [ν, K, Measure.smul_apply, ENNReal.inv_mul_cancel hS0 hSt]⟩
  have hνK : ∀ φ : UnitAddCircle → ℝ≥0∞, ∫⁻ x, φ x ∂ν ≤ K * ∫⁻ x, φ x := by
    intro φ
    rw [hν_def, lintegral_smul_measure, smul_eq_mul]
    exact mul_le_mul_right (setLIntegral_le_lintegral _ _) K
  have hνi : ∀ (f : Lp ℝ p (volume : Measure UnitAddCircle)) x,
      Integrable (fun s => f (x - s)) ν := by
    intro f x
    have : Integrable (fun s => f (x - s)) volume :=
      ((Lp.memLp f).integrable Fact.out).comp_sub_left x
    exact this.restrict.smul_measure hKt
  let G : Lp ℝ p (volume : Measure UnitAddCircle) → UnitAddCircle → ℝ :=
    fun f x => ∫ s, f (x - s) ∂ν
  have hdiff : ∀ f x y, dist (G f y) (G f x) ≤ K.toReal * ‖shiftL p (x - y) f - f‖ := by
    intro f x y
    have h1 := avg_diff_le p f ν K hνK (hνi f) x y
    rw [dist_eq_norm, ← toReal_enorm, Lp.norm_def, ← ENNReal.toReal_mul]
    exact ENNReal.toReal_mono (ENNReal.mul_ne_top hKt (Lp.eLpNorm_ne_top _)) h1
  have hbound : ∀ f x, |G f x| ≤ K.toReal * ‖f‖ := by
    intro f x
    have h1 := avg_bound_le p f ν K hνK x
    rw [← Real.norm_eq_abs, ← toReal_enorm, Lp.norm_def, ← ENNReal.toReal_mul]
    exact ENNReal.toReal_mono (ENNReal.mul_ne_top hKt (Lp.eLpNorm_ne_top _)) h1
  have hest : ∀ x0 : UnitAddCircle, ∀ ε' > 0, ∃ δ' > 0, ∀ x, dist x x0 < δ' → ∀ f ∈ 𝓕,
      dist (G f x0) (G f x) < ε' := by
    intro x0 ε' hε'
    obtain ⟨δ', hδ', h'⟩ := hEC' (ε' / (2 * (K.toReal + 1))) (by positivity)
    refine ⟨δ', hδ', fun x hx f hf => ?_⟩
    have hK0 : 0 ≤ K.toReal := ENNReal.toReal_nonneg
    calc dist (G f x0) (G f x) ≤ K.toReal * ‖shiftL p (x - x0) f - f‖ := hdiff f x x0
      _ ≤ K.toReal * (ε' / (2 * (K.toReal + 1))) :=
          mul_le_mul_of_nonneg_left (h' f hf _ (by rwa [← dist_eq_norm])) hK0
      _ < ε' := by
          rw [mul_div_assoc', div_lt_iff₀ (by positivity)]; nlinarith
  have hcont : ∀ f ∈ 𝓕, Continuous (G f) := by
    intro f hf
    rw [Metric.continuous_iff]
    intro x0 ε' hε'
    obtain ⟨δ', hδ', h'⟩ := hest x0 ε' hε'
    exact ⟨δ', hδ', fun x hx => by rw [dist_comm]; exact h' x hx f hf⟩
  let Φ : 𝓕 → (BoundedContinuousFunction UnitAddCircle ℝ) := fun f =>
    BoundedContinuousFunction.mkOfCompact ⟨G f, hcont f f.2⟩
  have hΦ : ∀ f x, Φ f x = G f x := fun f x => rfl
  set A := Set.range Φ
  set M := K.toReal * B
  have in_s : ∀ (g : BoundedContinuousFunction UnitAddCircle ℝ) (x : UnitAddCircle), g ∈ A → g x ∈ Set.Icc (-M) M := by
    rintro g x ⟨f, rfl⟩
    rw [hΦ, Set.mem_Icc, ← abs_le]
    exact (hbound f x).trans (mul_le_mul_of_nonneg_left (hB f f.2) ENNReal.toReal_nonneg)
  have H : Equicontinuous ((↑) : A → UnitAddCircle → ℝ) := by
    intro x0
    rw [Metric.equicontinuousAt_iff]
    intro ε' hε'
    obtain ⟨δ', hδ', h'⟩ := hest x0 ε' hε'
    refine ⟨δ', hδ', fun x hx i => ?_⟩
    obtain ⟨f, hf⟩ := i.2
    rw [← hf]
    exact h' x hx f f.2
  have hA : IsCompact (closure A) :=
    BoundedContinuousFunction.arzela_ascoli (Set.Icc (-M) M) isCompact_Icc A in_s H
  have TB : TotallyBounded A := hA.totallyBounded.subset subset_closure
  let L := BoundedContinuousFunction.toLp (E := ℝ) p (volume : Measure UnitAddCircle) ℝ
  have TB' : TotallyBounded (L '' A) := TB.image L.uniformContinuous
  obtain ⟨t, htfin, hcover⟩ := Metric.totallyBounded_iff.1 TB' (ε / 3) (by positivity)
  refine ⟨t, htfin, fun f hf => ?_⟩
  have hmem : L (Φ ⟨f, hf⟩) ∈ L '' A := ⟨_, ⟨_, rfl⟩, rfl⟩
  obtain ⟨y, hy, hdy⟩ := Set.mem_iUnion₂.1 (hcover hmem)
  have hclose : dist f (L (Φ ⟨f, hf⟩)) ≤ ε / 3 := by
    rw [dist_comm, dist_eq_norm, Lp.norm_def]
    have he : eLpNorm (⇑(L (Φ ⟨f, hf⟩) - f)) p volume =
        eLpNorm (fun x => (∫ s, f (x - s) ∂ν) - f x) p volume := by
      apply eLpNorm_congr_ae
      filter_upwards [Lp.coeFn_sub (L (Φ ⟨f, hf⟩)) f,
        BoundedContinuousFunction.coeFn_toLp (E := ℝ) (p := p) (μ := volume) ℝ (Φ ⟨f, hf⟩)]
        with x h1 h2
      rw [h1, Pi.sub_apply, h2]
      rfl
    rw [he]
    have hae : ∀ᵐ a ∂ν, ‖shiftL p a f - f‖ ≤ ε / 3 := by
      have : ∀ᵐ a ∂(volume.restrict S), a ∈ S := ae_restrict_mem hSm
      filter_upwards [Measure.ae_smul_measure this K] with a ha
      exact hδf f hf a (mem_ball_zero_iff.1 ha)
    exact ENNReal.toReal_le_of_le_ofReal (by positivity)
      (avg_eLpNorm_le p hp f ν (hνi f) (ε / 3) hae)
  refine Set.mem_iUnion₂.2 ⟨y, hy, ?_⟩
  rw [Metric.mem_ball] at hdy ⊢
  calc dist f y ≤ dist f (L (Φ ⟨f, hf⟩)) + dist (L (Φ ⟨f, hf⟩)) y := dist_triangle _ _ _
    _ < ε / 3 + ε / 3 := by linarith
    _ < ε := by linarith

#print axioms reverse_dir

theorem diag_subseq {ι : Type*} [Countable ι] (a : ι → ℕ → ℝ) (C : ι → ℝ)
    (ha : ∀ i n, |a i n| ≤ C i) :
    ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∀ i, ∃ c, Tendsto (fun k => a i (φ k)) atTop (𝓝 c) := by
  have hs : IsCompact (Set.pi Set.univ (fun i => Set.Icc (-C i) (C i))) :=
    isCompact_univ_pi (fun i => isCompact_Icc)
  obtain ⟨c, -, φ, hφ, hc⟩ := hs.tendsto_subseq (x := fun n i => a i n)
    (fun n => by simp only [Set.mem_pi, Set.mem_univ, Set.mem_Icc, forall_const]
                 exact fun i => abs_le.1 (ha i n))
  exact ⟨φ, hφ, fun i => ⟨c i, (tendsto_pi_nhds.1 hc) i⟩⟩

#print axioms diag_subseq

theorem hilbert_weak_limit {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H]
    [CompleteSpace H] (x : ℕ → H) (B : ℝ) (hB : ∀ n, ‖x n‖ ≤ B)
    (hconv : ∀ m, ∃ c, Tendsto (fun n => inner ℝ (x m) (x n)) atTop (𝓝 c)) :
    ∃ w : H, ∀ z, Tendsto (fun n => inner ℝ z (x n)) atTop (𝓝 (inner ℝ z w)) := by
  set S : Submodule ℝ H := Submodule.span ℝ (Set.range x)
  have hS : ∀ z ∈ S, ∃ c, Tendsto (fun n => inner ℝ z (x n)) atTop (𝓝 c) := by
    intro z hz
    induction hz using Submodule.span_induction with
    | mem z hz => obtain ⟨m, rfl⟩ := hz; exact hconv m
    | zero => exact ⟨0, by simp⟩
    | add a b _ _ ha hb =>
      obtain ⟨c, hc⟩ := ha; obtain ⟨d, hd⟩ := hb
      exact ⟨c + d, by simpa [inner_add_left] using hc.add hd⟩
    | smul r a _ ha =>
      obtain ⟨c, hc⟩ := ha
      exact ⟨r * c, by simpa [real_inner_smul_left] using hc.const_mul r⟩
  set V := S.topologicalClosure
  have hB0 : 0 ≤ B := le_trans (norm_nonneg _) (hB 0)
  have hV : ∀ z ∈ V, ∃ c, Tendsto (fun n => inner ℝ z (x n)) atTop (𝓝 c) := by
    intro z hz
    apply cauchySeq_tendsto_of_complete
    rw [Metric.cauchySeq_iff']
    intro ε hε
    have hz' : z ∈ closure (S : Set H) := by
      rwa [← Submodule.topologicalClosure_coe]
    obtain ⟨z', hz'S, hzz'⟩ := Metric.mem_closure_iff.1 hz' (ε / (3 * (B + 1)))
      (by positivity)
    obtain ⟨c, hc⟩ := hS z' hz'S
    obtain ⟨N, hN⟩ := Metric.cauchySeq_iff'.1 hc.cauchySeq (ε / 3) (by positivity)
    refine ⟨N, fun n hn => ?_⟩
    have h1 : ∀ m, |inner ℝ z (x m) - inner ℝ z' (x m)| ≤ ε / 3 := by
      intro m
      rw [← inner_sub_left]
      calc |inner ℝ (z - z') (x m)| ≤ ‖z - z'‖ * ‖x m‖ := abs_real_inner_le_norm _ _
        _ ≤ ε / (3 * (B + 1)) * (B + 1) := by
            apply mul_le_mul (by rw [← dist_eq_norm]; exact hzz'.le) (by linarith [hB m])
              (norm_nonneg _) (by positivity)
        _ = ε / 3 := by field_simp
    have h2 := hN n hn
    rw [Real.dist_eq] at h2 ⊢
    have := h1 n; have := h1 N
    calc |inner ℝ z (x n) - inner ℝ z (x N)|
        ≤ |inner ℝ z (x n) - inner ℝ z' (x n)| + |inner ℝ z' (x n) - inner ℝ z' (x N)|
          + |inner ℝ z' (x N) - inner ℝ z (x N)| := by
          have := abs_add_three (inner ℝ z (x n) - inner ℝ z' (x n))
            (inner ℝ z' (x n) - inner ℝ z' (x N)) (inner ℝ z' (x N) - inner ℝ z (x N))
          ring_nf at this ⊢; linarith
      _ < ε := by rw [abs_sub_comm (inner ℝ z' (x N))]; linarith
  have hall : ∀ z, ∃ c, Tendsto (fun n => inner ℝ z (x n)) atTop (𝓝 c) := by
    intro z
    have htop : z ∈ V ⊔ Vᗮ := by
      rw [Submodule.sup_orthogonal_of_hasOrthogonalProjection]; trivial
    obtain ⟨a, ha, b, hb, rfl⟩ := Submodule.mem_sup.1 htop
    obtain ⟨c, hc⟩ := hV a ha
    refine ⟨c, ?_⟩
    have hxV : ∀ n, x n ∈ V := fun n =>
      Submodule.le_topologicalClosure _ (Submodule.subset_span ⟨n, rfl⟩)
    have : ∀ n, inner ℝ b (x n) = 0 := fun n =>
      Submodule.inner_left_of_mem_orthogonal (hxV n) hb
    simpa [inner_add_left, this] using hc
  choose f hf using hall
  let g : ℕ → H →L[ℝ] ℝ := fun n => innerSL ℝ (x n)
  have hg : Tendsto (fun n z => g n z) atTop (𝓝 f) := by
    rw [tendsto_pi_nhds]
    intro z
    simpa [g, real_inner_comm] using hf z
  let ℓ : H →L[ℝ] ℝ := continuousLinearMapOfTendsto g hg
  refine ⟨(InnerProductSpace.toDual ℝ H).symm ℓ, fun z => ?_⟩
  rw [real_inner_comm, InnerProductSpace.toDual_symm_apply]
  exact hf z

#print axioms hilbert_weak_limit

theorem trunc_abs_le (K : ℝ) (hK : 0 ≤ K) (r : ℝ) : |max (-K) (min K r)| ≤ K := by
  rw [abs_le]; constructor
  · exact le_max_left _ _
  · exact max_le (by linarith) (min_le_left _ _)

#print axioms trunc_abs_le

theorem trunc_abs_le_abs (K : ℝ) (hK : 0 ≤ K) (r : ℝ) : |max (-K) (min K r)| ≤ |r| := by
  rw [abs_le]
  rcases abs_cases r with h | h <;> rcases min_cases K r with h1 | h1 <;>
    rcases max_cases (-K) (min K r) with h2 | h2 <;> constructor <;> linarith

#print axioms trunc_abs_le_abs

theorem trunc_err (K : ℝ) (hK : 0 ≤ K) (r : ℝ) :
    |r - max (-K) (min K r)| ≤ if K < |r| then |r| else 0 := by
  split_ifs with h <;> rw [abs_le] <;>
  rcases abs_cases r with h' | h' <;> rcases min_cases K r with h1 | h1 <;>
    rcases max_cases (-K) (min K r) with h2 | h2 <;> constructor <;> linarith

#print axioms trunc_err

theorem memLp_top_ae_bound {α : Type*} [MeasurableSpace α] {μ : Measure α} {y : α → ℝ}
    (hy : MemLp y ∞ μ) : ∃ C, 0 ≤ C ∧ ∀ᵐ x ∂μ, |y x| ≤ C := by
  have h2 : eLpNormEssSup y μ ≠ ∞ := by
    have h := hy.eLpNorm_ne_top; rwa [eLpNorm_exponent_top hy.aestronglyMeasurable] at h
  refine ⟨(eLpNormEssSup y μ).toReal, ENNReal.toReal_nonneg, ?_⟩
  filter_upwards [ae_le_eLpNormEssSup (f := y) (μ := μ)] with x hx
  rw [← Real.norm_eq_abs, ← toReal_enorm]
  exact ENNReal.toReal_mono h2 hx

#print axioms memLp_top_ae_bound

theorem tail_integrable {α : Type*} [MeasurableSpace α] {μ : Measure α} {f : α → ℝ}
    (hf : Integrable f μ) (K : ℝ) : Integrable (fun x => if K < |f x| then |f x| else 0) μ := by
  have hm : Measurable (fun r : ℝ => if K < |r| then |r| else 0) :=
    Measurable.ite (measurableSet_lt measurable_const continuous_abs.measurable)
      continuous_abs.measurable measurable_const
  refine hf.norm.mono' (hm.comp_aemeasurable hf.aemeasurable).aestronglyMeasurable
    (ae_of_all _ fun x => ?_)
  simp only [Real.norm_eq_abs]
  split_ifs <;> simp

#print axioms tail_integrable

theorem trunc_err_integral {α : Type*} [MeasurableSpace α] {μ : Measure α} [IsFiniteMeasure μ]
    {f y : α → ℝ} (hf : Integrable f μ) (hy : MemLp y ∞ μ) (Cy : ℝ)
    (hCy : ∀ᵐ x ∂μ, |y x| ≤ Cy) (K : ℝ) (hK : 0 ≤ K) :
    |∫ x, y x * f x ∂μ - ∫ x, y x * max (-K) (min K (f x)) ∂μ| ≤
      Cy * ∫ x, (if K < |f x| then |f x| else 0) ∂μ := by
  have hTf : Integrable (fun x => max (-K) (min K (f x))) μ :=
    hf.norm.mono' (((continuous_const.max (continuous_const.min continuous_id)).comp_aestronglyMeasurable
      hf.aestronglyMeasurable)) (ae_of_all _ fun x => by
        simpa [Real.norm_eq_abs] using trunc_abs_le_abs K hK (f x))
  have h1 : Integrable (fun x => y x * f x) μ := hf.mul_of_top_right hy
  have h2 : Integrable (fun x => y x * max (-K) (min K (f x))) μ := hTf.mul_of_top_right hy
  rw [← integral_sub h1 h2, ← integral_const_mul]
  refine (abs_integral_le_integral_abs).trans (integral_mono_ae (h1.sub h2).abs
    ((tail_integrable hf K).const_mul Cy) ?_)
  filter_upwards [hCy] with x hx
  rw [← mul_sub, abs_mul]
  exact mul_le_mul hx (trunc_err K hK (f x)) (abs_nonneg _) ((abs_nonneg _).trans hx)

#print axioms trunc_err_integral

theorem click_measurable (n : ℕ) : Measurable (click n) := by
  unfold click
  exact Measurable.ite (measurableSet_lt measurable_fract measurable_const)
    measurable_const measurable_const

#print axioms click_measurable

theorem click_abs_le (n : ℕ) (x : ℝ) : |click n x| ≤ n := by
  unfold click; split_ifs <;> simp

#print axioms click_abs_le

theorem click_eq (n : ℕ) {y : ℝ} (h0 : 0 ≤ y) (h1 : y < 1) :
    click n y = if y < 1 / (n : ℝ) then (n : ℝ) else 0 := by
  simp only [click, Int.fract_eq_self.2 ⟨h0, h1⟩]

#print axioms click_eq

theorem click_eq_neg (n : ℕ) {y : ℝ} (h0 : -1 ≤ y) (h1 : y < 0) :
    click n y = if y + 1 < 1 / (n : ℝ) then (n : ℝ) else 0 := by
  have : Int.fract y = y + 1 := Int.fract_eq_iff.2 ⟨by linarith, by linarith, -1, by push_cast; ring⟩
  simp only [click, this]

#print axioms click_eq_neg

theorem integral_eq_of_Ioo {f : ℝ → ℝ} {a b c : ℝ} (hab : a ≤ b)
    (h : ∀ x ∈ Set.Ioo a b, f x = c) : ∫ x in a..b, f x = (b - a) * c := by
  rw [intervalIntegral.integral_of_le hab, integral_Ioc_eq_integral_Ioo,
    setIntegral_congr_fun measurableSet_Ioo h, setIntegral_const]
  simp [Measure.real, Real.volume_Ioo, ENNReal.toReal_ofReal (sub_nonneg.2 hab)]

#print axioms integral_eq_of_Ioo

theorem ii_of_bdd {g : ℝ → ℝ} (hg : Measurable g) (M : ℝ) (hM : ∀ x, |g x| ≤ M) (a b : ℝ) :
    IntervalIntegrable g volume a b := by
  refine ⟨?_, ?_⟩ <;>
  exact Measure.integrableOn_of_bounded (M := M) (by simp) hg.aestronglyMeasurable
    (ae_of_all _ fun x => by simpa [Real.norm_eq_abs] using hM x)

#print axioms ii_of_bdd

theorem clicks_part1 : ∀ n : ℕ, 2 ≤ n → ∀ h : ℝ, 0 ≤ h → h ≤ 1 / 2 →
        ∫ x in (0 : ℝ)..1, |click n (x - h) - click n x| = 2 * min ((n : ℝ) * h) 1 := by
  intro n hn h h0 h1
  have hn' : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have hn0 : (0 : ℝ) < n := by linarith
  have ha0 : (0 : ℝ) < 1 / n := by positivity
  have ha1 : 1 / (n : ℝ) ≤ 1 / 2 := by
    rw [div_le_div_iff₀ hn0 (by norm_num)]; linarith
  have hna : (n : ℝ) * (1 / n) = 1 := by field_simp
  have ii : ∀ p q, IntervalIntegrable (fun x => |click n (x - h) - click n x|) volume p q :=
    ii_of_bdd (((click_measurable n).comp (measurable_id.sub_const h)).sub
      (click_measurable n)).abs (2 * n) (fun x => by
        rw [abs_abs]
        have := click_abs_le n (x - h); have := click_abs_le n x
        calc |click n (x - h) - click n x| ≤ |click n (x - h)| + |click n x| := abs_sub _ _
          _ ≤ 2 * n := by linarith)
  rcases le_or_gt h (1 / n) with hh | hh
  · rw [← intervalIntegral.integral_add_adjacent_intervals (ii 0 h) (ii h 1),
      ← intervalIntegral.integral_add_adjacent_intervals (ii h (1 / n)) (ii (1 / n) 1),
      ← intervalIntegral.integral_add_adjacent_intervals (ii (1 / n) (h + 1 / n))
        (ii (h + 1 / n) 1)]
    rw [integral_eq_of_Ioo h0 (c := n) (fun x hx => by
          rw [click_eq_neg n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_right (by linarith [hx.1]), ite_eq_left (by linarith [hx.2])]; simp),
      integral_eq_of_Ioo hh (c := 0) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_left (by linarith [hx.2]), ite_eq_left (by linarith [hx.2])]; simp),
      integral_eq_of_Ioo (by linarith) (c := n) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_left (by linarith [hx.2]), ite_eq_right (by linarith [hx.1])]; simp),
      integral_eq_of_Ioo (by linarith) (c := 0) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_right (by linarith [hx.1]), ite_eq_right (by linarith [hx.1])]; simp)]
    have : (n : ℝ) * h ≤ 1 := by nlinarith
    rw [min_eq_left this]; ring
  · rw [← intervalIntegral.integral_add_adjacent_intervals (ii 0 (1 / n)) (ii (1 / n) 1),
      ← intervalIntegral.integral_add_adjacent_intervals (ii (1 / n) h) (ii h 1),
      ← intervalIntegral.integral_add_adjacent_intervals (ii h (h + 1 / n))
        (ii (h + 1 / n) 1)]
    rw [integral_eq_of_Ioo ha0.le (c := n) (fun x hx => by
          rw [click_eq_neg n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_right (by linarith [hx.1]), ite_eq_left (by linarith [hx.2])]; simp),
      integral_eq_of_Ioo hh.le (c := 0) (fun x hx => by
          rw [click_eq_neg n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_right (by linarith [hx.1]), ite_eq_right (by linarith [hx.1])]; simp),
      integral_eq_of_Ioo (by linarith) (c := n) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_left (by linarith [hx.2]), ite_eq_right (by linarith [hx.1])]; simp),
      integral_eq_of_Ioo (by linarith) (c := 0) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_right (by linarith [hx.1]), ite_eq_right (by linarith [hx.1])]; simp)]
    have : 1 ≤ (n : ℝ) * h := by nlinarith
    rw [min_eq_right this]; linear_combination 2 * hna

#print axioms clicks_part1

theorem clicks_part2 : ∀ n m : ℕ, 0 < n → n < m →
        ∫ x in (0 : ℝ)..1, |click n x - click m x| = 2 * (1 - (n : ℝ) / m) := by
  intro n m hn hnm
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hnm' : (n : ℝ) < m := by exact_mod_cast hnm
  have hm0 : (0 : ℝ) < m := by linarith
  have hb0 : (0 : ℝ) < 1 / m := by positivity
  have hba : 1 / (m : ℝ) < 1 / n := one_div_lt_one_div_of_lt (by linarith) hnm'
  have ha1 : 1 / (n : ℝ) ≤ 1 := by rw [div_le_one (by linarith)]; exact hn1
  have ii : ∀ p q, IntervalIntegrable (fun x => |click n x - click m x|) volume p q :=
    ii_of_bdd ((click_measurable n).sub (click_measurable m)).abs (n + m) (fun x => by
        rw [abs_abs]
        have := click_abs_le n x; have := click_abs_le m x
        calc |click n x - click m x| ≤ |click n x| + |click m x| := abs_sub _ _
          _ ≤ n + m := by linarith)
  rw [← intervalIntegral.integral_add_adjacent_intervals (ii 0 (1 / m)) (ii (1 / m) 1),
      ← intervalIntegral.integral_add_adjacent_intervals (ii (1 / m) (1 / n)) (ii (1 / n) 1)]
  rw [integral_eq_of_Ioo hb0.le (c := m - n) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq m (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_left (by linarith [hx.2]), ite_eq_left (by linarith [hx.2])]
          rw [abs_of_neg (by linarith)]; ring),
      integral_eq_of_Ioo hba.le (c := n) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq m (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_left (by linarith [hx.2]), ite_eq_right (by linarith [hx.1])]; simp),
      integral_eq_of_Ioo ha1 (c := 0) (fun x hx => by
          rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
            click_eq m (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_right (by linarith [hx.1]), ite_eq_right (by linarith [hx.1, hx.2])]; simp)]
  field_simp; ring

#print axioms clicks_part2

theorem setIntegral_Ico_eq (f : ℝ → ℝ) {a b : ℝ} (hab : a ≤ b) :
    ∫ x in Set.Ico a b, f x = ∫ x in a..b, f x := by
  rw [intervalIntegral.integral_of_le hab, integral_Ico_eq_integral_Ioo,
    integral_Ioc_eq_integral_Ioo]

#print axioms setIntegral_Ico_eq

theorem clicks_part3 : ∀ K : ℝ, ∀ n : ℕ, 0 < n → K < n →
        ∫ x in Set.Ico (0 : ℝ) 1, (if K < |click n x| then |click n x| else 0) = 1 := by
  intro K n hn hK
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have ha0 : (0 : ℝ) < 1 / n := by positivity
  have ha1 : 1 / (n : ℝ) ≤ 1 := by rw [div_le_one (by linarith)]; exact hn1
  have hm : Measurable (fun x => if K < |click n x| then |click n x| else 0) :=
    Measurable.ite (measurableSet_lt measurable_const (click_measurable n).abs)
      (click_measurable n).abs measurable_const
  have ii : ∀ p q, IntervalIntegrable (fun x => if K < |click n x| then |click n x| else 0)
      volume p q := ii_of_bdd hm n (fun x => by
        have := click_abs_le n x
        split_ifs <;> simp [abs_abs, this])
  rw [setIntegral_Ico_eq _ zero_le_one,
    ← intervalIntegral.integral_add_adjacent_intervals (ii 0 (1 / n)) (ii (1 / n) 1),
    integral_eq_of_Ioo ha0.le (c := n) (fun x hx => by
      rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
        ite_eq_left (show x < 1 / (n : ℝ) by linarith [hx.2])]
      rw [abs_of_pos (by linarith), ite_eq_left hK]),
    integral_eq_of_Ioo ha1 (c := 0) (fun x hx => by
      rw [click_eq n (by linarith [hx.1]) (by linarith [hx.2]),
        ite_eq_right (show ¬ x < 1 / (n : ℝ) by linarith [hx.1])]
      simp)]
  field_simp; ring

#print axioms clicks_part3

theorem clicks_part4 : ¬ ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ v : ℝ → ℝ, IntegrableOn v (Set.Ico 0 1) ∧
        ∀ y : ℝ → ℝ, MemLp y ∞ (volume.restrict (Set.Ico (0 : ℝ) 1)) →
          Tendsto (fun k => ∫ x in Set.Ico (0 : ℝ) 1, y x * click (φ k) x) atTop
            (𝓝 (∫ x in Set.Ico (0 : ℝ) 1, y x * v x)) := by
  rintro ⟨φ, hφ, v, hv, hlim⟩
  have key : ∀ t : ℝ, 0 < t → t ≤ 1 → ∫ x in (0 : ℝ)..t, v x = 1 := by
    intro t ht0 ht1
    set y : ℝ → ℝ := fun x => if x < t then 1 else 0 with hy_def
    have hym : Measurable y := Measurable.ite (measurableSet_lt measurable_id measurable_const)
      measurable_const measurable_const
    have hy : MemLp y ∞ (volume.restrict (Set.Ico (0 : ℝ) 1)) :=
      memLp_top_of_bound hym.aestronglyMeasurable 1 (ae_of_all _ fun x => by
        simp only [hy_def]; split_ifs <;> simp)
    have h1 := hlim y hy
    have hev : ∀ᶠ k in atTop, ∫ x in Set.Ico (0 : ℝ) 1, y x * click (φ k) x = 1 := by
      obtain ⟨N, hN⟩ := exists_nat_gt (1 / t)
      filter_upwards [hφ.tendsto_atTop.eventually_ge_atTop (max N 1)] with k hk
      have hn1 : (1 : ℝ) ≤ φ k := by exact_mod_cast (le_max_right _ _).trans hk
      have hNk : (N : ℝ) ≤ φ k := by exact_mod_cast (le_max_left _ _).trans hk
      have ha0 : (0 : ℝ) < 1 / (φ k : ℝ) := by positivity
      have hnt : 1 / (φ k : ℝ) ≤ t := by
        rw [div_le_iff₀ (by linarith)]
        rw [div_lt_iff₀ ht0] at hN; nlinarith
      have hm : Measurable (fun x => y x * click (φ k) x) := hym.mul (click_measurable _)
      have ii : ∀ p q, IntervalIntegrable (fun x => y x * click (φ k) x) volume p q :=
        ii_of_bdd hm (φ k) (fun x => by
          have := click_abs_le (φ k) x
          rw [abs_mul]; simp only [hy_def]; split_ifs <;> simp [this])
      rw [setIntegral_Ico_eq _ zero_le_one,
        ← intervalIntegral.integral_add_adjacent_intervals (ii 0 (1 / φ k)) (ii (1 / φ k) 1),
        ← intervalIntegral.integral_add_adjacent_intervals (ii (1 / φ k) t) (ii t 1),
        integral_eq_of_Ioo ha0.le (c := φ k) (fun x hx => by
          rw [click_eq _ (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_left (show x < 1 / (φ k : ℝ) by linarith [hx.2])]
          simp only [hy_def]; rw [ite_eq_left (show x < t by linarith [hx.2])]; ring),
        integral_eq_of_Ioo hnt (c := 0) (fun x hx => by
          rw [click_eq _ (by linarith [hx.1]) (by linarith [hx.2]),
            ite_eq_right (show ¬ x < 1 / (φ k : ℝ) by linarith [hx.1])]; ring),
        integral_eq_of_Ioo ht1 (c := 0) (fun x hx => by
          simp only [hy_def]; rw [ite_eq_right (show ¬ x < t by linarith [hx.1])]; ring)]
      field_simp; ring
    have h2 : Tendsto (fun k => ∫ x in Set.Ico (0 : ℝ) 1, y x * click (φ k) x) atTop (𝓝 1) :=
      tendsto_const_nhds.congr' (hev.mono fun k hk => hk.symm)
    have h3 := tendsto_nhds_unique h1 h2
    rw [← h3]
    have : ∫ x in Set.Ico (0 : ℝ) 1, y x * v x =
        ∫ x in Set.Ico (0 : ℝ) 1, (Set.Iio t).indicator v x := by
      congr 1; ext x; simp only [hy_def, Set.indicator, Set.mem_Iio]; split_ifs <;> simp
    rw [this, setIntegral_indicator measurableSet_Iio, Set.Ico_inter_Iio, min_eq_right ht1,
      setIntegral_Ico_eq _ ht0.le]
  have hvi : IntervalIntegrable v volume 0 1 := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le zero_le_one]
    exact hv.congr_set_ae Ico_ae_eq_Ioc.symm
  have hcw : ContinuousWithinAt (fun b => ∫ x in (0 : ℝ)..b, v x) (Set.uIcc 0 1) 0 :=
    intervalIntegral.continuousOn_primitive_interval' hvi Set.left_mem_uIcc 0 Set.left_mem_uIcc
  have ht : Tendsto (fun j : ℕ => 1 / ((j : ℝ) + 1)) atTop (𝓝[Set.uIcc 0 1] 0) := by
    refine tendsto_nhdsWithin_iff.2 ⟨tendsto_one_div_add_atTop_nhds_zero_nat, ?_⟩
    refine Eventually.of_forall fun j => ?_
    rw [Set.uIcc_of_le zero_le_one]
    constructor
    · positivity
    · rw [div_le_one (by positivity)]; simp
  have hA := hcw.tendsto.comp ht
  have hB : Tendsto ((fun b => ∫ x in (0 : ℝ)..b, v x) ∘ fun j : ℕ => 1 / ((j : ℝ) + 1)) atTop
      (𝓝 1) := by
    refine tendsto_const_nhds.congr fun j => ?_
    simp only [Function.comp]
    rw [key _ (by positivity) (by rw [div_le_one (by positivity)]; simp)]
  have := tendsto_nhds_unique hA hB
  simp at this

#print axioms clicks_part4

/-- Kolmogorov–Riesz on the loop. Let 1 ≤ p < ∞ and let 𝓕 be a family of real clips in Lp of
the one-second loop, bounded: every member has size at most some B. Then every sequence in 𝓕
has a subsequence converging in Lp size to some clip in Lp exactly when one small delay moves
every member by little: for every tolerance ε > 0 there is a δ > 0 such that every delay s with
|s| ≤ δ gives ‖τ_s f − f‖_p ≤ ε for every member f at once (the shift modulus ω_𝓕(h) tends to 0
as h tends to 0). -/
theorem relatively_compact_iff_small_delays_move_every_member_little
    (p : ℝ≥0∞) [Fact (1 ≤ p)] (hp : p ≠ ∞)
    (𝓕 : Set (Lp ℝ p (volume : Measure UnitAddCircle)))
    (hbdd : ∃ B : ℝ, ∀ f ∈ 𝓕, ‖f‖ ≤ B) :
    (∀ u : ℕ → Lp ℝ p (volume : Measure UnitAddCircle), (∀ n, u n ∈ 𝓕) →
      ∃ g : Lp ℝ p (volume : Measure UnitAddCircle), ∃ φ : ℕ → ℕ, StrictMono φ ∧
        Tendsto (fun k => u (φ k)) atTop (𝓝 g)) ↔
    (∀ ε > 0, ∃ δ > 0, ∀ f ∈ 𝓕, ∀ s : ℝ, |s| ≤ δ → ‖delay p s f - f‖ ≤ ε) := by
  constructor
  · exact forward_dir p hp 𝓕
  · intro hEC u hu
    have hTB := reverse_dir p hp 𝓕 hbdd hEC
    have hc : IsCompact (closure 𝓕) := hTB.closure.isCompact_of_isClosed isClosed_closure
    obtain ⟨g, -, φ, hφ, hlim⟩ := hc.tendsto_subseq (fun n => subset_closure (hu n))
    exact ⟨g, φ, hφ, hlim⟩

/-- Dunford–Pettis, the direction the card proves. On a space of finite total measure, let 𝓕 be
a family of integrable real functions that is uniformly integrable in the card's sense: the worst
area any member keeps above a level K, sup over f in 𝓕 of the integral of |f| over {|f| > K},
tends to 0 as K grows. Then every sequence in 𝓕 has a subsequence that converges weakly in L1 to
an integrable v: for every bounded weight y in L∞, the readings ∫ y f_{n_k} settle at ∫ y v. -/
theorem uniformly_integrable_has_weakly_convergent_subsequence
    {α : Type*} [MeasurableSpace α] (μ : Measure α) [IsFiniteMeasure μ]
    (𝓕 : Set (α → ℝ)) (hint : ∀ f ∈ 𝓕, Integrable f μ)
    (hui : ∀ ε > 0, ∃ K₀ : ℝ, ∀ K ≥ K₀, ∀ f ∈ 𝓕,
      ∫ x, (if K < |f x| then |f x| else 0) ∂μ ≤ ε)
    (u : ℕ → α → ℝ) (hu : ∀ n, u n ∈ 𝓕) :
    ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ v : α → ℝ, Integrable v μ ∧
      ∀ y : α → ℝ, MemLp y ∞ μ →
        Tendsto (fun k => ∫ x, y x * u (φ k) x ∂μ) atTop (𝓝 (∫ x, y x * v x ∂μ)) := by
  classical
  have hui' : ∀ ε > 0, ∃ N : ℕ, ∀ K : ℕ, N ≤ K → ∀ n,
      ∫ x, (if (K : ℝ) < |u n x| then |u n x| else 0) ∂μ ≤ ε := by
    intro ε hε
    obtain ⟨K₀, hK₀⟩ := hui ε hε
    refine ⟨⌈K₀⌉₊, fun K hK n => hK₀ K ?_ _ (hu n)⟩
    exact (Nat.le_ceil K₀).trans (by exact_mod_cast hK)
  let T : ℕ → ℝ → ℝ := fun K r => max (-(K : ℝ)) (min (K : ℝ) r)
  have hTc : ∀ K, Continuous (T K) := fun K =>
    continuous_const.max (continuous_const.min continuous_id)
  have hTb : ∀ K r, |T K r| ≤ K := fun K r => trunc_abs_le K K.cast_nonneg r
  have hTm : ∀ K n, MemLp (fun x => T K (u n x)) ∞ μ := fun K n =>
    memLp_top_of_bound ((hTc K).comp_aestronglyMeasurable (hint _ (hu n)).aestronglyMeasurable) K
      (ae_of_all _ fun x => by simpa [Real.norm_eq_abs] using hTb K (u n x))
  have hT2 : ∀ K n, MemLp (fun x => T K (u n x)) 2 μ := fun K n =>
    (hTm K n).mono_exponent le_top
  let X : ℕ → ℕ → Lp ℝ 2 μ := fun K n => (hT2 K n).toLp _
  obtain ⟨C, hC⟩ : ∃ C : ℕ → ℝ, ∀ K n, ‖X K n‖ ≤ C K := ⟨_, fun K n =>
    Lp.norm_le_of_ae_bound K.cast_nonneg (by
      filter_upwards [(hT2 K n).coeFn_toLp] with x hx
      rw [hx]; simpa [Real.norm_eq_abs] using hTb K (u n x))⟩
  have hC0 : ∀ K, 0 ≤ C K := fun K => (norm_nonneg _).trans (hC K 0)
  obtain ⟨φ, hφ, hconv⟩ := diag_subseq (ι := ℕ × ℕ)
    (fun i n => inner ℝ (X i.1 i.2) (X i.1 n)) (fun i => C i.1 * C i.1)
    (fun i n => (abs_real_inner_le_norm _ _).trans
      (mul_le_mul (hC _ _) (hC _ _) (norm_nonneg _) (hC0 _)))
  have hw : ∀ K, ∃ w : Lp ℝ 2 μ, ∀ z, Tendsto (fun k => inner ℝ z (X K (φ k))) atTop
      (𝓝 (inner ℝ z w)) := fun K =>
    hilbert_weak_limit (fun k => X K (φ k)) (C K) (fun k => hC K _) (fun m => hconv (K, φ m))
  choose w hw using hw
  -- readings
  have hread : ∀ y (hy : MemLp y ∞ μ) K n,
      inner ℝ ((hy.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).toLp y) (X K n) =
        ∫ x, y x * T K (u n x) ∂μ := by
    intro y hy K n
    rw [L2.inner_def]
    apply integral_congr_ae
    filter_upwards [(hy.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).coeFn_toLp,
      (hT2 K n).coeFn_toLp] with x h1 h2
    simp only [X] at h2 ⊢
    rw [h1, h2]; simp [mul_comm]
  have hreadw : ∀ y (hy : MemLp y ∞ μ) K,
      inner ℝ ((hy.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).toLp y) (w K) =
        ∫ x, y x * w K x ∂μ := by
    intro y hy K
    rw [L2.inner_def]
    apply integral_congr_ae
    filter_upwards [(hy.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).coeFn_toLp] with x h1
    rw [h1]; simp [mul_comm]
  have hwint : ∀ K, Integrable (w K) μ := fun K => (Lp.memLp (w K)).integrable one_le_two
  -- L1 Cauchy estimate
  have hcau : ∀ ε > 0, ∃ N : ℕ, ∀ K ≥ N, ∀ L ≥ N, ∫ x, |w K x - w L x| ∂μ ≤ 2 * ε := by
    intro ε hε
    obtain ⟨N, hN⟩ := hui' ε hε
    refine ⟨N, fun K hK L hL => ?_⟩
    set s : α → ℝ := fun x => if 0 ≤ w K x - w L x then 1 else -1 with hs_def
    have hsm : Measurable s :=
      Measurable.ite (measurableSet_le measurable_const
        ((Lp.stronglyMeasurable (w K)).measurable.sub (Lp.stronglyMeasurable (w L)).measurable))
        measurable_const measurable_const
    have hs : MemLp s ∞ μ := memLp_top_of_bound hsm.aestronglyMeasurable 1
      (ae_of_all _ fun x => by simp only [hs_def]; split_ifs <;> simp)
    have hs1 : ∀ᵐ x ∂μ, |s x| ≤ 1 := ae_of_all _ fun x => by
      simp only [hs_def]; split_ifs <;> simp
    have hkey : ∫ x, |w K x - w L x| ∂μ =
        inner ℝ ((hs.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).toLp s) (w K) -
        inner ℝ ((hs.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).toLp s) (w L) := by
      have i1 : Integrable (fun x => s x * w K x) μ := (hwint K).mul_of_top_right hs
      have i2 : Integrable (fun x => s x * w L x) μ := (hwint L).mul_of_top_right hs
      rw [hreadw s hs, hreadw s hs, ← integral_sub i1 i2]
      congr 1; ext x
      simp only [hs_def]
      split_ifs with h
      · rw [abs_of_nonneg h]; ring
      · rw [abs_of_neg (not_le.1 h)]; ring
    rw [hkey]
    have hlim := ((hw K ((hs.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).toLp s)).sub
      (hw L ((hs.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).toLp s)))
    refine le_of_tendsto' hlim fun k => ?_
    rw [hread s hs, hread s hs]
    have e1 := trunc_err_integral (hint _ (hu (φ k))) hs 1 hs1 K K.cast_nonneg
    have e2 := trunc_err_integral (hint _ (hu (φ k))) hs 1 hs1 L L.cast_nonneg
    have b1 := hN K hK (φ k)
    have b2 := hN L hL (φ k)
    simp only [T]
    have := abs_le.1 e1; have := abs_le.1 e2
    nlinarith
  -- L1 elements
  let W : ℕ → Lp ℝ 1 μ := fun K => ((Lp.memLp (w K)).mono_exponent one_le_two).toLp (w K)
  have hWd : ∀ K (V : Lp ℝ 1 μ), ‖W K - V‖ = ∫ x, |w K x - V x| ∂μ := by
    intro K V
    rw [L1.norm_eq_integral_norm]
    apply integral_congr_ae
    filter_upwards [Lp.coeFn_sub (W K) V,
      ((Lp.memLp (w K)).mono_exponent one_le_two).coeFn_toLp] with x h1 h2
    rw [h1, Pi.sub_apply, h2, Real.norm_eq_abs]
  have hWc : CauchySeq W := by
    rw [Metric.cauchySeq_iff']
    intro ε hε
    obtain ⟨N, hN⟩ := hcau (ε / 4) (by positivity)
    refine ⟨N, fun n hn => ?_⟩
    rw [dist_eq_norm, hWd]
    have h1 := hN n hn N le_rfl
    have h2 : ∫ x, |w n x - (W N) x| ∂μ = ∫ x, |w n x - w N x| ∂μ := by
      apply integral_congr_ae
      filter_upwards [((Lp.memLp (w N)).mono_exponent one_le_two).coeFn_toLp] with x hx
      rw [hx]
    rw [h2]; linarith
  obtain ⟨V, hV⟩ := cauchySeq_tendsto_of_complete hWc
  refine ⟨φ, hφ, V, L1.integrable_coeFn V, fun y hy => ?_⟩
  obtain ⟨Cy, hCy0, hCy⟩ := memLp_top_ae_bound hy
  rw [Metric.tendsto_atTop]
  intro ε hε
  set η := ε / (4 * (Cy + 1)) with hη
  have hη0 : 0 < η := by positivity
  obtain ⟨N1, hN1⟩ := hui' η hη0
  obtain ⟨N2, hN2⟩ := Metric.tendsto_atTop.1 hV η hη0
  set K := max N1 N2
  have hK3 : |∫ x, y x * w K x ∂μ - ∫ x, y x * V x ∂μ| ≤ Cy * η := by
    have hd := hN2 K (le_max_right _ _)
    rw [dist_eq_norm, hWd] at hd
    have i1 : Integrable (fun x => y x * w K x) μ := (hwint K).mul_of_top_right hy
    have i2 : Integrable (fun x => y x * V x) μ := (L1.integrable_coeFn V).mul_of_top_right hy
    rw [← integral_sub i1 i2]
    calc _ ≤ ∫ x, |y x * w K x - y x * V x| ∂μ := abs_integral_le_integral_abs
      _ ≤ ∫ x, Cy * |w K x - V x| ∂μ := integral_mono_ae (i1.sub i2).abs
          (((hwint K).sub (L1.integrable_coeFn V)).abs.const_mul Cy) (by
            filter_upwards [hCy] with x hx
            rw [← mul_sub, abs_mul]; exact mul_le_mul_of_nonneg_right hx (abs_nonneg _))
      _ = Cy * ∫ x, |w K x - V x| ∂μ := integral_const_mul _ _
      _ ≤ Cy * η := mul_le_mul_of_nonneg_left hd.le hCy0
  have hK1 : ∀ n, |∫ x, y x * u n x ∂μ - ∫ x, y x * T K (u n x) ∂μ| ≤ Cy * η := fun n =>
    (trunc_err_integral (hint _ (hu n)) hy Cy hCy K K.cast_nonneg).trans
      (mul_le_mul_of_nonneg_left (hN1 K (le_max_left _ _) n) hCy0)
  have hlimK := hw K ((hy.mono_exponent (le_top : (2 : ℝ≥0∞) ≤ ∞)).toLp y)
  rw [hreadw y hy] at hlimK
  obtain ⟨N3, hN3⟩ := Metric.tendsto_atTop.1 hlimK (ε / 4) (by positivity)
  refine ⟨N3, fun k hk => ?_⟩
  have h3 := hN3 k hk
  rw [hread y hy, Real.dist_eq] at h3
  rw [Real.dist_eq]
  have hCη : Cy * η ≤ ε / 4 := by
    rw [hη, mul_div_assoc', div_le_div_iff₀ (by positivity) (by positivity)]; nlinarith
  have a1 := abs_le.1 (hK1 (φ k))
  have a2 := abs_lt.1 h3
  have a3 := abs_le.1 hK3
  rw [abs_lt]; constructor <;> linarith

/-- The clicks fail both tests. Click n is n on [0, 1/n) of the loop and 0 elsewhere, so its L1
size is 1. (1) For n ≥ 2 and a delay 0 ≤ h ≤ 1/2, the L1 distance between click n and its delayed
copy is 2 min(nh, 1), so it reaches 2 once n ≥ 1/h. (2) For 0 < n < m, clicks n and m are
2(1 − n/m) apart in L1, so clicks n and 2n stay 1 apart and no subsequence converges in L1.
(3) Above any level K, every click with n > K keeps its whole area 1: not uniformly integrable.
(4) No subsequence of the clicks converges weakly in L1 of [0, 1) to an integrable v. -/
theorem clicks_fail_shift_test_and_pile_up
    : (∀ n : ℕ, 2 ≤ n → ∀ h : ℝ, 0 ≤ h → h ≤ 1 / 2 →
        ∫ x in (0 : ℝ)..1, |click n (x - h) - click n x| = 2 * min ((n : ℝ) * h) 1) ∧
      (∀ n m : ℕ, 0 < n → n < m →
        ∫ x in (0 : ℝ)..1, |click n x - click m x| = 2 * (1 - (n : ℝ) / m)) ∧
      (∀ K : ℝ, ∀ n : ℕ, 0 < n → K < n →
        ∫ x in Set.Ico (0 : ℝ) 1, (if K < |click n x| then |click n x| else 0) = 1) ∧
      (¬ ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ v : ℝ → ℝ, IntegrableOn v (Set.Ico 0 1) ∧
        ∀ y : ℝ → ℝ, MemLp y ∞ (volume.restrict (Set.Ico (0 : ℝ) 1)) →
          Tendsto (fun k => ∫ x in Set.Ico (0 : ℝ) 1, y x * click (φ k) x) atTop
            (𝓝 (∫ x in Set.Ico (0 : ℝ) 1, y x * v x))) := by
  exact ⟨clicks_part1, clicks_part2, clicks_part3, clicks_part4⟩

-- Worked numbers, by hand: click 100 is 100 units tall for 1/100 s, so its size is 1.
example : (100 : ℚ) * (1 / 100) = 1 := by norm_num
-- A delay of h = 1/1000 moves click 100 by 2 × 100 × 1/1000 = 1/5.
example : 2 * min ((100 : ℚ) * (1 / 1000)) 1 = 1 / 5 := by norm_num
-- A delay of h = 1/100, the click's own length, moves it by 2 min(100 × 1/100, 1) = 2.
example : 2 * min ((100 : ℚ) * (1 / 100)) 1 = 2 := by norm_num
-- Clicks 1000 and 10000 move by the full 2 at h = 1/1000.
example : 2 * min ((1000 : ℚ) * (1 / 1000)) 1 = 2 ∧ 2 * min ((10000 : ℚ) * (1 / 1000)) 1 = 2 := by
  norm_num
-- Clicks 100 and 200 are 2 (1 − 100/200) = 1 apart; (10, 40) gives 3/2; (100, 10000) gives 99/50.
example : 2 * (1 - (100 : ℚ) / 200) = 1 ∧ 2 * (1 - (10 : ℚ) / 20) = 1 ∧
    2 * (1 - (10 : ℚ) / 40) = 3 / 2 ∧ 2 * (1 - (100 : ℚ) / 10000) = 99 / 50 := by norm_num
-- Readings on the first millisecond: min(1, n/1000) is 1/100, 1/10, 1, 1 at n = 10, 100, 1000, 10000.
example : min (1 : ℚ) (10 * (1 / 1000)) = 1 / 100 ∧ min (1 : ℚ) (100 * (1 / 1000)) = 1 / 10 ∧
    min (1 : ℚ) (1000 * (1 / 1000)) = 1 ∧ min (1 : ℚ) (10000 * (1 / 1000)) = 1 := by norm_num
-- Blurred click 100 against the 50 ms box: 1/(100 × 1/20) = 1/5.
example : 1 / ((100 : ℚ) * (1 / 20)) = 1 / 5 := by norm_num
-- Worst move of any blurred click at h = 1/1000, blur ε = 1/20: 2h/ε = 1/25 (40h).
example : 2 * (1 / 1000 : ℚ) / (1 / 20) = 1 / 25 ∧ 40 * (1 / 1000 : ℚ) = 1 / 25 := by norm_num

#print axioms relatively_compact_iff_small_delays_move_every_member_little
#print axioms uniformly_integrable_has_weakly_convergent_subsequence
#print axioms clicks_fail_shift_test_and_pile_up
