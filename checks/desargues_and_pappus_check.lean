-- Desargues and Pappus: in homogeneous coordinates over the reals, triangles in perspective from a point have matching sides meeting on one line, the cross-joins of three points on each of two lines meet on one line, and the dual of Desargues (its converse) holds.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Basic.Real.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.Tactic.Ring

open Matrix

/-- Bracket identity behind Desargues: the side-meet determinant factors as the two triangle
determinants times the determinant of the three corner-joining lines. -/
theorem desargues_bracket_identity (a b c a' b' c' : Fin 3 → ℝ) :
    det ![(a ⨯₃ b) ⨯₃ (a' ⨯₃ b'), (b ⨯₃ c) ⨯₃ (b' ⨯₃ c'), (c ⨯₃ a) ⨯₃ (c' ⨯₃ a')] =
      det ![a, b, c] * det ![a', b', c'] * det ![a ⨯₃ a', b ⨯₃ b', c ⨯₃ c'] := by
  simp only [← triple_product_eq_det]
  simp [cross_apply, dotProduct, Fin.sum_univ_three]
  ring

#print axioms desargues_bracket_identity

/-- Bracket identity behind Pappus: the crossing determinant is a combination of the two
collinearity determinants `det ![d₁, d₂, d₃]` and `det ![t₁, t₂, t₃]`. -/
theorem pappus_bracket_identity (d₁ d₂ d₃ t₁ t₂ t₃ : Fin 3 → ℝ) :
    det ![(d₁ ⨯₃ t₂) ⨯₃ (d₂ ⨯₃ t₁), (d₁ ⨯₃ t₃) ⨯₃ (d₃ ⨯₃ t₁), (d₂ ⨯₃ t₃) ⨯₃ (d₃ ⨯₃ t₂)] =
      det ![d₁, d₂, d₃] * det ![d₁, t₁, t₂] * det ![d₂, t₁, t₃] * det ![d₃, t₂, t₃] -
      det ![t₁, t₂, t₃] * det ![d₁, d₂, t₁] * det ![d₁, d₃, t₂] * det ![d₂, d₃, t₃] := by
  simp only [← triple_product_eq_det]
  simp [cross_apply, dotProduct, Fin.sum_univ_three]
  ring

#print axioms pappus_bracket_identity

/-- Three triples all perpendicular to one nonzero triple have determinant `0`. -/
theorem det_eq_zero_of_dotProduct_eq_zero (u v w o : Fin 3 → ℝ) (ho : o ≠ 0)
    (hu : u ⬝ᵥ o = 0) (hv : v ⬝ᵥ o = 0) (hw : w ⬝ᵥ o = 0) : det ![u, v, w] = 0 := by
  show det (Matrix.of ![u, v, w]) = 0
  rw [← Matrix.exists_mulVec_eq_zero_iff]
  refine ⟨o, ho, ?_⟩
  ext i
  fin_cases i <;> simp [mulVec, hu, hv, hw]

#print axioms det_eq_zero_of_dotProduct_eq_zero

/-- Desargues' theorem. Points and lines are real triples (any nonzero multiple naming the same
point); a point `p` lies on the line through `u` and `v` when `det [p u v] = 0`; the line through
two points, and the meet of two lines, are cross products. If triangles `a b c` and `a' b' c'`
are in perspective from a point `o` (each primed corner on the line through `o` and its
partner), both triangles are genuine (not flat), and matching sides are distinct lines (their
meets are genuine points), then the three meets `P = AB ∩ A'B'`, `Q = BC ∩ B'C'` and
`R = CA ∩ C'A'` lie on one line: the determinant of their triples is `0`. Points at infinity
(last entry `0`) are allowed. -/
theorem desargues_perspective_triangles_sides_meet_on_one_line
    (o a b c a' b' c' : Fin 3 → ℝ) (ho : o ≠ 0)
    (hA : det ![o, a, a'] = 0) (hB : det ![o, b, b'] = 0) (hC : det ![o, c, c'] = 0)
    (habc : det ![a, b, c] ≠ 0) (habc' : det ![a', b', c'] ≠ 0)
    (hP : (a ⨯₃ b) ⨯₃ (a' ⨯₃ b') ≠ 0) (hQ : (b ⨯₃ c) ⨯₃ (b' ⨯₃ c') ≠ 0)
    (hR : (c ⨯₃ a) ⨯₃ (c' ⨯₃ a') ≠ 0) :
    det ![(a ⨯₃ b) ⨯₃ (a' ⨯₃ b'), (b ⨯₃ c) ⨯₃ (b' ⨯₃ c'), (c ⨯₃ a) ⨯₃ (c' ⨯₃ a')] = 0 := by
  rw [desargues_bracket_identity]
  have hL : det ![a ⨯₃ a', b ⨯₃ b', c ⨯₃ c'] = 0 :=
    det_eq_zero_of_dotProduct_eq_zero _ _ _ o ho
      (by rw [dotProduct_comm, triple_product_eq_det]; exact hA)
      (by rw [dotProduct_comm, triple_product_eq_det]; exact hB)
      (by rw [dotProduct_comm, triple_product_eq_det]; exact hC)
  rw [hL, mul_zero]

/-- Pappus's theorem. Points `d₁ d₂ d₃` lie on one line `ℓ` and points `t₁ t₂ t₃` on another
line `m` (a point `p` lies on a line `ℓ` when `ℓ ⬝ p = 0`). Join each `dᵢ` to a different `tⱼ`
and cross the joins in pairs: `Mᵢⱼ = (dᵢ × tⱼ) × (dⱼ × tᵢ)`. When the three crossings are genuine
points, they lie on one line: the determinant of their triples is `0`. -/
theorem pappus_cross_joins_meet_on_one_line
    (ℓ m d₁ d₂ d₃ t₁ t₂ t₃ : Fin 3 → ℝ) (hℓ : ℓ ≠ 0) (hm : m ≠ 0)
    (hd₁ : ℓ ⬝ᵥ d₁ = 0) (hd₂ : ℓ ⬝ᵥ d₂ = 0) (hd₃ : ℓ ⬝ᵥ d₃ = 0)
    (ht₁ : m ⬝ᵥ t₁ = 0) (ht₂ : m ⬝ᵥ t₂ = 0) (ht₃ : m ⬝ᵥ t₃ = 0)
    (hM₁₂ : (d₁ ⨯₃ t₂) ⨯₃ (d₂ ⨯₃ t₁) ≠ 0) (hM₁₃ : (d₁ ⨯₃ t₃) ⨯₃ (d₃ ⨯₃ t₁) ≠ 0)
    (hM₂₃ : (d₂ ⨯₃ t₃) ⨯₃ (d₃ ⨯₃ t₂) ≠ 0) :
    det ![(d₁ ⨯₃ t₂) ⨯₃ (d₂ ⨯₃ t₁), (d₁ ⨯₃ t₃) ⨯₃ (d₃ ⨯₃ t₁), (d₂ ⨯₃ t₃) ⨯₃ (d₃ ⨯₃ t₂)] = 0 := by
  have hD : det ![d₁, d₂, d₃] = 0 :=
    det_eq_zero_of_dotProduct_eq_zero _ _ _ ℓ hℓ
      (by rw [dotProduct_comm]; exact hd₁) (by rw [dotProduct_comm]; exact hd₂)
      (by rw [dotProduct_comm]; exact hd₃)
  have hT : det ![t₁, t₂, t₃] = 0 :=
    det_eq_zero_of_dotProduct_eq_zero _ _ _ m hm
      (by rw [dotProduct_comm]; exact ht₁) (by rw [dotProduct_comm]; exact ht₂)
      (by rw [dotProduct_comm]; exact ht₃)
  rw [pappus_bracket_identity, hD, hT]
  ring

/-- The dual of Desargues, which is its converse. For genuine triangles `a b c` and `a' b' c'`
whose matching sides are distinct lines, if the meets of matching sides lie on one line, then
the lines through matching corners pass through one point: some point `o` lies on the line
through `a` and `a'`, on the line through `b` and `b'`, and on the line through `c` and `c'`,
so the triangles are in perspective from `o`. -/
theorem desargues_converse_sides_on_one_line_gives_perspective_from_a_point
    (a b c a' b' c' : Fin 3 → ℝ)
    (habc : det ![a, b, c] ≠ 0) (habc' : det ![a', b', c'] ≠ 0)
    (hP : (a ⨯₃ b) ⨯₃ (a' ⨯₃ b') ≠ 0) (hQ : (b ⨯₃ c) ⨯₃ (b' ⨯₃ c') ≠ 0)
    (hR : (c ⨯₃ a) ⨯₃ (c' ⨯₃ a') ≠ 0)
    (h : det ![(a ⨯₃ b) ⨯₃ (a' ⨯₃ b'), (b ⨯₃ c) ⨯₃ (b' ⨯₃ c'), (c ⨯₃ a) ⨯₃ (c' ⨯₃ a')] = 0) :
    ∃ o : Fin 3 → ℝ, o ≠ 0 ∧ det ![o, a, a'] = 0 ∧ det ![o, b, b'] = 0 ∧ det ![o, c, c'] = 0 := by
  rw [desargues_bracket_identity] at h
  have hL : det ![a ⨯₃ a', b ⨯₃ b', c ⨯₃ c'] = 0 := by
    rcases mul_eq_zero.mp h with h1 | h1
    · exact absurd h1 (mul_ne_zero habc habc')
    · exact h1
  obtain ⟨o, ho, hmul⟩ :=
    (Matrix.exists_mulVec_eq_zero_iff (M := Matrix.of ![a ⨯₃ a', b ⨯₃ b', c ⨯₃ c'])).mpr hL
  have h0 := congrFun hmul 0
  have h1 := congrFun hmul 1
  have h2 := congrFun hmul 2
  simp [mulVec] at h0 h1 h2
  refine ⟨o, ho, ?_, ?_, ?_⟩
  · rw [← triple_product_eq_det, dotProduct_comm]; exact h0
  · rw [← triple_product_eq_det, dotProduct_comm]; exact h1
  · rw [← triple_product_eq_det, dotProduct_comm]; exact h2

-- The card's triangles: A = (1 : 0 : 1), B = (0 : 1 : 1), C = (1 : 2 : 1) and
-- A' = (2 : 0 : 1), B' = (0 : 3 : 1), C' = (3/2, 3) = (3 : 6 : 2), in perspective from O = (0 : 0 : 1).
example : det !![(0 : ℚ), 0, 1; 1, 0, 1; 2, 0, 1] = 0 ∧
    det !![(0 : ℚ), 0, 1; 0, 1, 1; 0, 3, 1] = 0 ∧
    det !![(0 : ℚ), 0, 1; 1, 2, 1; 3, 6, 2] = 0 := by
  norm_num [det_fin_three]
-- Meets of matching sides by cross products: P = (-4 : 3 : -1) = (4, -3),
-- Q = (-6 : -9 : -3) = (2, 3), R = (2 : 12 : 2) = (1, 6).
example : (![(1 : ℚ), 0, 1] ⨯₃ ![0, 1, 1]) ⨯₃ (![2, 0, 1] ⨯₃ ![0, 3, 1]) = ![-4, 3, -1] := by
  norm_num [cross_apply]
example : (![(0 : ℚ), 1, 1] ⨯₃ ![1, 2, 1]) ⨯₃ (![0, 3, 1] ⨯₃ ![3, 6, 2]) = ![-6, -9, -3] := by
  norm_num [cross_apply]
example : (![(1 : ℚ), 2, 1] ⨯₃ ![1, 0, 1]) ⨯₃ (![3, 6, 2] ⨯₃ ![2, 0, 1]) = ![2, 12, 2] := by
  norm_num [cross_apply]
-- P, Q, R share a line: determinant 0, and slope -3 from P to Q and from Q to R.
example : det !![(-4 : ℚ), 3, -1; -6, -9, -3; 2, 12, 2] = 0 := by
  norm_num [det_fin_three]
example : ((3 : ℚ) - (-3)) / (2 - 4) = -3 ∧ ((6 : ℚ) - 3) / (1 - 2) = -3 := by norm_num
-- Road 2, rescaled corners: a - a' = b - b' = c - c' = (0, 0, 2), and
-- a - b = (4, -3, 1), b - c = (-6, -9, -3), c - a = (2, 12, 2), which add to zero.
example : ![(4 : ℚ), 0, 4] - ![4, 0, 2] = ![0, 0, 2] ∧ ![(0 : ℚ), 3, 3] - ![0, 3, 1] = ![0, 0, 2] ∧
    ![(6 : ℚ), 12, 6] - ![6, 12, 4] = ![0, 0, 2] := by
  refine ⟨?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;> norm_num
example : ![(4 : ℚ), 0, 4] - ![0, 3, 3] = ![4, -3, 1] ∧ ![(0 : ℚ), 3, 3] - ![6, 12, 6] = ![-6, -9, -3] ∧
    ![(6 : ℚ), 12, 6] - ![4, 0, 4] = ![2, 12, 2] := by
  refine ⟨?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;> norm_num
-- The dual: the lines through matching corners, (-36 : 18 : 0), (0 : 18 : 0), (-36 : 0 : 0),
-- have determinant 0 and pass through the centre (0, 0).
example : det !![(-36 : ℚ), 18, 0; 0, 18, 0; -36, 0, 0] = 0 := by
  norm_num [det_fin_three]
example : ![(-36 : ℚ), 18, 0] ⬝ᵥ ![0, 0, 1] = 0 ∧ ![(0 : ℚ), 18, 0] ⬝ᵥ ![0, 0, 1] = 0 ∧
    ![(-36 : ℚ), 0, 0] ⬝ᵥ ![0, 0, 1] = 0 := by
  norm_num [dotProduct, Fin.sum_univ_succ]
-- Pappus: x = 0, 1, 3 on y = 0 and x = 0, 2, 5 on y = 2. The crossings are
-- M12 = (4 : 4 : 6) = (2/3, 2/3), M13 = (30 : 12 : 16) = (15/8, 3/4), M23 = (26 : 8 : 10) = (13/5, 4/5).
example : (![(0 : ℚ), 0, 1] ⨯₃ ![2, 2, 1]) ⨯₃ (![1, 0, 1] ⨯₃ ![0, 2, 1]) = ![4, 4, 6] := by
  norm_num [cross_apply]
example : (![(0 : ℚ), 0, 1] ⨯₃ ![5, 2, 1]) ⨯₃ (![3, 0, 1] ⨯₃ ![0, 2, 1]) = ![30, 12, 16] := by
  norm_num [cross_apply]
example : (![(1 : ℚ), 0, 1] ⨯₃ ![5, 2, 1]) ⨯₃ (![3, 0, 1] ⨯₃ ![2, 2, 1]) = ![26, 8, 10] := by
  norm_num [cross_apply]
example : det !![(4 : ℚ), 4, 6; 30, 12, 16; 26, 8, 10] = 0 := by
  norm_num [det_fin_three]
-- Slope 2/29 from M12 to M13 and from M13 to M23.
example : ((3/4 : ℚ) - 2/3) / (15/8 - 2/3) = 2/29 ∧ ((4/5 : ℚ) - 3/4) / (13/5 - 15/8) = 2/29 := by
  norm_num
-- Pappus road 2: V = (0, 0, 0), (2, 2, 3), (15, 6, 8); V2 - V1, V3 - V1, V3 - V2 name the crossings.
example : ![(2 : ℚ), 2, 3] - ![0, 0, 0] = ![2, 2, 3] ∧ ![(15 : ℚ), 6, 8] - ![0, 0, 0] = ![15, 6, 8] ∧
    ![(15 : ℚ), 6, 8] - ![2, 2, 3] = ![13, 4, 5] := by
  refine ⟨?_, ?_, ?_⟩ <;> ext i <;> fin_cases i <;> norm_num
example : (2 : ℚ) / 3 = 4 / 6 ∧ (15 : ℚ) / 8 = 30 / 16 ∧ (6 : ℚ) / 8 = 12 / 16 ∧
    (13 : ℚ) / 5 = 26 / 10 ∧ (4 : ℚ) / 5 = 8 / 10 := by norm_num
-- Mistake: mismatched sides (AB with C'A', BC with A'B', CA with B'C') give (11/5, -6/5),
-- (4/5, 9/5) and (1, 3): determinant not 0, slopes -15/7 and 6, no shared line.
example : (![(1 : ℚ), 0, 1] ⨯₃ ![0, 1, 1]) ⨯₃ (![3, 6, 2] ⨯₃ ![2, 0, 1]) = ![11, -6, 5] := by
  norm_num [cross_apply]
example : (![(0 : ℚ), 1, 1] ⨯₃ ![1, 2, 1]) ⨯₃ (![2, 0, 1] ⨯₃ ![0, 3, 1]) = ![4, 9, 5] := by
  norm_num [cross_apply]
example : (![(1 : ℚ), 2, 1] ⨯₃ ![1, 0, 1]) ⨯₃ (![0, 3, 1] ⨯₃ ![3, 6, 2]) = ![6, 18, 6] := by
  norm_num [cross_apply]
example : det !![(11 : ℚ), -6, 5; 4, 9, 5; 6, 18, 6] ≠ 0 := by
  norm_num [det_fin_three]
example : ((9/5 : ℚ) - (-6/5)) / (4/5 - 11/5) = -15/7 ∧ ((3 : ℚ) - 9/5) / (1 - 4/5) = 6 := by
  norm_num

#print axioms desargues_perspective_triangles_sides_meet_on_one_line
#print axioms pappus_cross_joins_meet_on_one_line
#print axioms desargues_converse_sides_on_one_line_gives_perspective_from_a_point
