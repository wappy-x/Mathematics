-- Isogenies: the map φ(x, y) = (y²/x², −y(x² + 1)/x²) carries y² = x³ − x onto Y² = X³ + 4X and its dual brings every point back as twice itself, multiplication by m has an x-fraction of degree m², and a never-negative degree form m² − a·m·n + p·n² forces Hasse's bound a² ≤ 4p.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.AlgebraicGeometry.EllipticCurve.DivisionPolynomial.Degree
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Fintype.Prod

open WeierstrassCurve

/-- The card's curve E : y² = x³ − x. -/
def curveE (F : Type*) [Field F] : WeierstrassCurve F :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := -1, a₆ := 0 }

/-- The card's curve E′ : Y² = X³ + 4X. -/
def curveE' (F : Type*) [Field F] : WeierstrassCurve F :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := 4, a₆ := 0 }

/-- The isogeny φ(x, y) = (y²/x², −y(x² + 1)/x²), coordinate by coordinate. -/
def phiX {F : Type*} [Field F] (x y : F) : F := y ^ 2 / x ^ 2
def phiY {F : Type*} [Field F] (x y : F) : F := -y * (x ^ 2 + 1) / x ^ 2

/-- The dual φ̂(X, Y) = (Y²/(4X²), Y(4 − X²)/(8X²)), coordinate by coordinate. -/
def dualX {F : Type*} [Field F] (X Y : F) : F := Y ^ 2 / (4 * X ^ 2)
def dualY {F : Type*} [Field F] (X Y : F) : F := Y * (4 - X ^ 2) / (8 * X ^ 2)

/-- The card's main claim for its example, over any field where 2 ≠ 0 (every odd prime):
for a point P = (x, y) of E : y² = x³ − x with x ≠ 0 and y ≠ 0 (so neither φ nor φ̂ sends it
to O), the image φ(P) is a point of E′ : Y² = X³ + 4X, and the dual sends φ(P) back to a point
of E that equals P + P in E's group law: φ̂ ∘ φ = [2], where 2 = deg φ. -/
theorem dual_comp_phi_eq_two {F : Type*} [Field F] [DecidableEq F] (h2 : (2 : F) ≠ 0) {x y : F}
    (hP : (curveE F).toAffine.Nonsingular x y) (hx : x ≠ 0) (hy : y ≠ 0) :
    (curveE' F).toAffine.Nonsingular (phiX x y) (phiY x y) ∧
    ∃ hR : (curveE F).toAffine.Nonsingular (dualX (phiX x y) (phiY x y)) (dualY (phiX x y) (phiY x y)),
      Affine.Point.some x y hP + Affine.Point.some x y hP = Affine.Point.some _ _ hR := by
  have hE : y ^ 2 = x ^ 3 - x := by
    have := hP.1
    rw [Affine.equation_iff] at this
    simp only [curveE] at this
    linear_combination this
  have h2y : 2 * y ≠ 0 := mul_ne_zero h2 hy
  have hne : y ≠ (curveE F).toAffine.negY x y := by
    simp only [Affine.negY, curveE]
    intro h; apply h2y; linear_combination h
  have h4 : (4 : F) ≠ 0 := by
    have := mul_ne_zero h2 h2; norm_num at this; exact this
  have h8 : (8 : F) ≠ 0 := by
    have := mul_ne_zero h4 h2; norm_num at this; exact this
  refine ⟨?_, ?_⟩
  · rw [Affine.nonsingular_iff]
    refine ⟨?_, ?_⟩
    · rw [Affine.equation_iff]
      simp only [curveE', phiX, phiY]
      field_simp
      linear_combination (-y ^ 2 * (y ^ 2 + x ^ 3 - x)) * hE
    · simp only [curveE']
      by_cases hx1 : x ^ 2 + 1 = 0
      · left
        have hXv : phiX x y = 2 * x := by
          simp only [phiX]
          rw [div_eq_iff (pow_ne_zero 2 hx)]
          linear_combination hE - x * hx1
        rw [hXv]
        intro h
        apply h8
        linear_combination h + 12 * hx1
      · right
        have hYv : phiY x y ≠ 0 := by
          simp only [phiY]
          exact div_ne_zero (mul_ne_zero (neg_ne_zero.mpr hy) hx1) (pow_ne_zero 2 hx)
        intro h
        apply mul_ne_zero h2 hYv
        linear_combination h
  · have hs : (curveE F).toAffine.slope x x y y = (3 * x ^ 2 - 1) / (2 * y) := by
      rw [Affine.slope_of_Y_ne rfl hne]
      simp only [Affine.negY, curveE]
      congr 1 <;> ring
    have hX : dualX (phiX x y) (phiY x y) = (curveE F).toAffine.addX x x ((curveE F).toAffine.slope x x y y) := by
      rw [hs]
      simp only [dualX, phiX, phiY, Affine.addX, curveE]
      field_simp
      linear_combination 32 * x * hE
    have hY : dualY (phiX x y) (phiY x y) = (curveE F).toAffine.addY x x y ((curveE F).toAffine.slope x x y y) := by
      rw [hs]
      simp only [dualY, phiX, phiY, Affine.addY, Affine.negAddY, Affine.addX, Affine.negY, curveE]
      field_simp
      linear_combination ((8 : F) * y ^ 2 - 8 * x + 72 * x ^ 2 * y ^ 2 + 32 * x ^ 3 - 216 * x ^ 5) * hE
    have key : ∀ {a b c d : F} (h1 : (curveE F).toAffine.Nonsingular a b),
        c = a → d = b → ∃ h2 : (curveE F).toAffine.Nonsingular c d,
          Affine.Point.some a b h1 = Affine.Point.some c d h2 := by
      rintro a b c d h1 rfl rfl; exact ⟨h1, rfl⟩
    rw [Affine.Point.add_self_of_Y_ne hne]
    exact key _ hX hY

/-- deg [m] = m², leading terms: when the characteristic does not divide m, the x-coordinate of
mP is Φ_m / ψ_m², whose top Φ_m has degree m² and leading coefficient 1, and whose bottom ψ_m²
has degree m² − 1 and leading coefficient m². -/
theorem x_mul_top_bottom_degrees {F : Type*} [Field F] (W : WeierstrassCurve F) (m : ℕ)
    (hm : (m : F) ≠ 0) :
    (W.Φ m).natDegree = m ^ 2 ∧ (W.Φ m).leadingCoeff = 1 ∧
    (W.ΨSq m).natDegree = m ^ 2 - 1 ∧ (W.ΨSq m).leadingCoeff = (m : F) ^ 2 := by
  have h : (((m : ℤ) : F)) ≠ 0 := by rwa [Int.cast_natCast]
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [W.natDegree_Φ]; simp
  · exact W.leadingCoeff_Φ _
  · rw [W.natDegree_ΨSq h]; simp
  · rw [W.leadingCoeff_ΨSq h]; simp

/-- Hasse's bound from the degree form: if deg(m − nπ) = m² − a·m·n + p·n² is never negative
for whole numbers m and n, then a² ≤ 4p. -/
theorem hasse_of_degree_form_nonneg (a p : ℤ)
    (h : ∀ m n : ℤ, 0 ≤ m ^ 2 - a * m * n + p * n ^ 2) : a ^ 2 ≤ 4 * p := by
  have := h a 2
  linarith

instance : Fact (Nat.Prime 29) := ⟨by decide⟩

-- Isogenous curves, equal counts (O included): 8 over 𝔽₅ and 𝔽₁₃, 16 over 𝔽₁₇, 40 over 𝔽₂₉.
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - q.1)).card + 1 = 8 := by decide
example : ((Finset.univ : Finset (ZMod 5 × ZMod 5)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 + 4 * q.1)).card + 1 = 8 := by decide
example : ((Finset.univ : Finset (ZMod 13 × ZMod 13)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - q.1)).card + 1 = 8 := by decide
example : ((Finset.univ : Finset (ZMod 13 × ZMod 13)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 + 4 * q.1)).card + 1 = 8 := by decide
example : ((Finset.univ : Finset (ZMod 17 × ZMod 17)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - q.1)).card + 1 = 16 := by decide
example : ((Finset.univ : Finset (ZMod 17 × ZMod 17)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 + 4 * q.1)).card + 1 = 16 := by decide
example : ((Finset.univ : Finset (ZMod 29 × ZMod 29)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 - q.1)).card + 1 = 40 := by decide
example : ((Finset.univ : Finset (ZMod 29 × ZMod 29)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 + 4 * q.1)).card + 1 = 40 := by decide

-- The worked numbers mod 29: P = (3, 13) is on E, φ(P) = (22, 21) is on E′,
-- φ̂(φ(P)) = (24, 24), and 2P by the tangent rule (slope (3·9 − 1)/(2·13) = 1) is (24, 24).
example : (13 : ZMod 29) ^ 2 = 3 ^ 3 - 3 := by decide
example : phiX (3 : ZMod 29) 13 = 22 := by
  rw [phiX, div_eq_iff (by decide)]; decide
example : phiY (3 : ZMod 29) 13 = 21 := by
  rw [phiY, div_eq_iff (by decide)]; decide
example : (21 : ZMod 29) ^ 2 = 22 ^ 3 + 4 * 22 := by decide
example : dualX (22 : ZMod 29) 21 = 24 := by
  rw [dualX, div_eq_iff (by decide)]; decide
example : dualY (22 : ZMod 29) 21 = 24 := by
  rw [dualY, div_eq_iff (by decide)]; decide
example : ((3 * 3 ^ 2 - 1) / (2 * 13) : ZMod 29) = 1 := by
  rw [div_eq_iff (by decide)]; decide
example : (1 : ZMod 29) ^ 2 - 2 * 3 = 24 ∧ (1 : ZMod 29) * (3 - 24) - 13 = 24 := by decide

-- The house curve y² = x³ − 2: x(2P) = (x⁴ + 16x)/(4x³ − 8) at x = 3 is 129/100,
-- the tangent rule's (27/10)² − 2·3.
example : ((3 : ℚ) ^ 4 + 16 * 3) / (4 * 3 ^ 3 - 8) = 129 / 100 ∧
    ((27 : ℚ) / 10) ^ 2 - 2 * 3 = 129 / 100 := by norm_num

-- Hasse at p = 5: 8 points, so a₅ = 5 + 1 − 8 = −2, and the discriminant a₅² − 4·5 is −16.
example : (5 + 1 - 8 : ℤ) = -2 ∧ (-2 : ℤ) ^ 2 - 4 * 5 = -16 := by norm_num
-- deg(1 + π) at p = 5 is the form at m = 1, n = −1: 1 − 2 + 5 = 4; and 8 × 4 = 32.
example : (1 : ℤ) ^ 2 - (-2) * 1 * (-1) + 5 * (-1) ^ 2 = 4 ∧ (8 : ℤ) * 4 = 32 := by norm_num

#print axioms dual_comp_phi_eq_two
#print axioms x_mul_top_bottom_degrees
#print axioms hasse_of_degree_form_nonneg
