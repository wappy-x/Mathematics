-- Limit laws and the squeeze: limits of real functions pass through sums, multiples, products and quotients (bottom limit not 0), a function trapped on a window around a between two functions with the same limit has that limit too, and so x^2 sin(1/x) heads for 0 at 0 although sin(1/x) has no limit there.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Topology.Algebra.GroupWithZero
import Mathlib.Topology.Order.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Topology.Algebra.Order.Field

open Filter Topology

/-- The limit laws. If f(x) heads for the finite number L and g(x) heads for the finite number M
as x heads for a (a itself aside), then f + g heads for L + M, c times f heads for c times L,
f times g heads for L times M, and, when M is not 0, f over g heads for L over M. -/
theorem limit_laws (f g : ℝ → ℝ) (a L M c : ℝ)
    (hf : Tendsto f (𝓝[≠] a) (𝓝 L)) (hg : Tendsto g (𝓝[≠] a) (𝓝 M)) :
    Tendsto (fun x => f x + g x) (𝓝[≠] a) (𝓝 (L + M)) ∧
    Tendsto (fun x => c * f x) (𝓝[≠] a) (𝓝 (c * L)) ∧
    Tendsto (fun x => f x * g x) (𝓝[≠] a) (𝓝 (L * M)) ∧
    (M ≠ 0 → Tendsto (fun x => f x / g x) (𝓝[≠] a) (𝓝 (L / M))) := by
  refine ⟨hf.add hg, hf.const_mul c, hf.mul hg, fun hM => hf.div hg hM⟩

/-- The squeeze theorem. If, for every x in some window around a (a itself aside), the floor
f(x) is at most h(x) and h(x) is at most the ceiling g(x), and floor and ceiling both head for
the same number L as x heads for a, then h(x) heads for L as well. -/
theorem squeeze_theorem (f g h : ℝ → ℝ) (a L : ℝ)
    (htrap : ∃ δ > 0, ∀ x, 0 < |x - a| → |x - a| < δ → f x ≤ h x ∧ h x ≤ g x)
    (hf : Tendsto f (𝓝[≠] a) (𝓝 L)) (hg : Tendsto g (𝓝[≠] a) (𝓝 L)) :
    Tendsto h (𝓝[≠] a) (𝓝 L) := by
  obtain ⟨δ, hδ, htr⟩ := htrap
  have hev : ∀ᶠ x in 𝓝[≠] a, f x ≤ h x ∧ h x ≤ g x := by
    rw [eventually_nhdsWithin_iff, Metric.eventually_nhds_iff]
    refine ⟨δ, hδ, fun y hy hne => htr y ?_ ?_⟩
    · exact abs_pos.mpr (sub_ne_zero.mpr hne)
    · simpa [Real.dist_eq] using hy
  exact tendsto_of_tendsto_of_tendsto_of_le_of_le' hf hg
    (hev.mono fun _ hx => hx.1) (hev.mono fun _ hx => hx.2)

/-- The card's example. The sine of 1 over x has no limit as x heads for 0, yet x squared times
the sine of 1 over x heads for 0, and then the laws carry it on: (x^2 sin(1/x) + 5)/(x + 2)
heads for 5/2. -/
theorem x_sq_sin_inv_tendsto_zero_though_sin_inv_has_no_limit :
    (¬ ∃ L : ℝ, Tendsto (fun x : ℝ => Real.sin (1 / x)) (𝓝[≠] 0) (𝓝 L)) ∧
    Tendsto (fun x : ℝ => x ^ 2 * Real.sin (1 / x)) (𝓝[≠] 0) (𝓝 0) ∧
    Tendsto (fun x : ℝ => (x ^ 2 * Real.sin (1 / x) + 5) / (x + 2)) (𝓝[≠] 0) (𝓝 (5 / 2)) := by
  have hsq : Tendsto (fun x : ℝ => x ^ 2 * Real.sin (1 / x)) (𝓝[≠] 0) (𝓝 0) := by
    have h2 : Tendsto (fun x : ℝ => x ^ 2) (𝓝[≠] 0) (𝓝 0) := by
      have : Tendsto (fun x : ℝ => x ^ 2) (𝓝 0) (𝓝 0) := by
        simpa using ((continuous_pow 2).tendsto (0 : ℝ))
      exact this.mono_left nhdsWithin_le_nhds
    refine squeeze_zero_norm (fun x => ?_) h2
    rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, abs_pow, sq_abs]
    calc x ^ 2 * |Real.sin (1 / x)| ≤ x ^ 2 * 1 :=
          mul_le_mul_of_nonneg_left (Real.abs_sin_le_one _) (sq_nonneg x)
      _ = x ^ 2 := mul_one _
  refine ⟨?_, hsq, ?_⟩
  · rintro ⟨L, hL⟩
    have hinv : Tendsto (fun y : ℝ => y⁻¹) atTop (𝓝[≠] (0 : ℝ)) :=
      tendsto_inv_atTop_nhdsGT_zero.mono_right (nhdsWithin_mono _ (fun y hy => ne_of_gt hy))
    have hsin : Tendsto Real.sin atTop (𝓝 L) := by
      have := hL.comp hinv
      refine this.congr (fun y => ?_)
      simp [Function.comp]
    have hA : Tendsto (fun n : ℕ => 2 * Real.pi * n + Real.pi / 2) atTop atTop := by
      refine tendsto_atTop_add_const_right _ _ ?_
      exact (tendsto_natCast_atTop_atTop).const_mul_atTop (by positivity)
    have hB : Tendsto (fun n : ℕ => Real.pi * n) atTop atTop :=
      (tendsto_natCast_atTop_atTop).const_mul_atTop Real.pi_pos
    have h1 : Tendsto (fun n : ℕ => Real.sin (2 * Real.pi * n + Real.pi / 2)) atTop (𝓝 L) :=
      hsin.comp hA
    have h0 : Tendsto (fun n : ℕ => Real.sin (Real.pi * n)) atTop (𝓝 L) := hsin.comp hB
    have e1 : (fun n : ℕ => Real.sin (2 * Real.pi * n + Real.pi / 2)) = fun _ => (1 : ℝ) := by
      funext n
      rw [Real.sin_add_pi_div_two]
      have : 2 * Real.pi * (n : ℝ) = (n : ℕ) * (2 * Real.pi) := by ring
      rw [this, Real.cos_nat_mul_two_pi]
    have e0 : (fun n : ℕ => Real.sin (Real.pi * n)) = fun _ => (0 : ℝ) := by
      funext n
      rw [mul_comm, Real.sin_nat_mul_pi]
    rw [e1] at h1
    rw [e0] at h0
    have a1 := tendsto_const_nhds_iff.mp h1
    have a0 := tendsto_const_nhds_iff.mp h0
    norm_num [← a1] at a0
  · have hnum : Tendsto (fun x : ℝ => x ^ 2 * Real.sin (1 / x) + 5) (𝓝[≠] 0) (𝓝 (0 + 5)) :=
      hsq.add tendsto_const_nhds
    have hden : Tendsto (fun x : ℝ => x + 2) (𝓝[≠] 0) (𝓝 (0 + 2)) := by
      have : Tendsto (fun x : ℝ => x + 2) (𝓝 0) (𝓝 (0 + 2)) :=
        (continuous_id.add continuous_const).tendsto 0
      exact this.mono_left nhdsWithin_le_nhds
    have := hnum.div hden (by norm_num)
    convert this using 2
    norm_num

-- Worked numbers: the laws give (0 + 5) / (0 + 2) = 5/2 = 2.5.
example : ((0 : ℚ) + 5) / (0 + 2) = 5 / 2 := by norm_num
-- Infinite limit: 1/x^2 at x = 1/1000 is 1000000; 1/x is 1000 at 1/1000 and -1000 at -1/1000.
example : (1 : ℚ) / (1 / 1000) ^ 2 = 1000000 := by norm_num
example : (1 : ℚ) / (1 / 1000) = 1000 ∧ (1 : ℚ) / (-1 / 1000) = -1000 := by norm_num
-- The 0 over 0 mistake at x = 1/1000: x/x = 1, x^2/x = 1/1000, x/x^2 = 1000.
example : ((1 : ℚ) / 1000) / (1 / 1000) = 1 ∧ ((1 : ℚ) / 1000) ^ 2 / (1 / 1000) = 1 / 1000 ∧
    ((1 : ℚ) / 1000) / ((1 / 1000) ^ 2) = 1000 := by norm_num
-- The squeeze window: for tolerance 1/1000, every x with |x| below the window has x^2 under it,
-- and the window sqrt(1/1000) squared is exactly 1/1000.
example : Real.sqrt (1 / 1000) ^ 2 = 1 / 1000 := by
  rw [Real.sq_sqrt]; norm_num

#print axioms limit_laws
#print axioms squeeze_theorem
#print axioms x_sq_sin_inv_tendsto_zero_though_sin_inv_has_no_limit
