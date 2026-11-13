-- The layer-cake formula: the integral of a non-negative measurable function equals the integral over heights t of the size of the set where the function exceeds t, with the weighted version for p-th powers and the shifted version for the average excess over a level K.
import Mathlib.MeasureTheory.Integral.Layercake
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Pow.Integral

open MeasureTheory Set
open scoped ENNReal

open Filter Topology in
/-- Helper: the moment formula, proved by truncating `f` at height `n` and passing to the limit. -/
theorem helper_rpow {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : Ω → ℝ≥0∞) (hf : Measurable f) (p : ℝ) (hp : 0 < p) :
    ∫⁻ ω, f ω ^ p ∂μ =
      ∫⁻ t in Ioi (0 : ℝ), ENNReal.ofReal (p * t ^ (p - 1)) * μ {ω | ENNReal.ofReal t < f ω} := by
  set F : ℕ → Ω → ℝ≥0∞ := fun n ω => min (f ω) (n : ℝ≥0∞) with hF
  have hFm : ∀ n, Measurable (F n) := fun n => hf.min measurable_const
  have hFne : ∀ n ω, F n ω ≠ ∞ := fun n ω =>
    (lt_of_le_of_lt (min_le_right _ _) (ENNReal.natCast_lt_top n)).ne
  have hFmono : ∀ ω, Monotone fun n => F n ω := fun ω i j hij =>
    min_le_min_left _ (by exact_mod_cast hij)
  have hFlim : ∀ ω, Tendsto (fun n => F n ω) atTop (𝓝 (f ω)) := by
    intro ω
    have : Tendsto (fun n : ℕ => (n : ℝ≥0∞)) atTop (𝓝 ∞) := ENNReal.tendsto_nat_nhds_top
    simpa using (tendsto_const_nhds (x := f ω)).min this
  have key : ∀ n, ∫⁻ ω, F n ω ^ p ∂μ =
      ∫⁻ t in Ioi (0 : ℝ), ENNReal.ofReal (p * t ^ (p - 1)) * μ {ω | ENNReal.ofReal t < F n ω} := by
    intro n
    have h := lintegral_rpow_eq_lintegral_meas_lt_mul μ (f := fun ω => (F n ω).toReal)
      (Eventually.of_forall fun ω => ENNReal.toReal_nonneg)
      ((hFm n).ennreal_toReal.aemeasurable) hp
    have e1 : ∀ ω, ENNReal.ofReal ((F n ω).toReal ^ p) = F n ω ^ p := by
      intro ω
      rw [← ENNReal.ofReal_rpow_of_nonneg ENNReal.toReal_nonneg hp.le,
        ENNReal.ofReal_toReal (hFne n ω)]
    simp_rw [e1] at h
    rw [h, ← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top]
    refine setLIntegral_congr_fun measurableSet_Ioi (fun t ht => ?_)
    have ht0 : (0 : ℝ) ≤ t := le_of_lt ht
    have hs : {a | t < (F n a).toReal} = {ω | ENNReal.ofReal t < F n ω} := by
      ext ω
      simp [ENNReal.ofReal_lt_iff_lt_toReal ht0 (hFne n ω)]
    rw [hs, ENNReal.ofReal_mul hp.le]
    ring
  have hmeasT : ∀ g : Ω → ℝ≥0∞, Measurable fun t : ℝ => μ {ω | ENNReal.ofReal t < g ω} := by
    intro g
    refine Antitone.measurable (fun s t hst => measure_mono ?_)
    intro ω hω
    exact lt_of_le_of_lt (ENNReal.ofReal_le_ofReal hst) hω
  have hwm : Measurable fun t : ℝ => ENNReal.ofReal (p * t ^ (p - 1)) := by
    fun_prop
  have L : Tendsto (fun n => ∫⁻ ω, F n ω ^ p ∂μ) atTop (𝓝 (∫⁻ ω, f ω ^ p ∂μ)) := by
    refine lintegral_tendsto_of_tendsto_of_monotone
      (fun n => ((hFm n).pow_const p).aemeasurable) (Eventually.of_forall fun ω => ?_)
      (Eventually.of_forall fun ω => ?_)
    · exact fun i j hij => ENNReal.rpow_le_rpow (hFmono ω hij) hp.le
    · exact ((ENNReal.continuous_rpow_const (y := p)).tendsto _).comp (hFlim ω)
  have R : Tendsto (fun n => ∫⁻ t in Ioi (0 : ℝ),
      ENNReal.ofReal (p * t ^ (p - 1)) * μ {ω | ENNReal.ofReal t < F n ω}) atTop
      (𝓝 (∫⁻ t in Ioi (0 : ℝ), ENNReal.ofReal (p * t ^ (p - 1)) *
        μ {ω | ENNReal.ofReal t < f ω})) := by
    refine lintegral_tendsto_of_tendsto_of_monotone
      (fun n => (hwm.mul (hmeasT (F n))).aemeasurable) (Eventually.of_forall fun t => ?_)
      (Eventually.of_forall fun t => ?_)
    · intro i j hij
      refine mul_le_mul' le_rfl (measure_mono ?_)
      intro ω hω
      exact lt_of_lt_of_le hω (hFmono ω hij)
    · refine ENNReal.Tendsto.const_mul ?_ (Or.inr ENNReal.ofReal_ne_top)
      have hmono : Monotone fun n => {ω | ENNReal.ofReal t < F n ω} := by
        intro i j hij ω hω
        exact lt_of_lt_of_le hω (hFmono ω hij)
      have hU : (⋃ n, {ω | ENNReal.ofReal t < F n ω}) = {ω | ENNReal.ofReal t < f ω} := by
        ext ω
        simp only [mem_iUnion, mem_ofPred_eq, hF, lt_min_iff]
        constructor
        · rintro ⟨n, h, -⟩
          exact h
        · intro h
          obtain ⟨n, hn⟩ := ENNReal.exists_nat_gt (ENNReal.ofReal_ne_top (r := t))
          exact ⟨n, h, hn⟩
      have := tendsto_measure_iUnion_atTop (μ := μ) hmono
      rw [hU] at this
      exact this
  simp_rw [key] at L
  exact tendsto_nhds_unique L R

#print axioms helper_rpow

/-- The layer-cake formula. On any measure space, for every measurable function `f ≥ 0`
(the value `+∞` allowed), the integral of `f` equals the integral, over every height `t > 0`,
of the size `μ(f > t)` of the set where `f` exceeds `t`. Both sides may be `+∞`. -/
theorem integral_eq_integral_of_tail_sizes {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : Ω → ℝ≥0∞) (hf : Measurable f) :
    ∫⁻ ω, f ω ∂μ = ∫⁻ t in Ioi (0 : ℝ), μ {ω | ENNReal.ofReal t < f ω} := by
  simpa using helper_rpow μ f hf 1 one_pos

/-- The moment formula. On any measure space, for every measurable function `f ≥ 0`
(the value `+∞` allowed) and every power `p > 0`, the integral of `f ^ p` equals the area
under the tail sizes `μ(f > t)` weighted by `p t^(p-1)`. -/
theorem integral_rpow_eq_weighted_tail_integral {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : Ω → ℝ≥0∞) (hf : Measurable f) (p : ℝ) (hp : 0 < p) :
    ∫⁻ ω, f ω ^ p ∂μ =
      ∫⁻ t in Ioi (0 : ℝ), ENNReal.ofReal (p * t ^ (p - 1)) * μ {ω | ENNReal.ofReal t < f ω} := by
  exact helper_rpow μ f hf p hp

/-- The shifted tail formula. For a random variable `X` on a probability space and any real
level `K`, the average excess `E[(X - K)^+]` equals the area under the tail `P(X > t)`
over heights `t` above `K`. -/
theorem average_excess_eq_tail_integral_above {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (hX : Measurable X) (K : ℝ) :
    ∫⁻ ω, ENNReal.ofReal (X ω - K) ∂P = ∫⁻ t in Ioi K, P {ω | t < X ω} := by
  have h := lintegral_eq_lintegral_meas_lt P (f := fun ω => max (X ω - K) 0)
    (Filter.Eventually.of_forall fun ω => le_max_right _ _)
    ((hX.sub_const K).max measurable_const).aemeasurable
  have e1 : ∀ ω, ENNReal.ofReal (max (X ω - K) 0) = ENNReal.ofReal (X ω - K) := by
    intro ω
    rcases le_total (X ω - K) 0 with h0 | h0
    · rw [max_eq_right h0, ENNReal.ofReal_zero, ENNReal.ofReal_of_nonpos h0]
    · rw [max_eq_left h0]
  simp_rw [e1] at h
  rw [h]
  have e2 : ∫⁻ t in Ioi (0 : ℝ), P {a | t < max (X a - K) 0} =
      ∫⁻ t in Ioi (0 : ℝ), P {ω | t + K < X ω} := by
    refine setLIntegral_congr_fun measurableSet_Ioi (fun t ht => ?_)
    congr 1
    ext ω
    simp only [mem_ofPred_eq, lt_max_iff]
    have : ¬ t < 0 := not_lt.mpr (le_of_lt ht)
    constructor
    · rintro (h | h)
      · linarith
      · exact absurd h this
    · intro h; left; linarith
  rw [e2]
  have hmp := measurePreserving_add_right (volume : Measure ℝ) K
  have := hmp.setLIntegral_comp_preimage_emb (measurableEmbedding_addRight K)
    (fun t => P {ω | t < X ω}) (Ioi K)
  rw [← this]
  simp

/-! The card's sixteen-point grid: each coordinate is one of 1/4, 2/4, 3/4, 1, written here
as `i + 1` quarters for `i : Fin 4`, so the larger coordinate is `max i j + 1` quarters. -/

-- The larger coordinate is k/4 on 2k - 1 points: 1, 3, 5, 7 of them.
example : (List.range 4).map (fun k =>
    ((Finset.univ : Finset (Fin 4 × Fin 4)).filter (fun q => (max q.1 q.2 : ℕ) = k)).card) =
    [1, 3, 5, 7] := by decide

-- The points with max above 0, 1/4, 2/4, 3/4 number 16, 15, 12, 7.
example : (List.range 4).map (fun k =>
    ((Finset.univ : Finset (Fin 4 × Fin 4)).filter (fun q => k < (max q.1 q.2 : ℕ) + 1)).card) =
    [16, 15, 12, 7] := by decide

-- Counting by columns and by rows gives the same 50 quarter-blocks.
example : ∑ q : Fin 4 × Fin 4, ((max q.1 q.2 : ℕ) + 1) =
    ∑ k : Fin 4, ((Finset.univ : Finset (Fin 4 × Fin 4)).filter
      (fun q => (k : ℕ) < (max q.1 q.2 : ℕ) + 1)).card := by decide

example : 1 * 1 + 2 * 3 + 3 * 5 + 4 * 7 = 50 ∧ 16 + 15 + 12 + 7 = 50 := by norm_num

-- E[M_4] = 50 / 64 = 25 / 32, the closed form (n + 1)(4n - 1)/(6n^2) at n = 4,
-- and the overshoot (3n - 1)/(6n^2) above 2/3.
example : (50 : ℚ) / (4 * 16) = 25 / 32 := by norm_num
example : ((4 + 1) * (4 * 4 - 1) : ℚ) / (6 * 4 ^ 2) = 25 / 32 := by norm_num
example : (25 : ℚ) / 32 - 2 / 3 = (3 * 4 - 1) / (6 * 4 ^ 2) := by norm_num

-- The closed form on the n by n grid for n = 2 and n = 10: the larger coordinate, in 1/n units,
-- summed over all n^2 points, is n^3 times (n + 1)(4n - 1)/(6n^2); cleared of denominators,
-- 6 times the sum equals (n + 1)(4n - 1) n.
example : 6 * ∑ q : Fin 2 × Fin 2, ((max q.1 q.2 : ℕ) + 1) = (2 + 1) * (4 * 2 - 1) * 2 := by
  decide
example : 6 * ∑ q : Fin 10 × Fin 10, ((max q.1 q.2 : ℕ) + 1) = (10 + 1) * (4 * 10 - 1) * 10 := by
  decide

-- Board arithmetic from the worked-numbers table: variance 1/2 - (2/3)^2 = 1/18,
-- moments 2/(p + 2) for p = 1, 2, 3, and the Markov rectangle 1/2 × 3/4 = 3/8 below 2/3.
example : (1 : ℚ) / 2 - (2 / 3) ^ 2 = 1 / 18 := by norm_num
example : ((2 : ℚ) / (1 + 2), (2 : ℚ) / (2 + 2), (2 : ℚ) / (3 + 2)) = (2 / 3, 1 / 2, 2 / 5) := by
  norm_num
example : (1 : ℚ) / 2 * (3 / 4) = 3 / 8 ∧ (3 : ℚ) / 8 < 2 / 3 := by norm_num

#print axioms integral_eq_integral_of_tail_sizes
#print axioms integral_rpow_eq_weighted_tail_integral
#print axioms average_excess_eq_tail_integral_above
