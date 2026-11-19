-- Moduli spaces in outline: over an algebraically closed field with 2 and 3 not zero, the j-invariant matches smooth curves y^2 = x^3 + ax + b up to rescaling one for one with the field's numbers, and the Plücker coordinates of a line satisfy the Plücker relation and their meeting form vanishes exactly when two lines meet.
import Mathlib.FieldTheory.IsAlgClosed.Basic
import Mathlib.LinearAlgebra.LinearIndependent.Basic
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.LinearAlgebra.Span.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum

/-- The j-invariant of y^2 = x^3 + ax + b, as on the card: 1728 · 4a^3 / (4a^3 + 27b^2).
(For a short Weierstrass curve this is Mathlib's `WeierstrassCurve.j`, which is c₄^3/Δ.) -/
def jInv {K : Type*} [Field K] (a b : K) : K :=
  1728 * (4 * a ^ 3) / (4 * a ^ 3 + 27 * b ^ 2)

/-- The six Plücker coordinates (p₁₂, p₁₃, p₁₄, p₂₃, p₂₄, p₃₄) of the line through the points
u and v of projective 3-space: p_il = u_i v_l - u_l v_i. -/
def plucker {R : Type*} [CommRing R] (u v : Fin 4 → R) : Fin 6 → R :=
  ![u 0 * v 1 - u 1 * v 0, u 0 * v 2 - u 2 * v 0, u 0 * v 3 - u 3 * v 0,
    u 1 * v 2 - u 2 * v 1, u 1 * v 3 - u 3 * v 1, u 2 * v 3 - u 3 * v 2]

/-- The meeting form of two lists of Plücker coordinates:
p₁₂p'₃₄ - p₁₃p'₂₄ + p₁₄p'₂₃ + p₂₃p'₁₄ - p₂₄p'₁₃ + p₃₄p'₁₂. -/
def meet {R : Type*} [CommRing R] (p p' : Fin 6 → R) : R :=
  p 0 * p' 5 - p 1 * p' 4 + p 2 * p' 3 + p 3 * p' 2 - p 4 * p' 1 + p 5 * p' 0

/-- Helper: the meeting form of two Plücker lists is the 4 × 4 determinant with rows u, v, u', v'. -/
theorem meet_plucker_eq_det {R : Type*} [CommRing R] (u v u' v' : Fin 4 → R) :
    meet (plucker u v) (plucker u' v') = Matrix.det (Matrix.of ![u, v, u', v']) := by
  have e1 : Fin.succAbove (1 : Fin 4) 2 = 3 := rfl
  have e2 : Fin.succAbove (2 : Fin 4) 2 = 3 := rfl
  have e3 : Fin.succAbove (3 : Fin 4) 2 = 2 := rfl
  rw [Matrix.det_succ_row_zero]
  simp [Fin.sum_univ_succ, Matrix.det_fin_three, Matrix.submatrix, meet, plucker, e1, e2, e3]
  ring

#print axioms meet_plucker_eq_det

/-- The j-line. Over a field where every polynomial has a root (like ℂ) and 2, 3 are not
zero: two smooth curves y^2 = x^3 + ax + b and y^2 = x^3 + a'x + b' (smooth meaning
4a^3 + 27b^2 ≠ 0) have the same j exactly when a rescaling x = u^2 X, y = u^3 Y with u ≠ 0
turns one into the other, that is a' = a/u^4 and b' = b/u^6; and every number j is the
j-invariant of some smooth curve. So j matches the curves, counted once up to rescaling,
one for one with the numbers. -/
theorem j_line_classifies_elliptic_curves {K : Type*} [Field K] [IsAlgClosed K]
    (h2 : (2 : K) ≠ 0) (h3 : (3 : K) ≠ 0) :
    (∀ a b a' b' : K, 4 * a ^ 3 + 27 * b ^ 2 ≠ 0 → 4 * a' ^ 3 + 27 * b' ^ 2 ≠ 0 →
      (jInv a b = jInv a' b' ↔ ∃ u : K, u ≠ 0 ∧ a' = a / u ^ 4 ∧ b' = b / u ^ 6)) ∧
    (∀ j : K, ∃ a b : K, 4 * a ^ 3 + 27 * b ^ 2 ≠ 0 ∧ jInv a b = j) := by
  have h1728 : (1728 : K) ≠ 0 := by
    have : (1728 : K) = 2 ^ 6 * 3 ^ 3 := by norm_num
    rw [this]; exact mul_ne_zero (pow_ne_zero _ h2) (pow_ne_zero _ h3)
  have h4 : (4 : K) ≠ 0 := by
    have : (4 : K) = 2 ^ 2 := by norm_num
    rw [this]; exact pow_ne_zero _ h2
  have h27 : (27 : K) ≠ 0 := by
    have : (27 : K) = 3 ^ 3 := by norm_num
    rw [this]; exact pow_ne_zero _ h3
  refine ⟨fun a b a' b' hD hD' => ?_, fun j => ?_⟩
  · constructor
    · intro hj
      unfold jInv at hj
      rw [div_eq_div_iff hD hD'] at hj
      have key : a ^ 3 * b' ^ 2 = a' ^ 3 * b ^ 2 := by
        have h0 : (1728 * 4 * 27 : K) * (a ^ 3 * b' ^ 2 - a' ^ 3 * b ^ 2) = 0 := by
          linear_combination hj
        have hne : (1728 * 4 * 27 : K) ≠ 0 := mul_ne_zero (mul_ne_zero h1728 h4) h27
        linear_combination (mul_eq_zero.1 h0).resolve_left hne
      by_cases ha : a = 0
      · have hb : b ≠ 0 := by rintro rfl; apply hD; simp [ha]
        have ha' : a' = 0 := by
          have e : a' ^ 3 * b ^ 2 = 0 := by rw [← key, ha]; ring
          exact pow_eq_zero_iff (n := 3) (by norm_num) |>.mp
            ((mul_eq_zero.1 e).resolve_right (pow_ne_zero _ hb))
        have hb' : b' ≠ 0 := by rintro rfl; apply hD'; simp [ha']
        obtain ⟨u, hu⟩ := IsAlgClosed.exists_pow_nat_eq (b / b') (by norm_num : 0 < 6)
        have hu0 : u ≠ 0 := by
          rintro rfl; rw [zero_pow (by norm_num)] at hu; exact div_ne_zero hb hb' hu.symm
        refine ⟨u, hu0, by simp [ha, ha'], ?_⟩
        rw [hu]; field_simp
      by_cases hb : b = 0
      · have hb' : b' = 0 := by
          have e : a ^ 3 * b' ^ 2 = 0 := by rw [key, hb]; ring
          exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp
            ((mul_eq_zero.1 e).resolve_left (pow_ne_zero _ ha))
        have ha' : a' ≠ 0 := by rintro rfl; apply hD'; simp [hb']
        obtain ⟨u, hu⟩ := IsAlgClosed.exists_pow_nat_eq (a / a') (by norm_num : 0 < 4)
        have hu0 : u ≠ 0 := by
          rintro rfl; rw [zero_pow (by norm_num)] at hu; exact div_ne_zero ha ha' hu.symm
        refine ⟨u, hu0, ?_, by simp [hb, hb']⟩
        rw [hu]; field_simp
      have ha' : a' ≠ 0 := by
        intro ha'
        have e : a ^ 3 * b' ^ 2 = 0 := by rw [key, ha']; ring
        have hb' : b' = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp
            ((mul_eq_zero.1 e).resolve_left (pow_ne_zero _ ha))
        apply hD'; simp [ha', hb']
      have hb' : b' ≠ 0 := by
        intro hb'
        have e : a' ^ 3 * b ^ 2 = 0 := by rw [← key, hb']; ring
        exact ha' (pow_eq_zero_iff (n := 3) (by norm_num) |>.mp
            ((mul_eq_zero.1 e).resolve_right (pow_ne_zero _ hb)))
      obtain ⟨u, hu⟩ := IsAlgClosed.exists_pow_nat_eq (b * a' / (b' * a)) (by norm_num : 0 < 2)
      have hu0 : u ≠ 0 := by
        rintro rfl; rw [zero_pow (by norm_num)] at hu
        exact div_ne_zero (mul_ne_zero hb ha') (mul_ne_zero hb' ha) hu.symm
      refine ⟨u, hu0, ?_, ?_⟩
      · rw [show u ^ 4 = (u ^ 2) ^ 2 by ring, hu]
        field_simp
        linear_combination -key
      · rw [show u ^ 6 = (u ^ 2) ^ 3 by ring, hu]
        field_simp
        linear_combination -key
    · rintro ⟨u, hu, rfl, rfl⟩
      unfold jInv
      rw [div_eq_div_iff hD hD']
      field_simp
  · by_cases hj0 : j = 0
    · exact ⟨0, 1, by simpa using h27, by simp [jInv, hj0]⟩
    by_cases hj1 : j = 1728
    · exact ⟨1, 0, by simpa using h4, by simp [jInv, hj1, h4]⟩
    have hk : (1728 - j) ≠ 0 := sub_ne_zero.2 (Ne.symm hj1)
    have hD : 4 * (3 * j * (1728 - j)) ^ 3 + 27 * (2 * j * (1728 - j) ^ 2) ^ 2
        = (4 * 27 * 1728) * j ^ 2 * (1728 - j) ^ 3 := by ring
    have hne : (4 * 27 * 1728 : K) * j ^ 2 * (1728 - j) ^ 3 ≠ 0 :=
      mul_ne_zero (mul_ne_zero (mul_ne_zero (mul_ne_zero h4 h27) h1728) (pow_ne_zero _ hj0))
        (pow_ne_zero _ hk)
    refine ⟨3 * j * (1728 - j), 2 * j * (1728 - j) ^ 2, hD ▸ hne, ?_⟩
    rw [jInv, hD, div_eq_iff hne]
    ring

/-- The Plücker relation: the Plücker coordinates of the line through any two points u, v
satisfy p₁₂p₃₄ - p₁₃p₂₄ + p₁₄p₂₃ = 0, so every line is a point of the quadric G(2, 4). -/
theorem plucker_relation {R : Type*} [CommRing R] (u v : Fin 4 → R) :
    plucker u v 0 * plucker u v 5 - plucker u v 1 * plucker u v 4
      + plucker u v 2 * plucker u v 3 = 0 := by
  simp [plucker]
  ring

/-- Two lines meet exactly when their meeting form is zero: for the line through u, v and the
line through u', v' (each pair of points distinct, so linearly independent in K^4), the
meeting form of their Plücker coordinates is zero exactly when the two lines share a point,
that is when the planes spanned by u, v and by u', v' share a nonzero vector. -/
theorem meet_eq_zero_iff_lines_meet {K : Type*} [Field K] (u v u' v' : Fin 4 → K)
    (h : LinearIndependent K ![u, v]) (h' : LinearIndependent K ![u', v']) :
    meet (plucker u v) (plucker u' v') = 0 ↔
      Submodule.span K {u, v} ⊓ Submodule.span K {u', v'} ≠ ⊥ := by
  rw [meet_plucker_eq_det, ← Matrix.exists_vecMul_eq_zero_iff, Submodule.ne_bot_iff]
  rw [LinearIndependent.pair_iff] at h h'
  constructor
  · rintro ⟨c, hc, hcM⟩
    have key : (c 0 • u + c 1 • v) + (c 2 • u' + c 3 • v') = 0 := by
      ext j
      have := congrFun hcM j
      simp [Matrix.vecMul, dotProduct, Fin.sum_univ_four] at this ⊢
      linear_combination this
    refine ⟨c 0 • u + c 1 • v, Submodule.mem_inf.2 ⟨Submodule.mem_span_pair.2 ⟨_, _, rfl⟩,
      Submodule.mem_span_pair.2 ⟨-c 2, -c 3, ?_⟩⟩, ?_⟩
    · rw [neg_smul, neg_smul, eq_comm, ← neg_add]
      exact eq_neg_of_add_eq_zero_left key
    · intro h0
      obtain ⟨h00, h01⟩ := h _ _ h0
      have e2 : c 2 • u' + c 3 • v' = 0 := by rw [h0, zero_add] at key; exact key
      obtain ⟨h02, h03⟩ := h' _ _ e2
      apply hc
      ext i
      fin_cases i <;> simp [*]
  · rintro ⟨w, hw, hw0⟩
    obtain ⟨hw1, hw2⟩ := Submodule.mem_inf.1 hw
    obtain ⟨a, b, rfl⟩ := Submodule.mem_span_pair.1 hw1
    obtain ⟨c, d, hcd⟩ := Submodule.mem_span_pair.1 hw2
    refine ⟨![a, b, -c, -d], ?_, ?_⟩
    · intro h0
      apply hw0
      have ha : a = 0 := congrFun h0 0
      have hb : b = 0 := congrFun h0 1
      simp [ha, hb]
    · ext j
      have := congrFun hcd j
      simp [Matrix.vecMul, dotProduct, Fin.sum_univ_four] at this ⊢
      linear_combination -this

-- The main example, y^2 = x^3 - 11x + 14: 4a^3 = -5324, 27b^2 = 5292, sum -32, j = 287496 = 66^3.
example : 4 * (-11 : ℤ) ^ 3 = -5324 ∧ 27 * (14 : ℤ) ^ 2 = 5292 ∧ (-5324 : ℤ) + 5292 = -32 := by
  norm_num
example : jInv (-11 : ℚ) 14 = 287496 := by norm_num [jInv]
example : (287496 : ℕ) = 66 ^ 3 ∧ (8000 : ℕ) = 20 ^ 3 ∧ (1728 : ℕ) = 12 ^ 3 := by norm_num

-- The table's curves: y^2 = x^3 - 2 has j = 0, y^2 = x^3 - x has j = 1728, y^2 = x^3 - 30x + 56 has j = 8000.
example : jInv (0 : ℚ) (-2) = 0 ∧ jInv (-1 : ℚ) 0 = 1728 ∧ jInv (-30 : ℚ) 56 = 8000 := by
  norm_num [jInv]

-- The family E_j at j = 8000: a = 3jk, b = 2jk^2 with k = 1728 - j, and its j is 8000.
example : 3 * 8000 * (1728 - 8000 : ℤ) = -150528000 ∧
    2 * 8000 * (1728 - 8000 : ℤ) ^ 2 = 629407744000 := by norm_num
example : jInv (-150528000 : ℚ) 629407744000 = 8000 := by norm_num [jInv]

-- Rescaling with u^2 = 2240 turns E_8000 into y^2 = x^3 - 30x + 56.
example : (2240 : ℤ) ^ 2 = 5017600 ∧ (2240 : ℤ) ^ 3 = 11239424000 ∧
    (-150528000 : ℤ) = 2240 ^ 2 * (-30) ∧ (629407744000 : ℤ) = 2240 ^ 3 * 56 := by norm_num

-- The family y^2 = x^3 + tx + t at t = 1, 2, 5: j = 6912/31, 13824/35, 34560/47.
example : jInv (1 : ℚ) 1 = 6912 / 31 ∧ jInv (2 : ℚ) 2 = 13824 / 35 ∧
    jInv (5 : ℚ) 5 = 34560 / 47 := by norm_num [jInv]

-- The node y^2 = x^3 - 3x + 2 has 4a^3 + 27b^2 = 0, so no j.
example : 4 * (-3 : ℤ) ^ 3 + 27 * 2 ^ 2 = 0 := by norm_num

-- The twists y^2 = x^3 - 30x ± 56 have 18 and 6 points mod 11 (the point at infinity included).
example : ((Finset.univ : Finset (ZMod 11 × ZMod 11)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 - 30 * p.1 + 56)).card + 1 = 18 := by decide
example : ((Finset.univ : Finset (ZMod 11 × ZMod 11)).filter
    (fun p => p.2 ^ 2 = p.1 ^ 3 - 30 * p.1 - 56)).card + 1 = 6 := by decide

-- Line A through (1, 0, 0) and (0, 0, 1) has Plücker coordinates (0, 1, 1, 0, 0, -1);
-- through (2, 0, -1) and (-1, 0, 2) it gets three times that list.
example : plucker (R := ℤ) ![1, 0, 0, 1] ![0, 0, 1, 1] = ![0, 1, 1, 0, 0, -1] := by decide
example : plucker (R := ℤ) ![2, 0, -1, 1] ![-1, 0, 2, 1] = ![0, 3, 3, 0, 0, -3] := by decide

-- Line B through (0, 0, 0) and (0, -1, 1) has Plücker coordinates (0, 0, 0, 0, 1, -1).
example : plucker (R := ℤ) ![0, 0, 0, 1] ![0, -1, 1, 1] = ![0, 0, 0, 0, 1, -1] := by decide

-- The four given lines: pairwise meeting values 1, 1, 2, 2, 2, 12, none zero.
example :
    let L1 : Fin 6 → ℤ := ![0, 0, -1, 0, 0, 0]
    let L2 : Fin 6 → ℤ := ![0, 0, 0, -1, -1, 0]
    let L3 : Fin 6 → ℤ := ![1, -1, -3, -1, -2, -1]
    let L4 : Fin 6 → ℤ := ![-1, 1, -1, -2, -1, 3]
    [meet L1 L2, meet L1 L3, meet L1 L4, meet L2 L3, meet L2 L4, meet L3 L4] = [1, 1, 2, 2, 2, 12] := by
  decide

-- Lines A and B both meet all four given lines.
example :
    let L : List (Fin 6 → ℤ) := [![0, 0, -1, 0, 0, 0], ![0, 0, 0, -1, -1, 0],
      ![1, -1, -3, -1, -2, -1], ![-1, 1, -1, -2, -1, 3]]
    L.map (meet ![0, 1, 1, 0, 0, -1]) = [0, 0, 0, 0] ∧
      L.map (meet ![0, 0, 0, 0, 1, -1]) = [0, 0, 0, 0] := by
  decide

-- Over F_5: (p^2 + 1)(p^2 + p + 1) = 806 lines, against (p^6 - 1)/(p - 1) = 3906 points of P^5.
example : (5 ^ 2 + 1) * (5 ^ 2 + 5 + 1) = 806 ∧ (5 ^ 6 - 1) / (5 - 1) = 3906 := by norm_num

#print axioms j_line_classifies_elliptic_curves
#print axioms plucker_relation
#print axioms meet_eq_zero_iff_lines_meet
