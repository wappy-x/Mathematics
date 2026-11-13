-- Annuities: the sum of n discount factors collapses to (1 - (1+i)^(-n)) / i, the payment loan / factor clears the loan exactly, and the factor tends to 1/i exactly when the rate is above zero.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Finset Filter Topology

/-! The period rate is `i`. A payment `k` periods away has discount factor `(1 + i) ^ (-k)`.
The annuity factor `a_n(i)` is `∑ k ∈ Icc 1 n, (1 + i) ^ (-k)`: today's value of one dollar
at the end of each of `n` periods. -/

/-- One step of the annuity factor: multiplying the `m + 1`-period factor by `1 + i`
gives one plus the `m`-period factor. -/
theorem annuity_factor_step (x : ℝ) (hx : x ≠ 0) (m : ℕ) :
    x * ∑ k ∈ Icc 1 (m + 1), x ^ (-(k : ℤ)) = 1 + ∑ k ∈ Icc 1 m, x ^ (-(k : ℤ)) := by
  induction m with
  | zero => simp [hx]
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih, Finset.sum_Icc_succ_top (by omega)]
    have : x * x ^ (-((m + 1 + 1 : ℕ) : ℤ)) = x ^ (-((m + 1 : ℕ) : ℤ)) := by
      simp only [zpow_neg, zpow_natCast, pow_succ]
      field_simp
    rw [this]; ring

/-- The annuity factor in closed form: the value today of one dollar at the end of each of
`n` periods, the sum of the `n` discount factors `(1 + i) ^ (-k)`, equals one minus the discount
factor of the last payment, divided by the period rate (for a nonzero rate, with `1 + i ≠ 0`
so that every discount factor is defined). -/
theorem annuity_factor_closed_form (i : ℝ) (h1 : 1 + i ≠ 0) (hi : i ≠ 0) (n : ℕ) :
    ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ)) = (1 - (1 + i) ^ (-(n : ℤ))) / i := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    simp only [zpow_neg, zpow_natCast, pow_succ]
    field_simp
    ring

/-- The loan schedule. Start with the loan `B 0 = L`; each period interest is added and the
payment lands, `B (k + 1) = (1 + i) * B k - A`. If the rate is above `-1`, the contract has
`n ≥ 1` payments, and the payment is the loan divided by the annuity factor, then after `k ≤ n`
payments the balance is the value of the `n - k` payments still due, and equally the loan grown
forward less the payments grown forward (`A` times the accumulation factor `s_k(i)`);
after the last payment the balance is exactly zero. -/
theorem level_payment_clears_loan (i L A : ℝ) (n : ℕ) (B : ℕ → ℝ)
    (hi : -1 < i) (hn : 0 < n)
    (hA : A = L / ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ)))
    (hB0 : B 0 = L) (hB : ∀ k, B (k + 1) = (1 + i) * B k - A) :
    (∀ k ≤ n,
      B k = A * ∑ j ∈ Icc 1 (n - k), (1 + i) ^ (-(j : ℤ)) ∧
      B k = L * (1 + i) ^ k - A * ∑ j ∈ range k, (1 + i) ^ j) ∧
    B n = 0 := by
  have hx : (0 : ℝ) < 1 + i := by linarith
  have hx0 : (1 + i) ≠ 0 := hx.ne'
  have hF : (0 : ℝ) < ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ)) := by
    apply Finset.sum_pos
    · intro k _; exact zpow_pos hx _
    · exact ⟨1, by simp; omega⟩
  have hL : L = A * ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ)) := by
    rw [hA]; field_simp
  have h1 : ∀ k ≤ n, B k = A * ∑ j ∈ Icc 1 (n - k), (1 + i) ^ (-(j : ℤ)) := by
    intro k
    induction k with
    | zero => intro _; simpa [hB0] using hL
    | succ k ih =>
      intro hk
      have e : n - k = (n - (k + 1)) + 1 := by omega
      rw [hB, ih (by omega), e, ← mul_assoc, mul_comm (1 + i) A, mul_assoc,
        annuity_factor_step _ hx0]
      ring
  have h2 : ∀ k, B k = L * (1 + i) ^ k - A * ∑ j ∈ range k, (1 + i) ^ j := by
    intro k
    induction k with
    | zero => simp [hB0]
    | succ k ih =>
      rw [hB, ih, Finset.sum_range_succ', pow_succ]
      simp only [pow_succ, ← Finset.sum_mul]
      ring
  refine ⟨fun k hk => ⟨h1 k hk, h2 k⟩, ?_⟩
  rw [h1 n le_rfl]; simp

/-- The perpetuity: for a rate above zero the annuity factor tends to `1 / i` as the number of
payments grows; for a rate in `(-1, 0]` the discounted payments do not shrink and the factor
grows without bound, so no perpetuity value exists. -/
theorem perpetuity_factor_limit (i : ℝ) (hi : -1 < i) :
    (0 < i → Tendsto (fun n : ℕ => ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ))) atTop (𝓝 (1 / i))) ∧
    (i ≤ 0 → Tendsto (fun n : ℕ => ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ))) atTop atTop) := by
  have hx : (0 : ℝ) < 1 + i := by linarith
  constructor
  · intro hi0
    have hcf : (fun n : ℕ => ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ))) =
        fun n : ℕ => (1 - ((1 + i)⁻¹) ^ n) / i := by
      funext n
      rw [annuity_factor_closed_form i hx.ne' hi0.ne' n, zpow_neg, zpow_natCast, inv_pow]
    rw [hcf]
    have h0 : Tendsto (fun n : ℕ => ((1 + i)⁻¹) ^ n) atTop (𝓝 0) :=
      tendsto_pow_atTop_nhds_zero_of_lt_one (inv_nonneg.mpr hx.le)
        (inv_lt_one_of_one_lt₀ (by linarith))
    have := ((tendsto_const_nhds (x := (1 : ℝ))).sub h0).div_const i
    simpa using this
  · intro hi0
    apply tendsto_atTop_mono _ tendsto_natCast_atTop_atTop
    intro n
    calc (n : ℝ) = ∑ k ∈ Icc 1 n, (1 : ℝ) := by simp
      _ ≤ ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ)) := by
        apply Finset.sum_le_sum
        intro k _
        exact one_le_zpow_of_nonpos₀ hx (by linarith) (by omega)

/-! The card's exact worked numbers. The monthly rate is `5/100 / 12 = 1/240`. -/

-- The monthly rate: 5 percent a year cut into 12 pieces is 1/240 a month.
example : (5 / 100 : ℚ) / 12 = 1 / 240 := by norm_num

-- Interest-only (perpetuity) payment on 200,000 at 1/240 a month: 2500/3 = 833.33...
example : (200000 : ℚ) * (1 / 240) = 2500 / 3 := by norm_num

-- 5 percent charged flat on 200,000 for 25 years, split 300 ways: 1,500.
example : (200000 + 200000 * (5 / 100) * 25 : ℚ) / 300 = 1500 := by norm_num

-- The house bond: 60 a year for 5 years plus 1,000 at the end, at a 5 percent yield.
-- Coupons as 60 times the five-year annuity factor in closed form, plus the discounted face,
-- equal the six payments discounted one at a time.
example :
    60 * ((1 - (21 / 20 : ℚ) ^ (-(5 : ℤ))) / (1 / 20)) + 1000 * (21 / 20 : ℚ) ^ (-(5 : ℤ)) =
      60 * (21 / 20 : ℚ) ^ (-(1 : ℤ)) + 60 * (21 / 20 : ℚ) ^ (-(2 : ℤ)) +
      60 * (21 / 20 : ℚ) ^ (-(3 : ℤ)) + 60 * (21 / 20 : ℚ) ^ (-(4 : ℤ)) +
      60 * (21 / 20 : ℚ) ^ (-(5 : ℤ)) + 1000 * (21 / 20 : ℚ) ^ (-(5 : ℤ)) := by norm_num

#print axioms annuity_factor_step
#print axioms annuity_factor_closed_form
#print axioms level_payment_clears_loan
#print axioms perpetuity_factor_limit
