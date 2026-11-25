-- The direct method: a coercive, convex, lower semicontinuous energy on a reflexive space has a minimiser at which every directional derivative is 0, the slot energy ∫(¼u'⁴ − u) has the single minimiser ¾[(½)^(4/3) − |x − ½|^(4/3)] solving its Euler-Lagrange equation weakly, and Bolza's energy has zigzags with energy 1/(12n²) but no profile with energy 0.
import Mathlib.Analysis.Normed.Module.DoubleDual
import Mathlib.Analysis.Convex.Function
import Mathlib.Topology.Semicontinuity.Basic
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.LocallyConvex.WeakSpace
import Mathlib.Analysis.Normed.Module.WeakDual
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.InnerProductSpace.NormPow
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Topology.MetricSpace.HausdorffDistance
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
import Mathlib.Analysis.Calculus.FDeriv.Measurable

lemma bolza_intervalIntegrable {w : ℝ → ℝ} {K : NNReal} (hw : LipschitzWith K w) (a b : ℝ) :
    IntervalIntegrable (fun x => ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2) MeasureTheory.volume a b := by
  have hc : Continuous w := hw.continuous
  refine IntervalIntegrable.add ?_ ((hc.pow 2).intervalIntegrable a b)
  have hm : Measurable (deriv w) := measurable_deriv w
  have hb : ∀ x, ‖((deriv w x) ^ 2 - 1) ^ 2‖ ≤ ((K : ℝ) ^ 2 + 1) ^ 2 := by
    intro x
    have h1 : ‖deriv w x‖ ≤ K := norm_deriv_le_of_lipschitz hw
    rw [Real.norm_eq_abs] at h1 ⊢
    rw [abs_of_nonneg (sq_nonneg _)]
    have hd2 : deriv w x ^ 2 ≤ (K : ℝ) ^ 2 := sq_le_sq' (abs_le.mp h1).1 (abs_le.mp h1).2
    have hd0 : 0 ≤ deriv w x ^ 2 := sq_nonneg _
    have hK0 : 0 ≤ (K : ℝ) ^ 2 := sq_nonneg _
    exact sq_le_sq' (by linarith) (by linarith)
  have hmeas : ∀ μ : MeasureTheory.Measure ℝ,
      MeasureTheory.AEStronglyMeasurable (fun x => ((deriv w x) ^ 2 - 1) ^ 2) μ :=
    fun μ => (((hm.pow_const 2).sub_const 1).pow_const 2).aestronglyMeasurable
  exact ⟨MeasureTheory.IntegrableOn.of_bound measure_Ioc_lt_top (hmeas _) _
      (Filter.Eventually.of_forall hb),
    MeasureTheory.IntegrableOn.of_bound measure_Ioc_lt_top (hmeas _) _
      (Filter.Eventually.of_forall hb)⟩

#print axioms bolza_intervalIntegrable

lemma bolza_zigzag (n : ℕ) (hn : 0 < n) : ∃ w : ℝ → ℝ, LipschitzWith 1 w ∧ w 0 = 0 ∧ w 1 = 0 ∧
      (∫ x in (0 : ℝ)..1, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2) = 1 / (12 * (n : ℝ) ^ 2) := by
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  set h : ℝ := 1 / (n : ℝ) with hh
  have hpos : 0 < h := by positivity
  set S : Set ℝ := Set.range (fun k : ℤ => (k : ℝ) / n) with hS
  have hmemS : ∀ k : ℤ, (k : ℝ) / n ∈ S := fun k => ⟨k, rfl⟩
  have h0S : (0 : ℝ) ∈ S := by simpa using hmemS 0
  have hhS : h ∈ S := by simpa [hh] using hmemS 1
  set w : ℝ → ℝ := fun x => Metric.infDist x S with hw
  have hlip : LipschitzWith 1 w := Metric.lipschitz_infDist_pt S
  have hw0 : w 0 = 0 := Metric.infDist_zero_of_mem h0S
  have hw1 : w 1 = 0 := Metric.infDist_zero_of_mem (by simpa [hnR.ne'] using hmemS n)
  have hSshift : (fun x => x + h) '' S = S := by
    ext y
    constructor
    · rintro ⟨_, ⟨k, rfl⟩, rfl⟩
      exact ⟨k + 1, by simp only [hh]; push_cast; ring⟩
    · rintro ⟨k, rfl⟩
      exact ⟨((k - 1 : ℤ) : ℝ) / n, hmemS _, by simp only [hh]; push_cast; ring⟩
  have hper : Function.Periodic w h := by
    intro x
    have hiso : Isometry (fun x : ℝ => x + h) :=
      Isometry.of_dist_eq (fun x y => dist_add_right x y h)
    have := Metric.infDist_image hiso (x := x) (t := S)
    rw [hSshift] at this
    exact this
  have hform : ∀ t ∈ Set.Icc 0 h, w t = min t (h - t) := by
    intro t ht
    apply le_antisymm
    · apply le_min
      · have := Metric.infDist_le_dist_of_mem (x := t) h0S
        rw [Real.dist_eq, sub_zero, abs_of_nonneg ht.1] at this
        exact this
      · have := Metric.infDist_le_dist_of_mem (x := t) hhS
        rw [Real.dist_eq, abs_of_nonpos (by linarith [ht.2])] at this
        linarith
    · by_contra hlt
      push Not at hlt
      obtain ⟨y, ⟨k, rfl⟩, hy⟩ := (Metric.infDist_lt_iff ⟨0, h0S⟩).mp hlt
      rw [Real.dist_eq] at hy
      rcases le_or_gt k 0 with hk | hk
      · have h1 : (k : ℝ) / n ≤ 0 :=
          div_nonpos_of_nonpos_of_nonneg (by exact_mod_cast hk) hnR.le
        have h2 := lt_of_lt_of_le hy (min_le_left _ _)
        have h3 := le_abs_self (t - k / n)
        linarith
      · have hk1 : (1 : ℝ) ≤ k := by exact_mod_cast hk
        have h1 : h ≤ (k : ℝ) / n := by
          rw [hh]; exact div_le_div_of_nonneg_right hk1 hnR.le
        have h2 := lt_of_lt_of_le hy (min_le_right _ _)
        have h3 := neg_abs_le (t - k / n)
        linarith
  have hd1 : ∀ t ∈ Set.Ioo 0 (h / 2), deriv w t = 1 := by
    intro t ht
    have heq : w =ᶠ[nhds t] id := by
      filter_upwards [Ioo_mem_nhds ht.1 ht.2] with y hy
      rw [hform y ⟨hy.1.le, by linarith [hy.2]⟩, min_eq_left (by linarith [hy.2])]
      rfl
    rw [heq.deriv_eq]
    simp
  have hd2 : ∀ t ∈ Set.Ioo (h / 2) h, deriv w t = -1 := by
    intro t ht
    have heq : w =ᶠ[nhds t] fun y => h - y := by
      filter_upwards [Ioo_mem_nhds ht.1 ht.2] with y hy
      rw [hform y ⟨by linarith [hy.1], hy.2.le⟩, min_eq_right (by linarith [hy.1])]
    rw [heq.deriv_eq]
    simp
  have hint := fun a b => bolza_intervalIntegrable hlip a b
  have hA : (∫ x in (0 : ℝ)..h / 2, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2)
      = ∫ x in (0 : ℝ)..h / 2, x ^ 2 := by
    apply intervalIntegral.integral_congr_Ioo_of_le (by linarith)
    intro x hx
    simp only
    rw [hd1 x hx, hform x ⟨hx.1.le, by linarith [hx.2]⟩, min_eq_left (by linarith [hx.2])]
    ring
  have hB : (∫ x in h / 2..h, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2)
      = ∫ x in h / 2..h, (h - x) ^ 2 := by
    apply intervalIntegral.integral_congr_Ioo_of_le (by linarith)
    intro x hx
    simp only
    rw [hd2 x hx, hform x ⟨by linarith [hx.1], hx.2.le⟩, min_eq_right (by linarith [hx.1])]
    ring
  have hB' : (∫ x in h / 2..h, (h - x) ^ 2) = ∫ x in (0 : ℝ)..h / 2, x ^ 2 := by
    rw [intervalIntegral.integral_comp_sub_left (fun x : ℝ => x ^ 2) h,
      show h - h = 0 by ring, show h - h / 2 = h / 2 by ring]
  have hcell : (∫ x in (0 : ℝ)..h, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2) = h ^ 3 / 12 := by
    rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 (h / 2)) (hint (h / 2) h),
      hA, hB, hB', integral_pow]
    ring
  have hdper : ∀ x, deriv w (x + h) = deriv w x := by
    intro x
    rw [← deriv_comp_add_const]
    congr 1
    funext y
    exact hper y
  have hHper : Function.Periodic (fun x => ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2) h := by
    intro x
    simp only [hdper x, hper x]
  have h1eq : (0 : ℝ) + (n : ℤ) • h = 1 := by
    rw [zsmul_eq_mul, hh]
    push_cast
    field_simp
    norm_num
  have := hHper.intervalIntegral_add_zsmul_eq (n : ℤ) 0 hint
  rw [h1eq, zero_add, hcell] at this
  refine ⟨w, hlip, hw0, hw1, ?_⟩
  rw [this, zsmul_eq_mul, hh]
  push_cast
  field_simp

#print axioms bolza_zigzag

/-- The direct method (Tonelli's existence theorem, in abstract form). Let `E` be a reflexive
real normed space: every element of the dual of its dual comes from a point of `E`. Let the
energy `J` be coercive (every set where the energy is at most `c` is bounded), convex, and
lower semicontinuous. Then `J` has a minimiser `u`, and `u` solves the Euler-Lagrange equation:
nudging `u` along any direction `v`, the energy `s ↦ J (u + s • v)` has slope 0 at `s = 0`
whenever that slope exists. -/
theorem direct_method_exists_minimiser
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (hrefl : Function.Surjective (NormedSpace.inclusionInDoubleDual ℝ E))
    (J : E → ℝ) (hcoer : ∀ c : ℝ, Bornology.IsBounded {w : E | J w ≤ c})
    (hconv : ConvexOn ℝ Set.univ J) (hlsc : LowerSemicontinuous J) :
    ∃ u : E, (∀ w : E, J u ≤ J w) ∧
      ∀ v : E, ∀ d : ℝ, HasDerivAt (fun s : ℝ => J (u + s • v)) d 0 → d = 0 := by
  obtain ⟨u, hu⟩ : ∃ u : E, ∀ w, J u ≤ J w := by
    let e := toWeakSpace ℝ E
    let J' : WeakSpace ℝ E → ℝ := fun x => J (e.symm x)
    have hpre : ∀ c, J' ⁻¹' Set.Iic c = e '' {w : E | J w ≤ c} := by
      intro c
      ext x
      constructor
      · intro hx
        exact ⟨e.symm x, hx, by simp⟩
      · rintro ⟨w, hw, rfl⟩
        simpa [J'] using hw
    have hclosed : ∀ c, IsClosed (e '' {w : E | J w ≤ c}) := by
      intro c
      have hS : IsClosed {w : E | J w ≤ c} := hlsc.isClosed_preimage c
      have hSc : Convex ℝ {w : E | J w ≤ c} := by
        have := hconv.convex_le c
        simpa using this
      have := hSc.toWeakSpace_closure ℝ
      rw [hS.closure_eq] at this
      rw [this]
      exact isClosed_closure
    have hlsc' : LowerSemicontinuous J' := by
      rw [lowerSemicontinuous_iff_isClosed_preimage]
      intro c
      rw [hpre c]
      exact hclosed c
    obtain ⟨R, hR⟩ := (hcoer (J 0)).subset_closedBall 0
    let g : WeakDual ℝ (StrongDual ℝ E) → WeakSpace ℝ E :=
      fun φ => e (Function.surjInv hrefl (WeakDual.toStrongDual φ))
    have hg : Continuous g := by
      refine WeakBilin.continuous_of_continuous_eval _ (fun f => ?_)
      have : (fun φ => (topDualPairing ℝ E).flip (g φ) f) = fun φ : WeakDual ℝ (StrongDual ℝ E) => φ f := by
        funext φ
        have h := Function.surjInv_eq hrefl (WeakDual.toStrongDual φ)
        have h2 := congrArg (fun ψ => ψ f) h
        exact h2
      rw [this]
      exact WeakBilin.eval_continuous _ f
    have hK : IsCompact (WeakDual.toStrongDual ⁻¹' Metric.closedBall (0 : StrongDual ℝ (StrongDual ℝ E)) R) :=
      WeakDual.isCompact_closedBall 0 R
    have hsub : e '' {w : E | J w ≤ J 0} ⊆ g '' (WeakDual.toStrongDual ⁻¹' Metric.closedBall 0 R) := by
      rintro _ ⟨w, hw, rfl⟩
      refine ⟨StrongDual.toWeakDual (NormedSpace.inclusionInDoubleDual ℝ E w), ?_, ?_⟩
      · have : ‖NormedSpace.inclusionInDoubleDual ℝ E w‖ ≤ R :=
          (NormedSpace.double_dual_bound ℝ E w).trans (by simpa using hR hw)
        show NormedSpace.inclusionInDoubleDual ℝ E w ∈ Metric.closedBall 0 R
        rw [Metric.mem_closedBall]
        exact (le_of_eq (dist_zero_right (NormedSpace.inclusionInDoubleDual ℝ E w))).trans this
      · have hinj : Function.Injective (NormedSpace.inclusionInDoubleDual ℝ E) :=
          (NormedSpace.inclusionInDoubleDualLi (E := E) ℝ).injective
        simp only [g]
        congr 1
        apply hinj
        exact Function.surjInv_eq hrefl _
    have hcpt : IsCompact (e '' {w : E | J w ≤ J 0}) :=
      (hK.image hg).of_isClosed_subset (hclosed _) hsub
    have h0 : e 0 ∈ e '' {w : E | J w ≤ J 0} :=
      Set.mem_image_of_mem e (by show J 0 ≤ J 0; exact le_rfl)
    obtain ⟨a, ha, hmin⟩ := LowerSemicontinuousOn.exists_isMinOn
      ⟨e 0, h0⟩ hcpt (hlsc'.lowerSemicontinuousOn _)
    refine ⟨e.symm a, fun w => ?_⟩
    by_cases hw : J w ≤ J 0
    · have := hmin (Set.mem_image_of_mem e (show w ∈ {w : E | J w ≤ J 0} from hw))
      change J (e.symm a) ≤ J (e.symm (e w)) at this
      rwa [LinearEquiv.symm_apply_apply] at this
    · have := hmin h0
      change J (e.symm a) ≤ J (e.symm (e 0)) at this
      rw [LinearEquiv.symm_apply_apply] at this
      linarith
  refine ⟨u, hu, fun v d hd => ?_⟩
  have hmin : IsLocalMin (fun s : ℝ => J (u + s • v)) 0 :=
    Filter.Eventually.of_forall (fun s => by simpa using hu (u + s • v))
  exact hmin.hasDerivAt_eq_zero hd

/-- The shear-thickening liquid in the slot, in scaled units. The profile
`u(x) = ¾[(½)^(4/3) − |x − ½|^(4/3)]` is continuously differentiable, is zero at both plates and
peaks at `¾ (½)^(4/3)` in the middle. Its energy `J(u) = ∫₀¹ (¼u'⁴ − u) dx` is
`−(9/28)(½)^(4/3)`. Every other continuously differentiable profile `w` with `w(0) = w(1) = 0`
has energy at least `J(u)`, and equal energy only if `w = u` on `[0, 1]`. And `u` is a weak
solution of the Euler-Lagrange equation `−(u'³)' = 1`: `∫₀¹ u'³ v' dx = ∫₀¹ v dx` for every such
test nudge `v`. -/
theorem power_law_slot_unique_minimiser (u : ℝ → ℝ)
    (hu : u = fun x => 3 / 4 * ((1 / 2 : ℝ) ^ (4 / 3 : ℝ) - |x - 1 / 2| ^ (4 / 3 : ℝ))) :
    ContDiff ℝ 1 u ∧ u 0 = 0 ∧ u 1 = 0 ∧ u (1 / 2) = 3 / 4 * (1 / 2 : ℝ) ^ (4 / 3 : ℝ) ∧
      (∫ x in (0 : ℝ)..1, (deriv u x) ^ 4 / 4 - u x) = -9 / 28 * (1 / 2 : ℝ) ^ (4 / 3 : ℝ) ∧
      (∀ w : ℝ → ℝ, ContDiff ℝ 1 w → w 0 = 0 → w 1 = 0 →
        (∫ x in (0 : ℝ)..1, (deriv u x) ^ 4 / 4 - u x)
          ≤ ∫ x in (0 : ℝ)..1, (deriv w x) ^ 4 / 4 - w x) ∧
      (∀ w : ℝ → ℝ, ContDiff ℝ 1 w → w 0 = 0 → w 1 = 0 →
        (∫ x in (0 : ℝ)..1, (deriv w x) ^ 4 / 4 - w x)
          = (∫ x in (0 : ℝ)..1, (deriv u x) ^ 4 / 4 - u x) →
        ∀ x ∈ Set.Icc (0 : ℝ) 1, w x = u x) ∧
      (∀ v : ℝ → ℝ, ContDiff ℝ 1 v → v 0 = 0 → v 1 = 0 →
        (∫ x in (0 : ℝ)..1, (deriv u x) ^ 3 * deriv v x) = ∫ x in (0 : ℝ)..1, v x) := by
  set D : ℝ → ℝ := fun x => -(|x - 1 / 2| ^ ((4 / 3 : ℝ) - 2) * (x - 1 / 2)) with hD
  have hderiv : ∀ x, HasDerivAt u (D x) x := by
    intro x
    have h1 := (hasDerivAt_abs_rpow (x - 1 / 2) (show (1 : ℝ) < 4 / 3 by norm_num)).comp x
      ((hasDerivAt_id x).sub_const (1 / 2))
    have h2 := (h1.const_sub ((1 / 2 : ℝ) ^ (4 / 3 : ℝ))).const_mul (3 / 4 : ℝ)
    rw [hu]
    refine h2.congr_deriv ?_
    simp only [hD]
    ring
  have hdu : deriv u = D := funext fun x => (hderiv x).deriv
  have hcont_u : ContDiff ℝ 1 u := by
    rw [hu]
    have : ContDiff ℝ 1 (fun x : ℝ => ‖x - 1 / 2‖ ^ (4 / 3 : ℝ)) :=
      (contDiff_id.sub contDiff_const).norm_rpow (by norm_num)
    simp only [Real.norm_eq_abs] at this
    exact contDiff_const.mul (contDiff_const.sub this)
  have hDcont : Continuous D := by rw [← hdu]; exact hcont_u.continuous_deriv le_rfl
  have hucont : Continuous u := hcont_u.continuous
  have hu0 : u 0 = 0 := by rw [hu]; norm_num
  have hu1 : u 1 = 0 := by rw [hu]; norm_num
  have hD3 : ∀ x, D x ^ 3 = 1 / 2 - x := by
    intro x
    by_cases ht : x - 1 / 2 = 0
    · simp only [D, ht]
      simp
      linarith
    · have hpos : 0 < |x - 1 / 2| := abs_pos.mpr ht
      have key : (|x - 1 / 2| ^ ((4 / 3 : ℝ) - 2)) ^ (3 : ℕ) = ((x - 1 / 2) ^ 2)⁻¹ := by
        rw [← Real.rpow_natCast, ← Real.rpow_mul hpos.le]
        rw [show ((4 / 3 : ℝ) - 2) * ((3 : ℕ) : ℝ) = -((2 : ℕ) : ℝ) by norm_num,
          Real.rpow_neg hpos.le, Real.rpow_natCast, sq_abs]
      simp only [D]
      rw [neg_pow, mul_pow, key]
      field_simp
      ring
  have hD4 : ∀ x, D x ^ 4 = |x - 1 / 2| ^ (4 / 3 : ℝ) := by
    intro x
    by_cases ht : x - 1 / 2 = 0
    · simp only [D, ht]
      simp
    · have hpos : 0 < |x - 1 / 2| := abs_pos.mpr ht
      have key : (|x - 1 / 2| ^ ((4 / 3 : ℝ) - 2)) ^ (4 : ℕ) * (x - 1 / 2) ^ 4
          = |x - 1 / 2| ^ (4 / 3 : ℝ) := by
        have h4 : (x - 1 / 2) ^ 4 = |x - 1 / 2| ^ (4 : ℕ) := by
          rw [pow_abs, abs_of_nonneg (by positivity)]
        rw [← Real.rpow_natCast (|x - 1 / 2| ^ ((4 / 3 : ℝ) - 2)) 4, ← Real.rpow_mul hpos.le,
          h4, ← Real.rpow_natCast (|x - 1 / 2|) 4, ← Real.rpow_add hpos]
        norm_num
      simp only [D]
      rw [neg_pow, mul_pow, key]
      norm_num
  have hEL : ∀ v : ℝ → ℝ, ContDiff ℝ 1 v → v 0 = 0 → v 1 = 0 →
      (∫ x in (0 : ℝ)..1, (deriv u x) ^ 3 * deriv v x) = ∫ x in (0 : ℝ)..1, v x := by
    intro v hv hv0 hv1
    have hvd : ∀ x, HasDerivAt v (deriv v x) x := fun x =>
      ((hv.differentiable one_ne_zero) x).hasDerivAt
    have hvc : Continuous (deriv v) := hv.continuous_deriv le_rfl
    have hcongr : (fun x => (deriv u x) ^ 3 * deriv v x) = fun x => (1 / 2 - x) * deriv v x := by
      funext x; rw [hdu, hD3]
    rw [hcongr]
    have hibp := intervalIntegral.integral_mul_deriv_eq_deriv_mul (a := 0) (b := 1)
      (u := fun x => 1 / 2 - x) (u' := fun _ => -1) (v := v) (v' := deriv v)
      (fun x _ => by simpa using (hasDerivAt_id x).const_sub (1 / 2 : ℝ)) (fun x _ => hvd x)
      intervalIntegrable_const (hvc.intervalIntegrable 0 1)
    rw [hibp, hv0, hv1]
    simp
  have hΦ : ∀ a b : ℝ, a ^ 4 / 4 - b ^ 4 / 4 - b ^ 3 * (a - b)
      = (a - b) ^ 2 * ((a + b) ^ 2 + 2 * b ^ 2) / 4 := by intro a b; ring
  have hΦnn : ∀ a b : ℝ, 0 ≤ a ^ 4 / 4 - b ^ 4 / 4 - b ^ 3 * (a - b) := by
    intro a b; rw [hΦ]; positivity
  have hgap : ∀ w : ℝ → ℝ, ContDiff ℝ 1 w → w 0 = 0 → w 1 = 0 →
      (∫ x in (0 : ℝ)..1, (deriv w x) ^ 4 / 4 - w x) - (∫ x in (0 : ℝ)..1, (deriv u x) ^ 4 / 4 - u x)
        = ∫ x in (0 : ℝ)..1,
            ((deriv w x) ^ 4 / 4 - (D x) ^ 4 / 4 - (D x) ^ 3 * (deriv w x - D x)) := by
    intro w hw hw0 hw1
    have hwc : Continuous (deriv w) := hw.continuous_deriv le_rfl
    have hwcont : Continuous w := hw.continuous
    have hv : ContDiff ℝ 1 (fun x => w x - u x) := hw.sub hcont_u
    have hEL' := hEL (fun x => w x - u x) hv (by simp [hw0, hu0]) (by simp [hw1, hu1])
    have hdv : deriv (fun x => w x - u x) = fun x => deriv w x - D x := by
      funext x
      exact ((((hw.differentiable one_ne_zero) x).hasDerivAt).sub (hderiv x)).deriv
    rw [hdv, hdu] at hEL'
    rw [hdu]
    have hB : (∫ x in (0 : ℝ)..1, ((D x) ^ 3 * (deriv w x - D x) - (w x - u x))) = 0 := by
      rw [intervalIntegral.integral_sub (by apply Continuous.intervalIntegrable; fun_prop)
        (by apply Continuous.intervalIntegrable; fun_prop), hEL', sub_self]
    have hsplit : (∫ x in (0 : ℝ)..1,
        ((deriv w x) ^ 4 / 4 - (D x) ^ 4 / 4 - (D x) ^ 3 * (deriv w x - D x)))
        = (∫ x in (0 : ℝ)..1, (((deriv w x) ^ 4 / 4 - w x) - ((D x) ^ 4 / 4 - u x)))
          - ∫ x in (0 : ℝ)..1, ((D x) ^ 3 * (deriv w x - D x) - (w x - u x)) := by
      rw [← intervalIntegral.integral_sub (by apply Continuous.intervalIntegrable; fun_prop)
        (by apply Continuous.intervalIntegrable; fun_prop)]
      congr 1
      funext x
      ring
    rw [hsplit, hB, sub_zero]
    exact (intervalIntegral.integral_sub
      (by apply Continuous.intervalIntegrable; fun_prop)
      (by apply Continuous.intervalIntegrable; fun_prop)).symm
  have hval : (∫ x in (0 : ℝ)..1, (deriv u x) ^ 4 / 4 - u x)
      = -9 / 28 * (1 / 2 : ℝ) ^ (4 / 3 : ℝ) := by
    have hAc : Continuous (fun x : ℝ => |x| ^ (4 / 3 : ℝ)) :=
      continuous_abs.rpow_const (fun _ => Or.inr (by norm_num))
    have hpt : (fun x => (deriv u x) ^ 4 / 4 - u x)
        = fun x => |x - 1 / 2| ^ (4 / 3 : ℝ) - 3 / 4 * (1 / 2 : ℝ) ^ (4 / 3 : ℝ) := by
      funext x
      rw [hdu, hD4, hu]
      ring
    have hA2 : IntervalIntegrable (fun x : ℝ => |x - 1 / 2| ^ (4 / 3 : ℝ)) MeasureTheory.volume 0 1 :=
      (hAc.comp (continuous_id.sub continuous_const)).intervalIntegrable _ _
    rw [hpt, intervalIntegral.integral_sub hA2 intervalIntegrable_const,
      intervalIntegral.integral_const]
    have hA : (∫ x in (0 : ℝ)..1, |x - 1 / 2| ^ (4 / 3 : ℝ))
        = 3 / 7 * (1 / 2 : ℝ) ^ (4 / 3 : ℝ) := by
      rw [intervalIntegral.integral_comp_sub_right (fun x => |x| ^ (4 / 3 : ℝ))]
      rw [← intervalIntegral.integral_add_adjacent_intervals (b := 0)
        (hAc.intervalIntegrable _ _) (hAc.intervalIntegrable _ _)]
      have hneg := intervalIntegral.integral_comp_neg (a := 0) (b := 1 / 2)
        (fun x : ℝ => |x| ^ (4 / 3 : ℝ))
      simp only [abs_neg, neg_zero] at hneg
      have hpos : (∫ x in (0 : ℝ)..1 / 2, |x| ^ (4 / 3 : ℝ))
          = ∫ x in (0 : ℝ)..1 / 2, x ^ (4 / 3 : ℝ) := by
        apply intervalIntegral.integral_congr
        intro x hx
        rw [Set.uIcc_of_le (by norm_num)] at hx
        simp only [abs_of_nonneg hx.1]
      rw [integral_rpow (Or.inl (by norm_num))] at hpos
      rw [Real.rpow_add_one (by norm_num), Real.zero_rpow (by norm_num)] at hpos
      norm_num at hneg hpos ⊢
      rw [← hneg, hpos]
      ring
    rw [hA]
    norm_num
    ring
  refine ⟨hcont_u, hu0, hu1, ?_, hval, ?_, ?_, hEL⟩
  · rw [hu]; norm_num
  · intro w hw hw0 hw1
    have := hgap w hw hw0 hw1
    have hnn : 0 ≤ ∫ x in (0 : ℝ)..1,
        ((deriv w x) ^ 4 / 4 - (D x) ^ 4 / 4 - (D x) ^ 3 * (deriv w x - D x)) :=
      intervalIntegral.integral_nonneg (by norm_num) (fun x _ => hΦnn _ _)
    linarith
  · intro w hw hw0 hw1 heq x hx
    have hwc : Continuous (deriv w) := hw.continuous_deriv le_rfl
    have hgap0 := hgap w hw hw0 hw1
    rw [heq, sub_self] at hgap0
    have hzero : ∀ y ∈ Set.Icc (0 : ℝ) 1, deriv w y = D y := by
      intro y hy
      by_contra hne
      have hposy : 0 < deriv w y ^ 4 / 4 - D y ^ 4 / 4 - D y ^ 3 * (deriv w y - D y) := by
        rw [hΦ]
        have h1 : 0 < (deriv w y - D y) ^ 2 := by
          have : deriv w y - D y ≠ 0 := sub_ne_zero.mpr hne
          positivity
        have h2 : 0 < (deriv w y + D y) ^ 2 + 2 * D y ^ 2 := by
          by_contra h2
          push Not at h2
          have hb : D y = 0 := by nlinarith [sq_nonneg (deriv w y + D y), sq_nonneg (D y)]
          have ha : deriv w y = 0 := by
            rw [hb] at h2; nlinarith [sq_nonneg (deriv w y)]
          exact hne (by rw [ha, hb])
        positivity
      have := intervalIntegral.integral_pos (by norm_num : (0 : ℝ) < 1)
        (f := fun x => (deriv w x) ^ 4 / 4 - (D x) ^ 4 / 4 - (D x) ^ 3 * (deriv w x - D x))
        (by apply Continuous.continuousOn; fun_prop) (fun x _ => hΦnn _ _) ⟨y, hy, hposy⟩
      linarith
    have hftc := intervalIntegral.integral_eq_sub_of_hasDerivAt (a := 0) (b := x)
      (f := fun y => w y - u y) (f' := fun y => deriv w y - D y)
      (fun y _ => (((hw.differentiable one_ne_zero) y).hasDerivAt).sub (hderiv y))
      ((hwc.sub hDcont).intervalIntegrable 0 x)
    have hint0 : (∫ y in (0 : ℝ)..x, (deriv w y - D y)) = 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => (0 : ℝ)) ?_]
      · simp
      · intro y hy
        rw [Set.uIcc_of_le hx.1] at hy
        simp [hzero y ⟨hy.1, hy.2.trans hx.2⟩]
    rw [hint0] at hftc
    simp only [hw0, hu0, sub_zero] at hftc
    linarith

/-- Bolza's energy `B(w) = ∫₀¹ [(w'² − 1)² + w²] dx` has no minimiser. For every number of teeth
`n ≥ 1` there is a zigzag profile with slopes ±1, zero at both ends, whose energy is exactly
`1/(12n²)`, so the energy can be pushed as close to 0 as you like. But no Lipschitz profile with
`w(0) = w(1) = 0` has energy 0. -/
theorem bolza_energy_has_no_minimiser :
    (∀ n : ℕ, 0 < n → ∃ w : ℝ → ℝ, LipschitzWith 1 w ∧ w 0 = 0 ∧ w 1 = 0 ∧
      (∫ x in (0 : ℝ)..1, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2) = 1 / (12 * (n : ℝ) ^ 2)) ∧
    (∀ w : ℝ → ℝ, (∃ K, LipschitzWith K w) → w 0 = 0 → w 1 = 0 →
      0 < ∫ x in (0 : ℝ)..1, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2) := by
  refine ⟨bolza_zigzag, ?_⟩
  rintro w ⟨K, hK⟩ hw0 hw1
  have hint := bolza_intervalIntegrable hK 0 1
  have hc := hK.continuous
  by_cases hex : ∃ x0 ∈ Set.Icc (0 : ℝ) 1, w x0 ≠ 0
  · obtain ⟨x0, hx0, hne⟩ := hex
    have hpos : 0 < ∫ x in (0 : ℝ)..1, w x ^ 2 :=
      intervalIntegral.integral_pos (by norm_num) (hc.pow 2).continuousOn
        (fun x _ => sq_nonneg _)
        ⟨x0, hx0, lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hne))⟩
    have hle : (∫ x in (0 : ℝ)..1, w x ^ 2)
        ≤ ∫ x in (0 : ℝ)..1, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2 :=
      intervalIntegral.integral_mono_on (by norm_num) ((hc.pow 2).intervalIntegrable 0 1) hint
        (fun x _ => by nlinarith [sq_nonneg ((deriv w x) ^ 2 - 1)])
    linarith
  · push Not at hex
    have h1 : (∫ x in (0 : ℝ)..1, ((deriv w x) ^ 2 - 1) ^ 2 + w x ^ 2)
        = ∫ x in (0 : ℝ)..1, (1 : ℝ) := by
      apply intervalIntegral.integral_congr_Ioo_of_le (by norm_num)
      intro x hx
      have heq : w =ᶠ[nhds x] fun _ => (0 : ℝ) := by
        filter_upwards [Ioo_mem_nhds hx.1 hx.2] with y hy
        exact hex y ⟨hy.1.le, hy.2.le⟩
      simp only [heq.deriv_eq, deriv_const, hex x ⟨hx.1.le, hx.2.le⟩]
      norm_num
    rw [h1]
    simp

-- The speed scale (F d⁴ / m)^(1/3) with F = 1600 Pa/m, d = 0.05 m, m = 0.01 Pa s³: F d⁴ / m = 1.
example : (1600 : ℚ) * (1 / 20) ^ 4 / (1 / 100) = 1 := by norm_num

-- Coercivity: t⁴/4 − t is never below −3/4, the energy's floor.
example (t : ℝ) : -3 / 4 ≤ t ^ 4 / 4 - t := by
  nlinarith [sq_nonneg (t - 1), sq_nonneg (t + 1), mul_nonneg (sq_nonneg (t - 1)) (sq_nonneg (t + 1))]

-- Bolza's integrand (ξ² − 1)² is not convex: it is 1 at slope 0 but 0 at slopes +1 and −1.
example : ((0 : ℤ) ^ 2 - 1) ^ 2 = 1 ∧ ((1 : ℤ) ^ 2 - 1) ^ 2 = 0 ∧ ((-1 : ℤ) ^ 2 - 1) ^ 2 = 0 := by
  decide

-- Zigzag with n teeth: 2n half-teeth of width 1/(2n), each adding (1/(2n))³/3, total 1/(12n²),
-- for n = 1, 10, 100.
example : (2 * 1 : ℚ) * (1 / (2 * 1)) ^ 3 / 3 = 1 / 12 ∧
    (2 * 10 : ℚ) * (1 / (2 * 10)) ^ 3 / 3 = 1 / 1200 ∧
    (2 * 100 : ℚ) * (1 / (2 * 100)) ^ 3 / 3 = 1 / 120000 := by norm_num

-- The p = 1 ramps of width e have energy 1 + e/3: 31/30, 301/300, 3001/3000 at e = 1/10, 1/100, 1/1000.
example : (1 : ℚ) + (1 / 10) / 3 = 31 / 30 ∧ (1 : ℚ) + (1 / 100) / 3 = 301 / 300 ∧
    (1 : ℚ) + (1 / 1000) / 3 = 3001 / 3000 := by norm_num

#print axioms direct_method_exists_minimiser
#print axioms power_law_slot_unique_minimiser
#print axioms bolza_energy_has_no_minimiser
