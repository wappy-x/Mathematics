-- Samples and estimators: under random sampling the poll's share of yes answers has mean exactly p and variance p(1-p)/n, it stays unbiased without independence, and drawing without replacement keeps it unbiased while multiplying its variance by (N - n)/(N - 1).
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Data.Finset.Powerset

open MeasureTheory ProbabilityTheory

theorem psae_integral_bernoulli
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    (Y : Ω → ℝ) (hmeas : Measurable Y) (hval : ∀ ω, Y ω = 0 ∨ Y ω = 1) :
    ∫ ω, Y ω ∂P = P.real {ω | Y ω = 1} := by
  have hY : Y = Set.indicator {ω | Y ω = 1} 1 := by
    funext ω
    rcases hval ω with h | h <;> simp [Set.indicator, h]
  have hs : MeasurableSet {ω | Y ω = 1} := hmeas (measurableSet_singleton 1)
  conv_lhs => rw [hY]
  exact integral_indicator_one hs

#print axioms psae_integral_bernoulli

theorem psae_mean
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (hn : 1 ≤ n) (p : ℝ) (X : Fin n → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i))
    (hval : ∀ i ω, X i ω = 0 ∨ X i ω = 1)
    (hyes : ∀ i, P.real {ω | X i ω = 1} = p) :
    ∫ ω, (∑ i, X i ω) / n ∂P = p := by
  have hint : ∀ i, Integrable (X i) P := fun i =>
    (MemLp.of_bound (p := 1) (hmeas i).aestronglyMeasurable 1
      (Filter.Eventually.of_forall fun ω => by
        rcases hval i ω with h | h <;> simp [h])).integrable le_rfl
  rw [integral_div, integral_finsetSum _ (fun i _ => hint i)]
  simp_rw [psae_integral_bernoulli (P := P) (X _) (hmeas _) (hval _), hyes]
  have : (n : ℝ) ≠ 0 := by positivity
  simp
  field_simp

#print axioms psae_mean

theorem psae_sum_mem {N : ℕ} (s : Finset (Fin N)) (z : Fin N → ℝ) :
    ∑ j ∈ s, z j = ∑ j, if j ∈ s then z j else 0 := by
  rw [Finset.sum_ite_mem, Finset.univ_inter]

#print axioms psae_sum_mem

theorem psae_count_sum {N : ℕ} (S : Finset (Finset (Fin N))) (z : Fin N → ℝ) :
    ∑ s ∈ S, ∑ j ∈ s, z j = ∑ j, z j * (S.filter (j ∈ ·)).card := by
  rw [Finset.sum_congr rfl (fun s _ => psae_sum_mem s z), Finset.sum_comm]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul, mul_comm]

#print axioms psae_count_sum

theorem psae_count_sum_sq {N : ℕ} (S : Finset (Finset (Fin N))) (z : Fin N → ℝ) :
    ∑ s ∈ S, (∑ j ∈ s, z j) ^ 2 =
      ∑ j, ∑ k, z j * z k * (S.filter (fun s => j ∈ s ∧ k ∈ s)).card := by
  rw [Finset.sum_congr rfl (fun s _ => by rw [psae_sum_mem s z])]
  simp_rw [sq, Finset.sum_mul_sum]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun k _ => ?_
  have : ∀ s : Finset (Fin N), ((if j ∈ s then z j else 0) * if k ∈ s then z k else 0) =
      if (j ∈ s ∧ k ∈ s) then z j * z k else 0 := by
    intro s; by_cases hj : j ∈ s <;> by_cases hk : k ∈ s <;> simp [hj, hk]
  simp_rw [this]
  rw [← Finset.sum_filter, Finset.sum_const, nsmul_eq_mul, mul_comm]

#print axioms psae_count_sum_sq

theorem psae_count1 (N n : ℕ) (hn : 1 ≤ n) (j : Fin N) :
    (((Finset.univ : Finset (Fin N)).powersetCard n).filter (j ∈ ·)).card
      = Nat.choose (N - 1) (n - 1) := by
  have h := Finset.card_filter_powersetCard_subset {j} (Finset.univ : Finset (Fin N)) n
    (Finset.subset_univ _) (by simpa using hn)
  simp only [Finset.singleton_subset_iff, Finset.card_singleton, Finset.card_univ,
    Fintype.card_fin] at h
  exact h

#print axioms psae_count1

theorem psae_count2 (N n : ℕ) (j k : Fin N) (hjk : j ≠ k) :
    (((Finset.univ : Finset (Fin N)).powersetCard n).filter (fun s => j ∈ s ∧ k ∈ s)).card
      = if 2 ≤ n then Nat.choose (N - 2) (n - 2) else 0 := by
  split_ifs with h2
  · have h := Finset.card_filter_powersetCard_subset {j, k} (Finset.univ : Finset (Fin N)) n
      (Finset.subset_univ _) (by rw [Finset.card_pair hjk]; exact h2)
    rw [Finset.card_pair hjk] at h
    simp only [Finset.card_univ, Fintype.card_fin] at h
    rw [← h]
    congr 1
    apply Finset.filter_congr
    intro s _
    simp [Finset.insert_subset_iff]
  · rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
    intro s hs ⟨hj, hk⟩
    rw [Finset.mem_powersetCard] at hs
    have : ({j, k} : Finset (Fin N)).card ≤ s.card :=
      Finset.card_le_card (by simp [Finset.insert_subset_iff, hj, hk])
    rw [Finset.card_pair hjk, hs.2] at this
    omega

#print axioms psae_count2

theorem psae_sq_formula (N n : ℕ) (hn : 1 ≤ n) (z : Fin N → ℝ) :
    ∑ s ∈ (Finset.univ : Finset (Fin N)).powersetCard n, (∑ j ∈ s, z j) ^ 2 =
      (Nat.choose (N - 1) (n - 1) : ℝ) * ∑ j, z j ^ 2 +
      ((if 2 ≤ n then Nat.choose (N - 2) (n - 2) else 0 : ℕ) : ℝ) *
        ((∑ j, z j) ^ 2 - ∑ j, z j ^ 2) := by
  set c1 : ℝ := (Nat.choose (N - 1) (n - 1) : ℝ)
  set d : ℝ := ((if 2 ≤ n then Nat.choose (N - 2) (n - 2) else 0 : ℕ) : ℝ)
  rw [psae_count_sum_sq]
  have hc : ∀ j k : Fin N, z j * z k *
      ((((Finset.univ : Finset (Fin N)).powersetCard n).filter
        (fun s => j ∈ s ∧ k ∈ s)).card : ℝ) =
      d * (z j * z k) + if j = k then (c1 - d) * (z j * z k) else 0 := by
    intro j k
    by_cases hjk : j = k
    · subst hjk
      simp only [and_self, ite_true]
      rw [psae_count1 N n hn j]
      ring
    · rw [psae_count2 N n j k hjk, ite_eq_right_iff.mpr (fun h => absurd h hjk)]
      ring
  have hsq : (∑ j, z j) ^ 2 = ∑ j, ∑ k, z j * z k := by
    rw [sq, Finset.sum_mul_sum]
  calc ∑ j, ∑ k, z j * z k *
        ((((Finset.univ : Finset (Fin N)).powersetCard n).filter
          (fun s => j ∈ s ∧ k ∈ s)).card : ℝ)
      = ∑ j, ∑ k, (d * (z j * z k) + if j = k then (c1 - d) * (z j * z k) else 0) := by
        simp_rw [hc]
    _ = d * ∑ j, ∑ k, z j * z k + (c1 - d) * ∑ j, z j ^ 2 := by
        simp only [Finset.sum_add_distrib, Finset.sum_ite_eq, Finset.mem_univ, ite_true,
          Finset.mul_sum, sq]
    _ = _ := by rw [hsq]; ring

#print axioms psae_sq_formula

theorem psae_sum_formula (N n : ℕ) (hn : 1 ≤ n) (z : Fin N → ℝ) :
    ∑ s ∈ (Finset.univ : Finset (Fin N)).powersetCard n, ∑ j ∈ s, z j =
      (Nat.choose (N - 1) (n - 1) : ℝ) * ∑ j, z j := by
  rw [psae_count_sum, Finset.mul_sum]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [psae_count1 N n hn j, mul_comm]

#print axioms psae_sum_formula

/-- **The poll's share has no bias and noise `√(p(1-p)/n)`.** Poll `n ≥ 1` voters. Before the
calls, voter `i`'s answer is a random variable `X i` that is 1 for yes and 0 for no. Under the
iid sampling model the answers are independent and each is yes with the same chance `p`. Then
the sample share `p̂ = (X 1 + … + X n)/n` has mean exactly `p`, variance `p(1-p)/n`, and
standard deviation (its noise, or standard error) `√(p(1-p)/n)`. -/
theorem poll_share_unbiased_with_noise_sqrt_p_one_minus_p_over_n
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (hn : 1 ≤ n) (p : ℝ) (X : Fin n → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i))
    (hval : ∀ i ω, X i ω = 0 ∨ X i ω = 1)
    (hyes : ∀ i, P.real {ω | X i ω = 1} = p)
    (hind : iIndepFun X P) :
    ∫ ω, (∑ i, X i ω) / n ∂P = p ∧
      variance (fun ω => (∑ i, X i ω) / n) P = p * (1 - p) / n ∧
      Real.sqrt (variance (fun ω => (∑ i, X i ω) / n) P) = Real.sqrt (p * (1 - p) / n) := by
  have hmem : ∀ i, MemLp (X i) 2 P := fun i =>
    MemLp.of_bound (hmeas i).aestronglyMeasurable 1
      (Filter.Eventually.of_forall fun ω => by
        rcases hval i ω with h | h <;> simp [h])
  have hvar : variance (fun ω => (∑ i, X i ω) / n) P = p * (1 - p) / n := by
    have h1 : (fun ω => (∑ i, X i ω) / (n : ℝ)) = fun ω => (n : ℝ)⁻¹ * (∑ i, X i) ω := by
      funext ω
      rw [Finset.sum_apply, div_eq_inv_mul]
    rw [h1, variance_const_mul, IndepFun.variance_sum (fun i _ => hmem i)
      (fun i _ j _ hij => hind.indepFun hij)]
    have hvi : ∀ i, variance (X i) P = p - p ^ 2 := by
      intro i
      rw [variance_eq_sub (hmem i)]
      have hsq : X i ^ 2 = X i := by
        funext ω
        rcases hval i ω with h | h <;> simp [h]
      rw [hsq]
      have := psae_integral_bernoulli (P := P) (X i) (hmeas i) (hval i)
      rw [this, hyes]
    simp_rw [hvi]
    have : (n : ℝ) ≠ 0 := by positivity
    simp
    field_simp
  refine ⟨psae_mean n hn p X hmeas hval hyes, hvar, by rw [hvar]⟩

/-- **No bias needs identical laws, not independence.** If each of the `n ≥ 1` answers
`X i` is 1 for yes and 0 for no, and each is yes with the same chance `p`, then the sample
share has mean exactly `p`, whether or not the answers are independent. -/
theorem poll_share_unbiased_without_independence
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (hn : 1 ≤ n) (p : ℝ) (X : Fin n → Ω → ℝ)
    (hmeas : ∀ i, Measurable (X i))
    (hval : ∀ i ω, X i ω = 0 ∨ X i ω = 1)
    (hyes : ∀ i, P.real {ω | X i ω = 1} = p) :
    ∫ ω, (∑ i, X i ω) / n ∂P = p := by
  exact psae_mean n hn p X hmeas hval hyes

/-- **Without replacement: still unbiased, variance shrunk by `(N - n)/(N - 1)`.** A population
of `N` voters has fixed votes `y j`, 1 for yes and 0 for no, so its yes share is
`p = (y 1 + … + y N)/N`. Draw `n` voters without replacement, `1 ≤ n ≤ N`, every set of `n`
voters equally likely. Averaged over all those sets, the sample share is exactly `p`, and its
variance is `p(1-p)/n × (N - n)/(N - 1)`. -/
theorem share_without_replacement_unbiased_with_corrected_variance
    (N n : ℕ) (hn : 1 ≤ n) (hnN : n ≤ N) (y : Fin N → ℝ) (hy : ∀ j, y j = 0 ∨ y j = 1) :
    let S := (Finset.univ : Finset (Fin N)).powersetCard n
    let p := (∑ j, y j) / N
    let share := fun s : Finset (Fin N) => (∑ j ∈ s, y j) / n
    (∑ s ∈ S, share s) / S.card = p ∧
      (∑ s ∈ S, (share s - p) ^ 2) / S.card = p * (1 - p) / n * ((N - n) / (N - 1)) := by
  intro S p share
  set c1 : ℝ := (Nat.choose (N - 1) (n - 1) : ℝ) with hc1def
  set d : ℝ := ((if 2 ≤ n then Nat.choose (N - 2) (n - 2) else 0 : ℕ) : ℝ) with hddef
  set K : ℝ := ∑ j, y j with hK
  set C : ℝ := (S.card : ℝ) with hCdef
  have hSc : S.card = Nat.choose N n := by
    simp [S, Finset.card_powersetCard]
  have hCpos : 0 < C := by
    rw [hCdef, hSc]; exact_mod_cast Nat.choose_pos hnN
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hNpos : (0 : ℝ) < N := by exact_mod_cast (lt_of_lt_of_le hn hnN)
  -- relations from the all-ones vector
  have hcard : ∀ s ∈ S, ∑ j ∈ s, (1 : ℝ) = n := by
    intro s hs
    rw [Finset.mem_powersetCard] at hs
    simp [hs.2]
  have R1 : (n : ℝ) * C = c1 * N := by
    have h := psae_sum_formula N n hn (fun _ => (1 : ℝ))
    rw [Finset.sum_congr rfl hcard] at h
    simpa [Finset.sum_const, hCdef, mul_comm] using h
  have R2 : (n : ℝ) ^ 2 * C = c1 * N + d * ((N : ℝ) ^ 2 - N) := by
    have h := psae_sq_formula N n hn (fun _ => (1 : ℝ))
    rw [Finset.sum_congr rfl (fun s hs => by rw [hcard s hs]), ← hc1def, ← hddef] at h
    simp only [Finset.sum_const, nsmul_eq_mul, Finset.card_univ, Fintype.card_fin, one_pow,
      mul_one] at h
    rw [hCdef]
    linear_combination h
  have hysq : ∑ j, y j ^ 2 = K := by
    refine Finset.sum_congr rfl fun j _ => ?_
    rcases hy j with h | h <;> simp [h]
  have hB : ∑ s ∈ S, ∑ j ∈ s, y j = c1 * K := psae_sum_formula N n hn y
  have hA : ∑ s ∈ S, (∑ j ∈ s, y j) ^ 2 = c1 * K + d * (K ^ 2 - K) := by
    rw [psae_sq_formula N n hn y, hysq]
  have hmean : (∑ s ∈ S, share s) / S.card = p := by
    simp only [share, p]
    rw [← Finset.sum_div, hB, ← hCdef]
    field_simp
    linear_combination (-K) * R1
  refine ⟨hmean, ?_⟩
  have hexp : ∑ s ∈ S, (share s - p) ^ 2 =
      (∑ s ∈ S, (∑ j ∈ s, y j) ^ 2) / (n : ℝ) ^ 2
        - 2 * p / n * ∑ s ∈ S, ∑ j ∈ s, y j + C * p ^ 2 := by
    simp only [share]
    rw [Finset.sum_div, Finset.mul_sum, hCdef, ← nsmul_eq_mul, ← Finset.sum_const,
      ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun s _ => ?_
    field_simp
    ring
  rw [hexp, hA, hB]
  simp only [p]
  rcases Nat.lt_or_ge N 2 with hN | hN
  · -- N = 1
    have hN1 : N = 1 := by omega
    have hn1 : n = 1 := by omega
    subst hN1 hn1
    have hd0 : d = 0 := by simp [hddef]
    have hK2 : K ^ 2 = K := by
      rw [hK, Fin.sum_univ_one]
      rcases hy 0 with h | h <;> simp [h]
    have hc1C : c1 = C := by simpa using R1.symm
    have hKy : K = y 0 := by rw [hK, Fin.sum_univ_one]
    rw [hd0, hc1C, hK2]
    simp
    left
    rw [hKy] at hK2 ⊢
    linear_combination (-C) * hK2
  · have hN1 : (N : ℝ) - 1 ≠ 0 := by
      have : (2 : ℝ) ≤ N := by exact_mod_cast hN
      linarith
    have hc1 : c1 = n * C / N := by
      field_simp; linarith
    have hd : d = n * (n - 1) * C / (N * (N - 1)) := by
      field_simp
      have : d * ((N : ℝ) ^ 2 - N) = n ^ 2 * C - n * C := by rw [R1]; linarith
      linear_combination this
    rw [hc1, hd]
    field_simp
    ring

-- The estimate: 520 yeses in 1,000 calls is a share of 13/25 (0.52).
example : (520 : ℚ) / 1000 = 13 / 25 := by norm_num
-- One answer's variance: 0.52 × 0.48 = 156/625 (0.2496); over 1,000 voters, 156/625000.
example : (13 / 25 : ℚ) * (1 - 13 / 25) = 156 / 625 := by norm_num
example : (156 / 625 : ℚ) / 1000 = 156 / 625000 := by norm_num
-- Self-selected answers: of every 1,000 phoned, 260 yes voters and 288 no voters answer, 548 in all.
example : (520 : ℕ) / 2 = 260 ∧ 480 * 6 / 10 = 288 ∧ 260 + 288 = 548 := by decide
-- Their yes share is 260/548 = 65/137 (0.4745), a bias of -156/3425 (-0.0455).
example : (260 : ℚ) / 548 = 65 / 137 := by norm_num
example : (65 / 137 : ℚ) - 13 / 25 = -156 / 3425 := by norm_num
-- The town of 25 voters, polled 5 at a time: C(25, 5) = 53,130 possible samples.
example : Nat.choose 25 5 = 53130 := by decide
-- Each voter is in C(24, 4) of them, exactly 1 sample in 5.
example : Nat.choose 24 4 * 5 = Nat.choose 25 5 := by decide
-- Two given voters are together in C(23, 3) of them: a fraction n(n-1)/(N(N-1)) = 20/600.
example : Nat.choose 23 3 * (25 * 24) = Nat.choose 25 5 * (5 * 4) := by decide
-- With 13 yes voters, the share's variance is 156/625 / 5 × 20/24 = 26/625 (0.0416), against 156/3125 (0.0499) with replacement.
example : (156 / 625 : ℚ) / 5 * ((25 - 5) / (25 - 1)) = 26 / 625 := by norm_num
example : (156 / 625 : ℚ) / 5 = 156 / 3125 := by norm_num
-- An electorate of a million and a poll of 1,000: the factor is 999000/999999 (0.999001).
example : ((10 ^ 6 - 1000 : ℚ)) / (10 ^ 6 - 1) = 999000 / 999999 := by norm_num

#print axioms poll_share_unbiased_with_noise_sqrt_p_one_minus_p_over_n
#print axioms poll_share_unbiased_without_independence
#print axioms share_without_replacement_unbiased_with_corrected_variance
