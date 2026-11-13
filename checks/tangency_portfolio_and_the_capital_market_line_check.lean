-- Adding a riskless asset: with a positive definite covariance matrix and a bank rate below the minimum-variance portfolio's expected return, every least-risk portfolio for a target return holds the risky assets in the tangency proportions Σ⁻¹(μ − r_f·1), rescaled to add to one, and sits on the line μ_p = r_f + √H·σ_p.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

lemma tangency_mulVec_inv_mulVec {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (d : Fin n → ℝ) : Sigma *ᵥ (Sigma⁻¹ *ᵥ d) = d := by
  rw [mulVec_mulVec, mul_nonsing_inv _ ((isUnit_iff_isUnit_det _).mp hSigma.isUnit), one_mulVec]

lemma tangency_symm {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (u v : Fin n → ℝ) : u ⬝ᵥ (Sigma *ᵥ v) = v ⬝ᵥ (Sigma *ᵥ u) := by
  have hT : Sigmaᵀ = Sigma := by
    have h : Sigma.IsSymm := by simpa [conjTranspose_eq_transpose_of_trivial] using hSigma.1
    exact h
  rw [dotProduct_mulVec, ← mulVec_transpose, hT, dotProduct_comm]

lemma tangency_quad_pos {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (v : Fin n → ℝ) (hv : v ≠ 0) : 0 < v ⬝ᵥ (Sigma *ᵥ v) := by
  simpa using hSigma.dotProduct_mulVec_pos hv

lemma tangency_quad_nonneg {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (v : Fin n → ℝ) : 0 ≤ v ⬝ᵥ (Sigma *ᵥ v) := by
  by_cases hv : v = 0
  · simp [hv]
  · exact (tangency_quad_pos Sigma hSigma v hv).le

lemma tangency_quad_eq_zero {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (v : Fin n → ℝ) : v ⬝ᵥ (Sigma *ᵥ v) = 0 ↔ v = 0 := by
  constructor
  · intro h
    by_contra hv
    have := tangency_quad_pos Sigma hSigma v hv
    linarith
  · intro h; simp [h]

lemma tangency_H_pos {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (d : Fin n → ℝ) (hd : d ≠ 0) : 0 < d ⬝ᵥ (Sigma⁻¹ *ᵥ d) :=
  tangency_quad_pos _ hSigma.inv d hd

lemma tangency_key {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (d x : Fin n → ℝ) (hH : d ⬝ᵥ (Sigma⁻¹ *ᵥ d) ≠ 0) :
    (x - ((d ⬝ᵥ x) / (d ⬝ᵥ (Sigma⁻¹ *ᵥ d))) • (Sigma⁻¹ *ᵥ d)) ⬝ᵥ
        (Sigma *ᵥ (x - ((d ⬝ᵥ x) / (d ⬝ᵥ (Sigma⁻¹ *ᵥ d))) • (Sigma⁻¹ *ᵥ d))) =
      x ⬝ᵥ (Sigma *ᵥ x) - (d ⬝ᵥ x) ^ 2 / (d ⬝ᵥ (Sigma⁻¹ *ᵥ d)) := by
  set z := Sigma⁻¹ *ᵥ d with hz
  set H := d ⬝ᵥ z
  have h1 : Sigma *ᵥ z = d := tangency_mulVec_inv_mulVec Sigma hSigma d
  have h2 : z ⬝ᵥ (Sigma *ᵥ x) = d ⬝ᵥ x := by
    rw [tangency_symm Sigma hSigma, h1, dotProduct_comm]
  have h3 : z ⬝ᵥ d = H := dotProduct_comm _ _
  rw [mulVec_sub, mulVec_smul, h1]
  simp only [sub_dotProduct, dotProduct_sub, smul_dotProduct, dotProduct_smul, h2, h3,
    dotProduct_comm x d, smul_eq_mul]
  field_simp
  ring

lemma tangency_min {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (d x : Fin n → ℝ) (hH : 0 < d ⬝ᵥ (Sigma⁻¹ *ᵥ d)) (q : ℝ) (hq : d ⬝ᵥ x = q) :
    q ^ 2 / (d ⬝ᵥ (Sigma⁻¹ *ᵥ d)) ≤ x ⬝ᵥ (Sigma *ᵥ x) ∧
    (x ⬝ᵥ (Sigma *ᵥ x) = q ^ 2 / (d ⬝ᵥ (Sigma⁻¹ *ᵥ d)) ↔
      x = (q / (d ⬝ᵥ (Sigma⁻¹ *ᵥ d))) • (Sigma⁻¹ *ᵥ d)) := by
  have hk := tangency_key Sigma hSigma d x hH.ne'
  rw [hq] at hk
  constructor
  · have := tangency_quad_nonneg Sigma hSigma
      (x - (q / (d ⬝ᵥ (Sigma⁻¹ *ᵥ d))) • (Sigma⁻¹ *ᵥ d))
    linarith
  · rw [← sub_eq_zero (a := x), ← tangency_quad_eq_zero Sigma hSigma, hk, sub_eq_zero]

lemma tangency_D_eq {n : ℕ} (Sigma : Matrix (Fin n) (Fin n) ℝ) (mu : Fin n → ℝ) (rf : ℝ) :
    ∑ i, (Sigma⁻¹ *ᵥ (mu - rf • (1 : Fin n → ℝ))) i =
      (1 : Fin n → ℝ) ⬝ᵥ (Sigma⁻¹ *ᵥ mu) - rf * ((1 : Fin n → ℝ) ⬝ᵥ (Sigma⁻¹ *ᵥ 1)) := by
  rw [mulVec_sub, mulVec_smul]
  simp [dotProduct, Finset.sum_sub_distrib, Finset.mul_sum]

lemma tangency_a_pos {n : ℕ} (hn : 0 < n) (Sigma : Matrix (Fin n) (Fin n) ℝ)
    (hSigma : Sigma.PosDef) : 0 < (1 : Fin n → ℝ) ⬝ᵥ (Sigma⁻¹ *ᵥ 1) := by
  have h1 : (1 : Fin n → ℝ) ≠ 0 := by
    intro h
    have := congr_fun h ⟨0, hn⟩
    simp at this
  exact tangency_H_pos Sigma hSigma 1 h1

#print axioms tangency_mulVec_inv_mulVec
#print axioms tangency_symm
#print axioms tangency_quad_pos
#print axioms tangency_quad_nonneg
#print axioms tangency_quad_eq_zero
#print axioms tangency_H_pos
#print axioms tangency_key
#print axioms tangency_min
#print axioms tangency_D_eq
#print axioms tangency_a_pos

/-- Two-fund separation and the capital market line (the card's main claim, Step 4).
Take n risky assets with expected returns μ and covariance matrix Σ, positive definite (no mix of
the risky assets is riskless, so Σ has an inverse), and a bank that lends and borrows at one rate
r_f. Write d = μ − r_f·1 for the excess returns, z = Σ⁻¹d, D = 1·z (the sum of z's entries),
H = d·z, and the tangency weights w_T = z / D. Suppose the bank rate is below the minimum-variance
portfolio's expected return b/a, where a = 1·Σ⁻¹1 and b = 1·Σ⁻¹μ.
A position puts amounts x in the risky assets and 1 − Σᵢ xᵢ in the bank; its expected return is
μ·x + r_f(1 − Σᵢ xᵢ) and its variance is x·Σx. Then for every target expected return μ_p above
r_f: the tangency weights add to one; a position reaching μ_p has the least variance among all
positions reaching μ_p exactly when it is y·w_T with y = (μ_p − r_f)·D/H, the same risky mix for
every investor, who chooses only how much of it to hold; and that position satisfies
μ_p = r_f + √H·σ_p, the capital market line. -/
theorem two_fund_separation_on_capital_market_line {n : ℕ}
    (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (mu : Fin n → ℝ) (rf : ℝ)
    (h_exists : rf < ((1 : Fin n → ℝ) ⬝ᵥ (Sigma⁻¹ *ᵥ mu)) / ((1 : Fin n → ℝ) ⬝ᵥ (Sigma⁻¹ *ᵥ 1)))
    (mu_p : ℝ) (h_target : rf < mu_p)
    (x : Fin n → ℝ) (hx : mu ⬝ᵥ x + rf * (1 - ∑ i, x i) = mu_p) :
    let d : Fin n → ℝ := mu - rf • (1 : Fin n → ℝ)
    let z : Fin n → ℝ := Sigma⁻¹ *ᵥ d
    let D : ℝ := ∑ i, z i
    let H : ℝ := d ⬝ᵥ z
    let wT : Fin n → ℝ := D⁻¹ • z
    (∑ i, wT i = 1) ∧
    ((∀ x' : Fin n → ℝ, mu ⬝ᵥ x' + rf * (1 - ∑ i, x' i) = mu_p →
        x ⬝ᵥ (Sigma *ᵥ x) ≤ x' ⬝ᵥ (Sigma *ᵥ x')) ↔
      x = ((mu_p - rf) * D / H) • wT) ∧
    (x = ((mu_p - rf) * D / H) • wT →
      mu_p = rf + Real.sqrt H * Real.sqrt (x ⬝ᵥ (Sigma *ᵥ x))) := by
  intro d z D H wT
  set q := mu_p - rf with hqdef
  have hq : 0 < q := sub_pos.mpr h_target
  -- the budget constraint is the excess-return constraint d ⬝ᵥ x' = q
  have hcon : ∀ x' : Fin n → ℝ, mu ⬝ᵥ x' + rf * (1 - ∑ i, x' i) = mu_p ↔ d ⬝ᵥ x' = q := by
    intro x'
    have : d ⬝ᵥ x' = mu ⬝ᵥ x' - rf * ∑ i, x' i := by
      simp only [d, dotProduct, Pi.sub_apply, Pi.smul_apply, Pi.one_apply, smul_eq_mul, mul_one,
        sub_mul, Finset.sum_sub_distrib, Finset.mul_sum]
    rw [this, hqdef]
    constructor <;> intro h <;> linarith
  have hxq : d ⬝ᵥ x = q := (hcon x).mp hx
  -- D is positive
  have hDpos : 0 < D := by
    rcases Nat.eq_zero_or_pos n with h0 | hn
    · subst h0
      simp at hx
      linarith
    · have hDe : D = _ := tangency_D_eq Sigma mu rf
      have ha := tangency_a_pos hn Sigma hSigma
      rw [hDe, sub_pos]
      rwa [lt_div_iff₀ ha] at h_exists
  have hd : d ≠ 0 := by
    intro h
    have : z = 0 := by simp [z, h]
    have : D = 0 := by simp [D, this]
    linarith
  have hH : 0 < H := tangency_H_pos Sigma hSigma d hd
  have hstar : ((mu_p - rf) * D / H) • wT = (q / H) • z := by
    simp only [wT, smul_smul, ← hqdef]
    congr 1
    field_simp
  have hm : ∀ x' : Fin n → ℝ, d ⬝ᵥ x' = q →
      q ^ 2 / H ≤ x' ⬝ᵥ (Sigma *ᵥ x') ∧
      (x' ⬝ᵥ (Sigma *ᵥ x') = q ^ 2 / H ↔ x' = (q / H) • z) :=
    fun x' hx' => tangency_min Sigma hSigma d x' hH q hx'
  have hstar_q : d ⬝ᵥ ((q / H) • z) = q := by
    rw [dotProduct_smul, smul_eq_mul]
    change q / H * H = q
    field_simp
  have hstar_S : ((q / H) • z) ⬝ᵥ (Sigma *ᵥ ((q / H) • z)) = q ^ 2 / H :=
    ((hm _ hstar_q).2).mpr rfl
  rw [hstar]
  refine ⟨?_, ?_, ?_⟩
  · simp only [wT, Pi.smul_apply, smul_eq_mul, ← Finset.mul_sum]
    exact inv_mul_cancel₀ hDpos.ne'
  · constructor
    · intro hmin
      have h1 := hmin _ ((hcon _).mpr hstar_q)
      rw [hstar_S] at h1
      have h2 := (hm x hxq).1
      exact (hm x hxq).2.mp (le_antisymm h1 h2)
    · intro hxe x' hx'
      rw [hxe, hstar_S]
      exact (hm x' ((hcon x').mp hx')).1
  · intro hxe
    rw [hxe, hstar_S, Real.sqrt_div (sq_nonneg q), Real.sqrt_sq hq.le]
    have hsH : 0 < Real.sqrt H := Real.sqrt_pos.mpr hH
    field_simp
    ring

/-- The steepest line (Step 1). With Σ positive definite, excess returns d = μ − r_f·1 and
z = Σ⁻¹d, every risky position x with positive excess return d·x has Sharpe ratio
(d·x)/√(x·Σx) at most √(d·z), and equality holds exactly when x is a positive multiple of z. -/
theorem sharpe_ratio_at_most_sqrt_H {n : ℕ}
    (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (mu : Fin n → ℝ) (rf : ℝ) (x : Fin n → ℝ)
    (hx : 0 < (mu - rf • (1 : Fin n → ℝ)) ⬝ᵥ x) :
    let d : Fin n → ℝ := mu - rf • (1 : Fin n → ℝ)
    let z : Fin n → ℝ := Sigma⁻¹ *ᵥ d
    (d ⬝ᵥ x) / Real.sqrt (x ⬝ᵥ (Sigma *ᵥ x)) ≤ Real.sqrt (d ⬝ᵥ z) ∧
    ((d ⬝ᵥ x) / Real.sqrt (x ⬝ᵥ (Sigma *ᵥ x)) = Real.sqrt (d ⬝ᵥ z) ↔
      ∃ c : ℝ, 0 < c ∧ x = c • z) := by
  intro d z
  have hd : d ≠ 0 := by
    intro h
    simp only [d] at h
    rw [h, zero_dotProduct] at hx
    exact lt_irrefl _ hx
  have hx0 : x ≠ 0 := by
    intro h
    rw [h, dotProduct_zero] at hx
    exact lt_irrefl _ hx
  have hH : 0 < d ⬝ᵥ z := tangency_H_pos Sigma hSigma d hd
  have hS : 0 < x ⬝ᵥ (Sigma *ᵥ x) := tangency_quad_pos Sigma hSigma x hx0
  set H := d ⬝ᵥ z with hHdef
  set S := x ⬝ᵥ (Sigma *ᵥ x) with hSdef
  set p := d ⬝ᵥ x with hp
  have hm : p ^ 2 / H ≤ S ∧ (S = p ^ 2 / H ↔ x = (p / H) • z) :=
    tangency_min Sigma hSigma d x hH p rfl
  have hsS : 0 < Real.sqrt S := Real.sqrt_pos.mpr hS
  have hsH : 0 < Real.sqrt H := Real.sqrt_pos.mpr hH
  have hsq : Real.sqrt H * Real.sqrt S = Real.sqrt (H * S) := (Real.sqrt_mul hH.le S).symm
  have hle : p ^ 2 ≤ H * S := by
    have := hm.1
    rw [div_le_iff₀ hH] at this
    linarith
  -- the ratio equals √H exactly when p² = H S
  have heq : p / Real.sqrt S = Real.sqrt H ↔ p ^ 2 = H * S := by
    rw [div_eq_iff hsS.ne', hsq]
    constructor
    · intro h
      rw [h, Real.sq_sqrt (by positivity)]
    · intro h
      rw [← h, Real.sqrt_sq hx.le]
  refine ⟨?_, ?_⟩
  · rw [div_le_iff₀ hsS, hsq]
    exact Real.le_sqrt_of_sq_le hle
  · rw [heq]
    constructor
    · intro h
      refine ⟨p / H, div_pos hx hH, ?_⟩
      apply hm.2.mp
      field_simp
      linarith
    · rintro ⟨c, _, rfl⟩
      have hzz : z ⬝ᵥ (Sigma *ᵥ z) = H := by
        rw [tangency_mulVec_inv_mulVec Sigma hSigma d, dotProduct_comm]
      rw [hp, hSdef, dotProduct_smul, mulVec_smul, smul_dotProduct, dotProduct_smul, hzz]
      simp only [smul_eq_mul]
      ring

/-- When a tangency portfolio exists (Step 3). With at least one risky asset and Σ positive
definite, the sum D of the entries of Σ⁻¹(μ − r_f·1) equals b − r_f·a, where a = 1·Σ⁻¹1 and
b = 1·Σ⁻¹μ; so D is positive exactly when the bank rate is below the minimum-variance
portfolio's expected return b/a. -/
theorem tangency_exists_iff_rate_below_min_variance_return {n : ℕ} (hn : 0 < n)
    (Sigma : Matrix (Fin n) (Fin n) ℝ) (hSigma : Sigma.PosDef)
    (mu : Fin n → ℝ) (rf : ℝ) :
    let a : ℝ := (1 : Fin n → ℝ) ⬝ᵥ (Sigma⁻¹ *ᵥ 1)
    let b : ℝ := (1 : Fin n → ℝ) ⬝ᵥ (Sigma⁻¹ *ᵥ mu)
    let D : ℝ := ∑ i, (Sigma⁻¹ *ᵥ (mu - rf • (1 : Fin n → ℝ))) i
    D = b - rf * a ∧ (0 < D ↔ rf < b / a) := by
  intro a b D
  have hD : D = b - rf * a := tangency_D_eq Sigma mu rf
  have ha : 0 < a := tangency_a_pos hn Sigma hSigma
  refine ⟨hD, ?_⟩
  rw [hD, lt_div_iff₀ ha, sub_pos]

/-! ### The card's house market, checked exactly

Shares, bonds, gold: expected returns 8/100, 4/100, 5/100; bank rate 2/100. The covariance
matrix entries are ρᵢⱼσᵢσⱼ: 0.04 = 1/25, 0.0024 = 3/1250, 0.003 = 3/1000, 0.0036 = 9/2500,
0.0225 = 9/400. All arithmetic below is exact over the rationals. -/

/-- The covariance matrix: 0.2 × 0.20 × 0.06 = 0.0024 and 0.1 × 0.20 × 0.15 = 0.003. -/
example : (2 / 10 : ℚ) * (20 / 100) * (6 / 100) = 3 / 1250 ∧
    (1 / 10 : ℚ) * (20 / 100) * (15 / 100) = 3 / 1000 ∧
    ((20 : ℚ) / 100) ^ 2 = 1 / 25 ∧ ((6 : ℚ) / 100) ^ 2 = 9 / 2500 ∧
    ((15 : ℚ) / 100) ^ 2 = 9 / 400 := by
  norm_num

/-- Solving Σz = d with d = (6/100, 2/100, 3/100): z = (64/57, 274/57, 1012/855),
about 1.122807, 4.807018, 1.183626. -/
example :
    !![(1 / 25 : ℚ), 3 / 1250, 3 / 1000; 3 / 1250, 9 / 2500, 0; 3 / 1000, 0, 9 / 400] *ᵥ
      ![64 / 57, 274 / 57, 1012 / 855] = ![6 / 100, 2 / 100, 3 / 100] := by
  ext i
  fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num

/-- D = 6082/855 (about 7.113450), and the tangency weights z/D are 480/3041, 2055/3041 and
506/3041 (15.8, 67.6 and 16.6 percent): all positive, adding to one. -/
example :
    (64 / 57 + 274 / 57 + 1012 / 855 : ℚ) = 6082 / 855 ∧
    (64 / 57 : ℚ) / (6082 / 855) = 480 / 3041 ∧
    (274 / 57 : ℚ) / (6082 / 855) = 2055 / 3041 ∧
    (1012 / 855 : ℚ) / (6082 / 855) = 506 / 3041 ∧
    (480 + 2055 + 506 : ℚ) / 3041 = 1 := by
  norm_num

/-- The second road: H = d·z = 1418/7125 (about 0.199018, square root about 0.446). -/
example :
    (6 / 100 : ℚ) * (64 / 57) + 2 / 100 * (274 / 57) + 3 / 100 * (1012 / 855) = 1418 / 7125 := by
  norm_num

/-- The frontier constants: Σ⁻¹1 = (100/19, 46900/171, 7480/171), so a = 55280/171 (about 323.27);
Σ⁻¹μ = (70/57, 1760/171, 352/171), so b = 258/19 (about 13.58); and D = b − r_f·a. -/
example :
    !![(1 / 25 : ℚ), 3 / 1250, 3 / 1000; 3 / 1250, 9 / 2500, 0; 3 / 1000, 0, 9 / 400] *ᵥ
        ![100 / 19, 46900 / 171, 7480 / 171] = ![1, 1, 1] ∧
    !![(1 / 25 : ℚ), 3 / 1250, 3 / 1000; 3 / 1250, 9 / 2500, 0; 3 / 1000, 0, 9 / 400] *ᵥ
        ![70 / 57, 1760 / 171, 352 / 171] = ![8 / 100, 4 / 100, 5 / 100] ∧
    (100 / 19 + 46900 / 171 + 7480 / 171 : ℚ) = 55280 / 171 ∧
    (70 / 57 + 1760 / 171 + 352 / 171 : ℚ) = 258 / 19 ∧
    (258 / 19 : ℚ) - 2 / 100 * (55280 / 171) = 6082 / 855 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · ext i
    fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num
  · ext i
    fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num
  all_goals norm_num

/-- The bank rate 2/100 is below the minimum-variance return b/a = 1161/27640 (about 4.20
percent), so the tangency portfolio exists. -/
example : (258 / 19 : ℚ) / (55280 / 171) = 1161 / 27640 ∧ (2 / 100 : ℚ) < 1161 / 27640 := by
  norm_num

/-- The cautious investor targets 3 percent, an excess return q = 1/100: the fraction held in
the tangency portfolio is y = q·D/H = 3041/8508 (about 0.357). -/
example : (1 / 100 : ℚ) * (6082 / 855) / (1418 / 7125) = 3041 / 8508 := by
  norm_num

#print axioms two_fund_separation_on_capital_market_line
#print axioms sharpe_ratio_at_most_sqrt_H
#print axioms tangency_exists_iff_rate_below_min_variance_return
