-- Second derivatives: a function whose second derivative is negative throughout an open interval has its graph strictly below each of its tangent lines there, the second difference (f(t+h) - 2f(t) + f(t-h))/h² heads for f''(t) as the window h shrinks, and the card's car s(t) = (3/2)t² - (1/10)t³ has velocity 3t - (3/10)t², acceleration 3 - (3/5)t, jerk -3/5, and a central second difference equal to its acceleration at every window.
import Mathlib.Analysis.Convex.Deriv
import Mathlib.Analysis.Calculus.LHopital
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Tactic.NormNum

open Filter Topology

/-- Concave down lies below its tangents (the card's Detailed proof). Let I be an open interval
of the real line (it may run on forever at either end). Suppose f has a derivative f' at every
point of I, f' itself has a derivative f'' at every point of I, and f'' is negative throughout I.
Then for any two different points a and t of I, the graph at t lies strictly below the tangent
line drawn at a: f(t) < f(a) + f'(a)(t - a). -/
theorem graph_below_tangent_of_second_deriv_neg {I : Set ℝ} (hIo : IsOpen I) (hIc : Convex ℝ I)
    {f : ℝ → ℝ} (hf : DifferentiableOn ℝ f I) (hf' : DifferentiableOn ℝ (deriv f) I)
    (hneg : ∀ x ∈ I, deriv (deriv f) x < 0)
    {a t : ℝ} (ha : a ∈ I) (ht : t ∈ I) (hat : a ≠ t) :
    f t < f a + deriv f a * (t - a) := by
  have hc : StrictConcaveOn ℝ I f :=
    strictConcaveOn_of_deriv2_neg' hIc hf.continuousOn (fun x hx => by
      simpa [Function.iterate_succ] using hneg x hx)
  have hda : DifferentiableAt ℝ f a := hf.differentiableAt (hIo.mem_nhds ha)
  rcases lt_or_gt_of_ne hat with h | h
  · have := hc.slope_lt_deriv ha ht h hda
    rw [slope_def_field, div_lt_iff₀ (by linarith)] at this
    linarith
  · have := hc.deriv_lt_slope ht ha h hda
    rw [slope_def_field, lt_div_iff₀ (by linarith)] at this
    linarith

/-- The second derivative straight from positions. Suppose f has a derivative on a stretch around
t, and that derivative has a derivative f''(t) at t (no corner). Then the difference of
differences (f(t + h) - 2 f(t) + f(t - h)) / h² heads for f''(t) as the window h shrinks to 0,
with h = 0 itself left out. -/
theorem second_difference_tends_to_second_deriv {f : ℝ → ℝ} {t : ℝ}
    (hf : ∀ᶠ x in 𝓝 t, DifferentiableAt ℝ f x) (hf' : DifferentiableAt ℝ (deriv f) t) :
    Tendsto (fun h : ℝ => (f (t + h) - 2 * f t + f (t - h)) / h ^ 2) (𝓝[≠] 0)
      (𝓝 (deriv (deriv f) t)) := by
  -- differentiability of f near t, transported to h near 0
  have hplus : ∀ᶠ h in 𝓝 (0:ℝ), DifferentiableAt ℝ f (t + h) := by
    have hc : Tendsto (fun h : ℝ => t + h) (𝓝 0) (𝓝 t) := by
      simpa using (tendsto_const_nhds (x := t) (f := 𝓝 (0:ℝ))).add tendsto_id
    exact hc.eventually hf
  have hminus : ∀ᶠ h in 𝓝 (0:ℝ), DifferentiableAt ℝ f (t - h) := by
    have hc : Tendsto (fun h : ℝ => t - h) (𝓝 0) (𝓝 t) := by
      simpa using (tendsto_const_nhds (x := t) (f := 𝓝 (0:ℝ))).sub tendsto_id
    exact hc.eventually hf
  have hft : DifferentiableAt ℝ f t := hf.self_of_nhds
  have hff' : ∀ᶠ h in 𝓝[≠] (0:ℝ), HasDerivAt (fun h => f (t + h) - 2 * f t + f (t - h))
      (deriv f (t + h) - deriv f (t - h)) h := by
    refine nhdsWithin_le_nhds ((hplus.and hminus).mono fun h ⟨h1, h2⟩ => ?_)
    have e1 : HasDerivAt (fun h => f (t + h)) (deriv f (t + h)) h := by
      have := h1.hasDerivAt.comp h ((hasDerivAt_id h).const_add t)
      simpa [Function.comp_def] using this
    have e2 : HasDerivAt (fun h => f (t - h)) (deriv f (t - h) * (-1)) h := by
      have := h2.hasDerivAt.comp h ((hasDerivAt_id h).const_sub t)
      simpa [Function.comp_def] using this
    have := (e1.sub_const (2 * f t)).add e2
    convert this using 1
    ring
  have hgg' : ∀ᶠ h in 𝓝[≠] (0:ℝ), HasDerivAt (fun h : ℝ => h ^ 2) (2 * h) h :=
    Eventually.of_forall fun h => by simpa using hasDerivAt_pow 2 h
  have hg' : ∀ᶠ h in 𝓝[≠] (0:ℝ), 2 * h ≠ 0 :=
    eventually_mem_nhdsWithin.mono fun h hh => mul_ne_zero two_ne_zero hh
  have hfa : Tendsto (fun h => f (t + h) - 2 * f t + f (t - h)) (𝓝[≠] (0:ℝ)) (𝓝 0) := by
    have hcont : ContinuousAt (fun h => f (t + h) - 2 * f t + f (t - h)) 0 := by
      have c1 : ContinuousAt (fun h => f (t + h)) 0 :=
        ContinuousAt.comp (g := f) (by simpa using hft.continuousAt)
          (continuous_const.add continuous_id).continuousAt
      have c2 : ContinuousAt (fun h => f (t - h)) 0 :=
        ContinuousAt.comp (g := f) (by simpa using hft.continuousAt)
          (continuous_const.sub continuous_id).continuousAt
      exact (c1.sub continuousAt_const).add c2
    have := hcont.tendsto
    simp only [add_zero, sub_zero] at this
    have h0 : f t - 2 * f t + f t = 0 := by ring
    rw [h0] at this
    exact this.mono_left nhdsWithin_le_nhds
  have hga : Tendsto (fun h : ℝ => h ^ 2) (𝓝[≠] (0:ℝ)) (𝓝 0) := by
    have : Tendsto (fun h : ℝ => h ^ 2) (𝓝 (0:ℝ)) (𝓝 0) := by
      simpa using ((continuous_pow 2).tendsto (0:ℝ))
    exact this.mono_left nhdsWithin_le_nhds
  have hdiv : Tendsto (fun h => (deriv f (t + h) - deriv f (t - h)) / (2 * h)) (𝓝[≠] (0:ℝ))
      (𝓝 (deriv (deriv f) t)) := by
    have H := hf'.hasDerivAt.tendsto_slope_zero
    have Hneg : Tendsto (fun h : ℝ => (-h)⁻¹ • (deriv f (t + -h) - deriv f t)) (𝓝[≠] (0:ℝ))
        (𝓝 (deriv (deriv f) t)) := by
      have hm : Tendsto (fun h : ℝ => -h) (𝓝[≠] (0:ℝ)) (𝓝[≠] 0) := by
        refine tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within _ ?_ ?_
        · exact (by simpa using (continuous_neg.tendsto (0:ℝ)) :
            Tendsto (fun h : ℝ => -h) (𝓝 0) (𝓝 0)).mono_left nhdsWithin_le_nhds
        · exact eventually_mem_nhdsWithin.mono fun h hh => by simpa using hh
      exact H.comp hm
    have := (H.add Hneg).div_const 2
    rw [show (deriv (deriv f) t + deriv (deriv f) t) / 2 = deriv (deriv f) t by ring] at this
    refine this.congr' (eventually_mem_nhdsWithin.mono fun h hh => ?_)
    have hh' : h ≠ 0 := hh
    simp only [smul_eq_mul, ← sub_eq_add_neg]
    field_simp
    ring
  exact HasDerivAt.lhopital_zero_nhdsNE hff' hgg' hg' hfa hga hdiv

/-- The car (Steps 1 and 2). The odometer s(t) = (3/2)t² - (1/10)t³ metres at t seconds has
velocity 3t - (3/10)t², acceleration 3 - (3/5)t and jerk -3/5 at every instant, and its central
second difference (s(t + h) - 2 s(t) + s(t - h)) / h² equals the acceleration exactly, for every
window h other than 0. -/
theorem car_derivatives_and_exact_central_difference (t : ℝ) :
    let s : ℝ → ℝ := fun u => 3 / 2 * u ^ 2 - 1 / 10 * u ^ 3
    deriv s t = 3 * t - 3 / 10 * t ^ 2 ∧
      deriv (deriv s) t = 3 - 3 / 5 * t ∧
      deriv (deriv (deriv s)) t = -3 / 5 ∧
      ∀ h : ℝ, h ≠ 0 → (s (t + h) - 2 * s t + s (t - h)) / h ^ 2 = 3 - 3 / 5 * t := by
  intro s
  have d1 : deriv s = fun u => 3 * u - 3 / 10 * u ^ 2 := by
    funext u
    have := ((hasDerivAt_pow 2 u).const_mul (3 / 2 : ℝ)).sub
      ((hasDerivAt_pow 3 u).const_mul (1 / 10 : ℝ))
    rw [this.deriv.symm.trans (by rfl : deriv (fun x => 3 / 2 * x ^ 2 - 1 / 10 * x ^ 3) u = deriv s u) |>.symm]
    push_cast; ring
  have d2 : deriv (deriv s) = fun u => 3 - 3 / 5 * u := by
    rw [d1]; funext u
    have : HasDerivAt (fun u : ℝ => 3 * u - 3 / 10 * u ^ 2) (3 * 1 - 3 / 10 * (↑2 * u ^ (2 - 1))) u :=
      ((hasDerivAt_id u).const_mul (3 : ℝ)).sub ((hasDerivAt_pow 2 u).const_mul (3 / 10 : ℝ))
    rw [this.deriv]
    norm_num; ring
  have d3 : deriv (deriv (deriv s)) = fun _ => -3 / 5 := by
    rw [d2]; funext u
    have : HasDerivAt (fun u : ℝ => 3 - 3 / 5 * u) (0 - 3 / 5 * 1) u :=
      (hasDerivAt_const u (3:ℝ)).sub ((hasDerivAt_id u).const_mul (3 / 5 : ℝ))
    rw [this.deriv]; ring
  refine ⟨by rw [d1], by rw [d2], by rw [d3], fun h hh => ?_⟩
  simp only [s]
  field_simp
  ring

-- Odometer readings at 6, 7 and 8 s: 32.4, 39.2 and 44.8 m, written as fractions.
example : (3 / 2 * 6 ^ 2 - 1 / 10 * 6 ^ 3 : ℚ) = 162 / 5 ∧ (3 / 2 * 7 ^ 2 - 1 / 10 * 7 ^ 3 : ℚ) = 196 / 5 ∧
    (3 / 2 * 8 ^ 2 - 1 / 10 * 8 ^ 3 : ℚ) = 224 / 5 := by norm_num
-- Metres in the seventh and eighth seconds, 6.8 and 5.6; their difference -1.2 matches 3 - 0.6 × 7.
example : (196 / 5 - 162 / 5 : ℚ) = 34 / 5 ∧ (224 / 5 - 196 / 5 : ℚ) = 28 / 5 ∧
    (28 / 5 - 34 / 5 : ℚ) = -6 / 5 ∧ (3 - 3 / 5 * 7 : ℚ) = -6 / 5 := by norm_num
-- Velocity at 7 s is 6.3 m/s; squaring it by mistake gives 39.69.
example : (3 * 7 - 3 / 10 * 7 ^ 2 : ℚ) = 63 / 10 ∧ (63 / 10 : ℚ) ^ 2 = 3969 / 100 := by norm_num
-- Tangent at 7 s predicts 45.5 m at 8 s; the car is at 44.8 m, a gap of -0.7 = 1² × (-0.6 - 0.1).
example : (196 / 5 + 63 / 10 * 1 : ℚ) = 91 / 2 ∧ (224 / 5 - 91 / 2 : ℚ) = -7 / 10 ∧
    (1 ^ 2 * (-3 / 5 - 1 / 10 * 1) : ℚ) = -7 / 10 := by norm_num
-- Inflection at 5 s: acceleration 0, position 25 m, top speed 7.5 m/s.
example : (3 - 3 / 5 * 5 : ℚ) = 0 ∧ (3 / 2 * 5 ^ 2 - 1 / 10 * 5 ^ 3 : ℚ) = 25 ∧
    (3 * 5 - 3 / 10 * 5 ^ 2 : ℚ) = 15 / 2 := by norm_num
-- One-sided second difference at 7 s with h = 1: -1.8 = -1.2 - 0.6 × 1 (s(9) = 48.6 m).
example : (3 / 2 * 9 ^ 2 - 1 / 10 * 9 ^ 3 : ℚ) = 243 / 5 ∧
    (243 / 5 - 2 * (224 / 5) + 196 / 5 : ℚ) = -9 / 5 ∧ (-6 / 5 - 3 / 5 * 1 : ℚ) = -9 / 5 := by norm_num
-- At 10 s the car stops: velocity 0, acceleration -3, so curvature |-3| / (1 + 0²)^(3/2) = 3.
example : (3 * 10 - 3 / 10 * 10 ^ 2 : ℚ) = 0 ∧ (3 - 3 / 5 * 10 : ℚ) = -3 ∧ |(-3 : ℚ)| / (1 + 0 ^ 2) = 3 := by
  norm_num
-- f(t) = t⁴: second derivative 12t² is 0 at 0 but 0.12 at -0.1 and at 0.1, so no sign change.
example : (12 * 0 ^ 2 : ℚ) = 0 ∧ (12 * (-1 / 10) ^ 2 : ℚ) = 3 / 25 ∧ (12 * (1 / 10) ^ 2 : ℚ) = 3 / 25 := by
  norm_num

#print axioms graph_below_tangent_of_second_deriv_neg
#print axioms second_difference_tends_to_second_deriv
#print axioms car_derivatives_and_exact_central_difference
