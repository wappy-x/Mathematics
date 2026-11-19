-- Hairy ball theorem: every continuous field of arrows tangent to the round globe has a calm spot, the same holds on every even-dimensional sphere, and the 3-sphere carries a field that never stops.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Geometry.Manifold.SmoothApprox
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.Analysis.SpecialFunctions.SmoothTransition
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.LinearAlgebra.Matrix.Polynomial
import Mathlib.Analysis.Complex.Tietze
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.ApproximatesLinearOn
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open RealInnerProductSpace Matrix
open Polynomial in
/-- A real polynomial squared is never a nonzero constant times `(1 + X²)^d` with `d` odd. -/
theorem hb_sq_ne_C_mul_pow {d : ℕ} (hd : Odd d) {a : ℝ} (ha : a ≠ 0) (P : ℝ[X]) :
    P ^ 2 ≠ C a * (1 + X ^ 2) ^ d := by
  intro h
  have h' := congrArg (Polynomial.map (algebraMap ℝ ℂ)) h
  simp only [Polynomial.map_pow, Polynomial.map_mul, Polynomial.map_C, Polynomial.map_add,
    Polynomial.map_one, Polynomial.map_X] at h'
  have hQ : (1 + X ^ 2 : ℂ[X]) = (X - C Complex.I) * (X - C (-Complex.I)) := by
    have : (C Complex.I) * C Complex.I = (-1 : ℂ[X]) := by
      rw [← C_mul, Complex.I_mul_I, C_neg, C_1]
    rw [C_neg]; linear_combination this
  have ha' : (algebraMap ℝ ℂ a) ≠ 0 := by simpa using ha
  have hne : (C (algebraMap ℝ ℂ a) * (1 + X ^ 2) ^ d : ℂ[X]) ≠ 0 := by
    rw [hQ]
    refine mul_ne_zero (by simpa using ha') (pow_ne_zero _ (mul_ne_zero (X_sub_C_ne_zero _)
      (X_sub_C_ne_zero _)))
  have hc := congrArg (fun p : ℂ[X] => p.roots.count Complex.I) h'
  simp only [roots_pow, roots_C_mul _ ha', hQ] at hc
  rw [roots_mul (by
      exact mul_ne_zero (X_sub_C_ne_zero _) (X_sub_C_ne_zero _))] at hc
  simp only [roots_X_sub_C, Multiset.count_nsmul, Multiset.count_add,
    Multiset.count_singleton] at hc
  have hI : Complex.I ≠ -Complex.I := by
    intro hI; have := congrArg Complex.im hI; simp at this; norm_num at this
  simp [hI] at hc
  obtain ⟨k, rfl⟩ := hd
  omega

#print axioms hb_sq_ne_C_mul_pow

open Polynomial in
theorem hb_not_poly {d : ℕ} (hd : Odd d) {a t₀ : ℝ} (ha : 0 < a) (ht₀ : 0 < t₀) (P : ℝ[X])
    (h : ∀ t ∈ Set.Icc 0 t₀, P.eval t = a * Real.sqrt (1 + t ^ 2) ^ d) : False := by
  apply hb_sq_ne_C_mul_pow hd (pow_ne_zero 2 ha.ne') P
  apply Polynomial.eq_of_infinite_eval_eq
  apply Set.Infinite.mono _ (Set.Icc_infinite ht₀)
  intro t ht
  simp only [Set.mem_ofPred_eq, eval_pow, h t ht, eval_mul, eval_C, eval_add, eval_one, eval_X]
  rw [mul_pow, ← pow_mul, mul_comm d 2, pow_mul, Real.sq_sqrt (by positivity)]

#print axioms hb_not_poly

open Polynomial in
/-- `t ↦ det (id + t • L)` is a polynomial of degree at most the dimension. -/
theorem hb_det_poly {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    (L : E →L[ℝ] E) : ∃ Q : ℝ[X], Q.natDegree ≤ Module.finrank ℝ E ∧
      ∀ t : ℝ, Q.eval t = (ContinuousLinearMap.id ℝ E + t • L).det := by
  classical
  let b := Module.finBasis ℝ E
  let M := LinearMap.toMatrix b b (L : E →ₗ[ℝ] E)
  refine ⟨Matrix.det ((X : ℝ[X]) • M.map C + (1 : Matrix (Fin _) (Fin _) ℝ).map C), ?_, ?_⟩
  · simpa using natDegree_det_X_add_C_le M (1 : Matrix (Fin _) (Fin _) ℝ)
  · intro t
    rw [ContinuousLinearMap.det, ← LinearMap.det_toMatrix b]
    have h1 : eval t (Matrix.det ((X : ℝ[X]) • M.map C + (1 : Matrix (Fin _) (Fin _) ℝ).map C))
        = Matrix.det (((X : ℝ[X]) • M.map C + (1 : Matrix (Fin _) (Fin _) ℝ).map C).map (eval t)) :=
      by simpa using RingHom.map_det (Polynomial.evalRingHom t) _
    rw [h1]
    congr 1
    ext i j
    by_cases hij : i = j
    · subst hij; simp [M, LinearMap.toMatrix_apply]; ring
    · simp [M, LinearMap.toMatrix_apply, hij]
      ring

#print axioms hb_det_poly

open Polynomial in
/-- Integrating a family of polynomials of bounded degree gives a polynomial. -/
theorem hb_integral_poly {E : Type*} [MeasurableSpace E] (μ : MeasureTheory.Measure E) (A : Set E)
    (d : ℕ) (g : E → ℝ → ℝ)
    (hg : ∀ x, ∃ Q : ℝ[X], Q.natDegree ≤ d ∧ ∀ t, Q.eval t = g x t)
    (hint : ∀ t, MeasureTheory.IntegrableOn (fun x => g x t) A μ) :
    ∃ P : ℝ[X], ∀ t, ∫ x in A, g x t ∂μ = P.eval t := by
  classical
  let s : Finset (Fin (d + 1)) := Finset.univ
  let v : Fin (d + 1) → ℝ := fun i => ((i : ℕ) : ℝ)
  have hv : Set.InjOn v s := fun i _ j _ hij => Fin.ext (by simpa [v] using hij)
  have key : ∀ x t, g x t = ∑ i ∈ s, g x (v i) * (Lagrange.basis s v i).eval t := by
    intro x t
    obtain ⟨Q, hQd, hQ⟩ := hg x
    have hdeg : Q.degree < s.card := by
      refine lt_of_le_of_lt degree_le_natDegree ?_
      simp only [s, Finset.card_univ, Fintype.card_fin]
      exact_mod_cast Nat.lt_succ_of_le hQd
    rw [← hQ t, Lagrange.eq_interpolate hv hdeg, Lagrange.interpolate_apply, eval_finsetSum]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [eval_mul, eval_C, hQ]
  refine ⟨∑ i ∈ s, C (∫ x in A, g x (v i) ∂μ) * Lagrange.basis s v i, fun t => ?_⟩
  rw [eval_finsetSum]
  simp_rw [key _ t]
  rw [MeasureTheory.integral_finsetSum _ (fun i _ => (hint (v i)).mul_const _)]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [MeasureTheory.integral_mul_const, eval_mul, eval_C]

#print axioms hb_integral_poly

open RealInnerProductSpace in
/-- A nowhere-zero continuous tangent field on the unit sphere can be replaced by a smooth map on
the whole space that is tangent and nonzero at every point of the sphere. -/
theorem hb_smooth_tangent {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E]
    (X : Metric.sphere (0 : E) 1 → E) (hcont : Continuous X)
    (htangent : ∀ x : Metric.sphere (0 : E) 1, ⟪(x : E), X x⟫ = 0) (hne : ∀ x, X x ≠ 0) :
    ∃ w : E → E, ContDiff ℝ 1 w ∧ ∀ y : E, ‖y‖ = 1 → ⟪y, w y⟫ = 0 ∧ w y ≠ 0 := by
  let v : C(Metric.sphere (0 : E) 1, E) :=
    ⟨fun x => ‖X x‖⁻¹ • X x, (hcont.norm.inv₀ fun x => norm_ne_zero_iff.mpr (hne x)).smul hcont⟩
  obtain ⟨V, hV⟩ := ContinuousMap.exists_extension
    (Metric.isClosed_sphere.isClosedEmbedding_subtypeVal) v
  have hVv : ∀ p : Metric.sphere (0 : E) 1, V p = v p := fun p => DFunLike.congr_fun hV p
  obtain ⟨G, hG, hGV, -⟩ := Continuous.exists_contDiff_approx (f := V) 1 V.continuous
    continuous_const (fun _ => (by norm_num : (0 : ℝ) < 1 / 4))
  have hG1 : ContDiff ℝ 1 G := by exact_mod_cast hG
  refine ⟨fun y => G y - ⟪G y, y⟫ • y, hG1.sub ((hG1.inner ℝ contDiff_id).smul contDiff_id), ?_⟩
  intro y hy
  have hyy : ⟪y, y⟫ = 1 := by rw [real_inner_self_eq_norm_sq, hy]; norm_num
  refine ⟨?_, ?_⟩
  · rw [inner_sub_right, inner_smul_right, hyy, real_inner_comm]; ring
  · let p : Metric.sphere (0 : E) 1 := ⟨y, by simpa using hy⟩
    have hVy : V y = v p := hVv p
    have hv1 : ‖v p‖ = 1 := by
      simp only [v, ContinuousMap.coe_mk, norm_smul, norm_inv, norm_norm]
      exact inv_mul_cancel₀ (norm_ne_zero_iff.mpr (hne p))
    have hvt : ⟪v p, y⟫ = 0 := by
      simp only [v, ContinuousMap.coe_mk, inner_smul_left]
      rw [real_inner_comm, htangent p]; simp
    set e := G y - V y with he
    have he' : ‖e‖ < 1 / 4 := by rw [← dist_eq_norm]; exact hGV y
    have hGy : G y = V y + e := by rw [he]; abel
    have hw : G y - ⟪G y, y⟫ • y - V y = e - ⟪e, y⟫ • y := by
      rw [hGy, inner_add_left, hVy, hvt, zero_add]; abel
    have hb : ‖G y - ⟪G y, y⟫ • y - V y‖ < 1 / 2 := by
      rw [hw]
      calc ‖e - ⟪e, y⟫ • y‖ ≤ ‖e‖ + ‖⟪e, y⟫ • y‖ := norm_sub_le _ _
        _ ≤ ‖e‖ + ‖e‖ := by
          gcongr
          rw [norm_smul, hy, mul_one, Real.norm_eq_abs]
          simpa [hy] using abs_real_inner_le_norm e y
        _ < 1 / 2 := by linarith
    intro h0
    simp only at h0
    rw [h0, zero_sub, norm_neg, hVy, hv1] at hb
    norm_num at hb

#print axioms hb_smooth_tangent

open RealInnerProductSpace in
/-- From a smooth map that is tangent and nonzero on the unit sphere, build a smooth, compactly
supported field `U` that is tangent to every sphere about `0`, never longer than `‖x‖`, and of
length exactly `‖x‖` when `1/4 ≤ ‖x‖ ≤ 2`. -/
theorem hb_radial_field {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E]
    (w : E → E) (hw : ContDiff ℝ 1 w) (hwt : ∀ y : E, ‖y‖ = 1 → ⟪y, w y⟫ = 0 ∧ w y ≠ 0) :
    ∃ U : E → E, ContDiff ℝ 1 U ∧ HasCompactSupport U ∧ (∀ x, ⟪x, U x⟫ = 0) ∧
      (∀ x, ‖U x‖ ≤ ‖x‖) ∧ (∀ x, 1 / 4 ≤ ‖x‖ → ‖x‖ ≤ 2 → ‖U x‖ = ‖x‖) := by
  let φ : ℝ → ℝ := fun s => Real.smoothTransition (32 * s - 1) * Real.smoothTransition (5 - s)
  have hφ0 : ∀ s, 0 ≤ φ s := fun s =>
    mul_nonneg (Real.smoothTransition.nonneg _) (Real.smoothTransition.nonneg _)
  have hφ1 : ∀ s, φ s ≤ 1 := fun s => by
    simp only [φ]
    nlinarith [Real.smoothTransition.le_one (32 * s - 1), Real.smoothTransition.nonneg (32 * s - 1),
      Real.smoothTransition.le_one (5 - s), Real.smoothTransition.nonneg (5 - s)]
  have hφc : ContDiff ℝ 1 φ := by
    have h := (Real.smoothTransition.contDiff (n := 1))
    exact (h.comp ((contDiff_const.mul contDiff_id).sub contDiff_const)).mul
      (h.comp (contDiff_const.sub contDiff_id))
  have hunit : ∀ x : E, x ≠ 0 → ‖‖x‖⁻¹ • x‖ = 1 := fun x hx => by
    rw [norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ (norm_ne_zero_iff.mpr hx)]
  let U : E → E := fun x => (φ (‖x‖ ^ 2) * ‖x‖ * ‖w (‖x‖⁻¹ • x)‖⁻¹) • w (‖x‖⁻¹ • x)
  have hUn : ∀ x : E, x ≠ 0 → ‖U x‖ = φ (‖x‖ ^ 2) * ‖x‖ := by
    intro x hx
    have hne : ‖w (‖x‖⁻¹ • x)‖ ≠ 0 := norm_ne_zero_iff.mpr (hwt _ (hunit x hx)).2
    simp only [U, norm_smul, Real.norm_eq_abs]
    rw [abs_of_nonneg (by have := hφ0 (‖x‖ ^ 2); positivity), mul_assoc, inv_mul_cancel₀ hne,
      mul_one]
  refine ⟨U, ?_, ?_, ?_, ?_, ?_⟩
  · rw [contDiff_iff_contDiffAt]
    intro x
    by_cases hx : ‖x‖ ^ 2 < 1 / 32
    · apply contDiffAt_const (c := (0 : E)).congr_of_eventuallyEq
      have ho : IsOpen {y : E | ‖y‖ ^ 2 < 1 / 32} :=
        isOpen_lt (continuous_norm.pow 2) continuous_const
      filter_upwards [ho.mem_nhds hx] with y hy
      have : φ (‖y‖ ^ 2) = 0 := by
        simp only [φ]
        rw [Real.smoothTransition.zero_of_nonpos (by linarith),
          zero_mul]
      simp [U, this]
    · have hx0 : x ≠ 0 := by
        rintro rfl; norm_num at hx
      have hn : ContDiffAt ℝ 1 (fun y : E => ‖y‖) x := contDiffAt_norm ℝ hx0
      have hu : ContDiffAt ℝ 1 (fun y : E => ‖y‖⁻¹ • y) x :=
        (hn.inv (norm_ne_zero_iff.mpr hx0)).smul contDiffAt_id
      have hwu : ContDiffAt ℝ 1 (fun y : E => w (‖y‖⁻¹ • y)) x := hw.contDiffAt.comp x hu
      have hne : w (‖x‖⁻¹ • x) ≠ 0 := (hwt _ (hunit x hx0)).2
      have hwn : ContDiffAt ℝ 1 (fun y : E => ‖w (‖y‖⁻¹ • y)‖) x := ContDiffAt.norm ℝ hwu hne
      have hφx : ContDiffAt ℝ 1 (fun y : E => φ (‖y‖ ^ 2)) x :=
        (hφc.comp (contDiff_norm_sq ℝ)).contDiffAt
      exact ((hφx.mul hn).mul (hwn.inv (norm_ne_zero_iff.mpr hne))).smul hwu
  · refine HasCompactSupport.intro (isCompact_closedBall (0 : E) 3) fun x hx => ?_
    have h3 : 3 < ‖x‖ := by simpa using hx
    have : φ (‖x‖ ^ 2) = 0 := by
      simp only [φ]
      rw [Real.smoothTransition.zero_of_nonpos (x := 5 - ‖x‖ ^ 2) (by nlinarith), mul_zero]
    simp [U, this]
  · intro x
    by_cases hx : x = 0
    · simp [hx]
    · simp only [U, inner_smul_right]
      have h := (hwt _ (hunit x hx)).1
      rw [inner_smul_left] at h
      have : ⟪x, w (‖x‖⁻¹ • x)⟫ = 0 := by
        simpa [norm_ne_zero_iff.mpr hx] using h
      rw [this, mul_zero]
  · intro x
    by_cases hx : x = 0
    · simp [hx, U]
    · rw [hUn x hx]
      exact mul_le_of_le_one_left (norm_nonneg _) (hφ1 _)
  · intro x h1 h2
    have hx : x ≠ 0 := by rintro rfl; norm_num at h1
    rw [hUn x hx]
    have : φ (‖x‖ ^ 2) = 1 := by
      simp only [φ]
      rw [Real.smoothTransition.one_of_one_le (by nlinarith),
        Real.smoothTransition.one_of_one_le (by nlinarith), mul_one]
    rw [this, one_mul]

#print axioms hb_radial_field

/-- If `‖t • M‖ < 1` then `id + t • M` has positive determinant. -/
theorem hb_det_pos {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    (M : E →L[ℝ] E) {L t : ℝ} (hM : ‖M‖ ≤ L) (ht : 0 ≤ t) (htL : t * L < 1) :
    0 < (ContinuousLinearMap.id ℝ E + t • M).det := by
  have hne : ∀ s ∈ Set.Icc (0 : ℝ) t, (ContinuousLinearMap.id ℝ E + s • M).det ≠ 0 := by
    intro s hs
    have hsL : s * L < 1 := by
      have hL0 : 0 ≤ L := (norm_nonneg _).trans hM
      nlinarith [hs.1, hs.2]
    have hker : LinearMap.ker ((ContinuousLinearMap.id ℝ E + s • M : E →L[ℝ] E) : E →ₗ[ℝ] E)
        = ⊥ := by
      rw [LinearMap.ker_eq_bot']
      intro v hv
      simp only [ContinuousLinearMap.coe_coe, add_apply,
        ContinuousLinearMap.coe_id', id_eq, FunLike.coe_smul, Pi.smul_apply] at hv
      have hv' : v = -(s • M v) := eq_neg_of_add_eq_zero_left hv
      have h1 : ‖v‖ ≤ s * (L * ‖v‖) := by
        have hvn : ‖v‖ = ‖s • M v‖ := by
          have := congrArg norm hv'
          rwa [norm_neg] at this
        calc ‖v‖ = ‖s • M v‖ := hvn
          _ = s * ‖M v‖ := by rw [norm_smul, Real.norm_of_nonneg hs.1]
          _ ≤ s * (L * ‖v‖) := by
            gcongr
            · exact hs.1
            · exact (M.le_opNorm v).trans (by gcongr)
      have : ‖v‖ ≤ 0 := by nlinarith [norm_nonneg v, hs.1]
      exact norm_le_zero_iff.mp this
    have hu := (LinearMap.isUnit_iff_isUnit_det _).1 ((LinearMap.isUnit_iff_ker_eq_bot _).2 hker)
    exact hu.ne_zero
  by_contra hneg
  replace hneg := not_lt.mp hneg
  have hlt : (ContinuousLinearMap.id ℝ E + t • M).det < 0 :=
    lt_of_le_of_ne hneg (hne t ⟨ht, le_rfl⟩)
  have hcont : ContinuousOn (fun s : ℝ => (ContinuousLinearMap.id ℝ E + s • M).det)
      (Set.Icc 0 t) :=
    (ContinuousLinearMap.continuous_det.comp
      (continuous_const.add (continuous_id.smul continuous_const))).continuousOn
  obtain ⟨s, hs, hs0⟩ := intermediate_value_Icc' ht hcont
    (show (0 : ℝ) ∈ Set.Icc _ _ from ⟨hlt.le, by simp [ContinuousLinearMap.det]⟩)
  exact hne s hs hs0

#print axioms hb_det_pos

open RealInnerProductSpace MeasureTheory Pointwise in
/-- Milnor's volume argument: in odd dimension there is no smooth compactly supported field `U`
tangent to the spheres about `0` with `‖U x‖ = ‖x‖` on the shell `1/4 ≤ ‖x‖ ≤ 2`. -/
theorem hb_no_radial_field {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E] [MeasurableSpace E] [BorelSpace E] (μ : Measure E)
    [μ.IsAddHaarMeasure] (hd : Odd (Module.finrank ℝ E))
    (U : E → E) (hU : ContDiff ℝ 1 U) (hUc : HasCompactSupport U)
    (horth : ∀ x, ⟪x, U x⟫ = 0) (hle : ∀ x, ‖U x‖ ≤ ‖x‖)
    (heq : ∀ x, 1 / 4 ≤ ‖x‖ → ‖x‖ ≤ 2 → ‖U x‖ = ‖x‖) : False := by
  set d := Module.finrank ℝ E with hd_def
  have : Nontrivial E := Module.finrank_pos_iff.mp hd.pos
  obtain ⟨L, hL⟩ := ContDiff.lipschitzWith_of_hasCompactSupport hUc hU one_ne_zero
  have hL0 : (0 : ℝ) ≤ L := L.2
  set t₀ : ℝ := 1 / ((L : ℝ) + 2) with ht₀_def
  have ht₀ : 0 < t₀ := by positivity
  have ht₀h : t₀ ≤ 1 / 2 := by
    rw [ht₀_def]; exact one_div_le_one_div_of_le (by norm_num) (by linarith)
  have ht₀L : t₀ * L < 1 := by
    rw [ht₀_def, one_div_mul_eq_div, div_lt_one (by positivity)]; linarith
  -- the shell `A`
  set A : Set E := Metric.closedBall (0 : E) 1 \ Metric.ball 0 (1 / 2) with hA_def
  have hmemA : ∀ x, x ∈ A ↔ 1 / 2 ≤ ‖x‖ ∧ ‖x‖ ≤ 1 := by
    intro x; simp [hA_def, and_comm]
  have hAc : IsCompact A := (isCompact_closedBall _ _).diff Metric.isOpen_ball
  have hAm : MeasurableSet A := measurableSet_closedBall.diff measurableSet_ball
  have hAfin : μ A ≠ ⊤ := hAc.measure_lt_top.ne
  have hApos : 0 < μ A := by
    obtain ⟨z, hz⟩ := exists_norm_eq E (show (0 : ℝ) ≤ 3 / 4 by norm_num)
    refine lt_of_lt_of_le (Metric.measure_ball_pos μ z (show (0 : ℝ) < 1 / 4 by norm_num))
      (measure_mono fun y hy => ?_)
    rw [Metric.mem_ball, dist_eq_norm] at hy
    rw [hmemA]
    have h1 := norm_sub_norm_le y z
    have h2 := norm_sub_norm_le z y
    rw [norm_sub_rev z y] at h2
    constructor <;> linarith
  set a := (μ A).toReal with ha_def
  have ha : 0 < a := ENNReal.toReal_pos hApos.ne' hAfin
  -- derivatives
  set M : E → E →L[ℝ] E := fun x => fderiv ℝ U x with hM_def
  have hMc : Continuous M := hU.continuous_fderiv one_ne_zero
  have hML : ∀ x, ‖M x‖ ≤ L := fun x => norm_fderiv_le_of_lipschitz ℝ hL
  set g : E → ℝ → ℝ := fun x t => (ContinuousLinearMap.id ℝ E + t • M x).det with hg_def
  have hgc : ∀ t, Continuous fun x => g x t := fun t =>
    ContinuousLinearMap.continuous_det.comp (continuous_const.add (hMc.const_smul t))
  have hint : ∀ t, IntegrableOn (fun x => g x t) A μ := fun t =>
    (hgc t).continuousOn.integrableOn_compact hAc
  obtain ⟨P, hP⟩ := hb_integral_poly μ A d g (fun x => hb_det_poly (M x)) hint
  apply hb_not_poly hd ha ht₀ P
  intro t ht
  obtain ⟨ht0, htt⟩ := ht
  have htL : t * L < 1 := lt_of_le_of_lt (by gcongr) ht₀L
  have ht1 : t ≤ 1 / 2 := htt.trans ht₀h
  set f : E → E := fun x => x + t • U x with hf_def
  have hf' : ∀ x, HasFDerivAt f (ContinuousLinearMap.id ℝ E + t • M x) x := fun x =>
    (hasFDerivAt_id x).add (((hU.differentiable one_ne_zero) x).hasFDerivAt.const_smul t)
  have happrox : ApproximatesLinearOn f
      ((ContinuousLinearEquiv.refl ℝ E : E ≃L[ℝ] E) : E →L[ℝ] E) Set.univ (Real.toNNReal t * L) := by
    intro x _ y _
    have : f x - f y - ((ContinuousLinearEquiv.refl ℝ E : E ≃L[ℝ] E) : E →L[ℝ] E) (x - y)
        = t • (U x - U y) := by
      simp only [hf_def, ContinuousLinearEquiv.coe_coe, ContinuousLinearEquiv.coe_refl',
        id_eq, smul_sub]
      abel
    rw [this, norm_smul, Real.norm_of_nonneg ht0, NNReal.coe_mul, Real.coe_toNNReal _ ht0,
      mul_assoc]
    gcongr
    exact hL.norm_sub_le x y
  have hc : Subsingleton E ∨ Real.toNNReal t * L <
      ‖(((ContinuousLinearEquiv.refl ℝ E).symm : E ≃L[ℝ] E) : E →L[ℝ] E)‖₊⁻¹ := by
    right
    have h1 : (((ContinuousLinearEquiv.refl ℝ E).symm : E ≃L[ℝ] E) : E →L[ℝ] E)
        = ContinuousLinearMap.id ℝ E := rfl
    rw [h1, ContinuousLinearMap.nnnorm_id, inv_one, ← NNReal.coe_lt_coe, NNReal.coe_mul,
      Real.coe_toNNReal _ ht0, NNReal.coe_one]
    exact htL
  have hinj : Set.InjOn f A := (happrox.injOn hc).mono (Set.subset_univ _)
  have hsurj : Function.Surjective f := happrox.surjective hc
  -- norms along `f`
  have hnormf : ∀ x, ‖f x‖ ^ 2 = ‖x‖ ^ 2 + t ^ 2 * ‖U x‖ ^ 2 := by
    intro x
    simp only [hf_def]
    rw [norm_add_sq_real, inner_smul_right, horth, norm_smul, Real.norm_of_nonneg ht0]
    ring
  set s := Real.sqrt (1 + t ^ 2) with hs_def
  have hs0 : 0 < s := Real.sqrt_pos.mpr (by positivity)
  have hs2 : s ^ 2 = 1 + t ^ 2 := Real.sq_sqrt (by positivity)
  have hs1 : 1 ≤ s := by nlinarith
  have hs2' : s ≤ 2 := by nlinarith
  have hfeq : ∀ x, 1 / 4 ≤ ‖x‖ → ‖x‖ ≤ 2 → ‖f x‖ = s * ‖x‖ := by
    intro x h1 h2
    refine (sq_eq_sq₀ (norm_nonneg _) (by positivity)).1 ?_
    rw [hnormf, heq x h1 h2, mul_pow, hs2]; ring
  have himage : f '' A = s • A := by
    ext y
    constructor
    · rintro ⟨x, hx, rfl⟩
      rw [hmemA] at hx
      have hfx := hfeq x (by linarith [hx.1]) (by linarith [hx.2])
      refine Set.mem_smul_set.2 ⟨s⁻¹ • f x, ?_, ?_⟩
      · rw [hmemA, norm_smul, norm_inv, Real.norm_of_nonneg hs0.le, hfx, ← mul_assoc,
          inv_mul_cancel₀ hs0.ne', one_mul]
        exact hx
      · rw [smul_smul, mul_inv_cancel₀ hs0.ne', one_smul]
    · rintro ⟨z, hz, rfl⟩
      rw [hmemA] at hz
      obtain ⟨x, hx⟩ := hsurj (s • z)
      have hy : ‖f x‖ = s * ‖z‖ := by rw [hx, norm_smul, Real.norm_of_nonneg hs0.le]
      have hfx2 := hnormf x
      have hUx := hle x
      have hUx0 := norm_nonneg (U x)
      have hx0 := norm_nonneg x
      have hxle : ‖x‖ ≤ 2 := by
        have : ‖x‖ ^ 2 ≤ ‖f x‖ ^ 2 := by rw [hfx2]; nlinarith
        have h' : ‖x‖ ≤ ‖f x‖ := by nlinarith [norm_nonneg (f x)]
        rw [hy] at h'
        nlinarith [hz.2]
      have hxge : 1 / 4 ≤ ‖x‖ := by
        have : ‖f x‖ ^ 2 ≤ (s * ‖x‖) ^ 2 := by
          rw [hfx2, mul_pow, hs2]; nlinarith [mul_le_mul hUx hUx hUx0 hx0]
        have h' : ‖f x‖ ≤ s * ‖x‖ :=
          (pow_le_pow_iff_left₀ (norm_nonneg _) (by positivity) two_ne_zero).1 this
        rw [hy] at h'
        have : ‖z‖ ≤ ‖x‖ := le_of_mul_le_mul_left h' hs0
        linarith [hz.1]
      have hfx := hfeq x hxge hxle
      rw [hy] at hfx
      have hxz : ‖x‖ = ‖z‖ := (mul_left_cancel₀ hs0.ne' hfx).symm
      exact ⟨x, by rw [hmemA, hxz]; exact hz, hx⟩
  -- change of variables
  have hcov := lintegral_abs_det_fderiv_eq_addHaar_image μ hAm
    (fun x _ => (hf' x).hasFDerivWithinAt) hinj
  rw [himage, Measure.addHaar_smul, ← ENNReal.ofReal_toReal hAfin, ← ha_def,
    ← ENNReal.ofReal_mul (abs_nonneg _)] at hcov
  have hpos : ∀ x, 0 < g x t := fun x => hb_det_pos (M x) (hML x) ht0 htL
  have hlin : ∫⁻ x in A, ENNReal.ofReal |(ContinuousLinearMap.id ℝ E + t • M x).det| ∂μ
      = ENNReal.ofReal (∫ x in A, g x t ∂μ) := by
    rw [ofReal_integral_eq_lintegral_ofReal (hint t)
      (Filter.Eventually.of_forall fun x => (hpos x).le)]
    refine lintegral_congr fun x => ?_
    rw [abs_of_pos (hpos x)]
  rw [hlin, ENNReal.ofReal_eq_ofReal_iff (setIntegral_nonneg hAm fun x _ => (hpos x).le)
    (by positivity)] at hcov
  rw [← hP t, hcov, abs_of_nonneg (by positivity)]
  ring

#print axioms hb_no_radial_field

open RealInnerProductSpace in
/-- The general form: on the unit sphere of an odd-dimensional real inner product space, every
continuous tangent field has a zero. -/
theorem hb_odd_dim_field_has_zero {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E] [MeasurableSpace E] [BorelSpace E]
    (hd : Odd (Module.finrank ℝ E))
    (X : Metric.sphere (0 : E) 1 → E) (hcont : Continuous X)
    (htangent : ∀ x : Metric.sphere (0 : E) 1, ⟪(x : E), X x⟫ = 0) :
    ∃ x, X x = 0 := by
  by_contra h
  have hne : ∀ x, X x ≠ 0 := fun x hx => h ⟨x, hx⟩
  obtain ⟨w, hw, hwt⟩ := hb_smooth_tangent X hcont htangent hne
  obtain ⟨U, hU, hUc, horth, hle, heq⟩ := hb_radial_field w hw hwt
  exact hb_no_radial_field MeasureTheory.Measure.addHaar hd U hU hUc horth hle heq

#print axioms hb_odd_dim_field_has_zero


/-- The hairy ball theorem, the globe's case of Poincaré–Hopf. Take the globe as the unit sphere
in three-dimensional space. A field `X` that puts an arrow `X x` at each point `x` of the globe,
changing continuously and lying along the surface (perpendicular to the radius `x`), has at least
one calm spot: a point where the arrow has length zero. -/
theorem hairy_ball_field_on_sphere_has_zero
    (X : Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1 → EuclideanSpace ℝ (Fin 3))
    (hcont : Continuous X)
    (htangent : ∀ x : Metric.sphere (0 : EuclideanSpace ℝ (Fin 3)) 1,
      ⟪(x : EuclideanSpace ℝ (Fin 3)), X x⟫ = 0) :
    ∃ x, X x = 0 := by
  exact hb_odd_dim_field_has_zero (by simp only [finrank_euclideanSpace_fin]; exact ⟨1, rfl⟩) X
    hcont htangent

/-- Beyond surfaces: on a sphere of even dimension `n` (the unit sphere in `n + 1`-dimensional
space), every continuous tangent field stops somewhere. -/
theorem even_sphere_field_has_zero (n : ℕ) (heven : Even n)
    (X : Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) 1 → EuclideanSpace ℝ (Fin (n + 1)))
    (hcont : Continuous X)
    (htangent : ∀ x : Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) 1,
      ⟪(x : EuclideanSpace ℝ (Fin (n + 1))), X x⟫ = 0) :
    ∃ x, X x = 0 := by
  exact hb_odd_dim_field_has_zero (by simpa using heven.add_one) X hcont htangent

/-- On the 3-sphere, the points `(x₁, x₂, x₃, x₄)` at distance 1 from the origin in
four-dimensional space, the field `(−x₂, x₁, −x₄, x₃)` lies along the sphere and has length 1
everywhere, so it never stops: an odd-dimensional sphere needs no calm spot. -/
theorem three_sphere_field_never_stops (x : EuclideanSpace ℝ (Fin 4))
    (hx : x ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin 4)) 1) :
    ⟪x, !₂[-x 1, x 0, -x 3, x 2]⟫ = 0 ∧ ‖(!₂[-x 1, x 0, -x 3, x 2] : EuclideanSpace ℝ (Fin 4))‖ = 1 := by
  have hx1 : ‖x‖ = 1 := by simpa using hx
  constructor
  · simp [PiLp.inner_apply, Fin.sum_univ_four]
    ring
  · rw [EuclideanSpace.norm_eq] at hx1 ⊢
    rw [← hx1]
    congr 1
    simp [Fin.sum_univ_four]
    ring

/-- The worked map: 4 highs and 4 lows (index +1 each) and 6 cols (index −1 each) add to 2. -/
example : (4 : ℤ) * 1 + 4 * 1 + 6 * (-1) = 2 := by norm_num

/-- The globe has no holes: `χ = 2 − 2g` with `g = 0` is 2. -/
example : (2 : ℤ) - 2 * 0 = 2 := by norm_num

/-- The doughnut has one hole: `χ = 2 − 2 · 1 = 0`. -/
example : (2 : ℤ) - 2 * 1 = 0 := by norm_num

/-- The code's globe grid: `V − E + F = 488 − 972 + 486 = 2`. -/
example : (488 : ℤ) - 972 + 486 = 2 := by norm_num

/-- The doughnut grid, 6 by 6 glued edge to edge: `V − E + F = 36 − 72 + 36 = 0`. -/
example : (36 : ℤ) - 72 + 36 = 0 := by norm_num

/-- The doughnut world's indices `+1, +1, −1, −1` add to 0. -/
example : (1 : ℤ) + 1 + (-1) + (-1) = 0 := by norm_num

/-- Counting every calm spot as +1 gives 14, not 2. -/
example : (4 : ℤ) + 4 + 6 = 14 := by norm_num

/-- Walking every loop clockwise flips each index: the total becomes −2. -/
example : (4 : ℤ) * (-1) + 4 * (-1) + 6 * 1 = -2 := by norm_num

/-- The 60° loop round the North Pole holds the col and 2 highs and 2 lows: −1 + 1 + 1 + 1 + 1 = 3. -/
example : (-1 : ℤ) + 1 + 1 + 1 + 1 = 3 := by norm_num

/-- Source `(u, v)`: the linear part has determinant +1. -/
example : det !![(1 : ℤ), 0; 0, 1] = 1 := by simp [det_fin_two_of]

/-- Sink `(−u, −v)`: determinant +1. -/
example : det !![(-1 : ℤ), 0; 0, -1] = 1 := by simp [det_fin_two_of]

/-- Vortex `(−v, u)`, the quarter turn: determinant +1. -/
example : det !![(0 : ℤ), -1; 1, 0] = 1 := by simp [det_fin_two_of]

/-- Saddle `(u, −v)`, a col: determinant −1. -/
example : det !![(1 : ℤ), 0; 0, -1] = -1 := by simp [det_fin_two_of]

#print axioms hairy_ball_field_on_sphere_has_zero
#print axioms even_sphere_field_has_zero
#print axioms three_sphere_field_never_stops
