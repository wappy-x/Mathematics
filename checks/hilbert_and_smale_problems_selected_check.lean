-- Hilbert's and Smale's lists: Matiyasevich's Fibonacci lemma, that the square of the n-th Fibonacci number divides the m-th exactly when n times the n-th Fibonacci number divides m (for n at least 3), with its remainder formula and the equation picking out neighbouring Fibonacci pairs.
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.NormNum
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith

open Nat

theorem fib_mul_zmod (p j : ℕ) :
    ((fib ((p + 1) * (j + 1)) : ZMod (fib (p + 1) ^ 2)) =
        ((j + 1 : ℕ) : ZMod (fib (p + 1) ^ 2)) * fib (p + 1) * fib p ^ j) ∧
    ((fib ((p + 1) * (j + 1) + 1) : ZMod (fib (p + 1) ^ 2)) =
        fib p ^ (j + 1) + ((j + 1 : ℕ) : ZMod (fib (p + 1) ^ 2)) * fib (p + 1) * fib p ^ j) := by
  have hF2 : ((fib (p + 1) : ZMod (fib (p + 1) ^ 2))) ^ 2 = 0 := by
    rw [← Nat.cast_pow, ZMod.natCast_self]
  induction j with
  | zero =>
    refine ⟨by simp, ?_⟩
    have : (p + 1) * (0 + 1) + 1 = p + 2 := by ring
    rw [this, fib_add_two]; push_cast; ring
  | succ j ih =>
    obtain ⟨h1, h2⟩ := ih
    have e1 : fib ((p + 1) * (j + 1 + 1)) =
        fib ((p + 1) * (j + 1)) * fib p + fib ((p + 1) * (j + 1) + 1) * fib (p + 1) := by
      have : (p + 1) * (j + 1 + 1) = (p + 1) * (j + 1) + p + 1 := by ring
      rw [this, fib_add]
    have e2 : fib ((p + 1) * (j + 1 + 1) + 1) =
        fib ((p + 1) * (j + 1)) * fib (p + 1) + fib ((p + 1) * (j + 1) + 1) * fib (p + 2) := by
      have : (p + 1) * (j + 1 + 1) + 1 = (p + 1) * (j + 1) + (p + 1) + 1 := by ring
      rw [this, fib_add]
    rw [fib_add_two] at e2
    constructor
    · rw [e1]; push_cast at h1 h2 ⊢; rw [h1, h2]
      linear_combination ((j + 1 : ZMod _) * fib p ^ j) * hF2
    · rw [e2]; push_cast at h1 h2 ⊢; rw [h1, h2]
      linear_combination ((j + 1 : ZMod _) * fib p ^ j + (j + 1 : ZMod _) * fib p ^ j) * hF2

#print axioms fib_mul_zmod

theorem fib_mul_modEq_aux (n k : ℕ) :
    fib (n * k) ≡ k * fib n * fib (n - 1) ^ (k - 1) [MOD fib n ^ 2] := by
  rcases n with _ | p
  · simp
  rcases k with _ | j
  · simpa using Nat.ModEq.refl 0
  rw [← ZMod.natCast_eq_natCast_iff]
  simp only [Nat.add_sub_cancel]
  rw [(fib_mul_zmod p j).1]
  push_cast; ring

#print axioms fib_mul_modEq_aux

theorem dvd_of_fib_dvd_fib {n m : ℕ} (hn : 3 ≤ n) (h : fib n ∣ fib m) : n ∣ m := by
  have hg : fib (Nat.gcd n m) = fib n := by
    rw [fib_gcd]; exact Nat.gcd_eq_left h
  have hle : Nat.gcd n m ≤ n := Nat.gcd_le_left _ (by omega)
  have heq : Nat.gcd n m = n := by
    by_contra hne
    have hlt : Nat.gcd n m < n := lt_of_le_of_ne hle hne
    by_cases h2 : 2 ≤ Nat.gcd n m
    · have := (fib_lt_fib h2).2 hlt
      omega
    · have h3 : fib 3 ≤ fib n := fib_mono hn
      have f3 : fib 3 = 2 := rfl
      rcases (by omega : Nat.gcd n m = 0 ∨ Nat.gcd n m = 1) with h0 | h0 <;>
        rw [h0] at hg <;> simp at hg <;> omega
  exact heq ▸ Nat.gcd_dvd_right n m

#print axioms dvd_of_fib_dvd_fib

theorem cassini_sq (k : ℕ) :
    ((fib (k + 1) : ℤ) ^ 2 - fib k * fib (k + 1) - fib k ^ 2) ^ 2 = 1 := by
  induction k with
  | zero => simp
  | succ k ih =>
    have e : (fib (k + 2) : ℤ) = fib k + fib (k + 1) := by exact_mod_cast fib_add_two
    rw [show k + 1 + 1 = k + 2 by ring, e]
    linear_combination ih

#print axioms cassini_sq

theorem neighbouring_fwd (s : ℕ) : ∀ a b : ℕ, a + b = s → a ≤ b →
    ((b : ℤ) ^ 2 - a * b - a ^ 2) ^ 2 = 1 → ∃ k, a = fib k ∧ b = fib (k + 1) := by
  induction s using Nat.strong_induction_on with
  | _ s ih =>
  intro a b hs hab h
  rcases Nat.eq_zero_or_pos a with rfl | ha
  · have h4 : b ^ 4 = 1 := by
      have : ((b : ℤ) ^ 4) = 1 := by linear_combination h
      exact_mod_cast this
    have hb : b = 1 := by simpa using h4
    exact ⟨0, by simp, by simp [hb]⟩
  · have hb2 : b ≤ 2 * a := by
      by_contra hc
      have hc' : (2 * a + 1 : ℤ) ≤ b := by exact_mod_cast (by omega : 2 * a + 1 ≤ b)
      have ha' : (1 : ℤ) ≤ a := by exact_mod_cast ha
      have hx : (b : ℤ) ^ 2 - a * b - a ^ 2 ≤ 1 := by
        nlinarith [sq_nonneg ((b : ℤ) ^ 2 - a * b - a ^ 2 - 1)]
      have ht : (0 : ℤ) ≤ b - (2 * a + 1) := by linarith
      nlinarith [mul_nonneg ht ht, mul_nonneg (by linarith : (0 : ℤ) ≤ a) ht]
    obtain ⟨k, hk1, hk2⟩ := ih b (by omega) (b - a) a (by omega) (by omega) (by
      push_cast [hab]
      linear_combination h)
    refine ⟨k + 1, hk2, ?_⟩
    rw [fib_add_two, ← hk1, ← hk2]; omega

#print axioms neighbouring_fwd

/-- Matiyasevich's lemma: for n at least 3, the square of the n-th Fibonacci number
divides the m-th Fibonacci number exactly when n times the n-th Fibonacci number
divides m. -/
theorem fib_sq_dvd_fib_iff (n m : ℕ) (hn : 3 ≤ n) :
    fib n ^ 2 ∣ fib m ↔ n * fib n ∣ m := by
  have hFpos : 0 < fib n := fib_pos.2 (by omega)
  constructor
  · intro h
    have h1 : fib n ∣ fib m := (dvd_pow_self _ two_ne_zero).trans h
    obtain ⟨k, rfl⟩ := dvd_of_fib_dvd_fib hn h1
    have hmod := fib_mul_modEq_aux n k
    have h0 : k * fib n * fib (n - 1) ^ (k - 1) ≡ 0 [MOD fib n ^ 2] :=
      hmod.symm.trans ((Nat.modEq_zero_iff_dvd).2 h)
    rw [Nat.modEq_zero_iff_dvd] at h0
    have h2 : fib n * fib n ∣ fib n * (k * fib (n - 1) ^ (k - 1)) := by
      rw [← pow_two]; convert h0 using 1; ring
    have h3 : fib n ∣ k * fib (n - 1) ^ (k - 1) := Nat.dvd_of_mul_dvd_mul_left hFpos h2
    have hcop : Nat.Coprime (fib n) (fib (n - 1)) := by
      have := fib_coprime_fib_succ (n - 1)
      rw [Nat.sub_add_cancel (by omega)] at this
      exact this.symm
    have h4 : fib n ∣ k := (Nat.Coprime.pow_right (k - 1) hcop).dvd_of_dvd_mul_right h3
    exact Nat.mul_dvd_mul_left n h4
  · rintro ⟨j, rfl⟩
    have hmod := fib_mul_modEq_aux n (fib n * j)
    rw [← mul_assoc] at hmod
    apply (Nat.modEq_zero_iff_dvd).1
    refine hmod.trans ((Nat.modEq_zero_iff_dvd).2 ?_)
    exact ⟨j * fib (n - 1) ^ (fib n * j - 1), by ring⟩

/-- The remainder formula: the Fibonacci number at position n times k leaves the same
remainder on division by the square of the n-th Fibonacci number as
k times the n-th Fibonacci number times the (n − 1)-th to the power k − 1. -/
theorem fib_mul_modEq (n k : ℕ) :
    fib (n * k) ≡ k * fib n * fib (n - 1) ^ (k - 1) [MOD fib n ^ 2] := by
  exact fib_mul_modEq_aux n k

/-- Whole numbers 0 ≤ a ≤ b are neighbouring Fibonacci numbers exactly when
(b² − ab − a²)² = 1. -/
theorem neighbouring_fib_iff (a b : ℕ) (hab : a ≤ b) :
    ((b : ℤ) ^ 2 - a * b - a ^ 2) ^ 2 = 1 ↔ ∃ k, a = fib k ∧ b = fib (k + 1) := by
  constructor
  · exact neighbouring_fwd (a + b) a b rfl hab
  · rintro ⟨k, rfl, rfl⟩
    exact cassini_sq k

-- n = 5, k = 3: F_15 = 610 and the formula's 3 × 5 × 3² = 135 both leave 10 on division by 25.
example : fib 5 = 5 ∧ fib 4 = 3 ∧ fib 15 = 610 := by decide
example : 3 * 5 * 3 ^ 2 = 135 ∧ 610 % 25 = 10 ∧ 135 % 25 = 10 := by norm_num
-- F_25 = 75,025 = 25 × 3,001.
example : fib 25 = 75025 ∧ 75025 = 25 * 3001 := by decide
-- n = 2 breaks the lemma: F_2 = 1 divides F_3 = 2, but 2 does not divide 3.
example : fib 2 = 1 ∧ fib 3 = 2 ∧ fib 2 ^ 2 ∣ fib 3 ∧ ¬ (2 * fib 2 ∣ 3) := by decide
-- n = 20: F_20 = 6,765, so m must be a multiple of 20 × 6,765 = 135,300.
example : fib 20 = 6765 ∧ 20 * fib 20 = 135300 := by decide

#print axioms fib_sq_dvd_fib_iff
#print axioms fib_mul_modEq
#print axioms neighbouring_fib_iff
