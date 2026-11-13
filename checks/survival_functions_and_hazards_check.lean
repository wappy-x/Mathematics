-- Survival: for a positive lifetime with a density, survival past t is e to the minus the hazard added up to t, survival from s to t uses only the hazard in between, and deaths over time watched is the best constant hazard.
import Mathlib.Probability.ConditionalProbability
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.DivergenceTheorem
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open MeasureTheory Real

/-- The survival function of a lifetime law `μ` on the real line: `S(t) = P(T > t)`. -/
noncomputable def survival (μ : Measure ℝ) (t : ℝ) : ℝ := μ.real (Set.Ioi t)

/-- The hazard of a lifetime with density `f`: `h(t) = f(t) / S(t)`, the death rate at `t`
among those still alive at `t`. -/
noncomputable def hazard (μ : Measure ℝ) (f : ℝ → ℝ) (t : ℝ) : ℝ := f t / survival μ t

/-- The cumulative hazard `H(t) = ∫₀ᵗ h(u) du`: the hazard added up from diagnosis to `t`. -/
noncomputable def cumHazard (μ : Measure ℝ) (f : ℝ → ℝ) (t : ℝ) : ℝ :=
  ∫ u in (0 : ℝ)..t, hazard μ f u


/-- A density of a probability law is integrable. -/
lemma survival_density_integrable (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (f : ℝ → ℝ) (hf_meas : Measurable f) (hf_nonneg : ∀ x, 0 ≤ f x)
    (hμ : μ = volume.withDensity (fun x => ENNReal.ofReal (f x))) :
    Integrable f := by
  refine ⟨hf_meas.aestronglyMeasurable, ?_⟩
  have h1 : ∫⁻ x, ENNReal.ofReal (f x) = 1 := by
    have h := (measure_univ : μ Set.univ = 1)
    rw [hμ, withDensity_apply _ MeasurableSet.univ, Measure.restrict_univ] at h
    exact h
  show ∫⁻ x, ‖f x‖ₑ < ⊤
  calc ∫⁻ x, ‖f x‖ₑ = ∫⁻ x, ENNReal.ofReal (f x) :=
        lintegral_congr (fun x => by rw [Real.enorm_eq_ofReal (hf_nonneg x)])
    _ < ⊤ := by rw [h1]; exact ENNReal.one_lt_top

/-- For `u ≥ 0`, survival is one minus the density added up from `0` to `u`. -/
lemma survival_eq_one_sub_integral (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (f : ℝ → ℝ) (hf_meas : Measurable f) (hf_nonneg : ∀ x, 0 ≤ f x)
    (hμ : μ = volume.withDensity (fun x => ENNReal.ofReal (f x)))
    (hT : μ (Set.Iic 0) = 0) (u : ℝ) (hu : 0 ≤ u) :
    survival μ u = 1 - ∫ x in (0 : ℝ)..u, f x := by
  have hint := survival_density_integrable μ f hf_meas hf_nonneg hμ
  have hc : μ.real (Set.Ioi u) = 1 - μ.real (Set.Iic u) := by
    rw [← Set.compl_Iic, probReal_compl_eq_one_sub measurableSet_Iic]
  have hI : μ (Set.Iic u) = μ (Set.Ioc 0 u) := by
    rw [← Set.Iic_union_Ioc_eq_Iic hu, measure_union (Set.Iic_disjoint_Ioc le_rfl)
      measurableSet_Ioc, hT, zero_add]
  have hD : μ (Set.Ioc 0 u) = ENNReal.ofReal (∫ x in Set.Ioc 0 u, f x) := by
    rw [hμ, withDensity_apply _ measurableSet_Ioc,
      ofReal_integral_eq_lintegral_ofReal hint.integrableOn (ae_of_all _ hf_nonneg)]
  unfold survival
  rw [hc, measureReal_def, hI, hD,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Ioc (fun x _ => hf_nonneg x)),
    intervalIntegral.integral_of_le hu]

/-- Survival is e to the minus the cumulative hazard. Let the lifetime `T` be positive
(`P(T ≤ 0) = 0`) with law `μ` and density `f`: no chance sits at a single instant, and `f` is
continuous except at finitely many times (the jumps of a hazard that changes by year). At any
time `t ≥ 0` where survival is still above zero, `S(t) = e^(-H(t))`. -/
theorem survival_eq_exp_neg_cumHazard (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (f : ℝ → ℝ) (hf_meas : Measurable f) (hf_nonneg : ∀ x, 0 ≤ f x)
    (hμ : μ = volume.withDensity (fun x => ENNReal.ofReal (f x)))
    (hT : μ (Set.Iic 0) = 0)
    (F : Finset ℝ) (hf_cont : ∀ x ∉ F, ContinuousAt f x)
    (t : ℝ) (ht : 0 ≤ t) (hS : 0 < survival μ t) :
    survival μ t = Real.exp (-cumHazard μ f t) := by
  have hint := survival_density_integrable μ f hf_meas hf_nonneg hμ
  have hII : ∀ a b : ℝ, IntervalIntegrable f volume a b := fun a b => hint.intervalIntegrable
  set G : ℝ → ℝ := fun u => ∫ x in (0 : ℝ)..u, f x with hG
  have hGc : Continuous G := intervalIntegral.continuous_primitive hII 0
  have hSG : ∀ u ∈ Set.Icc (0 : ℝ) t, survival μ u = 1 - G u := fun u hu =>
    survival_eq_one_sub_integral μ f hf_meas hf_nonneg hμ hT u hu.1
  have hpos : ∀ u ∈ Set.Icc (0 : ℝ) t, 0 < 1 - G u := by
    intro u hu
    rw [← hSG u hu]
    refine lt_of_lt_of_le hS ?_
    exact measureReal_mono (Set.Ioi_subset_Ioi hu.2)
  have hcongr : cumHazard μ f t = ∫ u in (0 : ℝ)..t, f u / (1 - G u) := by
    unfold cumHazard
    apply intervalIntegral.integral_congr
    intro u hu
    rw [Set.uIcc_of_le ht] at hu
    simp only [hazard, hSG u hu]
  have hφc : ContinuousOn (fun u => -Real.log (1 - G u)) (Set.Icc 0 t) := by
    apply ContinuousOn.neg
    apply ContinuousOn.log ((continuous_const.sub hGc).continuousOn)
    intro u hu; exact (hpos u hu).ne'
  have hd : ∀ x ∈ Set.Ioo (0 : ℝ) t \ (F : Set ℝ),
      HasDerivAt (fun u => -Real.log (1 - G u)) (f x / (1 - G x)) x := by
    intro x hx
    have hxF : x ∉ F := hx.2
    have h1 : HasDerivAt G (f x) x :=
      intervalIntegral.integral_hasDerivAt_right (hII 0 x)
        hf_meas.stronglyMeasurable.stronglyMeasurableAtFilter (hf_cont x hxF)
    have h2 := ((h1.const_sub 1).log (hpos x (Set.Ioo_subset_Icc_self hx.1)).ne').neg
    convert h2 using 1
    rw [neg_div, neg_neg]
  have hi : IntervalIntegrable (fun u => f u / (1 - G u)) volume 0 t := by
    have hinv : ContinuousOn (fun u => (1 - G u)⁻¹) (Set.uIcc 0 t) := by
      rw [Set.uIcc_of_le ht]
      exact ((continuous_const.sub hGc).continuousOn).inv₀ (fun u hu => (hpos u hu).ne')
    simpa [div_eq_mul_inv] using (hII 0 t).mul_continuousOn hinv
  have hftc := integral_eq_of_hasDerivAt_off_countable_of_le
    (fun u => -Real.log (1 - G u)) (fun u => f u / (1 - G u)) ht F.countable_toSet hφc hd hi
  have hG0 : G 0 = 0 := by simp [hG]
  rw [hcongr, hftc, hG0, sub_zero, Real.log_one, neg_zero, sub_zero, neg_neg,
    ← hSG t ⟨ht, le_rfl⟩, Real.exp_log hS]

/-- The past is paid for. Under the same conditions, for times `0 ≤ s ≤ t` with survival above
zero at `t`, the chance of lasting past `t` given alive at `s` is `P(T > t | T > s) = S(t)/S(s)`,
and it equals `e^(-[H(t) - H(s)])`: only the hazard still ahead counts. -/
theorem conditional_survival_eq_exp_neg_hazard_ahead (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (f : ℝ → ℝ) (hf_meas : Measurable f) (hf_nonneg : ∀ x, 0 ≤ f x)
    (hμ : μ = volume.withDensity (fun x => ENNReal.ofReal (f x)))
    (hT : μ (Set.Iic 0) = 0)
    (F : Finset ℝ) (hf_cont : ∀ x ∉ F, ContinuousAt f x)
    (s t : ℝ) (hs : 0 ≤ s) (hst : s ≤ t) (hS : 0 < survival μ t) :
    (ProbabilityTheory.cond μ (Set.Ioi s)).real (Set.Ioi t) = survival μ t / survival μ s ∧
      survival μ t / survival μ s = Real.exp (-(cumHazard μ f t - cumHazard μ f s)) := by
  have hSs : 0 < survival μ s := lt_of_lt_of_le hS (measureReal_mono (Set.Ioi_subset_Ioi hst))
  refine ⟨?_, ?_⟩
  · rw [measureReal_def, ProbabilityTheory.cond_apply measurableSet_Ioi, Set.Ioi_inter_Ioi,
      max_eq_right hst]
    simp only [measureReal_def, ENNReal.toReal_mul, ENNReal.toReal_inv, survival]
    ring
  · rw [survival_eq_exp_neg_cumHazard μ f hf_meas hf_nonneg hμ hT F hf_cont t (hs.trans hst) hS,
      survival_eq_exp_neg_cumHazard μ f hf_meas hf_nonneg hμ hT F hf_cont s hs hSs,
      ← Real.exp_sub]
    ring_nf

/-- Deaths over time watched. With a constant hazard `λ`, the log-likelihood of the records is
`D ln λ - λ E`, where `D ≥ 1` deaths were seen over `E > 0` person-years watched. It is highest
at `λ = D / E`, and every other positive rate scores strictly lower. -/
theorem constant_hazard_mle_eq_deaths_over_exposure (D : ℕ) (E : ℝ) (hD : 0 < D) (hE : 0 < E)
    (l : ℝ) (hl : 0 < l) (hne : l ≠ D / E) :
    (D : ℝ) * Real.log l - l * E < D * Real.log (D / E) - D / E * E := by
  have hDpos : (0 : ℝ) < D := by exact_mod_cast hD
  set x : ℝ := l * E / D with hx
  have hxpos : 0 < x := by positivity
  have hx1 : x ≠ 1 := by
    intro h
    apply hne
    rw [hx, div_eq_one_iff_eq hDpos.ne'] at h
    field_simp
    linarith
  have hl : l = D / E * x := by rw [hx]; field_simp
  have hlog : Real.log l = Real.log (D / E) + Real.log x := by
    rw [hl, Real.log_mul (by positivity) hxpos.ne']
  have hlE : l * E = D * x := by rw [hx]; field_simp
  have key := Real.log_lt_sub_one_of_pos hxpos hx1
  have hDE : (D : ℝ) / E * E = D := by field_simp
  rw [hlog, hlE, hDE]
  nlinarith [key, hDpos]

-- Step 2 and the formula: H(5) = 0.30 + 0.20 + 0.15 + 0.10 + 0.10 = 0.85, as exact fractions.
example : (3 / 10 + 2 / 10 + 15 / 100 + 1 / 10 + 1 / 10 : ℚ) = 85 / 100 := by norm_num
-- Step 3: a constant hazard of 0.17 for 5 years piles up the same 0.85.
example : (5 * (17 / 100) : ℚ) = 85 / 100 := by norm_num
-- Step 3: alive at 2, the hazard still ahead to 5 is 0.15 + 0.10 + 0.10 = 0.35.
example : (15 / 100 + 1 / 10 + 1 / 10 : ℚ) = 35 / 100 := by norm_num
-- When it holds: 5% dying on the day of surgery leaves 1 - 0.05 = 0.95 alive across that day.
example : (1 - 5 / 100 : ℚ) = 95 / 100 := by norm_num
-- Worked numbers: person-years in tenths of a year, 4 + 10 + 13 + 21 + 25 + 30 + 36 + 42 + 50 + 50
-- = 281, that is E = 28.10.
example : (4 + 10 + 13 + 21 + 25 + 30 + 36 + 42 + 50 + 50 : ℕ) = 281 := by norm_num
-- The rate D/E = 4 / 28.10 = 40/281 per year (about 0.1423).
example : (4 / (281 / 10) : ℚ) = 40 / 281 := by norm_num
-- What breaks: censored records counted as deaths give 10 / 28.10 = 100/281 (about 0.3559).
example : (10 / (281 / 10) : ℚ) = 100 / 281 := by norm_num
-- What breaks: 6 of 10 not seen to die gives 0.6000; dropping the 4 censored before 5 leaves
-- 2 alive of 6 known, 0.3333.
example : (6 / 10 : ℚ) = 3 / 5 ∧ (2 / (10 - 4) : ℚ) = 1 / 3 := by norm_num

#print axioms survival_density_integrable
#print axioms survival_eq_one_sub_integral
#print axioms survival_eq_exp_neg_cumHazard
#print axioms conditional_survival_eq_exp_neg_hazard_ahead
#print axioms constant_hazard_mle_eq_deaths_over_exposure
