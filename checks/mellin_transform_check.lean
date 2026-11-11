-- The Mellin transform: for Re s > 1 the Mellin transform of 1/(e^t - 1) is Γ(s)ζ(s), stretching the input by k > 0 multiplies the transform by k^(-s), and the transform of e^(-t) is Γ(s) for Re s > 0.
import Mathlib.Analysis.MellinTransform
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.NumberTheory.LSeries.HurwitzZetaValues
import Mathlib.Tactic.NormNum

open Real

section Helpers

open MeasureTheory Set

lemma helper_geom (t : ℝ) (ht : 0 < t) :
    1 / (Real.exp t - 1) = ∑' n : ℕ, Real.exp (-(((n : ℝ) + 1) * t)) := by
  have h0 : 0 ≤ Real.exp (-t) := (Real.exp_pos _).le
  have h1 : Real.exp (-t) < 1 := by
    have := Real.exp_lt_exp.mpr (show -t < 0 by linarith); simpa using this
  have : ∀ n : ℕ, Real.exp (-(((n : ℝ) + 1) * t)) = Real.exp (-t) * Real.exp (-t) ^ n := by
    intro n
    rw [← Real.exp_nat_mul, ← Real.exp_add]; congr 1; ring
  simp_rw [this]
  rw [tsum_mul_left, tsum_geometric_of_lt_one h0 h1, Real.exp_neg]
  have : 1 < Real.exp t := Real.one_lt_exp_iff.mpr ht
  field_simp

lemma helper_norm (s : ℂ) (r t : ℝ) (ht : 0 < t) :
    ‖(t : ℂ) ^ (s - 1) * Complex.exp (-((r : ℂ) * t))‖ = t ^ (s.re - 1) * Real.exp (-r * t ^ (1:ℝ)) := by
  rw [norm_mul, Complex.norm_cpow_eq_rpow_re_of_pos ht, Complex.norm_exp, Real.rpow_one]
  simp

lemma helper_int (s : ℂ) (hs : 0 < s.re) {r : ℝ} (hr : 0 < r) :
    IntegrableOn (fun t : ℝ => (t : ℂ) ^ (s - 1) * Complex.exp (-((r : ℂ) * t))) (Ioi 0) := by
  have hI := integrableOn_rpow_mul_exp_neg_mul_rpow (p := 1) (s := s.re - 1) (b := r)
    (by linarith) one_pos hr
  refine Integrable.mono' hI ?_ ?_
  · refine Measurable.aestronglyMeasurable ?_
    fun_prop
  · refine (ae_restrict_iff' measurableSet_Ioi).mpr (Filter.Eventually.of_forall fun t ht => ?_)
    exact (helper_norm s r t ht).le

lemma helper_intval (s : ℂ) (hs : 0 < s.re) (n : ℕ) :
    ∫ t : ℝ in Ioi 0, (t : ℂ) ^ (s - 1) * Complex.exp (-(((n : ℝ) + 1 : ℝ) * (t : ℂ)))
      = Complex.Gamma s * (1 / ((n : ℂ) + 1) ^ s) := by
  rw [Complex.integral_cpow_mul_exp_neg_mul_Ioi hs (by positivity), mul_comm]
  congr 1
  rw [one_div, one_div, Complex.inv_cpow]
  · push_cast; rfl
  · rw [show ((((n : ℝ) + 1 : ℝ)) : ℂ) = (((n : ℝ) + 1 : ℝ) : ℂ) from rfl, Complex.arg_ofReal_of_nonneg (by positivity)]
    exact Real.pi_pos.ne

lemma helper_normint (s : ℂ) (hs : 0 < s.re) (n : ℕ) :
    ∫ t : ℝ in Ioi 0, ‖(t : ℂ) ^ (s - 1) * Complex.exp (-(((n : ℝ) + 1 : ℝ) * (t : ℂ)))‖
      = (1 / ((n : ℝ) + 1)) ^ s.re * Real.Gamma s.re := by
  rw [← Real.integral_rpow_mul_exp_neg_mul_Ioi hs (by positivity)]
  refine setIntegral_congr_fun measurableSet_Ioi fun t ht => ?_
  rw [helper_norm s _ t ht, Real.rpow_one, neg_mul]

#print axioms helper_geom
#print axioms helper_norm
#print axioms helper_int
#print axioms helper_intval
#print axioms helper_normint

end Helpers

/-- The card's main claim, the gamma-zeta integral. For every complex s with Re s > 1, the
Mellin transform of 1/(e^t - 1), that is the area under t^(s-1)/(e^t - 1) over the positive
axis, equals gamma times zeta: Γ(s)ζ(s). -/
theorem mellin_one_div_exp_sub_one_eq_gamma_mul_zeta (s : ℂ) (hs : 1 < s.re) :
    mellin (fun t : ℝ => ((1 / (Real.exp t - 1) : ℝ) : ℂ)) s
      = Complex.Gamma s * riemannZeta s := by
  have hs0 : 0 < s.re := by linarith
  set F : ℕ → ℝ → ℂ := fun n t =>
    (t : ℂ) ^ (s - 1) * Complex.exp (-(((n : ℝ) + 1 : ℝ) * (t : ℂ))) with hF
  have h1 : mellin (fun t : ℝ => ((1 / (Real.exp t - 1) : ℝ) : ℂ)) s
      = ∫ t : ℝ in Set.Ioi 0, ∑' n, F n t := by
    unfold mellin
    refine MeasureTheory.setIntegral_congr_fun measurableSet_Ioi fun t ht => ?_
    simp only [hF, smul_eq_mul]
    rw [helper_geom t ht, Complex.ofReal_tsum, ← tsum_mul_left]
    congr 1; funext n
    push_cast; rfl
  rw [h1, ← MeasureTheory.integral_tsum_of_summable_integral_norm (μ := MeasureTheory.volume.restrict (Set.Ioi 0))]
  · simp only [hF, helper_intval s hs0]
    rw [tsum_mul_left, zeta_eq_tsum_one_div_nat_add_one_cpow hs]
  · intro n
    exact helper_int s hs0 (by positivity)
  · simp only [hF, helper_normint s hs0]
    refine Summable.mul_right _ ?_
    have := (Real.summable_one_div_nat_add_rpow 1 s.re).mpr hs
    refine this.congr fun n => ?_
    have hn : (0 : ℝ) < (n : ℝ) + 1 := by positivity
    rw [abs_of_pos hn, Real.div_rpow zero_le_one hn.le, Real.one_rpow]

/-- Stretching becomes multiplying. For every function f on the positive axis, every complex s
and every stretch factor k > 0, the Mellin transform of f(kt) is k^(-s) times the Mellin
transform of f. -/
theorem mellin_stretch (f : ℝ → ℂ) (s : ℂ) {k : ℝ} (hk : 0 < k) :
    mellin (fun t => f (k * t)) s = (k : ℂ) ^ (-s) * mellin f s := by
  rw [mellin_comp_mul_left f s hk, smul_eq_mul]

/-- The first example is gamma. For every complex s with Re s > 0, the Mellin transform of
e^(-t) is Γ(s). -/
theorem mellin_exp_neg_eq_gamma (s : ℂ) (hs : 0 < s.re) :
    mellin (fun t : ℝ => ((Real.exp (-t) : ℝ) : ℂ)) s = Complex.Gamma s := by
  rw [Complex.Gamma_eq_integral hs, Complex.GammaIntegral, mellin]
  refine MeasureTheory.integral_congr_ae (Filter.Eventually.of_forall fun t => ?_)
  simp only [smul_eq_mul, mul_comm]

-- Worked numbers from the card, stated exactly.

-- Gamma at whole numbers: Γ(2) = 1! = 1 and Γ(4) = 3! = 6.
example : Complex.Gamma 2 = 1 := by
  rw [Complex.Gamma_ofNat_eq_factorial]; simp
example : Complex.Gamma 4 = 6 := by
  rw [Complex.Gamma_ofNat_eq_factorial]; simp [Nat.factorial]

-- Zipf, first four ranks with exponent 2: 1 + 1/4 + 1/9 + 1/16 = 205/144 (1.423611).
example : (∑ k ∈ Finset.range 4, (1 : ℚ) / ((k : ℚ) + 1) ^ 2) = 205 / 144 := by
  simp [Finset.sum_range_succ]; norm_num

-- Zipf city sizes with largest 8,000,000: rank 2 holds 4,000,000 and rank 4 holds 2,000,000.
example : 8000000 / 2 = 4000000 ∧ 8000000 / 4 = 2000000 := by norm_num

-- Stretch by k = 2 at s = 2: the transform of e^(-2t) is Γ(2)/2^2 = 1/4.
example : mellin (fun t : ℝ => ((Real.exp (-(2 * t)) : ℝ) : ℂ)) 2 = 1 / 4 := by
  have h := mellin_stretch (fun t : ℝ => ((Real.exp (-t) : ℝ) : ℂ)) 2 (k := 2) two_pos
  rw [h, mellin_exp_neg_eq_gamma 2 (by norm_num)]
  rw [Complex.Gamma_ofNat_eq_factorial, Complex.cpow_neg]
  norm_num

-- The two cases on the card: the area under t/(e^t - 1) is π^2/6, and under t^3/(e^t - 1)
-- it is Γ(4)ζ(4) = π^4/15.
example : mellin (fun t : ℝ => ((1 / (Real.exp t - 1) : ℝ) : ℂ)) 2 = (π : ℂ) ^ 2 / 6 := by
  rw [mellin_one_div_exp_sub_one_eq_gamma_mul_zeta 2 (by norm_num), riemannZeta_two,
    Complex.Gamma_ofNat_eq_factorial]
  simp
example : mellin (fun t : ℝ => ((1 / (Real.exp t - 1) : ℝ) : ℂ)) 4 = (π : ℂ) ^ 4 / 15 := by
  rw [mellin_one_div_exp_sub_one_eq_gamma_mul_zeta 4 (by norm_num), riemannZeta_four,
    Complex.Gamma_ofNat_eq_factorial]
  simp [Nat.factorial]
  ring

#print axioms mellin_one_div_exp_sub_one_eq_gamma_mul_zeta
#print axioms mellin_stretch
#print axioms mellin_exp_neg_eq_gamma
