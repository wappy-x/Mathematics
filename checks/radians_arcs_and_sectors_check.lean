-- Radians: on a circle of radius r centred at the corner, the arc cut by an angle of θ radians has length r × θ, the sector it cuts has area r² × θ / 2 when θ is at most one turn, and arc over radius does not depend on the circle's size.
import Mathlib.Topology.EMetricSpace.BoundedVariation
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.MeasureTheory.Measure.Lebesgue.Complex
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Complex MeasureTheory Set

theorem rim_dist (r x y : ℝ) (hr : 0 ≤ r) :
    dist ((r : ℂ) * exp ((x : ℂ) * I)) ((r : ℂ) * exp ((y : ℂ) * I)) =
      r * ‖exp (I * ((x - y : ℝ) : ℂ)) - 1‖ := by
  rw [dist_eq_norm]
  have he : (y : ℂ) * I + I * ((x - y : ℝ) : ℂ) = (x : ℂ) * I := by push_cast; ring
  have h : (r : ℂ) * exp ((x : ℂ) * I) - (r : ℂ) * exp ((y : ℂ) * I) =
      (r : ℂ) * exp ((y : ℂ) * I) * (exp (I * ((x - y : ℝ) : ℂ)) - 1) := by
    rw [mul_sub, mul_one, mul_assoc, ← exp_add, he]
  rw [h, norm_mul, norm_mul, norm_exp_ofReal_mul_I, Complex.norm_of_nonneg hr, mul_one]

#print axioms rim_dist

theorem rim_lipschitz (r : ℝ) (hr : 0 ≤ r) :
    LipschitzWith (Real.toNNReal r) (fun t : ℝ => (r : ℂ) * exp ((t : ℂ) * I)) := by
  refine LipschitzWith.of_dist_le_mul fun x y => ?_
  rw [rim_dist r x y hr, Real.coe_toNNReal r hr, Real.dist_eq]
  gcongr
  exact (Real.norm_exp_I_mul_ofReal_sub_one_le (x := x - y)).trans (le_of_eq (Real.norm_eq_abs _))

#print axioms rim_lipschitz

theorem chord_lower (h : ℝ) (hh : 0 < h) : h - h ^ 3 / 24 ≤ ‖exp (I * (h : ℂ)) - 1‖ := by
  rw [norm_exp_I_mul_ofReal_sub_one, Real.norm_eq_abs]
  have := Real.sin_gt_sub_cube (x := h / 2) (by positivity)
  calc h - h ^ 3 / 24 = 2 * (h / 2 - (h / 2) ^ 3 / 6) := by ring
    _ ≤ 2 * Real.sin (h / 2) := by linarith
    _ ≤ |2 * Real.sin (h / 2)| := le_abs_self _

#print axioms chord_lower

theorem polar_symm_injOn_Ioo (r θ : ℝ) (hturn : θ ≤ 2 * Real.pi) :
    InjOn polarCoord.symm (Ioo 0 r ×ˢ Ioo 0 θ) := by
  rintro ⟨a, φ⟩ ⟨ha, hφ⟩ ⟨b, ψ⟩ ⟨hb, hψ⟩ h
  simp only [mem_Ioo] at ha hφ hb hψ
  have key : polarCoord.symm (a, φ - Real.pi) = polarCoord.symm (b, ψ - Real.pi) := by
    simp only [polarCoord_symm_apply, Real.cos_sub_pi, Real.sin_sub_pi, Prod.ext_iff] at h ⊢
    simp [mul_neg, h.1, h.2]
  have hmem : ∀ c ψ : ℝ, 0 < c → 0 < ψ → ψ < θ → (c, ψ - Real.pi) ∈ polarCoord.symm.source := by
    intro c ψ hc h0 h1
    rw [OpenPartialHomeomorph.symm_source, polarCoord_target]
    exact ⟨hc, by constructor <;> linarith⟩
  have := polarCoord.symm.injOn (hmem a φ ha.1 hφ.1 hφ.2) (hmem b ψ hb.1 hψ.1 hψ.2) key
  simp only [Prod.ext_iff] at this ⊢
  exact ⟨this.1, by linarith [this.2]⟩

#print axioms polar_symm_injOn_Ioo

theorem rect_lintegral (r θ : ℝ) (hr : 0 ≤ r) :
    ∫⁻ p in Icc 0 r ×ˢ Icc 0 θ, ENNReal.ofReal |p.1| = ENNReal.ofReal (r ^ 2 * θ / 2) := by
  rw [Measure.volume_eq_prod, ← Measure.prod_restrict,
    lintegral_prod _ (by fun_prop)]
  simp only [lintegral_const, Measure.restrict_apply_univ, Real.volume_Icc, sub_zero]
  rw [lintegral_mul_const _ (by fun_prop)]
  have h1 : ∫⁻ x in Icc 0 r, ENNReal.ofReal |x| = ∫⁻ x in Icc 0 r, ENNReal.ofReal x :=
    setLIntegral_congr_fun measurableSet_Icc (fun x hx => by rw [abs_of_nonneg hx.1])
  have hint : IntegrableOn (fun x : ℝ => x) (Icc 0 r) := continuous_id.integrableOn_Icc
  rw [h1, ← ofReal_integral_eq_lintegral_ofReal hint
    ((ae_restrict_mem measurableSet_Icc).mono fun x hx => hx.1),
    integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le hr, integral_id,
    ← ENNReal.ofReal_mul (by norm_num; positivity)]
  congr 1
  ring

#print axioms rect_lintegral

/-- The arc formula, s = r θ. Put the corner of an angle of θ radians (θ ≥ 0) at the centre of a
circle of radius r, here the complex plane with centre 0. Walk the rim from angle 0 to angle θ:
the point r × e^(i t) for t from 0 to θ. The length of that arc (the limit of totals of straight
chords along it, Mathlib's `eVariationOn`) is exactly r × θ. Past one full turn it is the
distance the rim travels. -/
theorem arc_length_eq_radius_mul_angle (r θ : ℝ) (hr : 0 ≤ r) (hθ : 0 ≤ θ) :
    eVariationOn (fun t : ℝ => (r : ℂ) * exp ((t : ℂ) * I)) (Icc 0 θ) = ENNReal.ofReal (r * θ) := by
  set f := fun t : ℝ => (r : ℂ) * exp ((t : ℂ) * I) with hf
  apply le_antisymm
  · have h1 := ((rim_lipschitz r hr).lipschitzOnWith (s := univ)).comp_eVariationOn_le
      (g := id) (s := Icc 0 θ) (mapsTo_univ _ _)
    rw [eVariationOn_id_Icc] at h1
    calc eVariationOn f (Icc 0 θ) = eVariationOn (f ∘ id) (Icc 0 θ) := rfl
      _ ≤ _ := h1
      _ = ENNReal.ofReal (r * θ) := by rw [sub_zero, ENNReal.ofReal_mul hr]; rfl
  · rcases hθ.eq_or_lt with h0 | hpos
    · subst h0; simp
    apply ENNReal.le_of_forall_pos_le_add
    intro ε hε _
    obtain ⟨n, hn⟩ := exists_nat_gt (r * θ ^ 3 / (24 * ε))
    set N : ℕ := n + 1 with hN
    have hNpos : (0 : ℝ) < N := by positivity
    have hnN : (n : ℝ) ≤ N := by simp [hN]
    have hN1 : (1 : ℝ) ≤ N := by simp [hN]
    set u : ℕ → ℝ := fun i => ((min i N : ℕ) : ℝ) * (θ / N) with hu_def
    have hu : Monotone u := fun i j hij => by
      simp only [hu_def]
      gcongr
    have us : ∀ i, u i ∈ Icc 0 θ := fun i => by
      simp only [hu_def, mem_Icc]
      constructor
      · positivity
      · have : ((min i N : ℕ) : ℝ) ≤ N := by exact_mod_cast min_le_right i N
        calc ((min i N : ℕ) : ℝ) * (θ / N) ≤ N * (θ / N) := by gcongr
          _ = θ := by field_simp
    have hsum := eVariationOn.sum_le (f := f) (n := N) hu us
    set c := ‖exp (I * ((θ / N : ℝ) : ℂ)) - 1‖ with hc_def
    have hterm : ∀ i ∈ Finset.range N,
        edist (f (u (i + 1))) (f (u i)) = ENNReal.ofReal (r * c) := by
      intro i hi
      have hi' : i < N := Finset.mem_range.1 hi
      have hd : u (i + 1) - u i = θ / N := by
        simp only [hu_def, Nat.min_eq_left hi', Nat.min_eq_left hi'.le]
        push_cast; ring
      rw [edist_dist, hf, rim_dist r _ _ hr, hd]
    rw [Finset.sum_congr rfl hterm, Finset.sum_const, Finset.card_range, nsmul_eq_mul] at hsum
    have hc := chord_lower (θ / N) (by positivity)
    have hsmall : r * θ ^ 3 / (24 * (N : ℝ) ^ 2) ≤ ε := by
      rw [div_lt_iff₀ (by positivity)] at hn
      rw [div_le_iff₀ (by positivity)]
      have : (n : ℝ) ≤ (N : ℝ) ^ 2 := by nlinarith
      have h24 : (0 : ℝ) ≤ 24 * (ε : ℝ) := by positivity
      have := mul_le_mul_of_nonneg_left this h24
      nlinarith
    have key : r * θ ≤ N * (r * c) + ε := by
      have h2 : (N : ℝ) * (r * c) ≥ r * θ - r * θ ^ 3 / (24 * (N : ℝ) ^ 2) := by
        calc (N : ℝ) * (r * c) ≥ N * (r * (θ / N - (θ / N) ^ 3 / 24)) := by gcongr
          _ = r * θ - r * θ ^ 3 / (24 * (N : ℝ) ^ 2) := by field_simp
      linarith
    calc ENNReal.ofReal (r * θ) ≤ ENNReal.ofReal (N * (r * c) + ε) := ENNReal.ofReal_le_ofReal key
      _ ≤ ENNReal.ofReal (N * (r * c)) + ENNReal.ofReal ε := ENNReal.ofReal_add_le
      _ = (N : ENNReal) * ENNReal.ofReal (r * c) + ε := by
        rw [ENNReal.ofReal_mul (Nat.cast_nonneg _), ENNReal.ofReal_natCast, ENNReal.ofReal_coe_nnreal]
      _ ≤ eVariationOn f (Icc 0 θ) + ε := by gcongr

/-- The sector formula, A = r² θ / 2. The slice cut from the centre of a circle of radius r by an
angle of θ radians, at most one full turn (0 ≤ θ ≤ 2π), is every point ρ × e^(i φ) with
0 ≤ ρ ≤ r and 0 ≤ φ ≤ θ. Its area (Lebesgue measure in the plane) is exactly r² × θ / 2. -/
theorem sector_area_eq_half_radius_sq_mul_angle (r θ : ℝ) (hr : 0 ≤ r) (hθ : 0 ≤ θ)
    (hturn : θ ≤ 2 * Real.pi) :
    volume {z : ℂ | ∃ ρ ∈ Icc 0 r, ∃ φ ∈ Icc 0 θ, z = (ρ : ℂ) * exp ((φ : ℂ) * I)} =
      ENNReal.ofReal (r ^ 2 * θ / 2) := by
  have hS : {z : ℂ | ∃ ρ ∈ Icc 0 r, ∃ φ ∈ Icc 0 θ, z = (ρ : ℂ) * exp ((φ : ℂ) * I)} =
      measurableEquivRealProd.symm '' (polarCoord.symm '' (Icc 0 r ×ˢ Icc 0 θ)) := by
    rw [image_image]
    ext z
    simp only [mem_ofPred_eq, mem_image, Prod.exists, mem_prod,
      measurableEquivRealProd_symm_polarCoord_symm_apply, Complex.polarCoord_symm_apply,
      exp_mul_I, ← ofReal_cos, ← ofReal_sin]
    constructor
    · rintro ⟨ρ, hρ, φ, hφ, rfl⟩
      exact ⟨ρ, φ, ⟨hρ, hφ⟩, rfl⟩
    · rintro ⟨ρ, φ, ⟨hρ, hφ⟩, rfl⟩
      exact ⟨ρ, hρ, φ, hφ, rfl⟩
  rw [hS, MeasurableEquiv.image_symm,
    Complex.volume_preserving_equiv_real_prod.measure_preimage_equiv]
  apply le_antisymm
  · refine (addHaar_image_le_lintegral_abs_det_fderiv volume
      (measurableSet_Icc.prod measurableSet_Icc)
      (fun p _ => (hasFDerivAt_polarCoord_symm p).hasFDerivWithinAt)).trans (le_of_eq ?_)
    simp_rw [det_fderivPolarCoordSymm]
    exact rect_lintegral r θ hr
  · have hae : (Ioo 0 r ×ˢ Ioo 0 θ : Set (ℝ × ℝ)) =ᵐ[volume] Icc 0 r ×ˢ Icc 0 θ := by
      rw [Measure.volume_eq_prod]
      exact Measure.set_prod_ae_eq Ioo_ae_eq_Icc Ioo_ae_eq_Icc
    calc ENNReal.ofReal (r ^ 2 * θ / 2)
        = ∫⁻ p in Ioo 0 r ×ˢ Ioo 0 θ, ENNReal.ofReal |(fderivPolarCoordSymm p).det| := by
          simp_rw [det_fderivPolarCoordSymm]
          rw [Measure.restrict_congr_set hae, rect_lintegral r θ hr]
      _ = volume (polarCoord.symm '' (Ioo 0 r ×ˢ Ioo 0 θ)) :=
          lintegral_abs_det_fderiv_eq_addHaar_image volume
            (measurableSet_Ioo.prod measurableSet_Ioo)
            (fun p _ => (hasFDerivAt_polarCoord_symm p).hasFDerivWithinAt)
            (polar_symm_injOn_Ioo r θ hturn)
      _ ≤ volume (polarCoord.symm '' (Icc 0 r ×ˢ Icc 0 θ)) :=
          measure_mono (image_mono (prod_mono Ioo_subset_Icc_self Ioo_subset_Icc_self))

/-- Step 0: arc over radius belongs to the angle, not to the pizza. Cut the same angle θ (θ ≥ 0)
from two circles of radii r₁ and r₂ (both positive): the arc divided by the radius comes out the
same, so it can measure the angle. -/
theorem arc_over_radius_ignores_circle_size (r₁ r₂ θ : ℝ) (h₁ : 0 < r₁) (h₂ : 0 < r₂)
    (hθ : 0 ≤ θ) :
    (eVariationOn (fun t : ℝ => (r₁ : ℂ) * exp ((t : ℂ) * I)) (Icc 0 θ)).toReal / r₁ =
      (eVariationOn (fun t : ℝ => (r₂ : ℂ) * exp ((t : ℂ) * I)) (Icc 0 θ)).toReal / r₂ := by
  rw [arc_length_eq_radius_mul_angle r₁ θ h₁.le hθ, arc_length_eq_radius_mul_angle r₂ θ h₂.le hθ,
    ENNReal.toReal_ofReal (by positivity), ENNReal.toReal_ofReal (by positivity),
    mul_div_cancel_left₀ _ h₁.ne', mul_div_cancel_left₀ _ h₂.ne']

-- The card's slice: 60 degrees is π/3 radians.
example : (60 : ℝ) * Real.pi / 180 = Real.pi / 3 := by ring
-- A full turn, 360 degrees, is 2π radians; 180 degrees is π radians.
example : (360 : ℝ) * Real.pi / 180 = 2 * Real.pi := by ring
example : (180 : ℝ) * Real.pi / 180 = Real.pi := by ring
-- Crust of the slice, radius 15: s = 15 × π/3 = 5π, a sixth of the rim 2π × 15.
example : (15 : ℝ) * (Real.pi / 3) = 5 * Real.pi := by ring
example : (15 : ℝ) * (Real.pi / 3) = 2 * Real.pi * 15 / 6 := by ring
-- Pizza on the slice: A = 15² × (π/3) / 2 = 75π/2, a sixth of π × 15².
example : (15 : ℝ) ^ 2 * (Real.pi / 3) / 2 = 75 * Real.pi / 2 := by ring
example : (15 : ℝ) ^ 2 * (Real.pi / 3) / 2 = Real.pi * 15 ^ 2 / 6 := by ring
-- Second case: 20 cm of crust on radius 15 is 4/3 rad, and its area is 15 × 20 / 2 = 150.
example : (20 : ℚ) / 15 = 4 / 3 := by norm_num
example : (15 : ℚ) * 20 / 2 = 150 := by norm_num
example : (15 : ℚ) ^ 2 * (20 / 15) / 2 = 150 := by norm_num
-- The usual mistake: 60 fed in as radians gives 15 × 60 = 900 cm of crust and 15² × 60 / 2 = 6750.
example : (15 : ℕ) * 60 = 900 := by decide
example : (15 : ℚ) ^ 2 * 60 / 2 = 6750 := by norm_num

#print axioms arc_length_eq_radius_mul_angle
#print axioms sector_area_eq_half_radius_sq_mul_angle
#print axioms arc_over_radius_ignores_circle_size
