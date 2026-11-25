-- Kronecker-Weber: the square roots of 5 and of minus 5 lie in the fields of 5th and 20th roots of 1 (by signed sums of roots of 1 that square to 5 and to minus 5), and a prime other than 5 splits in the field with root 5 exactly when it is 1 or 4 mod 5.
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.FieldTheory.IntermediateField.Adjoin.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.Complex.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic

open IntermediateField

/-- Step 1 of the card (the overview's example): for a primitive 5th root of 1, ζ, the signed
sum ζ − ζ² − ζ³ + ζ⁴ (signs + on the squares 1, 4 mod 5 and − on the non-squares 2, 3)
squares to 5, so the square root of 5 lies in the cyclotomic field ℚ(ζ₅). -/
theorem sqrt_five_mem_cyclotomic_five {ζ : ℂ} (hζ : IsPrimitiveRoot ζ 5) :
    (ζ - ζ ^ 2 - ζ ^ 3 + ζ ^ 4) ^ 2 = 5 ∧ ((Real.sqrt 5 : ℝ) : ℂ) ∈ ℚ⟮ζ⟯ := by
  have hs : ∑ i ∈ Finset.range 5, ζ ^ i = 0 := hζ.geom_sum_eq_zero (by norm_num)
  simp only [Finset.sum_range_succ, Finset.sum_range_zero] at hs
  have hsq : (ζ - ζ ^ 2 - ζ ^ 3 + ζ ^ 4) ^ 2 = 5 := by
    linear_combination (-5 + 5 * ζ + ζ ^ 2 - 3 * ζ ^ 3 + ζ ^ 4) * hs
  refine ⟨hsq, ?_⟩
  have hz : ζ ∈ ℚ⟮ζ⟯ := mem_adjoin_simple_self ℚ ζ
  have hg : ζ - ζ ^ 2 - ζ ^ 3 + ζ ^ 4 ∈ ℚ⟮ζ⟯ :=
    add_mem (sub_mem (sub_mem hz (pow_mem hz 2)) (pow_mem hz 3)) (pow_mem hz 4)
  have hr : (((Real.sqrt 5 : ℝ) : ℂ)) ^ 2 = 5 := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; norm_num
  have hprod : ((ζ - ζ ^ 2 - ζ ^ 3 + ζ ^ 4) - ((Real.sqrt 5 : ℝ) : ℂ)) *
      ((ζ - ζ ^ 2 - ζ ^ 3 + ζ ^ 4) + ((Real.sqrt 5 : ℝ) : ℂ)) = 0 := by
    linear_combination hsq - hr
  rcases mul_eq_zero.mp hprod with h | h
  · rw [← sub_eq_zero.mp h]; exact hg
  · rw [show ((Real.sqrt 5 : ℝ) : ℂ) = -(ζ - ζ ^ 2 - ζ ^ 3 + ζ ^ 4) by linear_combination h]
    exact neg_mem hg

/-- Step 1 of the card, the house field: for a primitive 20th root of 1, ζ, the signed sum
ζ + ζ⁹ − ζ¹³ − ζ¹⁷ squares to −5, so the square root of −5 (that is, i√5) lies in the
cyclotomic field ℚ(ζ₂₀). -/
theorem sqrt_neg_five_mem_cyclotomic_twenty {ζ : ℂ} (hζ : IsPrimitiveRoot ζ 20) :
    (ζ + ζ ^ 9 - ζ ^ 13 - ζ ^ 17) ^ 2 = -5 ∧
      Complex.I * ((Real.sqrt 5 : ℝ) : ℂ) ∈ ℚ⟮ζ⟯ := by
  have h10 : ζ ^ 10 = -1 := by
    have := hζ.pow_of_dvd (p := 10) (by norm_num) (by norm_num)
    exact IsPrimitiveRoot.eq_neg_one_of_two_right (by simpa using this)
  have h4 : IsPrimitiveRoot (ζ ^ 4) 5 := by
    simpa using hζ.pow_of_dvd (p := 4) (by norm_num) (by norm_num)
  have hs : ∑ i ∈ Finset.range 5, (ζ ^ 4) ^ i = 0 := h4.geom_sum_eq_zero (by norm_num)
  simp only [Finset.sum_range_succ, Finset.sum_range_zero] at hs
  have hΦ : ζ ^ 8 - ζ ^ 6 + ζ ^ 4 - ζ ^ 2 + 1 = 0 := by
    linear_combination hs - (ζ ^ 2 + ζ ^ 6) * h10
  have hsq : (ζ + ζ ^ 9 - ζ ^ 13 - ζ ^ 17) ^ 2 = -5 := by
    linear_combination (5 + 6 * ζ ^ 2 + ζ ^ 4 - 3 * ζ ^ 10 - 4 * ζ ^ 12 - 3 * ζ ^ 14
      - 2 * ζ ^ 16 - ζ ^ 18 + 2 * ζ ^ 20 + 2 * ζ ^ 22 + ζ ^ 24 + ζ ^ 26) * hΦ
  refine ⟨hsq, ?_⟩
  have hz : ζ ∈ ℚ⟮ζ⟯ := mem_adjoin_simple_self ℚ ζ
  have hg : ζ + ζ ^ 9 - ζ ^ 13 - ζ ^ 17 ∈ ℚ⟮ζ⟯ :=
    sub_mem (sub_mem (add_mem hz (pow_mem hz 9)) (pow_mem hz 13)) (pow_mem hz 17)
  have hr : (Complex.I * ((Real.sqrt 5 : ℝ) : ℂ)) ^ 2 = -5 := by
    rw [mul_pow, Complex.I_sq, ← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; push_cast; ring
  have hprod : ((ζ + ζ ^ 9 - ζ ^ 13 - ζ ^ 17) - Complex.I * ((Real.sqrt 5 : ℝ) : ℂ)) *
      ((ζ + ζ ^ 9 - ζ ^ 13 - ζ ^ 17) + Complex.I * ((Real.sqrt 5 : ℝ) : ℂ)) = 0 := by
    linear_combination hsq - hr
  rcases mul_eq_zero.mp hprod with h | h
  · rw [← sub_eq_zero.mp h]; exact hg
  · rw [show Complex.I * ((Real.sqrt 5 : ℝ) : ℂ) = -(ζ + ζ ^ 9 - ζ ^ 13 - ζ ^ 17) by
      linear_combination h]
    exact neg_mem hg

/-- Helper: x² − x − 1 has no root mod 2. -/
theorem no_golden_root_mod_two : ¬ ∃ x : ZMod 2, x ^ 2 - x - 1 = 0 := by
  decide

/-- Helper: the nonzero squares mod 5 are exactly 1 and 4. -/
theorem square_mod_five_table (r : ℕ) (hr : r < 5) (h0 : r ≠ 0) :
    IsSquare ((r : ℕ) : ZMod 5) ↔ r = 1 ∨ r = 4 := by
  interval_cases r
  · exact absurd rfl h0
  all_goals
    simp only [IsSquare]
    decide

#print axioms no_golden_root_mod_two
#print axioms square_mod_five_table

/-- Step 2 of the card, the splitting rule for ℚ(√5): for a prime p other than 5, the
polynomial x² − x − 1 (whose root (1 + √5)/2 generates the ring of integers) has a root mod p,
so that p splits, exactly when p is 1 or 4 mod 5. -/
theorem golden_poly_has_root_mod_p_iff (p : ℕ) [Fact p.Prime] (h5 : p ≠ 5) :
    (∃ x : ZMod p, x ^ 2 - x - 1 = 0) ↔ p % 5 = 1 ∨ p % 5 = 4 := by
  have hp := (Fact.out : p.Prime)
  rcases hp.eq_two_or_odd' with rfl | hodd
  · exact iff_of_false no_golden_root_mod_two (by norm_num)
  have hp2 : p ≠ 2 := by rintro rfl; exact (Nat.not_odd_iff_even.mpr even_two) hodd
  have h2 : (2 : ZMod p) ≠ 0 := by
    intro h
    have h' : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
    rw [ZMod.natCast_eq_zero_iff] at h'
    have := Nat.le_of_dvd (by norm_num) h'
    have := hp.two_le
    omega
  -- a root of x² − x − 1 is the same as a square root of 5, via y = 2x − 1
  have hroot : (∃ x : ZMod p, x ^ 2 - x - 1 = 0) ↔ IsSquare (5 : ZMod p) := by
    constructor
    · rintro ⟨x, hx⟩
      exact ⟨2 * x - 1, by linear_combination (-4 : ZMod p) * hx⟩
    · rintro ⟨y, hy⟩
      refine ⟨(y + 1) / 2, ?_⟩
      field_simp
      linear_combination -hy
  have : Fact (Nat.Prime 5) := ⟨by norm_num⟩
  have hqr : IsSquare ((5 : ℕ) : ZMod p) ↔ IsSquare ((p : ℕ) : ZMod 5) :=
    (ZMod.exists_sq_eq_prime_iff_of_mod_four_eq_one (p := 5) (q := p) (by norm_num) hp2).symm
  rw [hroot, show (5 : ZMod p) = ((5 : ℕ) : ZMod p) by norm_num, hqr, ← ZMod.natCast_mod p 5]
  have h0 : p % 5 ≠ 0 := by
    intro h
    have : 5 ∣ p := Nat.dvd_of_mod_eq_zero h
    exact h5 ((Nat.prime_dvd_prime_iff_eq (by norm_num) hp).mp this).symm
  exact square_mod_five_table (p % 5) (Nat.mod_lt _ (by norm_num)) h0

-- The table of Step 2: x² − x − 1 has two roots mod 11, 19 and 29, none mod 2, 3, 7, 13.
example : ((Finset.univ : Finset (ZMod 11)).filter (fun x => x ^ 2 - x - 1 = 0)).card = 2 := by
  decide
example : ((Finset.univ : Finset (ZMod 19)).filter (fun x => x ^ 2 - x - 1 = 0)).card = 2 := by
  decide
example : ((Finset.univ : Finset (ZMod 29)).filter (fun x => x ^ 2 - x - 1 = 0)).card = 2 := by
  decide
example : ((Finset.univ : Finset (ZMod 2)).filter (fun x => x ^ 2 - x - 1 = 0)).card = 0 := by
  decide
example : ((Finset.univ : Finset (ZMod 3)).filter (fun x => x ^ 2 - x - 1 = 0)).card = 0 := by
  decide
example : ((Finset.univ : Finset (ZMod 7)).filter (fun x => x ^ 2 - x - 1 = 0)).card = 0 := by
  decide
example : ((Finset.univ : Finset (ZMod 13)).filter (fun x => x ^ 2 - x - 1 = 0)).card = 0 := by
  decide
-- 5 ramifies: x² − x − 1 has the one double root 3 mod 5.
example : (Finset.univ : Finset (ZMod 5)).filter (fun x => x ^ 2 - x - 1 = 0) = {3} := by
  decide
-- Frobenius at 11 and 13: 11 is 1 mod 5, 13 is 3 mod 5.
example : 11 % 5 = 1 ∧ 13 % 5 = 3 := by norm_num
-- The house field's subgroup is {1, 3, 7, 9} mod 20; the remainders that are 1 mod 4 and
-- 1 mod 5 contain 13 and 11, outside it, so the conductor is 20.
example : (Finset.range 20).filter (fun k => Nat.Coprime k 20 ∧ k % 4 = 1) = {1, 9, 13, 17} := by
  decide
example : (Finset.range 20).filter (fun k => Nat.Coprime k 20 ∧ k % 5 = 1) = {1, 11} := by
  decide
-- The inertia bound of Step 5: φ(4) × φ(5) = 2 × 4 = 8 = φ(20).
example : Nat.totient 4 = 2 ∧ Nat.totient 5 = 4 ∧ Nat.totient 20 = 8 := by decide
-- What breaks: mod 5, x³ − 2 has the single root 3, and x² + 3x + 4 has no root.
example : (Finset.univ : Finset (ZMod 5)).filter (fun x => x ^ 3 - 2 = 0) = {3} := by decide
example : (Finset.univ : Finset (ZMod 5)).filter (fun x => x ^ 2 + 3 * x + 4 = 0) = ∅ := by decide
-- The local count: units mod 125 fall into 2 square classes, units mod 64 into 4.
example : ((Finset.range 125).filter (fun k => Nat.Coprime k 125)).card /
    (((Finset.range 125).filter (fun k => Nat.Coprime k 125)).image (fun k => k * k % 125)).card
      = 2 := by decide +kernel
example : ((Finset.range 64).filter (fun k => Nat.Coprime k 64)).card /
    (((Finset.range 64).filter (fun k => Nat.Coprime k 64)).image (fun k => k * k % 64)).card
      = 4 := by decide +kernel

#print axioms sqrt_five_mem_cyclotomic_five
#print axioms sqrt_neg_five_mem_cyclotomic_twenty
#print axioms golden_poly_has_root_mod_p_iff
