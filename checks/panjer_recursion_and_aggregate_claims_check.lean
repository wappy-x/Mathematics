-- Panjer's recursion: for a Poisson number of independent whole-unit claims, the chance that the total is k units equals λ/k times the sum over sizes j of j·q_j times the chance of a total of k − j, starting from exp(−λ(1 − q₀)), and the same short sum works for every count in the (a, b, 0) family.
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.Derivative

open PowerSeries Finset ProbabilityTheory
open scoped NNReal

/-- The aggregate claim distribution, defined as the card defines it: a sum over the claim count.
`r n` is the chance of `n` claims, `q j` the chance that one claim is `j` units, and the
coefficient of `z ^ k` in `(∑ q_j z^j) ^ n` is the chance that `n` independent claims total
exactly `k` units. So `aggregateDist r q k = ∑ₙ P(N = n) · P(n claims total k) = P(K = k)`. -/
noncomputable def aggregateDist (r q : ℕ → ℝ) (k : ℕ) : ℝ :=
  ∑' n : ℕ, r n * coeff k (mk q ^ n)

lemma panjer_coeff_succ (q : ℕ → ℝ) (n k : ℕ) :
    coeff k (mk q ^ (n + 1)) = ∑ j ∈ range (k + 1), q j * coeff (k - j) (mk q ^ n) := by
  rw [pow_succ', coeff_mul, Finset.Nat.sum_antidiagonal_eq_sum_range_succ
    (fun i j => coeff i (mk q) * coeff j (mk q ^ n))]
  simp [coeff_mk]

lemma panjer_coeff_deriv (q : ℕ → ℝ) (n k : ℕ) :
    ((k : ℝ) + 1) * coeff (k + 1) (mk q ^ (n + 1)) =
      ((n : ℝ) + 1) * ∑ j ∈ range (k + 2), (j : ℝ) * q j * coeff (k + 1 - j) (mk q ^ n) := by
  have h := congrArg (coeff k) (derivative_pow (mk q) (n + 1))
  rw [coeff_derivative] at h
  rw [mul_comm, h, Finset.sum_range_succ']
  rw [show ((n + 1 : ℕ) : ℝ⟦X⟧) = C ((n : ℝ) + 1) by simp, mul_assoc, coeff_C_mul,
    Nat.add_sub_cancel, mul_comm (mk q ^ n), coeff_mul, Finset.Nat.sum_antidiagonal_eq_sum_range_succ
    (fun i j => coeff i (d⁄dX (mk q)) * coeff j (mk q ^ n))]
  simp only [coeff_derivative, coeff_mk, Nat.add_sub_add_right]
  simp only [Nat.cast_add, Nat.cast_one, Nat.cast_zero, zero_mul, add_zero]
  congr 1
  refine Finset.sum_congr rfl (fun j _ => by ring)

lemma panjer_coeff_bound (q : ℕ → ℝ) (hq_nonneg : ∀ j, 0 ≤ q j)
    (hq_le : ∀ K, ∑ j ∈ range K, q j ≤ 1) (n k : ℕ) :
    0 ≤ coeff k (mk q ^ n) ∧ coeff k (mk q ^ n) ≤ 1 := by
  induction n generalizing k with
  | zero => simp only [pow_zero, coeff_one]; split_ifs <;> norm_num
  | succ n ih =>
    rw [panjer_coeff_succ]
    constructor
    · exact Finset.sum_nonneg (fun j _ => mul_nonneg (hq_nonneg j) (ih _).1)
    · calc ∑ j ∈ range (k + 1), q j * coeff (k - j) (mk q ^ n)
          ≤ ∑ j ∈ range (k + 1), q j := Finset.sum_le_sum (fun j _ =>
            mul_le_of_le_one_right (hq_nonneg j) (ih _).2)
        _ ≤ 1 := hq_le _

lemma panjer_q_le (q : ℕ → ℝ) (m : ℕ) (hq_nonneg : ∀ j, 0 ≤ q j)
    (hq_sum : ∑ j ∈ range (m + 1), q j = 1) (hq_max : ∀ j, m < j → q j = 0) (K : ℕ) :
    ∑ j ∈ range K, q j ≤ 1 := by
  calc ∑ j ∈ range K, q j ≤ ∑ j ∈ range (max K (m + 1)), q j :=
        Finset.sum_le_sum_of_subset_of_nonneg (range_subset_range.2 (le_max_left _ _))
          (fun j _ _ => hq_nonneg j)
    _ = ∑ j ∈ range (m + 1), q j := by
        symm
        refine Finset.sum_subset (range_subset_range.2 (le_max_right _ _)) ?_
        intro j _ hj
        simp only [mem_range, not_lt] at hj
        exact hq_max j (by omega)
    _ = 1 := hq_sum

lemma panjer_degenerate_r (r : ℕ → ℝ) (a b : ℝ)
    (hr_nonneg : ∀ n, 0 ≤ r n) (hr_sum : HasSum r 1)
    (hr_ab : ∀ n, 1 ≤ n → r n = (a + b / n) * r (n - 1)) (ha : 1 < a) :
    ∀ n, 1 ≤ n → r n = 0 := by
  obtain ⟨N, hN1, hN⟩ : ∃ N : ℕ, 1 ≤ N ∧ ∀ n : ℕ, N ≤ n → 1 ≤ a + b / n := by
    refine ⟨⌈|b| / (a - 1)⌉₊ + 1, by omega, fun n hn => ?_⟩
    have hc := Nat.le_ceil (|b| / (a - 1))
    have hn' : ((⌈|b| / (a - 1)⌉₊ + 1 : ℕ) : ℝ) ≤ n := Nat.cast_le.2 hn
    push_cast at hn'
    have hlt : |b| / (a - 1) < n := by linarith
    rw [div_lt_iff₀ (by linarith)] at hlt
    have hnpos : (0 : ℝ) < n := by
      have := abs_nonneg b
      nlinarith
    have : a + b / n - 1 = ((a - 1) * n + b) / n := by field_simp; ring
    have h2 : 0 ≤ ((a - 1) * n + b) / n := by
      apply div_nonneg _ hnpos.le
      nlinarith [neg_abs_le b]
    linarith
  have mono : ∀ M, N ≤ M → ∀ n, M ≤ n → r M ≤ r n := by
    intro M hM n hn
    induction n, hn using Nat.le_induction with
    | base => exact le_refl _
    | succ n hn ih =>
      rw [hr_ab (n + 1) (by omega)]
      simp only [Nat.add_sub_cancel]
      have := hN (n + 1) (by omega)
      nlinarith [hr_nonneg n]
  have htend := hr_sum.summable.tendsto_atTop_zero
  have hzero : ∀ M, N ≤ M → r M = 0 := fun M hM =>
    le_antisymm (ge_of_tendsto htend (Filter.eventually_atTop.2 ⟨M, mono M hM⟩)) (hr_nonneg M)
  have back : ∀ d n, n + d = N → 1 ≤ n → r n = 0 := by
    intro d
    induction d with
    | zero => intro n hn _; exact hzero n (by omega)
    | succ d ih =>
      intro n hn h1
      have h2 : r (n + 1) = 0 := ih (n + 1) (by omega) (by omega)
      obtain ⟨n', rfl⟩ : ∃ n', n = n' + 1 := ⟨n - 1, by omega⟩
      have e := hr_ab (n' + 2) (by omega)
      rw [h2, show n' + 2 - 1 = n' + 1 by omega] at e
      rcases mul_eq_zero.1 e.symm with h | h
      · push_cast at h
        have hpos : (0 : ℝ) < (n' : ℝ) + 2 := by positivity
        have hb : b = -a * ((n' : ℝ) + 2) := by
          field_simp at h
          linarith
        have e' := hr_ab (n' + 1) (by omega)
        rw [Nat.add_sub_cancel] at e'
        have hx : a + b / ((n' + 1 : ℕ) : ℝ) = -a / ((n' : ℝ) + 1) := by
          rw [hb]; push_cast; field_simp; ring
        rw [hx] at e'
        have : -a / ((n' : ℝ) + 1) * r n' ≤ 0 :=
          mul_nonpos_of_nonpos_of_nonneg (div_nonpos_of_nonpos_of_nonneg (by linarith)
            (by positivity)) (hr_nonneg n')
        linarith [hr_nonneg (n' + 1)]
      · exact h
  intro n hn
  by_cases h : n ≤ N
  · exact back (N - n) n (by omega) hn
  · exact hzero n (by omega)

lemma panjer_identity (r : ℕ → ℝ) (a b : ℝ)
    (hr_nonneg : ∀ n, 0 ≤ r n) (hr_sum : HasSum r 1)
    (hr_ab : ∀ n, 1 ≤ n → r n = (a + b / n) * r (n - 1))
    (q : ℕ → ℝ) (hq_nonneg : ∀ j, 0 ≤ q j) (hq_le : ∀ K, ∑ j ∈ range K, q j ≤ 1)
    (k : ℕ) (hk : 1 ≤ k) :
    aggregateDist r q k =
      ∑ j ∈ range (k + 1), (a * q j * aggregateDist r q (k - j) +
        b / k * ((j : ℝ) * q j) * aggregateDist r q (k - j)) := by
  have hs : ∀ i, Summable (fun n => r n * coeff i (mk q ^ n)) := fun i =>
    Summable.of_nonneg_of_le
      (fun n => mul_nonneg (hr_nonneg n) (panjer_coeff_bound q hq_nonneg hq_le n i).1)
      (fun n => mul_le_of_le_one_right (hr_nonneg n) (panjer_coeff_bound q hq_nonneg hq_le n i).2)
      hr_sum.summable
  have h1 : HasSum (fun n => r (n + 1) * coeff k (mk q ^ (n + 1))) (aggregateDist r q k) := by
    have := (hasSum_nat_add_iff' 1).2 (hs k).hasSum
    convert this using 1
    simp [aggregateDist, coeff_one, show k ≠ 0 by omega]
  have A : HasSum (fun n => ∑ j ∈ range (k + 1), a * q j * (r n * coeff (k - j) (mk q ^ n)))
      (∑ j ∈ range (k + 1), a * q j * aggregateDist r q (k - j)) :=
    hasSum_sum (fun j _ => ((hs (k - j)).hasSum).mul_left (a * q j))
  have B : HasSum (fun n => ∑ j ∈ range (k + 1),
        b / k * ((j : ℝ) * q j) * (r n * coeff (k - j) (mk q ^ n)))
      (∑ j ∈ range (k + 1), b / k * ((j : ℝ) * q j) * aggregateDist r q (k - j)) :=
    hasSum_sum (fun j _ => ((hs (k - j)).hasSum).mul_left (b / k * ((j : ℝ) * q j)))
  have h2 := A.add B
  rw [← Finset.sum_add_distrib] at h2
  refine h1.unique (h2.congr_fun ?_)
  intro n
  obtain ⟨k', rfl⟩ : ∃ k', k = k' + 1 := ⟨k - 1, by omega⟩
  rw [hr_ab (n + 1) (by omega), Nat.add_sub_cancel]
  have hc := panjer_coeff_succ q n (k' + 1)
  have hd := panjer_coeff_deriv q n k'
  have e1 : ∑ j ∈ range (k' + 1 + 1), a * q j * (r n * coeff (k' + 1 - j) (mk q ^ n)) +
      ∑ j ∈ range (k' + 1 + 1),
        b / ((k' + 1 : ℕ) : ℝ) * ((j : ℝ) * q j) * (r n * coeff (k' + 1 - j) (mk q ^ n)) =
      a * r n * ∑ j ∈ range (k' + 1 + 1), q j * coeff (k' + 1 - j) (mk q ^ n) +
      b / ((k' + 1 : ℕ) : ℝ) * r n *
        ∑ j ∈ range (k' + 2), (j : ℝ) * q j * coeff (k' + 1 - j) (mk q ^ n) := by
    rw [Finset.mul_sum, Finset.mul_sum]
    congr 1 <;> exact Finset.sum_congr rfl (fun j _ => by ring)
  rw [e1, ← hc]
  push_cast
  have hk0 : (0 : ℝ) < (k' : ℝ) + 1 := by positivity
  have hn0 : (0 : ℝ) < (n : ℝ) + 1 := by positivity
  field_simp
  linear_combination (b * r n) * hd


lemma panjer_ab0_aux (r : ℕ → ℝ) (a b : ℝ)
    (hr_nonneg : ∀ n, 0 ≤ r n) (hr_sum : HasSum r 1)
    (hr_ab : ∀ n, 1 ≤ n → r n = (a + b / n) * r (n - 1))
    (q : ℕ → ℝ) (m : ℕ)
    (hq_nonneg : ∀ j, 0 ≤ q j) (hq_sum : ∑ j ∈ range (m + 1), q j = 1)
    (hq_max : ∀ j, m < j → q j = 0) (k : ℕ) (hk : 1 ≤ k) :
    aggregateDist r q k =
      1 / (1 - a * q 0) * ∑ j ∈ Icc 1 (min k m),
        (a + b * j / k) * q j * aggregateDist r q (k - j) := by
  have hq_le := panjer_q_le q m hq_nonneg hq_sum hq_max
  have hid := panjer_identity r a b hr_nonneg hr_sum hr_ab q hq_nonneg hq_le k hk
  rw [← Finset.sum_subset (s₁ := insert 0 (Icc 1 (min k m))) (s₂ := range (k + 1))
      (by intro j hj; simp only [mem_insert, mem_Icc, mem_range] at hj ⊢; omega)
      (by
        intro j hj hj'
        simp only [mem_insert, mem_Icc, mem_range, not_or, not_and, not_le] at hj hj'
        have : q j = 0 := hq_max j (by omega)
        simp [this]),
    Finset.sum_insert (by simp)] at hid
  simp only [Nat.cast_zero, zero_mul, mul_zero, add_zero, Nat.sub_zero] at hid
  have hT : ∑ x ∈ Icc 1 (min k m), (a * q x * aggregateDist r q (k - x) +
      b / k * ((x : ℝ) * q x) * aggregateDist r q (k - x)) =
      ∑ j ∈ Icc 1 (min k m), (a + b * j / k) * q j * aggregateDist r q (k - j) :=
    Finset.sum_congr rfl (fun j _ => by ring)
  rw [hT] at hid
  by_cases h : 1 - a * q 0 = 0
  · rw [h, div_zero, zero_mul]
    have hq0le : q 0 ≤ 1 := by simpa using hq_le 1
    by_cases hq0 : q 0 = 1
    · have hqj : ∀ j, 1 ≤ j → q j = 0 := by
        intro j hj
        by_cases hjm : m < j
        · exact hq_max j hjm
        · rw [Finset.sum_range_succ', hq0] at hq_sum
          have h0 : ∑ i ∈ range m, q (i + 1) = 0 := by linarith
          rw [Finset.sum_eq_zero_iff_of_nonneg (fun i _ => hq_nonneg (i + 1))] at h0
          obtain ⟨i, rfl⟩ : ∃ i, j = i + 1 := ⟨j - 1, by omega⟩
          exact h0 i (by simp; omega)
      have hQ : mk q = 1 := by
        ext j
        rw [coeff_mk, coeff_one]
        split_ifs with hj
        · subst hj; exact hq0
        · exact hqj j (by omega)
      simp [aggregateDist, hQ, coeff_one, show k ≠ 0 by omega]
    · have ha : 1 < a := by
        by_contra hcon
        rw [not_lt] at hcon
        nlinarith [mul_nonneg (sub_nonneg.2 hcon) (hq_nonneg 0), lt_of_le_of_ne hq0le hq0]
      have hr0 := panjer_degenerate_r r a b hr_nonneg hr_sum hr_ab ha
      have hfun : (fun n => r n * coeff k (mk q ^ n)) = fun _ => 0 := by
        funext n
        rcases n with _ | n
        · simp [coeff_one, show k ≠ 0 by omega]
        · simp [hr0 (n + 1) (by omega)]
      simp only [aggregateDist, hfun, tsum_zero]
  · rw [div_mul_eq_mul_div, one_mul, eq_div_iff h]
    linarith

#print axioms panjer_coeff_succ
#print axioms panjer_coeff_deriv
#print axioms panjer_coeff_bound
#print axioms panjer_q_le
#print axioms panjer_degenerate_r
#print axioms panjer_identity
#print axioms panjer_ab0_aux

/-- Panjer's recursion, Poisson case. Let the claim count be Poisson with mean `λ`, and let each
claim, independently, be `j` grid units with chance `q j`, the largest possible size being `m`
units. Then for every total `k ≥ 1`, the chance that the year's total is exactly `k` units is
`p_k = (λ / k) · ∑_{j=1}^{min(k, m)} j · q_j · p_{k-j}`. -/
theorem panjer_recursion_poisson (lam : ℝ≥0) (q : ℕ → ℝ) (m : ℕ)
    (hq_nonneg : ∀ j, 0 ≤ q j) (hq_sum : ∑ j ∈ range (m + 1), q j = 1)
    (hq_max : ∀ j, m < j → q j = 0) (k : ℕ) (hk : 1 ≤ k) :
    aggregateDist (fun n => (poissonMeasure lam).real {n}) q k =
      (lam : ℝ) / k * ∑ j ∈ Icc 1 (min k m),
        (j : ℝ) * q j * aggregateDist (fun n => (poissonMeasure lam).real {n}) q (k - j) := by
  have hr : (fun n => (poissonMeasure lam).real {n}) =
      fun n => Real.exp (-(lam : ℝ)) * (lam : ℝ) ^ n / (n.factorial : ℝ) :=
    funext (poissonMeasure_real_singleton lam)
  have hsum : HasSum (fun n => (poissonMeasure lam).real {n}) 1 := by
    rw [hr]; exact hasSum_one_poissonMeasure lam
  have hrec : ∀ n, 1 ≤ n → (fun n => (poissonMeasure lam).real {n}) n =
      (0 + (lam : ℝ) / n) * (fun n => (poissonMeasure lam).real {n}) (n - 1) := by
    intro n hn
    obtain ⟨n, rfl⟩ : ∃ n', n = n' + 1 := ⟨n - 1, by omega⟩
    rw [hr]
    simp only [Nat.add_sub_cancel, Nat.factorial_succ, pow_succ, Nat.cast_mul]
    have : (0 : ℝ) < (n.factorial : ℝ) := by positivity
    push_cast
    field_simp
    ring
  rw [panjer_ab0_aux _ 0 lam (fun n => MeasureTheory.measureReal_nonneg) hsum hrec q m hq_nonneg
    hq_sum hq_max k hk]
  simp only [zero_mul, sub_zero, div_one, one_mul, zero_add, Finset.mul_sum]
  exact Finset.sum_congr rfl (fun j _ => by ring)

/-- The starting value: under a Poisson count with mean `λ`, the chance that the year's total is
zero is `p_0 = exp(-λ (1 - q_0))`. -/
theorem panjer_start_poisson (lam : ℝ≥0) (q : ℕ → ℝ) (m : ℕ)
    (hq_nonneg : ∀ j, 0 ≤ q j) (hq_sum : ∑ j ∈ range (m + 1), q j = 1)
    (hq_max : ∀ j, m < j → q j = 0) :
    aggregateDist (fun n => (poissonMeasure lam).real {n}) q 0 =
      Real.exp (-((lam : ℝ) * (1 - q 0))) := by
  have hc : ∀ n, coeff 0 (mk q ^ n) = q 0 ^ n := by
    intro n
    rw [coeff_zero_eq_constantCoeff_apply, map_pow, ← coeff_zero_eq_constantCoeff_apply,
      coeff_mk]
  have hs := (NormedSpace.expSeries_div_hasSum_exp ((lam : ℝ) * q 0)).mul_left
    (Real.exp (-(lam : ℝ)))
  unfold aggregateDist
  simp only [poissonMeasure_real_singleton, hc]
  rw [show Real.exp (-((lam : ℝ) * (1 - q 0))) =
      Real.exp (-(lam : ℝ)) * NormedSpace.exp ((lam : ℝ) * q 0) by
    rw [← Real.exp_eq_exp_ℝ, ← Real.exp_add]; congr 1; ring]
  rw [← hs.tsum_eq]
  congr 1
  funext n
  rw [mul_pow]
  ring

/-- Panjer's recursion for the (a, b, 0) family. If the count's chances obey
`P(N = n) = (a + b / n) · P(N = n - 1)` for every `n ≥ 1`, then for every total `k ≥ 1`,
`p_k = 1 / (1 - a q_0) · ∑_{j=1}^{min(k, m)} (a + b j / k) · q_j · p_{k-j}`. -/
theorem panjer_recursion_ab0 (r : ℕ → ℝ) (a b : ℝ)
    (hr_nonneg : ∀ n, 0 ≤ r n) (hr_sum : HasSum r 1)
    (hr_ab : ∀ n, 1 ≤ n → r n = (a + b / n) * r (n - 1))
    (q : ℕ → ℝ) (m : ℕ)
    (hq_nonneg : ∀ j, 0 ≤ q j) (hq_sum : ∑ j ∈ range (m + 1), q j = 1)
    (hq_max : ∀ j, m < j → q j = 0) (k : ℕ) (hk : 1 ≤ k) :
    aggregateDist r q k =
      1 / (1 - a * q 0) * ∑ j ∈ Icc 1 (min k m),
        (a + b * j / k) * q j * aggregateDist r q (k - j) := by
  exact panjer_ab0_aux r a b hr_nonneg hr_sum hr_ab q m hq_nonneg hq_sum hq_max k hk

/-! The card's worked numbers: λ = 20, sizes 1, 2, 5 units with chances 1/2, 3/10, 1/5.
Values are in units of `p_0`. -/

-- mean claim 2.1 units, mean total 42 units, variance λ E[X²] = 134 square units
example : (1 / 2 : ℚ) * 1 + 3 / 10 * 2 + 1 / 5 * 5 = 21 / 10 := by norm_num
example : (20 : ℚ) * (21 / 10) = 42 := by norm_num
example : (20 : ℚ) * (1 / 2 * 1 + 3 / 10 * 4 + 1 / 5 * 25) = 134 := by norm_num
-- threshold 120% of 42 is 50.4 units, so a breach is a total of 51 units or more
example : (6 / 5 : ℚ) * 42 = 252 / 5 := by norm_num
example : ⌊(252 / 5 : ℚ)⌋ = 50 := by norm_num [Int.floor_eq_iff]
-- p_1 = 10 p_0, p_2 = 56 p_0, p_3 = 680/3 p_0 (226.666667 p_0)
example : (20 : ℚ) / 1 * (1 * (1 / 2) * 1) = 10 := by norm_num
example : (20 : ℚ) / 2 * (1 * (1 / 2) * 10 + 2 * (3 / 10) * 1) = 56 := by norm_num
example : (20 : ℚ) / 3 * (1 * (1 / 2) * 56 + 2 * (3 / 10) * 10) = 680 / 3 := by norm_num
-- p_2 by the Poisson split: two $10,000 claims (10 · 10 / 2) or one $20,000 claim (6)
example : (10 : ℚ) * 10 / 2 + 6 = 56 := by norm_num
-- the split means: 20 · 1/2 = 10, 20 · 3/10 = 6, 20 · 1/5 = 4
example : (20 : ℚ) * (1 / 2) = 10 ∧ (20 : ℚ) * (3 / 10) = 6 ∧ (20 : ℚ) * (1 / 5) = 4 := by
  norm_num
-- negative binomial with mean 20, variance 60: a = 2/3, b = 6, p_0 = 3^(-10)
-- (r = 10, β = 2: a = β/(1+β), b = (r-1)β/(1+β), mean rβ, variance rβ(1+β))
example : (2 : ℚ) / (1 + 2) = 2 / 3 ∧ (10 - 1 : ℚ) * 2 / (1 + 2) = 6 ∧
    (10 : ℚ) * 2 = 20 ∧ (10 : ℚ) * 2 * (1 + 2) = 60 := by norm_num

#print axioms panjer_recursion_poisson
#print axioms panjer_start_poisson
#print axioms panjer_recursion_ab0
