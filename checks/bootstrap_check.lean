-- Bootstrap: over all n^n equally likely resamples of n numbers, the resampled mean averages to the sample mean with standard error σ̂/√n, a resample contains a given claim with chance 1 − (1 − 1/n)^n, and its largest rank is the k-th smallest with chance (k/n)^n − ((k−1)/n)^n.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.BigOperators.Field

open Finset

theorem bootstrap_sum_single (n : ℕ) (i : Fin n) (g : Fin n → ℝ) :
    ∑ f : Fin n → Fin n, g (f i) = (∏ _a ∈ ({i} : Finset (Fin n))ᶜ, (n : ℝ)) * ∑ j, g j := by
  have h := Fintype.prod_sum (fun (a : Fin n) (j : Fin n) => if a = i then g j else 1)
  simp only [Fintype.prod_ite_eq'] at h
  rw [← h, ← Finset.prod_mul_prod_compl {i}, Finset.prod_singleton, mul_comm]
  congr 1
  · apply Finset.prod_congr rfl
    intro a ha
    simp only [Finset.mem_compl, Finset.mem_singleton] at ha
    simp [ha]
  · simp

theorem bootstrap_sum_pair (n : ℕ) (i i' : Fin n) (hii : i ≠ i') (g h : Fin n → ℝ) :
    ∑ f : Fin n → Fin n, g (f i) * h (f i') =
      (∏ _a ∈ ({i, i'} : Finset (Fin n))ᶜ, (n : ℝ)) * ((∑ j, g j) * ∑ j, h j) := by
  have H := Fintype.prod_sum
    (fun (a : Fin n) (j : Fin n) => if a = i then g j else if a = i' then h j else 1)
  have hR : ∀ x : Fin n → Fin n,
      (∏ a, (if a = i then g (x a) else if a = i' then h (x a) else 1)) = g (x i) * h (x i') := by
    intro x
    rw [← Finset.prod_mul_prod_compl {i, i'}, Finset.prod_pair hii]
    rw [Finset.prod_eq_one]
    · simp [hii.symm]
    · intro a ha
      simp only [Finset.mem_compl, Finset.mem_insert, Finset.mem_singleton, not_or] at ha
      simp [ha.1, ha.2]
  simp only [hR] at H
  rw [← H, ← Finset.prod_mul_prod_compl {i, i'}, Finset.prod_pair hii, mul_comm]
  congr 1
  · apply Finset.prod_congr rfl
    intro a ha
    simp only [Finset.mem_compl, Finset.mem_insert, Finset.mem_singleton, not_or] at ha
    simp [ha.1, ha.2]
  · simp [hii.symm]

#print axioms bootstrap_sum_single
#print axioms bootstrap_sum_pair

/-- The exact bootstrap standard error of the mean. A resample of a book of n claims
`x 0, …, x (n-1)` draws n claims with replacement; it is a function `f : Fin n → Fin n`
saying which claim each draw picks, and all `n ^ n` such resamples are equally likely.
Averaged over every resample, the resampled mean equals the book's mean `x̄`, and the
standard deviation of the resampled mean (the exact bootstrap standard error, with B
taken without end) equals `σ̂ / √n`, where `σ̂² = (1/n) Σ (xᵢ − x̄)²` is the book's spread
with divisor n. -/
theorem bootstrap_se_of_mean_eq_spread_div_sqrt_n (n : ℕ) (x : Fin n → ℝ) :
    let xbar : ℝ := (∑ i, x i) / n
    let sigma2 : ℝ := (∑ i, (x i - xbar) ^ 2) / n
    let avg : ((Fin n → Fin n) → ℝ) → ℝ :=
      fun g => (∑ f, g f) / (Fintype.card (Fin n → Fin n) : ℝ)
    let resampledMean : (Fin n → Fin n) → ℝ := fun f => (∑ i, x (f i)) / n
    avg resampledMean = xbar ∧
      Real.sqrt (avg (fun f => (resampledMean f - avg resampledMean) ^ 2)) =
        Real.sqrt sigma2 / Real.sqrt n := by
  intro xbar sigma2 avg resampledMean
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp [xbar, sigma2, avg, resampledMean]
  have hn0 : (n : ℝ) ≠ 0 := by positivity
  have hcard : (Fintype.card (Fin n → Fin n) : ℝ) = (n : ℝ) ^ n := by simp
  have hP : ∀ i : Fin n, (∏ _a ∈ ({i} : Finset (Fin n))ᶜ, (n : ℝ)) = (n : ℝ) ^ (n - 1) := by
    intro i
    rw [Finset.prod_const, Finset.card_compl, Finset.card_singleton, Fintype.card_fin]
  have hpow : (n : ℝ) ^ n = n * (n : ℝ) ^ (n - 1) := by
    rw [← pow_succ']; congr 1; omega
  have h1 : avg resampledMean = xbar := by
    simp only [avg, resampledMean, xbar, hcard]
    rw [← Finset.sum_div, Finset.sum_comm]
    simp_rw [bootstrap_sum_single, hP]
    rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, hpow]
    field_simp
  refine ⟨h1, ?_⟩
  rw [h1]
  set y : Fin n → ℝ := fun j => x j - xbar with hydef
  have hy : ∑ j, y j = 0 := by
    simp only [y, xbar, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul]
    field_simp
    ring
  have hdiff : ∀ f : Fin n → Fin n, resampledMean f - xbar = (∑ i, y (f i)) / n := by
    intro f
    simp only [resampledMean, y, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul]
    field_simp
  have hinner : ∀ i : Fin n,
      ∑ i' : Fin n, ∑ f : Fin n → Fin n, y (f i) * y (f i') = (n : ℝ) ^ (n - 1) * ∑ j, y j ^ 2 := by
    intro i
    rw [Finset.sum_eq_single i]
    · rw [← hP i, ← bootstrap_sum_single n i (fun j => y j ^ 2)]
      simp [sq]
    · intro i' _ hne
      rw [bootstrap_sum_pair n i i' (Ne.symm hne), hy]
      simp
    · simp
  have hsum : ∑ f : Fin n → Fin n, (resampledMean f - xbar) ^ 2 =
      (n : ℝ) ^ n * (∑ j, y j ^ 2) / (n : ℝ) ^ 2 := by
    simp_rw [hdiff, div_pow, sq (∑ i, _), Finset.sum_mul_sum, ← Finset.sum_div]
    rw [Finset.sum_comm]
    simp_rw [Finset.sum_comm (s := (Finset.univ : Finset (Fin n → Fin n)))]
    simp_rw [hinner]
    rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, ← mul_assoc, ← hpow]
  have hvar : avg (fun f => (resampledMean f - xbar) ^ 2) = sigma2 / n := by
    simp only [avg]
    rw [hsum, hcard]
    simp only [sigma2]
    have : (n : ℝ) ^ n ≠ 0 := pow_ne_zero _ hn0
    field_simp
    rfl
  rw [hvar, Real.sqrt_div' _ (Nat.cast_nonneg n)]

/-- A resample of n claims, drawn with replacement with all `n ^ n` resamples equally
likely, contains any one given claim `i` (for example the book's largest) with chance
`1 − (1 − 1/n)^n`: it misses that claim only if all n draws miss it. -/
theorem resample_contains_claim_prob (n : ℕ) (i : Fin n) :
    (((univ : Finset (Fin n → Fin n)).filter (fun f => ∃ j, f j = i)).card : ℝ) /
        (Fintype.card (Fin n → Fin n) : ℝ) =
      1 - (1 - 1 / (n : ℝ)) ^ n := by
  have hn : 0 < n := Fin.pos i
  have hn0 : (n : ℝ) ≠ 0 := by positivity
  have hmiss : (univ : Finset (Fin n → Fin n)).filter (fun f => ¬ ∃ j, f j = i) =
      Fintype.piFinset (fun _ => (univ : Finset (Fin n)).erase i) := by
    ext f
    simp
  have hc := Finset.card_filter_add_card_filter_not
    (s := (univ : Finset (Fin n → Fin n))) (fun f => ∃ j, f j = i)
  rw [hmiss] at hc
  simp only [Fintype.card_piFinset, Finset.prod_const, Finset.card_erase_of_mem (mem_univ i),
    Finset.card_univ, Fintype.card_fin, Fintype.card_fun] at hc
  have hc' : (((univ : Finset (Fin n → Fin n)).filter (fun f => ∃ j, f j = i)).card : ℝ) =
      (n : ℝ) ^ n - ((n : ℝ) - 1) ^ n := by
    have := congrArg (fun m : ℕ => (m : ℝ)) hc
    simp only [Nat.cast_add, Nat.cast_pow, Nat.cast_sub (Nat.one_le_iff_ne_zero.mpr hn.ne'),
      Nat.cast_one] at this
    linarith
  rw [hc', Fintype.card_fun, Fintype.card_fin]
  push_cast
  rw [one_sub_div hn0, div_pow]
  have : (n : ℝ) ^ n ≠ 0 := pow_ne_zero _ hn0
  field_simp

/-- The exact law of the largest claim in a resample. Rank the book's claims from
smallest (rank 0) to largest (rank n − 1). Over all `n ^ n` equally likely resamples,
the largest rank drawn is rank `k` (the (k+1)-th smallest claim) with chance
`((k+1)/n)^n − (k/n)^n`: every draw lands at rank k or below, minus the case where
every draw lands below rank k. -/
theorem resample_max_rank_prob (n : ℕ) (k : Fin n) :
    (((univ : Finset (Fin n → Fin n)).filter
          (fun f => (∀ j, f j ≤ k) ∧ ∃ j, f j = k)).card : ℝ) /
        (Fintype.card (Fin n → Fin n) : ℝ) =
      (((k : ℕ) + 1 : ℝ) / n) ^ n - ((k : ℕ) / (n : ℝ)) ^ n := by
  have hset : (univ : Finset (Fin n → Fin n)).filter
      (fun f => (∀ j, f j ≤ k) ∧ ∃ j, f j = k) =
      Fintype.piFinset (fun _ => Finset.Iic k) \ Fintype.piFinset (fun _ => Finset.Iio k) := by
    ext f
    simp only [mem_filter, mem_univ, true_and, mem_sdiff, Fintype.mem_piFinset, mem_Iic,
      mem_Iio, not_forall, not_lt]
    constructor
    · rintro ⟨h1, j, hj⟩
      exact ⟨h1, j, hj.ge⟩
    · rintro ⟨h1, j, hj⟩
      exact ⟨h1, j, le_antisymm (h1 j) hj⟩
  have hsub : Fintype.piFinset (fun _ : Fin n => Finset.Iio k) ⊆
      Fintype.piFinset (fun _ => Finset.Iic k) :=
    Fintype.piFinset_subset _ _ (fun _ => Finset.Iio_subset_Iic_self)
  rw [hset, Finset.card_sdiff_of_subset hsub, Fintype.card_piFinset, Fintype.card_piFinset,
    Finset.prod_const, Finset.prod_const, Fin.card_Iic, Fin.card_Iio, Finset.card_univ,
    Fintype.card_fin, Fintype.card_fun, Fintype.card_fin,
    Nat.cast_sub (Nat.pow_le_pow_left (Nat.le_succ _) _)]
  push_cast
  rw [div_pow, div_pow, sub_div]

#print axioms bootstrap_se_of_mean_eq_spread_div_sqrt_n
#print axioms resample_contains_claim_prob
#print axioms resample_max_rank_prob
