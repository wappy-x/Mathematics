-- The ellipsoid method: a central cut's half-ball lies inside the wrap, each update keeps the shape matrix positive definite and multiplies its determinant by ρ_n², and the volume factor ρ_n is below exp(-1/(2(n+1))).
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.SchurComplement
import Mathlib.Algebra.Order.Star.Real

open Matrix

/-- Symmetry of the bilinear form of a symmetric real matrix. -/
theorem ellipsoid_dot_mulVec_symm {n : ℕ} (P : Matrix (Fin n) (Fin n) ℝ) (hP : Pᵀ = P)
    (x y : Fin n → ℝ) : x ⬝ᵥ (P *ᵥ y) = y ⬝ᵥ (P *ᵥ x) := by
  rw [dotProduct_mulVec, ← mulVec_transpose, hP, dotProduct_comm]

/-- Cauchy–Schwarz for a positive semidefinite real form. -/
theorem ellipsoid_cauchy_schwarz {n : ℕ} (P : Matrix (Fin n) (Fin n) ℝ) (hP : P.PosDef)
    (a x : Fin n → ℝ) :
    (a ⬝ᵥ (P *ᵥ x)) ^ 2 ≤ (a ⬝ᵥ (P *ᵥ a)) * (x ⬝ᵥ (P *ᵥ x)) := by
  have hT : Pᵀ = P := hP.isHermitian.eq
  set A := a ⬝ᵥ (P *ᵥ a)
  set B := a ⬝ᵥ (P *ᵥ x)
  set C := x ⬝ᵥ (P *ᵥ x)
  have hsym : x ⬝ᵥ (P *ᵥ a) = B := ellipsoid_dot_mulVec_symm P hT x a
  have hA : 0 ≤ A := by
    have := hP.posSemidef.dotProduct_mulVec_nonneg a
    simpa using this
  let y : Fin n → ℝ := A • x - B • a
  have hy : 0 ≤ y ⬝ᵥ (P *ᵥ y) := by
    have := hP.posSemidef.dotProduct_mulVec_nonneg y
    simpa using this
  have e : y ⬝ᵥ (P *ᵥ y) = A * (A * C - B ^ 2) := by
    simp only [y, mulVec_sub, mulVec_smul, dotProduct_sub, sub_dotProduct, dotProduct_smul,
      smul_dotProduct, smul_eq_mul]
    rw [hsym]
    ring
  rw [e] at hy
  rcases hA.lt_or_eq with hA' | hA'
  · nlinarith [(mul_nonneg_iff_of_pos_left hA').mp hy]
  · -- A = 0 forces a = 0
    have ha : a = 0 := by
      by_contra h
      have := hP.dotProduct_mulVec_pos h
      simp at this
      exact absurd hA'.symm (ne_of_gt this)
    subst ha
    have hB : B = 0 := by simp [B]
    rw [hB, ← hA']
    simp

#print axioms ellipsoid_dot_mulVec_symm
#print axioms ellipsoid_cauchy_schwarz

/-- The detailed proof on the card: cut the unit ball of `ℝⁿ` through its centre along a unit
direction `v`, keeping the half `⟪v, u⟫ ≤ 0`. Every point `u` of that half-ball passes the test of
the wrap, the ellipsoid with centre `-v/(n+1)`, half-axis `n/(n+1)` along `v` and `n/√(n²-1)`
across:
`((n+1)/n)² (⟪v,u⟫ + 1/(n+1))² + ((n²-1)/n²) (‖u‖² - ⟪v,u⟫²) ≤ 1`. -/
theorem half_ball_subset_ellipsoid_wrap {n : ℕ} (v u : EuclideanSpace ℝ (Fin n))
    (hv : ‖v‖ = 1) (hu : ‖u‖ ≤ 1) (hcut : inner ℝ v u ≤ 0) :
    (((n : ℝ) + 1) / n) ^ 2 * (inner ℝ v u + 1 / ((n : ℝ) + 1)) ^ 2
      + (((n : ℝ) ^ 2 - 1) / (n : ℝ) ^ 2) * (‖u‖ ^ 2 - (inner ℝ v u) ^ 2) ≤ 1 := by
  have hn : (1 : ℝ) ≤ n := by
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h
      have : v = 0 := Subsingleton.elim _ _
      simp [this] at hv
    · exact_mod_cast h
  set t := inner ℝ v u with ht
  have habs : |t| ≤ 1 := by
    calc |t| ≤ ‖v‖ * ‖u‖ := abs_real_inner_le_norm v u
      _ ≤ 1 := by rw [hv, one_mul]; exact hu
  have ht1 : -1 ≤ t := (abs_le.mp habs).1
  have hsq : t ^ 2 ≤ ‖u‖ ^ 2 := by
    have : |t| ≤ ‖u‖ := by
      calc |t| ≤ ‖v‖ * ‖u‖ := abs_real_inner_le_norm v u
        _ = ‖u‖ := by rw [hv, one_mul]
    have h0 : 0 ≤ |t| := abs_nonneg _
    calc t ^ 2 = |t| ^ 2 := (sq_abs t).symm
      _ ≤ ‖u‖ ^ 2 := pow_le_pow_left₀ h0 this 2
  have hs1 : ‖u‖ ^ 2 ≤ 1 := by
    have := norm_nonneg u
    nlinarith
  have hn0 : (0 : ℝ) < n := by linarith
  have hn1 : (0 : ℝ) < (n : ℝ) + 1 := by linarith
  have key : (((n : ℝ) + 1) / n) ^ 2 * (t + 1 / ((n : ℝ) + 1)) ^ 2
      + (((n : ℝ) ^ 2 - 1) / (n : ℝ) ^ 2) * (‖u‖ ^ 2 - t ^ 2)
      = ((((n : ℝ) + 1) * t + 1) ^ 2 + ((n : ℝ) ^ 2 - 1) * (‖u‖ ^ 2 - t ^ 2)) / (n : ℝ) ^ 2 := by
    field_simp
  rw [key, div_le_one (by positivity)]
  have h2 : 0 ≤ (n : ℝ) ^ 2 - 1 := by nlinarith
  have h3 : ((n : ℝ) ^ 2 - 1) * (‖u‖ ^ 2 - t ^ 2) ≤ ((n : ℝ) ^ 2 - 1) * (1 - t ^ 2) :=
    mul_le_mul_of_nonneg_left (by linarith) h2
  nlinarith [mul_nonneg (neg_nonneg.mpr hcut) (show 0 ≤ t + 1 by linarith)]

/-- The update in The formula: for a positive definite shape matrix `P` and a cut row `a ≠ 0`, with
`d = P a / √(aᵀ P a)` and `P' = n²/(n²-1) (P - 2/(n+1) d dᵀ)`, the new shape matrix `P'` is again
positive definite, and `det P' = ρ_n² det P` where `ρ_n² = (n/(n+1))² (n²/(n²-1))^(n-1)`. Since
volume is proportional to `√det`, each cut multiplies the volume by `ρ_n`. -/
theorem ellipsoid_update_posDef_and_det {n : ℕ} (hn : 2 ≤ n) (P : Matrix (Fin n) (Fin n) ℝ)
    (hP : P.PosDef) (a : Fin n → ℝ) (ha : a ≠ 0) :
    let d : Fin n → ℝ := (Real.sqrt (a ⬝ᵥ (P *ᵥ a)))⁻¹ • (P *ᵥ a)
    let P' : Matrix (Fin n) (Fin n) ℝ :=
      ((n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1)) • (P - (2 / ((n : ℝ) + 1)) • vecMulVec d d)
    P'.PosDef ∧
      P'.det = ((n : ℝ) / ((n : ℝ) + 1)) ^ 2 * ((n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1)) ^ (n - 1) * P.det := by
  intro d P'
  have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have hn1 : (0 : ℝ) < (n : ℝ) + 1 := by linarith
  have hq1 : (0 : ℝ) < (n : ℝ) ^ 2 - 1 := by nlinarith
  have hT : Pᵀ = P := hP.isHermitian.eq
  set q := a ⬝ᵥ (P *ᵥ a) with hq_def
  have hq : 0 < q := by
    have := hP.dotProduct_mulVec_pos ha
    simpa using this
  set s := Real.sqrt q with hs_def
  have hs : 0 < s := Real.sqrt_pos.mpr hq
  have hss : s * s = q := Real.mul_self_sqrt hq.le
  set k : ℝ := 2 / ((n : ℝ) + 1) with hk_def
  have hk0 : 0 < k := by positivity
  have hk1 : k < 1 := by rw [hk_def, div_lt_one hn1]; linarith
  set c : ℝ := (n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1) with hc_def
  have hc : 0 < c := by positivity
  set M : Matrix (Fin n) (Fin n) ℝ := P - k • vecMulVec d d with hM_def
  have hdx : ∀ x : Fin n → ℝ, d ⬝ᵥ x = s⁻¹ * (a ⬝ᵥ (P *ᵥ x)) := by
    intro x
    have hd : d = s⁻¹ • (P *ᵥ a) := rfl
    rw [hd, smul_dotProduct, smul_eq_mul, dotProduct_comm (P *ᵥ a) x,
      ellipsoid_dot_mulVec_symm P hT x a]
  constructor
  · -- positive definiteness
    have hMd : M.PosDef := by
      refine PosDef.of_dotProduct_mulVec_pos ?_ ?_
      · have h1 : (vecMulVec d d)ᴴ = vecMulVec d d := by
          rw [conjTranspose_eq_transpose_of_trivial, transpose_vecMulVec]
        have h2 : Pᴴ = P := hP.isHermitian.eq
        show (P - k • vecMulVec d d)ᴴ = P - k • vecMulVec d d
        rw [conjTranspose_sub, conjTranspose_smul, h1, h2, star_trivial]
      · intro x hx
        rw [star_trivial]
        have hC := hP.dotProduct_mulVec_pos hx
        rw [star_trivial] at hC
        have hCS := ellipsoid_cauchy_schwarz P hP a x
        rw [← hq_def] at hCS
        have e : x ⬝ᵥ (M *ᵥ x) = x ⬝ᵥ (P *ᵥ x) - k * (d ⬝ᵥ x) ^ 2 := by
          simp only [hM_def, sub_mulVec, smul_mulVec, vecMulVec_mulVec, dotProduct_sub,
            dotProduct_smul, smul_eq_mul, op_smul_eq_smul]
          rw [dotProduct_comm x d]
          ring
        rw [e, hdx x]
        set B := a ⬝ᵥ (P *ᵥ x)
        set C := x ⬝ᵥ (P *ᵥ x)
        have e2 : (s⁻¹ * B) ^ 2 = B ^ 2 / q := by
          rw [mul_pow, inv_pow, ← hss]; ring
        rw [e2]
        have h3 : B ^ 2 / q ≤ C := by rw [div_le_iff₀ hq]; linarith
        nlinarith
    exact hMd.smul hc
  · -- determinant
    let w : Fin n → ℝ := (-(k * s⁻¹)) • a
    have hPw : P *ᵥ w = -k • d := by
      simp only [w, d, mulVec_smul, smul_smul, neg_mul]
      rfl
    have hfac : M = P * (1 + vecMulVec w d) := by
      rw [Matrix.mul_add, Matrix.mul_one, mul_vecMulVec, hPw, smul_vecMulVec, neg_smul,
        ← sub_eq_add_neg]
    have hdw : d ⬝ᵥ w = -k := by
      simp only [w, dotProduct_smul, smul_eq_mul]
      rw [hdx a, ← hq_def]
      field_simp
      rw [← hss]
      ring
    have hdet1 : (1 + vecMulVec w d).det = 1 - k := by
      rw [vecMulVec_eq Unit, det_one_add_replicateCol_mul_replicateRow, hdw]
      ring
    have hM : M.det = (1 - k) * P.det := by
      rw [hfac, det_mul, hdet1, mul_comm]
    show (c • M).det = _
    rw [det_smul, hM, Fintype.card_fin]
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
    rw [Nat.add_sub_cancel, pow_succ]
    simp only [hc_def, hk_def]
    push_cast
    have : ((m : ℝ) + 1) ^ 2 - 1 ≠ 0 := by push_cast at hq1; exact hq1.ne'
    have : ((m : ℝ) + 1) + 1 ≠ 0 := by push_cast at hn1; exact hn1.ne'
    field_simp
    ring

/-- Step 4: in every dimension `n ≥ 2` the volume factor
`ρ_n = n/(n+1) · (n²/(n²-1))^((n-1)/2)` is below `exp(-1/(2(n+1)))`, hence below one. -/
theorem ellipsoid_volume_factor_lt_exp {n : ℕ} (hn : 2 ≤ n) :
    (n : ℝ) / ((n : ℝ) + 1) * ((n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1)) ^ (((n : ℝ) - 1) / 2)
      < Real.exp (-1 / (2 * ((n : ℝ) + 1))) := by
  have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have hn1 : (0 : ℝ) < (n : ℝ) + 1 := by linarith
  have hq : (0 : ℝ) < (n : ℝ) ^ 2 - 1 := by nlinarith
  have h1 : (n : ℝ) / ((n : ℝ) + 1) < Real.exp (-1 / ((n : ℝ) + 1)) := by
    have hne : -1 / ((n : ℝ) + 1) ≠ 0 := by
      have : (0 : ℝ) < 1 / ((n : ℝ) + 1) := by positivity
      intro h; rw [neg_div] at h; linarith
    have := Real.add_one_lt_exp hne
    have e : (n : ℝ) / ((n : ℝ) + 1) = -1 / ((n : ℝ) + 1) + 1 := by field_simp; ring
    rw [e]; exact this
  have h2 : ((n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1)) ^ (((n : ℝ) - 1) / 2)
      ≤ Real.exp (1 / (2 * ((n : ℝ) + 1))) := by
    have hb : (n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1) ≤ Real.exp (1 / ((n : ℝ) ^ 2 - 1)) := by
      have e : (n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1) = 1 / ((n : ℝ) ^ 2 - 1) + 1 := by
        field_simp; ring
      rw [e]; exact Real.add_one_le_exp _
    have hexp : (0 : ℝ) ≤ ((n : ℝ) - 1) / 2 := by
      have : (0 : ℝ) ≤ (n : ℝ) - 1 := by linarith
      positivity
    calc ((n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1)) ^ (((n : ℝ) - 1) / 2)
        ≤ (Real.exp (1 / ((n : ℝ) ^ 2 - 1))) ^ (((n : ℝ) - 1) / 2) :=
          Real.rpow_le_rpow (by positivity) hb hexp
      _ = Real.exp (1 / ((n : ℝ) ^ 2 - 1) * (((n : ℝ) - 1) / 2)) := (Real.exp_mul _ _).symm
      _ = Real.exp (1 / (2 * ((n : ℝ) + 1))) := by
          congr 1
          have : (n : ℝ) ^ 2 - 1 = ((n : ℝ) - 1) * ((n : ℝ) + 1) := by ring
          rw [this]
          have : (0 : ℝ) < (n : ℝ) - 1 := by linarith
          field_simp
  have hpos1 : (0 : ℝ) < (n : ℝ) / ((n : ℝ) + 1) := by
    have : (0 : ℝ) < n := by linarith
    positivity
  have hpos2 : (0 : ℝ) < ((n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1)) ^ (((n : ℝ) - 1) / 2) := by
    apply Real.rpow_pos_of_pos; positivity
  calc (n : ℝ) / ((n : ℝ) + 1) * ((n : ℝ) ^ 2 / ((n : ℝ) ^ 2 - 1)) ^ (((n : ℝ) - 1) / 2)
      < Real.exp (-1 / ((n : ℝ) + 1)) * Real.exp (1 / (2 * ((n : ℝ) + 1))) :=
        mul_lt_mul h1 h2 hpos2 (Real.exp_pos _).le
    _ = Real.exp (-1 / (2 * ((n : ℝ) + 1))) := by
        rw [← Real.exp_add]; congr 1; field_simp; ring

-- In two dimensions ρ₂² = (2/3)² · (4/3) = 16/27, so ρ₂ = (2/3)√(4/3).
example : ((2 : ℚ) / (2 + 1)) ^ 2 * ((2 : ℚ) ^ 2 / ((2 : ℚ) ^ 2 - 1)) ^ (2 - 1) = 16 / 27 := by norm_num

-- The first cut at target £900: aᵀ P₀ a = 10000 · (19² + 20²) = 7610000.
example : (10000 : ℤ) * ((-19) ^ 2 + (-20) ^ 2) = 7610000 := by norm_num

-- The best plan, 32 tables and 16 chairs: timber 160 m, labour 112 h ≤ 120, finish 64 l, profit £928.
example : 4 * 32 + 2 * 16 = 160 ∧ 3 * 32 + 1 * 16 ≤ 120 ∧ 1 * 32 + 2 * 16 = 64 ∧ 19 * 32 + 20 * 16 = 928 := by
  norm_num

-- The prices y = (3, 0, 7) cover each product's profit and value the stock at £928.
example : 3 * 4 + 0 * 3 + 7 * 1 = 19 ∧ 3 * 2 + 0 * 1 + 7 * 2 = 20 ∧ 3 * 160 + 0 * 120 + 7 * 64 = 928 := by
  norm_num

-- With slack ε = 1/20 the loosened £929 question is empty: 928 + 10ε < 929 - ε, as 11ε < 1.
example : (928 : ℚ) + 10 * (1 / 20) < 929 - 1 / 20 ∧ 11 * ((1 : ℚ) / 20) < 1 := by norm_num

-- The corners of the plans earning at least £900: (100/3, 40/3) and (260/9, 158/9) earn exactly £900,
-- the first on the timber line, the second on the finish line.
example : (19 : ℚ) * (100 / 3) + 20 * (40 / 3) = 900 ∧ (4 : ℚ) * (100 / 3) + 2 * (40 / 3) = 160 ∧
    (19 : ℚ) * (260 / 9) + 20 * (158 / 9) = 900 ∧ (260 : ℚ) / 9 + 2 * (158 / 9) = 64 := by norm_num

-- That triangle, with third corner (32, 16), has area 28/9 = 3.1111.
example : |((100 : ℚ) / 3 - 32) * (158 / 9 - 16) - (40 / 3 - 16) * (260 / 9 - 32)| / 2 = 28 / 9 := by
  norm_num

-- Bisection from the bracket [0, 2759] needs twelve questions: 2^11 < 2759 ≤ 2^12.
example : 2 ^ 11 < 2759 ∧ 2759 ≤ 2 ^ 12 := by norm_num

#print axioms half_ball_subset_ellipsoid_wrap
#print axioms ellipsoid_update_posDef_and_det
#print axioms ellipsoid_volume_factor_lt_exp
