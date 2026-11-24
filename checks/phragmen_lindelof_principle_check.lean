-- Phragmen-Lindelof: on the strip |Im z| < π/2 a holomorphic function with modulus at most 1 on both edges and growth below exp(A e^(c|x|)), c < 1, has modulus at most 1 inside; exp(exp z) shows the rate 1 fails; and Hadamard's three-lines bound holds.
import Mathlib.Analysis.Complex.PhragmenLindelof
import Mathlib.Analysis.Complex.Hadamard

open Complex Set

/-- **Phragmen-Lindelof on a strip.** Let S be the strip `|Im z| < π/2`. If f is holomorphic
on S and continuous up to its edges, `|f| ≤ 1` on both edges `Im z = ± π/2`, and
`|f(x + iy)| ≤ exp(A e^(c|x|))` on S for a fixed `A > 0` and a rate `c < 1`, then `|f| ≤ 1`
on all of S. -/
theorem phragmen_lindelof_strip (f : ℂ → ℂ)
    (hf : DiffContOnCl ℂ f {z : ℂ | |z.im| < Real.pi / 2})
    (h_top : ∀ z : ℂ, z.im = Real.pi / 2 → ‖f z‖ ≤ 1)
    (h_bot : ∀ z : ℂ, z.im = -(Real.pi / 2) → ‖f z‖ ≤ 1)
    (A c : ℝ) (hA : 0 < A) (hc : c < 1)
    (hgrowth : ∀ z : ℂ, |z.im| < Real.pi / 2 → ‖f z‖ ≤ Real.exp (A * Real.exp (c * |z.re|))) :
    ∀ z : ℂ, |z.im| < Real.pi / 2 → ‖f z‖ ≤ 1 := by
  intro z hz
  have hset : {z : ℂ | |z.im| < Real.pi / 2} = im ⁻¹' Ioo (-(Real.pi / 2)) (Real.pi / 2) := by
    ext w; simp [abs_lt]
  rw [hset] at hf
  have hz' := abs_lt.1 hz
  refine PhragmenLindelof.horizontal_strip (C := 1) hf ⟨c, ?_, A, ?_⟩ h_bot h_top hz'.1.le hz'.2.le
  · have : Real.pi / (Real.pi / 2 - -(Real.pi / 2)) = 1 := by
      field_simp; norm_num
    rw [this]; exact hc
  · refine Asymptotics.IsBigO.of_bound 1 ?_
    refine Filter.mem_inf_of_right ?_
    intro w hw
    have hw' : |w.im| < Real.pi / 2 := abs_lt.2 hw
    simp only [Real.norm_eq_abs, Real.abs_exp, one_mul]
    exact hgrowth w hw'

/-- **The growth bound is needed: `exp(exp z)` sits exactly on the rate limit.** On the strip
`|Im z| < π/2`, `f(z) = exp(exp z)` is holomorphic, has modulus 1 at every point of both edges,
grows at most like `exp(e^|x|)` (rate c = 1, A = 1), and yet `|f(1)| = e^e > 1`. -/
theorem exp_exp_escapes_strip :
    Differentiable ℂ (fun z : ℂ => Complex.exp (Complex.exp z)) ∧
    (∀ z : ℂ, z.im = Real.pi / 2 → ‖Complex.exp (Complex.exp z)‖ = 1) ∧
    (∀ z : ℂ, z.im = -(Real.pi / 2) → ‖Complex.exp (Complex.exp z)‖ = 1) ∧
    (∀ z : ℂ, |z.im| < Real.pi / 2 →
      ‖Complex.exp (Complex.exp z)‖ ≤ Real.exp (1 * Real.exp (1 * |z.re|))) ∧
    ‖Complex.exp (Complex.exp 1)‖ = Real.exp (Real.exp 1) ∧
    1 < ‖Complex.exp (Complex.exp 1)‖ := by
  have h1 : ‖Complex.exp (Complex.exp 1)‖ = Real.exp (Real.exp 1) := by
    rw [Complex.norm_exp, ← Complex.ofReal_one, Complex.exp_ofReal_re]
  refine ⟨Complex.differentiable_exp.comp Complex.differentiable_exp, ?_, ?_, ?_, h1, ?_⟩
  · intro z hz
    rw [Complex.norm_exp, Complex.exp_re, hz, Real.cos_pi_div_two, mul_zero, Real.exp_zero]
  · intro z hz
    rw [Complex.norm_exp, Complex.exp_re, hz, Real.cos_neg, Real.cos_pi_div_two, mul_zero,
      Real.exp_zero]
  · intro z _
    rw [Complex.norm_exp, Complex.exp_re, one_mul, one_mul]
    apply Real.exp_le_exp.2
    calc Real.exp z.re * Real.cos z.im ≤ Real.exp z.re * 1 :=
          mul_le_mul_of_nonneg_left (Real.cos_le_one _) (Real.exp_pos _).le
      _ = Real.exp z.re := mul_one _
      _ ≤ Real.exp |z.re| := Real.exp_le_exp.2 (le_abs_self _)
  · rw [h1]; exact Real.one_lt_exp_iff.2 (Real.exp_pos 1)

/-- **Hadamard's three-lines theorem.** Let f be bounded and continuous on the strip
`0 ≤ Re z ≤ 1` and holomorphic inside. Write `M(θ)` for the least upper bound of `|f|` on the
line `Re z = θ`. Then `M(θ) ≤ M(0)^(1-θ) · M(1)^θ` for every `0 ≤ θ ≤ 1`. -/
theorem hadamard_three_lines (f : ℂ → ℂ)
    (hf : DiffContOnCl ℂ f {z : ℂ | 0 < z.re ∧ z.re < 1})
    (hbdd : BddAbove ((fun z => ‖f z‖) '' {z : ℂ | 0 ≤ z.re ∧ z.re ≤ 1}))
    (θ : ℝ) (hθ0 : 0 ≤ θ) (hθ1 : θ ≤ 1) :
    HadamardThreeLines.sSupNormIm f θ ≤
      HadamardThreeLines.sSupNormIm f 0 ^ (1 - θ) * HadamardThreeLines.sSupNormIm f 1 ^ θ := by
  have hd : DiffContOnCl ℂ f (HadamardThreeLines.verticalStrip 0 1) := by
    convert hf using 1
    ext w; simp [HadamardThreeLines.verticalStrip]
  have hB : BddAbove ((norm ∘ f) '' HadamardThreeLines.verticalClosedStrip 0 1) := by
    convert hbdd using 1
    ext r; simp [HadamardThreeLines.verticalClosedStrip]
  have key : ∀ z : ℂ, z.re = θ → ‖f z‖ ≤
      HadamardThreeLines.sSupNormIm f 0 ^ (1 - θ) * HadamardThreeLines.sSupNormIm f 1 ^ θ := by
    intro z hz
    have hzm : z ∈ HadamardThreeLines.verticalClosedStrip 0 1 := by
      simp only [HadamardThreeLines.verticalClosedStrip, mem_preimage, mem_Icc, hz]
      exact ⟨hθ0, hθ1⟩
    have := HadamardThreeLines.norm_le_interp_of_mem_verticalClosedStrip₀₁' f hzm hd hB
      (a := HadamardThreeLines.sSupNormIm f 0) (b := HadamardThreeLines.sSupNormIm f 1)
      (fun w hw => by
        have hw' : w.re = 0 := hw
        have := HadamardThreeLines.norm_le_sSupNormIm f w
          (by simp [HadamardThreeLines.verticalClosedStrip, hw']) hB
        rwa [hw'] at this)
      (fun w hw => by
        have hw' : w.re = 1 := hw
        have := HadamardThreeLines.norm_le_sSupNormIm f w
          (by simp [HadamardThreeLines.verticalClosedStrip, hw']) hB
        rwa [hw'] at this)
    rwa [hz] at this
  unfold HadamardThreeLines.sSupNormIm
  apply csSup_le
  · exact ⟨_, mem_image_of_mem _ (show (θ : ℂ) ∈ re ⁻¹' {θ} by simp)⟩
  · rintro _ ⟨w, hw, rfl⟩
    exact key w hw

#print axioms phragmen_lindelof_strip
#print axioms exp_exp_escapes_strip
#print axioms hadamard_three_lines
