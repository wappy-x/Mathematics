-- Banach algebras: in a commutative complex Banach algebra the spectrum of an element is the set of values its characters give it, the largest of them in size is lim ‖xⁿ‖^(1/n) ≤ ‖x‖, and the characters of C[a, b] are the readings at single times.
import Mathlib.Analysis.CStarAlgebra.GelfandDuality
import Mathlib.Analysis.Normed.Algebra.GelfandFormula
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum

open Filter Topology
open scoped NNReal ENNReal

/-- In a commutative Banach algebra over the complex numbers, a number `λ` is in the spectrum of
`x` (so `x - λ 1` has no inverse) exactly when some character `χ`, a linear map to `ℂ` that
respects products and the unit, reads `χ x = λ`. No continuity is assumed of the characters. -/
theorem spectrum_eq_character_values {A : Type*} [NormedCommRing A] [NormedAlgebra ℂ A]
    [CompleteSpace A] (x : A) :
    spectrum ℂ x = {z : ℂ | ∃ χ : A →ₐ[ℂ] ℂ, χ x = z} := by
  refine Set.ext fun z => ?_
  rw [WeakDual.CharacterSpace.mem_spectrum_iff_exists]
  constructor
  · rintro ⟨f, hf⟩
    exact ⟨WeakDual.CharacterSpace.equivAlgHom f, hf⟩
  · rintro ⟨χ, hχ⟩
    exact ⟨WeakDual.CharacterSpace.equivAlgHom.symm χ, hχ⟩

/-- In a commutative complex Banach algebra, the largest size of the Gelfand transform
`x̂(χ) = χ x` over all characters is the spectral radius `r(x)`; that radius is the limit of
`‖xⁿ‖^(1/n)`, and it is never more than `‖x‖`. -/
theorem gelfand_transform_sup_eq_spectral_radius {A : Type*} [NormedCommRing A]
    [NormedAlgebra ℂ A] [CompleteSpace A] (x : A) :
    (⨆ χ : A →ₐ[ℂ] ℂ, (‖χ x‖₊ : ℝ≥0∞)) = spectralRadius ℂ x ∧
      Tendsto (fun n : ℕ => ENNReal.ofReal (‖x ^ n‖ ^ (1 / n : ℝ))) atTop
        (𝓝 (spectralRadius ℂ x)) ∧
      spectralRadius ℂ x ≤ ‖x‖₊ := by
  refine ⟨?_, spectrum.pow_norm_pow_one_div_tendsto_nhds_spectralRadius x,
    spectralRadius_le_nnnorm x⟩
  rw [spectralRadius_eq_of_unital]
  apply le_antisymm
  · refine iSup_le fun χ => ?_
    exact le_iSup₂ (f := fun k (_ : k ∈ spectrum ℂ x) => (‖k‖₊ : ℝ≥0∞)) (χ x)
      (AlgHom.apply_mem_spectrum χ x)
  · refine iSup₂_le fun k hk => ?_
    rw [WeakDual.CharacterSpace.mem_spectrum_iff_exists] at hk
    obtain ⟨f, rfl⟩ := hk
    exact le_iSup (fun χ : A →ₐ[ℂ] ℂ => (‖χ x‖₊ : ℝ≥0∞))
      (WeakDual.CharacterSpace.equivAlgHom f)

/-- The characters of `C[a, b]`, the continuous complex curves on a closed bounded interval, are
exactly the clock times: each character reads the curve at one single time `t`, and that time is
unique. -/
theorem characters_of_C_interval_are_point_readings (a b : ℝ)
    (χ : C(Set.Icc a b, ℂ) →ₐ[ℂ] ℂ) :
    ∃! t : Set.Icc a b, ∀ f : C(Set.Icc a b, ℂ), χ f = f t := by
  obtain ⟨t, ht⟩ := (WeakDual.CharacterSpace.continuousMapEval_bijective (Set.Icc a b) ℂ).2
    (WeakDual.CharacterSpace.equivAlgHom.symm χ)
  refine ⟨t, fun f => ?_, fun s hs => ?_⟩
  · have := congrArg (fun φ : WeakDual.characterSpace ℂ C(Set.Icc a b, ℂ) => φ f) ht
    simpa using this.symm
  · apply (WeakDual.CharacterSpace.continuousMapEval_bijective (Set.Icc a b) ℂ).1
    rw [ht]
    ext f
    simp [hs f]

/-! Worked numbers from the card, checked exactly. -/

/-- The illustrative price curve, in pounds per MWh, `p(t) = 30 + (t - 12)² / 2`. -/
def price (t : ℚ) : ℚ := 30 + (t - 12) ^ 2 / 2

-- The rehearsal list: prices at 0:00, 6:00, 12:00 and 18:00 are 102, 48, 30, 48.
example : (price 0, price 6, price 12, price 18) = (102, 48, 30, 48) := by
  norm_num [price]

-- Smallest price 30 at noon, largest 102 at midnight (both ends of the day).
example : price 12 = 30 ∧ price 0 = 102 ∧ price 24 = 102 := by norm_num [price]

-- The level 80 is reached at 2:00 and at 22:00, so 80 is in the spectrum.
example : price 2 = 80 ∧ price 22 = 80 := by norm_num [price]

-- The reading at 5:00 is 54.5 = 109/2, inside [30, 102].
example : price 5 = 109 / 2 ∧ 30 ≤ price 5 ∧ price 5 ≤ 102 := by norm_num [price]

-- The nearest prices to 20 and 110 are 30 and 102, so the inverses have sizes 1/10 and 1/8.
example : (1 : ℚ) / (30 - 20) = 1 / 10 ∧ (1 : ℚ) / (110 - 102) = 1 / 8 := by norm_num

-- The swap J squares to the identity, and the nilpotent Z squares to zero.
example : !![(0 : ℚ), 1; 1, 0] * !![0, 1; 1, 0] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]

example : !![(0 : ℚ), 1; 0, 0] * !![0, 1; 0, 0] = 0 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]

-- The light blur 0.8 I + 0.2 J has inverse (4/3) I - (1/3) J.
example : !![(4 : ℚ) / 5, 1 / 5; 1 / 5, 4 / 5] * !![4 / 3, -1 / 3; -1 / 3, 4 / 3] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]

-- The full average 0.5 I + 0.5 J has transform (1, 0) and determinant 0.
example : (1 : ℚ) / 2 + 1 / 2 = 1 ∧ (1 : ℚ) / 2 - 1 / 2 = 0 ∧
    Matrix.det !![(1 : ℚ) / 2, 1 / 2; 1 / 2, 1 / 2] = 0 := by
  norm_num [Matrix.det_fin_two_of]

-- The daily average is not a character: mean of p² is 3376.8 = 16884/5, (mean p)² = 54² = 2916.
example : (16884 : ℚ) / 5 - 54 ^ 2 = 2304 / 5 ∧ (54 : ℚ) ^ 2 = 2916 := by norm_num

-- The shear T = I + Z has T¹⁰ = [[1, 10], [0, 1]], so its largest row sum is 11 = 10 + 1.
example : !![(1 : ℤ), 1; 0, 1] ^ 10 = !![1, 10; 0, 1] := by decide

#print axioms spectrum_eq_character_values
#print axioms gelfand_transform_sup_eq_spectral_radius
#print axioms characters_of_C_interval_are_point_readings
