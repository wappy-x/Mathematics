-- Convergence in distribution: distribution functions of probability laws on the line converge at every continuity point of the limit exactly when the averages of every bounded continuous function converge, convergence in probability forces this, and towards a constant it forces convergence in probability back.
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Topology.ContinuousMap.Bounded.Basic
import Mathlib.MeasureTheory.Measure.Portmanteau
import Mathlib.MeasureTheory.Function.ConvergenceInDistribution
import Mathlib.Topology.Algebra.Module.Cardinality

open MeasureTheory ProbabilityTheory Filter Topology Set BoundedContinuousFunction

lemma cdfConv_measure_singleton_eq_zero (μ : Measure ℝ) [IsProbabilityMeasure μ] (t : ℝ)
    (ht : ContinuousAt (cdf μ) t) : μ {t} = 0 := by
  have h1 : Function.leftLim (cdf μ) t = cdf μ t :=
    leftLim_eq_of_tendsto (ht.tendsto.mono_left nhdsWithin_le_nhds)
  rw [← measure_cdf μ, StieltjesFunction.measure_singleton, h1, sub_self, ENNReal.ofReal_zero]

lemma cdfConv_of_tendsto_pm (μs : ℕ → Measure ℝ) [∀ n, IsProbabilityMeasure (μs n)]
    (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (h : Tendsto (β := ProbabilityMeasure ℝ) (fun n => ⟨μs n, inferInstance⟩) atTop
      (𝓝 ⟨μ, inferInstance⟩))
    (t : ℝ) (ht : ContinuousAt (cdf μ) t) :
    Tendsto (fun n => cdf (μs n) t) atTop (𝓝 (cdf μ t)) := by
  have hfr : (μ : Measure ℝ) (frontier (Iic t)) = 0 := by
    rw [frontier_Iic]; exact cdfConv_measure_singleton_eq_zero μ t ht
  have h1 := ProbabilityMeasure.tendsto_measure_of_null_frontier_of_tendsto' h hfr
  have h2 := (ENNReal.tendsto_toReal (measure_ne_top μ (Iic t))).comp h1
  simpa [Function.comp_def, cdf_eq_real, measureReal_def] using h2

lemma cdfConv_tendsto_pm_of_cdf (μs : ℕ → Measure ℝ) [∀ n, IsProbabilityMeasure (μs n)]
    (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (h : ∀ t : ℝ, ContinuousAt (cdf μ) t →
        Tendsto (fun n => cdf (μs n) t) atTop (𝓝 (cdf μ t))) :
    Tendsto (β := ProbabilityMeasure ℝ) (fun n => ⟨μs n, inferInstance⟩) atTop
      (𝓝 ⟨μ, inferInstance⟩) := by
  set D := {t : ℝ | ContinuousAt (cdf μ) t} with hD
  have hDc : Dense D := by
    have : Set.Countable {x | ¬ContinuousAt (cdf μ) x} := (cdf μ).mono.countable_not_continuousAt
    convert Set.Countable.dense_compl ℝ this using 1
    ext x; simp [hD]
  let S : Set (Set ℝ) := {s | ∃ a ∈ D, ∃ b ∈ D, s = Ioc a b}
  have hS : IsPiSystem S := by
    rintro _ ⟨a, ha, b, hb, rfl⟩ _ ⟨c, hc, d, hd, rfl⟩ _
    refine ⟨max a c, ?_, min b d, ?_, Ioc_inter_Ioc⟩
    · rcases le_total a c with h | h <;> simp [h, ha, hc]
    · rcases le_total b d with h | h <;> simp [h, hb, hd]
  apply hS.tendsto_probabilityMeasure_of_tendsto_of_mem
  · rintro _ ⟨a, -, b, -, rfl⟩; exact measurableSet_Ioc
  · intro u hu x hx
    obtain ⟨ε, εpos, hε⟩ := Metric.isOpen_iff.1 hu x hx
    obtain ⟨a, haD, ha⟩ := hDc.exists_between (show x - ε < x by linarith)
    obtain ⟨b, hbD, hb⟩ := hDc.exists_between (show x < x + ε by linarith)
    refine ⟨Ioc a b, ⟨a, haD, b, hbD, rfl⟩, Ioc_mem_nhds ha.2 hb.1, ?_⟩
    intro y hy
    apply hε
    rw [Metric.mem_ball, Real.dist_eq, abs_lt]
    constructor <;> linarith [hy.1, hy.2, ha.1, hb.2]
  · rintro _ ⟨a, ha, b, hb, rfl⟩
    have key : ∀ ν : Measure ℝ, [IsProbabilityMeasure ν] →
        ν (Ioc a b) = ENNReal.ofReal (cdf ν b - cdf ν a) := by
      intro ν _
      rw [← StieltjesFunction.measure_Ioc, measure_cdf]
    change Tendsto (fun i => ((μs i) (Ioc a b)).toNNReal) atTop (𝓝 ((μ (Ioc a b)).toNNReal))
    simp_rw [key, ENNReal.ofReal, ENNReal.toNNReal_coe]
    have := ((h b hb).sub (h a ha))
    exact (continuous_real_toNNReal.tendsto _).comp this

lemma cdfConv_cdf_dirac (c t : ℝ) : cdf (Measure.dirac c) t = if c ≤ t then 1 else 0 := by
  rw [cdf_eq_real, measureReal_def, Measure.dirac_apply' _ measurableSet_Iic]
  by_cases h : c ≤ t <;> simp [h, Set.indicator]

lemma cdfConv_cdf_map_eq {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P] (Y : Ω → ℝ) (hY : Measurable Y)
    (t : ℝ) : cdf (P.map Y) t = P.real {ω | Y ω ≤ t} := by
  rw [cdf_eq_real, measureReal_def, Measure.map_apply hY measurableSet_Iic]
  rfl


/-- The two forms of convergence in distribution agree: for probability laws `μs n` and `μ`
on the line, the distribution functions `F_n(t)` tend to `F(t)` at every threshold `t` where
`F` does not jump exactly when, for every bounded continuous `f`, the average of `f` under
`μs n` tends to its average under `μ`. -/
theorem cdf_convergence_iff_bounded_continuous_averages_converge
    (μs : ℕ → Measure ℝ) [∀ n, IsProbabilityMeasure (μs n)]
    (μ : Measure ℝ) [IsProbabilityMeasure μ] :
    (∀ t : ℝ, ContinuousAt (cdf μ) t →
        Tendsto (fun n => cdf (μs n) t) atTop (𝓝 (cdf μ t))) ↔
      (∀ f : ℝ →ᵇ ℝ,
        Tendsto (fun n => ∫ x, f x ∂(μs n)) atTop (𝓝 (∫ x, f x ∂μ))) := by
  constructor
  · intro h
    exact ProbabilityMeasure.tendsto_iff_forall_integral_tendsto.1
      (cdfConv_tendsto_pm_of_cdf μs μ h)
  · intro h t ht
    exact cdfConv_of_tendsto_pm μs μ
      (ProbabilityMeasure.tendsto_iff_forall_integral_tendsto.2 h) t ht

/-- Convergence in probability forces convergence in distribution: if measurable `X n` and `X`
live on one probability space and `P(|X n - X| ≥ ε) → 0` for every `ε > 0`, then the
distribution function of `X n` tends to that of `X` at every continuity point of the latter. -/
theorem tendstoInMeasure_implies_cdf_convergence
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (Y : Ω → ℝ) (hX : ∀ n, Measurable (X n)) (hY : Measurable Y)
    (h : TendstoInMeasure P X atTop Y) :
    ∀ t : ℝ, ContinuousAt (cdf (P.map Y)) t →
      Tendsto (fun n => cdf (P.map (X n)) t) atTop (𝓝 (cdf (P.map Y) t)) := by
  intro t ht
  have hd := h.tendstoInDistribution (fun n => (hX n).aemeasurable)
  exact cdfConv_of_tendsto_pm (fun n => P.map (X n)) (P.map Y) hd.tendsto t ht

/-- Towards a constant, convergence in distribution is convergence in probability: if the
distribution function of `X n` tends to that of the constant `c` at every continuity point of
the latter, then `X n` converges to `c` in probability. -/
theorem cdf_convergence_to_constant_implies_tendstoInMeasure
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℕ → Ω → ℝ) (hX : ∀ n, Measurable (X n)) (c : ℝ)
    (h : ∀ t : ℝ, ContinuousAt (cdf (Measure.dirac c)) t →
      Tendsto (fun n => cdf (P.map (X n)) t) atTop (𝓝 (cdf (Measure.dirac c) t))) :
    TendstoInMeasure P X atTop (fun _ => c) := by
  rw [tendstoInMeasure_iff_measureReal_dist]
  intro ε hε
  have hlo : Tendsto (fun n => cdf (P.map (X n)) (c - ε)) atTop (𝓝 0) := by
    have hc : ContinuousAt (cdf (Measure.dirac c)) (c - ε) := by
      refine (continuousAt_const (y := (0 : ℝ))).congr ?_
      filter_upwards [Iio_mem_nhds (show c - ε < c by linarith)] with x hx
      simp [cdfConv_cdf_dirac, not_le.2 (mem_Iio.1 hx)]
    have := h _ hc
    simpa [cdfConv_cdf_dirac, show ¬ c ≤ c - ε by linarith] using this
  have hhi : Tendsto (fun n => cdf (P.map (X n)) (c + ε / 2)) atTop (𝓝 1) := by
    have hc : ContinuousAt (cdf (Measure.dirac c)) (c + ε / 2) := by
      refine (continuousAt_const (y := (1 : ℝ))).congr ?_
      filter_upwards [Ioi_mem_nhds (show c < c + ε / 2 by linarith)] with x hx
      simp [cdfConv_cdf_dirac, le_of_lt (mem_Ioi.1 hx)]
    have := h _ hc
    simpa [cdfConv_cdf_dirac, show c ≤ c + ε / 2 by linarith] using this
  have hlim : Tendsto (fun n => cdf (P.map (X n)) (c - ε) + (1 - cdf (P.map (X n)) (c + ε / 2)))
      atTop (𝓝 0) := by
    simpa using hlo.add ((tendsto_const_nhds (x := (1:ℝ))).sub hhi)
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hlim
    (fun n => measureReal_nonneg) (fun n => ?_)
  rw [cdfConv_cdf_map_eq P _ (hX n), cdfConv_cdf_map_eq P _ (hX n)]
  have hsub : {ω | ε ≤ dist (X n ω) c} ⊆
      {ω | X n ω ≤ c - ε} ∪ {ω | X n ω ≤ c + ε / 2}ᶜ := by
    intro ω hω
    simp only [mem_ofPred_eq, Real.dist_eq, le_abs] at hω
    simp only [mem_union, mem_ofPred_eq, mem_compl_iff, not_le]
    rcases hω with h1 | h1
    · right; linarith
    · left; linarith
  have hm : MeasurableSet {ω | X n ω ≤ c + ε / 2} := measurableSet_le (hX n) measurable_const
  calc P.real {ω | ε ≤ dist (X n ω) c}
      ≤ P.real ({ω | X n ω ≤ c - ε} ∪ {ω | X n ω ≤ c + ε / 2}ᶜ) := measureReal_mono hsub
    _ ≤ P.real {ω | X n ω ≤ c - ε} + P.real {ω | X n ω ≤ c + ε / 2}ᶜ := measureReal_union_le _ _
    _ = _ := by rw [probReal_compl_eq_one_sub hm]

-- Two dice: 21 of the 36 ordered pairs of faces have total at most 7.
example : ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun p : ℕ × ℕ => p.1 + p.2 ≤ 7)).card = 21 := by
  decide
-- The largest single jump at two dice: total 7 arises in 6 of the 36 ways.
example : ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun p : ℕ × ℕ => p.1 + p.2 = 7)).card = 6 := by
  decide
-- Fractions k/n at most 1/3 (that is, 3k ≤ n): 3 of 10, 33 of 100, 333 of 1000.
example : ((Finset.Icc 1 10).filter (fun k => 3 * k ≤ 10)).card = 3 := by decide
example : ((Finset.Icc 1 100).filter (fun k => 3 * k ≤ 100)).card = 33 := by decide
set_option maxRecDepth 100000 in
example : ((Finset.Icc 1 1000).filter (fun k => 3 * k ≤ 1000)).card = 333 := by decide
-- Average of x squared under U_10: (1 + 4 + ... + 100) / 1000 = 385 / 1000.
example : ∑ k ∈ Finset.Icc 1 10, k ^ 2 = 385 := by decide
-- The face underneath: |(7 - d) - d| for d = 1, ..., 6 is 5, 3, 1, 1, 3, 5, never below 1.
example : (List.range' 1 6).map (fun d : ℤ => |(7 - d) - d|) = [5, 3, 1, 1, 3, 5] := by decide
example : ∀ d ∈ Finset.Icc (1 : ℤ) 6, 1 ≤ |(7 - d) - d| := by decide

#print axioms cdf_convergence_iff_bounded_continuous_averages_converge
#print axioms tendstoInMeasure_implies_cdf_convergence
#print axioms cdf_convergence_to_constant_implies_tendstoInMeasure
#print axioms cdfConv_measure_singleton_eq_zero
#print axioms cdfConv_of_tendsto_pm
#print axioms cdfConv_tendsto_pm_of_cdf
#print axioms cdfConv_cdf_dirac
#print axioms cdfConv_cdf_map_eq
