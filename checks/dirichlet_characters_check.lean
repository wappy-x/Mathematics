-- Dirichlet characters: summing over all characters mod q, each weighted by the conjugate of its value at a unit a and divided by φ(q), gives 1 on a's class and 0 elsewhere, so it counts the primes in that class.
import Mathlib.NumberTheory.DirichletCharacter.Orthogonality
import Mathlib.RingTheory.RootsOfUnity.AlgebraicallyClosed
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Data.Nat.Totient

open Finset

/-- For a unit a mod q, the complex conjugate of χ(a) is χ(a⁻¹). -/
theorem conj_apply_eq_inv (q : ℕ) [NeZero q] (χ : DirichletCharacter ℂ q) {a : ZMod q}
    (ha : IsUnit a) : starRingEnd ℂ (χ a) = χ a⁻¹ := by
  have h1 : χ a * χ a⁻¹ = 1 := by
    rw [← map_mul, ZMod.mul_inv_of_unit a ha, map_one]
  have h2 : χ a * starRingEnd ℂ (χ a) = 1 := by
    have := MulChar.star_apply' χ a
    rw [RCLike.star_def] at this
    rw [this, ← MulChar.mul_apply, mul_inv_cancel, MulChar.one_apply ha]
  have hne : χ a ≠ 0 := by
    intro h; rw [h, zero_mul] at h1; exact zero_ne_one h1
  exact mul_left_cancel₀ hne (h2.trans h1.symm)

#print axioms conj_apply_eq_inv

/-- The filter for one remainder class. Let q be a positive modulus and a a whole number
that shares no factor with q. Weight each Dirichlet character mod q at n by the complex
conjugate of its value at a, add over all the characters and divide by φ(q): the answer
is 1 when n ≡ a (mod q) and 0 otherwise. -/
theorem dirichlet_character_filter (q : ℕ) [NeZero q] (a : ℕ) (ha : Nat.Coprime a q) (n : ℕ) :
    (1 / (Nat.totient q : ℂ)) *
        ∑ χ : DirichletCharacter ℂ q, starRingEnd ℂ (χ (a : ZMod q)) * χ (n : ZMod q) =
      if n ≡ a [MOD q] then 1 else 0 := by
  have hu : IsUnit (a : ZMod q) := (ZMod.unitOfCoprime a ha).isUnit
  simp_rw [conj_apply_eq_inv q _ hu]
  rw [DirichletCharacter.sum_char_inv_mul_char_eq ℂ hu]
  have hφ : (Nat.totient q : ℂ) ≠ 0 := by
    exact_mod_cast (Nat.totient_pos.mpr (Nat.pos_of_ne_zero (NeZero.ne q))).ne'
  have hiff : ((a : ZMod q) = (n : ZMod q)) ↔ n ≡ a [MOD q] := by
    rw [ZMod.natCast_eq_natCast_iff]; exact ⟨Nat.ModEq.symm, Nat.ModEq.symm⟩
  simp only [hiff]
  split_ifs
  · field_simp
  · rw [mul_zero]

/-- Every positive modulus q has exactly φ(q) Dirichlet characters with complex values. -/
theorem card_dirichlet_characters_eq_totient (q : ℕ) [NeZero q] :
    Nat.card (DirichletCharacter ℂ q) = Nat.totient q := by
  exact DirichletCharacter.card_eq_totient_of_hasEnoughRootsOfUnity ℂ q

/-- The filter run over the primes. For a positive modulus q, a whole number a coprime
to q and any limit x, the number of primes p < x with p ≡ a (mod q) equals
(1/φ(q)) times the sum over the characters χ mod q of conj χ(a) times S(χ),
where S(χ) is the sum of χ(p) over the primes p < x. -/
theorem count_primes_in_class_by_characters (q : ℕ) [NeZero q] (a : ℕ) (ha : Nat.Coprime a q)
    (x : ℕ) :
    ((((range x).filter (fun p => p.Prime ∧ p ≡ a [MOD q])).card : ℕ) : ℂ) =
      (1 / (Nat.totient q : ℂ)) *
        ∑ χ : DirichletCharacter ℂ q, starRingEnd ℂ (χ (a : ZMod q)) *
          ∑ p ∈ (range x).filter Nat.Prime, χ (p : ZMod q) := by
  have hfil : (range x).filter (fun p => p.Prime ∧ p ≡ a [MOD q]) =
      ((range x).filter Nat.Prime).filter (fun p => p ≡ a [MOD q]) := by
    rw [Finset.filter_filter]
  rw [hfil, Finset.card_filter, Nat.cast_sum]
  simp_rw [Finset.mul_sum]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun p _ => ?_
  rw [← Finset.mul_sum, dirichlet_character_filter q a ha p]
  push_cast
  rfl

-- The units mod 10 are 1, 3, 7 and 9, and φ(10) = 4.
example : (range 10).filter (fun n => Nat.Coprime n 10) = {1, 3, 7, 9} := by decide
example : Nat.totient 10 = 4 := by decide
-- 3 is a primitive root mod 10: its powers are 1, 3, 9, 7. And 3 × 7 = 21 ends in 1.
example : (List.range 4).map (fun k => 3 ^ k % 10) = [1, 3, 9, 7] := by decide
example : 3 * 7 % 10 = 1 := by decide
-- The other moduli the code checks: φ(7) = 6, φ(8) = 4, φ(12) = 4; mod 8 every unit squares to 1.
example : Nat.totient 7 = 6 ∧ Nat.totient 8 = 4 ∧ Nat.totient 12 = 4 := by decide
example : ∀ u ∈ [1, 3, 5, 7], u ^ 2 % 8 = 1 := by decide
-- The pattern 1, i, −1, −i on 1, 3, 7, 9 fails at 3 × 3: 9 gets −i, but i · i = −1.
example : Complex.I * Complex.I ≠ -Complex.I := by
  simp [Complex.ext_iff]
-- Trying every table: 4^4 = 256 ways to fill a row with fourth roots of unity.
example : 4 ^ 4 = 256 := by norm_num
-- Worked numbers below a million: the four endings add to 78,496 and an even quarter is 19,624.
example : 19617 + 19665 + 19621 + 19593 = 78496 ∧ 78496 / 4 = 19624 := by norm_num
-- The weighted terms for ending 3: (−i)(24 + 44i) = 44 − 24i and i(24 − 44i) = 44 + 24i.
example : (-Complex.I) * (24 + 44 * Complex.I) = 44 - 24 * Complex.I := by
  simp [Complex.ext_iff]
example : Complex.I * (24 - 44 * Complex.I) = 44 + 24 * Complex.I := by
  simp [Complex.ext_iff]
-- Add and divide by φ(10) = 4: 78,660 / 4 = 19,665, a lead of (44 + 76 + 44) / 4 = 41.
example : 78496 + 44 + 76 + 44 = 78660 ∧ 78660 / 4 = 19665 ∧ (44 + 76 + 44) / 4 = 41 := by
  norm_num
-- The mistakes: dividing by q = 10 gives 7,866; real characters only give the average 19,643.
example : 78660 / 10 = 7866 ∧ (19665 + 19621) / 2 = 19643 := by norm_num

#print axioms dirichlet_character_filter
#print axioms card_dirichlet_characters_eq_totient
#print axioms count_primes_in_class_by_characters
