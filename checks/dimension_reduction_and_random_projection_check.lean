-- Random projection: a k by d table of independent standard normal draws, scaled by 1/√k, keeps every squared distance among n fixed points within 1 ± ε except with chance at most δ once k ≥ 2 ln(n(n-1)/δ) / (ε²/2 - ε³/3), whatever d is.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Probability.Distributions.Gaussian.HasGaussianLaw.Independence
import Mathlib.Probability.Moments.Basic
import Mathlib.Probability.Moments.Covariance
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

/-! The card's objects. A point is a vector in `EuclideanSpace ℝ (Fin d)`, whose norm is the
square root of the sum of squared entries. The table `R` has `k` rows and `d` columns, entry
`R (i, j)`. Its entries are random: functions on a probability space `Ω`, independent, each with
law `gaussianReal 0 1`. The points are fixed numbers, chosen before the table is drawn. -/

open MeasureTheory ProbabilityTheory

namespace RandomProjection

/-- The projection `f(x) = R x / √k` for one fixed table `R`: entry `i` is
`(1/√k) (R (i,1) x_1 + … + R (i,d) x_d)`. -/
noncomputable def proj {k d : ℕ} (R : Fin k × Fin d → ℝ) (x : EuclideanSpace ℝ (Fin d)) :
    EuclideanSpace ℝ (Fin k) :=
  WithLp.toLp 2 (fun i => (1 / Real.sqrt k) * ∑ j, R (i, j) * x j)

variable {Ω : Type*} [MeasurableSpace Ω]


lemma integral_exp_mul_sq_gaussianReal {v : NNReal} (hv : v ≠ 0) {t : ℝ}
    (ht : 2 * t * v < 1) :
    ∫ w, Real.exp (t * w ^ 2) ∂gaussianReal 0 v = 1 / Real.sqrt (1 - 2 * t * v) := by
  have hvpos : (0 : ℝ) < v := by positivity
  rw [integral_gaussianReal_eq_integral_smul hv]
  have hb : 0 < 1 / (2 * (v : ℝ)) - t := by
    rw [sub_pos, lt_div_iff₀ (by positivity)]; linarith
  have h1 : ∀ w : ℝ, gaussianPDFReal 0 v w • Real.exp (t * w ^ 2) =
      (Real.sqrt (2 * Real.pi * v))⁻¹ * Real.exp (-(1 / (2 * (v : ℝ)) - t) * w ^ 2) := by
    intro w
    rw [gaussianPDFReal, smul_eq_mul, mul_assoc, ← Real.exp_add]
    congr 2
    field_simp
    ring
  simp_rw [h1]
  rw [integral_const_mul, integral_gaussian]
  have h2 : 1 - 2 * t * v = (2 * v) * (1 / (2 * (v : ℝ)) - t) := by field_simp
  rw [h2, Real.sqrt_div' _ hb.le, Real.sqrt_mul (by positivity), Real.sqrt_mul (by positivity)]
  have : (0 : ℝ) < Real.sqrt (1 / (2 * (v : ℝ)) - t) := Real.sqrt_pos.2 hb
  have : (0 : ℝ) < Real.sqrt v := Real.sqrt_pos.2 hvpos
  have : (0 : ℝ) < Real.sqrt Real.pi := Real.sqrt_pos.2 Real.pi_pos
  rw [Real.sqrt_mul (by positivity)]
  field_simp
  rw [Real.sqrt_mul (by norm_num : (0:ℝ) ≤ 2)]

#print axioms integral_exp_mul_sq_gaussianReal

lemma norm_proj_sq {k d : ℕ} (R : Fin k × Fin d → ℝ) (x : EuclideanSpace ℝ (Fin d)) :
    ‖proj R x‖ ^ 2 = (1 / (k : ℝ)) * ∑ i, (∑ j, R (i, j) * x j) ^ 2 := by
  rw [EuclideanSpace.real_norm_sq_eq, Finset.mul_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  simp only [proj, PiLp.toLp_apply, mul_pow, div_pow, one_pow, Real.sq_sqrt (Nat.cast_nonneg k)]

#print axioms norm_proj_sq

lemma proj_sub {k d : ℕ} (R : Fin k × Fin d → ℝ) (x y : EuclideanSpace ℝ (Fin d)) :
    proj R x - proj R y = proj R (x - y) := by
  ext i
  simp [proj, mul_sub, Finset.sum_sub_distrib]

#print axioms proj_sub

lemma aemeasurable_of_map_eq {P : Measure Ω} {X : Ω → ℝ} (h : P.map X = gaussianReal 0 1) :
    AEMeasurable X P := by
  by_contra hX
  have hP : P ≠ 0 := by
    rintro rfl
    rw [Measure.map_zero] at h
    have h1 : (gaussianReal 0 1) Set.univ = 1 := measure_univ
    rw [← h] at h1
    simp at h1
  rw [Measure.map_of_not_aemeasurable_of_ne_zero hX hP] at h
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  have h1 := congrArg (fun m : Measure ℝ => m {Classical.ofNonempty}) h
  simp at h1

#print axioms aemeasurable_of_map_eq


section Gauss

variable {k d : ℕ} {P : Measure Ω} [IsProbabilityMeasure P] {R : Fin k × Fin d → Ω → ℝ}

omit [IsProbabilityMeasure P] in
lemma hasGaussianLaw_entry (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (ij : Fin k × Fin d) : HasGaussianLaw (R ij) P where
  aemeasurable := aemeasurable_of_map_eq (hlaw ij)
  isGaussian_map := by rw [hlaw ij]; infer_instance

#print axioms hasGaussianLaw_entry

omit [IsProbabilityMeasure P] in
lemma entry_moments (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1) (ij : Fin k × Fin d) :
    P[R ij] = 0 ∧ Var[R ij; P] = 1 := by
  have h := (hasGaussianLaw_entry hlaw ij).map_eq_gaussianReal
  rw [hlaw ij, gaussianReal_ext_iff] at h
  obtain ⟨h1, h2⟩ := h
  refine ⟨h1.symm, ?_⟩
  have h0 := variance_nonneg (R ij) P
  have h3 := congrArg (fun v : NNReal => (v : ℝ)) h2
  simp only [NNReal.coe_one, Real.coe_toNNReal _ h0] at h3
  linarith

#print axioms entry_moments

omit [IsProbabilityMeasure P] in
lemma cov_entry (hind : iIndepFun R P) (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (a b : Fin k × Fin d) : cov[R a, R b; P] = if a = b then 1 else 0 := by
  split_ifs with hab
  · subst hab
    rw [covariance_self (aemeasurable_of_map_eq (hlaw a))]
    exact (entry_moments hlaw a).2
  · exact (hind.indepFun hab).covariance_eq_zero (hasGaussianLaw_entry hlaw a).memLp_two
      (hasGaussianLaw_entry hlaw b).memLp_two

#print axioms cov_entry

lemma cov_row (hind : iIndepFun R P) (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (c c' : Fin d → ℝ) (i i' : Fin k) :
    cov[fun ω => ∑ j, R (i, j) ω * c j, fun ω => ∑ j, R (i', j) ω * c' j; P] =
      if i = i' then ∑ j, c j * c' j else 0 := by
  have hm : ∀ ij (a : ℝ), MemLp (fun ω => R ij ω * a) 2 P := fun ij a =>
    (hasGaussianLaw_entry hlaw ij).memLp_two.mul_const a
  rw [covariance_fun_sum_fun_sum (X := fun j ω => R (i, j) ω * c j)
    (Y := fun j ω => R (i', j) ω * c' j) (fun j => hm _ _) (fun j => hm _ _)]
  simp_rw [covariance_mul_const_left, covariance_mul_const_right, cov_entry hind hlaw]
  split_ifs with h
  · subst h
    simp only [Prod.mk.injEq, true_and, ite_mul, one_mul, zero_mul, Finset.sum_ite_eq,
      Finset.mem_univ, ite_true]
    exact Finset.sum_congr rfl fun j _ => mul_comm _ _
  · simp [h]

#print axioms cov_row

omit [IsProbabilityMeasure P] in
lemma integral_row (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1) (c : Fin d → ℝ) (i : Fin k) :
    ∫ ω, ∑ j, R (i, j) ω * c j ∂P = 0 := by
  rw [integral_finsetSum _ (fun j _ => ((hasGaussianLaw_entry hlaw (i, j)).integrable).mul_const _)]
  simp [integral_mul_const, (entry_moments hlaw _).1]

#print axioms integral_row

omit [IsProbabilityMeasure P] in
lemma hasGaussianLaw_rows (hind : iIndepFun R P) (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (c : Fin d → ℝ) : HasGaussianLaw (fun ω (i : Fin k) => ∑ j, R (i, j) ω * c j) P := by
  have hJ : HasGaussianLaw (fun ω ij => R ij ω) P := hind.hasGaussianLaw (hasGaussianLaw_entry hlaw)
  let L : (Fin k × Fin d → ℝ) →L[ℝ] (Fin k → ℝ) :=
    ContinuousLinearMap.pi fun i => ∑ j, c j • ContinuousLinearMap.proj (R := ℝ)
      (φ := fun _ : Fin k × Fin d => ℝ) (i, j)
  convert hJ.map L using 1
  ext ω i
  simp [L, mul_comm]

#print axioms hasGaussianLaw_rows

omit [IsProbabilityMeasure P] in
lemma hasGaussianLaw_row (hind : iIndepFun R P) (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (c : Fin d → ℝ) (i : Fin k) : HasGaussianLaw (fun ω => ∑ j, R (i, j) ω * c j) P :=
  (hasGaussianLaw_rows hind hlaw c).eval (X := fun i ω => ∑ j, R (i, j) ω * c j) i

#print axioms hasGaussianLaw_row

lemma map_row (hind : iIndepFun R P) (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (c : Fin d → ℝ) (i : Fin k) :
    P.map (fun ω => ∑ j, R (i, j) ω * c j) = gaussianReal 0 (∑ j, c j ^ 2).toNNReal := by
  rw [(hasGaussianLaw_row hind hlaw c i).map_eq_gaussianReal, integral_row hlaw c i,
    ← covariance_self (hasGaussianLaw_row hind hlaw c i).aemeasurable, cov_row hind hlaw c c i i]
  simp [sq]

#print axioms map_row

lemma iIndepFun_rows (hind : iIndepFun R P) (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (c : Fin d → ℝ) : iIndepFun (fun i ω => ∑ j, R (i, j) ω * c j) P :=
  (hasGaussianLaw_rows hind hlaw c).iIndepFun_of_covariance_eq_zero
    (X := fun i ω => ∑ j, R (i, j) ω * c j) fun i i' h => by rw [cov_row hind hlaw]; simp [h]

#print axioms iIndepFun_rows


lemma mgf_sum_sq (hind : iIndepFun R P) (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (c : Fin d → ℝ) (hc : 0 < ∑ j, c j ^ 2) {t : ℝ} (ht : 2 * t * ∑ j, c j ^ 2 < 1) :
    mgf (fun ω => ∑ i, (∑ j, R (i, j) ω * c j) ^ 2) P t =
        (1 / Real.sqrt (1 - 2 * t * ∑ j, c j ^ 2)) ^ k ∧
      Integrable (fun ω => Real.exp (t * ∑ i, (∑ j, R (i, j) ω * c j) ^ 2)) P := by
  set s := ∑ j, c j ^ 2 with hs
  have hv : s.toNNReal ≠ 0 := by simpa using hc
  have hvs : ((s.toNNReal : NNReal) : ℝ) = s := Real.coe_toNNReal _ hc.le
  have hind2 : iIndepFun (fun i ω => (∑ j, R (i, j) ω * c j) ^ 2) P :=
    (iIndepFun_rows hind hlaw c).comp (fun _ w => w ^ 2) (fun _ => by fun_prop)
  have hsum : (fun ω => ∑ i, (∑ j, R (i, j) ω * c j) ^ 2) =
      ∑ i ∈ Finset.univ, (fun ω => (∑ j, R (i, j) ω * c j) ^ 2) := by
    ext ω; simp
  have hone : ∀ i : Fin k, mgf (fun ω => (∑ j, R (i, j) ω * c j) ^ 2) P t =
      1 / Real.sqrt (1 - 2 * t * s) := by
    intro i
    have hm := (hasGaussianLaw_row hind hlaw c i).aemeasurable
    calc mgf (fun ω => (∑ j, R (i, j) ω * c j) ^ 2) P t
        = ∫ w, Real.exp (t * w ^ 2) ∂(P.map (fun ω => ∑ j, R (i, j) ω * c j)) := by
          rw [integral_map hm (by fun_prop)]; rfl
      _ = 1 / Real.sqrt (1 - 2 * t * s) := by
          rw [map_row hind hlaw c i, integral_exp_mul_sq_gaussianReal hv (by rwa [hvs]), hvs]
  have hmgf : mgf (fun ω => ∑ i, (∑ j, R (i, j) ω * c j) ^ 2) P t =
      (1 / Real.sqrt (1 - 2 * t * s)) ^ k := by
    rw [hsum, hind2.mgf_sum₀ (fun i => by
      have := (hasGaussianLaw_row hind hlaw c i).aemeasurable; fun_prop) Finset.univ]
    simp_rw [hone]
    rw [Finset.prod_const, Finset.card_univ, Fintype.card_fin]
  refine ⟨hmgf, ?_⟩
  by_contra hint
  have h0 : mgf (fun ω => ∑ i, (∑ j, R (i, j) ω * c j) ^ 2) P t = 0 := integral_undef hint
  rw [hmgf] at h0
  have hpos : 0 < 1 - 2 * t * s := by linarith
  have : 0 < (1 / Real.sqrt (1 - 2 * t * s)) ^ k := by
    have := Real.sqrt_pos.2 hpos
    positivity
  linarith

#print axioms mgf_sum_sq

end Gauss

lemma rpow_half_eq {a : ℝ} (ha : 0 ≤ a) (b : ℝ) (k : ℕ) :
    (a * Real.exp b) ^ ((k : ℝ) / 2) = Real.sqrt a ^ k * Real.exp (b * k / 2) := by
  rw [Real.mul_rpow ha (Real.exp_pos b).le, ← Real.exp_mul, Real.sqrt_eq_rpow,
    ← Real.rpow_natCast, ← Real.rpow_mul ha]
  congr 2 <;> ring

#print axioms rpow_half_eq

/-- `1 + ε ≤ exp (ε - ε²/2 + ε³/3)` on `0 < ε < 1`. -/
lemma one_add_le_exp {ε : ℝ} (hε0 : 0 < ε) (hε1 : ε < 1) :
    1 + ε ≤ Real.exp (ε - ε ^ 2 / 2 + ε ^ 3 / 3) := by
  set u := ε - ε ^ 2 / 2 + ε ^ 3 / 3 with hu
  have hu0 : 0 ≤ u := by nlinarith
  have h := Real.sum_le_exp_of_nonneg hu0 4
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, Nat.factorial] at h
  norm_num at h
  refine le_trans ?_ h
  have e2 : ε ^ 2 ≤ 1 := by nlinarith
  have e4 : ε ^ 4 ≤ 1 := by nlinarith
  have hh : 0 ≤ 5 / 24 + ε / 8 - 19 * ε ^ 2 / 144 + 7 * ε ^ 3 / 72 - ε ^ 4 / 36 + ε ^ 5 / 162 := by
    have : 0 ≤ ε ^ 3 := by positivity
    have : 0 ≤ ε ^ 5 := by positivity
    nlinarith
  have key : 1 + u + u ^ 2 / 2 + u ^ 3 / 6 - (1 + ε) =
      ε ^ 4 * (5 / 24 + ε / 8 - 19 * ε ^ 2 / 144 + 7 * ε ^ 3 / 72 - ε ^ 4 / 36 + ε ^ 5 / 162) := by
    rw [hu]; ring
  have : 0 ≤ ε ^ 4 * (5 / 24 + ε / 8 - 19 * ε ^ 2 / 144 + 7 * ε ^ 3 / 72 - ε ^ 4 / 36 +
      ε ^ 5 / 162) := mul_nonneg (by positivity) hh
  nlinarith

#print axioms one_add_le_exp

/-- `1 - ε ≤ exp (-(ε + ε²/2))` on `0 < ε < 1`. -/
lemma one_sub_le_exp {ε : ℝ} (hε0 : 0 < ε) (hε1 : ε < 1) :
    1 - ε ≤ Real.exp (-(ε + ε ^ 2 / 2)) := by
  have habs : |ε| < 1 := by rw [abs_of_pos hε0]; exact hε1
  have h := sum_le_hasSum (Finset.range 2) (fun n _ => by positivity)
    (Real.hasSum_pow_div_log_of_abs_lt_one habs)
  simp only [Finset.sum_range_succ, Finset.sum_range_zero] at h
  norm_num at h
  have hlog : Real.log (1 - ε) ≤ -(ε + ε ^ 2 / 2) := by linarith
  calc 1 - ε = Real.exp (Real.log (1 - ε)) := (Real.exp_log (by linarith)).symm
    _ ≤ _ := Real.exp_le_exp.2 hlog

#print axioms one_sub_le_exp

/-- The two Chernoff tails, proved here so the counted form can use them. -/
lemma one_pair_chernoff_tails_aux {k d : ℕ} (P : Measure Ω) [IsProbabilityMeasure P]
    (R : Fin k × Fin d → Ω → ℝ) (hind : iIndepFun R P)
    (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (x : EuclideanSpace ℝ (Fin d)) (hx : x ≠ 0) {ε : ℝ} (hε0 : 0 < ε) (hε1 : ε < 1) :
    P {ω | (1 + ε) * ‖x‖ ^ 2 ≤ ‖proj (fun ij => R ij ω) x‖ ^ 2} ≤
        ENNReal.ofReal (((1 + ε) * Real.exp (-ε)) ^ ((k : ℝ) / 2)) ∧
      P {ω | ‖proj (fun ij => R ij ω) x‖ ^ 2 ≤ (1 - ε) * ‖x‖ ^ 2} ≤
        ENNReal.ofReal (((1 - ε) * Real.exp ε) ^ ((k : ℝ) / 2)) := by
  rcases Nat.eq_zero_or_pos k with hk | hk
  · subst hk
    simp only [CharP.cast_eq_zero, zero_div, Real.rpow_zero, ENNReal.ofReal_one]
    exact ⟨prob_le_one, prob_le_one⟩
  have hx2 : ‖x‖ ^ 2 = ∑ j, x j ^ 2 := EuclideanSpace.real_norm_sq_eq x
  have hs : 0 < ‖x‖ ^ 2 := by have := norm_pos_iff.2 hx; positivity
  have hkpos : (0 : ℝ) < k := Nat.cast_pos.2 hk
  have hcs : 0 < ∑ j, x j ^ 2 := hx2 ▸ hs
  constructor
  · set t := ε / (2 * ‖x‖ ^ 2 * (1 + ε)) with ht_def
    have ht0 : 0 ≤ t := by positivity
    have h2t : 2 * t * ‖x‖ ^ 2 = ε / (1 + ε) := by rw [ht_def]; field_simp
    have ht : 2 * t * ∑ j, x j ^ 2 < 1 := by
      rw [← hx2, h2t, div_lt_one (by linarith)]; linarith
    obtain ⟨hmgf, hint⟩ := mgf_sum_sq hind hlaw (fun j => x j) hcs ht
    have hset : {ω | (1 + ε) * ‖x‖ ^ 2 ≤ ‖proj (fun ij => R ij ω) x‖ ^ 2} =
        {ω | (1 + ε) * ‖x‖ ^ 2 * k ≤ ∑ i, (∑ j, R (i, j) ω * x j) ^ 2} := by
      ext ω
      simp only [Set.mem_ofPred_eq, norm_proj_sq, one_div_mul_eq_div]
      rw [le_div_iff₀ hkpos]
    rw [hset, ← ofReal_measureReal]
    apply ENNReal.ofReal_le_ofReal
    refine (measure_ge_le_exp_mul_mgf _ ht0 hint).trans (le_of_eq ?_)
    rw [hmgf, ← hx2, rpow_half_eq (by linarith) (-ε) k]
    have h1 : 1 / Real.sqrt (1 - 2 * t * ‖x‖ ^ 2) = Real.sqrt (1 + ε) := by
      have : 1 - 2 * t * ‖x‖ ^ 2 = (1 + ε)⁻¹ := by
        rw [h2t]; field_simp; ring
      rw [this, Real.sqrt_inv, one_div, inv_inv]
    have h3 : -t * ((1 + ε) * ‖x‖ ^ 2 * k) = -ε * k / 2 := by
      rw [ht_def]; field_simp
    rw [h1, h3, mul_comm]
  · set t := -(ε / (2 * ‖x‖ ^ 2 * (1 - ε))) with ht_def
    have h1ε : 0 < 1 - ε := by linarith
    have ht0 : t ≤ 0 := by rw [ht_def]; exact neg_nonpos.2 (by positivity)
    have h2t : 2 * t * ‖x‖ ^ 2 = -(ε / (1 - ε)) := by rw [ht_def]; field_simp
    have ht : 2 * t * ∑ j, x j ^ 2 < 1 := by
      rw [← hx2, h2t]; have : 0 ≤ ε / (1 - ε) := by positivity
      linarith
    obtain ⟨hmgf, hint⟩ := mgf_sum_sq hind hlaw (fun j => x j) hcs ht
    have hset : {ω | ‖proj (fun ij => R ij ω) x‖ ^ 2 ≤ (1 - ε) * ‖x‖ ^ 2} =
        {ω | ∑ i, (∑ j, R (i, j) ω * x j) ^ 2 ≤ (1 - ε) * ‖x‖ ^ 2 * k} := by
      ext ω
      simp only [Set.mem_ofPred_eq, norm_proj_sq, one_div_mul_eq_div]
      rw [div_le_iff₀ hkpos]
    rw [hset, ← ofReal_measureReal]
    apply ENNReal.ofReal_le_ofReal
    refine (measure_le_le_exp_mul_mgf _ ht0 hint).trans (le_of_eq ?_)
    rw [hmgf, ← hx2, rpow_half_eq h1ε.le ε k]
    have h1 : 1 / Real.sqrt (1 - 2 * t * ‖x‖ ^ 2) = Real.sqrt (1 - ε) := by
      have : 1 - 2 * t * ‖x‖ ^ 2 = (1 - ε)⁻¹ := by
        rw [h2t]; field_simp; ring
      rw [this, Real.sqrt_inv, one_div, inv_inv]
    have h3 : -t * ((1 - ε) * ‖x‖ ^ 2 * k) = ε * k / 2 := by
      rw [ht_def]; field_simp
    rw [h1, h3, mul_comm]

#print axioms one_pair_chernoff_tails_aux

/-- The per-pair bound used by the counted form. -/
lemma pair_fail_le {k d : ℕ} (P : Measure Ω) [IsProbabilityMeasure P]
    (R : Fin k × Fin d → Ω → ℝ) (hind : iIndepFun R P)
    (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (u v : EuclideanSpace ℝ (Fin d)) {ε q : ℝ} (hε0 : 0 < ε) (hε1 : ε < 1)
    (hq : Real.exp (-((ε ^ 2 / 2 - ε ^ 3 / 3) * k / 2)) ≤ q) :
    P {ω | ¬ ((1 - ε) * ‖u - v‖ ^ 2 ≤
              ‖proj (fun ij => R ij ω) u - proj (fun ij => R ij ω) v‖ ^ 2 ∧
            ‖proj (fun ij => R ij ω) u - proj (fun ij => R ij ω) v‖ ^ 2 ≤
              (1 + ε) * ‖u - v‖ ^ 2)} ≤ ENNReal.ofReal (2 * q) := by
  by_cases huv : u - v = 0
  · have : u = v := sub_eq_zero.1 huv
    subst this
    simp
  obtain ⟨h1, h2⟩ := one_pair_chernoff_tails_aux P R hind hlaw (u - v) huv hε0 hε1
  set c := ε ^ 2 / 2 - ε ^ 3 / 3 with hc
  have hk2 : (0 : ℝ) ≤ (k : ℝ) / 2 := by positivity
  have hb1 : ((1 + ε) * Real.exp (-ε)) ^ ((k : ℝ) / 2) ≤ q := by
    refine le_trans ?_ hq
    have hbase : (1 + ε) * Real.exp (-ε) ≤ Real.exp (-c) := by
      have := one_add_le_exp hε0 hε1
      calc (1 + ε) * Real.exp (-ε) ≤ Real.exp (ε - ε ^ 2 / 2 + ε ^ 3 / 3) * Real.exp (-ε) :=
            mul_le_mul_of_nonneg_right this (Real.exp_pos _).le
        _ = Real.exp (-c) := by rw [← Real.exp_add, hc]; ring_nf
    calc ((1 + ε) * Real.exp (-ε)) ^ ((k : ℝ) / 2) ≤ Real.exp (-c) ^ ((k : ℝ) / 2) :=
          Real.rpow_le_rpow (by have := Real.exp_pos (-ε); positivity) hbase hk2
      _ = Real.exp (-(c * k / 2)) := by rw [← Real.exp_mul]; ring_nf
  have hb2 : ((1 - ε) * Real.exp ε) ^ ((k : ℝ) / 2) ≤ q := by
    refine le_trans ?_ hq
    have hbase : (1 - ε) * Real.exp ε ≤ Real.exp (-c) := by
      have := one_sub_le_exp hε0 hε1
      calc (1 - ε) * Real.exp ε ≤ Real.exp (-(ε + ε ^ 2 / 2)) * Real.exp ε :=
            mul_le_mul_of_nonneg_right this (Real.exp_pos _).le
        _ = Real.exp (-(ε ^ 2 / 2)) := by rw [← Real.exp_add]; ring_nf
        _ ≤ Real.exp (-c) := Real.exp_le_exp.2 (by rw [hc]; nlinarith [pow_pos hε0 3])
    calc ((1 - ε) * Real.exp ε) ^ ((k : ℝ) / 2) ≤ Real.exp (-c) ^ ((k : ℝ) / 2) :=
          Real.rpow_le_rpow (mul_nonneg (by linarith) (Real.exp_pos ε).le) hbase hk2
      _ = Real.exp (-(c * k / 2)) := by rw [← Real.exp_mul]; ring_nf
  have hsub : {ω | ¬ ((1 - ε) * ‖u - v‖ ^ 2 ≤
              ‖proj (fun ij => R ij ω) u - proj (fun ij => R ij ω) v‖ ^ 2 ∧
            ‖proj (fun ij => R ij ω) u - proj (fun ij => R ij ω) v‖ ^ 2 ≤
              (1 + ε) * ‖u - v‖ ^ 2)} ⊆
      {ω | (1 + ε) * ‖u - v‖ ^ 2 ≤ ‖proj (fun ij => R ij ω) (u - v)‖ ^ 2} ∪
      {ω | ‖proj (fun ij => R ij ω) (u - v)‖ ^ 2 ≤ (1 - ε) * ‖u - v‖ ^ 2} := by
    intro ω hω
    simp only [Set.mem_ofPred_eq, proj_sub, not_and_or, not_le] at hω
    rcases hω with h | h
    · exact Or.inr h.le
    · exact Or.inl h.le
  have hq0 : 0 ≤ q := le_trans (Real.exp_pos _).le hq
  calc _ ≤ _ := measure_mono hsub
    _ ≤ _ := measure_union_le _ _
    _ ≤ ENNReal.ofReal q + ENNReal.ofReal q :=
        add_le_add (h1.trans (ENNReal.ofReal_le_ofReal hb1)) (h2.trans (ENNReal.ofReal_le_ofReal hb2))
    _ = ENNReal.ofReal (2 * q) := by rw [← ENNReal.ofReal_add hq0 hq0, two_mul]

#print axioms pair_fail_le

/-- **The Johnson–Lindenstrauss lemma, counted form.** Fix `n` points in `d` dimensions. Draw a
`k` by `d` table of independent standard normal entries and project by `f(x) = R x / √k`. Let
`0 < ε < 1` and `0 < δ`. If `k ≥ 2 ln(n(n-1)/δ) / c(ε)` with `c(ε) = ε²/2 - ε³/3`, then the chance
that some pair's squared distance leaves `1 ± ε` times its true value is at most `δ`. The count
never reads `d`. -/
theorem johnson_lindenstrauss {k d n : ℕ} (P : Measure Ω) [IsProbabilityMeasure P]
    (R : Fin k × Fin d → Ω → ℝ) (hind : iIndepFun R P)
    (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (x : Fin n → EuclideanSpace ℝ (Fin d)) {ε δ : ℝ} (hε0 : 0 < ε) (hε1 : ε < 1) (hδ : 0 < δ)
    (hk : 2 * Real.log ((n : ℝ) * ((n : ℝ) - 1) / δ) / (ε ^ 2 / 2 - ε ^ 3 / 3) ≤ (k : ℝ)) :
    P {ω | ∃ a b : Fin n,
        ¬ ((1 - ε) * ‖x a - x b‖ ^ 2 ≤
              ‖proj (fun ij => R ij ω) (x a) - proj (fun ij => R ij ω) (x b)‖ ^ 2 ∧
            ‖proj (fun ij => R ij ω) (x a) - proj (fun ij => R ij ω) (x b)‖ ^ 2 ≤
              (1 + ε) * ‖x a - x b‖ ^ 2)} ≤ ENNReal.ofReal δ := by
  classical
  set c := ε ^ 2 / 2 - ε ^ 3 / 3 with hc
  have hcpos : 0 < c := by
    rw [hc]; have : 0 < ε ^ 2 := by positivity
    nlinarith
  set N : ℝ := (n : ℝ) * ((n : ℝ) - 1) with hN
  let F : Fin n × Fin n → Set Ω := fun p => {ω |
      ¬ ((1 - ε) * ‖x p.1 - x p.2‖ ^ 2 ≤
              ‖proj (fun ij => R ij ω) (x p.1) - proj (fun ij => R ij ω) (x p.2)‖ ^ 2 ∧
            ‖proj (fun ij => R ij ω) (x p.1) - proj (fun ij => R ij ω) (x p.2)‖ ^ 2 ≤
              (1 + ε) * ‖x p.1 - x p.2‖ ^ 2)}
  have hFsymm : ∀ a b, F (a, b) = F (b, a) := by
    intro a b
    ext ω
    simp only [F, Set.mem_ofPred_eq]
    rw [norm_sub_rev (x a), norm_sub_rev (proj (fun ij => R ij ω) (x a))]
  have hFdiag : ∀ a, F (a, a) = ∅ := by
    intro a
    ext ω
    simp [F]
  -- every failing outcome lies in some `F (a, b)` with `a ≠ b`, in either order
  have hcover : ∀ (S : Finset (Fin n × Fin n)),
      (∀ a b, a ≠ b → (a, b) ∈ S ∨ (b, a) ∈ S) →
      {ω | ∃ a b : Fin n,
        ¬ ((1 - ε) * ‖x a - x b‖ ^ 2 ≤
              ‖proj (fun ij => R ij ω) (x a) - proj (fun ij => R ij ω) (x b)‖ ^ 2 ∧
            ‖proj (fun ij => R ij ω) (x a) - proj (fun ij => R ij ω) (x b)‖ ^ 2 ≤
              (1 + ε) * ‖x a - x b‖ ^ 2)} ⊆ ⋃ p ∈ S, F p := by
    intro S hS ω ⟨a, b, h⟩
    have hω : ω ∈ F (a, b) := h
    have hab : a ≠ b := by
      rintro rfl
      rw [hFdiag] at hω
      exact hω
    simp only [Set.mem_iUnion]
    rcases hS a b hab with hm | hm
    · exact ⟨(a, b), hm, hω⟩
    · exact ⟨(b, a), hm, by rw [← hFsymm]; exact hω⟩
  set S := (Finset.univ : Finset (Fin n)).offDiag with hS
  set S1 := S.filter (fun p => p.1 < p.2) with hS1
  set S2 := S.filter (fun p => ¬ p.1 < p.2) with hS2
  have hc1 := hcover S1 (fun a b hab => by
    rcases lt_or_gt_of_ne hab with h | h
    · left; simp [hS1, hS, h, hab]
    · right; simp [hS1, hS, h, hab.symm])
  have hc2 := hcover S2 (fun a b hab => by
    rcases lt_or_gt_of_ne hab with h | h
    · right; simp [hS2, hS, h.le, hab.symm]
    · left; simp [hS2, hS, h.le, hab])
  set E := {ω | ∃ a b : Fin n,
        ¬ ((1 - ε) * ‖x a - x b‖ ^ 2 ≤
              ‖proj (fun ij => R ij ω) (x a) - proj (fun ij => R ij ω) (x b)‖ ^ 2 ∧
            ‖proj (fun ij => R ij ω) (x a) - proj (fun ij => R ij ω) (x b)‖ ^ 2 ≤
              (1 + ε) * ‖x a - x b‖ ^ 2)} with hE
  have htwo : P E + P E ≤ ∑ p ∈ S, P (F p) := by
    rw [← Finset.sum_filter_add_sum_filter_not S (fun p => p.1 < p.2)]
    exact add_le_add ((measure_mono hc1).trans (measure_biUnion_finset_le _ _))
      ((measure_mono hc2).trans (measure_biUnion_finset_le _ _))
  -- the case of fewer than two points
  rcases lt_or_ge n 2 with hn | hn
  · have hS0 : S = ∅ := by
      apply Finset.card_eq_zero.1
      rw [hS, Finset.offDiag_card, Finset.card_univ, Fintype.card_fin]
      have h1 := Nat.mul_le_mul_right n (show n ≤ 1 by omega)
      rw [one_mul] at h1
      exact Nat.sub_eq_zero_of_le h1
    rw [hS0, Finset.sum_empty] at htwo
    have : P E = 0 := by
      have := add_eq_zero.1 (le_antisymm htwo zero_le)
      exact this.1
    rw [this]
    exact zero_le
  have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have hNpos : 0 < N := by rw [hN]; nlinarith
  have hq : Real.exp (-(c * k / 2)) ≤ δ / N := by
    have hlog : Real.log (N / δ) ≤ c * k / 2 := by
      have := (div_le_iff₀ hcpos).1 hk
      linarith
    calc Real.exp (-(c * k / 2)) ≤ Real.exp (-Real.log (N / δ)) := Real.exp_le_exp.2 (by linarith)
      _ = δ / N := by
        rw [Real.exp_neg, Real.exp_log (by positivity), inv_div]
  have hsum : ∑ p ∈ S, P (F p) ≤ ∑ p ∈ S, ENNReal.ofReal (2 * (δ / N)) := by
    refine Finset.sum_le_sum fun p _ => ?_
    exact pair_fail_le P R hind hlaw (x p.1) (x p.2) hε0 hε1 hq
  rw [Finset.sum_const, nsmul_eq_mul, hS, Finset.offDiag_card, Finset.card_univ,
    Fintype.card_fin] at hsum
  have hcard : (((n * n - n : ℕ) : ENNReal)) * ENNReal.ofReal (2 * (δ / N)) =
      ENNReal.ofReal δ + ENNReal.ofReal δ := by
    rw [← ENNReal.ofReal_natCast, ← ENNReal.ofReal_mul (by positivity),
      ← ENNReal.ofReal_add hδ.le hδ.le]
    congr 1
    have : ((n * n - n : ℕ) : ℝ) = N := by
      rw [hN, Nat.cast_sub (Nat.le_mul_self n)]
      push_cast
      ring
    rw [this]
    field_simp
    ring
  rw [hcard] at hsum
  have h := htwo.trans hsum
  by_contra hlt
  rw [not_le] at hlt
  exact absurd h (not_le.2 (ENNReal.add_lt_add hlt hlt))

/-- **One pair: the two Chernoff tails.** For one fixed nonzero vector `x` (a pair's difference
`u - v`) and `0 < ε < 1`, the squared ratio `Y = ‖f(x)‖² / ‖x‖²` satisfies
`Pr[Y ≥ 1 + ε] ≤ ((1 + ε) e^(-ε))^(k/2)` and `Pr[Y ≤ 1 - ε] ≤ ((1 - ε) e^ε)^(k/2)`. -/
theorem one_pair_chernoff_tails {k d : ℕ} (P : Measure Ω) [IsProbabilityMeasure P]
    (R : Fin k × Fin d → Ω → ℝ) (hind : iIndepFun R P)
    (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1)
    (x : EuclideanSpace ℝ (Fin d)) (hx : x ≠ 0) {ε : ℝ} (hε0 : 0 < ε) (hε1 : ε < 1) :
    P {ω | (1 + ε) * ‖x‖ ^ 2 ≤ ‖proj (fun ij => R ij ω) x‖ ^ 2} ≤
        ENNReal.ofReal (((1 + ε) * Real.exp (-ε)) ^ ((k : ℝ) / 2)) ∧
      P {ω | ‖proj (fun ij => R ij ω) x‖ ^ 2 ≤ (1 - ε) * ‖x‖ ^ 2} ≤
        ENNReal.ofReal (((1 - ε) * Real.exp ε) ^ ((k : ℝ) / 2)) := by
  exact one_pair_chernoff_tails_aux P R hind hlaw x hx hε0 hε1

/-- **The scale makes the average exactly right.** With at least one row, the mean of the
projected squared length `‖f(x)‖²` is the true squared length `‖x‖²`, for every vector `x`. -/
theorem mean_projected_sq_length {k d : ℕ} (P : Measure Ω) [IsProbabilityMeasure P]
    (R : Fin k × Fin d → Ω → ℝ) (hind : iIndepFun R P)
    (hlaw : ∀ ij, P.map (R ij) = gaussianReal 0 1) (hk : 0 < k)
    (x : EuclideanSpace ℝ (Fin d)) :
    ∫ ω, ‖proj (fun ij => R ij ω) x‖ ^ 2 ∂P = ‖x‖ ^ 2 := by
  have hx2 : ‖x‖ ^ 2 = ∑ j, x j ^ 2 := EuclideanSpace.real_norm_sq_eq x
  have hkpos : (0 : ℝ) < k := Nat.cast_pos.2 hk
  simp_rw [norm_proj_sq]
  rw [integral_const_mul, integral_finsetSum _ (fun i _ =>
    (hasGaussianLaw_row hind hlaw (fun j => x j) i).memLp_two.integrable_sq)]
  have hi : ∀ i, ∫ ω, (∑ j, R (i, j) ω * x j) ^ 2 ∂P = ‖x‖ ^ 2 := by
    intro i
    have hm := (hasGaussianLaw_row hind hlaw (fun j => x j) i).aemeasurable
    rw [← variance_of_integral_eq_zero hm (integral_row hlaw _ i), ← covariance_self hm,
      cov_row hind hlaw, hx2]
    simp [sq]
  simp_rw [hi]
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  field_simp

/-! ### The card's whole-number worked examples -/

-- 30 songs make 30 · 29 / 2 = 435 pairs.
example : 30 * 29 / 2 = 435 := by decide

-- The rate at ε = 1/2: c(1/2) = 1/8 - 1/24 = 1/12 (the card's 0.083333).
example : ((1 : ℚ) / 2) ^ 2 / 2 - ((1 : ℚ) / 2) ^ 3 / 3 = 1 / 12 := by norm_num

-- The cost table, counted multiply-adds with d = 10,000 and k = 100:
-- all pairs directly n(n-1)/2 · d, against project then compare n·k·d + n(n-1)/2 · k.
example : 30 * 29 / 2 * 10000 = 4350000 ∧ 30 * 100 * 10000 + 30 * 29 / 2 * 100 = 30043500 := by
  norm_num
example : 1000 * 999 / 2 * 10000 = 4995000000 ∧
    1000 * 100 * 10000 + 1000 * 999 / 2 * 100 = 1049950000 := by norm_num
example : 1000000 * 999999 / 2 * 10000 = 4999995000000000 ∧
    1000000 * 100 * 10000 + 1000000 * 999999 / 2 * 100 = 50999950000000 := by norm_num

#print axioms johnson_lindenstrauss
#print axioms one_pair_chernoff_tails
#print axioms mean_projected_sq_length

end RandomProjection
