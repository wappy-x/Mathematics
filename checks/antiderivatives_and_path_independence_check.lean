-- Antiderivatives: if F' = f on an open set holding a piecewise smooth path, the integral of f along the path is F(end) − F(start), while 1/z has no antiderivative on any open set holding a circle round 0 and is the only power of z without one.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv
import Mathlib.Analysis.Calculus.Deriv.ZPow
import Mathlib.Analysis.Calculus.ContDiff.Basic

open Complex Real Set

-- Helper: on one smooth piece [a, b], the integral of f(γ(t)) γ'(t) is F(γ(b)) − F(γ(a)).
theorem piece_integral_eq (f F : ℂ → ℂ) (U : Set ℂ)
    (hF : ∀ z ∈ U, HasDerivAt F (f z) z) (hf : ContinuousOn f U)
    (γ : ℝ → ℂ) (a b : ℝ) (hab : a < b) (hγU : ∀ t ∈ Icc a b, γ t ∈ U)
    (hγ : ContDiffOn ℝ 1 γ (Icc a b)) :
    IntervalIntegrable (fun t => f (γ t) * deriv γ t) MeasureTheory.volume a b ∧
    ∫ t in a..b, f (γ t) * deriv γ t = F (γ b) - F (γ a) := by
  have hγc : ContinuousOn γ (Icc a b) := hγ.continuousOn
  have hfγ : ContinuousOn (fun t => f (γ t)) (Icc a b) :=
    hf.comp hγc (fun t ht => hγU t ht)
  have hdw : ContinuousOn (derivWithin γ (Icc a b)) (Icc a b) :=
    hγ.continuousOn_derivWithin (uniqueDiffOn_Icc hab) le_rfl
  have hEq : EqOn (fun t => f (γ t) * deriv γ t) (fun t => f (γ t) * derivWithin γ (Icc a b) t)
      (Ioo a b) := by
    intro t ht
    simp only
    rw [derivWithin_of_mem_nhds (Icc_mem_nhds ht.1 ht.2)]
  have hint : IntervalIntegrable (fun t => f (γ t) * deriv γ t) MeasureTheory.volume a b := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le hab.le]
    have h1 : MeasureTheory.IntegrableOn (fun t => f (γ t) * derivWithin γ (Icc a b) t)
        (Icc a b) := (hfγ.mul hdw).integrableOn_compact isCompact_Icc
    have h2 := (h1.mono_set Ioo_subset_Icc_self).congr_fun hEq.symm measurableSet_Ioo
    exact ((integrableOn_Icc_iff_integrableOn_Ioo).2 h2).mono_set Ioc_subset_Icc_self
  refine ⟨hint, ?_⟩
  apply intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hab.le
  · have hFc : ContinuousOn F U := fun z hz => (hF z hz).continuousAt.continuousWithinAt
    exact hFc.comp hγc (fun t ht => hγU t ht)
  · intro t ht
    have hd : DifferentiableAt ℝ γ t :=
      (hγ.contDiffAt (Icc_mem_nhds ht.1 ht.2)).differentiableAt one_ne_zero
    exact (hF (γ t) (hγU t (Ioo_subset_Icc_self ht))).comp t hd.hasDerivAt
  · exact hint

#print axioms piece_integral_eq

-- Helper: the derivative of t ↦ e^(2πit).
theorem hasDerivAt_exp_two_pi_I (t : ℝ) :
    HasDerivAt (fun s : ℝ => exp (2 * π * I * s)) (2 * π * I * exp (2 * π * I * t)) t := by
  have h := (((hasDerivAt_id (t : ℂ)).const_mul (2 * π * I)).cexp).comp_ofReal
  simp only [id] at h
  convert h using 1
  ring

#print axioms hasDerivAt_exp_two_pi_I

-- Antiderivative test: if g' is the complex derivative of g everywhere, then ∫₀¹ g'(t) dt = g(1) - g(0).
theorem integral_unit_of_complex_antideriv (g g' : ℂ → ℂ) (hg : ∀ z, HasDerivAt g (g' z) z)
    (hc : Continuous g') : ∫ t in (0 : ℝ)..1, g' t = g 1 - g 0 := by
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun t : ℝ => g t)
    (fun t _ => (hg t).comp_ofReal) ((hc.comp continuous_ofReal).intervalIntegrable 0 1)]
  simp

#print axioms integral_unit_of_complex_antideriv

/-- If F has complex derivative f on an open set U, f is continuous, and the path γ (clock t from
0 to 1) stays inside U and is made of finitely many smooth pieces (corners allowed), then the
integral of f along γ, that is ∫₀¹ f(γ(t)) γ'(t) dt, equals F at the finish minus F at the start.
So any two such routes with the same ends give the same answer. -/
theorem integral_along_path_eq_antiderivative_change
    (f F : ℂ → ℂ) (U : Set ℂ) (hU : IsOpen U)
    (hF : ∀ z ∈ U, HasDerivAt F (f z) z) (hf : ContinuousOn f U)
    (γ : ℝ → ℂ) (hγU : ∀ t ∈ Icc (0 : ℝ) 1, γ t ∈ U)
    (n : ℕ) (c : ℕ → ℝ) (hc0 : c 0 = 0) (hcn : c n = 1) (hcmono : ∀ k < n, c k < c (k + 1))
    (hpieces : ∀ k < n, ContDiffOn ℝ 1 γ (Icc (c k) (c (k + 1)))) :
    ∫ t in (0 : ℝ)..1, f (γ t) * deriv γ t = F (γ 1) - F (γ 0) := by
  have hle : ∀ i j, i ≤ j → j ≤ n → c i ≤ c j := by
    intro i j hij
    induction j, hij using Nat.le_induction with
    | base => intro _; exact le_rfl
    | succ j hij ih =>
      intro hj
      exact (ih (by omega)).trans (hcmono j (by omega)).le
  have hpiece : ∀ k < n,
      IntervalIntegrable (fun t => f (γ t) * deriv γ t) MeasureTheory.volume (c k) (c (k + 1)) ∧
      ∫ t in (c k)..(c (k + 1)), f (γ t) * deriv γ t = F (γ (c (k + 1))) - F (γ (c k)) := by
    intro k hk
    refine piece_integral_eq f F U hF hf γ (c k) (c (k + 1)) (hcmono k hk) ?_ (hpieces k hk)
    intro t ht
    apply hγU
    constructor
    · rw [← hc0]; exact (hle 0 k (Nat.zero_le _) hk.le).trans ht.1
    · rw [← hcn]; exact ht.2.trans (hle (k + 1) n hk le_rfl)
  have hsum := intervalIntegral.sum_integral_adjacent_intervals
    (f := fun t => f (γ t) * deriv γ t) (μ := MeasureTheory.volume) (a := c) (n := n)
    (fun k hk => (hpiece k hk).1)
  rw [hc0, hcn] at hsum
  rw [← hsum, Finset.sum_congr rfl (fun k hk => (hpiece k (Finset.mem_range.1 hk)).2),
    Finset.sum_range_sub (fun k => F (γ (c k))) n, hc0, hcn]

/-- Once anticlockwise round the unit circle, γ(t) = e^(2πit), the function 1/z adds up to 2πi,
not 0; and 1/z has no antiderivative on any open set that holds a circle round 0. -/
theorem inv_loop_and_no_antiderivative :
    (∫ t in (0 : ℝ)..1, (exp (2 * π * I * t))⁻¹ * deriv (fun s : ℝ => exp (2 * π * I * s)) t
        = 2 * π * I) ∧
      ∀ r : ℝ, 0 < r → ∀ U : Set ℂ, IsOpen U → Metric.sphere (0 : ℂ) r ⊆ U →
        ¬ ∃ F : ℂ → ℂ, ∀ z ∈ U, HasDerivAt F z⁻¹ z := by
  have hval : ∀ t : ℝ, (exp (2 * π * I * t))⁻¹ * (2 * π * I * exp (2 * π * I * t)) = 2 * π * I := by
    intro t
    field_simp [Complex.exp_ne_zero]
  refine ⟨?_, ?_⟩
  · simp_rw [fun t => (hasDerivAt_exp_two_pi_I t).deriv, hval]
    simp
  · rintro r hr U hU hsub ⟨F, hF⟩
    set γ : ℝ → ℂ := fun s => (r : ℂ) * exp (2 * π * I * s) with hγdef
    have hγd : ∀ t : ℝ, HasDerivAt γ ((r : ℂ) * (2 * π * I * exp (2 * π * I * t))) t :=
      fun t => (hasDerivAt_exp_two_pi_I t).const_mul (r : ℂ)
    have hr0 : (r : ℂ) ≠ 0 := by exact_mod_cast hr.ne'
    have hγU : ∀ t ∈ Icc (0 : ℝ) 1, γ t ∈ U \ {0} := by
      intro t _
      refine ⟨hsub ?_, ?_⟩
      · rw [mem_sphere_zero_iff_norm, hγdef]
        simp only
        rw [norm_mul, Complex.norm_exp]
        have : (2 * π * I * (t : ℂ)).re = 0 := by simp
        rw [this, Real.exp_zero, mul_one, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hr]
      · simp [hγdef, hr0, Complex.exp_ne_zero]
    have hcd : ContDiff ℝ 1 γ := by
      rw [hγdef]
      exact contDiff_const.mul ((contDiff_const.mul ofRealCLM.contDiff).cexp)
    have key := integral_along_path_eq_antiderivative_change (fun z => z⁻¹) F (U \ {0})
      (hU.sdiff isClosed_singleton) (fun z hz => hF z hz.1)
      (fun z hz => (continuousAt_inv₀ (by simpa using hz.2)).continuousWithinAt)
      γ hγU 1 (fun k => (k : ℝ)) (by simp) (by simp) (fun k hk => by push_cast; linarith)
      (fun k _ => hcd.contDiffOn)
    have hval2 : ∀ t : ℝ, (γ t)⁻¹ * deriv γ t = 2 * π * I := by
      intro t
      rw [(hγd t).deriv, hγdef]
      simp only
      field_simp [Complex.exp_ne_zero]
    simp_rw [hval2] at key
    have h1 : γ 1 = γ 0 := by
      simp [hγdef, Complex.exp_two_pi_mul_I]
    rw [h1, sub_self] at key
    simp [Real.pi_ne_zero, I_ne_zero] at key

/-- Among the whole-number powers z^n, every one except 1/z has an antiderivative on the plane
with 0 removed (namely z^(n+1)/(n+1)); 1/z, n = −1, is the only one without. -/
theorem zpow_has_antiderivative_iff (n : ℤ) :
    (∃ F : ℂ → ℂ, ∀ z : ℂ, z ≠ 0 → HasDerivAt F (z ^ n) z) ↔ n ≠ -1 := by
  constructor
  · rintro ⟨F, hF⟩ rfl
    apply (inv_loop_and_no_antiderivative.2 1 one_pos {z | z ≠ 0} isOpen_ne ?_)
    · refine ⟨F, fun z hz => ?_⟩
      simpa using hF z hz
    · intro z hz
      have : ‖z‖ = 1 := by simpa using hz
      intro h0
      rw [h0, norm_zero] at this
      exact zero_ne_one this
  · intro hn
    have hn1 : ((n + 1 : ℤ) : ℂ) ≠ 0 := by
      exact_mod_cast (show n + 1 ≠ 0 by omega)
    refine ⟨fun z => z ^ (n + 1) / ((n + 1 : ℤ) : ℂ), fun z hz => ?_⟩
    have h := (hasDerivAt_zpow (n + 1) z (Or.inl hz)).div_const ((n + 1 : ℤ) : ℂ)
    convert h using 1
    rw [add_sub_cancel_right]
    field_simp

-- Cube the finish: (1 + i)^3 = −2 + 2i.
example : (1 + I) ^ 3 = -2 + 2 * I := by
  ring_nf; rw [I_sq, pow_three, I_mul_I]; ring

-- Straight route, by F = z^3/3: ((1 + i)^3 − 0^3)/3 = (−2 + 2i)/3.
example : ((1 + I) ^ 3 - 0 ^ 3) / 3 = (-2 + 2 * I) / 3 := by
  ring_nf; rw [I_sq, pow_three, I_mul_I]; ring

-- Broken route by F: first leg 1/3, second leg ((1 + i)^3 − 1)/3 = −1 + 2i/3, sum (−2 + 2i)/3.
example : (1 : ℂ) ^ 3 / 3 - 0 ^ 3 / 3 = 1 / 3 ∧ ((1 + I) ^ 3 - 1) / 3 = -1 + 2 * I / 3 ∧
    (1 / 3 : ℂ) + (-1 + 2 * I / 3) = (-2 + 2 * I) / 3 := by
  refine ⟨by norm_num, ?_, by ring⟩
  ring_nf; rw [I_sq, pow_three, I_mul_I]; ring

-- Walking the straight route γ(t) = (1 + i)t, velocity 1 + i: z^2 adds up to (−2 + 2i)/3.
example : ∫ t in (0 : ℝ)..1, ((1 + I) * t) ^ 2 * (1 + I) = (-2 + 2 * I) / 3 := by
  rw [integral_unit_of_complex_antideriv (fun z => ((1 + I) * z) ^ 3 / 3)
    (fun z => ((1 + I) * z) ^ 2 * (1 + I)) (fun z => by
      have h := (((hasDerivAt_id' z).const_mul (1 + I)).pow 3).div_const 3
      convert h using 1; norm_num; ring_nf) (by fun_prop)]
  ring_nf; rw [I_sq, pow_three, I_mul_I]; ring

-- Walking the broken route: along the real axis to 1, then up to 1 + i: the same (−2 + 2i)/3.
example : (∫ t in (0 : ℝ)..1, (t : ℂ) ^ 2 * 1) + (∫ t in (0 : ℝ)..1, (1 + I * t) ^ 2 * I)
    = (-2 + 2 * I) / 3 := by
  rw [integral_unit_of_complex_antideriv (fun z => z ^ 3 / 3)
    (fun z => z ^ 2 * 1) (fun z => by
      have h := ((hasDerivAt_id' z).pow 3).div_const 3
      convert h using 1; norm_num) (by fun_prop),
    integral_unit_of_complex_antideriv (fun z => (1 + I * z) ^ 3 / 3)
    (fun z => (1 + I * z) ^ 2 * I) (fun z => by
      have h := ((((hasDerivAt_id' z).const_mul I).const_add 1).pow 3).div_const 3
      convert h using 1; norm_num; ring_nf) (by fun_prop)]
  ring_nf; rw [I_sq, pow_three, I_mul_I]; ring

-- The triangle 0 → 2 → 1 + i → 0 gives 0 for z^2.
example : (∫ t in (0 : ℝ)..1, (2 * t : ℂ) ^ 2 * 2) +
    (∫ t in (0 : ℝ)..1, (2 + (-1 + I) * t) ^ 2 * (-1 + I)) +
    (∫ t in (0 : ℝ)..1, ((1 + I) * (1 - t)) ^ 2 * (-(1 + I))) = 0 := by
  rw [integral_unit_of_complex_antideriv (fun z => (2 * z) ^ 3 / 3)
    (fun z => (2 * z) ^ 2 * 2) (fun z => by
      have h := (((hasDerivAt_id' z).const_mul 2).pow 3).div_const 3
      convert h using 1; norm_num; ring_nf) (by fun_prop),
    integral_unit_of_complex_antideriv (fun z => (2 + (-1 + I) * z) ^ 3 / 3)
    (fun z => (2 + (-1 + I) * z) ^ 2 * (-1 + I)) (fun z => by
      have h := ((((hasDerivAt_id' z).const_mul (-1 + I)).const_add 2).pow 3).div_const 3
      convert h using 1; norm_num; ring_nf) (by fun_prop),
    integral_unit_of_complex_antideriv (fun z => ((1 + I) * (1 - z)) ^ 3 / 3)
    (fun z => ((1 + I) * (1 - z)) ^ 2 * (-(1 + I))) (fun z => by
      have h := ((((hasDerivAt_id' z).const_sub 1).const_mul (1 + I)).pow 3).div_const 3
      convert h using 1; norm_num; ring_nf) (by fun_prop)]
  ring_nf

-- The mistake with z-bar, which has no antiderivative: straight route 1, broken route 1 + i.
example : (∫ t in (0 : ℝ)..1, (starRingEnd ℂ) ((1 + I) * t) * (1 + I)) = 1 ∧
    (∫ t in (0 : ℝ)..1, (starRingEnd ℂ) (t : ℂ) * 1) +
      (∫ t in (0 : ℝ)..1, (starRingEnd ℂ) (1 + I * t) * I) = 1 + I := by
  simp only [map_mul, map_add, map_one, conj_ofReal, conj_I]
  refine ⟨?_, ?_⟩
  · rw [integral_unit_of_complex_antideriv (fun z => (1 - I) * (1 + I) * z ^ 2 / 2)
      (fun z => (1 + -I) * z * (1 + I)) (fun z => by
        have h := (((hasDerivAt_id' z).pow 2).const_mul ((1 - I) * (1 + I))).div_const 2
        convert h using 1; norm_num; ring_nf) (by fun_prop)]
    ring_nf; rw [I_sq]; ring
  · rw [integral_unit_of_complex_antideriv (fun z => z ^ 2 / 2)
      (fun z => z * 1) (fun z => by
        have h := ((hasDerivAt_id' z).pow 2).div_const 2
        convert h using 1; norm_num) (by fun_prop),
      integral_unit_of_complex_antideriv (fun z => I * z - I * I * z ^ 2 / 2)
      (fun z => (1 + -I * z) * I) (fun z => by
        have h := ((hasDerivAt_id' z).const_mul I).sub (((hasDerivAt_id' z).pow 2).const_mul (I * I) |>.div_const 2)
        convert h using 1; norm_num; ring_nf; rw [I_sq]; ring) (by fun_prop)]
    ring_nf; rw [I_sq]; ring

-- 1/z from 1 to −1: the upper half gives πi, the lower half −πi, but Log(−1) − Log(1) says πi.
example : (∫ t in (0 : ℝ)..1, (exp (π * I * t))⁻¹ * (π * I * exp (π * I * t))) = π * I ∧
    (∫ t in (0 : ℝ)..1, (exp (-π * I * t))⁻¹ * (-π * I * exp (-π * I * t))) = -(π * I) ∧
    Complex.log (-1) - Complex.log 1 = π * I := by
  have h1 : ∀ t : ℝ, (exp (π * I * t))⁻¹ * (π * I * exp (π * I * t)) = π * I := by
    intro t; field_simp [Complex.exp_ne_zero]
  have h2 : ∀ t : ℝ, (exp (-π * I * t))⁻¹ * (-π * I * exp (-π * I * t)) = -(π * I) := by
    intro t; field_simp [Complex.exp_ne_zero]
  simp_rw [h1, h2]
  refine ⟨by simp, by simp, by rw [log_neg_one, Complex.log_one, sub_zero]⟩

#print axioms integral_along_path_eq_antiderivative_change
#print axioms inv_loop_and_no_antiderivative
#print axioms zpow_has_antiderivative_iff
