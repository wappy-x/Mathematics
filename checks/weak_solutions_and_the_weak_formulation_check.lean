-- Weak solutions: a twice-differentiable shape solves the weak form of the sheet equation exactly when it solves the equation point by point, the creased tent solves the weak form with the rods' line load, and a Burgers jump from 1 to 0 solves its weak form exactly at the Rankine-Hugoniot speed one half.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.Analysis.Calculus.LineDeriv.IntegrationByParts
import Mathlib.MeasureTheory.Integral.DivergenceTheorem

open MeasureTheory Set Laplacian
open scoped Gradient ContDiff RealInnerProductSpace

theorem wsw_integrable_mul {d : ℕ} {Ω : Set (EuclideanSpace ℝ (Fin d))} (hΩ : IsOpen Ω)
    {φ ψ : EuclideanSpace ℝ (Fin d) → ℝ} (hφ : ContinuousOn φ Ω) (hψ : Continuous ψ)
    (hψs : HasCompactSupport ψ) (hψΩ : tsupport ψ ⊆ Ω) :
    Integrable (fun x => φ x * ψ x) := by
  have hc : Continuous (fun x => φ x * ψ x) :=
    (hφ.mul hψ.continuousOn).continuous_of_tsupport_subset hΩ
      ((tsupport_mul_subset_right).trans hψΩ)
  exact hc.integrable_of_hasCompactSupport (hψs.mul_left (f := φ))

#print axioms wsw_integrable_mul

theorem wsw_partial_test2 {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {v : E → ℝ} (hv : ContDiff ℝ ∞ v)
    (hvs : HasCompactSupport v) (e : E) :
    Continuous (fun x => fderiv ℝ v x e) ∧ HasCompactSupport (fun x => fderiv ℝ v x e) ∧
      tsupport (fun x => fderiv ℝ v x e) ⊆ tsupport v := by
  have h1 : (fun x => fderiv ℝ v x e) = (fun L : E →L[ℝ] ℝ => L e) ∘ fderiv ℝ v := rfl
  refine ⟨(hv.continuous_fderiv (by simp)).clm_apply continuous_const, ?_, ?_⟩
  · rw [h1]; exact (hvs.fderiv (𝕜 := ℝ)).comp_left (by simp)
  · rw [h1]; exact (tsupport_comp_subset (by simp) _).trans (tsupport_fderiv_subset ℝ)

#print axioms wsw_partial_test2

theorem wsw_second_partial {d : ℕ} {u : EuclideanSpace ℝ (Fin d) → ℝ} {x : EuclideanSpace ℝ (Fin d)}
    (h : DifferentiableAt ℝ (fderiv ℝ u) x) (e : EuclideanSpace ℝ (Fin d)) :
    fderiv ℝ (fun y => fderiv ℝ u y e) x e = iteratedFDeriv ℝ 2 u x ![e, e] := by
  rw [iteratedFDeriv_two_apply, fderiv_clm_apply h (differentiableAt_const e)]
  simp

#print axioms wsw_second_partial

theorem wsw_ibp_identity {d : ℕ} {Ω : Set (EuclideanSpace ℝ (Fin d))}
    (hΩ : IsOpen Ω) (T : ℝ) {u : EuclideanSpace ℝ (Fin d) → ℝ}
    (hu : ContDiffOn ℝ 2 u Ω) {v : EuclideanSpace ℝ (Fin d) → ℝ} (hv : ContDiff ℝ ∞ v)
    (hvs : HasCompactSupport v) (hvΩ : tsupport v ⊆ Ω) :
    ∫ x, T * ⟪∇ u x, ∇ v x⟫ = ∫ x, (-T * Δ u x) * v x := by
  set b := stdOrthonormalBasis ℝ (EuclideanSpace ℝ (Fin d)) with hb
  have hdu : ∀ x ∈ Ω, DifferentiableAt ℝ (fderiv ℝ u) x := fun x hx =>
    ((hu.fderiv_of_isOpen hΩ (m := 1) (by norm_num)).differentiableOn (by norm_num)).differentiableAt
      (hΩ.mem_nhds hx)
  have hcu : ∀ e, ContinuousOn (fun x => fderiv ℝ u x e) Ω := fun e =>
    (hu.continuousOn_fderiv_of_isOpen hΩ (by norm_num)).clm_apply continuousOn_const
  have hci : ∀ e, ContinuousOn (fun x => iteratedFDeriv ℝ 2 u x ![e, e]) Ω := by
    intro e
    have : ContinuousOn (iteratedFDeriv ℝ 2 u) Ω :=
      (hu.continuousOn_iteratedFDerivWithin (m := 2) le_rfl hΩ.uniqueDiffOn).congr
        (iteratedFDerivWithin_of_isOpen 2 hΩ).symm
    exact (continuous_eval_const _).comp_continuousOn this
  have hv0 : ∀ x, x ∉ Ω → v x = 0 := fun x hx =>
    image_eq_zero_of_notMem_tsupport (fun h => hx (hvΩ h))
  have hgrad : ∀ x, ⟪∇ u x, ∇ v x⟫ = ∑ i, fderiv ℝ u x (b i) * fderiv ℝ v x (b i) := by
    intro x
    rw [← b.sum_inner_mul_inner]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [real_inner_comm (∇ v x) (b i), gradient, gradient, InnerProductSpace.toDual_symm_apply,
      InnerProductSpace.toDual_symm_apply]
  have hint1 : ∀ i, Integrable (fun x => fderiv ℝ u x (b i) * fderiv ℝ v x (b i)) := by
    intro i
    obtain ⟨h1, h2, h3⟩ := wsw_partial_test2 hv hvs (b i)
    exact wsw_integrable_mul hΩ (hcu _) h1 h2 (h3.trans hvΩ)
  have hint2 : ∀ i, Integrable (fun x => iteratedFDeriv ℝ 2 u x ![b i, b i] * v x) := fun i =>
    wsw_integrable_mul hΩ (hci _) hv.continuous hvs hvΩ
  have hibp : ∀ i, ∫ x, fderiv ℝ u x (b i) * fderiv ℝ v x (b i) =
      - ∫ x, iteratedFDeriv ℝ 2 u x ![b i, b i] * v x := by
    intro i
    have hpt : ∀ x, fderiv ℝ (fun y => fderiv ℝ u y (b i)) x (b i) * v x =
        iteratedFDeriv ℝ 2 u x ![b i, b i] * v x := by
      intro x
      by_cases hx : x ∈ Ω
      · rw [wsw_second_partial (hdu x hx)]
      · simp [hv0 x hx]
    simp_rw [← hpt]
    apply integral_mul_fderiv_eq_neg_fderiv_mul_of_integrable
    · simp_rw [hpt]; exact hint2 i
    · exact hint1 i
    · exact wsw_integrable_mul hΩ (hcu _) hv.continuous hvs hvΩ
    · intro x hx
      exact (hdu x (hvΩ hx)).clm_apply (differentiableAt_const _)
    · intro x _
      exact hv.differentiable (by simp) x
  have hlap : ∀ x, Δ u x = ∑ i, iteratedFDeriv ℝ 2 u x ![b i, b i] := fun x =>
    congrFun (InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis u b) x
  simp_rw [hgrad, hlap]
  have hL : ∫ x, T * ∑ i, fderiv ℝ u x (b i) * fderiv ℝ v x (b i) =
      ∑ i, T * (-∫ x, iteratedFDeriv ℝ 2 u x ![b i, b i] * v x) := by
    simp_rw [Finset.mul_sum]
    rw [integral_finsetSum _ (fun i _ => (hint1 i).const_mul T)]
    simp_rw [integral_const_mul, hibp]
  have hpt : ∀ x, -T * (∑ i, iteratedFDeriv ℝ 2 u x ![b i, b i]) * v x =
      ∑ i, -T * (iteratedFDeriv ℝ 2 u x ![b i, b i] * v x) := by
    intro x; rw [mul_assoc, Finset.sum_mul, Finset.mul_sum]
  have hR : ∫ x, -T * (∑ i, iteratedFDeriv ℝ 2 u x ![b i, b i]) * v x =
      ∑ i, -T * ∫ x, iteratedFDeriv ℝ 2 u x ![b i, b i] * v x := by
    simp_rw [hpt]
    rw [integral_finsetSum _ (fun i _ => (hint2 i).const_mul _)]
    simp_rw [integral_const_mul]
  rw [hL, hR]
  exact Finset.sum_congr rfl fun i _ => by ring

#print axioms wsw_ibp_identity

theorem wsw_slice_fst {v : ℝ × ℝ → ℝ} (hv : Differentiable ℝ v) (x y : ℝ) :
    deriv (fun x => v (x, y)) x = fderiv ℝ v (x, y) (1, 0) :=
  ((hv (x, y)).hasFDerivAt.comp_hasDerivAt x
    ((hasDerivAt_id x).prodMk (hasDerivAt_const x y))).deriv

#print axioms wsw_slice_fst

theorem wsw_slice_snd {v : ℝ × ℝ → ℝ} (hv : Differentiable ℝ v) (x y : ℝ) :
    deriv (fun y => v (x, y)) y = fderiv ℝ v (x, y) (0, 1) :=
  ((hv (x, y)).hasFDerivAt.comp_hasDerivAt y
    ((hasDerivAt_const y x).prodMk (hasDerivAt_id y))).deriv

#print axioms wsw_slice_snd

theorem wsw_tent_deriv_bound (z₀ R : ℝ) (hR : 0 < R) (c x : ℝ) :
    |deriv (fun x => z₀ * (1 - max |x| c / R)) x| ≤ |z₀| / R := by
  have hK : 0 ≤ |z₀| / R := by positivity
  have hL : LipschitzWith ⟨|z₀| / R, hK⟩ (fun x => z₀ * (1 - max |x| c / R)) := by
    refine LipschitzWith.of_dist_le_mul fun a b => ?_
    simp only [Real.dist_eq]
    calc |z₀ * (1 - max |a| c / R) - z₀ * (1 - max |b| c / R)|
        = |z₀| / R * |max |a| c - max |b| c| := by
          rw [show z₀ * (1 - max |a| c / R) - z₀ * (1 - max |b| c / R)
              = z₀ / R * (max |b| c - max |a| c) by field_simp; ring,
            abs_mul, abs_div, abs_of_pos hR, abs_sub_comm (max |b| c)]
      _ ≤ |z₀| / R * |a - b| :=
          mul_le_mul_of_nonneg_left ((abs_max_sub_max_le_abs _ _ _).trans
            (abs_abs_sub_abs_le_abs_sub _ _)) hK
  have := norm_deriv_le_of_lipschitz (x₀ := x) hL
  rw [Real.norm_eq_abs] at this
  exact this

#print axioms wsw_tent_deriv_bound

theorem wsw_tent_1d (T z₀ R : ℝ) (hR : 0 < R) (c : ℝ) (hc0 : 0 ≤ c) (hcR : c < R)
    (ψ : ℝ → ℝ) (hψ : ContDiff ℝ 1 ψ) (hψR : ψ R = 0) (hψmR : ψ (-R) = 0) :
    ∫ x in Ioo (-R) R, T * (deriv (fun x => z₀ * (1 - max |x| c / R)) x * deriv ψ x) =
      T * z₀ / R * (ψ c + ψ (-c)) := by
  have hψc : Continuous ψ := hψ.continuous
  have hψd : ∀ x, HasDerivAt ψ (deriv ψ x) x := fun x =>
    (hψ.differentiable one_ne_zero x).hasDerivAt
  rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le (by linarith)]
  set K := T * z₀ / R with hKdef
  set Hf : ℝ → ℝ := fun x => -K * (ψ (max x c) - ψ (min x (-c))) with hHf
  have hHc : ContinuousOn Hf (Icc (-R) R) := by
    apply Continuous.continuousOn
    simp only [Hf]
    fun_prop
  have hint : IntervalIntegrable
      (fun x => T * (deriv (fun x => z₀ * (1 - max |x| c / R)) x * deriv ψ x)) volume (-R) R := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le (by linarith)]
    have h1 : IntegrableOn (deriv ψ) (Ioc (-R) R) :=
      (hψ.continuous_deriv le_rfl).integrableOn_Ioc
    have h2 := h1.bdd_mul (f := deriv (fun x => z₀ * (1 - max |x| c / R)))
      (measurable_deriv _).aestronglyMeasurable
      (Filter.Eventually.of_forall fun x => by
        rw [Real.norm_eq_abs]; exact wsw_tent_deriv_bound z₀ R hR c x)
    exact h2.const_mul T
  rw [integral_eq_of_hasDerivAt_off_countable_of_le Hf _ (by linarith)
    (s := {c, -c}) ((Set.countable_singleton _).insert _) hHc ?_ hint]
  · have e1 : max R c = R := max_eq_left hcR.le
    have e2 : min R (-c) = -c := min_eq_right (by linarith)
    have e3 : max (-R) c = c := max_eq_right (by linarith)
    have e4 : min (-R) (-c) = -R := min_eq_left (by linarith)
    simp only [Hf, e1, e2, e3, e4, hψR, hψmR]
    ring
  · intro x hx
    simp only [Set.mem_sdiff, Set.mem_insert_iff, Set.mem_singleton_iff, not_or, Set.mem_Ioo] at hx
    obtain ⟨⟨hx1, hx2⟩, hxc, hxmc⟩ := hx
    rcases lt_or_gt_of_ne hxc with hlt | hgt
    · rcases lt_or_gt_of_ne hxmc with hlt' | hgt'
      · -- x < -c
        have hev : ∀ᶠ y in nhds x, y < -c := Iio_mem_nhds hlt'
        have hφ : HasDerivAt (fun x => z₀ * (1 - max |x| c / R)) (z₀ / R) x := by
          have h0 : HasDerivAt (fun y : ℝ => z₀ * (1 + y / R)) (z₀ / R) x := by
            have := (((hasDerivAt_id x).div_const R).const_add 1).const_mul z₀
            exact this.congr_deriv (by ring)
          refine h0.congr_of_eventuallyEq ?_
          filter_upwards [hev] with y hy
          have hy0 : y < 0 := by linarith
          rw [abs_of_neg hy0, max_eq_left (by linarith)]
          ring
        have hH : HasDerivAt Hf (K * deriv ψ x) x := by
          have h0 : HasDerivAt (fun y => -K * (ψ c - ψ y)) (K * deriv ψ x) x := by
            have := ((hψd x).const_sub (ψ c)).const_mul (-K)
            convert this using 1; ring
          refine h0.congr_of_eventuallyEq ?_
          filter_upwards [hev] with y hy
          simp only [Hf]
          rw [max_eq_right (by linarith), min_eq_left hy.le]
        rw [hφ.deriv]
        convert hH using 1
        rw [hKdef]; ring
      · -- -c < x < c
        have hev : ∀ᶠ y in nhds x, -c < y ∧ y < c :=
          Filter.Eventually.and (Ioi_mem_nhds hgt') (Iio_mem_nhds hlt)
        have hφ : HasDerivAt (fun x => z₀ * (1 - max |x| c / R)) 0 x := by
          refine (hasDerivAt_const x (z₀ * (1 - c / R))).congr_of_eventuallyEq ?_
          filter_upwards [hev] with y hy
          rw [max_eq_right (abs_le.mpr ⟨hy.1.le, hy.2.le⟩)]
        have hH : HasDerivAt Hf 0 x := by
          refine (hasDerivAt_const x (-K * (ψ c - ψ (-c)))).congr_of_eventuallyEq ?_
          filter_upwards [hev] with y hy
          simp only [Hf]
          rw [max_eq_right hy.2.le, min_eq_right hy.1.le]
        rw [hφ.deriv]
        convert hH using 1
        ring
    · -- c < x
      have hev : ∀ᶠ y in nhds x, c < y := Ioi_mem_nhds hgt
      have hφ : HasDerivAt (fun x => z₀ * (1 - max |x| c / R)) (-(z₀ / R)) x := by
        have h0 : HasDerivAt (fun y : ℝ => z₀ * (1 - y / R)) (-(z₀ / R)) x := by
          have := (((hasDerivAt_id x).div_const R).const_sub 1).const_mul z₀
          exact this.congr_deriv (by ring)
        refine h0.congr_of_eventuallyEq ?_
        filter_upwards [hev] with y hy
        have hy0 : 0 < y := by linarith
        rw [abs_of_pos hy0, max_eq_left hy.le]
      have hH : HasDerivAt Hf (-K * deriv ψ x) x := by
        have h0 : HasDerivAt (fun y => -K * (ψ y - ψ (-c))) (-K * deriv ψ x) x :=
          ((hψd x).sub_const (ψ (-c))).const_mul (-K)
        refine h0.congr_of_eventuallyEq ?_
        filter_upwards [hev] with y hy
        simp only [Hf]
        rw [max_eq_left hy.le, min_eq_right (by linarith)]
      rw [hφ.deriv]
      convert hH using 1
      rw [hKdef]; ring

#print axioms wsw_tent_1d

theorem wsw_tent_int (T R C : ℝ) (a w : ℝ × ℝ → ℝ) (ha : Measurable a) (hab : ∀ q, |a q| ≤ C)
    (hw : Continuous w) (hws : HasCompactSupport w) :
    IntegrableOn (fun q : ℝ × ℝ => T * (a q * w q))
      (Ioo (-R) R ×ˢ Ioo (-R) R) (volume.prod volume) := by
  have h1 : IntegrableOn w (Ioo (-R) R ×ˢ Ioo (-R) R) (volume.prod volume) :=
    (hw.integrable_of_hasCompactSupport hws).integrableOn
  have h2 := h1.bdd_mul (f := a) ha.aestronglyMeasurable
    (Filter.Eventually.of_forall fun q => by rw [Real.norm_eq_abs]; exact hab q)
  exact h2.const_mul T

#print axioms wsw_tent_int

theorem wsw_burgers_residual (s : ℝ) (v : ℝ × ℝ → ℝ) (hv : ContDiff ℝ ∞ v)
    (hvs : HasCompactSupport v) :
    ∫ p : ℝ × ℝ, ((if p.1 < s * p.2 then (1 : ℝ) else 0) * deriv (fun t => v (p.1, t)) p.2 +
        1 / 2 * (if p.1 < s * p.2 then (1 : ℝ) else 0) ^ 2 * deriv (fun x => v (x, p.2)) p.1) =
      (1 / 2 - s) * ∫ t, v (s * t, t) := by
  have hd : Differentiable ℝ v := hv.differentiable (by simp)
  set A : ℝ × ℝ → ℝ := fun p => fderiv ℝ v p (0, 1) with hA
  set B : ℝ × ℝ → ℝ := fun p => fderiv ℝ v p (1, 0) with hB
  obtain ⟨hAc, hAs, -⟩ := wsw_partial_test2 hv hvs ((0, 1) : ℝ × ℝ)
  obtain ⟨hBc, hBs, -⟩ := wsw_partial_test2 hv hvs ((1, 0) : ℝ × ℝ)
  set H : ℝ × ℝ → ℝ := fun p => A p + 1 / 2 * B p with hH
  have hHc : Continuous H := hAc.add (continuous_const.mul hBc)
  have hHs : HasCompactSupport H := hAs.add (hBs.mul_left (f := fun _ => (1 / 2 : ℝ)))
  set S : Set (ℝ × ℝ) := {p | p.1 < s * p.2} with hSdef
  have hS : MeasurableSet S := measurableSet_lt measurable_fst (measurable_snd.const_mul s)
  have h1 : ∀ p : ℝ × ℝ, ((if p.1 < s * p.2 then (1 : ℝ) else 0) * deriv (fun t => v (p.1, t)) p.2 +
        1 / 2 * (if p.1 < s * p.2 then (1 : ℝ) else 0) ^ 2 * deriv (fun x => v (x, p.2)) p.1) =
        S.indicator H p := by
    intro p
    rw [wsw_slice_fst hd, wsw_slice_snd hd]
    by_cases hp : p.1 < s * p.2
    · rw [Set.indicator_of_mem (show p ∈ S from hp)]
      simp [hp, H, A, B]
    · rw [Set.indicator_of_notMem (show p ∉ S from hp)]
      simp [hp]
  simp_rw [h1]
  let Φ : ℝ × ℝ ≃ₜ ℝ × ℝ :=
    { toFun := fun q => (q.1 + s * q.2, q.2)
      invFun := fun p => (p.1 - s * p.2, p.2)
      left_inv := fun q => by simp
      right_inv := fun p => by simp
      continuous_toFun := by fun_prop
      continuous_invFun := by fun_prop }
  set S0 : Set (ℝ × ℝ) := {q | q.1 < 0} with hS0def
  have hS0 : MeasurableSet S0 := measurableSet_lt measurable_fst measurable_const
  have hF : Integrable (S.indicator H) (volume.prod volume) :=
    (hHc.integrable_of_hasCompactSupport hHs).indicator hS
  have hG : Integrable (S0.indicator (H ∘ Φ)) (volume.prod volume) :=
    ((hHc.comp Φ.continuous).integrable_of_hasCompactSupport (hHs.comp_homeomorph Φ)).indicator hS0
  have hshear : ∫ p, S.indicator H p = ∫ q, S0.indicator (H ∘ Φ) q := by
    rw [Measure.volume_eq_prod, integral_prod_symm _ hF, integral_prod_symm _ hG]
    congr 1; ext t
    rw [← integral_add_right_eq_self _ (s * t)]
    congr 1; ext y
    by_cases hy : y < 0
    · have h2 : (y + s * t, t) ∈ S := by simp [S]; linarith
      rw [Set.indicator_of_mem h2, Set.indicator_of_mem (show (y, t) ∈ S0 from hy)]
      rfl
    · have h2 : (y + s * t, t) ∉ S := by simp [S]; linarith
      rw [Set.indicator_of_notMem h2, Set.indicator_of_notMem (show (y, t) ∉ S0 from hy)]
  obtain ⟨hKc, hKs, -⟩ := wsw_partial_test2 hv hvs ((s, 1) : ℝ × ℝ)
  set Wt : ℝ × ℝ → ℝ := fun q => fderiv ℝ v (Φ q) (s, 1) with hWtdef
  set Wy : ℝ × ℝ → ℝ := fun q => B (Φ q) with hWydef
  have hWt : Integrable (S0.indicator Wt) (volume.prod volume) :=
    ((hKc.comp Φ.continuous).integrable_of_hasCompactSupport (hKs.comp_homeomorph Φ)).indicator hS0
  have hWy : Integrable (S0.indicator Wy) (volume.prod volume) :=
    ((hBc.comp Φ.continuous).integrable_of_hasCompactSupport (hBs.comp_homeomorph Φ)).indicator hS0
  have hdec : ∀ q, S0.indicator (H ∘ Φ) q = S0.indicator Wt q + (1 / 2 - s) * S0.indicator Wy q := by
    intro q
    by_cases hq : q ∈ S0
    · rw [Set.indicator_of_mem hq, Set.indicator_of_mem hq, Set.indicator_of_mem hq]
      have hsplit : ((s, 1) : ℝ × ℝ) = s • ((1, 0) : ℝ × ℝ) + ((0, 1) : ℝ × ℝ) := by
        ext <;> simp
      simp only [Function.comp, H, A, Wt, Wy, B]
      rw [hsplit, map_add, map_smul, smul_eq_mul]
      ring
    · simp [Set.indicator_of_notMem hq]
  have ha : ∫ q, S0.indicator Wt q = 0 := by
    rw [Measure.volume_eq_prod, integral_prod _ hWt]
    have hy0 : ∀ y : ℝ, ∫ t, S0.indicator Wt (y, t) = 0 := by
      intro y
      by_cases hy : y < 0
      · have hin : ∀ t : ℝ, S0.indicator Wt (y, t) = Wt (y, t) := fun t =>
          Set.indicator_of_mem (show (y, t) ∈ S0 from hy) _
        simp_rw [hin]
        let γ : ℝ → ℝ × ℝ := fun t => (y + s * t, t)
        have hγ : Topology.IsClosedEmbedding γ :=
          Function.LeftInverse.isClosedEmbedding (f := Prod.snd) (fun t => rfl) continuous_snd
            (by fun_prop)
        apply integral_eq_zero_of_hasDerivAt_of_integrable (f := fun t => v (γ t))
        · intro t
          have hγd : HasDerivAt γ ((s, 1) : ℝ × ℝ) t :=
            ((((hasDerivAt_id t).const_mul s).const_add y).prodMk (hasDerivAt_id t)).congr_deriv
              (by simp)
          exact (hd (γ t)).hasFDerivAt.comp_hasDerivAt t hγd
        · exact (hKc.comp hγ.continuous).integrable_of_hasCompactSupport
            (hKs.comp_isClosedEmbedding hγ)
        · exact (hv.continuous.comp hγ.continuous).integrable_of_hasCompactSupport
            (hvs.comp_isClosedEmbedding hγ)
      · have hout : ∀ t : ℝ, S0.indicator Wt (y, t) = 0 := fun t =>
          Set.indicator_of_notMem (show (y, t) ∉ S0 from hy) _
        simp_rw [hout]; simp
    simp_rw [hy0]; simp
  have hb : ∫ q, S0.indicator Wy q = ∫ t, v (s * t, t) := by
    rw [Measure.volume_eq_prod, integral_prod_symm _ hWy]
    congr 1; ext t
    let γ : ℝ → ℝ × ℝ := fun y => (y + s * t, t)
    have hγ : Topology.IsClosedEmbedding γ :=
      Function.LeftInverse.isClosedEmbedding (f := fun p : ℝ × ℝ => p.1 - s * t)
        (fun y => by simp [γ]) (by fun_prop) (by fun_prop)
    have hderiv : ∀ y, deriv (fun y => v (γ y)) y = Wy (y, t) := fun y => by
      have hγd : HasDerivAt γ ((1, 0) : ℝ × ℝ) y :=
        ((hasDerivAt_id y).add_const (s * t)).prodMk (hasDerivAt_const y t)
      exact ((hd (γ y)).hasFDerivAt.comp_hasDerivAt y hγd).deriv
    have hind : ∀ y, S0.indicator Wy (y, t) =
        (Iio (0 : ℝ)).indicator (fun y => deriv (fun y => v (γ y)) y) y := by
      intro y
      by_cases hy : y < 0
      · rw [Set.indicator_of_mem (show (y, t) ∈ S0 from hy),
          Set.indicator_of_mem (show y ∈ Iio (0 : ℝ) from hy)]
        exact (hderiv y).symm
      · rw [Set.indicator_of_notMem (show (y, t) ∉ S0 from hy),
          Set.indicator_of_notMem (show y ∉ Iio (0 : ℝ) from hy)]
    simp_rw [hind]
    have hγc : ContDiff ℝ 1 (fun y => v (γ y)) :=
      (hv.of_le (by simp)).comp (by fun_prop)
    rw [integral_indicator measurableSet_Iio, ← integral_Iic_eq_integral_Iio,
      HasCompactSupport.integral_Iic_deriv_eq hγc (hvs.comp_isClosedEmbedding hγ)]
    simp [γ]
  rw [hshear]
  simp_rw [hdec]
  rw [Measure.volume_eq_prod] at ha hb ⊢
  rw [integral_add hWt (hWy.const_mul _), integral_const_mul, ha, hb]
  ring

#print axioms wsw_burgers_residual

/-- **Weak and ordinary solutions agree for smooth shapes (Steps 1 and 2).** Let the sheet be an
open region `Ω` in `d`-dimensional space, let `T` be the tension and `f` the load per unit area,
continuous on `Ω`, and let the shape `u` have two continuous derivatives on `Ω`. Then `u`
satisfies the weak form `∫ T ∇u · ∇v = ∫ f v` for every test function `v` (smooth, vanishing
outside a closed and bounded part of `Ω`, so zero near the frame) if and only if `u` solves the
strong equation `-T Δu = f` at every point of `Ω`. So the weak form adds no new smooth solutions
and loses none. -/
theorem weak_solution_iff_classical_solution {d : ℕ} {Ω : Set (EuclideanSpace ℝ (Fin d))}
    (hΩ : IsOpen Ω) (T : ℝ) {u f : EuclideanSpace ℝ (Fin d) → ℝ}
    (hu : ContDiffOn ℝ 2 u Ω) (hf : ContinuousOn f Ω) :
    (∀ v : EuclideanSpace ℝ (Fin d) → ℝ, ContDiff ℝ ∞ v → HasCompactSupport v →
        tsupport v ⊆ Ω →
        ∫ x, T * ⟪∇ u x, ∇ v x⟫ = ∫ x, f x * v x) ↔
      ∀ x ∈ Ω, -T * Δ u x = f x := by
  have hlapc : ContinuousOn (Δ u) Ω := by
    have hci : ∀ e, ContinuousOn (fun x => iteratedFDeriv ℝ 2 u x ![e, e]) Ω := by
      intro e
      have : ContinuousOn (iteratedFDeriv ℝ 2 u) Ω :=
        (hu.continuousOn_iteratedFDerivWithin (m := 2) le_rfl hΩ.uniqueDiffOn).congr
          (iteratedFDerivWithin_of_isOpen 2 hΩ).symm
      exact (continuous_eval_const _).comp_continuousOn this
    rw [InnerProductSpace.laplacian_eq_iteratedFDeriv_orthonormalBasis u
      (stdOrthonormalBasis ℝ (EuclideanSpace ℝ (Fin d)))]
    exact continuousOn_finsetSum _ fun i _ => hci _
  have hhc : ContinuousOn (fun x => -T * Δ u x - f x) Ω :=
    (continuousOn_const.mul hlapc).sub hf
  constructor
  · intro hweak
    have hzero : ∀ g : EuclideanSpace ℝ (Fin d) → ℝ, ContDiff ℝ ∞ g → HasCompactSupport g →
        tsupport g ⊆ Ω → ∫ x, g x • (-T * Δ u x - f x) = 0 := by
      intro g hg hgs hgΩ
      have h1 := wsw_integrable_mul hΩ (φ := fun x => -T * Δ u x)
        (continuousOn_const.mul hlapc) hg.continuous hgs hgΩ
      have h2 := wsw_integrable_mul hΩ hf hg.continuous hgs hgΩ
      have h3 : ∫ x, g x • (-T * Δ u x - f x) =
          (∫ x, (-T * Δ u x) * g x) - ∫ x, f x * g x := by
        rw [← integral_sub h1 h2]
        congr 1; ext x; simp only [smul_eq_mul]; ring
      rw [h3, ← wsw_ibp_identity hΩ T hu hg hgs hgΩ, hweak g hg hgs hgΩ, sub_self]
    have hae := hΩ.ae_eq_zero_of_integral_contDiff_smul_eq_zero
      (μ := volume) (hhc.locallyIntegrableOn hΩ.measurableSet) hzero
    have heq : (fun x => -T * Δ u x - f x) =ᵐ[volume.restrict Ω] (fun _ => (0 : ℝ)) := by
      rw [Filter.EventuallyEq, ae_restrict_iff' hΩ.measurableSet]
      exact hae
    intro x hx
    have := Measure.eqOn_open_of_ae_eq heq hΩ hhc continuousOn_const hx
    simp only at this
    linarith
  · intro hstrong v hv hvs hvΩ
    rw [wsw_ibp_identity hΩ T hu hv hvs hvΩ]
    congr 1; ext x
    by_cases hx : x ∈ Ω
    · rw [hstrong x hx]
    · simp [image_eq_zero_of_notMem_tsupport (fun h => hx (hvΩ h))]

/-- **The tent is a weak solution with the rods' load (Step 3).** The sheet is the square
`-R < x < R`, `-R < y < R` under tension `T`, and the tent is
`u(x, y) = z₀ (1 - max(|x|, |y|) / R)`, flat on four faces and creased along both diagonals
(the rods). For every test function `v` (smooth, vanishing outside a closed and bounded part of
the open square), the tension side `∫ T (u_x v_x + u_y v_y)` over the square equals the rod side
`q ∫_rods v dS` with line load `q = √2 T z₀ / R`; along each diagonal the length element is
`dS = √2 dt`, so `∫_rods v dS = √2 ∫_{-R}^{R} (v(t, t) + v(t, -t)) dt`. Partial derivatives are
taken by `deriv` along each coordinate; on the creases, a set of zero area, the tent has none. -/
theorem tent_is_weak_solution_with_rod_load (T z₀ R : ℝ) (hR : 0 < R) (v : ℝ × ℝ → ℝ)
    (hv : ContDiff ℝ ∞ v) (hv_supp : HasCompactSupport v)
    (hv_sq : tsupport v ⊆ Ioo (-R) R ×ˢ Ioo (-R) R) :
    let u : ℝ × ℝ → ℝ := fun p => z₀ * (1 - max |p.1| |p.2| / R)
    ∫ p in Ioo (-R) R ×ˢ Ioo (-R) R,
        T * (deriv (fun x => u (x, p.2)) p.1 * deriv (fun x => v (x, p.2)) p.1 +
          deriv (fun y => u (p.1, y)) p.2 * deriv (fun y => v (p.1, y)) p.2) =
      (Real.sqrt 2 * T * z₀ / R) *
        (Real.sqrt 2 * ∫ t in (-R)..R, (v (t, t) + v (t, -t))) := by
  intro u
  have hd : Differentiable ℝ v := hv.differentiable (by simp)
  have hv1 : ContDiff ℝ 1 v := hv.of_le (by simp)
  have hvz : ∀ p : ℝ × ℝ, p ∉ Ioo (-R) R ×ˢ Ioo (-R) R → v p = 0 := fun p hp =>
    image_eq_zero_of_notMem_tsupport (fun h => hp (hv_sq h))
  set P1 : ℝ × ℝ → ℝ := fun q =>
    T * (deriv (fun y => z₀ * (1 - max |y| |q.1| / R)) q.2 * deriv (fun x => v (x, q.1)) q.2)
    with hP1def
  set P2 : ℝ × ℝ → ℝ := fun q =>
    T * (deriv (fun y => z₀ * (1 - max |y| |q.1| / R)) q.2 * deriv (fun y => v (q.1, y)) q.2)
    with hP2def
  have hpt : ∀ p : ℝ × ℝ,
      T * (deriv (fun x => u (x, p.2)) p.1 * deriv (fun x => v (x, p.2)) p.1 +
          deriv (fun y => u (p.1, y)) p.2 * deriv (fun y => v (p.1, y)) p.2) =
        P1 p.swap + P2 p := by
    intro p
    have e1 : (fun x => u (x, p.2)) = fun y => z₀ * (1 - max |y| |p.2| / R) := rfl
    have e2 : (fun y => u (p.1, y)) = fun y => z₀ * (1 - max |y| |p.1| / R) :=
      funext fun y => by simp only [u]; rw [max_comm]
    rw [e1, e2]
    simp only [P1, P2, Prod.fst_swap, Prod.snd_swap]
    ring
  simp_rw [hpt]
  -- measurability and bounds of the tent's partial derivatives
  have hm : Measurable (fun q : ℝ × ℝ => deriv (fun y => z₀ * (1 - max |y| |q.1| / R)) q.2) :=
    measurable_deriv_with_param (f := fun a y => z₀ * (1 - max |y| |a| / R))
      (by unfold Function.uncurry; fun_prop)
  have hbd : ∀ q : ℝ × ℝ, |deriv (fun y => z₀ * (1 - max |y| |q.1| / R)) q.2| ≤ |z₀| / R :=
    fun q => wsw_tent_deriv_bound z₀ R hR _ _
  obtain ⟨hAc, hAs, -⟩ := wsw_partial_test2 hv hv_supp ((0, 1) : ℝ × ℝ)
  obtain ⟨hBc, hBs, -⟩ := wsw_partial_test2 hv hv_supp ((1, 0) : ℝ × ℝ)
  have eA : (fun q : ℝ × ℝ => deriv (fun y => v (q.1, y)) q.2) =
      fun q => fderiv ℝ v q (0, 1) := funext fun q => wsw_slice_snd hd q.1 q.2
  have eB : (fun q : ℝ × ℝ => deriv (fun x => v (x, q.1)) q.2) =
      (fun q => fderiv ℝ v q (1, 0)) ∘ Homeomorph.prodComm ℝ ℝ :=
    funext fun q => wsw_slice_fst hd q.2 q.1
  have eB' : (fun q : ℝ × ℝ => deriv (fun x => v (x, q.2)) q.1) =
      fun q => fderiv ℝ v q (1, 0) := funext fun q => wsw_slice_fst hd q.1 q.2
  have hP1 : IntegrableOn P1 (Ioo (-R) R ×ˢ Ioo (-R) R) (volume.prod volume) := by
    have := wsw_tent_int T R (|z₀| / R) _ _ hm hbd
      (hw := show Continuous (fun q : ℝ × ℝ => deriv (fun x => v (x, q.1)) q.2) by
        rw [eB]; exact hBc.comp (Homeomorph.prodComm ℝ ℝ).continuous)
      (show HasCompactSupport (fun q : ℝ × ℝ => deriv (fun x => v (x, q.1)) q.2) by
        rw [eB]; exact hBs.comp_homeomorph _)
    exact this
  have hP2 : IntegrableOn P2 (Ioo (-R) R ×ˢ Ioo (-R) R) (volume.prod volume) := by
    have := wsw_tent_int T R (|z₀| / R) _ _ hm hbd
      (hw := show Continuous (fun q : ℝ × ℝ => deriv (fun y => v (q.1, y)) q.2) by
        rw [eA]; exact hAc)
      (show HasCompactSupport (fun q : ℝ × ℝ => deriv (fun y => v (q.1, y)) q.2) by
        rw [eA]; exact hAs)
    exact this
  have hP1s : IntegrableOn (fun p : ℝ × ℝ => P1 p.swap) (Ioo (-R) R ×ˢ Ioo (-R) R)
      (volume.prod volume) := by
    have := wsw_tent_int T R (|z₀| / R) _ _ (hm.comp measurable_swap) (fun q => hbd q.swap)
      (hw := show Continuous (fun q : ℝ × ℝ => deriv (fun x => v (x, q.2)) q.1) by
        rw [eB']; exact hBc)
      (show HasCompactSupport (fun q : ℝ × ℝ => deriv (fun x => v (x, q.2)) q.1) by
        rw [eB']; exact hBs)
    exact this
  have hvR : ∀ a : ℝ, v (a, R) = 0 ∧ v (a, -R) = 0 ∧ v (R, a) = 0 ∧ v (-R, a) = 0 := by
    intro a
    refine ⟨hvz _ fun h => lt_irrefl R h.2.2, hvz _ fun h => lt_irrefl (-R) h.2.1,
      hvz _ fun h => lt_irrefl R h.1.2, hvz _ fun h => lt_irrefl (-R) h.1.1⟩
  have hI1 : ∫ q in Ioo (-R) R ×ˢ Ioo (-R) R, P1 q ∂(volume.prod volume) =
      ∫ y in Ioo (-R) R, T * z₀ / R * (v (|y|, y) + v (-|y|, y)) := by
    rw [setIntegral_prod _ hP1]
    refine setIntegral_congr_fun measurableSet_Ioo fun y hy => ?_
    exact wsw_tent_1d T z₀ R hR |y| (abs_nonneg y) (abs_lt.mpr hy) (fun x => v (x, y))
      (hv1.comp (by fun_prop)) (hvR y).2.2.1 (hvR y).2.2.2
  have hI2 : ∫ q in Ioo (-R) R ×ˢ Ioo (-R) R, P2 q ∂(volume.prod volume) =
      ∫ x in Ioo (-R) R, T * z₀ / R * (v (x, |x|) + v (x, -|x|)) := by
    rw [setIntegral_prod _ hP2]
    refine setIntegral_congr_fun measurableSet_Ioo fun x hx => ?_
    exact wsw_tent_1d T z₀ R hR |x| (abs_nonneg x) (abs_lt.mpr hx) (fun y => v (x, y))
      (hv1.comp (by fun_prop)) (hvR x).1 (hvR x).2.1
  have hc1 : Continuous (fun t : ℝ => v (t, t)) := hv.continuous.comp (by fun_prop)
  have hc2 : Continuous (fun t : ℝ => v (t, -t)) := hv.continuous.comp (by fun_prop)
  have hc3 : Continuous (fun t : ℝ => v (-t, t)) := hv.continuous.comp (by fun_prop)
  have hRle : -R ≤ R := by linarith
  have hJ1 : ∫ y in Ioo (-R) R, T * z₀ / R * (v (|y|, y) + v (-|y|, y)) =
      T * z₀ / R * ∫ t in (-R)..R, (v (t, t) + v (t, -t)) := by
    rw [integral_const_mul]
    congr 1
    rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hRle]
    have hsym : ∀ y : ℝ, v (|y|, y) + v (-|y|, y) = v (y, y) + v (-y, y) := by
      intro y
      rcases le_total 0 y with h | h
      · rw [abs_of_nonneg h]
      · rw [abs_of_nonpos h, neg_neg]; ring
    simp_rw [hsym]
    rw [intervalIntegral.integral_add (hc1.intervalIntegrable _ _) (hc3.intervalIntegrable _ _),
      intervalIntegral.integral_add (hc1.intervalIntegrable _ _) (hc2.intervalIntegrable _ _)]
    congr 1
    have := intervalIntegral.integral_comp_neg (a := -R) (b := R) (fun t => v (t, -t))
    simp only [neg_neg] at this
    exact this
  have hJ2 : ∫ x in Ioo (-R) R, T * z₀ / R * (v (x, |x|) + v (x, -|x|)) =
      T * z₀ / R * ∫ t in (-R)..R, (v (t, t) + v (t, -t)) := by
    rw [integral_const_mul]
    congr 1
    rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hRle]
    have hsym : ∀ x : ℝ, v (x, |x|) + v (x, -|x|) = v (x, x) + v (x, -x) := by
      intro x
      rcases le_total 0 x with h | h
      · rw [abs_of_nonneg h]
      · rw [abs_of_nonpos h, neg_neg]; ring
    simp_rw [hsym]
  rw [Measure.volume_eq_prod, integral_add hP1s hP2,
    setIntegral_prod_swap (Ioo (-R) R) (Ioo (-R) R) P1, hI1, hI2, hJ1, hJ2]
  have h2 : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
  linear_combination (-(T * z₀ / R * ∫ t in (-R)..R, (v (t, t) + v (t, -t)))) * h2

/-- **The Burgers jump and the Rankine-Hugoniot speed (Step 5).** For Burgers' equation
`u_t + (u²/2)_x = 0` (scaled units), take the jump `u(x, t) = 1` for `x < s t` and `u = 0`
otherwise, moving at speed `s`. For every test function `v(x, t)` (smooth, vanishing outside a
bounded set), the weak residual `∬ (u v_t + ½ u² v_x) dx dt` equals
`(1/2 - s) ∫ v(s t, t) dt`, the jump in flux minus the speed times the jump in `u`, weighted
along the shock's path. Consequently the jump is a weak solution, residual zero for every test
function, exactly when `s = 1/2`. -/
theorem burgers_jump_weak_residual (s : ℝ) :
    let u : ℝ × ℝ → ℝ := fun p => if p.1 < s * p.2 then 1 else 0
    (∀ v : ℝ × ℝ → ℝ, ContDiff ℝ ∞ v → HasCompactSupport v →
        ∫ p, (u p * deriv (fun t => v (p.1, t)) p.2 +
            1 / 2 * u p ^ 2 * deriv (fun x => v (x, p.2)) p.1) =
          (1 / 2 - s) * ∫ t, v (s * t, t)) ∧
    ((∀ v : ℝ × ℝ → ℝ, ContDiff ℝ ∞ v → HasCompactSupport v →
        ∫ p, (u p * deriv (fun t => v (p.1, t)) p.2 +
            1 / 2 * u p ^ 2 * deriv (fun x => v (x, p.2)) p.1) = 0) ↔ s = 1 / 2) := by
  intro u
  have key : ∀ v : ℝ × ℝ → ℝ, ContDiff ℝ ∞ v → HasCompactSupport v →
      ∫ p, (u p * deriv (fun t => v (p.1, t)) p.2 +
          1 / 2 * u p ^ 2 * deriv (fun x => v (x, p.2)) p.1) =
        (1 / 2 - s) * ∫ t, v (s * t, t) := fun v hv hvs => wsw_burgers_residual s v hv hvs
  refine ⟨key, ⟨fun h => ?_, fun h v hv hvs => ?_⟩⟩
  · let φ : ContDiffBump (0 : ℝ × ℝ) := ⟨1, 2, by norm_num, by norm_num⟩
    have hφ : ContDiff ℝ ∞ φ := φ.contDiff
    have hφs : HasCompactSupport φ := φ.hasCompactSupport
    have h0 := h φ hφ hφs
    rw [key φ hφ hφs] at h0
    let γ : ℝ → ℝ × ℝ := fun t => (s * t, t)
    have hγ : Topology.IsClosedEmbedding γ :=
      Function.LeftInverse.isClosedEmbedding (f := Prod.snd) (fun t => rfl) continuous_snd
        (by fun_prop)
    have hpos : 0 < ∫ t, φ (s * t, t) := by
      refine Continuous.integral_pos_of_hasCompactSupport_nonneg_ne_zero (x := 0)
        (φ.continuous.comp hγ.continuous) (hφs.comp_isClosedEmbedding hγ)
        (fun t => φ.nonneg) ?_
      have : φ ((s * 0, 0) : ℝ × ℝ) = 1 := φ.one_of_mem_closedBall (by simp [φ])
      show φ (γ 0) ≠ 0
      simp only [γ]
      rw [this]; norm_num
    rcases mul_eq_zero.mp h0 with h1 | h1
    · linarith
    · linarith
  · rw [key v hv hvs, h]; ring

/-! The card's worked numbers, with `R = 1/2` m, `T = 200` N/m and `z₀ = 1/20` m. -/

-- face slope: 0.05 ÷ 0.5 = 0.10
example : ((1 : ℚ) / 20) / (1 / 2) = 1 / 10 := by norm_num

-- the frame pulls down 200 × 0.10 × 4 m of edge = 80 N
example : (200 : ℚ) * (1 / 10) * 4 = 80 := by norm_num

-- the rods lift q × (total rod length) = (√2 × 200 × 0.10) × (4 √2 × 0.5) = 80 N, matching the frame
example : (Real.sqrt 2 * 200 * (1 / 10)) * (4 * Real.sqrt 2 * (1 / 2)) = 80 := by
  have h : Real.sqrt 2 * Real.sqrt 2 = 2 := Real.mul_self_sqrt (by norm_num)
  nlinarith [h]

-- tension side with v = u: 200 × 0.10² × 1 m² = 2 J, stored energy 1 J
example : (200 : ℚ) * (1 / 10) ^ 2 * 1 = 2 ∧ (2 : ℚ) / 2 = 1 := by norm_num

-- slope jump measured along x instead of straight across: 200 × 0.10 = 20 N/m
example : (200 : ℚ) * (1 / 10) = 20 := by norm_num

-- Rankine-Hugoniot speed for the 1-to-0 jump: jump in flux over jump in u
example : ((1 : ℚ) ^ 2 / 2 - 0 ^ 2 / 2) / (1 - 0) = 1 / 2 := by norm_num

#print axioms weak_solution_iff_classical_solution
#print axioms tent_is_weak_solution_with_rod_load
#print axioms burgers_jump_weak_residual
