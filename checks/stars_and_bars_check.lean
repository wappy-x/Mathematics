-- Stars and bars: n identical items go into k labelled boxes in C(n + k - 1, k - 1) ways, in C(n - 1, k - 1) ways when no box may be empty, and a whole number n is an ordered sum of positive parts in 2^(n - 1) ways.
import Mathlib.Combinatorics.Enumerative.Composition
import Mathlib.Data.Fin.Tuple.NatAntidiagonal
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Data.Finsupp.Multiset
import Mathlib.Data.Sym.Card

open Finset

/-- Stars and bars. Share n identical items among k labelled boxes (k at least 1), with no
ceiling on any box and empty boxes allowed. A sharing-out is just the count in each box, a
function from the k boxes to the whole numbers whose values add up to n. The number of
sharing-outs is C(n + k - 1, k - 1): choose which k - 1 of the n + k - 1 places in a row of
stars and bars hold the bars. -/
theorem stars_and_bars_count (n k : ℕ) (hk : 0 < k) :
    Nat.card {x : Fin k → ℕ // ∑ i, x i = n} = (n + k - 1).choose (k - 1) := by
  rw [← Nat.card_congr (Sym.equivNatSumOfFintype (Fin k) n), Nat.card_eq_fintype_card,
    Sym.card_sym_eq_choose, Fintype.card_fin]
  rw [add_comm k n, Nat.choose_symm_of_eq_add]
  omega

/-- No box empty. Share n identical items among k labelled boxes (k at least 1) so that every
box gets at least one item. The number of ways is C(n - 1, k - 1): put the k - 1 bars into the
n - 1 gaps between the items, at most one to a gap. When there are fewer items than boxes this
is 0: there is no way at all. -/
theorem stars_and_bars_no_empty_box (n k : ℕ) (hn : 0 < n) (hk : 0 < k) :
    Nat.card {x : Fin k → ℕ // (∀ i, 0 < x i) ∧ ∑ i, x i = n} = (n - 1).choose (k - 1) := by
  by_cases hkn : k ≤ n
  · have e : {x : Fin k → ℕ // (∀ i, 0 < x i) ∧ ∑ i, x i = n} ≃
        {y : Fin k → ℕ // ∑ i, y i = n - k} :=
      { toFun := fun x => ⟨fun i => x.1 i - 1, by
          obtain ⟨x, hpos, hsum⟩ := x
          have h1 : ∑ i, (x i - 1) + ∑ _i : Fin k, 1 = ∑ i, x i := by
            rw [← Finset.sum_add_distrib]
            exact Finset.sum_congr rfl fun i _ => Nat.sub_add_cancel (hpos i)
          simp at h1
          simp only
          omega⟩
        invFun := fun y => ⟨fun i => y.1 i + 1, fun i => Nat.succ_pos _, by
          obtain ⟨y, hsum⟩ := y
          simp only
          rw [Finset.sum_add_distrib]
          simp
          omega⟩
        left_inv := fun x => by
          ext i
          simp only
          have := x.2.1 i
          omega
        right_inv := fun y => by
          ext i
          simp }
    rw [Nat.card_congr e, stars_and_bars_count _ _ hk]
    congr 1
    omega
  · rw [not_le] at hkn
    have hempty : IsEmpty {x : Fin k → ℕ // (∀ i, 0 < x i) ∧ ∑ i, x i = n} := by
      refine ⟨fun ⟨x, hpos, hsum⟩ => ?_⟩
      have : ∑ _i : Fin k, 1 ≤ ∑ i, x i := Finset.sum_le_sum fun i _ => hpos i
      simp at this
      omega
    rw [Nat.card_of_isEmpty, Nat.choose_eq_zero_of_lt]
    omega

/-- Compositions. The ways to write a whole number n as an ordered sum of positive parts
(order counts, so 1 + 5 and 5 + 1 are two answers) number 2^(n - 1): each of the n - 1 gaps
between n stars is either cut or left alone. -/
theorem compositions_count (n : ℕ) :
    Fintype.card (Composition n) = 2 ^ (n - 1) := by
  exact composition_card n

-- The gelato tubs: 5 scoops across 3 flavours, C(5 + 3 - 1, 3 - 1) = C(7, 2) = 21.
example : (5 + 3 - 1).choose (3 - 1) = 21 := by decide
-- Every tub listed directly: 21 ways to give 3 flavours counts adding to 5.
example : (Finset.Nat.antidiagonalTuple 3 5).card = 21 := by decide
-- The four tubs in the table are among them.
example : ![5, 0, 0] ∈ Finset.Nat.antidiagonalTuple 3 5 ∧ ![2, 0, 3] ∈ Finset.Nat.antidiagonalTuple 3 5 ∧
    ![0, 5, 0] ∈ Finset.Nat.antidiagonalTuple 3 5 ∧ ![1, 2, 2] ∈ Finset.Nat.antidiagonalTuple 3 5 := by
  decide
-- The ladder: fix the chocolate at 0 to 5, the rest splits 6, 5, 4, 3, 2, 1 ways, adding to 21.
example : 6 + 5 + 4 + 3 + 2 + 1 = 21 := by decide
-- Every flavour used: 4 gaps between 5 stars, choose 2, gives 6.
example : (5 - 1).choose (3 - 1) = 6 := by decide
example : ((Finset.Nat.antidiagonalTuple 3 5).filter (fun x => ∀ i, 0 < x i)).card = 6 := by decide
-- Twelve tins on three shelves, none bare: C(12 - 1, 3 - 1) = C(11, 2) = 55.
example : (12 - 1).choose (3 - 1) = 55 := by decide
-- Hand one tin to each shelf first, then share 9 with empties allowed: C(9 + 3 - 1, 2) = 55.
example : (9 + 3 - 1).choose (3 - 1) = 55 := by decide
example : ((Finset.Nat.antidiagonalTuple 3 12).filter (fun x => ∀ i, 0 < x i)).card = 55 := by decide
-- Compositions of 6: 2^5 = 32, and split by number of parts, C(5, 0) to C(5, 5).
example : 2 ^ (6 - 1) = 32 := by decide
example : (List.range 6).map (Nat.choose 5) = [1, 5, 10, 10, 5, 1] := by decide
example : 1 + 5 + 10 + 10 + 5 + 1 = 32 := by decide
-- The wrong turns: C(7, 3) = 35, C(5, 2) = 10, C(4, 2) = 6.
example : Nat.choose 7 3 = 35 ∧ Nat.choose 5 2 = 10 ∧ Nat.choose 4 2 = 6 := by decide
-- The try-changing numbers: a fourth flavour gives C(8, 3) = 56, a sixth scoop C(8, 2) = 28.
example : (5 + 4 - 1).choose (4 - 1) = 56 ∧ (6 + 3 - 1).choose (3 - 1) = 28 := by decide

#print axioms stars_and_bars_count
#print axioms stars_and_bars_no_empty_box
#print axioms compositions_count
