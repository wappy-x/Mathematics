-- The hazard rate: if a default date has smooth, positive survival chances and hazard rate λ(t), then the chance of surviving past t is e to the minus the area under λ from 0 to t; a flat hazard forgets the past, and one survival number gives back exactly one flat hazard.
import Mathlib.Probability.ConditionalProbability
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open MeasureTheory ProbabilityTheory Filter Topology

lemma survival_right_deriv
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (τ : Ω → ℝ) (hτ : Measurable τ) (x L : ℝ)
    (hpos : 0 < μ {ω | x < τ ω})
    (h : Tendsto (fun Δ => (μ[{ω | x < τ ω ∧ τ ω ≤ x + Δ} | {ω | x < τ ω}]).toReal / Δ)
        (𝓝[>] 0) (𝓝 L)) :
    HasDerivWithinAt (fun s => (μ {ω | s < τ ω}).toReal)
      (-((μ {ω | x < τ ω}).toReal * L)) (Set.Ioi x) x := by
  rw [hasDerivWithinAt_iff_tendsto_slope' (lt_irrefl x)]
  have hsub : Tendsto (fun y : ℝ => y - x) (𝓝[>] x) (𝓝[>] 0) := by
    refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
    · have : Tendsto (fun y : ℝ => y - x) (𝓝 x) (𝓝 (x - x)) :=
        (continuous_id.sub continuous_const).tendsto x
      rw [sub_self] at this
      exact this.mono_left nhdsWithin_le_nhds
    · filter_upwards [self_mem_nhdsWithin] with y hy
      exact sub_pos.2 (show x < y from hy)
  have hlim := ((h.comp hsub).const_mul (-(μ {ω | x < τ ω}).toReal))
  rw [neg_mul] at hlim
  refine hlim.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with y hy
  have hy' : x < y := hy
  have hB : MeasurableSet {ω | x < τ ω} := measurableSet_lt measurable_const hτ
  have hC : MeasurableSet {ω | y < τ ω} := measurableSet_lt measurable_const hτ
  have hCB : {ω | y < τ ω} ⊆ {ω | x < τ ω} := fun ω hω => lt_trans hy' hω
  have hset : {ω | x < τ ω} ∩ {ω | x < τ ω ∧ τ ω ≤ x + (y - x)} =
      {ω | x < τ ω} \ {ω | y < τ ω} := by
    ext ω; simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, Set.mem_sdiff, not_lt]
    constructor
    · rintro ⟨h1, _, h3⟩; exact ⟨h1, by linarith⟩
    · rintro ⟨h1, h3⟩; exact ⟨h1, h1, by linarith⟩
  have hBpos : 0 < (μ {ω | x < τ ω}).toReal :=
    ENNReal.toReal_pos hpos.ne' (measure_ne_top _ _)
  have hle : μ {ω | y < τ ω} ≤ μ {ω | x < τ ω} := measure_mono hCB
  simp only [Function.comp_def]
  rw [cond_apply hB, hset, measure_sdiff hCB hC.nullMeasurableSet (measure_ne_top _ _),
    ENNReal.toReal_mul, ENNReal.toReal_inv, ENNReal.toReal_sub_of_le hle (measure_ne_top _ _),
    slope_def_field]
  have hyx : y - x ≠ 0 := sub_ne_zero.2 hy'.ne'
  field_simp
  ring

#print axioms survival_right_deriv

/-- Survival is e to the minus the area under the hazard.

`τ` is the random default date, measured in years from today, so the company is alive
today (`μ {0 < τ} = 1`). Survival `S(t) = P(τ > t)` is positive and changes smoothly
(differentiable at every future date). The hazard `haz t` is the chance of defaulting in the
next stretch `Δ`, counted only among companies still alive at `t`, divided by `Δ`, as `Δ`
shrinks to 0; the hazard curve is continuous. Then for every `t ≥ 0`,
`P(τ > t) = exp (-∫₀ᵗ haz u du)`. -/
theorem survival_eq_exp_neg_integral_hazard
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (τ : Ω → ℝ) (hτ : Measurable τ) (haz : ℝ → ℝ)
    (halive : μ {ω | 0 < τ ω} = 1)
    (hpos : ∀ t, 0 ≤ t → 0 < μ {ω | t < τ ω})
    (hsmooth : ∀ t, 0 < t → DifferentiableAt ℝ (fun s => (μ {ω | s < τ ω}).toReal) t)
    (hcont : ContinuousOn haz (Set.Ici 0))
    (hhaz : ∀ t, 0 ≤ t →
      Tendsto (fun Δ => (μ[{ω | t < τ ω ∧ τ ω ≤ t + Δ} | {ω | t < τ ω}]).toReal / Δ)
        (𝓝[>] 0) (𝓝 (haz t)))
    (t : ℝ) (ht : 0 ≤ t) :
    (μ {ω | t < τ ω}).toReal = Real.exp (-∫ u in (0 : ℝ)..t, haz u) := by
  set S : ℝ → ℝ := fun s => (μ {ω | s < τ ω}).toReal with hSdef
  have Spos : ∀ u, 0 ≤ u → 0 < S u := fun u hu =>
    ENNReal.toReal_pos (hpos u hu).ne' (measure_ne_top _ _)
  have hd : ∀ x, 0 ≤ x → HasDerivWithinAt S (-(S x * haz x)) (Set.Ioi x) x := fun x hx =>
    survival_right_deriv μ τ hτ x (haz x) (hpos x hx) (hhaz x hx)
  have hF : ∀ x, 0 ≤ x →
      HasDerivWithinAt (fun u => -Real.log (S u)) (haz x) (Set.Ioi x) x := by
    intro x hx
    have := ((hd x hx).log (Spos x hx).ne').neg
    convert this using 1
    field_simp [(Spos x hx).ne']
  have hScont : ContinuousOn S (Set.Icc 0 t) := by
    intro x hx
    rcases eq_or_lt_of_le hx.1 with h0 | h0
    · subst h0
      have h1 : HasDerivWithinAt S (-(S 0 * haz 0)) (Set.Ici 0) 0 :=
        hasDerivWithinAt_Ioi_iff_Ici.1 (hd 0 le_rfl)
      exact h1.continuousWithinAt.mono Set.Icc_subset_Ici_self
    · exact (hsmooth x h0).continuousAt.continuousWithinAt
  have hFcont : ContinuousOn (fun u => -Real.log (S u)) (Set.Icc 0 t) :=
    (hScont.log fun x hx => (Spos x hx.1).ne').neg
  have hint : IntervalIntegrable haz MeasureSpace.volume 0 t :=
    (hcont.mono Set.Icc_subset_Ici_self).intervalIntegrable_of_Icc ht
  have hftc := intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le ht hFcont
    (fun x hx => hF x hx.1.le) hint
  have hS0 : S 0 = 1 := by simp [hSdef, halive]
  rw [hftc, hS0, Real.log_one, neg_zero, sub_zero, neg_neg, Real.exp_log (Spos t ht)]

/-- A flat hazard gives `S(t) = e^{-λ t}` and forgets the past.

With the same set-up and a hazard equal to the constant `lam` at every date, survival is
`P(τ > t) = exp (-lam * t)`, and a company still alive at date `s` survives the next `t`
years with the same chance as a brand-new one: `P(τ > s + t | τ > s) = P(τ > t)`. -/
theorem flat_hazard_survival_and_memoryless
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (τ : Ω → ℝ) (hτ : Measurable τ) (lam : ℝ)
    (halive : μ {ω | 0 < τ ω} = 1)
    (hpos : ∀ t, 0 ≤ t → 0 < μ {ω | t < τ ω})
    (hsmooth : ∀ t, 0 < t → DifferentiableAt ℝ (fun s => (μ {ω | s < τ ω}).toReal) t)
    (hhaz : ∀ t, 0 ≤ t →
      Tendsto (fun Δ => (μ[{ω | t < τ ω ∧ τ ω ≤ t + Δ} | {ω | t < τ ω}]).toReal / Δ)
        (𝓝[>] 0) (𝓝 lam))
    (s t : ℝ) (hs : 0 ≤ s) (ht : 0 ≤ t) :
    (μ {ω | t < τ ω}).toReal = Real.exp (-(lam * t)) ∧
      μ[{ω | s + t < τ ω} | {ω | s < τ ω}] = μ {ω | t < τ ω} := by
  have key : ∀ u, 0 ≤ u → (μ {ω | u < τ ω}).toReal = Real.exp (-(lam * u)) := by
    intro u hu
    rw [survival_eq_exp_neg_integral_hazard μ τ hτ (fun _ => lam) halive hpos hsmooth
      continuousOn_const hhaz u hu]
    simp [intervalIntegral.integral_const, mul_comm]
  refine ⟨key t ht, ?_⟩
  have hB : MeasurableSet {ω | s < τ ω} := measurableSet_lt measurable_const hτ
  have hset : {ω | s < τ ω} ∩ {ω | s + t < τ ω} = {ω | s + t < τ ω} := by
    ext ω
    simp only [Set.mem_inter_iff, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨_, h⟩; exact h
    · intro h; exact ⟨by linarith, h⟩
  rw [cond_apply hB, hset]
  have hBne : μ {ω | s < τ ω} ≠ 0 := (hpos s hs).ne'
  rw [← ENNReal.toReal_eq_toReal_iff' (ENNReal.mul_ne_top (ENNReal.inv_ne_top.2 hBne)
    (measure_ne_top _ _)) (measure_ne_top _ _), ENNReal.toReal_mul, ENNReal.toReal_inv,
    key s hs, key (s + t) (by linarith), key t ht, ← Real.exp_neg, ← Real.exp_add]
  congr 1
  ring

/-- Inverting the flat case.

For a horizon `T > 0`, each survival probability `S` with `0 < S ≤ 1` comes from exactly one
flat hazard `lam ≥ 0` with `exp (-lam * T) = S`, namely `lam = -ln S / T`; and survival `0`
comes from no finite hazard at all. -/
theorem flat_hazard_from_survival (T S : ℝ) (hT : 0 < T) :
    (0 < S → S ≤ 1 →
      ∀ lam : ℝ, (0 ≤ lam ∧ Real.exp (-(lam * T)) = S) ↔ lam = -Real.log S / T) ∧
    ¬ ∃ lam : ℝ, Real.exp (-(lam * T)) = 0 := by
  refine ⟨fun hS hS1 lam => ⟨?_, ?_⟩, ?_⟩
  · rintro ⟨_, h⟩
    have h2 : -(lam * T) = Real.log S := by rw [← h, Real.log_exp]
    field_simp
    linarith
  · intro h
    have hlog : Real.log S ≤ 0 := Real.log_nonpos hS.le hS1
    refine ⟨?_, ?_⟩
    · rw [h]; exact div_nonneg (by linarith) hT.le
    · rw [h, div_mul_cancel₀ _ hT.ne', neg_neg, Real.exp_log hS]
  · rintro ⟨lam, h⟩
    exact (Real.exp_pos _).ne' h

-- Area under a flat 2% hazard over five years is 0.1.
example : (2 / 100 : ℚ) * 5 = 1 / 10 := by norm_num

-- The rising hazard 1% → 3% over five years has the same area, a trapezium of 0.1.
example : (5 : ℚ) * (1 / 100 + 3 / 100) / 2 = 1 / 10 := by norm_num

-- Mean default date at a flat 2% hazard: 1 / λ = 50 years.
example : (1 : ℚ) / (2 / 100) = 50 := by norm_num

-- Memorylessness at Northwind's numbers: S(15) / S(10) = e^{-0.3} / e^{-0.2} = e^{-0.1}.
example : Real.exp (-(3 / 10)) / Real.exp (-(2 / 10)) = Real.exp (-(1 / 10)) := by
  rw [← Real.exp_sub]; norm_num

#print axioms survival_eq_exp_neg_integral_hazard
#print axioms flat_hazard_survival_and_memoryless
#print axioms flat_hazard_from_survival
