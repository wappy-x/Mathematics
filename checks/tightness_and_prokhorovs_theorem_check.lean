-- Tightness and Prokhorov's theorem: a family of laws on R^d is tight exactly when every sequence in it has a subsequence converging in distribution to a law, with Helly's selection theorem on the line and the version on complete separable metric spaces.
import Mathlib.MeasureTheory.Measure.Prokhorov
import Mathlib.MeasureTheory.Measure.LevyProkhorovMetric
import Mathlib.Probability.CDF
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan

open MeasureTheory Filter Topology Set ProbabilityTheory
open scoped NNReal

theorem tp_polish_aux
    {S : Type*} [MetricSpace S] [CompleteSpace S] [TopologicalSpace.SeparableSpace S]
    [MeasurableSpace S] [BorelSpace S] (M : Set (ProbabilityMeasure S)) :
    (∀ ε : ℝ, 0 < ε → ∃ K : Set S, IsCompact K ∧ ∀ μ ∈ M, 1 - ε ≤ ((μ K : ℝ≥0) : ℝ)) ↔
      ∀ μs : ℕ → ProbabilityMeasure S, (∀ n, μs n ∈ M) →
        ∃ φ : ℕ → ℕ, StrictMono φ ∧
          ∃ μ : ProbabilityMeasure S, Tendsto (fun k => μs (φ k)) atTop (𝓝 μ) := by
  have key : ∀ (μ : ProbabilityMeasure S) (K : Set S), IsClosed K →
      ((μ : Measure S) Kᶜ).toReal = 1 - ((μ K : ℝ≥0) : ℝ) := by
    intro μ K hK
    rw [← measureReal_def, measureReal_compl hK.measurableSet, probReal_univ]
    rfl
  constructor
  · intro h μs hμs
    have hT : IsTightMeasureSet {((μ : ProbabilityMeasure S) : Measure S) | μ ∈ M} := by
      rw [isTightMeasureSet_iff_exists_isCompact_measure_compl_le]
      intro ε hε
      by_cases htop : ε = ⊤
      · exact ⟨∅, isCompact_empty, fun _ _ => by simp [htop]⟩
      obtain ⟨K, hK, hKM⟩ := h ε.toReal (ENNReal.toReal_pos hε.ne' htop)
      refine ⟨K, hK, ?_⟩
      rintro _ ⟨μ, hμ, rfl⟩
      rw [← ENNReal.toReal_le_toReal (measure_ne_top _ _) htop, key μ K hK.isClosed]
      linarith [hKM μ hμ]
    obtain ⟨μ, -, φ, hφ, hlim⟩ :=
      (isCompact_closure_of_isTightMeasureSet hT).isSeqCompact (fun n => subset_closure (hμs n))
    exact ⟨φ, hφ, μ, hlim⟩
  · intro h
    have hcl : IsCompact (closure M) := by
      let _ : MetricSpace (ProbabilityMeasure S) := TopologicalSpace.metrizableSpaceMetric _
      apply IsSeqCompact.isCompact
      intro x hx
      have : ∀ n : ℕ, ∃ y ∈ M, dist (x n) y < 1 / ((n : ℝ) + 1) := fun n =>
        Metric.mem_closure_iff.1 (hx n) _ Nat.one_div_pos_of_nat
      choose y hyM hy using this
      obtain ⟨φ, hφ, μ, hμ⟩ := h y hyM
      refine ⟨μ, mem_closure_of_tendsto hμ (Eventually.of_forall fun k => hyM _), φ, hφ, ?_⟩
      rw [tendsto_iff_dist_tendsto_zero]
      have h1 : Tendsto (fun k => 1 / ((φ k : ℝ) + 1)) atTop (𝓝 0) :=
        tendsto_one_div_add_atTop_nhds_zero_nat.comp hφ.tendsto_atTop
      have h2 : Tendsto (fun k => dist (y (φ k)) μ) atTop (𝓝 0) :=
        (tendsto_iff_dist_tendsto_zero).1 hμ
      have h3 := h1.add h2
      rw [add_zero] at h3
      refine squeeze_zero (fun _ => dist_nonneg) (fun k => ?_) h3
      exact (dist_triangle _ (y (φ k)) _).trans (add_le_add_left (hy (φ k)).le _)
    have hT := isTightMeasureSet_of_isCompact_closure hcl
    rw [isTightMeasureSet_iff_exists_isCompact_measure_compl_le] at hT
    intro ε hε
    obtain ⟨K, hK, hKM⟩ := hT (ENNReal.ofReal ε) (ENNReal.ofReal_pos.2 hε)
    refine ⟨K, hK, fun μ hμ => ?_⟩
    have := hKM _ ⟨μ, hμ, rfl⟩
    rw [← ENNReal.toReal_le_toReal (measure_ne_top _ _) ENNReal.ofReal_ne_top,
      key μ K hK.isClosed, ENNReal.toReal_ofReal hε.le] at this
    linarith

#print axioms tp_polish_aux

/-- **Prokhorov's theorem on R^d.** A family of laws on `R^d` is tight (for every leak
`ε > 0` one box `[-K, K]^d` holds at least `1 - ε` of every law in the family) exactly when
every sequence of laws from the family has a subsequence converging in distribution to some law. -/
theorem tight_iff_every_sequence_has_convergent_subsequence {d : ℕ}
    (M : Set (ProbabilityMeasure (Fin d → ℝ))) :
    (∀ ε : ℝ, 0 < ε → ∃ K : ℝ, ∀ μ ∈ M,
        1 - ε ≤ ((μ (Set.univ.pi fun _ : Fin d => Set.Icc (-K) K) : ℝ≥0) : ℝ)) ↔
      ∀ μs : ℕ → ProbabilityMeasure (Fin d → ℝ), (∀ n, μs n ∈ M) →
        ∃ φ : ℕ → ℕ, StrictMono φ ∧
          ∃ μ : ProbabilityMeasure (Fin d → ℝ), Tendsto (fun k => μs (φ k)) atTop (𝓝 μ) := by
  rw [← tp_polish_aux M]
  constructor
  · intro h ε hε
    obtain ⟨K, hK⟩ := h ε hε
    exact ⟨_, isCompact_univ_pi fun _ => isCompact_Icc, hK⟩
  · intro h ε hε
    obtain ⟨K, hK, hKM⟩ := h ε hε
    obtain ⟨R, hR⟩ := hK.isBounded.subset_closedBall 0
    refine ⟨R, fun μ hμ => (hKM μ hμ).trans ?_⟩
    refine NNReal.coe_le_coe.2 (μ.apply_mono fun x hx => ?_)
    have hx' : ‖x‖ ≤ R := mem_closedBall_zero_iff.1 (hR hx)
    refine Set.mem_univ_pi.2 fun i => ?_
    have := (norm_le_pi_norm x i).trans hx'
    rw [Real.norm_eq_abs] at this
    exact abs_le.1 this

/-- **Helly's selection theorem.** Every sequence of distribution functions on the line has a
subsequence that converges, at every point where the limit is continuous, to a non-decreasing,
right-continuous function `F` with values in `[0, 1]` (which may lose mass at the ends). -/
theorem helly_selection (μ : ℕ → ProbabilityMeasure ℝ) :
    ∃ φ : ℕ → ℕ, StrictMono φ ∧ ∃ F : StieltjesFunction ℝ,
      (∀ x, F x ∈ Set.Icc (0 : ℝ) 1) ∧
      ∀ x, ContinuousAt F x →
        Tendsto (fun k => cdf (μ (φ k) : Measure ℝ) x) atTop (𝓝 (F x)) := by
  set ν : ℕ → ProbabilityMeasure ℝ := fun n => (μ n).map Real.arctan with hν
  have hpre : ∀ a : ℝ, Real.arctan ⁻¹' Iic (Real.arctan a) = Iic a := by
    intro a; ext y; simp [Real.arctan_strictMono.le_iff_le]
  have hM : ∀ ε : ℝ, 0 < ε → ∃ K : Set ℝ, IsCompact K ∧
      ∀ ρ ∈ range ν, 1 - ε ≤ ((ρ K : ℝ≥0) : ℝ) := by
    intro ε hε
    refine ⟨Icc (-(Real.pi / 2)) (Real.pi / 2), isCompact_Icc, ?_⟩
    rintro _ ⟨n, rfl⟩
    have : ν n (Icc (-(Real.pi / 2)) (Real.pi / 2)) = 1 := by
      rw [hν, ProbabilityMeasure.map_apply _ Real.continuous_arctan.aemeasurable
        measurableSet_Icc]
      have : Real.arctan ⁻¹' Icc (-(Real.pi / 2)) (Real.pi / 2) = univ := by
        ext y
        simp only [mem_preimage, mem_Icc, mem_univ, iff_true]
        exact ⟨(Real.neg_pi_div_two_lt_arctan y).le, (Real.arctan_lt_pi_div_two y).le⟩
      rw [this, ProbabilityMeasure.coeFn_univ]
    rw [this]
    simp
    linarith
  obtain ⟨φ, hφ, ρ, hρ⟩ := (tp_polish_aux (range ν)).1 hM ν (fun n => mem_range_self n)
  let F : StieltjesFunction ℝ :=
    { toFun := fun x => cdf (ρ : Measure ℝ) (Real.arctan x)
      mono' := (cdf (ρ : Measure ℝ)).mono.comp Real.arctan_strictMono.monotone
      right_continuous' := fun x =>
        ((cdf (ρ : Measure ℝ)).right_continuous _).comp
          Real.continuous_arctan.continuousWithinAt
          (fun y hy => Real.arctan_strictMono.monotone hy) }
  have hF : ∀ x, F x = cdf (ρ : Measure ℝ) (Real.arctan x) := fun x => rfl
  refine ⟨φ, hφ, F, fun x => ⟨by rw [hF]; exact cdf_nonneg _ _, by rw [hF]; exact cdf_le_one _ _⟩,
    fun x hx => ?_⟩
  set a := Real.arctan x with ha
  -- continuity of the cdf of ρ at a
  have hcont : ContinuousAt (cdf (ρ : Measure ℝ)) a := by
    have htan : ContinuousAt Real.tan a :=
      Real.continuousOn_tan_Ioo.continuousAt (Ioo_mem_nhds (Real.neg_pi_div_two_lt_arctan x)
        (Real.arctan_lt_pi_div_two x))
    have h1 : ContinuousAt (F ∘ Real.tan) a :=
      ContinuousAt.comp_of_eq hx htan (by rw [ha, Real.tan_arctan])
    refine h1.congr ?_
    filter_upwards [Ioo_mem_nhds (Real.neg_pi_div_two_lt_arctan x)
      (Real.arctan_lt_pi_div_two x)] with y hy
    simp only [Function.comp_apply, hF]
    rw [Real.arctan_tan hy.1 hy.2]
  have hnull : (ρ : Measure ℝ) {a} = 0 := by
    have hm := (cdf (ρ : Measure ℝ)).measure_singleton a
    rw [measure_cdf, hcont.continuousWithinAt.leftLim_eq] at hm
    simpa using hm
  have hfr : ρ (frontier (Iic a)) = 0 := by
    rw [frontier_Iic]
    have : ((ρ {a} : ℝ≥0) : ENNReal) = 0 := by
      rw [ProbabilityMeasure.ennreal_coeFn_eq_coeFn_toMeasure]; exact hnull
    exact_mod_cast this
  have hlim := NNReal.tendsto_coe.2
    (ProbabilityMeasure.tendsto_measure_of_null_frontier_of_tendsto hρ hfr)
  have hcdf : ∀ (P : ProbabilityMeasure ℝ) (b : ℝ),
      cdf (P : Measure ℝ) b = ((P (Iic b) : ℝ≥0) : ℝ) := fun P b => by
    rw [cdf_eq_real]; rfl
  rw [hF, hcdf]
  refine hlim.congr fun k => ?_
  simp only [hν]
  rw [ProbabilityMeasure.map_apply _ Real.continuous_arctan.aemeasurable measurableSet_Iic,
    ha, hpre, hcdf]

/-- **Prokhorov's theorem on a complete separable metric space.** A family of laws is tight
(for every `ε > 0` one compact set holds at least `1 - ε` of every law in it) exactly when
every sequence of laws from it has a weakly convergent subsequence. -/
theorem polish_tight_iff_every_sequence_has_convergent_subsequence
    {S : Type*} [MetricSpace S] [CompleteSpace S] [TopologicalSpace.SeparableSpace S]
    [MeasurableSpace S] [BorelSpace S] (M : Set (ProbabilityMeasure S)) :
    (∀ ε : ℝ, 0 < ε → ∃ K : Set S, IsCompact K ∧ ∀ μ ∈ M, 1 - ε ≤ ((μ K : ℝ≥0) : ℝ)) ↔
      ∀ μs : ℕ → ProbabilityMeasure S, (∀ n, μs n ∈ M) →
        ∃ φ : ℕ → ℕ, StrictMono φ ∧
          ∃ μ : ProbabilityMeasure S, Tendsto (fun k => μs (φ k)) atTop (𝓝 μ) := by
  exact tp_polish_aux M

-- The fair die (faces 1 to 6): mean 7/2 and variance 35/12, used to standardise the die totals.
example : (∑ k ∈ Finset.range 6, ((k : ℚ) + 1)) / 6 = 7 / 2 := by
  norm_num [Finset.sum_range_succ]
example : (∑ k ∈ Finset.range 6, ((k : ℚ) + 1 - 7 / 2) ^ 2) / 6 = 35 / 12 := by
  norm_num [Finset.sum_range_succ]

-- Chebyshev's cap 1/K^2 on P(|Z_n| > K) at K = 2, 3 and 10.
example : (1 : ℚ) / 2 ^ 2 = 1 / 4 ∧ (1 : ℚ) / 3 ^ 2 = 1 / 9 ∧ (1 : ℚ) / 10 ^ 2 = 1 / 100 := by
  norm_num

-- Point masses at 0, 1, 2, ...: F_n(5) = 1 exactly for the six laws n = 0, ..., 5.
example : ((Finset.range 11).filter (fun n => n ≤ 5)).card = 6 := by decide

#print axioms tight_iff_every_sequence_has_convergent_subsequence
#print axioms helly_selection
#print axioms polish_tight_iff_every_sequence_has_convergent_subsequence
