-- Lattices: Kyber's decryption identity v - sᵀu = 1665·m + (eᵀr - sᵀe₁ + e₂) holds over every commutative ring, rounding mod 3329 returns each bit whenever the noise stays below 832, two bases related by a whole-number mix of area factor 1 make the same lattice, and the card's size, lattice and Shor numbers are exact.
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Algebra.Order.Group.Abs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.PowMod
import Mathlib.Tactic.NormNum.GCD
import Mathlib

namespace LatticesAndPostQuantumCryptography

open Matrix

/-- The decryption identity (Step 3). Work in any commutative ring `R` (for Kyber, polynomials
mod q with X^256 = -1) and any number of rows. Let the public key be t = A s + e, and let the
ciphertext be u = Aᵀ r + e₁ and v = tᵀ r + e₂ + 1665 m. Then the owner of s computes
v - sᵀ u = 1665 m + (eᵀ r - sᵀ e₁ + e₂): the terms (A s)ᵀ r and sᵀ Aᵀ r cancel, and only
the message and a noise made of the small numbers remain. -/
theorem kyber_decryption_identity {R ι : Type*} [CommRing R] [Fintype ι]
    (A : Matrix ι ι R) (s e r e₁ t u : ι → R) (e₂ m v : R)
    (ht : t = A *ᵥ s + e) (hu : u = Aᵀ *ᵥ r + e₁) (hv : v = t ⬝ᵥ r + e₂ + 1665 * m) :
    v - s ⬝ᵥ u = 1665 * m + (e ⬝ᵥ r - s ⬝ᵥ e₁ + e₂) := by
  subst ht hu hv
  simp only [add_dotProduct, dotProduct_add, dotProduct_mulVec, vecMul_transpose]
  rw [dotProduct_comm (A *ᵥ s) r]
  ring

/-- Kyber's rounding of one number mod q = 3329 to a bit: `compress(x, 1)` in the card's code,
⌊(4x + q) / 2q⌋ mod 2. It gives 1 when x is nearer 1665 than 0 on the clock, and 0 otherwise. -/
def roundBit (x : ZMod 3329) : ℕ := (4 * x.val + 3329) / 6658 % 2

/-- Decryption succeeds when the noise is small (When it holds). If a bit b is sent as
1665·b and the total noise d is below q/4 = 832 in size, then rounding 1665·b + d mod 3329
to the nearer of 0 and 1665 returns b. -/
theorem round_recovers_bit_of_noise_lt_832 (b : ℕ) (hb : b ≤ 1) (d : ℤ) (hd : |d| < 832) :
    roundBit (((1665 * b : ℤ) + d : ℤ) : ZMod 3329) = b := by
  unfold roundBit
  have hx := ZMod.val_intCast (n := 3329) ((1665 * b : ℤ) + d)
  generalize ((((1665 * b : ℤ) + d : ℤ) : ZMod 3329)).val = x at hx ⊢
  rw [abs_lt] at hd
  push_cast at hx
  obtain ⟨hd1, hd2⟩ := hd
  interval_cases b
  · rcases le_or_gt 0 d with h0 | h0
    · have : (x : ℤ) = d := by rw [hx]; omega
      omega
    · have : (x : ℤ) = d + 3329 := by rw [hx]; omega
      omega
  · have : (x : ℤ) = 1665 + d := by rw [hx]; omega
    omega

/-- A good basis and a bad basis make the same lattice (Step 1). If the arrows c₁ = a g₁ + b g₂
and c₂ = c g₁ + d g₂ are whole-number mixes of g₁ and g₂ whose area factor a d - b c is 1,
the mix can be undone with whole numbers, so every whole-number mix of c₁, c₂ is one of
g₁, g₂ and back: L(c₁, c₂) = L(g₁, g₂). -/
theorem same_lattice_of_mix_with_area_factor_one {n : ℕ} (g₁ g₂ : Fin n → ℤ) (a b c d : ℤ)
    (h : a * d - b * c = 1) :
    Submodule.span ℤ ({a • g₁ + b • g₂, c • g₁ + d • g₂} : Set (Fin n → ℤ)) =
      Submodule.span ℤ ({g₁, g₂} : Set (Fin n → ℤ)) := by
  apply le_antisymm
  · rw [Submodule.span_le, Set.insert_subset_iff, Set.singleton_subset_iff]
    have m1 : g₁ ∈ Submodule.span ℤ ({g₁, g₂} : Set (Fin n → ℤ)) :=
      Submodule.subset_span (by simp)
    have m2 : g₂ ∈ Submodule.span ℤ ({g₁, g₂} : Set (Fin n → ℤ)) :=
      Submodule.subset_span (by simp)
    exact ⟨Submodule.add_mem _ (Submodule.smul_mem _ _ m1) (Submodule.smul_mem _ _ m2),
      Submodule.add_mem _ (Submodule.smul_mem _ _ m1) (Submodule.smul_mem _ _ m2)⟩
  · rw [Submodule.span_le, Set.insert_subset_iff, Set.singleton_subset_iff]
    set S := Submodule.span ℤ ({a • g₁ + b • g₂, c • g₁ + d • g₂} : Set (Fin n → ℤ)) with hS
    have m1 : a • g₁ + b • g₂ ∈ S := Submodule.subset_span (by simp)
    have m2 : c • g₁ + d • g₂ ∈ S := Submodule.subset_span (by simp)
    have h1 : g₁ = d • (a • g₁ + b • g₂) + (-b) • (c • g₁ + d • g₂) := by
      ext i
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      linear_combination (-(g₁ i)) * h
    have h2 : g₂ = (-c) • (a • g₁ + b • g₂) + a • (c • g₁ + d • g₂) := by
      ext i
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      linear_combination (-(g₂ i)) * h
    refine ⟨?_, ?_⟩
    · rw [h1]
      exact Submodule.add_mem _ (Submodule.smul_mem _ _ m1) (Submodule.smul_mem _ _ m2)
    · rw [h2]
      exact Submodule.add_mem _ (Submodule.smul_mem _ _ m1) (Submodule.smul_mem _ _ m2)

-- Kyber-768 sizes: 3 × 256 = 768 secret numbers; key 3 × 256 × 12 / 8 + 32 = 1,184 bytes;
-- ciphertext 3 × 256 × 10 / 8 + 256 × 4 / 8 = 960 + 128 = 1,088 bytes.
example : 3 * 256 = 768 ∧ 3 * 256 * 12 / 8 = 1152 ∧ 1152 + 32 = 1184 := by decide
example : 3 * 256 * 10 / 8 = 960 ∧ 256 * 4 / 8 = 128 ∧ 960 + 128 = 1088 := by decide
-- 1665 is q/2 rounded, 832 is q/4 rounded down; the key is 37 times an X25519 key.
example : (3329 + 1) / 2 = 1665 ∧ 3329 / 4 = 832 ∧ 1184 = 37 * 32 := by decide
-- Hybrid shares 1,184 + 32 = 1,216 and 1,088 + 32 = 1,120; Kyber-512 800 and 768,
-- Kyber-1024 1,568 and 1,568.
example : 1184 + 32 = 1216 ∧ 1088 + 32 = 1120 := by decide
example : 384 * 2 + 32 = 800 ∧ 32 * (10 * 2 + 4) = 768 ∧
    384 * 4 + 32 = 1568 ∧ 32 * (11 * 4 + 5) = 1568 := by decide
-- ML-DSA-65: public key 32 + 320 × 6 = 1,952 bytes, signature 192/4 + 5 × 32 × 20 + 55 + 6 = 3,309.
example : 32 + 320 * 6 = 1952 ∧ 192 / 4 + 5 * 32 * (1 + 19) + 55 + 6 = 3309 := by decide

-- The bad arrows are mixes of the good ones: (17, 14) = 5 (4, 1) + 3 (-1, 3),
-- (10, 9) = 3 (4, 1) + 2 (-1, 3), with area factor 5 × 2 - 3 × 3 = 1; both cells have area 13.
example : ((5 * 4 + 3 * (-1) : ℤ), (5 * 1 + 3 * 3 : ℤ)) = (17, 14) ∧
    ((3 * 4 + 2 * (-1) : ℤ), (3 * 1 + 2 * 3 : ℤ)) = (10, 9) := by decide
example : (5 * 2 - 3 * 3 : ℤ) = 1 ∧ (4 * 3 - 1 * (-1) : ℤ) = 13 ∧ (17 * 9 - 14 * 10 : ℤ) = 13 := by
  decide
-- The shortest nonzero point of the lattice x (4, 1) + y (-1, 3) has length² 10, at (1, -3).
example : ∀ x y : ℤ, (x, y) ≠ (0, 0) → 10 ≤ (4 * x - y) ^ 2 + (x + 3 * y) ^ 2 := by 
  intro x y hxy
  by_cases hx : x = 0
  · subst hx
    have hy : y ≠ 0 := by
      intro hy
      exact hxy (by simp [hy])
    have : 1 ≤ y ^ 2 := by
      have : 0 < |y| := abs_pos.mpr hy
      nlinarith [sq_abs y]
    nlinarith
  · have : 1 ≤ x ^ 2 := by
      have : 0 < |x| := abs_pos.mpr hx
      nlinarith [sq_abs x]
    nlinarith [sq_nonneg (x - y), sq_nonneg y]
example : ((0 * 4 + (-1) * (-1) : ℤ), (0 * 1 + (-1) * 3 : ℤ)) = (1, -3) ∧
    (1 : ℤ) ^ 2 + (-3) ^ 2 = 10 := by decide
-- Nearest point to the target (6, 10): (5, 11) = 2 (4, 1) + 3 (-1, 3) at distance² 2,
-- and no lattice point is nearer.
example : ((2 * 4 + 3 * (-1) : ℤ), (2 * 1 + 3 * 3 : ℤ)) = (5, 11) ∧
    (5 - 6 : ℤ) ^ 2 + (11 - 10) ^ 2 = 2 := by decide
example : ∀ x y : ℤ, 2 ≤ (4 * x - y - 6) ^ 2 + (x + 3 * y - 10) ^ 2 := by 
  intro x y
  by_contra hlt
  rw [not_le] at hlt
  have h1 : (4 * x - y - 6) ^ 2 ≤ 1 := by nlinarith [sq_nonneg (x + 3 * y - 10)]
  have h2 : (x + 3 * y - 10) ^ 2 ≤ 1 := by nlinarith [sq_nonneg (4 * x - y - 6)]
  rw [sq_le_one_iff_abs_le_one, abs_le] at h1 h2
  have : (4 * x - y - 6) ^ 2 + (x + 3 * y - 10) ^ 2 ≤ 1 := by omega
  rcases (show 4 * x - y - 6 = -1 ∨ 4 * x - y - 6 = 0 ∨ 4 * x - y - 6 = 1 by omega) with e | e | e <;>
  rcases (show x + 3 * y - 10 = -1 ∨ x + 3 * y - 10 = 0 ∨ x + 3 * y - 10 = 1 by omega) with f | f | f <;>
  first | omega | (rw [e, f] at hlt; norm_num at hlt)
-- Rounding the amounts: good basis 28/13 → 2 and 34/13 → 3; bad basis -46/13 → -4 and
-- 86/13 → 7, giving (2, 7) = -4 (17, 14) + 7 (10, 9) at distance² 25.
example : (6 * 3 - 10 * (-1) : ℤ) = 28 ∧ (4 * 10 - 1 * 6 : ℤ) = 34 ∧
    (6 * 9 - 10 * 10 : ℤ) = -46 ∧ (17 * 10 - 14 * 6 : ℤ) = 86 := by decide
example : 2 * |(28 : ℤ) - 13 * 2| < 13 ∧ 2 * |(34 : ℤ) - 13 * 3| < 13 ∧
    2 * |(-46 : ℤ) - 13 * (-4)| < 13 ∧ 2 * |(86 : ℤ) - 13 * 7| < 13 := by decide
example : ((-4 * 17 + 7 * 10 : ℤ), (-4 * 14 + 7 * 9 : ℤ)) = (2, 7) ∧
    (2 - 6 : ℤ) ^ 2 + (7 - 10) ^ 2 = 25 := by decide

-- Shor's step on 3233 = 61 × 53: the powers of 3 repeat every 260 steps, 3^130 = 794,
-- and gcd(793, 3233) = 61, gcd(795, 3233) = 53.
example : 61 * 53 = 3233 := by decide
example : orderOf (3 : ZMod 3233) = 260 := by 
  apply orderOf_eq_of_pow_and_pow_div_prime (by norm_num) (by decide)
  intro p hp hdvd
  have h260 : (260 : ℕ) = 2 * 2 * 5 * 13 := by norm_num
  rw [h260] at hdvd
  rcases (Nat.Prime.dvd_mul hp).1 hdvd with h | h
  · rcases (Nat.Prime.dvd_mul hp).1 h with h | h
    · rcases (Nat.Prime.dvd_mul hp).1 h with h | h <;>
      · rw [(Nat.prime_dvd_prime_iff_eq hp Nat.prime_two).1 h]; decide
    · rw [(Nat.prime_dvd_prime_iff_eq hp (by norm_num : Nat.Prime _)).1 h]; decide
  · rw [(Nat.prime_dvd_prime_iff_eq hp (by norm_num : Nat.Prime _)).1 h]; decide
example : (3 : ℕ) ^ 130 % 3233 = 794 ∧ Nat.gcd 793 3233 = 61 ∧ Nat.gcd 795 3233 = 53 := by norm_num
-- With base 2 the period is 780, but 2^390 = 3232 = -1 mod 3233: no factor.
example : orderOf (2 : ZMod 3233) = 780 := by 
  apply orderOf_eq_of_pow_and_pow_div_prime (by norm_num) (by decide)
  intro p hp hdvd
  have h780 : (780 : ℕ) = 2 * 2 * 3 * 5 * 13 := by norm_num
  rw [h780] at hdvd
  rcases (Nat.Prime.dvd_mul hp).1 hdvd with h | h
  · rcases (Nat.Prime.dvd_mul hp).1 h with h | h
    · rcases (Nat.Prime.dvd_mul hp).1 h with h | h
      · rcases (Nat.Prime.dvd_mul hp).1 h with h | h <;>
        · rw [(Nat.prime_dvd_prime_iff_eq hp Nat.prime_two).1 h]; decide
      · rw [(Nat.prime_dvd_prime_iff_eq hp Nat.prime_three).1 h]; decide
    · rw [(Nat.prime_dvd_prime_iff_eq hp (by norm_num : Nat.Prime _)).1 h]; decide
  · rw [(Nat.prime_dvd_prime_iff_eq hp (by norm_num : Nat.Prime _)).1 h]; decide
example : (2 : ℕ) ^ 390 % 3233 = 3232 := by decide

#print axioms kyber_decryption_identity
#print axioms round_recovers_bit_of_noise_lt_832
#print axioms same_lattice_of_mix_with_area_factor_one

end LatticesAndPostQuantumCryptography
