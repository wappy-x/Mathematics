-- Elliptic curves: the chord-and-tangent rule, with an extra point O as zero, adds points of y² = x³ + ax + b (no cusp or self-crossing) so that the sum stays on the curve and the laws of ordinary addition hold.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

/-! A point is `some (x, y)`, an ordinary point with coordinates x and y, or `none`, the extra
point O pictured infinitely far up and down every vertical line. The numbers can be fractions
(`ℚ`), remainders mod a prime (`ZMod 7`), or any other field: anywhere the four operations work. -/

open Polynomial

namespace EllipticCard

variable {F : Type*} [Field F]

/-- The point lies on the curve y² = x³ + ax + b. O counts as on every curve. -/
def OnCurve (a b : F) : Option (F × F) → Prop
  | none => True
  | some (x, y) => y ^ 2 = x ^ 3 + a * x + b

/-- The reflection in the x-axis: (x, y) goes to (x, −y), and O stays O. -/
def neg : Option (F × F) → Option (F × F)
  | none => none
  | some (x, y) => some (x, -y)

/-- The card's rule. O is the zero. Mirror images (same x, heights adding to 0) give O, the
vertical line. Otherwise take the slope m of the chord, or of the tangent when the two points
agree; then x₃ = m² − x₁ − x₂ and y₃ = m(x₁ − x₃) − y₁ (the third crossing, reflected). -/
def add [DecidableEq F] (a : F) : Option (F × F) → Option (F × F) → Option (F × F)
  | none, q => q
  | p, none => p
  | some (x₁, y₁), some (x₂, y₂) =>
      if x₁ = x₂ ∧ y₁ + y₂ = 0 then none
      else
        let m := if (x₁, y₁) = (x₂, y₂) then (3 * x₁ ^ 2 + a) / (2 * y₁)
                 else (y₂ - y₁) / (x₂ - x₁)
        let x₃ := m ^ 2 - x₁ - x₂
        some (x₃, m * (x₁ - x₃) - y₁)

/-- The card's curve y² = x³ + ax + b as a Weierstrass curve in Mathlib. -/
def curve (a b : F) : WeierstrassCurve.Affine F :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := a, a₆ := b }

lemma curve_equation_iff (a b x y : F) :
    (curve a b).Equation x y ↔ y ^ 2 = x ^ 3 + a * x + b := by
  rw [WeierstrassCurve.Affine.equation_iff]
  simp [curve]

lemma curve_nonsingular (h2 : (2 : F) ≠ 0) {a b : F} (hdisc : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0)
    {x y : F} (h : y ^ 2 = x ^ 3 + a * x + b) : (curve a b).Nonsingular x y := by
  rw [WeierstrassCurve.Affine.nonsingular_iff, curve_equation_iff]
  refine ⟨h, ?_⟩
  by_contra hc
  push Not at hc
  obtain ⟨e1, e2⟩ := hc
  simp only [curve] at e1 e2
  have hy : y = 0 := by
    have : 2 * y = 0 := by linear_combination e2
    simpa [h2] using this
  subst hy
  have ea : a + 3 * x ^ 2 = 0 := by linear_combination -e1
  have eb : b - 2 * x ^ 3 = 0 := by linear_combination -h - x * ea
  apply hdisc
  linear_combination 4 * (a ^ 2 - 3 * a * x ^ 2 + 9 * x ^ 4) * ea + 27 * (b + 2 * x ^ 3) * eb

open Classical in
/-- Send a point of the card to the matching point of Mathlib's curve. -/
noncomputable def toPt (a b : F) : Option (F × F) → (curve a b).Point
  | none => 0
  | some (x, y) => if h : (curve a b).Nonsingular x y then .some x y h else 0

lemma toPt_none (a b : F) : toPt a b none = 0 := rfl

lemma toPt_some {a b x y : F} (h : (curve a b).Nonsingular x y) :
    toPt a b (some (x, y)) = .some x y h := by
  simp [toPt, h]

lemma toPt_inj (h2 : (2 : F) ≠ 0) {a b : F} (hdisc : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0)
    {P Q : Option (F × F)} (hP : OnCurve a b P) (hQ : OnCurve a b Q)
    (h : toPt a b P = toPt a b Q) : P = Q := by
  rcases P with _ | ⟨x₁, y₁⟩ <;> rcases Q with _ | ⟨x₂, y₂⟩
  · rfl
  · rw [toPt_none, toPt_some (curve_nonsingular h2 hdisc hQ)] at h
    exact absurd h.symm (WeierstrassCurve.Affine.Point.some_ne_zero _)
  · rw [toPt_none, toPt_some (curve_nonsingular h2 hdisc hP)] at h
    exact absurd h (WeierstrassCurve.Affine.Point.some_ne_zero _)
  · rw [toPt_some (curve_nonsingular h2 hdisc hP), toPt_some (curve_nonsingular h2 hdisc hQ)] at h
    simp only [WeierstrassCurve.Affine.Point.some.injEq] at h
    rw [h.1, h.2]

lemma add_some_some [DecidableEq F] (h2 : (2 : F) ≠ 0) {a b : F}
    (hdisc : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0) {x₁ y₁ x₂ y₂ : F}
    (hP : y₁ ^ 2 = x₁ ^ 3 + a * x₁ + b) (hQ : y₂ ^ 2 = x₂ ^ 3 + a * x₂ + b) :
    OnCurve a b (add a (some (x₁, y₁)) (some (x₂, y₂))) ∧
      toPt a b (add a (some (x₁, y₁)) (some (x₂, y₂))) =
        toPt a b (some (x₁, y₁)) + toPt a b (some (x₂, y₂)) := by
  have h₁ := curve_nonsingular h2 hdisc hP
  have h₂ := curve_nonsingular h2 hdisc hQ
  rw [toPt_some h₁, toPt_some h₂]
  by_cases hxy : x₁ = x₂ ∧ y₁ + y₂ = 0
  · have hadd : add a (some (x₁, y₁)) (some (x₂, y₂)) = none := by simp [add, hxy]
    rw [hadd, toPt_none, WeierstrassCurve.Affine.Point.add_of_Y_eq hxy.1
      (by simp [curve]; linear_combination hxy.2)]
    exact ⟨trivial, rfl⟩
  · have hxy' : ¬(x₁ = x₂ ∧ y₁ = (curve a b).negY x₂ y₂) := by
      rintro ⟨hx, hy⟩
      exact hxy ⟨hx, by simp [curve] at hy; linear_combination hy⟩
    have hm : (if (x₁, y₁) = (x₂, y₂) then (3 * x₁ ^ 2 + a) / (2 * y₁)
        else (y₂ - y₁) / (x₂ - x₁)) = (curve a b).slope x₁ x₂ y₁ y₂ := by
      by_cases hx : x₁ = x₂
      · subst hx
        have hy : y₁ = y₂ := by
          have hne : y₁ + y₂ ≠ 0 := fun h => hxy ⟨rfl, h⟩
          have : (y₁ - y₂) * (y₁ + y₂) = 0 := by linear_combination hP - hQ
          have := (mul_eq_zero.1 this).resolve_right hne
          linear_combination this
        subst hy
        have hy' : y₁ ≠ (curve a b).negY x₁ y₁ := fun h => hxy' ⟨rfl, h⟩
        simp only [↓reduceIte]
        rw [WeierstrassCurve.Affine.slope_of_Y_ne rfl hy']
        simp only [curve, WeierstrassCurve.Affine.negY]
        congr 1 <;> ring
      · have hne : (x₁, y₁) ≠ (x₂, y₂) := fun h => hx (Prod.ext_iff.1 h).1
        simp only [hne, ↓reduceIte]
        rw [WeierstrassCurve.Affine.slope_of_X_ne hx, ← neg_sub x₁, ← neg_sub y₁,
          neg_div_neg_eq]
    have hadd : add a (some (x₁, y₁)) (some (x₂, y₂)) =
        some ((curve a b).addX x₁ x₂ ((curve a b).slope x₁ x₂ y₁ y₂),
          (curve a b).addY x₁ x₂ y₁ ((curve a b).slope x₁ x₂ y₁ y₂)) := by
      simp only [add, hxy, ↓reduceIte]
      rw [hm]
      simp only [WeierstrassCurve.Affine.addY, WeierstrassCurve.Affine.negAddY,
        WeierstrassCurve.Affine.negY, WeierstrassCurve.Affine.addX, curve]
      congr 2 <;> ring
    rw [WeierstrassCurve.Affine.Point.add_some hxy', hadd,
      toPt_some (WeierstrassCurve.Affine.nonsingular_add h₁ h₂ hxy')]
    exact ⟨(curve_equation_iff _ _ _ _).1 (WeierstrassCurve.Affine.nonsingular_add h₁ h₂ hxy').1,
      rfl⟩

lemma add_hom [DecidableEq F] (h2 : (2 : F) ≠ 0) {a b : F}
    (hdisc : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0) {P Q : Option (F × F)}
    (hP : OnCurve a b P) (hQ : OnCurve a b Q) :
    OnCurve a b (add a P Q) ∧ toPt a b (add a P Q) = toPt a b P + toPt a b Q := by
  rcases P with _ | ⟨x₁, y₁⟩ <;> rcases Q with _ | ⟨x₂, y₂⟩
  · exact ⟨trivial, by simp [add, toPt_none]⟩
  · exact ⟨hQ, by rw [toPt_none, zero_add]; rfl⟩
  · exact ⟨hP, by rw [toPt_none, add_zero]; rfl⟩
  · exact add_some_some h2 hdisc hP hQ

/-- Chord, third crossing, reflection adds any two points of an elliptic curve and lands on the
curve, and with O as zero it obeys the laws of ordinary addition. Precisely: when division works
and the remainders are not mod 2 or mod 3, and 4a³ + 27b² is not zero (no cusp or
self-crossing), then for any points P, Q, W on the curve y² = x³ + ax + b: P + Q is on the
curve, P + O = P, P plus its mirror image is O, P + Q = Q + P, and
(P + Q) + W = P + (Q + W). -/
theorem chord_tangent_addition_is_a_group [DecidableEq F] (h2 : (2 : F) ≠ 0) (h3 : (3 : F) ≠ 0)
    (a b : F) (hdisc : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0) (P Q W : Option (F × F))
    (hP : OnCurve a b P) (hQ : OnCurve a b Q) (hW : OnCurve a b W) :
    OnCurve a b (add a P Q) ∧
      add a P none = P ∧
      add a P (neg P) = none ∧
      add a P Q = add a Q P ∧
      add a (add a P Q) W = add a P (add a Q W) := by
  obtain ⟨hPQ, ePQ⟩ := add_hom h2 hdisc hP hQ
  refine ⟨hPQ, ?_, ?_, ?_, ?_⟩
  · rcases P with _ | ⟨x, y⟩ <;> rfl
  · rcases P with _ | ⟨x, y⟩
    · rfl
    · simp [add, neg]
  · obtain ⟨hQP, eQP⟩ := add_hom h2 hdisc hQ hP
    exact toPt_inj h2 hdisc hPQ hQP (by rw [ePQ, eQP, add_comm])
  · obtain ⟨hQW, eQW⟩ := add_hom h2 hdisc hQ hW
    obtain ⟨h1, e1⟩ := add_hom h2 hdisc hPQ hW
    obtain ⟨h2', e2⟩ := add_hom h2 hdisc hP hQW
    exact toPt_inj h2 hdisc h1 h2' (by rw [e1, e2, ePQ, eQW, add_assoc])

/-- Step 1, the third crossing from the sum of the roots: if the line y = mx + k meets the curve
y² = x³ + ax + b at two points with different x-coordinates x₁ and x₂, then putting the line
into the curve gives the cubic x³ + ax + b − (mx + k)², and it factors as
(x − x₁)(x − x₂)(x − x₃) with x₃ = m² − x₁ − x₂. So the three crossings add up to m². -/
theorem third_crossing_from_sum_of_roots (a b m k x₁ x₂ : F) (hx : x₁ ≠ x₂)
    (h₁ : (m * x₁ + k) ^ 2 = x₁ ^ 3 + a * x₁ + b)
    (h₂ : (m * x₂ + k) ^ 2 = x₂ ^ 3 + a * x₂ + b) :
    X ^ 3 + C a * X + C b - (C m * X + C k) ^ 2 =
      (X - C x₁) * (X - C x₂) * (X - C (m ^ 2 - x₁ - x₂)) := by
  have e1 : a - 2 * m * k = m ^ 2 * (x₁ + x₂) - x₁ ^ 2 - x₁ * x₂ - x₂ ^ 2 := by
    apply mul_left_cancel₀ (sub_ne_zero.2 hx)
    linear_combination h₂ - h₁
  have ha : a = 2 * m * k + m ^ 2 * (x₁ + x₂) - x₁ ^ 2 - x₁ * x₂ - x₂ ^ 2 := by
    linear_combination e1
  subst ha
  have hb : b = (m * x₁ + k) ^ 2 - x₁ ^ 3 -
      (2 * m * k + m ^ 2 * (x₁ + x₂) - x₁ ^ 2 - x₁ * x₂ - x₂ ^ 2) * x₁ := by
    linear_combination -h₁
  subst hb
  simp only [map_add, map_sub, map_mul, map_pow, map_ofNat]
  ring

/-- Step 2, the tangent slope without calculus: for a point (x₁, y₁) on the curve, the line of
slope m through it touches the curve there (x₁ is a crossing twice over, so the cubic factors
as (x − x₁)²(x − x₃) with x₃ = m² − 2x₁) exactly when 2y₁m = 3x₁² + a. -/
theorem tangent_slope_touches_twice (a b m x₁ y₁ : F)
    (hP : y₁ ^ 2 = x₁ ^ 3 + a * x₁ + b) :
    X ^ 3 + C a * X + C b - (C m * (X - C x₁) + C y₁) ^ 2 =
        (X - C x₁) ^ 2 * (X - C (m ^ 2 - 2 * x₁)) ↔
      2 * y₁ * m = 3 * x₁ ^ 2 + a := by
  constructor
  · intro H
    have h := congrArg (eval (x₁ + 1)) H
    simp only [eval_sub, eval_add, eval_mul, eval_pow, eval_X, eval_C] at h
    linear_combination -h - hP
  · intro h
    have ha : a = 2 * y₁ * m - 3 * x₁ ^ 2 := by linear_combination -h
    subst ha
    have hb : b = y₁ ^ 2 - x₁ ^ 3 - (2 * y₁ * m - 3 * x₁ ^ 2) * x₁ := by linear_combination -hP
    subst hb
    simp only [map_sub, map_mul, map_pow, map_ofNat]
    ring

-- The card's curve y² = x³ − x + 1, so a = −1 and b = 1: 4a³ + 27b² is 23, not zero.
example : 4 * (-1 : ℚ) ^ 3 + 27 * 1 ^ 2 = 23 := by norm_num
-- P = (0, 1) and Q = (1, 1) are on it; adding coordinates gives (1, 2), which is off it.
example : OnCurve (-1 : ℚ) 1 (some (0, 1)) ∧ OnCurve (-1 : ℚ) 1 (some (1, 1)) := by
  norm_num [OnCurve]
example : ¬ OnCurve (-1 : ℚ) 1 (some (1, 2)) := by norm_num [OnCurve]
-- P + Q = (−1, −1): chord slope 0, third crossing R = (−1, 1), reflected.
example : add (-1 : ℚ) (some (0, 1)) (some (1, 1)) = some (-1, -1) := by norm_num [add]
example : OnCurve (-1 : ℚ) 1 (some (-1, 1)) := by norm_num [OnCurve]
-- Q + Q = (−1, 1): tangent slope (3 − 1) ÷ 2 = 1.
example : add (-1 : ℚ) (some (1, 1)) (some (1, 1)) = some (-1, 1) := by norm_num [add]
-- P + P = (1/4, −7/8): tangent slope −1/2; both sides of the curve's equation are 49/64.
example : add (-1 : ℚ) (some (0, 1)) (some (0, 1)) = some (1 / 4, -7 / 8) := by norm_num [add]
example : (-7 / 8 : ℚ) ^ 2 = 49 / 64 ∧ (1 / 4 : ℚ) ^ 3 - 1 / 4 + 1 = 49 / 64 := by norm_num
-- Adding Q again and again: 3Q = (0, −1), 4Q = (3, −5), 5Q = (5, 11), 6Q = (1/4, 7/8).
example : add (-1 : ℚ) (some (-1, 1)) (some (1, 1)) = some (0, -1) := by norm_num [add]
example : add (-1 : ℚ) (some (0, -1)) (some (1, 1)) = some (3, -5) := by norm_num [add]
example : add (-1 : ℚ) (some (3, -5)) (some (1, 1)) = some (5, 11) := by norm_num [add]
example : add (-1 : ℚ) (some (5, 11)) (some (1, 1)) = some (1 / 4, 7 / 8) := by norm_num [add]
-- 6Q is the mirror image of P + P.
example : neg (some (1 / 4, -7 / 8) : Option (ℚ × ℚ)) = some (1 / 4, 7 / 8) := by norm_num [neg]
-- 7Q = (−11/9, −17/27), 8Q = (19/25, −103/125), 9Q = (56, −419).
example : add (-1 : ℚ) (some (1 / 4, 7 / 8)) (some (1, 1)) = some (-11 / 9, -17 / 27) := by
  norm_num [add]
example : add (-1 : ℚ) (some (-11 / 9, -17 / 27)) (some (1, 1)) = some (19 / 25, -103 / 125) := by
  norm_num [add]
example : add (-1 : ℚ) (some (19 / 25, -103 / 125)) (some (1, 1)) = some (56, -419) := by
  norm_num [add]
-- The usual mistake: dropping a from the tangent slope gives slope 3/2 and (1/4, 1/8), off the curve.
example : ¬ OnCurve (-1 : ℚ) 1 (some (1 / 4, 1 / 8)) := by norm_num [OnCurve]
-- Mod 7: 4a³ + 27b² leaves remainder 2, and y² = x³ − x + 1 has 11 ordinary points, 12 with O.
example : 4 * (-1 : ZMod 7) ^ 3 + 27 * 1 ^ 2 = 2 := by decide
example : (Finset.univ.filter
    (fun p : ZMod 7 × ZMod 7 => p.2 ^ 2 = p.1 ^ 3 - p.1 + 1)).card = 11 := by decide

end EllipticCard

open EllipticCard

#print axioms chord_tangent_addition_is_a_group
#print axioms third_crossing_from_sum_of_roots
#print axioms tangent_slope_touches_twice
#print axioms curve_equation_iff
#print axioms curve_nonsingular
#print axioms toPt_none
#print axioms toPt_some
#print axioms toPt_inj
#print axioms add_some_some
#print axioms add_hom
