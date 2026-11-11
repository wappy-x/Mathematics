-- Solving by mapping: the Laplacian of U after a holomorphic map f is |f'|^2 times the Laplacian of U at the image point, so a harmonic function stays harmonic under such a map, and e^z and z^2 carry the corridor and the quarter plane one-to-one onto the upper half plane, walls to walls, giving the temperatures 100y/pi and (200/pi) arg z.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.InnerProductSpace.Harmonic.Constructions
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Complex.RealDeriv
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Tactic.NormNum

open Set Complex Laplacian InnerProductSpace

/-- The card's formula. Let f be holomorphic (complex-differentiable) on an open set s, let z be
a point of s, and let U be a real function with continuous second partial derivatives near f(z).
Then the Laplacian of U after f, at z, equals the square of the local stretch |f'(z)| times the
Laplacian of U at the image point f(z). -/
theorem laplacian_comp_holomorphic {s : Set ℂ} {f : ℂ → ℂ} {U : ℂ → ℝ} {z : ℂ}
    (hs : IsOpen s) (hf : DifferentiableOn ℂ f s) (hz : z ∈ s)
    (hU : ContDiffAt ℝ 2 U (f z)) :
    Δ (U ∘ f) z = ‖deriv f z‖ ^ 2 * Δ U (f z) := by
  have hfa : AnalyticAt ℂ f z := hf.analyticAt (hs.mem_nhds hz)
  have hfC : ContDiffAt ℂ ⊤ f z := hfa.contDiffAt
  have hfR : ContDiffAt ℝ ⊤ f z := hfC.restrict_scalars ℝ
  have hfdR : DifferentiableAt ℝ f z := hfR.differentiableAt (by simp)
  have hΔf : Δ f z = 0 := (hfC.of_le (by simp)).harmonicAt.2.eq_of_nhds
  have hev : fderiv ℝ (U ∘ f) =ᶠ[nhds z]
      fun y => (fderiv ℝ U (f y)).comp (fderiv ℝ f y) := by
    have h1 : ∀ᶠ y in nhds z, DifferentiableAt ℝ U (f y) := by
      have := hU.eventually (by simp)
      exact (hfR.continuousAt.eventually this).mono fun y hy => hy.differentiableAt (by simp)
    have h2 : ∀ᶠ y in nhds z, DifferentiableAt ℝ f y :=
      (hfR.eventually (by simp)).mono fun y hy => hy.differentiableAt (by simp)
    filter_upwards [h1, h2] with y hy1 hy2
    exact fderiv_comp y hy1 hy2
  have hDU : DifferentiableAt ℝ (fderiv ℝ U) (f z) :=
    (hU.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  have hDf : DifferentiableAt ℝ (fderiv ℝ f) z :=
    (hfR.fderiv_right (m := 1) (by simp)).differentiableAt (by norm_num)
  have hc : DifferentiableAt ℝ (fun y => fderiv ℝ U (f y)) z := hDU.comp z hfdR
  have key : ∀ v : ℂ, fderiv ℝ (fderiv ℝ (U ∘ f)) z v v =
      fderiv ℝ (fderiv ℝ U) (f z) (fderiv ℝ f z v) (fderiv ℝ f z v)
        + fderiv ℝ U (f z) (fderiv ℝ (fderiv ℝ f) z v v) := by
    intro v
    rw [hev.fderiv_eq, fderiv_clm_comp hc hDf,
      show (fun y => fderiv ℝ U (f y)) = fderiv ℝ U ∘ f from rfl, fderiv_comp z hDU hfdR]
    simp only [add_apply, ContinuousLinearMap.comp_apply,
      ContinuousLinearMap.compL_apply, ContinuousLinearMap.flip_apply]
    rw [add_comm]
  have hfd : ∀ v : ℂ, fderiv ℝ f z v = v * deriv f z := by
    intro v
    rw [hfC.differentiableAt (by simp) |>.fderiv_restrictScalars ℝ]
    simp only [ContinuousLinearMap.coe_restrictScalars']
    rw [← fderiv_apply_one_eq_deriv, ← smul_eq_mul, ← map_smul, smul_eq_mul, mul_one]
  rw [laplacian_eq_iteratedFDeriv_complexPlane, laplacian_eq_iteratedFDeriv_complexPlane] at *
  simp only [iteratedFDeriv_two_apply, Matrix.cons_val_zero, Matrix.cons_val_one] at hΔf ⊢
  rw [key 1, key I, hfd, hfd]
  have hlin : fderiv ℝ U (f z) (fderiv ℝ (fderiv ℝ f) z 1 1)
      + fderiv ℝ U (f z) (fderiv ℝ (fderiv ℝ f) z I I) = 0 := by
    rw [← map_add, hΔf, map_zero]
  set a := deriv f z
  have ha : 1 * a = (a.re : ℝ) • (1 : ℂ) + (a.im : ℝ) • I := by
    apply Complex.ext <;> simp
  have hIa : I * a = (-a.im : ℝ) • (1 : ℂ) + (a.re : ℝ) • I := by
    apply Complex.ext <;> simp
  rw [ha, hIa]
  simp only [map_add, map_smul, add_apply, smul_apply,
    smul_eq_mul]
  rw [Complex.sq_norm, Complex.normSq_apply]
  linear_combination hlin

/-- Harmonic stays harmonic. If f is holomorphic on an open set s and sends s into a set V on
which U is harmonic, then u = U after f is harmonic on s. Only holomorphy is used: f need not be
one-to-one, and f' may vanish. -/
theorem harmonic_comp_holomorphic {s V : Set ℂ} {f : ℂ → ℂ} {U : ℂ → ℝ}
    (hs : IsOpen s) (hf : DifferentiableOn ℂ f s) (hmap : MapsTo f s V)
    (hU : HarmonicOnNhd U V) :
    HarmonicOnNhd (U ∘ f) s := by
  intro z hz
  have hfR : ContDiffAt ℝ 2 f z :=
    ((hf.analyticAt (hs.mem_nhds hz)).contDiffAt (n := 2)).restrict_scalars ℝ
  have hUz := hU (f z) (hmap hz)
  refine ⟨hUz.1.comp z hfR, ?_⟩
  have h1 : ∀ᶠ y in nhds z, ContDiffAt ℝ 2 U (f y) :=
    hfR.continuousAt.eventually (hUz.1.eventually (by simp))
  have h2 : ∀ᶠ y in nhds z, Δ U (f y) = 0 := hfR.continuousAt.eventually hUz.2
  filter_upwards [h1, h2, hs.mem_nhds hz] with y hy1 hy2 hy3
  rw [laplacian_comp_holomorphic hs hf hy3 hy1, hy2, mul_zero]
  rfl

/-- The card's two worked cases. The half-plane temperature is U(w) = (100/π) arg w: 0 on the
positive real axis, 100 on the negative one.
Corridor: e^z sends the strip 0 < Im z < π one-to-one onto the upper half plane, the floor to the
positive real axis (0 degrees) and the ceiling to the negative real axis (100 degrees), and the
answer carried back is U(e^z) = 100y/π.
Quarter plane: z^2 sends the points with positive real and imaginary parts one-to-one onto the
upper half plane, the positive real axis to 0 degrees and the positive imaginary axis to 100,
and the answer carried back is U(z^2) = (200/π) arg z. -/
theorem corridor_and_quarter_plane_by_mapping :
    (BijOn exp {z : ℂ | 0 < z.im ∧ z.im < Real.pi} {w : ℂ | 0 < w.im} ∧
      (∀ x : ℝ, 100 / Real.pi * arg (exp (x : ℂ)) = 0) ∧
      (∀ x : ℝ, 100 / Real.pi * arg (exp ((x : ℂ) + Real.pi * I)) = 100) ∧
      ∀ z : ℂ, 0 < z.im → z.im < Real.pi →
        100 / Real.pi * arg (exp z) = 100 * z.im / Real.pi) ∧
    (BijOn (fun z : ℂ => z ^ 2) {z : ℂ | 0 < z.re ∧ 0 < z.im} {w : ℂ | 0 < w.im} ∧
      (∀ t : ℝ, 0 < t → 100 / Real.pi * arg ((t : ℂ) ^ 2) = 0) ∧
      (∀ t : ℝ, 0 < t → 100 / Real.pi * arg (((t : ℂ) * I) ^ 2) = 100) ∧
      ∀ z : ℂ, 0 < z.re → 0 < z.im →
        100 / Real.pi * arg (z ^ 2) = 200 / Real.pi * arg z) := by
  have hpi : Real.pi ≠ 0 := Real.pi_ne_zero
  have hargexp : ∀ z : ℂ, -Real.pi < z.im → z.im ≤ Real.pi → arg (exp z) = z.im := by
    intro z h1 h2
    rw [← log_im, log_exp h1 h2]
  -- arg of a point in the upper half plane lies in (0, π)
  have harg_up : ∀ w : ℂ, 0 < w.im → 0 < arg w ∧ arg w < Real.pi := by
    intro w hw
    refine ⟨?_, ?_⟩
    · rcases lt_or_eq_of_le (arg_nonneg_iff.mpr hw.le) with h | h
      · exact h
      · exfalso
        have := (arg_eq_zero_iff.mp h.symm).2
        linarith
    · exact arg_lt_pi_iff.mpr (Or.inr hw.ne')
  refine ⟨⟨?_, ?_, ?_, ?_⟩, ⟨?_, ?_, ?_, ?_⟩⟩
  · refine ⟨?_, ?_, ?_⟩
    · intro z ⟨h1, h2⟩
      show 0 < (exp z).im
      rw [exp_im]
      exact mul_pos (Real.exp_pos _) (Real.sin_pos_of_pos_of_lt_pi h1 h2)
    · intro z ⟨h1, h2⟩ w ⟨h3, h4⟩ h
      rw [← log_exp (by linarith) h2.le, ← log_exp (by linarith) h4.le, h]
    · intro w hw
      have hw0 : w ≠ 0 := fun h => by simp [h] at hw
      obtain ⟨a1, a2⟩ := harg_up w hw
      exact ⟨log w, ⟨by rw [log_im]; exact a1, by rw [log_im]; exact a2⟩, exp_log hw0⟩
  · intro x
    rw [← ofReal_exp, arg_ofReal_of_nonneg (Real.exp_pos x).le, mul_zero]
  · intro x
    rw [hargexp _ (by simp; linarith [Real.pi_pos]) (by simp)]
    simp
  · intro z h1 h2
    rw [hargexp z (by linarith [Real.pi_pos]) h2.le]
    ring
  · refine ⟨?_, ?_, ?_⟩
    · intro z ⟨h1, h2⟩
      show 0 < (z ^ 2).im
      rw [sq, mul_im]
      nlinarith
    · intro z ⟨h1, h2⟩ w ⟨h3, h4⟩ h
      have h' : z ^ 2 = w ^ 2 := h
      rcases sq_eq_sq_iff_eq_or_eq_neg.mp h' with h5 | h5
      · exact h5
      · exfalso
        have := congrArg re h5
        simp at this
        linarith
    · intro w hw
      have hw0 : w ≠ 0 := fun h => by simp [h] at hw
      obtain ⟨a1, a2⟩ := harg_up w hw
      refine ⟨exp (log w / 2), ⟨?_, ?_⟩, ?_⟩
      · rw [exp_re]
        apply mul_pos (Real.exp_pos _)
        apply Real.cos_pos_of_mem_Ioo
        have : (log w / 2).im = arg w / 2 := by simp [log_im]
        rw [this]
        constructor <;> linarith
      · rw [exp_im]
        apply mul_pos (Real.exp_pos _)
        apply Real.sin_pos_of_pos_of_lt_pi
        · have : (log w / 2).im = arg w / 2 := by simp [log_im]
          rw [this]; linarith
        · have : (log w / 2).im = arg w / 2 := by simp [log_im]
          rw [this]; linarith
      · show exp (log w / 2) ^ 2 = w
        rw [← exp_nat_mul]
        push_cast
        rw [mul_div_cancel₀ _ two_ne_zero, exp_log hw0]
  · intro t ht
    rw [← ofReal_pow, arg_ofReal_of_nonneg (by positivity), mul_zero]
  · intro t ht
    have : ((t : ℂ) * I) ^ 2 = ((-(t ^ 2) : ℝ) : ℂ) := by
      rw [mul_pow, I_sq]; push_cast; ring
    rw [this, arg_ofReal_of_neg (by nlinarith)]
    field_simp
  · intro z h1 h2
    have hz0 : z ≠ 0 := fun h => by simp [h] at h1
    have a1 : 0 < arg z := (harg_up z h2).1
    have a2 : arg z < Real.pi / 2 := by
      have := abs_arg_lt_pi_div_two_iff.mpr (Or.inl h1)
      exact (abs_lt.mp this).2
    have h2l : (2 * log z).im = 2 * arg z := by simp [log_im]
    have : z ^ 2 = exp (2 * log z) := by
      rw [show (2 : ℂ) = ((2 : ℕ) : ℂ) by norm_num, exp_nat_mul, exp_log hz0]
    rw [this, hargexp _ (by rw [h2l]; linarith [Real.pi_pos]) (by rw [h2l]; linarith), h2l]
    ring

/-- Worked numbers: (1 + 2i)^2 = 1 + 4i - 4 = -3 + 4i. -/
example : ((1 : ℂ) + 2 * I) ^ 2 = -3 + 4 * I := by
  apply Complex.ext <;> simp [sq] <;> norm_num

/-- Quarter-plane walls: 2 goes to 4 and 2i goes to -4. -/
example : (2 : ℂ) ^ 2 = 4 ∧ ((2 : ℂ) * I) ^ 2 = -4 := by
  constructor
  · norm_num
  · rw [mul_pow, I_sq]; norm_num

/-- The fold: z^2 on the half plane sends 2 and -2 to the same point 4. -/
example : (2 : ℂ) ^ 2 = 4 ∧ (-2 : ℂ) ^ 2 = 4 := by
  constructor <;> norm_num

#print axioms laplacian_comp_holomorphic
#print axioms harmonic_comp_holomorphic
#print axioms corridor_and_quarter_plane_by_mapping
