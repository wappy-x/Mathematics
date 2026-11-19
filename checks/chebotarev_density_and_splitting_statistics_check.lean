-- Chebotarev: in the field with root minus five a prime other than 2 and 5 splits (minus five is a square mod p) exactly when it is 1, 3, 7 or 9 mod 20, Euler's test picks out the same primes, and the six symmetries of x^3 - 2 fall into classes of sizes 1, 3 and 2.
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.GroupTheory.Perm.Cycle.Type
import Mathlib.NumberTheory.Zsqrtd.Basic
import Mathlib.Data.Nat.Prime.Basic

open Equiv

/-- Helper: `-5` is not zero mod a prime `p ≠ 5`. -/
theorem neg_five_cast_ne_zero (p : ℕ) (hp : p.Prime) (h5 : p ≠ 5) : ((-5 : ℤ) : ZMod p) ≠ 0 := by
  intro h
  rw [ZMod.intCast_zmod_eq_zero_iff_dvd] at h
  have : (p : ℤ) ∣ 5 := by simpa using h
  have h' : p ∣ 5 := by exact_mod_cast this
  rcases (Nat.dvd_prime Nat.prime_five).1 h' with h1 | h1
  · exact hp.one_lt.ne' h1
  · exact h5 h1

/-- Helper: the Legendre symbol mod 5 on the residues 1, 2, 3, 4. -/
theorem legendre_five_table :
    @legendreSym 5 ⟨Nat.prime_five⟩ 1 = 1 ∧ @legendreSym 5 ⟨Nat.prime_five⟩ 2 = -1 ∧
    @legendreSym 5 ⟨Nat.prime_five⟩ 3 = -1 ∧ @legendreSym 5 ⟨Nat.prime_five⟩ 4 = 1 := by
  decide

/-- Helper: the character mod 4 on the odd residues 1 and 3. -/
theorem chi_four_table : ZMod.χ₄ (1 : ℕ) = 1 ∧ ZMod.χ₄ (3 : ℕ) = -1 := by decide

/-- Steps 1 and 2 of the card: for a prime `p` that does not ramify in `Q(√-5)`
(so `p ≠ 2` and `p ≠ 5`), `x^2 + 5` has a root mod `p` (the prime splits, its
Frobenius is "do nothing") exactly when `p` is 1, 3, 7 or 9 mod 20. -/
theorem neg_five_isSquare_iff_mod_twenty (p : ℕ) (hp : p.Prime) (h2 : p ≠ 2) (h5 : p ≠ 5) :
    IsSquare (-5 : ZMod p) ↔ p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9 := by
  have : Fact p.Prime := ⟨hp⟩
  have h0 := neg_five_cast_ne_zero p hp h5
  have key : IsSquare (-5 : ZMod p) ↔ legendreSym p (-5) = 1 := by
    rw [legendreSym.eq_one_iff p h0]; push_cast; rfl
  rw [key]
  have hm : legendreSym p (-5) = legendreSym p (-1) * legendreSym p 5 := by
    rw [← legendreSym.mul]; norm_num
  rw [hm, legendreSym.at_neg_one h2, ZMod.χ₄_nat_mod_four]
  have hr : legendreSym p 5 = @legendreSym 5 ⟨Nat.prime_five⟩ (p % 5 : ℕ) := by
    have h := @legendreSym.quadratic_reciprocity_one_mod_four 5 p ⟨Nat.prime_five⟩ _
      (by norm_num) h2
    rw [show legendreSym p 5 = legendreSym p ((5 : ℕ) : ℤ) by norm_num, h,
      @legendreSym.mod 5 ⟨Nat.prime_five⟩ (p : ℤ)]
    push_cast; rfl
  rw [hr]
  obtain ⟨t1, t2, t3, t4⟩ := legendre_five_table
  obtain ⟨c1, c3⟩ := chi_four_table
  have hodd : p % 2 = 1 := by
    rcases hp.eq_two_or_odd with h | h <;> omega
  have h5' : p % 5 ≠ 0 := by
    intro h
    have : 5 ∣ p := Nat.dvd_of_mod_eq_zero h
    rcases (Nat.dvd_prime hp).1 this with h1 | h1 <;> omega
  have : p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9 ∨ p % 20 = 11 ∨ p % 20 = 13 ∨
      p % 20 = 17 ∨ p % 20 = 19 := by omega
  rcases this with h | h | h | h | h | h | h | h
  all_goals
    have e4 : p % 4 = (p % 20) % 4 := by omega
    have e5 : p % 5 = (p % 20) % 5 := by omega
    rw [e4, e5, h]
    norm_num [t1, t2, t3, t4, c1, c3]

/-- Step 1 of the card: Frobenius on `√-5` is Euler's test. For a prime `p ≠ 2, 5`,
`(-5)^((p-1)/2)` is `1` mod `p` exactly when `-5` is a square mod `p`, that is,
exactly when `p` splits in `Q(√-5)`. -/
theorem euler_test_iff_neg_five_isSquare (p : ℕ) (hp : p.Prime) (h2 : p ≠ 2) (h5 : p ≠ 5) :
    (-5 : ZMod p) ^ ((p - 1) / 2) = 1 ↔ IsSquare (-5 : ZMod p) := by
  have : Fact p.Prime := ⟨hp⟩
  have h0 := neg_five_cast_ne_zero p hp h5
  push_cast at h0
  rw [ZMod.euler_criterion p h0]
  have hodd : p % 2 = 1 := by
    rcases hp.eq_two_or_odd with h | h <;> omega
  have : (p - 1) / 2 = p / 2 := by omega
  rw [this]

/-- Step 5 of the card: the six symmetries `S_3` of the splitting field of `x^3 - 2`
fall into three conjugacy classes (by cycle type): one "do nothing", three swaps of two
roots, two 3-cycles. So Chebotarev's shares are 1/6, 1/2 and 1/3, not a third each. -/
theorem s3_class_sizes :
    Fintype.card (Perm (Fin 3)) = 6 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 3) => σ.cycleType = 0)).card = 1 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 3) => σ.cycleType = {2})).card = 3 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 3) => σ.cycleType = {3})).card = 2 := by
  decide

-- Worked numbers: Euler's test at 3 (splits) and at 11 (inert, 10 = -1).
example : (-5 : ZMod 3) ^ 1 = 1 := by decide
example : (-5 : ZMod 11) ^ 5 = -1 := by decide
example : ((-5 : ℤ) ^ 5) % 11 = 10 := by norm_num
-- The house example: (1 + √-5)(1 - √-5) = 6 = 2 × 3.
example : (⟨1, 1⟩ : ℤ√(-5)) * ⟨1, -1⟩ = 6 := by decide
-- Primes below 50 other than 2 and 5: seven split, six inert, by the mod-20 rule.
example : (List.range 50).filter (fun p => p.Prime ∧ p ≠ 2 ∧ p ≠ 5 ∧
    (p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9)) = [3, 7, 23, 29, 41, 43, 47] := by
  decide
example : (List.range 50).filter (fun p => p.Prime ∧ p ≠ 2 ∧ p ≠ 5 ∧
    ¬ (p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9)) = [11, 13, 17, 19, 31, 37] := by
  decide
-- Below 100: 25 primes, 11 split and 12 inert.
example : ((List.range 101).filter (fun p => p.Prime ∧ p ≠ 2 ∧ p ≠ 5 ∧
    (p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9))).length = 11 := by
  decide
example : ((List.range 101).filter (fun p => p.Prime ∧ p ≠ 2 ∧ p ≠ 5 ∧
    ¬ (p % 20 = 1 ∨ p % 20 = 3 ∨ p % 20 = 7 ∨ p % 20 = 9))).length = 12 := by
  decide
-- Sums of forms: 29 and 41 are x^2 + 5y^2; 3 and 7 are 2x^2 + 2xy + 3y^2; 31 is x^2 + 27y^2.
example : (29 : ℤ) = 3 ^ 2 + 5 * 2 ^ 2 := by norm_num
example : (41 : ℤ) = 6 ^ 2 + 5 * 1 ^ 2 := by norm_num
example : (3 : ℤ) = 2 * 0 ^ 2 + 2 * 0 * 1 + 3 * 1 ^ 2 := by norm_num
example : (7 : ℤ) = 2 * 1 ^ 2 + 2 * 1 * 1 + 3 * 1 ^ 2 := by norm_num
example : (31 : ℤ) = 2 ^ 2 + 27 * 1 ^ 2 := by norm_num
-- Roots of x^3 - 2: mod 5 only 3; mod 7 none; mod 31 exactly 4, 7 and 20.
example : (Finset.univ.filter (fun x : ZMod 5 => x ^ 3 - 2 = 0)) = {3} := by decide
example : (Finset.univ.filter (fun x : ZMod 7 => x ^ 3 - 2 = 0)) = ∅ := by decide
example : (Finset.univ.filter (fun x : ZMod 31 => x ^ 3 - 2 = 0)) = {4, 7, 20} := by decide
-- The ramified prime 3: one root, 2, yet x^3 - 2 = (x + 1)^3 mod 3, a triple root.
example : (Finset.univ.filter (fun x : ZMod 3 => x ^ 3 - 2 = 0)) = {2} := by decide
example : ∀ x : ZMod 3, x ^ 3 - 2 = (x + 1) ^ 3 := by decide

#print axioms neg_five_cast_ne_zero
#print axioms legendre_five_table
#print axioms chi_four_table
#print axioms neg_five_isSquare_iff_mod_twenty
#print axioms euler_test_iff_neg_five_isSquare
#print axioms s3_class_sizes
