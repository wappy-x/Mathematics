-- Energy methods: on a rectangular plate, two classical solutions of the heat equation with the same edge values and the same start are equal, a heat source a·u lets the energy of their gap grow at most by the Gronwall factor e^(2at), and two struck plates with the same edge values, start and starting velocity ring the same way.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib

open Real Set

section EnergyMethodHelpers

open MeasureTheory Filter Topology

lemma em_clamp_mem {a b s : ℝ} (h : a ≤ b) : max a (min b s) ∈ Icc a b :=
  ⟨le_max_left _ _, max_le h (min_le_left _ _)⟩

lemma em_clamp_eq {a b s : ℝ} (h : s ∈ Icc a b) : max a (min b s) = s := by
  rw [min_eq_right h.2, max_eq_right h.1]

lemma em_ext3 {F : ℝ → ℝ → ℝ → ℝ} {a b lx ly : ℝ} (hab : a ≤ b) (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hF : ContinuousOn (fun p : ℝ × ℝ × ℝ => F p.1 p.2.1 p.2.2) (Icc a b ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) :
    ∃ G : ℝ → ℝ → ℝ → ℝ, Continuous (fun p : ℝ × ℝ × ℝ => G p.1 p.2.1 p.2.2) ∧
      ∀ s ∈ Icc a b, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, G s x y = F s x y := by
  refine ⟨fun s x y => F (max a (min b s)) (max 0 (min lx x)) (max 0 (min ly y)), ?_, ?_⟩
  · have hcl : Continuous fun p : ℝ × ℝ × ℝ =>
        ((max a (min b p.1), max 0 (min lx p.2.1), max 0 (min ly p.2.2)) : ℝ × ℝ × ℝ) := by
      fun_prop
    exact hF.comp_continuous hcl fun p => ⟨em_clamp_mem hab, em_clamp_mem hlx, em_clamp_mem hly⟩
  · intro s hs x hx y hy
    simp only [em_clamp_eq hs, em_clamp_eq hx, em_clamp_eq hy]

lemma em_ext2 {F : ℝ → ℝ → ℝ} {lx ly : ℝ} (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hF : ContinuousOn (fun p : ℝ × ℝ => F p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly)) :
    ∃ G : ℝ → ℝ → ℝ, Continuous (fun p : ℝ × ℝ => G p.1 p.2) ∧
      ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, G x y = F x y := by
  refine ⟨fun x y => F (max 0 (min lx x)) (max 0 (min ly y)), ?_, ?_⟩
  · have hcl : Continuous fun p : ℝ × ℝ =>
        ((max 0 (min lx p.1), max 0 (min ly p.2)) : ℝ × ℝ) := by
      fun_prop
    exact hF.comp_continuous hcl fun p => ⟨em_clamp_mem hlx, em_clamp_mem hly⟩
  · intro x hx y hy
    simp only [em_clamp_eq hx, em_clamp_eq hy]

lemma em_param_cont {F : ℝ → ℝ → ℝ} {lx ly : ℝ} (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hF : ContinuousOn (fun p : ℝ × ℝ => F p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly)) :
    ContinuousOn (fun x => ∫ y in (0:ℝ)..ly, F x y) (Icc 0 lx) := by
  obtain ⟨G, hG, hGF⟩ := em_ext2 hlx hly hF
  have : Continuous fun x => ∫ y in (0:ℝ)..ly, G x y :=
    intervalIntegral.continuous_parametric_intervalIntegral_of_continuous' (f := G) hG 0 ly
  refine this.continuousOn.congr fun x hx => ?_
  refine intervalIntegral.integral_congr fun y hy => ?_
  rw [uIcc_of_le hly] at hy
  exact (hGF x hx y hy).symm

lemma em_slice {F : ℝ → ℝ → ℝ} {lx ly x : ℝ} (hx : x ∈ Icc 0 lx)
    (hF : ContinuousOn (fun p : ℝ × ℝ => F p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly)) :
    ContinuousOn (fun y => F x y) (Icc 0 ly) :=
  hF.comp (continuousOn_const.prodMk continuousOn_id) fun _ hy => ⟨hx, hy⟩

lemma em_slice' {F : ℝ → ℝ → ℝ} {lx ly y : ℝ} (hy : y ∈ Icc 0 ly)
    (hF : ContinuousOn (fun p : ℝ × ℝ => F p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly)) :
    ContinuousOn (fun x => F x y) (Icc 0 lx) :=
  hF.comp (continuousOn_id.prodMk continuousOn_const) fun _ hx => ⟨hx, hy⟩

lemma em_dint_add3 {X Y Z : ℝ → ℝ → ℝ} {lx ly : ℝ} (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hX : ContinuousOn (fun p : ℝ × ℝ => X p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly))
    (hY : ContinuousOn (fun p : ℝ × ℝ => Y p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly))
    (hZ : ContinuousOn (fun p : ℝ × ℝ => Z p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly)) :
    ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (X x y + Y x y + Z x y)
      = (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, X x y) + (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, Y x y)
        + ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, Z x y := by
  have h1 : ∀ x ∈ uIcc 0 lx, (∫ y in (0:ℝ)..ly, (X x y + Y x y + Z x y))
      = (∫ y in (0:ℝ)..ly, X x y) + (∫ y in (0:ℝ)..ly, Y x y) + ∫ y in (0:ℝ)..ly, Z x y := by
    intro x hx
    rw [uIcc_of_le hlx] at hx
    rw [intervalIntegral.integral_add, intervalIntegral.integral_add]
    · exact (em_slice hx hX).intervalIntegrable_of_Icc hly
    · exact (em_slice hx hY).intervalIntegrable_of_Icc hly
    · exact ((em_slice hx hX).add (em_slice hx hY)).intervalIntegrable_of_Icc hly
    · exact (em_slice hx hZ).intervalIntegrable_of_Icc hly
  rw [intervalIntegral.integral_congr h1, intervalIntegral.integral_add, intervalIntegral.integral_add]
  · exact (em_param_cont hlx hly hX).intervalIntegrable_of_Icc hlx
  · exact (em_param_cont hlx hly hY).intervalIntegrable_of_Icc hlx
  · exact ((em_param_cont hlx hly hX).add (em_param_cont hlx hly hY)).intervalIntegrable_of_Icc hlx
  · exact (em_param_cont hlx hly hZ).intervalIntegrable_of_Icc hlx

lemma em_int_nonpos {f : ℝ → ℝ} {L : ℝ} (hL : 0 ≤ L) (hf : ContinuousOn f (Icc 0 L))
    (h : ∀ x ∈ Icc 0 L, f x ≤ 0) : ∫ x in (0:ℝ)..L, f x ≤ 0 := by
  have := intervalIntegral.integral_mono_on hL (hf.intervalIntegrable_of_Icc hL)
    (intervalIntegrable_const (μ := volume) (c := (0:ℝ))) h
  simpa using this

lemma em_dint_nonpos {X : ℝ → ℝ → ℝ} {lx ly : ℝ} (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hX : ContinuousOn (fun p : ℝ × ℝ => X p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly))
    (h : ∀ x ∈ Icc 0 lx, ∫ y in (0:ℝ)..ly, X x y ≤ 0) :
    ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, X x y ≤ 0 :=
  em_int_nonpos hlx (em_param_cont hlx hly hX) h

lemma em_dint_swap {X : ℝ → ℝ → ℝ} {lx ly : ℝ} (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hX : ContinuousOn (fun p : ℝ × ℝ => X p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly)) :
    ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, X x y = ∫ y in (0:ℝ)..ly, ∫ x in (0:ℝ)..lx, X x y := by
  apply intervalIntegral_intervalIntegral_swap
  refine (hX.integrableOn_compact (isCompact_Icc.prod isCompact_Icc)).mono_set ?_
  rw [uIoc_of_le hlx, uIoc_of_le hly]
  exact prod_mono Ioc_subset_Icc_self Ioc_subset_Icc_self

lemma em_dint_nonpos' {X : ℝ → ℝ → ℝ} {lx ly : ℝ} (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hX : ContinuousOn (fun p : ℝ × ℝ => X p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly))
    (h : ∀ y ∈ Icc 0 ly, ∫ x in (0:ℝ)..lx, X x y ≤ 0) :
    ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, X x y ≤ 0 := by
  rw [em_dint_swap hlx hly hX]
  have hX' : ContinuousOn (fun p : ℝ × ℝ => X p.2 p.1) (Icc 0 ly ×ˢ Icc 0 lx) :=
    hX.comp continuous_swap.continuousOn fun p hp => ⟨hp.2, hp.1⟩
  exact em_dint_nonpos (X := fun y x => X x y) hly hlx hX' h

lemma em_eq_zero_of_integral {g : ℝ → ℝ} {a b : ℝ} (hab : a < b) (hg : ContinuousOn g (Icc a b))
    (h0 : ∀ x ∈ Icc a b, 0 ≤ g x) (hI : ∫ x in a..b, g x = 0) : ∀ x ∈ Icc a b, g x = 0 := by
  have hae := (intervalIntegral.integral_eq_zero_iff_of_le_of_nonneg_ae hab.le
    (ae_restrict_of_forall_mem measurableSet_Ioc fun x hx => h0 x (Ioc_subset_Icc_self hx))
    (hg.intervalIntegrable_of_Icc hab.le)).1 hI
  have hIoo : ∀ x ∈ Ioo a b, g x = 0 := by
    intro x hx
    by_contra hne
    have hpos : 0 < g x := lt_of_le_of_ne (h0 x (Ioo_subset_Icc_self hx)) (Ne.symm hne)
    have hopen : IsOpen (Ioo a b ∩ g ⁻¹' Ioi 0) :=
      (hg.mono Ioo_subset_Icc_self).isOpen_inter_preimage isOpen_Ioo isOpen_Ioi
    have hpm : 0 < volume (Ioo a b ∩ g ⁻¹' Ioi 0) := hopen.measure_pos volume ⟨x, hx, hpos⟩
    rw [Filter.EventuallyEq, ae_restrict_iff' measurableSet_Ioc, ae_iff] at hae
    refine hpm.ne' (measure_mono_null (fun y hy => ?_) hae)
    simp only [mem_ofPred_eq, not_imp, Pi.zero_apply]
    exact ⟨Ioo_subset_Ioc_self hy.1, (show 0 < g y from hy.2).ne'⟩
  have := Set.EqOn.of_subset_closure (f := g) (g := fun _ => (0:ℝ)) hIoo hg continuousOn_const
    Ioo_subset_Icc_self (by rw [closure_Ioo hab.ne])
  exact this

lemma em_ibp {u u' v v' : ℝ → ℝ} {L : ℝ} (hL : 0 ≤ L)
    (hu : ∀ x ∈ Icc 0 L, HasDerivWithinAt u (u' x) (Icc 0 L) x)
    (hv : ∀ x ∈ Icc 0 L, HasDerivWithinAt v (v' x) (Icc 0 L) x)
    (hu' : ContinuousOn u' (Icc 0 L)) (hv' : ContinuousOn v' (Icc 0 L))
    (h0 : v 0 = 0) (hL0 : v L = 0) :
    ∫ x in (0:ℝ)..L, u x * v' x = - ∫ x in (0:ℝ)..L, u' x * v x := by
  rw [← uIcc_of_le hL] at hu hv hu' hv'
  rw [intervalIntegral.integral_mul_deriv_eq_deriv_mul_of_hasDerivWithinAt hu hv
    hu'.intervalIntegrable hv'.intervalIntegrable, h0, hL0]
  ring

lemma em_iter2 {φ φ' φ'' : ℝ → ℝ} {L x : ℝ} (hx : x ∈ Ioo 0 L)
    (h1 : ∀ z ∈ Icc 0 L, HasDerivWithinAt φ (φ' z) (Icc 0 L) z)
    (h2 : ∀ z ∈ Icc 0 L, HasDerivWithinAt φ' (φ'' z) (Icc 0 L) z) :
    iteratedDeriv 2 φ x = φ'' x := by
  rw [iteratedDeriv_succ, iteratedDeriv_one]
  have : deriv φ =ᶠ[𝓝 x] φ' := by
    filter_upwards [Ioo_mem_nhds hx.1 hx.2] with z hz
    exact ((h1 z (Ioo_subset_Icc_self hz)).hasDerivAt (Icc_mem_nhds hz.1 hz.2)).deriv
  rw [this.deriv_eq]
  exact ((h2 x (Ioo_subset_Icc_self hx)).hasDerivAt (Icc_mem_nhds hx.1 hx.2)).deriv

lemma em_deriv_zero {φ : ℝ → ℝ} {L x d : ℝ} (hL : 0 < L) (hx : x ∈ Icc 0 L)
    (h0 : ∀ z ∈ Icc 0 L, φ z = 0) (hd : HasDerivWithinAt φ d (Icc 0 L) x) : d = 0 := by
  have h2 : HasDerivWithinAt φ 0 (Icc 0 L) x :=
    (hasDerivWithinAt_const x _ (0:ℝ)).congr (fun z hz => h0 z hz) (h0 x hx)
  exact (uniqueDiffOn_Icc hL x hx).eq_deriv _ hd h2

lemma em_param_deriv {F F' : ℝ → ℝ → ℝ} {a b c d : ℝ} (hcd : c ≤ d)
    (hF : Continuous fun p : ℝ × ℝ => F p.1 p.2) (hF' : Continuous fun p : ℝ × ℝ => F' p.1 p.2)
    (hD : ∀ s ∈ Ioo a b, ∀ y ∈ Icc c d, HasDerivAt (fun s => F s y) (F' s y) s)
    {t : ℝ} (ht : t ∈ Ioo a b) :
    HasDerivAt (fun s => ∫ y in c..d, F s y) (∫ y in c..d, F' t y) t := by
  obtain ⟨M, hM⟩ := (isCompact_Icc.prod isCompact_Icc : IsCompact (Icc a b ×ˢ Icc c d)).exists_bound_of_continuousOn
    hF'.continuousOn
  have hc : ∀ s, Continuous (F s) := fun s => hF.comp (continuous_const.prodMk continuous_id)
  have hc' : ∀ s, Continuous (F' s) := fun s => hF'.comp (continuous_const.prodMk continuous_id)
  refine (intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le (bound := fun _ => M)
    (Ioo_mem_nhds ht.1 ht.2) ?_ ?_ ?_ ?_ ?_ ?_).2
  · exact Filter.Eventually.of_forall fun s => (hc s).aestronglyMeasurable
  · exact (hc t).intervalIntegrable _ _
  · exact (hc' t).aestronglyMeasurable
  · refine Filter.Eventually.of_forall fun y hy s hs => ?_
    rw [uIoc_of_le hcd] at hy
    exact hM (s, y) ⟨Ioo_subset_Icc_self hs, Ioc_subset_Icc_self hy⟩
  · exact intervalIntegrable_const
  · refine Filter.Eventually.of_forall fun y hy s hs => ?_
    rw [uIoc_of_le hcd] at hy
    exact hD s hs y (Ioc_subset_Icc_self hy)

lemma em_param_deriv2 {F F' : ℝ → ℝ → ℝ → ℝ} {a b lx ly : ℝ} (hlx : 0 ≤ lx) (hly : 0 ≤ ly)
    (hF : Continuous fun p : ℝ × ℝ × ℝ => F p.1 p.2.1 p.2.2)
    (hF' : Continuous fun p : ℝ × ℝ × ℝ => F' p.1 p.2.1 p.2.2)
    (hD : ∀ s ∈ Ioo a b, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, HasDerivAt (fun s => F s x y) (F' s x y) s)
    {t : ℝ} (ht : t ∈ Ioo a b) :
    HasDerivAt (fun s => ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, F s x y)
      (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, F' t x y) t := by
  have hm : Continuous fun q : (ℝ × ℝ) × ℝ => ((q.1.1, q.1.2, q.2) : ℝ × ℝ × ℝ) := by fun_prop
  have hI : Continuous fun q : ℝ × ℝ => ∫ y in (0:ℝ)..ly, F q.1 q.2 y :=
    intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
      (f := fun (q : ℝ × ℝ) y => F q.1 q.2 y) (hF.comp hm) 0 ly
  have hI' : Continuous fun q : ℝ × ℝ => ∫ y in (0:ℝ)..ly, F' q.1 q.2 y :=
    intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
      (f := fun (q : ℝ × ℝ) y => F' q.1 q.2 y) (hF'.comp hm) 0 ly
  refine em_param_deriv (F := fun s x => ∫ y in (0:ℝ)..ly, F s x y)
    (F' := fun s x => ∫ y in (0:ℝ)..ly, F' s x y) hlx hI hI' (fun s hs x hx => ?_) ht
  have hx1 : Continuous fun q : ℝ × ℝ => ((q.1, x, q.2) : ℝ × ℝ × ℝ) := by fun_prop
  exact em_param_deriv (F := fun s y => F s x y) (F' := fun s y => F' s x y) hly
    (hF.comp hx1) (hF'.comp hx1) (fun s hs y hy => hD s hs x hx y hy) hs

lemma em_param_deriv2On {F F' : ℝ → ℝ → ℝ → ℝ} {a b lx ly : ℝ} (hab : a ≤ b) (hlx : 0 ≤ lx)
    (hly : 0 ≤ ly)
    (hF : ContinuousOn (fun p : ℝ × ℝ × ℝ => F p.1 p.2.1 p.2.2) (Icc a b ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hF' : ContinuousOn (fun p : ℝ × ℝ × ℝ => F' p.1 p.2.1 p.2.2) (Icc a b ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hD : ∀ s ∈ Ioo a b, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, HasDerivAt (fun s => F s x y) (F' s x y) s)
    {t : ℝ} (ht : t ∈ Ioo a b) :
    HasDerivAt (fun s => ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, F s x y)
      (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, F' t x y) t := by
  obtain ⟨G, hG, hGF⟩ := em_ext3 hab hlx hly hF
  obtain ⟨G', hG', hGF'⟩ := em_ext3 hab hlx hly hF'
  have hEq : ∀ s ∈ Icc a b, (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, G s x y)
      = ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, F s x y := by
    intro s hs
    refine intervalIntegral.integral_congr fun x hx => intervalIntegral.integral_congr fun y hy => ?_
    rw [uIcc_of_le hlx] at hx
    rw [uIcc_of_le hly] at hy
    exact hGF s hs x hx y hy
  have hEq' : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, G' t x y)
      = ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, F' t x y := by
    refine intervalIntegral.integral_congr fun x hx => intervalIntegral.integral_congr fun y hy => ?_
    rw [uIcc_of_le hlx] at hx
    rw [uIcc_of_le hly] at hy
    exact hGF' t (Ioo_subset_Icc_self ht) x hx y hy
  have key := em_param_deriv2 hlx hly hG hG' (fun s hs x hx y hy => ?_) ht
  · rw [hEq'] at key
    refine key.congr_of_eventuallyEq ?_
    filter_upwards [Ioo_mem_nhds ht.1 ht.2] with s hs
    exact (hEq s (Ioo_subset_Icc_self hs)).symm
  · rw [hGF' s (Ioo_subset_Icc_self hs) x hx y hy]
    refine (hD s hs x hx y hy).congr_of_eventuallyEq ?_
    filter_upwards [Ioo_mem_nhds hs.1 hs.2] with r hr
    exact hGF r (Ioo_subset_Icc_self hr) x hx y hy

lemma em_dint_contOn {F : ℝ → ℝ → ℝ → ℝ} {a b lx ly : ℝ} (hab : a ≤ b) (hlx : 0 ≤ lx)
    (hly : 0 ≤ ly)
    (hF : ContinuousOn (fun p : ℝ × ℝ × ℝ => F p.1 p.2.1 p.2.2) (Icc a b ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) :
    ContinuousOn (fun s => ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, F s x y) (Icc a b) := by
  obtain ⟨G, hG, hGF⟩ := em_ext3 hab hlx hly hF
  have hm : Continuous fun q : (ℝ × ℝ) × ℝ => ((q.1.1, q.1.2, q.2) : ℝ × ℝ × ℝ) := by fun_prop
  have hI : Continuous fun q : ℝ × ℝ => ∫ y in (0:ℝ)..ly, G q.1 q.2 y :=
    intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
      (f := fun (q : ℝ × ℝ) y => G q.1 q.2 y) (hG.comp hm) 0 ly
  have hII : Continuous fun s => ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, G s x y :=
    intervalIntegral.continuous_parametric_intervalIntegral_of_continuous'
      (f := fun s x => ∫ y in (0:ℝ)..ly, G s x y) hI 0 lx
  refine hII.continuousOn.congr fun s hs => ?_
  refine intervalIntegral.integral_congr fun x hx => intervalIntegral.integral_congr fun y hy => ?_
  rw [uIcc_of_le hlx] at hx
  rw [uIcc_of_le hly] at hy
  exact (hGF s hs x hx y hy).symm


lemma em_line {T lx ly : ℝ} {H : ℝ × ℝ × ℝ → ℝ} {H' : ℝ × ℝ × ℝ →L[ℝ] ℝ} {t x y : ℝ}
    (ht : t ∈ Icc 0 T) (hx : x ∈ Icc 0 lx) (hy : y ∈ Icc 0 ly)
    (h : HasFDerivWithinAt H H' (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y)) :
    HasDerivWithinAt (fun s => H (s, x, y)) (H' (1, 0, 0)) (Icc 0 T) t ∧
    HasDerivWithinAt (fun x' => H (t, x', y)) (H' (0, 1, 0)) (Icc 0 lx) x ∧
    HasDerivWithinAt (fun y' => H (t, x, y')) (H' (0, 0, 1)) (Icc 0 ly) y := by
  refine ⟨?_, ?_, ?_⟩
  · have hl : HasDerivWithinAt (fun s : ℝ => ((s, x, y) : ℝ × ℝ × ℝ)) ((1, 0, 0) : ℝ × ℝ × ℝ)
        (Icc 0 T) t :=
      (hasDerivWithinAt_id t _).prodMk
        ((hasDerivWithinAt_const t _ x).prodMk (hasDerivWithinAt_const t _ y))
    exact h.comp_hasDerivWithinAt t hl (by intro s hs; exact ⟨hs, hx, hy⟩)
  · have hl : HasDerivWithinAt (fun x' : ℝ => ((t, x', y) : ℝ × ℝ × ℝ)) ((0, 1, 0) : ℝ × ℝ × ℝ)
        (Icc 0 lx) x :=
      (hasDerivWithinAt_const x _ t).prodMk
        ((hasDerivWithinAt_id x _).prodMk (hasDerivWithinAt_const x _ y))
    exact h.comp_hasDerivWithinAt x hl (by intro s hs; exact ⟨ht, hs, hy⟩)
  · have hl : HasDerivWithinAt (fun y' : ℝ => ((t, x, y') : ℝ × ℝ × ℝ)) ((0, 0, 1) : ℝ × ℝ × ℝ)
        (Icc 0 ly) y :=
      (hasDerivWithinAt_const y _ t).prodMk
        ((hasDerivWithinAt_const y _ x).prodMk (hasDerivWithinAt_id y _))
    exact h.comp_hasDerivWithinAt y hl (by intro s hs; exact ⟨ht, hx, hs⟩)

lemma em_package {T lx ly : ℝ} (hT : 0 < T) (hlx : 0 < lx) (hly : 0 < ly) (g : ℝ → ℝ → ℝ → ℝ)
    (hg : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) :
    ∃ g1 g2 g3 g11 g22 g33 g12 g13 : ℝ → ℝ → ℝ → ℝ,
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g1 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g2 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g3 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g11 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g22 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g33 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g12 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ContinuousOn (fun p : ℝ × ℝ × ℝ => g13 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) ∧
      ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
        HasDerivWithinAt (fun s => g s x y) (g1 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => g t x' y) (g2 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun y' => g t x y') (g3 t x y) (Icc 0 ly) y ∧
        HasDerivWithinAt (fun s => g1 s x y) (g11 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => g2 t x' y) (g22 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun y' => g3 t x y') (g33 t x y) (Icc 0 ly) y ∧
        HasDerivWithinAt (fun s => g2 s x y) (g12 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => g1 t x' y) (g12 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun s => g3 s x y) (g13 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun y' => g1 t x y') (g13 t x y) (Icc 0 ly) y := by
  have uK : UniqueDiffOn ℝ (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) :=
    (uniqueDiffOn_Icc hT).prod ((uniqueDiffOn_Icc hlx).prod (uniqueDiffOn_Icc hly))
  have hD1 := hg.fderivWithin uK (m := 1) (by norm_num)
  have hDc := hD1.continuousOn
  have hDDc := hD1.continuousOn_fderivWithin uK le_rfl
  have hGd : ∀ p ∈ Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly, HasFDerivWithinAt
      (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
      (fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) p)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) p :=
    fun p hp => (hg.differentiableOn (by norm_num) p hp).hasFDerivWithinAt
  have hDv : ∀ v : ℝ × ℝ × ℝ, ∀ p ∈ Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly, HasFDerivWithinAt
      (fun q => fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) q v)
      ((ContinuousLinearMap.apply ℝ ℝ v).comp (fderivWithin ℝ (fderivWithin ℝ
        (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) p))
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) p :=
    fun v p hp => (ContinuousLinearMap.apply ℝ ℝ v).hasFDerivAt.comp_hasFDerivWithinAt p
      (hD1.differentiableOn one_ne_zero p hp).hasFDerivWithinAt
  have hsym : ∀ p ∈ Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly,
      IsSymmSndFDerivWithinAt ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) p := by
    intro p hp
    refine (hg p hp).isSymmSndFDerivWithinAt (by simp) uK ?_ hp
    rw [interior_prod_eq, interior_prod_eq, interior_Icc, interior_Icc, interior_Icc,
      closure_prod_eq, closure_prod_eq, closure_Ioo hT.ne, closure_Ioo hlx.ne, closure_Ioo hly.ne]
    exact hp
  refine ⟨fun t x y => fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y) (1, 0, 0),
    fun t x y => fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y) (0, 1, 0),
    fun t x y => fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y) (0, 0, 1),
    fun t x y => fderivWithin ℝ (fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y)
        (1, 0, 0) (1, 0, 0),
    fun t x y => fderivWithin ℝ (fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y)
        (0, 1, 0) (0, 1, 0),
    fun t x y => fderivWithin ℝ (fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y)
        (0, 0, 1) (0, 0, 1),
    fun t x y => fderivWithin ℝ (fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y)
        (1, 0, 0) (0, 1, 0),
    fun t x y => fderivWithin ℝ (fderivWithin ℝ (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2)
        (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly)) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) (t, x, y)
        (1, 0, 0) (0, 0, 1),
    hDc.clm_apply continuousOn_const, hDc.clm_apply continuousOn_const,
    hDc.clm_apply continuousOn_const,
    (hDDc.clm_apply continuousOn_const).clm_apply continuousOn_const,
    (hDDc.clm_apply continuousOn_const).clm_apply continuousOn_const,
    (hDDc.clm_apply continuousOn_const).clm_apply continuousOn_const,
    (hDDc.clm_apply continuousOn_const).clm_apply continuousOn_const,
    (hDDc.clm_apply continuousOn_const).clm_apply continuousOn_const, ?_⟩
  intro t ht x hx y hy
  have hp : ((t, x, y) : ℝ × ℝ × ℝ) ∈ Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly := ⟨ht, hx, hy⟩
  have L0 := em_line ht hx hy (hGd _ hp)
  have L1 := em_line ht hx hy (hDv (1, 0, 0) _ hp)
  have L2 := em_line ht hx hy (hDv (0, 1, 0) _ hp)
  have L3 := em_line ht hx hy (hDv (0, 0, 1) _ hp)
  simp only [ContinuousLinearMap.comp_apply, ContinuousLinearMap.apply_apply] at L1 L2 L3
  have s12 := hsym _ hp (1, 0, 0) (0, 1, 0)
  have s13 := hsym _ hp (1, 0, 0) (0, 0, 1)
  refine ⟨L0.1, L0.2.1, L0.2.2, L1.1, L2.2.1, L3.2.2, L2.1, ?_, L3.1, ?_⟩
  · beta_reduce; rw [s12]; exact L1.2.1
  · beta_reduce; rw [s13]; exact L1.2.2

lemma em_cx {F : ℝ → ℝ → ℝ → ℝ} {T lx ly t y : ℝ}
    (hF : ContinuousOn (fun p : ℝ × ℝ × ℝ => F p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (ht : t ∈ Icc 0 T) (hy : y ∈ Icc 0 ly) : ContinuousOn (fun x => F t x y) (Icc 0 lx) :=
  hF.comp (continuousOn_const.prodMk (continuousOn_id.prodMk continuousOn_const))
    (by intro x hx; exact ⟨ht, hx, hy⟩)

lemma em_cy {F : ℝ → ℝ → ℝ → ℝ} {T lx ly t x : ℝ}
    (hF : ContinuousOn (fun p : ℝ × ℝ × ℝ => F p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (ht : t ∈ Icc 0 T) (hx : x ∈ Icc 0 lx) : ContinuousOn (fun y => F t x y) (Icc 0 ly) :=
  hF.comp (continuousOn_const.prodMk (continuousOn_const.prodMk continuousOn_id))
    (by intro y hy; exact ⟨ht, hx, hy⟩)

lemma em_cxy {F : ℝ → ℝ → ℝ → ℝ} {T lx ly t : ℝ}
    (hF : ContinuousOn (fun p : ℝ × ℝ × ℝ => F p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (ht : t ∈ Icc 0 T) :
    ContinuousOn (fun p : ℝ × ℝ => F t p.1 p.2) (Icc 0 lx ×ˢ Icc 0 ly) :=
  hF.comp (continuousOn_const.prodMk continuousOn_id) (by intro p hp; exact ⟨ht, hp⟩)

lemma em_closure_eq {T lx ly : ℝ} (hT : 0 < T) (hlx : 0 < lx) (hly : 0 < ly)
    {f g : ℝ → ℝ → ℝ → ℝ}
    (hf : ContinuousOn (fun p : ℝ × ℝ × ℝ => f p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hg : ContinuousOn (fun p : ℝ × ℝ × ℝ => g p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (h : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly, f t x y = g t x y) :
    ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, f t x y = g t x y := by
  intro t ht x hx y hy
  have := Set.EqOn.of_subset_closure (s := Ioo 0 T ×ˢ Ioo 0 lx ×ˢ Ioo 0 ly)
    (fun p hp => h p.1 hp.1 p.2.1 hp.2.1 p.2.2 hp.2.2) hf hg
    (prod_mono Ioo_subset_Icc_self (prod_mono Ioo_subset_Icc_self Ioo_subset_Icc_self))
    (by rw [closure_prod_eq, closure_prod_eq, closure_Ioo hT.ne, closure_Ioo hlx.ne,
      closure_Ioo hly.ne])
    (show ((t, x, y) : ℝ × ℝ × ℝ) ∈ Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly from ⟨ht, hx, hy⟩)
  exact this

lemma em_interior {T lx ly : ℝ} {g g1 g2 g3 g11 g22 g33 : ℝ → ℝ → ℝ → ℝ}
    (hd : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      HasDerivWithinAt (fun s => g s x y) (g1 t x y) (Icc 0 T) t ∧
      HasDerivWithinAt (fun x' => g t x' y) (g2 t x y) (Icc 0 lx) x ∧
      HasDerivWithinAt (fun y' => g t x y') (g3 t x y) (Icc 0 ly) y ∧
      HasDerivWithinAt (fun s => g1 s x y) (g11 t x y) (Icc 0 T) t ∧
      HasDerivWithinAt (fun x' => g2 t x' y) (g22 t x y) (Icc 0 lx) x ∧
      HasDerivWithinAt (fun y' => g3 t x y') (g33 t x y) (Icc 0 ly) y)
    {t x y : ℝ} (ht : t ∈ Ioo 0 T) (hx : x ∈ Ioo 0 lx) (hy : y ∈ Ioo 0 ly) :
    deriv (fun s => g s x y) t = g1 t x y ∧
    iteratedDeriv 2 (fun s => g s x y) t = g11 t x y ∧
    iteratedDeriv 2 (fun x' => g t x' y) x = g22 t x y ∧
    iteratedDeriv 2 (fun y' => g t x y') y = g33 t x y := by
  have ht' := Ioo_subset_Icc_self ht
  have hx' := Ioo_subset_Icc_self hx
  have hy' := Ioo_subset_Icc_self hy
  refine ⟨((hd t ht' x hx' y hy').1.hasDerivAt (Icc_mem_nhds ht.1 ht.2)).deriv, ?_, ?_, ?_⟩
  · exact em_iter2 ht (fun z hz => (hd z hz x hx' y hy').1) (fun z hz => (hd z hz x hx' y hy').2.2.2.1)
  · exact em_iter2 hx (fun z hz => (hd t ht' z hz y hy').2.1)
      (fun z hz => (hd t ht' z hz y hy').2.2.2.2.1)
  · exact em_iter2 hy (fun z hz => (hd t ht' x hx' z hz).2.2.1)
      (fun z hz => (hd t ht' x hx' z hz).2.2.2.2.2)

lemma em_gronwall_w {κ a T lx ly : ℝ} (hκ : 0 < κ) (hT : 0 < T) (hlx : 0 < lx) (hly : 0 < ly)
    {w w1 w2 w3 w22 w33 : ℝ → ℝ → ℝ → ℝ}
    (cw : ContinuousOn (fun p : ℝ × ℝ × ℝ => w p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw1 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w1 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw2 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w2 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw3 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w3 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw22 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w22 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw33 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w33 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (dw : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      HasDerivWithinAt (fun s => w s x y) (w1 t x y) (Icc 0 T) t ∧
      HasDerivWithinAt (fun x' => w t x' y) (w2 t x y) (Icc 0 lx) x ∧
      HasDerivWithinAt (fun y' => w t x y') (w3 t x y) (Icc 0 ly) y ∧
      HasDerivWithinAt (fun x' => w2 t x' y) (w22 t x y) (Icc 0 lx) x ∧
      HasDerivWithinAt (fun y' => w3 t x y') (w33 t x y) (Icc 0 ly) y)
    (heat : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      w1 t x y = κ * (w22 t x y + w33 t x y) + a * w t x y)
    (edge : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      (x = 0 ∨ x = lx ∨ y = 0 ∨ y = ly) → w t x y = 0) :
    ∀ t ∈ Icc 0 T, ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (w t x y) ^ 2
      ≤ (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (w 0 x y) ^ 2) * exp (2 * a * t) := by
  have heatK := em_closure_eq hT hlx hly (f := w1)
    (g := fun t x y => κ * (w22 t x y + w33 t x y) + a * w t x y) cw1
    ((continuousOn_const.mul (cw22.add cw33)).add (continuousOn_const.mul cw)) heat
  set E : ℝ → ℝ := fun s => ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (w s x y) ^ 2 with hE
  have hEc : ContinuousOn E (Icc 0 T) :=
    em_dint_contOn (F := fun s x y => (w s x y) ^ 2) hT.le hlx.le hly.le (cw.pow 2)
  have hEd : ∀ s ∈ Ioo 0 T, HasDerivAt E
      (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, 2 * w s x y * w1 s x y) s := by
    intro s hs
    refine em_param_deriv2On (F := fun s x y => (w s x y) ^ 2)
      (F' := fun s x y => 2 * w s x y * w1 s x y) hT.le hlx.le hly.le (cw.pow 2)
      ((continuousOn_const.mul cw).mul cw1) (fun r hr x hx y hy => ?_) hs
    have := ((dw r (Ioo_subset_Icc_self hr) x hx y hy).1.hasDerivAt (Icc_mem_nhds hr.1 hr.2)).pow 2
    convert this using 1
    push_cast
    ring
  have hEle : ∀ s ∈ Ioo 0 T,
      (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, 2 * w s x y * w1 s x y) ≤ 2 * a * E s := by
    intro s hs
    have hs' := Ioo_subset_Icc_self hs
    have e1 : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, 2 * w s x y * w1 s x y)
        = ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (2 * κ * (w22 s x y * w s x y)
          + 2 * κ * (w33 s x y * w s x y) + 2 * a * (w s x y) ^ 2) := by
      refine intervalIntegral.integral_congr fun x hx =>
        intervalIntegral.integral_congr fun y hy => ?_
      rw [uIcc_of_le hlx.le] at hx
      rw [uIcc_of_le hly.le] at hy
      simp only [heatK s hs' x hx y hy]
      ring
    have hX := em_cxy (F := fun s x y => 2 * κ * (w22 s x y * w s x y))
      (continuousOn_const.mul (cw22.mul cw)) hs'
    have hY := em_cxy (F := fun s x y => 2 * κ * (w33 s x y * w s x y))
      (continuousOn_const.mul (cw33.mul cw)) hs'
    have hZ := em_cxy (F := fun s x y => 2 * a * (w s x y) ^ 2)
      (continuousOn_const.mul (cw.pow 2)) hs'
    rw [e1, em_dint_add3 hlx.le hly.le hX hY hZ]
    have hXn : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, 2 * κ * (w22 s x y * w s x y)) ≤ 0 := by
      apply em_dint_nonpos' hlx.le hly.le hX
      intro y hy
      rw [intervalIntegral.integral_const_mul]
      have hibp := em_ibp hlx.le (u := fun x => w2 s x y) (u' := fun x => w22 s x y)
        (v := fun x => w s x y) (v' := fun x => w2 s x y)
        (fun x hx => (dw s hs' x hx y hy).2.2.2.1) (fun x hx => (dw s hs' x hx y hy).2.1)
        (em_cx cw22 hs' hy) (em_cx cw2 hs' hy)
        (edge s hs' 0 ⟨le_rfl, hlx.le⟩ y hy (Or.inl rfl))
        (edge s hs' lx ⟨hlx.le, le_rfl⟩ y hy (Or.inr (Or.inl rfl)))
      have hsq : 0 ≤ ∫ x in (0:ℝ)..lx, w2 s x y * w2 s x y :=
        intervalIntegral.integral_nonneg hlx.le (fun x _ => mul_self_nonneg _)
      have : (∫ x in (0:ℝ)..lx, w22 s x y * w s x y) ≤ 0 := by linarith
      exact mul_nonpos_of_nonneg_of_nonpos (by positivity) this
    have hYn : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, 2 * κ * (w33 s x y * w s x y)) ≤ 0 := by
      apply em_dint_nonpos hlx.le hly.le hY
      intro x hx
      rw [intervalIntegral.integral_const_mul]
      have hibp := em_ibp hly.le (u := fun y => w3 s x y) (u' := fun y => w33 s x y)
        (v := fun y => w s x y) (v' := fun y => w3 s x y)
        (fun y hy => (dw s hs' x hx y hy).2.2.2.2) (fun y hy => (dw s hs' x hx y hy).2.2.1)
        (em_cy cw33 hs' hx) (em_cy cw3 hs' hx)
        (edge s hs' x hx 0 ⟨le_rfl, hly.le⟩ (Or.inr (Or.inr (Or.inl rfl))))
        (edge s hs' x hx ly ⟨hly.le, le_rfl⟩ (Or.inr (Or.inr (Or.inr rfl))))
      have hsq : 0 ≤ ∫ y in (0:ℝ)..ly, w3 s x y * w3 s x y :=
        intervalIntegral.integral_nonneg hly.le (fun y _ => mul_self_nonneg _)
      have : (∫ y in (0:ℝ)..ly, w33 s x y * w s x y) ≤ 0 := by linarith
      exact mul_nonpos_of_nonneg_of_nonpos (by positivity) this
    have hZe : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, 2 * a * (w s x y) ^ 2) = 2 * a * E s := by
      simp only [hE, intervalIntegral.integral_const_mul]
    linarith
  have hexp : ∀ s, HasDerivAt (fun s => exp (-(2 * a * s))) (exp (-(2 * a * s)) * (-(2 * a))) s := by
    intro s
    have h1 : HasDerivAt (fun s : ℝ => -(2 * a * s)) (-(2 * a)) s := by
      have := (hasDerivAt_id s).const_mul (-(2 * a))
      convert this using 1
      · funext r
        simp only [id]
        ring
      · ring
    exact h1.exp
  have hφ : AntitoneOn (fun s => E s * exp (-(2 * a * s))) (Icc 0 T) := by
    apply antitoneOn_of_deriv_nonpos (convex_Icc 0 T)
    · exact hEc.mul (by fun_prop : Continuous fun s : ℝ => exp (-(2 * a * s))).continuousOn
    · rw [interior_Icc]
      intro s hs
      exact ((hEd s hs).mul (hexp s)).differentiableAt.differentiableWithinAt
    · rw [interior_Icc]
      intro s hs
      have hd : HasDerivAt (fun s => E s * exp (-(2 * a * s)))
          ((∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, 2 * w s x y * w1 s x y) * exp (-(2 * a * s))
            + E s * (exp (-(2 * a * s)) * (-(2 * a)))) s := (hEd s hs).mul (hexp s)
      rw [hd.deriv]
      have h1 := hEle s hs
      have h2 := exp_pos (-(2 * a * s))
      nlinarith
  intro t ht
  have h := hφ ⟨le_rfl, hT.le⟩ ht ht.1
  simp only [mul_zero, neg_zero, exp_zero, mul_one] at h
  have hEt : E t = E t * exp (-(2 * a * t)) * exp (2 * a * t) := by
    rw [mul_assoc, ← exp_add]
    simp
  show E t ≤ E 0 * exp (2 * a * t)
  rw [hEt]
  exact mul_le_mul_of_nonneg_right h (exp_pos _).le

lemma em_six {T lx ly : ℝ} {g g1 g2 g3 g11 g22 g33 g12 g13 : ℝ → ℝ → ℝ → ℝ}
    (hd : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
        HasDerivWithinAt (fun s => g s x y) (g1 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => g t x' y) (g2 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun y' => g t x y') (g3 t x y) (Icc 0 ly) y ∧
        HasDerivWithinAt (fun s => g1 s x y) (g11 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => g2 t x' y) (g22 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun y' => g3 t x y') (g33 t x y) (Icc 0 ly) y ∧
        HasDerivWithinAt (fun s => g2 s x y) (g12 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => g1 t x' y) (g12 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun s => g3 s x y) (g13 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun y' => g1 t x y') (g13 t x y) (Icc 0 ly) y) :
    ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      HasDerivWithinAt (fun s => g s x y) (g1 t x y) (Icc 0 T) t ∧
      HasDerivWithinAt (fun x' => g t x' y) (g2 t x y) (Icc 0 lx) x ∧
      HasDerivWithinAt (fun y' => g t x y') (g3 t x y) (Icc 0 ly) y ∧
      HasDerivWithinAt (fun s => g1 s x y) (g11 t x y) (Icc 0 T) t ∧
      HasDerivWithinAt (fun x' => g2 t x' y) (g22 t x y) (Icc 0 lx) x ∧
      HasDerivWithinAt (fun y' => g3 t x y') (g33 t x y) (Icc 0 ly) y := by
  intro t ht x hx y hy
  obtain ⟨a1, a2, a3, a4, a5, a6, -⟩ := hd t ht x hx y hy
  exact ⟨a1, a2, a3, a4, a5, a6⟩

lemma em_gronwall_uv (κ a T lx ly : ℝ) (hκ : 0 < κ) (hlx : 0 < lx) (hly : 0 < ly)
    (u v : ℝ → ℝ → ℝ → ℝ)
    (hu : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => u p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hv : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => v p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hu_heat : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      deriv (fun s => u s x y) t
        = κ * (iteratedDeriv 2 (fun x' => u t x' y) x + iteratedDeriv 2 (fun y' => u t x y') y)
          + a * u t x y)
    (hv_heat : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      deriv (fun s => v s x y) t
        = κ * (iteratedDeriv 2 (fun x' => v t x' y) x + iteratedDeriv 2 (fun y' => v t x y') y)
          + a * v t x y)
    (h_edge : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      (x = 0 ∨ x = lx ∨ y = 0 ∨ y = ly) → u t x y = v t x y) :
    ∀ t ∈ Icc 0 T,
      (1 / 2) * ∫ x in (0 : ℝ)..lx, ∫ y in (0 : ℝ)..ly, (u t x y - v t x y) ^ 2
        ≤ ((1 / 2) * ∫ x in (0 : ℝ)..lx, ∫ y in (0 : ℝ)..ly, (u 0 x y - v 0 x y) ^ 2)
          * exp (2 * a * t) := by
  intro t ht
  rcases eq_or_lt_of_le (ht.1.trans ht.2) with hT0 | hT
  · have : t = 0 := le_antisymm (hT0 ▸ ht.2) ht.1
    subst this
    simp
  obtain ⟨u1, u2, u3, u11, u22, u33, u12, u13, cu1, cu2, cu3, -, cu22, cu33, -, -, du⟩ :=
    em_package hT hlx hly u hu
  obtain ⟨v1, v2, v3, v11, v22, v33, v12, v13, cv1, cv2, cv3, -, cv22, cv33, -, -, dv⟩ :=
    em_package hT hlx hly v hv
  have key := em_gronwall_w (κ := κ) (a := a) hκ hT hlx hly
    (w := fun s x y => u s x y - v s x y) (w1 := fun s x y => u1 s x y - v1 s x y)
    (w2 := fun s x y => u2 s x y - v2 s x y) (w3 := fun s x y => u3 s x y - v3 s x y)
    (w22 := fun s x y => u22 s x y - v22 s x y) (w33 := fun s x y => u33 s x y - v33 s x y)
    (hu.continuousOn.sub hv.continuousOn) (cu1.sub cv1) (cu2.sub cv2) (cu3.sub cv3)
    (cu22.sub cv22) (cu33.sub cv33)
    (fun t ht x hx y hy => by
      obtain ⟨a1, a2, a3, -, a5, a6, -⟩ := du t ht x hx y hy
      obtain ⟨b1, b2, b3, -, b5, b6, -⟩ := dv t ht x hx y hy
      exact ⟨a1.sub b1, a2.sub b2, a3.sub b3, a5.sub b5, a6.sub b6⟩)
    (fun t ht x hx y hy => by
      obtain ⟨eu1, -, eu2, eu3⟩ := em_interior (em_six du) ht hx hy
      obtain ⟨ev1, -, ev2, ev3⟩ := em_interior (em_six dv) ht hx hy
      have h1 := hu_heat t ht x hx y hy
      have h2 := hv_heat t ht x hx y hy
      rw [eu1, eu2, eu3] at h1
      rw [ev1, ev2, ev3] at h2
      linear_combination h1 - h2)
    (fun t ht x hx y hy hxy => sub_eq_zero.2 (h_edge t ht x hx y hy hxy)) t ht
  rw [mul_assoc]
  exact mul_le_mul_of_nonneg_left key (by norm_num)

lemma em_wave_w {c b T lx ly : ℝ} (hc : 0 < c) (hb : 0 ≤ b) (hT : 0 < T) (hlx : 0 < lx)
    (hly : 0 < ly) {w w1 w2 w3 w11 w22 w33 w12 w13 : ℝ → ℝ → ℝ → ℝ}
    (cw1 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w1 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw2 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w2 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw3 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w3 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw11 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w11 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw22 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w22 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw33 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w33 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw12 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w12 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (cw13 : ContinuousOn (fun p : ℝ × ℝ × ℝ => w13 p.1 p.2.1 p.2.2) (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (dw : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
        HasDerivWithinAt (fun s => w s x y) (w1 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => w t x' y) (w2 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun y' => w t x y') (w3 t x y) (Icc 0 ly) y ∧
        HasDerivWithinAt (fun s => w1 s x y) (w11 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => w2 t x' y) (w22 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun y' => w3 t x y') (w33 t x y) (Icc 0 ly) y ∧
        HasDerivWithinAt (fun s => w2 s x y) (w12 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun x' => w1 t x' y) (w12 t x y) (Icc 0 lx) x ∧
        HasDerivWithinAt (fun s => w3 s x y) (w13 t x y) (Icc 0 T) t ∧
        HasDerivWithinAt (fun y' => w1 t x y') (w13 t x y) (Icc 0 ly) y)
    (wave : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      w11 t x y + b * w1 t x y = c ^ 2 * (w22 t x y + w33 t x y))
    (edge : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      (x = 0 ∨ x = lx ∨ y = 0 ∨ y = ly) → w t x y = 0)
    (shape : ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, w 0 x y = 0)
    (speed : ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, w1 0 x y = 0) :
    ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, w t x y = 0 := by
  have hT0 : (0:ℝ) ∈ Icc 0 T := ⟨le_rfl, hT.le⟩
  have waveK := em_closure_eq hT hlx hly (f := w11)
    (g := fun t x y => c ^ 2 * (w22 t x y + w33 t x y) - b * w1 t x y) cw11
    ((continuousOn_const.mul (cw22.add cw33)).sub (continuousOn_const.mul cw1))
    (fun t ht x hx y hy => by rw [← wave t ht x hx y hy]; ring)
  have e1x0 : ∀ s ∈ Icc 0 T, ∀ y ∈ Icc 0 ly, w1 s 0 y = 0 := fun s hs y hy =>
    em_deriv_zero hT hs (fun z hz => edge z hz 0 ⟨le_rfl, hlx.le⟩ y hy (Or.inl rfl))
      (dw s hs 0 ⟨le_rfl, hlx.le⟩ y hy).1
  have e1xl : ∀ s ∈ Icc 0 T, ∀ y ∈ Icc 0 ly, w1 s lx y = 0 := fun s hs y hy =>
    em_deriv_zero hT hs (fun z hz => edge z hz lx ⟨hlx.le, le_rfl⟩ y hy (Or.inr (Or.inl rfl)))
      (dw s hs lx ⟨hlx.le, le_rfl⟩ y hy).1
  have e1y0 : ∀ s ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, w1 s x 0 = 0 := fun s hs x hx =>
    em_deriv_zero hT hs
      (fun z hz => edge z hz x hx 0 ⟨le_rfl, hly.le⟩ (Or.inr (Or.inr (Or.inl rfl))))
      (dw s hs x hx 0 ⟨le_rfl, hly.le⟩).1
  have e1yl : ∀ s ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, w1 s x ly = 0 := fun s hs x hx =>
    em_deriv_zero hT hs
      (fun z hz => edge z hz x hx ly ⟨hly.le, le_rfl⟩ (Or.inr (Or.inr (Or.inr rfl))))
      (dw s hs x hx ly ⟨hly.le, le_rfl⟩).1
  have i2 : ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, w2 0 x y = 0 := fun x hx y hy =>
    em_deriv_zero hlx hx (fun z hz => shape z hz y hy) (dw 0 hT0 x hx y hy).2.1
  have i3 : ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, w3 0 x y = 0 := fun x hx y hy =>
    em_deriv_zero hly hy (fun z hz => shape x hx z hz) (dw 0 hT0 x hx y hy).2.2.1
  have cen : ContinuousOn (fun p : ℝ × ℝ × ℝ => (w1 p.1 p.2.1 p.2.2) ^ 2
      + c ^ 2 * ((w2 p.1 p.2.1 p.2.2) ^ 2 + (w3 p.1 p.2.1 p.2.2) ^ 2))
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly) :=
    (cw1.pow 2).add (continuousOn_const.mul ((cw2.pow 2).add (cw3.pow 2)))
  set E : ℝ → ℝ := fun s => ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
    ((w1 s x y) ^ 2 + c ^ 2 * ((w2 s x y) ^ 2 + (w3 s x y) ^ 2)) with hE
  have hEc : ContinuousOn E (Icc 0 T) :=
    em_dint_contOn (F := fun s x y => (w1 s x y) ^ 2 + c ^ 2 * ((w2 s x y) ^ 2 + (w3 s x y) ^ 2))
      hT.le hlx.le hly.le cen
  have hEd : ∀ s ∈ Ioo 0 T, HasDerivAt E (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
      (2 * w1 s x y * w11 s x y + c ^ 2 * (2 * w2 s x y * w12 s x y + 2 * w3 s x y * w13 s x y))) s := by
    intro s hs
    refine em_param_deriv2On
      (F := fun s x y => (w1 s x y) ^ 2 + c ^ 2 * ((w2 s x y) ^ 2 + (w3 s x y) ^ 2))
      (F' := fun s x y => 2 * w1 s x y * w11 s x y
        + c ^ 2 * (2 * w2 s x y * w12 s x y + 2 * w3 s x y * w13 s x y))
      hT.le hlx.le hly.le cen
      (((continuousOn_const.mul cw1).mul cw11).add (continuousOn_const.mul
        (((continuousOn_const.mul cw2).mul cw12).add ((continuousOn_const.mul cw3).mul cw13))))
      (fun r hr x hx y hy => ?_) hs
    have hr' := Ioo_subset_Icc_self hr
    have hn := Icc_mem_nhds hr.1 hr.2
    obtain ⟨-, -, -, a4, -, -, a7, -, a9, -⟩ := dw r hr' x hx y hy
    have := ((a4.hasDerivAt hn).pow 2).add
      ((((a7.hasDerivAt hn).pow 2).add ((a9.hasDerivAt hn).pow 2)).const_mul (c ^ 2))
    convert this using 1
    push_cast
    ring
  have hEle : ∀ s ∈ Ioo 0 T, (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
      (2 * w1 s x y * w11 s x y + c ^ 2 * (2 * w2 s x y * w12 s x y + 2 * w3 s x y * w13 s x y)))
      ≤ 0 := by
    intro s hs
    have hs' := Ioo_subset_Icc_self hs
    have e1 : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
        (2 * w1 s x y * w11 s x y + c ^ 2 * (2 * w2 s x y * w12 s x y + 2 * w3 s x y * w13 s x y)))
        = ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
          (2 * c ^ 2 * (w2 s x y * w12 s x y + w22 s x y * w1 s x y)
          + 2 * c ^ 2 * (w3 s x y * w13 s x y + w33 s x y * w1 s x y)
          + (-2 * b) * (w1 s x y) ^ 2) := by
      refine intervalIntegral.integral_congr fun x hx =>
        intervalIntegral.integral_congr fun y hy => ?_
      rw [uIcc_of_le hlx.le] at hx
      rw [uIcc_of_le hly.le] at hy
      simp only [waveK s hs' x hx y hy]
      ring
    have hX := em_cxy (F := fun s x y => 2 * c ^ 2 * (w2 s x y * w12 s x y + w22 s x y * w1 s x y))
      (continuousOn_const.mul ((cw2.mul cw12).add (cw22.mul cw1))) hs'
    have hY := em_cxy (F := fun s x y => 2 * c ^ 2 * (w3 s x y * w13 s x y + w33 s x y * w1 s x y))
      (continuousOn_const.mul ((cw3.mul cw13).add (cw33.mul cw1))) hs'
    have hZ := em_cxy (F := fun s x y => (-2 * b) * (w1 s x y) ^ 2)
      (continuousOn_const.mul (cw1.pow 2)) hs'
    rw [e1, em_dint_add3 hlx.le hly.le hX hY hZ]
    have hXn : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
        2 * c ^ 2 * (w2 s x y * w12 s x y + w22 s x y * w1 s x y)) ≤ 0 := by
      apply em_dint_nonpos' hlx.le hly.le hX
      intro y hy
      rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_add
        (f := fun x => w2 s x y * w12 s x y) (g := fun x => w22 s x y * w1 s x y)
        (((em_cx cw2 hs' hy).mul (em_cx cw12 hs' hy)).intervalIntegrable_of_Icc hlx.le)
        (((em_cx cw22 hs' hy).mul (em_cx cw1 hs' hy)).intervalIntegrable_of_Icc hlx.le)]
      have hibp := em_ibp hlx.le (u := fun x => w2 s x y) (u' := fun x => w22 s x y)
        (v := fun x => w1 s x y) (v' := fun x => w12 s x y)
        (fun x hx => (dw s hs' x hx y hy).2.2.2.2.1)
        (fun x hx => (dw s hs' x hx y hy).2.2.2.2.2.2.2.1)
        (em_cx cw22 hs' hy) (em_cx cw12 hs' hy) (e1x0 s hs' y hy) (e1xl s hs' y hy)
      rw [hibp]
      simp
    have hYn : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
        2 * c ^ 2 * (w3 s x y * w13 s x y + w33 s x y * w1 s x y)) ≤ 0 := by
      apply em_dint_nonpos hlx.le hly.le hY
      intro x hx
      rw [intervalIntegral.integral_const_mul, intervalIntegral.integral_add
        (f := fun y => w3 s x y * w13 s x y) (g := fun y => w33 s x y * w1 s x y)
        (((em_cy cw3 hs' hx).mul (em_cy cw13 hs' hx)).intervalIntegrable_of_Icc hly.le)
        (((em_cy cw33 hs' hx).mul (em_cy cw1 hs' hx)).intervalIntegrable_of_Icc hly.le)]
      have hibp := em_ibp hly.le (u := fun y => w3 s x y) (u' := fun y => w33 s x y)
        (v := fun y => w1 s x y) (v' := fun y => w13 s x y)
        (fun y hy => (dw s hs' x hx y hy).2.2.2.2.2.1)
        (fun y hy => (dw s hs' x hx y hy).2.2.2.2.2.2.2.2.2)
        (em_cy cw33 hs' hx) (em_cy cw13 hs' hx) (e1y0 s hs' x hx) (e1yl s hs' x hx)
      rw [hibp]
      simp
    have hZn : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (-2 * b) * (w1 s x y) ^ 2) ≤ 0 :=
      em_dint_nonpos hlx.le hly.le hZ fun x hx => em_int_nonpos hly.le
        (em_slice (F := fun x y => (-2 * b) * (w1 s x y) ^ 2) hx hZ)
        fun y _ => mul_nonpos_of_nonpos_of_nonneg (by linarith) (sq_nonneg _)
    linarith
  have hanti : AntitoneOn E (Icc 0 T) := by
    apply antitoneOn_of_deriv_nonpos (convex_Icc 0 T) hEc
    · rw [interior_Icc]
      intro s hs
      exact (hEd s hs).differentiableAt.differentiableWithinAt
    · rw [interior_Icc]
      intro s hs
      rw [(hEd s hs).deriv]
      exact hEle s hs
  have hE0 : E 0 = 0 := by
    show (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly,
      ((w1 0 x y) ^ 2 + c ^ 2 * ((w2 0 x y) ^ 2 + (w3 0 x y) ^ 2))) = 0
    rw [intervalIntegral.integral_congr (g := fun _ => (0:ℝ)) ?_]
    · simp
    intro x hx
    rw [uIcc_of_le hlx.le] at hx
    simp only
    rw [intervalIntegral.integral_congr (g := fun _ => (0:ℝ)) ?_]
    · simp
    intro y hy
    rw [uIcc_of_le hly.le] at hy
    simp [speed x hx y hy, i2 x hx y hy, i3 x hx y hy]
  have hw1 : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, w1 t x y = 0 := by
    intro t ht x hx y hy
    have cxy := em_cxy
      (F := fun s x y => (w1 s x y) ^ 2 + c ^ 2 * ((w2 s x y) ^ 2 + (w3 s x y) ^ 2)) cen ht
    have hnn : 0 ≤ E t := intervalIntegral.integral_nonneg hlx.le fun x _ =>
      intervalIntegral.integral_nonneg hly.le fun y _ => by positivity
    have hEt : E t = 0 := le_antisymm (by have := hanti hT0 ht ht.1; rwa [hE0] at this) hnn
    have hI := em_eq_zero_of_integral hlx
      (em_param_cont (F := fun x y => (w1 t x y) ^ 2 + c ^ 2 * ((w2 t x y) ^ 2 + (w3 t x y) ^ 2))
        hlx.le hly.le cxy)
      (fun x _ => intervalIntegral.integral_nonneg hly.le fun y _ => by positivity) hEt x hx
    have hp := em_eq_zero_of_integral hly
      (em_slice (F := fun x y => (w1 t x y) ^ 2 + c ^ 2 * ((w2 t x y) ^ 2 + (w3 t x y) ^ 2))
        hx cxy) (fun y _ => by positivity) hI y hy
    have h2 : (w1 t x y) ^ 2 = 0 := by
      have := mul_nonneg (sq_nonneg c) (add_nonneg (sq_nonneg (w2 t x y)) (sq_nonneg (w3 t x y)))
      nlinarith [sq_nonneg (w1 t x y)]
    exact pow_eq_zero_iff two_ne_zero |>.1 h2
  intro t ht x hx y hy
  have hconst := constant_of_derivWithin_zero (f := fun s => w s x y) (a := 0) (b := T)
    (fun s hs => (dw s hs x hx y hy).1.differentiableWithinAt)
    (fun s hs => by
      rw [(dw s (Ico_subset_Icc_self hs) x hx y hy).1.derivWithin
        (uniqueDiffOn_Icc hT s (Ico_subset_Icc_self hs))]
      exact hw1 s (Ico_subset_Icc_self hs) x hx y hy) t ht
  rw [show w t x y = w 0 x y from hconst]
  exact shape x hx y hy

end EnergyMethodHelpers

#print axioms em_clamp_mem
#print axioms em_clamp_eq
#print axioms em_ext3
#print axioms em_ext2
#print axioms em_param_cont
#print axioms em_slice
#print axioms em_slice'
#print axioms em_dint_add3
#print axioms em_int_nonpos
#print axioms em_dint_nonpos
#print axioms em_dint_swap
#print axioms em_dint_nonpos'
#print axioms em_eq_zero_of_integral
#print axioms em_ibp
#print axioms em_iter2
#print axioms em_deriv_zero
#print axioms em_param_deriv
#print axioms em_param_deriv2
#print axioms em_param_deriv2On
#print axioms em_dint_contOn
#print axioms em_line
#print axioms em_package
#print axioms em_cx
#print axioms em_cy
#print axioms em_cxy
#print axioms em_closure_eq
#print axioms em_interior
#print axioms em_gronwall_w
#print axioms em_six
#print axioms em_gronwall_uv
#print axioms em_wave_w

/-- Uniqueness for the heat equation (Step 3 and its detailed proof). Let `u t x y` and
`v t x y` be temperatures on the plate `0 ≤ x ≤ lx`, `0 ≤ y ≤ ly` over the times `0 ≤ t ≤ T`,
both classical solutions: twice continuously differentiable up to the edge, and obeying the
heat equation `u_t = κ (u_xx + u_yy)` inside, with diffusivity `κ > 0` (time runs forwards).
If they have the same values on the edge at every time and the same starting pattern, then
they are equal at every point of the plate at every time. -/
theorem heat_solutions_with_equal_data_agree (κ T lx ly : ℝ) (hκ : 0 < κ)
    (u v : ℝ → ℝ → ℝ → ℝ)
    (hu : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => u p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hv : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => v p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hu_heat : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      deriv (fun s => u s x y) t
        = κ * (iteratedDeriv 2 (fun x' => u t x' y) x + iteratedDeriv 2 (fun y' => u t x y') y))
    (hv_heat : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      deriv (fun s => v s x y) t
        = κ * (iteratedDeriv 2 (fun x' => v t x' y) x + iteratedDeriv 2 (fun y' => v t x y') y))
    (h_edge : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      (x = 0 ∨ x = lx ∨ y = 0 ∨ y = ly) → u t x y = v t x y)
    (h_start : ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, u 0 x y = v 0 x y) :
    ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, u t x y = v t x y := by
  intro t ht x hx y hy
  rcases le_or_gt lx 0 with hlx | hlx
  · exact h_edge t ht x hx y hy (Or.inl (le_antisymm (hx.2.trans hlx) hx.1))
  rcases le_or_gt ly 0 with hly | hly
  · exact h_edge t ht x hx y hy (Or.inr (Or.inr (Or.inl (le_antisymm (hy.2.trans hly) hy.1))))
  have hE := em_gronwall_uv κ 0 T lx ly hκ hlx hly u v hu hv
    (fun t ht x hx y hy => by simpa using hu_heat t ht x hx y hy)
    (fun t ht x hx y hy => by simpa using hv_heat t ht x hx y hy) h_edge t ht
  have h0 : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (u 0 x y - v 0 x y) ^ 2) = 0 := by
    rw [intervalIntegral.integral_congr (g := fun _ => (0:ℝ)) ?_]
    · simp
    intro x hx
    rw [uIcc_of_le hlx.le] at hx
    simp only
    rw [intervalIntegral.integral_congr (g := fun _ => (0:ℝ)) ?_]
    · simp
    intro y hy
    rw [uIcc_of_le hly.le] at hy
    simp [h_start x hx y hy]
  rw [h0] at hE
  have cxy := em_cxy (F := fun s x y => (u s x y - v s x y) ^ 2)
    ((hu.continuousOn.sub hv.continuousOn).pow 2) ht
  have hnn : 0 ≤ ∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (u t x y - v t x y) ^ 2 :=
    intervalIntegral.integral_nonneg hlx.le fun x _ =>
      intervalIntegral.integral_nonneg hly.le fun y _ => by positivity
  have hEt : (∫ x in (0:ℝ)..lx, ∫ y in (0:ℝ)..ly, (u t x y - v t x y) ^ 2) = 0 := by
    simp only [mul_zero, zero_mul] at hE
    linarith
  have hI := em_eq_zero_of_integral hlx
    (em_param_cont (F := fun x y => (u t x y - v t x y) ^ 2) hlx.le hly.le cxy)
    (fun x _ => intervalIntegral.integral_nonneg hly.le fun y _ => by positivity) hEt x hx
  have hp := em_eq_zero_of_integral hly
    (em_slice (F := fun x y => (u t x y - v t x y) ^ 2) hx cxy) (fun y _ => by positivity) hI y hy
  exact sub_eq_zero.1 (pow_eq_zero_iff two_ne_zero |>.1 hp)

/-- Stability through Gronwall (Step 4). Let `u` and `v` be classical solutions on the plate
`0 ≤ x ≤ lx`, `0 ≤ y ≤ ly` (sides `lx, ly > 0`) over `0 ≤ t ≤ T` of the heat equation with a source that grows
with temperature, `u_t = κ (u_xx + u_yy) + a u`, with `κ > 0` and a fixed rate `a`, and with
the same values on the edge at every time. Then the energy of their gap,
`E(t) = (1/2) ∫∫ (u - v)^2`, is at most its start times `e^(2 a t)`: `E(t) ≤ E(0) e^(2 a t)`.
With `a = 0` this says the energy of the gap never rises above its start. -/
theorem heat_gap_energy_le_gronwall (κ a T lx ly : ℝ) (hκ : 0 < κ) (hlx : 0 < lx) (hly : 0 < ly)
    (u v : ℝ → ℝ → ℝ → ℝ)
    (hu : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => u p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hv : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => v p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hu_heat : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      deriv (fun s => u s x y) t
        = κ * (iteratedDeriv 2 (fun x' => u t x' y) x + iteratedDeriv 2 (fun y' => u t x y') y)
          + a * u t x y)
    (hv_heat : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      deriv (fun s => v s x y) t
        = κ * (iteratedDeriv 2 (fun x' => v t x' y) x + iteratedDeriv 2 (fun y' => v t x y') y)
          + a * v t x y)
    (h_edge : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      (x = 0 ∨ x = lx ∨ y = 0 ∨ y = ly) → u t x y = v t x y) :
    ∀ t ∈ Icc 0 T,
      (1 / 2) * ∫ x in (0 : ℝ)..lx, ∫ y in (0 : ℝ)..ly, (u t x y - v t x y) ^ 2
        ≤ ((1 / 2) * ∫ x in (0 : ℝ)..lx, ∫ y in (0 : ℝ)..ly, (u 0 x y - v 0 x y) ^ 2)
          * exp (2 * a * t) := by
  exact em_gronwall_uv κ a T lx ly hκ hlx hly u v hu hv hu_heat hv_heat h_edge

/-- Uniqueness for the struck plate (Step 5). Let `u` and `v` be sideways displacements of
the plate `0 ≤ x ≤ lx`, `0 ≤ y ≤ ly` over `0 ≤ t ≤ T`, both classical solutions of the damped
wave equation `ρ_s u_tt + b ρ_s u_t = ρ_s c^2 (u_xx + u_yy)` inside, with mass per area
`ρ_s > 0`, wave speed `c > 0` and damping rate `b ≥ 0`. If they have the same values on the
edge at every time, the same starting shape and the same starting velocity, then they are
the same motion at every point of the plate at every time. -/
theorem damped_plates_struck_alike_ring_alike (ρ c b T lx ly : ℝ)
    (hρ : 0 < ρ) (hc : 0 < c) (hb : 0 ≤ b)
    (u v : ℝ → ℝ → ℝ → ℝ)
    (hu : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => u p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hv : ContDiffOn ℝ 2 (fun p : ℝ × ℝ × ℝ => v p.1 p.2.1 p.2.2)
      (Icc 0 T ×ˢ Icc 0 lx ×ˢ Icc 0 ly))
    (hu_wave : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      ρ * iteratedDeriv 2 (fun s => u s x y) t + b * ρ * deriv (fun s => u s x y) t
        = ρ * c ^ 2
          * (iteratedDeriv 2 (fun x' => u t x' y) x + iteratedDeriv 2 (fun y' => u t x y') y))
    (hv_wave : ∀ t ∈ Ioo 0 T, ∀ x ∈ Ioo 0 lx, ∀ y ∈ Ioo 0 ly,
      ρ * iteratedDeriv 2 (fun s => v s x y) t + b * ρ * deriv (fun s => v s x y) t
        = ρ * c ^ 2
          * (iteratedDeriv 2 (fun x' => v t x' y) x + iteratedDeriv 2 (fun y' => v t x y') y))
    (h_edge : ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      (x = 0 ∨ x = lx ∨ y = 0 ∨ y = ly) → u t x y = v t x y)
    (h_shape : ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, u 0 x y = v 0 x y)
    (h_speed : ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly,
      derivWithin (fun s => u s x y) (Icc 0 T) 0 = derivWithin (fun s => v s x y) (Icc 0 T) 0) :
    ∀ t ∈ Icc 0 T, ∀ x ∈ Icc 0 lx, ∀ y ∈ Icc 0 ly, u t x y = v t x y := by
  intro t ht x hx y hy
  rcases le_or_gt lx 0 with hlx | hlx
  · exact h_edge t ht x hx y hy (Or.inl (le_antisymm (hx.2.trans hlx) hx.1))
  rcases le_or_gt ly 0 with hly | hly
  · exact h_edge t ht x hx y hy (Or.inr (Or.inr (Or.inl (le_antisymm (hy.2.trans hly) hy.1))))
  rcases eq_or_lt_of_le (ht.1.trans ht.2) with hTz | hT
  · have : t = 0 := le_antisymm (hTz ▸ ht.2) ht.1
    subst this
    exact h_shape x hx y hy
  obtain ⟨u1, u2, u3, u11, u22, u33, u12, u13, cu1, cu2, cu3, cu11, cu22, cu33, cu12, cu13, du⟩ :=
    em_package hT hlx hly u hu
  obtain ⟨v1, v2, v3, v11, v22, v33, v12, v13, cv1, cv2, cv3, cv11, cv22, cv33, cv12, cv13, dv⟩ :=
    em_package hT hlx hly v hv
  have h0T : (0:ℝ) ∈ Icc 0 T := ⟨le_rfl, hT.le⟩
  have key := em_wave_w (c := c) (b := b) hc hb hT hlx hly
    (w := fun s x y => u s x y - v s x y) (w1 := fun s x y => u1 s x y - v1 s x y)
    (w2 := fun s x y => u2 s x y - v2 s x y) (w3 := fun s x y => u3 s x y - v3 s x y)
    (w11 := fun s x y => u11 s x y - v11 s x y) (w22 := fun s x y => u22 s x y - v22 s x y)
    (w33 := fun s x y => u33 s x y - v33 s x y) (w12 := fun s x y => u12 s x y - v12 s x y)
    (w13 := fun s x y => u13 s x y - v13 s x y)
    (cu1.sub cv1) (cu2.sub cv2) (cu3.sub cv3) (cu11.sub cv11) (cu22.sub cv22) (cu33.sub cv33)
    (cu12.sub cv12) (cu13.sub cv13)
    (fun t ht x hx y hy => by
      obtain ⟨a1, a2, a3, a4, a5, a6, a7, a8, a9, a10⟩ := du t ht x hx y hy
      obtain ⟨b1, b2, b3, b4, b5, b6, b7, b8, b9, b10⟩ := dv t ht x hx y hy
      exact ⟨a1.sub b1, a2.sub b2, a3.sub b3, a4.sub b4, a5.sub b5, a6.sub b6, a7.sub b7,
        a8.sub b8, a9.sub b9, a10.sub b10⟩)
    (fun t ht x hx y hy => by
      obtain ⟨eu1, eu11, eu22, eu33⟩ := em_interior (em_six du) ht hx hy
      obtain ⟨ev1, ev11, ev22, ev33⟩ := em_interior (em_six dv) ht hx hy
      have h1 := hu_wave t ht x hx y hy
      have h2 := hv_wave t ht x hx y hy
      rw [eu1, eu11, eu22, eu33] at h1
      rw [ev1, ev11, ev22, ev33] at h2
      have h3 : ρ * ((u11 t x y - v11 t x y) + b * (u1 t x y - v1 t x y)
          - c ^ 2 * ((u22 t x y - v22 t x y) + (u33 t x y - v33 t x y))) = 0 := by
        linear_combination h1 - h2
      have := (mul_eq_zero.1 h3).resolve_left hρ.ne'
      linarith)
    (fun t ht x hx y hy hxy => sub_eq_zero.2 (h_edge t ht x hx y hy hxy))
    (fun x hx y hy => sub_eq_zero.2 (h_shape x hx y hy))
    (fun x hx y hy => by
      have := h_speed x hx y hy
      rw [(du 0 h0T x hx y hy).1.derivWithin (uniqueDiffOn_Icc hT 0 h0T),
        (dv 0 h0T x hx y hy).1.derivWithin (uniqueDiffOn_Icc hT 0 h0T)] at this
      exact sub_eq_zero.2 this)
  exact sub_eq_zero.1 (key t ht x hx y hy)

-- Worked numbers from the card (the 1 m square plate).
-- Energy at the start: (1/2)(0.5^2 + 0.3^2)/4 = 0.03125 + 0.01125 = 0.0425.
example : (1 / 2 : ℚ) * ((1 / 2) ^ 2 + (3 / 10) ^ 2) / 4 = 3125 / 100000 + 1125 / 100000 := by
  norm_num
example : (1 / 2 : ℚ) * ((1 / 2) ^ 2 + (3 / 10) ^ 2) / 4 = 425 / 10000 := by norm_num
-- The finer pattern (2, 3) has -Laplacian eigenvalue (2^2 + 3^2) π^2 = 13 π^2; the bump (1, 1) has 2 π^2.
example : (2 : ℕ) ^ 2 + 3 ^ 2 = 13 ∧ (1 : ℕ) ^ 2 + 1 ^ 2 = 2 := by decide
-- The backward-heat pattern (10, 10) has eigenvalue 200 π^2.
example : (10 : ℕ) ^ 2 + 10 ^ 2 = 200 := by decide
-- Gronwall exponent at 60 min with a = 1e-4 per s: 2 × 1e-4 × 3600 = 0.72.
example : (2 : ℚ) * (1 / 10000) * 3600 = 72 / 100 := by norm_num
-- Gronwall exponent at 60 min with a = 5e-4 per s: 2 × 5e-4 × 3600 = 3.6.
example : (2 : ℚ) * (5 / 10000) * 3600 = 36 / 10 := by norm_num
-- Mass per area: 2 mm of steel at 7,850 kg/m^3 is 15.7 kg/m^2.
example : (2 / 1000 : ℚ) * 7850 = 157 / 10 := by norm_num

#print axioms heat_solutions_with_equal_data_agree
#print axioms heat_gap_energy_le_gronwall
#print axioms damped_plates_struck_alike_ring_alike
