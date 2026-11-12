-- Forward, backward and central differences: for a function smooth across each stencil, the forward and backward differences miss the slope by ±(h/2)·f''(ξ), the central difference by (h²/6)·f'''(ξ), and the one-sided three-point differences by -(h²/3)·f'''(ξ).
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Tactic

open Set

namespace DifferenceFormulas

lemma facts2 {f : ℝ → ℝ} {y : ℝ} (hf : ContDiffAt ℝ 2 f y) :
    HasDerivAt f (deriv f y) y ∧ HasDerivAt (deriv f) (iteratedDeriv 2 f y) y := by
  have h2 : iteratedDeriv 2 f = deriv (deriv f) := by rw [iteratedDeriv_succ, iteratedDeriv_one]
  have d1 : ContDiffAt ℝ 1 (deriv f) y := hf.derivWithin (by norm_num)
  refine ⟨(hf.differentiableAt (by norm_num)).hasDerivAt, ?_⟩
  rw [h2]; exact (d1.differentiableAt (by norm_num)).hasDerivAt

#print axioms facts2

lemma facts3 {f : ℝ → ℝ} {y : ℝ} (hf : ContDiffAt ℝ 3 f y) :
    HasDerivAt f (deriv f y) y ∧ HasDerivAt (deriv f) (iteratedDeriv 2 f y) y ∧
      HasDerivAt (iteratedDeriv 2 f) (iteratedDeriv 3 f y) y := by
  have h2 : iteratedDeriv 2 f = deriv (deriv f) := by rw [iteratedDeriv_succ, iteratedDeriv_one]
  have h3 : iteratedDeriv 3 f = deriv (deriv (deriv f)) := by rw [iteratedDeriv_succ, h2]
  have d1 : ContDiffAt ℝ 2 (deriv f) y := hf.derivWithin (by norm_num)
  have d2 : ContDiffAt ℝ 1 (deriv (deriv f)) y := d1.derivWithin (by norm_num)
  refine ⟨(hf.differentiableAt (by norm_num)).hasDerivAt, ?_, ?_⟩
  · rw [h2]; exact (d1.differentiableAt (by norm_num)).hasDerivAt
  · rw [h2, h3]; exact (d2.differentiableAt (by norm_num)).hasDerivAt

#print axioms facts3

lemma hd_aff {g : ℝ → ℝ} {d x c s : ℝ} (hg : HasDerivAt g d (x + c * s)) :
    HasDerivAt (fun t => g (x + c * t)) (c * d) s := by
  have hl : HasDerivAt (fun t => x + c * t) c s := by
    simpa using ((hasDerivAt_id s).const_mul c).const_add x
  have := hg.comp s hl
  rw [mul_comm]; exact this

#print axioms hd_aff

lemma cauchy_sq (D D' : ℝ → ℝ) (h : ℝ) (hh : 0 < h)
    (hD : ∀ s ∈ Icc 0 h, HasDerivAt D (D' s) s) (h0 : D 0 = 0) :
    ∃ s ∈ Ioo 0 h, D h * (2 * s) = h ^ 2 * D' s := by
  obtain ⟨s, hs, e⟩ := exists_ratio_hasDerivAt_eq_ratio_slope D D' hh
    (fun y hy => (hD y hy).continuousAt.continuousWithinAt)
    (fun y hy => hD y (Ioo_subset_Icc_self hy))
    (fun t => t ^ 2) (fun t => 2 * t) (by fun_prop) (fun y _ => by simpa using hasDerivAt_pow 2 y)
  refine ⟨s, hs, ?_⟩
  rw [h0] at e
  linear_combination -e

#print axioms cauchy_sq

lemma cauchy_cube (D D' D'' : ℝ → ℝ) (h : ℝ) (hh : 0 < h)
    (hD : ∀ s ∈ Icc 0 h, HasDerivAt D (D' s) s) (hD' : ∀ s ∈ Icc 0 h, HasDerivAt D' (D'' s) s)
    (h0 : D 0 = 0) (h0' : D' 0 = 0) :
    ∃ s ∈ Ioo 0 h, D h * (6 * s) = h ^ 3 * D'' s := by
  obtain ⟨s1, hs1, e1⟩ := exists_ratio_hasDerivAt_eq_ratio_slope D D' hh
    (fun y hy => (hD y hy).continuousAt.continuousWithinAt)
    (fun y hy => hD y (Ioo_subset_Icc_self hy))
    (fun t => t ^ 3) (fun t => 3 * t ^ 2) (by fun_prop)
    (fun y _ => by simpa using hasDerivAt_pow 3 y)
  have hsub : Icc 0 s1 ⊆ Icc 0 h := Icc_subset_Icc le_rfl hs1.2.le
  obtain ⟨s2, hs2, e2⟩ := exists_ratio_hasDerivAt_eq_ratio_slope D' D'' hs1.1
    (fun y hy => (hD' y (hsub hy)).continuousAt.continuousWithinAt)
    (fun y hy => hD' y (hsub (Ioo_subset_Icc_self hy)))
    (fun t => t ^ 2) (fun t => 2 * t) (by fun_prop) (fun y _ => by simpa using hasDerivAt_pow 2 y)
  refine ⟨s2, ⟨hs2.1, hs2.2.trans hs1.2⟩, ?_⟩
  rw [h0] at e1
  rw [h0'] at e2
  have key : s1 ^ 2 * (D h * (6 * s2) - h ^ 3 * D'' s2) = 0 := by
    linear_combination (-h ^ 3) * e2 - 2 * s2 * e1
  have hs1ne : s1 ^ 2 ≠ 0 := by have := hs1.1; positivity
  exact sub_eq_zero.mp ((mul_eq_zero.mp key).resolve_left hs1ne)

#print axioms cauchy_cube

lemma forward_err (f : ℝ → ℝ) (x h : ℝ) (hh : 0 < h)
    (hf : ∀ y ∈ Icc x (x + h), ContDiffAt ℝ 2 f y) :
    ∃ ξ ∈ Ioo x (x + h),
      (f (x + h) - f x) / h - deriv f x = h / 2 * iteratedDeriv 2 f ξ := by
  have F := fun y hy => facts2 (hf y hy)
  have hD : ∀ t ∈ Icc 0 h, HasDerivAt (fun t => f (x + 1 * t) - f x - t * deriv f x)
      (deriv f (x + 1 * t) - deriv f x) t := by
    intro t ht
    have := hd_aff (c := 1) (F (x + 1 * t) ⟨by linarith [ht.1], by linarith [ht.2]⟩).1
    convert (this.sub (hasDerivAt_const t (f x))).sub (hasDerivAt_mul_const (deriv f x)) using 1
    ring
  obtain ⟨s, hs, e⟩ := cauchy_sq _ _ h hh hD (by simp)
  have hxs : x < x + s := by linarith [hs.1]
  obtain ⟨ξ, hξ, eξ⟩ := exists_hasDerivAt_eq_slope (deriv f) (iteratedDeriv 2 f) hxs
    (fun y hy => (F y ⟨hy.1, by linarith [hy.2, hs.2]⟩).2.continuousAt.continuousWithinAt)
    (fun y hy => (F y ⟨hy.1.le, by linarith [hy.2, hs.2]⟩).2)
  refine ⟨ξ, ⟨hξ.1, by linarith [hξ.2, hs.2]⟩, ?_⟩
  simp only [one_mul] at e
  rw [eξ, show x + s - x = s by ring]
  have hs0 : s ≠ 0 := hs.1.ne'
  have hh0 : h ≠ 0 := hh.ne'
  field_simp
  linear_combination e

#print axioms forward_err

lemma backward_err (f : ℝ → ℝ) (x h : ℝ) (hh : 0 < h)
    (hf : ∀ y ∈ Icc (x - h) x, ContDiffAt ℝ 2 f y) :
    ∃ ξ ∈ Ioo (x - h) x,
      (f x - f (x - h)) / h - deriv f x = -(h / 2) * iteratedDeriv 2 f ξ := by
  have F := fun y hy => facts2 (hf y hy)
  have hD : ∀ t ∈ Icc 0 h, HasDerivAt (fun t => f x - f (x + -1 * t) - t * deriv f x)
      (deriv f (x + -1 * t) - deriv f x) t := by
    intro t ht
    have := hd_aff (c := -1) (F (x + -1 * t) ⟨by linarith [ht.2], by linarith [ht.1]⟩).1
    convert ((hasDerivAt_const t (f x)).sub this).sub (hasDerivAt_mul_const (deriv f x)) using 1
    ring
  obtain ⟨s, hs, e⟩ := cauchy_sq _ _ h hh hD (by simp)
  have hxs : x - s < x := by linarith [hs.1]
  obtain ⟨ξ, hξ, eξ⟩ := exists_hasDerivAt_eq_slope (deriv f) (iteratedDeriv 2 f) hxs
    (fun y hy => (F y ⟨by linarith [hy.1, hs.2], hy.2⟩).2.continuousAt.continuousWithinAt)
    (fun y hy => (F y ⟨by linarith [hy.1, hs.2], hy.2.le⟩).2)
  refine ⟨ξ, ⟨by linarith [hξ.1, hs.2], hξ.2⟩, ?_⟩
  simp only [neg_one_mul, ← sub_eq_add_neg] at e
  rw [eξ, show x - (x - s) = s by ring]
  have hs0 : s ≠ 0 := hs.1.ne'
  have hh0 : h ≠ 0 := hh.ne'
  field_simp
  linear_combination e

#print axioms backward_err

lemma central_err (f : ℝ → ℝ) (x h : ℝ) (hh : 0 < h)
    (hf : ∀ y ∈ Icc (x - h) (x + h), ContDiffAt ℝ 3 f y) :
    ∃ ξ ∈ Ioo (x - h) (x + h),
      (f (x + h) - f (x - h)) / (2 * h) - deriv f x = h ^ 2 / 6 * iteratedDeriv 3 f ξ := by
  have F := fun y hy => facts3 (hf y hy)
  have mem : ∀ t ∈ Icc 0 h, ∀ c : ℝ, -1 ≤ c → c ≤ 1 → x + c * t ∈ Icc (x - h) (x + h) := by
    intro t ht c hc1 hc2
    constructor <;> nlinarith [ht.1, ht.2]
  have hD : ∀ t ∈ Icc 0 h,
      HasDerivAt (fun t => f (x + 1 * t) - f (x + -1 * t) - t * (2 * deriv f x))
      (deriv f (x + 1 * t) + deriv f (x + -1 * t) - 2 * deriv f x) t := by
    intro t ht
    have h1 := hd_aff (c := 1) (F (x + 1 * t) (mem t ht 1 (by norm_num) (by norm_num))).1
    have h2 := hd_aff (c := -1) (F (x + -1 * t) (mem t ht (-1) (by norm_num) (by norm_num))).1
    convert (h1.sub h2).sub (hasDerivAt_mul_const (2 * deriv f x)) using 1
    ring
  have hD' : ∀ t ∈ Icc 0 h,
      HasDerivAt (fun t => deriv f (x + 1 * t) + deriv f (x + -1 * t) - 2 * deriv f x)
      (iteratedDeriv 2 f (x + 1 * t) - iteratedDeriv 2 f (x + -1 * t)) t := by
    intro t ht
    have h1 := hd_aff (c := 1) (F (x + 1 * t) (mem t ht 1 (by norm_num) (by norm_num))).2.1
    have h2 := hd_aff (c := -1) (F (x + -1 * t) (mem t ht (-1) (by norm_num) (by norm_num))).2.1
    convert (h1.add h2).sub (hasDerivAt_const t (2 * deriv f x)) using 1
    ring
  obtain ⟨s, hs, e⟩ := cauchy_cube _ _ _ h hh hD hD' (by simp) (by simp only [mul_zero, add_zero]; ring)
  have hxs : x - s < x + s := by linarith [hs.1]
  obtain ⟨ξ, hξ, eξ⟩ := exists_hasDerivAt_eq_slope (iteratedDeriv 2 f) (iteratedDeriv 3 f) hxs
    (fun y hy => (F y ⟨by linarith [hy.1, hs.2], by linarith [hy.2, hs.2]⟩).2.2.continuousAt.continuousWithinAt)
    (fun y hy => (F y ⟨by linarith [hy.1, hs.2], by linarith [hy.2, hs.2]⟩).2.2)
  refine ⟨ξ, ⟨by linarith [hξ.1, hs.2], by linarith [hξ.2, hs.2]⟩, ?_⟩
  simp only [one_mul, neg_one_mul, ← sub_eq_add_neg] at e
  rw [eξ, show x + s - (x - s) = 2 * s by ring]
  have hs0 : s ≠ 0 := hs.1.ne'
  have hh0 : h ≠ 0 := hh.ne'
  field_simp
  linear_combination e

#print axioms central_err

lemma up_err (f : ℝ → ℝ) (x h : ℝ) (hh : 0 < h)
    (hf : ∀ y ∈ Icc x (x + 2 * h), ContDiffAt ℝ 3 f y) :
    ∃ ξ ∈ Ioo x (x + 2 * h),
      (-3 * f x + 4 * f (x + h) - f (x + 2 * h)) / (2 * h) - deriv f x
        = -(h ^ 2 / 3) * iteratedDeriv 3 f ξ := by
  have F := fun y hy => facts3 (hf y hy)
  have mem : ∀ t ∈ Icc 0 h, ∀ c : ℝ, 0 ≤ c → c ≤ 2 → x + c * t ∈ Icc x (x + 2 * h) := by
    intro t ht c hc1 hc2
    constructor <;> nlinarith [ht.1, ht.2]
  have hD : ∀ t ∈ Icc 0 h,
      HasDerivAt (fun t => -3 * f x + 4 * f (x + 1 * t) - f (x + 2 * t) - t * (2 * deriv f x))
      (4 * deriv f (x + 1 * t) - 2 * deriv f (x + 2 * t) - 2 * deriv f x) t := by
    intro t ht
    have h1 := hd_aff (c := 1) (F (x + 1 * t) (mem t ht 1 (by norm_num) (by norm_num))).1
    have h2 := hd_aff (c := 2) (F (x + 2 * t) (mem t ht 2 (by norm_num) (by norm_num))).1
    convert (((hasDerivAt_const t (-3 * f x)).add (h1.const_mul 4)).sub h2).sub
      (hasDerivAt_mul_const (2 * deriv f x)) using 1
    ring
  have hD' : ∀ t ∈ Icc 0 h,
      HasDerivAt (fun t => 4 * deriv f (x + 1 * t) - 2 * deriv f (x + 2 * t) - 2 * deriv f x)
      (4 * iteratedDeriv 2 f (x + 1 * t) - 4 * iteratedDeriv 2 f (x + 2 * t)) t := by
    intro t ht
    have h1 := hd_aff (c := 1) (F (x + 1 * t) (mem t ht 1 (by norm_num) (by norm_num))).2.1
    have h2 := hd_aff (c := 2) (F (x + 2 * t) (mem t ht 2 (by norm_num) (by norm_num))).2.1
    convert ((h1.const_mul 4).sub (h2.const_mul 2)).sub (hasDerivAt_const t (2 * deriv f x)) using 1
    ring
  obtain ⟨s, hs, e⟩ := cauchy_cube _ _ _ h hh hD hD' (by simp only [mul_zero, add_zero, zero_mul, sub_zero]; ring)
    (by simp only [mul_zero, add_zero]; ring)
  have hxs : x + 1 * s < x + 2 * s := by linarith [hs.1]
  obtain ⟨ξ, hξ, eξ⟩ := exists_hasDerivAt_eq_slope (iteratedDeriv 2 f) (iteratedDeriv 3 f) hxs
    (fun y hy => (F y ⟨by linarith [hy.1, hs.1], by linarith [hy.2, hs.2]⟩).2.2.continuousAt.continuousWithinAt)
    (fun y hy => (F y ⟨by linarith [hy.1, hs.1], by linarith [hy.2, hs.2]⟩).2.2)
  refine ⟨ξ, ⟨by linarith [hξ.1, hs.1], by linarith [hξ.2, hs.2]⟩, ?_⟩
  simp only [one_mul] at e eξ
  rw [eξ, show x + 2 * s - (x + s) = s by ring]
  have hs0 : s ≠ 0 := hs.1.ne'
  have hh0 : h ≠ 0 := hh.ne'
  generalize f (x + h) = a1 at e ⊢
  generalize f (x + 2 * h) = a2 at e ⊢
  generalize iteratedDeriv 2 f (x + s) = b1 at e ⊢
  generalize iteratedDeriv 2 f (x + 2 * s) = b2 at e ⊢
  field_simp
  linear_combination e / 2

#print axioms up_err

lemma down_err (f : ℝ → ℝ) (x h : ℝ) (hh : 0 < h)
    (hf : ∀ y ∈ Icc (x - 2 * h) x, ContDiffAt ℝ 3 f y) :
    ∃ ξ ∈ Ioo (x - 2 * h) x,
      (3 * f x - 4 * f (x - h) + f (x - 2 * h)) / (2 * h) - deriv f x
        = -(h ^ 2 / 3) * iteratedDeriv 3 f ξ := by
  have F := fun y hy => facts3 (hf y hy)
  have mem : ∀ t ∈ Icc 0 h, ∀ c : ℝ, -2 ≤ c → c ≤ 0 → x + c * t ∈ Icc (x - 2 * h) x := by
    intro t ht c hc1 hc2
    constructor <;> nlinarith [ht.1, ht.2]
  have hD : ∀ t ∈ Icc 0 h,
      HasDerivAt (fun t => 3 * f x - 4 * f (x + -1 * t) + f (x + -2 * t) - t * (2 * deriv f x))
      (4 * deriv f (x + -1 * t) - 2 * deriv f (x + -2 * t) - 2 * deriv f x) t := by
    intro t ht
    have h1 := hd_aff (c := -1) (F (x + -1 * t) (mem t ht (-1) (by norm_num) (by norm_num))).1
    have h2 := hd_aff (c := -2) (F (x + -2 * t) (mem t ht (-2) (by norm_num) (by norm_num))).1
    convert (((hasDerivAt_const t (3 * f x)).sub (h1.const_mul 4)).add h2).sub
      (hasDerivAt_mul_const (2 * deriv f x)) using 1
    ring
  have hD' : ∀ t ∈ Icc 0 h,
      HasDerivAt (fun t => 4 * deriv f (x + -1 * t) - 2 * deriv f (x + -2 * t) - 2 * deriv f x)
      (-4 * iteratedDeriv 2 f (x + -1 * t) + 4 * iteratedDeriv 2 f (x + -2 * t)) t := by
    intro t ht
    have h1 := hd_aff (c := -1) (F (x + -1 * t) (mem t ht (-1) (by norm_num) (by norm_num))).2.1
    have h2 := hd_aff (c := -2) (F (x + -2 * t) (mem t ht (-2) (by norm_num) (by norm_num))).2.1
    convert ((h1.const_mul 4).sub (h2.const_mul 2)).sub (hasDerivAt_const t (2 * deriv f x)) using 1
    ring
  obtain ⟨s, hs, e⟩ := cauchy_cube _ _ _ h hh hD hD' (by simp only [mul_zero, add_zero, zero_mul, sub_zero]; ring)
    (by simp only [mul_zero, add_zero]; ring)
  have hxs : x + -2 * s < x + -1 * s := by linarith [hs.1]
  obtain ⟨ξ, hξ, eξ⟩ := exists_hasDerivAt_eq_slope (iteratedDeriv 2 f) (iteratedDeriv 3 f) hxs
    (fun y hy => (F y ⟨by linarith [hy.1, hs.2], by linarith [hy.2, hs.1]⟩).2.2.continuousAt.continuousWithinAt)
    (fun y hy => (F y ⟨by linarith [hy.1, hs.2], by linarith [hy.2, hs.1]⟩).2.2)
  refine ⟨ξ, ⟨by linarith [hξ.1, hs.2], by linarith [hξ.2, hs.1]⟩, ?_⟩
  simp only [neg_mul, one_mul, ← sub_eq_add_neg] at e eξ
  rw [eξ, show x - s - (x - 2 * s) = s by ring]
  have hs0 : s ≠ 0 := hs.1.ne'
  have hh0 : h ≠ 0 := hh.ne'
  generalize f (x - h) = a1 at e ⊢
  generalize f (x - 2 * h) = a2 at e ⊢
  generalize iteratedDeriv 2 f (x - s) = b1 at e ⊢
  generalize iteratedDeriv 2 f (x - 2 * s) = b2 at e ⊢
  field_simp
  linear_combination e / 2

#print axioms down_err


/-- The error of each difference formula, from Taylor's theorem. Take a step `h > 0`.
* Forward, `(f(x+h) - f(x))/h`: if `f` has a continuous second derivative across
  `[x, x+h]`, it misses the slope `f'(x)` by `(h/2)·f''(ξ)` for some `ξ` in the stencil.
* Backward, `(f(x) - f(x-h))/h`: with a continuous `f''` across `[x-h, x]`, it misses by
  `-(h/2)·f''(ξ)`: the same size as forward, the opposite sign.
* Central, `(f(x+h) - f(x-h))/(2h)`: with a continuous `f'''` across `[x-h, x+h]`, it misses
  by `(h²/6)·f'''(ξ)`.
* One-sided three-point, up, `(-3f(x) + 4f(x+h) - f(x+2h))/(2h)`, and down,
  `(3f(x) - 4f(x-h) + f(x-2h))/(2h)`: with a continuous `f'''` across their stencils, each
  misses by `-(h²/3)·f'''(ξ)`.
So forward and backward have errors proportional to the step (order 1), and the other three
errors proportional to its square (order 2). Each `ξ` is a point inside that formula's own
stencil. -/
theorem difference_formula_errors (f : ℝ → ℝ) (x h : ℝ) (hh : 0 < h) :
    ((∀ y ∈ Icc x (x + h), ContDiffAt ℝ 2 f y) →
      ∃ ξ ∈ Ioo x (x + h),
        (f (x + h) - f x) / h - deriv f x = h / 2 * iteratedDeriv 2 f ξ) ∧
    ((∀ y ∈ Icc (x - h) x, ContDiffAt ℝ 2 f y) →
      ∃ ξ ∈ Ioo (x - h) x,
        (f x - f (x - h)) / h - deriv f x = -(h / 2) * iteratedDeriv 2 f ξ) ∧
    ((∀ y ∈ Icc (x - h) (x + h), ContDiffAt ℝ 3 f y) →
      ∃ ξ ∈ Ioo (x - h) (x + h),
        (f (x + h) - f (x - h)) / (2 * h) - deriv f x = h ^ 2 / 6 * iteratedDeriv 3 f ξ) ∧
    ((∀ y ∈ Icc x (x + 2 * h), ContDiffAt ℝ 3 f y) →
      ∃ ξ ∈ Ioo x (x + 2 * h),
        (-3 * f x + 4 * f (x + h) - f (x + 2 * h)) / (2 * h) - deriv f x
          = -(h ^ 2 / 3) * iteratedDeriv 3 f ξ) ∧
    ((∀ y ∈ Icc (x - 2 * h) x, ContDiffAt ℝ 3 f y) →
      ∃ ξ ∈ Ioo (x - 2 * h) x,
        (3 * f x - 4 * f (x - h) + f (x - 2 * h)) / (2 * h) - deriv f x
          = -(h ^ 2 / 3) * iteratedDeriv 3 f ξ) := by
  exact ⟨forward_err f x h hh, backward_err f x h hh, central_err f x h hh, up_err f x h hh,
    down_err f x h hh⟩

/-- The central difference is the average of the forward and backward differences: adding
them and halving cancels the `f(x)` terms and leaves `(f(x+h) - f(x-h))/(2h)`. -/
theorem central_eq_average_of_forward_and_backward (f : ℝ → ℝ) (x h : ℝ) (hh : h ≠ 0) :
    (f (x + h) - f (x - h)) / (2 * h)
      = ((f (x + h) - f x) / h + (f x - f (x - h)) / h) / 2 := by
  field_simp
  ring

/-- The one-sided three-point weights are forced. Weights `a, b, c` on the prices at `x`,
`x+h`, `x+2h` cancel the price level (`a + b + c = 0`), bring out the slope once
(`b + 2c = 1`) and cancel the bend (`b + 4c = 0`) exactly when they are `-3/2, 2, -1/2`,
that is, `-3, 4, -1` over `2h`. -/
theorem three_point_weights_unique (a b c : ℝ) :
    (a + b + c = 0 ∧ b + 2 * c = 1 ∧ b + 4 * c = 0) ↔ (a = -3 / 2 ∧ b = 2 ∧ c = -1 / 2) := by
  constructor
  · rintro ⟨h1, h2, h3⟩
    refine ⟨by linarith, by linarith, by linarith⟩
  · rintro ⟨rfl, rfl, rfl⟩
    norm_num

-- Step 3: the weights -3/2, 2, -1/2 solve the three Taylor rows.
example : (-3 / 2 : ℚ) + 2 + (-1 / 2) = 0 ∧ (2 : ℚ) + 2 * (-1 / 2) = 1 ∧
    (2 : ℚ) + 4 * (-1 / 2) = 0 := by norm_num

-- Step 3: the leftover f''' term, (1/6)(b + 8c), is -1/3, so the error is -(h²/3) f'''.
example : (1 / 6 : ℚ) * (2 + 8 * (-1 / 2)) = -1 / 3 := by norm_num

-- What breaks: the uneven pair +1 step and -2 steps over 3 steps leaves the f'' term,
-- with coefficient (1² - 2²)/(2·3) = -1/2 times h: order 1, not 2.
example : ((1 : ℚ) ^ 2 - (-2) ^ 2) / (2 * 3) = -1 / 2 := by norm_num

#print axioms difference_formula_errors
#print axioms central_eq_average_of_forward_and_backward
#print axioms three_point_weights_unique

end DifferenceFormulas
