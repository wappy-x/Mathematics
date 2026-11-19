-- The p-adic numbers: a root of a whole-number polynomial modulo a prime p, where the slope is not divisible by p, lifts to exactly one root modulo every power of p and to exactly one p-adic root, and the p-adic size obeys the strong triangle inequality.
import Mathlib.NumberTheory.Padics.PadicIntegers
import Mathlib.NumberTheory.Padics.PadicNorm
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Algebra.Polynomial.AlgebraMap
import Mathlib.Data.ZMod.Basic
import Mathlib.NumberTheory.Padics.Hensel
import Mathlib.NumberTheory.Padics.RingHoms
import Mathlib.Algebra.Polynomial.Identities
import Mathlib.Data.ZMod.Units

open Polynomial

/-- A ring map commutes with evaluating a whole-number polynomial. -/
theorem padic_helper_map_aeval {A B : Type*} [CommRing A] [CommRing B] (φ : A →+* B)
    (f : ℤ[X]) (x : A) : φ (aeval x f) = aeval (φ x) f :=
  (Polynomial.aeval_algHom_apply φ.toIntAlgHom x f).symm

#print axioms padic_helper_map_aeval

/-- Evaluating a whole-number polynomial at a whole number, then casting. -/
theorem padic_helper_aeval_int {A : Type*} [CommRing A] (g : ℤ[X]) (x : ℤ) :
    aeval (x : A) g = ((g.eval x : ℤ) : A) := by
  rw [← eq_intCast (Int.castRingHom A), ← padic_helper_map_aeval, coe_aeval_eq_eval, eq_intCast]

#print axioms padic_helper_aeval_int

/-- A residue mod `p^k` whose reduction mod `p` is nonzero is a unit. -/
theorem padic_helper_isUnit (p : ℕ) [Fact p.Prime] (k : ℕ) (hk : k ≠ 0) (u : ZMod (p ^ k))
    (h : ZMod.castHom (dvd_pow_self p hk) (ZMod p) u ≠ 0) : IsUnit u := by
  have : NeZero (p ^ k) := ⟨pow_ne_zero _ (Fact.out : p.Prime).ne_zero⟩
  rw [ZMod.castHom_apply, ZMod.cast_eq_val, Ne, ZMod.natCast_eq_zero_iff] at h
  rw [← ZMod.natCast_zmod_val u, ZMod.isUnit_iff_coprime,
    Nat.coprime_pow_right_iff (Nat.pos_of_ne_zero hk)]
  exact ((Nat.Prime.coprime_iff_not_dvd Fact.out).2 h).symm

#print axioms padic_helper_isUnit

/-- Two roots mod `p^k` that agree mod `p`, where the slope is a unit, are equal. -/
theorem padic_helper_unique (p : ℕ) [Fact p.Prime] (f : ℤ[X]) (a : ℤ)
    (hslope : ¬ (p : ℤ) ∣ f.derivative.eval a) (k : ℕ) (hk : k ≠ 0) (b c : ZMod (p ^ k))
    (hb : aeval b f = 0) (hba : ZMod.castHom (dvd_pow_self p hk) (ZMod p) b = (a : ZMod p))
    (hc : aeval c f = 0) (hca : ZMod.castHom (dvd_pow_self p hk) (ZMod p) c = (a : ZMod p)) :
    c = b := by
  have hev : ∀ (h : ℤ[X]) (x : ZMod (p ^ k)),
      aeval x h = (h.map (Int.castRingHom (ZMod (p ^ k)))).eval x := by
    intro h x; rw [aeval_def, eval_map, algebraMap_int_eq]
  obtain ⟨e, he⟩ := binomExpansion (f.map (Int.castRingHom (ZMod (p ^ k)))) b (c - b)
  rw [add_sub_cancel, ← hev, hc, ← hev, hb, derivative_map, ← hev] at he
  have hu : IsUnit (aeval b (derivative f) + e * (c - b)) := by
    apply padic_helper_isUnit p k hk
    rw [map_add, map_mul, map_sub, hca, hba, sub_self, mul_zero, add_zero,
      padic_helper_map_aeval, hba, padic_helper_aeval_int, Ne, ZMod.intCast_zmod_eq_zero_iff_dvd]
    exact hslope
  have h0 : (c - b) * (aeval b (derivative f) + e * (c - b)) = 0 := by linear_combination -he
  rw [hu.mul_left_eq_zero] at h0
  exact sub_eq_zero.1 h0

#print axioms padic_helper_unique

/-- Hensel's lemma: let `f` have whole coefficients, and let the whole number `a` satisfy
`f(a) ≡ 0 (mod p)` with `p` not dividing the slope `f'(a)`. Then there is exactly one
p-adic integer `α` with `f(α) = 0` and `α ≡ a (mod p)`. -/
theorem hensel_unique_padic_root (p : ℕ) [Fact p.Prime] (f : ℤ[X]) (a : ℤ)
    (hroot : (p : ℤ) ∣ f.eval a) (hslope : ¬ (p : ℤ) ∣ f.derivative.eval a) :
    ∃! α : ℤ_[p], aeval α f = 0 ∧ (p : ℤ_[p]) ∣ α - (a : ℤ_[p]) := by
  have h1 : ‖aeval (a : ℤ_[p]) f‖ < 1 := by
    rw [padic_helper_aeval_int]; exact (PadicInt.norm_int_lt_one_iff_dvd _).2 hroot
  have h2 : ‖aeval (a : ℤ_[p]) (derivative f)‖ = 1 := by
    rw [padic_helper_aeval_int]
    exact le_antisymm (PadicInt.norm_le_one _)
      (not_lt.1 (fun h => hslope ((PadicInt.norm_int_lt_one_iff_dvd _).1 h)))
  obtain ⟨z, hz, hza, -, huniq⟩ :=
    hensels_lemma (F := f) (a := (a : ℤ_[p])) (by rw [h2, one_pow]; exact h1)
  rw [h2] at hza huniq
  refine ⟨z, ⟨hz, (PadicInt.norm_lt_one_iff_dvd _).1 hza⟩, ?_⟩
  rintro y ⟨hy, hya⟩
  exact huniq y hy ((PadicInt.norm_lt_one_iff_dvd _).2 hya)

/-- The lift one power at a time: under the same hypotheses, for every power `p^k` with
`k ≥ 1` there is exactly one root of `f` modulo `p^k` that reduces to `a` modulo `p`. -/
theorem hensel_unique_root_mod_prime_power (p : ℕ) [Fact p.Prime] (f : ℤ[X]) (a : ℤ)
    (hroot : (p : ℤ) ∣ f.eval a) (hslope : ¬ (p : ℤ) ∣ f.derivative.eval a)
    (k : ℕ) (hk : k ≠ 0) :
    ∃! b : ZMod (p ^ k), aeval b f = 0 ∧
      ZMod.castHom (dvd_pow_self p hk) (ZMod p) b = (a : ZMod p) := by
  obtain ⟨α, ⟨hα, hαa⟩, -⟩ := hensel_unique_padic_root p f a hroot hslope
  have hb : aeval (PadicInt.toZModPow k α) f = 0 := by
    rw [← padic_helper_map_aeval, hα, map_zero]
  have hba : ZMod.castHom (dvd_pow_self p hk) (ZMod p) (PadicInt.toZModPow k α) = (a : ZMod p) := by
    obtain ⟨c, hc⟩ := hαa
    have hα' : α = a + p * c := by rw [← hc]; ring
    rw [hα', map_add, map_add, map_mul, map_mul, map_intCast, map_intCast, map_natCast,
      map_natCast, ZMod.natCast_self, zero_mul, add_zero]
  refine ⟨PadicInt.toZModPow k α, ⟨hb, hba⟩, ?_⟩
  rintro c ⟨hc, hca⟩
  exact padic_helper_unique p f a hslope k hk _ c hb hba hc hca

/-- The strong triangle inequality: for fractions `x` and `y`, the p-adic size of `x + y`
is at most the larger of the p-adic sizes of `x` and `y`. -/
theorem padicNorm_strong_triangle (p : ℕ) [Fact p.Prime] (x y : ℚ) :
    padicNorm p (x + y) ≤ max (padicNorm p x) (padicNorm p y) := by
  exact padicNorm.nonarchimedean

-- Worked example: the lifts 3, 10, 108, 2166 of the 7-adic square root of 2.
example : (3 : ℤ) ^ 2 - 2 = 7 := by norm_num
example : (10 : ℤ) ^ 2 - 2 = 2 * 49 ∧ (10 : ℤ) = 3 + 1 * 7 := by norm_num
example : (108 : ℤ) ^ 2 - 2 = 11662 ∧ (11662 : ℤ) = 34 * 343 ∧ (108 : ℤ) = 10 + 2 * 49 := by norm_num
example : (2166 : ℤ) = 108 + 6 * 343 ∧ ((2166 : ℤ) ^ 2 - 2) % 2401 = 0 := by norm_num
-- The digits t: 1, 2, 6 from t ≡ -c · 6⁻¹ (mod 7), where 6 is its own inverse mod 7.
example : (6 * 6) % 7 = 1 ∧ (-1 * 6 : ℤ) % 7 = 1 ∧ (-2 * 6 : ℤ) % 7 = 2 ∧ (-34 * 6 : ℤ) % 7 = 6 := by
  norm_num
-- The lifts of 4: 39 mod 49 and 235 mod 343 and mod 2401.
example : ((39 : ℤ) ^ 2 - 2) % 49 = 0 ∧ ((235 : ℤ) ^ 2 - 2) % 2401 = 0 := by norm_num
-- Exactly two roots of x² ≡ 2 mod 7, 49 and 343.
example : (Finset.univ.filter (fun x : ZMod 7 => x ^ 2 = 2)).card = 2 := by decide
example : (Finset.univ.filter (fun x : ZMod 49 => x ^ 2 = 2)).card = 2 := by decide
example : (Finset.univ.filter (fun x : ZMod 343 => x ^ 2 = 2)).card = 2 := by decide
-- What breaks: no root of x² ≡ 3 mod 7; x² ≡ 7 has the root 0 mod 7 and none mod 49.
example : ∀ x : ZMod 7, x ^ 2 ≠ 3 := by decide
example : ∀ x : ZMod 49, x ^ 2 ≠ 7 := by decide
-- What breaks at p = 2: roots of x² ≡ 17 mod 2, 4, 8, 16, 32, 64 number 1, 2, 4, 4, 4, 4.
example : (Finset.univ.filter (fun x : ZMod 2 => x ^ 2 = 17)).card = 1 := by decide
example : (Finset.univ.filter (fun x : ZMod 4 => x ^ 2 = 17)).card = 2 := by decide
example : (Finset.univ.filter (fun x : ZMod 8 => x ^ 2 = 17)).card = 4 := by decide
example : (Finset.univ.filter (fun x : ZMod 16 => x ^ 2 = 17)).card = 4 := by decide
example : (Finset.univ.filter (fun x : ZMod 32 => x ^ 2 = 17)).card = 4 := by decide
example : (Finset.univ.filter (fun x : ZMod 64 => x ^ 2 = 17)).card = 4 := by decide
-- Newton's step on exact fractions from 3: 11/6, then 193/132; and 11/6 is 10 mod 49.
example : (3 : ℚ) - (3 ^ 2 - 2) / (2 * 3) = 11 / 6 := by norm_num
example : (11 / 6 : ℚ) - ((11 / 6) ^ 2 - 2) / (2 * (11 / 6)) = 193 / 132 := by norm_num
example : (6 * 10) % 49 = 11 := by norm_num
-- Product formula for 11662 = 2 · 7³ · 17: 11662 · (1/2) · (1/343) · (1/17) = 1.
example : (11662 : ℚ) = 2 * 7 ^ 3 * 17 ∧ (11662 : ℚ) * (1 / 2) * (1 / 343) * (1 / 17) = 1 := by norm_num
-- House example: x² = -5 has the root 3 mod 7, lifting to 17 mod 49 and 311 mod 343.
example : (3 : ℤ) ^ 2 + 5 = 2 * 7 ∧ (17 : ℤ) ^ 2 + 5 = 6 * 49 ∧ (311 : ℤ) ^ 2 + 5 = 282 * 343 := by norm_num

#print axioms hensel_unique_padic_root
#print axioms hensel_unique_root_mod_prime_power
#print axioms padicNorm_strong_triangle
