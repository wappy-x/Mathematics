-- KVA: under the simple capital rule, the KVA integral of a bought option collapses to hurdle times capital rate times today's price times the survival-weighted life, and the integral itself comes from averaging the capital cost stream over default and the market.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.Probability.Process.Filtration
import Mathlib.Probability.Independence.Integration

open MeasureTheory ProbabilityTheory Real
open scoped ENNReal

/-- KVA closed form for a bought option (Steps 2 and 3). The option pays `X ≥ 0` at expiry `T`;
its clean value at date `t` is `V(t) = e^{-r(T-t)} 𝔼[X | ℱ t]` and today's price is
`C₀ = e^{-rT} 𝔼[X]`. Under the simple rule capital is a fixed multiple `c` of the exposure
`max(V(t), 0)`. With hurdle `h`, discount `e^{-rt}` and survival `e^{-λt}` at a hazard `λ > 0`,
the KVA integral `h ∫₀ᵀ D(t) 𝔼[K(t)] Q(t) dt` equals `h · c · C₀ · (1 - e^{-λT}) / λ`. -/
theorem kva_closed_form_bought_option {Ω : Type*} {m0 : MeasurableSpace Ω}
    (μ : Measure Ω) [IsProbabilityMeasure μ] (ℱ : Filtration ℝ m0)
    (X : Ω → ℝ) (hX : ∀ ω, 0 ≤ X ω) (h c r lam T : ℝ) (hlam : 0 < lam) :
    h * ∫ t in (0)..T,
        exp (-r * t) * (∫ ω, c * max (exp (-r * (T - t)) * μ[X | ℱ t] ω) 0 ∂μ) * exp (-lam * t)
      = h * c * (exp (-r * T) * ∫ ω, X ω ∂μ) * ((1 - exp (-lam * T)) / lam) := by
  set E := ∫ ω, X ω ∂μ with hEdef
  have hE : ∀ t, ∫ ω, c * max (exp (-r * (T - t)) * μ[X | ℱ t] ω) 0 ∂μ
      = c * (exp (-r * (T - t)) * E) := by
    intro t
    have hnn := condExp_nonneg (m := ℱ t) (μ := μ) (f := X) (ae_of_all _ hX)
    rw [integral_congr_ae (g := fun ω => c * (exp (-r * (T - t)) * μ[X | ℱ t] ω))]
    · rw [integral_const_mul, integral_const_mul, integral_condExp (ℱ.le t)]
    · filter_upwards [hnn] with ω hω
      rw [max_eq_left (mul_nonneg (exp_pos _).le hω)]
  have hpt : ∀ t, exp (-r * t) * (c * (exp (-r * (T - t)) * E)) * exp (-lam * t)
      = (c * exp (-r * T) * E) * exp (-lam * t) := by
    intro t
    have : exp (-r * T) = exp (-r * t) * exp (-r * (T - t)) := by
      rw [← exp_add]; ring_nf
    rw [this]; ring
  have hI : ∫ t in (0)..T, exp (-lam * t) = (1 - exp (-lam * T)) / lam := by
    rw [intervalIntegral.integral_comp_mul_left (fun x => exp x) (neg_ne_zero.2 hlam.ne')]
    simp only [integral_exp, mul_zero, exp_zero, smul_eq_mul]
    field_simp
    ring
  simp_rw [hE, hpt]
  rw [intervalIntegral.integral_const_mul, hI]
  ring

/-- The KVA formula (Step 1). KVA is the average, over when the counterparty defaults (at `τ`)
and over where the market goes, of the capital cost stream `D(t) · h · K(t)` run from today
until the trade ends at `min(τ, T)`. When default is independent of the capital held, this
equals the hurdle rate times the integral over the trade's life of the discount factor, the
expected capital and the chance `Q(t) = P(t < τ)` that the counterparty is still alive. -/
theorem kva_eq_hurdle_times_integral_of_expected_capital {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (τ : Ω → ℝ) (K : ℝ → Ω → ℝ≥0∞)
    (hτ : Measurable τ) (hK : Measurable (Function.uncurry K))
    (hind : ∀ t, IndepFun τ (K t) μ) (h r T : ℝ) :
    ∫⁻ ω, (∫⁻ t in Set.Ioc 0 (min (τ ω) T), ENNReal.ofReal (exp (-r * t) * h) * K t ω) ∂μ
      = ENNReal.ofReal h * ∫⁻ t in Set.Ioc 0 T,
          ENNReal.ofReal (exp (-r * t)) * (∫⁻ ω, K t ω ∂μ) * μ {ω | t < τ ω} := by
  set G : Ω → ℝ → ℝ≥0∞ := fun ω t =>
    ENNReal.ofReal (exp (-r * t) * h) * ((if t < τ ω then 1 else 0) * K t ω) with hG
  -- Step A: for each ω, rewrite the stopped integral as an integral over (0, T].
  have hA : ∀ ω, ∫⁻ t in Set.Ioc 0 (min (τ ω) T), ENNReal.ofReal (exp (-r * t) * h) * K t ω
      = ∫⁻ t in Set.Ioc 0 T, G ω t := by
    intro ω
    have hset : (Set.Ioc 0 (min (τ ω) T) : Set ℝ) =ᵐ[volume] Set.Iio (τ ω) ∩ Set.Ioc 0 T := by
      rw [ae_eq_set]
      constructor
      · apply measure_mono_null _ (measure_singleton (τ ω))
        intro t ht
        obtain ⟨⟨h0, h1⟩, h3⟩ := ht
        rw [Set.mem_singleton_iff]
        by_contra hne
        exact h3 ⟨lt_of_le_of_ne (h1.trans (min_le_left _ _)) hne, h0,
          h1.trans (min_le_right _ _)⟩
      · have hsub : Set.Iio (τ ω) ∩ Set.Ioc 0 T ⊆ Set.Ioc 0 (min (τ ω) T) := by
          rintro t ⟨h1, h2, h3⟩
          exact ⟨h2, le_min (le_of_lt h1) h3⟩
        rw [Set.sdiff_eq_empty.2 hsub, measure_empty]
    rw [Measure.restrict_congr_set hset, ← Measure.restrict_restrict measurableSet_Iio,
      ← lintegral_indicator measurableSet_Iio]
    apply lintegral_congr
    intro t
    by_cases ht : t < τ ω
    · simp [Set.indicator, ht, hG]
    · simp [Set.indicator, ht, hG]
  have hmeas : AEMeasurable (Function.uncurry G) (μ.prod (volume.restrict (Set.Ioc 0 T))) := by
    apply Measurable.aemeasurable
    have hK' : Measurable (fun p : Ω × ℝ => K p.2 p.1) := hK.comp measurable_swap
    have hs : MeasurableSet {p : Ω × ℝ | p.2 < τ p.1} :=
      measurableSet_lt measurable_snd (hτ.comp measurable_fst)
    have : Function.uncurry G = fun p : Ω × ℝ =>
        ENNReal.ofReal (exp (-r * p.2) * h) * ((if p.2 < τ p.1 then 1 else 0) * K p.2 p.1) := rfl
    rw [this]
    refine Measurable.mul ?_ (Measurable.mul ?_ hK')
    · exact ENNReal.measurable_ofReal.comp
        (((measurable_const.mul measurable_snd).exp).mul measurable_const)
    · exact Measurable.ite hs measurable_const measurable_const
  have hB : ∀ t, ∫⁻ ω, G ω t ∂μ
      = ENNReal.ofReal h * (ENNReal.ofReal (exp (-r * t)) * (∫⁻ ω, K t ω ∂μ) * μ {ω | t < τ ω}) := by
    intro t
    have hφ : Measurable (fun x : ℝ => if t < x then (1 : ℝ≥0∞) else 0) :=
      Measurable.ite measurableSet_Ioi measurable_const measurable_const
    have hind' := (hind t).comp hφ measurable_id
    have hKt : Measurable (K t) := hK.comp (measurable_const.prodMk measurable_id)
    have hmul := lintegral_mul_eq_lintegral_mul_lintegral_of_indepFun
      (hφ.comp hτ) (measurable_id.comp hKt) hind'
    have hone : ∫⁻ ω, ((fun x : ℝ => if t < x then (1 : ℝ≥0∞) else 0) ∘ τ) ω ∂μ
        = μ {ω | t < τ ω} := by
      have : ((fun x : ℝ => if t < x then (1 : ℝ≥0∞) else 0) ∘ τ)
          = {ω | t < τ ω}.indicator 1 := by
        ext ω; simp [Set.indicator]
      rw [this, lintegral_indicator_one (measurableSet_lt measurable_const hτ)]
    show ∫⁻ ω, ENNReal.ofReal (exp (-r * t) * h) * ((if t < τ ω then 1 else 0) * K t ω) ∂μ = _
    rw [lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
    have : (fun ω => (if t < τ ω then (1 : ℝ≥0∞) else 0) * K t ω)
        = ((fun x : ℝ => if t < x then (1 : ℝ≥0∞) else 0) ∘ τ) * (id ∘ K t) := rfl
    rw [this, hmul, hone, ENNReal.ofReal_mul (exp_pos _).le]
    have hid : ∫⁻ ω, (id ∘ K t) ω ∂μ = ∫⁻ ω, K t ω ∂μ := rfl
    rw [hid]
    ring
  calc _ = ∫⁻ ω, (∫⁻ t in Set.Ioc 0 T, G ω t) ∂μ := lintegral_congr hA
    _ = ∫⁻ t in Set.Ioc 0 T, (∫⁻ ω, G ω t ∂μ) := lintegral_lintegral_swap hmeas
    _ = _ := by
      simp_rw [hB]
      rw [lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]

/-- KVA is a CVA with a different running rate (Step 4). With recovery `R < 1` and hazard
`λ > 0`, the KVA closed form equals the CVA closed form `(1 - R) C₀ (1 - e^{-λT})` scaled by
the ratio of running rates `h c / ((1 - R) λ)`. -/
theorem kva_eq_running_rate_ratio_times_cva (h c C₀ R lam T : ℝ) (hR : R < 1) (hlam : 0 < lam) :
    h * c * C₀ * ((1 - exp (-lam * T)) / lam)
      = (h * c) / ((1 - R) * lam) * ((1 - R) * C₀ * (1 - exp (-lam * T))) := by
  have h1 : (1 - R) ≠ 0 := by linarith
  have h2 : lam ≠ 0 := hlam.ne'
  field_simp

-- Capital per dollar of trade value: c = 8% × RW 100% × α 1.4 = 0.112.
example : (8 / 100 : ℚ) * 1 * (14 / 10) = 112 / 1000 := by norm_num
-- Running rates: CVA charges (1 - R) λ = 0.6 × 2% = 1.2%; KVA charges h c = 10% × 0.112 = 1.12%.
example : (1 - 4 / 10 : ℚ) * (2 / 100) = 12 / 1000 := by norm_num
example : (1 / 10 : ℚ) * (112 / 1000) = 112 / 10000 := by norm_num
-- KVA / CVA = 0.0112 / 0.012 = 0.933333... = 14/15.
example : ((1 / 10 : ℚ) * (112 / 1000)) / ((1 - 4 / 10) * (2 / 100)) = 14 / 15 := by norm_num
-- Charging the hurdle on the whole EAD instead of the capital multiplies KVA by α / c = 12.5.
example : (14 / 10 : ℚ) / (112 / 1000) = 25 / 2 := by norm_num

#print axioms kva_closed_form_bought_option
#print axioms kva_eq_hurdle_times_integral_of_expected_capital
#print axioms kva_eq_running_rate_ratio_times_cva
