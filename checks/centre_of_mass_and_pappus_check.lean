-- Centre of mass: a bounded flat region on one side of an axis, spun once round it, sweeps a solid whose volume is the region's area times the circle its centroid travels, so a swim ring holds 2π²Rr² and a half-disc's centroid sits 4r/(3π) up from its flat edge.
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Group.Integral

/-! A flat region is a set `S` of points `p = (p.1, p.2)` in the plane `ℝ × ℝ`: `p.1` is the
distance from the axis and `p.2` the height along it. "On one side of the axis, touching
allowed" is `0 ≤ p.1` for every point of `S`. `volume` is ordinary area on the plane and
ordinary volume in space (Lebesgue measure). The area is `A = (volume S).toReal`, the moment
is `M = ∫ p in S, p.1` (each bit of area weighted by its distance) and the centroid's
distance is `x̄ = M / A`.

Space is `ℝ × ℝ × ℝ`, a point `q = (q.1, q.2.1, q.2.2)`, and the axis is the third
coordinate line. A point of space lies at distance `√(q.1² + q.2.1²)` from the axis and at
height `q.2.2` along it. Spinning `S` once round the axis sweeps every point whose
(distance, height) pair lies in `S`: that set is the solid of revolution. -/

open MeasureTheory Real

lemma solid_volume_eq_lintegral (S : Set (ℝ × ℝ)) (hS : MeasurableSet S) :
    volume {q : ℝ × ℝ × ℝ | (√(q.1 ^ 2 + q.2.1 ^ 2), q.2.2) ∈ S} =
      ENNReal.ofReal (2 * π) * ∫⁻ p in S, ENNReal.ofReal p.1 := by
  set g : ℝ → ENNReal := fun ρ => volume (Prod.mk ρ ⁻¹' S) with hg_def
  have hg : Measurable g := measurable_measure_prodMk_left hS
  have hT : MeasurableSet {q : ℝ × ℝ × ℝ | (√(q.1 ^ 2 + q.2.1 ^ 2), q.2.2) ∈ S} :=
    hS.preimage (by fun_prop)
  have hmp := measurePreserving_prodAssoc (volume : Measure ℝ) (volume : Measure ℝ)
    (volume : Measure ℝ)
  have step1 : volume {q : ℝ × ℝ × ℝ | (√(q.1 ^ 2 + q.2.1 ^ 2), q.2.2) ∈ S} =
      ∫⁻ w : ℝ × ℝ, g (√(w.1 ^ 2 + w.2 ^ 2)) := by
    rw [show (volume : Measure (ℝ × ℝ × ℝ)) = volume.prod (volume.prod volume) from rfl,
      ← hmp.measure_preimage hT.nullMeasurableSet, Measure.prod_apply]
    · rfl
    · exact hT.preimage (MeasurableEquiv.measurable _)
  have step2 : ∫⁻ w : ℝ × ℝ, g (√(w.1 ^ 2 + w.2 ^ 2)) =
      ∫⁻ p in Set.Ioi (0:ℝ) ×ˢ Set.Ioo (-π) π, ENNReal.ofReal p.1 * g p.1 := by
    rw [← lintegral_comp_polarCoord_symm, polarCoord_target]
    refine setLIntegral_congr_fun (measurableSet_Ioi.prod measurableSet_Ioo) (fun p hp => ?_)
    have h1 : (p.1 * cos p.2) ^ 2 + (p.1 * sin p.2) ^ 2 = p.1 ^ 2 := by
      nlinarith [sin_sq_add_cos_sq p.2]
    simp only [polarCoord_symm_apply, smul_eq_mul, h1, sqrt_sq (le_of_lt hp.1)]
  have step3 : ∫⁻ p in Set.Ioi (0:ℝ) ×ˢ Set.Ioo (-π) π, ENNReal.ofReal p.1 * g p.1 =
      (∫⁻ ρ in Set.Ioi (0:ℝ), ENNReal.ofReal ρ * g ρ) * ENNReal.ofReal (2 * π) := by
    rw [Measure.volume_eq_prod, ← Measure.prod_restrict]
    have := lintegral_prod_mul (μ := volume.restrict (Set.Ioi (0:ℝ)))
      (ν := volume.restrict (Set.Ioo (-π) π))
      (f := fun ρ => ENNReal.ofReal ρ * g ρ) (g := fun _ => 1)
      (by fun_prop) aemeasurable_const
    simp only [mul_one, lintegral_one, Measure.restrict_apply_univ, Real.volume_Ioo] at this
    rw [this]
    congr 2
    ring
  have step4 : ∫⁻ p in S, ENNReal.ofReal p.1 =
      ∫⁻ ρ in Set.Ioi (0:ℝ), ENNReal.ofReal ρ * g ρ := by
    rw [← lintegral_indicator hS, Measure.volume_eq_prod,
      lintegral_prod _ ((measurable_fst.ennreal_ofReal.indicator hS).aemeasurable)]
    rw [setLIntegral_eq_of_support_subset]
    · congr 1
      funext ρ
      have : ∀ z, S.indicator (fun p : ℝ × ℝ => ENNReal.ofReal p.1) (ρ, z) =
          (Prod.mk ρ ⁻¹' S).indicator (fun _ => ENNReal.ofReal ρ) z := fun z => rfl
      simp_rw [this]
      rw [lintegral_indicator_const (measurable_prodMk_left hS)]
    · intro ρ hρ
      simp only [Set.mem_Ioi]
      by_contra h
      apply hρ
      simp [ENNReal.ofReal_eq_zero.mpr (not_lt.mp h)]
  rw [step1, step2, step3, step4, mul_comm]

#print axioms solid_volume_eq_lintegral

lemma setIntegral_polar_shift (f : ℝ × ℝ → ℝ) (c : ℝ × ℝ) (D Q : Set (ℝ × ℝ))
    (hD : MeasurableSet D) (hQ : MeasurableSet Q)
    (h : ∀ p ∈ polarCoord.target, polarCoord.symm p + c ∈ D ↔ p ∈ Q) :
    ∫ p in D, f p = ∫ p in polarCoord.target ∩ Q, p.1 * f (polarCoord.symm p + c) := by
  rw [← integral_indicator hD, ← integral_add_right_eq_self _ c,
    ← integral_comp_polarCoord_symm, ← setIntegral_indicator hQ]
  refine setIntegral_congr_fun polarCoord.open_target.measurableSet (fun p hp => ?_)
  by_cases hq : p ∈ Q
  · have hd : polarCoord.symm p + c ∈ D := (h p hp).mpr hq
    show p.1 • D.indicator f (polarCoord.symm p + c) = Q.indicator _ p
    rw [Set.indicator_of_mem hq, Set.indicator_of_mem hd, smul_eq_mul]
  · have hd : polarCoord.symm p + c ∉ D := fun hd => hq ((h p hp).mp hd)
    show p.1 • D.indicator f (polarCoord.symm p + c) = Q.indicator _ p
    rw [Set.indicator_of_notMem hq, Set.indicator_of_notMem hd, smul_zero]

#print axioms setIntegral_polar_shift

lemma setIntegral_prod_mul' (s t : Set ℝ) (f g : ℝ → ℝ) :
    ∫ p in s ×ˢ t, f p.1 * g p.2 = (∫ x in s, f x) * ∫ y in t, g y := by
  rw [Measure.volume_eq_prod, ← Measure.prod_restrict, integral_prod_mul]

#print axioms setIntegral_prod_mul'

lemma integral_Ioc_sq (r : ℝ) (hr : 0 ≤ r) : ∫ x in Set.Ioc 0 r, x * x = r ^ 3 / 3 := by
  rw [← intervalIntegral.integral_of_le hr]
  simp_rw [← sq]
  simp [integral_pow]
  norm_num

#print axioms integral_Ioc_sq

lemma integral_Ioc_id (r : ℝ) (hr : 0 ≤ r) : ∫ x in Set.Ioc 0 r, x = r ^ 2 / 2 := by
  rw [← intervalIntegral.integral_of_le hr]
  simp [integral_id]

#print axioms integral_Ioc_id

lemma polar_sq (ρ θ : ℝ) (hρ : 0 < ρ) (r : ℝ) (hr : 0 ≤ r) :
    (ρ * cos θ) ^ 2 + (ρ * sin θ) ^ 2 ≤ r ^ 2 ↔ ρ ≤ r := by
  have h1 : (ρ * cos θ) ^ 2 + (ρ * sin θ) ^ 2 = ρ ^ 2 := by
    nlinarith [sin_sq_add_cos_sq θ]
  rw [h1]
  exact pow_le_pow_iff_left₀ hρ.le hr two_ne_zero

#print axioms polar_sq

lemma toReal_volume_eq_setIntegral_one (D : Set (ℝ × ℝ)) :
    (volume D).toReal = ∫ _ in D, (1 : ℝ) := by
  rw [setIntegral_const, smul_eq_mul, mul_one, measureReal_def]

#print axioms toReal_volume_eq_setIntegral_one

lemma half_disc_polar (r : ℝ) (hr : 0 < r) (f : ℝ × ℝ → ℝ) :
    ∫ p in {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ r ^ 2 ∧ 0 ≤ p.2}, f p =
      ∫ p in Set.Ioc 0 r ×ˢ Set.Ico 0 π, p.1 * f (polarCoord.symm p + 0) := by
  have hQ : MeasurableSet (Set.Iic r ×ˢ Set.Ici (0:ℝ)) := measurableSet_Iic.prod measurableSet_Ici
  have hD : MeasurableSet {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ r ^ 2 ∧ 0 ≤ p.2} :=
    (measurableSet_le (by fun_prop : Measurable fun p : ℝ × ℝ => p.1 ^ 2 + p.2 ^ 2)
      measurable_const).inter (measurableSet_le measurable_const measurable_snd)
  rw [setIntegral_polar_shift f 0 _ (Set.Iic r ×ˢ Set.Ici 0) hD hQ]
  · congr 2
    ext ⟨a, b⟩
    simp only [polarCoord_target, Set.mem_inter_iff, Set.mem_prod, Set.mem_Ioi, Set.mem_Ioo,
      Set.mem_Iic, Set.mem_Ici, Set.mem_Ioc, Set.mem_Ico]
    constructor
    · rintro ⟨⟨h1, h2, h3⟩, h4, h5⟩; exact ⟨⟨h1, h4⟩, h5, h3⟩
    · rintro ⟨⟨h1, h4⟩, h5, h3⟩; exact ⟨⟨h1, by linarith [pi_pos], h3⟩, h4, h5⟩
  · rintro ⟨a, b⟩ ⟨ha, hb⟩
    simp only [Set.mem_Ioi, Set.mem_Ioo] at ha hb
    simp only [polarCoord_symm_apply, add_zero, Set.mem_ofPred_eq, Set.mem_prod, Set.mem_Iic,
      Set.mem_Ici, polar_sq a b ha r hr.le]
    apply and_congr Iff.rfl
    constructor
    · intro h
      by_contra hb'
      have := sin_neg_of_neg_of_neg_pi_lt (not_le.mp hb') hb.1
      nlinarith
    · intro h
      exact mul_nonneg ha.le (sin_nonneg_of_nonneg_of_le_pi h hb.2.le)

#print axioms half_disc_polar

lemma half_disc_area (r : ℝ) (hr : 0 < r) :
    (volume {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ r ^ 2 ∧ 0 ≤ p.2}).toReal = π * r ^ 2 / 2 := by
  rw [toReal_volume_eq_setIntegral_one, half_disc_polar r hr,
    setIntegral_prod_mul' _ _ (fun x => x) (fun _ => 1), integral_Ioc_id r hr.le,
    setIntegral_const, smul_eq_mul, mul_one, measureReal_def, Real.volume_Ico,
    ENNReal.toReal_ofReal (by linarith [pi_pos])]
  ring

#print axioms half_disc_area

lemma half_disc_moment (r : ℝ) (hr : 0 < r) :
    ∫ p in {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ r ^ 2 ∧ 0 ≤ p.2}, p.2 = 2 * r ^ 3 / 3 := by
  rw [half_disc_polar r hr]
  simp only [polarCoord_symm_apply, add_zero]
  simp_rw [← mul_assoc]
  rw [setIntegral_prod_mul' _ _ (fun x => x * x) sin, integral_Ioc_sq r hr.le,
    integral_Ico_eq_integral_Ioc, ← intervalIntegral.integral_of_le pi_pos.le, integral_sin]
  simp
  ring

#print axioms half_disc_moment

lemma disc_polar (R r : ℝ) (hr : 0 ≤ r) (f : ℝ × ℝ → ℝ) :
    ∫ p in {p : ℝ × ℝ | (p.1 - R) ^ 2 + p.2 ^ 2 ≤ r ^ 2}, f p =
      ∫ p in Set.Ioc 0 r ×ˢ Set.Ioo (-π) π, p.1 * f (polarCoord.symm p + (R, 0)) := by
  have hQ : MeasurableSet (Set.Iic r ×ˢ (Set.univ : Set ℝ)) :=
    measurableSet_Iic.prod MeasurableSet.univ
  have hD : MeasurableSet {p : ℝ × ℝ | (p.1 - R) ^ 2 + p.2 ^ 2 ≤ r ^ 2} :=
    measurableSet_le (by fun_prop : Measurable fun p : ℝ × ℝ => (p.1 - R) ^ 2 + p.2 ^ 2)
      measurable_const
  rw [setIntegral_polar_shift f (R, 0) _ (Set.Iic r ×ˢ Set.univ) hD hQ]
  · congr 2
    ext ⟨a, b⟩
    simp only [polarCoord_target, Set.mem_inter_iff, Set.mem_prod, Set.mem_Ioi, Set.mem_Ioo,
      Set.mem_Iic, Set.mem_univ, Set.mem_Ioc]
    tauto
  · rintro ⟨a, b⟩ ⟨ha, hb⟩
    simp only [Set.mem_Ioi] at ha
    simp only [polarCoord_symm_apply, Prod.mk_add_mk, add_zero, add_sub_cancel_right,
      Set.mem_ofPred_eq, Set.mem_prod, Set.mem_Iic, Set.mem_univ, and_true,
      polar_sq a b ha r hr]

#print axioms disc_polar

lemma integral_Ioo_one : ∫ _ in Set.Ioo (-π) π, (1 : ℝ) = 2 * π := by
  rw [setIntegral_const, smul_eq_mul, mul_one, measureReal_def, Real.volume_Ioo,
    ENNReal.toReal_ofReal (by linarith [pi_pos])]
  ring

#print axioms integral_Ioo_one

lemma disc_area (R r : ℝ) (hr : 0 ≤ r) :
    (volume {p : ℝ × ℝ | (p.1 - R) ^ 2 + p.2 ^ 2 ≤ r ^ 2}).toReal = π * r ^ 2 := by
  rw [toReal_volume_eq_setIntegral_one, disc_polar R r hr,
    setIntegral_prod_mul' _ _ (fun x => x) (fun _ => 1), integral_Ioc_id r hr,
    integral_Ioo_one]
  ring

#print axioms disc_area

lemma disc_moment (R r : ℝ) (hr : 0 ≤ r) :
    ∫ p in {p : ℝ × ℝ | (p.1 - R) ^ 2 + p.2 ^ 2 ≤ r ^ 2}, p.1 = π * r ^ 2 * R := by
  rw [disc_polar R r hr]
  simp only [polarCoord_symm_apply, Prod.mk_add_mk, add_zero]
  have hK : IsCompact (Set.Icc 0 r ×ˢ Set.Icc (-π) π) := isCompact_Icc.prod isCompact_Icc
  have hsub : Set.Ioc 0 r ×ˢ Set.Ioo (-π) π ⊆ Set.Icc 0 r ×ˢ Set.Icc (-π) π :=
    Set.prod_mono Set.Ioc_subset_Icc_self Set.Ioo_subset_Icc_self
  have e : ∀ p : ℝ × ℝ, p.1 * (p.1 * cos p.2 + R) = p.1 * p.1 * cos p.2 + R * p.1 * 1 := by
    intro p; ring
  simp_rw [e]
  rw [integral_add, setIntegral_prod_mul' _ _ (fun x => x * x) cos,
    setIntegral_prod_mul' _ _ (fun x => R * x) (fun _ => 1), integral_Ioo_one,
    ← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le (by linarith [pi_pos] : -π ≤ π),
    integral_cos, integral_const_mul, integral_Ioc_id r hr]
  · simp
    ring
  · exact ((by fun_prop : Continuous fun p : ℝ × ℝ => p.1 * p.1 * cos p.2).continuousOn.integrableOn_compact hK).mono_set hsub
  · exact ((by fun_prop : Continuous fun p : ℝ × ℝ => R * p.1 * 1).continuousOn.integrableOn_compact hK).mono_set hsub

#print axioms disc_moment

/-- Pappus's theorem. Take a flat region that has an area (a measurable set) and fits in a
finite box (bounded), lying on one side of the axis in its own plane (touching allowed).
Spin it one full turn round the axis. The solid it sweeps has volume equal to the region's
area `A` times the length `2π x̄` of the circle its centroid travels, where the centroid's
distance `x̄` is the moment `∫ x dA` divided by the area. -/
theorem pappus_volume_eq_area_times_centroid_path (S : Set (ℝ × ℝ))
    (hS : MeasurableSet S) (hbdd : Bornology.IsBounded S) (hside : ∀ p ∈ S, 0 ≤ p.1) :
    volume {q : ℝ × ℝ × ℝ | (√(q.1 ^ 2 + q.2.1 ^ 2), q.2.2) ∈ S} =
      ENNReal.ofReal
        ((volume S).toReal * (2 * π * ((∫ p in S, p.1) / (volume S).toReal))) := by
  have hfin : volume S < ⊤ := hbdd.measure_lt_top
  have hint : IntegrableOn (fun p : ℝ × ℝ => p.1) S :=
    (continuous_fst.continuousOn.integrableOn_compact hbdd.isCompact_closure).mono_set
      subset_closure
  have hL : ∫⁻ p in S, ENNReal.ofReal p.1 = ENNReal.ofReal (∫ p in S, p.1) :=
    (ofReal_integral_eq_lintegral_ofReal hint (ae_restrict_of_forall_mem hS hside)).symm
  rw [solid_volume_eq_lintegral S hS, hL, ← ENNReal.ofReal_mul (by positivity)]
  congr 1
  rcases eq_or_ne (volume S).toReal 0 with h | h
  · have h0 : volume S = 0 := by
      rcases ENNReal.toReal_eq_zero_iff _ |>.mp h with h' | h'
      · exact h'
      · exact absurd h' hfin.ne
    have hM : ∫ p in S, p.1 = 0 := by
      rw [Measure.restrict_eq_zero.mpr h0, integral_zero_measure]
    simp [h, hM]
  · field_simp

/-- The swim ring. A circle of radius `r` whose middle is `R` from the axis, with `r ≤ R`
so it does not cross the axis (touching allowed), spun once round the axis sweeps a torus
of volume `π r² × 2π R = 2π² R r²`. -/
theorem torus_volume_eq_two_pi_sq_mul (R r : ℝ) (hr : 0 ≤ r) (hrR : r ≤ R) :
    volume {q : ℝ × ℝ × ℝ | (√(q.1 ^ 2 + q.2.1 ^ 2) - R) ^ 2 + q.2.2 ^ 2 ≤ r ^ 2} =
      ENNReal.ofReal (2 * π ^ 2 * R * r ^ 2) := by
  set D : Set (ℝ × ℝ) := {p : ℝ × ℝ | (p.1 - R) ^ 2 + p.2 ^ 2 ≤ r ^ 2} with hD_def
  have hD : MeasurableSet D :=
    measurableSet_le (by fun_prop : Measurable fun p : ℝ × ℝ => (p.1 - R) ^ 2 + p.2 ^ 2)
      measurable_const
  have hbound : ∀ p ∈ D, |p.1 - R| ≤ r ∧ |p.2| ≤ r := by
    intro p hp
    have hp' : (p.1 - R) ^ 2 + p.2 ^ 2 ≤ r ^ 2 := hp
    constructor
    · exact abs_le_of_sq_le_sq' (by nlinarith [sq_nonneg p.2]) hr |> fun h => abs_le.mpr h
    · exact abs_le_of_sq_le_sq' (by nlinarith [sq_nonneg (p.1 - R)]) hr |> fun h => abs_le.mpr h
  have hbdd : Bornology.IsBounded D := by
    refine ((Metric.isBounded_Icc (R - r) (R + r)).prod (Metric.isBounded_Icc (-r) r)).subset ?_
    intro p hp
    obtain ⟨h1, h2⟩ := hbound p hp
    rw [abs_le] at h1 h2
    exact ⟨⟨by linarith, by linarith⟩, ⟨by linarith, by linarith⟩⟩
  have hside : ∀ p ∈ D, 0 ≤ p.1 := by
    intro p hp
    obtain ⟨h1, -⟩ := hbound p hp
    rw [abs_le] at h1
    linarith
  have := pappus_volume_eq_area_times_centroid_path D hD hbdd hside
  rw [show {q : ℝ × ℝ × ℝ | (√(q.1 ^ 2 + q.2.1 ^ 2) - R) ^ 2 + q.2.2 ^ 2 ≤ r ^ 2} =
    {q : ℝ × ℝ × ℝ | (√(q.1 ^ 2 + q.2.1 ^ 2), q.2.2) ∈ D} from rfl, this,
    disc_area R r hr, disc_moment R r hr]
  congr 1
  rcases eq_or_ne r 0 with h | h
  · subst h; simp
  · have := pi_pos
    field_simp

/-- A centroid that is not in the middle. A half-disc of radius `r > 0`, flat edge down on
the line `y = 0`, has its centroid `4r / (3π)` above the flat edge: its moment about the
edge, `∫ y dA`, divided by its area. -/
theorem half_disc_centroid_height (r : ℝ) (hr : 0 < r) :
    (∫ p in {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ r ^ 2 ∧ 0 ≤ p.2}, p.2) /
        (volume {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ r ^ 2 ∧ 0 ≤ p.2}).toReal =
      4 * r / (3 * π) := by
  rw [half_disc_moment r hr, half_disc_area r hr]
  have := pi_pos
  field_simp
  ring

-- The card's numbers, as exact fractions (metres; r = 1/10, R = 3/10).
-- One strip (Step 0): a thin ring between x and x + Δx, height h, is the strip's area h Δx
-- times the circle its middle travels.
example (x Δx h : ℝ) : π * ((x + Δx) ^ 2 - x ^ 2) * h = 2 * π * (x + Δx / 2) * (h * Δx) := by
  ring
-- Swim ring: area π r² times path 2π R is 2π² R r² = (3/500) π² m³.
example : π * (1 / 10 : ℝ) ^ 2 * (2 * π * (3 / 10)) = 2 * π ^ 2 * (3 / 10) * (1 / 10) ^ 2 := by
  ring
example : 2 * π ^ 2 * (3 / 10 : ℝ) * (1 / 10) ^ 2 = 3 / 500 * π ^ 2 := by ring
-- Half-disc moment: 2 r³ / 3 = 2 × (1/10)³ / 3 = 1/1500 m³.
example : (2 : ℚ) * (1 / 10) ^ 3 / 3 = 1 / 1500 := by norm_num
-- Half-disc spun on its flat edge: area (π r²/2) × 2π × 4r/(3π) is the ball's 4/3 π r³.
example (r : ℝ) : (π * r ^ 2 / 2) * (2 * π * (4 * r / (3 * π))) = 4 / 3 * π * r ^ 3 := by
  field_simp
-- Mistakes: the outer edge 4/10 gives 4/3 of the right volume, the inner edge 2/10 gives 2/3.
example : (4 / 10 : ℚ) / (3 / 10) = 4 / 3 ∧ (2 / 10 : ℚ) / (3 / 10) = 2 / 3 := by norm_num

#print axioms pappus_volume_eq_area_times_centroid_path
#print axioms torus_volume_eq_two_pi_sq_mul
#print axioms half_disc_centroid_height
