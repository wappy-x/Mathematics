-- The par swap rate: with one curve that both forecasts and discounts, the only fixed rate that makes a new swap worth zero is one dollar at the start less one dollar at the end, divided by the annuity, and that ratio is the average of the forward rates weighted by each date's share of the annuity.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Finset

/-! The swap pays on dates `T_1, …, T_n`; date `T_0` is its start. `D i` is the discount factor
`D(T_i)`, today's price of one dollar paid at `T_i`, and `α i` is the accrual of period `i`, its
length as a fraction of a year. One curve both forecasts and discounts: the forward rate of
period `i` is read off the same `D` that discounts the payments. -/

/-- The forward rate for period `i`, read off the discount curve:
`F_i = (1 / α_i) * (D(T_{i-1}) / D(T_i) - 1)`. -/
noncomputable def forwardRate (α D : ℕ → ℝ) (i : ℕ) : ℝ :=
  (1 / α i) * (D (i - 1) / D i - 1)

/-- The annuity: the value today of one unit of rate paid on every fixed date,
`A = ∑_{i=1}^{n} α_i D(T_i)`. -/
noncomputable def annuity (n : ℕ) (α D : ℕ → ℝ) : ℝ :=
  ∑ i ∈ Icc 1 n, α i * D i

/-- The sum of successive drops in `D` telescopes. -/
theorem sum_Icc_drop_telescope (D : ℕ → ℝ) (n : ℕ) :
    ∑ i ∈ Icc 1 n, (D (i - 1) - D i) = D 0 - D n := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    simp

/-- Each floating payment, valued at its forward rate and discounted, is the drop in `D`. -/
theorem sum_alpha_forward_disc (n : ℕ) (α D : ℕ → ℝ)
    (hα : ∀ i ∈ Icc 1 n, 0 < α i) (hD : ∀ i ∈ Icc 1 n, 0 < D i) :
    ∑ i ∈ Icc 1 n, α i * forwardRate α D i * D i = D 0 - D n := by
  rw [← sum_Icc_drop_telescope D n]
  refine Finset.sum_congr rfl (fun i hi => ?_)
  have h1 := (hα i hi).ne'
  have h2 := (hD i hi).ne'
  unfold forwardRate
  field_simp

/-- The annuity is positive. -/
theorem annuity_pos (n : ℕ) (α D : ℕ → ℝ) (hn : 1 ≤ n)
    (hα : ∀ i ∈ Icc 1 n, 0 < α i) (hD : ∀ i ∈ Icc 1 n, 0 < D i) :
    0 < annuity n α D := by
  unfold annuity
  apply Finset.sum_pos
  · intro i hi; exact mul_pos (hα i hi) (hD i hi)
  · exact ⟨1, by simp; omega⟩

#print axioms sum_Icc_drop_telescope
#print axioms sum_alpha_forward_disc
#print axioms annuity_pos

/-- The card's main claim. Take a swap with `n ≥ 1` payment dates, positive accruals and
positive discount factors, and a notional `N > 0`. The fixed leg at rate `K` is worth
`N K A`; the floating leg, each payment valued at its forward rate and discounted, is worth
`∑ N α_i F_i D(T_i)`. Then the two legs are worth the same for exactly one fixed rate, the par
swap rate `S = (D(T_0) - D(T_n)) / A`, and that rate is the average of the forward rates
weighted by each date's share of the annuity, `w_i = α_i D(T_i) / A`. -/
theorem par_swap_rate_eq_weighted_average_of_forwards (n : ℕ) (N : ℝ) (α D : ℕ → ℝ)
    (hn : 1 ≤ n) (hN : 0 < N)
    (hα : ∀ i ∈ Icc 1 n, 0 < α i) (hD : ∀ i ∈ Icc 1 n, 0 < D i) :
    (∀ K : ℝ, N * K * annuity n α D = ∑ i ∈ Icc 1 n, N * α i * forwardRate α D i * D i ↔
      K = (D 0 - D n) / annuity n α D) ∧
    (D 0 - D n) / annuity n α D
      = ∑ i ∈ Icc 1 n, (α i * D i / annuity n α D) * forwardRate α D i := by
  have hA := annuity_pos n α D hn hα hD
  have hS := sum_alpha_forward_disc n α D hα hD
  have hsum : ∑ i ∈ Icc 1 n, N * α i * forwardRate α D i * D i = N * (D 0 - D n) := by
    rw [← hS, Finset.mul_sum]
    exact Finset.sum_congr rfl (fun i _ => by ring)
  refine ⟨fun K => ?_, ?_⟩
  · rw [hsum, eq_div_iff hA.ne']
    constructor
    · intro h
      have := mul_left_cancel₀ hN.ne' (by linarith [h] : N * (K * annuity n α D) = N * (D 0 - D n))
      exact this
    · intro h; rw [← h]; ring
  · rw [← hS, Finset.sum_div]
    exact Finset.sum_congr rfl (fun i _ => by ring)

/-- The weights `w_i = α_i D(T_i) / A` are positive and add to one, so the par swap rate lies
between the smallest and the largest forward rate: any bounds `m ≤ F_i ≤ M` that hold for every
period also hold for the par rate. -/
theorem par_swap_rate_between_forwards (n : ℕ) (α D : ℕ → ℝ)
    (hn : 1 ≤ n)
    (hα : ∀ i ∈ Icc 1 n, 0 < α i) (hD : ∀ i ∈ Icc 1 n, 0 < D i) :
    (∀ i ∈ Icc 1 n, 0 < α i * D i / annuity n α D) ∧
    ∑ i ∈ Icc 1 n, α i * D i / annuity n α D = 1 ∧
    ∀ m M : ℝ, (∀ i ∈ Icc 1 n, m ≤ forwardRate α D i ∧ forwardRate α D i ≤ M) →
      m ≤ (D 0 - D n) / annuity n α D ∧ (D 0 - D n) / annuity n α D ≤ M := by
  have hA := annuity_pos n α D hn hα hD
  have hS := sum_alpha_forward_disc n α D hα hD
  have hpar : (D 0 - D n) / annuity n α D
      = ∑ i ∈ Icc 1 n, (α i * D i / annuity n α D) * forwardRate α D i := by
    rw [← hS, Finset.sum_div]
    exact Finset.sum_congr rfl (fun i _ => by ring)
  have hw : ∀ i ∈ Icc 1 n, 0 < α i * D i / annuity n α D :=
    fun i hi => div_pos (mul_pos (hα i hi) (hD i hi)) hA
  have hone : ∑ i ∈ Icc 1 n, α i * D i / annuity n α D = 1 := by
    rw [← Finset.sum_div]
    exact div_self hA.ne'
  refine ⟨hw, hone, fun m M hmM => ⟨?_, ?_⟩⟩
  · rw [hpar]
    calc m = ∑ i ∈ Icc 1 n, (α i * D i / annuity n α D) * m := by
          rw [← Finset.sum_mul, hone, one_mul]
      _ ≤ _ := Finset.sum_le_sum (fun i hi =>
          mul_le_mul_of_nonneg_left (hmM i hi).1 (hw i hi).le)
  · rw [hpar]
    calc _ ≤ ∑ i ∈ Icc 1 n, (α i * D i / annuity n α D) * M :=
          Finset.sum_le_sum (fun i hi =>
            mul_le_mul_of_nonneg_left (hmM i hi).2 (hw i hi).le)
      _ = M := by rw [← Finset.sum_mul, hone, one_mul]

/-- The annuity turns a rate gap into money. A swap already on the books at fixed rate `K`, on
notional `N`, is worth to the side paying fixed the floating leg less the fixed leg,
`∑ N α_i (F_i - K) D(T_i)`, and this equals `N A (S - K)`, where `S` is the par swap rate. -/
theorem swap_value_eq_notional_annuity_rate_gap (n : ℕ) (N K : ℝ) (α D : ℕ → ℝ)
    (hn : 1 ≤ n)
    (hα : ∀ i ∈ Icc 1 n, 0 < α i) (hD : ∀ i ∈ Icc 1 n, 0 < D i) :
    ∑ i ∈ Icc 1 n, N * α i * (forwardRate α D i - K) * D i
      = N * annuity n α D * ((D 0 - D n) / annuity n α D - K) := by
  have hA := annuity_pos n α D hn hα hD
  have hS := sum_alpha_forward_disc n α D hα hD
  have h : ∑ i ∈ Icc 1 n, N * α i * (forwardRate α D i - K) * D i
      = N * (∑ i ∈ Icc 1 n, α i * forwardRate α D i * D i)
        - N * K * annuity n α D := by
    unfold annuity
    rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl (fun i _ => by ring)
  rw [h, hS]
  field_simp

/-! The card's curve, exactly, in fractions. The one-year forwards are 5.00, 4.60, 4.30, 4.10
and 4.00 percent, so the growth factors are 21/20, 523/500, 1043/1000, 1041/1000 and 26/25,
and each discount factor is one over the product of the growth factors up to that year. -/

-- The annuity is 4.380745 to six places: 75457915860 / 17224906153 exactly.
example :
    (1 / (21 / 20) + 1 / ((21 / 20) * (523 / 500)) + 1 / ((21 / 20) * (523 / 500) * (1043 / 1000))
      + 1 / ((21 / 20) * (523 / 500) * (1043 / 1000) * (1041 / 1000))
      + 1 / ((21 / 20) * (523 / 500) * (1043 / 1000) * (1041 / 1000) * (26 / 25)) : ℚ)
      = 75457915860 / 17224906153 := by norm_num

-- The par rate (1 - D(5)) / A is 4.421030 percent to six places, and it sits above the plain
-- average of the five forwards, 4.40 percent.
example :
    let A : ℚ := 75457915860 / 17224906153
    let D5 : ℚ := 1 / ((21 / 20) * (523 / 500) * (1043 / 1000) * (1041 / 1000) * (26 / 25))
    4421025 / 100000000 < (1 - D5) / A ∧ (1 - D5) / A < 4421035 / 100000000 ∧
      (50 / 1000 + 46 / 1000 + 43 / 1000 + 41 / 1000 + 40 / 1000) / 5 < (1 - D5) / A := by
  norm_num

-- The house swap, paying 4.50 percent fixed on 10 million, is worth N A (S - K) to the fixed
-- payer: -34,594.64 dollars, to the cent.
example :
    let A : ℚ := 75457915860 / 17224906153
    let D5 : ℚ := 1 / ((21 / 20) * (523 / 500) * (1043 / 1000) * (1041 / 1000) * (26 / 25))
    (-3459465 / 100 : ℚ) < 10000000 * A * ((1 - D5) / A - 45 / 1000) ∧
      10000000 * A * ((1 - D5) / A - 45 / 1000) < -3459464 / 100 := by
  norm_num

#print axioms par_swap_rate_eq_weighted_average_of_forwards
#print axioms par_swap_rate_between_forwards
#print axioms swap_value_eq_notional_annuity_rate_gap
