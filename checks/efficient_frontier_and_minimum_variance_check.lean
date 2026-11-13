-- The efficient frontier: for a positive definite covariance matrix and expected returns that are not all equal, the least-variance fully invested portfolio for each target return is the unique two-fund blend given by the closed form, its variance is (A m² - 2 B m + C) / Δ, the global minimum-variance portfolio is Σ⁻¹1 / A with variance 1 / A and mean B / A, and only the targets above B / A are efficient.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Adjugate
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

lemma ef_pd_pos {ι : Type*} [Fintype ι] {M : Matrix ι ι ℝ} (hM : M.PosDef) {x : ι → ℝ}
    (hx : x ≠ 0) : 0 < x ⬝ᵥ (M *ᵥ x) := by
  simpa using hM.dotProduct_mulVec_pos hx

lemma ef_herm_dot {ι : Type*} [Fintype ι] {M : Matrix ι ι ℝ} (hM : M.IsHermitian)
    (v w : ι → ℝ) : v ⬝ᵥ (M *ᵥ w) = w ⬝ᵥ (M *ᵥ v) := by
  have hT : Mᵀ = M := by
    have := hM.eq
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  rw [dotProduct_mulVec, dotProduct_comm, ← mulVec_transpose, hT]

lemma ef_inv_cancel {ι : Type*} [Fintype ι] [DecidableEq ι] {S : Matrix ι ι ℝ} (hS : S.PosDef)
    (v : ι → ℝ) : S *ᵥ (S⁻¹ *ᵥ v) = v := by
  rw [mulVec_mulVec, mul_nonsing_inv (h := (isUnit_iff_isUnit_det S).mp hS.isUnit), one_mulVec]

lemma ef_strict_min {ι : Type*} [Fintype ι] {S : Matrix ι ι ℝ} (hS : S.PosDef)
    (w u : ι → ℝ) (hne : u ≠ w) (h : (u - w) ⬝ᵥ (S *ᵥ w) = 0) :
    w ⬝ᵥ (S *ᵥ w) < u ⬝ᵥ (S *ᵥ u) := by
  have hd : u - w ≠ 0 := sub_ne_zero.mpr hne
  have hpos := ef_pd_pos hS hd
  have hsym := ef_herm_dot hS.isHermitian w (u - w)
  have hu : u = w + (u - w) := by abel
  generalize u - w = d at hpos hsym hu h
  subst hu
  simp only [mulVec_add, dotProduct_add, add_dotProduct]
  linarith

lemma ef_mv_core {ι : Type*} [Fintype ι] [DecidableEq ι]
    (S : Matrix ι ι ℝ) (hS : S.PosDef) (μ one : ι → ℝ) (hone : one = fun _ => 1)
    (hμ : ∃ i j, μ i ≠ μ j) (A B C Δ m : ℝ) (hA : A = one ⬝ᵥ (S⁻¹ *ᵥ one))
    (hB : B = one ⬝ᵥ (S⁻¹ *ᵥ μ)) (hC : C = μ ⬝ᵥ (S⁻¹ *ᵥ μ)) (hΔ : Δ = A * C - B ^ 2)
    (w : ι → ℝ) (hw : w = ((C - B * m) / Δ) • (S⁻¹ *ᵥ one) + ((A * m - B) / Δ) • (S⁻¹ *ᵥ μ)) :
    0 < A ∧ 0 < Δ ∧ one ⬝ᵥ w = 1 ∧ μ ⬝ᵥ w = m ∧
      w ⬝ᵥ (S *ᵥ w) = (A * m ^ 2 - 2 * B * m + C) / Δ ∧
      ∀ u : ι → ℝ, one ⬝ᵥ u = 1 → μ ⬝ᵥ u = m → u ≠ w →
        w ⬝ᵥ (S *ᵥ w) < u ⬝ᵥ (S *ᵥ u) := by
  have hSP : ∀ v, S *ᵥ (S⁻¹ *ᵥ v) = v := ef_inv_cancel hS
  set P := S⁻¹ with hPdef
  have hP : P.PosDef := hS.inv
  have hsym : ∀ v w : ι → ℝ, v ⬝ᵥ (P *ᵥ w) = w ⬝ᵥ (P *ᵥ v) := ef_herm_dot hP.isHermitian
  obtain ⟨i, j, hij⟩ := hμ
  have hone_ne : one ≠ 0 := by
    intro h
    have := congrFun h i
    simp [hone] at this
  have hApos : 0 < A := hA ▸ ef_pd_pos hP hone_ne
  have hBμ : μ ⬝ᵥ (P *ᵥ one) = B := by rw [hB, hsym]
  have hx : A • μ - B • one ≠ 0 := by
    intro h
    have hi := congrFun h i
    have hj := congrFun h j
    simp [hone] at hi hj
    apply hij
    have : A * μ i = A * μ j := by linarith
    exact mul_left_cancel₀ hApos.ne' this
  have hq := ef_pd_pos hP hx
  have hexp : (A • μ - B • one) ⬝ᵥ (P *ᵥ (A • μ - B • one)) = A * (A * C - B ^ 2) := by
    simp only [mulVec_sub, mulVec_smul, dotProduct_sub, sub_dotProduct, dotProduct_smul,
      smul_dotProduct, smul_eq_mul]
    rw [hBμ, ← hA, ← hB, ← hC]
    ring
  have hΔpos : 0 < Δ := by
    rw [hΔ]
    rw [hexp] at hq
    exact pos_of_mul_pos_right hq hApos.le
  set a := (C - B * m) / Δ with ha
  set b := (A * m - B) / Δ with hb
  have hw1 : one ⬝ᵥ w = 1 := by
    rw [hw]
    simp only [dotProduct_add, dotProduct_smul, smul_eq_mul]
    rw [← hA, ← hB, ha, hb, div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div,
      div_eq_one_iff_eq hΔpos.ne', hΔ]
    ring
  have hwμ : μ ⬝ᵥ w = m := by
    rw [hw]
    simp only [dotProduct_add, dotProduct_smul, smul_eq_mul]
    rw [hBμ, ← hC, ha, hb, div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div,
      div_eq_iff hΔpos.ne', hΔ]
    ring
  have hSw : S *ᵥ w = a • one + b • μ := by
    rw [hw, mulVec_add, mulVec_smul, mulVec_smul, hSP, hSP]
  refine ⟨hApos, hΔpos, hw1, hwμ, ?_, ?_⟩
  · rw [hSw, dotProduct_add, dotProduct_smul, dotProduct_smul, smul_eq_mul, smul_eq_mul,
      dotProduct_comm w one, dotProduct_comm w μ, hw1, hwμ, ha, hb, mul_one,
      div_mul_eq_mul_div, ← add_div]
    congr 1
    ring
  · intro u hu1 hum hne
    apply ef_strict_min hS w u hne
    rw [hSw, dotProduct_add, dotProduct_smul, dotProduct_smul, smul_eq_mul, smul_eq_mul,
      sub_dotProduct, sub_dotProduct, dotProduct_comm u one, dotProduct_comm w one,
      dotProduct_comm u μ, dotProduct_comm w μ, hu1, hum, hw1, hwμ]
    ring

lemma ef_gmv_core {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (S : Matrix ι ι ℝ) (hS : S.PosDef) (μ one : ι → ℝ) (hone : one = fun _ => 1)
    (A B : ℝ) (hA : A = one ⬝ᵥ (S⁻¹ *ᵥ one)) (hB : B = one ⬝ᵥ (S⁻¹ *ᵥ μ))
    (wg : ι → ℝ) (hwg : wg = A⁻¹ • (S⁻¹ *ᵥ one)) :
    0 < A ∧ one ⬝ᵥ wg = 1 ∧ wg ⬝ᵥ (S *ᵥ wg) = 1 / A ∧ μ ⬝ᵥ wg = B / A ∧
      ∀ u : ι → ℝ, one ⬝ᵥ u = 1 → u ≠ wg → wg ⬝ᵥ (S *ᵥ wg) < u ⬝ᵥ (S *ᵥ u) := by
  have hSP : ∀ v, S *ᵥ (S⁻¹ *ᵥ v) = v := ef_inv_cancel hS
  set P := S⁻¹ with hPdef
  have hP : P.PosDef := hS.inv
  have hsym : ∀ v w : ι → ℝ, v ⬝ᵥ (P *ᵥ w) = w ⬝ᵥ (P *ᵥ v) := ef_herm_dot hP.isHermitian
  have hone_ne : one ≠ 0 := by
    intro h
    have := congrFun h (Classical.arbitrary ι)
    simp [hone] at this
  have hApos : 0 < A := hA ▸ ef_pd_pos hP hone_ne
  have hBμ : μ ⬝ᵥ (P *ᵥ one) = B := by rw [hB, hsym]
  have hw1 : one ⬝ᵥ wg = 1 := by
    rw [hwg, dotProduct_smul, smul_eq_mul, ← hA, inv_mul_cancel₀ hApos.ne']
  have hSw : S *ᵥ wg = A⁻¹ • one := by
    rw [hwg, mulVec_smul, hSP]
  refine ⟨hApos, hw1, ?_, ?_, ?_⟩
  · rw [hSw, dotProduct_smul, smul_eq_mul, dotProduct_comm, hw1, mul_one, one_div]
  · rw [hwg, dotProduct_smul, smul_eq_mul, hBμ, div_eq_inv_mul]
  · intro u hu1 hne
    apply ef_strict_min hS wg u hne
    rw [hSw, dotProduct_smul, smul_eq_mul, sub_dotProduct, dotProduct_comm u one,
      dotProduct_comm wg one, hu1, hw1]
    ring

/-- The minimum-variance portfolio for a target return `m`. Let `S` be the covariance matrix
(positive definite) and `μ` the expected returns (not all equal), with
`A = 1ᵀ S⁻¹ 1`, `B = 1ᵀ S⁻¹ μ`, `C = μᵀ S⁻¹ μ` and `Δ = A C - B²`. Then `Δ > 0`, and the blend
`w = ((C - B m) / Δ) S⁻¹ 1 + ((A m - B) / Δ) S⁻¹ μ` of the two fixed portfolios `S⁻¹ 1` and
`S⁻¹ μ` invests all the money, expects exactly `m`, has variance `(A m² - 2 B m + C) / Δ`, and
every other fully invested portfolio that expects `m` has strictly larger variance. Weights may be
any real numbers, so short selling is allowed. -/
theorem minimum_variance_portfolio_for_target {ι : Type*} [Fintype ι] [DecidableEq ι]
    (S : Matrix ι ι ℝ) (hS : S.PosDef) (μ : ι → ℝ) (hμ : ∃ i j, μ i ≠ μ j) (m : ℝ) :
    let one : ι → ℝ := fun _ => 1
    let A := one ⬝ᵥ (S⁻¹ *ᵥ one)
    let B := one ⬝ᵥ (S⁻¹ *ᵥ μ)
    let C := μ ⬝ᵥ (S⁻¹ *ᵥ μ)
    let Δ := A * C - B ^ 2
    let w := ((C - B * m) / Δ) • (S⁻¹ *ᵥ one) + ((A * m - B) / Δ) • (S⁻¹ *ᵥ μ)
    0 < Δ ∧ one ⬝ᵥ w = 1 ∧ μ ⬝ᵥ w = m ∧
      w ⬝ᵥ (S *ᵥ w) = (A * m ^ 2 - 2 * B * m + C) / Δ ∧
      ∀ u : ι → ℝ, one ⬝ᵥ u = 1 → μ ⬝ᵥ u = m → u ≠ w →
        w ⬝ᵥ (S *ᵥ w) < u ⬝ᵥ (S *ᵥ u) := by
  intro one A B C Δ w
  exact (ef_mv_core S hS μ one rfl hμ A B C Δ m rfl rfl rfl rfl w rfl).2

/-- The global minimum-variance portfolio. For a positive definite covariance matrix `S`, the
portfolio `w_g = S⁻¹ 1 / A`, with `A = 1ᵀ S⁻¹ 1`, invests all the money, has variance `1 / A`
and expected return `B / A` with `B = 1ᵀ S⁻¹ μ`, and every other fully invested portfolio has
strictly larger variance. The expected returns play no part in finding it. -/
theorem global_minimum_variance_portfolio {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (S : Matrix ι ι ℝ) (hS : S.PosDef) (μ : ι → ℝ) :
    let one : ι → ℝ := fun _ => 1
    let A := one ⬝ᵥ (S⁻¹ *ᵥ one)
    let B := one ⬝ᵥ (S⁻¹ *ᵥ μ)
    let wg := A⁻¹ • (S⁻¹ *ᵥ one)
    one ⬝ᵥ wg = 1 ∧ wg ⬝ᵥ (S *ᵥ wg) = 1 / A ∧ μ ⬝ᵥ wg = B / A ∧
      ∀ u : ι → ℝ, one ⬝ᵥ u = 1 → u ≠ wg → wg ⬝ᵥ (S *ᵥ wg) < u ⬝ᵥ (S *ᵥ u) := by
  intro one A B wg
  exact (ef_gmv_core S hS μ one rfl A B rfl rfl wg rfl).2

/-- The efficient frontier is the part above the global minimum-variance return `B / A`. For a
target `m > B / A`, any fully invested portfolio that expects at least `m` with variance at most
that of the frontier portfolio `w(m)` is `w(m)` itself, so nothing beats it on both return and
risk. For a target `m < B / A`, the global minimum-variance portfolio expects more and has
strictly less variance, so `w(m)` is not worth holding. -/
theorem efficient_frontier_above_global_minimum {ι : Type*} [Fintype ι] [DecidableEq ι]
    (S : Matrix ι ι ℝ) (hS : S.PosDef) (μ : ι → ℝ) (hμ : ∃ i j, μ i ≠ μ j) (m : ℝ) :
    let one : ι → ℝ := fun _ => 1
    let A := one ⬝ᵥ (S⁻¹ *ᵥ one)
    let B := one ⬝ᵥ (S⁻¹ *ᵥ μ)
    let C := μ ⬝ᵥ (S⁻¹ *ᵥ μ)
    let Δ := A * C - B ^ 2
    let w := ((C - B * m) / Δ) • (S⁻¹ *ᵥ one) + ((A * m - B) / Δ) • (S⁻¹ *ᵥ μ)
    let wg := A⁻¹ • (S⁻¹ *ᵥ one)
    (B / A < m → ∀ u : ι → ℝ, one ⬝ᵥ u = 1 → m ≤ μ ⬝ᵥ u →
        u ⬝ᵥ (S *ᵥ u) ≤ w ⬝ᵥ (S *ᵥ w) → u = w) ∧
      (m < B / A → m < μ ⬝ᵥ wg ∧ wg ⬝ᵥ (S *ᵥ wg) < w ⬝ᵥ (S *ᵥ w)) := by
  intro one A B C Δ w wg
  obtain ⟨hApos, hΔ, hw1, hwμ, hV, hmin⟩ :=
    ef_mv_core S hS μ one rfl hμ A B C Δ m rfl rfl rfl rfl w rfl
  have hΔdef : Δ = A * C - B ^ 2 := rfl
  constructor
  · intro hm u hu1 hmu hle
    have hBm : B < m * A := (div_lt_iff₀ hApos).mp hm
    set m' := μ ⬝ᵥ u with hm'
    set w' := ((C - B * m') / Δ) • (S⁻¹ *ᵥ one) + ((A * m' - B) / Δ) • (S⁻¹ *ᵥ μ) with hw'
    obtain ⟨-, -, -, -, hV', hmin'⟩ :=
      ef_mv_core S hS μ one rfl hμ A B C Δ m' rfl rfl rfl rfl w' rfl
    have hge : w' ⬝ᵥ (S *ᵥ w') ≤ u ⬝ᵥ (S *ᵥ u) := by
      rcases eq_or_ne u w' with h | h
      · exact le_of_eq (by rw [h])
      · exact (hmin' u hu1 hm'.symm h).le
    have hnum : A * m' ^ 2 - 2 * B * m' + C ≤ A * m ^ 2 - 2 * B * m + C := by
      rw [← div_le_div_iff_of_pos_right hΔ, ← hV', ← hV]
      linarith
    have heq : m' = m := by
      by_contra hne
      have hlt : m < m' := lt_of_le_of_ne hmu (Ne.symm hne)
      have h1 : 0 < m' - m := sub_pos.mpr hlt
      have h2 : 0 < A * (m' + m) - 2 * B := by nlinarith
      have h3 := mul_pos h1 h2
      nlinarith
    by_contra hne
    have := hmin u hu1 (hm'.symm.trans heq) hne
    linarith
  · intro hm
    obtain ⟨i, -, -⟩ := hμ
    have : Nonempty ι := ⟨i⟩
    obtain ⟨-, -, hgV, hgμ, -⟩ := ef_gmv_core S hS μ one rfl A B rfl rfl wg rfl
    refine ⟨by rw [hgμ]; exact hm, ?_⟩
    have hmA : m * A < B := (lt_div_iff₀ hApos).mp hm
    have hsq : 0 < (B - m * A) ^ 2 := pow_pos (sub_pos.mpr hmA) 2
    rw [hgV, hV, div_lt_div_iff₀ hApos hΔ, hΔdef]
    nlinarith [hsq]

/-! The card's worked numbers, in percent units: means 8, 4, 5 and the covariance matrix
`[[400, 24, 30], [24, 36, 0], [30, 0, 225]]` in percent squared. -/

-- The determinant of the covariance matrix is 3,078,000.
example : (!![400, 24, 30; 24, 36, 0; 30, 0, 225] : Matrix (Fin 3) (Fin 3) ℤ).det = 3078000 := by
  norm_num [Matrix.det_fin_three]

-- The adjugate (determinant times the inverse) is the card's table.
example : (!![400, 24, 30; 24, 36, 0; 30, 0, 225] : Matrix (Fin 3) (Fin 3) ℤ).adjugate =
    !![8100, -5400, -1080; -5400, 89100, 720; -1080, 720, 13824] := by
  rw [Matrix.adjugate_fin_three]
  ext i j; fin_cases i <;> fin_cases j <;> norm_num

-- Row sums of the adjugate: 1,620; 84,420; 13,464, adding to determinant times A = 99,504.
example : (!![8100, -5400, -1080; -5400, 89100, 720; -1080, 720, 13824] : Matrix (Fin 3) (Fin 3) ℤ)
    *ᵥ ![1, 1, 1] = ![1620, 84420, 13464] ∧ (1620 + 84420 + 13464 : ℤ) = 99504 := by
  refine ⟨?_, by norm_num⟩
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three]

-- Adjugate times the means: 37,800; 316,800; 63,360, so determinant times B = 417,960
-- and determinant times C = 8·37,800 + 4·316,800 + 5·63,360 = 1,886,400.
example : (!![8100, -5400, -1080; -5400, 89100, 720; -1080, 720, 13824] : Matrix (Fin 3) (Fin 3) ℤ)
    *ᵥ ![8, 4, 5] = ![37800, 316800, 63360] ∧ (37800 + 316800 + 63360 : ℤ) = 417960 ∧
    (8 * 37800 + 4 * 316800 + 5 * 63360 : ℤ) = 1886400 := by
  refine ⟨?_, by norm_num, by norm_num⟩
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three]

-- Half shares and half bonds expects 6 percent with variance 121, a standard deviation of 11 percent.
example : ![(8 : ℚ), 4, 5] ⬝ᵥ ![1 / 2, 1 / 2, 0] = 6 ∧
    ![(1 : ℚ) / 2, 1 / 2, 0] ⬝ᵥ ((!![400, 24, 30; 24, 36, 0; 30, 0, 225] : Matrix (Fin 3) (Fin 3) ℚ)
      *ᵥ ![1 / 2, 1 / 2, 0]) = 121 := by
  constructor <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num

#print axioms ef_pd_pos
#print axioms ef_herm_dot
#print axioms ef_inv_cancel
#print axioms ef_strict_min
#print axioms ef_mv_core
#print axioms ef_gmv_core
#print axioms minimum_variance_portfolio_for_target
#print axioms global_minimum_variance_portfolio
#print axioms efficient_frontier_above_global_minimum
