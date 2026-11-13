-- The weak law of large numbers: for draws with a common mean, variances at most σ² and no correlation between any two, the chance that the average of n draws misses the mean by at least ε is at most σ²/(nε²) and tends to 0, the count ⌈σ²/(δε²)⌉ guarantees a hit with chance at least 1 - δ, and for draws independent in pairs with one law a finite mean alone is enough.
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.IdentDistrib
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Data.Rat.Floor
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Probability.StrongLaw
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.MeasureTheory.Function.L2Space

open MeasureTheory ProbabilityTheory Filter Topology

lemma wlln_chebyshev_bound {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (m σ2 : ℝ)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hvar : ∀ i, ∫ ω, (X i ω - m) ^ 2 ∂P ≤ σ2)
    (hcorr : ∀ i j, i ≠ j → ∫ ω, (X i ω - m) * (X j ω - m) ∂P = 0)
    (ε : ℝ) (hε : 0 < ε) (n : ℕ) (hn : 1 ≤ n) :
    P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - m|} ≤
      ENNReal.ofReal (σ2 / (n * ε ^ 2)) := by
  have hZ : ∀ i, MemLp (fun ω => X i ω - m) 2 P := fun i => (hL2 i).sub (memLp_const m)
  have hprod : ∀ i j, Integrable (fun ω => (X i ω - m) * (X j ω - m)) P :=
    fun i j => (hZ i).integrable_mul (hZ j)
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  set Y : Ω → ℝ := fun ω => ∑ i ∈ Finset.range n, (X i ω - m) with hYdef
  have hY2 : ∀ ω, Y ω ^ 2 =
      ∑ i ∈ Finset.range n, ∑ j ∈ Finset.range n, (X i ω - m) * (X j ω - m) := by
    intro ω; simp only [Y, sq]; exact Finset.sum_mul_sum _ _ _ _
  have hYint : Integrable (fun ω => Y ω ^ 2) P := by
    simp_rw [hY2]
    exact integrable_finsetSum _ fun i _ => integrable_finsetSum _ fun j _ => hprod i j
  have hEY : ∫ ω, Y ω ^ 2 ∂P ≤ n * σ2 := by
    simp_rw [hY2]
    rw [integral_finsetSum _ fun i _ => integrable_finsetSum _ fun j _ => hprod i j]
    have : ∀ i ∈ Finset.range n, ∫ ω, ∑ j ∈ Finset.range n, (X i ω - m) * (X j ω - m) ∂P
        = ∫ ω, (X i ω - m) ^ 2 ∂P := by
      intro i hi
      rw [integral_finsetSum _ fun j _ => hprod i j]
      rw [Finset.sum_eq_single i]
      · simp [sq]
      · intro j _ hji; exact hcorr i j (Ne.symm hji)
      · intro h; exact absurd hi h
    rw [Finset.sum_congr rfl this]
    calc ∑ i ∈ Finset.range n, ∫ ω, (X i ω - m) ^ 2 ∂P
        ≤ ∑ i ∈ Finset.range n, σ2 := Finset.sum_le_sum fun i _ => hvar i
      _ = n * σ2 := by simp
  have hmarkov := mul_meas_ge_le_integral_of_nonneg
    (Eventually.of_forall fun ω => sq_nonneg (Y ω)) hYint ((n * ε) ^ 2)
  have hsub : {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - m|} ⊆
      {ω | (n * ε) ^ 2 ≤ Y ω ^ 2} := by
    intro ω hω
    simp only [Set.mem_ofPred_eq] at hω ⊢
    have hYeq : Y ω = n * ((∑ i ∈ Finset.range n, X i ω) / n - m) := by
      simp only [Y, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
      field_simp
    rw [hYeq, mul_pow, mul_pow]
    have : ε ^ 2 ≤ ((∑ i ∈ Finset.range n, X i ω) / n - m) ^ 2 := by
      rw [← sq_abs ((∑ i ∈ Finset.range n, X i ω) / n - m)]
      exact pow_le_pow_left₀ hε.le hω 2
    exact mul_le_mul_of_nonneg_left this (by positivity)
  have hreal : P.real {ω | (n * ε) ^ 2 ≤ Y ω ^ 2} ≤ σ2 / (n * ε ^ 2) := by
    have hpos : (0 : ℝ) < (n * ε) ^ 2 := by positivity
    rw [le_div_iff₀ (by positivity)]
    have := hmarkov.trans hEY
    nlinarith
  calc P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - m|}
      ≤ P {ω | (n * ε) ^ 2 ≤ Y ω ^ 2} := measure_mono hsub
    _ = ENNReal.ofReal (P.real {ω | (n * ε) ^ 2 ≤ Y ω ^ 2}) := by
        rw [ofReal_measureReal]
    _ ≤ ENNReal.ofReal (σ2 / (n * ε ^ 2)) := ENNReal.ofReal_le_ofReal hreal

#print axioms wlln_chebyshev_bound

/-- **The weak law, finite variance.** Let `X 0, X 1, X 2, …` be random variables on a
probability space with finite second moments, a common mean `m`, variances
`E[(X i - m)²]` at most `σ²`, and no correlation between any two:
`E[(X i - m)(X j - m)] = 0` whenever `i ≠ j`. Fix a margin `ε > 0`. Then for every `n ≥ 1`
the chance that the average of the first `n` draws misses `m` by at least `ε` is at most
`σ² / (n ε²)`, and this chance tends to 0 as `n` grows. -/
theorem weak_law_of_uncorrelated_draws {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (m σ2 : ℝ)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = m)
    (hvar : ∀ i, ∫ ω, (X i ω - m) ^ 2 ∂P ≤ σ2)
    (hcorr : ∀ i j, i ≠ j → ∫ ω, (X i ω - m) * (X j ω - m) ∂P = 0)
    (ε : ℝ) (hε : 0 < ε) :
    (∀ n : ℕ, 1 ≤ n →
      P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - m|} ≤
        ENNReal.ofReal (σ2 / (n * ε ^ 2))) ∧
    Tendsto (fun n : ℕ => P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - m|})
      atTop (𝓝 0) := by
  have hb := wlln_chebyshev_bound X m σ2 hL2 hvar hcorr ε hε
  refine ⟨hb, ?_⟩
  have hlim : Tendsto (fun n : ℕ => ENNReal.ofReal (σ2 / (n * ε ^ 2))) atTop (𝓝 0) := by
    rw [← ENNReal.ofReal_zero]
    apply ENNReal.tendsto_ofReal
    have := tendsto_const_div_atTop_nhds_zero_nat (σ2 / ε ^ 2)
    refine this.congr fun n => ?_
    rw [div_div, mul_comm]
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hlim
    (Eventually.of_forall fun n => bot_le) ?_
  filter_upwards [eventually_ge_atTop 1] with n hn using hb n hn

/-- **The explicit count.** Under the same hypotheses (finite second moments, common mean `m`,
variances at most `σ²`, no correlation between any two), fix a margin `ε > 0` and an allowed
chance of a miss `δ` with `0 < δ < 1`, and put `N = ⌈σ² / (δ ε²)⌉`. Then for every `n ≥ 1`
with `n ≥ N`, the average of the first `n` draws lands within `ε` of `m` with probability at
least `1 - δ`. And `N` is the least count the inequality certifies: for `1 ≤ n < N`, the
ceiling `σ² / (n ε²)` is above `δ`. -/
theorem weak_law_explicit_count {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ) (m σ2 : ℝ)
    (hL2 : ∀ i, MemLp (X i) 2 P)
    (hmean : ∀ i, ∫ ω, X i ω ∂P = m)
    (hvar : ∀ i, ∫ ω, (X i ω - m) ^ 2 ∂P ≤ σ2)
    (hcorr : ∀ i j, i ≠ j → ∫ ω, (X i ω - m) * (X j ω - m) ∂P = 0)
    (ε δ : ℝ) (hε : 0 < ε) (hδ0 : 0 < δ) (hδ1 : δ < 1) :
    (∀ n : ℕ, 1 ≤ n → ⌈σ2 / (δ * ε ^ 2)⌉₊ ≤ n →
      ENNReal.ofReal (1 - δ) ≤
        P {ω | |(∑ i ∈ Finset.range n, X i ω) / n - m| < ε}) ∧
    (∀ n : ℕ, 1 ≤ n → n < ⌈σ2 / (δ * ε ^ 2)⌉₊ → δ < σ2 / (n * ε ^ 2)) := by
  have hε2 : 0 < ε ^ 2 := by positivity
  refine ⟨fun n hn hN => ?_, fun n hn hN => ?_⟩
  · have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
    have hle : σ2 / (δ * ε ^ 2) ≤ n := (Nat.le_ceil _).trans (by exact_mod_cast hN)
    have hδ : σ2 / (n * ε ^ 2) ≤ δ := by
      rw [div_le_iff₀ (by positivity)] at hle ⊢
      nlinarith
    set A := {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - m|} with hA
    have hAc : {ω | |(∑ i ∈ Finset.range n, X i ω) / n - m| < ε} = Aᶜ := by
      ext ω; simp [A, not_le]
    rw [hAc]
    have hPA : P A ≤ ENNReal.ofReal δ :=
      (wlln_chebyshev_bound X m σ2 hL2 hvar hcorr ε hε n hn).trans
        (ENNReal.ofReal_le_ofReal hδ)
    have hunion : 1 ≤ P Aᶜ + P A := by
      calc (1 : ENNReal) = P (Aᶜ ∪ A) := by rw [Set.compl_union_self, measure_univ]
        _ ≤ P Aᶜ + P A := measure_union_le _ _
    rw [ENNReal.ofReal_sub _ hδ0.le, ENNReal.ofReal_one]
    calc 1 - ENNReal.ofReal δ ≤ 1 - P A := tsub_le_tsub_left hPA 1
      _ ≤ P Aᶜ := tsub_le_iff_right.mpr hunion
  · have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
    have hlt : (n : ℝ) < σ2 / (δ * ε ^ 2) := Nat.lt_ceil.mp hN
    rw [lt_div_iff₀ (by positivity)] at hlt ⊢
    nlinarith

/-- **The weak law, finite mean (Khintchine).** Let `X 0, X 1, X 2, …` be random variables on
a probability space, independent in pairs, each with the law of `X 0`, and with a finite mean
`E|X 0| < ∞`. Then for every margin `ε > 0`, the chance that the average of the first `n`
draws misses `E[X 0]` by at least `ε` tends to 0 as `n` grows. No variance is assumed. -/
theorem weak_law_of_finite_mean {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hindep : Pairwise fun i j => IndepFun (X i) (X j) P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hint : Integrable (X 0) P)
    (ε : ℝ) (hε : 0 < ε) :
    Tendsto
      (fun n : ℕ => P {ω | ε ≤ |(∑ i ∈ Finset.range n, X i ω) / n - ∫ ω', X 0 ω' ∂P|})
      atTop (𝓝 0) := by
  have hae := strong_law_ae X hint hindep hident
  have hmeas : ∀ n : ℕ, AEStronglyMeasurable
      (fun ω => (n : ℝ)⁻¹ • ∑ i ∈ Finset.range n, X i ω) P := by
    intro n
    have hs : AEStronglyMeasurable (fun ω => ∑ i ∈ Finset.range n, X i ω) P :=
      Finset.aestronglyMeasurable_fun_sum _ fun i _ =>
        (hident i).aemeasurable_fst.aestronglyMeasurable
    exact hs.const_smul ((n : ℝ)⁻¹)
  have hm := tendstoInMeasure_of_tendsto_ae hmeas
    (g := fun _ => ∫ ω', X 0 ω' ∂P) hae
  rw [tendstoInMeasure_iff_dist] at hm
  refine (hm ε hε).congr fun n => ?_
  congr 1
  ext ω
  simp [Real.dist_eq, smul_eq_mul, inv_mul_eq_div]

-- One fair die: mean (1 + 2 + ⋯ + 6)/6 = 7/2, mean square 91/6, variance 91/6 - (7/2)² = 35/12.
example : ((1 + 2 + 3 + 4 + 5 + 6 : ℚ)) / 6 = 7 / 2 := by norm_num
example : ((1 + 4 + 9 + 16 + 25 + 36 : ℚ)) / 6 = 91 / 6 := by norm_num
example : (91 / 6 : ℚ) - (7 / 2) ^ 2 = 35 / 12 := by norm_num
-- The Chebyshev constant at ε = 1/10: (35/12)/(1/10)² = 875/3.
example : (35 / 12 : ℚ) / (1 / 10) ^ 2 = 875 / 3 := by norm_num
-- The count for 99%: N = ⌈(35/12)/((1/100)(1/10)²)⌉ = 29,167.
example : ⌈(35 / 12 : ℚ) / ((1 / 100) * (1 / 10) ^ 2)⌉₊ = 29167 := by
  rw [Nat.ceil_eq_iff (by norm_num)]; norm_num
-- 29,167 rolls are certified (bound below 1/100), 29,166 are not (bound above 1/100).
example : (875 / 3 : ℚ) / 29167 < 1 / 100 := by norm_num
example : (1 / 100 : ℚ) < (875 / 3) / 29166 := by norm_num
-- The average of 1,000 rolls has variance (35/12)/1000 = 7/2400; Chebyshev's ceiling there is 7/24.
example : (35 / 12 : ℚ) / 1000 = 7 / 2400 := by norm_num
example : (875 / 3 : ℚ) / 1000 = 7 / 24 := by norm_num
-- The average of 15 faces independent in pairs has variance (35/12)/15 = 7/36, Chebyshev's ceiling at ε = 1.
example : (35 / 12 : ℚ) / 15 = 7 / 36 := by norm_num
-- Step 4's recipe: 4 real dice a, b, c, d (each 0 to 5) give 2⁴ - 1 = 15 faces, one for each
-- nonempty subset s of the four: (sum of the dice in s) mod 6, plus 1. `fifteenFaceTotal` adds them.
def fifteenFaceTotal (a b c d : ℕ) : ℤ :=
  ∑ s ∈ Finset.range 16, if s = 0 then 0 else
    (((if s % 2 = 1 then a else 0) + (if s / 2 % 2 = 1 then b else 0)
      + (if s / 4 % 2 = 1 then c else 0) + (if s / 8 % 2 = 1 then d else 0)) % 6 + 1 : ℕ)
example : 2 ^ 4 - 1 = 15 := by decide
-- Listing all 1,296 outcomes: the sum of (2T - 105)² is 226,800, so the average of the 15 faces
-- has variance 226800/(900 · 1296) = 7/36 = (35/12)/15, as for 15 uncorrelated draws.
example : (∑ a ∈ Finset.range 6, ∑ b ∈ Finset.range 6, ∑ c ∈ Finset.range 6,
    ∑ d ∈ Finset.range 6, (2 * fifteenFaceTotal a b c d - 105) ^ 2) = 226800 := by decide
example : (226800 : ℚ) / (900 * 1296) = 7 / 36 := by norm_num
-- Faces 1, 2 and "1 plus 2" all show 1 on 36 of the 1,296 outcomes: chance 1/36, not 1/216.
example : (∑ a ∈ Finset.range 6, ∑ b ∈ Finset.range 6, ∑ _c ∈ Finset.range 6,
    ∑ _d ∈ Finset.range 6, if a = 0 ∧ b = 0 ∧ (a + b) % 6 = 0 then 1 else 0) = 36 := by decide
example : (36 / 1296 : ℚ) = 1 / 36 ∧ (1 / 36 : ℚ) ≠ 1 / 216 := by norm_num
-- Every roll a copy of the first: every face misses 7/2 by at least 1/10, that is |10f - 35| ≥ 1.
example : ∀ f ∈ Finset.Icc (1 : ℤ) 6, 1 ≤ |10 * f - 35| := by decide
-- 1 - δ for δ: N = ⌈(875/3)/(99/100)⌉ = 295, where Chebyshev only gives 175/177.
example : ⌈(875 / 3 : ℚ) / (99 / 100)⌉₊ = 295 := by
  rw [Nat.ceil_eq_iff (by norm_num)]; norm_num
example : (875 / 3 : ℚ) / 295 = 175 / 177 := by norm_num
-- Pareto with P(X > x) = x^(-3/2): the cut mean misses by 3/√n, which is 1/4 at n = 144.
example : (3 : ℚ) / 12 = 1 / 4 ∧ (12 : ℕ) ^ 2 = 144 := by norm_num

#print axioms weak_law_of_uncorrelated_draws
#print axioms weak_law_explicit_count
#print axioms weak_law_of_finite_mean
