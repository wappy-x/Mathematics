-- Counting by multiplying series: the coefficient of x^n in a product of factors, each listing once the amounts one kind may contribute, equals the number of ways to pick one allowed amount per kind with total n, so the till's four coin factors give 49 piles for 50 cents and k all-ones factors give the stars-and-bars count.
import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.Data.Fin.Tuple.NatAntidiagonal
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Nat.Choose.Sum

open PowerSeries

/-- Each restriction becomes one factor, the factors are multiplied, and the count is one
coefficient. There are `k` kinds; kind `i` may contribute any amount in its set `S i`, and its
factor lists each allowed amount once (coefficient 1 on `x^a` for `a ∈ S i`, 0 elsewhere).
Then the coefficient of `x^n` in the product of the `k` factors is the number of piles worth
`n`: the choices of one allowed amount `a i ∈ S i` for every kind with `a 0 + ⋯ + a (k-1) = n`. -/
theorem coeff_prod_factors_eq_card_piles (k n : ℕ) (S : Fin k → Set ℕ)
    [∀ i, DecidablePred (· ∈ S i)] :
    coeff n (∏ i : Fin k, mk (fun m => if m ∈ S i then (1 : ℕ) else 0)) =
      ((Finset.Nat.antidiagonalTuple k n).filter (fun a => ∀ i, a i ∈ S i)).card := by
  classical
  rw [coeff_prod, Finset.card_filter]
  refine Finset.sum_bij' (fun l _ => ⇑l) (fun f _ => Finsupp.equivFunOnFinite.symm f)
    ?_ ?_ ?_ ?_ ?_
  · intro l hl
    rw [Finset.mem_finsuppAntidiag] at hl
    exact Finset.Nat.mem_antidiagonalTuple.mpr hl.1
  · intro f hf
    rw [Finset.mem_finsuppAntidiag]
    exact ⟨by simpa using Finset.Nat.mem_antidiagonalTuple.mp hf, Finset.subset_univ _⟩
  · intro l _
    simp
  · intro f _
    simp
  · intro l _
    simp only [coeff_mk]
    rw [Finset.prod_boole]
    simp

/-- The till: pennies, nickels, dimes and quarters, plenty of each. A coin worth `v` cents has
factor `1 + x^v + x^(2v) + ⋯` (coefficient 1 on every multiple of `v`), and the coefficient of
`x^50` in the product `1/((1-x)(1-x^5)(1-x^10)(1-x^25))` is 49. -/
theorem till_fifty_cents_coeff :
    coeff 50 (mk (fun m => if 1 ∣ m then (1 : ℕ) else 0) *
      mk (fun m => if 5 ∣ m then (1 : ℕ) else 0) *
      mk (fun m => if 10 ∣ m then (1 : ℕ) else 0) *
      mk (fun m => if 25 ∣ m then (1 : ℕ) else 0)) = 49 := by
  simp only [coeff_mul, coeff_mk]
  decide +kernel

/-- Stars and bars is the case where every factor is the all-ones list `1 + x + x^2 + ⋯`:
for `k` kinds (at least one), the coefficient of `x^n` in `1/(1-x)^k` is `C(n + k - 1, k - 1)`. -/
theorem coeff_all_ones_pow_eq_choose (k n : ℕ) (hk : 0 < k) :
    coeff n ((mk (fun _ => (1 : ℕ))) ^ k) = Nat.choose (n + k - 1) (k - 1) := by
  obtain ⟨d, rfl⟩ : ∃ d, k = d + 1 := ⟨k - 1, by omega⟩
  clear hk
  simp only [Nat.add_sub_cancel]
  rw [show n + (d + 1) - 1 = d + n by omega]
  induction d generalizing n with
  | zero => simp
  | succ d hd =>
      rw [pow_add, pow_one, mul_comm, coeff_mul]
      simp only [coeff_mk, one_mul, hd]
      rw [Finset.sum_antidiagonal_choose_add, add_right_comm]

-- The till by counting piles: pennies a, nickels b, dimes c, quarters d with a + 5b + 10c + 25d = 50.
example : ((Finset.range 51 ×ˢ Finset.range 11 ×ˢ Finset.range 6 ×ˢ Finset.range 3).filter
    (fun p => p.1 + 5 * p.2.1 + 10 * p.2.2.1 + 25 * p.2.2.2 = 50)).card = 49 := by
  decide +kernel
-- Pennies filling the rest: nickels, dimes and quarters spending at most 50 cents, 49 piles.
example : ((Finset.range 11 ×ˢ Finset.range 6 ×ˢ Finset.range 3).filter
    (fun p => 5 * p.1 + 10 * p.2.1 + 25 * p.2.2 ≤ 50)).card = 49 := by
  decide +kernel
-- One kind added at a time, the count at 50 cents: 1, 11, 36, 49.
example : ((Finset.range 11).filter (fun b => 5 * b ≤ 50)).card = 11 := by decide +kernel
example : ((Finset.range 11 ×ˢ Finset.range 6).filter
    (fun p => 5 * p.1 + 10 * p.2 ≤ 50)).card = 36 := by decide +kernel
-- Split on the quarters: 36 with none, 12 with one, 1 with two.
example : ((Finset.range 11 ×ˢ Finset.range 6).filter
    (fun p => 5 * p.1 + 10 * p.2 ≤ 25)).card = 12 := by decide +kernel
example : ((Finset.range 11 ×ˢ Finset.range 6).filter
    (fun p => 5 * p.1 + 10 * p.2 ≤ 0)).card = 1 := by decide +kernel
example : 36 + 12 + 1 = 49 := by norm_num
-- Other charges from the same product: 13 piles pay 25 cents, 4 pay 10.
example : ((Finset.range 6 ×ˢ Finset.range 3 ×ˢ Finset.range 2).filter
    (fun p => 5 * p.1 + 10 * p.2.1 + 25 * p.2.2 ≤ 25)).card = 13 := by decide +kernel
example : ((Finset.range 3 ×ˢ Finset.range 2).filter
    (fun p => 5 * p.1 + 10 * p.2 ≤ 10)).card = 4 := by decide +kernel
-- Pennies and nickels alone at 50 cents: 11.
example : ((Finset.range 51 ×ˢ Finset.range 11).filter
    (fun p => p.1 + 5 * p.2 = 50)).card = 11 := by decide +kernel
-- Two dice: 6 ordered pairs total 7, and 36 pairs in all.
example : ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun p => p.1 + p.2 = 7)).card = 6 := by
  decide +kernel
example : (Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).card = 36 := by decide +kernel
-- Three unlimited kinds, total 5: 21 tuples, and C(7, 2) = 21.
example : (Finset.Nat.antidiagonalTuple 3 5).card = 21 := by decide +kernel
example : Nat.choose 7 2 = 21 := by decide
-- The mistakes: 11 × 6 × 3 = 198; stars and bars alone C(53, 3) = 23426.
example : 11 * 6 * 3 = 198 := by norm_num
example : Nat.choose 53 3 = 23426 := by decide

#print axioms coeff_prod_factors_eq_card_piles
#print axioms till_fifty_cents_coeff
#print axioms coeff_all_ones_pow_eq_choose
