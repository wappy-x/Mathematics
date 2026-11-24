-- Local normal form: near any point a, a non-constant holomorphic function on a region is f(a) + h(z)^m with h a local change of coordinate, so it is m-to-1 near a and covers a disc about f(a); open sets go to open sets, and where f'(a) ≠ 0 it has a holomorphic inverse.
import Mathlib.Analysis.Complex.OpenMapping
import Mathlib.Analysis.Analytic.Order
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Set.Card
import Mathlib.Analysis.Calculus.InverseFunctionTheorem.Deriv
import Mathlib.Analysis.SpecialFunctions.Complex.Analytic
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.RingTheory.RootsOfUnity.Complex

open Filter Metric Set
open scoped Topology

/-- A nonzero complex number has exactly `m` different `m`-th roots. -/
theorem card_pow_eq_of_ne_zero {m : ℕ} (hm : 0 < m) {u : ℂ} (hu : u ≠ 0) :
    {ζ : ℂ | ζ ^ m = u}.ncard = m := by
  classical
  have hprim := Complex.isPrimitiveRoot_exp m hm.ne'
  have hset : {ζ : ℂ | ζ ^ m = u} = ↑(Polynomial.nthRoots m u).toFinset := by
    ext ζ; simp [Polynomial.mem_nthRoots hm]
  rw [hset, Set.ncard_coe_finset, Multiset.toFinset_card_of_nodup (hprim.nthRoots_nodup hu),
    hprim.card_nthRoots]
  have hα : (u ^ ((m : ℂ)⁻¹)) ^ m = u := Complex.cpow_nat_inv_pow u hm.ne'
  simp only [show ∃ α : ℂ, α ^ m = u from ⟨_, hα⟩, ite_true]

/-- **Local normal form.** Let `f` be holomorphic on a region `U` (an open set in one piece),
let `a` be a point of `U`, and let `f` not be constant on `U`. Then there is a whole number
`m ≥ 1`, the order of `f - f(a)` at `a`, and a local change of coordinate `h` (holomorphic at
`a`, with `h(a) = 0` and `h'(a) ≠ 0`) such that `f(z) = f(a) + h(z)^m` near `a`. Moreover there
are radii `r, δ > 0` such that every value `w` within `δ` of `f(a)`, other than `f(a)` itself,
has exactly `m` different preimages within `r` of `a`, and the disc of radius `r` about `a`
covers the whole disc of radius `δ` about `f(a)`. -/
theorem local_normal_form_m_to_one {f : ℂ → ℂ} {U : Set ℂ} {a : ℂ}
    (hU : IsOpen U) (hUc : IsPreconnected U) (ha : a ∈ U)
    (hf : DifferentiableOn ℂ f U) (hnc : ∃ z ∈ U, f z ≠ f a) :
    ∃ m : ℕ, 0 < m ∧ analyticOrderAt (fun z => f z - f a) a = (m : ℕ∞) ∧
      (∃ h : ℂ → ℂ, AnalyticAt ℂ h a ∧ h a = 0 ∧ deriv h a ≠ 0 ∧
        ∀ᶠ z in 𝓝 a, f z = f a + h z ^ m) ∧
      ∃ r > 0, ∃ δ > 0, ball a r ⊆ U ∧
        (∀ w : ℂ, w ≠ f a → w ∈ ball (f a) δ → {z | z ∈ ball a r ∧ f z = w}.ncard = m) ∧
        ball (f a) δ ⊆ f '' ball a r := by
  have hA : AnalyticOnNhd ℂ f U := hf.analyticOnNhd hU
  have hFA : AnalyticAt ℂ (fun z => f z - f a) a := (hA a ha).sub analyticAt_const
  -- the order is finite
  have hne : analyticOrderAt (fun z => f z - f a) a ≠ ⊤ := by
    intro htop
    rw [analyticOrderAt_eq_top] at htop
    have hev : f =ᶠ[𝓝 a] fun _ => f a := htop.mono fun z hz => sub_eq_zero.mp hz
    have hEq := hA.eqOn_of_preconnected_of_eventuallyEq analyticOnNhd_const hUc ha hev
    obtain ⟨z, hz, hzne⟩ := hnc
    exact hzne (hEq hz)
  obtain ⟨m, hm⟩ := ENat.ne_top_iff_exists.mp hne
  have hm0 : m ≠ 0 := by
    rintro rfl
    have := (hFA.analyticOrderAt_eq_zero).mp (by rw [← hm]; rfl)
    exact this (by simp)
  have hmpos : 0 < m := Nat.pos_of_ne_zero hm0
  obtain ⟨g, hg, hga, hgev⟩ := (hFA.analyticOrderAt_eq_natCast).mp hm.symm
  -- an m-th root of g near a
  set c : ℂ := g a ^ ((m : ℂ)⁻¹) with hc
  have hcm : c ^ m = g a := Complex.cpow_nat_inv_pow _ hm0
  have hc0 : c ≠ 0 := by
    intro h0; apply hga; rw [← hcm, h0, zero_pow hm0]
  set k : ℂ → ℂ := fun z => c * (g z / g a) ^ ((m : ℂ)⁻¹) with hk
  have hkA : AnalyticAt ℂ k a := by
    refine analyticAt_const.mul ((hg.div analyticAt_const hga).cpow analyticAt_const ?_)
    show g a / g a ∈ Complex.slitPlane
    rw [div_self hga]; exact Complex.one_mem_slitPlane
  have hkm : ∀ z, k z ^ m = g z := by
    intro z
    simp only [hk, mul_pow, Complex.cpow_nat_inv_pow _ hm0, hcm]
    field_simp
  have hka : k a = c := by simp [hk, div_self hga]
  set h : ℂ → ℂ := fun z => (z - a) * k z with hh
  have hhA : AnalyticAt ℂ h a := (analyticAt_id.sub analyticAt_const).mul hkA
  have hha : h a = 0 := by simp [hh]
  have hhd : HasDerivAt h (k a) a := by
    have := ((hasDerivAt_id a).sub_const a).mul hkA.differentiableAt.hasDerivAt
    convert this using 1
    · rfl
    · simp
  have hderiv : deriv h a ≠ 0 := by rw [hhd.deriv, hka]; exact hc0
  have hfh : ∀ᶠ z in 𝓝 a, f z = f a + h z ^ m := by
    filter_upwards [hgev] with z hz
    simp only [smul_eq_mul] at hz
    simp only [hh, mul_pow, hkm]
    linear_combination hz
  refine ⟨m, hmpos, hm.symm, ⟨h, hhA, hha, hderiv, hfh⟩, ?_⟩
  -- the counting part
  have hsd : HasStrictDerivAt h (deriv h a) a := hhA.hasStrictDerivAt
  set e := (hsd.hasStrictFDerivAt_equiv hderiv).toOpenPartialHomeomorph h with he
  have he_coe : (e : ℂ → ℂ) = h := rfl
  have hsrc : e.source ∈ 𝓝 a :=
    e.open_source.mem_nhds (hsd.hasStrictFDerivAt_equiv hderiv).mem_toOpenPartialHomeomorph_source
  have hN : U ∩ e.source ∩ {z | f z = f a + h z ^ m} ∈ 𝓝 a :=
    inter_mem (inter_mem (hU.mem_nhds ha) hsrc) hfh
  obtain ⟨r, hr, hrsub⟩ := Metric.mem_nhds_iff.mp hN
  have hopen : IsOpen (h '' ball a r) := by
    rw [← he_coe]
    exact e.isOpen_image_of_subset_source isOpen_ball
      (fun z hz => (hrsub hz).1.2)
  have h0mem : (0 : ℂ) ∈ h '' ball a r := ⟨a, mem_ball_self hr, hha⟩
  obtain ⟨ε, hε, hεsub⟩ := Metric.isOpen_iff.mp hopen 0 h0mem
  have hδ : 0 < ε ^ m := pow_pos hε m
  refine ⟨r, hr, ε ^ m, hδ, fun z hz => (hrsub hz).1.1, ?_, ?_⟩
  · -- key fact: every m-th root of w - f a is hit
    have hinj : InjOn h (ball a r) := by
      rw [← he_coe]; exact e.injOn.mono (fun z hz => (hrsub hz).1.2)
    have hroot : ∀ w ∈ ball (f a) (ε ^ m), ∀ ζ : ℂ, ζ ^ m = w - f a →
        ∃ z ∈ ball a r, h z = ζ := by
      intro w hw ζ hζ
      have hnorm : ‖ζ‖ ^ m < ε ^ m := by
        rw [← norm_pow, hζ, ← dist_eq_norm]; exact hw
      have hlt : ‖ζ‖ < ε := lt_of_pow_lt_pow_left₀ m hε.le hnorm
      obtain ⟨z, hz, hzζ⟩ := hεsub (by simpa [mem_ball, dist_zero_right] using hlt)
      exact ⟨z, hz, hzζ⟩
    intro w hw0 hw
    have himg : h '' {z | z ∈ ball a r ∧ f z = w} = {ζ : ℂ | ζ ^ m = w - f a} := by
      ext ζ
      constructor
      · rintro ⟨z, ⟨hz, hfz⟩, rfl⟩
        have := (hrsub hz).2
        simp only [mem_ofPred_eq] at this ⊢
        rw [← hfz, this]; ring
      · intro hζ
        obtain ⟨z, hz, hzζ⟩ := hroot w hw ζ hζ
        refine ⟨z, ⟨hz, ?_⟩, hzζ⟩
        have := (hrsub hz).2
        simp only [mem_ofPred_eq] at this hζ
        rw [this, hzζ, hζ]; ring
    have hinj' : InjOn h {z | z ∈ ball a r ∧ f z = w} := hinj.mono (fun z hz => hz.1)
    rw [← hinj'.ncard_image, himg]
    exact card_pow_eq_of_ne_zero hmpos (sub_ne_zero.mpr hw0)
  · intro w hw
    set ζ : ℂ := (w - f a) ^ ((m : ℂ)⁻¹)
    have hζ : ζ ^ m = w - f a := Complex.cpow_nat_inv_pow _ hm0
    have hnorm : ‖ζ‖ ^ m < ε ^ m := by
      rw [← norm_pow, hζ, ← dist_eq_norm]; exact hw
    have hlt : ‖ζ‖ < ε := lt_of_pow_lt_pow_left₀ m hε.le hnorm
    obtain ⟨z, hz, hzζ⟩ := hεsub (by simpa [mem_ball, dist_zero_right] using hlt)
    refine ⟨z, hz, ?_⟩
    have := (hrsub hz).2
    simp only [mem_ofPred_eq] at this
    rw [this, hzζ, hζ]; ring

/-- **Open mapping theorem.** A holomorphic function that is not constant on a region `U`
sends every open set inside `U` to an open set. -/
theorem open_mapping_theorem {f : ℂ → ℂ} {U : Set ℂ}
    (hU : IsOpen U) (hUc : IsPreconnected U)
    (hf : DifferentiableOn ℂ f U) (hnc : ∃ z₁ ∈ U, ∃ z₂ ∈ U, f z₁ ≠ f z₂) :
    ∀ V ⊆ U, IsOpen V → IsOpen (f '' V) := by
  have hA : AnalyticOnNhd ℂ f U := hf.analyticOnNhd hU
  rcases hA.is_constant_or_isOpen hUc with ⟨w, hw⟩ | h
  · obtain ⟨z₁, hz₁, z₂, hz₂, hne⟩ := hnc
    exact absurd ((hw z₁ hz₁).trans (hw z₂ hz₂).symm) hne
  · exact h

/-- **Holomorphic inverse function theorem** (the case `m = 1`). Let `f` be holomorphic on an
open set `U` about `a` with `f'(a) ≠ 0`. Then there are radii `r, δ > 0` such that each `w`
within `δ` of `f(a)` has exactly one preimage `z(w)` within `r` of `a`, and `w ↦ z(w)` is
holomorphic on that disc, with derivative `1 / f'(z(w))`. -/
theorem holomorphic_inverse_function_theorem {f : ℂ → ℂ} {U : Set ℂ} {a : ℂ}
    (hU : IsOpen U) (ha : a ∈ U) (hf : DifferentiableOn ℂ f U) (hf' : deriv f a ≠ 0) :
    ∃ r > 0, ∃ δ > 0, ball a r ⊆ U ∧ ∃ g : ℂ → ℂ, DifferentiableOn ℂ g (ball (f a) δ) ∧
      ∀ w ∈ ball (f a) δ, g w ∈ ball a r ∧ f (g w) = w ∧
        (∀ z ∈ ball a r, f z = w → z = g w) ∧ deriv g w = 1 / deriv f (g w) := by
  have hA : AnalyticOnNhd ℂ f U := hf.analyticOnNhd hU
  have hsd : HasStrictDerivAt f (deriv f a) a := (hA a ha).hasStrictDerivAt
  set e := (hsd.hasStrictFDerivAt_equiv hf').toOpenPartialHomeomorph f with he
  have he_coe : (e : ℂ → ℂ) = f := rfl
  have hsrc : e.source ∈ 𝓝 a :=
    e.open_source.mem_nhds (hsd.hasStrictFDerivAt_equiv hf').mem_toOpenPartialHomeomorph_source
  have hdc : ContinuousAt (deriv f) a := (hA.deriv a ha).continuousAt
  have hd0 : {z | deriv f z ≠ 0} ∈ 𝓝 a := hdc.eventually_ne hf'
  have hN : U ∩ e.source ∩ {z | deriv f z ≠ 0} ∈ 𝓝 a :=
    inter_mem (inter_mem (hU.mem_nhds ha) hsrc) hd0
  obtain ⟨r, hr, hrsub⟩ := Metric.mem_nhds_iff.mp hN
  have hopen : IsOpen (e '' ball a r) :=
    e.isOpen_image_of_subset_source isOpen_ball (fun z hz => (hrsub hz).1.2)
  have hfa : f a ∈ e '' ball a r := ⟨a, mem_ball_self hr, rfl⟩
  obtain ⟨δ, hδ, hδsub⟩ := Metric.isOpen_iff.mp hopen (f a) hfa
  have key : ∀ w ∈ ball (f a) δ, ∃ z ∈ ball a r, e.symm w = z ∧ f z = w ∧ w ∈ e.target := by
    intro w hw
    obtain ⟨z, hz, rfl⟩ := hδsub hw
    exact ⟨z, hz, e.left_inv (hrsub hz).1.2, rfl, e.map_source (hrsub hz).1.2⟩
  have hder : ∀ w ∈ ball (f a) δ, HasDerivAt e.symm (deriv f (e.symm w))⁻¹ w := by
    intro w hw
    obtain ⟨z, hz, hzw, _, htgt⟩ := key w hw
    rw [hzw]
    apply e.hasDerivAt_symm htgt (hrsub hz).2
    rw [hzw]
    exact (hA z (hrsub hz).1.1).differentiableAt.hasDerivAt
  refine ⟨r, hr, δ, hδ, fun z hz => (hrsub hz).1.1, e.symm, ?_, ?_⟩
  · intro w hw
    exact (hder w hw).differentiableAt.differentiableWithinAt
  · intro w hw
    obtain ⟨z, hz, hzw, hfz, _⟩ := key w hw
    refine ⟨hzw ▸ hz, hzw ▸ hfz, ?_, ?_⟩
    · intro z' hz' hfz'
      rw [hzw]
      have : e z' = e z := by rw [he_coe, hfz', hfz]
      exact e.injOn (hrsub hz').1.2 (hrsub hz).1.2 this
    · rw [(hder w hw).deriv, one_div]

-- The pendulum's normal form: cos z = 1 - h(z)^2 with h(z) = √2 sin(z/2).
example (z : ℂ) : Complex.cos z = 1 - ((Real.sqrt 2 : ℂ) * Complex.sin (z / 2)) ^ 2 := by
  have h2 : ((Real.sqrt 2 : ℂ)) ^ 2 = 2 := by
    rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; norm_num
  rw [mul_pow, h2, ← Complex.cos_two_mul_eq_one_sub]; ring_nf

-- The minus sign folds into the coordinate: (i h)^2 = -h^2.
example (h : ℂ) : (Complex.I * h) ^ 2 = -h ^ 2 := by
  rw [mul_pow, Complex.I_sq]; ring

#print axioms card_pow_eq_of_ne_zero
#print axioms local_normal_form_m_to_one
#print axioms open_mapping_theorem
#print axioms holomorphic_inverse_function_theorem
