-- Maximum likelihood: for a yes-or-no poll the share of yeses k/n is the unique top of the likelihood p^k (1-p)^(n-k) on [0, 1], for a normal model the average and Q/n are the unique top when Q > 0, and when Q = 0 the normal likelihood has no top.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Tactic.NormNum

open ProbabilityTheory NNReal

lemma log_prod_gaussianPDFReal (n : ℕ) (x : Fin n → ℝ) (μ : ℝ) (v : ℝ≥0) (hv : v ≠ 0) :
    Real.log (∏ i, gaussianPDFReal μ v (x i)) =
      -((n : ℝ) / 2) * Real.log (2 * Real.pi * v) - (∑ i, (x i - μ) ^ 2) / (2 * v) := by
  have hv' : (0 : ℝ) < v := by positivity
  rw [Real.log_prod (fun i _ => (gaussianPDFReal_pos μ v (x i) hv).ne')]
  have : ∀ i, Real.log (gaussianPDFReal μ v (x i)) =
      -(1 / 2) * Real.log (2 * Real.pi * v) - (x i - μ) ^ 2 / (2 * v) := by
    intro i
    rw [gaussianPDFReal, Real.log_mul (by positivity) (Real.exp_pos _).ne', Real.log_inv,
      Real.log_exp, Real.log_sqrt (by positivity)]
    ring
  simp_rw [this]
  rw [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
    nsmul_eq_mul, Finset.sum_div]
  ring

#print axioms log_prod_gaussianPDFReal

lemma sum_sq_sub_eq (n : ℕ) (hn : 0 < n) (x : Fin n → ℝ) (μ : ℝ) :
    ∑ i, (x i - μ) ^ 2 =
      ∑ i, (x i - (∑ j, x j) / n) ^ 2 + n * ((∑ j, x j) / n - μ) ^ 2 := by
  have hn' : (n : ℝ) ≠ 0 := by positivity
  set m := (∑ j, x j) / n with hm
  have hs : ∑ j, x j = n * m := by rw [hm]; field_simp
  have : ∀ i, (x i - μ) ^ 2 = (x i - m) ^ 2 + 2 * (m - μ) * x i + (μ ^ 2 - m ^ 2) := by
    intro i; ring
  simp_rw [this]
  rw [Finset.sum_add_distrib, Finset.sum_add_distrib, ← Finset.mul_sum, hs, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  ring

#print axioms sum_sq_sub_eq

/-- The poll. With k yeses out of n calls (n at least 1), the likelihood of a candidate share p
is p^k (1 - p)^(n - k). The share of yeses, k/n, is an allowed share (between 0 and 1), and every
other allowed share gives the record a strictly smaller likelihood: k/n is the one highest point.
This includes the edge case k = 0, where the top is p = 0. -/
theorem binomial_likelihood_max_at_share (n k : ℕ) (hn : 0 < n) (hk : k ≤ n) :
    (k / n : ℝ) ∈ Set.Icc (0 : ℝ) 1 ∧
      ∀ p ∈ Set.Icc (0 : ℝ) 1, p ≠ (k / n : ℝ) →
        p ^ k * (1 - p) ^ (n - k) < (k / n : ℝ) ^ k * (1 - (k / n : ℝ)) ^ (n - k) := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hkn : (k : ℝ) ≤ n := by exact_mod_cast hk
  refine ⟨⟨by positivity, (div_le_one hn').2 hkn⟩, ?_⟩
  rintro p ⟨hp0, hp1⟩ hne
  rcases Nat.eq_zero_or_pos k with rfl | hk0
  · simp only [pow_zero, Nat.cast_zero, zero_div, sub_zero, Nat.sub_zero, one_mul, one_pow] at hne ⊢
    have : 0 < p := lt_of_le_of_ne hp0 (Ne.symm hne)
    exact pow_lt_one₀ (by linarith) (by linarith) hn.ne'
  rcases eq_or_lt_of_le hk with rfl | hkn'
  · simp only [Nat.sub_self, pow_zero, mul_one, div_self hn'.ne', one_pow] at hne ⊢
    exact pow_lt_one₀ hp0 (lt_of_le_of_ne hp1 hne) hn.ne'
  have hk0' : (0 : ℝ) < k := by exact_mod_cast hk0
  have hkn'' : (k : ℝ) < n := by exact_mod_cast hkn'
  have ha0 : 0 < (k / n : ℝ) := by positivity
  have hb0 : 0 < 1 - (k / n : ℝ) := by
    have : (k / n : ℝ) < 1 := (div_lt_one hn').2 hkn''
    linarith
  have hnk : n - k ≠ 0 := by omega
  have hRHS : 0 < (k / n : ℝ) ^ k * (1 - (k / n : ℝ)) ^ (n - k) := by positivity
  rcases eq_or_lt_of_le hp0 with rfl | hp0'
  · simpa [zero_pow hk0.ne'] using hRHS
  rcases eq_or_lt_of_le hp1 with rfl | hp1'
  · simpa [zero_pow hnk] using hRHS
  have hq0 : 0 < 1 - p := by linarith
  rw [← Real.log_lt_log_iff (by positivity) hRHS, Real.log_mul (by positivity) (by positivity),
    Real.log_mul (by positivity) (by positivity), Real.log_pow, Real.log_pow, Real.log_pow,
    Real.log_pow, Nat.cast_sub hk]
  set a : ℝ := k / n with ha
  have h1 : Real.log (p / a) < p / a - 1 :=
    Real.log_lt_sub_one_of_pos (by positivity) (by
      intro h; apply hne; field_simp at h; linarith)
  have h2 : Real.log ((1 - p) / (1 - a)) ≤ (1 - p) / (1 - a) - 1 :=
    Real.log_le_sub_one_of_pos (by positivity)
  rw [Real.log_div hp0'.ne' ha0.ne'] at h1
  rw [Real.log_div hq0.ne' hb0.ne'] at h2
  have hnk' : (0 : ℝ) < n - k := by linarith
  have e : (k : ℝ) * (p / a - 1) + (n - k) * ((1 - p) / (1 - a) - 1) = 0 := by
    rw [ha]
    have : (1 : ℝ) - k / n = (n - k) / n := by field_simp
    rw [this]
    field_simp
    ring
  nlinarith [mul_lt_mul_of_pos_left h1 hk0', mul_le_mul_of_nonneg_left h2 hnk'.le]

/-- The normal model. For n measurements x_i with average x̄ and total squared gap
Q = Σ (x_i - x̄)^2 greater than 0, the likelihood of a centre μ and a variance v > 0 is the
product of the normal density heights at the data. The pair (x̄, Q/n) gives the largest
likelihood, and every other allowed pair gives a strictly smaller one. -/
theorem normal_likelihood_max_at_mean_and_Q_over_n (n : ℕ) (x : Fin n → ℝ)
    (hQ : 0 < ∑ i, (x i - (∑ j, x j) / n) ^ 2) :
    Real.toNNReal ((∑ i, (x i - (∑ j, x j) / n) ^ 2) / n) ≠ 0 ∧
      ∀ (μ : ℝ) (v : ℝ≥0), v ≠ 0 →
        (μ ≠ (∑ j, x j) / n ∨ v ≠ Real.toNNReal ((∑ i, (x i - (∑ j, x j) / n) ^ 2) / n)) →
          ∏ i, gaussianPDFReal μ v (x i) <
            ∏ i, gaussianPDFReal ((∑ j, x j) / n)
              (Real.toNNReal ((∑ i, (x i - (∑ j, x j) / n) ^ 2) / n)) (x i) := by
  have hn : 0 < n := by
    rcases Nat.eq_zero_or_pos n with rfl | h
    · simp at hQ
    · exact h
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  set m := (∑ j, x j) / n with hm
  set Q := ∑ i, (x i - m) ^ 2 with hQdef
  have hv0pos : 0 < Q / n := by positivity
  have hv0ne : Real.toNNReal (Q / n) ≠ 0 := by
    simpa [Real.toNNReal_eq_zero, not_le] using hv0pos
  refine ⟨hv0ne, ?_⟩
  intro μ v hv hne
  have hvc : ((Real.toNNReal (Q / n) : ℝ≥0) : ℝ) = Q / n := Real.coe_toNNReal _ hv0pos.le
  have hv' : (0 : ℝ) < v := by positivity
  rw [← Real.log_lt_log_iff (Finset.prod_pos fun i _ => gaussianPDFReal_pos _ _ _ hv)
    (Finset.prod_pos fun i _ => gaussianPDFReal_pos _ _ _ hv0ne),
    log_prod_gaussianPDFReal n x μ v hv, log_prod_gaussianPDFReal n x m _ hv0ne, hvc,
    sum_sq_sub_eq n hn x μ, ← hm, ← hQdef]
  have h2pi : (0 : ℝ) < 2 * Real.pi := by positivity
  rw [Real.log_mul h2pi.ne' hv'.ne', Real.log_mul h2pi.ne' hv0pos.ne']
  -- reduce to log (Q/n / v) ≤ Q/n / v - 1
  have key : Real.log (Q / n / v) ≤ Q / n / v - 1 := Real.log_le_sub_one_of_pos (by positivity)
  rw [Real.log_div hv0pos.ne' hv'.ne'] at key
  have hd : 0 ≤ (m - μ) ^ 2 := sq_nonneg _
  have hQn : Q / (2 * (Q / n)) = n / 2 := by field_simp
  rw [hQn]
  have e1 : (Q + n * (m - μ) ^ 2) / (2 * v) = (n / 2) * (Q / n / v) + n * (m - μ) ^ 2 / (2 * v) := by
    field_simp
  rw [e1]
  rcases hne with hμ | hvne
  · have hd' : 0 < (m - μ) ^ 2 := by
      have : m - μ ≠ 0 := sub_ne_zero.2 (Ne.symm hμ)
      positivity
    have : 0 < n * (m - μ) ^ 2 / (2 * v) := by positivity
    nlinarith [mul_le_mul_of_nonneg_left key (by positivity : (0 : ℝ) ≤ n / 2)]
  · have hvne' : (v : ℝ) ≠ Q / n := by
      intro h; apply hvne; rw [← h, Real.toNNReal_coe]
    have key' : Real.log (Q / n / v) < Q / n / v - 1 :=
      Real.log_lt_sub_one_of_pos (by positivity) (by
        intro h; apply hvne'; exact ((div_eq_one_iff_eq hv'.ne').1 h).symm)
    rw [Real.log_div hv0pos.ne' hv'.ne'] at key'
    have : 0 ≤ n * (m - μ) ^ 2 / (2 * v) := by positivity
    nlinarith [mul_lt_mul_of_pos_left key' (by positivity : (0 : ℝ) < n / 2)]

/-- When the likelihood is unbounded there is no estimate. If n ≥ 1 measurements have total
squared gap Q = 0 (they are all equal), then every allowed pair (μ, v) with v > 0 is beaten by
another allowed pair: the normal likelihood has no highest point. -/
theorem normal_likelihood_no_max_when_Q_zero (n : ℕ) (hn : 0 < n) (x : Fin n → ℝ)
    (hQ : ∑ i, (x i - (∑ j, x j) / n) ^ 2 = 0) :
    ∀ (μ : ℝ) (v : ℝ≥0), v ≠ 0 →
      ∃ (μ' : ℝ) (v' : ℝ≥0), v' ≠ 0 ∧
        ∏ i, gaussianPDFReal μ v (x i) < ∏ i, gaussianPDFReal μ' v' (x i) := by
  intro μ v hv
  set m := (∑ j, x j) / n with hm
  have hx : ∀ i, x i = m := by
    intro i
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => sq_nonneg (x i - m))).1 hQ i
      (Finset.mem_univ i)
    have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 this
    linarith
  refine ⟨m, v / 2, by simpa using hv, ?_⟩
  have hv' : (0 : ℝ) < v := by positivity
  have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
  refine Finset.prod_lt_prod_of_nonempty₀ (fun i _ => gaussianPDFReal_pos _ _ _ hv) ?_
    Finset.univ_nonempty
  intro i _
  rw [hx i, gaussianPDFReal, gaussianPDFReal]
  simp only [sub_self, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, neg_zero,
    zero_div, Real.exp_zero, mul_one, NNReal.coe_div, NNReal.coe_ofNat]
  calc (√(2 * Real.pi * v))⁻¹ * Real.exp (-(m - μ) ^ 2 / (2 * v))
      ≤ (√(2 * Real.pi * v))⁻¹ * 1 := by
        gcongr
        rw [Real.exp_le_one_iff]
        apply div_nonpos_of_nonpos_of_nonneg
        · nlinarith [sq_nonneg (m - μ)]
        · positivity
    _ < (√(2 * Real.pi * (v / 2)))⁻¹ := by
        rw [mul_one]
        apply inv_strictAnti₀ (by positivity)
        apply Real.sqrt_lt_sqrt (by positivity)
        nlinarith [Real.pi_pos]

-- The poll: 520 yeses in 1,000 calls; the share is 0.52 = 13/25.
example : ((520 : ℚ) / 1000) = 13 / 25 := by norm_num
-- Setting the slope to zero: 520 (1 - p) = 480 p at p = 13/25, that is 1000 p = 520.
example : (520 : ℚ) * (1 - 13 / 25) = 480 * (13 / 25) := by norm_num
example : (1000 : ℚ) * (13 / 25) = 520 := by norm_num
-- Curvature at the peak: 520/0.52^2 + 480/0.48^2 = 1000/(0.52 * 0.48), about 4,006.
example : (520 : ℚ) / (13 / 25) ^ 2 + 480 / (12 / 25) ^ 2 = 1000 / ((13 / 25) * (12 / 25)) := by
  norm_num
example : (4006 : ℚ) < 1000 / ((13 / 25) * (12 / 25)) ∧
    1000 / ((13 / 25) * (12 / 25)) < 4007 := by norm_num
-- The edge poll: 0 yeses in 20 calls; the share is 0, and the likelihood there is (1 - 0)^20 = 1.
example : ((0 : ℚ) / 20) = 0 := by norm_num
example : ((1 : ℚ) - 0) ^ 20 = 1 := by norm_num
-- Five earlier polls: 0.49, 0.51, 0.52, 0.54, 0.54. Average 0.52, Q = 0.0018, Q/n = 0.00036.
example : ((49 : ℚ) / 100 + 51 / 100 + 52 / 100 + 54 / 100 + 54 / 100) / 5 = 13 / 25 := by norm_num
example : ((49 : ℚ) / 100 - 52 / 100) ^ 2 + (51 / 100 - 52 / 100) ^ 2 + (52 / 100 - 52 / 100) ^ 2
    + (54 / 100 - 52 / 100) ^ 2 + (54 / 100 - 52 / 100) ^ 2 = 18 / 10000 := by norm_num
example : ((18 : ℚ) / 10000) / 5 = 36 / 100000 := by norm_num
-- The unbiased variance divides by n - 1 instead: 0.0018 / 4 = 0.00045.
example : ((18 : ℚ) / 10000) / 4 = 45 / 100000 := by norm_num

#print axioms binomial_likelihood_max_at_share
#print axioms normal_likelihood_max_at_mean_and_Q_over_n
#print axioms normal_likelihood_no_max_when_Q_zero
