-- Pairs trading: the least-squares hedge ratio is the one ratio with the smallest misfit, pooled slopes between every two dates give the same ratio, and a position held in that ratio gains exactly the number of A shares times the spread's change.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith

open Finset

/-- The window average of a price series over `n` days: `x̄ = (Σ_t x_t) / n`. -/
noncomputable def windowMean {n : ℕ} (x : Fin n → ℝ) : ℝ := (∑ t, x t) / n

/-- The least-squares hedge ratio of A on B:
`β̂ = Σ_t (B_t - B̄)(A_t - Ā) / Σ_t (B_t - B̄)²`. -/
noncomputable def hedgeRatio {n : ℕ} (A B : Fin n → ℝ) : ℝ :=
  (∑ t, (B t - windowMean B) * (A t - windowMean A)) / ∑ t, (B t - windowMean B) ^ 2

/-- The fitted intercept `ĉ = Ā - β̂ B̄`. -/
noncomputable def intercept {n : ℕ} (A B : Fin n → ℝ) : ℝ :=
  windowMean A - hedgeRatio A B * windowMean B

/-- The fitted spread `s_t = A_t - ĉ - β̂ B_t`. -/
noncomputable def spread {n : ℕ} (A B : Fin n → ℝ) (t : Fin n) : ℝ :=
  A t - intercept A B - hedgeRatio A B * B t

/-- The misfit of a trial ratio `b`: `Σ_t ((A_t - Ā) - b (B_t - B̄))²`. -/
noncomputable def misfit {n : ℕ} (A B : Fin n → ℝ) (b : ℝ) : ℝ :=
  ∑ t, ((A t - windowMean A) - b * (B t - windowMean B)) ^ 2

/-- Misfit expanded as a quadratic in the trial ratio. -/
lemma misfit_expand {n : ℕ} (A B : Fin n → ℝ) (b : ℝ) :
    misfit A B b = ∑ t, (A t - windowMean A) ^ 2
      - 2 * b * ∑ t, (B t - windowMean B) * (A t - windowMean A)
      + b ^ 2 * ∑ t, (B t - windowMean B) ^ 2 := by
  unfold misfit
  rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
  exact Finset.sum_congr rfl (fun t _ => by ring)

/-- B's sum of squared deviations is positive when B is not constant. -/
lemma sumsq_pos {n : ℕ} (B : Fin n → ℝ) (hB : ∃ i j, B i ≠ B j) :
    0 < ∑ t, (B t - windowMean B) ^ 2 := by
  obtain ⟨i, j, hij⟩ := hB
  have h0 : 0 ≤ ∑ t, (B t - windowMean B) ^ 2 :=
    Finset.sum_nonneg (fun t _ => sq_nonneg _)
  rcases h0.lt_or_eq with h | h
  · exact h
  · exfalso
    have h' := (Finset.sum_eq_zero_iff_of_nonneg (fun t _ => sq_nonneg (B t - windowMean B))).1 h.symm
    have hi := h' i (Finset.mem_univ _)
    have hj := h' j (Finset.mem_univ _)
    have hi' : B i = windowMean B := by nlinarith [sq_nonneg (B i - windowMean B)]
    have hj' : B j = windowMean B := by nlinarith [sq_nonneg (B j - windowMean B)]
    exact hij (hi'.trans hj'.symm)

#print axioms misfit_expand
#print axioms sumsq_pos

/-- Half of a symmetric double sum with zero diagonal is the sum over pairs `i < j`. -/
lemma two_mul_sum_Ioi {n : ℕ} (f : Fin n → Fin n → ℝ) (hsymm : ∀ i j, f i j = f j i)
    (hdiag : ∀ i, f i i = 0) :
    2 * ∑ i : Fin n, ∑ j ∈ Ioi i, f i j = ∑ i : Fin n, ∑ j, f i j := by
  have hIoi : ∀ i : Fin n, ∑ j ∈ Ioi i, f i j = ∑ j, if i < j then f i j else 0 := by
    intro i
    rw [← Finset.sum_filter]
    congr 1
    ext j; simp
  simp_rw [hIoi]
  have hswap : ∑ i : Fin n, ∑ j : Fin n, (if i < j then f i j else 0)
      = ∑ i : Fin n, ∑ j : Fin n, (if j < i then f i j else 0) := by
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl (fun i _ => Finset.sum_congr rfl (fun j _ => ?_))
    rw [hsymm]
  rw [two_mul]
  nth_rewrite 2 [hswap]
  rw [← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  rw [← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl (fun j _ => ?_)
  rcases lt_trichotomy i j with h | h | h
  · simp [h, not_lt.mpr h.le]
  · subst h; simp [hdiag]
  · simp [h, not_lt.mpr h.le]

#print axioms two_mul_sum_Ioi

/-- Least squares finds the ratio: when B's price is not the same on every day of the window,
the formula `β̂ = Σ (B_t - B̄)(A_t - Ā) / Σ (B_t - B̄)²` gives the trial ratio with the smallest
misfit, and every other trial ratio `b` has a strictly larger misfit. -/
theorem least_squares_hedge_ratio_minimises_misfit {n : ℕ} (A B : Fin n → ℝ)
    (hB : ∃ i j, B i ≠ B j) (b : ℝ) (hb : b ≠ hedgeRatio A B) :
    misfit A B (hedgeRatio A B) < misfit A B b := by
  have hC := sumsq_pos B hB
  rw [misfit_expand, misfit_expand]
  set C := ∑ t, (B t - windowMean B) ^ 2 with hCdef
  set S := ∑ t, (B t - windowMean B) * (A t - windowMean A) with hSdef
  have hβ : hedgeRatio A B = S / C := rfl
  have hS : S = hedgeRatio A B * C := by rw [hβ]; field_simp
  have hd : b - hedgeRatio A B ≠ 0 := sub_ne_zero.mpr hb
  have hpos : 0 < C * (b - hedgeRatio A B) ^ 2 := by positivity
  rw [hS]
  nlinarith [hpos]

/-- Pooling pairs of dates gives the same ratio: for any prices over `n` days,
`Σ_{i<j} (B_i - B_j)(A_i - A_j) = n Σ_t (B_t - B̄)(A_t - Ā)`, so the pooled slope
`Σ_{i<j} (B_i - B_j)(A_i - A_j) / Σ_{i<j} (B_i - B_j)²` equals the least-squares `β̂`. -/
theorem pairwise_slopes_eq_hedge_ratio {n : ℕ} (A B : Fin n → ℝ) :
    (∑ i : Fin n, ∑ j ∈ Ioi i, (B i - B j) * (A i - A j)
        = n * ∑ t, (B t - windowMean B) * (A t - windowMean A)) ∧
    (∑ i : Fin n, ∑ j ∈ Ioi i, (B i - B j) * (A i - A j))
        / (∑ i : Fin n, ∑ j ∈ Ioi i, (B i - B j) ^ 2) = hedgeRatio A B := by
  have key : ∀ X Y : Fin n → ℝ, ∑ i : Fin n, ∑ j ∈ Ioi i, (X i - X j) * (Y i - Y j)
      = n * ∑ t, (X t - windowMean X) * (Y t - windowMean Y) := by
    intro X Y
    have h2 := two_mul_sum_Ioi (fun i j => (X i - X j) * (Y i - Y j))
      (fun i j => by ring) (fun i => by ring)
    have hfull : ∑ i : Fin n, ∑ j, (X i - X j) * (Y i - Y j)
        = 2 * (n * ∑ t, X t * Y t - (∑ t, X t) * ∑ t, Y t) := by
      have e : ∑ i : Fin n, ∑ j, (X i - X j) * (Y i - Y j)
          = ∑ i : Fin n, ∑ j : Fin n, (X i * Y i - X i * Y j - X j * Y i + X j * Y j) :=
        Finset.sum_congr rfl (fun i _ => Finset.sum_congr rfl (fun j _ => by ring))
      rw [e]
      simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib, Finset.sum_const,
        Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, ← Finset.mul_sum, ← Finset.sum_mul]
      ring
    have hmean : n * ∑ t, (X t - windowMean X) * (Y t - windowMean Y)
        = n * ∑ t, X t * Y t - (∑ t, X t) * ∑ t, Y t := by
      have e : ∑ t, (X t - windowMean X) * (Y t - windowMean Y)
          = ∑ t, (X t * Y t - X t * windowMean Y - windowMean X * Y t
              + windowMean X * windowMean Y) :=
        Finset.sum_congr rfl (fun t _ => by ring)
      rw [e]
      simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib, Finset.sum_const,
        Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, ← Finset.mul_sum, ← Finset.sum_mul]
      rcases Nat.eq_zero_or_pos n with hn | hn
      · subst hn; simp
      · have hn' : (n : ℝ) ≠ 0 := by positivity
        unfold windowMean
        field_simp
        ring
    linarith
  refine ⟨key B A, ?_⟩
  have hsq : ∀ i : Fin n, ∑ j ∈ Ioi i, (B i - B j) ^ 2 = ∑ j ∈ Ioi i, (B i - B j) * (B i - B j) :=
    fun i => Finset.sum_congr rfl (fun j _ => by ring)
  have hsq2 : ∑ t, (B t - windowMean B) ^ 2 = ∑ t, (B t - windowMean B) * (B t - windowMean B) :=
    Finset.sum_congr rfl (fun t _ => by ring)
  rw [Finset.sum_congr rfl (fun i _ => hsq i), key B A, key B B, hedgeRatio, hsq2]
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn; simp
  · have hn' : (n : ℝ) ≠ 0 := by positivity
    exact mul_div_mul_left _ _ hn'

/-- The position: hold `N_A` shares of A and short `N_B = β̂ N_A` shares of B. Its value on day
`t` is `N_A A_t - N_B B_t = N_A (s_t + ĉ)`, and its profit from day `t₀` to day `t₁` is
`N_A (s_{t₁} - s_{t₀})`: it gains only from the spread. -/
theorem position_profit_eq_shares_times_spread_change {n : ℕ} (A B : Fin n → ℝ) (NA : ℝ)
    (t t₀ t₁ : Fin n) :
    NA * A t - hedgeRatio A B * NA * B t = NA * (spread A B t + intercept A B) ∧
    (NA * A t₁ - hedgeRatio A B * NA * B t₁) - (NA * A t₀ - hedgeRatio A B * NA * B t₀)
      = NA * (spread A B t₁ - spread A B t₀) := by
  unfold spread
  constructor <;> ring

-- The six-date table: B = 100, 101, 99, 100, 102, 101 and A = 130.0, 132.3, 129.7, 128.0,
-- 132.6, 131.3 dollars give the hedge ratio 1.3 exactly.
example : hedgeRatio ![130, 1323 / 10, 1297 / 10, 128, 1326 / 10, 1313 / 10]
    ![100, 101, 99, 100, 102, 101] = 13 / 10 := by
  norm_num [hedgeRatio, windowMean, Fin.sum_univ_succ]

-- The table's sums: B's own movement 5.5 and the joint movement 7.15, ratio 1.3.
example : (1 / 4 + 1 / 4 + 9 / 4 + 1 / 4 + 9 / 4 + 1 / 4 : ℚ) = 11 / 2 := by norm_num
example : (143 / 20 : ℚ) / (11 / 2) = 13 / 10 := by norm_num

-- The pull-back on the table: (0 + 0 - 3 - 4 + 0) / (0 + 1 + 1 + 4 + 0) = -7/6.
example : ((0 * 1 + 1 * 0 + 1 * (-3) + (-2) * 2 + 0 * 0) : ℚ) / (0 + 1 + 1 + 4 + 0) = -7 / 6 := by
  norm_num

-- Unexplained changes, squared and summed: 1 + (7/6)² + (11/6)² + (1/3)² + 0 = 35/6.
example : (1 + (7 / 6) ^ 2 + (11 / 6) ^ 2 + (1 / 3) ^ 2 + 0 : ℚ) = 35 / 6 := by norm_num

-- τ² = ρ̂² / se² = (7/6)² / ((35/6 / (5 - 1)) / 6) = 28/5, so τ = -14/√35.
example : ((7 / 6) ^ 2 : ℚ) / ((35 / 6 / (5 - 1)) / 6) = 14 ^ 2 / 35 := by norm_num

-- The legs at date 3: long 100 A at $128 and short 130 B at $100.
example : 100 * 128 = 12800 ∧ 130 * 100 = 13000 := by decide

-- Profit from date 3 to 4, leg by leg and from the spread: both $200.
example : (100 * (1326 / 10 - 128) - 130 * (102 - 100) : ℚ) = 200 := by norm_num
example : (100 * (0 - (-2)) : ℚ) = 200 := by norm_num

-- Forcing equal dollars with 128 B shares: a $10 move in B leaves $20 unhedged.
example : (100 * (13 / 10) * 10 - 128 * 10 : ℚ) = 20 := by norm_num

#print axioms least_squares_hedge_ratio_minimises_misfit
#print axioms pairwise_slopes_eq_hedge_ratio
#print axioms position_profit_eq_shares_times_spread_change
