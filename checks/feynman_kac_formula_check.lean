-- Feynman-Kac: for a Brownian motion with constant drift and kick size, the discounted average of a payoff solves the backward equation, a solution with finite energy equals that average, and without the true-martingale condition the equation for dX = X^2 dW has a second solution.
import Mathlib.Probability.BrownianMotion.Basic
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open MeasureTheory ProbabilityTheory Filter Topology
open scoped NNReal ENNReal

/-- Polynomial growth gives growth at most `C e^{|y|}`. -/
lemma fk_growth_exp {g : ℝ → ℝ} (h : ∃ C : ℝ, ∃ k : ℕ, ∀ y, |g y| ≤ C * (1 + |y| ^ k)) :
    ∃ C, 0 ≤ C ∧ ∀ y, |g y| ≤ C * Real.exp |y| := by
  obtain ⟨C, k, hC⟩ := h
  have hC0 : 0 ≤ C := by
    have h0 := hC 0
    have hpos : 0 < 1 + |(0:ℝ)| ^ k := by positivity
    by_contra hneg
    push Not at hneg
    have : C * (1 + |(0:ℝ)| ^ k) < 0 := mul_neg_of_neg_of_pos hneg hpos
    linarith [abs_nonneg (g 0)]
  refine ⟨C * (1 + k.factorial), by positivity, fun y => (hC y).trans ?_⟩
  have h1 : |y| ^ k ≤ k.factorial * Real.exp |y| := by
    have := Real.pow_div_factorial_le_exp (x := |y|) (abs_nonneg y) k
    rw [div_le_iff₀ (by positivity)] at this
    linarith
  have h2 : 1 ≤ Real.exp |y| := Real.one_le_exp (abs_nonneg y)
  have : 1 + |y| ^ k ≤ (1 + k.factorial) * Real.exp |y| := by nlinarith
  calc C * (1 + |y| ^ k) ≤ C * ((1 + k.factorial) * Real.exp |y|) :=
        mul_le_mul_of_nonneg_left this hC0
    _ = _ := by ring

/-- The bell kernel with variance `v`, written as Mathlib writes the normal density. -/
noncomputable def fkK (v w : ℝ) : ℝ := (Real.sqrt (2 * Real.pi * v))⁻¹ * Real.exp (-w ^ 2 / (2 * v))

lemma fkK_nonneg (v w : ℝ) : 0 ≤ fkK v w := by unfold fkK; positivity

lemma fkK_continuous (v : ℝ) : Continuous (fkK v) := by unfold fkK; fun_prop

/-- Slope of the kernel along a path `(v(s), w(s))`. -/
lemma fkK_hasDerivAt {v w : ℝ → ℝ} {v' w' t : ℝ} (hv : HasDerivAt v v' t) (hw : HasDerivAt w w' t)
    (hpos : 0 < v t) :
    HasDerivAt (fun s => fkK (v s) (w s))
      (fkK (v t) (w t) * (v' * (w t ^ 2 / (2 * v t ^ 2) - 1 / (2 * v t)) + w' * (-(w t) / v t)))
      t := by
  have h2pv : 0 < 2 * Real.pi * v t := by positivity
  have hs : 0 < Real.sqrt (2 * Real.pi * v t) := Real.sqrt_pos.2 h2pv
  have h1 : HasDerivAt (fun s => (Real.sqrt (2 * Real.pi * v s))⁻¹)
      (-(2 * Real.pi * v' / (2 * Real.sqrt (2 * Real.pi * v t))) /
        Real.sqrt (2 * Real.pi * v t) ^ 2) t :=
    ((hv.const_mul (2 * Real.pi)).sqrt h2pv.ne').inv hs.ne'
  have hw2 : HasDerivAt (fun s => -w s ^ 2 / (2 * v s))
      ((-(2 * w t * w') * (2 * v t) - (-w t ^ 2) * (2 * v')) / (2 * v t) ^ 2) t := by
    have := ((hw.pow 2).neg).div (hv.const_mul 2) (by positivity)
    convert this using 1
    simp
  have h := h1.mul hw2.exp
  unfold fkK
  refine h.congr_deriv ?_
  have hsq : Real.sqrt (2 * Real.pi * v t) ^ 2 = 2 * Real.pi * v t := Real.sq_sqrt h2pv.le
  field_simp
  rw [hsq]
  ring

/-- The kernel is at most a fixed bell, uniformly in the variance on `[v1, v2]`. -/
lemma fkK_bound {v1 v2 v : ℝ} (hv1 : 0 < v1) (hv : v1 ≤ v) (hv2 : v ≤ v2) (w : ℝ) :
    fkK v w * (1 + w ^ 2) ≤
      (1 + 4 * v2) * (Real.sqrt (2 * Real.pi * v1))⁻¹ * Real.exp (-(1 / (4 * v2)) * w ^ 2) := by
  have hv0 : 0 < v := lt_of_lt_of_le hv1 hv
  have hv20 : 0 < v2 := lt_of_lt_of_le hv0 hv2
  have hs1 : 0 < Real.sqrt (2 * Real.pi * v1) := Real.sqrt_pos.2 (by positivity)
  have hsv : (Real.sqrt (2 * Real.pi * v))⁻¹ ≤ (Real.sqrt (2 * Real.pi * v1))⁻¹ := by
    apply inv_anti₀ hs1
    apply Real.sqrt_le_sqrt
    have := Real.pi_pos
    nlinarith
  have he : Real.exp (-w ^ 2 / (2 * v)) ≤
      Real.exp (-(1 / (4 * v2)) * w ^ 2) * Real.exp (-(1 / (4 * v2)) * w ^ 2) := by
    rw [← Real.exp_add]
    apply Real.exp_le_exp.2
    have : w ^ 2 / (2 * v2) ≤ w ^ 2 / (2 * v) :=
      div_le_div_of_nonneg_left (sq_nonneg w) (by positivity) (by linarith)
    have e2 : -(1 / (4 * v2)) * w ^ 2 + -(1 / (4 * v2)) * w ^ 2 = -(w ^ 2 / (2 * v2)) := by
      field_simp; ring
    rw [e2, neg_div]
    linarith
  have hq : (1 + w ^ 2) * Real.exp (-(1 / (4 * v2)) * w ^ 2) ≤ 1 + 4 * v2 := by
    have h1 : w ^ 2 / (4 * v2) + 1 ≤ Real.exp (w ^ 2 / (4 * v2)) := Real.add_one_le_exp _
    have h2 : Real.exp (-(1 / (4 * v2)) * w ^ 2) * Real.exp (w ^ 2 / (4 * v2)) = 1 := by
      rw [← Real.exp_add]; simp; field_simp; ring
    have h3 : Real.exp (-(1 / (4 * v2)) * w ^ 2) ≤ 1 := by
      apply Real.exp_le_one_iff.2
      have : 0 ≤ 1 / (4 * v2) * w ^ 2 := by positivity
      linarith
    have hE := Real.exp_pos (-(1 / (4 * v2)) * w ^ 2)
    have h4 : w ^ 2 * Real.exp (-(1 / (4 * v2)) * w ^ 2) ≤ 4 * v2 := by
      have : w ^ 2 / (4 * v2) * Real.exp (-(1 / (4 * v2)) * w ^ 2) ≤ 1 := by
        calc w ^ 2 / (4 * v2) * Real.exp (-(1 / (4 * v2)) * w ^ 2)
            ≤ Real.exp (w ^ 2 / (4 * v2)) * Real.exp (-(1 / (4 * v2)) * w ^ 2) :=
              mul_le_mul_of_nonneg_right (by linarith) hE.le
          _ = 1 := by rw [mul_comm, h2]
      rw [div_mul_eq_mul_div, div_le_one (by positivity)] at this
      exact this
    nlinarith
  unfold fkK
  calc (Real.sqrt (2 * Real.pi * v))⁻¹ * Real.exp (-w ^ 2 / (2 * v)) * (1 + w ^ 2)
      ≤ (Real.sqrt (2 * Real.pi * v1))⁻¹ *
          (Real.exp (-(1 / (4 * v2)) * w ^ 2) * Real.exp (-(1 / (4 * v2)) * w ^ 2)) * (1 + w ^ 2) := by
        gcongr
    _ = (Real.sqrt (2 * Real.pi * v1))⁻¹ * Real.exp (-(1 / (4 * v2)) * w ^ 2) *
          ((1 + w ^ 2) * Real.exp (-(1 / (4 * v2)) * w ^ 2)) := by ring
    _ ≤ (Real.sqrt (2 * Real.pi * v1))⁻¹ * Real.exp (-(1 / (4 * v2)) * w ^ 2) * (1 + 4 * v2) := by
        gcongr
    _ = _ := by ring

lemma fk_exp_shift_le {b : ℝ} (hb : 0 < b) (c0 c z : ℝ) (hc : |c - c0| ≤ 1) :
    Real.exp (-b * (z - c) ^ 2) ≤ Real.exp b * Real.exp (-(b / 2) * (z - c0) ^ 2) := by
  rw [← Real.exp_add]
  apply Real.exp_le_exp.2
  have hx2 : (c - c0) ^ 2 ≤ 1 := by
    have := abs_le.1 hc; nlinarith
  have h1 : (z - c0) ^ 2 ≤ 2 * (z - c) ^ 2 + 2 := by nlinarith [sq_nonneg (z - c + (c0 - c))]
  nlinarith [mul_le_mul_of_nonneg_left h1 hb.le]

lemma fk_integrable_dom {b : ℝ} (hb : 0 < b) (c0 : ℝ) :
    Integrable (fun z => Real.exp (-b * (z - c0) ^ 2) * Real.exp |z|) := by
  have hint : Integrable (fun z => Real.exp (|c0| + 1 / (2 * b)) *
      Real.exp (-(b / 2) * (z - c0) ^ 2)) :=
    ((integrable_exp_neg_mul_sq (half_pos hb)).comp_sub_right c0).const_mul _
  refine hint.mono' (by fun_prop) (ae_of_all _ fun z => ?_)
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity), ← Real.exp_add, ← Real.exp_add]
  apply Real.exp_le_exp.2
  have h1 : |z| ≤ |z - c0| + |c0| := by
    have := abs_add_le (z - c0) c0; simpa using this
  have h2 : |z - c0| ≤ b / 2 * (z - c0) ^ 2 + 1 / (2 * b) := by
    have hsq : |z - c0| ^ 2 = (z - c0) ^ 2 := sq_abs _
    have : 0 ≤ (b * |z - c0| - 1) ^ 2 := sq_nonneg _
    have e : b / 2 * (z - c0) ^ 2 + 1 / (2 * b) - |z - c0| = (b * |z - c0| - 1) ^ 2 / (2 * b) := by
      rw [← hsq]; field_simp; ring
    have : 0 ≤ (b * |z - c0| - 1) ^ 2 / (2 * b) := by positivity
    linarith
  linarith

/-- The combined pointwise bound used for every slope under the integral. -/
lemma fk_dom_bound {A C v1 v2 v c c0 z q G : ℝ} (hv1 : 0 < v1) (hv : v1 ≤ v) (hv2 : v ≤ v2)
    (hc : |c - c0| ≤ 1) (hA : 0 ≤ A) (hC : 0 ≤ C) (hq : |q| ≤ A * (1 + (z - c) ^ 2))
    (hG : |G| ≤ C * Real.exp |z|) :
    ‖fkK v (z - c) * q * G‖ ≤
      A * C * (1 + 4 * v2) * (Real.sqrt (2 * Real.pi * v1))⁻¹ * Real.exp (1 / (4 * v2)) *
        (Real.exp (-(1 / (4 * v2) / 2) * (z - c0) ^ 2) * Real.exp |z|) := by
  have hv20 : 0 < v2 := by linarith
  have hb : 0 < 1 / (4 * v2) := by positivity
  have hK := fkK_bound hv1 hv hv2 (z - c)
  have hsh := fk_exp_shift_le hb c0 c z hc
  rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_of_nonneg (fkK_nonneg _ _)]
  have hK0 := fkK_nonneg v (z - c)
  calc fkK v (z - c) * |q| * |G| ≤ fkK v (z - c) * (A * (1 + (z - c) ^ 2)) * (C * Real.exp |z|) := by
        gcongr
    _ = A * C * Real.exp |z| * (fkK v (z - c) * (1 + (z - c) ^ 2)) := by ring
    _ ≤ A * C * Real.exp |z| * ((1 + 4 * v2) * (Real.sqrt (2 * Real.pi * v1))⁻¹ *
          Real.exp (-(1 / (4 * v2)) * (z - c) ^ 2)) := by gcongr
    _ ≤ A * C * Real.exp |z| * ((1 + 4 * v2) * (Real.sqrt (2 * Real.pi * v1))⁻¹ *
          (Real.exp (1 / (4 * v2)) * Real.exp (-(1 / (4 * v2) / 2) * (z - c0) ^ 2))) := by gcongr
    _ = _ := by ring

section Kernel

variable {g : ℝ → ℝ} {C : ℝ}

lemma fk_integrable_kernel (hg : Continuous g) (hC : 0 ≤ C) (hgC : ∀ y, |g y| ≤ C * Real.exp |y|)
    {v A c : ℝ} (hv : 0 < v) (hA : 0 ≤ A) {Q : ℝ → ℝ} (hQc : Continuous Q)
    (hQ : ∀ w, |Q w| ≤ A * (1 + w ^ 2)) :
    Integrable (fun z => fkK v (z - c) * Q (z - c) * g z) := by
  have hb : 0 < 1 / (4 * v) / 2 := by positivity
  refine ((fk_integrable_dom hb c).const_mul (A * C * (1 + 4 * v) *
    (Real.sqrt (2 * Real.pi * v))⁻¹ * Real.exp (1 / (4 * v)))).mono' ?_ (ae_of_all _ fun z => ?_)
  · have := fkK_continuous v
    fun_prop
  · exact fk_dom_bound hv le_rfl le_rfl (by simp) hA hC (hQ _) (hgC z)

/-- Slope in the start point, under the integral. -/
lemma fk_hasDerivAt_x (hg : Continuous g) (hC : 0 ≤ C) (hgC : ∀ y, |g y| ≤ C * Real.exp |y|)
    {v m A : ℝ} (hv : 0 < v) (hA : 0 ≤ A) {Q0 Q1 : ℝ → ℝ} (hQ0c : Continuous Q0)
    (hQ1c : Continuous Q1) (hQ0 : ∀ w, |Q0 w| ≤ A * (1 + w ^ 2))
    (hQ1 : ∀ w, |Q1 w| ≤ A * (1 + w ^ 2))
    (hd : ∀ x z, HasDerivAt (fun x => fkK v (z - (x + m)) * Q0 (z - (x + m)))
      (fkK v (z - (x + m)) * Q1 (z - (x + m))) x) (x0 : ℝ) :
    Integrable (fun z => fkK v (z - (x0 + m)) * Q1 (z - (x0 + m)) * g z) ∧
    HasDerivAt (fun x => ∫ z, fkK v (z - (x + m)) * Q0 (z - (x + m)) * g z)
      (∫ z, fkK v (z - (x0 + m)) * Q1 (z - (x0 + m)) * g z) x0 := by
  have hb : 0 < 1 / (4 * v) / 2 := by positivity
  have hKc := fkK_continuous v
  refine hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun x z => fkK v (z - (x + m)) * Q0 (z - (x + m)) * g z)
    (F' := fun x z => fkK v (z - (x + m)) * Q1 (z - (x + m)) * g z) (x₀ := x0)
    (bound := fun z => A * C * (1 + 4 * v) * (Real.sqrt (2 * Real.pi * v))⁻¹ *
      Real.exp (1 / (4 * v)) * (Real.exp (-(1 / (4 * v) / 2) * (z - (x0 + m)) ^ 2) *
        Real.exp |z|))
    (Metric.ball_mem_nhds x0 one_pos)
    (Eventually.of_forall fun x => by apply Continuous.aestronglyMeasurable; fun_prop)
    (fk_integrable_kernel hg hC hgC hv hA hQ0c hQ0)
    (by apply Continuous.aestronglyMeasurable; fun_prop)
    (ae_of_all _ fun z x hx => ?_)
    ((fk_integrable_dom hb _).const_mul _)
    (ae_of_all _ fun z x _ => (hd x z).mul_const (g z))
  rw [Metric.mem_ball, Real.dist_eq] at hx
  exact fk_dom_bound hv le_rfl le_rfl (by rw [show x + m - (x0 + m) = x - x0 by ring]; exact hx.le)
    hA hC (hQ1 _) (hgC z)

lemma fk_Qt_bound {v1 v r μ s2 w : ℝ} (hv1 : 0 < v1) (hv : v1 ≤ v) (hs2 : 0 ≤ s2) :
    |r - s2 * (w ^ 2 / (2 * v ^ 2) - 1 / (2 * v)) - μ * w / v| ≤
      (|r| + s2 * (1 / v1 ^ 2 + 1 / v1) + |μ| / v1) * (1 + w ^ 2) := by
  have hv0 : 0 < v := lt_of_lt_of_le hv1 hv
  have ha0 : 0 ≤ w ^ 2 / (2 * v ^ 2) := by positivity
  have ha1 : w ^ 2 / (2 * v ^ 2) ≤ 1 / v1 ^ 2 * w ^ 2 := by
    rw [one_div_mul_eq_div]
    apply div_le_div_of_nonneg_left (sq_nonneg w) (by positivity)
    nlinarith
  have hb0 : 0 ≤ 1 / (2 * v) := by positivity
  have hb1 : 1 / (2 * v) ≤ 1 / v1 := one_div_le_one_div_of_le hv1 (by linarith)
  have hw : |w| ≤ 1 + w ^ 2 := by nlinarith [sq_nonneg (|w| - 1), sq_abs w, abs_nonneg w]
  have hc : |μ * w / v| ≤ |μ| / v1 * (1 + w ^ 2) := by
    rw [abs_div, abs_mul, abs_of_pos hv0, div_le_iff₀ hv0]
    have : |μ| / v1 * v ≥ |μ| := by
      rw [div_mul_eq_mul_div, ge_iff_le, le_div_iff₀ hv1]
      exact mul_le_mul_of_nonneg_left hv (abs_nonneg μ)
    calc |μ| * |w| ≤ |μ| * (1 + w ^ 2) := mul_le_mul_of_nonneg_left hw (abs_nonneg μ)
      _ ≤ |μ| / v1 * v * (1 + w ^ 2) := mul_le_mul_of_nonneg_right this (by positivity)
      _ = _ := by ring
  have hsa : |s2 * (w ^ 2 / (2 * v ^ 2) - 1 / (2 * v))| ≤
      s2 * (1 / v1 ^ 2 + 1 / v1) * (1 + w ^ 2) := by
    rw [abs_mul, abs_of_nonneg hs2]
    have : |w ^ 2 / (2 * v ^ 2) - 1 / (2 * v)| ≤ (1 / v1 ^ 2 + 1 / v1) * (1 + w ^ 2) := by
      refine (abs_sub _ _).trans ?_
      rw [abs_of_nonneg ha0, abs_of_nonneg hb0]
      have h1 : 0 ≤ 1 / v1 ^ 2 := by positivity
      have h2 : 0 ≤ 1 / v1 := by positivity
      nlinarith [sq_nonneg w]
    calc s2 * |w ^ 2 / (2 * v ^ 2) - 1 / (2 * v)| ≤ s2 * ((1 / v1 ^ 2 + 1 / v1) * (1 + w ^ 2)) :=
          mul_le_mul_of_nonneg_left this hs2
      _ = _ := by ring
  have hr : |r| ≤ |r| * (1 + w ^ 2) := by nlinarith [abs_nonneg r, sq_nonneg w]
  calc |r - s2 * (w ^ 2 / (2 * v ^ 2) - 1 / (2 * v)) - μ * w / v|
      ≤ |r| + |s2 * (w ^ 2 / (2 * v ^ 2) - 1 / (2 * v))| + |μ * w / v| := by
        refine (abs_sub _ _).trans ?_
        gcongr
        exact abs_sub _ _
    _ ≤ _ := by nlinarith

end Kernel

/-- The time-slope factor of the discounted kernel. -/
noncomputable def fkQt (μ σ r v w : ℝ) : ℝ := r - σ ^ 2 * (w ^ 2 / (2 * v ^ 2) - 1 / (2 * v)) - μ * w / v

section TimeSlope

variable {g : ℝ → ℝ} {C : ℝ}

lemma fk_hasDerivAt_t (hg : Continuous g) (hC : 0 ≤ C) (hgC : ∀ y, |g y| ≤ C * Real.exp |y|)
    {μ σ r T t0 x : ℝ} (hσ : σ ≠ 0) (ht0 : t0 < T) :
    Integrable (fun z => fkK (σ ^ 2 * (T - t0)) (z - (x + μ * (T - t0))) *
      (Real.exp (-r * (T - t0)) * fkQt μ σ r (σ ^ 2 * (T - t0)) (z - (x + μ * (T - t0)))) * g z) ∧
    HasDerivAt (fun s => ∫ z, fkK (σ ^ 2 * (T - s)) (z - (x + μ * (T - s))) *
        Real.exp (-r * (T - s)) * g z)
      (∫ z, fkK (σ ^ 2 * (T - t0)) (z - (x + μ * (T - t0))) *
        (Real.exp (-r * (T - t0)) * fkQt μ σ r (σ ^ 2 * (T - t0)) (z - (x + μ * (T - t0)))) *
          g z) t0 := by
  set τ0 := T - t0 with hτ0
  have hτ0p : 0 < τ0 := by rw [hτ0]; linarith
  have hσ2 : 0 < σ ^ 2 := by positivity
  set v1 := σ ^ 2 * τ0 / 2 with hv1
  set v2 := σ ^ 2 * τ0 * 2 with hv2
  have hv1p : 0 < v1 := by positivity
  set δ := min (τ0 / 2) (1 / (|μ| + 1)) with hδ
  have hδp : 0 < δ := by positivity
  set E := Real.exp (|r| * (2 * τ0)) with hE
  set A' := |r| + σ ^ 2 * (1 / v1 ^ 2 + 1 / v1) + |μ| / v1 with hA'
  have hA'0 : 0 ≤ A' := by positivity
  have hb : 0 < 1 / (4 * v2) / 2 := by positivity
  have hKc : ∀ v, Continuous (fkK v) := fkK_continuous
  -- facts on the ball
  have hball : ∀ s ∈ Metric.ball t0 δ, v1 ≤ σ ^ 2 * (T - s) ∧ σ ^ 2 * (T - s) ≤ v2 ∧
      |x + μ * (T - s) - (x + μ * (T - t0))| ≤ 1 ∧ Real.exp (-r * (T - s)) ≤ E := by
    intro s hs
    rw [Metric.mem_ball, Real.dist_eq, abs_lt] at hs
    have hδ1 : δ ≤ τ0 / 2 := min_le_left _ _
    have hδ2 : δ ≤ 1 / (|μ| + 1) := min_le_right _ _
    have hTs1 : τ0 / 2 ≤ T - s := by rw [hτ0]; linarith
    have hTs2 : T - s ≤ 2 * τ0 := by rw [hτ0] at *; linarith
    refine ⟨?_, ?_, ?_, ?_⟩
    · rw [hv1]; nlinarith
    · rw [hv2]; nlinarith
    · rw [show x + μ * (T - s) - (x + μ * (T - t0)) = μ * (t0 - s) by ring, abs_mul]
      have h1 : |t0 - s| ≤ 1 / (|μ| + 1) := by rw [abs_le]; constructor <;> linarith
      calc |μ| * |t0 - s| ≤ |μ| * (1 / (|μ| + 1)) := mul_le_mul_of_nonneg_left h1 (abs_nonneg _)
        _ ≤ 1 := by
          rw [mul_one_div, div_le_one (by positivity)]; linarith
    · rw [hE]; apply Real.exp_le_exp.2
      have : -r * (T - s) ≤ |r| * (T - s) := by
        have := neg_abs_le r
        nlinarith [hTs1, hτ0p]
      nlinarith [abs_nonneg r]
  refine hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun s z => fkK (σ ^ 2 * (T - s)) (z - (x + μ * (T - s))) * Real.exp (-r * (T - s)) * g z)
    (F' := fun s z => fkK (σ ^ 2 * (T - s)) (z - (x + μ * (T - s))) *
      (Real.exp (-r * (T - s)) * fkQt μ σ r (σ ^ 2 * (T - s)) (z - (x + μ * (T - s)))) * g z)
    (x₀ := t0)
    (bound := fun z => (E * A') * C * (1 + 4 * v2) * (Real.sqrt (2 * Real.pi * v1))⁻¹ *
      Real.exp (1 / (4 * v2)) * (Real.exp (-(1 / (4 * v2) / 2) * (z - (x + μ * (T - t0))) ^ 2) *
        Real.exp |z|))
    (Metric.ball_mem_nhds t0 hδp)
    (Eventually.of_forall fun s => by apply Continuous.aestronglyMeasurable; have := hKc (σ ^ 2 * (T - s)); fun_prop)
    ?_ ?_ (ae_of_all _ fun z s hs => ?_) ((fk_integrable_dom hb _).const_mul _)
    (ae_of_all _ fun z s hs => ?_)
  · have := fk_integrable_kernel (c := x + μ * (T - t0)) hg hC hgC (v := σ ^ 2 * (T - t0))
      (by positivity) (zero_le_one) (Q := fun _ => 1) continuous_const (fun w => by
        simp only [abs_one]; nlinarith [sq_nonneg w])
    refine (this.mul_const (Real.exp (-r * (T - t0)))).congr (ae_of_all _ fun z => ?_)
    simp only; ring
  · apply Continuous.aestronglyMeasurable
    have := hKc (σ ^ 2 * (T - t0))
    unfold fkQt
    fun_prop
  · obtain ⟨h1, h2, h3, h4⟩ := hball s hs
    refine fk_dom_bound hv1p h1 h2 h3 (by positivity) hC ?_ (hgC z)
    rw [abs_mul, abs_of_pos (Real.exp_pos _)]
    have hq := fk_Qt_bound (r := r) (μ := μ) (w := z - (x + μ * (T - s))) hv1p h1 hσ2.le
    calc Real.exp (-r * (T - s)) * |fkQt μ σ r (σ ^ 2 * (T - s)) (z - (x + μ * (T - s)))|
        ≤ E * (A' * (1 + (z - (x + μ * (T - s))) ^ 2)) := by
          unfold fkQt; gcongr
      _ = _ := by ring
  · obtain ⟨h1, -, -, -⟩ := hball s hs
    have hvpos : 0 < σ ^ 2 * (T - s) := lt_of_lt_of_le hv1p h1
    have hv : HasDerivAt (fun s => σ ^ 2 * (T - s)) (σ ^ 2 * (0 - 1)) s :=
      ((hasDerivAt_const s T).sub (hasDerivAt_id s)).const_mul (σ ^ 2)
    have hw : HasDerivAt (fun s => z - (x + μ * (T - s))) (0 - (0 + μ * (0 - 1))) s :=
      (hasDerivAt_const s z).sub ((hasDerivAt_const s x).add
        (((hasDerivAt_const s T).sub (hasDerivAt_id s)).const_mul μ))
    have hK := fkK_hasDerivAt hv hw hvpos
    have hexp : HasDerivAt (fun s => Real.exp (-r * (T - s)))
        (Real.exp (-r * (T - s)) * (-r * (0 - 1))) s :=
      (((hasDerivAt_const s T).sub (hasDerivAt_id s)).const_mul (-r)).exp
    refine ((hK.mul hexp).mul_const (g z)).congr_deriv ?_
    unfold fkQt
    ring

end TimeSlope

section Bridge

variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ}

lemma fk_bridge (hB : IsBrownianReal B P) (τ : ℝ≥0) {f : ℝ → ℝ} (hf : Continuous f) :
    ∫ ω, f (B τ ω) ∂P = ∫ y, f y ∂(gaussianReal 0 τ) :=
  (hB.toIsPreBrownianReal.hasLaw_eval τ).integral_comp hf.aestronglyMeasurable

lemma fk_std_form (τ : ℝ≥0) {f : ℝ → ℝ} (hf : Continuous f) :
    ∫ y, f y ∂(gaussianReal 0 τ) = ∫ z, f (Real.sqrt τ * z) ∂(gaussianReal 0 1) := by
  have hmap : (gaussianReal 0 1).map (fun z => Real.sqrt τ * z) = gaussianReal 0 τ := by
    rw [gaussianReal_map_const_mul]
    congr 1
    · simp
    · ext; simp
  rw [← hmap, integral_map (by fun_prop) hf.aestronglyMeasurable]

lemma fk_kernel_form (τ : ℝ≥0) (hτ : τ ≠ 0) {σ : ℝ} (hσ : σ ≠ 0) (c : ℝ) {g : ℝ → ℝ}
    (hg : Continuous g) :
    ∫ y, g (c + σ * y) ∂(gaussianReal 0 τ) = ∫ z, fkK (σ ^ 2 * τ) (z - c) * g z := by
  have hmap : (gaussianReal 0 τ).map (fun y => c + σ * y) =
      gaussianReal c (⟨σ ^ 2, sq_nonneg _⟩ * τ) := by
    have : (fun y => c + σ * y) = (fun y => c + y) ∘ (fun y => σ * y) := rfl
    rw [this, ← Measure.map_map (by fun_prop) (by fun_prop), gaussianReal_map_const_mul,
      gaussianReal_map_const_add]
    simp only [mul_zero, zero_add]
    rfl
  have hv : (⟨σ ^ 2, sq_nonneg _⟩ * τ : ℝ≥0) ≠ 0 := by
    apply mul_ne_zero _ hτ
    intro h
    have := congrArg (fun q : ℝ≥0 => (q : ℝ)) h
    simp only [NNReal.coe_zero] at this
    exact hσ (pow_eq_zero_iff two_ne_zero |>.1 this)
  rw [← integral_map (f := g) (φ := fun y => c + σ * y) (by fun_prop) hg.aestronglyMeasurable,
    hmap, integral_gaussianReal_eq_integral_smul hv]
  congr 1

end Bridge

/-- The discounted average of the payoff, as in the card. -/
noncomputable def fkW {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (B : ℝ≥0 → Ω → ℝ)
    (μ σ r T : ℝ) (g : ℝ → ℝ) (t x : ℝ) : ℝ :=
  Real.exp (-r * (T - t)) * ∫ ω, g (x + μ * (T - t) + σ * B (T - t).toNNReal ω) ∂P

/-- Its slope in the start point. -/
noncomputable def fkWx (μ σ r T : ℝ) (g : ℝ → ℝ) (t x : ℝ) : ℝ :=
  Real.exp (-r * (T - t)) * ∫ z, fkK (σ ^ 2 * (T - t)) (z - (x + μ * (T - t))) *
    ((z - (x + μ * (T - t))) / (σ ^ 2 * (T - t))) * g z

/-- Its second slope in the start point. -/
noncomputable def fkWxx (μ σ r T : ℝ) (g : ℝ → ℝ) (t x : ℝ) : ℝ :=
  Real.exp (-r * (T - t)) * ∫ z, fkK (σ ^ 2 * (T - t)) (z - (x + μ * (T - t))) *
    ((z - (x + μ * (T - t))) ^ 2 / (σ ^ 2 * (T - t)) ^ 2 - 1 / (σ ^ 2 * (T - t))) * g z

/-- Its slope in time. -/
noncomputable def fkWt (μ σ r T : ℝ) (g : ℝ → ℝ) (t x : ℝ) : ℝ :=
  ∫ z, fkK (σ ^ 2 * (T - t)) (z - (x + μ * (T - t))) *
    (Real.exp (-r * (T - t)) * fkQt μ σ r (σ ^ 2 * (T - t)) (z - (x + μ * (T - t)))) * g z

section Average

variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ}
  {μ σ r T : ℝ} {g : ℝ → ℝ}

lemma fkW_kernel (hB : IsBrownianReal B P) (hg : Continuous g) (hσ : σ ≠ 0) {t : ℝ} (ht : t < T)
    (x : ℝ) :
    fkW P B μ σ r T g t x =
      ∫ z, fkK (σ ^ 2 * (T - t)) (z - (x + μ * (T - t))) * Real.exp (-r * (T - t)) * g z := by
  have hτ : (T - t).toNNReal ≠ 0 := by
    rw [Ne, Real.toNNReal_eq_zero, not_le]; linarith
  unfold fkW
  rw [fk_bridge hB _ (f := fun y => g (x + μ * (T - t) + σ * y)) (by fun_prop),
    fk_kernel_form _ hτ hσ _ hg, Real.coe_toNNReal _ (by linarith), ← integral_const_mul]
  congr 1; funext z; ring

lemma fkW_zero_vol (hB : IsBrownianReal B P) (hg : Continuous g) (t x : ℝ) :
    fkW P B μ 0 r T g t x = Real.exp (-r * (T - t)) * g (x + μ * (T - t)) := by
  unfold fkW
  rw [fk_bridge hB _ (f := fun y => g (x + μ * (T - t) + 0 * y)) (by fun_prop)]
  simp

lemma fkW_derivs (hB : IsBrownianReal B P) (hg : Continuous g)
    (hg_growth : ∃ C : ℝ, ∃ k : ℕ, ∀ y, |g y| ≤ C * (1 + |y| ^ k)) (hσ : σ ≠ 0) {t : ℝ}
    (ht : t < T) (x : ℝ) :
    HasDerivAt (fun s => fkW P B μ σ r T g s x) (fkWt μ σ r T g t x) t ∧
    (∀ y, HasDerivAt (fun y => fkW P B μ σ r T g t y) (fkWx μ σ r T g t y) y) ∧
    (∀ y, HasDerivAt (fun y => fkWx μ σ r T g t y) (fkWxx μ σ r T g t y) y) ∧
    fkWt μ σ r T g t x + μ * fkWx μ σ r T g t x + 1 / 2 * σ ^ 2 * fkWxx μ σ r T g t x
      - r * fkW P B μ σ r T g t x = 0 := by
  obtain ⟨C, hC, hgC⟩ := fk_growth_exp hg_growth
  set v := σ ^ 2 * (T - t) with hvdef
  have hv : 0 < v := by
    have : 0 < T - t := by linarith
    positivity
  set m := μ * (T - t) with hm
  set A := 1 + 1 / v + 1 / v ^ 2 with hA
  have hA0 : 0 ≤ A := by positivity
  have hw1 : ∀ w : ℝ, |w| ≤ 1 + w ^ 2 := fun w => by
    nlinarith [sq_nonneg (|w| - 1), sq_abs w, abs_nonneg w]
  have hQ0 : ∀ w : ℝ, |(fun _ : ℝ => (1:ℝ)) w| ≤ A * (1 + w ^ 2) := fun w => by
    simp only [abs_one]
    have : 0 ≤ 1 / v + 1 / v ^ 2 := by positivity
    nlinarith [sq_nonneg w]
  have hQ1 : ∀ w : ℝ, |w / v| ≤ A * (1 + w ^ 2) := fun w => by
    rw [abs_div, abs_of_pos hv, div_eq_mul_one_div, mul_comm]
    have h1 : 0 ≤ 1 / v := by positivity
    have h2 : 0 ≤ 1 / v ^ 2 := by positivity
    nlinarith [hw1 w, sq_nonneg w, mul_le_mul_of_nonneg_left (hw1 w) h1]
  have hQ2 : ∀ w : ℝ, |w ^ 2 / v ^ 2 - 1 / v| ≤ A * (1 + w ^ 2) := fun w => by
    refine (abs_sub _ _).trans ?_
    rw [abs_of_nonneg (by positivity), abs_of_nonneg (by positivity)]
    have h1 : 0 ≤ 1 / v := by positivity
    have h2 : 0 ≤ 1 / v ^ 2 := by positivity
    have : w ^ 2 / v ^ 2 = 1 / v ^ 2 * w ^ 2 := by ring
    rw [this]
    nlinarith [sq_nonneg w, mul_nonneg h1 (sq_nonneg w), mul_nonneg h2 (sq_nonneg w)]
  have hwd : ∀ x z : ℝ, HasDerivAt (fun x => z - (x + m)) (0 - (1 + 0)) x := fun x z =>
    (hasDerivAt_const x z).sub ((hasDerivAt_id x).add (hasDerivAt_const x m))
  have hd0 : ∀ x z : ℝ, HasDerivAt (fun x => fkK v (z - (x + m)) * (fun _ : ℝ => (1:ℝ)) (z - (x + m)))
      (fkK v (z - (x + m)) * (fun w => w / v) (z - (x + m))) x := fun x z => by
    have h := (fkK_hasDerivAt (hasDerivAt_const x v) (hwd x z) hv).mul_const (1:ℝ)
    refine h.congr_deriv ?_
    simp only; ring
  have hd1 : ∀ x z : ℝ, HasDerivAt (fun x => fkK v (z - (x + m)) * (fun w => w / v) (z - (x + m)))
      (fkK v (z - (x + m)) * (fun w => w ^ 2 / v ^ 2 - 1 / v) (z - (x + m))) x := fun x z => by
    have h := (fkK_hasDerivAt (hasDerivAt_const x v) (hwd x z) hv).mul ((hwd x z).div_const v)
    refine h.congr_deriv ?_
    simp only; field_simp; ring
  have hX0 := fun x0 => fk_hasDerivAt_x hg hC hgC hv hA0 continuous_const (by fun_prop) hQ0
    hQ1 hd0 x0 (m := m)
  have hX1 := fun x0 => fk_hasDerivAt_x hg hC hgC hv hA0 (by fun_prop) (by fun_prop) hQ1
    hQ2 hd1 x0 (m := m)
  have hT := fk_hasDerivAt_t (x := x) (r := r) (μ := μ) hg hC hgC hσ ht
  have hWfun : (fun y => fkW P B μ σ r T g t y) =
      fun y => Real.exp (-r * (T - t)) *
        ∫ z, fkK v (z - (y + m)) * (fun _ : ℝ => (1:ℝ)) (z - (y + m)) * g z := by
    funext y
    rw [fkW_kernel hB hg hσ ht, ← integral_const_mul]
    congr 1; funext z; simp only; ring
  have hI0 : Integrable (fun z => fkK v (z - (x + m)) * g z) := by
    have := fk_integrable_kernel (c := x + m) hg hC hgC hv hA0 continuous_const hQ0
    simpa using this
  refine ⟨?_, fun y => ?_, fun y => ?_, ?_⟩
  · refine hT.2.congr_of_eventuallyEq ?_
    filter_upwards [Iio_mem_nhds ht] with s hs
    exact fkW_kernel hB hg hσ hs x
  · rw [hWfun]
    exact (hX0 y).2.const_mul _
  · exact (hX1 y).2.const_mul _
  · -- the backward equation, point by point under the integral
    have hI1 := (hX0 x).1
    have hI2 := (hX1 x).1
    have hpt : (fun z => fkK v (z - (x + m)) *
        (Real.exp (-r * (T - t)) * fkQt μ σ r v (z - (x + m))) * g z) =
        fun z => Real.exp (-r * (T - t)) * (r * (fkK v (z - (x + m)) * g z)
          - μ * (fkK v (z - (x + m)) * ((z - (x + m)) / v) * g z)
          - 1 / 2 * σ ^ 2 * (fkK v (z - (x + m)) * ((z - (x + m)) ^ 2 / v ^ 2 - 1 / v) * g z)) := by
      funext z
      unfold fkQt
      field_simp
      ring
    have hWt : fkWt μ σ r T g t x = Real.exp (-r * (T - t)) * (r * (∫ z, fkK v (z - (x + m)) * g z)
        - μ * (∫ z, fkK v (z - (x + m)) * ((z - (x + m)) / v) * g z)
        - 1 / 2 * σ ^ 2 * (∫ z, fkK v (z - (x + m)) * ((z - (x + m)) ^ 2 / v ^ 2 - 1 / v) * g z)) := by
      unfold fkWt
      rw [← hvdef, ← hm, hpt, integral_const_mul, integral_sub, integral_sub, integral_const_mul,
        integral_const_mul, integral_const_mul]
      · exact hI0.const_mul _
      · exact hI1.const_mul _
      · exact (hI0.const_mul _).sub (hI1.const_mul _)
      · exact hI2.const_mul _
    have hW : fkW P B μ σ r T g t x = Real.exp (-r * (T - t)) * ∫ z, fkK v (z - (x + m)) * g z := by
      rw [fkW_kernel hB hg hσ ht, ← integral_const_mul]
      congr 1; funext z; ring
    rw [hWt, hW]
    unfold fkWx fkWxx
    rw [← hvdef, ← hm]
    ring

end Average

lemma fk_poly_le_exp {C : ℝ} (hC : 0 ≤ C) (k : ℕ) (y : ℝ) :
    C * (1 + |y| ^ k) ≤ C * (1 + k.factorial) * Real.exp |y| := by
  have h1 : |y| ^ k ≤ k.factorial * Real.exp |y| := by
    have := Real.pow_div_factorial_le_exp (x := |y|) (abs_nonneg y) k
    rw [div_le_iff₀ (by positivity)] at this
    linarith
  have h2 : 1 ≤ Real.exp |y| := Real.one_le_exp (abs_nonneg y)
  have : 1 + |y| ^ k ≤ (1 + k.factorial) * Real.exp |y| := by nlinarith
  calc C * (1 + |y| ^ k) ≤ C * ((1 + k.factorial) * Real.exp |y|) :=
        mul_le_mul_of_nonneg_left this hC
    _ = _ := by ring

lemma fk_integrable_exp_abs (K : ℝ) :
    Integrable (fun z => Real.exp (K * |z|)) (gaussianReal 0 1) := by
  refine ((integrable_exp_mul_gaussianReal K).add (integrable_exp_mul_gaussianReal (-K))).mono'
    (by fun_prop) (ae_of_all _ fun z => ?_)
  rw [Real.norm_eq_abs, abs_of_pos (Real.exp_pos _)]
  have h1 := Real.exp_pos (K * z)
  have h2 := Real.exp_pos (-K * z)
  rcases abs_cases z with ⟨hz, _⟩ | ⟨hz, _⟩
  · rw [hz]; simp only [Pi.add_apply]; linarith
  · rw [hz]; simp only [Pi.add_apply]
    rw [show K * -z = -K * z by ring]; linarith

section AverageProps

variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} {B : ℝ≥0 → Ω → ℝ}
  {μ σ r T : ℝ} {g : ℝ → ℝ}

lemma fkW_std (hB : IsBrownianReal B P) (hg : Continuous g) (t x : ℝ) :
    fkW P B μ σ r T g t x = Real.exp (-r * (T - t)) *
      ∫ z, g (x + μ * (T - t) + σ * (Real.sqrt (max (T - t) 0) * z)) ∂(gaussianReal 0 1) := by
  unfold fkW
  rw [fk_bridge hB _ (f := fun y => g (x + μ * (T - t) + σ * y)) (by fun_prop),
    fk_std_form _ (f := fun y => g (x + μ * (T - t) + σ * y)) (by fun_prop), Real.coe_toNNReal']

lemma fkW_continuous (hB : IsBrownianReal B P) (hg : Continuous g)
    (hg_growth : ∃ C : ℝ, ∃ k : ℕ, ∀ y, |g y| ≤ C * (1 + |y| ^ k)) :
    Continuous (fun p : ℝ × ℝ => fkW P B μ σ r T g p.1 p.2) := by
  obtain ⟨C, hC, hgC⟩ := fk_growth_exp hg_growth
  have he : (fun p : ℝ × ℝ => fkW P B μ σ r T g p.1 p.2) = fun p => Real.exp (-r * (T - p.1)) *
      ∫ z, g (p.2 + μ * (T - p.1) + σ * (Real.sqrt (max (T - p.1) 0) * z)) ∂(gaussianReal 0 1) := by
    funext p; exact fkW_std hB hg p.1 p.2
  rw [he]
  refine Continuous.mul (by fun_prop) (continuous_iff_continuousAt.2 fun p0 => ?_)
  set K1 := |p0.2| + 1 + |μ| * (|T - p0.1| + 1) with hK1
  set K2 := |σ| * Real.sqrt (|T - p0.1| + 1) with hK2
  refine continuousAt_of_dominated
    (bound := fun z => C * Real.exp K1 * Real.exp (K2 * |z|))
    (Eventually.of_forall fun p => by apply Continuous.aestronglyMeasurable; fun_prop) ?_
    ((fk_integrable_exp_abs K2).const_mul _) (ae_of_all _ fun z => by fun_prop)
  filter_upwards [Metric.ball_mem_nhds p0 one_pos] with p hp
  refine ae_of_all _ fun z => ?_
  rw [Metric.mem_ball, Prod.dist_eq, max_lt_iff, Real.dist_eq, Real.dist_eq] at hp
  rw [Real.norm_eq_abs]
  refine (hgC _).trans ?_
  rw [mul_assoc, ← Real.exp_add]
  apply mul_le_mul_of_nonneg_left _ hC
  apply Real.exp_le_exp.2
  have hx : |p.2| ≤ |p0.2| + 1 := by
    have := abs_sub_abs_le_abs_sub p.2 p0.2; linarith
  have ht : |T - p.1| ≤ |T - p0.1| + 1 := by
    have := abs_sub_abs_le_abs_sub (T - p.1) (T - p0.1)
    rw [show T - p.1 - (T - p0.1) = -(p.1 - p0.1) by ring, abs_neg] at this; linarith
  have hs : Real.sqrt (max (T - p.1) 0) ≤ Real.sqrt (|T - p0.1| + 1) := by
    apply Real.sqrt_le_sqrt
    exact max_le ((le_abs_self _).trans ht) (by positivity)
  have hsn := Real.sqrt_nonneg (max (T - p.1) 0)
  calc |p.2 + μ * (T - p.1) + σ * (Real.sqrt (max (T - p.1) 0) * z)|
      ≤ |p.2| + |μ| * |T - p.1| + |σ| * (Real.sqrt (max (T - p.1) 0) * |z|) := by
        refine (abs_add_le _ _).trans ?_
        rw [abs_mul σ, abs_mul, abs_of_nonneg hsn]
        gcongr
        refine (abs_add_le _ _).trans ?_
        rw [abs_mul]
    _ ≤ K1 + K2 * |z| := by
        rw [hK1, hK2]
        have h1 : |μ| * |T - p.1| ≤ |μ| * (|T - p0.1| + 1) :=
          mul_le_mul_of_nonneg_left ht (abs_nonneg _)
        have h2 : |σ| * (Real.sqrt (max (T - p.1) 0) * |z|) ≤
            |σ| * Real.sqrt (|T - p0.1| + 1) * |z| := by
          rw [← mul_assoc]
          apply mul_le_mul_of_nonneg_right _ (abs_nonneg _)
          exact mul_le_mul_of_nonneg_left hs (abs_nonneg _)
        linarith

lemma fkW_growth (hB : IsBrownianReal B P) (hg : Continuous g)
    (hg_growth : ∃ C : ℝ, ∃ k : ℕ, ∀ y, |g y| ≤ C * (1 + |y| ^ k)) :
    ∃ C', ∀ t ∈ Set.Icc 0 T, ∀ x, |fkW P B μ σ r T g t x| ≤ C' * Real.exp |x| := by
  obtain ⟨C, hC, hgC⟩ := fk_growth_exp hg_growth
  set I := ∫ z, Real.exp (|σ| * Real.sqrt T * |z|) ∂(gaussianReal 0 1) with hI
  refine ⟨Real.exp (|r| * T) * (C * Real.exp (|μ| * T) * I), fun t ht x => ?_⟩
  obtain ⟨ht0, htT⟩ := ht
  rw [fkW_std hB hg, abs_mul, abs_of_pos (Real.exp_pos _)]
  have hE : Real.exp (-r * (T - t)) ≤ Real.exp (|r| * T) := by
    apply Real.exp_le_exp.2
    have := neg_abs_le r
    have h1 : 0 ≤ T - t := by linarith
    nlinarith [abs_nonneg r]
  have hInt : |∫ z, g (x + μ * (T - t) + σ * (Real.sqrt (max (T - t) 0) * z)) ∂(gaussianReal 0 1)|
      ≤ C * Real.exp (|μ| * T) * I * Real.exp |x| := by
    rw [← Real.norm_eq_abs]
    have hb : ∀ z, ‖g (x + μ * (T - t) + σ * (Real.sqrt (max (T - t) 0) * z))‖ ≤
        C * Real.exp (|μ| * T) * Real.exp |x| * Real.exp (|σ| * Real.sqrt T * |z|) := by
      intro z
      rw [Real.norm_eq_abs]
      refine (hgC _).trans ?_
      rw [mul_assoc C, mul_assoc C, ← Real.exp_add, ← Real.exp_add]
      apply mul_le_mul_of_nonneg_left _ hC
      apply Real.exp_le_exp.2
      have hm : max (T - t) 0 = T - t := max_eq_left (by linarith)
      rw [hm]
      have hs : Real.sqrt (T - t) ≤ Real.sqrt T := Real.sqrt_le_sqrt (by linarith)
      have hsn := Real.sqrt_nonneg (T - t)
      have e1 : |x + μ * (T - t) + σ * (Real.sqrt (T - t) * z)| ≤
          |x| + |μ| * (T - t) + |σ| * (Real.sqrt (T - t) * |z|) := by
        refine (abs_add_le _ _).trans ?_
        rw [abs_mul σ, abs_mul, abs_of_nonneg hsn]
        gcongr
        refine (abs_add_le _ _).trans ?_
        rw [abs_mul, abs_of_nonneg (by linarith : 0 ≤ T - t)]
      have e2 : |μ| * (T - t) ≤ |μ| * T := mul_le_mul_of_nonneg_left (by linarith) (abs_nonneg _)
      have e3 : |σ| * (Real.sqrt (T - t) * |z|) ≤ |σ| * Real.sqrt T * |z| := by
        rw [← mul_assoc]
        apply mul_le_mul_of_nonneg_right _ (abs_nonneg _)
        exact mul_le_mul_of_nonneg_left hs (abs_nonneg _)
      linarith
    refine (norm_integral_le_of_norm_le ((fk_integrable_exp_abs _).const_mul _)
      (ae_of_all _ hb)).trans ?_
    rw [integral_const_mul]
    ring_nf; rfl
  have hI0 : 0 ≤ I := integral_nonneg fun z => (Real.exp_pos _).le
  calc Real.exp (-r * (T - t)) * |∫ z, g (x + μ * (T - t) + σ * (Real.sqrt (max (T - t) 0) * z))
        ∂(gaussianReal 0 1)|
      ≤ Real.exp (|r| * T) * (C * Real.exp (|μ| * T) * I * Real.exp |x|) :=
        mul_le_mul hE hInt (abs_nonneg _) (Real.exp_pos _).le
    _ = _ := by ring

lemma fkW_terminal (hB : IsBrownianReal B P) (hg : Continuous g) (x : ℝ) :
    fkW P B μ σ r T g T x = g x := by
  rw [fkW_std hB hg]
  simp

end AverageProps

/-- One-sided first-derivative test: largest at `a` among the later times of `(a, b)`. -/
lemma fk_deriv_nonpos_of_right_max {f : ℝ → ℝ} {d a b : ℝ} (hab : a < b) (hd : HasDerivAt f d a)
    (hmax : ∀ s ∈ Set.Ioo a b, f s ≤ f a) : d ≤ 0 := by
  have hsl := (hasDerivAt_iff_tendsto_slope_left_right.mp hd).2
  refine le_of_tendsto hsl ?_
  filter_upwards [Ioo_mem_nhdsGT hab] with s hs
  rw [slope_def_field]
  exact div_nonpos_of_nonpos_of_nonneg (by linarith [hmax s hs]) (by linarith [hs.1])

/-- Second-derivative test at an inside maximum. -/
lemma fk_second_deriv_nonpos_of_max (f f' : ℝ → ℝ) (a b x₀ c : ℝ) (hx₀ : x₀ ∈ Set.Ioo a b)
    (hf : ∀ y ∈ Set.Ioo a b, HasDerivAt f (f' y) y) (hc : HasDerivAt f' c x₀)
    (hmax : ∀ y ∈ Set.Ioo a b, f y ≤ f x₀) : c ≤ 0 := by
  by_contra hpos
  push Not at hpos
  have hloc : IsLocalMax f x₀ :=
    Filter.mem_of_superset (Ioo_mem_nhds hx₀.1 hx₀.2) fun y hy => hmax y hy
  have h0 : f' x₀ = 0 := IsLocalMax.hasDerivAt_eq_zero hloc (hf x₀ hx₀)
  have hsl := (hasDerivAt_iff_tendsto_slope_left_right.mp hc).2
  have hev : ∀ᶠ y in nhdsWithin x₀ (Set.Ioi x₀), 0 < slope f' x₀ y :=
    hsl.eventually (Ioi_mem_nhds hpos)
  have hev2 : ∀ᶠ y in nhdsWithin x₀ (Set.Ioi x₀), y < b :=
    nhdsWithin_le_nhds (Iio_mem_nhds hx₀.2)
  obtain ⟨u, hu, hsub⟩ := mem_nhdsGT_iff_exists_Ioo_subset.mp (hev.and hev2)
  have hpos' : ∀ y ∈ Set.Ioo x₀ u, 0 < f' y := by
    intro y hy
    have h := (hsub hy).1
    rw [slope_def_field, h0, sub_zero] at h
    exact (div_pos_iff_of_pos_right (by linarith [hy.1])).mp h
  have hu' : x₀ < u := hu
  set y₁ := (x₀ + u) / 2 with hy₁_def
  have hy₁ : y₁ ∈ Set.Ioo x₀ u := ⟨by rw [hy₁_def]; linarith, by rw [hy₁_def]; linarith⟩
  have hy₁b : y₁ < b := (hsub hy₁).2
  have hsubI : Set.Icc x₀ y₁ ⊆ Set.Ioo a b :=
    fun z hz => ⟨by linarith [hz.1, hx₀.1], by linarith [hz.2]⟩
  have hcont : ContinuousOn f (Set.Icc x₀ y₁) := fun z hz =>
    (hf z (hsubI hz)).continuousAt.continuousWithinAt
  obtain ⟨ξ, hξ, hξeq⟩ := exists_hasDerivAt_eq_slope f f' hy₁.1 hcont
    (fun z hz => hf z (hsubI (Set.Ioo_subset_Icc_self hz)))
  have hξpos : 0 < f' ξ := hpos' ξ ⟨hξ.1, hξ.2.trans hy₁.2⟩
  rw [hξeq] at hξpos
  have : 0 < f y₁ - f x₀ := (div_pos_iff_of_pos_right (by linarith [hy₁.1])).mp hξpos
  linarith [hmax y₁ ⟨by linarith [hx₀.1, hy₁.1], hy₁b⟩]

/-- Maximum principle for the backward equation on `[0, T] × ℝ`, for functions that grow at
most like `e^{|x|}` and vanish at `T`. -/
lemma fk_max_principle {T μ σ r : ℝ} (hT : 0 < T) {v vt vx vxx : ℝ → ℝ → ℝ}
    (hcont : ContinuousOn (fun p : ℝ × ℝ => v p.1 p.2) (Set.Icc 0 T ×ˢ Set.univ))
    (hvT : ∀ x, v T x = 0)
    (ht : ∀ t ∈ Set.Ioo 0 T, ∀ x, HasDerivAt (fun s => v s x) (vt t x) t)
    (hx : ∀ t ∈ Set.Ioo 0 T, ∀ x, HasDerivAt (fun y => v t y) (vx t x) x)
    (hxx : ∀ t ∈ Set.Ioo 0 T, ∀ x, HasDerivAt (fun y => vx t y) (vxx t x) x)
    (hpde : ∀ t ∈ Set.Ioo 0 T, ∀ x,
      vt t x + μ * vx t x + 1 / 2 * σ ^ 2 * vxx t x - r * v t x = 0)
    (hgrow : ∃ C, ∀ t ∈ Set.Icc 0 T, ∀ x, |v t x| ≤ C * Real.exp |x|) :
    ∀ t ∈ Set.Icc 0 T, ∀ x, v t x ≤ 0 := by
  obtain ⟨C, hC⟩ := hgrow
  have hC0 : 0 ≤ C := by
    have := hC T ⟨hT.le, le_rfl⟩ 0
    simp only [abs_zero, Real.exp_zero, mul_one] at this
    linarith [abs_nonneg (v T 0)]
  set a := |r| + 1 with ha
  set c := 2 * |μ| + 2 * σ ^ 2 with hc
  have hc0 : 0 ≤ c := by positivity
  have hθle : ∀ t ∈ Set.Icc 0 T, Real.exp (-a * (T - t)) ≤ 1 := fun t ht => by
    apply Real.exp_le_one_iff.2
    have : 0 ≤ T - t := by linarith [ht.2]
    have : 0 ≤ a := by positivity
    nlinarith
  have hEge : ∀ t ∈ Set.Icc 0 T, 1 ≤ Real.exp (c * (T - t)) := fun t ht => by
    apply Real.one_le_exp
    have : 0 ≤ T - t := by linarith [ht.2]
    positivity
  have key : ∀ t1 ∈ Set.Ioc 0 T, ∀ x1, ∀ ε > 0,
      Real.exp (-a * (T - t1)) * v t1 x1 ≤
        ε * (Real.exp (c * (T - t1)) * Real.cosh (2 * x1)) := by
    intro t1 ht1 x1 ε hε
    by_contra hcon
    push Not at hcon
    set φ : ℝ × ℝ → ℝ := fun p => Real.exp (-a * (T - p.1)) * v p.1 p.2 -
      ε * (Real.exp (c * (T - p.1)) * Real.cosh (2 * p.2)) with hφ
    have hφ1 : 0 < φ (t1, x1) := by simp only [hφ]; linarith
    set R := |x1| + 2 * C / ε + 1 with hR
    have h2C : 0 ≤ 2 * C / ε := by positivity
    set S := Set.Icc t1 T ×ˢ Set.Icc (-R) R with hS
    have hSc : IsCompact S := isCompact_Icc.prod isCompact_Icc
    have hmem1 : (t1, x1) ∈ S :=
      ⟨⟨le_rfl, ht1.2⟩, ⟨by linarith [neg_abs_le x1], by linarith [le_abs_self x1]⟩⟩
    have hSsub : S ⊆ Set.Icc 0 T ×ˢ Set.univ :=
      fun p hp => ⟨⟨by linarith [ht1.1, hp.1.1], hp.1.2⟩, trivial⟩
    have hφc : ContinuousOn φ S := by
      have h1 : ContinuousOn (fun p : ℝ × ℝ => v p.1 p.2) S := hcont.mono hSsub
      exact ((Continuous.continuousOn (by fun_prop)).mul h1).sub
        (Continuous.continuousOn (by fun_prop))
    obtain ⟨p, hpS, hpmax⟩ := hSc.exists_isMaxOn ⟨_, hmem1⟩ hφc
    have hp_pos : 0 < φ p := lt_of_lt_of_le hφ1 (hpmax hmem1)
    obtain ⟨⟨hpt1, hptT⟩, ⟨hpxl, hpxr⟩⟩ := hpS
    have hpIcc : p.1 ∈ Set.Icc 0 T := ⟨by linarith [ht1.1], hptT⟩
    -- the maximum is not at the final time
    have hpT : p.1 < T := by
      rcases lt_or_eq_of_le hptT with h | h
      · exact h
      · exfalso
        have : φ p ≤ 0 := by
          simp only [hφ]; rw [h, hvT]
          have := Real.cosh_pos (2 * p.2)
          have := Real.exp_pos (c * (T - T))
          nlinarith [mul_pos this (Real.cosh_pos (2 * p.2))]
        linarith
    -- the maximum is not on the side edges
    have hedge : ∀ t ∈ Set.Icc 0 T, ∀ x, |x| = R → φ (t, x) < 0 := by
      intro t ht x hx
      simp only [hφ]
      have hv := hC t ht x
      rw [hx] at hv
      have h1 : Real.exp (-a * (T - t)) * v t x ≤ C * Real.exp R := by
        calc Real.exp (-a * (T - t)) * v t x ≤ Real.exp (-a * (T - t)) * |v t x| :=
              mul_le_mul_of_nonneg_left (le_abs_self _) (Real.exp_pos _).le
          _ ≤ 1 * (C * Real.exp R) :=
              mul_le_mul (hθle t ht) hv (abs_nonneg _) zero_le_one
          _ = _ := one_mul _
      have hcosh : Real.exp (2 * R) / 2 < Real.cosh (2 * x) := by
        have : Real.cosh (2 * x) = Real.cosh (2 * R) := by
          rw [← Real.cosh_abs, abs_mul, abs_two, hx]
        rw [this, Real.cosh_eq]
        have := Real.exp_pos (-(2 * R))
        linarith
      have hR1 : 2 * C / ε < Real.exp R := by
        have := Real.add_one_le_exp R
        have : 0 ≤ |x1| := abs_nonneg _
        linarith
      have hER : 0 < Real.exp R := Real.exp_pos R
      have h2 : C * Real.exp R < ε * (Real.exp (2 * R) / 2) := by
        rw [show Real.exp (2 * R) = Real.exp R * Real.exp R by rw [← Real.exp_add]; ring_nf]
        rw [div_lt_iff₀ hε] at hR1
        nlinarith
      have h3 : ε * (Real.exp (2 * R) / 2) ≤
          ε * (Real.exp (c * (T - t)) * Real.cosh (2 * x)) := by
        apply mul_le_mul_of_nonneg_left _ hε.le
        have := hEge t ht
        have := Real.cosh_pos (2 * x)
        nlinarith
      linarith
    have hpx : p.2 ∈ Set.Ioo (-R) R := by
      constructor
      · rcases lt_or_eq_of_le hpxl with h | h
        · exact h
        · exfalso
          have hR0 : 0 ≤ R := by linarith [abs_nonneg x1]
          have := hedge p.1 hpIcc p.2 (by rw [← h, abs_neg, abs_of_nonneg hR0])
          linarith
      · rcases lt_or_eq_of_le hpxr with h | h
        · exact h
        · exfalso
          have hR0 : 0 ≤ R := by linarith [abs_nonneg x1]
          have := hedge p.1 hpIcc p.2 (by rw [h, abs_of_nonneg hR0])
          linarith
    have hts : p.1 ∈ Set.Ioo 0 T := ⟨lt_of_lt_of_le ht1.1 hpt1, hpT⟩
    set ts := p.1 with hts_def
    set xs := p.2 with hxs_def
    have hp_eq : p = (ts, xs) := rfl
    set θ := Real.exp (-a * (T - ts)) with hθ
    set E := Real.exp (c * (T - ts)) with hE
    -- slope in time
    have hdt : HasDerivAt (fun s => φ (s, xs))
        (θ * (-a * (0 - 1)) * v ts xs + θ * vt ts xs -
          ε * (E * (c * (0 - 1)) * Real.cosh (2 * xs))) ts := by
      have hT1 : HasDerivAt (fun s : ℝ => T - s) (0 - 1) ts :=
        (hasDerivAt_const ts T).sub (hasDerivAt_id ts)
      exact ((((hT1.const_mul (-a)).exp).mul (ht ts hts xs)).sub
        ((((hT1.const_mul c).exp).mul_const (Real.cosh (2 * xs))).const_mul ε))
    have hdt0 := fk_deriv_nonpos_of_right_max hpT hdt (fun s hs => by
      have := hpmax (show (s, xs) ∈ S from ⟨⟨by linarith [hs.1], hs.2.le⟩, ⟨hpxl, hpxr⟩⟩)
      exact this)
    -- slopes in space
    have hdx : ∀ y, HasDerivAt (fun y => φ (ts, y))
        (θ * vx ts y - ε * (E * (Real.sinh (2 * y) * (2 * 1)))) y := fun y =>
      ((hx ts hts y).const_mul θ).sub
        (((((hasDerivAt_id y).const_mul 2).cosh).const_mul E).const_mul ε)
    have hdxx : HasDerivAt (fun y => θ * vx ts y - ε * (E * (Real.sinh (2 * y) * (2 * 1))))
        (θ * vxx ts xs - ε * (E * (Real.cosh (2 * xs) * (2 * 1) * (2 * 1)))) xs :=
      ((hxx ts hts xs).const_mul θ).sub
        ((((((hasDerivAt_id xs).const_mul 2).sinh).mul_const (2 * 1)).const_mul E).const_mul ε)
    have hmaxx : ∀ y ∈ Set.Ioo (-R) R, φ (ts, y) ≤ φ (ts, xs) := fun y hy =>
      hpmax (show (ts, y) ∈ S from ⟨⟨hpt1, hptT⟩, ⟨hy.1.le, hy.2.le⟩⟩)
    have hloc : IsLocalMax (fun y => φ (ts, y)) xs :=
      Filter.mem_of_superset (Ioo_mem_nhds hpx.1 hpx.2) fun y hy => hmaxx y hy
    have hx0 := IsLocalMax.hasDerivAt_eq_zero hloc (hdx xs)
    have hxx0 := fk_second_deriv_nonpos_of_max _ _ (-R) R xs _ hpx (fun y _ => hdx y) hdxx hmaxx
    -- combine with the equation
    have hpde' := hpde ts hts xs
    have hsinh : μ * Real.sinh (2 * xs) ≤ |μ| * Real.cosh (2 * xs) := by
      have h1 : |Real.sinh (2 * xs)| ≤ Real.cosh (2 * xs) := by
        have hsq := Real.cosh_sq (2 * xs)
        have hpos := Real.cosh_pos (2 * xs)
        rw [abs_le]; constructor <;> nlinarith [sq_nonneg (Real.sinh (2 * xs) + Real.cosh (2 * xs)),
          sq_nonneg (Real.sinh (2 * xs) - Real.cosh (2 * xs))]
      calc μ * Real.sinh (2 * xs) ≤ |μ * Real.sinh (2 * xs)| := le_abs_self _
        _ = |μ| * |Real.sinh (2 * xs)| := abs_mul _ _
        _ ≤ |μ| * Real.cosh (2 * xs) := mul_le_mul_of_nonneg_left h1 (abs_nonneg _)
    have hθv : 0 < θ * v ts xs := by
      have hpp : 0 < φ (ts, xs) := hp_pos
      simp only [hφ] at hpp
      have : 0 < ε * (E * Real.cosh (2 * xs)) := by
        have := Real.cosh_pos (2 * xs); positivity
      linarith
    have hsum : (θ * (-a * (0 - 1)) * v ts xs + θ * vt ts xs -
          ε * (E * (c * (0 - 1)) * Real.cosh (2 * xs))) +
        μ * (θ * vx ts xs - ε * (E * (Real.sinh (2 * xs) * (2 * 1)))) +
        1 / 2 * σ ^ 2 * (θ * vxx ts xs - ε * (E * (Real.cosh (2 * xs) * (2 * 1) * (2 * 1)))) =
        (a + r) * (θ * v ts xs) +
          ε * E * (2 * (|μ| * Real.cosh (2 * xs) - μ * Real.sinh (2 * xs))) := by
      rw [hc]; linear_combination θ * hpde'
    have hnn : 0 ≤ ε * E * (2 * (|μ| * Real.cosh (2 * xs) - μ * Real.sinh (2 * xs))) := by
      have : 0 ≤ |μ| * Real.cosh (2 * xs) - μ * Real.sinh (2 * xs) := by linarith
      positivity
    have har : 1 ≤ a + r := by rw [ha]; linarith [neg_abs_le r]
    have hσxx : 1 / 2 * σ ^ 2 *
        (θ * vxx ts xs - ε * (E * (Real.cosh (2 * xs) * (2 * 1) * (2 * 1)))) ≤ 0 :=
      mul_nonpos_of_nonneg_of_nonpos (by positivity) hxx0
    rw [hx0, mul_zero, add_zero] at hsum
    nlinarith
  -- the solution is at most `0` after time `0`
  have hIoc : ∀ t ∈ Set.Ioc 0 T, ∀ x, v t x ≤ 0 := by
    intro t ht x
    by_contra h
    push Not at h
    have hθp : 0 < Real.exp (-a * (T - t)) := Real.exp_pos _
    have hΨ : 0 < Real.exp (c * (T - t)) * Real.cosh (2 * x) :=
      mul_pos (Real.exp_pos _) (Real.cosh_pos _)
    have hpos : 0 < Real.exp (-a * (T - t)) * v t x := mul_pos hθp h
    have := key t ht x (Real.exp (-a * (T - t)) * v t x /
      (2 * (Real.exp (c * (T - t)) * Real.cosh (2 * x)))) (by positivity)
    rw [div_mul_eq_mul_div, le_div_iff₀ (by positivity)] at this
    nlinarith
  intro t ht x
  rcases eq_or_lt_of_le ht.1 with h0 | hpos
  · subst h0
    have hcw : ContinuousWithinAt (fun s => v s x) (Set.Icc 0 T) 0 := by
      have h1 := hcont (0, x) ⟨⟨le_rfl, hT.le⟩, trivial⟩
      exact h1.comp (f := fun s : ℝ => (s, x)) (Continuous.continuousWithinAt (by fun_prop))
        (fun s hs => ⟨hs, trivial⟩)
    have htend := (hcw.mono Set.Ioo_subset_Icc_self).tendsto
    rw [nhdsWithin_Ioo_eq_nhdsGT hT] at htend
    refine le_of_tendsto htend ?_
    filter_upwards [Ioo_mem_nhdsGT hT] with s hs
    exact hIoc s ⟨hs.1, hs.2.le⟩ x
  · exact hIoc t ⟨hpos, ht.2⟩ x

/-- Two-sided version: the only such solution with zero final values is zero. -/
lemma fk_zero_of_pde {T μ σ r : ℝ} (hT : 0 < T) {v vt vx vxx : ℝ → ℝ → ℝ}
    (hcont : ContinuousOn (fun p : ℝ × ℝ => v p.1 p.2) (Set.Icc 0 T ×ˢ Set.univ))
    (hvT : ∀ x, v T x = 0)
    (ht : ∀ t ∈ Set.Ioo 0 T, ∀ x, HasDerivAt (fun s => v s x) (vt t x) t)
    (hx : ∀ t ∈ Set.Ioo 0 T, ∀ x, HasDerivAt (fun y => v t y) (vx t x) x)
    (hxx : ∀ t ∈ Set.Ioo 0 T, ∀ x, HasDerivAt (fun y => vx t y) (vxx t x) x)
    (hpde : ∀ t ∈ Set.Ioo 0 T, ∀ x,
      vt t x + μ * vx t x + 1 / 2 * σ ^ 2 * vxx t x - r * v t x = 0)
    (hgrow : ∃ C, ∀ t ∈ Set.Icc 0 T, ∀ x, |v t x| ≤ C * Real.exp |x|) :
    ∀ t ∈ Set.Icc 0 T, ∀ x, v t x = 0 := by
  have h1 := fk_max_principle hT hcont hvT ht hx hxx hpde hgrow
  obtain ⟨C, hC⟩ := hgrow
  have h2 := fk_max_principle (v := fun t x => -v t x) (vt := fun t x => -vt t x)
    (vx := fun t x => -vx t x) (vxx := fun t x => -vxx t x) (μ := μ) (σ := σ) (r := r) hT
    hcont.neg (fun x => by simp [hvT x]) (fun t h x => (ht t h x).neg) (fun t h x => (hx t h x).neg)
    (fun t h x => (hxx t h x).neg) (fun t h x => by have := hpde t h x; linarith)
    ⟨C, fun t h x => by rw [abs_neg]; exact hC t h x⟩
  intro t h x
  have a := h1 t h x
  have b : -v t x ≤ 0 := h2 t h x
  linarith

/-- Chain rule along a straight line in `(t, x)`, from a time slope at one point and a space
slope that is continuous in both variables. -/
lemma fk_char_hasDerivAt {u : ℝ → ℝ → ℝ} {T μ s y : ℝ} (hs : s ∈ Set.Ioo 0 T)
    (hut : DifferentiableAt ℝ (fun s' => u s' y) s)
    (hux : ∀ s' ∈ Set.Ioo 0 T, Differentiable ℝ (u s'))
    (hcont : ContinuousAt (fun p : ℝ × ℝ => deriv (u p.1) p.2) (s, y)) :
    HasDerivAt (fun s' => u s' (y + μ * (s' - s)))
      (deriv (fun s' => u s' y) s + μ * deriv (u s) y) s := by
  rw [hasDerivAt_iff_isLittleO]
  have h2 := hasDerivAt_iff_isLittleO.1 hut.hasDerivAt
  set ux0 := deriv (u s) y with hux0
  have h1 : (fun s' => u s' (y + μ * (s' - s)) - u s' y - (s' - s) • (μ * ux0)) =o[𝓝 s]
      (fun s' => s' - s) := by
    rw [Asymptotics.isLittleO_iff]
    intro ε hε
    have hμ1 : 0 < |μ| + 1 := by positivity
    obtain ⟨δ, hδ, hδc⟩ := Metric.continuousAt_iff.1 hcont (ε / (|μ| + 1)) (by positivity)
    filter_upwards [Metric.ball_mem_nhds s (lt_min hδ (div_pos hδ hμ1)),
      Ioo_mem_nhds hs.1 hs.2] with s' hs' hs'T
    rw [Metric.mem_ball, Real.dist_eq, lt_min_iff] at hs'
    obtain ⟨hh1, hh2⟩ := hs'
    have hμh : |μ * (s' - s)| < δ := by
      rw [abs_mul]
      rw [lt_div_iff₀ hμ1] at hh2
      nlinarith [abs_nonneg μ, abs_nonneg (s' - s)]
    have hF : ∀ z ∈ Metric.ball y δ, HasDerivWithinAt (fun z => u s' z - z * ux0)
        (deriv (u s') z - ux0) (Metric.ball y δ) z := fun z _ => by
      have h : HasDerivAt (fun z => u s' z - z * ux0) (deriv (u s') z - 1 * ux0) z :=
        (hux s' hs'T z).hasDerivAt.sub ((hasDerivAt_id z).mul_const ux0)
      rw [show deriv (u s') z - ux0 = deriv (u s') z - 1 * ux0 by ring]
      exact h.hasDerivWithinAt
    have hbound : ∀ z ∈ Metric.ball y δ, ‖deriv (u s') z - ux0‖ ≤ ε / (|μ| + 1) := by
      intro z hz
      have hd : dist (s', z) (s, y) < δ := by
        rw [Prod.dist_eq, max_lt_iff, Real.dist_eq]
        exact ⟨hh1, hz⟩
      have := hδc hd
      rw [Real.dist_eq] at this
      rw [Real.norm_eq_abs]
      exact this.le
    have hmem : y + μ * (s' - s) ∈ Metric.ball y δ := by
      rw [Metric.mem_ball, Real.dist_eq, add_sub_cancel_left]; exact hμh
    have hmvt := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le hF hbound (convex_ball y δ)
      (Metric.mem_ball_self hδ) hmem
    rw [add_sub_cancel_left] at hmvt
    have he : u s' (y + μ * (s' - s)) - (y + μ * (s' - s)) * ux0 - (u s' y - y * ux0) =
        u s' (y + μ * (s' - s)) - u s' y - (s' - s) • (μ * ux0) := by
      rw [smul_eq_mul]; ring
    rw [he] at hmvt
    refine hmvt.trans ?_
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_mul]
    have : ε / (|μ| + 1) * |μ| ≤ ε := by
      rw [div_mul_eq_mul_div, div_le_iff₀ hμ1]; nlinarith [abs_nonneg μ]
    nlinarith [abs_nonneg (s' - s)]
  refine (h1.add h2).congr_left (fun s' => ?_)
  simp only [sub_self, mul_zero, add_zero, smul_eq_mul]
  ring

/-- The standard bell density. -/
lemma fk_pdf_eq (z : ℝ) :
    gaussianPDFReal 0 1 z = (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-z ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma fk_cdf_eq_add (x : ℝ) :
    cdf (gaussianReal 0 1) x = cdf (gaussianReal 0 1) 0 +
      ∫ y in (0:ℝ)..x, gaussianPDFReal 0 1 y := by
  have hi : Integrable (gaussianPDFReal 0 1) := integrable_gaussianPDFReal _ _
  have h : ∀ x, cdf (gaussianReal 0 1) x = ∫ y in Set.Iic x, gaussianPDFReal 0 1 y := by
    intro x
    rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
      ENNReal.toReal_ofReal]
    exact setIntegral_nonneg measurableSet_Iic (fun y _ => gaussianPDFReal_nonneg _ _ _)
  rw [← intervalIntegral.integral_Iic_sub_Iic hi.integrableOn hi.integrableOn, h, h]
  ring

lemma fk_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  have : gaussianPDFReal 0 1 = fun z => (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-z ^ 2 / 2) :=
    funext fk_pdf_eq
  rw [this]; fun_prop

lemma fk_hasDerivAt_cdf (x : ℝ) :
    HasDerivAt (fun z => cdf (gaussianReal 0 1) z) (gaussianPDFReal 0 1 x) x := by
  have h := (fk_continuous_pdf.integral_hasStrictDerivAt 0 x).hasDerivAt.const_add
    (cdf (gaussianReal 0 1) 0)
  have he : (fun z => cdf (gaussianReal 0 1) z) =
      fun x => cdf (gaussianReal 0 1) 0 + ∫ y in (0:ℝ)..x, gaussianPDFReal 0 1 y :=
    funext fk_cdf_eq_add
  rw [he]; exact h

lemma fk_hasDerivAt_pdf (x : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-x * gaussianPDFReal 0 1 x) x := by
  have : gaussianPDFReal 0 1 = fun z => (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-z ^ 2 / 2) :=
    funext fk_pdf_eq
  rw [this]
  have h0 : HasDerivAt (fun z : ℝ => -z ^ 2 / 2) (-x) x := by
    have := (hasDerivAt_pow 2 x).const_mul (-1 / 2 : ℝ)
    convert this using 1
    · funext z; ring
    · simp; ring
  have h := (h0.exp).const_mul (Real.sqrt (2 * Real.pi))⁻¹
  refine h.congr_deriv ?_
  ring

lemma fk_contDiff_cdf : ContDiff ℝ 2 (fun z => cdf (gaussianReal 0 1) z) := by
  rw [show (2 : WithTop ℕ∞) = 1 + 1 from rfl, contDiff_succ_iff_deriv]
  refine ⟨fun x => (fk_hasDerivAt_cdf x).differentiableAt, by simp, ?_⟩
  have : deriv (fun z => cdf (gaussianReal 0 1) z) =
      fun z => (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-z ^ 2 / 2) := by
    funext z; rw [(fk_hasDerivAt_cdf z).deriv, fk_pdf_eq]
  rw [this]; fun_prop

/-- Slope in `x` of `w τ x = x (2 N(1/(x√τ)) - 1)`. -/
lemma fk_w_hasDerivAt_x (τ x : ℝ) (hτ : 0 < τ) (hx : 0 < x) :
    HasDerivAt (fun y => y * (2 * cdf (gaussianReal 0 1) (1 / (y * Real.sqrt τ)) - 1))
      (2 * cdf (gaussianReal 0 1) (1 / (x * Real.sqrt τ)) - 1
        - 2 * (1 / (x * Real.sqrt τ)) * gaussianPDFReal 0 1 (1 / (x * Real.sqrt τ))) x := by
  have hs : 0 < Real.sqrt τ := Real.sqrt_pos.2 hτ
  have hxs : x * Real.sqrt τ ≠ 0 := by positivity
  have ha : HasDerivAt (fun y => 1 / (y * Real.sqrt τ))
      (-(1 * Real.sqrt τ) / (x * Real.sqrt τ) ^ 2) x :=
    ((hasDerivAt_const x (1:ℝ)).div ((hasDerivAt_id x).mul_const (Real.sqrt τ)) hxs).congr_deriv
      (by simp)
  have h := (hasDerivAt_id x).mul
    ((((fk_hasDerivAt_cdf (1 / (x * Real.sqrt τ))).comp x ha).const_mul 2).sub_const 1)
  refine h.congr_deriv ?_
  simp only [Function.comp_def, id]
  field_simp
  ring

lemma fk_w1_hasDerivAt_x (τ x : ℝ) (hτ : 0 < τ) (hx : 0 < x) :
    HasDerivAt (fun y => 2 * cdf (gaussianReal 0 1) (1 / (y * Real.sqrt τ)) - 1
        - 2 * (1 / (y * Real.sqrt τ)) * gaussianPDFReal 0 1 (1 / (y * Real.sqrt τ)))
      (-2 * (1 / (x * Real.sqrt τ)) ^ 3 * gaussianPDFReal 0 1 (1 / (x * Real.sqrt τ)) / x) x := by
  have hs : 0 < Real.sqrt τ := Real.sqrt_pos.2 hτ
  have hxs : x * Real.sqrt τ ≠ 0 := by positivity
  have ha : HasDerivAt (fun y => 1 / (y * Real.sqrt τ))
      (-(1 * Real.sqrt τ) / (x * Real.sqrt τ) ^ 2) x :=
    ((hasDerivAt_const x (1:ℝ)).div ((hasDerivAt_id x).mul_const (Real.sqrt τ)) hxs).congr_deriv
      (by simp)
  have h1 := (((fk_hasDerivAt_cdf (1 / (x * Real.sqrt τ))).comp x ha).const_mul 2).sub_const 1
  have h2 := (ha.const_mul 2).mul ((fk_hasDerivAt_pdf (1 / (x * Real.sqrt τ))).comp x ha)
  have h := h1.sub h2
  refine h.congr_deriv ?_
  simp only [Function.comp_def]
  field_simp
  ring

#print axioms fk_growth_exp
#print axioms fkK_nonneg
#print axioms fkK_continuous
#print axioms fkK_hasDerivAt
#print axioms fkK_bound
#print axioms fk_exp_shift_le
#print axioms fk_integrable_dom
#print axioms fk_dom_bound
#print axioms fk_integrable_kernel
#print axioms fk_hasDerivAt_x
#print axioms fk_Qt_bound
#print axioms fk_hasDerivAt_t
#print axioms fk_bridge
#print axioms fk_std_form
#print axioms fk_kernel_form
#print axioms fkW_kernel
#print axioms fkW_zero_vol
#print axioms fkW_derivs
#print axioms fk_poly_le_exp
#print axioms fk_integrable_exp_abs
#print axioms fkW_std
#print axioms fkW_continuous
#print axioms fkW_growth
#print axioms fkW_terminal
#print axioms fk_deriv_nonpos_of_right_max
#print axioms fk_second_deriv_nonpos_of_max
#print axioms fk_max_principle
#print axioms fk_zero_of_pde
#print axioms fk_char_hasDerivAt
#print axioms fk_pdf_eq
#print axioms fk_cdf_eq_add
#print axioms fk_continuous_pdf
#print axioms fk_hasDerivAt_cdf
#print axioms fk_hasDerivAt_pdf
#print axioms fk_contDiff_cdf
#print axioms fk_w_hasDerivAt_x
#print axioms fk_w1_hasDerivAt_x

/-! The diffusion here is `dX = μ dt + σ dW` with constant `μ`, `σ` and a constant rate `r`
(Mathlib has Brownian motion but no stochastic integrals, so the card's general `μ(x, t)`,
`σ(x, t)` cannot be stated). Started from `x` at time `t`, its value at `T` is
`x + μ (T - t) + σ (W_T - W_t)`, and `W_T - W_t` has the law of `B (T - t)`.
So `E[e^{-r(T-t)} g(X_T) | X_t = x] = e^{-r(T-t)} ∫ g(x + μ (T - t) + σ B_{T-t}) dP`. -/

/-- **Average to equation.** For a diffusion with drift `μ` and kick size `σ`, a continuous
payoff `g` of at most polynomial growth and a discount rate `r`, let `u(t, x)` be the average
of the discounted payoff `e^{-r(T-t)} g(X_T)` over the paths that start at `x` at time `t`.
If `u` is smooth enough for Ito's lemma (one slope in time, two in space, all continuous before
`T`), then it solves the backward equation `u_t + μ u_x + ½ σ² u_xx - r u = 0` for `t < T`. -/
theorem average_solves_backward_equation
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (B : ℝ≥0 → Ω → ℝ) (hB : IsBrownianReal B P)
    (μ σ r T : ℝ) (g : ℝ → ℝ) (hg : Continuous g)
    (hg_growth : ∃ C : ℝ, ∃ k : ℕ, ∀ y, |g y| ≤ C * (1 + |y| ^ k))
    (u : ℝ → ℝ → ℝ)
    (hu : ∀ t x, u t x =
      Real.exp (-r * (T - t)) * ∫ ω, g (x + μ * (T - t) + σ * B (T - t).toNNReal ω) ∂P)
    (hu_t : ∀ t < T, ∀ x, DifferentiableAt ℝ (fun s => u s x) t)
    (hu_x : ∀ t < T, ContDiff ℝ 2 (u t))
    (hu_t_cont : ContinuousOn (fun p : ℝ × ℝ => deriv (fun s => u s p.2) p.1) {p | p.1 < T})
    (hu_x_cont : ContinuousOn (fun p : ℝ × ℝ => deriv (u p.1) p.2) {p | p.1 < T})
    (hu_xx_cont : ContinuousOn (fun p : ℝ × ℝ => deriv (deriv (u p.1)) p.2) {p | p.1 < T}) :
    ∀ t < T, ∀ x,
      deriv (fun s => u s x) t + μ * deriv (u t) x
        + 1 / 2 * σ ^ 2 * deriv (deriv (u t)) x - r * u t x = 0 := by
  intro t ht x
  have hu' : u = fun t x => fkW P B μ σ r T g t x := by
    funext t x; rw [hu]; rfl
  by_cases hσ : σ = 0
  · subst hσ
    have hu0 : ∀ t x, u t x = Real.exp (-r * (T - t)) * g (x + μ * (T - t)) := fun t x => by
      rw [hu']; exact fkW_zero_vol hB hg t x
    have hgd : ∀ y, DifferentiableAt ℝ g y := by
      intro y
      have hd : Differentiable ℝ (u t) := (hu_x t ht).differentiable (by norm_num)
      have : g = fun y => Real.exp (r * (T - t)) * u t (y - μ * (T - t)) := by
        funext y
        rw [hu0, ← mul_assoc, ← Real.exp_add]
        simp
      rw [this]
      exact ((hd _).comp y (differentiableAt_id.sub_const _)).const_mul _
    have hT : HasDerivAt (fun s => u s x)
        (Real.exp (-r * (T - t)) * (-r * (0 - 1)) * g (x + μ * (T - t)) +
          Real.exp (-r * (T - t)) * (deriv g (x + μ * (T - t)) * (0 + μ * (0 - 1)))) t := by
      have hc : HasDerivAt (fun s => T - s) (0 - 1) t := (hasDerivAt_const t T).sub (hasDerivAt_id t)
      have h := ((hc.const_mul (-r)).exp).mul
        ((hgd (x + μ * (T - t))).hasDerivAt.comp t ((hasDerivAt_const t x).add (hc.const_mul μ)))
      have he : (fun s => u s x) = fun s => Real.exp (-r * (T - s)) * g (x + μ * (T - s)) := by
        funext s; exact hu0 s x
      rw [he]; exact h
    have hX : HasDerivAt (u t) (Real.exp (-r * (T - t)) * (deriv g (x + μ * (T - t)) * (1 + 0))) x := by
      have he : u t = fun y => Real.exp (-r * (T - t)) * g (y + μ * (T - t)) := by
        funext y; exact hu0 t y
      rw [he]
      exact ((hgd _).hasDerivAt.comp x ((hasDerivAt_id x).add (hasDerivAt_const x _))).const_mul _
    rw [hT.deriv, hX.deriv, hu0]
    ring
  · obtain ⟨h1, h2, h3, h4⟩ := fkW_derivs (P := P) (B := B) (μ := μ) (r := r) hB hg hg_growth hσ ht x
    have e1 : deriv (fun s => u s x) t = fkWt μ σ r T g t x := by rw [hu']; exact h1.deriv
    have e2 : deriv (u t) = fun y => fkWx μ σ r T g t y := by
      rw [hu']; funext y; exact (h2 y).deriv
    have e3 : deriv (deriv (u t)) x = fkWxx μ σ r T g t x := by rw [e2]; exact (h3 x).deriv
    rw [e1, e3, e2, hu']
    exact h4

/-- **Equation to average.** Let `u` be continuous on `[0, T] × ℝ`, with one slope in time and
two in space, all continuous, before `T`; let it solve `u_t + μ u_x + ½ σ² u_xx - r u = 0` with
`u(T, x) = g(x)`, grow at most polynomially, and have finite energy: the average over the paths
from `x` at time `t` of `∫_t^T (σ u_x(v, X_v))² dv` is finite (this is what makes the kick part a
true martingale). Then `u(t, x)` is the average of the discounted payoff `e^{-r(T-t)} g(X_T)` over
the paths that start at `x` at time `t`. In particular the equation has only one such solution. -/
theorem backward_equation_solution_eq_average
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (B : ℝ≥0 → Ω → ℝ) (hB : IsBrownianReal B P)
    (μ σ r T : ℝ) (hT : 0 < T) (g : ℝ → ℝ) (hg : Continuous g)
    (hg_growth : ∃ C : ℝ, ∃ k : ℕ, ∀ y, |g y| ≤ C * (1 + |y| ^ k))
    (u : ℝ → ℝ → ℝ)
    (hu_cont : ContinuousOn (fun p : ℝ × ℝ => u p.1 p.2) (Set.Icc 0 T ×ˢ Set.univ))
    (hu_T : ∀ x, u T x = g x)
    (hu_t : ∀ t ∈ Set.Ioo 0 T, ∀ x, DifferentiableAt ℝ (fun s => u s x) t)
    (hu_x : ∀ t ∈ Set.Ioo 0 T, ContDiff ℝ 2 (u t))
    (hu_t_cont : ContinuousOn (fun p : ℝ × ℝ => deriv (fun s => u s p.2) p.1)
      (Set.Ioo 0 T ×ˢ Set.univ))
    (hu_x_cont : ContinuousOn (fun p : ℝ × ℝ => deriv (u p.1) p.2) (Set.Ioo 0 T ×ˢ Set.univ))
    (hu_xx_cont : ContinuousOn (fun p : ℝ × ℝ => deriv (deriv (u p.1)) p.2)
      (Set.Ioo 0 T ×ˢ Set.univ))
    (hpde : ∀ t ∈ Set.Ioo 0 T, ∀ x,
      deriv (fun s => u s x) t + μ * deriv (u t) x
        + 1 / 2 * σ ^ 2 * deriv (deriv (u t)) x - r * u t x = 0)
    (hu_growth : ∃ C : ℝ, ∃ k : ℕ, ∀ t ∈ Set.Icc 0 T, ∀ x, |u t x| ≤ C * (1 + |x| ^ k))
    (h_energy : ∀ t ∈ Set.Ico 0 T, ∀ x,
      ∫⁻ v in Set.Ioo t T, ∫⁻ ω,
        ENNReal.ofReal ((σ * deriv (u v) (x + μ * (v - t) + σ * B (v - t).toNNReal ω)) ^ 2) ∂P
        < ⊤) :
    ∀ t ∈ Set.Icc 0 T, ∀ x, u t x =
      Real.exp (-r * (T - t)) * ∫ ω, g (x + μ * (T - t) + σ * B (T - t).toNNReal ω) ∂P := by
  have hu_d : ∀ t ∈ Set.Ioo 0 T, Differentiable ℝ (u t) := fun t ht =>
    (hu_x t ht).differentiable (by norm_num)
  have hu_dd : ∀ t ∈ Set.Ioo 0 T, Differentiable ℝ (deriv (u t)) := fun t ht => by
    have := (contDiff_succ_iff_deriv.1 (show ContDiff ℝ (1 + 1) (u t) from hu_x t ht)).2.2
    exact this.differentiable (by norm_num)
  intro t ht x
  show u t x = fkW P B μ σ r T g t x
  by_cases hσ : σ = 0
  · subst hσ
    rw [fkW_zero_vol hB hg]
    rcases eq_or_lt_of_le ht.2 with hT' | hlt
    · subst hT'; simp [hu_T]
    · set h : ℝ → ℝ := fun s => Real.exp (-r * (s - t)) * u s (x + μ * (s - t)) with hh
      have hcont_h : ContinuousOn h (Set.Icc t T) := by
        have hc := hu_cont.comp (Continuous.continuousOn (f := fun s : ℝ => (s, x + μ * (s - t)))
          (s := Set.Icc t T) (by fun_prop)) (fun s hs => ⟨⟨le_trans ht.1 hs.1, hs.2⟩, trivial⟩)
        exact (Continuous.continuousOn (by fun_prop)).mul hc
      have hderiv : ∀ s ∈ Set.Ioo t T, HasDerivAt h 0 s := by
        intro s hs
        have hs0 : s ∈ Set.Ioo 0 T := ⟨lt_of_le_of_lt ht.1 hs.1, hs.2⟩
        have hc := fk_char_hasDerivAt (μ := μ) hs0 (hu_t s hs0 (x + μ * (s - t))) hu_d
          (hu_x_cont.continuousAt ((isOpen_Ioo.prod isOpen_univ).mem_nhds ⟨hs0, trivial⟩))
        have hfun : (fun s' => u s' (x + μ * (s - t) + μ * (s' - s))) =
            fun s' => u s' (x + μ * (s' - t)) := by
          funext s'; congr 1; ring
        rw [hfun] at hc
        have hE : HasDerivAt (fun s' => Real.exp (-r * (s' - t)))
            (Real.exp (-r * (s - t)) * (-r * (1 - 0))) s :=
          (((hasDerivAt_id s).sub (hasDerivAt_const s t)).const_mul (-r)).exp
        refine (hE.mul hc).congr_deriv ?_
        have := hpde s hs0 (x + μ * (s - t))
        simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero,
          zero_mul, add_zero] at this
        linear_combination Real.exp (-r * (s - t)) * this
      obtain ⟨ξ, hξ, hξeq⟩ := exists_hasDerivAt_eq_slope h (fun _ => 0) hlt hcont_h
        (fun s hs => hderiv s hs)
      have hTt : h T = h t := by
        have hne : T - t ≠ 0 := by linarith
        have := hξeq.symm
        rw [div_eq_zero_iff] at this
        rcases this with h0 | h0
        · linarith
        · exact absurd h0 hne
      simp only [hh, sub_self, mul_zero, Real.exp_zero, one_mul, add_zero, hu_T] at hTt
      rw [← hTt]
  · set W := fun t x => fkW P B μ σ r T g t x
    have hzero := fk_zero_of_pde hT (v := fun t x => u t x - W t x)
      (vt := fun t x => deriv (fun s => u s x) t - fkWt μ σ r T g t x)
      (vx := fun t x => deriv (u t) x - fkWx μ σ r T g t x)
      (vxx := fun t x => deriv (deriv (u t)) x - fkWxx μ σ r T g t x) (μ := μ) (σ := σ) (r := r)
      (hu_cont.sub (fkW_continuous hB hg hg_growth).continuousOn)
      (fun x => by simp only [W, hu_T, fkW_terminal hB hg, sub_self])
      (fun t ht x => (hu_t t ht x).hasDerivAt.sub
        (fkW_derivs (P := P) (B := B) (μ := μ) (r := r) hB hg hg_growth hσ ht.2 x).1)
      (fun t ht x => ((hu_d t ht) x).hasDerivAt.sub
        ((fkW_derivs (P := P) (B := B) (μ := μ) (r := r) hB hg hg_growth hσ ht.2 x).2.1 x))
      (fun t ht x => ((hu_dd t ht) x).hasDerivAt.sub
        ((fkW_derivs (P := P) (B := B) (μ := μ) (r := r) hB hg hg_growth hσ ht.2 x).2.2.1 x))
      (fun t ht x => by
        have h1 := hpde t ht x
        have h2 := (fkW_derivs (P := P) (B := B) (μ := μ) (r := r) hB hg hg_growth hσ ht.2 x).2.2.2
        simp only [W]
        linear_combination h1 - h2)
      (by
        obtain ⟨C1, k, hC1⟩ := hu_growth
        obtain ⟨C2, hC2⟩ := fkW_growth (P := P) (B := B) (μ := μ) (σ := σ) (r := r) (T := T)
          hB hg hg_growth
        have hC10 : 0 ≤ C1 := by
          have h0 := hC1 0 ⟨le_rfl, hT.le⟩ 0
          have hpos : 0 < 1 + |(0:ℝ)| ^ k := by positivity
          by_contra hneg
          push Not at hneg
          have : C1 * (1 + |(0:ℝ)| ^ k) < 0 := mul_neg_of_neg_of_pos hneg hpos
          linarith [abs_nonneg (u 0 0)]
        refine ⟨C1 * (1 + k.factorial) + C2, fun t ht x => ?_⟩
        have e1 := (hC1 t ht x).trans (fk_poly_le_exp hC10 k x)
        have e2 := hC2 t ht x
        calc |u t x - W t x| ≤ |u t x| + |W t x| := abs_sub _ _
          _ ≤ C1 * (1 + k.factorial) * Real.exp |x| + C2 * Real.exp |x| := add_le_add e1 e2
          _ = _ := by ring)
    have := hzero t ht x
    simp only [W] at this
    linarith

/-- **What breaks without the true-martingale condition.** For `dX = X² dW` (no drift, kick
`x²`, no discount) the backward equation in the time left `τ` is `u_τ = ½ x⁴ u_xx`, with payoff
`u(0, x) = x`. The function `u = x` solves it. So does the average,
`w(τ, x) = x (2 N(1 / (x √τ)) - 1)`, where `N` is the bell-curve area to the left of a point:
it solves the equation for `τ > 0` and `x > 0` and tends to the payoff `x` as `τ → 0`.
Yet the two differ: from `x = 1` after one year the average is `2 N(1) - 1 < 1`. -/
theorem local_martingale_gives_second_solution :
    let N : ℝ → ℝ := fun z => cdf (gaussianReal 0 1) z
    let w : ℝ → ℝ → ℝ := fun τ x => x * (2 * N (1 / (x * Real.sqrt τ)) - 1)
    (∀ τ > 0, ∀ x > 0, ContDiffAt ℝ 2 (w τ) x ∧
      HasDerivAt (fun s => w s x) (1 / 2 * x ^ 4 * deriv (deriv (w τ)) x) τ) ∧
    (∀ x > 0, Tendsto (fun τ => w τ x) (𝓝[>] 0) (𝓝 x)) ∧
    w 1 1 < 1 := by
  intro N w
  refine ⟨fun τ hτ x hx => ⟨?_, ?_⟩, fun x hx => ?_, ?_⟩
  · -- smoothness in x
    have hs : 0 < Real.sqrt τ := Real.sqrt_pos.2 hτ
    have ha : ContDiffAt ℝ 2 (fun y => 1 / (y * Real.sqrt τ)) x := by
      have : ContDiffAt ℝ 2 (fun y : ℝ => y * Real.sqrt τ) x := by fun_prop
      exact contDiffAt_const.div this (by positivity)
    have hN : ContDiffAt ℝ 2 (fun y => N (1 / (y * Real.sqrt τ))) x :=
      fk_contDiff_cdf.contDiffAt.comp x ha
    show ContDiffAt ℝ 2 (fun y => y * (2 * N (1 / (y * Real.sqrt τ)) - 1)) x
    exact contDiffAt_id.mul ((hN.const_smul (2:ℝ)).sub contDiffAt_const)
  · have hs : 0 < Real.sqrt τ := Real.sqrt_pos.2 hτ
    -- second slope in x
    have hd1 : deriv (w τ) =ᶠ[𝓝 x] fun y => 2 * N (1 / (y * Real.sqrt τ)) - 1
        - 2 * (1 / (y * Real.sqrt τ)) * gaussianPDFReal 0 1 (1 / (y * Real.sqrt τ)) := by
      filter_upwards [Ioi_mem_nhds hx] with y hy
      exact (fk_w_hasDerivAt_x τ y hτ hy).deriv
    have hd2 : deriv (deriv (w τ)) x =
        -2 * (1 / (x * Real.sqrt τ)) ^ 3 * gaussianPDFReal 0 1 (1 / (x * Real.sqrt τ)) / x := by
      rw [hd1.deriv_eq]; exact (fk_w1_hasDerivAt_x τ x hτ hx).deriv
    rw [hd2]
    -- slope in τ
    have hsq : HasDerivAt Real.sqrt (1 / (2 * Real.sqrt τ)) τ := by
      have := Real.hasDerivAt_sqrt hτ.ne'
      simpa using this
    have hxs : x * Real.sqrt τ ≠ 0 := by positivity
    have ha : HasDerivAt (fun s => 1 / (x * Real.sqrt s))
        (-(x * (1 / (2 * Real.sqrt τ))) / (x * Real.sqrt τ) ^ 2) τ :=
      ((hasDerivAt_const τ (1:ℝ)).div (hsq.const_mul x) hxs).congr_deriv (by simp)
    have h := (((fk_hasDerivAt_cdf (1 / (x * Real.sqrt τ))).comp τ ha).const_mul 2).sub_const 1
      |>.const_mul x
    refine h.congr_deriv ?_
    have hsτ : Real.sqrt τ ^ 2 = τ := Real.sq_sqrt hτ.le
    set p := gaussianPDFReal 0 1 (1 / (x * Real.sqrt τ))
    field_simp
  · -- limit as τ → 0
    have h1 : Tendsto (fun τ => Real.sqrt τ) (𝓝[>] 0) (𝓝[>] 0) := by
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · have := (Real.continuous_sqrt.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
        simpa using this
      · filter_upwards [self_mem_nhdsWithin] with τ hτ
        exact Real.sqrt_pos.2 hτ
    have h2 : Tendsto (fun τ => x * Real.sqrt τ) (𝓝[>] 0) (𝓝[>] 0) := by
      refine tendsto_nhdsWithin_iff.2 ⟨?_, ?_⟩
      · have := (h1.mono_right nhdsWithin_le_nhds).const_mul x
        simpa using this
      · filter_upwards [self_mem_nhdsWithin] with τ hτ
        exact mul_pos hx (Real.sqrt_pos.2 hτ)
    have h3 : Tendsto (fun τ => 1 / (x * Real.sqrt τ)) (𝓝[>] 0) atTop := by
      exact (tendsto_inv_nhdsGT_zero.comp h2).congr fun τ => by simp [one_div]
    have h4 : Tendsto (fun τ => N (1 / (x * Real.sqrt τ))) (𝓝[>] 0) (𝓝 1) :=
      (tendsto_cdf_atTop (μ := gaussianReal 0 1)).comp h3
    have h5 := (h4.const_mul 2).sub_const 1 |>.const_mul x
    show Tendsto (fun τ => x * (2 * N (1 / (x * Real.sqrt τ)) - 1)) (𝓝[>] 0) (𝓝 x)
    convert h5 using 2; ring
  · have hmono : StrictMono N := by
      refine strictMono_of_deriv_pos fun z => ?_
      rw [(fk_hasDerivAt_cdf z).deriv]
      exact gaussianPDFReal_pos _ _ _ one_ne_zero
    have h12 : N 1 < N 2 := hmono (by norm_num)
    have h2 : N 2 ≤ 1 := cdf_le_one (μ := gaussianReal 0 1) 2
    show 1 * (2 * N (1 / (1 * Real.sqrt 1)) - 1) < 1
    simp only [Real.sqrt_one, mul_one, one_mul, div_one]
    linarith

#print axioms average_solves_backward_equation
#print axioms backward_equation_solution_eq_average
#print axioms local_martingale_gives_second_solution
