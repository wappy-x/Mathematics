-- Momentum and factor signals: the Newey-West long-run variance with Bartlett weights equals an average of squared window sums and so is never negative, the long-short spread cancels the market's return, and the variance of an average counts each lag j exactly T - j times.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Finset

/-! Months are numbered by integers; the sample is months `1, …, T` of the spread `x`. -/

/-- The average monthly spread `x̄ = (x₁ + ⋯ + x_T) / T`. -/
noncomputable def spreadMean (x : ℤ → ℝ) (T : ℕ) : ℝ :=
  (∑ k ∈ Icc (1 : ℤ) T, x k) / T

/-- `d_k = x_k - x̄` for `k = 1, …, T`, and `d_k = 0` outside that range. -/
noncomputable def spreadDev (x : ℤ → ℝ) (T : ℕ) (k : ℤ) : ℝ :=
  if k ∈ Icc (1 : ℤ) T then x k - spreadMean x T else 0

/-- The sample autocovariance at lag `j`:
`γ̂_j = (1/T) ∑_{k=j+1}^{T} (x_k - x̄)(x_{k-j} - x̄)`. At `j = 0` it is the variance. -/
noncomputable def autocov (x : ℤ → ℝ) (T : ℕ) (j : ℕ) : ℝ :=
  (1 / (T : ℝ)) * ∑ k ∈ Icc ((j : ℤ) + 1) T, (x k - spreadMean x T) * (x (k - j) - spreadMean x T)

/-- The Newey-West long-run variance with `L` lags and Bartlett weights:
`σ̂² = γ̂₀ + 2 ∑_{j=1}^{L} (1 - j/(L+1)) γ̂_j`. -/
noncomputable def nwLongRunVar (x : ℤ → ℝ) (T L : ℕ) : ℝ :=
  autocov x T 0 + 2 * ∑ j ∈ Icc 1 L, (1 - (j : ℝ) / (L + 1)) * autocov x T j

/-- The window sum `W_s = d_s + d_{s+1} + ⋯ + d_{s+L}`, a window `L + 1` months long. -/
noncomputable def windowSum (x : ℤ → ℝ) (T L : ℕ) (s : ℤ) : ℝ :=
  ∑ a ∈ range (L + 1), spreadDev x T (s + a)

theorem lag_count_range (g : ℕ → ℝ) (n : ℕ) :
    ∑ a ∈ range n, ∑ b ∈ range n, g ((a : ℤ) - b).natAbs
      = 2 * ∑ j ∈ range n, ((n : ℝ) - j) * g j - n * g 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    have h1 : ∀ a ∈ range n, g ((a : ℤ) - (n : ℕ)).natAbs = g (n - 1 - a + 1) := by
      intro a ha
      simp only [mem_range] at ha
      congr 1
      omega
    have h2 : ∀ b ∈ range n, g (((n : ℕ) : ℤ) - b).natAbs = g (n - 1 - b + 1) := by
      intro b hb
      simp only [mem_range] at hb
      congr 1
      omega
    have hr : ∑ a ∈ range n, g (n - 1 - a + 1) = ∑ j ∈ range n, g (j + 1) :=
      sum_range_reflect (fun j => g (j + 1)) n
    have hs : ∑ j ∈ range (n + 1), g j = ∑ j ∈ range n, g (j + 1) + g 0 := sum_range_succ' _ _
    have hcoef : ∑ j ∈ range n, (((n + 1 : ℕ) : ℝ) - j) * g j
        = ∑ j ∈ range n, ((n : ℝ) - j) * g j + ∑ j ∈ range n, g j := by
      rw [← sum_add_distrib]
      refine sum_congr rfl fun j _ => ?_
      push_cast; ring
    rw [sum_range_succ, sum_range_succ]
    simp only [sum_range_succ]
    rw [sum_add_distrib, ih, sum_congr rfl h1, sum_congr rfl h2, hr, hcoef]
    rw [sum_range_succ] at hs
    simp only [sub_self, Int.natAbs_zero]
    push_cast
    linarith

#print axioms lag_count_range

theorem sum_Icc_int_one_eq_range (T : ℕ) (f : ℤ → ℝ) :
    ∑ s ∈ Icc (1 : ℤ) T, f s = ∑ a ∈ range T, f ((a : ℤ) + 1) := by
  symm
  apply sum_nbij' (fun a : ℕ => (a : ℤ) + 1) (fun s : ℤ => (s - 1).toNat)
  · intro a ha; simp only [mem_range, mem_Icc] at ha ⊢; omega
  · intro s hs; simp only [mem_range, mem_Icc] at hs ⊢; omega
  · intro a _; simp
  · intro s hs; simp only [mem_Icc] at hs; omega
  · intro a _; rfl

#print axioms sum_Icc_int_one_eq_range

theorem sum_range_split_zero (f : ℕ → ℝ) (n : ℕ) (hn : 0 < n) :
    ∑ j ∈ range n, f j = f 0 + ∑ j ∈ Icc 1 (n - 1), f j := by
  rw [range_eq_Ico, sum_eq_sum_Ico_succ_bot hn]
  congr 1

#print axioms sum_range_split_zero

/-- `T · γ̂_j` written with the zero-padded deviations `d`. -/
theorem T_mul_autocov (x : ℤ → ℝ) (T j : ℕ) :
    (T : ℝ) * autocov x T j
      = ∑ k ∈ Icc ((j : ℤ) + 1) T, spreadDev x T k * spreadDev x T (k - j) := by
  rcases Nat.eq_zero_or_pos T with hT | hT
  · subst hT
    simp [autocov]
  · have hT' : (T : ℝ) ≠ 0 := by positivity
    rw [autocov, ← mul_assoc, mul_one_div_cancel hT', one_mul]
    refine sum_congr rfl fun k hk => ?_
    simp only [mem_Icc] at hk
    have h1 : k ∈ Icc (1 : ℤ) T := by simp only [mem_Icc]; omega
    have h2 : k - j ∈ Icc (1 : ℤ) T := by simp only [mem_Icc]; omega
    simp only [spreadDev, h1, h2, ite_true]

#print axioms T_mul_autocov

/-- One pair of window positions `a ≥ b` gives the lag-`(a - b)` cross product. -/
theorem window_pair_sum (x : ℤ → ℝ) (T L a b : ℕ) (ha : a ≤ L) (hba : b ≤ a) :
    ∑ s ∈ Icc (1 - (L : ℤ)) T, spreadDev x T (s + a) * spreadDev x T (s + b)
      = ∑ k ∈ Icc (((a - b : ℕ) : ℤ) + 1) T,
          spreadDev x T k * spreadDev x T (k - (a - b : ℕ)) := by
  set d := spreadDev x T with hd_def
  have hd : ∀ k, k ∉ Icc (1 : ℤ) T → d k = 0 := fun k hk => by
    simp only [hd_def, spreadDev, hk, ite_false]
  have hshift : ∑ s ∈ Icc (1 - (L : ℤ)) T, d (s + a) * d (s + b)
      = ∑ k ∈ Icc (1 - (L : ℤ) + a) (T + a), d k * d (k - (a - b : ℕ)) := by
    apply sum_nbij' (fun s : ℤ => s + a) (fun k : ℤ => k - a)
    · intro s hs; simp only [mem_Icc] at hs ⊢; omega
    · intro k hk; simp only [mem_Icc] at hk ⊢; omega
    · intro s _; ring
    · intro k _; ring
    · intro s _
      congr 2
      push_cast [hba]
      ring
  rw [hshift]
  symm
  apply sum_subset
  · intro k hk; simp only [mem_Icc] at hk ⊢; omega
  · intro k hk hk'
    simp only [mem_Icc, not_and_or, not_le] at hk hk'
    rcases hk' with h | h
    · rw [hd (k - (a - b : ℕ)) (by simp only [mem_Icc]; omega), mul_zero]
    · rw [hd k (by simp only [mem_Icc]; omega), zero_mul]

#print axioms window_pair_sum

/-- The card's main claim (the folded proof in "Why it works", Step 5). For any monthly
spreads `x₁, …, x_T` and any number of lags `L`, adding the squared window sums `W_s` over
every start `s` from `1 - L` to `T` gives exactly `(L + 1) · T` times the Newey-West long-run
variance. So the Bartlett-weighted long-run variance is an average of squares and is never
negative. -/
theorem nw_long_run_var_eq_window_sums_and_nonneg (x : ℤ → ℝ) (T L : ℕ) :
    ∑ s ∈ Icc (1 - (L : ℤ)) T, (windowSum x T L s) ^ 2
        = ((L : ℝ) + 1) * T * nwLongRunVar x T L ∧
      0 ≤ nwLongRunVar x T L := by
  set C : ℕ → ℝ := fun j => ∑ k ∈ Icc ((j : ℤ) + 1) T, spreadDev x T k * spreadDev x T (k - j)
    with hC
  have hpair : ∀ a ∈ range (L + 1), ∀ b ∈ range (L + 1),
      ∑ s ∈ Icc (1 - (L : ℤ)) T, spreadDev x T (s + a) * spreadDev x T (s + b)
        = C ((a : ℤ) - b).natAbs := by
    intro a ha b hb
    simp only [mem_range] at ha hb
    rcases le_total b a with hba | hab
    · rw [window_pair_sum x T L a b (by omega) hba]
      have : ((a : ℤ) - b).natAbs = a - b := by omega
      rw [this]
    · rw [show ∑ s ∈ Icc (1 - (L : ℤ)) T, spreadDev x T (s + a) * spreadDev x T (s + b)
          = ∑ s ∈ Icc (1 - (L : ℤ)) T, spreadDev x T (s + b) * spreadDev x T (s + a) from
          sum_congr rfl fun _ _ => mul_comm _ _]
      rw [window_pair_sum x T L b a (by omega) hab]
      have : ((a : ℤ) - b).natAbs = b - a := by omega
      rw [this]
  have hlhs : ∑ s ∈ Icc (1 - (L : ℤ)) T, (windowSum x T L s) ^ 2
      = 2 * ∑ j ∈ range (L + 1), (((L + 1 : ℕ) : ℝ) - j) * C j - ((L + 1 : ℕ) : ℝ) * C 0 := by
    rw [← lag_count_range C (L + 1)]
    simp only [windowSum, sq, sum_mul_sum]
    rw [sum_comm]
    refine sum_congr rfl fun a ha => ?_
    rw [sum_comm]
    exact sum_congr rfl fun b hb => hpair a ha b hb
  have hrhs : ((L : ℝ) + 1) * T * nwLongRunVar x T L
      = ((L : ℝ) + 1) * C 0 + 2 * ∑ j ∈ Icc 1 L, (((L : ℝ) + 1) - j) * C j := by
    have hCj : ∀ j, C j = (T : ℝ) * autocov x T j := fun j => (T_mul_autocov x T j).symm
    simp only [hCj, nwLongRunVar, mul_add, mul_sum]
    have hL : ((L : ℝ) + 1) ≠ 0 := by positivity
    congr 1
    · ring
    · refine sum_congr rfl fun j _ => ?_
      field_simp
  have heq : ∑ s ∈ Icc (1 - (L : ℤ)) T, (windowSum x T L s) ^ 2
      = ((L : ℝ) + 1) * T * nwLongRunVar x T L := by
    rw [hlhs, hrhs, sum_range_split_zero _ (L + 1) (by omega)]
    simp only [Nat.add_sub_cancel]
    push_cast
    ring
  refine ⟨heq, ?_⟩
  rcases Nat.eq_zero_or_pos T with hT | hT
  · subst hT
    simp [nwLongRunVar, autocov]
  · have hpos : (0 : ℝ) < ((L : ℝ) + 1) * T := by positivity
    have hnn : 0 ≤ ∑ s ∈ Icc (1 - (L : ℤ)) T, (windowSum x T L s) ^ 2 :=
      sum_nonneg fun _ _ => sq_nonneg _
    rw [heq] at hnn
    exact (mul_nonneg_iff_of_pos_left hpos).mp hnn

/-- Step 1: the long-short spread removes the market. If every stock's return this month is
the market's return `m` plus its own part `u i`, and the top and bottom deciles each hold `n`
stocks, then the top decile's average return minus the bottom decile's average return equals
the same difference of the stocks' own parts: the market's return cancels exactly. -/
theorem long_short_spread_cancels_market {ι : Type*} (top bottom : Finset ι) (n : ℕ)
    (htop : top.card = n) (hbot : bottom.card = n) (m : ℝ) (u r : ι → ℝ)
    (hr : ∀ i, r i = m + u i) :
    (1 / (n : ℝ)) * ∑ i ∈ top, r i - (1 / (n : ℝ)) * ∑ i ∈ bottom, r i
      = (1 / (n : ℝ)) * ∑ i ∈ top, u i - (1 / (n : ℝ)) * ∑ i ∈ bottom, u i := by
  simp only [hr, sum_add_distrib, sum_const, htop, hbot, nsmul_eq_mul]
  ring

/-- Step 4: the variance of an average when months lean on each other. If the covariance of
months `s` and `k` depends only on how far apart they are, `Cov(x_s, x_k) = γ_{|s-k|}`, then
`(1/T²) ∑_s ∑_k Cov(x_s, x_k) = (1/T) [γ₀ + 2 ∑_{j=1}^{T-1} (1 - j/T) γ_j]`, because pairs
`j` months apart occur `T - j` times. -/
theorem variance_of_average_counts_lags (T : ℕ) (Cov : ℤ → ℤ → ℝ) (γ : ℕ → ℝ)
    (hCov : ∀ s k, Cov s k = γ (s - k).natAbs) :
    (1 / (T : ℝ) ^ 2) * ∑ s ∈ Icc (1 : ℤ) T, ∑ k ∈ Icc (1 : ℤ) T, Cov s k
      = (1 / (T : ℝ)) * (γ 0 + 2 * ∑ j ∈ Icc 1 (T - 1), (1 - (j : ℝ) / T) * γ j) := by
  have hsum : ∑ s ∈ Icc (1 : ℤ) T, ∑ k ∈ Icc (1 : ℤ) T, Cov s k
      = 2 * ∑ j ∈ range T, ((T : ℝ) - j) * γ j - T * γ 0 := by
    rw [← lag_count_range γ T, sum_Icc_int_one_eq_range]
    refine sum_congr rfl fun a _ => ?_
    rw [sum_Icc_int_one_eq_range]
    refine sum_congr rfl fun b _ => ?_
    rw [hCov]
    congr 2
    ring
  rw [hsum]
  rcases Nat.eq_zero_or_pos T with hT | hT
  · subst hT; simp
  · have hT' : (T : ℝ) ≠ 0 := by positivity
    rw [sum_range_split_zero _ T hT]
    have hc : ∑ j ∈ Icc 1 (T - 1), ((T : ℝ) - j) * γ j
        = T * ∑ j ∈ Icc 1 (T - 1), (1 - (j : ℝ) / T) * γ j := by
      rw [mul_sum]
      refine sum_congr rfl fun j _ => ?_
      field_simp
    rw [hc]
    field_simp
    ring

-- The example stock's signal: $61.00 / $50.00 - 1 = 0.22 exactly.
example : (61 : ℚ) / 50 - 1 = 22 / 100 := by norm_num

-- 300 stocks cut into ten deciles hold 30 stocks each.
example : 300 / 10 = 30 := by decide

-- The Newey-West 1994 lag rule for T = 240 months: L = ⌊4 (240/100)^(2/9)⌋ = 4.
example : ⌊(4 : ℝ) * ((240 : ℝ) / 100) ^ ((2 : ℝ) / 9)⌋₊ = 4 := by
  rw [Nat.floor_eq_iff (by positivity)]
  have h1 : (1 : ℝ) ≤ ((240 : ℝ) / 100) ^ ((2 : ℝ) / 9) :=
    Real.one_le_rpow (by norm_num) (by norm_num)
  have h9 : (((240 : ℝ) / 100) ^ ((2 : ℝ) / 9)) ^ (9 : ℕ) = ((240 : ℝ) / 100) ^ (2 : ℕ) := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul (by norm_num)]
    norm_num
  have h2 : ((240 : ℝ) / 100) ^ ((2 : ℝ) / 9) < 5 / 4 := by
    by_contra h
    push Not at h
    have := pow_le_pow_left₀ (by norm_num) h 9
    rw [h9] at this
    norm_num at this
  constructor <;> push_cast <;> linarith

-- The Bartlett weights 1 - j/(L+1) for L = 4: 0.8, 0.6, 0.4, 0.2.
example : [1, 2, 3, 4].map (fun j : ℕ => 1 - (j : ℚ) / (4 + 1)) = [8 / 10, 6 / 10, 4 / 10, 2 / 10] := by
  norm_num

#print axioms nw_long_run_var_eq_window_sums_and_nonneg
#print axioms long_short_spread_cancels_market
#print axioms variance_of_average_counts_lags
