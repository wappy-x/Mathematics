-- Modularity: the Frey curve y² = x(x − a^p)(x + b^p) of a supposed solution of a^p + b^p = c^p has discriminant 16(abc)^(2p), its three roots never all meet mod a prime when a and b are coprime, and Fermat's last theorem follows from the prime exponents of 5 or more.
import Mathlib.AlgebraicGeometry.EllipticCurve.Weierstrass
import Mathlib.NumberTheory.FLT.Three
import Mathlib.NumberTheory.FLT.Four
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime.Basic

/-- The Frey curve of a supposed solution a^p + b^p = c^p, as a Weierstrass curve over the
rationals: y² = x(x − a^p)(x + b^p) = x³ + (b^p − a^p)x² − a^p b^p x. -/
def freyCurve (a b : ℤ) (p : ℕ) : WeierstrassCurve ℚ :=
  { a₁ := 0, a₂ := ((b ^ p - a ^ p : ℤ) : ℚ), a₃ := 0, a₄ := ((-(a ^ p * b ^ p) : ℤ) : ℚ), a₆ := 0 }

/-- The Frey curve's discriminant. If whole numbers a, b, c satisfy a^p + b^p = c^p, the curve
y² = x(x − a^p)(x + b^p) over the rationals has roots 0, a^p and −b^p, whose gaps are a^p, b^p
and a^p + b^p = c^p, so its discriminant is 16 times the squared product of the gaps:
Δ = 16(a^p b^p c^p)² = 16(abc)^(2p). -/
theorem frey_curve_discriminant (a b c : ℤ) (p : ℕ) (h : a ^ p + b ^ p = c ^ p) :
    (freyCurve a b p).Δ = 16 * (((a * b * c : ℤ) : ℚ)) ^ (2 * p) := by
  have hc : ((c : ℚ)) ^ p = (a : ℚ) ^ p + (b : ℚ) ^ p := by exact_mod_cast h.symm
  rw [pow_mul', Int.cast_mul, Int.cast_mul, mul_pow, mul_pow, hc]
  simp only [freyCurve, WeierstrassCurve.Δ, WeierstrassCurve.b₂, WeierstrassCurve.b₄,
    WeierstrassCurve.b₆, WeierstrassCurve.b₈]
  push_cast
  ring

/-- The Frey curve is semistable away from 2 because only two roots ever meet. If a and b have
no common factor and a^p + b^p = c^p, then at every prime ℓ the three roots 0, a^p and −b^p of
the Frey curve are never all equal mod ℓ (all three meeting would make ℓ divide both a and b). -/
theorem frey_curve_roots_never_all_meet (a b c : ℤ) (p ℓ : ℕ) (hℓ : ℓ.Prime)
    (hab : IsCoprime a b) (h : a ^ p + b ^ p = c ^ p) :
    ¬ ((0 : ZMod ℓ) = ((a ^ p : ℤ) : ZMod ℓ) ∧ ((a ^ p : ℤ) : ZMod ℓ) = ((-(b ^ p) : ℤ) : ZMod ℓ)) := by
  rintro ⟨h0, h1⟩
  have hℓ' : Prime (ℓ : ℤ) := Nat.prime_iff_prime_int.mp hℓ
  have ha : (ℓ : ℤ) ∣ a ^ p := (ZMod.intCast_zmod_eq_zero_iff_dvd _ _).mp h0.symm
  have hb0 : ((-(b ^ p) : ℤ) : ZMod ℓ) = 0 := h1.symm.trans h0.symm
  have hb : (ℓ : ℤ) ∣ -(b ^ p) := (ZMod.intCast_zmod_eq_zero_iff_dvd _ _).mp hb0
  rw [dvd_neg] at hb
  exact hℓ'.not_isUnit (hab.isUnit_of_dvd' (hℓ'.dvd_of_dvd_pow ha) (hℓ'.dvd_of_dvd_pow hb))

/-- Prime exponents of 5 or more are all that is left. Euler settled the exponent 3 and Fermat
the exponent 4, and every n ≥ 3 has a factor 4 or an odd prime, so if a^p + b^p = c^p has no
solution in positive whole numbers for every prime p ≥ 5, then x^n + y^n = z^n has none for
every n ≥ 3: Fermat's last theorem. -/
theorem fermat_of_prime_exponents_at_least_five
    (h : ∀ p : ℕ, p.Prime → 5 ≤ p → FermatLastTheoremFor p) : FermatLastTheorem := by
  refine FermatLastTheorem.of_odd_primes (fun p hp hodd => ?_)
  rcases (show p = 3 ∨ 5 ≤ p by
    have h2 := hp.two_le
    have hne2 : p ≠ 2 := by rintro rfl; exact absurd hodd (by decide)
    have hne4 : p ≠ 4 := by rintro rfl; exact absurd hodd (by decide)
    omega) with rfl | h5
  · exact fermatLastTheoremThree
  · exact h p hp h5

-- The stand-in 3² + 4² = 5² with p = 2: A, B, C = 9, 16, 25 and the curve y² = x(x − 9)(x + 16).
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num
example : (9 : ℕ) * 16 * 25 = 3600 ∧ 3600 ^ 2 = 12960000 ∧ 16 * 12960000 = 207360000 := by norm_num
example : (16 : ℕ) * 60 ^ 4 = 207360000 := by norm_num
-- The discriminant read from the expanded curve x³ + 7x² − 144x by Mathlib's formula.
example : (freyCurve 3 4 2).Δ = 207360000 := by
  norm_num [freyCurve, WeierstrassCurve.Δ, WeierstrassCurve.b₂, WeierstrassCurve.b₄,
    WeierstrassCurve.b₆, WeierstrassCurve.b₈]
-- The exponents of 3 and 5 in the discriminant are 4 and 4, both multiples of 2p = 4.
example : 3 ^ 4 ∣ 207360000 ∧ ¬ 3 ^ 5 ∣ 207360000 ∧ 5 ^ 4 ∣ 207360000 ∧ ¬ 5 ^ 5 ∣ 207360000 := by
  decide
-- rad(60) = 2 × 3 × 5 = 30.
example : ((Finset.range 61).filter (fun q => q.Prime ∧ q ∣ 60)).prod id = 30 := by decide
-- The flipped curve after x = 4X, y = 8Y + 4X: discriminant 50,625 = 3⁴ × 5⁴, and 2¹² × 50,625 = 207,360,000.
example : (50625 : ℕ) = 3 ^ 4 * 5 ^ 4 ∧ 50625 * 2 ^ 12 = 207360000 := by norm_num
-- The house curve y² = x³ − x mod 5: 7 affine points, plus O makes 8, so a₅ = 5 + 1 − 8 = −2.
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - q.1)).card = 7 := by decide
example : (5 : ℤ) + 1 - 8 = -2 := by norm_num
-- No weight-2 cusp form at level 2: genus 1 + μ/12 − ν₂/4 − ν₃/3 − ν∞/2 with μ = 3, ν₂ = 1, ν₃ = 0, ν∞ = 2.
example : (1 : ℚ) + 3 / 12 - 1 / 4 - 0 / 3 - 2 / 2 = 0 := by norm_num
-- What breaks: 9² + 12² = 15² gives y² = x(x − 81)(x + 144), whose discriminant is 3¹² times the 3, 4, 5 one.
example : (freyCurve 9 12 2).Δ = 3 ^ 12 * 207360000 := by
  norm_num [freyCurve, WeierstrassCurve.Δ, WeierstrassCurve.b₂, WeierstrassCurve.b₄,
    WeierstrassCurve.b₆, WeierstrassCurve.b₈]

#print axioms frey_curve_discriminant
#print axioms frey_curve_roots_never_all_meet
#print axioms fermat_of_prime_exponents_at_least_five
