-- Quadratic reciprocity: for two different odd primes p and q, (p/q)(q/p) = (-1)^((p-1)/2 · (q-1)/2), equivalently (q/p) = (p*/q), and the Gauss sum built from any ζ with ζ^p = 1 and 1 + ζ + … + ζ^(p-1) = 0 squares to p*.
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.NumberTheory.LegendreSymbol.JacobiSymbol
import Mathlib.Tactic.NormNum.LegendreSymbol
import Mathlib.Tactic.NormNum.Prime

instance fact_prime_3 : Fact (Nat.Prime 3) := ⟨by norm_num⟩
instance fact_prime_5 : Fact (Nat.Prime 5) := ⟨by norm_num⟩
instance fact_prime_7 : Fact (Nat.Prime 7) := ⟨by norm_num⟩
instance fact_prime_11 : Fact (Nat.Prime 11) := ⟨by norm_num⟩
instance fact_prime_43 : Fact (Nat.Prime 43) := ⟨by norm_num⟩
instance fact_prime_97 : Fact (Nat.Prime 97) := ⟨by norm_num⟩

/-- **Quadratic reciprocity.** For two different odd primes p and q, the Legendre symbols
(p/q) and (q/p) multiply to (-1)^((p-1)/2 · (q-1)/2): the answers to "is p a square mod q?"
and "is q a square mod p?" agree unless both primes are 3 mod 4, when they are opposite.
In Mathlib, `legendreSym q p` is (p/q). -/
theorem quadratic_reciprocity_odd_primes (p q : ℕ) [Fact p.Prime] [Fact q.Prime]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    legendreSym q p * legendreSym p q = (-1) ^ ((p - 1) / 2 * ((q - 1) / 2)) := by
  have hp1 : p % 2 = 1 := (Nat.Prime.eq_two_or_odd (Fact.out : p.Prime)).resolve_left hp
  have hq1 : q % 2 = 1 := (Nat.Prime.eq_two_or_odd (Fact.out : q.Prime)).resolve_left hq
  have ep : (p - 1) / 2 = p / 2 := by omega
  have eq' : (q - 1) / 2 = q / 2 := by omega
  rw [ep, eq']
  exact legendreSym.quadratic_reciprocity hp hq hpq

/-- **The p* form.** For two different odd primes p and q, with p* = (-1)^((p-1)/2) · p,
q is a square mod p exactly when p* is a square mod q: (q/p) = (p*/q). -/
theorem legendre_eq_legendre_p_star (p q : ℕ) [Fact p.Prime] [Fact q.Prime]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    legendreSym p q = legendreSym q ((-1) ^ ((p - 1) / 2) * p) := by
  have hp1 : p % 2 = 1 := (Nat.Prime.eq_two_or_odd (Fact.out : p.Prime)).resolve_left hp
  have hq1 : q % 2 = 1 := (Nat.Prime.eq_two_or_odd (Fact.out : q.Prime)).resolve_left hq
  have ep : (p - 1) / 2 = p / 2 := by omega
  have hq₂ : ringChar (ZMod q) ≠ 2 := by rw [ZMod.ringChar_zmod_n]; exact hq
  have hneg : legendreSym q ((-1) ^ ((p - 1) / 2) * p) = (-1) ^ (q / 2 * (p / 2)) * legendreSym q p := by
    rw [ep]
    unfold legendreSym
    push_cast
    rw [map_mul, map_pow, quadraticChar_neg_one hq₂, ZMod.card q, ZMod.χ₄_eq_neg_one_pow hq1,
      ← pow_mul]
  rw [hneg, legendreSym.quadratic_reciprocity' hp hq, ← mul_assoc, ← pow_add, mul_comm (q / 2),
    ← two_mul, pow_mul]
  simp

/-- **The Gauss sum squared is p*.** In any commutative ring (for instance arithmetic mod q),
if ζ satisfies the two rules ζ^p = 1 and 1 + ζ + … + ζ^(p-1) = 0, then the Gauss sum
g = ∑_{a=1}^{p-1} (a/p) ζ^a satisfies g² = p* = (-1)^((p-1)/2) · p, for every odd prime p. -/
theorem gauss_sum_sq_eq_p_star {R : Type*} [CommRing R] (p : ℕ) [Fact p.Prime] (hp : p ≠ 2)
    (ζ : R) (h1 : ζ ^ p = 1) (h2 : ∑ i ∈ Finset.range p, ζ ^ i = 0) :
    (∑ a ∈ Finset.Ico 1 p, (legendreSym p a : R) * ζ ^ a) ^ 2
      = (((-1) ^ ((p - 1) / 2) * p : ℤ) : R) := by
  classical
  have hpp : p.Prime := Fact.out
  have hp1 : p % 2 = 1 := hpp.eq_two_or_odd.resolve_left hp
  have hF : ringChar (ZMod p) ≠ 2 := by rw [ZMod.ringChar_zmod_n]; exact hp
  set χ := quadraticChar (ZMod p) with hχ
  set e : ZMod p → R := fun x => ζ ^ x.val with he
  have hmod : ∀ n : ℕ, ζ ^ (n % p) = ζ ^ n := by
    intro n
    conv_rhs => rw [← Nat.mod_add_div n p, pow_add, pow_mul, h1, one_pow, mul_one]
  have he_add : ∀ x y : ZMod p, e (x + y) = e x * e y := by
    intro x y
    simp only [he, ZMod.val_add, hmod, pow_add]
  have he_zero : e 0 = 1 := by simp [he]
  have hsum_e : ∑ x : ZMod p, e x = 0 := by
    rw [← h2]
    refine Finset.sum_nbij' (fun x => x.val) (fun i => (i : ZMod p)) ?_ ?_ ?_ ?_ ?_
    · intro x _; simp [ZMod.val_lt]
    · intro i _; simp
    · intro x _; simp
    · intro i hi
      have hi' : i < p := by simpa using hi
      simp [ZMod.val_natCast, Nat.mod_eq_of_lt hi']
    · intro x _; rfl
  have hsum_mul : ∀ c : ZMod p, ∑ x : ZMod p, e (x * c) = if c = 0 then (p : R) else 0 := by
    intro c
    split_ifs with hc
    · simp [hc, he_zero]
    · rw [← hsum_e]
      exact Fintype.sum_bijective _ (mulRight_bijective₀ c hc) _ _ (fun x => rfl)
  have hG : ∑ a ∈ Finset.Ico 1 p, (legendreSym p a : R) * ζ ^ a
      = ∑ x : ZMod p, (χ x : R) * e x := by
    have h0 : ∑ a ∈ Finset.Ico 1 p, (legendreSym p a : R) * ζ ^ a
        = ∑ a ∈ Finset.range p, (legendreSym p a : R) * ζ ^ a := by
      rw [Finset.range_eq_Ico, Finset.sum_eq_sum_Ico_succ_bot hpp.pos]
      simp [legendreSym]
    rw [h0]
    symm
    refine Finset.sum_nbij' (fun x => x.val) (fun i => (i : ZMod p)) ?_ ?_ ?_ ?_ ?_
    · intro x _; simp [ZMod.val_lt]
    · intro i _; simp
    · intro x _; simp
    · intro i hi
      have hi' : i < p := by simpa using hi
      simp [ZMod.val_natCast, Nat.mod_eq_of_lt hi']
    · intro x _
      simp [legendreSym, hχ, he]
  have hinner : ∀ x : ZMod p, ∑ y : ZMod p, (χ x : R) * e x * ((χ y : R) * e y)
      = ∑ c : ZMod p, (χ c : R) * e (x * (1 + c)) := by
    intro x
    by_cases hx : x = 0
    · subst hx
      simp only [MulChar.map_zero, Int.cast_zero, zero_mul, Finset.sum_const_zero, he_zero,
        mul_one]
      rw [← Int.cast_sum, quadraticChar_sum_zero hF, Int.cast_zero]
    · rw [← Fintype.sum_bijective _ (mulLeft_bijective₀ x hx)
        (fun c => (χ x : R) * e x * ((χ (x * c) : R) * e (x * c))) _ (fun c => rfl)]
      refine Finset.sum_congr rfl (fun c _ => ?_)
      have hsq := quadraticChar_sq_one hx
      have hsq' : (χ x : R) * (χ x : R) = 1 := by
        rw [← Int.cast_mul, ← sq, hsq, Int.cast_one]
      rw [map_mul, mul_add, mul_one, he_add, Int.cast_mul]
      linear_combination ((χ c : R) * e x * e (x * c)) * hsq'
  have hneg : (χ (-1) : ℤ) = (-1) ^ ((p - 1) / 2) := by
    have ep : (p - 1) / 2 = p / 2 := by omega
    rw [hχ, quadraticChar_neg_one hF, ZMod.card p, ZMod.χ₄_eq_neg_one_pow hp1, ep]
  rw [hG, sq, Finset.sum_mul_sum, Finset.sum_congr rfl (fun x _ => hinner x), Finset.sum_comm]
  simp_rw [← Finset.mul_sum, hsum_mul, add_eq_zero_iff_neg_eq, mul_ite, mul_zero]
  rw [Finset.sum_ite_eq]
  simp only [Finset.mem_univ, ite_true]
  rw [hneg]
  push_cast
  ring

-- Worked numbers: 43 is a square mod 97, with witness 25.
example : (25 * 25 : ℕ) = 6 * 97 + 43 := by norm_num
example : (25 : ZMod 97) ^ 2 = 43 := by decide
example : (43 : ℕ) ^ 48 % 97 = 1 := by norm_num
example : legendreSym 97 43 = 1 := by norm_num
-- The chain (43/97) = +(97/43) = +(11/43) = -(43/11) = -(10/11) = -(-1/11) = +1.
example : legendreSym 43 97 = legendreSym 43 11 := by norm_num
example : legendreSym 43 11 = 1 := by norm_num
example : legendreSym 11 43 = legendreSym 11 10 := by norm_num
example : legendreSym 11 10 = -1 := by norm_num
example : legendreSym 11 (-1) = -1 := by norm_num
-- p* signs: 97* = 97 and 43* = -43; (43/97) = (97*/43) and (97/43) = (43*/97).
example : legendreSym 97 43 = legendreSym 43 ((-1) ^ ((97 - 1) / 2) * 97) := by norm_num
example : legendreSym 43 97 = legendreSym 97 ((-1) ^ ((43 - 1) / 2) * 43) := by norm_num
-- Step 7 and mistake 3: (5/3) = (-3/5) = -1; (3/7) = -1 but (7/3) = +1.
example : legendreSym 3 5 = -1 := by norm_num
example : legendreSym 5 (-3) = -1 := by norm_num
example : legendreSym 7 3 = -1 := by norm_num
example : legendreSym 3 7 = 1 := by norm_num
-- Mistake 5: over the composite 15 the rules say +1, yet 2 is not a square mod 15.
example : legendreSym 3 2 * legendreSym 5 2 = 1 := by norm_num
example : jacobiSym 2 15 = 1 := by norm_num
example : ¬ ∃ x : ZMod 15, x ^ 2 = 2 := by decide

#print axioms quadratic_reciprocity_odd_primes
#print axioms legendre_eq_legendre_p_star
#print axioms gauss_sum_sq_eq_p_star
