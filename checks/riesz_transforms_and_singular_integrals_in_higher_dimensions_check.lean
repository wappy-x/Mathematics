-- Riesz transforms: the Riesz multipliers -i ξⱼ/|ξ| turn the source of -Δu = f into ∂ᵢ∂ⱼu and square-sum to -1, the mixed multiplier has size at most 1/2, and the kernel x₁x₂/(π|x|⁴) meets the size and cancellation conditions.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
import Mathlib.MeasureTheory.Integral.IntegrableOn
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set

open Complex

lemma riesz_aux_mul (a b r : ℝ) :
    (-I * (a : ℂ) / (r : ℂ)) * (-I * (b : ℂ) / (r : ℂ)) = ((-(a * b) / r ^ 2 : ℝ) : ℂ) := by
  push_cast
  ring_nf
  rw [I_sq]
  ring

lemma riesz_aux_two_mul_abs_le {n : ℕ} (x : EuclideanSpace ℝ (Fin n)) (i j : Fin n) (hij : i ≠ j) :
    2 * |x i * x j| ≤ ‖x‖ ^ 2 := by
  rw [EuclideanSpace.real_norm_sq_eq]
  have h1 : ∑ k ∈ ({i, j} : Finset (Fin n)), x k ^ 2 ≤ ∑ k, x k ^ 2 :=
    Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _) (fun k _ _ => sq_nonneg _)
  rw [Finset.sum_pair hij] at h1
  rcases abs_cases (x i * x j) with ⟨h, _⟩ | ⟨h, _⟩ <;> rw [h] <;>
    nlinarith [sq_nonneg (x i - x j), sq_nonneg (x i + x j)]

#print axioms riesz_aux_mul
#print axioms riesz_aux_two_mul_abs_le

/-- The Riesz multipliers and Poisson's equation, in every dimension n.
At a nonzero frequency ξ, the multiplier of `R_i R_j`, namely `(-i ξᵢ/|ξ|)(-i ξⱼ/|ξ|)`,
equals the multiplier `(2πi ξᵢ)(2πi ξⱼ)` of `∂ᵢ∂ⱼ` divided by the multiplier `4π²|ξ|²`
of `-Δ`; so `∂ᵢ∂ⱼ u = R_i R_j f` when `-Δu = f`. And the squares of the Riesz
multipliers add up to `-1`, which is `∑ⱼ R_j² = -I`. -/
theorem riesz_multipliers_give_second_derivatives_and_square_sum
    {n : ℕ} (ξ : EuclideanSpace ℝ (Fin n)) (hξ : ξ ≠ 0) :
    (∀ i j : Fin n,
      (-I * (ξ i : ℂ) / (‖ξ‖ : ℂ)) * (-I * (ξ j : ℂ) / (‖ξ‖ : ℂ)) =
        ((2 * Real.pi * I * (ξ i : ℂ)) * (2 * Real.pi * I * (ξ j : ℂ))) /
          (4 * (Real.pi : ℂ) ^ 2 * (‖ξ‖ : ℂ) ^ 2)) ∧
    ∑ j : Fin n, (-I * (ξ j : ℂ) / (‖ξ‖ : ℂ)) ^ 2 = -1 := by
  have hn : (‖ξ‖ : ℂ) ≠ 0 := by exact_mod_cast norm_ne_zero_iff.mpr hξ
  have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  refine ⟨fun i j => ?_, ?_⟩
  · field_simp
    ring_nf
  · have hs : ((‖ξ‖ ^ 2 : ℝ) : ℂ) = ∑ j, ((ξ j ^ 2 : ℝ) : ℂ) := by
      rw [EuclideanSpace.real_norm_sq_eq]; push_cast; rfl
    have : ∀ j, (-I * (ξ j : ℂ) / (‖ξ‖ : ℂ)) ^ 2 = -((ξ j ^ 2 : ℝ) : ℂ) / ((‖ξ‖ ^ 2 : ℝ) : ℂ) := by
      intro j; push_cast; ring_nf; rw [I_sq]; ring
    simp_rw [this]
    rw [← Finset.sum_div, Finset.sum_neg_distrib, ← hs]
    push_cast
    field_simp

/-- The energy bound for a mixed second derivative: for two different axes i ≠ j,
the multiplier of `R_i R_j` has size `|ξᵢ ξⱼ|/|ξ|² ≤ 1/2` at every nonzero frequency,
so `‖∂ᵢ∂ⱼ u‖₂ ≤ ½ ‖f‖₂`; and the value 1/2 is reached (at 45° between the two axes),
so 1/2 is the operator norm on energy. -/
theorem riesz_mixed_multiplier_le_half_and_sharp
    {n : ℕ} (i j : Fin n) (hij : i ≠ j) :
    (∀ ξ : EuclideanSpace ℝ (Fin n), ξ ≠ 0 →
      ‖(-I * (ξ i : ℂ) / (‖ξ‖ : ℂ)) * (-I * (ξ j : ℂ) / (‖ξ‖ : ℂ))‖ ≤ 1 / 2) ∧
    ∃ ξ : EuclideanSpace ℝ (Fin n), ξ ≠ 0 ∧
      ‖(-I * (ξ i : ℂ) / (‖ξ‖ : ℂ)) * (-I * (ξ j : ℂ) / (‖ξ‖ : ℂ))‖ = 1 / 2 := by
  refine ⟨fun ξ hξ => ?_, ?_⟩
  · rw [riesz_aux_mul, Complex.norm_real, Real.norm_eq_abs]
    have hpos : 0 < ‖ξ‖ ^ 2 := by positivity
    rw [abs_div, abs_neg, abs_of_pos hpos, div_le_iff₀ hpos]
    have := riesz_aux_two_mul_abs_le ξ i j hij
    linarith
  · set v : EuclideanSpace ℝ (Fin n) :=
      EuclideanSpace.single i (1 : ℝ) + EuclideanSpace.single j (1 : ℝ) with hv
    have hi : v i = 1 := by simp [hv, hij]
    have hj : v j = 1 := by simp [hv, hij.symm]
    have hnorm : ‖v‖ ^ 2 = 2 := by
      rw [hv, @norm_add_sq_real, PiLp.norm_single, PiLp.norm_single,
        EuclideanSpace.inner_single_left]
      simp [hij.symm]
      norm_num
    refine ⟨v, ?_, ?_⟩
    · intro h
      rw [h] at hi
      simp at hi
    · rw [riesz_aux_mul, Complex.norm_real, Real.norm_eq_abs, hi, hj, hnorm]
      norm_num

/-- The kernel `K(x) = x₁x₂/(π|x|⁴)` of `R₁R₂` in the plane is a Calderón–Zygmund kernel
in size and cancellation: `|K(x)| ≤ A/|x|²` with `A = 1/(2π)` at every point other
than the origin, and over every shell `ε < |x| < ℓ` with `ε > 0` it is integrable
and adds up to zero. -/
theorem riesz_product_kernel_size_and_cancellation :
    (∀ x : EuclideanSpace ℝ (Fin 2), x ≠ 0 →
      |x 0 * x 1 / (Real.pi * ‖x‖ ^ 4)| ≤ (1 / (2 * Real.pi)) / ‖x‖ ^ 2) ∧
    ∀ ε ℓ : ℝ, 0 < ε →
      MeasureTheory.IntegrableOn (fun x : EuclideanSpace ℝ (Fin 2) =>
        x 0 * x 1 / (Real.pi * ‖x‖ ^ 4)) {x | ε < ‖x‖ ∧ ‖x‖ < ℓ} ∧
      ∫ x in {x : EuclideanSpace ℝ (Fin 2) | ε < ‖x‖ ∧ ‖x‖ < ℓ},
        x 0 * x 1 / (Real.pi * ‖x‖ ^ 4) = 0 := by
  have hsize : ∀ x : EuclideanSpace ℝ (Fin 2), x ≠ 0 →
      |x 0 * x 1 / (Real.pi * ‖x‖ ^ 4)| ≤ (1 / (2 * Real.pi)) / ‖x‖ ^ 2 := by
    intro x hx
    have hx' : 0 < ‖x‖ := norm_pos_iff.mpr hx
    have h2 := riesz_aux_two_mul_abs_le x 0 1 (by decide)
    have hden : 0 < Real.pi * ‖x‖ ^ 4 := by positivity
    rw [abs_div, abs_of_pos hden, div_div, div_le_div_iff₀ hden (by positivity)]
    have : 0 < Real.pi * ‖x‖ ^ 2 := by positivity
    nlinarith
  refine ⟨hsize, fun ε ℓ hε => ⟨?_, ?_⟩⟩
  · have hs : MeasurableSet {x : EuclideanSpace ℝ (Fin 2) | ε < ‖x‖ ∧ ‖x‖ < ℓ} :=
      (measurableSet_lt measurable_const measurable_norm).inter
        (measurableSet_lt measurable_norm measurable_const)
    have hfin : MeasureTheory.volume {x : EuclideanSpace ℝ (Fin 2) | ε < ‖x‖ ∧ ‖x‖ < ℓ} ≠ ⊤ := by
      refine ne_top_of_le_ne_top (MeasureTheory.measure_ball_lt_top (x := (0 : EuclideanSpace ℝ (Fin 2)))
        (r := ℓ)).ne (MeasureTheory.measure_mono ?_)
      intro x hx
      simpa [Metric.mem_ball, dist_zero_right] using hx.2
    have hmeas : Measurable (fun x : EuclideanSpace ℝ (Fin 2) =>
        x 0 * x 1 / (Real.pi * ‖x‖ ^ 4)) := by fun_prop
    refine MeasureTheory.Measure.integrableOn_of_bounded hfin hmeas.aestronglyMeasurable
      (M := (1 / (2 * Real.pi)) / ε ^ 2) ?_
    refine MeasureTheory.ae_restrict_of_forall_mem hs ?_
    intro x hx
    have hx0 : x ≠ 0 := by
      intro h
      have h1 := hx.1
      rw [h, norm_zero] at h1
      linarith
    rw [Real.norm_eq_abs]
    refine (hsize x hx0).trans ?_
    have : 0 < 1 / (2 * Real.pi) := by positivity
    gcongr
    exact hx.1.le
  · set R : EuclideanSpace ℝ (Fin 2) ≃ₗᵢ[ℝ] EuclideanSpace ℝ (Fin 2) :=
      LinearIsometryEquiv.piLpCongrRight 2 (fun k : Fin 2 =>
        if k = 1 then LinearIsometryEquiv.neg ℝ else LinearIsometryEquiv.refl ℝ ℝ) with hR
    have hR0 : ∀ x, R x 0 = x 0 := by intro x; simp [hR]
    have hR1 : ∀ x, R x 1 = - x 1 := by intro x; simp [hR]
    have key := R.measurePreserving.setIntegral_preimage_emb
      R.toHomeomorph.measurableEmbedding
      (fun x : EuclideanSpace ℝ (Fin 2) => x 0 * x 1 / (Real.pi * ‖x‖ ^ 4))
      {x : EuclideanSpace ℝ (Fin 2) | ε < ‖x‖ ∧ ‖x‖ < ℓ}
    have hpre : R ⁻¹' {x : EuclideanSpace ℝ (Fin 2) | ε < ‖x‖ ∧ ‖x‖ < ℓ} =
        {x : EuclideanSpace ℝ (Fin 2) | ε < ‖x‖ ∧ ‖x‖ < ℓ} := by
      ext x; simp
    simp only [hpre, hR0, hR1, LinearIsometryEquiv.norm_map] at key
    have hneg : ∀ x : EuclideanSpace ℝ (Fin 2),
        x 0 * -x 1 / (Real.pi * ‖x‖ ^ 4) = -(x 0 * x 1 / (Real.pi * ‖x‖ ^ 4)) := by
      intro x; ring
    simp only [hneg, MeasureTheory.integral_neg] at key
    linarith

-- The card's exact hand numbers.
-- The kernel factor x₁x₂/r⁴ at the point (1, 1), where r² = 2: it is 1/4.
example : ((1 : ℚ) * 1) / ((1 ^ 2 + 1 ^ 2) ^ 2) = 1 / 4 := by norm_num
-- The sharp p-norm (p* - 1)/2 at p = 4: p' = 4/3, p* = max 4 (4/3) = 4, norm 3/2.
example : (1 : ℚ) / 4 + 1 / (4 / 3) = 1 ∧ max (4 : ℚ) (4 / 3) = 4 ∧
    (max (4 : ℚ) (4 / 3) - 1) / 2 = 3 / 2 := by norm_num
-- The average of the squared mixed multiplier over directions: cos²φ sin²φ = sin²2φ/4,
-- and sin² averages 1/2, so the average is (1/4)(1/2) = 1/8.
example : ((1 : ℚ) / 4) * (1 / 2) = 1 / 8 := by norm_num

#print axioms riesz_multipliers_give_second_derivatives_and_square_sum
#print axioms riesz_mixed_multiplier_le_half_and_sharp
#print axioms riesz_product_kernel_size_and_cancellation
