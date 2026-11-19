-- Weierstrass form: away from 2 and 3 every curve reduces to y^2 = x^3 + ax + b, which has a singular point exactly when -16(4a^3 + 27b^2) = 0, and over the complex numbers equal j means one curve rescales to the other.
import Mathlib.AlgebraicGeometry.EllipticCurve.NormalForms
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Data.ZMod.Basic

open WeierstrassCurve

/-- The short Weierstrass curve `y^2 = x^3 + a x + b`, as a Mathlib `WeierstrassCurve`
with `a₁ = a₂ = a₃ = 0`, `a₄ = a` and `a₆ = b`. -/
abbrev shortWeierstrass {K : Type*} [CommRing K] (a b : K) : WeierstrassCurve K :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := a, a₆ := b }

/-- In a field where `2 ≠ 0` and `3 ≠ 0`, the curve `y^2 = x^3 + a x + b` has discriminant
`Δ = -16 (4a^3 + 27b^2)`, and it has a singular point (a point on the curve where both slopes
vanish) exactly when `Δ = 0`. -/
theorem short_weierstrass_singular_iff_discriminant_eq_zero {K : Type*} [Field K]
    (h2 : (2 : K) ≠ 0) (h3 : (3 : K) ≠ 0) (a b : K) :
    (shortWeierstrass a b).Δ = -16 * (4 * a ^ 3 + 27 * b ^ 2) ∧
      ((∃ x y : K, (shortWeierstrass a b).toAffine.Equation x y ∧
          ¬ (shortWeierstrass a b).toAffine.Nonsingular x y) ↔
        (shortWeierstrass a b).Δ = 0) := by
  have hΔ : (shortWeierstrass a b).Δ = -16 * (4 * a ^ 3 + 27 * b ^ 2) := by
    simp only [Δ, b₂, b₄, b₆, b₈]; ring
  refine ⟨hΔ, ⟨?_, ?_⟩⟩
  · rintro ⟨x, y, he, hns⟩
    by_contra h
    exact hns ((Affine.equation_iff_nonsingular_of_Δ_ne_zero
      (W := (shortWeierstrass a b).toAffine) h).mp he)
  · intro h0
    rw [hΔ] at h0
    have h16 : (16 : K) ≠ 0 := by
      have : (16 : K) = 2 ^ 4 := by norm_num
      rw [this]; exact pow_ne_zero _ h2
    have h27 : (27 : K) ≠ 0 := by
      have : (27 : K) = 3 ^ 3 := by norm_num
      rw [this]; exact pow_ne_zero _ h3
    have h4 : 4 * a ^ 3 + 27 * b ^ 2 = 0 := by
      rcases mul_eq_zero.mp h0 with h | h
      · exact absurd (neg_eq_zero.mp h) h16
      · exact h
    by_cases ha : a = 0
    · have hb : b = 0 := by
        subst ha
        have : 27 * b ^ 2 = 0 := by simpa using h4
        exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp
          ((mul_eq_zero.mp this).resolve_left h27)
      refine ⟨0, 0, ?_, ?_⟩
      · rw [Affine.equation_iff']; simp [ha, hb]
      · rw [Affine.nonsingular_iff', Affine.equation_iff']; simp [ha, hb]
    · refine ⟨-3 * b / (2 * a), 0, ?_, ?_⟩
      · rw [Affine.equation_iff']
        field_simp
        linear_combination b * h4
      · rw [Affine.nonsingular_iff', Affine.equation_iff']
        simp only [not_and, not_or, not_not]
        intro _
        refine ⟨?_, by ring⟩
        field_simp
        linear_combination (-1) * h4

/-- Over the complex numbers, for two smooth short curves the j-invariant is
`1728 · 4a^3 / (4a^3 + 27b^2)`, and two curves have the same j exactly when one rescales to the
other: `x = u^2 X`, `y = u^3 Y` with `u ≠ 0`, which sends `a, b` to `a / u^4, b / u^6`. -/
theorem j_eq_iff_exists_rescaling (a b a' b' : ℂ)
    [(shortWeierstrass a b).IsElliptic] [(shortWeierstrass a' b').IsElliptic] :
    (shortWeierstrass a b).j = 1728 * (4 * a ^ 3) / (4 * a ^ 3 + 27 * b ^ 2) ∧
      ((shortWeierstrass a b).j = (shortWeierstrass a' b').j ↔
        ∃ u : ℂ, u ≠ 0 ∧ a' = a / u ^ 4 ∧ b' = b / u ^ 6) := by
  have : (shortWeierstrass a b).IsShortNF := ⟨rfl, rfl, rfl⟩
  have : (shortWeierstrass a' b').IsShortNF := ⟨rfl, rfl, rfl⟩
  have hj := j_of_isShortNF (shortWeierstrass a b)
  have hj' := j_of_isShortNF (shortWeierstrass a' b')
  have hD : 4 * a ^ 3 + 27 * b ^ 2 ≠ 0 := by
    have h := (shortWeierstrass a b).Δ'.ne_zero
    rw [coe_Δ', Δ_of_isShortNF] at h
    exact right_ne_zero_of_mul h
  have hD' : 4 * a' ^ 3 + 27 * b' ^ 2 ≠ 0 := by
    have h := (shortWeierstrass a' b').Δ'.ne_zero
    rw [coe_Δ', Δ_of_isShortNF] at h
    exact right_ne_zero_of_mul h
  simp only at hj hj'
  refine ⟨by rw [hj]; ring, ?_⟩
  rw [hj, hj']
  constructor
  · intro h
    rw [div_eq_div_iff hD hD'] at h
    have key : a ^ 3 * b' ^ 2 = a' ^ 3 * b ^ 2 := by linear_combination h / (6912 * 27)
    by_cases ha : a = 0
    · subst ha
      have hb : b ≠ 0 := by rintro rfl; simp at hD
      have ha' : a' = 0 := by
        have : a' ^ 3 * b ^ 2 = 0 := by rw [← key]; ring
        simpa [hb] using this
      subst ha'
      have hb' : b' ≠ 0 := by rintro rfl; simp at hD'
      obtain ⟨u, hu⟩ := IsAlgClosed.exists_pow_nat_eq (b / b') (by norm_num : 0 < 6)
      have hu0 : u ≠ 0 := by
        rintro rfl; exact div_ne_zero hb hb' (by simpa using hu.symm)
      refine ⟨u, hu0, by simp, ?_⟩
      rw [hu]; field_simp
    by_cases hb : b = 0
    · subst hb
      have hb' : b' = 0 := by
        have : a ^ 3 * b' ^ 2 = 0 := by rw [key]; ring
        simpa [ha] using this
      subst hb'
      have ha' : a' ≠ 0 := by rintro rfl; simp at hD'
      obtain ⟨u, hu⟩ := IsAlgClosed.exists_pow_nat_eq (a / a') (by norm_num : 0 < 4)
      have hu0 : u ≠ 0 := by
        rintro rfl; exact div_ne_zero ha ha' (by simpa using hu.symm)
      refine ⟨u, hu0, ?_, by simp⟩
      rw [hu]; field_simp
    have ha' : a' ≠ 0 := by
      rintro rfl
      have hb' : b' = 0 := by
        have : a ^ 3 * b' ^ 2 = 0 := by rw [key]; ring
        simpa [ha] using this
      subst hb'; simp at hD'
    have hb' : b' ≠ 0 := by
      rintro rfl
      have : a' ^ 3 * b ^ 2 = 0 := by rw [← key]; ring
      simp [ha', hb] at this
    obtain ⟨u, hu⟩ := IsAlgClosed.exists_pow_nat_eq (b * a' / (b' * a)) (by norm_num : 0 < 2)
    have hu0 : u ≠ 0 := by
      rintro rfl
      exact div_ne_zero (mul_ne_zero hb ha') (mul_ne_zero hb' ha) (by simpa using hu.symm)
    have hu4 : u ^ 4 = (b * a' / (b' * a)) ^ 2 := by rw [← hu]; ring
    have hu6 : u ^ 6 = (b * a' / (b' * a)) ^ 3 := by rw [← hu]; ring
    refine ⟨u, hu0, ?_, ?_⟩
    · rw [hu4, eq_div_iff (by positivity)]
      field_simp
      linear_combination -key
    · rw [hu6, eq_div_iff (by positivity)]
      field_simp
      linear_combination (-1) * key
  · rintro ⟨u, hu, rfl, rfl⟩
    rw [div_eq_div_iff hD hD']
    field_simp

/-- In a field where `2 ≠ 0` and `3 ≠ 0`, every Weierstrass curve
`y^2 + a₁xy + a₃y = x^3 + a₂x^2 + a₄x + a₆` can be moved by a change of coordinates into
short form `y^2 = x^3 + a x + b` (`a₁ = a₂ = a₃ = 0`). -/
theorem exists_change_to_short_weierstrass {K : Type*} [Field K]
    (h2 : (2 : K) ≠ 0) (h3 : (3 : K) ≠ 0) (W : WeierstrassCurve K) :
    ∃ C : VariableChange K, (C • W).IsShortNF := by
  let := invertibleOfNonzero h2
  let := invertibleOfNonzero h3
  exact W.exists_variableChange_isShortNF

/-! ### The card's worked examples, checked exactly -/

/-- The house curve `y^2 = x^3 - 2` passes through `(3, 5)`: `25 = 27 - 2`. -/
example : (shortWeierstrass (0 : ℚ) (-2)).toAffine.Equation 3 5 := by
  rw [Affine.equation_iff]; norm_num

/-- The house curve has `Δ = -16 × 108 = -1728`, and `1728 = 2^6 · 3^3`. -/
example : (shortWeierstrass (0 : ℚ) (-2)).Δ = -1728 := by
  norm_num [Δ, b₂, b₄, b₆, b₈]

example : (1728 : ℕ) = 2 ^ 6 * 3 ^ 3 := by norm_num

/-- Its j-invariant is `1728 × 0 / 108 = 0`. -/
example : (1728 * (4 * (0 : ℚ) ^ 3) / (4 * 0 ^ 3 + 27 * (-2) ^ 2) : ℚ) = 0 := by norm_num

/-- The disguised house curve `y^2 + 2xy + 2y = x^3 + 2x^2 + x - 2` passes through `(2, 2)`,
and Tate's formulas give `b₂, b₄, b₆, b₈ = 12, 6, -4, -21`, `c₄ = 0`, `c₆ = 1728`, `Δ = -1728`. -/
example : ({ a₁ := 2, a₂ := 2, a₃ := 2, a₄ := 1, a₆ := -2 } : WeierstrassCurve ℚ).toAffine.Equation
    2 2 := by
  rw [Affine.equation_iff]; norm_num

example : let W : WeierstrassCurve ℚ := { a₁ := 2, a₂ := 2, a₃ := 2, a₄ := 1, a₆ := -2 }
    W.b₂ = 12 ∧ W.b₄ = 6 ∧ W.b₆ = -4 ∧ W.b₈ = -21 ∧ W.c₄ = 0 ∧ W.c₆ = 1728 ∧ W.Δ = -1728 := by
  norm_num [Δ, b₂, b₄, b₆, b₈, c₄, c₆]

/-- Steps 1 and 2: `Y = y + x + 1`, then `x = X - 1`, turn the long form into `Y^2 = X^3 - 2`. -/
example (x y : ℚ) : y ^ 2 + 2 * x * y + 2 * y - (x ^ 3 + 2 * x ^ 2 + x - 2) =
    (y + x + 1) ^ 2 - ((x + 1) ^ 3 - 2) := by ring

/-- The node `y^2 = x^3 - 3x + 2` and the cusp `y^2 = x^3` have `Δ = 0`; `(1, 0)` is a singular
point of the node. -/
example : (shortWeierstrass (-3 : ℚ) 2).Δ = 0 ∧ (shortWeierstrass (0 : ℚ) 0).Δ = 0 := by
  norm_num [Δ, b₂, b₄, b₆, b₈]

example : (shortWeierstrass (-3 : ℚ) 2).toAffine.Equation 1 0 ∧
    ¬ (shortWeierstrass (-3 : ℚ) 2).toAffine.Nonsingular 1 0 := by
  rw [Affine.nonsingular_iff', Affine.equation_iff']; norm_num

/-- `y^2 + y = x^3` is smooth: Tate's `Δ` is `-27`. -/
example : ({ a₁ := 0, a₂ := 0, a₃ := 1, a₄ := 0, a₆ := 0 } : WeierstrassCurve ℚ).Δ = -27 := by
  norm_num [Δ, b₂, b₄, b₆, b₈]

/-- Rescaling with `u = 1/2`: `y^2 = x^3 - x + 1` and `y^2 = x^3 - 16x + 64` have
`Δ = -368` and `-1507328 = -368 × 2^12`, both `j = -6912/23`, and `(1, 1) ↦ (4, 8)`. -/
example : (shortWeierstrass (-1 : ℚ) 1).Δ = -368 ∧ (shortWeierstrass (-16 : ℚ) 64).Δ = -1507328 ∧
    (-1507328 : ℚ) = -368 * 2 ^ 12 := by
  norm_num [Δ, b₂, b₄, b₆, b₈]

example : (1728 * (4 * (-1) ^ 3) / (4 * (-1) ^ 3 + 27 * 1 ^ 2) : ℚ) = -6912 / 23 ∧
    (1728 * (4 * (-16) ^ 3) / (4 * (-16) ^ 3 + 27 * 64 ^ 2) : ℚ) = -6912 / 23 := by norm_num

example : (8 : ℤ) ^ 2 = 4 ^ 3 - 16 * 4 + 64 := by norm_num

/-- Step 7: from `y^2 = 4x^3 - g₂x - g₃` with `g₂ = 4`, `g₃ = -4`, `j = 1728 g₂^3/(g₂^3 - 27g₃^2)`. -/
example : (1728 * 4 ^ 3 / (4 ^ 3 - 27 * (-4) ^ 2) : ℚ) = -6912 / 23 := by norm_num

/-- `y^2 = x^3 - x` has `j = 1728`; secp256k1, `y^2 = x^3 + 7`, has `Δ = -21168`. -/
example : (1728 * (4 * (-1) ^ 3) / (4 * (-1) ^ 3 + 27 * 0 ^ 2) : ℚ) = 1728 := by norm_num

example : (shortWeierstrass (0 : ℚ) 7).Δ = -21168 := by
  norm_num [Δ, b₂, b₄, b₆, b₈]

/-- Mistake 1: reading `a = 3`, `b = -1` before the shift gives `Δ = -2160` and `j = 6912/5`. -/
example : (shortWeierstrass (3 : ℚ) (-1)).Δ = -2160 ∧
    (1728 * (4 * 3 ^ 3) / (4 * 3 ^ 3 + 27 * (-1) ^ 2) : ℚ) = 6912 / 5 := by
  norm_num [Δ, b₂, b₄, b₆, b₈]

/-- Mod 3 the house curve has the singular point `(2, 0)`. -/
example : (0 : ZMod 3) ^ 2 = 2 ^ 3 - 2 ∧ 3 * (2 : ZMod 3) ^ 2 = 0 ∧ 2 * (0 : ZMod 3) = 0 := by
  decide

/-- Mistake 3: over `𝔽₂` every short form `y^2 = x^3 + a x + b` has a singular point. -/
example : ∀ a b : ZMod 2, ∃ x y : ZMod 2,
    y ^ 2 = x ^ 3 + a * x + b ∧ 3 * x ^ 2 + a = 0 ∧ 2 * y = 0 := by
  decide

/-- Mistake 4: both have `j = 0`, yet mod 7 `y^2 = x^3 - 2` has 7 points (with `O`) and
`y^2 = x^3 + 1` has 12; the true rescaling `y^2 = x^3 - 128` also has 7. -/
example : (Finset.univ.filter (fun p : ZMod 7 × ZMod 7 => p.2 ^ 2 = p.1 ^ 3 - 2)).card + 1 = 7 ∧
    (Finset.univ.filter (fun p : ZMod 7 × ZMod 7 => p.2 ^ 2 = p.1 ^ 3 + 1)).card + 1 = 12 ∧
    (Finset.univ.filter (fun p : ZMod 7 × ZMod 7 => p.2 ^ 2 = p.1 ^ 3 - 128)).card + 1 = 7 := by
  decide

example : (40 : ℤ) ^ 2 = 12 ^ 3 - 128 := by norm_num

#print axioms short_weierstrass_singular_iff_discriminant_eq_zero
#print axioms j_eq_iff_exists_rescaling
#print axioms exists_change_to_short_weierstrass
