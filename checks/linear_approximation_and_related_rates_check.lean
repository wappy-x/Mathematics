-- Linear approximation: the tangent-line remainder divided by the step tends to 0, it is at most M h^2 / 2 when |f''| ≤ M, and a sphere's volume rate is 4πr^2 times its radius rate.
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Abs
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Filter Topology Real

/-- Helper: the tangent-line remainder bound, proved by moving along `a + s h` for `s ∈ [0, 1]`. -/
theorem linear_approximation_remainder_bound_aux
    {f f' f'' : ℝ → ℝ} {a h M : ℝ}
    (hf : ∀ x ∈ Set.uIcc a (a + h), HasDerivAt f (f' x) x)
    (hf' : ∀ x ∈ Set.uIcc a (a + h), HasDerivAt f' (f'' x) x)
    (hM : ∀ x ∈ Set.uIcc a (a + h), |f'' x| ≤ M) :
    |f (a + h) - f a - f' a * h| ≤ M * h ^ 2 / 2 := by
  have mem : ∀ s ∈ Set.Icc (0:ℝ) 1, a + s * h ∈ Set.uIcc a (a + h) := by
    intro s hs
    obtain ⟨hs0, hs1⟩ := hs
    rcases le_total 0 h with hh | hh
    · rw [Set.uIcc_of_le (by linarith)]; constructor <;> nlinarith
    · rw [Set.uIcc_of_ge (by linarith)]; constructor <;> nlinarith
  have ha : a ∈ Set.uIcc a (a + h) := Set.left_mem_uIcc
  have lip : ∀ s ∈ Set.Icc (0:ℝ) 1, |f' (a + s * h) - f' a| ≤ M * (s * |h|) := by
    intro s hs
    have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := f') (f' := f'')
      (s := Set.uIcc a (a + h)) (fun x hx => (hf' x hx).hasDerivWithinAt)
      (fun x hx => by simpa [Real.norm_eq_abs] using hM x hx) (convex_uIcc a (a + h)) ha (mem s hs)
    simp only [Real.norm_eq_abs] at this
    have e : |a + s * h - a| = s * |h| := by
      rw [show a + s * h - a = s * h by ring, abs_mul, abs_of_nonneg hs.1]
    rwa [e] at this
  have hφ : ∀ s ∈ Set.Icc (0:ℝ) 1,
      HasDerivAt (fun s => f (a + s * h) - f a - f' a * (s * h))
        (f' (a + s * h) * h - f' a * h) s := by
    intro s hs
    have h1 : HasDerivAt (fun s : ℝ => a + s * h) h s := by
      simpa using ((hasDerivAt_id s).mul_const h).const_add a
    have h2 := (hf _ (mem s hs)).comp s h1
    have h3 : HasDerivAt (fun s : ℝ => f' a * (s * h)) (f' a * h) s := by
      simpa using ((hasDerivAt_id s).mul_const h).const_mul (f' a)
    exact (h2.sub_const (f a)).sub h3
  have key := image_norm_le_of_norm_deriv_right_le_deriv_boundary
    (f := fun s => f (a + s * h) - f a - f' a * (s * h))
    (f' := fun s => f' (a + s * h) * h - f' a * h) (a := 0) (b := 1)
    (B := fun s => M * h ^ 2 * s ^ 2 / 2) (B' := fun s => M * h ^ 2 * s)
    (fun s hs => (hφ s hs).continuousAt.continuousWithinAt)
    (fun s hs => (hφ s (Set.Ico_subset_Icc_self hs)).hasDerivWithinAt)
    (by simp)
    (fun s => by
      have := ((hasDerivAt_pow 2 s).const_mul (M * h ^ 2)).div_const 2
      convert this using 1
      norm_num
      ring)
    (fun s hs => by
      have hs' := Set.Ico_subset_Icc_self hs
      simp only [Real.norm_eq_abs]
      rw [show f' (a + s * h) * h - f' a * h = (f' (a + s * h) - f' a) * h by ring, abs_mul]
      calc |f' (a + s * h) - f' a| * |h| ≤ M * (s * |h|) * |h| :=
            mul_le_mul_of_nonneg_right (lip s hs') (abs_nonneg h)
        _ = M * h ^ 2 * s := by rw [← sq_abs h]; ring)
    (Set.right_mem_Icc.mpr zero_le_one)
  simpa [Real.norm_eq_abs] using key

#print axioms linear_approximation_remainder_bound_aux

/-- If `f` has derivative `f'` at `a`, then the remainder `R(h) = f(a+h) - f(a) - f' h`
of the tangent-line forecast, divided by the step `h`, tends to 0 as `h → 0`. -/
theorem linear_approximation_remainder_div_step_tendsto_zero
    {f : ℝ → ℝ} {f' a : ℝ} (hf : HasDerivAt f f' a) :
    Tendsto (fun h : ℝ => (f (a + h) - f a - f' * h) / h) (𝓝[≠] 0) (𝓝 0) := by
  have hs := hf.tendsto_slope_zero
  have h2 := hs.sub_const f'
  rw [sub_self] at h2
  refine h2.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with h hh
  have hh0 : h ≠ 0 := hh
  simp only [smul_eq_mul]
  field_simp

/-- If `f` has derivative `f'` and `f'` has derivative `f''` at every point from `a` to `a + h`,
and the size of `f''` stays below a ceiling `M` there, then the tangent-line remainder
satisfies `|R(h)| ≤ M h^2 / 2`. -/
theorem linear_approximation_remainder_le_half_bound_mul_sq
    {f f' f'' : ℝ → ℝ} {a h M : ℝ}
    (hf : ∀ x ∈ Set.uIcc a (a + h), HasDerivAt f (f' x) x)
    (hf' : ∀ x ∈ Set.uIcc a (a + h), HasDerivAt f' (f'' x) x)
    (hM : ∀ x ∈ Set.uIcc a (a + h), |f'' x| ≤ M) :
    |f (a + h) - f a - f' a * h| ≤ M * h ^ 2 / 2 := by
  exact linear_approximation_remainder_bound_aux hf hf' hM

/-- Related rates for a sphere: if the volume is `V = (4/3) π r^3` at every instant and the radius
has rate `r'` at time `t`, then the volume rate is `4 π r^2 r'`; and when the radius is nonzero,
the radius rate is the volume rate divided by the surface `4 π r^2`. -/
theorem sphere_volume_rate_eq_surface_mul_radius_rate
    {r V : ℝ → ℝ} {r' t : ℝ}
    (hV : ∀ s, V s = 4 / 3 * π * r s ^ 3) (hr : HasDerivAt r r' t) :
    HasDerivAt V (4 * π * r t ^ 2 * r') t ∧
      (r t ≠ 0 → r' = deriv V t / (4 * π * r t ^ 2)) := by
  have hVe : V = fun s => 4 / 3 * π * r s ^ 3 := funext hV
  have hd : HasDerivAt V (4 * π * r t ^ 2 * r') t := by
    rw [hVe]
    have := (hr.pow 3).const_mul (4 / 3 * π)
    convert this using 1
    push_cast; ring
  refine ⟨hd, fun h0 => ?_⟩
  rw [hd.deriv]
  have : (4 * π * r t ^ 2) ≠ 0 := by positivity
  field_simp

-- The corner: |x| has no derivative at 0, so there is no tangent line to use there.
example : ¬ DifferentiableAt ℝ (fun x : ℝ => |x|) 0 := by exact not_differentiableAt_abs_zero

-- At radius 20 cm the surface is four times the surface at 10 cm.
example : 4 * π * (20 : ℝ) ^ 2 = 4 * (4 * π * 10 ^ 2) := by ring

-- So at 20 cm the radius rate under a 500 cm^3/s pump is a quarter of the rate at 10 cm.
example : 500 / (4 * π * (20 : ℝ) ^ 2) = 500 / (4 * π * 10 ^ 2) / 4 := by field_simp; ring

#print axioms linear_approximation_remainder_div_step_tendsto_zero
#print axioms linear_approximation_remainder_le_half_bound_mul_sq
#print axioms sphere_volume_rate_eq_surface_mul_radius_rate
