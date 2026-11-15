-- Schauder: a continuous map of a nonempty compact convex set in a Banach space into itself has a fixed point, as does a continuous self-map of a closed convex set whose image has compact closure, while Kakutani's map of the closed unit ball of ℓ² has none.
import Mathlib.Analysis.Normed.Lp.lpSpace
import Mathlib.Analysis.Convex.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.MetricSpace.Pseudo.Defs
import Mathlib

open Set Metric

section SchauderHelpers

open MeasureTheory Polynomial

/-- The functions continuous on a set form a subring. -/
def contOnSubring {α : Type*} [TopologicalSpace α] (s : Set α) : Subring (α → ℝ) where
  carrier := {g | ContinuousOn g s}
  mul_mem' ha hb := ContinuousOn.mul ha hb
  one_mem' := continuousOn_const
  add_mem' ha hb := ContinuousOn.add ha hb
  zero_mem' := continuousOn_const
  neg_mem' ha := ContinuousOn.neg ha

theorem det_one_add_smul_eq {n : ℕ}
    (L : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) (t : ℝ) :
    ((1 : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) + t • L).det =
      (1 + t • Matrix.of (fun i j => L (EuclideanSpace.single j 1) i)).det := by
  classical
  let b := (EuclideanSpace.basisFun (Fin n) ℝ).toBasis
  rw [ContinuousLinearMap.det, ← LinearMap.det_toMatrix b]
  congr 1
  ext i j
  simp [LinearMap.toMatrix_apply, b, Matrix.one_apply]

theorem integral_det_poly {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))} (hs : IsCompact s)
    {A : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)}
    (hA : ContinuousOn A s) :
    ∃ R : ℝ[X], ∀ t : ℝ, R.eval t =
      ∫ x in s, ((1 : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) + t • A x).det := by
  classical
  let S := contOnSubring s
  have hc : ∀ i j : Fin n, ContinuousOn (fun x => A x (EuclideanSpace.single j 1) i) s := by
    intro i j
    have : Continuous fun L : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n) =>
        L (EuclideanSpace.single j 1) i := by fun_prop
    exact this.comp_continuousOn hA
  let m : Matrix (Fin n) (Fin n) S := Matrix.of fun i j => ⟨fun x => A x (EuclideanSpace.single j 1) i, hc i j⟩
  let N : Matrix (Fin n) (Fin n) S[X] := (X : S[X]) • m.map C + 1
  let D := N.det
  let K := D.natDegree + 1
  have hpt : ∀ x t, ((1 : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) + t • A x).det
      = ∑ i ∈ Finset.range K, (D.coeff i : _ → ℝ) x * t ^ i := by
    intro x t
    let φ : S →+* ℝ := (Pi.evalRingHom (fun _ => ℝ) x).comp S.subtype
    have h1 : (D.map φ).eval t = ∑ i ∈ Finset.range K, (D.coeff i : _ → ℝ) x * t ^ i := by
      rw [eval_eq_sum_range' (natDegree_map_le.trans_lt (Nat.lt_succ_self _))]
      simp [coeff_map, φ, K]
    rw [← h1, det_one_add_smul_eq, eval_map, ← coe_eval₂RingHom, RingHom.map_det]
    congr 1
    ext i j
    simp only [N, m, φ, Matrix.one_apply, Matrix.add_apply, Matrix.smul_apply, Matrix.map_apply,
      Matrix.of_apply, RingHom.mapMatrix_apply]
    split_ifs <;> simp [eval₂_C] <;> ring
  refine ⟨∑ i ∈ Finset.range K, C (∫ x in s, (D.coeff i : _ → ℝ) x) * X ^ i, fun t => ?_⟩
  simp_rw [hpt]
  rw [integral_finsetSum]
  · simp [eval_finsetSum, integral_mul_const]
  · intro i _
    exact ((D.coeff i).2.mul continuousOn_const).integrableOn_compact hs

theorem radial_lip {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (x y : E) :
    ‖(max 1 ‖x‖)⁻¹ • x - (max 1 ‖y‖)⁻¹ • y‖ ≤ 2 * ‖x - y‖ := by
  set a := max 1 ‖x‖ with ha_def
  set b := max 1 ‖y‖ with hb_def
  have ha : 1 ≤ a := le_max_left _ _
  have hb : 1 ≤ b := le_max_left _ _
  have hyb : ‖y‖ ≤ b := le_max_right _ _
  have hab : |b - a| ≤ ‖x - y‖ := by
    calc |b - a| = |max ‖y‖ 1 - max ‖x‖ 1| := by rw [max_comm ‖y‖, max_comm ‖x‖]
      _ ≤ |‖y‖ - ‖x‖| := abs_max_sub_max_le_abs _ _ _
      _ = |‖x‖ - ‖y‖| := abs_sub_comm _ _
      _ ≤ ‖x - y‖ := abs_norm_sub_norm_le x y
  have hsplit : a⁻¹ • x - b⁻¹ • y = a⁻¹ • (x - y) + (a⁻¹ - b⁻¹) • y := by
    rw [smul_sub, sub_smul]; abel
  have ha0 : 0 < a := by linarith
  have hb0 : 0 < b := by linarith
  have h1 : a⁻¹ * ‖x - y‖ ≤ ‖x - y‖ := by
    have : a⁻¹ ≤ 1 := inv_le_one_of_one_le₀ ha
    nlinarith [norm_nonneg (x - y)]
  have h2 : |a⁻¹ - b⁻¹| * ‖y‖ ≤ ‖x - y‖ := by
    have he : a⁻¹ - b⁻¹ = (b - a) / (a * b) := by field_simp
    rw [he, abs_div, abs_of_pos (mul_pos ha0 hb0)]
    rw [div_mul_eq_mul_div, div_le_iff₀ (mul_pos ha0 hb0)]
    calc |b - a| * ‖y‖ ≤ |b - a| * b := mul_le_mul_of_nonneg_left hyb (abs_nonneg _)
      _ ≤ ‖x - y‖ * b := mul_le_mul_of_nonneg_right hab hb0.le
      _ ≤ ‖x - y‖ * (a * b) := by
          apply mul_le_mul_of_nonneg_left _ (norm_nonneg _)
          nlinarith
  rw [hsplit]
  calc _ ≤ ‖a⁻¹ • (x - y)‖ + ‖(a⁻¹ - b⁻¹) • y‖ := norm_add_le _ _
    _ = a⁻¹ * ‖x - y‖ + |a⁻¹ - b⁻¹| * ‖y‖ := by
        rw [norm_smul, norm_smul, Real.norm_eq_abs, Real.norm_eq_abs, abs_of_pos (inv_pos.2 ha0)]
    _ ≤ 2 * ‖x - y‖ := by linarith

theorem det_ne_zero_of_norm_lt_one {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] (L : E →L[ℝ] E) (hL : ‖L‖ < 1) : ((1 : E →L[ℝ] E) + L).det ≠ 0 := by
  have hinj : Function.Injective ((1 : E →L[ℝ] E) + L) := by
    rw [injective_iff_map_eq_zero]
    intro v hv
    have hv' : v = -(L v) := by
      have : v + L v = 0 := by simpa using hv
      exact eq_neg_of_add_eq_zero_left this
    have hle : ‖v‖ ≤ ‖L‖ * ‖v‖ := by
      calc ‖v‖ = ‖-(L v)‖ := by rw [← hv']
        _ = ‖L v‖ := norm_neg _
        _ ≤ ‖L‖ * ‖v‖ := L.le_opNorm v
    have : ‖v‖ = 0 := by nlinarith [norm_nonneg v, norm_nonneg L]
    exact norm_eq_zero.1 this
  have hu : IsUnit (((1 : E →L[ℝ] E) + L) : E →ₗ[ℝ] E) :=
    (LinearMap.isUnit_iff_ker_eq_bot _).2 (LinearMap.ker_eq_bot.2 hinj)
  exact ((LinearMap.isUnit_iff_isUnit_det _).1 hu).ne_zero

theorem det_pos_of_norm_lt_one {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] (L : E →L[ℝ] E) (hL : ‖L‖ < 1) : 0 < ((1 : E →L[ℝ] E) + L).det := by
  set h : ℝ → ℝ := fun s => ((1 : E →L[ℝ] E) + s • L).det with hh
  have hc : Continuous h := ContinuousLinearMap.continuous_det.comp (by fun_prop)
  have hne : ∀ s ∈ Icc (0 : ℝ) 1, h s ≠ 0 := by
    intro s hs
    apply det_ne_zero_of_norm_lt_one
    rw [norm_smul, Real.norm_eq_abs, abs_of_nonneg hs.1]
    calc s * ‖L‖ ≤ 1 * ‖L‖ := mul_le_mul_of_nonneg_right hs.2 (norm_nonneg _)
      _ < 1 := by rw [one_mul]; exact hL
  have h0 : h 0 = 1 := by
    simp only [hh, zero_smul, add_zero]
    exact LinearMap.det_id
  have h1 : h 1 = ((1 : E →L[ℝ] E) + L).det := by simp [hh]
  rw [← h1]
  by_contra hle
  push Not at hle
  have : (0 : ℝ) ∈ Icc (h 1) (h 0) := ⟨hle, by rw [h0]; norm_num⟩
  obtain ⟨s, hs, hs0⟩ := intermediate_value_Icc' zero_le_one hc.continuousOn this
  exact hne s hs hs0

theorem det_eq_zero_of_norm_one {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E] {r : E → E} {L : E →L[ℝ] E} {x : E} (hr : HasFDerivAt r L x)
    (hn : ∀ᶠ y in nhds x, ‖r y‖ = 1) : L.det = 0 := by
  by_contra hdet
  have h1 := hr.norm_sq
  have h2 : HasFDerivAt (fun y => ‖r y‖ ^ 2) (0 : E →L[ℝ] ℝ) x := by
    apply (hasFDerivAt_const (1 : ℝ) x).congr_of_eventuallyEq
    filter_upwards [hn] with y hy
    simp [hy]
  have heq := h1.unique h2
  have hu : IsUnit (L : E →ₗ[ℝ] E) := (LinearMap.isUnit_iff_isUnit_det _).2 (Ne.isUnit hdet)
  have hrange := (LinearMap.isUnit_iff_range_eq_top _).1 hu
  obtain ⟨v, hv⟩ : r x ∈ LinearMap.range (L : E →ₗ[ℝ] E) := by rw [hrange]; trivial
  have := congrArg (fun T : E →L[ℝ] ℝ => T v) heq
  simp only [smul_apply, ContinuousLinearMap.comp_apply, zero_apply] at this
  have hv' : L v = r x := hv
  rw [hv', innerSL_apply_apply, real_inner_self_eq_norm_sq, hn.self_of_nhds] at this
  norm_num at this

theorem no_C1_retraction {n : ℕ} {U : Set (EuclideanSpace ℝ (Fin n))} (hU : IsOpen U)
    (hBU : closedBall (0 : EuclideanSpace ℝ (Fin n)) 1 ⊆ U)
    {u : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)}
    (hu : ContDiffOn ℝ 1 u U) (hnorm : ∀ x ∈ U, ‖x + u x‖ = 1)
    (hsph : ∀ x : EuclideanSpace ℝ (Fin n), ‖x‖ = 1 → u x = 0) : False := by
  set B := closedBall (0 : EuclideanSpace ℝ (Fin n)) 1 with hBdef
  have hBc : IsCompact B := isCompact_closedBall 0 1
  set A := fun x => fderiv ℝ u x with hAdef
  have hAc : ContinuousOn A U := hu.continuousOn_fderiv_of_isOpen hU le_rfl
  have hdiff : ∀ x ∈ U, HasFDerivAt u (A x) x := fun x hx =>
    (((hu.differentiableOn one_ne_zero) x hx).differentiableAt (hU.mem_nhds hx)).hasFDerivAt
  obtain ⟨M0, hM0⟩ := hBc.exists_bound_of_continuousOn (hAc.mono hBU)
  set M := max M0 0 with hMdef
  have hM : ∀ x ∈ B, ‖A x‖ ≤ M := fun x hx => (hM0 x hx).trans (le_max_left _ _)
  have hM0' : 0 ≤ M := le_max_right _ _
  have hlip : ∀ x ∈ B, ∀ y ∈ B, ‖u x - u y‖ ≤ M * ‖x - y‖ := by
    intro x hx y hy
    exact (convex_closedBall (0 : EuclideanSpace ℝ (Fin n)) 1).norm_image_sub_le_of_norm_fderiv_le
      (fun z hz => (hdiff z (hBU hz)).differentiableAt) (fun z hz => hM z hz) hy hx
  set p : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n) :=
    fun x => (max 1 ‖x‖)⁻¹ • x with hp
  have hmax : ∀ x : EuclideanSpace ℝ (Fin n), 0 < max 1 ‖x‖ :=
    fun x => lt_of_lt_of_le one_pos (le_max_left _ _)
  have hpB : ∀ x, p x ∈ B := by
    intro x
    rw [mem_closedBall_zero_iff, hp, norm_smul, Real.norm_eq_abs, abs_of_pos (inv_pos.2 (hmax x)),
      inv_mul_le_iff₀ (hmax x), mul_one]
    exact le_max_right _ _
  have hpid : ∀ x ∈ B, p x = x := by
    intro x hx
    rw [mem_closedBall_zero_iff] at hx
    simp [hp, max_eq_left hx]
  have hpsph : ∀ x, x ∉ B → ‖p x‖ = 1 := by
    intro x hx
    rw [mem_closedBall_zero_iff, not_le] at hx
    show ‖(max 1 ‖x‖)⁻¹ • x‖ = 1
    rw [max_eq_right hx.le, norm_smul, norm_inv, norm_norm,
      inv_mul_cancel₀ (by positivity)]
  set t0 : ℝ := 1 / (4 * (M + 1)) with ht0
  have ht0pos : 0 < t0 := by positivity
  have key : ∀ t ∈ Ioo (0 : ℝ) t0, volume.real B =
      ∫ x in B, ((1 : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) + t • A x).det := by
    intro t ht
    have hM1 : 0 < 4 * (M + 1) := by positivity
    have htM' : t * (4 * (M + 1)) < 1 := by
      have := ht.2
      rw [ht0, lt_div_iff₀ hM1] at this
      exact this
    have htM : t * M ≤ 1 / 4 := by nlinarith [ht.1]
    have ht1 : t < 1 := by nlinarith [ht.1]
    set g := fun x : EuclideanSpace ℝ (Fin n) => x + t • u x with hg
    have hinj : InjOn g B := by
      intro x hx y hy hxy
      have h1 : x - y = t • u y - t • u x := by
        calc x - y = (x + t • u x) - (y + t • u y) + (t • u y - t • u x) := by abel
          _ = t • u y - t • u x := by
              have : x + t • u x = y + t • u y := hxy
              rw [this, sub_self, zero_add]
      have h2 : ‖x - y‖ ≤ (1 / 4) * ‖x - y‖ := by
        calc ‖x - y‖ = t * ‖u y - u x‖ := by
              rw [h1, ← smul_sub, norm_smul, Real.norm_eq_abs, abs_of_pos ht.1]
          _ ≤ t * (M * ‖y - x‖) := mul_le_mul_of_nonneg_left (hlip y hy x hx) ht.1.le
          _ = (t * M) * ‖x - y‖ := by rw [norm_sub_rev]; ring
          _ ≤ (1 / 4) * ‖x - y‖ := mul_le_mul_of_nonneg_right htM (norm_nonneg _)
      have : ‖x - y‖ = 0 := by nlinarith [norm_nonneg (x - y)]
      exact sub_eq_zero.1 (norm_eq_zero.1 this)
    have hmaps : ∀ x ∈ B, g x ∈ B := by
      intro x hx
      have hx' : ‖x‖ ≤ 1 := mem_closedBall_zero_iff.1 hx
      have he : g x = (1 - t) • x + t • (x + u x) := by
        simp only [hg, smul_add, sub_smul, one_smul]; abel
      rw [mem_closedBall_zero_iff, he]
      calc ‖(1 - t) • x + t • (x + u x)‖ ≤ ‖(1 - t) • x‖ + ‖t • (x + u x)‖ := norm_add_le _ _
        _ = (1 - t) * ‖x‖ + t * ‖x + u x‖ := by
            rw [norm_smul, norm_smul, Real.norm_eq_abs, Real.norm_eq_abs, abs_of_pos (by linarith),
              abs_of_pos ht.1]
        _ ≤ (1 - t) * 1 + t * 1 := by
            rw [hnorm x (hBU hx)]
            nlinarith
        _ = 1 := by ring
    have hsurj : ∀ y ∈ B, ∃ x ∈ B, g x = y := by
      intro y hy
      set Φ := fun z : EuclideanSpace ℝ (Fin n) => y - t • u (p z) with hΦ
      have hΦc : ContractingWith (2⁻¹ : NNReal) Φ := by
        refine ⟨by norm_num, LipschitzWith.of_dist_le_mul fun z w => ?_⟩
        rw [dist_eq_norm, dist_eq_norm]
        calc ‖Φ z - Φ w‖ = t * ‖u (p w) - u (p z)‖ := by
              rw [hΦ, sub_sub_sub_cancel_left, ← smul_sub, norm_smul, Real.norm_eq_abs,
                abs_of_pos ht.1]
          _ ≤ t * (M * ‖p w - p z‖) :=
              mul_le_mul_of_nonneg_left (hlip _ (hpB w) _ (hpB z)) ht.1.le
          _ ≤ t * (M * (2 * ‖w - z‖)) := by
              apply mul_le_mul_of_nonneg_left _ ht.1.le
              exact mul_le_mul_of_nonneg_left (radial_lip w z) hM0'
          _ = 2 * (t * M) * ‖z - w‖ := by rw [norm_sub_rev]; ring
          _ ≤ 2 * (1 / 4) * ‖z - w‖ := by
              apply mul_le_mul_of_nonneg_right _ (norm_nonneg _); linarith
          _ = ((2⁻¹ : NNReal) : ℝ) * ‖z - w‖ := by norm_num
      set z := ContractingWith.fixedPoint Φ hΦc
      have hz : Φ z = z := ContractingWith.fixedPoint_isFixedPt hΦc
      by_cases hzB : z ∈ B
      · refine ⟨z, hzB, ?_⟩
        have : y - t • u z = z := by
          have h := hz
          simp only [hΦ, hpid z hzB] at h
          exact h
        show z + t • u z = y
        calc z + t • u z = (y - t • u z) + t • u z := by rw [this]
          _ = y := sub_add_cancel _ _
      · exfalso
        have h0 : u (p z) = 0 := hsph _ (hpsph z hzB)
        have : y = z := by rw [← hz, hΦ]; simp [h0]
        exact hzB (this ▸ hy)
    have himg : g '' B = B :=
      Subset.antisymm (image_subset_iff.2 hmaps) fun y hy => by
        obtain ⟨x, hx, hxy⟩ := hsurj y hy
        exact ⟨x, hx, hxy⟩
    have hder : ∀ x ∈ B, HasFDerivWithinAt g
        ((1 : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) + t • A x) B x :=
      fun x hx => ((hasFDerivAt_id x).add ((hdiff x (hBU hx)).const_smul t)).hasFDerivWithinAt
    have hpos : ∀ x ∈ B,
        0 < ((1 : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) + t • A x).det := by
      intro x hx
      apply det_pos_of_norm_lt_one
      rw [norm_smul, Real.norm_eq_abs, abs_of_pos ht.1]
      calc t * ‖A x‖ ≤ t * M := mul_le_mul_of_nonneg_left (hM x hx) ht.1.le
        _ < 1 := by linarith
    have hcv := integral_image_eq_integral_abs_det_fderiv_smul volume measurableSet_closedBall
      hder hinj (fun _ => (1 : ℝ))
    rw [himg, setIntegral_const, smul_eq_mul, mul_one] at hcv
    rw [hcv]
    apply setIntegral_congr_fun measurableSet_closedBall
    intro x hx
    simp [abs_of_pos (hpos x hx)]
  obtain ⟨R, hR⟩ := integral_det_poly hBc (hAc.mono hBU)
  have hRC : R = C (volume.real B) := by
    apply Polynomial.eq_of_infinite_eval_eq
    apply Set.Infinite.mono _ (Set.Ioo_infinite ht0pos)
    intro t ht
    simp only [mem_ofPred_eq, eval_C, hR, ← key t ht]
  have hzero : ∫ x in B,
      ((1 : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) + (1 : ℝ) • A x).det = 0 := by
    apply setIntegral_eq_zero_of_forall_eq_zero
    intro x hx
    rw [one_smul]
    apply det_eq_zero_of_norm_one (r := fun y => y + u y) ((hasFDerivAt_id x).add (hdiff x (hBU hx)))
    filter_upwards [hU.mem_nhds (hBU hx)] with y hy using hnorm y hy
  have hV : volume.real B = 0 := by
    have := hR 1
    rw [hRC, eval_C, hzero] at this
    exact this
  have hVpos : 0 < volume.real B :=
    ENNReal.toReal_pos (measure_closedBall_pos volume 0 one_pos).ne' measure_closedBall_lt_top.ne
  linarith

theorem no_smooth_fixed_point_free_map {n : ℕ}
    {G : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)} (hG : ContDiff ℝ 1 G)
    (hfix : ∀ x ∈ closedBall (0 : EuclideanSpace ℝ (Fin n)) 1, G x ≠ x ∧ ‖G x‖ ≤ 1) : False := by
  set w := fun x : EuclideanSpace ℝ (Fin n) => x - G x with hwdef
  set a := fun x => ‖w x‖ ^ 2 with hadef
  set b := fun x : EuclideanSpace ℝ (Fin n) => inner ℝ x (w x) with hbdef
  set c := fun x : EuclideanSpace ℝ (Fin n) => 1 - ‖x‖ ^ 2 with hcdef
  set d := fun x => b x ^ 2 + a x * c x with hddef
  set u := fun x => ((-(b x) + Real.sqrt (d x)) / a x) • w x with hudef
  set U := {x | 0 < a x ∧ 0 < d x} with hUdef
  have hw : ContDiff ℝ 1 w := contDiff_id.sub hG
  have ha : ContDiff ℝ 1 a := hw.norm_sq ℝ
  have hb : ContDiff ℝ 1 b := contDiff_id.inner ℝ hw
  have hc : ContDiff ℝ 1 c := contDiff_const.sub (contDiff_id.norm_sq ℝ)
  have hd : ContDiff ℝ 1 d := (hb.pow 2).add (ha.mul hc)
  have hUo : IsOpen U :=
    (isOpen_lt continuous_const ha.continuous).inter (isOpen_lt continuous_const hd.continuous)
  have huc : ContDiffOn ℝ 1 u U := by
    intro x hx
    apply ContDiffAt.contDiffWithinAt
    rw [hudef]
    exact ContDiffAt.smul (ContDiffAt.div (hb.contDiffAt.neg.add (hd.contDiffAt.sqrt hx.2.ne'))
      ha.contDiffAt hx.1.ne') hw.contDiffAt
  have hn : ∀ x ∈ U, ‖x + u x‖ = 1 := by
    intro x hx
    set τ := (-(b x) + Real.sqrt (d x)) / a x with hτ
    set s := Real.sqrt (d x) with hsdef
    have hs : s ^ 2 = b x ^ 2 + a x * c x := Real.sq_sqrt hx.2.le
    have h1 : τ * a x = s - b x := by
      rw [hτ, div_mul_cancel₀ _ hx.1.ne']; ring
    have hq : a x * τ ^ 2 + 2 * b x * τ - c x = 0 := by
      have : (a x * τ ^ 2 + 2 * b x * τ - c x) * a x = 0 := by
        linear_combination (τ * a x + s + b x) * h1 + hs
      rcases mul_eq_zero.1 this with h | h
      · exact h
      · exact absurd h hx.1.ne'
    have hsq : ‖x + u x‖ ^ 2 = 1 := by
      show ‖x + τ • w x‖ ^ 2 = 1
      rw [norm_add_sq_real, norm_smul, inner_smul_right, mul_pow, Real.norm_eq_abs, sq_abs]
      have hc' : c x = 1 - ‖x‖ ^ 2 := rfl
      have ha' : a x = ‖w x‖ ^ 2 := rfl
      have hb' : b x = inner ℝ x (w x) := rfl
      rw [ha', hb', hc'] at hq
      linear_combination hq
    have h0 : 0 ≤ ‖x + u x‖ := norm_nonneg _
    nlinarith
  have hbpos : ∀ x : EuclideanSpace ℝ (Fin n), ‖x‖ = 1 → 0 < a x → ‖G x‖ ≤ 1 → 0 < b x := by
    intro x hx hax hGx
    have e1 : a x = ‖x‖ ^ 2 - 2 * inner ℝ x (G x) + ‖G x‖ ^ 2 := norm_sub_sq_real x (G x)
    have e2 : b x = ‖x‖ ^ 2 - inner ℝ x (G x) := by
      show inner ℝ x (x - G x) = _
      rw [inner_sub_right, real_inner_self_eq_norm_sq]
    rw [hx] at e1 e2
    have : ‖G x‖ ^ 2 ≤ 1 := by nlinarith [norm_nonneg (G x)]
    nlinarith
  have hBU : closedBall (0 : EuclideanSpace ℝ (Fin n)) 1 ⊆ U := by
    intro x hx
    have hax : 0 < a x := pow_pos (norm_pos_iff.2 (sub_ne_zero.2 (hfix x hx).1.symm)) 2
    refine ⟨hax, ?_⟩
    have hx' : ‖x‖ ≤ 1 := mem_closedBall_zero_iff.1 hx
    rcases hx'.lt_or_eq with hlt | heq
    · have : 0 < c x := by
        show 0 < 1 - ‖x‖ ^ 2
        nlinarith [norm_nonneg x]
      show 0 < b x ^ 2 + a x * c x
      nlinarith [sq_nonneg (b x), mul_pos hax this]
    · have hb0 := hbpos x heq hax (hfix x hx).2
      have : c x = 0 := by show 1 - ‖x‖ ^ 2 = 0; rw [heq]; norm_num
      show 0 < b x ^ 2 + a x * c x
      rw [this, mul_zero, add_zero]; positivity
  have hsph : ∀ x : EuclideanSpace ℝ (Fin n), ‖x‖ = 1 → u x = 0 := by
    intro x hx
    have hxB : x ∈ closedBall (0 : EuclideanSpace ℝ (Fin n)) 1 :=
      mem_closedBall_zero_iff.2 hx.le
    have hax := (hBU hxB).1
    have hb0 := hbpos x hx hax (hfix x hxB).2
    have hc0 : c x = 0 := by show 1 - ‖x‖ ^ 2 = 0; rw [hx]; norm_num
    have hd0 : d x = b x ^ 2 := by show b x ^ 2 + a x * c x = _; rw [hc0, mul_zero, add_zero]
    show ((-(b x) + Real.sqrt (d x)) / a x) • w x = 0
    rw [hd0, Real.sqrt_sq hb0.le]
    simp
  exact no_C1_retraction hUo hBU huc hn hsph

theorem smooth_approx_coord {n : ℕ} (φ : EuclideanSpace ℝ (Fin n) → ℝ)
    (hφ : ContinuousOn φ (closedBall 0 1)) {ε : ℝ} (hε : 0 < ε) :
    ∃ g : EuclideanSpace ℝ (Fin n) → ℝ, ContDiff ℝ 1 g ∧
      ∀ x ∈ closedBall (0 : EuclideanSpace ℝ (Fin n)) 1, |g x - φ x| < ε := by
  set B := closedBall (0 : EuclideanSpace ℝ (Fin n)) 1 with hB
  have : CompactSpace B := isCompact_iff_compactSpace.1 (isCompact_closedBall 0 1)
  let S : Subalgebra ℝ C(B, ℝ) :=
    { carrier := {g | ∃ G : EuclideanSpace ℝ (Fin n) → ℝ, ContDiff ℝ 1 G ∧ ∀ x : B, g x = G x}
      mul_mem' := by
        rintro f g ⟨F, hF, hFf⟩ ⟨G, hG, hGg⟩
        exact ⟨fun x => F x * G x, hF.mul hG, fun x => by simp [hFf, hGg]⟩
      add_mem' := by
        rintro f g ⟨F, hF, hFf⟩ ⟨G, hG, hGg⟩
        exact ⟨fun x => F x + G x, hF.add hG, fun x => by simp [hFf, hGg]⟩
      algebraMap_mem' := fun r => ⟨fun _ => r, contDiff_const, fun x => by simp⟩ }
  have hsep : S.SeparatesPoints := by
    intro x y hxy
    have hne : (x : EuclideanSpace ℝ (Fin n)) ≠ y := fun h => hxy (Subtype.ext h)
    obtain ⟨i, hi⟩ : ∃ i, (x : EuclideanSpace ℝ (Fin n)) i ≠ (y : EuclideanSpace ℝ (Fin n)) i := by
      by_contra h
      push Not at h
      exact hne (PiLp.ext h)
    let e : C(B, ℝ) := ContinuousMap.mk (fun z => (z : EuclideanSpace ℝ (Fin n)) i) (by fun_prop)
    have heS : e ∈ S := ⟨fun z => z i,
      (EuclideanSpace.proj i : EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ).contDiff, fun _ => rfl⟩
    exact ⟨e, ⟨e, heS, rfl⟩, hi⟩
  obtain ⟨g, hg⟩ := ContinuousMap.exists_mem_subalgebra_near_continuous_of_separatesPoints S hsep
    (fun x => φ x) hφ.domRestrict ε hε
  obtain ⟨G, hG, hGg⟩ := g.2
  refine ⟨G, hG, fun x hx => ?_⟩
  have h1 := hg ⟨x, hx⟩
  rw [hGg, Real.norm_eq_abs] at h1
  exact h1

theorem smooth_approx {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (hf : ContinuousOn f (closedBall 0 1)) {ε : ℝ} (hε : 0 < ε) :
    ∃ G : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n), ContDiff ℝ 1 G ∧
      ∀ x ∈ closedBall (0 : EuclideanSpace ℝ (Fin n)) 1, ‖G x - f x‖ ≤ ε := by
  have hε' : 0 < ε / (n + 1) := by positivity
  have hfi : ∀ i : Fin n, ContinuousOn (fun x => f x i) (closedBall 0 1) := fun i =>
    (EuclideanSpace.proj i : EuclideanSpace ℝ (Fin n) →L[ℝ] ℝ).continuous.comp_continuousOn hf
  choose g hg hgε using fun i => smooth_approx_coord (fun x => f x i) (hfi i) hε'
  refine ⟨fun x => (EuclideanSpace.equiv (Fin n) ℝ).symm (fun i => g i x),
    (EuclideanSpace.equiv (Fin n) ℝ).symm.contDiff.comp (contDiff_pi.2 hg), fun x hx => ?_⟩
  rw [EuclideanSpace.norm_eq]
  have hsum : ∑ i, ‖((EuclideanSpace.equiv (Fin n) ℝ).symm (fun i => g i x) - f x) i‖ ^ 2
      ≤ ∑ _i : Fin n, (ε / (n + 1)) ^ 2 := by
    apply Finset.sum_le_sum
    intro i _
    have := hgε i x hx
    have h2 : ‖((EuclideanSpace.equiv (Fin n) ℝ).symm (fun i => g i x) - f x) i‖ ≤ ε / (n + 1) := by
      simpa [Real.norm_eq_abs] using this.le
    exact pow_le_pow_left₀ (norm_nonneg _) h2 2
  rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul] at hsum
  have h3 : (n : ℝ) * (ε / (n + 1)) ^ 2 ≤ ε ^ 2 := by
    rw [div_pow, ← mul_div_assoc, div_le_iff₀ (by positivity)]
    have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    nlinarith [sq_nonneg ε, mul_nonneg this (sq_nonneg ε)]
  calc Real.sqrt _ ≤ Real.sqrt (ε ^ 2) := Real.sqrt_le_sqrt (hsum.trans h3)
    _ = ε := Real.sqrt_sq hε.le

theorem brouwer_ball {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (hf : ContinuousOn f (closedBall 0 1)) (hmaps : MapsTo f (closedBall 0 1) (closedBall 0 1)) :
    ∃ x ∈ closedBall (0 : EuclideanSpace ℝ (Fin n)) 1, f x = x := by
  by_contra hno
  push Not at hno
  obtain ⟨x0, hx0, hmin⟩ := (isCompact_closedBall (0 : EuclideanSpace ℝ (Fin n)) 1).exists_isMinOn
    (nonempty_closedBall.2 zero_le_one) (hf.sub continuousOn_id).norm
  set δ := ‖f x0 - x0‖ with hδdef
  have hδ : 0 < δ := norm_pos_iff.2 (sub_ne_zero.2 (hno x0 hx0))
  obtain ⟨G, hG, hGε⟩ := smooth_approx f hf (by positivity : 0 < δ / 4)
  set k := (1 + δ / 4)⁻¹ with hk
  have hk1 : k * (1 + δ / 4) = 1 := inv_mul_cancel₀ (by positivity)
  have hk0 : 0 < k := by positivity
  have hkle : k ≤ 1 := inv_le_one_of_one_le₀ (by linarith)
  apply no_smooth_fixed_point_free_map (G := fun x => k • G x)
    ((contDiff_const (c := k)).smul hG)
  intro x hx
  have hfx : ‖f x‖ ≤ 1 := mem_closedBall_zero_iff.1 (hmaps hx)
  have hGx : ‖G x‖ ≤ 1 + δ / 4 := by
    calc ‖G x‖ = ‖(G x - f x) + f x‖ := by rw [sub_add_cancel]
      _ ≤ ‖G x - f x‖ + ‖f x‖ := norm_add_le _ _
      _ ≤ δ / 4 + 1 := add_le_add (hGε x hx) hfx
      _ = 1 + δ / 4 := by ring
  have hkG : ‖k • G x‖ ≤ 1 := by
    rw [norm_smul, Real.norm_eq_abs, abs_of_pos hk0]
    calc k * ‖G x‖ ≤ k * (1 + δ / 4) := mul_le_mul_of_nonneg_left hGx hk0.le
      _ = 1 := hk1
  have hdist : ‖k • G x - f x‖ ≤ δ / 2 := by
    calc ‖k • G x - f x‖ = ‖(k • G x - G x) + (G x - f x)‖ := by congr 1; abel
      _ ≤ ‖k • G x - G x‖ + ‖G x - f x‖ := norm_add_le _ _
      _ = (1 - k) * ‖G x‖ + ‖G x - f x‖ := by
          rw [show k • G x - G x = (k - 1) • G x by rw [sub_smul, one_smul], norm_smul,
            Real.norm_eq_abs, abs_of_nonpos (by linarith), neg_sub]
      _ ≤ (1 - k) * (1 + δ / 4) + δ / 4 :=
          add_le_add (mul_le_mul_of_nonneg_left hGx (by linarith)) (hGε x hx)
      _ = δ / 2 := by nlinarith
  have hmin' : δ ≤ ‖f x - x‖ := hmin hx
  refine ⟨fun h => ?_, hkG⟩
  have h' : k • G x = x := h
  rw [h', norm_sub_rev] at hdist
  linarith

/-- The standard simplex of weight vectors on `m` points. -/
def schSimplex (m : ℕ) : Set (Fin m → ℝ) := {l | (∀ i, 0 ≤ l i) ∧ ∑ i, l i = 1}

theorem brouwer_simplex {m : ℕ} (hm : 0 < m) (g : (Fin m → ℝ) → (Fin m → ℝ))
    (hg : ContinuousOn g (schSimplex m)) (hgm : MapsTo g (schSimplex m) (schSimplex m)) :
    ∃ t ∈ schSimplex m, g t = t := by
  set ρ : (Fin m → ℝ) → (Fin m → ℝ) := fun x i =>
    max (x i) 0 / max 1 (∑ j, max (x j) 0) + max (1 - ∑ j, max (x j) 0) 0 / m with hρ
  have hρc : Continuous ρ := by
    apply continuous_pi
    intro i
    apply Continuous.add
    · apply Continuous.div (by fun_prop) (by fun_prop)
      intro x
      exact (lt_of_lt_of_le one_pos (le_max_left _ _)).ne'
    · fun_prop
  have hm' : (m : ℝ) ≠ 0 := by positivity
  have hρΔ : ∀ x, ρ x ∈ schSimplex m := by
    intro x
    refine ⟨fun i => add_nonneg (div_nonneg (le_max_right _ _)
      (le_trans zero_le_one (le_max_left _ _))) (div_nonneg (le_max_right _ _) (Nat.cast_nonneg _)),
      ?_⟩
    simp only [hρ]
    rw [Finset.sum_add_distrib, ← Finset.sum_div, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul, mul_div_cancel₀ _ hm']
    set s := ∑ j, max (x j) 0
    rcases le_total s 1 with h | h
    · rw [max_eq_left h, div_one, max_eq_left (by linarith)]; ring
    · rw [max_eq_right h, div_self (by linarith), max_eq_right (by linarith)]; ring
  have hρid : ∀ l ∈ schSimplex m, ρ l = l := by
    intro l hl
    have hpos : ∀ j, max (l j) 0 = l j := fun j => max_eq_left (hl.1 j)
    funext i
    simp only [hρ, hpos, hl.2, max_self, div_one, sub_self, zero_div, add_zero]
  let e := EuclideanSpace.equiv (Fin m) ℝ
  have hΔB : ∀ l ∈ schSimplex m, e.symm l ∈ closedBall (0 : EuclideanSpace ℝ (Fin m)) 1 := by
    intro l hl
    rw [mem_closedBall_zero_iff, EuclideanSpace.norm_eq]
    have h1 : ∑ i, ‖(e.symm l) i‖ ^ 2 ≤ 1 := by
      calc ∑ i, ‖(e.symm l) i‖ ^ 2 = ∑ i, l i ^ 2 := by
            apply Finset.sum_congr rfl
            intro i _
            rw [Real.norm_eq_abs, sq_abs]
            rfl
        _ ≤ ∑ i, l i := by
            apply Finset.sum_le_sum
            intro i _
            have h0 := hl.1 i
            have h1 : l i ≤ 1 := by
              rw [← hl.2]
              exact Finset.single_le_sum (fun j _ => hl.1 j) (Finset.mem_univ i)
            nlinarith
        _ = 1 := hl.2
    calc Real.sqrt _ ≤ Real.sqrt 1 := Real.sqrt_le_sqrt h1
      _ = 1 := Real.sqrt_one
  set h : EuclideanSpace ℝ (Fin m) → EuclideanSpace ℝ (Fin m) := fun z => e.symm (g (ρ (e z)))
  have hgρ : Continuous fun z => g (ρ (e z)) :=
    hg.comp_continuous (hρc.comp e.continuous) (fun z => hρΔ _)
  have hhc : ContinuousOn h (closedBall 0 1) := (e.symm.continuous.comp hgρ).continuousOn
  obtain ⟨z, -, hfz⟩ := brouwer_ball h hhc (fun z _ => hΔB _ (hgm (hρΔ _)))
  have hl : g (ρ (e z)) = e z := by
    have := congrArg e hfz
    simpa [h] using this
  have hlΔ : e z ∈ schSimplex m := hl ▸ hgm (hρΔ (e z))
  refine ⟨e z, hlΔ, ?_⟩
  rw [hρid _ hlΔ] at hl
  exact hl

end SchauderHelpers

theorem schauder_approx
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {K : Set X} (hne : K.Nonempty) (hK : IsCompact K) (hconv : Convex ℝ K)
    {f : X → X} (hf : ContinuousOn f K) (hmaps : MapsTo f K K) {ε : ℝ} (hε : 0 < ε) :
    ∃ x ∈ K, ‖f x - x‖ ≤ ε := by
  obtain ⟨t, htK, hcov⟩ := hK.elim_nhds_subcover _ (fun x _ => ball_mem_nhds x hε)
  obtain ⟨m, e, he⟩ := (t : Set X).toFinite.fin_embedding
  set y : Fin m → X := fun i => e i with hy
  have hyK : ∀ i, y i ∈ K := fun i =>
    htK (y i) (Finset.mem_coe.1 (he ▸ mem_range_self i))
  let μ : X → Fin m → ℝ := fun z i => max 0 (ε - ‖z - y i‖)
  have hμ0 : ∀ z i, 0 ≤ μ z i := fun z i => le_max_left _ _
  have hμpos : ∀ z ∈ K, 0 < ∑ i, μ z i := by
    intro z hz
    obtain ⟨w, hw, hzw⟩ := mem_iUnion₂.1 (hcov hz)
    have hw' : w ∈ range e := by rw [he]; exact hw
    obtain ⟨i, rfl⟩ := hw'
    have : 0 < μ z i := by
      rw [mem_ball, dist_eq_norm] at hzw
      exact lt_max_of_lt_right (by simp only [hy]; linarith)
    exact lt_of_lt_of_le this
      (Finset.single_le_sum (fun j _ => hμ0 z j) (Finset.mem_univ i))
  let A : (Fin m → ℝ) → X := fun l => ∑ i, l i • y i
  have hAc : Continuous A := by fun_prop
  have hAK : MapsTo A (schSimplex m) K := fun l hl =>
    hconv.sum_mem (fun i _ => hl.1 i) hl.2 (fun i _ => hyK i)
  let g : (Fin m → ℝ) → (Fin m → ℝ) := fun l i => μ (f (A l)) i / ∑ j, μ (f (A l)) j
  have hμc : ∀ i, Continuous fun z => μ z i := fun i => by fun_prop
  have hfA : ContinuousOn (fun l => f (A l)) (schSimplex m) :=
    hf.comp hAc.continuousOn hAK
  have hgc : ContinuousOn g (schSimplex m) := by
    apply continuousOn_pi.2
    intro i
    apply ContinuousOn.div
    · exact (hμc i).comp_continuousOn hfA
    · exact continuousOn_finsetSum _ (fun j _ => (hμc j).comp_continuousOn hfA)
    · intro l hl; exact (hμpos _ (hmaps (hAK hl))).ne'
  have hgm : MapsTo g (schSimplex m) (schSimplex m) := by
    intro l hl
    have hp := hμpos _ (hmaps (hAK hl))
    refine ⟨fun i => div_nonneg (hμ0 _ _) hp.le, ?_⟩
    simp only [g]
    rw [← Finset.sum_div, div_self hp.ne']
  have hm : 0 < m := by
    obtain ⟨z, hz⟩ := hne
    obtain ⟨w, hw, -⟩ := mem_iUnion₂.1 (hcov hz)
    have hw' : w ∈ range e := by rw [he]; exact hw
    obtain ⟨i, -⟩ := hw'
    exact i.pos
  obtain ⟨l, hl, hfix⟩ := brouwer_simplex hm g hgc hgm
  refine ⟨A l, hAK hl, ?_⟩
  have hp := hμpos _ (hmaps (hAK hl))
  have hAl : A l = ∑ i, l i • y i := rfl
  have hzsum : f (A l) - A l = ∑ i, l i • (f (A l) - y i) := by
    simp only [smul_sub, Finset.sum_sub_distrib, ← Finset.sum_smul, hl.2, one_smul, hAl]
  rw [hzsum]
  set z := f (A l) with hz
  calc ‖∑ i, l i • (z - y i)‖ ≤ ∑ i, ‖l i • (z - y i)‖ := norm_sum_le _ _
    _ ≤ ∑ i, l i * ε := by
        apply Finset.sum_le_sum
        intro i _
        rw [norm_smul, Real.norm_of_nonneg (hl.1 i)]
        by_cases h0 : l i = 0
        · simp [h0]
        · apply mul_le_mul_of_nonneg_left _ (hl.1 i)
          have hli : l i = μ z i / ∑ j, μ z j := (congrFun hfix i).symm
          have : 0 < μ z i := by
            rcases (hμ0 z i).lt_or_eq with h | h
            · exact h
            · exfalso; apply h0; rw [hli, ← h, zero_div]
          have : 0 < ε - ‖z - y i‖ := by
            by_contra hc; push Not at hc
            have : μ z i = 0 := max_eq_left hc
            linarith
          linarith
    _ = ε := by rw [← Finset.sum_mul, hl.2, one_mul]

theorem schauder_of_brouwer
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    {K : Set X} (hne : K.Nonempty) (hK : IsCompact K) (hconv : Convex ℝ K)
    {f : X → X} (hf : ContinuousOn f K) (hmaps : MapsTo f K K) :
    ∃ x ∈ K, f x = x := by
  have hdc : ContinuousOn (fun x => ‖f x - x‖) K := (hf.sub continuousOn_id).norm
  obtain ⟨x0, hx0, hmin⟩ := hK.exists_isMinOn hne hdc
  refine ⟨x0, hx0, ?_⟩
  by_contra hne0
  have hpos : 0 < ‖f x0 - x0‖ := norm_pos_iff.2 (sub_ne_zero.2 hne0)
  obtain ⟨x, hx, hle⟩ := schauder_approx hne hK hconv hf hmaps (half_pos hpos)
  have := hmin hx
  simp only [mem_ofPred_eq] at this
  linarith

abbrev L2 := lp (fun _ : ℕ => ℝ) 2

theorem kak_hasSum (x : L2) : HasSum (fun i => x i ^ 2) (‖x‖ ^ 2) := by
  have h := lp.hasSum_norm (p := 2) (by norm_num) x
  simpa [Real.rpow_two, Real.norm_eq_abs, sq_abs] using h

def kakCons (c : ℝ) (x : ℕ → ℝ) : ℕ → ℝ
  | 0 => c
  | n + 1 => x n

theorem kakCons_hasSum (c : ℝ) (x : L2) :
    HasSum (fun i => kakCons c x i ^ 2) (c ^ 2 + ‖x‖ ^ 2) := by
  rw [← hasSum_nat_add_iff' 1]
  simpa [kakCons] using kak_hasSum x

def kakL (c : ℝ) (x : L2) : L2 :=
  ⟨kakCons c x, by
    apply memℓp_gen
    have := (kakCons_hasSum c x).summable
    simpa [Real.rpow_two, Real.norm_eq_abs, sq_abs] using this⟩

theorem kakL_norm_sq (c : ℝ) (x : L2) : ‖kakL c x‖ ^ 2 = c ^ 2 + ‖x‖ ^ 2 :=
  (kak_hasSum (kakL c x)).unique (kakCons_hasSum c x)

theorem kakL_sub (c d : ℝ) (x y : L2) : kakL c x - kakL d y = kakL (c - d) (x - y) := by
  ext n
  rw [lp.coeFn_sub]
  cases n <;> rfl

theorem kakL_dist (c d : ℝ) (x y : L2) : ‖kakL c x - kakL d y‖ ≤ |c - d| + ‖x - y‖ := by
  rw [kakL_sub]
  have h := kakL_norm_sq (c - d) (x - y)
  have h1 : 0 ≤ ‖kakL (c - d) (x - y)‖ := norm_nonneg _
  have h2 : 0 ≤ ‖x - y‖ := norm_nonneg _
  have h3 : 0 ≤ |c - d| := abs_nonneg _
  nlinarith [sq_abs (c - d)]

/-- Schauder's fixed point theorem: in a Banach space X (a complete normed space over ℝ), a
continuous map f that sends a nonempty compact convex set K into itself leaves some point x* of K
unmoved: f(x*) = x*. -/
theorem continuous_self_map_of_compact_convex_set_has_fixed_point
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    {K : Set X} (hne : K.Nonempty) (hK : IsCompact K) (hconv : Convex ℝ K)
    {f : X → X} (hf : ContinuousOn f K) (hmaps : MapsTo f K K) :
    ∃ x ∈ K, f x = x := by
  exact schauder_of_brouwer hne hK hconv hf hmaps

/-- The working form: in a Banach space X, a continuous map f that sends a nonempty closed
convex set C into itself, and whose outputs f(C) have compact closure, leaves some point x* of C
unmoved: f(x*) = x*. -/
theorem continuous_self_map_with_compact_image_closure_has_fixed_point
    {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    {C : Set X} (hne : C.Nonempty) (hC : IsClosed C) (hconv : Convex ℝ C)
    {f : X → X} (hf : ContinuousOn f C) (hmaps : MapsTo f C C)
    (himg : IsCompact (closure (f '' C))) :
    ∃ x ∈ C, f x = x := by
  set K := closure (convexHull ℝ (f '' C)) with hKdef
  have hsub : K ⊆ C :=
    closure_minimal (convexHull_min (image_subset_iff.2 hmaps) hconv) hC
  have hKc : IsCompact K :=
    ((himg.totallyBounded.subset subset_closure).convexHull.closure).isCompact_of_isClosed
      isClosed_closure
  obtain ⟨x, hx, hfx⟩ := continuous_self_map_of_compact_convex_set_has_fixed_point ((hne.image f).convexHull.closure)
    hKc (convex_convexHull ℝ _).closure (hf.mono hsub)
    (fun x hx => subset_closure (subset_convexHull ℝ _ (mem_image_of_mem f (hsub hx))))
  exact ⟨x, hsub hx, hfx⟩

/-- Compactness cannot be dropped: on ℓ², the endless lists with a finite sum of squares, there is
a continuous map g with g(x) = (√(1 − ‖x‖²), x₁, x₂, …) that sends the closed unit ball, a closed,
bounded, convex set, into itself, yet moves every point of that ball (Kakutani's map). -/
theorem kakutani_map_of_l2_ball_has_no_fixed_point :
    ∃ g : lp (fun _ : ℕ => ℝ) 2 → lp (fun _ : ℕ => ℝ) 2,
      Continuous g ∧
      (∀ x, g x 0 = Real.sqrt (1 - ‖x‖ ^ 2) ∧ ∀ n, g x (n + 1) = x n) ∧
      MapsTo g (closedBall 0 1) (closedBall 0 1) ∧
      ∀ x ∈ closedBall (0 : lp (fun _ : ℕ => ℝ) 2) 1, g x ≠ x := by
  refine ⟨fun x => kakL (Real.sqrt (1 - ‖x‖ ^ 2)) x, ?_, fun x => ⟨rfl, fun n => rfl⟩, ?_, ?_⟩
  · have hc : Continuous fun x : L2 => Real.sqrt (1 - ‖x‖ ^ 2) := by fun_prop
    rw [Metric.continuous_iff] at hc ⊢
    intro x ε hε
    obtain ⟨δ, hδ, hδ'⟩ := hc x (ε / 2) (by positivity)
    refine ⟨min δ (ε / 2), by positivity, fun y hy => ?_⟩
    rw [dist_eq_norm]
    have h1 := hδ' y (lt_of_lt_of_le hy (min_le_left _ _))
    rw [Real.dist_eq] at h1
    have h2 : ‖y - x‖ < ε / 2 := by
      rw [← dist_eq_norm]; exact lt_of_lt_of_le hy (min_le_right _ _)
    linarith [kakL_dist (Real.sqrt (1 - ‖y‖ ^ 2)) (Real.sqrt (1 - ‖x‖ ^ 2)) y x]
  · intro x hx
    rw [mem_closedBall_zero_iff] at hx ⊢
    have h := kakL_norm_sq (Real.sqrt (1 - ‖x‖ ^ 2)) x
    have h0 : 0 ≤ 1 - ‖x‖ ^ 2 := by nlinarith [norm_nonneg x]
    rw [Real.sq_sqrt h0] at h
    have : ‖kakL (Real.sqrt (1 - ‖x‖ ^ 2)) x‖ ^ 2 ≤ 1 ^ 2 := by linarith
    exact (pow_le_pow_iff_left₀ (norm_nonneg _) zero_le_one two_ne_zero).1 this
  · intro x hx hfix
    have hstep : ∀ n, x (n + 1) = x n := fun n => by
      have := congrArg (fun y : L2 => y (n + 1)) hfix
      simpa [kakL, kakCons] using this.symm
    have hconst : ∀ n, x n = x 0 := by
      intro n; induction n with
      | zero => rfl
      | succ n ih => rw [hstep, ih]
    have hsum := (kak_hasSum x).summable
    have h0 : x 0 = 0 := by
      have ht := hsum.tendsto_atTop_zero
      simp_rw [hconst] at ht
      have := tendsto_nhds_unique ht tendsto_const_nhds
      exact pow_eq_zero_iff two_ne_zero |>.1 this.symm
    have hx0 : x = 0 := by
      ext n; rw [hconst, h0]; rfl
    have := congrArg (fun y : L2 => y 0) hfix
    simp only [kakL, kakCons] at this
    rw [hx0] at this
    simp at this

-- The market's clearing prices, in £, sum to the £100 basket:
-- grain 3325/96 = 34.635417, cloth 2275/96 = 23.697917, fuel 125/3 = 41.666667.
example : (3325 / 96 : ℚ) + 2275 / 96 + 125 / 3 = 100 := by norm_num

-- Ann's wealth 8·p₁ + p₂ + 2·p₃ = 36875/96 = 384.114583 and Ben's 2·p₁ + 9·p₂ + 4·p₃ = 43125/96 = 449.21875.
example : 8 * (3325 / 96 : ℚ) + 2275 / 96 + 2 * (125 / 3) = 36875 / 96 := by norm_num
example : 2 * (3325 / 96 : ℚ) + 9 * (2275 / 96) + 4 * (125 / 3) = 43125 / 96 := by norm_num

-- At those prices the traders want exactly what they own: 10 grain, 10 cloth, 6 fuel.
example : ((1 / 5 : ℚ) * (36875 / 96) + 3 / 5 * (43125 / 96)) / (3325 / 96) = 10 := by norm_num
example : ((1 / 2 : ℚ) * (36875 / 96) + 1 / 10 * (43125 / 96)) / (2275 / 96) = 10 := by norm_num
example : ((3 / 10 : ℚ) * (36875 / 96) + 3 / 10 * (43125 / 96)) / (125 / 3) = 6 := by norm_num

-- The fuel and cloth equations from the hand table: 7.2·p₃ = 300 and 12.8·p₂ = 303.333333.
example : (36 / 5 : ℚ) * (125 / 3) = 300 := by norm_num
example : (64 / 5 : ℚ) * (2275 / 96) = 21 / 5 * (100 - 125 / 3) + 7 / 5 * (125 / 3) := by norm_num

-- The tank: q·τ = (1/100)·100 = 1 m, and the depth tends to (q/k)² = 1 m.
example : (1 / 100 : ℚ) * 100 = 1 := by norm_num
example : ((1 / 100 : ℚ) / (1 / 100)) ^ 2 = 1 := by norm_num

-- The backwards tank's second solution (k·t/2)² at k = 1/100, t = 100 s is 1/4 m.
example : ((1 / 100 : ℚ) * 100 / 2) ^ 2 = 1 / 4 := by norm_num

-- The jumping fuel demand: every price moves by at least 2·(10 − 5) = 10 pounds.
example : 2 * min (10 - 5) (5 - 0) = (10 : ℕ) := by decide

#print axioms continuous_self_map_of_compact_convex_set_has_fixed_point
#print axioms continuous_self_map_with_compact_image_closure_has_fixed_point
#print axioms kakutani_map_of_l2_ball_has_no_fixed_point
#print axioms det_one_add_smul_eq
#print axioms integral_det_poly
#print axioms radial_lip
#print axioms det_ne_zero_of_norm_lt_one
#print axioms det_pos_of_norm_lt_one
#print axioms det_eq_zero_of_norm_one
#print axioms no_C1_retraction
#print axioms no_smooth_fixed_point_free_map
#print axioms smooth_approx_coord
#print axioms smooth_approx
#print axioms brouwer_ball
#print axioms brouwer_simplex
#print axioms schauder_approx
#print axioms schauder_of_brouwer
#print axioms kak_hasSum
#print axioms kakCons_hasSum
#print axioms kakL_norm_sq
#print axioms kakL_sub
#print axioms kakL_dist
