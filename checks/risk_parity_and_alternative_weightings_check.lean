-- Risk parity: for a positive definite covariance table the volatility contributions w_i (Σw)_i / σ(w) add up exactly to the fund's volatility, exactly one long-only fully invested portfolio gives every asset the same contribution σ(w)/n, and with two assets that portfolio is the inverse-volatility one whatever the correlation.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Topology.Order.Compact
import Mathlib.Analysis.Normed.Group.Basic
import Mathlib.Algebra.BigOperators.Field

open Matrix

/-! Weights `w i` are the fractions of the money in asset `i`, for assets `i : Fin n`.
`S` is the covariance table Σ. Mathlib's `S.PosDef` says `S` is symmetric and every nonzero
mix `x` has `xᵀ S x > 0`: no mix of the assets is riskless. `S *ᵥ w` is the list `(Σw)_i`,
and `w ⬝ᵥ (S *ᵥ w)` is the fund's variance. -/

/-- The covariance table built from volatilities and correlations: `Σ_ij = ρ_ij σ_i σ_j`. -/
def covOf {n : ℕ} (σ : Fin n → ℝ) (ρ : Matrix (Fin n) (Fin n) ℝ) : Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j => ρ i j * σ i * σ j

/-- The fund's volatility `σ(w) = √(Σ_i Σ_j w_i Σ_ij w_j)`. -/
noncomputable def portfolioVol {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (w : Fin n → ℝ) : ℝ :=
  Real.sqrt (w ⬝ᵥ (S *ᵥ w))

/-- Marginal risk of asset `i`: `MRC_i = (Σw)_i / σ(w)`. -/
noncomputable def marginalRisk {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (w : Fin n → ℝ)
    (i : Fin n) : ℝ :=
  (S *ᵥ w) i / portfolioVol S w

/-- Risk contribution of asset `i`: `RC_i = w_i · MRC_i`. -/
noncomputable def riskContribution {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (w : Fin n → ℝ)
    (i : Fin n) : ℝ :=
  w i * marginalRisk S w i

lemma rp_symm {n : ℕ} {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) (i j : Fin n) :
    S j i = S i j := by
  simpa using hS.isHermitian.apply i j

lemma rp_qpos {n : ℕ} {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) {x : Fin n → ℝ}
    (hx : x ≠ 0) : 0 < x ⬝ᵥ (S *ᵥ x) := by
  simpa using hS.dotProduct_mulVec_pos hx

lemma rp_vecMul {n : ℕ} {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) (w : Fin n → ℝ) :
    w ᵥ* S = S *ᵥ w := by
  funext i
  simp only [vecMul, mulVec, dotProduct]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [rp_symm hS j i, mul_comm]

lemma rp_quad_update {n : ℕ} {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) (w : Fin n → ℝ)
    (i : Fin n) (x : ℝ) :
    Function.update w i x ⬝ᵥ (S *ᵥ Function.update w i x) =
      w ⬝ᵥ (S *ᵥ w) + 2 * (x - w i) * (S *ᵥ w) i + (x - w i) ^ 2 * S i i := by
  have hu : Function.update w i x = w + (x - w i) • Pi.single i 1 := by
    funext j
    by_cases h : j = i
    · subst h; simp
    · simp [h]
  have h1 : w ⬝ᵥ (S *ᵥ Pi.single i 1) = (S *ᵥ w) i := by
    rw [dotProduct_mulVec, dotProduct_single, rp_vecMul hS, mul_one]
  rw [hu]
  simp only [mulVec_add, mulVec_smul, add_dotProduct, dotProduct_add, smul_dotProduct,
    dotProduct_smul, single_dotProduct, mulVec_single_one, smul_eq_mul]
  have h1' : w ⬝ᵥ S.col i = (S *ᵥ w) i := by rw [← h1, mulVec_single_one]
  simp [h1']
  ring

lemma rp_deriv_quad {n : ℕ} {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) (w : Fin n → ℝ)
    (i : Fin n) :
    HasDerivAt (fun x => Function.update w i x ⬝ᵥ (S *ᵥ Function.update w i x))
      (2 * (S *ᵥ w) i) (w i) := by
  have : (fun x => Function.update w i x ⬝ᵥ (S *ᵥ Function.update w i x)) =
      fun x => w ⬝ᵥ (S *ᵥ w) + 2 * (x - w i) * (S *ᵥ w) i + (x - w i) ^ 2 * S i i := by
    funext x; exact rp_quad_update hS w i x
  rw [this]
  have h0 : HasDerivAt (fun x : ℝ => x - w i) 1 (w i) := (hasDerivAt_id (w i)).sub_const (w i)
  have h := (h0.const_mul 2).mul_const ((S *ᵥ w) i)
  have h2 := (h0.pow 2).mul_const (S i i)
  have h3 := (h.const_add (w ⬝ᵥ (S *ᵥ w))).add h2
  convert h3 using 1
  simp

lemma rp_ne_zero_of_sum {n : ℕ} {w : Fin n → ℝ} (hw : ∑ i, w i = 1) : w ≠ 0 := by
  rintro rfl; simp at hw

lemma rp_sum_rc {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (w : Fin n → ℝ)
    : ∑ i, riskContribution S w i = portfolioVol S w := by
  simp only [riskContribution, marginalRisk, mul_div_assoc']
  rw [← Finset.sum_div]
  change w ⬝ᵥ (S *ᵥ w) / portfolioVol S w = portfolioVol S w
  unfold portfolioVol
  rw [Real.div_sqrt]

#print axioms rp_symm
#print axioms rp_qpos
#print axioms rp_vecMul
#print axioms rp_quad_update
#print axioms rp_deriv_quad
#print axioms rp_ne_zero_of_sum
#print axioms rp_sum_rc

/-- Euler's split of volatility. Take a covariance table with no riskless mix and weights that
add to 1. Doubling every position doubles volatility (`σ(t w) = t σ(w)` for every `t > 0`);
the rate at which volatility rises as weight `w_i` alone grows is the marginal risk
`(Σw)_i / σ(w)`; and the risk contributions `w_i (Σw)_i / σ(w)` add up exactly to `σ(w)`. -/
theorem risk_contributions_sum_to_volatility {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ)
    (hS : S.PosDef) (w : Fin n → ℝ) (hw : ∑ i, w i = 1) :
    (∀ t : ℝ, 0 < t → portfolioVol S (t • w) = t * portfolioVol S w) ∧
    (∀ i, HasDerivAt (fun x => portfolioVol S (Function.update w i x))
        (marginalRisk S w i) (w i)) ∧
    ∑ i, riskContribution S w i = portfolioVol S w := by
  have hq : 0 < w ⬝ᵥ (S *ᵥ w) := rp_qpos hS (rp_ne_zero_of_sum hw)
  refine ⟨fun t ht => ?_, fun i => ?_, rp_sum_rc S w⟩
  · unfold portfolioVol
    rw [mulVec_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul, smul_eq_mul, ← mul_assoc,
      Real.sqrt_mul (by positivity), Real.sqrt_mul_self ht.le]
  · have h := (rp_deriv_quad hS w i).sqrt (by rw [Function.update_eq_self]; exact hq.ne')
    rw [Function.update_eq_self] at h
    have hs : 0 < Real.sqrt (w ⬝ᵥ (S *ᵥ w)) := Real.sqrt_pos.mpr hq
    convert h using 1
    · rfl
    unfold marginalRisk portfolioVol
    field_simp

lemma rp_coercive {n : ℕ} (hn : 0 < n) {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) :
    ∃ m > 0, ∀ y : Fin n → ℝ, m * ∑ j, y j ^ 2 ≤ y ⬝ᵥ (S *ᵥ y) := by
  set K : Set (Fin n → ℝ) := {y | ∑ j, y j ^ 2 = 1} with hKdef
  have hcont : Continuous fun y : Fin n → ℝ => y ⬝ᵥ (S *ᵥ y) := by
    simp only [dotProduct, mulVec]; fun_prop
  have hK : IsCompact K := by
    apply Metric.isCompact_of_isClosed_isBounded
    · exact isClosed_eq (by fun_prop) continuous_const
    · refine (Metric.isBounded_closedBall (x := (0 : Fin n → ℝ)) (r := 1)).subset ?_
      intro y hy
      rw [Metric.mem_closedBall, dist_zero_right, pi_norm_le_iff_of_nonneg zero_le_one]
      intro j
      rw [Real.norm_eq_abs]
      have h1 : y j ^ 2 ≤ ∑ k, y k ^ 2 :=
        Finset.single_le_sum (f := fun k => y k ^ 2) (fun k _ => sq_nonneg _) (Finset.mem_univ j)
      have hy' : ∑ k, y k ^ 2 = 1 := hy
      rw [hy'] at h1
      nlinarith [abs_nonneg (y j), sq_abs (y j)]
  have hne : K.Nonempty := ⟨Pi.single ⟨0, hn⟩ 1, by simp [K, Pi.single_apply]⟩
  obtain ⟨y0, hy0, hmin⟩ := hK.exists_isMinOn hne hcont.continuousOn
  have hy0ne : y0 ≠ 0 := by
    rintro rfl
    have h : ∑ j : Fin n, (0 : Fin n → ℝ) j ^ 2 = 1 := hy0
    simp at h
  refine ⟨_, rp_qpos hS hy0ne, fun y => ?_⟩
  by_cases hy : y = 0
  · subst hy; simp
  set s := ∑ j, y j ^ 2 with hsdef
  have hs : 0 < s := by
    obtain ⟨j, hj⟩ : ∃ j, y j ≠ 0 := by
      by_contra h; exact hy (funext fun j => not_not.mp fun hj => h ⟨j, hj⟩)
    exact lt_of_lt_of_le (by positivity)
      (Finset.single_le_sum (f := fun k => y k ^ 2) (fun k _ => sq_nonneg _) (Finset.mem_univ j))
  set r := Real.sqrt s
  have hr : 0 < r := Real.sqrt_pos.mpr hs
  have hrr : r ^ 2 = s := Real.sq_sqrt hs.le
  have hz : r⁻¹ • y ∈ K := by
    show ∑ j, (r⁻¹ • y) j ^ 2 = 1
    simp only [Pi.smul_apply, smul_eq_mul, mul_pow, ← Finset.mul_sum]
    rw [← hsdef, inv_pow, hrr, inv_mul_cancel₀ hs.ne']
  have h2 := isMinOn_iff.mp hmin _ hz
  simp only [mulVec_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul] at h2
  have h3 : y0 ⬝ᵥ (S *ᵥ y0) * r ^ 2 ≤ y ⬝ᵥ (S *ᵥ y) := by
    have : r⁻¹ * (r⁻¹ * y ⬝ᵥ (S *ᵥ y)) * r ^ 2 = y ⬝ᵥ (S *ᵥ y) := by field_simp
    nlinarith [sq_nonneg r]
  rw [hrr] at h3
  linarith

lemma rp_h_lower (m t : ℝ) (hm : 0 < m) (ht : 0 < t) :
    -(1 / (2 * m)) ≤ m * t ^ 2 / 2 - Real.log t := by
  have h1 := Real.log_le_sub_one_of_pos ht
  have h2 : 0 ≤ (m * t - 1) ^ 2 / (2 * m) := by positivity
  have h3 : (m * t - 1) ^ 2 / (2 * m) = m * t ^ 2 / 2 - t + 1 / (2 * m) := by
    field_simp; ring
  linarith

lemma rp_exists_sol {n : ℕ} (hn : 0 < n) {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) :
    ∃ y : Fin n → ℝ, (∀ i, 0 < y i) ∧ ∀ i, y i * (S *ᵥ y) i = 1 := by
  obtain ⟨m, hm, hmq⟩ := rp_coercive hn hS
  set F : (Fin n → ℝ) → ℝ := fun y => y ⬝ᵥ (S *ᵥ y) / 2 - ∑ j, Real.log (y j) with hFdef
  set A := F 1
  set B := A + n / (2 * m)
  have hbound : ∀ y : Fin n → ℝ, (∀ j, 0 < y j) → F y ≤ A →
      ∀ i, m * y i ^ 2 / 2 - Real.log (y i) ≤ B := by
    intro y hy hF i
    have h1 : ∑ j, (m * y j ^ 2 / 2 - Real.log (y j)) ≤ F y := by
      simp only [F, Finset.sum_sub_distrib, ← Finset.sum_div, ← Finset.mul_sum]
      linarith [hmq y]
    have h2 : m * y i ^ 2 / 2 - Real.log (y i) + 1 / (2 * m) ≤
        ∑ j, (m * y j ^ 2 / 2 - Real.log (y j) + 1 / (2 * m)) :=
      Finset.single_le_sum (f := fun j => m * y j ^ 2 / 2 - Real.log (y j) + 1 / (2 * m))
        (fun j _ => by linarith [rp_h_lower m (y j) hm (hy j)]) (Finset.mem_univ i)
    rw [Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul] at h2
    have h3 : (n : ℝ) * (1 / (2 * m)) = n / (2 * m) := by ring
    have h4 : 0 < 1 / (2 * m) := by positivity
    linarith
  set δ := Real.exp (-B - 1) with hδdef
  set M := 4 / m + |B| + 1 with hMdef
  have hδ : 0 < δ := Real.exp_pos _
  have hin : ∀ y : Fin n → ℝ, (∀ j, 0 < y j) → F y ≤ A → ∀ i, δ < y i ∧ y i < M := by
    intro y hy hF i
    have hb := hbound y hy hF i
    have hyi := hy i
    constructor
    · have h0 : 0 ≤ m * y i ^ 2 / 2 := by positivity
      have : -B - 1 < Real.log (y i) := by linarith
      calc δ = Real.exp (-B - 1) := rfl
        _ < Real.exp (Real.log (y i)) := Real.exp_lt_exp.mpr this
        _ = y i := Real.exp_log hyi
    · by_contra hc
      replace hc := not_lt.mp hc
      have hm4 : 0 ≤ 4 / m := by positivity
      have hlog := Real.log_le_sub_one_of_pos hyi
      have h4 : 4 / m ≤ y i := by linarith [abs_nonneg B]
      have h5 : 4 ≤ m * y i := by rw [div_le_iff₀ hm] at h4; linarith
      have : 2 * y i ≤ m * y i ^ 2 / 2 := by nlinarith
      linarith [le_abs_self B]
  have hone : ∀ j : Fin n, 0 < (1 : Fin n → ℝ) j := fun j => by simp
  have hin1 := hin 1 hone le_rfl
  set K : Set (Fin n → ℝ) := Set.Icc (fun _ => δ) (fun _ => M) with hKdef
  have h1K : (1 : Fin n → ℝ) ∈ K :=
    ⟨fun j => by simpa using (hin1 j).1.le, fun j => by simpa using (hin1 j).2.le⟩
  have hqc : Continuous fun y : Fin n → ℝ => y ⬝ᵥ (S *ᵥ y) / 2 := by
    simp only [dotProduct, mulVec]; fun_prop
  have hcontF : ContinuousOn F K := by
    apply ContinuousOn.sub hqc.continuousOn
    apply continuousOn_finsetSum
    intro j _
    apply ContinuousOn.log (continuous_apply j).continuousOn
    intro y hy
    exact (lt_of_lt_of_le hδ (hy.1 j)).ne'
  obtain ⟨y, hyK, hmin⟩ := isCompact_Icc.exists_isMinOn ⟨1, h1K⟩ hcontF
  have hypos : ∀ j, 0 < y j := fun j => lt_of_lt_of_le hδ (hyK.1 j)
  have hFy : F y ≤ A := isMinOn_iff.mp hmin 1 h1K
  have hyin := hin y hypos hFy
  refine ⟨y, hypos, fun i => ?_⟩
  have hloc : IsLocalMin (fun x => F (Function.update y i x)) (y i) := by
    have hmem : Set.Ioo δ M ∈ nhds (y i) := Ioo_mem_nhds (hyin i).1 (hyin i).2
    show ∀ᶠ x in nhds (y i), _
    filter_upwards [hmem] with x hx
    rw [Function.update_eq_self]
    apply isMinOn_iff.mp hmin
    refine ⟨fun j => ?_, fun j => ?_⟩
    · rcases eq_or_ne j i with rfl | h
      · simp [hx.1.le]
      · simp [h, hyK.1 j]
    · rcases eq_or_ne j i with rfl | h
      · simp [hx.2.le]
      · simp [h, hyK.2 j]
  have hlog_eq : ∀ x, ∑ j, Real.log (Function.update y i x j) =
      Real.log x + ∑ j ∈ Finset.univ \ {i}, Real.log (y j) := by
    intro x
    have : (fun j => Real.log (Function.update y i x j)) =
        Function.update (fun j => Real.log (y j)) i (Real.log x) := by
      funext j; rcases eq_or_ne j i with rfl | h <;> simp [*]
    rw [this, Finset.sum_update_of_mem (Finset.mem_univ i)]
  have e : (fun x => F (Function.update y i x)) = fun x =>
      Function.update y i x ⬝ᵥ (S *ᵥ Function.update y i x) / 2 -
        (Real.log x + ∑ j ∈ Finset.univ \ {i}, Real.log (y j)) := by
    funext x; simp only [F, hlog_eq]
  have hder : HasDerivAt (fun x => F (Function.update y i x)) ((S *ᵥ y) i - (y i)⁻¹) (y i) := by
    rw [e]
    have := ((rp_deriv_quad hS y i).div_const 2).sub
      ((Real.hasDerivAt_log (hypos i).ne').add_const (∑ j ∈ Finset.univ \ {i}, Real.log (y j)))
    convert this using 1
    ring
  have h0 := hloc.hasDerivAt_eq_zero hder
  have hyi := (hypos i).ne'
  field_simp at h0
  linarith

lemma rp_unique {n : ℕ} {S : Matrix (Fin n) (Fin n) ℝ} (hS : S.PosDef) {y z : Fin n → ℝ}
    (hy : ∀ i, 0 < y i) (hz : ∀ i, 0 < z i) (hy1 : ∀ i, y i * (S *ᵥ y) i = 1)
    (hz1 : ∀ i, z i * (S *ᵥ z) i = 1) : y = z := by
  by_contra hne
  have hd : y - z ≠ 0 := sub_ne_zero.mpr hne
  have hpos := rp_qpos hS hd
  have hle : (y - z) ⬝ᵥ (S *ᵥ (y - z)) ≤ 0 := by
    rw [mulVec_sub]
    simp only [dotProduct, Pi.sub_apply]
    apply Finset.sum_nonpos
    intro i _
    have ha := hy i
    have hb := hz i
    have h1 := hy1 i
    have h2 := hz1 i
    have key : (y i - z i) * ((S *ᵥ y) i - (S *ᵥ z) i) * (y i * z i) = -(y i - z i) ^ 2 := by
      linear_combination (y i - z i) * z i * h1 - (y i - z i) * y i * h2
    have hab : 0 < y i * z i := mul_pos ha hb
    nlinarith [sq_nonneg (y i - z i)]
  linarith

lemma rp_rc_of_const {n : ℕ} (hn : 0 < n) (S : Matrix (Fin n) (Fin n) ℝ) (w : Fin n → ℝ)
    (c : ℝ) (hc : 0 < c) (hw : ∀ i, w i * (S *ᵥ w) i = c) (i : Fin n) :
    riskContribution S w i = portfolioVol S w / n := by
  have hq : w ⬝ᵥ (S *ᵥ w) = n * c := by
    simp only [dotProduct, hw, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul]
  have hnr : (0 : ℝ) < n := Nat.cast_pos.mpr hn
  have hσ : 0 < portfolioVol S w := by
    unfold portfolioVol; rw [hq]; positivity
  have hσ2 : portfolioVol S w ^ 2 = n * c := by
    unfold portfolioVol; rw [hq, Real.sq_sqrt (by positivity)]
  unfold riskContribution marginalRisk
  rw [mul_div_assoc', hw i]
  field_simp
  linarith [hσ2]

#print axioms rp_coercive
#print axioms rp_h_lower
#print axioms rp_exists_sol
#print axioms rp_unique
#print axioms rp_rc_of_const

/-- Risk parity has exactly one answer. For `n ≥ 1` assets whose covariance table has no
riskless mix (positive definite), there is exactly one list of weights that are all positive,
add to 1, and give every asset the same risk contribution, one `n`-th of the fund's
volatility: `RC_1 = ⋯ = RC_n = σ(w)/n`. -/
theorem equal_risk_contribution_portfolio_exists_unique {n : ℕ} (hn : 0 < n)
    (S : Matrix (Fin n) (Fin n) ℝ) (hS : S.PosDef) :
    ∃! w : Fin n → ℝ, (∀ i, 0 < w i) ∧ ∑ i, w i = 1 ∧
      ∀ i, riskContribution S w i = portfolioVol S w / n := by
  obtain ⟨y, hy, hy1⟩ := rp_exists_sol hn hS
  have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
  set s := ∑ i, y i with hsdef
  have hs : 0 < s := Finset.sum_pos (fun i _ => hy i) Finset.univ_nonempty
  have key : ∀ v : Fin n → ℝ, (∀ i, 0 < v i) → ∑ i, v i = 1 →
      (∀ i, riskContribution S v i = portfolioVol S v / n) → v = s⁻¹ • y := by
    intro v hv hv1 hv3
    have hq : 0 < v ⬝ᵥ (S *ᵥ v) := rp_qpos hS (rp_ne_zero_of_sum hv1)
    have hnr : (0 : ℝ) < n := Nat.cast_pos.mpr hn
    have hσ : 0 < portfolioVol S v := Real.sqrt_pos.mpr hq
    have hσ2 : portfolioVol S v ^ 2 = v ⬝ᵥ (S *ᵥ v) := Real.sq_sqrt hq.le
    set c := v ⬝ᵥ (S *ᵥ v) / n with hcdef
    have hc : 0 < c := by positivity
    have hvc : ∀ i, v i * (S *ᵥ v) i = c := by
      intro i
      have h := hv3 i
      unfold riskContribution marginalRisk at h
      rw [hcdef, ← hσ2]
      field_simp at h ⊢
      nlinarith [h]
    set t := Real.sqrt c with htdef
    have ht : 0 < t := Real.sqrt_pos.mpr hc
    have ht2 : t ^ 2 = c := Real.sq_sqrt hc.le
    have hz : t⁻¹ • v = y := by
      apply rp_unique hS _ hy _ hy1
      · intro i; simp only [Pi.smul_apply, smul_eq_mul]; exact mul_pos (inv_pos.mpr ht) (hv i)
      · intro i
        simp only [Pi.smul_apply, smul_eq_mul, mulVec_smul]
        rw [show t⁻¹ * v i * (t⁻¹ * (S *ᵥ v) i) = (t ^ 2)⁻¹ * (v i * (S *ᵥ v) i) by ring,
          hvc i, ht2, inv_mul_cancel₀ hc.ne']
    have hvy : v = t • y := by rw [← hz, smul_smul, mul_inv_cancel₀ ht.ne', one_smul]
    have hts : t * s = 1 := by
      rw [← hv1, hvy, hsdef, Finset.mul_sum]; simp
    rw [hvy]
    congr 1
    field_simp
    linarith
  refine ⟨s⁻¹ • y, ⟨fun i => ?_, ?_, fun i => ?_⟩, fun v ⟨h1, h2, h3⟩ => key v h1 h2 h3⟩
  · simp only [Pi.smul_apply, smul_eq_mul]; exact mul_pos (inv_pos.mpr hs) (hy i)
  · simp only [Pi.smul_apply, smul_eq_mul, ← Finset.mul_sum]
    rw [← hsdef, inv_mul_cancel₀ hs.ne']
  · apply rp_rc_of_const hn S _ (s⁻¹ ^ 2) (by positivity)
    intro j
    simp only [Pi.smul_apply, smul_eq_mul, mulVec_smul]
    rw [show s⁻¹ * y j * (s⁻¹ * (S *ᵥ y) j) = s⁻¹ ^ 2 * (y j * (S *ᵥ y) j) by ring, hy1 j,
      mul_one]

/-- Two assets: equal risk is inverse volatility, whatever the correlation. With volatilities
`σ₁, σ₂ > 0` and any correlation `ρ`, if positive weights adding to 1 make
`w_1 (Σw)_1 = w_2 (Σw)_2`, then the cross terms cancel, `w_1 σ₁ = w_2 σ₂`, and the weights are
`σ₂/(σ₁+σ₂)` and `σ₁/(σ₁+σ₂)`. -/
theorem two_asset_equal_risk_is_inverse_volatility (σ₁ σ₂ ρ : ℝ) (h₁ : 0 < σ₁) (h₂ : 0 < σ₂)
    (w : Fin 2 → ℝ) (hpos : ∀ i, 0 < w i) (hsum : ∑ i, w i = 1)
    (heq : w 0 * (covOf ![σ₁, σ₂] !![1, ρ; ρ, 1] *ᵥ w) 0 =
      w 1 * (covOf ![σ₁, σ₂] !![1, ρ; ρ, 1] *ᵥ w) 1) :
    w = ![σ₂ / (σ₁ + σ₂), σ₁ / (σ₁ + σ₂)] := by
  simp [covOf, mulVec, dotProduct, Fin.sum_univ_two] at heq hsum
  have p0 := hpos 0
  have p1 := hpos 1
  have key : σ₁ * w 0 = σ₂ * w 1 := by
    have h3 : (σ₁ * w 0 - σ₂ * w 1) * (σ₁ * w 0 + σ₂ * w 1) = 0 := by linear_combination heq
    rcases mul_eq_zero.mp h3 with h | h
    · linarith
    · nlinarith [mul_pos h₁ p0, mul_pos h₂ p1]
  have hs : σ₁ + σ₂ ≠ 0 := by positivity
  funext i
  fin_cases i
  · simp; field_simp; nlinarith
  · simp; field_simp; nlinarith

/-! The card's worked numbers, in percent units so every entry is a whole number: the
covariance table `[[400, 24, 30], [24, 36, 0], [30, 0, 225]]` (percent squared) for shares,
bonds, gold. Risk shares do not change when all weights are scaled, so weights are given
unscaled. Each list below is `w_i (Σw)_i`; asset `i`'s share of the risk is its entry over the
total. -/

-- The table is ρ_ij σ_i σ_j with volatilities 20, 6, 15 and correlations 0.2, 0.1, 0
-- (correlations written in tenths, so the product is ten times the table).
example : (fun i j => (!![10, 2, 1; 2, 10, 0; 1, 0, 10] : Matrix (Fin 3) (Fin 3) ℤ) i j
      * ![20, 6, 15] i * ![20, 6, 15] j) =
    fun i j => (!![4000, 240, 300; 240, 360, 0; 300, 0, 2250] : Matrix (Fin 3) (Fin 3) ℤ) i j := by
  decide

-- Equal money (1, 1, 1): risk shares 454/769, 60/769, 255/769 = 59.04, 7.80, 33.16 percent.
example : (fun i => ![1, 1, 1] i *
      ((!![400, 24, 30; 24, 36, 0; 30, 0, 225] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![1, 1, 1]) i) =
    ![454, 60, 255] ∧ (454 + 60 + 255 : ℤ) = 769 := by
  decide

-- 60/40 shares/bonds (3, 2, 0): shares carry 3744/4032 = 13/14 = 92.86 percent of the risk.
example : (fun i => ![3, 2, 0] i *
      ((!![400, 24, 30; 24, 36, 0; 30, 0, 225] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![3, 2, 0]) i) =
    ![3744, 288, 0] ∧ (3744 : ℚ) / (3744 + 288 + 0) = 13 / 14 := by
  exact ⟨by decide, by norm_num⟩

-- Inverse volatility, weights 1/20 : 1/6 : 1/15 = 3 : 10 : 4 (17.65, 58.82, 23.53 percent):
-- risk in the ratio 13 : 12 : 11 of the correlation row sums, 36.11, 33.33, 30.56 percent.
example : (fun i => ![3, 10, 4] i *
      ((!![400, 24, 30; 24, 36, 0; 30, 0, 225] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![3, 10, 4]) i) =
    ![4680, 4320, 3960] ∧ (4680 : ℤ) = 360 * 13 ∧ (4320 : ℤ) = 360 * 12 ∧ (3960 : ℤ) = 360 * 11 := by
  decide

-- Two assets, shares and bonds, correlation 0.2 and then -0.5: the inverse-volatility weights
-- 3 : 10 (bonds 10/13 = 0.769231) give equal contributions both times.
example : (fun i => ![3, 10] i *
      ((!![400, 24; 24, 36] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![3, 10]) i) = ![4320, 4320] ∧
    (fun i => ![3, 10] i *
      ((!![400, -60; -60, 36] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![3, 10]) i) = ![1800, 1800] := by
  decide

#print axioms risk_contributions_sum_to_volatility
#print axioms equal_risk_contribution_portfolio_exists_unique
#print axioms two_asset_equal_risk_is_inverse_volatility
