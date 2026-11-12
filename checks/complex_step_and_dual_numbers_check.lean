-- Complex steps and dual numbers: the complex step Im f(y + ih)/h misses the slope by at most a constant times h², and a dual number carries the exact slope.
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.Complex.RealDeriv
import Mathlib.Analysis.Complex.Liouville
import Mathlib.Analysis.Complex.TaylorSeries
import Mathlib.Algebra.DualNumber
import Mathlib.Algebra.Polynomial.Taylor
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Complex Metric DualNumber TrivSqZeroExt

lemma im_deriv_eq_zero_of_real (g : ℂ → ℂ) (y ρ : ℝ) (hg : DifferentiableOn ℂ g (ball (y : ℂ) ρ))
    (hr : ∀ x : ℝ, |x - y| < ρ → (g x).im = 0) (x : ℝ) (hx : |x - y| < ρ) :
    (deriv g x).im = 0 := by
  have hmem : (x : ℂ) ∈ ball (y : ℂ) ρ := by
    rw [mem_ball, Complex.dist_eq, ← ofReal_sub, norm_real, Real.norm_eq_abs]; exact hx
  have hd : HasDerivAt g (deriv g x) x :=
    (hg.differentiableAt (isOpen_ball.mem_nhds hmem)).hasDerivAt
  have h1 := hd.comp_ofReal
  have h2 : HasDerivAt (fun t : ℝ => (g t).im) (deriv g x).im x := by
    have h4 : HasDerivAt (fun z => -I * g z) (-I * deriv g x) x := hd.const_mul (-I)
    simpa using h4.real_of_complex
  have h3 : (fun t : ℝ => (g t).im) =ᶠ[nhds x] fun _ => (0 : ℝ) := by
    have : ball y ρ ∈ nhds x := isOpen_ball.mem_nhds (by rw [mem_ball, Real.dist_eq]; exact hx)
    filter_upwards [this] with t ht
    exact hr t (by rw [mem_ball, Real.dist_eq] at ht; exact ht)
  exact h2.unique ((hasDerivAt_const x (0 : ℝ)).congr_of_eventuallyEq h3)

#print axioms im_deriv_eq_zero_of_real

lemma im_iteratedDeriv_eq_zero_of_real (y ρ : ℝ) (n : ℕ) : ∀ g : ℂ → ℂ,
    DifferentiableOn ℂ g (ball (y : ℂ) ρ) → (∀ x : ℝ, |x - y| < ρ → (g x).im = 0) →
    ∀ x : ℝ, |x - y| < ρ → (iteratedDeriv n g x).im = 0 := by
  induction n with
  | zero => intro g _ hr x hx; simpa using hr x hx
  | succ n ih =>
    intro g hg hr x hx
    rw [iteratedDeriv_succ']
    exact ih (deriv g) (hg.deriv isOpen_ball)
      (fun x hx => im_deriv_eq_zero_of_real g y ρ hg hr x hx) x hx

#print axioms im_iteratedDeriv_eq_zero_of_real

/-- The complex step's error bound. Let `P` be a real function whose complex extension `f`
is real on the real line (`f x = P x`) and has a complex derivative on the closed disc of
radius `ρ` about the real point `y`, with `|f| ≤ M` on the circle of that disc. Then for
every step `0 < h < ρ`, the slope read off the imaginary part, `Im f(y + ih) / h`, differs
from the true slope `P'(y)` by at most `(M/ρ)·(h/ρ)²/(1 − (h/ρ)²)`; and for `h ≤ ρ/2` this
is at most `(4/3)·M·h²/ρ³`, so the error is of order `h²`. -/
theorem complex_step_error_le
    (f : ℂ → ℂ) (P : ℝ → ℝ) (y ρ M h : ℝ)
    (hf : DifferentiableOn ℂ f (closedBall (y : ℂ) ρ))
    (hreal : ∀ x : ℝ, f x = P x)
    (hM : ∀ z ∈ sphere (y : ℂ) ρ, ‖f z‖ ≤ M)
    (hh : 0 < h) (hhρ : h < ρ) :
    |(f (y + h * I)).im / h - deriv P y| ≤ M / ρ * ((h / ρ) ^ 2 / (1 - (h / ρ) ^ 2)) ∧
      (h ≤ ρ / 2 → |(f (y + h * I)).im / h - deriv P y| ≤ 4 / 3 * M * h ^ 2 / ρ ^ 3) := by
  have hρ : 0 < ρ := hh.trans hhρ
  have hfb : DifferentiableOn ℂ f (ball (y : ℂ) ρ) := hf.mono ball_subset_closedBall
  have hre : ∀ x : ℝ, |x - y| < ρ → (f x).im = 0 := fun x _ => by rw [hreal]; simp
  set c : ℕ → ℂ := fun n => iteratedDeriv n f y with hc
  have creal : ∀ n, c n = ((c n).re : ℂ) := fun n => by
    apply Complex.ext <;> simp only [ofReal_re, ofReal_im]
    exact im_iteratedDeriv_eq_zero_of_real y ρ n f hfb hre y (by simpa using hρ)
  have hcb : ∀ n, ‖c n‖ ≤ n.factorial * M / ρ ^ n := fun n =>
    norm_iteratedDeriv_le_of_forall_mem_sphere_norm_le n hρ (hf.diffContOnCl_ball subset_rfl) hM
  -- real coefficients
  set a : ℕ → ℝ := fun n => ((n.factorial : ℝ))⁻¹ * (c n).re with ha
  have hab : ∀ n, |a n| ≤ M / ρ ^ n := fun n => by
    have h1 : |(c n).re| ≤ n.factorial * M / ρ ^ n := (abs_re_le_norm _).trans (hcb n)
    have hfac : (0 : ℝ) < n.factorial := by exact_mod_cast n.factorial_pos
    rw [ha, abs_mul, abs_inv, abs_of_pos hfac]
    calc (n.factorial : ℝ)⁻¹ * |(c n).re| ≤ (n.factorial : ℝ)⁻¹ * (n.factorial * M / ρ ^ n) :=
          mul_le_mul_of_nonneg_left h1 (by positivity)
      _ = M / ρ ^ n := by field_simp
  -- Taylor series at z = y + h I
  have hz : (y : ℂ) + h * I ∈ ball (y : ℂ) ρ := by
    rw [mem_ball, Complex.dist_eq, add_sub_cancel_left, norm_mul, norm_real, Complex.norm_I,
      mul_one, Real.norm_eq_abs, abs_of_pos hh]
    exact hhρ
  have H := Complex.hasSum_taylorSeries_on_ball hfb hz
  rw [add_sub_cancel_left] at H
  have hT : ∀ n, ((n.factorial : ℂ))⁻¹ • ((h : ℂ) * I) ^ n • c n = (a n : ℂ) * ((h : ℂ) * I) ^ n :=
    fun n => by
      rw [creal n]; simp only [ha, smul_eq_mul, ofReal_mul, ofReal_inv, ofReal_natCast]; ring
  have H' : HasSum (fun n => (a n : ℂ) * ((h : ℂ) * I) ^ n) (f (y + h * I)) := by
    convert H using 1; funext n; exact (hT n).symm
  have H2 := Complex.hasSum_im H'
  have hpow : ∀ k : ℕ, ((h : ℂ) * I) ^ (2 * k) = (((-1) ^ k * h ^ (2 * k) : ℝ) : ℂ) := fun k => by
    rw [pow_mul, mul_pow, I_sq]; push_cast; ring
  have hodd : ∀ k : ℕ, ((a (2 * k + 1) : ℂ) * ((h : ℂ) * I) ^ (2 * k + 1)).im
      = a (2 * k + 1) * (-1) ^ k * h ^ (2 * k + 1) := fun k => by
    rw [pow_succ, hpow k]
    simp only [mul_im, mul_re, ofReal_re, ofReal_im, I_re, I_im]
    ring
  have hinj : Function.Injective (fun k : ℕ => 2 * k + 1) := fun i j hij => by
    simp only at hij; omega
  have H3 : HasSum (fun k : ℕ => a (2 * k + 1) * (-1) ^ k * h ^ (2 * k + 1))
      (f (y + h * I)).im := by
    have := (hinj.hasSum_iff (f := fun n => ((a n : ℂ) * ((h : ℂ) * I) ^ n).im) (a := (f (y + h * I)).im)
      (fun n hn => by
        obtain ⟨k, rfl | rfl⟩ := Nat.even_or_odd' n
        · rw [hpow k, ← ofReal_mul, ofReal_im]
        · exact absurd ⟨k, rfl⟩ hn)).mpr H2
    convert this using 1; funext k; exact (hodd k).symm
  have H4 : HasSum (fun k : ℕ => a (2 * k + 1) * (-1) ^ k * h ^ (2 * k))
      ((f (y + h * I)).im / h) := by
    convert H3.div_const h using 2 with k
    rw [pow_succ]; field_simp
  have H5 := (hasSum_nat_add_iff' 1).mpr H4
  simp only [Finset.sum_range_one, pow_zero, mul_one, mul_zero] at H5
  -- the true slope
  have hderiv : deriv P y = a 1 := by
    have hdf : HasDerivAt f (deriv f y) y :=
      (hfb.differentiableAt (isOpen_ball.mem_nhds (mem_ball_self hρ))).hasDerivAt
    have h1 := hdf.real_of_complex
    have hPf : (fun x : ℝ => (f x).re) = P := funext fun x => by rw [hreal]; simp
    rw [hPf] at h1
    rw [h1.deriv, ha, hc]; simp
  rw [hderiv]
  -- the geometric majorant
  set q := h / ρ with hq
  have hq0 : 0 ≤ q ^ 2 := by positivity
  have hq1 : q ^ 2 < 1 := by
    have : q < 1 := (div_lt_one hρ).mpr hhρ
    have : 0 < q := div_pos hh hρ
    nlinarith
  have G : HasSum (fun k : ℕ => M / ρ * (q ^ 2) ^ (k + 1)) (M / ρ * (q ^ 2 / (1 - q ^ 2))) := by
    have := (hasSum_geometric_of_lt_one hq0 hq1).mul_left (M / ρ * q ^ 2)
    convert this using 1
    · funext k; ring
    · rw [div_eq_mul_inv]; ring
  have hterm : ∀ k : ℕ, |a (2 * (k + 1) + 1) * (-1) ^ (k + 1) * h ^ (2 * (k + 1))|
      ≤ M / ρ * (q ^ 2) ^ (k + 1) := fun k => by
    rw [abs_mul, abs_mul, abs_pow, abs_neg, abs_one, one_pow, mul_one, abs_pow, abs_of_pos hh]
    calc |a (2 * (k + 1) + 1)| * h ^ (2 * (k + 1))
        ≤ M / ρ ^ (2 * (k + 1) + 1) * h ^ (2 * (k + 1)) :=
          mul_le_mul_of_nonneg_right (hab _) (by positivity)
      _ = M / ρ * (q ^ 2) ^ (k + 1) := by
          have e : ((h / ρ) ^ 2) ^ (k + 1) = h ^ (2 * (k + 1)) / ρ ^ (2 * (k + 1)) := by
            rw [← pow_mul, div_pow]
          rw [hq, e, pow_succ ρ]; field_simp
  have hmain : |(f (y + h * I)).im / h - a 1| ≤ M / ρ * (q ^ 2 / (1 - q ^ 2)) := by
    rw [abs_le]; constructor
    · have := hasSum_le (fun k => neg_le_of_abs_le (hterm k)) G.neg H5
      linarith
    · exact hasSum_le (fun k => le_of_abs_le (hterm k)) H5 G
  refine ⟨hmain, fun h2 => hmain.trans ?_⟩
  have hM0 : 0 ≤ M := by
    have hs : (y : ℂ) + ρ ∈ sphere (y : ℂ) ρ := by
      rw [mem_sphere, Complex.dist_eq, add_sub_cancel_left, norm_real, Real.norm_eq_abs,
        abs_of_pos hρ]
    exact (norm_nonneg _).trans (hM _ hs)
  have hqh : q ≤ 1 / 2 := by rw [hq, div_le_iff₀ hρ]; linarith
  have hqp : 0 < q := div_pos hh hρ
  have hq2 : q ^ 2 / (1 - q ^ 2) ≤ 4 / 3 * q ^ 2 := by
    have h14 : q ^ 2 ≤ 1 / 4 := by nlinarith
    rw [div_le_iff₀ (by linarith)]; nlinarith [mul_le_mul_of_nonneg_left h14 hq0]
  calc M / ρ * (q ^ 2 / (1 - q ^ 2)) ≤ M / ρ * (4 / 3 * q ^ 2) :=
        mul_le_mul_of_nonneg_left hq2 (div_nonneg hM0 hρ.le)
    _ = 4 / 3 * M * h ^ 2 / ρ ^ 3 := by rw [hq]; field_simp

/-- A dual number carries the exact slope: for a polynomial `p` with real coefficients,
evaluating at the dual yield `y + ε` (where `ε² = 0`) gives `p(y) + p'(y) ε`, with no step
and no truncation error. -/
theorem dual_number_eval_eq_value_add_slope (p : Polynomial ℝ) (y : ℝ) :
    Polynomial.aeval (inl y + ε : ℝ[ε]) p =
      inl (p.eval y) + inl (p.derivative.eval y) * ε := by
  rw [Polynomial.aeval_add_of_sq_eq_zero _ _ _ (by rw [sq, eps_mul_eps])]
  rw [← algebraMap_eq_inl, Polynomial.aeval_algebraMap_apply_eq_algebraMap_eval,
    Polynomial.aeval_algebraMap_apply_eq_algebraMap_eval]

/-- The dual-number reciprocal rule used for the discount factor `1/(1 + y)`: when `a ≠ 0`,
`1/(a + bε) = 1/a − (b/a²) ε`, the derivative rule for a reciprocal. -/
theorem dual_number_inv_eq (a b : ℝ) (ha : a ≠ 0) :
    (inl a + inl b * ε : ℝ[ε])⁻¹ = inl a⁻¹ - inl (b / a ^ 2) * ε := by
  ext <;> simp
  field_simp

/-- The card's bond at par: a $5 annual coupon for 30 years plus $100 face, discounted at
5% (so `v = 1/1.05 = 20/21`), is worth exactly $100. -/
example :
    (∑ t ∈ Finset.range 30, (5 : ℚ) * (20 / 21) ^ (t + 1)) + 100 * (20 / 21) ^ 30 = 100 := by
  norm_num [Finset.sum_range_succ]

/-- The card's exact slope at par: `P'(0.05) = -(F/y)(1 - 1.05^-30) = -2000 (1 - (20/21)^30)`,
checked against the term-by-term sum `-Σ c_t t v^(t+1)`. -/
example :
    (∑ t ∈ Finset.range 30, -(5 : ℚ) * (t + 1) * (20 / 21) ^ (t + 2))
        - 100 * 30 * (20 / 21) ^ 31 = -2000 * (1 - (20 / 21) ^ 30) := by
  norm_num [Finset.sum_range_succ]

#print axioms complex_step_error_le
#print axioms dual_number_eval_eq_value_add_slope
#print axioms dual_number_inv_eq
