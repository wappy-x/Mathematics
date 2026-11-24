-- Holomorphic functional calculus: for a bounded operator T the loop integral of p(z) times the resolvent of T is p(T) and the spectrum of p(T) is p applied to the spectrum of T for every polynomial p, and the loop round 2 turns the resolvent of A = [[1, 1], [0, 2]] into the Riesz projection P = [[0, 1], [0, 1]].
import Mathlib.FieldTheory.IsAlgClosed.Spectrum
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Analysis.Normed.Operator.Mul
import Mathlib.MeasureTheory.Integral.CircleIntegral
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Analysis.Normed.Algebra.GelfandFormula
import Mathlib.Analysis.Complex.CauchyIntegral

open Polynomial Complex Real


section HFCHelpers

variable {F : Type*} [NormedAddCommGroup F] [NormedSpace ℂ F] [CompleteSpace F]

lemma hfc_mem_resolventSet [Nontrivial F] (T : F →L[ℂ] F) {r : ℝ} (hr : ‖T‖ < r) {z : ℂ}
    (hz : z ∈ Metric.sphere (0 : ℂ) r) : z ∈ resolventSet ℂ T :=
  spectrum.mem_resolventSet_of_norm_lt (by rw [mem_sphere_zero_iff_norm.mp hz]; exact hr)

omit [CompleteSpace F] in
lemma hfc_smul_resolvent (T : F →L[ℂ] F) {z : ℂ} (hz : z ∈ resolventSet ℂ T) :
    z • resolvent T z = 1 + T * resolvent T z := by
  have h : (algebraMap ℂ (F →L[ℂ] F) z - T) * resolvent T z = 1 :=
    Ring.mul_inverse_cancel _ hz
  rw [sub_mul, Algebra.algebraMap_eq_smul_one, smul_mul_assoc, one_mul,
    sub_eq_iff_eq_add] at h
  exact h

lemma hfc_continuousOn_resolvent [Nontrivial F] (T : F →L[ℂ] F) {r : ℝ} (hr : ‖T‖ < r) :
    ContinuousOn (resolvent T) (Metric.sphere (0 : ℂ) r) := fun _z hz =>
  (spectrum.hasDerivAt_resolvent_const_left
    (hfc_mem_resolventSet T hr hz)).continuousAt.continuousWithinAt

lemma hfc_ne_zero_of_mem_sphere {r : ℝ} (hr : 0 < r) {z : ℂ}
    (hz : z ∈ Metric.sphere (0 : ℂ) r) : z ≠ 0 := by
  rintro rfl
  rw [mem_sphere_zero_iff_norm, norm_zero] at hz
  linarith

lemma hfc_norm_resolvent_le [Nontrivial F] (T : F →L[ℂ] F) {r : ℝ} (hr : ‖T‖ < r) {z : ℂ}
    (hz : z ∈ Metric.sphere (0 : ℂ) r) : ‖resolvent T z‖ ≤ (r - ‖T‖)⁻¹ := by
  have h := hfc_smul_resolvent T (hfc_mem_resolventSet T hr hz)
  have h1 : r * ‖resolvent T z‖ ≤ 1 + ‖T‖ * ‖resolvent T z‖ := by
    have e := congrArg norm h
    rw [norm_smul, mem_sphere_zero_iff_norm.mp hz] at e
    rw [e]
    calc ‖1 + T * resolvent T z‖ ≤ ‖(1 : F →L[ℂ] F)‖ + ‖T * resolvent T z‖ := norm_add_le _ _
      _ ≤ 1 + ‖T‖ * ‖resolvent T z‖ := add_le_add (by simp) (norm_mul_le _ _)
  rw [inv_eq_one_div, le_div_iff₀ (by linarith)]
  nlinarith

lemma hfc_integral_mul_left (T : F →L[ℂ] F) {f : ℂ → F →L[ℂ] F} {r : ℝ}
    (hf : CircleIntegrable f 0 r) :
    (∮ z in C(0, r), T * f z) = T * ∮ z in C(0, r), f z := by
  unfold circleIntegral
  have := (ContinuousLinearMap.mul ℂ (F →L[ℂ] F) T).intervalIntegral_comp_comm hf.out
  simp only [ContinuousLinearMap.mul_apply'] at this
  rw [← this]
  congr 1
  ext1 θ
  rw [mul_smul_comm]

lemma hfc_integral_resolvent [Nontrivial F] (T : F →L[ℂ] F) {r : ℝ} (hr : ‖T‖ < r) :
    (∮ z in C(0, r), resolvent T z) = (2 * π * I) • (1 : F →L[ℂ] F) := by
  have hr0 : 0 < r := lt_of_le_of_lt (norm_nonneg _) hr
  set X : ℕ → (F →L[ℂ] F) := fun k => ∮ z in C(0, r), (z ^ k)⁻¹ • (T ^ k * resolvent T z)
    with hXdef
  have hcont : ∀ k, CircleIntegrable (fun z => (z ^ k)⁻¹ • (T ^ k * resolvent T z)) 0 r := by
    intro k
    refine ContinuousOn.circleIntegrable hr0.le ?_
    refine ContinuousOn.smul (f := fun z : ℂ => (z ^ k)⁻¹) ?_
      (continuousOn_const.mul (hfc_continuousOn_resolvent T hr))
    exact (continuousOn_pow k).inv₀ fun z hz => pow_ne_zero _ (hfc_ne_zero_of_mem_sphere hr0 hz)
  have hcont2 : ∀ k, CircleIntegrable (fun z : ℂ => (z ^ (k + 1))⁻¹ • T ^ k) 0 r := by
    intro k
    refine ContinuousOn.circleIntegrable hr0.le ?_
    refine ContinuousOn.smul (f := fun z : ℂ => (z ^ (k + 1))⁻¹) (g := fun _ => T ^ k) ?_
      continuousOn_const
    exact (continuousOn_pow _).inv₀ fun z hz => pow_ne_zero _ (hfc_ne_zero_of_mem_sphere hr0 hz)
  have hstep : ∀ k, X k = (∮ z in C(0, r), (z ^ (k + 1))⁻¹) • T ^ k + X (k + 1) := by
    intro k
    simp only [hXdef]
    rw [← circleIntegral.integral_smul_const (fun z => (z ^ (k + 1))⁻¹) (T ^ k) 0 r,
      ← circleIntegral.integral_add (hcont2 k) (hcont (k + 1))]
    apply circleIntegral.integral_congr hr0.le
    intro z hz
    have hz0 := hfc_ne_zero_of_mem_sphere hr0 hz
    have h := hfc_smul_resolvent T (hfc_mem_resolventSet T hr hz)
    have e1 : T ^ k + T ^ (k + 1) * resolvent T z = z • (T ^ k * resolvent T z) := by
      rw [← mul_smul_comm, h, mul_add, mul_one, pow_succ, mul_assoc]
    simp only
    rw [← smul_add, e1, smul_smul]
    congr 1
    field_simp
    ring
  have hint0 : (∮ z in C(0, r), (z ^ (0 + 1))⁻¹) = 2 * π * I := by
    simpa using circleIntegral.integral_sub_center_inv 0 hr0.ne'
  have hintk : ∀ k, 1 ≤ k → (∮ z in C(0, r), (z ^ (k + 1))⁻¹) = 0 := by
    intro k hk
    have e : ∀ z : ℂ, (z ^ (k + 1))⁻¹ = (z - 0) ^ (-(((k + 1 : ℕ)) : ℤ)) := fun z => by
      rw [sub_zero, zpow_neg, zpow_natCast]
    simp only [e]
    exact circleIntegral.integral_sub_zpow_of_ne (by omega) 0 0 r
  have hX : ∀ N, X 1 = X (N + 1) := by
    intro N
    induction N with
    | zero => rfl
    | succ n ih => rw [ih, hstep (n + 1), hintk (n + 1) (by omega), zero_smul, zero_add]
  have hbound : ∀ N, ‖X N‖ ≤ 2 * π * r * (r - ‖T‖)⁻¹ * (‖T‖ / r) ^ N := by
    intro N
    have := circleIntegral.norm_integral_le_of_norm_le_const hr0.le
      (f := fun z => (z ^ N)⁻¹ • (T ^ N * resolvent T z)) (c := 0)
      (C := (r ^ N)⁻¹ * (‖T‖ ^ N * (r - ‖T‖)⁻¹)) (by
        intro z hz
        rw [norm_smul, norm_inv, norm_pow, mem_sphere_zero_iff_norm.mp hz]
        refine mul_le_mul_of_nonneg_left ?_ (by positivity)
        refine (norm_mul_le _ _).trans ?_
        exact mul_le_mul (norm_pow_le _ _) (hfc_norm_resolvent_le T hr hz) (norm_nonneg _)
          (by positivity))
    refine this.trans (le_of_eq ?_)
    rw [div_pow]
    field_simp
  have hX1 : X 1 = 0 := by
    have ht : Filter.Tendsto (fun N : ℕ => 2 * π * r * (r - ‖T‖)⁻¹ * (‖T‖ / r) ^ (N + 1))
        Filter.atTop (nhds 0) := by
      have := tendsto_pow_atTop_nhds_zero_of_lt_one (div_nonneg (norm_nonneg T) hr0.le)
        ((div_lt_one hr0).mpr hr)
      simpa using (this.comp (Filter.tendsto_add_atTop_nat 1)).const_mul
        (2 * π * r * (r - ‖T‖)⁻¹)
    have : ‖X 1‖ ≤ 0 := ge_of_tendsto' ht (fun N => (hX N) ▸ hbound (N + 1))
    exact norm_le_zero_iff.mp this
  have h0 := hstep 0
  rw [hX1, add_zero, hint0] at h0
  simpa [hXdef] using h0

lemma hfc_integral_pow_smul_resolvent [Nontrivial F] (T : F →L[ℂ] F) {r : ℝ} (hr : ‖T‖ < r)
    (k : ℕ) : (∮ z in C(0, r), z ^ k • resolvent T z) = (2 * π * I) • T ^ k := by
  have hr0 : 0 < r := lt_of_le_of_lt (norm_nonneg _) hr
  have hcR : ∀ k : ℕ, CircleIntegrable (fun z : ℂ => z ^ k • resolvent T z) 0 r := fun k =>
    ContinuousOn.circleIntegrable hr0.le
      ((continuousOn_pow k).smul (hfc_continuousOn_resolvent T hr))
  induction k with
  | zero => simpa using hfc_integral_resolvent T hr
  | succ k ih =>
    have e : (∮ z in C(0, r), z ^ (k + 1) • resolvent T z) =
        ∮ z in C(0, r), (z ^ k • (1 : F →L[ℂ] F) + T * (z ^ k • resolvent T z)) := by
      apply circleIntegral.integral_congr hr0.le
      intro z hz
      have h := hfc_smul_resolvent T (hfc_mem_resolventSet T hr hz)
      simp only
      rw [pow_succ, mul_smul, h, smul_add, mul_smul_comm]
    have hc1 : CircleIntegrable (fun z : ℂ => z ^ k • (1 : F →L[ℂ] F)) 0 r :=
      ContinuousOn.circleIntegrable hr0.le ((continuousOn_pow k).smul continuousOn_const)
    have hc2 : CircleIntegrable (fun z : ℂ => T * (z ^ k • resolvent T z)) 0 r :=
      ContinuousOn.circleIntegrable hr0.le
        (continuousOn_const.mul ((continuousOn_pow k).smul (hfc_continuousOn_resolvent T hr)))
    have hzk : (∮ z in C(0, r), z ^ k) = 0 := by
      have e : ∀ z : ℂ, z ^ k = (z - 0) ^ ((k : ℕ) : ℤ) := fun z => by
        rw [sub_zero, zpow_natCast]
      simp only [e]
      exact circleIntegral.integral_sub_zpow_of_ne (by omega) 0 0 r
    rw [e, circleIntegral.integral_add hc1 hc2, circleIntegral.integral_smul_const, hzk,
      zero_smul, zero_add, hfc_integral_mul_left T (hcR k), ih, mul_smul_comm, pow_succ']

end HFCHelpers

#print axioms hfc_mem_resolventSet
#print axioms hfc_smul_resolvent
#print axioms hfc_continuousOn_resolvent
#print axioms hfc_ne_zero_of_mem_sphere
#print axioms hfc_norm_resolvent_le
#print axioms hfc_integral_mul_left
#print axioms hfc_integral_resolvent
#print axioms hfc_integral_pow_smul_resolvent

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℂ E] [CompleteSpace E]

/-- Spectral mapping theorem, polynomial case: for any bounded operator T on a complex
Banach space and any polynomial p, the spectrum of p(T) is p applied to every point of the
spectrum of T, that is σ(p(T)) = p(σ(T)). -/
theorem spectral_mapping_polynomial (T : E →L[ℂ] E) (p : ℂ[X]) :
    spectrum ℂ (aeval T p) = (fun z => p.eval z) '' spectrum ℂ T := by
  rcases subsingleton_or_nontrivial E with hE | hE
  · have : Subsingleton (E →L[ℂ] E) := ⟨fun a b => by ext x; exact Subsingleton.elim _ _⟩
    have h1 : ∀ S : E →L[ℂ] E, spectrum ℂ S = ∅ := by
      intro S
      ext k
      simp only [Set.mem_empty_iff_false, iff_false]
      intro hk
      exact (spectrum.mem_iff.mp hk) (isUnit_of_subsingleton _)
    rw [h1, h1, Set.image_empty]
  · exact spectrum.map_polynomial_aeval T p

/-- The loop integral agrees with polynomials: on a circle |z| = r with r larger than the
operator norm of T, one over 2πi times the loop integral of p(z) times the resolvent
(zI - T)⁻¹ is exactly p(T). -/
theorem loop_integral_resolvent_eq_polynomial (T : E →L[ℂ] E) (p : ℂ[X]) {r : ℝ}
    (hr : ‖T‖ < r) :
    (2 * π * I)⁻¹ • (∮ z in C(0, r), p.eval z • resolvent T z) = aeval T p := by
  rcases subsingleton_or_nontrivial E with hE | hE
  · ext x
    exact Subsingleton.elim _ _
  have hr0 : 0 < r := lt_of_le_of_lt (norm_nonneg _) hr
  have key : (∮ z in C(0, r), p.eval z • resolvent T z) = (2 * π * I) • aeval T p := by
    induction p using Polynomial.induction_on' with
    | add p q hp hq =>
      have hc : ∀ s : ℂ[X], CircleIntegrable (fun z => s.eval z • resolvent T z) 0 r :=
        fun s => ContinuousOn.circleIntegrable hr0.le
          (s.continuous.continuousOn.smul (hfc_continuousOn_resolvent T hr))
      simp only [eval_add, add_smul, map_add, smul_add]
      rw [circleIntegral.integral_add (hc p) (hc q), hp, hq]
    | monomial n a =>
      simp only [eval_monomial, aeval_monomial]
      rw [show (fun z => (a * z ^ n) • resolvent T z) = fun z => a • (z ^ n • resolvent T z) from
        funext fun z => mul_smul _ _ _]
      rw [circleIntegral.integral_smul, hfc_integral_pow_smul_resolvent T hr n,
        Algebra.algebraMap_eq_smul_one, smul_mul_assoc, one_mul, smul_comm]
  rw [key, smul_smul, inv_mul_cancel₀ two_pi_I_ne_zero, one_smul]

/-- The worked example: for A = [[1, 1], [0, 2]], one over 2πi times the loop integral of the
resolvent (zI - A)⁻¹ round the circle |z - 2| = 1/2, entry by entry, is the Riesz projection
P = [[0, 1], [0, 1]] onto the eigenvalue 2. -/
theorem riesz_projection_two_by_two :
    Matrix.of (fun i j => (2 * π * I)⁻¹ *
        ∮ z in C(2, 1 / 2),
          ((z • (1 : Matrix (Fin 2) (Fin 2) ℂ) - !![1, 1; 0, 2])⁻¹ : Matrix (Fin 2) (Fin 2) ℂ) i j) =
      !![0, 1; 0, 1] := by
  have hne : ∀ z ∈ Metric.sphere (2 : ℂ) (1 / 2), z - 1 ≠ 0 ∧ z - 2 ≠ 0 := by
    intro z hz
    rw [mem_sphere_iff_norm] at hz
    constructor
    · intro h
      have : z - 2 = -1 := by linear_combination h
      rw [this] at hz
      norm_num at hz
    · intro h
      rw [h] at hz
      norm_num at hz
  have hinv : ∀ z ∈ Metric.sphere (2 : ℂ) (1 / 2),
      ((z • (1 : Matrix (Fin 2) (Fin 2) ℂ) - !![1, 1; 0, 2])⁻¹ : Matrix (Fin 2) (Fin 2) ℂ) =
        !![(z - 1)⁻¹, ((z - 1) * (z - 2))⁻¹; 0, (z - 2)⁻¹] := by
    intro z hz
    obtain ⟨h1, h2⟩ := hne z hz
    apply Matrix.inv_eq_right_inv
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.one_apply] <;> field_simp <;> ring
  have hR : (0 : ℝ) ≤ 1 / 2 := by norm_num
  have hcont1 : ContinuousOn (fun z : ℂ => (z - 1)⁻¹) (Metric.sphere (2 : ℂ) (1 / 2)) :=
    (continuousOn_id.sub continuousOn_const).inv₀ fun z hz => (hne z hz).1
  have hcont2 : ContinuousOn (fun z : ℂ => (z - 2)⁻¹) (Metric.sphere (2 : ℂ) (1 / 2)) :=
    (continuousOn_id.sub continuousOn_const).inv₀ fun z hz => (hne z hz).2
  have hI2 : (∮ z in C(2, 1 / 2), (z - 2)⁻¹) = 2 * π * I :=
    circleIntegral.integral_sub_center_inv 2 (by norm_num)
  have hI1 : (∮ z in C(2, 1 / 2), (z - 1)⁻¹) = 0 := by
    apply DiffContOnCl.circleIntegral_eq_zero hR
    apply DifferentiableOn.diffContOnCl
    rw [closure_ball _ (by norm_num)]
    intro z hz
    have hz1 : z - 1 ≠ 0 := by
      intro h
      rw [Metric.mem_closedBall, dist_eq_norm, show z - 2 = -1 by linear_combination h] at hz
      norm_num at hz
    have hd : DifferentiableAt ℂ (fun y : ℂ => y - 1) z := differentiableAt_id.sub_const 1
    exact (hd.inv hz1).differentiableWithinAt
  have h00 : (∮ z in C(2, 1 / 2),
      ((z • (1 : Matrix (Fin 2) (Fin 2) ℂ) - !![1, 1; 0, 2])⁻¹ : Matrix (Fin 2) (Fin 2) ℂ) 0 0) =
      0 := by
    rw [circleIntegral.integral_congr hR (g := fun z => (z - 1)⁻¹), hI1]
    intro z hz
    simp [hinv z hz]
  have h01 : (∮ z in C(2, 1 / 2),
      ((z • (1 : Matrix (Fin 2) (Fin 2) ℂ) - !![1, 1; 0, 2])⁻¹ : Matrix (Fin 2) (Fin 2) ℂ) 0 1) =
      2 * π * I := by
    rw [circleIntegral.integral_congr hR (g := fun z => (z - 2)⁻¹ - (z - 1)⁻¹),
      circleIntegral.integral_sub (hcont2.circleIntegrable hR) (hcont1.circleIntegrable hR),
      hI1, hI2, sub_zero]
    intro z hz
    obtain ⟨h1, h2⟩ := hne z hz
    simp only [hinv z hz]
    simp
    field_simp
    ring
  have h10 : (∮ z in C(2, 1 / 2),
      ((z • (1 : Matrix (Fin 2) (Fin 2) ℂ) - !![1, 1; 0, 2])⁻¹ : Matrix (Fin 2) (Fin 2) ℂ) 1 0) =
      0 := by
    rw [circleIntegral.integral_congr hR (g := fun _ => (0 : ℂ))]
    · simp [circleIntegral]
    intro z hz
    simp [hinv z hz]
  have h11 : (∮ z in C(2, 1 / 2),
      ((z • (1 : Matrix (Fin 2) (Fin 2) ℂ) - !![1, 1; 0, 2])⁻¹ : Matrix (Fin 2) (Fin 2) ℂ) 1 1) =
      2 * π * I := by
    rw [circleIntegral.integral_congr hR (g := fun z => (z - 2)⁻¹), hI2]
    intro z hz
    simp [hinv z hz]
  have hpi : (2 * π * I)⁻¹ * (2 * π * I) = 1 := inv_mul_cancel₀ two_pi_I_ne_zero
  ext i j
  fin_cases i <;> fin_cases j
  · simp only [Matrix.of_apply, Fin.zero_eta, Fin.mk_one, Fin.isValue]
    rw [h00]
    simp
  · simp only [Matrix.of_apply, Fin.zero_eta, Fin.mk_one, Fin.isValue]
    rw [h01, hpi]
    simp
  · simp only [Matrix.of_apply, Fin.zero_eta, Fin.mk_one, Fin.isValue]
    rw [h10]
    simp
  · simp only [Matrix.of_apply, Fin.zero_eta, Fin.mk_one, Fin.isValue]
    rw [h11, hpi]
    simp

-- The card's whole-number worked examples, with A = [[1, 1], [0, 2]] and P = [[0, 1], [0, 1]].
-- P is a projection: P² = P.
example : (!![0, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 1; 0, 1] = !![0, 1; 0, 1] := by
  decide
-- AP = PA = [[0, 2], [0, 2]]: P commutes with A.
example : (!![1, 1; 0, 2] : Matrix (Fin 2) (Fin 2) ℤ) * !![0, 1; 0, 1] = !![0, 2; 0, 2] ∧
    (!![0, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) * !![1, 1; 0, 2] = !![0, 2; 0, 2] := by
  decide
-- P keeps the eigenvector (1, 1) and deletes the eigenvector (1, 0).
example : (!![0, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).mulVec ![1, 1] = ![1, 1] ∧
    (!![0, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).mulVec ![1, 0] = ![0, 0] := by
  decide
-- trace P = 1, and I - P = [[1, -1], [0, 0]].
example : Matrix.trace (!![0, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) = 1 := by
  decide
example : (1 : Matrix (Fin 2) (Fin 2) ℤ) - !![0, 1; 0, 1] = !![1, -1; 0, 0] := by
  decide
-- PᵀP = [[0, 0], [0, 2]], so the size of P is √2.
example : (!![0, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ).transpose * !![0, 1; 0, 1] = !![0, 0; 0, 2] := by
  decide
-- The nearest-point projection O = [[1/2, 1/2], [1/2, 1/2]] does not commute with A:
-- AO - OA = [[1/2, -1/2], [1/2, -1/2]].
example : (!![1, 1; 0, 2] : Matrix (Fin 2) (Fin 2) ℚ) * !![1/2, 1/2; 1/2, 1/2] -
    !![1/2, 1/2; 1/2, 1/2] * !![1, 1; 0, 2] = !![1/2, -1/2; 1/2, -1/2] := by
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Try changing: A² = [[1, 3], [0, 4]] and, for the Jordan block J = [[2, 1], [0, 2]], J² = [[4, 4], [0, 4]].
example : (!![1, 1; 0, 2] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = !![1, 3; 0, 4] := by
  decide
example : (!![2, 1; 0, 2] : Matrix (Fin 2) (Fin 2) ℤ) ^ 2 = !![4, 4; 0, 4] := by
  decide

#print axioms spectral_mapping_polynomial
#print axioms loop_integral_resolvent_eq_polynomial
#print axioms riesz_projection_two_by_two
