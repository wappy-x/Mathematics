-- Triple integrals: a continuous density on a closed box can be integrated one direction at a time in any of the six orders, the centre of mass of a bounded solid with positive mass is the one point about which the density-weighted positions cancel, and the card's wedge of radius R, height H and angle α with density 1 + r/40 has mass αH(R²/2 + R³/120) and x-moment 2 sin(α/2) H (R³/3 + R⁴/160).
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Set Real MeasureTheory

theorem swap2_aux {g : ℝ → ℝ → ℝ} {s t : Set ℝ}
    (hg : IntegrableOn (Function.uncurry g) (s ×ˢ t)) :
    ∫ x in s, ∫ y in t, g x y = ∫ y in t, ∫ x in s, g x y := by
  apply integral_integral_swap
  rw [Measure.prod_restrict, ← Measure.volume_eq_prod]
  exact hg

#print axioms swap2_aux

theorem fiber_aux {F : ℝ → ℝ → ℝ → ℝ} {s t u : Set ℝ}
    (hs : IsCompact s) (ht : IsCompact t) (hu : IsCompact u)
    (hF : ContinuousOn (fun q : (ℝ × ℝ) × ℝ => F q.1.1 q.1.2 q.2) ((s ×ˢ t) ×ˢ u)) :
    IntegrableOn (fun p : ℝ × ℝ => ∫ z in u, F p.1 p.2 z) (s ×ˢ t) := by
  have h1 : IntegrableOn (fun q : (ℝ × ℝ) × ℝ => F q.1.1 q.1.2 q.2) ((s ×ˢ t) ×ˢ u) :=
    hF.integrableOn_compact ((hs.prod ht).prod hu)
  have h2 : Integrable (fun q : (ℝ × ℝ) × ℝ => F q.1.1 q.1.2 q.2)
      ((volume.restrict (s ×ˢ t)).prod (volume.restrict u)) := by
    rw [Measure.prod_restrict, ← Measure.volume_eq_prod]
    exact h1
  exact h2.integral_prod_left

#print axioms fiber_aux

theorem triple_aux {ρ : ℝ × ℝ × ℝ → ℝ} {s t u : Set ℝ}
    (hs : IsCompact s) (ht : IsCompact t) (hu : IsCompact u)
    (hms : MeasurableSet s)
    (hρ : ContinuousOn ρ (s ×ˢ t ×ˢ u)) :
    ∫ p in s ×ˢ t ×ˢ u, ρ p = ∫ x in s, ∫ y in t, ∫ z in u, ρ (x, y, z) := by
  rw [Measure.volume_eq_prod, setIntegral_prod _ (hρ.integrableOn_compact (hs.prod (ht.prod hu)))]
  refine setIntegral_congr_fun hms fun x hx => ?_
  rw [Measure.volume_eq_prod, setIntegral_prod]
  refine ContinuousOn.integrableOn_compact (ht.prod hu) ?_
  refine hρ.comp (by fun_prop) ?_
  intro q hq
  exact ⟨hx, hq⟩

#print axioms triple_aux

/-- **Adding one direction at a time.** Let ρ be a density on the closed box
[a₁, b₁] × [a₂, b₂] × [a₃, b₃] in space, with no jumps there (continuous on the box). Then the
triple integral of ρ over the box (Mathlib's integral for the volume on ℝ × ℝ × ℝ) equals the
three single integrals done one after another, and all six orders of adding x, y and z give the
same number. The first order is the card's: each vertical column in z first, then y, then x. -/
theorem triple_integral_eq_iterated {ρ : ℝ × ℝ × ℝ → ℝ} {a₁ b₁ a₂ b₂ a₃ b₃ : ℝ}
    (hρ : ContinuousOn ρ (Icc a₁ b₁ ×ˢ Icc a₂ b₂ ×ˢ Icc a₃ b₃)) :
    let M := ∫ p in Icc a₁ b₁ ×ˢ Icc a₂ b₂ ×ˢ Icc a₃ b₃, ρ p
    (M = ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ρ (x, y, z)) ∧
    (M = ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ρ (x, y, z)) ∧
    (M = ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ρ (x, y, z)) ∧
    (M = ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ρ (x, y, z)) ∧
    (M = ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ρ (x, y, z)) ∧
    (M = ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ρ (x, y, z)) := by
  intro M
  have c1 := isCompact_Icc (a := a₁) (b := b₁)
  have c2 := isCompact_Icc (a := a₂) (b := b₂)
  have c3 := isCompact_Icc (a := a₃) (b := b₃)
  have h1 : M = ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ρ (x, y, z) :=
    triple_aux c1 c2 c3 measurableSet_Icc hρ
  have h2 : M = ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ρ (x, y, z) := by
    rw [h1]
    refine setIntegral_congr_fun measurableSet_Icc fun x hx => ?_
    refine swap2_aux (g := fun y z => ρ (x, y, z)) ?_
    refine ContinuousOn.integrableOn_compact (c2.prod c3) ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hx, hq⟩
  have h3 : M = ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ∫ z in Icc a₃ b₃, ρ (x, y, z) := by
    rw [h1]
    refine swap2_aux (g := fun x y => ∫ z in Icc a₃ b₃, ρ (x, y, z)) ?_
    refine fiber_aux (F := fun x y z => ρ (x, y, z)) c1 c2 c3 ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.1.1, hq.1.2, hq.2⟩
  have h4 : M = ∫ y in Icc a₂ b₂, ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ρ (x, y, z) := by
    rw [h3]
    refine setIntegral_congr_fun measurableSet_Icc fun y hy => ?_
    refine swap2_aux (g := fun x z => ρ (x, y, z)) ?_
    refine ContinuousOn.integrableOn_compact (c1.prod c3) ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.1, hy, hq.2⟩
  have h5 : M = ∫ z in Icc a₃ b₃, ∫ x in Icc a₁ b₁, ∫ y in Icc a₂ b₂, ρ (x, y, z) := by
    rw [h2]
    refine swap2_aux (g := fun x z => ∫ y in Icc a₂ b₂, ρ (x, y, z)) ?_
    refine fiber_aux (F := fun x z y => ρ (x, y, z)) c1 c3 c2 ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.1.1, hq.2, hq.1.2⟩
  have h6 : M = ∫ z in Icc a₃ b₃, ∫ y in Icc a₂ b₂, ∫ x in Icc a₁ b₁, ρ (x, y, z) := by
    rw [h4]
    refine swap2_aux (g := fun y z => ∫ x in Icc a₁ b₁, ρ (x, y, z)) ?_
    refine fiber_aux (F := fun y z x => ρ (x, y, z)) c2 c3 c1 ?_
    exact hρ.comp (by fun_prop) fun q hq => ⟨hq.2, hq.1.1, hq.1.2⟩
  exact ⟨h1, h2, h3, h4, h5, h6⟩

/-- **The centre of mass is where the moments cancel.** Take a bounded solid E in space (a
bounded measurable set) and a density ρ with no jumps (continuous). Suppose the total mass
M = ∫_E ρ dV is positive. Then a point c is a balance point, meaning the pieces' masses times
their offsets from c add to zero (∫_E ρ(p) (p − c) dV = 0), exactly when c is the moment
∫_E ρ(p) p dV divided by the mass M. In coordinates: x̄ = Q_x / M, and the same for y and z. -/
theorem centre_of_mass_balances {E : Set (ℝ × ℝ × ℝ)} {ρ : ℝ × ℝ × ℝ → ℝ}
    (hE : MeasurableSet E) (hEb : Bornology.IsBounded E) (hρ : Continuous ρ)
    (hM : 0 < ∫ p in E, ρ p) (c : ℝ × ℝ × ℝ) :
    (∫ p in E, ρ p • (p - c)) = 0 ↔ c = (∫ p in E, ρ p) ⁻¹ • ∫ p in E, ρ p • p := by
  have hK := hEb.isCompact_closure
  have i1 : IntegrableOn ρ E := (hρ.continuousOn.integrableOn_compact hK).mono_set subset_closure
  have i2 : IntegrableOn (fun p => ρ p • p) E :=
    ((hρ.smul continuous_id).continuousOn.integrableOn_compact hK).mono_set subset_closure
  have i3 : IntegrableOn (fun p => ρ p • c) E := i1.smul_const c
  simp_rw [smul_sub]
  rw [integral_sub i2 i3, integral_smul_const, sub_eq_zero, eq_inv_smul_iff₀ hM.ne', eq_comm]

/-- Two angles in `(-π, π]` with the same cosine and sine are equal. -/
theorem angle_eq_aux {θ θ' : ℝ} (h : θ ∈ Ioc (-π) π) (h' : θ' ∈ Ioc (-π) π)
    (hc : cos θ' = cos θ) (hs : sin θ' = sin θ) : θ' = θ := by
  have e1 := Complex.arg_cos_add_sin_mul_I h
  have e2 := Complex.arg_cos_add_sin_mul_I h'
  rw [← Complex.ofReal_cos, ← Complex.ofReal_sin] at e1 e2
  rw [hc, hs] at e2
  rw [← e2, e1]

#print axioms angle_eq_aux

/-- A point of the open polar strip that lands in the wedge comes from the wedge's own box. -/
theorem wedge_polar_aux {R α r θ : ℝ} (hα : α ≤ 2 * π) (hr : 0 < r) (hθ1 : -π < θ)
    (hθ2 : θ < π)
    (h : ∃ r' θ' : ℝ, 0 ≤ r' ∧ r' ≤ R ∧ -(α / 2) ≤ θ' ∧ θ' ≤ α / 2 ∧
      r * cos θ = r' * cos θ' ∧ r * sin θ = r' * sin θ') :
    r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 := by
  obtain ⟨r', θ', hr0, hrR, ht1, ht2, hx, hy⟩ := h
  have hsq : r' ^ 2 = r ^ 2 := by
    have e : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = (r' * cos θ') ^ 2 + (r' * sin θ') ^ 2 := by
      rw [hx, hy]
    have a := cos_sq_add_sin_sq θ
    have b := cos_sq_add_sin_sq θ'
    linear_combination (-1 : ℝ) * e + r ^ 2 * a - r' ^ 2 * b
  have hrr : r' = r := (sq_eq_sq₀ hr0 hr.le).1 hsq
  subst hrr
  have hc : cos θ' = cos θ := (mul_left_cancel₀ hr.ne' hx).symm
  have hs : sin θ' = sin θ := (mul_left_cancel₀ hr.ne' hy).symm
  have hθ : θ ∈ Ioc (-π) π := ⟨hθ1, hθ2.le⟩
  rcases eq_or_lt_of_le (show -π ≤ θ' by linarith) with h0 | h0
  · exfalso
    rw [← h0, sin_neg, sin_pi] at hs
    rw [← h0, cos_neg, cos_pi] at hc
    have e1 := Complex.arg_cos_add_sin_mul_I hθ
    rw [← Complex.ofReal_cos, ← Complex.ofReal_sin, ← hc, ← hs] at e1
    simp at e1
    linarith
  · have := angle_eq_aux hθ ⟨h0, by linarith⟩ hc hs
    subst this
    exact ⟨hrR, ht1, ht2⟩

#print axioms wedge_polar_aux

/-- The flat wedge (the cross-section of the solid wedge). -/
def wedgeD (R α : ℝ) : Set (ℝ × ℝ) :=
  {q | ∃ r θ : ℝ, 0 ≤ r ∧ r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 ∧ q.1 = r * cos θ ∧ q.2 = r * sin θ}

#print axioms wedgeD

theorem wedgeD_eq (R α : ℝ) : wedgeD R α =
    (fun p : ℝ × ℝ => (p.1 * cos p.2, p.1 * sin p.2)) '' (Icc 0 R ×ˢ Icc (-(α / 2)) (α / 2)) := by
  ext ⟨x, y⟩
  simp only [wedgeD, mem_ofPred_eq, mem_image, mem_prod, mem_Icc, Prod.exists, Prod.mk.injEq]
  constructor
  · rintro ⟨r, θ, h1, h2, h3, h4, h5, h6⟩
    exact ⟨r, θ, ⟨⟨h1, h2⟩, h3, h4⟩, h5.symm, h6.symm⟩
  · rintro ⟨r, θ, ⟨⟨h1, h2⟩, h3, h4⟩, h5, h6⟩
    exact ⟨r, θ, h1, h2, h3, h4, h5.symm, h6.symm⟩

#print axioms wedgeD_eq

theorem wedgeD_compact (R α : ℝ) : IsCompact (wedgeD R α) := by
  rw [wedgeD_eq]
  exact (isCompact_Icc.prod isCompact_Icc).image (by fun_prop)

#print axioms wedgeD_compact

/-- Integrating along the height of the solid wedge. -/
theorem wedge_height_aux {R H α : ℝ} (hH : 0 ≤ H) (F : ℝ × ℝ → ℝ) :
    let E : Set (ℝ × ℝ × ℝ) := {p | ∃ r θ : ℝ, 0 ≤ r ∧ r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 ∧
      p.1 = r * cos θ ∧ p.2.1 = r * sin θ ∧ 0 ≤ p.2.2 ∧ p.2.2 ≤ H}
    (∫ p in E, F (p.1, p.2.1)) = (∫ q in wedgeD R α, F q) * H := by
  intro E
  have hpre : (MeasurableEquiv.prodAssoc : (ℝ × ℝ) × ℝ ≃ᵐ ℝ × ℝ × ℝ) ⁻¹' E =
      wedgeD R α ×ˢ Icc 0 H := by
    ext ⟨⟨x, y⟩, z⟩
    simp only [E, wedgeD, mem_preimage, MeasurableEquiv.prodAssoc, MeasurableEquiv.coe_mk,
      Equiv.prodAssoc_apply, mem_ofPred_eq, mem_prod, mem_Icc]
    constructor
    · rintro ⟨r, θ, h1, h2, h3, h4, h5, h6, h7, h8⟩
      exact ⟨⟨r, θ, h1, h2, h3, h4, h5, h6⟩, h7, h8⟩
    · rintro ⟨⟨r, θ, h1, h2, h3, h4, h5, h6⟩, h7, h8⟩
      exact ⟨r, θ, h1, h2, h3, h4, h5, h6, h7, h8⟩
  rw [← volume_preserving_prodAssoc.setIntegral_preimage_emb
    MeasurableEquiv.prodAssoc.measurableEmbedding, hpre]
  have : ∀ q : (ℝ × ℝ) × ℝ,
      F ((MeasurableEquiv.prodAssoc q).1, (MeasurableEquiv.prodAssoc q).2.1) = F q.1 * 1 := by
    rintro ⟨⟨x, y⟩, z⟩; simp [MeasurableEquiv.prodAssoc]
  simp_rw [this]
  rw [Measure.volume_eq_prod, setIntegral_prod_mul F (fun _ : ℝ => (1 : ℝ))]
  simp [hH]

#print axioms wedge_height_aux

/-- Polar coordinates on the flat wedge. -/
theorem wedge_polar_change {R α : ℝ} (hα : α ≤ 2 * π) (F : ℝ × ℝ → ℝ) :
    (∫ q in wedgeD R α, F q) =
      ∫ p in Icc 0 R ×ˢ Icc (-(α / 2)) (α / 2), p.1 * F (p.1 * cos p.2, p.1 * sin p.2) := by
  set K : Set (ℝ × ℝ) := Icc 0 R ×ˢ Icc (-(α / 2)) (α / 2) with hKdef
  have hK : MeasurableSet K := measurableSet_Icc.prod measurableSet_Icc
  have hT : MeasurableSet polarCoord.target := by
    rw [polarCoord_target]; exact measurableSet_Ioi.prod measurableSet_Ioo
  rw [← integral_indicator (wedgeD_compact R α).isClosed.measurableSet,
    ← integral_comp_polarCoord_symm]
  have step : ∫ p in polarCoord.target, p.1 • (wedgeD R α).indicator F (polarCoord.symm p) =
      ∫ p in polarCoord.target,
        K.indicator (fun p => p.1 * F (p.1 * cos p.2, p.1 * sin p.2)) p := by
    refine setIntegral_congr_fun hT fun p hp => ?_
    obtain ⟨r, θ⟩ := p
    rw [polarCoord_target] at hp
    simp only [mem_prod, mem_Ioi, mem_Ioo] at hp
    obtain ⟨hr, hθ1, hθ2⟩ := hp
    simp only [polarCoord_symm_apply, smul_eq_mul]
    by_cases hp : (r, θ) ∈ K
    · rw [indicator_of_mem hp, indicator_of_mem]
      simp only [hKdef, mem_prod, mem_Icc] at hp
      exact ⟨r, θ, hp.1.1, hp.1.2, hp.2.1, hp.2.2, rfl, rfl⟩
    · rw [indicator_of_notMem hp, indicator_of_notMem, mul_zero]
      intro hm
      apply hp
      obtain ⟨r', θ', h1, h2, h3, h4, h5, h6⟩ := hm
      have := wedge_polar_aux hα hr hθ1 hθ2 ⟨r', θ', h1, h2, h3, h4, h5, h6⟩
      simp only [hKdef, mem_prod, mem_Icc]
      exact ⟨⟨hr.le, this.1⟩, this.2⟩
  rw [step, setIntegral_indicator hK]
  refine setIntegral_congr_set ?_
  rw [ae_eq_set]
  constructor
  · rw [sdiff_eq_empty.2 inter_subset_right, measure_empty]
  · have hsub : K \ (polarCoord.target ∩ K) ⊆ ({0} ×ˢ univ) ∪ (univ ×ˢ {-π, π}) := by
      rintro ⟨r, θ⟩ ⟨hpK, hpT⟩
      simp only [hKdef, mem_prod, mem_Icc] at hpK
      rw [polarCoord_target] at hpT
      simp only [mem_inter_iff, mem_prod, mem_Ioi, mem_Ioo, not_and_or, not_lt] at hpT
      simp only [mem_union, mem_prod, mem_singleton_iff, mem_univ, and_true, true_and,
        mem_insert_iff]
      rcases hpT with (h | h | h) | h
      · left; linarith
      · right; left; linarith
      · right; right; linarith
      · exact absurd hpK h
    refine measure_mono_null hsub (measure_union_null ?_ ?_)
    · rw [Measure.volume_eq_prod, Measure.prod_prod]; simp
    · rw [Measure.volume_eq_prod, Measure.prod_prod]
      rw [(Set.toFinite ({-π, π} : Set ℝ)).measure_zero, mul_zero]

#print axioms wedge_polar_change

theorem sqrt_polar_aux {r θ : ℝ} (hr : 0 ≤ r) :
    √((r * cos θ) ^ 2 + (r * sin θ) ^ 2) = r := by
  rw [show (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 by
    linear_combination r ^ 2 * cos_sq_add_sin_sq θ]
  exact sqrt_sq hr

#print axioms sqrt_polar_aux

theorem Icc_integral_aux {a b : ℝ} (hab : a ≤ b) (f : ℝ → ℝ) :
    ∫ x in Icc a b, f x = ∫ x in a..b, f x := by
  rw [integral_Icc_eq_integral_Ioc, intervalIntegral.integral_of_le hab]

#print axioms Icc_integral_aux

theorem radial_mass_aux (R : ℝ) :
    ∫ r in (0 : ℝ)..R, r * (1 + r / 40) = R ^ 2 / 2 + R ^ 3 / 120 := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun r : ℝ => r ^ 2 / 2 + r ^ 3 / 120) (fun x _ => ?_)
    ((by fun_prop : Continuous fun r : ℝ => r * (1 + r / 40)).intervalIntegrable _ _)]
  · ring
  · have := ((hasDerivAt_pow 2 x).div_const 2).add ((hasDerivAt_pow 3 x).div_const 120)
    convert this using 1
    push_cast; ring

#print axioms radial_mass_aux

theorem radial_moment_aux (R : ℝ) :
    ∫ r in (0 : ℝ)..R, r * r * (1 + r / 40) = R ^ 3 / 3 + R ^ 4 / 160 := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun r : ℝ => r ^ 3 / 3 + r ^ 4 / 160) (fun x _ => ?_)
    ((by fun_prop : Continuous fun r : ℝ => r * r * (1 + r / 40)).intervalIntegrable _ _)]
  · ring
  · have := ((hasDerivAt_pow 3 x).div_const 3).add ((hasDerivAt_pow 4 x).div_const 160)
    convert this using 1
    push_cast; ring

#print axioms radial_moment_aux

/-- **The cheese wedge, by hand.** The wedge of radius R, height H and angle α (in radians, at
most a full turn 2π) is every point (r cos θ, r sin θ, z) with r from 0 to R, θ from −α/2 to
α/2 and z from 0 to H. Its density at distance r = √(x² + y²) from the wheel's axis is
1 + r/40. Then its mass is M = αH(R²/2 + R³/120), and its moment along the middle line,
Q_x = ∫ x ρ dV, is 2 sin(α/2) H (R³/3 + R⁴/160). -/
theorem wedge_mass_and_moment {R H α : ℝ} (hR : 0 ≤ R) (hH : 0 ≤ H) (hα₀ : 0 ≤ α)
    (hα : α ≤ 2 * π) :
    let E : Set (ℝ × ℝ × ℝ) := {p | ∃ r θ : ℝ, 0 ≤ r ∧ r ≤ R ∧ -(α / 2) ≤ θ ∧ θ ≤ α / 2 ∧
      p.1 = r * cos θ ∧ p.2.1 = r * sin θ ∧ 0 ≤ p.2.2 ∧ p.2.2 ≤ H}
    (∫ p in E, (1 + √(p.1 ^ 2 + p.2.1 ^ 2) / 40)) = α * H * (R ^ 2 / 2 + R ^ 3 / 120) ∧
    (∫ p in E, p.1 * (1 + √(p.1 ^ 2 + p.2.1 ^ 2) / 40)) =
      2 * sin (α / 2) * H * (R ^ 3 / 3 + R ^ 4 / 160) := by
  intro E
  have hα2 : -(α / 2) ≤ α / 2 := by linarith
  constructor
  · refine (wedge_height_aux (R := R) (α := α) hH
      (fun q => 1 + √(q.1 ^ 2 + q.2 ^ 2) / 40)).trans ?_
    rw [wedge_polar_change hα]
    rw [setIntegral_congr_fun (measurableSet_Icc.prod measurableSet_Icc)
      (g := fun z : ℝ × ℝ => (z.1 * (1 + z.1 / 40)) * (fun _ : ℝ => (1 : ℝ)) z.2) ?_]
    · rw [Measure.volume_eq_prod, setIntegral_prod_mul (fun r : ℝ => r * (1 + r / 40))
        (fun _ : ℝ => (1 : ℝ)), Icc_integral_aux hR, radial_mass_aux]
      simp only [integral_const, MeasurableSet.univ, measureReal_restrict_apply, univ_inter,
        Real.volume_real_Icc_of_le hα2, smul_eq_mul, mul_one]
      ring
    · rintro ⟨r, θ⟩ hp
      simp only [mem_prod, mem_Icc] at hp
      simp only [sqrt_polar_aux hp.1.1, mul_one]
  · refine (wedge_height_aux (R := R) (α := α) hH
      (fun q => q.1 * (1 + √(q.1 ^ 2 + q.2 ^ 2) / 40))).trans ?_
    rw [wedge_polar_change hα]
    rw [setIntegral_congr_fun (measurableSet_Icc.prod measurableSet_Icc)
      (g := fun z : ℝ × ℝ => (z.1 * z.1 * (1 + z.1 / 40)) * cos z.2) ?_]
    · rw [Measure.volume_eq_prod, setIntegral_prod_mul (fun r : ℝ => r * r * (1 + r / 40))
        cos, Icc_integral_aux hR, radial_moment_aux, Icc_integral_aux hα2, integral_cos,
        sin_neg]
      ring
    · rintro ⟨r, θ⟩ hp
      simp only [mem_prod, mem_Icc] at hp
      simp only [sqrt_polar_aux hp.1.1]
      ring

-- The card's wedge: R = 20 cm, H = 10 cm, α = 60 degrees = π/3 radians.
-- Density 1 + r/40: 1 at the tip, 5/4 (1.25) halfway out at r = 10, 3/2 (1.5) at the rind.
example : (1 : ℚ) + 0 / 40 = 1 ∧ (1 : ℚ) + 10 / 40 = 5 / 4 ∧ (1 : ℚ) + 20 / 40 = 3 / 2 := by
  norm_num
-- The radius integral for the mass: 200 + 66.6667 = 800/3 (266.6667).
example : (20 : ℚ) ^ 2 / 2 + 20 ^ 3 / 120 = 800 / 3 := by norm_num
-- The radius integral for the moment: 2666.6667 + 1000 = 11000/3 (3666.6667).
example : (20 : ℚ) ^ 3 / 3 + 20 ^ 4 / 160 = 11000 / 3 := by norm_num
-- The angle factor 2 sin(α/2) is 2 sin(π/6) = 1.
example : 2 * sin (π / 3 / 2) = 1 := by
  rw [show π / 3 / 2 = π / 6 by ring, sin_pi_div_six]; norm_num
-- Volume: α/2 × R² × H = 2000π/3 cm³ (2094.40).
example : π / 3 / 2 * 20 ^ 2 * 10 = 2000 * π / 3 := by ring
-- Mass: α H (R²/2 + R³/120) = 8000π/9 g (2792.53).
example : π / 3 * 10 * (20 ^ 2 / 2 + 20 ^ 3 / 120) = 8000 * π / 9 := by ring
-- Moment: 1 × 10 × 11000/3 = 110000/3 g cm (36666.67).
example : (1 : ℚ) * 10 * (11000 / 3) = 110000 / 3 := by norm_num
-- Centre of mass: (110000/3) / (8000π/9) = 165/(4π) cm (13.1303).
example : (110000 / 3) / (8000 * π / 9) = 165 / (4 * π) := by
  field_simp [pi_ne_zero]; ring
-- Uniform centroid: 4R sin(α/2)/(3α) = 40/π cm (12.7324).
example : 4 * 20 * sin (π / 3 / 2) / (3 * (π / 3)) = 40 / π := by
  rw [show π / 3 / 2 = π / 6 by ring, sin_pi_div_six]; field_simp [pi_ne_zero]; ring
-- Average density: mass over volume, (8000π/9) / (2000π/3) = 4/3 g/cm³ (1.3333).
example : (8000 * π / 9) / (2000 * π / 3) = 4 / 3 := by
  field_simp [pi_ne_zero]; ring
-- Mistake 1, drop the r: α H (R + R²/80) = 250π/3 (261.80).
example : π / 3 * 10 * (20 + 20 ^ 2 / 80) = 250 * π / 3 := by ring
-- Mistake 3, divide the moment by volume: (110000/3) / (2000π/3) = 55/π (17.5070).
example : (110000 / 3) / (2000 * π / 3) = 55 / π := by
  field_simp [pi_ne_zero]; ring

#print axioms triple_integral_eq_iterated
#print axioms centre_of_mass_balances
#print axioms wedge_mass_and_moment
