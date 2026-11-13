-- Concentration: for independent readings with known ranges, the average overshoots its mean by ε with chance at most exp(-2n²ε² / Σ(bᵢ - aᵢ)²) (Hoeffding), a count of n independent coin flips reaches a share c above p with chance at most exp(-n D(c‖p)) (Chernoff), and both rest on Hoeffding's lemma E[e^{t(X - μ)}] ≤ e^{t²(b - a)²/8}.
import Mathlib.Probability.Moments.SubGaussian
import Mathlib.Data.Nat.Choose.Sum

open MeasureTheory ProbabilityTheory Real

/-- **Hoeffding's inequality.** Let `X 0, …, X (n-1)` be independent random readings, each
trapped in its own known range `a i ≤ X i ≤ b i`, and let `μ` be the average of their means.
Then for every gap `ε > 0`, the chance that the average of the readings is at least `ε` above
`μ` is at most `exp (-(2 n² ε²) / Σ (b i - a i)²)`. -/
theorem hoeffding_inequality {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (n : ℕ) (X : Fin n → Ω → ℝ) (a b : Fin n → ℝ)
    (hmeas : ∀ i, AEMeasurable (X i) P)
    (hind : iIndepFun X P)
    (hrange : ∀ i, ∀ᵐ ω ∂P, X i ω ∈ Set.Icc (a i) (b i))
    (ε : ℝ) (hε : 0 < ε) :
    P.real {ω | ε ≤ (∑ i, X i ω) / n - (∑ i, ∫ ω', X i ω' ∂P) / n} ≤
      exp (-(2 * (n : ℝ) ^ 2 * ε ^ 2) / ∑ i, (b i - a i) ^ 2) := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    have : {ω : Ω | ε ≤ (∑ i : Fin 0, X i ω) / (0:ℕ) - (∑ i : Fin 0, ∫ ω', X i ω' ∂P) / (0:ℕ)} = ∅ := by
      ext ω; simp [hε.not_ge]
    rw [this]; simp
  set Y : Fin n → Ω → ℝ := fun i ω => X i ω - ∫ ω', X i ω' ∂P with hY
  have hYind : iIndepFun Y P :=
    hind.comp (fun i x => x - ∫ ω', X i ω' ∂P) (fun i => by fun_prop)
  have hsub : ∀ i ∈ (Finset.univ : Finset (Fin n)),
      HasSubgaussianMGF (Y i) ((‖b i - a i‖₊ / 2) ^ 2) P :=
    fun i _ => hasSubgaussianMGF_of_mem_Icc (hmeas i) (hrange i)
  have hnpos : (0:ℝ) < n := by exact_mod_cast hn
  have key := HasSubgaussianMGF.measure_sum_ge_le_of_iIndepFun hYind hsub
    (ε := n * ε) (by positivity)
  have hset : {ω | ε ≤ (∑ i, X i ω) / n - (∑ i, ∫ ω', X i ω' ∂P) / n}
      = {ω | (n:ℝ) * ε ≤ ∑ i, Y i ω} := by
    ext ω
    simp only [Set.mem_ofPred_eq, hY, Finset.sum_sub_distrib]
    rw [← sub_div, le_div_iff₀ hnpos, mul_comm]
  rw [hset]
  refine key.trans_eq ?_
  congr 1
  push_cast
  simp only [Real.norm_eq_abs, div_pow, sq_abs]
  rw [← Finset.sum_div]
  field_simp

/-- **The Chernoff bound for a binomial count.** Let `X 0, …, X (n-1)` be independent coin
flips, each scored 1 for heads and 0 for tails, each heads with the same chance `p`. For a cut
`c` above `p`, the chance that the share of heads reaches `c` is at most `exp (-n D(c‖p))`,
where `D(c‖p) = c ln (c/p) + (1 - c) ln ((1 - c)/(1 - p))` is the relative entropy between a
coin with chance `c` and the real coin. -/
theorem chernoff_bound_binomial {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (n : ℕ) (X : Fin n → Ω → ℝ) (p c : ℝ)
    (hmeas : ∀ i, AEMeasurable (X i) P)
    (hind : iIndepFun X P)
    (hcoin : ∀ i, ∀ᵐ ω ∂P, X i ω = 0 ∨ X i ω = 1)
    (hp : ∀ i, P.real {ω | X i ω = 1} = p)
    (hc : p < c) :
    P.real {ω | c ≤ (∑ i, X i ω) / n} ≤
      exp (-(n * (c * log (c / p) + (1 - c) * log ((1 - c) / (1 - p))))) := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    simp only [CharP.cast_eq_zero, zero_mul, neg_zero, exp_zero]
    exact measureReal_le_one
  have hnpos : (0:ℝ) < n := by exact_mod_cast hn
  have hp0 : 0 ≤ p := by rw [← hp ⟨0, hn⟩]; exact measureReal_nonneg
  have hp1 : p ≤ 1 := by rw [← hp ⟨0, hn⟩]; exact measureReal_le_one
  -- the sum lies in [0, n] almost surely
  have hall : ∀ᵐ ω ∂P, ∀ i, X i ω = 0 ∨ X i ω = 1 := ae_all_iff.2 hcoin
  have hSrange : ∀ᵐ ω ∂P, (∑ i, X i) ω ∈ Set.Icc (0:ℝ) n := by
    filter_upwards [hall] with ω hω
    have h01 : ∀ i, 0 ≤ X i ω ∧ X i ω ≤ 1 := fun i => by
      rcases hω i with h | h <;> simp [h]
    rw [Finset.sum_apply]
    constructor
    · exact Finset.sum_nonneg fun i _ => (h01 i).1
    · calc ∑ i, X i ω ≤ ∑ _i : Fin n, (1:ℝ) := Finset.sum_le_sum fun i _ => (h01 i).2
        _ = n := by simp
  have hSmeas : AEMeasurable (∑ i, X i) P := Finset.aemeasurable_sum _ fun i _ => hmeas i
  -- the event, rewritten
  have hset : {ω | c ≤ (∑ i, X i ω) / n} = {ω | (n:ℝ) * c ≤ (∑ i, X i) ω} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Finset.sum_apply]
    rw [le_div_iff₀ hnpos, mul_comm]
  -- the moment generating function of one flip
  have hmgf : ∀ i t, mgf (X i) P t = 1 - p + p * exp t := by
    intro i t
    have hs : NullMeasurableSet {ω | X i ω = 1} P :=
      (hmeas i).nullMeasurable (measurableSet_singleton 1)
    have hae : (fun ω => exp (t * X i ω)) =ᵐ[P]
        fun ω => 1 + (exp t - 1) * Set.indicator {ω | X i ω = 1} (fun _ => (1:ℝ)) ω := by
      filter_upwards [hcoin i] with ω hω
      rcases hω with h | h <;> simp [Set.indicator, h]
    have hint : Integrable (Set.indicator {ω | X i ω = 1} (fun _ => (1:ℝ))) P :=
      (integrable_const (1:ℝ)).integrableOn.integrable_indicator₀ hs
    rw [mgf, integral_congr_ae hae, integral_add (integrable_const _) (hint.const_mul _),
      integral_const_mul, integral_indicator₀ hs, setIntegral_const, hp i]
    simp
    ring
  -- the exponential-moment bound
  have hbound : ∀ t, 0 ≤ t →
      P.real {ω | c ≤ (∑ i, X i ω) / n} ≤ exp (-t * (n * c)) * (1 - p + p * exp t) ^ n := by
    intro t ht
    rw [hset]
    have hint : Integrable (fun ω => exp (t * (∑ i, X i) ω)) P :=
      integrable_exp_mul_of_mem_Icc hSmeas hSrange
    refine (measure_ge_le_exp_mul_mgf _ ht hint).trans_eq ?_
    rw [hind.mgf_sum₀ hmeas]
    simp [hmgf]
  rcases lt_or_ge 1 c with hc1 | hc1
  · -- a cut above 1 cannot be reached
    have hnull : P {ω | c ≤ (∑ i, X i ω) / n} = 0 := by
      rw [hset]
      have h' : ∀ᵐ ω ∂P, (∑ i, X i) ω ≤ n := by
        filter_upwards [hSrange] with ω hω using hω.2
      rw [ae_iff] at h'
      refine measure_mono_null (fun ω hω => ?_) h'
      simp only [Set.mem_ofPred_eq, not_le] at hω ⊢
      nlinarith
    rw [Measure.real, hnull]
    simp only [ENNReal.toReal_zero]
    positivity
  rcases eq_or_lt_of_le hp0 with hp0' | hp0'
  · -- p = 0: the right side is at least 1
    subst hp0'
    have hlog : log (1 - c) ≤ 0 := Real.log_nonpos (by linarith) (by linarith)
    have hx : 0 ≤ -(n * (c * log (c / 0) + (1 - c) * log ((1 - c) / (1 - 0)))) := by
      simp only [div_zero, log_zero, mul_zero, zero_add, sub_zero, div_one]
      have : 0 ≤ (1 - c) := by linarith
      have : (1 - c) * log (1 - c) ≤ 0 := mul_nonpos_of_nonneg_of_nonpos this hlog
      nlinarith
    exact measureReal_le_one.trans (one_le_exp hx)
  have hpc1 : p < 1 := lt_of_lt_of_le hc hc1
  rcases eq_or_lt_of_le hc1 with hc1' | hc1'
  · -- c = 1: let the dial go to infinity
    subst hc1'
    have hrhs : exp (-(n * (1 * log (1 / p) + (1 - 1) * log ((1 - 1) / (1 - p))))) = p ^ n := by
      rw [one_div, log_inv, sub_self, zero_mul, add_zero, one_mul, neg_mul_eq_mul_neg, neg_neg,
        exp_nat_mul, exp_log hp0']
    rw [hrhs]
    have htend : Filter.Tendsto (fun t : ℝ => ((1 - p) * exp (-t) + p) ^ n) Filter.atTop
        (nhds (((1 - p) * 0 + p) ^ n)) :=
      ((tendsto_exp_neg_atTop_nhds_zero.const_mul (1 - p)).add_const p).pow n
    simp only [mul_zero, zero_add] at htend
    refine ge_of_tendsto htend ?_
    filter_upwards [Filter.eventually_ge_atTop (0:ℝ)] with t ht
    refine (hbound t ht).trans_eq ?_
    rw [mul_one, show -t * n = n * (-t) by ring, exp_nat_mul, ← mul_pow]
    congr 1
    rw [mul_add, mul_left_comm, ← exp_add]
    simp
    ring
  · -- 0 < p < c < 1: the best dial
    have h1c : 0 < 1 - c := by linarith
    have h1p : 0 < 1 - p := by linarith
    have hcpos : 0 < c := by linarith
    set r := c * (1 - p) / (p * (1 - c)) with hr
    have hr1 : 1 ≤ r := by
      rw [hr, one_le_div (by positivity)]
      nlinarith
    have hrpos : 0 < r := by linarith
    refine (hbound (log r) (log_nonneg hr1)).trans_eq ?_
    have hmid : 1 - p + p * exp (log r) = (1 - p) / (1 - c) := by
      rw [exp_log hrpos, hr]
      field_simp
      ring
    rw [hmid, ← exp_log (show 0 < (1 - p) / (1 - c) by positivity), ← exp_nat_mul, ← exp_add]
    congr 1
    rw [hr, log_div (by positivity) (by positivity), log_mul (by positivity) (by positivity),
      log_mul (by positivity) (by positivity), log_div (by positivity) (by positivity),
      log_div (by positivity) (by positivity), log_div (by positivity) (by positivity)]
    ring

/-- **Hoeffding's lemma.** If a random reading `X` always lies between `a` and `b`, then for
every dial `t`, the moment generating function of `X` measured from its mean is at most
`exp (t² (b - a)² / 8)`. -/
theorem hoeffding_lemma {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : Ω → ℝ) (a b : ℝ)
    (hmeas : AEMeasurable X P)
    (hrange : ∀ᵐ ω ∂P, X ω ∈ Set.Icc a b) (t : ℝ) :
    ∫ ω, exp (t * (X ω - ∫ ω', X ω' ∂P)) ∂P ≤ exp (t ^ 2 * (b - a) ^ 2 / 8) := by
  have h := (hasSubgaussianMGF_of_mem_Icc hmeas hrange).mgf_le t
  rw [mgf] at h
  refine h.trans_eq ?_
  congr 1
  push_cast
  rw [Real.norm_eq_abs, div_pow, sq_abs]
  ring

-- 1,000 fair flips, cut 0.55: the gap is 0.55 - 0.5 = 1/20.
example : (55 / 100 : ℚ) - 1 / 2 = 1 / 20 := by norm_num
-- The event "share at least 0.55" starts at 550 heads: the code's (11n + 19)/20 at n = 1000.
example : (11 * 1000 + 19) / 20 = 550 := by norm_num
-- Chebyshev: 0.25 / (1,000 × 0.05²) = 0.1.
example : (1 / 4 : ℚ) / (1000 * (1 / 20) ^ 2) = 1 / 10 := by norm_num
-- Hoeffding's exponent: 2 × 1,000 × 0.05² = 5, so the ceiling is e^-5.
example : (2 : ℚ) * 1000 * (1 / 20) ^ 2 = 5 := by norm_num
-- For ranges 0 to 1 the squared widths add to n, and Hoeffding's exponent 2n²ε²/n is 2nε².
example : (2 : ℚ) * 1000 ^ 2 * (1 / 20) ^ 2 / (1000 * (1 - 0) ^ 2) = 5 := by norm_num
-- Hoeffding's best dial 4nε/W with W = n is 4ε = 0.2.
example : (4 : ℚ) * 1000 * (1 / 20) / 1000 = 1 / 5 := by norm_num
-- Chernoff's best dial: e^t = 0.55 × 0.5 / (0.5 × 0.45) = 11/9.
example : (55 / 100 : ℚ) * (1 / 2) / ((1 / 2) * (45 / 100)) = 11 / 9 := by norm_num
-- At that dial 1 - p + p e^t = (1 - p)/(1 - c) = 10/9.
example : (1 : ℚ) - 1 / 2 + 1 / 2 * (11 / 9) = 10 / 9 := by norm_num
example : (1 - 1 / 2 : ℚ) / (1 - 55 / 100) = 10 / 9 := by norm_num
-- Chernoff's rate: c ln(c/p) + (1 - c) ln((1 - c)/(1 - p)) = 0.55 ln 1.1 + 0.45 ln 0.9.
example : (55 / 100 : ℚ) / (1 / 2) = 11 / 10 ∧ (1 - 55 / 100 : ℚ) / (1 - 1 / 2) = 9 / 10 := by
  norm_num
-- The method at dial 0.2: the discount e^(-t n c) is e^-110.
example : (1 / 5 : ℚ) * 1000 * (55 / 100) = 110 := by norm_num
-- Hoeffding's lemma for the fair coin at dial 0.2: the ceiling is e^(0.2² / 8) = e^(1/200).
example : (1 / 5 : ℚ) ^ 2 * (1 - 0) ^ 2 / 8 = 1 / 200 := by norm_num
-- Chernoff never worse than Hoeffding: D'' = 1/c + 1/(1 - c) = 1/(c(1 - c)) ≥ 4; at c = 0.55 it is 400/99.
example : (1 : ℚ) / (55 / 100) + 1 / (1 - 55 / 100) = 400 / 99 ∧ (4 : ℚ) ≤ 400 / 99 := by
  norm_num
-- The exact tail: Σ C(1000, k) / 2^1000 for k from 550 to 1,000 is 0.000865 (to six places).
example : 865 * 2 ^ 1000 ≤ 1000000 * (∑ k ∈ Finset.Icc 550 1000, Nat.choose 1000 k) := by
  decide +kernel
example : 1000000 * (∑ k ∈ Finset.Icc 550 1000, Nat.choose 1000 k) < 866 * 2 ^ 1000 := by
  decide +kernel
-- 99 percent sure: Chebyshev, both sides, asks for 0.25 / (0.01 × 0.05²) = 10,000 flips.
example : (1 / 4 : ℚ) / ((1 / 100) * (1 / 20) ^ 2) = 10000 := by norm_num
-- The die: Chebyshev, both sides, 1,000 rolls, ε = 0.1: (35/12)/(1000 × 0.01) = 7/24 = 0.2917.
example : (35 / 12 : ℚ) / (1000 * (1 / 10) ^ 2) = 7 / 24 := by norm_num
-- The die's range 1 to 6 would allow a variance of (6 - 1)²/4 = 6.25, above its true 35/12.
example : ((6 - 1 : ℚ)) ^ 2 / 4 = 25 / 4 ∧ (35 / 12 : ℚ) < 25 / 4 := by norm_num
-- The die: Hoeffding's exponent 2 × 1,000 × 0.1² / 5² = 4/5, so the two-sided ceiling is 2e^(-4/5).
example : (2 : ℚ) * 1000 * (1 / 10) ^ 2 / (6 - 1) ^ 2 = 4 / 5 := by norm_num
-- Score ±1 but keep the width at 1: the same event is a gap of 0.1, and the exponent reads 20.
example : (2 : ℚ) * 1000 * (1 / 10) ^ 2 = 20 := by norm_num

#print axioms hoeffding_inequality
#print axioms chernoff_bound_binomial
#print axioms hoeffding_lemma
