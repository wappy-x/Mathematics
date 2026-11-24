-- The area and coarea formulas: for a one-to-one map with continuous partial derivatives from m-dimensional to n-dimensional space, the normalised m-dimensional Hausdorff measure of the image of a Borel set equals the integral of the Jacobian sqrt(det(Df^T Df)) over the set; for a linear function the coarea formula holds, and det(L^T L) is the squared length of the cross product of the two columns.
import Mathlib.MeasureTheory.Measure.Hausdorff
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.InnerProductSpace.NormDet
import Mathlib.Analysis.InnerProductSpace.ProdL2
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.ApproximatesLinearOn
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.MeasureTheory.Integral.Marginal
import Mathlib.MeasureTheory.Covering.Besicovitch
import Mathlib.MeasureTheory.Covering.BesicovitchVectorSpace

open MeasureTheory Matrix
open scoped ENNReal

namespace AreaCoarea

open Filter Topology
open scoped NNReal

section Iso

/-- The set of reals `t` with `2|t| < c` has length `c`. -/
lemma volume_twice_abs_lt (c : ℝ≥0∞) :
    volume {t : ℝ | ENNReal.ofReal (2 * |t|) < c} = c := by
  rcases eq_or_ne c ∞ with rfl | hc
  · have : ∀ t : ℝ, ENNReal.ofReal (2 * |t|) < ∞ := fun t => ENNReal.ofReal_lt_top
    simp only [this, Set.ofPred_true, Real.volume_univ]
  · have hset : {t : ℝ | ENNReal.ofReal (2 * |t|) < c} = Set.Ioo (-(c.toReal / 2)) (c.toReal / 2) := by
      ext t
      simp only [Set.mem_ofPred_eq, Set.mem_Ioo]
      rw [ENNReal.ofReal_lt_iff_lt_toReal (by positivity) hc]
      constructor
      · intro h1
        constructor <;> cases abs_cases t <;> linarith
      · rintro ⟨h1, h2⟩
        cases abs_cases t <;> linarith
    rw [hset, Real.volume_Ioo]
    rw [show c.toReal / 2 - -(c.toReal / 2) = c.toReal by ring, ENNReal.ofReal_toReal hc]

/-- Two sets of reals whose points are all within `M` of each other have total length at most
`2M`. -/
lemma volume_add_volume_le {A B : Set ℝ} (hA : A.Nonempty) (hB : B.Nonempty) {M : ℝ}
    (h : ∀ a ∈ A, ∀ b ∈ B, |a - b| ≤ M) :
    volume A + volume B ≤ ENNReal.ofReal (2 * M) := by
  obtain ⟨a0, ha0⟩ := hA
  obtain ⟨b0, hb0⟩ := hB
  have key : ∀ a1 ∈ A, ∀ a2 ∈ A, ∀ b1 ∈ B, ∀ b2 ∈ B, |a1 - a2| + |b1 - b2| ≤ 2 * M := by
    intro a1 ha1 a2 ha2 b1 hb1 b2 hb2
    have h11 := abs_le.mp (h a1 ha1 b1 hb1)
    have h12 := abs_le.mp (h a1 ha1 b2 hb2)
    have h21 := abs_le.mp (h a2 ha2 b1 hb1)
    have h22 := abs_le.mp (h a2 ha2 b2 hb2)
    cases abs_cases (a1 - a2) <;> cases abs_cases (b1 - b2) <;> linarith
  have hAb : Bornology.IsBounded A := by
    refine (Metric.isBounded_closedBall (x := b0) (r := M)).subset ?_
    intro a ha
    rw [Metric.mem_closedBall, Real.dist_eq]
    exact h a ha b0 hb0
  have hdA : ∀ b1 ∈ B, ∀ b2 ∈ B, Metric.diam A ≤ 2 * M - |b1 - b2| := by
    intro b1 hb1 b2 hb2
    refine Metric.diam_le_of_forall_dist_le ?_ ?_
    · have := key a0 ha0 a0 ha0 b1 hb1 b2 hb2
      simp at this
      linarith
    · intro a1 ha1 a2 ha2
      rw [Real.dist_eq]
      have := key a1 ha1 a2 ha2 b1 hb1 b2 hb2
      linarith
  have hdB : Metric.diam B ≤ 2 * M - Metric.diam A := by
    refine Metric.diam_le_of_forall_dist_le ?_ ?_
    · have := hdA b0 hb0 b0 hb0
      simp at this
      linarith
    · intro b1 hb1 b2 hb2
      rw [Real.dist_eq]
      have := hdA b1 hb1 b2 hb2
      linarith
  have hBb : Bornology.IsBounded B := by
    refine (Metric.isBounded_closedBall (x := a0) (r := M)).subset ?_
    intro b hb
    rw [Metric.mem_closedBall, Real.dist_eq, abs_sub_comm]
    exact h a0 ha0 b hb
  have vA : volume A ≤ ENNReal.ofReal (Metric.diam A) :=
    (Real.volume_le_diam A).trans
      (Metric.ediam_le_of_forall_dist_le fun x hx y hy => Metric.dist_le_diam_of_mem hAb hx hy)
  have vB : volume B ≤ ENNReal.ofReal (Metric.diam B) :=
    (Real.volume_le_diam B).trans
      (Metric.ediam_le_of_forall_dist_le fun x hx y hy => Metric.dist_le_diam_of_mem hBb hx hy)
  calc volume A + volume B ≤ ENNReal.ofReal (Metric.diam A) + ENNReal.ofReal (Metric.diam B) :=
        add_le_add vA vB
    _ = ENNReal.ofReal (Metric.diam A + Metric.diam B) :=
        (ENNReal.ofReal_add Metric.diam_nonneg Metric.diam_nonneg).symm
    _ ≤ ENNReal.ofReal (2 * M) := ENNReal.ofReal_le_ofReal (by linarith)

variable {d : ℕ}

/-- Length of the slice of `S` through `x` along coordinate `i`. -/
noncomputable def sliceLen (i : Fin d) (S : Set (Fin d → ℝ)) : (Fin d → ℝ) → ℝ≥0∞ :=
  ∫⋯∫⁻_{i}, S.indicator 1 ∂(fun _ => (volume : Measure ℝ))

lemma sliceLen_eq (i : Fin d) {S : Set (Fin d → ℝ)} (hS : MeasurableSet S) (x : Fin d → ℝ) :
    sliceLen i S x = volume {t : ℝ | Function.update x i t ∈ S} := by
  rw [sliceLen, lmarginal_singleton]
  have hm : MeasurableSet {t : ℝ | Function.update x i t ∈ S} :=
    hS.preimage (measurable_update x)
  rw [← lintegral_indicator_one hm]
  rfl

lemma sliceLen_update (i : Fin d) (S : Set (Fin d → ℝ)) (x : Fin d → ℝ) (t : ℝ) :
    sliceLen i S (Function.update x i t) = sliceLen i S x :=
  lmarginal_update_of_mem _ (Finset.mem_singleton_self i) _ x t

lemma measurable_sliceLen (i : Fin d) {S : Set (Fin d → ℝ)} (hS : MeasurableSet S) :
    Measurable (sliceLen i S) :=
  (measurable_one.indicator hS).lmarginal _

/-- Steiner symmetrization along coordinate `i`. -/
def steiner (i : Fin d) (S : Set (Fin d → ℝ)) : Set (Fin d → ℝ) :=
  {x | ENNReal.ofReal (2 * |x i|) < sliceLen i S x}

lemma measurableSet_steiner (i : Fin d) {S : Set (Fin d → ℝ)} (hS : MeasurableSet S) :
    MeasurableSet (steiner i S) :=
  measurableSet_lt (by fun_prop) (measurable_sliceLen i hS)

lemma sliceLen_steiner (i : Fin d) (S : Set (Fin d → ℝ)) (hS : MeasurableSet S) :
    sliceLen i (steiner i S) = sliceLen i S := by
  ext x
  rw [sliceLen_eq i (measurableSet_steiner i hS)]
  have : {t : ℝ | Function.update x i t ∈ steiner i S} =
      {t : ℝ | ENNReal.ofReal (2 * |t|) < sliceLen i S x} := by
    ext t
    simp [steiner, sliceLen_update]
  rw [this, volume_twice_abs_lt]

lemma volume_steiner (i : Fin d) {S : Set (Fin d → ℝ)} (hS : MeasurableSet S) :
    volume (steiner i S) = volume S := by
  rw [← lintegral_indicator_one (measurableSet_steiner i hS), ← lintegral_indicator_one hS,
    volume_pi]
  exact lintegral_eq_of_lmarginal_eq {i} (measurable_one.indicator (measurableSet_steiner i hS))
    (measurable_one.indicator hS) (sliceLen_steiner i S hS)

/-- Squared Euclidean distance bound. -/
def DiamLE (S : Set (Fin d → ℝ)) (D : ℝ) : Prop :=
  ∀ x ∈ S, ∀ y ∈ S, ∑ k, (x k - y k) ^ 2 ≤ D ^ 2

lemma sum_update_sq (i : Fin d) (u v : Fin d → ℝ) (a b : ℝ) :
    ∑ k, (Function.update u i a k - Function.update v i b k) ^ 2 =
      (a - b) ^ 2 + ∑ k ∈ Finset.univ.erase i, (u k - v k) ^ 2 := by
  rw [← Finset.add_sum_erase _ _ (Finset.mem_univ i)]
  simp only [Function.update_self]
  congr 1
  refine Finset.sum_congr rfl fun k hk => ?_
  rw [Function.update_of_ne (Finset.ne_of_mem_erase hk),
    Function.update_of_ne (Finset.ne_of_mem_erase hk)]

lemma diamLE_steiner (i : Fin d) {S : Set (Fin d → ℝ)} (hS : MeasurableSet S) {D : ℝ}
    (h : DiamLE S D) : DiamLE (steiner i S) D := by
  intro x hx y hy
  simp only [steiner, Set.mem_ofPred_eq, sliceLen_eq i hS] at hx hy
  set A := {t : ℝ | Function.update x i t ∈ S}
  set B := {t : ℝ | Function.update y i t ∈ S}
  set R := ∑ k ∈ Finset.univ.erase i, (x k - y k) ^ 2
  have hAne : A.Nonempty := nonempty_of_measure_ne_zero (ne_bot_of_gt hx)
  have hBne : B.Nonempty := nonempty_of_measure_ne_zero (ne_bot_of_gt hy)
  have hab : ∀ a ∈ A, ∀ b ∈ B, (a - b) ^ 2 ≤ D ^ 2 - R := by
    intro a ha b hb
    have := h _ ha _ hb
    rw [sum_update_sq] at this
    linarith
  obtain ⟨a0, ha0⟩ := hAne
  obtain ⟨b0, hb0⟩ := hBne
  have hR : 0 ≤ D ^ 2 - R := (sq_nonneg _).trans (hab a0 ha0 b0 hb0)
  set M := Real.sqrt (D ^ 2 - R)
  have hM : ∀ a ∈ A, ∀ b ∈ B, |a - b| ≤ M := fun a ha b hb =>
    Real.abs_le_sqrt (hab a ha b hb)
  have hsum := volume_add_volume_le ⟨a0, ha0⟩ ⟨b0, hb0⟩ hM
  have hlt : ENNReal.ofReal (2 * |x i|) + ENNReal.ofReal (2 * |y i|) < ENNReal.ofReal (2 * M) :=
    (ENNReal.add_lt_add hx hy).trans_le hsum
  rw [← ENNReal.ofReal_add (by positivity) (by positivity),
    ENNReal.ofReal_lt_ofReal_iff'] at hlt
  have hxy : |x i - y i| ≤ M := by
    have := abs_sub (x i) (y i)
    linarith [hlt.1]
  have hsq : (x i - y i) ^ 2 ≤ D ^ 2 - R := by
    have h2 := sq_le_sq' (abs_le.mp hxy).1 (abs_le.mp hxy).2
    rw [Real.sq_sqrt hR] at h2
    exact h2
  have := sum_update_sq i x y (x i) (y i)
  simp only [Function.update_eq_self] at this
  rw [this]
  linarith

/-- Reflection in coordinate `j`. -/
def refl (j : Fin d) (x : Fin d → ℝ) : Fin d → ℝ := Function.update x j (-x j)

lemma refl_refl (j : Fin d) (x : Fin d → ℝ) : refl j (refl j x) = x := by
  ext k
  by_cases hk : k = j
  · subst hk; simp [refl]
  · simp [refl, Function.update_of_ne hk]

/-- `S` is symmetric in coordinate `j`. -/
def SymmIn (j : Fin d) (S : Set (Fin d → ℝ)) : Prop := ∀ x ∈ S, refl j x ∈ S

lemma symmIn_iff {j : Fin d} {S : Set (Fin d → ℝ)} (h : SymmIn j S) (x : Fin d → ℝ) :
    refl j x ∈ S ↔ x ∈ S :=
  ⟨fun hx => by simpa [refl_refl] using h _ hx, h x⟩

lemma symmIn_steiner_self (i : Fin d) (S : Set (Fin d → ℝ)) : SymmIn i (steiner i S) := by
  intro x hx
  simp only [steiner, Set.mem_ofPred_eq] at hx ⊢
  rw [refl, sliceLen_update]
  simpa using hx

lemma symmIn_steiner_of_ne {i j : Fin d} (hij : j ≠ i) {S : Set (Fin d → ℝ)}
    (h : SymmIn j S) : SymmIn j (steiner i S) := by
  intro x hx
  simp only [steiner, Set.mem_ofPred_eq] at hx ⊢
  have h1 : (refl j x) i = x i := by simp [refl, Function.update_of_ne hij.symm]
  have h2 : sliceLen i S (refl j x) = sliceLen i S x := by
    simp only [sliceLen, lmarginal_singleton]
    congr 1
    ext t
    have : Function.update (refl j x) i t = refl j (Function.update x i t) := by
      ext k
      by_cases hk : k = i
      · subst hk; simp [refl, Function.update_of_ne hij.symm]
      · by_cases hkj : k = j
        · subst hkj; simp [refl, Function.update_of_ne hk]
        · simp [refl, Function.update_of_ne hk, Function.update_of_ne hkj]
    rw [this]
    by_cases hz : Function.update x i t ∈ S <;> simp [Set.indicator, hz, symmIn_iff h]
  rw [h1, h2]
  exact hx

/-- The iterated symmetrization. -/
noncomputable def iter (S : Set (Fin d → ℝ)) : ℕ → Set (Fin d → ℝ)
  | 0 => S
  | k + 1 => if h : k < d then steiner ⟨k, h⟩ (iter S k) else iter S k

lemma iter_props {S : Set (Fin d → ℝ)} (hS : MeasurableSet S) {D : ℝ} (hD : DiamLE S D)
    (k : ℕ) : MeasurableSet (iter S k) ∧ DiamLE (iter S k) D ∧ volume (iter S k) = volume S ∧
      ∀ j : Fin d, j.val < k → SymmIn j (iter S k) := by
  induction k with
  | zero => exact ⟨hS, hD, rfl, fun j hj => absurd hj (Nat.not_lt_zero _)⟩
  | succ k ih =>
    obtain ⟨h1, h2, h3, h4⟩ := ih
    by_cases hk : k < d
    · simp only [iter, hk, dite_true]
      refine ⟨measurableSet_steiner _ h1, diamLE_steiner _ h1 h2,
        (volume_steiner _ h1).trans h3, fun j hj => ?_⟩
      rcases Nat.lt_succ_iff_lt_or_eq.mp hj with hj | hj
      · exact symmIn_steiner_of_ne (fun h => by subst h; simp at hj) (h4 j hj)
      · have : j = ⟨k, hk⟩ := Fin.ext hj
        subst this
        exact symmIn_steiner_self _ _
    · simp only [iter, hk, dite_false]
      exact ⟨h1, h2, h3, fun j hj => h4 j (by have := j.isLt; omega)⟩

lemma neg_mem_of_symm {T : Set (Fin d → ℝ)} (hT : ∀ j : Fin d, SymmIn j T) {x : Fin d → ℝ}
    (hx : x ∈ T) : -x ∈ T := by
  have : ∀ m : ℕ, (fun k : Fin d => if k.val < m then -x k else x k) ∈ T := by
    intro m
    induction m with
    | zero => simpa using hx
    | succ m ih =>
      by_cases hm : m < d
      · have := hT ⟨m, hm⟩ _ ih
        convert this using 1
        ext k
        by_cases hk : k = ⟨m, hm⟩
        · subst hk; simp [refl]
        · have hk' : k.val ≠ m := fun h => hk (Fin.ext h)
          simp only [refl, Function.update_of_ne hk]
          by_cases hkm : k.val < m
          · simp [hkm, show k.val < m + 1 by omega]
          · simp [hkm, show ¬ k.val < m + 1 by omega]
      · convert ih using 1
        ext k
        have := k.isLt
        simp [show k.val < m + 1 by omega, show k.val < m by omega]
  convert this d using 1
  ext k
  simp [k.isLt]

/-- The isodiametric inequality on `EuclideanSpace`. -/
theorem isodiametric (s : Set (EuclideanSpace ℝ (Fin d))) :
    volume s ≤ volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1) / 2 ^ d *
      Metric.ediam s ^ d := by
  set V := volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1)
  have hV0 : V ≠ 0 := (Metric.measure_ball_pos _ _ zero_lt_one).ne'
  have hVt : V ≠ ∞ := measure_ball_lt_top.ne
  rcases Nat.eq_zero_or_pos d with rfl | hd
  · simp only [pow_zero, div_one, mul_one]
    refine measure_mono fun x _ => ?_
    simp [Subsingleton.elim x 0]
  rcases eq_or_ne (Metric.ediam s) ∞ with htop | htop
  · rw [htop, ENNReal.top_pow hd.ne']
    rw [ENNReal.mul_top (ENNReal.div_pos hV0 (by simp)).ne']
    exact le_top
  set D := (Metric.ediam s).toReal
  have hD0 : 0 ≤ D := ENNReal.toReal_nonneg
  have hDs : Metric.ediam s = ENNReal.ofReal D := (ENNReal.ofReal_toReal htop).symm
  set s' := closure s
  have hdist : ∀ x ∈ s', ∀ y ∈ s', dist x y ≤ D := by
    intro x hx y hy
    have := Metric.edist_le_ediam_of_mem hx hy
    rw [Metric.ediam_closure] at this
    rw [edist_dist, hDs] at this
    exact (ENNReal.ofReal_le_ofReal_iff hD0).mp this
  let e := (MeasurableEquiv.toLp 2 (Fin d → ℝ))
  have he : MeasurePreserving e volume volume := PiLp.volume_preserving_toLp (Fin d)
  set S : Set (Fin d → ℝ) := e ⁻¹' s'
  have hS : MeasurableSet S := isClosed_closure.measurableSet.preimage e.measurable
  have hSD : DiamLE S D := by
    intro x hx y hy
    have := hdist _ hx _ hy
    rw [EuclideanSpace.dist_eq, Real.sqrt_le_left hD0] at this
    simpa [Real.dist_eq, sq_abs, e, MeasurableEquiv.coe_toLp] using this
  obtain ⟨h1, h2, h3, h4⟩ := iter_props hS hSD d
  set T := iter S d
  have hT : T ⊆ e ⁻¹' Metric.closedBall 0 (D / 2) := by
    intro x hx
    have hneg := neg_mem_of_symm (fun j => h4 j j.isLt) hx
    have := h2 x hx (-x) hneg
    simp only [Pi.neg_apply] at this
    simp only [Set.mem_preimage, Metric.mem_closedBall, dist_zero_right]
    rw [EuclideanSpace.norm_eq, Real.sqrt_le_left (by positivity)]
    have h' : ∑ k, (x k - -x k) ^ 2 = 4 * ∑ k, x k ^ 2 := by
      rw [Finset.mul_sum]; congr 1; ext k; ring
    simp only [Real.norm_eq_abs, sq_abs]
    change ∑ k, x k ^ 2 ≤ (D / 2) ^ 2
    rw [h'] at this
    have : (D / 2) ^ 2 = D ^ 2 / 4 := by ring
    linarith
  calc volume s ≤ volume s' := measure_mono subset_closure
    _ = volume S := (he.measure_preimage isClosed_closure.measurableSet.nullMeasurableSet).symm
    _ = volume T := h3.symm
    _ ≤ volume (e ⁻¹' Metric.closedBall 0 (D / 2)) := measure_mono hT
    _ = volume (Metric.closedBall (0 : EuclideanSpace ℝ (Fin d)) (D / 2)) :=
        he.measure_preimage measurableSet_closedBall.nullMeasurableSet
    _ = ENNReal.ofReal ((D / 2) ^ d) * V := by
        rw [Measure.addHaar_closedBall _ _ (by positivity), finrank_euclideanSpace_fin]
    _ = V / 2 ^ d * Metric.ediam s ^ d := by
        rw [hDs, div_pow, ENNReal.ofReal_div_of_pos (by positivity), ← ENNReal.ofReal_pow hD0]
        rw [ENNReal.ofReal_pow (by norm_num : (0:ℝ) ≤ 2)]
        simp only [ENNReal.ofReal_ofNat]
        rw [ENNReal.div_eq_inv_mul, ENNReal.div_eq_inv_mul]
        ring

lemma vol_le_smul_hausdorff :
    (volume : Measure (EuclideanSpace ℝ (Fin d))) ≤
      (volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1) / 2 ^ d) • μH[d] := by
  set V := volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1)
  have hV0 : V ≠ 0 := (Metric.measure_ball_pos _ _ zero_lt_one).ne'
  have hVt : V ≠ ∞ := measure_ball_lt_top.ne
  have hc0 : V / 2 ^ d ≠ 0 := (ENNReal.div_pos hV0 (by simp)).ne'
  have hct : V / 2 ^ d ≠ ∞ := ENNReal.div_ne_top hVt (by simp)
  have h := Measure.le_hausdorffMeasure (X := EuclideanSpace ℝ (Fin d)) (d : ℝ)
    ((V / 2 ^ d)⁻¹ • volume) 1 one_pos (fun s _ => by
      rw [Measure.smul_apply, smul_eq_mul, ENNReal.rpow_natCast]
      calc (V / 2 ^ d)⁻¹ * volume s ≤ (V / 2 ^ d)⁻¹ * (V / 2 ^ d * Metric.ediam s ^ d) :=
            mul_le_mul_right (isodiametric s) _
        _ = Metric.ediam s ^ d := by rw [← mul_assoc, ENNReal.inv_mul_cancel hc0 hct, one_mul])
  rw [Measure.le_iff'] at h ⊢
  intro s
  have hs := h s
  rw [Measure.smul_apply, smul_eq_mul] at hs ⊢
  calc volume s = V / 2 ^ d * ((V / 2 ^ d)⁻¹ * volume s) := by
        rw [← mul_assoc, ENNReal.mul_inv_cancel hc0 hct, one_mul]
    _ ≤ V / 2 ^ d * μH[d] s := mul_le_mul_right hs _

lemma hausdorff_ball_le :
    (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) (Metric.ball 0 1) ≤
      2 ^ d / volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1) *
        volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1) := by
  set B := Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1
  set V := volume B
  have hV0 : V ≠ 0 := (Metric.measure_ball_pos _ _ zero_lt_one).ne'
  have hVt : V ≠ ∞ := measure_ball_lt_top.ne
  set m : Set (EuclideanSpace ℝ (Fin d)) → ℝ≥0∞ := fun s => Metric.ediam s ^ (d : ℝ)
  have hμH : ∀ s, (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) s =
      OuterMeasure.mkMetric' m s := by
    intro s
    rw [Measure.hausdorffMeasure, ← OuterMeasure.coe_mkMetric]
    rfl
  have hnull : ∀ N, volume N = 0 → (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) N = 0 := by
    intro N hN
    rw [Measure.isAddLeftInvariant_eq_smul (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) volume]
    simp [hN]
  have key : ∀ ε : ℝ, 0 < ε → OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε) B ≤
      2 ^ d / V * V := by
    intro ε hε
    obtain ⟨t, ρ, ht_count, ht_sub, hρ, hnullc, hdisj⟩ :=
      Besicovitch.exists_disjoint_closedBall_covering_ae
        (volume : Measure (EuclideanSpace ℝ (Fin d)))
        (fun _ => Set.univ) B (fun x _ δ hδ => ⟨δ / 2, Set.mem_univ _, by constructor <;> linarith⟩)
        (fun x => min (ε / 2) (1 - ‖x‖))
        (fun x hx => lt_min (by linarith) (by rw [mem_ball_zero_iff] at hx; linarith))
    set U := ⋃ x ∈ t, Metric.closedBall x (ρ x)
    have hcov : B ⊆ U ∪ (B \ U) := fun y hy => by
      by_cases h : y ∈ U
      · exact Or.inl h
      · exact Or.inr ⟨hy, h⟩
    have hρpos : ∀ x ∈ t, 0 < ρ x := fun x hx => (hρ x hx).2.1
    have hρlt : ∀ x ∈ t, ρ x < min (ε / 2) (1 - ‖x‖) := fun x hx => (hρ x hx).2.2
    have hball_sub : ∀ x ∈ t, Metric.closedBall x (ρ x) ⊆ B := by
      intro x hx y hy
      have h1 := hρlt x hx
      rw [lt_min_iff] at h1
      rw [Metric.mem_closedBall, dist_eq_norm] at hy
      rw [mem_ball_zero_iff]
      have := norm_le_norm_add_norm_sub' y x
      linarith [h1.2]
    have hU : U ⊆ B := Set.iUnion₂_subset hball_sub
    have hUmeas : MeasurableSet U :=
      MeasurableSet.biUnion ht_count fun x _ => measurableSet_closedBall
    have hpiece : ∀ x ∈ t, OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε)
        (Metric.closedBall x (ρ x)) ≤ 2 ^ d / V * volume (Metric.closedBall x (ρ x)) := by
      intro x hx
      have h1 := hρlt x hx
      rw [lt_min_iff] at h1
      have h0 := hρpos x hx
      have hdiam : Metric.ediam (Metric.closedBall x (ρ x)) ≤ ENNReal.ofReal (2 * ρ x) := by
        refine Metric.ediam_le_of_forall_dist_le fun y hy z hz => ?_
        rw [Metric.mem_closedBall] at hy hz
        have := dist_triangle_right y z x
        linarith
      refine (OuterMeasure.mkMetric'.pre_le (hdiam.trans
        (ENNReal.ofReal_le_ofReal (by linarith)))).trans ?_
      simp only [m, ENNReal.rpow_natCast]
      rw [Measure.addHaar_closedBall _ _ h0.le, finrank_euclideanSpace_fin]
      calc Metric.ediam (Metric.closedBall x (ρ x)) ^ d ≤ ENNReal.ofReal (2 * ρ x) ^ d :=
            pow_le_pow_left' hdiam d
        _ = 2 ^ d / V * (ENNReal.ofReal (ρ x ^ d) * V) := by
            rw [mul_comm (ENNReal.ofReal _) V, ← mul_assoc, ENNReal.div_mul_cancel hV0 hVt,
              ENNReal.ofReal_mul (by norm_num), ENNReal.ofReal_pow h0.le, mul_pow]
            simp
    calc OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε) B
        ≤ OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε) (U ∪ (B \ U)) := measure_mono hcov
      _ ≤ OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε) U +
          OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε) (B \ U) := measure_union_le _ _
      _ ≤ (∑' x : t, OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε)
            (Metric.closedBall x (ρ x))) + 0 := by
          gcongr
          · exact measure_biUnion_le _ ht_count _
          · calc OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε) (B \ U)
                ≤ OuterMeasure.mkMetric' m (B \ U) := by
                  rw [OuterMeasure.mkMetric', OuterMeasure.iSup_apply]
                  refine le_trans ?_ (le_iSup _ (ENNReal.ofReal ε))
                  rw [OuterMeasure.iSup_apply]
                  exact le_iSup (fun _ : 0 < ENNReal.ofReal ε =>
                    OuterMeasure.mkMetric'.pre m (ENNReal.ofReal ε) (B \ U))
                    (ENNReal.ofReal_pos.mpr hε)
              _ = 0 := by rw [← hμH]; exact hnull _ hnullc
      _ ≤ ∑' x : t, 2 ^ d / V * volume (Metric.closedBall (x : EuclideanSpace ℝ (Fin d)) (ρ x)) := by
          rw [add_zero]
          exact tsum_le_tsum fun x => hpiece x x.2
      _ = 2 ^ d / V * volume U := by
          rw [ENNReal.tsum_mul_left, measure_biUnion ht_count hdisj
            (fun x _ => measurableSet_closedBall)]
      _ ≤ 2 ^ d / V * V := mul_le_mul_right (measure_mono hU) _
  rw [hμH, OuterMeasure.mkMetric', OuterMeasure.iSup_apply]
  refine iSup_le fun r => ?_
  rw [OuterMeasure.iSup_apply]
  refine iSup_le fun hr => ?_
  obtain ⟨ε, hε, hεr⟩ : ∃ ε : ℝ, 0 < ε ∧ ENNReal.ofReal ε ≤ r := by
    rcases eq_or_ne r ∞ with rfl | hrt
    · exact ⟨1, one_pos, le_top⟩
    · exact ⟨r.toReal, ENNReal.toReal_pos hr.ne' hrt, by rw [ENNReal.ofReal_toReal hrt]⟩
  exact (OuterMeasure.mkMetric'.mono_pre m hεr B).trans (key ε hε)

/-- The normalised Hausdorff measure equals Lebesgue measure on `ℝᵈ`. -/
theorem smul_hausdorff_eq_volume :
    (volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1) / 2 ^ d) •
      (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) = volume := by
  set B := Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1
  set V := volume B
  have hV0 : V ≠ 0 := (Metric.measure_ball_pos _ _ zero_lt_one).ne'
  have hVt : V ≠ ∞ := measure_ball_lt_top.ne
  set c := V / 2 ^ d
  have h1 : volume ≤ c • (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) := vol_le_smul_hausdorff
  have h2 : c * μH[d] B ≤ V := by
    calc c * μH[d] B ≤ c * (2 ^ d / V * V) := mul_le_mul_right hausdorff_ball_le _
      _ = V := by
        rw [ENNReal.div_mul_cancel hV0 hVt, ENNReal.div_mul_cancel (by simp) (by simp)]
  have hk := Measure.isAddLeftInvariant_eq_smul (μH[d] : Measure (EuclideanSpace ℝ (Fin d)))
    (volume : Measure (EuclideanSpace ℝ (Fin d)))
  set k := Measure.addHaarScalarFactor (μH[d] : Measure (EuclideanSpace ℝ (Fin d)))
    (volume : Measure (EuclideanSpace ℝ (Fin d)))
  have hB1 := Measure.le_iff'.1 h1 B
  rw [Measure.smul_apply, smul_eq_mul, hk, Measure.smul_apply, ENNReal.smul_def,
    smul_eq_mul] at hB1
  rw [hk, Measure.smul_apply, ENNReal.smul_def, smul_eq_mul] at h2
  have hck : c * (k : ℝ≥0∞) = 1 := by
    apply le_antisymm
    · refine (ENNReal.mul_le_mul_iff_left hV0 hVt).mp ?_
      rw [one_mul, mul_assoc]
      exact h2
    · refine (ENNReal.mul_le_mul_iff_left hV0 hVt).mp ?_
      rw [one_mul, mul_assoc]
      exact hB1
  rw [hk, ENNReal.smul_def, smul_smul, hck, one_smul]

/-- The normalising constant: `V_d / 2^d · μH[d] = μHE[d]` on any space. -/
theorem normalised_hausdorff_eq {X : Type*} [EMetricSpace X] [MeasurableSpace X] [BorelSpace X]
    (s : Set X) :
    volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1) / 2 ^ d * μH[d] s = μHE[d] s := by
  set B := Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1
  have hH0 : (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) B ≠ 0 :=
    (Measure.IsOpenPosMeasure.open_pos _ Metric.isOpen_ball
      ⟨0, Metric.mem_ball_self one_pos⟩)
  have hHt : (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) B ≠ ∞ := measure_ball_lt_top.ne
  have h1 := smul_hausdorff_eq_volume (d := d)
  have h2 := Measure.isAddLeftInvariant_eq_smul (volume : Measure (EuclideanSpace ℝ (Fin d)))
    (μH[d] : Measure (EuclideanSpace ℝ (Fin d)))
  have h3 : volume (Metric.ball (0 : EuclideanSpace ℝ (Fin d)) 1) / 2 ^ d =
      (Measure.addHaarScalarFactor (volume : Measure (EuclideanSpace ℝ (Fin d)))
        (μH[d] : Measure (EuclideanSpace ℝ (Fin d))) : ℝ≥0∞) := by
    have := congrArg (fun μ : Measure (EuclideanSpace ℝ (Fin d)) => μ B) (h1.trans h2)
    simp only [Measure.smul_apply, smul_eq_mul, ENNReal.smul_def] at this
    exact (ENNReal.mul_le_mul_iff_left hH0 hHt).1 this.le |>.antisymm
      ((ENNReal.mul_le_mul_iff_left hH0 hHt).1 this.ge)
  rw [h3, Measure.euclideanHausdorffMeasure_def, Measure.smul_apply, ENNReal.smul_def,
    smul_eq_mul]

end Iso

section Area

/-- Relative Lipschitz bound for the Euclidean Hausdorff measure of images. -/
lemma muHE_image_le_of_edist {X Y Z : Type*} [EMetricSpace X] [EMetricSpace Y] [EMetricSpace Z]
    [MeasurableSpace Y] [BorelSpace Y] [MeasurableSpace Z] [BorelSpace Z] (d : ℕ)
    {g : X → Y} {h : X → Z} {s : Set X} {K : ℝ≥0}
    (H : ∀ x ∈ s, ∀ y ∈ s, edist (g x) (g y) ≤ K * edist (h x) (h y)) :
    μHE[d] (g '' s) ≤ (K : ℝ≥0∞) ^ d * μHE[d] (h '' s) := by
  classical
  rcases s.eq_empty_or_nonempty with rfl | ⟨x0, hx0⟩
  · simp
  have : Nonempty X := ⟨x0⟩
  let Φ : Z → Y := fun z => g (Function.invFunOn h s z)
  have hspec : ∀ x ∈ s, Function.invFunOn h s (h x) ∈ s ∧
      h (Function.invFunOn h s (h x)) = h x := fun x hx =>
    ⟨Function.invFunOn_mem ⟨x, hx, rfl⟩, Function.invFunOn_eq ⟨x, hx, rfl⟩⟩
  have hΦ : LipschitzOnWith K Φ (h '' s) := by
    rintro _ ⟨x, hx, rfl⟩ _ ⟨y, hy, rfl⟩
    obtain ⟨hx1, hx2⟩ := hspec x hx
    obtain ⟨hy1, hy2⟩ := hspec y hy
    have := H _ hx1 _ hy1
    rw [hx2, hy2] at this
    exact this
  have himg : g '' s = Φ '' (h '' s) := by
    rw [Set.image_image]
    refine Set.image_congr fun x hx => ?_
    obtain ⟨hx1, hx2⟩ := hspec x hx
    have := H _ hx1 _ hx
    rw [hx2, edist_self, mul_zero, nonpos_iff_eq_zero, edist_eq_zero] at this
    exact this.symm
  rw [himg]
  simp only [Measure.euclideanHausdorffMeasure_def]
  have := hΦ.hausdorffMeasure_image_le (d := (d : ℝ)) (Nat.cast_nonneg d)
  rw [ENNReal.rpow_natCast] at this
  calc _ ≤ _ := mul_le_mul_right this _
    _ = _ := by rw [Measure.smul_apply, ENNReal.smul_def, smul_eq_mul]; ring

variable {m n : ℕ}

local notation "E" => EuclideanSpace ℝ (Fin m)
local notation "F" => EuclideanSpace ℝ (Fin n)

/-- The Jacobian factor of a linear map. -/
noncomputable def nd (L : E →L[ℝ] F) : ℝ := (L : E →ₗ[ℝ] F).normDet

lemma nd_nonneg (L : E →L[ℝ] F) : 0 ≤ nd L := LinearMap.normDet_nonneg _

/-- Gram matrix of `L` on the standard basis. -/
noncomputable def gramL (L : E →L[ℝ] F) : Matrix (Fin m) (Fin m) ℝ :=
  Matrix.gram ℝ (fun i => L (EuclideanSpace.basisFun (Fin m) ℝ i))

lemma nd_sq (L : E →L[ℝ] F) : nd L ^ 2 = (gramL L).det := by
  have := LinearMap.normDet_sq_eq_det_gram (L : E →ₗ[ℝ] F) (EuclideanSpace.basisFun (Fin m) ℝ)
  simpa [nd, gramL] using this

lemma nd_eq_sqrt (L : E →L[ℝ] F) : nd L = Real.sqrt (gramL L).det := by
  rw [← nd_sq, Real.sqrt_sq (nd_nonneg L)]

lemma continuous_nd : Continuous (nd : (E →L[ℝ] F) → ℝ) := by
  have : (nd : (E →L[ℝ] F) → ℝ) = fun L => Real.sqrt (gramL L).det := funext nd_eq_sqrt
  rw [this]
  refine Continuous.sqrt (Continuous.matrix_det ?_)
  refine continuous_matrix fun i j => ?_
  simp only [gramL, Matrix.gram, Matrix.of_apply]
  fun_prop

/-- The augmented map `v ↦ (L v, ε v)`. -/
noncomputable def augL (L : E →L[ℝ] F) (ε : ℝ) : E →ₗ[ℝ] WithLp 2 (F × E) :=
  (WithLp.linearEquiv 2 ℝ (F × E)).symm.toLinearMap ∘ₗ
    ((L : E →ₗ[ℝ] F).prod (ε • LinearMap.id))

lemma augL_apply (L : E →L[ℝ] F) (ε : ℝ) (v : E) :
    augL L ε v = WithLp.toLp 2 (L v, ε • v) := rfl

lemma norm_augL_sq (L : E →L[ℝ] F) (ε : ℝ) (v : E) :
    ‖augL L ε v‖ ^ 2 = ‖L v‖ ^ 2 + ε ^ 2 * ‖v‖ ^ 2 := by
  rw [augL_apply, WithLp.prod_norm_sq_eq_of_L2]
  simp [norm_smul, mul_pow]

lemma gram_augL (L : E →L[ℝ] F) (ε : ℝ) :
    Matrix.gram ℝ (fun i => augL L ε (EuclideanSpace.basisFun (Fin m) ℝ i)) =
      gramL L + (ε ^ 2) • (1 : Matrix (Fin m) (Fin m) ℝ) := by
  ext i j
  simp only [Matrix.gram, Matrix.of_apply, augL_apply, WithLp.prod_inner_apply, gramL,
    Matrix.add_apply, Matrix.smul_apply, Matrix.one_apply, inner_smul_left, inner_smul_right]
  rw [(EuclideanSpace.basisFun (Fin m) ℝ).inner_eq_ite]
  split_ifs <;> simp [pow_two]

lemma normDet_augL (L : E →L[ℝ] F) (ε : ℝ) :
    (augL L ε).normDet = Real.sqrt (gramL L + (ε ^ 2) • (1 : Matrix (Fin m) (Fin m) ℝ)).det := by
  have := LinearMap.normDet_sq_eq_det_gram (augL L ε) (EuclideanSpace.basisFun (Fin m) ℝ)
  rw [← gram_augL]
  simp only [RCLike.ofReal_real_eq_id, id] at this
  rw [← this, Real.sqrt_sq (LinearMap.normDet_nonneg _)]

lemma exists_pos_lt_of_continuous {φ : ℝ → ℝ} (hφ : Continuous φ) {c : ℝ} (h0 : φ 0 < c) :
    ∃ ε : ℝ, 0 < ε ∧ φ ε < c := by
  have h1 : ∀ᶠ ε in 𝓝 (0 : ℝ), φ ε < c := (hφ.tendsto 0).eventually (gt_mem_nhds h0)
  obtain ⟨ε, h2, h3⟩ := ((eventually_nhdsWithin_of_eventually_nhds h1).and
    (self_mem_nhdsWithin : Set.Ioi (0 : ℝ) ∈ 𝓝[>] 0)).exists
  exact ⟨ε, h3, h2⟩

lemma eventually_lt_of_continuous {φ : ℝ → ℝ} (hφ : Continuous φ) {c : ℝ} (h0 : φ 0 < c) :
    ∀ᶠ ε in 𝓝[>] (0 : ℝ), φ ε < c :=
  eventually_nhdsWithin_of_eventually_nhds ((hφ.tendsto 0).eventually (gt_mem_nhds h0))

lemma image_le_of_approx (L : E →L[ℝ] F) {r : ℝ≥0} (hr : ENNReal.ofReal (nd L) < r) :
    ∃ δ : ℝ≥0, 0 < δ ∧ ∀ (g : E → F) (t : Set E), ApproximatesLinearOn g L t δ →
      μHE[m] (g '' t) ≤ r * μHE[m] t := by
  let _ : MeasurableSpace (WithLp 2 (F × E)) := borel _
  have : BorelSpace (WithLp 2 (F × E)) := ⟨rfl⟩
  have hr' : nd L < r := by
    have : ENNReal.ofReal (nd L) < ENNReal.ofReal r := by simpa using hr
    exact (ENNReal.ofReal_lt_ofReal_iff_of_nonneg (nd_nonneg L)).1 this
  set r1 : ℝ := (nd L + r) / 2
  have hr1 : nd L < r1 := by simp only [r1]; linarith
  have hr2 : r1 < r := by simp only [r1]; linarith
  have hr1pos : 0 < r1 := (nd_nonneg L).trans_lt hr1
  -- choose `ε`
  set φ : ℝ → ℝ := fun ε => Real.sqrt (gramL L + (ε ^ 2) • (1 : Matrix (Fin m) (Fin m) ℝ)).det
  have hφ : Continuous φ := by
    refine Continuous.sqrt (Continuous.matrix_det ?_)
    exact continuous_const.add ((continuous_pow 2).smul continuous_const)
  have hφ0 : φ 0 = nd L := by simp [φ, nd_eq_sqrt]
  obtain ⟨ε, hε, hεφ⟩ := exists_pos_lt_of_continuous hφ (hφ0 ▸ hr1)
  -- choose `δ`
  set ψ : ℝ → ℝ := fun δ => (1 + δ / ε) ^ m * r1
  have hψ : Continuous ψ := by fun_prop
  obtain ⟨δ, hδ, hδψ⟩ := exists_pos_lt_of_continuous hψ (c := r) (by simpa [ψ] using hr2)
  refine ⟨⟨δ, hδ.le⟩, by exact_mod_cast hδ, fun g t happ => ?_⟩
  set G := augL L ε
  have hK0 : 0 ≤ 1 + δ / ε := add_nonneg zero_le_one (div_nonneg hδ.le hε.le)
  set K : ℝ≥0 := ⟨1 + δ / ε, hK0⟩
  have hnorm : ∀ v : E, ‖L v‖ ≤ ‖G v‖ ∧ ε * ‖v‖ ≤ ‖G v‖ := by
    intro v
    have h := norm_augL_sq L ε v
    constructor
    · exact (sq_le_sq₀ (norm_nonneg _) (norm_nonneg _)).1 (by nlinarith [sq_nonneg (ε * ‖v‖)])
    · exact (sq_le_sq₀ (by positivity) (norm_nonneg _)).1 (by nlinarith [sq_nonneg ‖L v‖])
  have hK : ∀ x ∈ t, ∀ y ∈ t, edist (g x) (g y) ≤ K * edist (G x) (G y) := by
    intro x hx y hy
    have h1 : ‖g x - g y - L (x - y)‖ ≤ δ * ‖x - y‖ := happ x hx y hy
    obtain ⟨h2, h3⟩ := hnorm (x - y)
    have hreal : dist (g x) (g y) ≤ (1 + δ / ε) * dist (G x) (G y) := by
      rw [dist_eq_norm, dist_eq_norm, ← map_sub]
      have h4 : ‖g x - g y‖ ≤ ‖g x - g y - L (x - y)‖ + ‖L (x - y)‖ := by
        have := norm_add_le (g x - g y - L (x - y)) (L (x - y))
        simpa using this
      have h5 : δ * ‖x - y‖ ≤ δ / ε * ‖G (x - y)‖ := by
        rw [div_mul_eq_mul_div, le_div_iff₀ hε]
        nlinarith
      nlinarith
    rw [edist_dist, edist_dist]
    calc ENNReal.ofReal (dist (g x) (g y)) ≤ ENNReal.ofReal ((1 + δ / ε) * dist (G x) (G y)) :=
          ENNReal.ofReal_le_ofReal hreal
      _ = K * ENNReal.ofReal (dist (G x) (G y)) := by
          rw [ENNReal.ofReal_mul hK0, ENNReal.ofReal_eq_coe_nnreal hK0]
          rfl
  have hfin : Module.finrank ℝ E = m := finrank_euclideanSpace_fin
  have himg := G.euclideanHausdorffMeasure_image t
  rw [hfin] at himg
  calc μHE[m] (g '' t) ≤ (K : ℝ≥0∞) ^ m * μHE[m] (G '' t) := muHE_image_le_of_edist m hK
    _ = (K : ℝ≥0∞) ^ m * ENNReal.ofReal (φ ε) * μHE[m] t := by
        rw [himg, normDet_augL, mul_assoc]
    _ ≤ ENNReal.ofReal ((1 + δ / ε) ^ m * r1) * μHE[m] t := by
        refine mul_le_mul_left ?_ _
        rw [ENNReal.ofReal_mul (pow_nonneg hK0 _), ENNReal.ofReal_pow hK0,
          ENNReal.ofReal_eq_coe_nnreal hK0]
        exact mul_le_mul_right (ENNReal.ofReal_le_ofReal hεφ.le) _
    _ ≤ r * μHE[m] t := by
        gcongr
        calc ENNReal.ofReal ((1 + δ / ε) ^ m * r1) ≤ ENNReal.ofReal r :=
              ENNReal.ofReal_le_ofReal hδψ.le
          _ = r := ENNReal.ofReal_coe_nnreal

lemma le_image_of_approx (L : E →L[ℝ] F) {r : ℝ≥0} (hr : (r : ℝ≥0∞) < ENNReal.ofReal (nd L)) :
    ∃ δ : ℝ≥0, 0 < δ ∧ ∀ (g : E → F) (t : Set E), ApproximatesLinearOn g L t δ →
      r * μHE[m] t ≤ μHE[m] (g '' t) := by
  have hr' : (r : ℝ) < nd L := by
    have : ENNReal.ofReal r < ENNReal.ofReal (nd L) := by simpa using hr
    exact (ENNReal.ofReal_lt_ofReal_iff_of_nonneg (by positivity)).1 this
  have hnd : nd L ≠ 0 := (lt_of_le_of_lt (NNReal.coe_nonneg r) hr').ne'
  have hker : (L : E →ₗ[ℝ] F).ker = ⊥ := by
    by_contra h
    exact hnd (LinearMap.normDet_eq_zero_iff_ker_ne_bot.2 h)
  obtain ⟨K, hKpos, hK⟩ := (L : E →ₗ[ℝ] F).exists_antilipschitzWith hker
  have hKv : ∀ v : E, ‖v‖ ≤ K * ‖L v‖ := fun v => by
    have := hK.le_mul_dist v 0
    simpa [dist_zero_right] using this
  set ψ : ℝ → ℝ := fun δ => -((1 - δ * K) ^ m * nd L)
  have hψ : Continuous ψ := by fun_prop
  have hKpos' : (0 : ℝ) < K := by exact_mod_cast hKpos
  have e1 := eventually_lt_of_continuous hψ (c := -(r : ℝ)) (by simpa [ψ] using hr')
  have e2 := eventually_lt_of_continuous (φ := fun δ : ℝ => δ * K) (by fun_prop) (c := 1 / 2)
    (by norm_num)
  obtain ⟨δ, hδψ, hδK, hδ⟩ := (e1.and (e2.and self_mem_nhdsWithin)).exists
  have hδ : 0 < δ := hδ
  have hψδ : (r : ℝ) < (1 - δ * K) ^ m * nd L := by
    have : -((1 - δ * K) ^ m * nd L) < -(r : ℝ) := hδψ
    linarith
  refine ⟨⟨δ, hδ.le⟩, by exact_mod_cast hδ, fun g t happ => ?_⟩
  set c : ℝ := 1 - δ * K
  have hδK' : δ * K < 1 / 2 := hδK
  have hc : 0 < c := by show 0 < 1 - δ * K; linarith
  set Kc : ℝ≥0 := ⟨c⁻¹, (inv_pos.2 hc).le⟩
  have hLip : ∀ x ∈ t, ∀ y ∈ t, edist (L x) (L y) ≤ Kc * edist (g x) (g y) := by
    intro x hx y hy
    have h1 : ‖g x - g y - L (x - y)‖ ≤ δ * ‖x - y‖ := happ x hx y hy
    have h2 := hKv (x - y)
    have hreal : dist (L x) (L y) ≤ c⁻¹ * dist (g x) (g y) := by
      rw [dist_eq_norm, dist_eq_norm, ← map_sub]
      have h4 : ‖L (x - y)‖ ≤ ‖g x - g y‖ + ‖g x - g y - L (x - y)‖ := by
        have := norm_sub_le (g x - g y) (g x - g y - L (x - y))
        simpa using this
      rw [le_inv_mul_iff₀ hc]
      simp only [c]
      nlinarith
    rw [edist_dist, edist_dist]
    calc ENNReal.ofReal (dist (L x) (L y)) ≤ ENNReal.ofReal (c⁻¹ * dist (g x) (g y)) :=
          ENNReal.ofReal_le_ofReal hreal
      _ = _ := by
          rw [ENNReal.ofReal_mul (inv_pos.2 hc).le, ENNReal.ofReal_eq_coe_nnreal (inv_pos.2 hc).le]
          rfl
  have hfin : Module.finrank ℝ E = m := finrank_euclideanSpace_fin
  have himg := (L : E →ₗ[ℝ] F).euclideanHausdorffMeasure_image t
  rw [hfin] at himg
  have h3 := muHE_image_le_of_edist m hLip
  change μHE[m] ((L : E →ₗ[ℝ] F) '' t) ≤ _ at h3
  rw [himg] at h3
  calc (r : ℝ≥0∞) * μHE[m] t ≤ ENNReal.ofReal (c ^ m * nd L) * μHE[m] t := by
        gcongr
        rw [← ENNReal.ofReal_coe_nnreal]
        exact ENNReal.ofReal_le_ofReal hψδ.le
    _ = ENNReal.ofReal (c ^ m) * (ENNReal.ofReal (nd L) * μHE[m] t) := by
        rw [ENNReal.ofReal_mul (pow_nonneg hc.le _), mul_assoc]
    _ ≤ ENNReal.ofReal (c ^ m) * ((Kc : ℝ≥0∞) ^ m * μHE[m] (g '' t)) :=
        mul_le_mul_right h3 _
    _ = μHE[m] (g '' t) := by
        have hKc : (Kc : ℝ≥0∞) = ENNReal.ofReal c⁻¹ :=
          (ENNReal.ofReal_eq_coe_nnreal (inv_pos.2 hc).le).symm
        rw [← mul_assoc, hKc, ← ENNReal.ofReal_pow (inv_pos.2 hc).le,
          ← ENNReal.ofReal_mul (pow_nonneg hc.le _)]
        rw [← mul_pow, mul_inv_cancel₀ hc.ne', one_pow, ENNReal.ofReal_one, one_mul]

/-- A countable partition of `E` adapted to a `C¹` map. -/
lemma exists_partition_C1 {f : E → F} (hf : ContDiff ℝ 1 f) (δ : (E →L[ℝ] F) → ℝ≥0)
    (hδ : ∀ A, 0 < δ A) :
    ∃ (t : ℕ → Set E) (A : ℕ → E →L[ℝ] F),
      Pairwise (Function.onFun Disjoint t) ∧ (∀ k, MeasurableSet (t k)) ∧ (⋃ k, t k) = Set.univ ∧
      (∀ k, ApproximatesLinearOn f (A k) (t k) (δ (A k))) ∧
      (∀ k, ∀ x ∈ t k, ‖fderiv ℝ f x - A k‖ ≤ δ (A k)) := by
  have hcont : Continuous (fderiv ℝ f) := hf.continuous_fderiv one_ne_zero
  have hdiff : Differentiable ℝ f := hf.differentiable one_ne_zero
  have hloc : ∀ x : E, ∃ ρ > 0, Metric.ball x ρ ⊆
      fderiv ℝ f ⁻¹' Metric.ball (fderiv ℝ f x) (δ (fderiv ℝ f x)) := fun x =>
    Metric.mem_nhds_iff.1 (hcont.continuousAt (Metric.ball_mem_nhds _ (by exact_mod_cast hδ _)))
  choose ρ hρpos hρ using hloc
  obtain ⟨S, hSc, hSU⟩ := TopologicalSpace.countable_cover_nhds
    (fun x : E => Metric.ball_mem_nhds x (hρpos x))
  have hSne : S.Nonempty := by
    by_contra h
    rw [Set.not_nonempty_iff_eq_empty] at h
    have : (0 : E) ∈ ⋃ x ∈ S, Metric.ball x (ρ x) := by rw [hSU]; trivial
    simp [h] at this
  obtain ⟨c, hc⟩ := hSc.exists_eq_range hSne
  set B : ℕ → Set E := fun k => Metric.ball (c k) (ρ (c k))
  have hBU : (⋃ k, B k) = Set.univ := by
    rw [← hSU, hc]
    simp [B]
  refine ⟨disjointed B, fun k => fderiv ℝ f (c k), disjoint_disjointed B,
    fun k => MeasurableSet.disjointed (fun _ => Metric.isOpen_ball.measurableSet) k,
    by rw [iUnion_disjointed, hBU], fun k => ?_, fun k x hx => ?_⟩
  · have hbound : ∀ x ∈ B k, ‖fderiv ℝ f x - fderiv ℝ f (c k)‖ ≤ δ (fderiv ℝ f (c k)) := by
      intro x hx
      have := hρ (c k) hx
      rw [Set.mem_preimage, Metric.mem_ball, dist_eq_norm] at this
      exact this.le
    intro x hx y hy
    have hx' := disjointed_subset B k hx
    have hy' := disjointed_subset B k hy
    exact (convex_ball _ _).norm_image_sub_le_of_norm_fderiv_le' (fun z _ => hdiff z) hbound hy' hx'
  · have := hρ (c k) (disjointed_subset B k hx)
    rw [Set.mem_preimage, Metric.mem_ball, dist_eq_norm] at this
    exact this.le

/-- Choice of `δ` for a linear map, with all needed properties. -/
lemma exists_delta (A : E →L[ℝ] F) {ε : ℝ≥0} (hε : 0 < ε) :
    ∃ δ : ℝ≥0, 0 < δ ∧ (∀ B : E →L[ℝ] F, ‖B - A‖ ≤ δ → |nd B - nd A| ≤ ε) ∧
      (∀ (g : E → F) (t : Set E), ApproximatesLinearOn g A t δ →
        μHE[m] (g '' t) ≤ (ENNReal.ofReal (nd A) + ε) * μHE[m] t) ∧
      (∀ (g : E → F) (t : Set E), ApproximatesLinearOn g A t δ →
        ENNReal.ofReal (nd A) * μHE[m] t ≤ μHE[m] (g '' t) + ε * μHE[m] t) := by
  -- continuity of `nd`
  obtain ⟨δ1, hδ1, hδ1'⟩ : ∃ δ1 : ℝ, 0 < δ1 ∧ ∀ B, dist B A < δ1 → dist (nd B) (nd A) < ε :=
    Metric.continuous_iff.1 continuous_nd A ε (by exact_mod_cast hε)
  -- upper bound
  have hup : ENNReal.ofReal (nd A) < ((nd A).toNNReal + ε : ℝ≥0) := by
    rw [ENNReal.coe_add, ENNReal.ofReal]
    exact ENNReal.lt_add_right ENNReal.coe_ne_top (by exact_mod_cast hε.ne')
  obtain ⟨δ2, hδ2, hδ2'⟩ := image_le_of_approx A hup
  -- lower bound
  obtain ⟨δ3, hδ3, hδ3'⟩ : ∃ δ3 : ℝ≥0, 0 < δ3 ∧ ∀ (g : E → F) (t : Set E),
      ApproximatesLinearOn g A t δ3 →
        ENNReal.ofReal (nd A) * μHE[m] t ≤ μHE[m] (g '' t) + ε * μHE[m] t := by
    rcases eq_or_ne (nd A) 0 with h0 | h0
    · exact ⟨1, one_pos, fun g t _ => by simp [h0]⟩
    have hlt : (((nd A).toNNReal - ε : ℝ≥0) : ℝ≥0∞) < ENNReal.ofReal (nd A) := by
      rw [ENNReal.ofReal]
      exact_mod_cast tsub_lt_self (Real.toNNReal_pos.2 ((nd_nonneg A).lt_of_ne' h0)) hε
    obtain ⟨δ3, hδ3, hδ3'⟩ := le_image_of_approx A hlt
    refine ⟨δ3, hδ3, fun g t ht => ?_⟩
    calc ENNReal.ofReal (nd A) * μHE[m] t
        ≤ ((((nd A).toNNReal - ε : ℝ≥0) : ℝ≥0∞) + ε) * μHE[m] t := by
          gcongr
          rw [ENNReal.ofReal, ← ENNReal.coe_add]
          exact_mod_cast le_tsub_add
      _ = (((nd A).toNNReal - ε : ℝ≥0) : ℝ≥0∞) * μHE[m] t + ε * μHE[m] t := add_mul _ _ _
      _ ≤ μHE[m] (g '' t) + ε * μHE[m] t := by gcongr; exact hδ3' g t ht
  set δ1' : ℝ≥0 := (δ1 / 2).toNNReal
  have hδ1'c : (δ1' : ℝ) = δ1 / 2 := Real.coe_toNNReal _ (by linarith)
  refine ⟨min δ1' (min δ2 δ3), lt_min (Real.toNNReal_pos.2 (by linarith)) (lt_min hδ2 hδ3),
    ?_, ?_, ?_⟩
  · intro B hB
    have : dist B A < δ1 := by
      rw [dist_eq_norm]
      calc ‖B - A‖ ≤ (min δ1' (min δ2 δ3) : ℝ≥0) := hB
        _ ≤ δ1' := by exact_mod_cast min_le_left _ _
        _ < δ1 := by rw [hδ1'c]; linarith
    have := hδ1' B this
    rw [Real.dist_eq] at this
    exact this.le
  · intro g t ht
    have := hδ2' g t (ht.mono_num ((min_le_right _ _).trans (min_le_left _ _)))
    calc μHE[m] (g '' t) ≤ (((nd A).toNNReal + ε : ℝ≥0) : ℝ≥0∞) * μHE[m] t := this
      _ = (ENNReal.ofReal (nd A) + ε) * μHE[m] t := by rw [ENNReal.coe_add, ENNReal.ofReal]
  · intro g t ht
    exact hδ3' g t (ht.mono_num ((min_le_right _ _).trans (min_le_right _ _)))

lemma le_of_forall_err {a b c : ℝ≥0∞} (hc : c ≠ ∞)
    (h : ∀ ε : ℝ≥0, 0 < ε → a ≤ b + 2 * ε * c) : a ≤ b := by
  have : Tendsto (fun ε : ℝ≥0 => b + 2 * ε * c) (𝓝[>] 0) (𝓝 (b + 2 * (0 : ℝ≥0) * c)) := by
    apply Tendsto.mono_left _ nhdsWithin_le_nhds
    refine tendsto_const_nhds.add ?_
    refine ENNReal.Tendsto.mul_const ?_ (Or.inr hc)
    exact ENNReal.Tendsto.const_mul (ENNReal.tendsto_coe.2 tendsto_id) (Or.inr ENNReal.coe_ne_top)
  simp only [add_zero, zero_mul, mul_zero, ENNReal.coe_zero] at this
  apply ge_of_tendsto this
  filter_upwards [self_mem_nhdsWithin] with ε hε
  exact h ε hε

lemma image_iUnion_eq {f : E → F} (hf : Continuous f) (hinj : Function.Injective f) {u : ℕ → Set E}
    (hu : ∀ k, MeasurableSet (u k)) (hdisj : Pairwise (Function.onFun Disjoint u)) :
    μHE[m] (f '' ⋃ k, u k) = ∑' k, μHE[m] (f '' u k) := by
  rw [Set.image_iUnion]
  refine measure_iUnion (fun i j hij => (Set.disjoint_image_iff hinj).2 (hdisj hij)) fun k => ?_
  exact (hu k).image_of_continuousOn_injOn hf.continuousOn hinj.injOn

lemma area_aux {f : E → F} (hf : ContDiff ℝ 1 f) (hinj : Function.Injective f) {s : Set E}
    (hs : MeasurableSet s) {ε : ℝ≥0} (hε : 0 < ε) :
    μHE[m] (f '' s) ≤ (∫⁻ x in s, ENNReal.ofReal (nd (fderiv ℝ f x))) + 2 * ε * volume s ∧
    (∫⁻ x in s, ENNReal.ofReal (nd (fderiv ℝ f x))) ≤ μHE[m] (f '' s) + 2 * ε * volume s := by
  choose δ hδ using fun A : E →L[ℝ] F => exists_delta (m := m) A hε
  obtain ⟨t, A, tdisj, tmeas, tcover, happ, hder⟩ := exists_partition_C1 hf δ (fun A => (hδ A).1)
  have hvol : (μHE[m] : Measure E) = volume := EuclideanSpace.euclideanHausdorffMeasure_eq_volume m
  set J : E → ℝ≥0∞ := fun x => ENNReal.ofReal (nd (fderiv ℝ f x))
  have hJ : Measurable J := ENNReal.measurable_ofReal.comp
    (continuous_nd.comp (hf.continuous_fderiv one_ne_zero)).measurable
  have hs_eq : s = ⋃ k, s ∩ t k := by rw [← Set.inter_iUnion, tcover, Set.inter_univ]
  have hpt : ∀ k, ∀ x ∈ t k, |nd (fderiv ℝ f x) - nd (A k)| ≤ ε :=
    fun k x hx => (hδ (A k)).2.1 _ (hder k x hx)
  have happ' : ∀ k, ApproximatesLinearOn f (A k) (s ∩ t k) (δ (A k)) :=
    fun k => (happ k).mono_set Set.inter_subset_right
  have hmeas : ∀ k, MeasurableSet (s ∩ t k) := fun k => hs.inter (tmeas k)
  have hdisj : Pairwise (Function.onFun Disjoint fun k => s ∩ t k) := fun i j hij =>
    (tdisj hij).mono Set.inter_subset_right Set.inter_subset_right
  have himg : μHE[m] (f '' s) = ∑' k, μHE[m] (f '' (s ∩ t k)) := by
    conv_lhs => rw [hs_eq]
    exact image_iUnion_eq (hf.continuous) hinj hmeas hdisj
  have hint : ∀ g : E → ℝ≥0∞, ∫⁻ x in s, g x = ∑' k, ∫⁻ x in s ∩ t k, g x := by
    intro g
    conv_lhs => rw [hs_eq]
    exact lintegral_iUnion hmeas hdisj g
  have hvols : volume s = ∑' k, volume (s ∩ t k) := by
    conv_lhs => rw [hs_eq]
    exact measure_iUnion hdisj hmeas
  constructor
  · calc μHE[m] (f '' s) = ∑' k, μHE[m] (f '' (s ∩ t k)) := himg
      _ ≤ ∑' k, (ENNReal.ofReal (nd (A k)) + ε) * volume (s ∩ t k) := by
          refine tsum_le_tsum fun k => ?_
          have := (hδ (A k)).2.2.1 f (s ∩ t k) (happ' k)
          rwa [hvol] at this
      _ ≤ ∑' k, ∫⁻ x in s ∩ t k, (J x + 2 * ε) := by
          refine tsum_le_tsum fun k => ?_
          rw [← setLIntegral_const]
          refine setLIntegral_mono' (hmeas k) fun x hx => ?_
          have h1 := hpt k x hx.2
          have h2 : nd (A k) ≤ nd (fderiv ℝ f x) + ε := by
            have := (abs_le.mp h1).1
            linarith
          calc ENNReal.ofReal (nd (A k)) + ε ≤ ENNReal.ofReal (nd (fderiv ℝ f x) + ε) + ε := by
                gcongr
            _ = J x + 2 * ε := by
                rw [ENNReal.ofReal_add (nd_nonneg _) ε.coe_nonneg, ENNReal.ofReal_coe_nnreal,
                  two_mul, add_assoc]
      _ = ∫⁻ x in s, (J x + 2 * ε) := (hint _).symm
      _ = (∫⁻ x in s, J x) + 2 * ε * volume s := by
          rw [lintegral_add_right _ measurable_const, setLIntegral_const]
  · calc (∫⁻ x in s, J x) = ∑' k, ∫⁻ x in s ∩ t k, J x := hint _
      _ ≤ ∑' k, ∫⁻ x in s ∩ t k, (ENNReal.ofReal (nd (A k)) + ε) := by
          refine tsum_le_tsum fun k => ?_
          refine setLIntegral_mono' (hmeas k) fun x hx => ?_
          have h1 := hpt k x hx.2
          have h2 : nd (fderiv ℝ f x) ≤ nd (A k) + ε := by
            have := (abs_le.mp h1).2
            linarith
          calc J x ≤ ENNReal.ofReal (nd (A k) + ε) := ENNReal.ofReal_le_ofReal h2
            _ = ENNReal.ofReal (nd (A k)) + ε := by
                rw [ENNReal.ofReal_add (nd_nonneg _) ε.coe_nonneg, ENNReal.ofReal_coe_nnreal]
      _ = ∑' k, (ENNReal.ofReal (nd (A k)) * volume (s ∩ t k) + ε * volume (s ∩ t k)) := by
          congr 1; ext k
          rw [setLIntegral_const, add_mul]
      _ ≤ ∑' k, (μHE[m] (f '' (s ∩ t k)) + ε * volume (s ∩ t k) + ε * volume (s ∩ t k)) := by
          refine tsum_le_tsum fun k => ?_
          have := (hδ (A k)).2.2.2 f (s ∩ t k) (happ' k)
          rw [hvol] at this
          gcongr
      _ = μHE[m] (f '' s) + 2 * ε * volume s := by
          rw [himg, hvols, ← ENNReal.tsum_mul_left, ← tsum_add]
          congr 1; ext k
          rw [mul_assoc, two_mul, add_assoc]

/-- The area formula for an injective `C¹` map, with the Euclidean Hausdorff measure. -/
theorem area_formula_muHE {f : E → F} (hf : ContDiff ℝ 1 f) (hinj : Function.Injective f) {s : Set E}
    (hs : MeasurableSet s) :
    μHE[m] (f '' s) = ∫⁻ x in s, ENNReal.ofReal (nd (fderiv ℝ f x)) := by
  set J : E → ℝ≥0∞ := fun x => ENNReal.ofReal (nd (fderiv ℝ f x))
  have hfin : ∀ u : Set E, MeasurableSet u → volume u ≠ ∞ → μHE[m] (f '' u) = ∫⁻ x in u, J x := by
    intro u hu hu'
    apply le_antisymm
    · exact le_of_forall_err hu' fun ε hε => (area_aux hf hinj hu hε).1
    · exact le_of_forall_err hu' fun ε hε => (area_aux hf hinj hu hε).2
  let u n := disjointed (spanningSets (volume : Measure E)) n
  have u_meas : ∀ n, MeasurableSet (u n) := fun n =>
    MeasurableSet.disjointed (fun i => measurableSet_spanningSets _ i) n
  have hs_eq : s = ⋃ n, s ∩ u n := by
    rw [← Set.inter_iUnion, iUnion_disjointed, iUnion_spanningSets, Set.inter_univ]
  have hmeas : ∀ n, MeasurableSet (s ∩ u n) := fun n => hs.inter (u_meas n)
  have hdisj : Pairwise (Function.onFun Disjoint fun n => s ∩ u n) := fun i j hij =>
    (disjoint_disjointed _ hij).mono Set.inter_subset_right Set.inter_subset_right
  calc μHE[m] (f '' s) = ∑' n, μHE[m] (f '' (s ∩ u n)) := by
        conv_lhs => rw [hs_eq]
        exact image_iUnion_eq hf.continuous hinj hmeas hdisj
    _ = ∑' n, ∫⁻ x in s ∩ u n, J x := by
        congr 1; ext n
        refine hfin _ (hmeas n) ?_
        exact ne_of_lt (lt_of_le_of_lt (measure_mono (Set.inter_subset_right.trans
          (disjointed_subset _ _))) (measure_spanningSets_lt_top _ n))
    _ = ∫⁻ x in s, J x := by
        conv_rhs => rw [hs_eq]
        exact (lintegral_iUnion hmeas hdisj J).symm

end Area

#print axioms volume_twice_abs_lt
#print axioms volume_add_volume_le
#print axioms sliceLen_eq
#print axioms sliceLen_update
#print axioms measurable_sliceLen
#print axioms measurableSet_steiner
#print axioms sliceLen_steiner
#print axioms volume_steiner
#print axioms sum_update_sq
#print axioms diamLE_steiner
#print axioms refl_refl
#print axioms symmIn_iff
#print axioms symmIn_steiner_self
#print axioms symmIn_steiner_of_ne
#print axioms iter_props
#print axioms neg_mem_of_symm
#print axioms isodiametric
#print axioms vol_le_smul_hausdorff
#print axioms hausdorff_ball_le
#print axioms smul_hausdorff_eq_volume
#print axioms normalised_hausdorff_eq
#print axioms muHE_image_le_of_edist
#print axioms nd_nonneg
#print axioms nd_sq
#print axioms nd_eq_sqrt
#print axioms continuous_nd
#print axioms augL_apply
#print axioms norm_augL_sq
#print axioms gram_augL
#print axioms normDet_augL
#print axioms exists_pos_lt_of_continuous
#print axioms eventually_lt_of_continuous
#print axioms image_le_of_approx
#print axioms le_image_of_approx
#print axioms exists_partition_C1
#print axioms exists_delta
#print axioms le_of_forall_err
#print axioms image_iUnion_eq
#print axioms area_aux
#print axioms area_formula_muHE

end AreaCoarea

/-- The area formula. Let `f` be a one-to-one map from `ℝᵐ` to `ℝⁿ` with `m ≤ n` and with
continuous partial derivatives. Its derivative matrix `Df(x)` has `n` rows and `m` columns
(column `j` is the derivative of `f` along the `j`-th coordinate arrow), and its Jacobian is
`Jf(x) = √(det(Df(x)ᵀ Df(x)))`. Then for every Borel set `A` in `ℝᵐ`, the normalised
`m`-dimensional Hausdorff measure of the image `f(A)` (Mathlib's `μH[m]` times `V_m / 2^m`,
where `V_m` is the volume of the unit ball of `ℝᵐ`) equals the integral of `Jf` over `A`. -/
theorem area_formula_injective_C1 {m n : ℕ} (hmn : m ≤ n)
    {f : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin n)}
    (hf : ContDiff ℝ 1 f) (hinj : Function.Injective f)
    {A : Set (EuclideanSpace ℝ (Fin m))} (hA : MeasurableSet A) :
    volume (Metric.ball (0 : EuclideanSpace ℝ (Fin m)) 1) / 2 ^ m * μH[m] (f '' A) =
      ∫⁻ x in A, ENNReal.ofReal (Real.sqrt
        (((Matrix.of fun (i : Fin n) (j : Fin m) =>
              fderiv ℝ f x (EuclideanSpace.single j 1) i)ᵀ *
          Matrix.of fun (i : Fin n) (j : Fin m) =>
              fderiv ℝ f x (EuclideanSpace.single j 1) i).det)) := by
  rw [AreaCoarea.normalised_hausdorff_eq, AreaCoarea.area_formula_muHE hf hinj hA]
  refine lintegral_congr fun x => ?_
  rw [AreaCoarea.nd_eq_sqrt]
  congr 3
  ext j k
  simp [AreaCoarea.gramL, Matrix.gram, Matrix.mul_apply, PiLp.inner_apply, mul_comm]

/-- The coarea formula for a linear function. Let `u(x) = a · x` on `ℝⁿ⁺¹`, a dot product with
a fixed nonzero arrow `a`, so its climbing rate `|∇u|` is `|a|` everywhere. Then for every Borel
set `A`, the integral of `|∇u|` over `A` equals the integral over all levels `t` of the
normalised `n`-dimensional Hausdorff measure (Mathlib's `μH[n]` times `V_n / 2^n`) of the slice
`A ∩ {u = t}`. -/
theorem coarea_formula_linear {n : ℕ} (a : EuclideanSpace ℝ (Fin (n + 1))) (ha : a ≠ 0)
    {A : Set (EuclideanSpace ℝ (Fin (n + 1)))} (hA : MeasurableSet A) :
    ∫⁻ _x in A, ENNReal.ofReal ‖a‖ =
      ∫⁻ t : ℝ, volume (Metric.ball (0 : EuclideanSpace ℝ (Fin n)) 1) / 2 ^ n *
        μH[n] (A ∩ {x | inner ℝ a x = t}) := by
  simp_rw [AreaCoarea.normalised_hausdorff_eq]
  set v : EuclideanSpace ℝ (Fin (n + 1)) := (‖a‖ ^ 2)⁻¹ • a with hv
  have ha' : ‖a‖ ≠ 0 := norm_ne_zero_iff.mpr ha
  have hv0 : v ≠ 0 := by simp [hv, ha]
  have h := EuclideanGeometry.euclideanHausdorffMeasure_eq_lintegral (0 : EuclideanSpace ℝ (Fin (n + 1))) hv0 hA
  rw [InnerProductSpace.euclideanHausdorffMeasure_eq_volume] at h
  simp only [finrank_euclideanSpace, Fintype.card_fin, add_tsub_cancel_right, vadd_eq_add,
    add_zero] at h
  have hset : ∀ x : ℝ, (A ∩ (AffineSubspace.mk' (x • v) (ℝ ∙ v)ᗮ : Set _)) =
      A ∩ {y | inner ℝ a y = x} := by
    intro x
    ext y
    simp only [Set.mem_inter_iff, SetLike.mem_coe, AffineSubspace.mem_mk', vsub_eq_sub,
      Submodule.mem_orthogonal_singleton_iff_inner_right, Set.mem_ofPred_eq, inner_sub_right,
      inner_smul_right, hv, inner_smul_left, real_inner_self_eq_norm_sq]
    constructor <;> rintro ⟨h1, h2⟩ <;> refine ⟨h1, ?_⟩
    · field_simp at h2
      rcases mul_eq_zero.mp h2 with h2 | h2
      · simp [ha'] at h2
      · linarith
    · simp [h2]
      field_simp
      ring
  simp_rw [hset] at h
  rw [setLIntegral_const, h, ← mul_assoc]
  have : ENNReal.ofReal ‖a‖ * ‖v‖ₑ = 1 := by
    rw [hv, enorm_smul, ← ofReal_norm, ← ofReal_norm, ← mul_assoc,
      ← ENNReal.ofReal_mul (norm_nonneg _), ← ENNReal.ofReal_mul (by positivity)]
    simp
    field_simp
  rw [this, one_mul]

/-- The Cauchy–Binet reading for a surface in space: for an `3` by `2` matrix `L`, the
determinant of the `2` by `2` matrix of dot products `Lᵀ L` equals the sum of the squares of the
three `2` by `2` minors of `L`, which is the squared length of the cross product of its two
columns. So `Jf` for a surface in space is the length of that cross product. -/
theorem det_transpose_mul_self_eq_cross_sq (L : Matrix (Fin 3) (Fin 2) ℝ) :
    (Lᵀ * L).det = (Lᵀ 0 ⨯₃ Lᵀ 1) ⬝ᵥ (Lᵀ 0 ⨯₃ Lᵀ 1) ∧
      (Lᵀ * L).det = (L 0 0 * L 1 1 - L 1 0 * L 0 1) ^ 2 +
        (L 0 0 * L 2 1 - L 2 0 * L 0 1) ^ 2 + (L 1 0 * L 2 1 - L 2 0 * L 1 1) ^ 2 := by
  constructor <;>
  · simp only [Matrix.det_fin_two, Matrix.mul_apply, Matrix.transpose_apply, Fin.sum_univ_three,
      cross_apply, dotProduct, Fin.sum_univ_three, Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
    ring

-- Worked numbers from the card, in exact fractions.
-- The dish z = x^2 + y^2 at (0.3, 0.4): derivative columns (1, 0, 0.6) and (0, 1, 0.8);
-- Df^T Df has entries 1.36, 0.48, 0.48, 1.64, and its determinant is 2.
example : (!![1, 0; 0, 1; 3 / 5, 4 / 5] : Matrix (Fin 3) (Fin 2) ℚ)ᵀ *
    (!![1, 0; 0, 1; 3 / 5, 4 / 5] : Matrix (Fin 3) (Fin 2) ℚ) =
      !![34 / 25, 12 / 25; 12 / 25, 41 / 25] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_three]
example : (!![34 / 25, 12 / 25; 12 / 25, 41 / 25] : Matrix (Fin 2) (Fin 2) ℚ).det = 2 := by
  norm_num [Matrix.det_fin_two]
-- By minors (the cross product): 1^2 + 0.8^2 + (-0.6)^2 = 2.
example : (1 : ℚ) ^ 2 + (4 / 5) ^ 2 + (-3 / 5) ^ 2 = 2 := by norm_num
-- Jf^2 = 1 + 4r^2 with r^2 = 0.3^2 + 0.4^2 = 0.25, so Jf^2 = 2.
example : (1 : ℚ) + 4 * ((3 / 10) ^ 2 + (4 / 10) ^ 2) = 2 := by norm_num
-- In general det(Df^T Df) = (1 + 4x^2)(1 + 4y^2) - (4xy)^2 = 1 + 4x^2 + 4y^2.
example (x y : ℚ) : (1 + 4 * x ^ 2) * (1 + 4 * y ^ 2) - (4 * x * y) ^ 2 = 1 + 4 * x ^ 2 + 4 * y ^ 2 := by
  ring
-- The wrong 3 by 3 matrix Df Df^T at (0.3, 0.4) has determinant 0.
example : (!![1, 0, 3 / 5; 0, 1, 4 / 5; 3 / 5, 4 / 5, 1] : Matrix (Fin 3) (Fin 3) ℚ).det = 0 := by
  norm_num [Matrix.det_fin_three]
-- Linear coarea: |grad u| = 5 for u = 3x + 4y and 13 for u = 5x + 12y.
example : (3 : ℚ) ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num
example : (5 : ℚ) ^ 2 + 12 ^ 2 = 13 ^ 2 := by norm_num
-- On the unit square, u = 3x + 4y runs over the levels 0 to 3 + 4 = 7.
example : (3 : ℚ) + 4 = 7 := by norm_num

#print axioms area_formula_injective_C1
#print axioms coarea_formula_linear
#print axioms det_transpose_mul_self_eq_cross_sq
