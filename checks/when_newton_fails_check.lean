-- Newton's bad days: at a root repeated m times Newton keeps the share (m - 1)/m of the error while the step stretched by m is quadratic, Newton converges from the convex side, and damped Newton with the halving Armijo test converges when the slope stays away from zero and the bend is bounded.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Order.MonotoneConvergence

open Filter Topology Set

/-- One-sided Taylor bound from a Lipschitz derivative. -/
lemma taylor_upper_aux (F : ℝ → ℝ) (M : ℝ) (hF : Differentiable ℝ F)
    (hlip : ∀ a b, |deriv F a - deriv F b| ≤ M * |a - b|) (y h : ℝ) :
    F (y + h) - F y - h * deriv F y ≤ M * h ^ 2 / 2 := by
  set φ : ℝ → ℝ := fun s => F (y + s * h) - F y - s * h * deriv F y - M * h ^ 2 * s ^ 2 / 2
    with hφ
  have hφd : ∀ s, HasDerivAt φ (h * deriv F (y + s * h) - h * deriv F y - M * h ^ 2 * s) s := by
    intro s
    have h1 : HasDerivAt (fun s => F (y + s * h)) (deriv F (y + s * h) * h) s := by
      have h0 : HasDerivAt (fun s => y + s * h) h s := by
        simpa using ((hasDerivAt_id s).mul_const h).const_add y
      exact (hF (y + s * h)).hasDerivAt.comp s h0
    have h2 : HasDerivAt (fun s : ℝ => s * h * deriv F y) (h * deriv F y) s := by
      simpa using ((hasDerivAt_id s).mul_const h).mul_const (deriv F y)
    have h3 : HasDerivAt (fun s : ℝ => M * h ^ 2 * s ^ 2 / 2) (M * h ^ 2 * s) s := by
      have := ((hasDerivAt_pow 2 s).const_mul (M * h ^ 2)).div_const 2
      convert this using 1
      push_cast
      ring
    convert ((h1.sub_const (F y)).sub h2).sub h3 using 1
    ring
  have hanti : AntitoneOn φ (Icc 0 1) := by
    apply antitoneOn_of_deriv_nonpos (convex_Icc 0 1)
    · exact fun s _ => (hφd s).continuousAt.continuousWithinAt
    · exact fun s _ => (hφd s).differentiableAt.differentiableWithinAt
    · intro s hs
      rw [interior_Icc] at hs
      rw [(hφd s).deriv]
      have hl := hlip (y + s * h) y
      have e : |y + s * h - y| = s * |h| := by
        rw [add_sub_cancel_left, abs_mul, abs_of_pos hs.1]
      rw [e] at hl
      have h4 : h * (deriv F (y + s * h) - deriv F y) ≤
          |h| * |deriv F (y + s * h) - deriv F y| := by
        rw [← abs_mul]; exact le_abs_self _
      have h5 : |h| * |deriv F (y + s * h) - deriv F y| ≤ |h| * (M * (s * |h|)) :=
        mul_le_mul_of_nonneg_left hl (abs_nonneg h)
      have hh : |h| * (M * (s * |h|)) = M * h ^ 2 * s := by
        rw [show |h| * (M * (s * |h|)) = M * s * (|h| * |h|) by ring, abs_mul_abs_self]; ring
      nlinarith
  have := hanti ⟨le_rfl, zero_le_one⟩ ⟨zero_le_one, le_rfl⟩ zero_le_one
  have e1 : φ 1 = F (y + h) - F y - h * deriv F y - M * h ^ 2 / 2 := by simp [φ]
  have e0 : φ 0 = 0 := by simp [φ]
  linarith

/-- Two-sided Taylor bound: `|F(y+h) - F(y) - h F'(y)| ≤ M h^2 / 2` when `|F''| ≤ M`. -/
lemma taylor_abs_aux (F : ℝ → ℝ) (M : ℝ) (hF : Differentiable ℝ F)
    (hF' : Differentiable ℝ (deriv F)) (hM : ∀ z, |deriv (deriv F) z| ≤ M) (y h : ℝ) :
    |F (y + h) - F y - h * deriv F y| ≤ M * h ^ 2 / 2 := by
  have hlip : ∀ a b, |deriv F a - deriv F b| ≤ M * |a - b| := by
    intro a b
    have := Convex.norm_image_sub_le_of_norm_deriv_le (s := univ) (fun z _ => hF' z)
      (fun z _ => by rw [Real.norm_eq_abs]; exact hM z) convex_univ (mem_univ b) (mem_univ a)
    simpa [Real.norm_eq_abs] using this
  have hneg : deriv (-F) = fun x => -deriv F x := deriv.neg'
  rw [abs_le]
  constructor
  · have := taylor_upper_aux (-F) M hF.neg (by
      intro a b
      rw [hneg]
      rw [show -deriv F a - -deriv F b = -(deriv F a - deriv F b) by ring, abs_neg]
      exact hlip a b) y h
    rw [hneg] at this
    simp only [Pi.neg_apply] at this
    linarith
  · exact taylor_upper_aux F M hF hlip y h

/-- A failed Armijo test at share `lam` forces `2 (1 - c1) μ^2 < M lam |f y|`. -/
lemma armijo_fail_aux (f : ℝ → ℝ) (M μ c1 : ℝ) (hf : Differentiable ℝ f)
    (hf' : Differentiable ℝ (deriv f)) (hM : ∀ z, |deriv (deriv f) z| ≤ M)
    (hc1' : c1 < 1) (y lam : ℝ) (hlam0 : 0 < lam) (hlam1 : lam ≤ 1)
    (hμ : 0 < μ) (hμy : μ ≤ |deriv f y|)
    (hfail : (1 - c1 * lam) * |f y| < |f (y + lam * (-(f y / deriv f y)))|) :
    2 * (1 - c1) * μ ^ 2 < M * lam * |f y| := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  have hb : deriv f y ≠ 0 := by
    intro h; rw [h, abs_zero] at hμy; linarith
  set a := f y with ha
  set b := deriv f y with hbdef
  set t := a / b with ht
  have hat : a = t * b := by rw [ht]; field_simp
  have hT := taylor_abs_aux f M hf hf' hM y (lam * (-t))
  rw [← ha, ← hbdef] at hT
  have hR : |f (y + lam * (-t))| ≤ (1 - lam) * |a| + M * lam ^ 2 * t ^ 2 / 2 := by
    have e : f (y + lam * (-t)) =
        (1 - lam) * a + (f (y + lam * (-t)) - a - lam * (-t) * b) := by
      rw [hat]; ring
    rw [e]
    calc |(1 - lam) * a + (f (y + lam * (-t)) - a - lam * (-t) * b)|
        ≤ |(1 - lam) * a| + |f (y + lam * (-t)) - a - lam * (-t) * b| := abs_add_le _ _
      _ ≤ (1 - lam) * |a| + M * (lam * (-t)) ^ 2 / 2 := by
          rw [abs_mul, abs_of_nonneg (by linarith : (0:ℝ) ≤ 1 - lam)]
          linarith
      _ = (1 - lam) * |a| + M * lam ^ 2 * t ^ 2 / 2 := by ring
  have h1 : (1 - c1) * lam * |a| < M * lam ^ 2 * t ^ 2 / 2 := by linarith
  have h2 : (1 - c1) * |a| < M * lam * t ^ 2 / 2 := by
    have : lam * ((1 - c1) * |a|) < lam * (M * lam * t ^ 2 / 2) := by nlinarith
    exact lt_of_mul_lt_mul_left this hlam0.le
  have hb2 : 0 < b ^ 2 := by positivity
  have h3 : (1 - c1) * |a| * b ^ 2 < M * lam * |a| ^ 2 / 2 := by
    have := mul_lt_mul_of_pos_right h2 hb2
    have e2 : M * lam * |a| ^ 2 / 2 = M * lam * t ^ 2 / 2 * b ^ 2 := by
      rw [sq_abs, hat]; ring
    rw [e2]; exact this
  have hapos : 0 < |a| := by
    rcases (abs_nonneg a).eq_or_lt with h | h
    · rw [← h] at h3; simp at h3
    · exact h
  have h4 : 2 * (1 - c1) * b ^ 2 < M * lam * |a| := by
    have : |a| * (2 * (1 - c1) * b ^ 2) < |a| * (M * lam * |a|) := by nlinarith
    exact lt_of_mul_lt_mul_left this hapos.le
  have h5 : μ ^ 2 ≤ b ^ 2 := by
    rw [← sq_abs b]; exact pow_le_pow_left₀ hμ.le hμy 2
  nlinarith

/-- At a root `xs` of multiplicity `m` (that is, `f x = (x - xs)^m * g x` with `g xs ≠ 0`),
plain Newton's error ratio `e_(k+1)/e_k` tends to `(m - 1)/m`, and the modified step
`x - m f(x)/f'(x)` has `e_(k+1)/e_k^2` tending to `g'(xs)/(m g(xs))`: order 2 again. -/
theorem newton_ratio_at_multiple_root (f g : ℝ → ℝ) (xs : ℝ) (m : ℕ) (hm : 1 ≤ m)
    (hg : ContDiff ℝ 1 g) (hg0 : g xs ≠ 0) (hf : ∀ x, f x = (x - xs) ^ m * g x) :
    Tendsto (fun x => (x - f x / deriv f x - xs) / (x - xs)) (𝓝[≠] xs)
        (𝓝 (((m : ℝ) - 1) / m)) ∧
      Tendsto (fun x => (x - m * (f x / deriv f x) - xs) / (x - xs) ^ 2) (𝓝[≠] xs)
        (𝓝 (deriv g xs / (m * g xs))) := by
  obtain ⟨n, rfl⟩ : ∃ n, m = n + 1 := ⟨m - 1, by omega⟩
  have hgd : Differentiable ℝ g := hg.differentiable one_ne_zero
  have hgc : Continuous (deriv g) := hg.continuous_deriv le_rfl
  have hfe : f = fun x => (x - xs) ^ (n + 1) * g x := funext hf
  set D : ℝ → ℝ := fun x => ((n : ℝ) + 1) * g x + (x - xs) * deriv g x with hD
  have hderiv : ∀ x, deriv f x = (x - xs) ^ n * D x := by
    intro x
    rw [hfe]
    have hp : HasDerivAt (fun y : ℝ => (y - xs) ^ (n + 1)) (((n + 1 : ℕ) : ℝ) * (x - xs) ^ n) x := by
      convert ((hasDerivAt_id x).sub_const xs).pow (n + 1) using 1
      · funext y; simp
      · simp
    have h1 : HasDerivAt (fun y => (y - xs) ^ (n + 1) * g y)
        (((n + 1 : ℕ) : ℝ) * (x - xs) ^ n * g x + (x - xs) ^ (n + 1) * deriv g x) x :=
      hp.mul (hgd x).hasDerivAt
    rw [h1.deriv]
    simp only [D]
    push_cast
    ring
  have hDc : Continuous D := by
    simp only [D]; fun_prop
  have hD0 : D xs = ((n : ℝ) + 1) * g xs := by simp [D]
  have hD0ne : D xs ≠ 0 := by rw [hD0]; exact mul_ne_zero (by positivity) hg0
  have hDev : ∀ᶠ x in 𝓝[≠] xs, D x ≠ 0 :=
    (hDc.continuousAt.eventually_ne hD0ne).filter_mono nhdsWithin_le_nhds
  have hne : ∀ᶠ x in 𝓝[≠] xs, x ≠ xs := self_mem_nhdsWithin
  have hquot : ∀ x, x ≠ xs → f x / deriv f x = (x - xs) * g x / D x := by
    intro x hx
    have he : x - xs ≠ 0 := sub_ne_zero.mpr hx
    rw [hf, hderiv, pow_succ, mul_assoc, mul_div_mul_left _ _ (pow_ne_zero n he)]
  constructor
  · have hlim : Tendsto (fun x => 1 - g x / D x) (𝓝[≠] xs) (𝓝 (1 - g xs / D xs)) :=
      (tendsto_const_nhds.sub (hgd.continuous.continuousAt.div hDc.continuousAt hD0ne)).mono_left
        nhdsWithin_le_nhds
    have hval : 1 - g xs / D xs = (((n + 1 : ℕ) : ℝ) - 1) / ((n + 1 : ℕ) : ℝ) := by
      rw [hD0]; push_cast; field_simp
    rw [← hval]
    refine hlim.congr' ?_
    filter_upwards [hne] with x hx
    have he : x - xs ≠ 0 := sub_ne_zero.mpr hx
    rw [hquot x hx, show x - (x - xs) * g x / D x - xs = (x - xs) * (1 - g x / D x) by ring,
      mul_div_cancel_left₀ _ he]
  · have hlim : Tendsto (fun x => deriv g x / D x) (𝓝[≠] xs) (𝓝 (deriv g xs / D xs)) :=
      (hgc.continuousAt.div hDc.continuousAt hD0ne).mono_left nhdsWithin_le_nhds
    have hval : deriv g xs / D xs = deriv g xs / (((n + 1 : ℕ) : ℝ) * g xs) := by
      rw [hD0]; push_cast; ring
    rw [← hval]
    refine hlim.congr' ?_
    filter_upwards [hne, hDev] with x hx hDx
    have he : x - xs ≠ 0 := sub_ne_zero.mpr hx
    rw [hquot x hx]
    have hDx' : D x = ((n : ℝ) + 1) * g x + (x - xs) * deriv g x := rfl
    field_simp
    rw [hDx']
    push_cast
    ring

/-- Newton converges from the convex side: if `xs < x0`, `f xs = 0`, `f` is twice
differentiable on `[xs, x0]`, and `f' > 0` and `f'' ≥ 0` on `(xs, x0]`, then Newton's guesses
from `x0` fall steadily, never pass the root, and converge to `xs`. -/
theorem newton_converges_from_convex_side (f : ℝ → ℝ) (xs x0 : ℝ) (hx0 : xs < x0)
    (hroot : f xs = 0)
    (hf : ∀ x ∈ Icc xs x0, DifferentiableAt ℝ f x)
    (hf' : ∀ x ∈ Icc xs x0, DifferentiableAt ℝ (deriv f) x)
    (hslope : ∀ x ∈ Ioc xs x0, 0 < deriv f x)
    (hbend : ∀ x ∈ Ioc xs x0, 0 ≤ deriv (deriv f) x)
    (x : ℕ → ℝ) (hstart : x 0 = x0)
    (hstep : ∀ k, x (k + 1) = x k - f (x k) / deriv f (x k)) :
    Antitone x ∧ (∀ k, xs ≤ x k) ∧ Tendsto x atTop (𝓝 xs) := by
  have hfc : ContinuousOn f (Icc xs x0) := fun y hy => (hf y hy).continuousAt.continuousWithinAt
  have hf'c : ContinuousOn (deriv f) (Icc xs x0) :=
    fun y hy => (hf' y hy).continuousAt.continuousWithinAt
  have hint : interior (Icc xs x0) = Ioo xs x0 := interior_Icc
  have hmono : StrictMonoOn f (Icc xs x0) :=
    strictMonoOn_of_deriv_pos (convex_Icc _ _) hfc
      (by rw [hint]; exact fun y hy => hslope y (Ioo_subset_Ioc_self hy))
  have hdmono : MonotoneOn (deriv f) (Icc xs x0) :=
    monotoneOn_of_deriv_nonneg (convex_Icc _ _) hf'c
      (by rw [hint]; exact fun y hy => (hf' y (Ioo_subset_Icc_self hy)).differentiableWithinAt)
      (by rw [hint]; exact fun y hy => hbend y (Ioo_subset_Ioc_self hy))
  have key : ∀ y ∈ Icc xs x0, xs ≤ y - f y / deriv f y ∧ y - f y / deriv f y ≤ y := by
    intro y hy
    rcases eq_or_lt_of_le hy.1 with h | h
    · subst h; simp [hroot]
    · have hpos : 0 < deriv f y := hslope y ⟨h, hy.2⟩
      have hfy : 0 < f y := by
        rw [← hroot]; exact hmono ⟨le_rfl, hx0.le⟩ hy h
      obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope f h (hfc.mono (Icc_subset_Icc_right hy.2))
        (fun z hz => (hf z ⟨hz.1.le, hz.2.le.trans hy.2⟩).differentiableWithinAt)
      have hcy : deriv f c ≤ deriv f y := hdmono ⟨hc.1.le, hc.2.le.trans hy.2⟩ hy hc.2.le
      rw [hroot, sub_zero] at hcd
      have hys : 0 < y - xs := sub_pos.mpr h
      have hfy' : f y = deriv f c * (y - xs) := by
        rw [hcd]; field_simp
      constructor
      · have : f y / deriv f y ≤ y - xs := by
          rw [div_le_iff₀ hpos, hfy']
          nlinarith
        linarith
      · have : 0 ≤ f y / deriv f y := div_nonneg hfy.le hpos.le
        linarith
  have hin : ∀ k, x k ∈ Icc xs x0 := by
    intro k
    induction k with
    | zero => rw [hstart]; exact ⟨hx0.le, le_rfl⟩
    | succ k ih =>
      rw [hstep]
      obtain ⟨h1, h2⟩ := key _ ih
      exact ⟨h1, h2.trans ih.2⟩
  have hanti : Antitone x :=
    antitone_nat_of_succ_le (fun k => by rw [hstep]; exact (key _ (hin k)).2)
  refine ⟨hanti, fun k => (hin k).1, ?_⟩
  have hbdd : BddBelow (range x) := ⟨xs, by rintro _ ⟨k, rfl⟩; exact (hin k).1⟩
  have hL := tendsto_atTop_ciInf hanti hbdd
  set L := ⨅ k, x k with hLdef
  have hLmem : L ∈ Icc xs x0 :=
    ⟨le_ciInf (fun k => (hin k).1), (ciInf_le hbdd 0).trans (by rw [hstart])⟩
  rcases eq_or_lt_of_le hLmem.1 with h | h
  · rw [h]; exact hL
  · exfalso
    have hpos : 0 < deriv f L := hslope L ⟨h, hLmem.2⟩
    have h1 : Tendsto (fun k => x (k + 1)) atTop (𝓝 L) := (tendsto_add_atTop_iff_nat 1).mpr hL
    have h2 : Tendsto (fun k => x k - f (x k) / deriv f (x k)) atTop
        (𝓝 (L - f L / deriv f L)) :=
      hL.sub (((hf L hLmem).continuousAt.tendsto.comp hL).div
        ((hf' L hLmem).continuousAt.tendsto.comp hL) hpos.ne')
    have h3 : L = L - f L / deriv f L :=
      tendsto_nhds_unique h1 (h2.congr (fun k => (hstep k).symm))
    have hfL : 0 < f L := by
      rw [← hroot]; exact hmono ⟨le_rfl, hx0.le⟩ hLmem h
    have : 0 < f L / deriv f L := div_pos hfL hpos
    linarith

/-- Damped Newton: if `|f''| ≤ M` everywhere and `|f'| ≥ μ > 0` wherever `|f| ≤ |f x0|`, then
halving the share `λ = (1/2)^j` of Newton's step until `|f(x + λ d)| ≤ (1 - c1 λ)|f(x)|` always
stops, never below `min 1 ((1 - c1) μ^2 / (M |f x0|))`; along the damped run the miss shrinks by
a fixed factor each step, full steps are taken from some step on, and the guesses converge to
a root. -/
theorem damped_newton_converges (f : ℝ → ℝ) (x0 μ M c1 : ℝ)
    (hf : Differentiable ℝ f) (hf' : Differentiable ℝ (deriv f))
    (hM : ∀ y, |deriv (deriv f) y| ≤ M)
    (hμ : 0 < μ) (hslope : ∀ y, |f y| ≤ |f x0| → μ ≤ |deriv f y|)
    (hc1 : 0 < c1) (hc1' : c1 < 1) :
    (∀ y, |f y| ≤ |f x0| → ∃ j : ℕ,
        |f (y + (1 / 2 : ℝ) ^ j * (-(f y / deriv f y)))| ≤ (1 - c1 * (1 / 2 : ℝ) ^ j) * |f y|) ∧
    ∀ (x : ℕ → ℝ) (j : ℕ → ℕ), x 0 = x0 →
      (∀ k, |f (x k + (1 / 2 : ℝ) ^ j k * (-(f (x k) / deriv f (x k))))| ≤
          (1 - c1 * (1 / 2 : ℝ) ^ j k) * |f (x k)|) →
      (∀ k, ∀ i < j k, (1 - c1 * (1 / 2 : ℝ) ^ i) * |f (x k)| <
          |f (x k + (1 / 2 : ℝ) ^ i * (-(f (x k) / deriv f (x k))))|) →
      (∀ k, x (k + 1) = x k + (1 / 2 : ℝ) ^ j k * (-(f (x k) / deriv f (x k)))) →
      (∀ k, min 1 ((1 - c1) * μ ^ 2 / (M * |f x0|)) ≤ (1 / 2 : ℝ) ^ j k) ∧
      (∀ k, |f (x (k + 1))| ≤ (1 - c1 * min 1 ((1 - c1) * μ ^ 2 / (M * |f x0|))) * |f (x k)|) ∧
      (∀ᶠ k in atTop, j k = 0) ∧
      ∃ xs, f xs = 0 ∧ Tendsto x atTop (𝓝 xs) := by
  have hM0 : 0 ≤ M := (abs_nonneg _).trans (hM 0)
  have hc1p : 0 < 1 - c1 := sub_pos.mpr hc1'
  have hgap : 0 < 2 * (1 - c1) * μ ^ 2 := by positivity
  have fail : ∀ y, |f y| ≤ |f x0| → ∀ i : ℕ,
      (1 - c1 * (1 / 2 : ℝ) ^ i) * |f y| < |f (y + (1 / 2 : ℝ) ^ i * (-(f y / deriv f y)))| →
      2 * (1 - c1) * μ ^ 2 < M * (1 / 2 : ℝ) ^ i * |f y| := by
    intro y hy i hi
    exact armijo_fail_aux f M μ c1 hf hf' hM hc1' y _ (by positivity)
      (pow_le_one₀ (by norm_num) (by norm_num)) hμ (hslope y hy) hi
  constructor
  · intro y hy
    have hlim : Tendsto (fun j : ℕ => M * (1 / 2 : ℝ) ^ j * |f y|) atTop (𝓝 0) := by
      have := ((tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0 : ℝ) ≤ 1 / 2)
        (by norm_num)).const_mul M).mul_const |f y|
      simpa using this
    obtain ⟨j, hj⟩ := (hlim.eventually (gt_mem_nhds hgap)).exists
    refine ⟨j, ?_⟩
    by_contra hcon
    push Not at hcon
    have := fail y hy j hcon
    linarith
  · intro x j hx0 harm hfailk hstepk
    set lmin := min 1 ((1 - c1) * μ ^ 2 / (M * |f x0|)) with hlmin
    have hbound : ∀ k, |f (x k)| ≤ |f x0| := by
      intro k
      induction k with
      | zero => rw [hx0]
      | succ k ih =>
        rw [hstepk k]
        refine (harm k).trans (le_trans ?_ ih)
        have : 0 ≤ c1 * (1 / 2 : ℝ) ^ j k * |f (x k)| := by positivity
        nlinarith
    have hlam : ∀ k, lmin ≤ (1 / 2 : ℝ) ^ j k := by
      intro k
      obtain hj | ⟨i, hi⟩ : j k = 0 ∨ ∃ i, j k = i + 1 :=
        (Nat.eq_zero_or_eq_succ_pred (j k)).imp id (fun h => ⟨_, h⟩)
      · rw [hj, pow_zero]; exact min_le_left _ _
      · have h1 := fail (x k) (hbound k) i (hfailk k i (by omega))
        have h2 : M * (1 / 2 : ℝ) ^ i * |f (x k)| ≤ M * (1 / 2 : ℝ) ^ i * |f x0| :=
          mul_le_mul_of_nonneg_left (hbound k) (by positivity)
        have hpos : 0 < M * |f x0| := by
          rcases (mul_nonneg hM0 (abs_nonneg (f x0))).eq_or_lt with h | h
          · have : M * (1 / 2 : ℝ) ^ i * |f x0| = (1 / 2 : ℝ) ^ i * (M * |f x0|) := by ring
            rw [this, ← h, mul_zero] at h2
            linarith
          · exact h
        refine (min_le_right _ _).trans ?_
        rw [div_le_iff₀ hpos, hi, pow_succ (1 / 2 : ℝ) i]
        nlinarith
    have hdec : ∀ k, |f (x (k + 1))| ≤ (1 - c1 * lmin) * |f (x k)| := by
      intro k
      rw [hstepk k]
      refine (harm k).trans (mul_le_mul_of_nonneg_right ?_ (abs_nonneg _))
      have := mul_le_mul_of_nonneg_left (hlam k) hc1.le
      linarith
    have hev : ∀ᶠ k in atTop, j k = 0 := by
      have hsmall : ∀ᶠ k in atTop, M * |f (x k)| < 2 * (1 - c1) * μ ^ 2 := by
        rcases (mul_nonneg hM0 (abs_nonneg (f x0))).eq_or_lt with h | h
        · refine Eventually.of_forall (fun k => ?_)
          have := mul_le_mul_of_nonneg_left (hbound k) hM0
          linarith
        · have hlpos : 0 < lmin := lt_min one_pos (by positivity)
          have hl1 : lmin ≤ 1 := min_le_left _ _
          set q := 1 - c1 * lmin with hq
          have hq0 : 0 ≤ q := by nlinarith
          have hq1 : q < 1 := by nlinarith
          have hgeo : ∀ k, |f (x k)| ≤ q ^ k * |f x0| := by
            intro k
            induction k with
            | zero => simp [hx0]
            | succ k ih =>
              calc |f (x (k + 1))| ≤ q * |f (x k)| := hdec k
                _ ≤ q * (q ^ k * |f x0|) := mul_le_mul_of_nonneg_left ih hq0
                _ = q ^ (k + 1) * |f x0| := by ring
          have hlim : Tendsto (fun k : ℕ => q ^ k * (M * |f x0|)) atTop (𝓝 0) := by
            simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hq0 hq1).mul_const (M * |f x0|)
          filter_upwards [hlim.eventually (gt_mem_nhds hgap)] with k hk
          have := mul_le_mul_of_nonneg_left (hgeo k) hM0
          nlinarith
      filter_upwards [hsmall] with k hk
      by_contra hne
      have := fail (x k) (hbound k) 0 (hfailk k 0 (Nat.pos_of_ne_zero hne))
      simp only [pow_zero, mul_one] at this
      linarith
    refine ⟨hlam, hdec, hev, ?_⟩
    obtain ⟨N, hN⟩ := eventually_atTop.mp hev
    set y : ℕ → ℝ := fun n => x (n + N) with hy
    have hystep : ∀ n, y (n + 1) = y n + -(f (y n) / deriv f (y n)) := by
      intro n
      simp only [hy]
      rw [show n + 1 + N = (n + N) + 1 by omega, hstepk, hN (n + N) (by omega), pow_zero, one_mul]
    have hyarm : ∀ n, |f (y (n + 1))| ≤ (1 - c1) * |f (y n)| := by
      intro n
      have := harm (n + N)
      rw [hN (n + N) (by omega), pow_zero, mul_one, one_mul] at this
      rw [hystep n]
      exact this
    have hygeo : ∀ n, |f (y n)| ≤ (1 - c1) ^ n * |f (y 0)| := by
      intro n
      induction n with
      | zero => simp
      | succ n ih =>
        calc |f (y (n + 1))| ≤ (1 - c1) * |f (y n)| := hyarm n
          _ ≤ (1 - c1) * ((1 - c1) ^ n * |f (y 0)|) := mul_le_mul_of_nonneg_left ih hc1p.le
          _ = (1 - c1) ^ (n + 1) * |f (y 0)| := by ring
    have hdist : ∀ n, dist (y n) (y (n + 1)) ≤ |f (y 0)| / μ * (1 - c1) ^ n := by
      intro n
      rw [Real.dist_eq, hystep n, show y n - (y n + -(f (y n) / deriv f (y n))) =
        f (y n) / deriv f (y n) by ring, abs_div]
      have h1 : |f (y n)| / |deriv f (y n)| ≤ |f (y n)| / μ :=
        div_le_div_of_nonneg_left (abs_nonneg _) hμ (hslope _ (hbound _))
      have h2 : |f (y n)| / μ ≤ (1 - c1) ^ n * |f (y 0)| / μ :=
        div_le_div_of_nonneg_right (hygeo n) hμ.le
      calc _ ≤ _ := h1
        _ ≤ _ := h2
        _ = |f (y 0)| / μ * (1 - c1) ^ n := by ring
    have hcauchy : CauchySeq y := cauchySeq_of_le_geometric (1 - c1) (|f (y 0)| / μ)
      (by linarith) hdist
    obtain ⟨xs, hxs⟩ := cauchySeq_tendsto_of_complete hcauchy
    have hfy0 : Tendsto (fun n => f (y n)) atTop (𝓝 0) := by
      have hg : Tendsto (fun n : ℕ => (1 - c1) ^ n * |f (y 0)|) atTop (𝓝 0) := by
        simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hc1p.le (by linarith)).mul_const |f (y 0)|
      refine squeeze_zero_norm (fun n => ?_) hg
      rw [Real.norm_eq_abs]; exact hygeo n
    refine ⟨xs, ?_, (tendsto_add_atTop_iff_nat N).mp hxs⟩
    exact tendsto_nhds_unique ((hf.continuous.tendsto xs).comp hxs) hfy0

-- x^3 from 1: plain steps give 2/3 then 4/9; the step stretched by 3 lands on 0 at once.
example : (1 : ℚ) - 1 ^ 3 / (3 * 1 ^ 2) = 2 / 3 := by norm_num
example : (2 / 3 : ℚ) - (2 / 3) ^ 3 / (3 * (2 / 3) ^ 2) = 4 / 9 := by norm_num
example : (1 : ℚ) - 3 * (1 ^ 3 / (3 * 1 ^ 2)) = 0 := by norm_num
-- The multiplicity read off the ratio 2/3: 1/(1 - 2/3) = 3.
example : (1 : ℚ) / (1 - 2 / 3) = 3 := by norm_num
-- Plain Newton on x^3 keeps 2/3 of the error: 52 steps to reach 1e-9, not 51.
example : (2 / 3 : ℚ) ^ 52 < 1 / 10 ^ 9 ∧ 1 / 10 ^ 9 ≤ (2 / 3 : ℚ) ^ 51 := by norm_num
-- With m = 2 the share kept is 1/3: 19 steps to reach 1e-9, not 18.
example : (1 / 3 : ℚ) ^ 19 < 1 / 10 ^ 9 ∧ 1 / 10 ^ 9 ≤ (1 / 3 : ℚ) ^ 18 := by norm_num
-- Modified step on x^3 + x^4 from 1 gives 1/7, then 1/175, following e_(k+1) = e_k^2/(3 + 4 e_k).
example : (1 : ℚ) - 3 * ((1 ^ 3 + 1 ^ 4) / (3 * 1 ^ 2 + 4 * 1 ^ 3)) = 1 / 7 := by norm_num
example : let x : ℚ := 1 / 7
    x - 3 * ((x ^ 3 + x ^ 4) / (3 * x ^ 2 + 4 * x ^ 3)) = 1 / 175 ∧
      (1 / 175 : ℚ) = x ^ 2 / (3 + 4 * x) := by norm_num

#print axioms taylor_upper_aux
#print axioms taylor_abs_aux
#print axioms armijo_fail_aux
#print axioms newton_ratio_at_multiple_root
#print axioms newton_converges_from_convex_side
#print axioms damped_newton_converges
