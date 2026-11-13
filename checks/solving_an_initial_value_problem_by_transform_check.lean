-- The round trip: this file proves that a linear constant-coefficient equation pushed by an exponentially bounded continuous force transforms to (s^2 + bs + k)Y = F + (s + b)y(0) + y'(0), that the test mass y'' + 2y' + 5y = 10 started from rest moves exactly as y = 2 - e^(-t)(2 cos 2t + sin 2t) and in no other way, and that it peaks at 2 + 2e^(-π/2) m at t = π/2 s and settles at 2 m.
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.MeasureTheory.Integral.ExpDecay
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.Calculus.Deriv.MeanValue

/-! Setting, in the card's notation.
* Time `t` is real and only `t ≥ 0` matters; derivatives are taken within `[0, ∞)`, so the
  motion need not be defined before the ram starts.
* `y'` and `y''` are the velocity and acceleration of the travel `y`, given as functions with
  `HasDerivWithinAt`.
* The Laplace transform of a signal `g` at a real `s` is `∫ t in (0, ∞), e^(-st) g(t)`. -/

open MeasureTheory Set Filter Topology

/-- The card's answer: the test mass's travel y(t) = 2 - e^(-t)(2 cos 2t + sin 2t), in metres. -/
noncomputable def travel (t : ℝ) : ℝ :=
  2 - Real.exp (-t) * (2 * Real.cos (2 * t) + Real.sin (2 * t))

theorem travel_hasDerivAt (t : ℝ) :
    HasDerivAt travel (5 * Real.exp (-t) * Real.sin (2 * t)) t := by
  have hc : HasDerivAt (fun u : ℝ => 2 * u) 2 t := by
    simpa using (hasDerivAt_id t).const_mul (2 : ℝ)
  have hexp : HasDerivAt (fun u : ℝ => Real.exp (-u)) (Real.exp (-t) * -1) t :=
    (hasDerivAt_neg t).exp
  have := (hexp.mul ((hc.cos.const_mul 2).add hc.sin)).const_sub 2
  exact this.congr_deriv (by simp only [Pi.add_apply]; ring)

#print axioms travel_hasDerivAt

theorem velocity_hasDerivAt (t : ℝ) :
    HasDerivAt (fun u => 5 * Real.exp (-u) * Real.sin (2 * u))
      (5 * Real.exp (-t) * (2 * Real.cos (2 * t) - Real.sin (2 * t))) t := by
  have hc : HasDerivAt (fun u : ℝ => 2 * u) 2 t := by
    simpa using (hasDerivAt_id t).const_mul (2 : ℝ)
  have hexp : HasDerivAt (fun u : ℝ => Real.exp (-u)) (Real.exp (-t) * -1) t :=
    (hasDerivAt_neg t).exp
  have := (hexp.const_mul 5).mul hc.sin
  exact this.congr_deriv (by ring)

#print axioms velocity_hasDerivAt

theorem travel_ode (t : ℝ) :
    5 * Real.exp (-t) * (2 * Real.cos (2 * t) - Real.sin (2 * t))
      + 2 * (5 * Real.exp (-t) * Real.sin (2 * t)) + 5 * travel t = 10 := by
  unfold travel; ring

#print axioms travel_ode

theorem travel_abs_le (t : ℝ) : |2 * Real.cos (2 * t) + Real.sin (2 * t)| ≤ 3 := by
  have h1 := Real.abs_cos_le_one (2 * t)
  have h2 := Real.abs_sin_le_one (2 * t)
  calc |2 * Real.cos (2 * t) + Real.sin (2 * t)|
      ≤ |2 * Real.cos (2 * t)| + |Real.sin (2 * t)| := abs_add_le _ _
    _ = 2 * |Real.cos (2 * t)| + |Real.sin (2 * t)| := by rw [abs_mul]; norm_num
    _ ≤ 3 := by linarith

#print axioms travel_abs_le

theorem laplace_exp_bound_integrable {g : ℝ → ℝ} {C α s : ℝ} (hg : ContinuousOn g (Ici 0))
    (hb : ∀ t ≥ 0, |g t| ≤ C * Real.exp (α * t)) (hs : α < s) :
    IntegrableOn (fun t => Real.exp (-(s * t)) * g t) (Ioi 0) ∧
      Tendsto (fun t => Real.exp (-(s * t)) * g t) atTop (𝓝 0) := by
  have key : ∀ t ≥ 0, ‖Real.exp (-(s * t)) * g t‖ ≤ C * Real.exp (-(s - α) * t) := by
    intro t ht
    rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, Real.abs_exp]
    calc Real.exp (-(s * t)) * |g t| ≤ Real.exp (-(s * t)) * (C * Real.exp (α * t)) :=
          mul_le_mul_of_nonneg_left (hb t ht) (Real.exp_pos _).le
      _ = C * Real.exp (-(s - α) * t) := by
          rw [show -(s - α) * t = -(s * t) + α * t by ring, Real.exp_add]; ring
  constructor
  · refine Integrable.mono' ((exp_neg_integrableOn_Ioi 0 (sub_pos.2 hs)).const_mul C) ?_ ?_
    · have hc : ContinuousOn (fun t => Real.exp (-(s * t)) * g t) (Ioi 0) :=
        ((by fun_prop : Continuous fun t : ℝ => Real.exp (-(s * t))).continuousOn).mul
          (hg.mono Ioi_subset_Ici_self)
      exact hc.aestronglyMeasurable measurableSet_Ioi
    · filter_upwards [ae_restrict_mem measurableSet_Ioi] with t ht
      exact key t (le_of_lt ht)
  · have hlim : Tendsto (fun t => C * Real.exp (-(s - α) * t)) atTop (𝓝 0) := by
      have := (Real.tendsto_exp_atBot.comp
        (tendsto_id.const_mul_atTop_of_neg (by linarith : -(s - α) < 0))).const_mul C
      simpa using this
    exact squeeze_zero_norm' ((eventually_ge_atTop 0).mono fun t ht => key t ht) hlim

#print axioms laplace_exp_bound_integrable

theorem laplace_of_deriv {s : ℝ} {g g' : ℝ → ℝ}
    (hg : ∀ t ≥ 0, HasDerivWithinAt g (g' t) (Ici 0) t)
    (h1 : IntegrableOn (fun t => Real.exp (-(s * t)) * g t) (Ioi 0))
    (h2 : IntegrableOn (fun t => Real.exp (-(s * t)) * g' t) (Ioi 0))
    (hlim : Tendsto (fun t => Real.exp (-(s * t)) * g t) atTop (𝓝 0)) :
    ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * g' t
      = s * (∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * g t) - g 0 := by
  have hderiv : ∀ x ∈ Ioi (0 : ℝ), HasDerivAt (fun t => Real.exp (-(s * t)) * g t)
      (-s * (Real.exp (-(s * x)) * g x) + Real.exp (-(s * x)) * g' x) x := by
    intro x hx
    have hgx : HasDerivAt g (g' x) x := (hg x (le_of_lt hx)).hasDerivAt (Ici_mem_nhds hx)
    have he : HasDerivAt (fun t => Real.exp (-(s * t))) (Real.exp (-(s * x)) * -(s * 1)) x :=
      ((hasDerivAt_id x).const_mul s).neg.exp
    exact (he.mul hgx).congr_deriv (by ring)
  have hint : IntegrableOn
      (fun x => -s * (Real.exp (-(s * x)) * g x) + Real.exp (-(s * x)) * g' x) (Ioi 0) :=
    (h1.const_mul (-s)).add h2
  have hcont : ContinuousWithinAt (fun t => Real.exp (-(s * t)) * g t) (Ici 0) 0 :=
    ((by fun_prop : Continuous fun t : ℝ => Real.exp (-(s * t))).continuousWithinAt).mul
      (hg 0 le_rfl).continuousWithinAt
  have := integral_Ioi_of_hasDerivAt_of_tendsto hcont hderiv hint hlim
  rw [integral_add (h1.const_mul _) h2, integral_const_mul] at this
  simp only [mul_zero, neg_zero, Real.exp_zero, one_mul, zero_sub] at this
  linarith

#print axioms laplace_of_deriv

theorem laplace_growth_bound (b k M L : ℝ) (f y y' y'' : ℝ → ℝ)
    (hgrow : ∀ t ≥ 0, |f t| ≤ M * Real.exp (L * t))
    (hy : ∀ t ≥ 0, HasDerivWithinAt y (y' t) (Ici 0) t)
    (hy' : ∀ t ≥ 0, HasDerivWithinAt y' (y'' t) (Ici 0) t)
    (heq : ∀ t ≥ 0, y'' t + b * y' t + k * y t = f t) :
    ∀ T ≥ 0, max |y T| |y' T|
      ≤ (max |y 0| |y' 0| + M) * Real.exp ((|L| + (1 + |b| + |k|)) * T) := by
  intro T hT
  have hM : 0 ≤ M := le_trans (abs_nonneg _) (by simpa using hgrow 0 le_rfl)
  set K := 1 + |b| + |k| with hK
  have hK1 : 1 ≤ K := by have := abs_nonneg b; have := abs_nonneg k; linarith
  set ε := M * Real.exp (|L| * T) with hε
  have hε0 : 0 ≤ ε := mul_nonneg hM (Real.exp_pos _).le
  have hzd : ∀ t ≥ 0, HasDerivWithinAt (fun t => (y t, y' t)) (y' t, y'' t) (Ici 0) t :=
    fun t ht => (hy t ht).prodMk (hy' t ht)
  have hnorm : ∀ t, ‖((y t, y' t) : ℝ × ℝ)‖ = max |y t| |y' t| := by
    intro t; rw [Prod.norm_def, Real.norm_eq_abs, Real.norm_eq_abs]
  have hnorm' : ∀ t, ‖((y' t, y'' t) : ℝ × ℝ)‖ = max |y' t| |y'' t| := by
    intro t; rw [Prod.norm_def, Real.norm_eq_abs, Real.norm_eq_abs]
  have hG := norm_le_gronwallBound_of_norm_deriv_right_le (f := fun t => (y t, y' t))
    (f' := fun t => (y' t, y'' t)) (δ := max |y 0| |y' 0|) (K := K) (ε := ε) (a := 0) (b := T)
    (fun t ht => (hzd t ht.1).continuousWithinAt.mono Icc_subset_Ici_self)
    (fun x hx => (hzd x hx.1).mono (Ici_subset_Ici.2 hx.1)) (le_of_eq (hnorm 0)) ?_ T
    ⟨hT, le_rfl⟩
  · rw [hnorm, gronwallBound_of_K_ne_0 (by linarith : K ≠ 0), sub_zero] at hG
    refine hG.trans ?_
    set δ := max |y 0| |y' 0|
    have hδ : 0 ≤ δ := le_trans (abs_nonneg _) (le_max_left _ _)
    set A := Real.exp (K * T)
    set B := Real.exp (|L| * T)
    have hA : 1 ≤ A := Real.one_le_exp (by nlinarith)
    have hB : 1 ≤ B := Real.one_le_exp (mul_nonneg (abs_nonneg _) hT)
    have hAB : Real.exp ((|L| + K) * T) = B * A := by rw [← Real.exp_add]; ring_nf
    rw [hAB]
    have hMB : 0 ≤ M * B := mul_nonneg hM (by linarith)
    have h1 : M * B / K * (A - 1) ≤ M * B * A := by
      calc M * B / K * (A - 1) ≤ M * B * (A - 1) :=
            mul_le_mul_of_nonneg_right (div_le_self hMB hK1) (by linarith)
        _ ≤ M * B * A := by nlinarith
    have h2 : δ * A ≤ δ * (B * A) := by nlinarith [mul_nonneg hδ (by linarith : (0:ℝ) ≤ A)]
    nlinarith
  · intro x hx
    rw [hnorm', hnorm]
    set m := max |y x| |y' x|
    have hym : |y x| ≤ m := le_max_left _ _
    have hy'm : |y' x| ≤ m := le_max_right _ _
    have hfx : |f x| ≤ ε := by
      refine (hgrow x hx.1).trans (mul_le_mul_of_nonneg_left (Real.exp_le_exp.2 ?_) hM)
      calc L * x ≤ |L| * x := mul_le_mul_of_nonneg_right (le_abs_self L) hx.1
        _ ≤ |L| * T := mul_le_mul_of_nonneg_left hx.2.le (abs_nonneg L)
    have hy'' : |y'' x| ≤ |f x| + |b| * |y' x| + |k| * |y x| := by
      have e : y'' x = f x - b * y' x - k * y x := by linarith [heq x hx.1]
      rw [e, ← abs_mul, ← abs_mul]
      have := abs_sub (f x - b * y' x) (k * y x)
      have := abs_sub (f x) (b * y' x)
      linarith
    have hb1 : |b| * |y' x| ≤ |b| * m := mul_le_mul_of_nonneg_left hy'm (abs_nonneg b)
    have hk1 : |k| * |y x| ≤ |k| * m := mul_le_mul_of_nonneg_left hym (abs_nonneg k)
    have hm0 : 0 ≤ m := le_trans (abs_nonneg _) hym
    refine max_le ?_ ?_
    · nlinarith
    · nlinarith

#print axioms laplace_growth_bound

/-- The card's main claim: the round trip's answer is the motion, and the only one. The travel
y = 2 - e^(-t)(2 cos 2t + sin 2t) starts at 0, has velocity 5e^(-t) sin 2t (0 at the start) and
acceleration 5e^(-t)(2 cos 2t - sin 2t), and satisfies y'' + 2y' + 5y = 10. Conversely, any
travel y with velocity y' and acceleration y'' on [0, ∞) that satisfies y'' + 2y' + 5y = 10 there,
from rest (y(0) = 0, y'(0) = 0), equals that formula at every t ≥ 0. -/
theorem forced_oscillator_from_rest_eq_round_trip_answer :
    (travel 0 = 0 ∧
      ∀ t : ℝ,
        HasDerivAt travel (5 * Real.exp (-t) * Real.sin (2 * t)) t ∧
        HasDerivAt (fun u => 5 * Real.exp (-u) * Real.sin (2 * u))
          (5 * Real.exp (-t) * (2 * Real.cos (2 * t) - Real.sin (2 * t))) t ∧
        5 * Real.exp (-t) * (2 * Real.cos (2 * t) - Real.sin (2 * t))
          + 2 * (5 * Real.exp (-t) * Real.sin (2 * t)) + 5 * travel t = 10) ∧
    (∀ y y' y'' : ℝ → ℝ,
      (∀ t ≥ 0, HasDerivWithinAt y (y' t) (Ici 0) t) →
      (∀ t ≥ 0, HasDerivWithinAt y' (y'' t) (Ici 0) t) →
      (∀ t ≥ 0, y'' t + 2 * y' t + 5 * y t = 10) →
      y 0 = 0 → y' 0 = 0 →
      ∀ t ≥ 0, y t = travel t) := by
  refine ⟨⟨by simp [travel], fun t => ⟨travel_hasDerivAt t, velocity_hasDerivAt t, travel_ode t⟩⟩,
    ?_⟩
  intro y y' y'' hy hy' heq h0 h0' t ht
  set v : ℝ → ℝ := fun u => 5 * Real.exp (-u) * Real.sin (2 * u) with hv
  set a : ℝ → ℝ := fun u => 5 * Real.exp (-u) * (2 * Real.cos (2 * u) - Real.sin (2 * u))
    with ha
  have hz : ∀ u ≥ 0, HasDerivWithinAt (fun u => y u - travel u) (y' u - v u) (Ici 0) u :=
    fun u hu => (hy u hu).sub (travel_hasDerivAt u).hasDerivWithinAt
  have hw : ∀ u ≥ 0, HasDerivWithinAt (fun u => y' u - v u) (y'' u - a u) (Ici 0) u :=
    fun u hu => (hy' u hu).sub (velocity_hasDerivAt u).hasDerivWithinAt
  set E : ℝ → ℝ := fun u => (y' u - v u) * (y' u - v u)
    + 5 * ((y u - travel u) * (y u - travel u)) with hE
  have hEd : ∀ u ≥ 0, HasDerivWithinAt E
      ((y'' u - a u) * (y' u - v u) + (y' u - v u) * (y'' u - a u)
        + 5 * ((y' u - v u) * (y u - travel u) + (y u - travel u) * (y' u - v u))) (Ici 0) u :=
    fun u hu => ((hw u hu).mul (hw u hu)).add (((hz u hu).mul (hz u hu)).const_mul 5)
  have hkey : ∀ u ≥ 0, y'' u - a u = -2 * (y' u - v u) - 5 * (y u - travel u) := by
    intro u hu
    have h1 := heq u hu
    have h2 := travel_ode u
    simp only [ha, hv]
    linarith
  have hanti : AntitoneOn E (Ici 0) := by
    refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ici 0)
      (fun u hu => (hEd u hu).continuousWithinAt) (fun u hu => (hEd u
        (interior_subset hu)).mono interior_subset) ?_
    intro u hu
    rw [hkey u (interior_subset hu)]
    nlinarith [sq_nonneg (y' u - v u)]
  have hE0 : E 0 = 0 := by simp [hE, hv, h0, h0', travel]
  have hEt : E t ≤ 0 := hE0 ▸ hanti (self_mem_Ici) ht ht
  simp only [hE] at hEt
  nlinarith [mul_self_nonneg (y' t - v t), mul_self_nonneg (y t - travel t)]

/-- The formula, for any y'' + b y' + k y = f(t) with constant b and k: if the push f is
continuous from t = 0 on (no infinite spike) and grows no faster than M e^(Lt) (so it has a
transform), and y solves the equation on [0, ∞) with starting values y(0) and y'(0) at t = 0,
then for every large enough s the travel's transform Y(s) exists and
(s^2 + b s + k) Y(s) = F(s) + (s + b) y(0) + y'(0), where F is the push's transform. -/
theorem laplace_transform_of_linear_equation (b k M L : ℝ) (f y y' y'' : ℝ → ℝ)
    (hf : ContinuousOn f (Ici 0))
    (hgrow : ∀ t ≥ 0, |f t| ≤ M * Real.exp (L * t))
    (hy : ∀ t ≥ 0, HasDerivWithinAt y (y' t) (Ici 0) t)
    (hy' : ∀ t ≥ 0, HasDerivWithinAt y' (y'' t) (Ici 0) t)
    (heq : ∀ t ≥ 0, y'' t + b * y' t + k * y t = f t) :
    ∃ L' : ℝ, ∀ s > L',
      IntegrableOn (fun t => Real.exp (-(s * t)) * y t) (Ioi 0) ∧
      (s ^ 2 + b * s + k) * ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * y t
        = (∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * f t) + (s + b) * y 0 + y' 0 := by
  have hG := laplace_growth_bound b k M L f y y' y'' hgrow hy hy' heq
  have hM : 0 ≤ M := le_trans (abs_nonneg _) (by simpa using hgrow 0 le_rfl)
  set α := |L| + (1 + |b| + |k|) with hα
  set C := max |y 0| |y' 0| + M with hC
  have hC0 : 0 ≤ C := by
    have := le_trans (abs_nonneg _) (le_max_left |y 0| |y' 0|); linarith
  have hLα : L ≤ α := by
    have := le_abs_self L; have := abs_nonneg b; have := abs_nonneg k; linarith
  have hyb : ∀ t ≥ 0, |y t| ≤ C * Real.exp (α * t) :=
    fun t ht => (le_max_left _ _).trans (hG t ht)
  have hy'b : ∀ t ≥ 0, |y' t| ≤ C * Real.exp (α * t) :=
    fun t ht => (le_max_right _ _).trans (hG t ht)
  have hfb : ∀ t ≥ 0, |f t| ≤ M * Real.exp (α * t) := fun t ht =>
    (hgrow t ht).trans (mul_le_mul_of_nonneg_left
      (Real.exp_le_exp.2 (mul_le_mul_of_nonneg_right hLα ht)) hM)
  have hy''b : ∀ t ≥ 0, |y'' t| ≤ (M + (|b| + |k|) * C) * Real.exp (α * t) := by
    intro t ht
    have e : y'' t = f t - b * y' t - k * y t := by linarith [heq t ht]
    have h1 : |y'' t| ≤ |f t| + |b| * |y' t| + |k| * |y t| := by
      rw [e, ← abs_mul, ← abs_mul]
      have := abs_sub (f t - b * y' t) (k * y t)
      have := abs_sub (f t) (b * y' t)
      linarith
    have hb1 := mul_le_mul_of_nonneg_left (hy'b t ht) (abs_nonneg b)
    have hk1 := mul_le_mul_of_nonneg_left (hyb t ht) (abs_nonneg k)
    have := hfb t ht
    nlinarith
  have hyc : ContinuousOn y (Ici 0) := fun t ht => (hy t ht).continuousWithinAt
  have hy'c : ContinuousOn y' (Ici 0) := fun t ht => (hy' t ht).continuousWithinAt
  have hy''c : ContinuousOn y'' (Ici 0) := by
    have h : ContinuousOn (fun t => f t - b * y' t - k * y t) (Ici 0) :=
      (hf.sub (continuousOn_const.mul hy'c)).sub (continuousOn_const.mul hyc)
    refine h.congr ?_
    intro t ht
    show y'' t = f t - b * y' t - k * y t
    linarith [heq t ht]
  refine ⟨α, fun s hs => ?_⟩
  obtain ⟨iy, ty⟩ := laplace_exp_bound_integrable hyc hyb hs
  obtain ⟨iy', ty'⟩ := laplace_exp_bound_integrable hy'c hy'b hs
  obtain ⟨iy'', -⟩ := laplace_exp_bound_integrable hy''c hy''b hs
  refine ⟨iy, ?_⟩
  have e1 := laplace_of_deriv hy iy iy' ty
  have e2 := laplace_of_deriv hy' iy' iy'' ty'
  have e3 : ∫ t in Ioi (0 : ℝ), Real.exp (-(s * t)) * f t
      = ∫ t in Ioi (0 : ℝ), (Real.exp (-(s * t)) * y'' t + b * (Real.exp (-(s * t)) * y' t))
          + k * (Real.exp (-(s * t)) * y t) := by
    refine setIntegral_congr_fun measurableSet_Ioi (fun t ht => ?_)
    show Real.exp (-(s * t)) * f t = _
    rw [← heq t (le_of_lt ht)]
    ring
  have i1 : IntegrableOn
      (fun t => Real.exp (-(s * t)) * y'' t + b * (Real.exp (-(s * t)) * y' t)) (Ioi 0) :=
    iy''.add (iy'.const_mul b)
  have i2 : IntegrableOn (fun t => b * (Real.exp (-(s * t)) * y' t)) (Ioi 0) := iy'.const_mul b
  have i3 : IntegrableOn (fun t => k * (Real.exp (-(s * t)) * y t)) (Ioi 0) := iy.const_mul k
  rw [integral_add i1 i3, integral_add iy'' i2, integral_const_mul, integral_const_mul] at e3
  rw [e3, e2, e1]
  ring

/-- The overshoot and the settling: the travel is largest at t = π/2 s (1.571 s) over all
t ≥ 0, where it reaches 2 + 2e^(-π/2) m (2.415759 m), and it settles toward the resting point
2 m as t grows. -/
theorem travel_peak_and_settle :
    IsMaxOn travel (Ici 0) (Real.pi / 2) ∧
    travel (Real.pi / 2) = 2 + 2 * Real.exp (-(Real.pi / 2)) ∧
    Tendsto travel atTop (𝓝 2) := by
  have hval : travel (Real.pi / 2) = 2 + 2 * Real.exp (-(Real.pi / 2)) := by
    unfold travel
    rw [show 2 * (Real.pi / 2) = Real.pi by ring, Real.cos_pi, Real.sin_pi]
    ring
  have hcont : Continuous travel := by unfold travel; fun_prop
  have hmono : MonotoneOn travel (Icc 0 (Real.pi / 2)) := by
    refine monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc _ _) hcont.continuousOn
      (fun x _ => (travel_hasDerivAt x).hasDerivWithinAt) ?_
    intro x hx
    rw [interior_Icc] at hx
    have : 0 ≤ Real.sin (2 * x) :=
      Real.sin_nonneg_of_nonneg_of_le_pi (by linarith [hx.1]) (by linarith [hx.2])
    positivity
  have hanti : AntitoneOn travel (Icc (Real.pi / 2) Real.pi) := by
    refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc _ _) hcont.continuousOn
      (fun x _ => (travel_hasDerivAt x).hasDerivWithinAt) ?_
    intro x hx
    rw [interior_Icc] at hx
    have h : 0 ≤ Real.sin (2 * x - Real.pi) :=
      Real.sin_nonneg_of_nonneg_of_le_pi (by linarith [hx.1]) (by linarith [hx.2])
    rw [Real.sin_sub_pi] at h
    have := Real.exp_pos (-x)
    nlinarith
  have hpi := Real.two_le_pi
  refine ⟨?_, hval, ?_⟩
  · intro t ht
    show travel t ≤ travel (Real.pi / 2)
    rcases le_total t (Real.pi / 2) with h1 | h1
    · exact hmono ⟨ht, h1⟩ ⟨by linarith, le_rfl⟩ h1
    rcases le_total t Real.pi with h2 | h2
    · exact hanti ⟨le_rfl, by linarith⟩ ⟨h1, h2⟩ h1
    rw [hval]
    unfold travel
    set A := Real.exp (-(Real.pi / 2))
    set B := Real.exp (Real.pi / 2)
    have hA : 0 < A := Real.exp_pos _
    have hAB : A * B = 1 := by rw [← Real.exp_add]; simp
    have hB : Real.pi / 2 + 1 ≤ B := Real.add_one_le_exp _
    have hte : Real.exp (-t) ≤ A * A := by
      rw [← Real.exp_add]; exact Real.exp_le_exp.2 (by linarith)
    have hX := (abs_le.1 (travel_abs_le t)).1
    have he := Real.exp_pos (-t)
    have h3A : 3 * A ≤ 2 := by nlinarith
    nlinarith [mul_le_mul_of_nonneg_left hX he.le]
  · have hlim : Tendsto (fun t => Real.exp (-t) * (2 * Real.cos (2 * t) + Real.sin (2 * t)))
        atTop (𝓝 0) := by
      refine squeeze_zero_norm (fun t => ?_)
        (by simpa using Real.tendsto_exp_neg_atTop_nhds_zero.const_mul 3)
      rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs, Real.abs_exp, mul_comm 3]
      exact mul_le_mul_of_nonneg_left (travel_abs_le t) (Real.exp_pos _).le
    have := (tendsto_const_nhds (x := (2 : ℝ))).sub hlim
    rw [sub_zero] at this
    exact this

/-! The card's exact worked numbers. -/

-- Resting point: the spring's 5 N/m balances the ram's 10 N at 10/5 = 2 m.
example : (10 : ℚ) / 5 = 2 := by norm_num
-- Partial fractions: 10 = 5A at s = 0 gives A = 2; 0 = A + C gives C = -2; 0 = 2A + D gives D = -4.
example : (10 : ℤ) = 5 * 2 ∧ (0 : ℤ) = 2 + (-2) ∧ (0 : ℤ) = 2 * 2 + (-4) := by norm_num
-- With those numbers, 10 = A(s^2 + 2s + 5) + (Cs + D)s for every s.
example (s : ℝ) : (10 : ℝ) = 2 * (s ^ 2 + 2 * s + 5) + (-2 * s - 4) * s := by ring
-- Completing the square, and splitting the numerator to match the table.
example (s : ℝ) : s ^ 2 + 2 * s + 5 = (s + 1) ^ 2 + 4 := by ring
example (s : ℝ) : -2 * s - 4 = -2 * (s + 1) - 2 := by ring
-- The characteristic roots -1 ± 2i: -1 + 2i is a root of s^2 + 2s + 5.
example : ((-1 : ℂ) + 2 * Complex.I) ^ 2 + 2 * ((-1 : ℂ) + 2 * Complex.I) + 5 = 0 := by
  ring_nf
  rw [Complex.I_sq]
  ring
-- The start: y(0) = 2 - (2·1 + 0) = 0, and y'(0) = 5·1·0 = 0.
example : (2 : ℤ) - (2 * 1 + 0) = 0 ∧ (5 : ℤ) * 1 * 0 = 0 := by norm_num
-- The oscillating push 10 cos t: 10s = (2s + 1)(s^2 + 2s + 5) + (-2s - 5)(s^2 + 1) for every s.
example (s : ℝ) : 10 * s = (2 * s + 1) * (s ^ 2 + 2 * s + 5) + (-2 * s - 5) * (s ^ 2 + 1) := by
  ring
-- Undetermined coefficients: 5K = 10 gives K = 2; c1 = -2 from y(0) = 0; -c1 + 2c2 = 0 gives c2 = -1.
example : (5 : ℤ) * 2 = 10 ∧ (2 : ℤ) + (-2) = 0 ∧ -(-2 : ℤ) + 2 * (-1) = 0 := by norm_num
-- Mistake 2, the sine's ½ dropped: the starting velocity is 2 - 2·2 = -2 m/s, not 0.
example : (2 : ℤ) - 2 * 2 = -2 := by norm_num

#print axioms forced_oscillator_from_rest_eq_round_trip_answer
#print axioms laplace_transform_of_linear_equation
#print axioms travel_peak_and_settle
