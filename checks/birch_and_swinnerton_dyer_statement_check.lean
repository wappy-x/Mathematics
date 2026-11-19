-- Birch and Swinnerton-Dyer: a functional equation with sign -1 forces L(E, 1) = 0, and the exact arithmetic of the house curve y^2 = x^3 - 2 (its discriminant, j-invariant, the points 2P and 3P of P = (3, 5), and its point counts modulo 5, 7, 11 and 13) is as the card states.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic

open WeierstrassCurve

/-- If the completed L-function `Λ(s) = N^(s/2) (2π)^(-s) Γ(s) L(s)` (with conductor `N > 0`)
satisfies the functional equation `Λ(2 - s) = w Λ(s)` with sign `w = -1`, then `L(1) = 0`:
at the centre `s = 1` the equation reads `Λ(1) = -Λ(1)`, so `Λ(1) = 0`, and the factor in front
of `L(1)` is not zero. This is why `L(E, 1) = 0` exactly for the rank-1 curve `y^2 = x^3 - 2`,
whose sign is `-1`. -/
theorem L_one_eq_zero_of_sign_neg_one (N : ℕ) (hN : 0 < N) (L : ℂ → ℂ)
    (hfe : ∀ s : ℂ,
      (N : ℂ) ^ ((2 - s) / 2) * ((2 * Real.pi : ℝ) : ℂ) ^ (-(2 - s)) * Complex.Gamma (2 - s) *
          L (2 - s) =
        -((N : ℂ) ^ (s / 2) * ((2 * Real.pi : ℝ) : ℂ) ^ (-s) * Complex.Gamma s * L s)) :
    L 1 = 0 := by
  have h := hfe 1
  have h21 : (2 : ℂ) - 1 = 1 := by norm_num
  rw [h21] at h
  have hx : (N : ℂ) ^ ((1 : ℂ) / 2) * ((2 * Real.pi : ℝ) : ℂ) ^ (-(1 : ℂ)) * Complex.Gamma 1 *
      L 1 = 0 := by
    linear_combination h / 2
  have hN' : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  have hpi : ((2 * Real.pi : ℝ) : ℂ) ≠ 0 := by
    exact_mod_cast (by positivity : (2 * Real.pi : ℝ) ≠ 0)
  have h1 : (N : ℂ) ^ ((1 : ℂ) / 2) ≠ 0 := by
    rw [Ne, Complex.cpow_eq_zero_iff]; tauto
  have h2 : ((2 * Real.pi : ℝ) : ℂ) ^ (-(1 : ℂ)) ≠ 0 := by
    rw [Ne, Complex.cpow_eq_zero_iff]; tauto
  rw [Complex.Gamma_one, mul_one] at hx
  rcases mul_eq_zero.mp hx with h | h
  · exact absurd h (mul_ne_zero h1 h2)
  · exact h

/-- The house curve `E : y^2 = x^3 - 2` over `ℚ` has discriminant `Δ = -1728` and `j = 0`;
`P = (3, 5)` is a nonsingular rational point on it, and the chord-and-tangent group law gives
`2P = (129/100, -383/1000)` and `3P = 2P + P = (164323/29241, -66234835/5000211)`. -/
theorem house_curve_discriminant_and_multiples :
    let W : WeierstrassCurve ℚ := ⟨0, 0, 0, 0, -2⟩
    W.Δ = -1728 ∧ (∀ [W.IsElliptic], W.j = 0) ∧
      ∃ (h₁ : W.toAffine.Nonsingular 3 5)
        (h₂ : W.toAffine.Nonsingular (129 / 100) (-383 / 1000))
        (h₃ : W.toAffine.Nonsingular (164323 / 29241) (-66234835 / 5000211)),
        Affine.Point.some 3 5 h₁ + Affine.Point.some 3 5 h₁ =
            Affine.Point.some (129 / 100) (-383 / 1000) h₂ ∧
          Affine.Point.some (129 / 100) (-383 / 1000) h₂ + Affine.Point.some 3 5 h₁ =
            Affine.Point.some (164323 / 29241) (-66234835 / 5000211) h₃ := by
  intro W
  refine ⟨?_, ?_, ?_⟩
  · simp [W, WeierstrassCurve.Δ, WeierstrassCurve.b₂, WeierstrassCurve.b₄, WeierstrassCurve.b₆,
      WeierstrassCurve.b₈]
    norm_num
  · intro _
    apply WeierstrassCurve.j_eq_zero
    simp [W, WeierstrassCurve.c₄, WeierstrassCurve.b₂, WeierstrassCurve.b₄]
  · have h₁ : W.toAffine.Nonsingular 3 5 := by
      rw [Affine.nonsingular_iff, Affine.equation_iff]; simp [W]; norm_num
    have h₂ : W.toAffine.Nonsingular (129 / 100) (-383 / 1000) := by
      rw [Affine.nonsingular_iff, Affine.equation_iff]; simp [W]; norm_num
    have h₃ : W.toAffine.Nonsingular (164323 / 29241) (-66234835 / 5000211) := by
      rw [Affine.nonsingular_iff, Affine.equation_iff]; simp [W]; norm_num
    refine ⟨h₁, h₂, h₃, ?_, ?_⟩
    · rw [Affine.Point.add_self_of_Y_ne (by simp [W, Affine.negY]; norm_num)]
      simp only [Affine.Point.some.injEq]
      constructor
      · simp [W, Affine.addX, Affine.slope, Affine.negY]; norm_num
      · simp [W, Affine.addY, Affine.addX, Affine.negAddY, Affine.slope, Affine.negY]; norm_num
    · rw [Affine.Point.add_of_X_ne (by norm_num)]
      simp only [Affine.Point.some.injEq]
      constructor
      · simp [W, Affine.addX, Affine.slope, Affine.negY]; norm_num
      · simp [W, Affine.addY, Affine.addX, Affine.negAddY, Affine.slope, Affine.negY]; norm_num

/-- The nonsingular points of a Weierstrass curve over a finite ring, the point at infinity
included, are the affine solutions passing the explicit nonsingularity test, plus one. -/
theorem card_point_eq {F : Type*} [CommRing F] [Fintype F] [DecidableEq F] (W : WeierstrassCurve F) :
    Nat.card W.toAffine.Point =
      ((Finset.univ : Finset (F × F)).filter (fun xy =>
        xy.2 ^ 2 + W.a₁ * xy.1 * xy.2 + W.a₃ * xy.2 =
            xy.1 ^ 3 + W.a₂ * xy.1 ^ 2 + W.a₄ * xy.1 + W.a₆ ∧
          (W.a₁ * xy.2 ≠ 3 * xy.1 ^ 2 + 2 * W.a₂ * xy.1 + W.a₄ ∨
            xy.2 ≠ -xy.2 - W.a₁ * xy.1 - W.a₃))).card + 1 := by
  rw [Nat.card_congr (Affine.nonsingularPointEquiv W.toAffine)]
  rw [show Nat.card (WithZero {xy : F × F // W.toAffine.Nonsingular xy.fst xy.snd}) =
    Nat.card (Option {xy : F × F // W.toAffine.Nonsingular xy.fst xy.snd}) from rfl,
    Finite.card_option]
  congr 1
  rw [Nat.card_congr (Equiv.subtypeEquivRight (fun xy => by
    rw [Affine.nonsingular_iff, Affine.equation_iff])), Nat.card_eq_fintype_card,
    Fintype.card_subtype]

#print axioms card_point_eq

/-- The number of points of `y^2 = x^3 - 2` modulo `p`, the point at infinity included, is
`N_5 = 6`, `N_7 = 7`, `N_11 = 12` and `N_13 = 19`. -/
theorem house_curve_points_mod_p :
    Nat.card (⟨0, 0, 0, 0, -2⟩ : WeierstrassCurve (ZMod 5)).toAffine.Point = 6 ∧
      Nat.card (⟨0, 0, 0, 0, -2⟩ : WeierstrassCurve (ZMod 7)).toAffine.Point = 7 ∧
      Nat.card (⟨0, 0, 0, 0, -2⟩ : WeierstrassCurve (ZMod 11)).toAffine.Point = 12 ∧
      Nat.card (⟨0, 0, 0, 0, -2⟩ : WeierstrassCurve (ZMod 13)).toAffine.Point = 19 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> rw [card_point_eq] <;> decide +kernel

-- (3, 5) lies on the curve: 5^2 = 25 = 3^3 - 2.
example : (5 : ℤ) ^ 2 = 3 ^ 3 - 2 := by norm_num
-- Doubling (3, 5): slope 3 * 3^2 / (2 * 5) = 27/10, and x(2P) = (27/10)^2 - 6 = 129/100.
example : (3 * 3 ^ 2 : ℚ) / (2 * 5) = 27 / 10 := by norm_num
example : ((27 : ℚ) / 10) ^ 2 - 2 * 3 = 129 / 100 := by norm_num
example : (27 : ℚ) / 10 * (3 - 129 / 100) - 5 = -383 / 1000 := by norm_num
-- Discriminant -16(4A^3 + 27B^2) with A = 0, B = -2.
example : (-16 : ℤ) * (4 * 0 ^ 3 + 27 * (-2) ^ 2) = -1728 := by norm_num
-- Mod 7, x^3 - 2 is a nonzero square exactly for x = 3, 5, 6.
example : ((3 : ZMod 7) ^ 3 - 2 = 4) ∧ ((5 : ZMod 7) ^ 3 - 2 = 4) ∧ ((6 : ZMod 7) ^ 3 - 2 = 4) := by
  decide
-- a_p = p + 1 - N_p: a_5 = 0, a_7 = 1, a_11 = 0, a_13 = -5.
example : ((5 : ℤ) + 1 - 6, (7 : ℤ) + 1 - 7, (11 : ℤ) + 1 - 12, (13 : ℤ) + 1 - 19) = (0, 1, 0, -5) := by
  norm_num
-- Torsion: gcd(N_5, N_7) = gcd(6, 7) = 1.
example : Nat.gcd 6 7 = 1 := by decide
-- The conductor: 2^6 * 3^3 = 1728.
example : 2 ^ 6 * 3 ^ 3 = 1728 := by norm_num
-- An order of Ш of 2 is impossible: when Ш is finite its order is a square, and 2 is not.
example : ¬ IsSquare (2 : ℕ) := by decide +kernel

#print axioms L_one_eq_zero_of_sign_neg_one
#print axioms house_curve_discriminant_and_multiples
#print axioms house_curve_points_mod_p
