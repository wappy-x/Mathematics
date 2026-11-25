-- Artin reciprocity: for K = Q(√-5), whose Hilbert class field is K(i) = K(√5), an odd prime p other than 5 is x^2 + 5y^2 exactly when (-5/p) = 1 and t^2 - 5 has a root mod p, which is exactly when p is 1 or 9 mod 20, because every odd norm a^2 + 5b^2 is 1 mod 4.
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.Data.Fintype.Pigeonhole
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.LinearCombination

/-- `5` is not zero mod a prime `p ≠ 5`. -/
lemma five_ne_zero_zmod (p : ℕ) [Fact p.Prime] (hp5 : p ≠ 5) : (5 : ZMod p) ≠ 0 := by
  intro h
  have h' : ((5 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
  rw [ZMod.natCast_eq_zero_iff] at h'
  exact hp5 ((Nat.prime_dvd_prime_iff_eq Fact.out Nat.prime_five).mp h')

/-- The nonzero squares mod 5 are 1 and 4. -/
lemma squares_mod_five : ∀ r : Fin 5, (r : ℕ) ≠ 0 →
    ((∃ z : ZMod 5, ((r : ℕ) : ZMod 5) = z * z) ↔ ((r : ℕ) = 1 ∨ (r : ℕ) = 4)) := by decide

/-- By quadratic reciprocity (with `5 ≡ 1 mod 4`), `5` is a square mod an odd prime `p ≠ 5`
exactly when `p` is `1` or `4` mod `5`. -/
lemma isSquare_five_iff (p : ℕ) [Fact p.Prime] (hp2 : p ≠ 2) (hp5 : p ≠ 5) :
    IsSquare (5 : ZMod p) ↔ p % 5 = 1 ∨ p % 5 = 4 := by
  have : Fact (Nat.Prime 5) := ⟨Nat.prime_five⟩
  have h := ZMod.exists_sq_eq_prime_iff_of_mod_four_eq_one (p := 5) (q := p) (by norm_num) hp2
  have e : ((5 : ℕ) : ZMod p) = 5 := by norm_cast
  rw [e] at h
  rw [← h, ← ZMod.natCast_mod p 5]
  have hlt : p % 5 < 5 := Nat.mod_lt _ (by norm_num)
  have hne : p % 5 ≠ 0 := by
    intro h0
    exact hp5 ((Nat.prime_dvd_prime_iff_eq Nat.prime_five (Fact.out : p.Prime)).mp
      (Nat.dvd_of_mod_eq_zero h0)).symm
  exact squares_mod_five ⟨p % 5, hlt⟩ hne

/-- `-5` and `5` are both squares mod an odd prime `p ≠ 5` exactly when `p` is `1` or `9`
mod `20`. -/
lemma squares_iff_mod_twenty (p : ℕ) [Fact p.Prime] (hp2 : p ≠ 2) (hp5 : p ≠ 5) :
    (IsSquare (-5 : ZMod p) ∧ IsSquare (5 : ZMod p)) ↔ p % 20 = 1 ∨ p % 20 = 9 := by
  have hodd : p % 2 = 1 := (Nat.Prime.mod_two_eq_one_iff_ne_two Fact.out).mpr hp2
  constructor
  · rintro ⟨⟨a, ha⟩, ⟨b, hb⟩⟩
    have hb0 : b ≠ 0 := by
      rintro rfl
      exact five_ne_zero_zmod p hp5 (by simpa using hb)
    have hm1 : IsSquare (-1 : ZMod p) := ⟨a / b, by
      rw [div_mul_div_comm, eq_div_iff (mul_ne_zero hb0 hb0), ← ha, ← hb]; ring⟩
    have h4 : p % 4 ≠ 3 := ZMod.exists_sq_eq_neg_one_iff.mp hm1
    have h5 := (isSquare_five_iff p hp2 hp5).mp ⟨b, hb⟩
    omega
  · intro h
    have h5 : IsSquare (5 : ZMod p) := (isSquare_five_iff p hp2 hp5).mpr (by omega)
    have hm1 : IsSquare (-1 : ZMod p) := ZMod.exists_sq_eq_neg_one_iff.mpr (by omega)
    refine ⟨?_, h5⟩
    have := hm1.mul h5
    rwa [neg_one_mul] at this

/-- Every prime `x² + 5y²` other than 2 and 5 is `1` or `9` mod `20`. -/
lemma mod_twenty_of_eq_sq_add_five_sq (x y p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) (hp5 : p ≠ 5)
    (h : p = x ^ 2 + 5 * y ^ 2) : p % 20 = 1 ∨ p % 20 = 9 := by
  have key : ∀ a b : ZMod 20, (a ^ 2 + 5 * b ^ 2).val = 0 ∨ (a ^ 2 + 5 * b ^ 2).val = 1 ∨
      (a ^ 2 + 5 * b ^ 2).val = 4 ∨ (a ^ 2 + 5 * b ^ 2).val = 5 ∨
      (a ^ 2 + 5 * b ^ 2).val = 6 ∨ (a ^ 2 + 5 * b ^ 2).val = 9 ∨
      (a ^ 2 + 5 * b ^ 2).val = 10 ∨ (a ^ 2 + 5 * b ^ 2).val = 14 ∨
      (a ^ 2 + 5 * b ^ 2).val = 16 := by decide
  have hv : (p : ZMod 20).val = p % 20 := ZMod.val_natCast 20 p
  have hc : (p : ZMod 20) = (x : ZMod 20) ^ 2 + 5 * (y : ZMod 20) ^ 2 := by
    rw [h]; push_cast; ring
  have h2 : p % 2 = 1 := (Nat.Prime.mod_two_eq_one_iff_ne_two hp).mpr hp2
  have h5 : p % 5 ≠ 0 := by
    intro h0
    exact hp5 ((Nat.prime_dvd_prime_iff_eq Nat.prime_five hp).mp (Nat.dvd_of_mod_eq_zero h0)).symm
  have := key x y
  rw [← hc, hv] at this
  omega

/-- Thue's lemma for `x² + 5y²`: if `-5` is a square mod a prime `p ≡ 1 mod 4`, then
`p = x² + 5y²`. Pigeonhole gives `x ≡ -a y mod p` with `|x|, |y| ≤ √p`, so
`x² + 5y² = k p` with `1 ≤ k ≤ 5`; mod 8 rules out `k = 2, 3`, and `k = 4, 5` descend. -/
lemma eq_sq_add_five_sq_of_sq_eq_neg_five (p : ℕ) [Fact p.Prime] (hp4 : p % 4 = 1)
    (a : ZMod p) (ha : a ^ 2 = -5) : ∃ x y : ℕ, p = x ^ 2 + 5 * y ^ 2 := by
  have hp : p.Prime := Fact.out
  have hm1 : Nat.sqrt p ^ 2 ≤ p := Nat.sqrt_le' p
  have hm2 : p < (Nat.sqrt p + 1) ^ 2 := Nat.lt_succ_sqrt' p
  set m := Nat.sqrt p with hm
  have hm3 : m ^ 2 < p := by
    rcases hm1.lt_or_eq with h | h
    · exact h
    exfalso
    have hd : m ∣ p := ⟨m, by rw [← h]; ring⟩
    rcases hp.eq_one_or_self_of_dvd m hd with h1 | h1
    · rw [h1] at h
      exact hp.one_lt.ne (by simpa using h)
    · rw [h1] at h
      have := hp.two_le
      nlinarith
  let f : Fin (m + 1) × Fin (m + 1) → ZMod p :=
    fun uv => ((uv.1 : ℕ) : ZMod p) + a * ((uv.2 : ℕ) : ZMod p)
  have hcard : Fintype.card (ZMod p) < Fintype.card (Fin (m + 1) × Fin (m + 1)) := by
    rw [ZMod.card, Fintype.card_prod, Fintype.card_fin]
    nlinarith
  obtain ⟨⟨u1, v1⟩, ⟨u2, v2⟩, hne, heq⟩ := Fintype.exists_ne_map_eq_of_card_lt f hcard
  simp only [f] at heq
  set X : ℤ := ((u1 : ℕ) : ℤ) - ((u2 : ℕ) : ℤ) with hX
  set Y : ℤ := ((v1 : ℕ) : ℤ) - ((v2 : ℕ) : ℤ) with hY
  have hXa : (X : ZMod p) = -a * (Y : ZMod p) := by
    rw [hX, hY]; push_cast; linear_combination heq
  have hXY : ((X ^ 2 + 5 * Y ^ 2 : ℤ) : ZMod p) = 0 := by
    push_cast; rw [hXa]; linear_combination (Y : ZMod p) ^ 2 * ha
  have hdvd : (p : ℤ) ∣ X ^ 2 + 5 * Y ^ 2 := (ZMod.intCast_zmod_eq_zero_iff_dvd _ p).mp hXY
  set A := X.natAbs with hA
  set B := Y.natAbs with hB
  have hAB : ((A ^ 2 + 5 * B ^ 2 : ℕ) : ℤ) = X ^ 2 + 5 * Y ^ 2 := by
    push_cast; rw [hA, hB, Int.natAbs_sq, Int.natAbs_sq]
  have hdvdN : p ∣ A ^ 2 + 5 * B ^ 2 := by
    rw [← Int.natCast_dvd_natCast, hAB]; exact hdvd
  have hu1 := u1.isLt
  have hu2 := u2.isLt
  have hv1 := v1.isLt
  have hv2 := v2.isLt
  have hAm : A ≤ m := by omega
  have hBm : B ≤ m := by omega
  have hpos : A ≠ 0 ∨ B ≠ 0 := by
    by_contra hc
    push Not at hc
    apply hne
    have e1 : u1 = u2 := Fin.ext (by omega)
    have e2 : v1 = v2 := Fin.ext (by omega)
    rw [e1, e2]
  obtain ⟨k, hk⟩ := hdvdN
  have hA2 : A ^ 2 ≤ m ^ 2 := Nat.pow_le_pow_left hAm 2
  have hB2 : B ^ 2 ≤ m ^ 2 := Nat.pow_le_pow_left hBm 2
  have hlt : p * k < p * 6 := by rw [← hk]; omega
  have hk6 : k < 6 := Nat.lt_of_mul_lt_mul_left hlt
  have hpos2 : 0 < A ^ 2 + 5 * B ^ 2 := by
    rcases hpos with h | h
    · have := pow_pos (Nat.pos_of_ne_zero h) 2; omega
    · have := pow_pos (Nat.pos_of_ne_zero h) 2; omega
  have key8 : ∀ r s : ZMod 8, ((r ^ 2 + 5 * s ^ 2).val = 0 ∨ (r ^ 2 + 5 * s ^ 2).val = 1 ∨
      (r ^ 2 + 5 * s ^ 2).val = 4 ∨ (r ^ 2 + 5 * s ^ 2).val = 5 ∨
      (r ^ 2 + 5 * s ^ 2).val = 6) ∧
      ((r ^ 2 + 5 * s ^ 2).val % 4 = 0 → r.val % 2 = 0 ∧ s.val % 2 = 0) := by decide
  have hv : ((A ^ 2 + 5 * B ^ 2 : ℕ) : ZMod 8).val = (A ^ 2 + 5 * B ^ 2) % 8 :=
    ZMod.val_natCast 8 _
  have hcast : ((A ^ 2 + 5 * B ^ 2 : ℕ) : ZMod 8) = (A : ZMod 8) ^ 2 + 5 * (B : ZMod 8) ^ 2 := by
    push_cast; ring
  have hAv : (A : ZMod 8).val = A % 8 := ZMod.val_natCast 8 A
  have hBv : (B : ZMod 8).val = B % 8 := ZMod.val_natCast 8 B
  obtain ⟨k1, k2⟩ := key8 A B
  rw [← hcast, hv, hAv, hBv] at k2
  rw [← hcast, hv] at k1
  interval_cases k
  · omega
  · exact ⟨A, B, by omega⟩
  · omega
  · omega
  · obtain ⟨hAe, hBe⟩ := k2 (by omega)
    obtain ⟨c, hc⟩ : 2 ∣ A := by omega
    obtain ⟨d, hd⟩ : 2 ∣ B := by omega
    have e1 : A ^ 2 = 4 * c ^ 2 := by rw [hc]; ring
    have e2 : B ^ 2 = 4 * d ^ 2 := by rw [hd]; ring
    exact ⟨c, d, by omega⟩
  · have h5 : 5 ∣ A ^ 2 := by omega
    obtain ⟨c, hc⟩ := (Nat.prime_five.dvd_of_dvd_pow h5)
    have e1 : A ^ 2 = 25 * c ^ 2 := by rw [hc]; ring
    exact ⟨B, c, by omega⟩

/-- A prime `p` other than 2 and 5 is `x² + 5y²` exactly when `p` is 1 or 9 mod 20. -/
lemma eq_sq_add_five_sq_iff_mod_twenty (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) (hp5 : p ≠ 5) :
    (∃ x y : ℕ, p = x ^ 2 + 5 * y ^ 2) ↔ p % 20 = 1 ∨ p % 20 = 9 := by
  have := Fact.mk hp
  constructor
  · rintro ⟨x, y, h⟩
    exact mod_twenty_of_eq_sq_add_five_sq x y p hp hp2 hp5 h
  · intro h
    obtain ⟨⟨r, hr⟩, -⟩ := (squares_iff_mod_twenty p hp2 hp5).mpr h
    exact eq_sq_add_five_sq_of_sq_eq_neg_five p (by omega) r (by rw [hr]; ring)

#print axioms five_ne_zero_zmod
#print axioms squares_mod_five
#print axioms isSquare_five_iff
#print axioms squares_iff_mod_twenty
#print axioms mod_twenty_of_eq_sq_add_five_sq
#print axioms eq_sq_add_five_sq_of_sq_eq_neg_five
#print axioms eq_sq_add_five_sq_iff_mod_twenty

/-- The Hilbert class field test for `n = 5` (Cox, Theorem 5.1, with `H = K(√5)` and
`f₅ = t² - 5`): an odd prime `p` dividing neither `5` nor the discriminant `20` of `f₅`
is `x² + 5y²` exactly when `(-5/p) = 1` and `t² - 5` has a root mod `p`. -/
theorem prime_eq_sq_add_five_sq_iff_splits_completely (p : ℕ) [Fact p.Prime]
    (hp2 : p ≠ 2) (hp5 : p ≠ 5) :
    (∃ x y : ℕ, p = x ^ 2 + 5 * y ^ 2) ↔
      legendreSym p (-5) = 1 ∧ ∃ t : ZMod p, t ^ 2 - 5 = 0 := by
  have hp : p.Prime := Fact.out
  rw [eq_sq_add_five_sq_iff_mod_twenty p hp hp2 hp5, ← squares_iff_mod_twenty p hp2 hp5]
  have hm5 : ((-5 : ℤ) : ZMod p) ≠ 0 := by
    push_cast; exact neg_ne_zero.mpr (five_ne_zero_zmod p hp5)
  rw [legendreSym.eq_one_iff p hm5]
  push_cast
  apply and_congr Iff.rfl
  constructor
  · rintro ⟨t, ht⟩
    exact ⟨t, by linear_combination -ht⟩
  · rintro ⟨t, ht⟩
    exact ⟨t, by linear_combination -ht⟩

/-- The house example: a prime `p` other than 2 and 5 is `x² + 5y²` exactly when `p` is
1 or 9 mod 20. -/
theorem prime_eq_sq_add_five_sq_iff_mod_twenty (p : ℕ) (hp : p.Prime)
    (hp2 : p ≠ 2) (hp5 : p ≠ 5) :
    (∃ x y : ℕ, p = x ^ 2 + 5 * y ^ 2) ↔ p % 20 = 1 ∨ p % 20 = 9 :=
  eq_sq_add_five_sq_iff_mod_twenty p hp hp2 hp5

/-- Step 2: the Frobenius cannot see principal ideals. Every odd norm `a² + 5b²` of a
number `a + b√-5` leaves remainder 1 on division by 4, so the Artin symbol `i ↦ i^N` of
every principal odd ideal is `+1`. -/
theorem odd_norm_sq_add_five_sq_mod_four (a b : ℤ) (h : Odd (a ^ 2 + 5 * b ^ 2)) :
    (a ^ 2 + 5 * b ^ 2) % 4 = 1 := by
  have h2 : (a ^ 2 + 5 * b ^ 2) % 2 = 1 := Int.odd_iff.mp h
  have key : ∀ r s : ZMod 4, (r ^ 2 + 5 * s ^ 2).val ≠ 3 := by decide
  have hcast : ((a ^ 2 + 5 * b ^ 2 : ℤ) : ZMod 4) = (a : ZMod 4) ^ 2 + 5 * (b : ZMod 4) ^ 2 := by
    push_cast; ring
  have hv := ZMod.val_intCast (n := 4) (a ^ 2 + 5 * b ^ 2)
  have := key a b
  rw [← hcast] at this
  omega

/-! ### The card's worked whole-number examples -/

-- Root minus five: 29 and 41 are x^2 + 5y^2, and they are 9 and 1 mod 20.
example : (29 : ℕ) = 3 ^ 2 + 5 * 2 ^ 2 ∧ (41 : ℕ) = 6 ^ 2 + 5 * 1 ^ 2 := by norm_num
example : (29 : ℕ) % 20 = 9 ∧ (41 : ℕ) % 20 = 1 := by decide
-- 3 and 7 are not x^2 + 5y^2 (any solution has x, y < 3), but they are 2x^2 + 2xy + 3y^2.
example : ∀ x < 3, ∀ y < 3, x ^ 2 + 5 * y ^ 2 ≠ 3 ∧ x ^ 2 + 5 * y ^ 2 ≠ 7 := by decide
example : (3 : ℤ) = 2 * 0 ^ 2 + 2 * 0 * 1 + 3 * 1 ^ 2 ∧ (7 : ℤ) = 2 * 1 ^ 2 + 2 * 1 * 1 + 3 * 1 ^ 2 := by
  norm_num
-- Symbols multiply: p3 p7 has symbol +1 and 21 = 4^2 + 5 = 1 + 5 * 2^2; p3 p29 has symbol -1 and 87 is not x^2 + 5y^2.
example : (21 : ℕ) = 4 ^ 2 + 5 * 1 ^ 2 ∧ (21 : ℕ) = 1 ^ 2 + 5 * 2 ^ 2 := by norm_num
example : ∀ x < 10, ∀ y < 10, x ^ 2 + 5 * y ^ 2 ≠ 87 := by decide
-- Over 2: t^2 - t - 1 has no root mod 2. Over 5: t^2 + 1 has the roots 2 and 3 mod 5.
example : ∀ t : ZMod 2, t ^ 2 - t - 1 ≠ 0 := by decide
example : ∀ t : ZMod 5, t ^ 2 + 1 = 0 ↔ t = 2 ∨ t = 3 := by decide

-- x^2 + 14y^2: 23 = 3^2 + 14, and f14 = t^4 + 2t^2 - 7 has exactly the roots 3, 9, 14, 20 mod 23.
example : (23 : ℕ) = 3 ^ 2 + 14 * 1 ^ 2 := by norm_num
example : ∀ t : ZMod 23, t ^ 4 + 2 * t ^ 2 - 7 = 0 ↔ t = 3 ∨ t = 9 ∨ t = 14 ∨ t = 20 := by decide
-- 71 is not x^2 + 14y^2 (any solution has x, y < 9), f14 has no root mod 71, and 71 = 2 * 2^2 + 7 * 3^2.
example : ∀ x < 9, ∀ y < 9, x ^ 2 + 14 * y ^ 2 ≠ 71 := by decide
example : ∀ t : ZMod 71, t ^ 4 + 2 * t ^ 2 - 7 ≠ 0 := by decide
example : (71 : ℕ) = 2 * 2 ^ 2 + 7 * 3 ^ 2 := by norm_num
-- Class orders, with witnesses: 3, 5, 13 have order 4; 71 has order 2.
example : (3 : ℕ) ^ 4 = 5 ^ 2 + 14 * 2 ^ 2 ∧ (5 : ℕ) ^ 4 = 11 ^ 2 + 14 * 6 ^ 2 ∧
    (13 : ℕ) ^ 4 = 155 ^ 2 + 14 * 18 ^ 2 ∧ (71 : ℕ) ^ 2 = 55 ^ 2 + 14 * 12 ^ 2 := by norm_num
-- Mod 3, f14 takes the values -7, -4, 17 at 0, 1, 2: no root.
example : ∀ t : ZMod 3, t ^ 4 + 2 * t ^ 2 - 7 ≠ 0 := by decide

-- What breaks: disc f14 = 16 b (a^2 - 4b)^2 with a = 2, b = -7 is -114688 = -2^14 * 7.
example : (16 * (-7) * (2 ^ 2 - 4 * (-7)) ^ 2 : ℤ) = -114688 ∧ (-114688 : ℤ) = -2 ^ 14 * 7 := by norm_num
-- What breaks: mod 7, f14 has the root 0, yet 7 is not x^2 + 14y^2.
example : ((0 : ZMod 7) ^ 4 + 2 * 0 ^ 2 - 7 = 0) ∧ ∀ x < 3, ∀ y < 3, x ^ 2 + 14 * y ^ 2 ≠ 7 := by decide
-- What breaks: 17 gives f14 a root but is not x^2 + 14y^2.
example : (∃ t : ZMod 17, t ^ 4 + 2 * t ^ 2 - 7 = 0) ∧ ∀ x < 5, ∀ y < 5, x ^ 2 + 14 * y ^ 2 ≠ 17 := by
  decide
-- What breaks: n = 27. 7 is 1 mod 3, yet 7 is not x^2 + 27y^2, and 2 is not a cube mod 7.
example : 7 % 3 = 1 ∧ ∀ x < 3, ∀ y < 3, x ^ 2 + 27 * y ^ 2 ≠ 7 := by decide
example : ∀ t : ZMod 7, t ^ 3 ≠ 2 := by decide

#print axioms prime_eq_sq_add_five_sq_iff_splits_completely
#print axioms prime_eq_sq_add_five_sq_iff_mod_twenty
#print axioms odd_norm_sq_add_five_sq_mod_four
