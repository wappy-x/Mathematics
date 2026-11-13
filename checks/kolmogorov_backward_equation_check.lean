-- Kolmogorov backward equation: for a share moving as Brownian motion with constant drift and noise, the expected payoff as a function of the time to go and today's price solves the backward (heat) equation with the payoff as its end condition; the call payoff has the closed form (x + μτ - K) N(d) + σ√τ φ(d); and the expected house rate θ + (x - θ)e^(-κτ) solves the rate's backward equation.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.Calculus.ParametricIntegral

namespace KolmogorovBackwardEquation

open MeasureTheory ProbabilityTheory Filter Topology

/-! Setting. Time is measured as the time to go `τ = T - t` before the payment date. The share
starts at price `x` and moves as `x + μ s + σ W_s`, with `W` a Brownian motion, so its price on
the payment date is `x + μ τ + σ √τ Z` with `Z` a standard normal (`gaussianReal 0 1`). The
expected payoff `u(τ, x) = E[f(X_T) | X_t = x]` is the average of `f` over that bell curve.
The backward equation `∂_t u + L u = 0` in calendar time is, in time to go,
`∂_τ u = μ ∂_x u + ½ σ² ∂_xx u`, with `u(0, x) = f(x)`. -/

/-- The expected payoff `u(τ, x) = ∫ f(x + μτ + σ√τ z) φ(z) dz`: the payoff rule `f` averaged
over the share's price on the payment date, `τ` years ahead, from today's price `x`. -/
noncomputable def expectedPayoff (μ σ : ℝ) (f : ℝ → ℝ) (τ x : ℝ) : ℝ :=
  ∫ z, f (x + μ * τ + σ * Real.sqrt τ * z) ∂(gaussianReal 0 1)

lemma kbe_poly_integrable_gauss (n : ℕ) (c : ℝ) (v : NNReal) :
    Integrable (fun z : ℝ => (1 + |z|) ^ n) (gaussianReal c v) := by
  have h : MemLp (fun z : ℝ => 1 + ‖id z‖) n (gaussianReal c v) :=
    (memLp_const 1).add (memLp_id_gaussianReal' (μ := c) (v := v) (n : ENNReal) (by simp)).norm
  refine h.integrable_norm_pow'.congr (ae_of_all _ fun z => ?_)
  simp only [id, Real.norm_eq_abs]
  rw [abs_of_nonneg (by positivity)]

lemma kbe_poly_exp_integrable (n : ℕ) {b : ℝ} (hb : 0 < b) (c : ℝ) :
    Integrable (fun y : ℝ => (1 + |y|) ^ n * Real.exp (-b * (y - c) ^ 2)) := by
  set v : NNReal := ⟨1 / (2 * b), by positivity⟩ with hv
  have hvr : (v : ℝ) = 1 / (2 * b) := rfl
  have hv0 : v ≠ 0 := by
    intro h
    have := congrArg NNReal.toReal h
    rw [hvr] at this
    simp at this
    linarith
  have hI := kbe_poly_integrable_gauss n c v
  rw [gaussianReal_of_var_ne_zero _ hv0, integrable_withDensity_iff_integrable_smul'
    (measurable_gaussianPDF _ _) (ae_of_all _ fun _ => gaussianPDF_lt_top)] at hI
  have := hI.const_mul (Real.sqrt (2 * Real.pi * v))
  refine this.congr (ae_of_all _ fun y => ?_)
  simp only [toReal_gaussianPDF, gaussianPDFReal, smul_eq_mul]
  have hs : 0 < Real.sqrt (2 * Real.pi * v) := Real.sqrt_pos.2 (by rw [hvr]; positivity)
  have : -(y - c) ^ 2 / (2 * (v : ℝ)) = -b * (y - c) ^ 2 := by
    rw [hvr]; field_simp
  rw [this]
  field_simp

lemma kbe_density (μ σ : ℝ) (hσ : 0 < σ) (f : ℝ → ℝ) (hf : Measurable f) (τ : ℝ) (hτ : 0 < τ)
    (x : ℝ) :
    expectedPayoff μ σ f τ x =
      ∫ y, f y * ((Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)))⁻¹ *
        Real.exp (-(y - (x + μ * τ)) ^ 2 / (2 * (σ ^ 2 * τ)))) := by
  set s := σ * Real.sqrt τ with hs
  set m := x + μ * τ with hm
  have hs2 : s ^ 2 = σ ^ 2 * τ := by
    rw [hs, mul_pow, Real.sq_sqrt hτ.le]
  set v : NNReal := ⟨σ ^ 2 * τ, by positivity⟩ with hv
  have hvr : (v : ℝ) = σ ^ 2 * τ := rfl
  have hmap : (gaussianReal 0 1).map (fun z => x + μ * τ + σ * Real.sqrt τ * z) =
      gaussianReal m v := by
    have : (fun z => x + μ * τ + σ * Real.sqrt τ * z) = (· + m) ∘ (s * ·) := by
      funext z; simp [hs, hm]; ring
    rw [this, ← Measure.map_map (measurable_add_const m) (measurable_const_mul s),
      gaussianReal_map_const_mul, gaussianReal_map_add_const]
    congr 1
    · simp
    · ext; rw [hvr]; simp [hs2]
  have hv0 : v ≠ 0 := by
    intro h
    have := congrArg NNReal.toReal h
    rw [hvr, NNReal.coe_zero] at this
    have : 0 < σ ^ 2 * τ := by positivity
    linarith
  unfold expectedPayoff
  rw [← integral_map (by fun_prop) hf.aestronglyMeasurable, hmap,
    integral_gaussianReal_eq_integral_smul hv0]
  congr 1
  funext y
  simp only [smul_eq_mul, gaussianPDFReal, hvr]
  ring

lemma kbe_tendsto (μ σ : ℝ) (hσ : 0 < σ) (f : ℝ → ℝ) (hf : Measurable f) (C : ℝ) (n : ℕ)
    (hgrowth : ∀ y, |f y| ≤ C * (1 + |y|) ^ n) (x : ℝ) (hc : ContinuousAt f x) :
    Tendsto (fun τ => expectedPayoff μ σ f τ x) (𝓝[>] 0) (𝓝 (f x)) := by
  have hC : 0 ≤ C := by
    have := hgrowth 0
    simp at this
    linarith [abs_nonneg (f 0)]
  set R := 1 + |x| + |μ| + σ with hR
  have hlim := tendsto_integral_filter_of_dominated_convergence (μ := gaussianReal 0 1)
    (l := 𝓝[>] (0 : ℝ))
    (F := fun τ z => f (x + μ * τ + σ * Real.sqrt τ * z)) (f := fun _ => f x)
    (fun z => C * R ^ n * (1 + |z|) ^ n) ?_ ?_ ?_ ?_
  · simpa [expectedPayoff] using hlim
  · exact Eventually.of_forall fun τ => (hf.comp (by fun_prop)).aestronglyMeasurable
  · filter_upwards [Ioo_mem_nhdsGT (zero_lt_one' ℝ)] with τ hτ
    refine ae_of_all _ fun z => ?_
    rw [Real.norm_eq_abs]
    refine (hgrowth _).trans ?_
    have hsq : Real.sqrt τ ≤ 1 := Real.sqrt_le_one.mpr hτ.2.le
    have hsq0 : 0 ≤ Real.sqrt τ := Real.sqrt_nonneg τ
    have h1 : |x + μ * τ + σ * Real.sqrt τ * z| ≤ |x| + |μ| + σ * |z| := by
      have e1 : |μ * τ| ≤ |μ| := by
        rw [abs_mul, abs_of_pos hτ.1]
        nlinarith [abs_nonneg μ, hτ.2]
      have e2 : |σ * Real.sqrt τ * z| ≤ σ * |z| := by
        rw [abs_mul, abs_mul, abs_of_pos hσ, abs_of_nonneg hsq0]
        exact mul_le_mul_of_nonneg_right (mul_le_of_le_one_right hσ.le hsq) (abs_nonneg z)
      calc |x + μ * τ + σ * Real.sqrt τ * z| ≤ |x + μ * τ| + |σ * Real.sqrt τ * z| := abs_add_le _ _
        _ ≤ |x| + |μ * τ| + |σ * Real.sqrt τ * z| := by gcongr; exact abs_add_le _ _
        _ ≤ _ := by linarith
    have h2 : 1 + |x + μ * τ + σ * Real.sqrt τ * z| ≤ R * (1 + |z|) := by
      have : 0 ≤ (|x| + |μ|) * |z| := by positivity
      nlinarith [abs_nonneg z]
    calc C * (1 + |x + μ * τ + σ * Real.sqrt τ * z|) ^ n ≤ C * (R * (1 + |z|)) ^ n := by
          gcongr
      _ = C * R ^ n * (1 + |z|) ^ n := by rw [mul_pow]; ring
  · exact (kbe_poly_integrable_gauss n 0 1).const_mul (C * R ^ n)
  · refine ae_of_all _ fun z => ?_
    have hin : Tendsto (fun τ : ℝ => x + μ * τ + σ * Real.sqrt τ * z) (𝓝[>] 0) (𝓝 x) := by
      have hc2 : Continuous (fun τ : ℝ => x + μ * τ + σ * Real.sqrt τ * z) := by fun_prop
      have := (hc2.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
      simpa using this
    exact hc.tendsto.comp hin

noncomputable def kbeG (a m y : ℝ) : ℝ :=
  (Real.sqrt (2 * Real.pi * a))⁻¹ * Real.exp (-(y - m) ^ 2 / (2 * a))

lemma kbeG_nonneg (a m y : ℝ) : 0 ≤ kbeG a m y := by
  unfold kbeG; positivity

lemma kbeG_continuous (a m : ℝ) : Continuous (fun y => kbeG a m y) := by
  unfold kbeG; fun_prop

lemma kbe_G_bound {a a1 a2 m c r : ℝ} (ha1 : 0 < a1) (h1 : a1 ≤ a) (h2 : a ≤ a2)
    (hr : |m - c| ≤ r) (y : ℝ) :
    kbeG a m y ≤ (Real.sqrt (2 * Real.pi * a1))⁻¹ * Real.exp (r ^ 2 / (2 * a2)) *
      Real.exp (-(1 / (4 * a2)) * (y - c) ^ 2) := by
  have ha : 0 < a := lt_of_lt_of_le ha1 h1
  have ha2 : 0 < a2 := lt_of_lt_of_le ha h2
  have hs : (Real.sqrt (2 * Real.pi * a))⁻¹ ≤ (Real.sqrt (2 * Real.pi * a1))⁻¹ := by
    apply inv_anti₀ (Real.sqrt_pos.2 (by positivity))
    apply Real.sqrt_le_sqrt
    have := Real.pi_pos
    nlinarith
  have he : Real.exp (-(y - m) ^ 2 / (2 * a)) ≤
      Real.exp (r ^ 2 / (2 * a2)) * Real.exp (-(1 / (4 * a2)) * (y - c) ^ 2) := by
    rw [← Real.exp_add]
    apply Real.exp_le_exp.2
    have q1 : (y - m) ^ 2 / (2 * a2) ≤ (y - m) ^ 2 / (2 * a) :=
      div_le_div_of_nonneg_left (sq_nonneg _) (by positivity) (by linarith)
    have hmc : (m - c) ^ 2 ≤ r ^ 2 := by
      have h0 := abs_nonneg (m - c)
      rw [← sq_abs (m - c)]
      nlinarith
    have q2 : (y - c) ^ 2 ≤ 2 * (y - m) ^ 2 + 2 * r ^ 2 := by
      nlinarith [sq_nonneg (y - m - (m - c))]
    have q3 : 1 / (4 * a2) * (y - c) ^ 2 ≤ 1 / (4 * a2) * (2 * (y - m) ^ 2 + 2 * r ^ 2) :=
      mul_le_mul_of_nonneg_left q2 (by positivity)
    have q4 : 1 / (4 * a2) * (2 * (y - m) ^ 2 + 2 * r ^ 2) =
        (y - m) ^ 2 / (2 * a2) + r ^ 2 / (2 * a2) := by
      field_simp; ring
    rw [neg_div, neg_mul]
    linarith
  unfold kbeG
  calc (Real.sqrt (2 * Real.pi * a))⁻¹ * Real.exp (-(y - m) ^ 2 / (2 * a))
      ≤ (Real.sqrt (2 * Real.pi * a1))⁻¹ * (Real.exp (r ^ 2 / (2 * a2)) *
          Real.exp (-(1 / (4 * a2)) * (y - c) ^ 2)) :=
        mul_le_mul hs he (Real.exp_pos _).le (by positivity)
    _ = _ := by ring

lemma kbe_KP_bound {a a1 a2 m c r P L : ℝ} (ha1 : 0 < a1) (h1 : a1 ≤ a) (h2 : a ≤ a2)
    (hr : |m - c| ≤ r) (y : ℝ) (hP : |P| ≤ L * (1 + |y|) ^ 2) :
    |kbeG a m y * P| ≤ ((Real.sqrt (2 * Real.pi * a1))⁻¹ * Real.exp (r ^ 2 / (2 * a2)) * L) *
      ((1 + |y|) ^ 2 * Real.exp (-(1 / (4 * a2)) * (y - c) ^ 2)) := by
  rw [abs_mul, abs_of_nonneg (kbeG_nonneg a m y)]
  have hG := kbe_G_bound ha1 h1 h2 hr y
  calc kbeG a m y * |P| ≤ ((Real.sqrt (2 * Real.pi * a1))⁻¹ * Real.exp (r ^ 2 / (2 * a2)) *
        Real.exp (-(1 / (4 * a2)) * (y - c) ^ 2)) * (L * (1 + |y|) ^ 2) :=
        mul_le_mul hG hP (abs_nonneg _) (by positivity)
    _ = _ := by ring

lemma kbe_w_bound {m c r : ℝ} (hr : |m - c| ≤ r) (y : ℝ) :
    |y - m| ≤ (1 + |c| + r) * (1 + |y|) := by
  have h1 : |y - m| ≤ |y| + |m| := abs_sub _ _
  have h2 : |m| ≤ |c| + r := by
    have := abs_sub_abs_le_abs_sub m c
    linarith
  have h3 : 0 ≤ |y| := abs_nonneg y
  have h4 : 0 ≤ |c| + r := le_trans (abs_nonneg m) h2
  nlinarith

lemma kbe_P_bound {a a1 w R Y α β : ℝ} (ha1 : 0 < a1) (h1 : a1 ≤ a) (hR : 0 ≤ R) (hY : 1 ≤ Y)
    (hw : |w| ≤ R * Y) :
    |α * (w / a) + β * ((w / a) ^ 2 - 1 / a)| ≤
      (|α| * (R / a1) + |β| * ((R / a1) ^ 2 + 1 / a1)) * Y ^ 2 := by
  have ha : 0 < a := lt_of_lt_of_le ha1 h1
  have hwa : |w / a| ≤ R / a1 * Y := by
    rw [abs_div, abs_of_pos ha, div_le_iff₀ ha]
    calc |w| ≤ R * Y := hw
      _ = R / a1 * Y * a1 := by field_simp
      _ ≤ R / a1 * Y * a := by
        apply mul_le_mul_of_nonneg_left h1; positivity
  have hY2 : Y ≤ Y ^ 2 := by nlinarith
  have hia : 1 / a ≤ 1 / a1 := one_div_le_one_div_of_le ha1 h1
  have e1 : |α * (w / a)| ≤ |α| * (R / a1) * Y ^ 2 := by
    rw [abs_mul]
    calc |α| * |w / a| ≤ |α| * (R / a1 * Y) := mul_le_mul_of_nonneg_left hwa (abs_nonneg _)
      _ ≤ |α| * (R / a1 * Y ^ 2) := by
        apply mul_le_mul_of_nonneg_left _ (abs_nonneg _)
        apply mul_le_mul_of_nonneg_left hY2; positivity
      _ = _ := by ring
  have e2 : |(w / a) ^ 2 - 1 / a| ≤ ((R / a1) ^ 2 + 1 / a1) * Y ^ 2 := by
    refine (abs_sub _ _).trans ?_
    rw [abs_of_nonneg (sq_nonneg _), abs_of_pos (by positivity)]
    have : (w / a) ^ 2 ≤ (R / a1 * Y) ^ 2 := by
      rw [← sq_abs]
      exact pow_le_pow_left₀ (abs_nonneg _) hwa 2
    have hY1 : 1 ≤ Y ^ 2 := by nlinarith
    have : 1 / a1 ≤ 1 / a1 * Y ^ 2 := le_mul_of_one_le_right (by positivity) hY1
    nlinarith
  have e3 : |β * ((w / a) ^ 2 - 1 / a)| ≤ |β| * (((R / a1) ^ 2 + 1 / a1) * Y ^ 2) := by
    rw [abs_mul]; exact mul_le_mul_of_nonneg_left e2 (abs_nonneg _)
  calc _ ≤ |α * (w / a)| + |β * ((w / a) ^ 2 - 1 / a)| := abs_add_le _ _
    _ ≤ _ := by nlinarith

lemma kbe_param_deriv {f : ℝ → ℝ} (hf : Measurable f) {C : ℝ} {n : ℕ}
    (hg : ∀ y, |f y| ≤ C * (1 + |y|) ^ n)
    {K K' : ℝ → ℝ → ℝ} {p0 ε : ℝ} (hε : 0 < ε)
    (hKc : ∀ p, Continuous (K p)) (hK'c : Continuous (K' p0))
    {A0 b0 c0 A b c : ℝ} (hb0 : 0 < b0) (hb : 0 < b)
    (hK0 : ∀ y, |K p0 y| ≤ A0 * ((1 + |y|) ^ 2 * Real.exp (-b0 * (y - c0) ^ 2)))
    (hK' : ∀ p ∈ Metric.ball p0 ε, ∀ y,
      |K' p y| ≤ A * ((1 + |y|) ^ 2 * Real.exp (-b * (y - c) ^ 2)))
    (hd : ∀ p ∈ Metric.ball p0 ε, ∀ y, HasDerivAt (fun q => K q y) (K' p y) p) :
    Integrable (fun y => f y * K' p0 y) ∧
    HasDerivAt (fun p => ∫ y, f y * K p y) (∫ y, f y * K' p0 y) p0 := by
  have hC : 0 ≤ C := by
    have := hg 0
    simp at this
    linarith [abs_nonneg (f 0)]
  have hbnd : ∀ (A b c y k : ℝ), |k| ≤ A * ((1 + |y|) ^ 2 * Real.exp (-b * (y - c) ^ 2)) →
      ‖f y * k‖ ≤ C * A * ((1 + |y|) ^ (n + 2) * Real.exp (-b * (y - c) ^ 2)) := by
    intro A b c y k hk
    rw [Real.norm_eq_abs, abs_mul]
    calc |f y| * |k| ≤ (C * (1 + |y|) ^ n) *
          (A * ((1 + |y|) ^ 2 * Real.exp (-b * (y - c) ^ 2))) :=
          mul_le_mul (hg y) hk (abs_nonneg _) (by positivity)
      _ = _ := by ring
  have hint0 := (kbe_poly_exp_integrable (n + 2) hb0 c0).const_mul (C * A0)
  have hint := (kbe_poly_exp_integrable (n + 2) hb c).const_mul (C * A)
  have key := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun p y => f y * K p y) (F' := fun p y => f y * K' p y) (x₀ := p0)
    (bound := fun y => C * A * ((1 + |y|) ^ (n + 2) * Real.exp (-b * (y - c) ^ 2)))
    (Metric.ball_mem_nhds p0 hε)
    (Eventually.of_forall fun p => (hf.mul (hKc p).measurable).aestronglyMeasurable)
    (hint0.mono' (hf.mul (hKc p0).measurable).aestronglyMeasurable
      (ae_of_all _ fun y => hbnd _ _ _ y _ (hK0 y)))
    (hf.mul hK'c.measurable).aestronglyMeasurable
    (ae_of_all _ fun y p hp => hbnd _ _ _ y _ (hK' p hp y))
    hint
    (ae_of_all _ fun y p hp => (hd p hp y).const_mul (f y))
  exact ⟨key.1, key.2⟩

lemma kbe_hasDerivAt_x1 (a d y x : ℝ) (ha : a ≠ 0) :
    HasDerivAt (fun x => kbeG a (x + d) y) (kbeG a (x + d) y * ((y - (x + d)) / a)) x := by
  have h : HasDerivAt (fun x => (Real.sqrt (2 * Real.pi * a))⁻¹ *
      Real.exp (-(y - (x + d)) ^ 2 / (2 * a))) _ x :=
    ((((((hasDerivAt_id' x).add_const d).const_sub y).pow 2).neg.div_const (2 * a)).exp).const_mul
      (Real.sqrt (2 * Real.pi * a))⁻¹
  unfold kbeG
  refine h.congr_deriv ?_
  simp only [Pi.neg_apply, Pi.pow_apply, Nat.cast_ofNat]
  field_simp
  ring

lemma kbe_hasDerivAt_x2 (a d y x : ℝ) (ha : a ≠ 0) :
    HasDerivAt (fun x => kbeG a (x + d) y * ((y - (x + d)) / a))
      (kbeG a (x + d) y * (((y - (x + d)) / a) ^ 2 - 1 / a)) x := by
  have h1 : HasDerivAt (fun x => (y - (x + d)) / a) _ x :=
    (((hasDerivAt_id' x).add_const d).const_sub y).div_const a
  have h2 := (kbe_hasDerivAt_x1 a d y x ha).mul h1
  refine h2.congr_deriv ?_
  ring

lemma kbe_hasDerivAt_t (μ σ x y τ : ℝ) (hσ : σ ≠ 0) (hτ : 0 < τ) :
    HasDerivAt (fun s => kbeG (σ ^ 2 * s) (x + μ * s) y)
      (kbeG (σ ^ 2 * τ) (x + μ * τ) y *
        (μ * ((y - (x + μ * τ)) / (σ ^ 2 * τ)) +
          σ ^ 2 / 2 * (((y - (x + μ * τ)) / (σ ^ 2 * τ)) ^ 2 - 1 / (σ ^ 2 * τ)))) τ := by
  have hσ2 : 0 < σ ^ 2 := by positivity
  have ha : 0 < σ ^ 2 * τ := by positivity
  have hp : 0 < 2 * Real.pi * (σ ^ 2 * τ) := by positivity
  have hS : 0 < Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)) := Real.sqrt_pos.2 hp
  have hden : HasDerivAt (fun s => 2 * (σ ^ 2 * s)) (2 * (σ ^ 2 * 1)) τ :=
    ((hasDerivAt_id τ).const_mul (σ ^ 2)).const_mul 2
  have hnum : HasDerivAt (fun s => -(y - (x + μ * s)) ^ 2) _ τ :=
    (((((hasDerivAt_id' τ).const_mul μ).const_add x).const_sub y).pow 2).neg
  have hin : HasDerivAt (fun s => -(y - (x + μ * s)) ^ 2 / (2 * (σ ^ 2 * s))) _ τ :=
    hnum.div hden (by positivity)
  have hsq : HasDerivAt (fun s => Real.sqrt (2 * Real.pi * (σ ^ 2 * s)))
      ((2 * Real.pi * (σ ^ 2 * 1)) / (2 * Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)))) τ :=
    (((hasDerivAt_id τ).const_mul (σ ^ 2)).const_mul (2 * Real.pi)).sqrt hp.ne'
  have h : HasDerivAt (fun s => (Real.sqrt (2 * Real.pi * (σ ^ 2 * s)))⁻¹ *
      Real.exp (-(y - (x + μ * s)) ^ 2 / (2 * (σ ^ 2 * s)))) _ τ :=
    (hsq.inv hS.ne').mul hin.exp
  unfold kbeG
  refine h.congr_deriv ?_
  simp only [Nat.cast_ofNat, Pi.inv_apply]
  norm_num
  have hss : Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)) ^ 2 = 2 * Real.pi * (σ ^ 2 * τ) :=
    Real.sq_sqrt hp.le
  generalize Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)) = S at hss hS ⊢
  generalize Real.exp (-(y - (x + μ * τ)) ^ 2 / (2 * (σ ^ 2 * τ))) = E
  have hpi := Real.pi_pos
  field_simp
  linear_combination (E * σ ^ 2 * τ) * hss

section BachHelpers
open Set
lemma kbe_bach_pdf_eq (z : ℝ) :
    gaussianPDFReal 0 1 z = (Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(1/2) * z ^ 2) := by
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  congr 2
  ring

lemma kbe_bach_pdf_neg (z : ℝ) : gaussianPDFReal 0 1 (-z) = gaussianPDFReal 0 1 z := by
  rw [kbe_bach_pdf_eq, kbe_bach_pdf_eq, neg_sq]

lemma kbe_bach_cdf_neg (d : ℝ) :
    cdf (gaussianReal 0 1) (-d) = 1 - cdf (gaussianReal 0 1) d := by
  have hmap : (gaussianReal 0 1).map (fun x : ℝ ↦ -x) = gaussianReal 0 1 := by
    rw [gaussianReal_map_neg, neg_zero]
  rw [cdf_eq_real, cdf_eq_real]
  have h1 : (gaussianReal 0 1).real (Iic (-d)) = (gaussianReal 0 1).real (Ici d) := by
    conv_lhs => rw [← hmap]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  rw [h1]
  have h2 : (gaussianReal 0 1).real (Ici d) = (gaussianReal 0 1).real (Ioi d) := by
    have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
    rw [measureReal_def, measureReal_def,
      measure_congr (Ioi_ae_eq_Ici (μ := gaussianReal 0 1) (a := d))]
  rw [h2, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ]

lemma kbe_bach_integrableOn_mul_pdf (a : ℝ) :
    IntegrableOn (fun z ↦ z * gaussianPDFReal 0 1 z) (Ioi a) := by
  have h := (integrable_mul_exp_neg_mul_sq (b := 1/2) (by norm_num)).const_mul
    (Real.sqrt (2 * Real.pi))⁻¹
  refine (h.congr (ae_of_all _ fun z ↦ ?_)).integrableOn
  simp only [kbe_bach_pdf_eq]
  ring

lemma kbe_bach_integral_Ioi_pdf (a : ℝ) :
    ∫ z in Ioi a, gaussianPDFReal 0 1 z = cdf (gaussianReal 0 1) (-a) := by
  have h := gaussianReal_apply_eq_integral 0 (v := 1) one_ne_zero (Ioi a)
  have hnn : 0 ≤ ∫ z in Ioi a, gaussianPDFReal 0 1 z :=
    setIntegral_nonneg measurableSet_Ioi fun z _ ↦ gaussianPDFReal_nonneg _ _ _
  have h2 : (gaussianReal 0 1).real (Ioi a) = ∫ z in Ioi a, gaussianPDFReal 0 1 z := by
    rw [measureReal_def, h, ENNReal.toReal_ofReal hnn]
  rw [← h2, ← compl_Iic, measureReal_compl measurableSet_Iic, probReal_univ, ← cdf_eq_real,
    kbe_bach_cdf_neg]

lemma kbe_bach_integral_Ioi_mul_pdf (a : ℝ) :
    ∫ z in Ioi a, z * gaussianPDFReal 0 1 z = gaussianPDFReal 0 1 a := by
  have hf : (fun z ↦ -gaussianPDFReal 0 1 z) =
      fun z ↦ -((Real.sqrt (2 * Real.pi))⁻¹ * Real.exp (-(1/2) * z ^ 2)) := by
    funext z; rw [kbe_bach_pdf_eq]
  have key := integral_Ioi_of_hasDerivAt_of_tendsto (a := a) (m := 0)
    (f := fun z ↦ -gaussianPDFReal 0 1 z) (f' := fun z ↦ z * gaussianPDFReal 0 1 z)
    ?_ ?_ (kbe_bach_integrableOn_mul_pdf a) ?_
  · rw [key]; ring
  · rw [hf]; exact (by fun_prop : Continuous _).continuousWithinAt
  · intro z _
    rw [hf, kbe_bach_pdf_eq]
    have h1 := (((hasDerivAt_pow 2 z).const_mul (-(1/2 : ℝ))).exp).const_mul
      (Real.sqrt (2 * Real.pi))⁻¹
    convert h1.neg using 1
    push_cast
    ring
  · rw [hf]
    have h0 : Tendsto (fun z : ℝ ↦ -(1/2) * z ^ 2) atTop atBot := by
      apply Tendsto.const_mul_atTop_of_neg (by norm_num)
      exact tendsto_pow_atTop two_ne_zero
    have h1 := (Real.tendsto_exp_atBot.comp h0).const_mul (Real.sqrt (2 * Real.pi))⁻¹
    have h2 := h1.neg
    simpa using h2

lemma kbe_bach_call_core (m s : ℝ) (hs : 0 < s) :
    ∫ z, max (m + s * z) 0 ∂(gaussianReal 0 1) =
      m * cdf (gaussianReal 0 1) (m / s) + s * gaussianPDFReal 0 1 (m / s) := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have hind : (fun z ↦ gaussianPDFReal 0 1 z • max (m + s * z) 0) =
      (Ioi (-(m / s))).indicator
        (fun z ↦ m * gaussianPDFReal 0 1 z + s * (z * gaussianPDFReal 0 1 z)) := by
    funext z
    have hms : m + s * z = s * (m / s + z) := by field_simp
    simp only [smul_eq_mul, indicator, mem_Ioi]
    split_ifs with h
    · rw [max_eq_left]
      · ring
      · rw [hms]; exact mul_nonneg hs.le (by linarith)
    · rw [max_eq_right, mul_zero]
      rw [hms]; exact mul_nonpos_of_nonneg_of_nonpos hs.le (by linarith)
  rw [hind, integral_indicator measurableSet_Ioi, integral_add, integral_const_mul,
    integral_const_mul, kbe_bach_integral_Ioi_pdf, kbe_bach_integral_Ioi_mul_pdf, neg_neg, kbe_bach_pdf_neg]
  · exact ((integrable_gaussianPDFReal 0 1).integrableOn).const_mul m
  · exact (kbe_bach_integrableOn_mul_pdf _).const_mul s

end BachHelpers

#print axioms kbe_poly_integrable_gauss
#print axioms kbe_poly_exp_integrable
#print axioms kbe_density
#print axioms kbe_tendsto
#print axioms kbeG_nonneg
#print axioms kbeG_continuous
#print axioms kbe_G_bound
#print axioms kbe_KP_bound
#print axioms kbe_w_bound
#print axioms kbe_P_bound
#print axioms kbe_param_deriv
#print axioms kbe_hasDerivAt_x1
#print axioms kbe_hasDerivAt_x2
#print axioms kbe_hasDerivAt_t
#print axioms kbe_bach_pdf_eq
#print axioms kbe_bach_pdf_neg
#print axioms kbe_bach_cdf_neg
#print axioms kbe_bach_integrableOn_mul_pdf
#print axioms kbe_bach_integral_Ioi_pdf
#print axioms kbe_bach_integral_Ioi_mul_pdf
#print axioms kbe_bach_call_core

/-- The card's main result (Brownian case, proved in full on the card). A share moves as
Brownian motion with constant drift `μ` and noise `σ > 0`, and the payoff rule `f` grows at most
like a power of the price. Then the expected payoff `u(τ, x)` is twice differentiable in the
price and differentiable in the time to go whenever time is left (`τ > 0`), and its rate in the
time to go equals the generator applied to it: `∂_τ u = μ ∂_x u + ½ σ² ∂_xx u`. As the time to go
shrinks to zero the expected payoff tends to the payoff itself, at every price where the payoff
rule is continuous. -/
theorem kolmogorov_backward_equation_brownian (μ σ : ℝ) (hσ : 0 < σ)
    (f : ℝ → ℝ) (hf : Measurable f) (C : ℝ) (n : ℕ)
    (hgrowth : ∀ y, |f y| ≤ C * (1 + |y|) ^ n) :
    (∀ τ > 0, ∀ x : ℝ,
      Differentiable ℝ (expectedPayoff μ σ f τ) ∧
      Differentiable ℝ (deriv (expectedPayoff μ σ f τ)) ∧
      DifferentiableAt ℝ (fun s => expectedPayoff μ σ f s x) τ ∧
      deriv (fun s => expectedPayoff μ σ f s x) τ =
        μ * deriv (expectedPayoff μ σ f τ) x +
          σ ^ 2 / 2 * deriv (deriv (expectedPayoff μ σ f τ)) x) ∧
    (∀ x : ℝ, ContinuousAt f x →
      Tendsto (fun τ => expectedPayoff μ σ f τ x) (𝓝[>] 0) (𝓝 (f x))) := by
  refine ⟨fun τ hτ x => ?_, fun x hx => kbe_tendsto μ σ hσ f hf C n hgrowth x hx⟩
  have ha : 0 < σ ^ 2 * τ := by positivity
  have hu : expectedPayoff μ σ f τ = fun x => ∫ y, f y * kbeG (σ ^ 2 * τ) (x + μ * τ) y :=
    funext fun x => kbe_density μ σ hσ f hf τ hτ x
  have hY : ∀ y : ℝ, 1 ≤ 1 + |y| := fun y => by linarith [abs_nonneg y]
  have hD1 : ∀ x0, Integrable (fun y => f y *
        (kbeG (σ ^ 2 * τ) (x0 + μ * τ) y * ((y - (x0 + μ * τ)) / (σ ^ 2 * τ)))) ∧
      HasDerivAt (fun x => ∫ y, f y * kbeG (σ ^ 2 * τ) (x + μ * τ) y)
        (∫ y, f y * (kbeG (σ ^ 2 * τ) (x0 + μ * τ) y * ((y - (x0 + μ * τ)) / (σ ^ 2 * τ)))) x0 := by
    intro x0
    have hR : 0 ≤ 1 + |x0 + μ * τ| + 1 := by positivity
    refine kbe_param_deriv (K := fun x y => kbeG (σ ^ 2 * τ) (x + μ * τ) y)
      (K' := fun x y => kbeG (σ ^ 2 * τ) (x + μ * τ) y * ((y - (x + μ * τ)) / (σ ^ 2 * τ)))
      hf hgrowth one_pos (fun p => kbeG_continuous _ _) ?_
      (A0 := (Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)))⁻¹ * Real.exp (0 ^ 2 / (2 * (σ ^ 2 * τ))) * 1)
      (b0 := 1 / (4 * (σ ^ 2 * τ))) (c0 := x0 + μ * τ)
      (A := (Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)))⁻¹ * Real.exp (1 ^ 2 / (2 * (σ ^ 2 * τ))) *
        ((1 + |x0 + μ * τ| + 1) / (σ ^ 2 * τ)))
      (b := 1 / (4 * (σ ^ 2 * τ))) (c := x0 + μ * τ)
      (by positivity) (by positivity) ?_ ?_ ?_
    · unfold kbeG; fun_prop
    · intro y
      have := kbe_KP_bound (P := 1) (L := 1) (r := 0) (m := x0 + μ * τ) (c := x0 + μ * τ) ha le_rfl
        le_rfl (by simp) y (by rw [abs_one, one_mul]; nlinarith [hY y])
      rw [mul_one] at this
      exact this
    · intro p hp y
      rw [Metric.mem_ball, Real.dist_eq] at hp
      have hr : |(p + μ * τ) - (x0 + μ * τ)| ≤ 1 := by
        rw [show (p + μ * τ) - (x0 + μ * τ) = p - x0 by ring]; exact hp.le
      have hP := kbe_P_bound (α := 1) (β := 0) ha le_rfl hR (hY y) (kbe_w_bound hr y)
      simp only [one_mul, zero_mul, add_zero, abs_one, abs_zero] at hP
      exact kbe_KP_bound ha le_rfl le_rfl hr y hP
    · intro p _ y
      exact kbe_hasDerivAt_x1 _ _ y p ha.ne'
  have hD2 : ∀ x0, Integrable (fun y => f y *
        (kbeG (σ ^ 2 * τ) (x0 + μ * τ) y *
          (((y - (x0 + μ * τ)) / (σ ^ 2 * τ)) ^ 2 - 1 / (σ ^ 2 * τ)))) ∧
      HasDerivAt (fun x => ∫ y, f y *
          (kbeG (σ ^ 2 * τ) (x + μ * τ) y * ((y - (x + μ * τ)) / (σ ^ 2 * τ))))
        (∫ y, f y * (kbeG (σ ^ 2 * τ) (x0 + μ * τ) y *
          (((y - (x0 + μ * τ)) / (σ ^ 2 * τ)) ^ 2 - 1 / (σ ^ 2 * τ)))) x0 := by
    intro x0
    have hR : 0 ≤ 1 + |x0 + μ * τ| + 0 := by positivity
    have hR1 : 0 ≤ 1 + |x0 + μ * τ| + 1 := by positivity
    refine kbe_param_deriv
      (K := fun x y => kbeG (σ ^ 2 * τ) (x + μ * τ) y * ((y - (x + μ * τ)) / (σ ^ 2 * τ)))
      (K' := fun x y => kbeG (σ ^ 2 * τ) (x + μ * τ) y *
        (((y - (x + μ * τ)) / (σ ^ 2 * τ)) ^ 2 - 1 / (σ ^ 2 * τ)))
      hf hgrowth one_pos (fun p => by unfold kbeG; fun_prop) ?_
      (A0 := (Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)))⁻¹ * Real.exp (0 ^ 2 / (2 * (σ ^ 2 * τ))) *
        ((1 + |x0 + μ * τ|) / (σ ^ 2 * τ)))
      (b0 := 1 / (4 * (σ ^ 2 * τ))) (c0 := x0 + μ * τ)
      (A := (Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)))⁻¹ * Real.exp (1 ^ 2 / (2 * (σ ^ 2 * τ))) *
        (((1 + |x0 + μ * τ| + 1) / (σ ^ 2 * τ)) ^ 2 + 1 / (σ ^ 2 * τ)))
      (b := 1 / (4 * (σ ^ 2 * τ))) (c := x0 + μ * τ)
      (by positivity) (by positivity) ?_ ?_ ?_
    · unfold kbeG; fun_prop
    · intro y
      have hr : |(x0 + μ * τ) - (x0 + μ * τ)| ≤ 0 := by simp
      have hP := kbe_P_bound (α := 1) (β := 0) ha le_rfl hR (hY y) (kbe_w_bound hr y)
      simp only [one_mul, zero_mul, add_zero, abs_one, abs_zero] at hP
      exact kbe_KP_bound ha le_rfl le_rfl hr y hP
    · intro p hp y
      rw [Metric.mem_ball, Real.dist_eq] at hp
      have hr : |(p + μ * τ) - (x0 + μ * τ)| ≤ 1 := by
        rw [show (p + μ * τ) - (x0 + μ * τ) = p - x0 by ring]; exact hp.le
      have hP := kbe_P_bound (α := 0) (β := 1) ha le_rfl hR1 (hY y) (kbe_w_bound hr y)
      simp only [one_mul, zero_mul, zero_add, abs_one, abs_zero] at hP
      exact kbe_KP_bound ha le_rfl le_rfl hr y hP
    · intro p _ y
      exact kbe_hasDerivAt_x2 _ _ y p ha.ne'
  have hd1 : deriv (expectedPayoff μ σ f τ) = fun x => ∫ y, f y *
      (kbeG (σ ^ 2 * τ) (x + μ * τ) y * ((y - (x + μ * τ)) / (σ ^ 2 * τ))) := by
    rw [hu]; exact funext fun x => (hD1 x).2.deriv
  have hd2 : deriv (deriv (expectedPayoff μ σ f τ)) = fun x => ∫ y, f y *
      (kbeG (σ ^ 2 * τ) (x + μ * τ) y *
        (((y - (x + μ * τ)) / (σ ^ 2 * τ)) ^ 2 - 1 / (σ ^ 2 * τ))) := by
    rw [hd1]; exact funext fun x => (hD2 x).2.deriv
  -- the derivative in the time to go
  have hDt : HasDerivAt (fun s => ∫ y, f y * kbeG (σ ^ 2 * s) (x + μ * s) y)
      (∫ y, f y * (kbeG (σ ^ 2 * τ) (x + μ * τ) y *
        (μ * ((y - (x + μ * τ)) / (σ ^ 2 * τ)) +
          σ ^ 2 / 2 * (((y - (x + μ * τ)) / (σ ^ 2 * τ)) ^ 2 - 1 / (σ ^ 2 * τ))))) τ := by
    have hR : 0 ≤ 1 + |x + μ * τ| + |μ| * (τ / 2) := by positivity
    have hR0 : 0 ≤ 1 + |x + μ * τ| + 0 := by positivity
    have ha1 : 0 < σ ^ 2 * (τ / 2) := by positivity
    refine (kbe_param_deriv (K := fun s y => kbeG (σ ^ 2 * s) (x + μ * s) y)
      (K' := fun s y => kbeG (σ ^ 2 * s) (x + μ * s) y *
        (μ * ((y - (x + μ * s)) / (σ ^ 2 * s)) +
          σ ^ 2 / 2 * (((y - (x + μ * s)) / (σ ^ 2 * s)) ^ 2 - 1 / (σ ^ 2 * s))))
      (p0 := τ) (ε := τ / 2)
      hf hgrowth (by positivity) (fun p => kbeG_continuous _ _) ?_
      (A0 := (Real.sqrt (2 * Real.pi * (σ ^ 2 * τ)))⁻¹ * Real.exp (0 ^ 2 / (2 * (σ ^ 2 * τ))) * 1)
      (b0 := 1 / (4 * (σ ^ 2 * τ))) (c0 := x + μ * τ)
      (A := (Real.sqrt (2 * Real.pi * (σ ^ 2 * (τ / 2))))⁻¹ *
        Real.exp ((|μ| * (τ / 2)) ^ 2 / (2 * (σ ^ 2 * (3 * τ / 2)))) *
        (|μ| * ((1 + |x + μ * τ| + |μ| * (τ / 2)) / (σ ^ 2 * (τ / 2))) +
          |σ ^ 2 / 2| * (((1 + |x + μ * τ| + |μ| * (τ / 2)) / (σ ^ 2 * (τ / 2))) ^ 2 +
            1 / (σ ^ 2 * (τ / 2)))))
      (b := 1 / (4 * (σ ^ 2 * (3 * τ / 2)))) (c := x + μ * τ)
      (by positivity) (by positivity) ?_ ?_ ?_).2
    · unfold kbeG; fun_prop
    · intro y
      have := kbe_KP_bound (P := 1) (L := 1) (r := 0) (m := x + μ * τ) (c := x + μ * τ) ha le_rfl
        le_rfl (by simp) y (by rw [abs_one, one_mul]; nlinarith [hY y])
      rw [mul_one] at this
      exact this
    · intro p hp y
      rw [Metric.mem_ball, Real.dist_eq, abs_lt] at hp
      have hσ2 : 0 < σ ^ 2 := by positivity
      have h1 : σ ^ 2 * (τ / 2) ≤ σ ^ 2 * p :=
        mul_le_mul_of_nonneg_left (by linarith) hσ2.le
      have h2 : σ ^ 2 * p ≤ σ ^ 2 * (3 * τ / 2) :=
        mul_le_mul_of_nonneg_left (by linarith) hσ2.le
      have hr : |(x + μ * p) - (x + μ * τ)| ≤ |μ| * (τ / 2) := by
        rw [show (x + μ * p) - (x + μ * τ) = μ * (p - τ) by ring, abs_mul]
        exact mul_le_mul_of_nonneg_left (abs_le.2 ⟨by linarith, by linarith⟩) (abs_nonneg _)
      have hP := kbe_P_bound (α := μ) (β := σ ^ 2 / 2) ha1 h1 hR (hY y) (kbe_w_bound hr y)
      exact kbe_KP_bound ha1 h1 h2 hr y hP
    · intro p hp y
      rw [Metric.mem_ball, Real.dist_eq, abs_lt] at hp
      exact kbe_hasDerivAt_t μ σ x y p hσ.ne' (by linarith)
  have hDt' : HasDerivAt (fun s => expectedPayoff μ σ f s x)
      (∫ y, f y * (kbeG (σ ^ 2 * τ) (x + μ * τ) y *
        (μ * ((y - (x + μ * τ)) / (σ ^ 2 * τ)) +
          σ ^ 2 / 2 * (((y - (x + μ * τ)) / (σ ^ 2 * τ)) ^ 2 - 1 / (σ ^ 2 * τ))))) τ := by
    refine hDt.congr_of_eventuallyEq ?_
    filter_upwards [Ioi_mem_nhds hτ] with s hs
    exact kbe_density μ σ hσ f hf s hs x
  refine ⟨?_, ?_, hDt'.differentiableAt, ?_⟩
  · rw [hu]; exact fun x => (hD1 x).2.differentiableAt
  · rw [hd1]; exact fun x => (hD2 x).2.differentiableAt
  · rw [hDt'.deriv, hd2, hd1]
    simp only
    rw [← integral_const_mul, ← integral_const_mul,
      ← integral_add ((hD1 x).1.const_mul μ) ((hD2 x).1.const_mul (σ ^ 2 / 2))]
    congr 1
    funext y
    ring

/-- The call formula. For the payoff `max(y - K, 0)`, with `τ > 0` years to go, the expected
payoff is `(m - K) N(d) + s φ(d)`, where `m = x + μτ` is the expected final price,
`s = σ√τ` the spread, `d = (m - K)/s`, `N` the bell-curve area to the left and `φ` the
bell-curve height. -/
theorem call_expected_payoff_formula (μ σ K : ℝ) (hσ : 0 < σ) (τ : ℝ) (hτ : 0 < τ) (x : ℝ) :
    expectedPayoff μ σ (fun y => max (y - K) 0) τ x =
      (x + μ * τ - K) * cdf (gaussianReal 0 1) ((x + μ * τ - K) / (σ * Real.sqrt τ)) +
        σ * Real.sqrt τ * gaussianPDFReal 0 1 ((x + μ * τ - K) / (σ * Real.sqrt τ)) := by
  have hs : 0 < σ * Real.sqrt τ := mul_pos hσ (Real.sqrt_pos.mpr hτ)
  rw [← kbe_bach_call_core (x + μ * τ - K) (σ * Real.sqrt τ) hs]
  unfold expectedPayoff
  congr 1
  funext z
  ring_nf

/-- The house rate (Step 5). For the mean-reverting rate with pull speed `κ`, long-run level `θ`
and noise `σ`, the generator is `L g = κ(θ - x) g' + ½ σ² g''`. The expected rate
`u(τ, x) = θ + (x - θ) e^(-κτ)` solves its backward equation in time to go,
`∂_τ u = κ(θ - x) ∂_x u + ½ σ² ∂_xx u`, and equals today's rate when no time is left. -/
theorem ou_expected_rate_solves_backward_equation (κ θ σ : ℝ) :
    let u : ℝ → ℝ → ℝ := fun τ x => θ + (x - θ) * Real.exp (-κ * τ)
    (∀ τ x : ℝ,
      deriv (fun s => u s x) τ =
        κ * (θ - x) * deriv (fun y => u τ y) x +
          σ ^ 2 / 2 * deriv (deriv (fun y => u τ y)) x) ∧
    (∀ x : ℝ, u 0 x = x) := by
  intro u
  refine ⟨fun τ x => ?_, fun x => by simp [u]⟩
  have h1 : HasDerivAt (fun s => u s x) ((x - θ) * (Real.exp (-κ * τ) * (-κ * 1))) τ :=
    ((((hasDerivAt_id' τ).const_mul (-κ)).exp).const_mul (x - θ)).const_add θ
  have h2 : deriv (fun y => u τ y) = fun _ => Real.exp (-κ * τ) := by
    funext y
    have : HasDerivAt (fun y => u τ y) (1 * Real.exp (-κ * τ)) y :=
      (((hasDerivAt_id' y).sub_const θ).mul_const (Real.exp (-κ * τ))).const_add θ
    rw [this.deriv, one_mul]
  rw [h1.deriv, h2, deriv_const]
  ring

/-! The card's whole-number checks: sigma = $20 per root-year, a year to go. -/

-- the spread over the year, σ√τ with τ = 1: 20 × 1 = 20
example : (20 : ℝ) * Real.sqrt 1 = 20 := by norm_num
-- the diffusivity one half sigma squared: 200 square dollars per year
example : (1 / 2 : ℚ) * 20 ^ 2 = 200 := by norm_num
-- distance to the strike in spread units from $100 and from $110
example : ((100 : ℚ) - 100) / 20 = 0 := by norm_num
example : ((110 : ℚ) - 100) / 20 = 1 / 2 := by norm_num
-- squared payoff (y - 100)²: u = (x - 100)² + σ²τ; τ-rate σ² = 400, bend 2, and 200 × 2 = 400
example : (20 : ℚ) ^ 2 = 400 ∧ (200 : ℚ) * 2 = 400 := by norm_num
-- at $100 a year out the expected square is (100 - 100)² + 20² × 1 = 400
example : ((100 : ℚ) - 100) ^ 2 + 20 ^ 2 * 1 = 400 := by norm_num

#print axioms kolmogorov_backward_equation_brownian
#print axioms call_expected_payoff_formula
#print axioms ou_expected_rate_solves_backward_equation

end KolmogorovBackwardEquation
