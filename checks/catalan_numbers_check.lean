-- Catalan numbers: the paths of n up-steps and n down-steps that never dip below the start number C(2n, n)/(n + 1), which also equals C(2n, n) - C(2n, n + 1) and obeys the first-return recurrence.
import Mathlib.Combinatorics.Enumerative.DyckWord
import Mathlib.Tactic.NormNum

open DyckWord

/-- Of the `C(2n, n)` orders of `n` five-dollar notes (up-steps `U`) and `n` ten-dollar notes
(down-steps `D`), the ones that never strand the cashier, that is, the paths whose running count
never dips below the start, number `C(2n, n)/(n + 1)`. In Mathlib these paths are the Dyck words
of semilength `n`: lists with as many `U`s as `D`s in which no prefix has more `D`s than `U`s. -/
theorem card_never_dip_paths_eq_choose_div (n : ℕ) :
    Fintype.card { p : DyckWord // p.semilength = n } = Nat.choose (2 * n) n / (n + 1) := by
  rw [card_dyckWord_semilength_eq_catalan, catalan_eq_centralBinom_div, Nat.centralBinom_eq_two_mul_choose]

/-- The reflection count: the safe orders are all `C(2n, n)` orders less the stranded ones, and
the stranded ones number `C(2n, n + 1)`, so `Cat(n) = C(2n, n) - C(2n, n + 1)`. -/
theorem card_never_dip_paths_eq_choose_sub_choose (n : ℕ) :
    Fintype.card { p : DyckWord // p.semilength = n } =
      Nat.choose (2 * n) n - Nat.choose (2 * n) (n + 1) := by
  rw [card_dyckWord_semilength_eq_catalan]
  have h1 := succ_mul_catalan_eq_centralBinom n
  rw [Nat.centralBinom_eq_two_mul_choose] at h1
  have h2 := Nat.choose_succ_right_eq (2 * n) n
  rw [← h1] at h2 ⊢
  have h3 : (2 * n).choose (n + 1) = n * catalan n := by
    have : (2 * n - n) = n := by omega
    rw [this] at h2
    have h4 : (2 * n).choose (n + 1) * (n + 1) = (n * catalan n) * (n + 1) := by
      rw [h2]; ring
    exact Nat.eq_of_mul_eq_mul_right (Nat.succ_pos n) h4
  rw [h3]
  have : (n + 1) * catalan n = n * catalan n + catalan n := by ring
  omega

/-- The first-return recurrence: splitting a safe queue of `n + 1` pairs at the first moment the
till is empty again gives `Cat(n + 1) = ∑_{i=0}^{n} Cat(i) Cat(n - i)`, with `Cat(0) = 1`. -/
theorem card_never_dip_paths_first_return (n : ℕ) :
    Fintype.card { p : DyckWord // p.semilength = 0 } = 1 ∧
    Fintype.card { p : DyckWord // p.semilength = n + 1 } =
      ∑ i ∈ Finset.range (n + 1),
        Fintype.card { p : DyckWord // p.semilength = i } *
          Fintype.card { p : DyckWord // p.semilength = n - i } := by
  simp only [card_dyckWord_semilength_eq_catalan]
  refine ⟨catalan_zero, ?_⟩
  rw [catalan_succ, Fin.sum_univ_eq_sum_range (fun i => catalan i * catalan (n - i))]

-- Five pairs: 252 orders in all, 210 stranded, 252 - 210 = 42 safe, and 252 / 6 = 42.
example : Nat.choose 10 5 = 252 ∧ Nat.choose 10 6 = 210 ∧ 252 - 210 = 42 ∧ 252 / (5 + 1) = 42 := by
  decide

-- Three pairs: 20 orders, 5 of them safe.
example : Nat.choose 6 3 = 20 ∧ Nat.choose 6 3 / (3 + 1) = 5 := by decide

-- First return at five pairs: 1x14 + 1x5 + 2x2 + 5x1 + 14x1 = 42.
example : 1 * 14 + 1 * 5 + 2 * 2 + 5 * 1 + 14 * 1 = 42 := by norm_num

-- Cat(0) to Cat(9) from the closed form: 1 1 2 5 14 42 132 429 1430 4862.
example : (List.range 10).map (fun n => Nat.choose (2 * n) n / (n + 1)) =
    [1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862] := by decide

-- Mistake 3: n read as the 10 customers gives Cat(10) = 16796, a queue of twenty.
example : Nat.choose 20 10 / (10 + 1) = 16796 := by decide

-- Mistake 4: the ten customers told apart, 42 x 5! x 5! = 604800.
example : 42 * Nat.factorial 5 * Nat.factorial 5 = 604800 := by decide

#print axioms card_never_dip_paths_eq_choose_div
#print axioms card_never_dip_paths_eq_choose_sub_choose
#print axioms card_never_dip_paths_first_return
