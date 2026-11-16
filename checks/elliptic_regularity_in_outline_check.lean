-- Elliptic regularity: for the heated wall -(k u')' = f on 0 < x < L, the weak form forces k u' = c₀ - F, so a weak solution gains two derivatives over its source: a square-integrable source gives u in H², and a source with m continuous derivatives and a conductivity with m + 1 give u with m + 2.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Function.LpSpace.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Integral.IntervalIntegral.AbsolutelyContinuousFun
import Mathlib.MeasureTheory.Integral.IntervalIntegral.LebesgueDifferentiationThm
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.Calculus.ContDiff.Deriv

open MeasureTheory Set

theorem restrict_Ioo_eq_Ioc_zero (L : ℝ) :
    volume.restrict (Ioo (0 : ℝ) L) = volume.restrict (Ioc 0 L) :=
  Measure.restrict_congr_set Ioo_ae_eq_Ioc

#print axioms restrict_Ioo_eq_Ioc_zero

theorem memLp_of_continuousOn_Icc_zero {L : ℝ} {g : ℝ → ℝ} (hg : ContinuousOn g (Icc 0 L))
    (p : ENNReal) : MemLp g p (volume.restrict (Ioc 0 L)) := by
  obtain ⟨C, hC⟩ := isCompact_Icc.exists_bound_of_continuousOn hg
  have hmeas : AEStronglyMeasurable g (volume.restrict (Ioc 0 L)) :=
    (hg.aestronglyMeasurable measurableSet_Icc).mono_measure
      (Measure.restrict_mono Ioc_subset_Icc_self le_rfl)
  refine MemLp.of_bound hmeas C ?_
  rw [ae_restrict_iff' measurableSet_Ioc]
  exact Filter.Eventually.of_forall fun x hx => hC x (Ioc_subset_Icc_self hx)

#print axioms memLp_of_continuousOn_Icc_zero

theorem intervalIntegrable_of_memLp_two {L x : ℝ} {g : ℝ → ℝ}
    (hg : MemLp g 2 (volume.restrict (Ioc 0 L))) (hx : x ∈ Icc 0 L) :
    IntervalIntegrable g volume 0 x := by
  have hi : IntegrableOn g (Ioc 0 L) := hg.integrable one_le_two
  rw [intervalIntegrable_iff_integrableOn_Ioc_of_le hx.1]
  exact hi.mono_set (Ioc_subset_Ioc_right hx.2)

#print axioms intervalIntegrable_of_memLp_two

theorem contDiffOn_primitive_Icc {L : ℝ} (hL : 0 < L) {n : ℕ} {h : ℝ → ℝ}
    (hh : ContDiffOn ℝ n h (Icc 0 L)) :
    ContDiffOn ℝ ((n : WithTop ℕ∞) + 1) (fun x => ∫ t in (0 : ℝ)..x, h t) (Icc 0 L) := by
  have hc : ContinuousOn h (Icc 0 L) := hh.continuousOn
  have hd : ∀ x ∈ Icc 0 L,
      HasDerivWithinAt (fun x => ∫ t in (0 : ℝ)..x, h t) (h x) (Icc 0 L) x := by
    intro x hx
    have : Fact (x ∈ Icc 0 L) := ⟨hx⟩
    exact intervalIntegral.integral_hasDerivWithinAt_right
      ((hc.mono (Icc_subset_Icc_right hx.2)).intervalIntegrable_of_Icc hx.1)
      (hc.stronglyMeasurableAtFilter_nhdsWithin measurableSet_Icc x) (hc x hx)
  rw [contDiffOn_succ_iff_derivWithin (uniqueDiffOn_Icc hL)]
  refine ⟨fun x hx => (hd x hx).differentiableWithinAt, by simp, ?_⟩
  exact hh.congr fun x hx => (hd x hx).derivWithin ((uniqueDiffOn_Icc hL) x hx)

#print axioms contDiffOn_primitive_Icc

/-- Helper: the flux formula, proved here so that the first theorem can use it. -/
theorem weak_form_flux_aux {L : ℝ} (hL : 0 < L) {k f du : ℝ → ℝ}
    (hk : ContinuousOn k (Icc 0 L))
    (hf : MemLp f 2 (volume.restrict (Ioo 0 L)))
    (hdu : MemLp du 2 (volume.restrict (Ioo 0 L)))
    (hweak : ∀ w : ℝ → ℝ, MemLp w 2 (volume.restrict (Ioo 0 L)) →
      ∫ t in (0 : ℝ)..L, w t = 0 →
      ∫ x in (0 : ℝ)..L, k x * du x * w x = ∫ x in (0 : ℝ)..L, f x * ∫ t in (0 : ℝ)..x, w t) :
    ∃ c₀ : ℝ, ∀ᵐ x ∂(volume.restrict (Ioo 0 L)), k x * du x = c₀ - ∫ t in (0 : ℝ)..x, f t := by
  rw [restrict_Ioo_eq_Ioc_zero] at hf hdu hweak ⊢
  set μ := volume.restrict (Ioc (0 : ℝ) L) with hμ
  have hLmem : L ∈ Icc 0 L := ⟨hL.le, le_rfl⟩
  have h0mem : (0 : ℝ) ∈ uIcc 0 L := left_mem_uIcc
  have hkL : MemLp k ⊤ μ := memLp_of_continuousOn_Icc_zero hk ⊤
  set F : ℝ → ℝ := fun x => ∫ t in (0 : ℝ)..x, f t with hF
  have hfi : IntervalIntegrable f volume 0 L := intervalIntegrable_of_memLp_two hf hLmem
  have hFac : AbsolutelyContinuousOnInterval F 0 L :=
    hfi.absolutelyContinuousOnInterval_intervalIntegral h0mem
  have hFc : ContinuousOn F (Icc 0 L) := by
    simpa [uIcc_of_le hL.le] using hFac.continuousOn
  have hFL : MemLp F 2 μ := memLp_of_continuousOn_Icc_zero hFc 2
  set G : ℝ → ℝ := fun x => k x * du x + F x with hG
  have hGL : MemLp G 2 μ := (hkL.mul hdu).add hFL
  -- the weak form, rewritten
  have key : ∀ w : ℝ → ℝ, MemLp w 2 μ → ∫ x, w x ∂μ = 0 → ∫ x, G x * w x ∂μ = 0 := by
    intro w hw hint
    have hint' : ∫ t in (0 : ℝ)..L, w t = 0 := by
      rw [intervalIntegral.integral_of_le hL.le]; exact hint
    have h1 := hweak w hw hint'
    have hwi : IntervalIntegrable w volume 0 L := intervalIntegrable_of_memLp_two hw hLmem
    set W : ℝ → ℝ := fun x => ∫ t in (0 : ℝ)..x, w t with hW
    have hWac : AbsolutelyContinuousOnInterval W 0 L :=
      hwi.absolutelyContinuousOnInterval_intervalIntegral h0mem
    have hibp := hFac.integral_mul_deriv_eq_deriv_mul hWac
    have hdW : ∫ x in (0 : ℝ)..L, F x * deriv W x = ∫ x in (0 : ℝ)..L, F x * w x := by
      apply intervalIntegral.integral_congr_ae
      filter_upwards [hwi.ae_hasDerivAt_integral] with x hx hxI
      rw [(hx (uIoc_subset_uIcc hxI) 0 h0mem).deriv]
    have hdF : ∫ x in (0 : ℝ)..L, deriv F x * W x = ∫ x in (0 : ℝ)..L, f x * W x := by
      apply intervalIntegral.integral_congr_ae
      filter_upwards [hfi.ae_hasDerivAt_integral] with x hx hxI
      rw [(hx (uIoc_subset_uIcc hxI) 0 h0mem).deriv]
    have hWL : W L = 0 := hint'
    have hF0 : F 0 = 0 := intervalIntegral.integral_same
    rw [hdW, hdF, hWL, hF0] at hibp
    have hsum : (∫ x in (0 : ℝ)..L, k x * du x * w x) + (∫ x in (0 : ℝ)..L, F x * w x) = 0 := by
      have hC : (∫ x in (0 : ℝ)..L, f x * W x)
          = ∫ x in (0 : ℝ)..L, f x * ∫ t in (0 : ℝ)..x, w t := rfl
      linarith
    have i1 : Integrable (fun x => k x * du x * w x) μ := (hkL.mul (r := 2) hdu).integrable_mul hw
    have i2 : Integrable (fun x => F x * w x) μ := hFL.integrable_mul hw
    rw [intervalIntegral.integral_of_le hL.le, intervalIntegral.integral_of_le hL.le,
      ← integral_add i1 i2] at hsum
    rw [← hsum]
    congr 1; ext x; simp only [hG]; ring
  -- the mean of G
  have hμL : μ.real univ = L := by simp [μ, hL.le]
  set a : ℝ := (∫ x, G x ∂μ) / L with ha
  have hGi : Integrable G μ := hGL.integrable one_le_two
  have hwL : MemLp (fun x => G x - a) 2 μ := hGL.sub (memLp_const a)
  have hwint : ∫ x, (G x - a) ∂μ = 0 := by
    rw [integral_sub hGi (integrable_const a), integral_const, hμL, smul_eq_mul, ha]
    field_simp; ring
  have h2 := key _ hwL hwint
  have hsq : ∫ x, (G x - a) ^ 2 ∂μ = 0 := by
    have e : (fun x => (G x - a) ^ 2) = fun x => G x * (G x - a) - a * (G x - a) := by
      ext x; ring
    have i3 : Integrable (fun x => G x * (G x - a)) μ := hGL.integrable_mul hwL
    rw [e, integral_sub i3 ((hwL.integrable one_le_two).const_mul a),
      integral_const_mul, h2, hwint]; ring
  have hae := (integral_eq_zero_iff_of_nonneg (fun x => sq_nonneg (G x - a))
    hwL.integrable_sq).1 hsq
  refine ⟨a, ?_⟩
  filter_upwards [hae] with x hx
  have : (G x - a) ^ 2 = 0 := hx
  have : G x = a := by nlinarith [sq_nonneg (G x - a), pow_eq_zero_iff (n := 2) (two_ne_zero) |>.1 this]
  simp only [hG] at this
  linarith

#print axioms weak_form_flux_aux

/-- **A weak solution is as smooth as its data allow (one space direction).** The wall is the
region `0 < x < L`. The conductivity `k` has `m + 1` continuous derivatives on the closed wall and
stays above the ellipticity constant `θ > 0`; the heat made per unit volume, `f`, has `m`
continuous derivatives there. The temperature `u` is a weak solution in `H¹`: it has a
square-integrable weak slope `du`, so `u x = u 0 + ∫₀ˣ du`, and it satisfies the weak form
`∫₀ᴸ k u' v' = ∫₀ᴸ f v` for every test function `v` in `H¹₀(0, L)`. Such a `v` is exactly
`v x = ∫₀ˣ w` with `w` square-integrable and `∫₀ᴸ w = 0` (so `v` is zero at both faces), and then
`v' = w`. Conclusion: `u` has `m + 2` continuous derivatives on the closed wall, so it is a
classical solution. -/
theorem weak_solution_gains_two_derivatives (m : ℕ) {L θ : ℝ} (hL : 0 < L) (hθ : 0 < θ)
    {k f u du : ℝ → ℝ}
    (hk : ContDiffOn ℝ (m + 1) k (Icc 0 L)) (hkθ : ∀ x ∈ Icc 0 L, θ ≤ k x)
    (hf : ContDiffOn ℝ m f (Icc 0 L))
    (hdu : MemLp du 2 (volume.restrict (Ioo 0 L)))
    (hu : ∀ x ∈ Icc 0 L, u x = u 0 + ∫ t in (0 : ℝ)..x, du t)
    (hweak : ∀ w : ℝ → ℝ, MemLp w 2 (volume.restrict (Ioo 0 L)) →
      ∫ t in (0 : ℝ)..L, w t = 0 →
      ∫ x in (0 : ℝ)..L, k x * du x * w x = ∫ x in (0 : ℝ)..L, f x * ∫ t in (0 : ℝ)..x, w t) :
    ContDiffOn ℝ (m + 2) u (Icc 0 L) := by
  have hf2 : MemLp f 2 (volume.restrict (Ioo 0 L)) := by
    rw [restrict_Ioo_eq_Ioc_zero]; exact memLp_of_continuousOn_Icc_zero hf.continuousOn 2
  obtain ⟨c₀, hc⟩ := weak_form_flux_aux hL hk.continuousOn hf2 hdu hweak
  rw [restrict_Ioo_eq_Ioc_zero, ae_restrict_iff' measurableSet_Ioc] at hc
  have hk0 : ∀ x ∈ Icc 0 L, k x ≠ 0 := fun x hx => (lt_of_lt_of_le hθ (hkθ x hx)).ne'
  set h : ℝ → ℝ := fun x => (c₀ - ∫ t in (0 : ℝ)..x, f t) / k x with hh
  have hhc : ContDiffOn ℝ ((m + 1 : ℕ) : WithTop ℕ∞) h (Icc 0 L) := by
    have hF := contDiffOn_primitive_Icc hL hf
    have hk' : ContDiffOn ℝ ((m + 1 : ℕ) : WithTop ℕ∞) k (Icc 0 L) := by
      convert hk using 1; push_cast; rfl
    refine ContDiffOn.div ?_ hk' hk0
    refine contDiffOn_const.sub ?_
    convert hF using 1
    push_cast; rfl
  have hu' : ∀ x ∈ Icc 0 L, u x = u 0 + ∫ t in (0 : ℝ)..x, h t := by
    intro x hx
    rw [hu x hx]
    congr 1
    apply intervalIntegral.integral_congr_ae
    filter_upwards [hc] with t ht htx
    rw [uIoc_of_le hx.1] at htx
    have htL : t ∈ Ioc 0 L := ⟨htx.1, htx.2.trans hx.2⟩
    have hkt := hk0 t (Ioc_subset_Icc_self htL)
    have := ht htL
    simp only [hh]
    field_simp
    linarith
  have hG := (contDiffOn_const (c := u 0)).add (contDiffOn_primitive_Icc hL hhc)
  have e : (((m + 1 : ℕ) : WithTop ℕ∞) + 1) = (m : WithTop ℕ∞) + 2 := by
    push_cast; rw [add_assoc]; norm_num
  rw [e] at hG
  exact hG.congr hu'

/-- **A square-integrable source puts the weak solution in `H²`.** This is the card's cable-layer
case, a source that jumps: with the conductivity `k` continuously differentiable and at least
`θ > 0` on the closed wall, the source `f` only square-integrable, and `u` a weak solution in `H¹`
as above, the slope `u'` is itself an `H¹` function: there is a square-integrable bend `u''` with
`u' x = u'(0) + ∫₀ˣ u''` for almost every depth `x` in the wall. So `u` is in `H²`, two
derivatives better than its source. -/
theorem weak_solution_in_H2_of_square_integrable_source {L θ : ℝ} (hL : 0 < L) (hθ : 0 < θ)
    {k f u du : ℝ → ℝ}
    (hk : ContDiffOn ℝ 1 k (Icc 0 L)) (hkθ : ∀ x ∈ Icc 0 L, θ ≤ k x)
    (hf : MemLp f 2 (volume.restrict (Ioo 0 L)))
    (hdu : MemLp du 2 (volume.restrict (Ioo 0 L)))
    (hu : ∀ x ∈ Icc 0 L, u x = u 0 + ∫ t in (0 : ℝ)..x, du t)
    (hweak : ∀ w : ℝ → ℝ, MemLp w 2 (volume.restrict (Ioo 0 L)) →
      ∫ t in (0 : ℝ)..L, w t = 0 →
      ∫ x in (0 : ℝ)..L, k x * du x * w x = ∫ x in (0 : ℝ)..L, f x * ∫ t in (0 : ℝ)..x, w t) :
    ∃ ddu : ℝ → ℝ, MemLp ddu 2 (volume.restrict (Ioo 0 L)) ∧
      ∃ d₀ : ℝ, ∀ᵐ x ∂(volume.restrict (Ioo 0 L)), du x = d₀ + ∫ t in (0 : ℝ)..x, ddu t := by
  obtain ⟨c₀, hc⟩ := weak_form_flux_aux hL hk.continuousOn hf hdu hweak
  rw [restrict_Ioo_eq_Ioc_zero] at hf hdu hc ⊢
  set μ := volume.restrict (Ioc (0 : ℝ) L) with hμ
  have hLmem : L ∈ Icc 0 L := ⟨hL.le, le_rfl⟩
  have h0mem : (0 : ℝ) ∈ uIcc 0 L := left_mem_uIcc
  have hk0 : ∀ x ∈ Icc 0 L, k x ≠ 0 := fun x hx => (lt_of_lt_of_le hθ (hkθ x hx)).ne'
  set g : ℝ → ℝ := fun x => (k x)⁻¹ with hgdef
  have hg : ContDiffOn ℝ 1 g (Icc 0 L) := hk.inv hk0
  have hfi : IntervalIntegrable f volume 0 L := intervalIntegrable_of_memLp_two hf hLmem
  set P : ℝ → ℝ := fun x => c₀ - ∫ t in (0 : ℝ)..x, f t with hP
  have hPac : AbsolutelyContinuousOnInterval P 0 L := by
    have h1 : AbsolutelyContinuousOnInterval (fun _ : ℝ => c₀) 0 L :=
      (contDiffOn_const (c := c₀)).absolutelyContinuousOnInterval
    exact h1.sub (hfi.absolutelyContinuousOnInterval_intervalIntegral h0mem)
  have hgac : AbsolutelyContinuousOnInterval g 0 L :=
    ContDiffOn.absolutelyContinuousOnInterval (by rwa [uIcc_of_le hL.le])
  have hPg : AbsolutelyContinuousOnInterval (fun x => P x * g x) 0 L := hPac.fun_mul hgac
  have hPc : ContinuousOn P (Icc 0 L) := by
    simpa [uIcc_of_le hL.le] using hPac.continuousOn
  set g' : ℝ → ℝ := derivWithin g (Icc 0 L) with hg'
  have hg'c : ContinuousOn g' (Icc 0 L) :=
    hg.continuousOn_derivWithin (uniqueDiffOn_Icc hL) le_rfl
  have hgc : ContinuousOn g (Icc 0 L) := hg.continuousOn
  refine ⟨deriv (fun x => P x * g x), ?_, P 0 * g 0, ?_⟩
  · have hm : MemLp (fun x => -f x * g x + P x * g' x) 2 μ :=
      (hf.neg.mul (r := 2) (memLp_of_continuousOn_Icc_zero hgc ⊤)).add
        (memLp_of_continuousOn_Icc_zero (hPc.mul hg'c) 2)
    refine hm.ae_eq ?_
    have hne : ∀ᵐ x ∂μ, x ≠ L := by
      apply ae_restrict_of_ae
      simp [ae_iff, measure_singleton]
    filter_upwards [ae_restrict_mem measurableSet_Ioc, hne,
      ae_restrict_of_ae hfi.ae_hasDerivAt_integral] with x hx hxL hd
    have hxo : x ∈ Ioo 0 L := ⟨hx.1, lt_of_le_of_ne hx.2 hxL⟩
    have hnhds : Icc 0 L ∈ nhds x := Icc_mem_nhds hxo.1 hxo.2
    have hxu : x ∈ uIcc 0 L := by rw [uIcc_of_le hL.le]; exact Ioc_subset_Icc_self hx
    have hF := hd hxu 0 h0mem
    have hgd : HasDerivAt g (g' x) x := by
      have := ((hg.differentiableOn one_ne_zero) x (Ioo_subset_Icc_self hxo)).differentiableAt hnhds
      rw [hg', derivWithin_of_mem_nhds hnhds]
      exact this.hasDerivAt
    have hPd : HasDerivAt P (-f x) x := (hasDerivAt_const x c₀).sub hF |>.congr_deriv (by ring)
    exact ((hPd.mul hgd).deriv).symm
  · filter_upwards [ae_restrict_mem measurableSet_Ioc, hc] with x hx hcx
    have hxI : x ∈ Icc 0 L := Ioc_subset_Icc_self hx
    have hac : AbsolutelyContinuousOnInterval (fun x => P x * g x) 0 x :=
      hPg.mono (by
        rw [uIcc_of_le hL.le, uIcc_of_le hxI.1]; exact Icc_subset_Icc_right hxI.2)
    rw [hac.integral_deriv_eq_sub]
    have hkx := hk0 x hxI
    simp only [hgdef, hP]
    field_simp
    linarith

/-- **The weak form forces `k u' = c₀ - F`.** On the wall `0 < x < L`, with the conductivity `k`
continuous on the closed wall, the source `f` and the weak slope `du` square-integrable, and the
weak form `∫₀ᴸ k u' v' = ∫₀ᴸ f v` for every `v` in `H¹₀(0, L)` (written as `v x = ∫₀ˣ w` with
`w` square-integrable and `∫₀ᴸ w = 0`), there is a constant `c₀`, the heat flux into the room,
with conductivity times slope equal to `c₀` minus the heat made so far,
`k x · u'(x) = c₀ - ∫₀ˣ f`, for almost every depth `x`. -/
theorem weak_form_forces_flux_formula {L : ℝ} (hL : 0 < L) {k f du : ℝ → ℝ}
    (hk : ContinuousOn k (Icc 0 L))
    (hf : MemLp f 2 (volume.restrict (Ioo 0 L)))
    (hdu : MemLp du 2 (volume.restrict (Ioo 0 L)))
    (hweak : ∀ w : ℝ → ℝ, MemLp w 2 (volume.restrict (Ioo 0 L)) →
      ∫ t in (0 : ℝ)..L, w t = 0 →
      ∫ x in (0 : ℝ)..L, k x * du x * w x = ∫ x in (0 : ℝ)..L, f x * ∫ t in (0 : ℝ)..x, w t) :
    ∃ c₀ : ℝ, ∀ᵐ x ∂(volume.restrict (Ioo 0 L)), k x * du x = c₀ - ∫ t in (0 : ℝ)..x, f t := by
  exact weak_form_flux_aux hL hk hf hdu hweak

-- The card's worked numbers for the cable layer, in exact fractions (lengths in m).
-- Heat made per m³: 100 W/m² spread over 2 cm.
example : (100 : ℚ) / (2 / 100) = 5000 := by norm_num
-- Bend in the layer, -f/k = -5000/0.77 = -6493.51... K/m².
example : -(5000 : ℚ) / (77 / 100) = -500000 / 77 := by norm_num
-- Loss through the unheated wall: 0.77 × 20 / 0.2 = 77 W/m².
example : (77 / 100 : ℚ) * 20 / (2 / 10) = 77 := by norm_num
-- Heater's share toward the room and the flux into the room: 85 - 77 = 8 W/m²; out the far face 92.
example : (100 : ℚ) * (17 / 100) / (20 / 100) = 85 := by norm_num
example : (100 : ℚ) * (17 / 100) / (20 / 100) - (77 / 100) * 20 / (2 / 10) = 8 := by norm_num
example : (100 : ℚ) - 8 = 92 := by norm_num
-- Temperature at 2 cm: 20 + 8 × 0.02 / 0.77 = 1556/77 = 20.2078... °C.
example : (20 : ℚ) + 8 * (2 / 100) / (77 / 100) = 1556 / 77 := by norm_num
-- The peak sits where F(x) = c₀: 0.02 + 8/5000 = 0.0216 m.
example : (2 / 100 : ℚ) + 8 / 5000 = 216 / 10000 := by norm_num
-- Peak temperature: 20.2078 + (8 × 0.0016 - 2500 × 0.0016²)/0.77 = 38916/1925 = 20.2161... °C.
example : (1556 / 77 : ℚ) + (8 * (16 / 10000) - 2500 * (16 / 10000) ^ 2) / (77 / 100)
    = 38916 / 1925 := by norm_num
-- At 10 cm every heater gives 20/2 + 100 × 0.03 × 0.1/(0.77 × 0.2) = 920/77 = 11.948... °C.
example : (20 : ℚ) / 2 + 100 * (3 / 100) * (1 / 10) / ((77 / 100) * (2 / 10)) = 920 / 77 := by
  norm_num
-- Two-material wall (10 cm wool at 0.035, 10 cm brick at 0.77): joint at 20/23 = 0.869565 °C,
-- slope jump 4200/23 = 182.61 K/m.
example : (20 : ℚ) * ((1 / 10) / (77 / 100)) / ((1 / 10) / (35 / 1000) + (1 / 10) / (77 / 100))
    = 20 / 23 := by norm_num
example : (154 / 23 : ℚ) / (35 / 1000) - (154 / 23) / (77 / 100) = 4200 / 23 := by norm_num
-- Corners: the power π/β is 2/3 at 270° and 2 at 90°; at 270° the bend goes as r^(2/3 - 2) = r^(-4/3).
example : Real.pi / (3 * Real.pi / 2) = 2 / 3 := by field_simp
example : Real.pi / (Real.pi / 2) = 2 := by field_simp
example : (2 / 3 : ℚ) - 2 = -4 / 3 := by norm_num

#print axioms weak_solution_gains_two_derivatives
#print axioms weak_solution_in_H2_of_square_integrable_source
#print axioms weak_form_forces_flux_formula
