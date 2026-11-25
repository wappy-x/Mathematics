-- The Jacobian: the genus-2 class count (N1^2 + N2)/2 - q equals L(1), the count lies in Weil's window, and in genus 1 the map P to P - O carries the chord-and-tangent sum to the sum of classes and never merges two points.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Data.ZMod.Basic

open Polynomial

/-- The genus-2 count formula: from the point counts `N₁` over `𝔽_q` and `N₂` over `𝔽_{q²}`,
set `a₁ = N₁ - q - 1` and `a₂ = (N₂ - q² - 1 + a₁²)/2`. Then the L-polynomial
`L(T) = 1 + a₁T + a₂T² + q a₁T³ + q²T⁴` takes the value `(N₁² + N₂)/2 - q` at `T = 1`;
this number is `#Jac(𝔽_q)`. -/
theorem jac_card_genus_two_eq_L_one (q N₁ N₂ : ℕ) (a₁ a₂ : ℚ)
    (ha₁ : a₁ = N₁ - q - 1) (ha₂ : a₂ = (N₂ - (q : ℚ) ^ 2 - 1 + a₁ ^ 2) / 2) :
    (C 1 + C a₁ * X + C a₂ * X ^ 2 + C ((q : ℚ) * a₁) * X ^ 3 + C ((q : ℚ) ^ 2) * X ^ 4 :
        ℚ[X]).eval 1 = ((N₁ : ℚ) ^ 2 + N₂) / 2 - q := by
  subst ha₂ ha₁
  simp only [eval_add, eval_mul, eval_C, eval_pow, eval_X, one_pow, mul_one]
  ring

/-- Weil's window: if the `2g` reciprocal roots `αᵢ` of the L-polynomial all have absolute value
`√q`, then `#Jac(𝔽_q) = |∏ (1 - αᵢ)|` lies between `(√q - 1)^(2g)` and `(√q + 1)^(2g)`. -/
theorem jac_card_in_weil_window (g q : ℕ) (α : Fin (2 * g) → ℂ)
    (hα : ∀ i, ‖α i‖ = Real.sqrt q) :
    (Real.sqrt q - 1) ^ (2 * g) ≤ ‖∏ i, (1 - α i)‖ ∧
      ‖∏ i, (1 - α i)‖ ≤ (Real.sqrt q + 1) ^ (2 * g) := by
  rw [norm_prod]
  have hcard : (Finset.univ : Finset (Fin (2 * g))).card = 2 * g := by simp
  constructor
  · have h1 : (Real.sqrt q - 1) ^ (2 * g) = ∏ _i : Fin (2 * g), |Real.sqrt q - 1| := by
      rw [Finset.prod_const, hcard, (even_two_mul g).pow_abs]
    rw [h1]
    refine Finset.prod_le_prod₀ (fun _ _ => abs_nonneg _) (fun i _ => ?_)
    have := abs_norm_sub_norm_le (α i) (1 : ℂ)
    rw [hα i, norm_one, norm_sub_rev] at this
    exact this
  · have h1 : (Real.sqrt q + 1) ^ (2 * g) = ∏ _i : Fin (2 * g), (Real.sqrt q + 1) := by
      rw [Finset.prod_const, hcard]
    rw [h1]
    refine Finset.prod_le_prod₀ (fun _ _ => norm_nonneg _) (fun i _ => ?_)
    calc ‖1 - α i‖ ≤ ‖(1 : ℂ)‖ + ‖α i‖ := norm_sub_le _ _
      _ = Real.sqrt q + 1 := by rw [norm_one, hα i]; ring

/-- Genus 1, Abel-Jacobi: on a smooth Weierstrass cubic over a field, the map sending a point `P`
to the class of `P - O` (Mathlib: `P` to the class of the ideal `⟨X - x, Y - y⟩` of the coordinate
ring) carries the chord-and-tangent sum to the sum of classes, and two different points never give
the same class. -/
theorem abel_jacobi_genus_one_add_and_injective {F : Type*} [Field F] [DecidableEq F]
    (W : WeierstrassCurve.Affine F) [W.IsElliptic] :
    (∀ P Q : W.Point, WeierstrassCurve.Affine.Point.toClass (P + Q) =
        WeierstrassCurve.Affine.Point.toClass P + WeierstrassCurve.Affine.Point.toClass Q) ∧
      Function.Injective (WeierstrassCurve.Affine.Point.toClass (W := W)) := by
  exact ⟨fun P Q => map_add _ P Q, WeierstrassCurve.Affine.Point.toClass_injective⟩

/-! Worked numbers on the card: `y² = x⁵ + x + 1` over `𝔽_5`. -/

-- 5 affine points over 𝔽_5; with ∞, N₁ = 6.
example : (Finset.univ.filter
    (fun p : ZMod 5 × ZMod 5 => p.2 ^ 2 = p.1 ^ 5 + p.1 + 1)).card = 5 := by decide

-- a₁ = 6 - 5 - 1 = 0 and a₂ = (46 - 25 - 1 + 0)/2 = 10.
example : (6 : ℤ) - 5 - 1 = 0 ∧ ((46 : ℤ) - 25 - 1 + 0 ^ 2) / 2 = 10 := by norm_num

-- the count: (6² + 46)/2 - 5 = 36 = L(1) = 1 + 0 + 10 + 0 + 25.
example : ((6 : ℤ) ^ 2 + 46) / 2 - 5 = 36 ∧ (1 + 0 + 10 + 0 + 25 : ℤ) = 36 := by norm_num

-- over 𝔽_25: L(1) L(-1) = 36 · 36 = 1296.
example : (36 : ℤ) * 36 = 1296 := by norm_num

-- the mistakes: dropping the - q gives 41; dropping ∞ gives (25 + 45)/2 - 5 = 30.
example : ((6 : ℤ) ^ 2 + 46) / 2 = 41 ∧ ((25 : ℤ) + 45) / 2 - 5 = 30 := by norm_num

-- the tangent at (0, 1): 2c = 1 in 𝔽_5 gives c = 3.
example : (2 * 3 : ZMod 5) = 1 := by decide

-- genus 1, y² = x³ + x² + 1 over 𝔽_5: 4 affine points, 5 with O.
example : (Finset.univ.filter
    (fun p : ZMod 5 × ZMod 5 => p.2 ^ 2 = p.1 ^ 3 + p.1 ^ 2 + 1)).card = 4 := by decide

-- the nodal cubic y² = x³ + x² over 𝔽_5: 4 affine points with the node (0, 0), so 5 with O,
-- but only 3 smooth affine points, a group of 4 with O.
example : (Finset.univ.filter
    (fun p : ZMod 5 × ZMod 5 => p.2 ^ 2 = p.1 ^ 3 + p.1 ^ 2)).card = 4 ∧
    (Finset.univ.filter
    (fun p : ZMod 5 × ZMod 5 => p.2 ^ 2 = p.1 ^ 3 + p.1 ^ 2 ∧ p ≠ (0, 0))).card = 3 := by decide

#print axioms jac_card_genus_two_eq_L_one
#print axioms jac_card_in_weil_window
#print axioms abel_jacobi_genus_one_add_and_injective
