-- Derangements: the number of shuffles of n names with nobody on their own name equals the alternating sieve sum of (-1)^k C(n, k) (n - k)!, which is also n!/k! summed with signs, obeys D(n) = (n - 1)(D(n - 1) + D(n - 2)) from D(0) = 1, D(1) = 0, and is the nearest whole number to n!/e from one person up, with the share D(n)/n! closing on 1/e.
import Mathlib.Combinatorics.Derangements.Exponential
import Mathlib.Algebra.Order.Round
import Mathlib.Tactic.NormNum

open Finset

theorem card_fin_derangements_eq_num (n : ℕ) :
    Fintype.card {σ : Equiv.Perm (Fin n) // ∀ i, σ i ≠ i} = numDerangements n := by
  rw [← card_derangements_fin_eq_numDerangements]
  exact Fintype.card_congr (Equiv.refl _)

theorem fact_div_fact_eq (n k : ℕ) (hk : k ≤ n) :
    n.factorial / k.factorial = n.choose k * (n - k).factorial := by
  apply Nat.div_eq_of_eq_mul_left (Nat.factorial_pos k)
  rw [mul_right_comm, Nat.choose_mul_factorial_mul_factorial hk]

theorem asc_eq_fact_div (n k : ℕ) (hk : k ≤ n) :
    (k + 1).ascFactorial (n - k) = n.factorial / k.factorial := by
  rw [Nat.ascFactorial_eq_div, Nat.add_sub_cancel' hk]

theorem num_sieve_div (n : ℕ) :
    (numDerangements n : ℤ) =
      ∑ k ∈ range (n + 1), (-1 : ℤ) ^ k * ((n.factorial / k.factorial : ℕ) : ℤ) := by
  rw [numDerangements_sum]
  refine Finset.sum_congr rfl fun k hk => ?_
  rw [asc_eq_fact_div n k (Finset.mem_range_succ_iff.mp hk)]

theorem num_real_eq (n : ℕ) :
    (numDerangements n : ℝ) =
      (n.factorial : ℝ) * ∑ k ∈ range (n + 1), (-1 : ℝ) ^ k / (k.factorial : ℝ) := by
  have h := congrArg (fun z : ℤ => (z : ℝ)) (num_sieve_div n)
  simp only [Int.cast_natCast, Int.cast_sum, Int.cast_mul, Int.cast_pow, Int.cast_neg,
    Int.cast_one] at h
  rw [h, Finset.mul_sum]
  refine Finset.sum_congr rfl fun k hk => ?_
  have hk' : k ≤ n := Finset.mem_range_succ_iff.mp hk
  rw [Nat.cast_div (Nat.factorial_dvd_factorial hk') (by positivity)]
  field_simp

#print axioms card_fin_derangements_eq_num
#print axioms fact_div_fact_eq
#print axioms asc_eq_fact_div
#print axioms num_sieve_div
#print axioms num_real_eq

/-- The sieve count of derangements. For every number `n` of people, the draws (shuffles of
`n` names, each name drawn exactly once) in which nobody holds their own name number
`D(n) = ∑_{k=0}^{n} (-1)^k C(n, k) (n - k)! = ∑_{k=0}^{n} (-1)^k n!/k!`. -/
theorem derangements_count_by_sieve (n : ℕ) :
    ((Fintype.card {σ : Equiv.Perm (Fin n) // ∀ i, σ i ≠ i} : ℕ) : ℤ) =
        ∑ k ∈ range (n + 1), (-1 : ℤ) ^ k * ((n.choose k * (n - k).factorial : ℕ) : ℤ) ∧
      ((Fintype.card {σ : Equiv.Perm (Fin n) // ∀ i, σ i ≠ i} : ℕ) : ℤ) =
        ∑ k ∈ range (n + 1), (-1 : ℤ) ^ k * ((n.factorial / k.factorial : ℕ) : ℤ) := by
  rw [card_fin_derangements_eq_num, num_sieve_div]
  refine ⟨Finset.sum_congr rfl fun k hk => ?_, rfl⟩
  rw [fact_div_fact_eq n k (Finset.mem_range_succ_iff.mp hk)]

/-- The recurrence. With `D(n)` the number of shuffles of `n` names with nobody on their own
name: the seeds are `D(0) = 1` and `D(1) = 0`, every later count is
`D(n) = (n - 1)(D(n - 1) + D(n - 2))`, and the shorter form is `D(n) = n D(n - 1) + (-1)^n`. -/
theorem derangements_recurrence :
    Fintype.card {σ : Equiv.Perm (Fin 0) // ∀ i, σ i ≠ i} = 1 ∧
      Fintype.card {σ : Equiv.Perm (Fin 1) // ∀ i, σ i ≠ i} = 0 ∧
      (∀ n : ℕ, 2 ≤ n →
        Fintype.card {σ : Equiv.Perm (Fin n) // ∀ i, σ i ≠ i} =
          (n - 1) * (Fintype.card {σ : Equiv.Perm (Fin (n - 1)) // ∀ i, σ i ≠ i} +
            Fintype.card {σ : Equiv.Perm (Fin (n - 2)) // ∀ i, σ i ≠ i})) ∧
      (∀ n : ℕ, 1 ≤ n →
        ((Fintype.card {σ : Equiv.Perm (Fin n) // ∀ i, σ i ≠ i} : ℕ) : ℤ) =
          (n : ℤ) * ((Fintype.card {σ : Equiv.Perm (Fin (n - 1)) // ∀ i, σ i ≠ i} : ℕ) : ℤ) +
            (-1 : ℤ) ^ n) := by
  simp only [card_fin_derangements_eq_num]
  refine ⟨rfl, rfl, fun n hn => ?_, fun n hn => ?_⟩
  · obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le' hn
    rw [numDerangements_add_two]
    simp only [Nat.add_sub_cancel, show m + 2 - 1 = m + 1 by omega]
    ring
  · obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le' hn
    rw [numDerangements_succ, Nat.add_sub_cancel]
    push_cast
    ring

/-- The share and the number `e`. The clean share `D(n)/n!` closes on `1/e` as the draw grows,
and from one person up `D(n)` is the nearest whole number to `n!/e`. -/
theorem derangements_share_and_rounding :
    Filter.Tendsto
        (fun n : ℕ => (Fintype.card {σ : Equiv.Perm (Fin n) // ∀ i, σ i ≠ i} : ℝ) /
          (n.factorial : ℝ))
        Filter.atTop (nhds (1 / Real.exp 1)) ∧
      ∀ n : ℕ, 1 ≤ n →
        round ((n.factorial : ℝ) / Real.exp 1) =
          (Fintype.card {σ : Equiv.Perm (Fin n) // ∀ i, σ i ≠ i} : ℤ) := by
  simp only [card_fin_derangements_eq_num]
  refine ⟨?_, fun n hn => ?_⟩
  · rw [one_div, ← Real.exp_neg]
    exact numDerangements_tendsto_inv_e
  · rw [round_eq, Int.floor_eq_iff]
    have hD : ((numDerangements n : ℤ) : ℝ) = (numDerangements n : ℝ) := Int.cast_natCast _
    rw [hD]
    have he : (n.factorial : ℝ) / Real.exp 1 = (n.factorial : ℝ) * Real.exp (-1) := by
      rw [Real.exp_neg]; ring
    rw [he]
    -- the distance between n!/e and D(n) is below 1/2
    suffices h : |(n.factorial : ℝ) * Real.exp (-1) - numDerangements n| < 1 / 2 by
      rw [abs_lt] at h
      constructor <;> linarith [h.1, h.2]
    rcases Nat.lt_or_ge n 2 with h2 | h2
    · obtain rfl : n = 1 := by omega
      have hgt : (2 : ℝ) < Real.exp 1 := by
        have := Real.add_one_lt_exp (x := (1 : ℝ)) one_ne_zero
        linarith
      have hpos : 0 < Real.exp (-1) := Real.exp_pos _
      have hlt : Real.exp (-1) < 1 / 2 := by
        rw [Real.exp_neg, inv_eq_one_div, div_lt_div_iff₀ (Real.exp_pos 1) (by norm_num)]
        linarith
      simp only [Nat.factorial_one, Nat.cast_one, numDerangements_one, Nat.cast_zero, one_mul,
        sub_zero, abs_of_pos hpos]
      exact hlt
    · have hb := Real.exp_bound (x := -1) (by simp) (n := n + 1) (by omega)
      rw [num_real_eq, ← mul_sub, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < n.factorial)]
      simp only [abs_neg, abs_one, one_pow, one_mul] at hb
      calc (n.factorial : ℝ) * |Real.exp (-1) - ∑ k ∈ range (n + 1), (-1 : ℝ) ^ k / (k.factorial : ℝ)|
          ≤ (n.factorial : ℝ) * (((n + 1).succ : ℕ) / ((n + 1).factorial * (n + 1 : ℕ))) :=
            mul_le_mul_of_nonneg_left hb (by positivity)
        _ = ((n : ℝ) + 2) / (((n : ℝ) + 1) * ((n : ℝ) + 1)) := by
            rw [Nat.factorial_succ]
            push_cast
            field_simp
            ring
        _ < 1 / 2 := by
            have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast h2
            rw [div_lt_div_iff₀ (by positivity) (by norm_num)]
            nlinarith

-- Secret Santa among six colleagues: 6! = 720 draws in all, 265 with nobody on their own name.
example : Nat.factorial 6 = 720 := by decide
example : Fintype.card {σ : Equiv.Perm (Fin 6) // ∀ i, σ i ≠ i} = 265 := by decide +kernel
-- The counts D(0) to D(5) by listing: 1, 0, 1, 2, 9, 44.
example : Fintype.card {σ : Equiv.Perm (Fin 0) // ∀ i, σ i ≠ i} = 1 ∧
    Fintype.card {σ : Equiv.Perm (Fin 1) // ∀ i, σ i ≠ i} = 0 ∧
    Fintype.card {σ : Equiv.Perm (Fin 2) // ∀ i, σ i ≠ i} = 1 ∧
    Fintype.card {σ : Equiv.Perm (Fin 3) // ∀ i, σ i ≠ i} = 2 ∧
    Fintype.card {σ : Equiv.Perm (Fin 4) // ∀ i, σ i ≠ i} = 9 ∧
    Fintype.card {σ : Equiv.Perm (Fin 5) // ∀ i, σ i ≠ i} = 44 := by decide +kernel
-- The sieve at six people, term by term: 720 − 720 + 360 − 120 + 30 − 6 + 1 = 265.
example : Nat.choose 6 2 = 15 ∧ Nat.factorial 4 = 24 ∧ Nat.choose 6 2 * Nat.factorial 4 = 360 := by
  decide
example : (720 : ℤ) - 720 + 360 - 120 + 30 - 6 + 1 = 265 := by norm_num
example : ∑ k ∈ range 7, (-1 : ℤ) ^ k * ((Nat.choose 6 k * Nat.factorial (6 - k) : ℕ) : ℤ) = 265 := by
  decide
-- Running totals of the sieve at six people: 720, 0, 360, 240, 270, 264, 265.
example : (720 : ℤ) - 720 = 0 ∧ (0 : ℤ) + 360 = 360 ∧ (360 : ℤ) - 120 = 240 ∧
    (240 : ℤ) + 30 = 270 ∧ (270 : ℤ) - 6 = 264 ∧ (264 : ℤ) + 1 = 265 := by norm_num
-- The sieve gives 1, 0, 1, 2, 9, 44, 265, 1854, 14833 for n = 0 to 8.
example : (List.range 9).map (fun n => ∑ k ∈ range (n + 1),
    (-1 : ℤ) ^ k * ((n.factorial / k.factorial : ℕ) : ℤ)) =
    [1, 0, 1, 2, 9, 44, 265, 1854, 14833] := by decide
-- By recurrence and in one step: 5 × (44 + 9) = 265 and 6 × 44 + 1 = 265.
example : 5 * (44 + 9) = 265 ∧ 5 * 53 = 265 ∧ 6 * 44 + 1 = 265 := by decide
-- Names put back after each draw, own name barred: 5^6 = 15625 lists.
example : 5 ^ 6 = 15625 := by decide
-- The mistakes: 720 − 6 × 120 = 0, dropping the last sieve term gives 264, 5 × 44 + 9 = 229.
example : 720 - 6 * 120 = 0 ∧ 265 - 1 = 264 ∧ 5 * 44 + 9 = 229 := by decide

#print axioms derangements_count_by_sieve
#print axioms derangements_recurrence
#print axioms derangements_share_and_rounding
