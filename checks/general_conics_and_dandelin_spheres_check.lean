-- Every conic: turning the axes by any angle leaves B^2 - 4AC unchanged, the turn with cot 2θ = (A - C)/B removes the xy term, and all tangents from one point to a sphere have the same length.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic

open Real

/-- B^2 - 4AC never changes under a turn. Turn the axes by any angle θ, so the old position
(x, y) is x = X cos θ - Y sin θ, y = X sin θ + Y cos θ in the new position (X, Y) (axes square,
equal units). If Ax^2 + Bxy + Cy^2 becomes A'X^2 + B'XY + C'Y^2 for every point (B and B' the
whole cross terms), then B'^2 - 4A'C' = B^2 - 4AC. -/
theorem discriminant_unchanged_by_turning_axes (A B C θ A' B' C' : ℝ)
    (h : ∀ X Y : ℝ,
      A * (X * cos θ - Y * sin θ) ^ 2
        + B * (X * cos θ - Y * sin θ) * (X * sin θ + Y * cos θ)
        + C * (X * sin θ + Y * cos θ) ^ 2
      = A' * X ^ 2 + B' * X * Y + C' * Y ^ 2) :
    B' ^ 2 - 4 * A' * C' = B ^ 2 - 4 * A * C := by
  have h10 := h 1 0
  have h01 := h 0 1
  have h11 := h 1 1
  simp only [one_mul, zero_mul, sub_zero, zero_sub, add_zero, zero_add, mul_one, one_pow,
    ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero] at h10 h01 h11
  have hA : A' = A * cos θ ^ 2 + B * cos θ * sin θ + C * sin θ ^ 2 := by linarith
  have hC : C' = A * sin θ ^ 2 - B * sin θ * cos θ + C * cos θ ^ 2 := by
    have : A' * 0 ^ 2 + B' * 0 * 1 + C' * 1 ^ 2 = C' := by ring
    nlinarith
  have hB' : B' = -2 * A * cos θ * sin θ + B * (cos θ ^ 2 - sin θ ^ 2)
      + 2 * C * cos θ * sin θ := by
    linear_combination h10 + h01 - h11
  subst hA hC hB'
  linear_combination (B ^ 2 - 4 * A * C) * (sin θ ^ 2 + cos θ ^ 2 + 1) * (sin_sq_add_cos_sq θ)

/-- Turning by the angle with cot 2θ = (A - C)/B kills the xy term. When B ≠ 0 and θ is chosen
with cot 2θ = (A - C)/B (so cot 2θ is defined: sin 2θ ≠ 0), the turned equation has no XY term:
Ax^2 + Bxy + Cy^2 = A'X^2 + C'Y^2 with
A' = (A + C)/2 + ((A - C)/2) cos 2θ + (B/2) sin 2θ and
C' = (A + C)/2 - ((A - C)/2) cos 2θ - (B/2) sin 2θ. -/
theorem cot_two_theta_turn_removes_cross_term (A B C θ : ℝ) (hB : B ≠ 0)
    (hsin : sin (2 * θ) ≠ 0) (hcot : cot (2 * θ) = (A - C) / B) (X Y : ℝ) :
    A * (X * cos θ - Y * sin θ) ^ 2
        + B * (X * cos θ - Y * sin θ) * (X * sin θ + Y * cos θ)
        + C * (X * sin θ + Y * cos θ) ^ 2
      = ((A + C) / 2 + (A - C) / 2 * cos (2 * θ) + B / 2 * sin (2 * θ)) * X ^ 2
        + ((A + C) / 2 - (A - C) / 2 * cos (2 * θ) - B / 2 * sin (2 * θ)) * Y ^ 2 := by
  have key : B * cos (2 * θ) = (A - C) * sin (2 * θ) := by
    rw [Real.cot_eq_cos_div_sin, div_eq_div_iff hsin hB] at hcot
    linear_combination hcot
  rw [cos_two_mul, sin_two_mul] at key ⊢
  linear_combination (C * X ^ 2 + A * Y ^ 2 - B * X * Y) * (sin_sq_add_cos_sq θ) + X * Y * key

/-- Dandelin's key fact: from a point P, every tangent to a ball has the same length. If T₁ and
T₂ lie on the sphere with centre O and radius r, and each segment PTᵢ is square to the radius
OTᵢ (a tangent), then PT₁² = PO² - r² (Pythagoras) and PT₁ = PT₂. -/
theorem tangents_from_a_point_to_a_sphere_are_equal
    (O P T₁ T₂ : EuclideanSpace ℝ (Fin 3)) (r : ℝ)
    (h₁ : dist T₁ O = r) (h₂ : dist T₂ O = r)
    (ht₁ : inner ℝ (P - T₁) (T₁ - O) = 0) (ht₂ : inner ℝ (P - T₂) (T₂ - O) = 0) :
    dist P T₁ ^ 2 = dist P O ^ 2 - r ^ 2 ∧ dist P T₁ = dist P T₂ := by
  have key : ∀ T : EuclideanSpace ℝ (Fin 3), dist T O = r → inner ℝ (P - T) (T - O) = 0 →
      dist P T ^ 2 = dist P O ^ 2 - r ^ 2 := by
    intro T hT ht
    rw [← hT]
    simp only [dist_eq_norm]
    have e : P - O = (P - T) + (T - O) := by abel
    rw [e, norm_add_sq_real, ht]
    ring
  refine ⟨key T₁ h₁ ht₁, ?_⟩
  have e : dist P T₁ ^ 2 = dist P T₂ ^ 2 := by rw [key T₁ h₁ ht₁, key T₂ h₂ ht₂]
  nlinarith [dist_nonneg (x := P) (y := T₁), dist_nonneg (x := P) (y := T₂)]

-- The bed x^2 + xy + y^2 = 3: A = B = C = 1, so B^2 - 4AC = 1 - 4 = -3 < 0, an ellipse.
example : (1 : ℤ) ^ 2 - 4 * 1 * 1 = -3 := by decide
-- The 45-degree turn: cos 45° = sin 45° = 1/√2, so x = (X - Y)/√2, y = (X + Y)/√2, and
-- x^2 + xy + y^2 = ((X - Y)^2 + (X - Y)(X + Y) + (X + Y)^2)/2 = (3/2)X^2 + (1/2)Y^2.
example (X Y : ℝ) :
    ((X - Y) ^ 2 + (X - Y) * (X + Y) + (X + Y) ^ 2) / 2 = 3 / 2 * X ^ 2 + 1 / 2 * Y ^ 2 := by
  ring
-- Dividing (3/2)X^2 + (1/2)Y^2 = 3 by 3 gives X^2/2 + Y^2/6 = 1; then c^2 = 6 - 2 = 2^2.
example (X Y : ℝ) : 3 / 2 * X ^ 2 + 1 / 2 * Y ^ 2 = 3 ↔ X ^ 2 / 2 + Y ^ 2 / 6 = 1 := by
  constructor <;> intro h <;> linarith
example : (6 : ℤ) - 2 = 2 ^ 2 := by decide
-- After the turn B' = 0, and the unchanged number is 0^2 - 4(3/2)(1/2) = -3 again.
example : (0 : ℚ) ^ 2 - 4 * (3 / 2) * (1 / 2) = -3 := by norm_num
-- xy = 1: B^2 - 4AC = 1 > 0, a hyperbola; the 45-degree turn gives X^2/2 - Y^2/2.
example : (1 : ℤ) ^ 2 - 4 * 0 * 0 = 1 := by decide
example (X Y : ℝ) : (X - Y) * (X + Y) / 2 = X ^ 2 / 2 - Y ^ 2 / 2 := by ring
-- 2x^2 + 4xy + 5y^2 - 6: B^2 - 4AC = 16 - 40 = -24; the turn with cos θ = 1/√5, sin θ = 2/√5
-- (63.43°) gives 6X^2 + Y^2, and 0^2 - 4·6·1 = -24 again.
example : (4 : ℤ) ^ 2 - 4 * 2 * 5 = -24 ∧ (0 : ℤ) ^ 2 - 4 * 6 * 1 = -24 := by decide
example (X Y : ℝ) :
    (2 * (X - 2 * Y) ^ 2 + 4 * (X - 2 * Y) * (2 * X + Y) + 5 * (2 * X + Y) ^ 2) / 5
      = 6 * X ^ 2 + Y ^ 2 := by
  ring
-- x^2 + 2xy + y^2: B^2 - 4AC = 0 (parabola or parallel lines); x^2 - y^2: 4 (two crossing lines);
-- x^2 + xy + y^2 + 3: -3, yet no point fits it.
example : (2 : ℤ) ^ 2 - 4 * 1 * 1 = 0 ∧ (0 : ℤ) ^ 2 - 4 * 1 * (-1) = 4 := by decide
example (x y : ℝ) : x ^ 2 + x * y + y ^ 2 + 3 ≠ 0 := by
  nlinarith [sq_nonneg (x + y / 2), sq_nonneg y]
-- Using B^2 - AC instead (the test for 2Bxy) misreads the bed: 1 - 1 = 0, "parabola".
example : (1 : ℤ) ^ 2 - 1 * 1 = 0 := by decide

#print axioms discriminant_unchanged_by_turning_axes
#print axioms cot_two_theta_turn_removes_cross_term
#print axioms tangents_from_a_point_to_a_sphere_are_equal
