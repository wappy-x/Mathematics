-- Geometric Brownian motion: for the price S_t = S₀ e^((μ - σ²/2) t + σ W_t) driven by a Brownian motion W, the average price is S₀ e^(μ t), the middle price is S₀ e^((μ - σ²/2) t), the chance of ending below the average is Φ(σ √t / 2), and every path's long-run growth rate is μ - σ²/2.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open MeasureTheory ProbabilityTheory Filter Topology
open scoped NNReal

/-! The model. `W : ℝ≥0 → Ω → ℝ` is Mathlib's `IsBrownianReal W P`: it starts at 0, its moves
over separate stretches are independent, `W t` is normal with mean 0 and variance t, and its
paths are continuous with probability one (the card's "Paths are continuous").
The price at time `t` (in years) is `S₀ * exp ((μ - σ ^ 2 / 2) * t + σ * W t ω)`, with
today's price `S₀ > 0` (the card's "The price starts above zero"), and one fixed drift `μ`
and one fixed volatility `σ` (the card's "Drift and volatility are constants" and
"Percentage moves with one fixed spread"). The average over all paths is the integral `∫ … ∂P`.
`Φ(x)` is Mathlib's `cdf (gaussianReal 0 1) x`. -/

/-- Two pre-Brownian motions, sampled at countably many times, have the same joint law. -/
lemma preBrownian_map_countable_eq {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {X Y : ℝ≥0 → Ω → ℝ} (hX : IsPreBrownianReal X P) (hY : IsPreBrownianReal Y P)
    {ι : Type*} [Countable ι] (ψ : ι → ℝ≥0) :
    P.map (fun ω i => X (ψ i) ω) = P.map (fun ω i => Y (ψ i) ω) := by
  classical
  have hP : IsProbabilityMeasure P := hX.isGaussianProcess.isProbabilityMeasure
  have key : ∀ (Z : ℝ≥0 → Ω → ℝ), IsPreBrownianReal Z P → ∀ I : Finset ι,
      P.map (fun ω (j : I) => Z (ψ j) ω) =
        (BrownianReal.projectiveFamily (I.image ψ)).map
          (fun (f : (I.image ψ) → ℝ) (j : I) => f ⟨ψ j, Finset.mem_image_of_mem ψ j.2⟩) := by
    intro Z hZ I
    have hg : HasLaw (fun (f : (I.image ψ) → ℝ) (j : I) => f ⟨ψ j, Finset.mem_image_of_mem ψ j.2⟩)
        ((BrownianReal.projectiveFamily (I.image ψ)).map
          (fun (f : (I.image ψ) → ℝ) (j : I) => f ⟨ψ j, Finset.mem_image_of_mem ψ j.2⟩))
        (BrownianReal.projectiveFamily (I.image ψ)) :=
      hasLaw_map (Measurable.aemeasurable (by fun_prop))
    exact (hg.comp (hZ.hasLaw (I.image ψ))).map_eq
  have haeX : AEMeasurable (fun ω i => X (ψ i) ω) P :=
    AEMeasurable.of_eval (fun i => hX.aemeasurable (ψ i))
  have haeY : AEMeasurable (fun ω i => Y (ψ i) ω) P :=
    AEMeasurable.of_eval (fun i => hY.aemeasurable (ψ i))
  have hlimX : IsProjectiveLimit (P.map (fun ω i => X (ψ i) ω))
      (fun I => P.map (fun ω (j : I) => X (ψ j) ω)) := by
    intro I
    rw [AEMeasurable.map_map_of_aemeasurable (by fun_prop) haeX]
    rfl
  have hlimY : IsProjectiveLimit (P.map (fun ω i => Y (ψ i) ω))
      (fun I => P.map (fun ω (j : I) => X (ψ j) ω)) := by
    intro I
    rw [AEMeasurable.map_map_of_aemeasurable (by fun_prop) haeY]
    change P.map (fun ω (j : I) => Y (ψ j) ω) = P.map (fun ω (j : I) => X (ψ j) ω)
    rw [key X hX, key Y hY]
  exact hlimX.unique hlimY

/-- **Mean and median of geometric Brownian motion.** If `W` is a Brownian motion and the price
is `S_t = S₀ e^((μ - σ²/2) t + σ W_t)` with `S₀ > 0`, then at every time `t` the average price
is `S₀ e^(μ t)`, growing at the drift, while `S₀ e^((μ - σ²/2) t)` is a median: at least half
the paths end at or below it and at least half end at or above it. The middle grows slower than
the average by half the volatility squared. -/
theorem gbm_mean_and_median {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (S₀ μ σ : ℝ) (hS₀ : 0 < S₀) (t : ℝ≥0) :
    ∫ ω, S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω) ∂P = S₀ * Real.exp (μ * t) ∧
      1 / 2 ≤ P.real {ω | S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω)
                            ≤ S₀ * Real.exp ((μ - σ ^ 2 / 2) * t)} ∧
      1 / 2 ≤ P.real {ω | S₀ * Real.exp ((μ - σ ^ 2 / 2) * t)
                            ≤ S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω)} := by
  have hL := hW.hasLaw_eval t
  have hP : IsProbabilityMeasure P := hL.isProbabilityMeasure
  have hZ := gaussianReal_const_mul hL σ
  rw [mul_zero] at hZ
  have hZn := gaussianReal_neg hZ
  rw [neg_zero] at hZn
  set ν := gaussianReal 0 (⟨σ ^ 2, sq_nonneg _⟩ * t)
  have e1 : {ω | S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω)
                            ≤ S₀ * Real.exp ((μ - σ ^ 2 / 2) * t)} = {ω | σ * W t ω ≤ 0} := by
    ext ω; simp [mul_le_mul_iff_right₀ hS₀]
  have e2 : {ω | S₀ * Real.exp ((μ - σ ^ 2 / 2) * t)
                            ≤ S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω)} = {ω | 0 ≤ σ * W t ω} := by
    ext ω; simp [mul_le_mul_iff_right₀ hS₀]
  have m1 : P.real {ω | σ * W t ω ≤ 0} = ν.real {x | x ≤ 0} :=
    hZ.measureReal_eq (p := fun x => x ≤ 0) measurableSet_Iic
  have m2 : P.real {ω | 0 ≤ σ * W t ω} = ν.real {x | x ≤ 0} := by
    have := hZn.measureReal_eq (p := fun x => x ≤ 0) measurableSet_Iic
    simp only [Pi.neg_apply, neg_nonpos] at this
    exact this
  have hsum : 1 ≤ P.real {ω | σ * W t ω ≤ 0} + P.real {ω | 0 ≤ σ * W t ω} := by
    have h := measureReal_union_le (μ := P) {ω | σ * W t ω ≤ 0} {ω | 0 ≤ σ * W t ω}
    have hu : {ω | σ * W t ω ≤ 0} ∪ {ω | 0 ≤ σ * W t ω} = Set.univ := by
      ext ω; simp [le_total]
    rw [hu, probReal_univ] at h
    exact h
  refine ⟨?_, ?_, ?_⟩
  · have hm := mgf_gaussianReal hL σ
    rw [mgf] at hm
    simp_rw [Real.exp_add]
    rw [integral_const_mul, integral_const_mul]
    rw [show (∫ ω, Real.exp (σ * W t ω) ∂P) = Real.exp (0 * σ + ↑t * σ ^ 2 / 2) from hm]
    rw [← Real.exp_add]
    congr 2
    ring
  · rw [e1]; linarith
  · rw [e2]; linarith

/-- **Most paths end below the average.** With a positive volatility and a positive horizon
`t`, the chance that the price ends strictly below its average `S₀ e^(μ t)` is `Φ(σ √t / 2)`,
which is above one half and rises towards 1 as the horizon grows. (At `t = 0` or `σ = 0` the
price is not random and the chance is 0, so the card's formula needs a real spread and a real
wait.) -/
theorem gbm_prob_below_mean {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (S₀ μ σ : ℝ) (hS₀ : 0 < S₀) (hσ : 0 < σ)
    (t : ℝ≥0) (ht : 0 < t) :
    P.real {ω | S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω) < S₀ * Real.exp (μ * t)} =
      cdf (gaussianReal 0 1) (σ * Real.sqrt t / 2) := by
  have hL := hW.hasLaw_eval t
  have htR : (0 : ℝ) < t := ht
  have hs : 0 < Real.sqrt t := Real.sqrt_pos.mpr htR
  have hZ := gaussianReal_const_mul hL (Real.sqrt t)⁻¹
  rw [mul_zero] at hZ
  have hv : NNReal.mk ((Real.sqrt t)⁻¹ ^ 2) (sq_nonneg _) * t = 1 := by
    ext
    simp only [NNReal.coe_mul, NNReal.coe_mk, NNReal.coe_one, inv_pow,
      Real.sq_sqrt htR.le]
    field_simp
  rw [hv] at hZ
  have e : {ω | S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω) < S₀ * Real.exp (μ * t)}
      = {ω | (Real.sqrt t)⁻¹ * W t ω < σ * Real.sqrt t / 2} := by
    ext ω
    simp only [Set.mem_ofPred_eq, mul_lt_mul_iff_right₀ hS₀, Real.exp_lt_exp]
    rw [inv_mul_lt_iff₀ hs]
    have h1 : Real.sqrt t * (σ * Real.sqrt t / 2) = σ * t / 2 := by
      rw [show Real.sqrt t * (σ * Real.sqrt t / 2) = σ * (Real.sqrt t * Real.sqrt t) / 2 by ring,
        Real.mul_self_sqrt htR.le]
    rw [h1]
    constructor
    · intro h; nlinarith
    · intro h; nlinarith
  rw [e, hZ.measureReal_eq (p := fun x => x < σ * Real.sqrt t / 2) measurableSet_Iio,
    cdf_eq_real]
  have : NullSingletonClass (gaussianReal 0 1) := nullSingletonClass_gaussianReal one_ne_zero
  exact measureReal_congr (Iio_ae_eq_Iic' (measure_singleton _))

/-- **Each path grows at the median's rate.** With probability one, the long-run growth rate
`(1/t) ln(S_t / S₀)` of the price tends to `μ - σ²/2` as `t` grows, not to the drift `μ`. -/
theorem gbm_long_run_growth_rate {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {W : ℝ≥0 → Ω → ℝ} (hW : IsBrownianReal W P) (S₀ μ σ : ℝ) (hS₀ : 0 < S₀) :
    ∀ᵐ ω ∂P, Tendsto
      (fun t : ℝ≥0 => (1 / (t : ℝ)) *
        Real.log (S₀ * Real.exp ((μ - σ ^ 2 / 2) * t + σ * W t ω) / S₀))
      atTop (𝓝 (μ - σ ^ 2 / 2)) := by
  -- sample times: `ψ q = 1 / q` for positive rationals `q`
  set ψ : ℚ → ℝ≥0 := fun q => (Real.toNNReal q)⁻¹ with hψ
  set A : Set (ℚ → ℝ) := {f | ∀ m : ℕ, ∃ n : ℕ, ∀ q : ℚ,
    ψ q < 1 / ((n : ℝ≥0) + 1) → |f q| ≤ 1 / ((m : ℝ) + 1)} with hA_def
  have hA : MeasurableSet A := by
    have hA' : A = ⋂ m : ℕ, ⋃ n : ℕ, ⋂ q : ℚ, {f : ℚ → ℝ |
        ψ q < 1 / ((n : ℝ≥0) + 1) → |f q| ≤ 1 / ((m : ℝ) + 1)} := by
      ext f
      simp only [hA_def, Set.mem_iInter, Set.mem_iUnion, Set.mem_ofPred_eq]
    rw [hA']
    refine MeasurableSet.iInter fun m => MeasurableSet.iUnion fun n =>
      MeasurableSet.iInter fun q => ?_
    have hs : {f : ℚ → ℝ | ψ q < 1 / ((n : ℝ≥0) + 1) → |f q| ≤ 1 / ((m : ℝ) + 1)} =
        {f : ℚ → ℝ | ¬ ψ q < 1 / ((n : ℝ≥0) + 1)} ∪ {f : ℚ → ℝ | |f q| ≤ 1 / ((m : ℝ) + 1)} := by
      ext f
      simp only [Set.mem_union, Set.mem_ofPred_eq]
      tauto
    rw [hs]
    exact (MeasurableSet.const _).union
      (measurableSet_le (continuous_abs.measurable.comp (measurable_pi_apply q)) measurable_const)
  -- the Brownian motion itself satisfies the event
  have hEW : ∀ᵐ ω ∂P, (fun q => W (ψ q) ω) ∈ A := by
    filter_upwards [hW.tendsto_nhds_zero] with ω hω
    intro m
    rw [Metric.tendsto_nhds_nhds] at hω
    obtain ⟨δ, hδ, hδ'⟩ := hω (1 / ((m : ℝ) + 1)) (by positivity)
    obtain ⟨n, hn⟩ := exists_nat_one_div_lt hδ
    refine ⟨n, fun q hq => ?_⟩
    have h1 : dist (ψ q) 0 < δ := by
      rw [NNReal.dist_eq, NNReal.coe_zero, sub_zero, NNReal.abs_eq]
      refine lt_trans ?_ hn
      exact_mod_cast hq
    have := hδ' h1
    rw [Real.dist_eq, sub_zero] at this
    exact this.le
  -- time inversion transfers the event
  have hinv := hW.toIsPreBrownianReal.inv
  have hEX : ∀ᵐ ω ∂P, (fun q => (ψ q : ℝ) * W (1 / ψ q) ω) ∈ A := by
    have heq := preBrownian_map_countable_eq hinv hW.toIsPreBrownianReal ψ
    have haeX : AEMeasurable (fun ω q => (ψ q : ℝ) * W (1 / ψ q) ω) P :=
      AEMeasurable.of_eval (fun i => hinv.aemeasurable (ψ i))
    have haeW : AEMeasurable (fun ω q => W (ψ q) ω) P :=
      AEMeasurable.of_eval (fun i => hW.aemeasurable (ψ i))
    rw [ae_iff] at hEW ⊢
    have h1 := Measure.map_apply_of_aemeasurable haeX hA.compl
    have h2 := Measure.map_apply_of_aemeasurable haeW hA.compl
    rw [heq, h2] at h1
    exact h1.symm.trans hEW
  filter_upwards [hEX, hW.cont] with ω hE hc
  -- the path grows slower than linearly
  have hlin : Tendsto (fun t : ℝ≥0 => W t ω / t) atTop (𝓝 0) := by
    rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨m, hm⟩ := exists_nat_one_div_lt hε
    obtain ⟨n, hn⟩ := hE m
    set e : ℝ := 1 / ((m : ℝ) + 1)
    have he : 0 < e := by positivity
    refine ⟨(n : ℝ≥0) + 2, fun t ht => ?_⟩
    have htn : ((n : ℝ) + 1) < t := by
      have : ((n : ℝ≥0) + 2 : ℝ≥0) ≤ t := ht
      have : ((n : ℝ) + 2) ≤ (t : ℝ) := by exact_mod_cast this
      linarith
    have htpos : (0 : ℝ) < t := by linarith [(n.cast_nonneg : (0 : ℝ) ≤ n)]
    -- the bound at rational times
    have hrat : ∀ q : ℚ, ((n : ℝ) + 1) < q → |W (Real.toNNReal q) ω| - e * q ≤ 0 := by
      intro q hq
      have hqpos : (0 : ℝ) < q := by linarith [(n.cast_nonneg : (0 : ℝ) ≤ n)]
      have hψq : ψ q < 1 / ((n : ℝ≥0) + 1) := by
        rw [hψ]
        simp only
        rw [← NNReal.coe_lt_coe, NNReal.coe_inv, Real.coe_toNNReal _ hqpos.le]
        push_cast
        rw [one_div]
        exact inv_strictAnti₀ (by positivity) hq
      have hb := hn q hψq
      simp only at hb
      have hψv : (ψ q : ℝ) = 1 / q := by
        rw [hψ]; simp only
        rw [NNReal.coe_inv, Real.coe_toNNReal _ hqpos.le, one_div]
      have hψi : 1 / ψ q = Real.toNNReal q := by
        rw [hψ]; simp only
        rw [one_div, inv_inv]
      rw [hψi, hψv, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < 1 / q)] at hb
      rw [div_mul_eq_mul_div, one_mul, div_le_iff₀ hqpos] at hb
      linarith
    have hcl : IsClosed {x : ℝ | |W (Real.toNNReal x) ω| - e * x ≤ 0} :=
      isClosed_le (by fun_prop) continuous_const
    have hsub : Set.Ioi ((n : ℝ) + 1) ⊆ {x : ℝ | |W (Real.toNNReal x) ω| - e * x ≤ 0} := by
      refine (Rat.denseRange_cast.open_subset_closure_inter isOpen_Ioi).trans ?_
      refine closure_minimal ?_ hcl
      rintro x ⟨hx, q, rfl⟩
      exact hrat q hx
    have hb := hsub (Set.mem_Ioi.mpr htn)
    simp only [Set.mem_ofPred_eq, Real.toNNReal_coe] at hb
    rw [Real.dist_eq, sub_zero, abs_div, abs_of_pos htpos, div_lt_iff₀ htpos]
    calc |W t ω| ≤ e * t := by linarith
      _ < ε * t := by gcongr
  have hlim : Tendsto (fun t : ℝ≥0 => (μ - σ ^ 2 / 2) + σ * (W t ω / t)) atTop
      (𝓝 (μ - σ ^ 2 / 2)) := by
    simpa using (hlin.const_mul σ).const_add (μ - σ ^ 2 / 2)
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop (0 : ℝ≥0)] with t ht
  have htR : (0 : ℝ) < t := ht
  rw [mul_div_cancel_left₀ _ hS₀.ne', Real.log_exp]
  field_simp

/-! The card's exact worked steps, with 0.05 = 1/20 and 0.20 = 1/5. -/

-- Variance per year: 0.20 × 0.20 = 0.04.
example : (1 / 5 : ℚ) * (1 / 5) = 1 / 25 := by norm_num
-- Volatility drag: 0.04 / 2 = 0.02.
example : (1 / 25 : ℚ) / 2 = 1 / 50 := by norm_num
-- The median's growth rate: 0.05 - 0.02 = 0.03.
example : (1 / 20 : ℚ) - 1 / 50 = 3 / 100 := by norm_num
-- The point inside Φ for the chance of ending below the mean: σ √t / 2 is 0.1 at one year
-- and 1 at 100 years (√100 = 10).
example : (1 / 5 : ℚ) * 1 / 2 = 1 / 10 ∧ (1 / 5 : ℚ) * 10 / 2 = 1 ∧ (10 : ℚ) ^ 2 = 100 := by
  norm_num
-- The chance of a loss is Φ(-0.03 / 0.20) = Φ(-0.15).
example : -(3 / 100 : ℚ) / (1 / 5) = -3 / 20 := by norm_num
-- Steps a year: a fourfold cut from 63 to 252 steps halves the gap, since √4 = 2.
example : 63 * 4 = 252 ∧ 2 ^ 2 = 4 := by decide
-- One up step and one down step: (1 + a + b)(1 + a - b) = (1 + a)² - b², losing b² = σ² Δt.
example (a b : ℚ) : (1 + a + b) * (1 + a - b) = (1 + a) ^ 2 - b ^ 2 := by ring

#print axioms preBrownian_map_countable_eq
#print axioms gbm_mean_and_median
#print axioms gbm_prob_below_mean
#print axioms gbm_long_run_growth_rate
