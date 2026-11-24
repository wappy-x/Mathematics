-- Darboux's theorem: every derivative on a closed interval takes each value strictly between its two end values at some inside point, so no derivative has a jump.
import Mathlib.Analysis.Calculus.Darboux
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.FDeriv.Extend
import Mathlib.Analysis.Asymptotics.Lemmas
import Mathlib.Tactic.NormNum

open Set Filter Topology

/-- Helper: away from `0`, the derivative of `t ↦ t² sin(1/t)` is `2x sin(1/x) - cos(1/x)`. -/
theorem xsq_hasDerivAt_ne {x : ℝ} (hx : x ≠ 0) :
    HasDerivAt (fun t : ℝ => t ^ 2 * Real.sin t⁻¹) (2 * x * Real.sin x⁻¹ - Real.cos x⁻¹) x := by
  have h : HasDerivAt (fun t : ℝ => t ^ 2 * Real.sin t⁻¹) _ x :=
    (hasDerivAt_pow 2 x).mul ((Real.hasDerivAt_sin _).comp x (hasDerivAt_inv hx))
  convert h using 1
  field_simp
  ring

/-- Helper: at `0`, the derivative of `t ↦ t² sin(1/t)` is `0`, since `|t² sin(1/t)| ≤ t²`. -/
theorem xsq_hasDerivAt_zero :
    HasDerivAt (fun t : ℝ => t ^ 2 * Real.sin t⁻¹) 0 0 := by
  rw [hasDerivAt_iff_isLittleO_nhds_zero]
  simp only [zero_add, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, inv_zero,
    Real.sin_zero, mul_zero, sub_zero, smul_zero]
  refine Asymptotics.IsBigO.trans_isLittleO ?_ (Asymptotics.isLittleO_pow_id (n := 2) one_lt_two)
  refine Asymptotics.IsBigO.of_bound 1 (Eventually.of_forall fun h => ?_)
  rw [norm_mul, one_mul]
  exact mul_le_of_le_one_right (norm_nonneg _) (by simpa using Real.abs_sin_le_one h⁻¹)

#print axioms xsq_hasDerivAt_ne
#print axioms xsq_hasDerivAt_zero

/-- **Darboux's theorem.** If `f` has a derivative `f' x` at every point `x` of the closed
interval `[a, b]` (one-sided at the two ends, taken from inside the interval), and the target
`y` lies strictly between `f' a` and `f' b` (in either order), then `f' c = y` for some point
`c` strictly inside `(a, b)`. -/
theorem derivative_takes_every_value_between_end_slopes {f f' : ℝ → ℝ} {a b y : ℝ}
    (hab : a ≤ b) (hf : ∀ x ∈ Icc a b, HasDerivWithinAt f (f' x) (Icc a b) x)
    (hy : (f' a < y ∧ y < f' b) ∨ (f' b < y ∧ y < f' a)) :
    ∃ c ∈ Ioo a b, f' c = y := by
  rcases hy with ⟨h1, h2⟩ | ⟨h1, h2⟩
  · exact exists_hasDerivWithinAt_eq_of_gt_of_lt hab hf h1 h2
  · exact exists_hasDerivWithinAt_eq_of_lt_of_gt hab hf h2 h1

/-- **No derivative has a jump (or a hole).** If `f` has derivative `f' x` at every point of an
open interval around `p`, and `f'` heads for `L` from the left of `p` and for `R` from the right,
then both limits equal `f' p`. In particular `L = R`: a derivative cannot jump. -/
theorem derivative_has_no_jump {f f' : ℝ → ℝ} {u v p L R : ℝ} (hp : p ∈ Ioo u v)
    (hf : ∀ x ∈ Ioo u v, HasDerivAt f (f' x) x)
    (hL : Tendsto f' (𝓝[<] p) (𝓝 L)) (hR : Tendsto f' (𝓝[>] p) (𝓝 R)) :
    L = f' p ∧ R = f' p := by
  have hcont : ContinuousAt f p := (hf p hp).continuousAt
  have hnhds : Ioo u v ∈ 𝓝 p := isOpen_Ioo.mem_nhds hp
  have hdiff : DifferentiableOn ℝ f (Ioo u v) := fun x hx =>
    (hf x hx).differentiableAt.differentiableWithinAt
  have hderiv : f' =ᶠ[𝓝 p] deriv f :=
    eventually_of_mem hnhds (fun x hx => (hf x hx).deriv.symm)
  constructor
  · have A : HasDerivWithinAt f L (Iic p) p :=
      hasDerivWithinAt_Iic_of_tendsto_deriv hdiff hcont.continuousWithinAt
        (mem_nhdsWithin_of_mem_nhds hnhds) (hL.congr' (hderiv.filter_mono nhdsWithin_le_nhds))
    exact UniqueDiffWithinAt.eq_deriv _ (uniqueDiffWithinAt_Iic p) A (hf p hp).hasDerivWithinAt
  · have A : HasDerivWithinAt f R (Ici p) p :=
      hasDerivWithinAt_Ici_of_tendsto_deriv hdiff hcont.continuousWithinAt
        (mem_nhdsWithin_of_mem_nhds hnhds) (hR.congr' (hderiv.filter_mono nhdsWithin_le_nhds))
    exact UniqueDiffWithinAt.eq_deriv _ (uniqueDiffWithinAt_Ici p) A (hf p hp).hasDerivWithinAt

/-- **A derivative can still be discontinuous.** For `f(x) = x² sin(1/x)` with `f(0) = 0`
(in Lean, `0⁻¹ = 0`, so the formula gives `f 0 = 0` by itself), `f` has a derivative at every
real number, the derivative at `0` is `0`, and the derivative is not continuous at `0`. -/
theorem x_sq_sin_inv_deriv_exists_but_discontinuous :
    (∀ x : ℝ, DifferentiableAt ℝ (fun t : ℝ => t ^ 2 * Real.sin t⁻¹) x) ∧
      deriv (fun t : ℝ => t ^ 2 * Real.sin t⁻¹) 0 = 0 ∧
      ¬ ContinuousAt (deriv (fun t : ℝ => t ^ 2 * Real.sin t⁻¹)) 0 := by
  refine ⟨fun x => ?_, xsq_hasDerivAt_zero.deriv, fun hc => ?_⟩
  · rcases eq_or_ne x 0 with rfl | hx
    · exact xsq_hasDerivAt_zero.differentiableAt
    · exact (xsq_hasDerivAt_ne hx).differentiableAt
  · set s : ℕ → ℝ := fun n => ((n : ℝ) * (2 * Real.pi))⁻¹ with hs
    have hs0 : Tendsto s atTop (𝓝 0) :=
      tendsto_inv_atTop_zero.comp
        (Tendsto.atTop_mul_const (by positivity) tendsto_natCast_atTop_atTop)
    have h1 := hc.tendsto.comp hs0
    rw [xsq_hasDerivAt_zero.deriv] at h1
    have h2 : (deriv (fun t : ℝ => t ^ 2 * Real.sin t⁻¹) ∘ s) =ᶠ[atTop] fun _ => (-1 : ℝ) := by
      filter_upwards [eventually_ge_atTop 1] with n hn
      have hn' : ((n : ℝ) * (2 * Real.pi)) ≠ 0 := by
        have : (1 : ℝ) ≤ n := by exact_mod_cast hn
        positivity
      have hsn : s n ≠ 0 := inv_ne_zero hn'
      have hsin : Real.sin ((n : ℝ) * (2 * Real.pi)) = 0 := by
        have := Real.sin_nat_mul_pi (2 * n)
        push_cast at this
        rwa [show (n : ℝ) * (2 * Real.pi) = 2 * n * Real.pi by ring]
      simp only [Function.comp_apply]
      rw [(xsq_hasDerivAt_ne hsn).deriv, hs]
      simp only [inv_inv, Real.cos_nat_mul_two_pi, hsin]
      ring
    have h3 := tendsto_nhds_unique (h1.congr' h2) tendsto_const_nhds
    norm_num at h3

-- The card's worked numbers for f(x) = x², f'(x) = 2x on [-1/2, 3/2], target slope 1/2.
-- End slopes: f'(-1/2) = -1 and f'(3/2) = 3.
example : (2 : ℚ) * (-1 / 2) = -1 ∧ (2 : ℚ) * (3 / 2) = 3 := by norm_num
-- The tilted function g(x) = x² - x/2 at the ends: g(-1/2) = 1/2 and g(3/2) = 3/2.
example : (-1 / 2 : ℚ) ^ 2 - (1 / 2) * (-1 / 2) = 1 / 2 ∧
    (3 / 2 : ℚ) ^ 2 - (1 / 2) * (3 / 2) = 3 / 2 := by norm_num
-- One step in, g is lower: g(-2/5) = 9/25 < 1/2 and g(7/5) = 63/50 < 3/2.
example : (-2 / 5 : ℚ) ^ 2 - (1 / 2) * (-2 / 5) = 9 / 25 ∧ (9 / 25 : ℚ) < 1 / 2 ∧
    (7 / 5 : ℚ) ^ 2 - (1 / 2) * (7 / 5) = 63 / 50 ∧ (63 / 50 : ℚ) < 3 / 2 := by norm_num
-- Lowest point c = 1/4: g(c) = -1/16 and f'(c) = 2c = 1/2, the target.
example : (1 / 4 : ℚ) ^ 2 - (1 / 2) * (1 / 4) = -1 / 16 ∧ (2 : ℚ) * (1 / 4) = 1 / 2 := by
  norm_num
-- Mistake 2: the mean value theorem's average slope is (f(3/2) - f(-1/2)) / 2 = 1, not 1/2.
example : ((3 / 2 : ℚ) ^ 2 - (-1 / 2) ^ 2) / 2 = 1 := by norm_num

#print axioms derivative_takes_every_value_between_end_slopes
#print axioms derivative_has_no_jump
#print axioms x_sq_sin_inv_deriv_exists_but_discontinuous
