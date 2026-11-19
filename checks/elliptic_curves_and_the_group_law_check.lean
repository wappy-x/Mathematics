-- The group law: on a smooth curve y² = x³ + ax + b, with the point at infinity O = (0 : 1 : 0) as zero, three points on one line (counted with multiplicity) add up to zero, the addition obeys every group law, and doubling (3, 5) on y² = x³ − 2 gives (129/100, −383/1000).
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.AlgebraicGeometry.EllipticCurve.Projective.Basic
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-! The curve E is `y² = x³ + ax + b` over a field F. Mathlib's `Point` type is E with the
point at infinity added: `0` is O, and `.some x y h` is the ordinary point (x, y), where `h`
says it lies on the curve with a single tangent there. Mathlib adds points by the chord and
tangent formulas. In homogeneous coordinates (X : Y : Z) the curve is Y²Z = X³ + aXZ² + bZ³. -/

open Polynomial

namespace GroupLawCard

variable {F : Type*} [Field F]

/-- The card's curve y² = x³ + ax + b as a Weierstrass curve in Mathlib
(a₁ = a₂ = a₃ = 0, a₄ = a, a₆ = b). -/
def curve (a b : F) : WeierstrassCurve F :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := a, a₆ := b }

open WeierstrassCurve WeierstrassCurve.Affine in
lemma curve_Δ (a b : F) : (curve a b).Δ = -16 * (4 * a ^ 3 + 27 * b ^ 2) := by
  simp only [WeierstrassCurve.Δ, WeierstrassCurve.b₂, WeierstrassCurve.b₄, WeierstrassCurve.b₆,
    WeierstrassCurve.b₈, curve]
  ring

open WeierstrassCurve WeierstrassCurve.Affine in
lemma curve_nonsingular {a b : F} (h2 : (2 : F) ≠ 0) (hdisc : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0)
    {x y : F} (h : y ^ 2 = x ^ 3 + a * x + b) : (curve a b).toAffine.Nonsingular x y := by
  have hΔ : (curve a b).Δ ≠ 0 := by
    rw [curve_Δ]
    refine mul_ne_zero ?_ hdisc
    have : (16 : F) = 2 ^ 4 := by norm_num
    rw [neg_ne_zero, this]
    exact pow_ne_zero _ h2
  refine (equation_iff_nonsingular_of_Δ_ne_zero hΔ).mp ?_
  rw [Affine.equation_iff]
  simp only [curve]
  linear_combination h

lemma some_congr {W : WeierstrassCurve.Affine F} {x y x' y' : F} {h : W.Nonsingular x y}
    {h' : W.Nonsingular x' y'} (hx : x = x') (hy : y = y') :
    WeierstrassCurve.Affine.Point.some x y h = .some x' y' h' := by
  subst hx hy
  rfl

/-- Three points on a line add up to zero, and this gives a group. Take a field in which 2 and 3
can be divided by, and a curve y² = x³ + ax + b with 4a³ + 27b² not zero (smooth: no cusp, no
self-crossing). Then:
* any line y = mx + k that meets the curve at x₁, x₂, x₃, counted with multiplicity (putting
  the line into the curve gives the cubic (x − x₁)(x − x₂)(x − x₃)), meets it in three points of
  E, and these three points add up to O; a tangent counts its point twice;
* a vertical line holds (x, y), (x, −y) and O, and these add up to O as well;
* the addition is associative for every triple of points, coincident ones included, is
  commutative, and has O as its zero. -/
theorem three_on_a_line_add_to_zero [DecidableEq F] (h2 : (2 : F) ≠ 0) (h3 : (3 : F) ≠ 0)
    (a b : F) (hdisc : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0) :
    (∀ m k x₁ x₂ x₃ : F,
      X ^ 3 + C a * X + C b - (C m * X + C k) ^ 2 =
        (X - C x₁) * (X - C x₂) * (X - C x₃) →
      ∃ (h₁ : (curve a b).toAffine.Nonsingular x₁ (m * x₁ + k))
        (h₂ : (curve a b).toAffine.Nonsingular x₂ (m * x₂ + k))
        (h₃ : (curve a b).toAffine.Nonsingular x₃ (m * x₃ + k)),
        WeierstrassCurve.Affine.Point.some _ _ h₁ + .some _ _ h₂ + .some _ _ h₃ = 0) ∧
    (∀ (x y : F) (h : (curve a b).toAffine.Nonsingular x y),
      ∃ h' : (curve a b).toAffine.Nonsingular x (-y),
        WeierstrassCurve.Affine.Point.some _ _ h + .some _ _ h' + 0 = 0) ∧
    (∀ P Q W : (curve a b).toAffine.Point, (P + Q) + W = P + (Q + W)) ∧
    (∀ P Q : (curve a b).toAffine.Point, P + Q = Q + P) ∧
    (∀ P : (curve a b).toAffine.Point, P + 0 = P) := by
  classical
  have ns : ∀ x y : F, y ^ 2 = x ^ 3 + a * x + b → (curve a b).toAffine.Nonsingular x y :=
    fun x y h => curve_nonsingular h2 hdisc h
  refine ⟨?_, ?_, add_assoc, add_comm, add_zero⟩
  · intro m k x₁ x₂ x₃ hpoly
    have hpt : ∀ t : F, t ^ 3 + a * t + b - (m * t + k) ^ 2 = (t - x₁) * (t - x₂) * (t - x₃) := by
      intro t
      simpa using congrArg (Polynomial.eval t) hpoly
    have c0 := hpt 0
    have c1 := hpt 1
    have cm := hpt (-1)
    have e1 : x₁ + x₂ + x₃ = m ^ 2 := by
      have : (2 : F) * (x₁ + x₂ + x₃ - m ^ 2) = 0 := by linear_combination c1 + cm - 2 * c0
      rcases mul_eq_zero.mp this with h | h
      · exact absurd h h2
      · linear_combination h
    have e2 : x₁ * x₂ + x₁ * x₃ + x₂ * x₃ = a - 2 * m * k := by
      have : (2 : F) * (x₁ * x₂ + x₁ * x₃ + x₂ * x₃ - (a - 2 * m * k)) = 0 := by
        linear_combination -(c1 - cm)
      rcases mul_eq_zero.mp this with h | h
      · exact absurd h h2
      · linear_combination h
    have on : ∀ t : F, (t - x₁) * (t - x₂) * (t - x₃) = 0 →
        (curve a b).toAffine.Nonsingular t (m * t + k) := fun t ht =>
      ns _ _ (by linear_combination -(hpt t) - ht)
    refine ⟨on x₁ (by ring), on x₂ (by ring), on x₃ (by ring), ?_⟩
    rw [show WeierstrassCurve.Affine.Point.some _ _ (on x₁ (by ring)) +
        WeierstrassCurve.Affine.Point.some _ _ (on x₂ (by ring)) =
        -WeierstrassCurve.Affine.Point.some _ _ (on x₃ (by ring)) from ?_, neg_add_cancel]
    by_cases hx : x₁ = x₂
    · subst hx
      by_cases hy : m * x₁ + k = (curve a b).toAffine.negY x₁ (m * x₁ + k)
      · exfalso
        have hy0 : m * x₁ + k = 0 := by
          have : (2 : F) * (m * x₁ + k) = 0 := by
            simp only [WeierstrassCurve.Affine.negY, curve] at hy
            linear_combination hy
          rcases mul_eq_zero.mp this with h | h
          · exact absurd h h2
          · exact h
        have htan : 3 * x₁ ^ 2 + a = 0 := by
          linear_combination -e2 + 2 * x₁ * e1 + 2 * m * hy0
        rcases ((WeierstrassCurve.Affine.nonsingular_iff _ _).mp (on x₁ (by ring))).2 with h | h
        · simp only [curve] at h
          exact h (by linear_combination -htan)
        · exact h hy
      · have hsl : (curve a b).toAffine.slope x₁ x₁ (m * x₁ + k) (m * x₁ + k) = m := by
          rw [WeierstrassCurve.Affine.slope_of_Y_ne rfl hy, div_eq_iff (sub_ne_zero.mpr hy)]
          simp only [WeierstrassCurve.Affine.negY, curve]
          linear_combination -e2 + 2 * x₁ * e1
        rw [WeierstrassCurve.Affine.Point.add_of_Y_ne hy, WeierstrassCurve.Affine.Point.neg_some]
        apply some_congr
        · rw [hsl]; simp only [WeierstrassCurve.Affine.addX, curve]; linear_combination -e1
        · rw [hsl]
          simp only [WeierstrassCurve.Affine.addY, WeierstrassCurve.Affine.negAddY,
            WeierstrassCurve.Affine.addX, WeierstrassCurve.Affine.negY, curve]
          linear_combination m * e1
    · have hsl : (curve a b).toAffine.slope x₁ x₂ (m * x₁ + k) (m * x₂ + k) = m := by
        rw [WeierstrassCurve.Affine.slope_of_X_ne hx, div_eq_iff (sub_ne_zero.mpr hx)]
        ring
      rw [WeierstrassCurve.Affine.Point.add_of_X_ne hx, WeierstrassCurve.Affine.Point.neg_some]
      apply some_congr
      · rw [hsl]; simp only [WeierstrassCurve.Affine.addX, curve]; linear_combination -e1
      · rw [hsl]
        simp only [WeierstrassCurve.Affine.addY, WeierstrassCurve.Affine.negAddY,
          WeierstrassCurve.Affine.addX, WeierstrassCurve.Affine.negY, curve]
        linear_combination m * e1
  · intro x y h
    have hn : (curve a b).toAffine.negY x y = -y := by
      simp [WeierstrassCurve.Affine.negY, curve]
    refine ⟨hn ▸ (WeierstrassCurve.Affine.nonsingular_neg x y).mpr h, ?_⟩
    rw [add_zero]
    exact WeierstrassCurve.Affine.Point.add_of_Y_eq rfl (by simp [curve])

/-- The point at infinity is (0 : 1 : 0), and it is a smooth flex. In homogeneous coordinates the
curve is Y²Z = X³ + aXZ² + bZ³. On the line at infinity Z = 0 this leaves X³ = 0, so the only
point there is (0 : 1 : 0): every point of the curve with Z = 0 is a nonzero multiple of
(0, 1, 0). Along that line the equation is −X³, a triple root at O, so the line at infinity
meets the curve three times at O (O is a flex). And O is a smooth point of the curve. -/
theorem point_at_infinity_is_a_smooth_flex (a b : F) :
    (∀ P : Fin 3 → F, P ≠ 0 → P 2 = 0 → (curve a b).toProjective.Equation P →
      ∃ u : F, u ≠ 0 ∧ P = u • ![0, 1, 0]) ∧
    (curve a b).toProjective.Equation ![0, 1, 0] ∧
    (∀ X : F, MvPolynomial.eval ![X, 1, 0] (curve a b).toProjective.polynomial = -X ^ 3) ∧
    (curve a b).toProjective.Nonsingular ![0, 1, 0] := by
  refine ⟨?_, WeierstrassCurve.Projective.equation_zero, ?_,
    WeierstrassCurve.Projective.nonsingular_zero⟩
  · intro P hP hz hE
    have h0 : P 0 = 0 :=
      WeierstrassCurve.Projective.X_eq_zero_of_Z_eq_zero hE hz
    have h1 : P 1 ≠ 0 := by
      intro h1
      apply hP
      funext i
      fin_cases i <;> simp [h0, h1, hz]
    refine ⟨P 1, h1, ?_⟩
    funext i
    fin_cases i <;> simp [h0, hz]
  · intro X
    rw [WeierstrassCurve.Projective.eval_polynomial]
    simp [curve]

/-- Doubling (3, 5) on y² = x³ − 2 over the rationals. Both (3, 5) and (129/100, −383/1000)
are points of the curve, and twice (3, 5) in the group is (129/100, −383/1000). -/
theorem double_three_five :
    ∃ (hP : (curve (0 : ℚ) (-2)).toAffine.Nonsingular 3 5)
      (hD : (curve (0 : ℚ) (-2)).toAffine.Nonsingular (129 / 100) (-383 / 1000)),
      2 • WeierstrassCurve.Affine.Point.some _ _ hP = .some _ _ hD := by
  have hP : (curve (0 : ℚ) (-2)).toAffine.Nonsingular 3 5 :=
    curve_nonsingular (by norm_num) (by norm_num) (by norm_num)
  have hD : (curve (0 : ℚ) (-2)).toAffine.Nonsingular (129 / 100) (-383 / 1000) :=
    curve_nonsingular (by norm_num) (by norm_num) (by norm_num)
  refine ⟨hP, hD, ?_⟩
  have hy : (5 : ℚ) ≠ (curve (0 : ℚ) (-2)).toAffine.negY 3 5 := by
    simp [curve]; norm_num
  rw [two_nsmul, WeierstrassCurve.Affine.Point.add_self_of_Y_ne hy]
  have hsl : (curve (0 : ℚ) (-2)).toAffine.slope 3 3 5 5 = 27 / 10 := by
    rw [WeierstrassCurve.Affine.slope_of_Y_ne rfl hy]
    simp [curve]; norm_num
  apply some_congr
  · rw [hsl]; simp [curve]; norm_num
  · rw [hsl]
    simp [WeierstrassCurve.Affine.addY, curve]; norm_num

end GroupLawCard

-- P = (3, 5) is on y² = x³ − 2: both sides are 25.
example : (5 : ℤ) ^ 2 = 3 ^ 3 - 2 := by norm_num
-- 4a³ + 27b² = 108 for a = 0, b = −2: not zero, so the curve is smooth.
example : 4 * (0 : ℤ) ^ 3 + 27 * (-2) ^ 2 = 108 := by norm_num
-- The tangent at P: slope 3·3²/(2·5) = 27/10, height at x = 0 is 5 − (27/10)·3 = −31/10.
example : (3 * 3 ^ 2 : ℚ) / (2 * 5) = 27 / 10 := by norm_num
example : (5 : ℚ) - 27 / 10 * 3 = -31 / 10 := by norm_num
-- The sum of the three roots is m² = 729/100, so the third root is 729/100 − 3 − 3 = 129/100.
example : (27 / 10 : ℚ) ^ 2 = 729 / 100 := by norm_num
example : (729 / 100 : ℚ) - 3 - 3 = 129 / 100 := by norm_num
-- R's height on the tangent: (27/10)(129/100) − 31/10 = 383/1000.
example : (27 / 10 : ℚ) * (129 / 100) - 31 / 10 = 383 / 1000 := by norm_num
-- Long division: x³ − (27/10 x − 31/10)² − 2 = (x − 3)² (x − 129/100), remainder 0.
example (x : ℚ) : x ^ 3 - (27 / 10 * x - 31 / 10) ^ 2 - 2 = (x - 3) ^ 2 * (x - 129 / 100) := by
  ring
-- 2P = (129/100, −383/1000) is on the curve: both sides are 146689/1000000.
example : (-383 / 1000 : ℚ) ^ 2 = 146689 / 1000000 := by norm_num
example : (129 / 100 : ℚ) ^ 3 - 2 = 146689 / 1000000 := by norm_num
-- 3P and 4P are on the curve.
example : (-66234835 / 5000211 : ℚ) ^ 2 = (164323 / 29241) ^ 3 - 2 := by norm_num
example : (113259286337279 / 449455096000 : ℚ) ^ 2 = (2340922881 / 58675600) ^ 3 - 2 := by
  norm_num
-- Mod 11 the curve has 11 ordinary points, 12 with O.
example : (Finset.univ.filter
    (fun p : ZMod 11 × ZMod 11 => p.2 ^ 2 = p.1 ^ 3 - 2)).card = 11 := by decide
-- What breaks: the cusp y² = x³ has 4a³ + 27b² = 0; and O is not the origin, since
-- (0, 0) is not on y² = x³ − 2.
example : 4 * (0 : ℤ) ^ 3 + 27 * 0 ^ 2 = 0 := by norm_num
example : (0 : ℤ) ^ 2 ≠ 0 ^ 3 - 2 := by norm_num

open GroupLawCard

#print axioms curve_Δ
#print axioms curve_nonsingular
#print axioms some_congr
#print axioms three_on_a_line_add_to_zero
#print axioms point_at_infinity_is_a_smooth_flex
#print axioms double_three_five
