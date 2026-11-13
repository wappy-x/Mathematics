-- The butterfly and the implied density: if every call price is the discounted average of its payoff over a continuous finishing-price density with a finite mean, then minus the slope of the call price in strike is the discounted chance of finishing above the strike, its bend is the discounted density, butterflies divided by h² close in on that bend, and a butterfly pays a tent of height h and area h².
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open MeasureTheory Filter Topology

theorem butterfly_tail_hasDerivAt (g : ℝ → ℝ) (hg : Continuous g) (hint : Integrable g) (K : ℝ) :
    HasDerivAt (fun k => ∫ x in Set.Ioi k, g x) (-g K) K := by
  have h : (fun k => ∫ x in Set.Ioi k, g x) =
      fun k => (∫ x in Set.Ioi 0, g x) - ∫ x in (0:ℝ)..k, g x := by
    funext k
    have := intervalIntegral.integral_Ioi_sub_Ioi' (μ := volume) (a := 0) (b := k)
      hint.integrableOn hint.integrableOn
    linarith
  rw [h]
  exact (hg.integral_hasStrictDerivAt 0 K).hasDerivAt.const_sub _

theorem butterfly_integrable_of_total (f : ℝ → ℝ) (htotal : ∫ x, f x = 1) : Integrable f := by
  by_contra h
  rw [integral_undef h] at htotal
  norm_num at htotal

theorem butterfly_call_hasDerivAt
    (f : ℝ → ℝ) (hcont : Continuous f)
    (htotal : ∫ x, f x = 1) (hmean : Integrable (fun x => x * f x))
    (D : ℝ) (K : ℝ) :
    HasDerivAt (fun k => D * ∫ x in Set.Ioi k, (x - k) * f x)
      (-(D * ∫ x in Set.Ioi K, f x)) K := by
  have hf := butterfly_integrable_of_total f htotal
  have h : (fun k => D * ∫ x in Set.Ioi k, (x - k) * f x) =
      fun k => D * ((∫ x in Set.Ioi k, x * f x) - k * ∫ x in Set.Ioi k, f x) := by
    funext k
    congr 1
    rw [← integral_const_mul, ← integral_sub hmean.integrableOn (hf.integrableOn.const_mul k)]
    congr 1
    funext x
    ring
  rw [h]
  have h1 := butterfly_tail_hasDerivAt (fun x => x * f x) (continuous_id.mul hcont) hmean K
  have h2 := butterfly_tail_hasDerivAt f hcont hf K
  have h3 : HasDerivAt
      (fun k => D * ((∫ x in Set.Ioi k, x * f x) - k * ∫ x in Set.Ioi k, f x))
      (D * (-(K * f K) - (1 * (∫ x in Set.Ioi K, f x) + K * -f K))) K :=
    (h1.sub ((hasDerivAt_id' K).mul h2)).const_mul D
  convert h3 using 1
  ring

theorem butterfly_tent (K h x : ℝ) (hh : 0 < h) :
    max (x - (K - h)) 0 - 2 * max (x - K) 0 + max (x - (K + h)) 0
        = max (h - |x - K|) 0 := by
  rcases le_total x K with hx | hx
  · rw [abs_of_nonpos (by linarith)]
    rcases le_total x (K - h) with hx2 | hx2
    · rw [max_eq_right (by linarith), max_eq_right (by linarith), max_eq_right (by linarith),
        max_eq_right (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith), max_eq_right (by linarith),
        max_eq_left (by linarith)]; ring
  · rw [abs_of_nonneg (by linarith)]
    rcases le_total x (K + h) with hx2 | hx2
    · rw [max_eq_left (by linarith), max_eq_left (by linarith), max_eq_right (by linarith),
        max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_left (by linarith), max_eq_left (by linarith),
        max_eq_right (by linarith)]; ring

#print axioms butterfly_tail_hasDerivAt
#print axioms butterfly_integrable_of_total
#print axioms butterfly_call_hasDerivAt
#print axioms butterfly_tent

/-! The setting. `f` is the risk-neutral density of Acme's finishing price `S_T`: a continuous
(no price carries a positive chance on its own), nonnegative function with total area 1 whose
mean `∫ x f(x) dx` exists (the forward). `D > 0` is the known discount factor, the price today
of $1 paid at expiry. The European call struck at `K` costs the discounted average payoff,
`C(K) = D ∫_K^∞ (x - K) f(x) dx`, for every strike `K`. The survival curve is
`G(K) = ∫_K^∞ f(x) dx`, the chance of finishing above `K`. -/

/-- **Breeden–Litzenberger: the bend of the call price in strike is the discounted density**
(The formula; Why it works, Steps 1 to 4). Let call prices at every strike be discounted
averages of the payoff over a continuous probability density `f` with a finite mean, with
discount factor `D > 0`. Then at every strike `K` the slope of the call price curve changes at rate
`D f(K)`: differentiate twice in strike and the density falls out after one undo of
discounting. And the quoted version holds too: the butterfly `C(K-h) - 2C(K) + C(K+h)` divided by
the tent's area `h²` tends to that same bend `D f(K)` as the half-width `h` shrinks to zero. -/
theorem call_bend_in_strike_eq_discounted_density
    (f : ℝ → ℝ) (hcont : Continuous f) (hnonneg : ∀ x, 0 ≤ f x)
    (htotal : ∫ x, f x = 1) (hmean : Integrable (fun x => x * f x))
    (D : ℝ) (hD : 0 < D) (K : ℝ) :
    let C : ℝ → ℝ := fun k => D * ∫ x in Set.Ioi k, (x - k) * f x
    HasDerivAt (deriv C) (D * f K) K ∧
      Tendsto (fun h => (C (K - h) - 2 * C K + C (K + h)) / h ^ 2) (𝓝[>] 0)
        (𝓝 (D * f K)) := by
  intro C
  have hf := butterfly_integrable_of_total f htotal
  have hC : ∀ k, HasDerivAt C (-(D * ∫ x in Set.Ioi k, f x)) k := fun k =>
    butterfly_call_hasDerivAt f hcont htotal hmean D k
  have hderiv : deriv C = fun k => -(D * ∫ x in Set.Ioi k, f x) :=
    funext fun k => (hC k).deriv
  have hP : ∀ k, HasDerivAt (deriv C) (D * f k) k := by
    intro k
    rw [hderiv]
    exact ((butterfly_tail_hasDerivAt f hcont hf k).const_mul D).neg.congr_deriv (by ring)
  have hC' : ∀ k, HasDerivAt C (deriv C k) k := fun k => (hC k).differentiableAt.hasDerivAt
  refine ⟨hP K, ?_⟩
  set P := deriv C with hPdef
  have hCcont : Continuous C := continuous_iff_continuousAt.2 fun k => (hC k).continuousAt
  have hNcont : Continuous (fun h => C (K - h) - 2 * C K + C (K + h)) := by fun_prop
  apply HasDerivAt.lhopital_zero_right_on_Ioo (b := 1) one_pos
    (f' := fun h => -P (K - h) + P (K + h)) (g' := fun h => 2 * h)
  · intro h _
    have h1 := (hC' (K - h)).comp_const_sub K h
    have h2 := (hC' (K + h)).comp_const_add K h
    exact (h1.sub_const (2 * C K)).add h2
  · intro h _
    simpa using hasDerivAt_pow 2 h
  · intro h hh
    exact mul_ne_zero two_ne_zero hh.1.ne'
  · have := (hNcont.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    convert this using 2
    simp only [sub_zero, add_zero]
    ring
  · have := ((continuous_pow 2).tendsto (0:ℝ)).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    simpa using this
  · have T := hasDerivAt_iff_tendsto_slope_zero.1 (hP K)
    have T1 := T.mono_left (nhdsWithin_mono _
      (show Set.Ioi (0:ℝ) ⊆ {0}ᶜ from fun x hx => (Set.mem_Ioi.1 hx).ne'))
    have hneg : Tendsto (fun h : ℝ => -h) (𝓝[>] 0) (𝓝[≠] 0) := by
      apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
      · have := ((continuous_neg.tendsto (0:ℝ)).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0)))
        simpa using this
      · exact eventually_nhdsWithin_of_forall fun x (hx : 0 < x) => by
          simp [hx.ne']
    have T2 := T.comp hneg
    have T3 := (T1.add T2).div_const 2
    rw [show (D * f K + D * f K) / 2 = D * f K by ring] at T3
    apply T3.congr'
    filter_upwards [self_mem_nhdsWithin] with h (hh : 0 < h)
    simp only [Function.comp, smul_eq_mul, ← sub_eq_add_neg]
    field_simp
    ring

/-- **One derivative gives the cash digital** (Why it works, Steps 1 and 2). With call prices
the discounted averages of the payoff over a continuous probability density `f` with a finite
mean, and discount factor `D > 0`: at every strike `K`, the call price has slope
`-D G(K)`, where `G(K) = ∫_K^∞ f` is the chance of finishing above `K`. Minus the slope is the
discounted chance of finishing above the strike: the price of the cash digital. -/
theorem call_slope_in_strike_eq_neg_discounted_chance_above
    (f : ℝ → ℝ) (hcont : Continuous f) (hnonneg : ∀ x, 0 ≤ f x)
    (htotal : ∫ x, f x = 1) (hmean : Integrable (fun x => x * f x))
    (D : ℝ) (hD : 0 < D) (K : ℝ) :
    HasDerivAt (fun k => D * ∫ x in Set.Ioi k, (x - k) * f x)
      (-(D * ∫ x in Set.Ioi K, f x)) K := by
  exact butterfly_call_hasDerivAt f hcont htotal hmean D K

/-- **A butterfly pays a tent of height `h` and area `h²`** (Step 0). Long one call at `K - h`,
short two at `K`, long one at `K + h`, with half-width `h > 0`: at every finishing price `x` the
payoff is `max (h - |x - K|) 0`, a tent peaking at `h` over the strike and zero outside
`[K - h, K + h]`; and the area under that payoff is `h²`. -/
theorem butterfly_payoff_is_tent_of_area_sq
    (K h : ℝ) (hh : 0 < h) :
    (∀ x : ℝ, max (x - (K - h)) 0 - 2 * max (x - K) 0 + max (x - (K + h)) 0
        = max (h - |x - K|) 0) ∧
      ∫ x, (max (x - (K - h)) 0 - 2 * max (x - K) 0 + max (x - (K + h)) 0) = h ^ 2 := by
  have e : ∀ x : ℝ, max (x - (K - h)) 0 - 2 * max (x - K) 0 + max (x - (K + h)) 0
        = max (h - |x - K|) 0 := fun x => butterfly_tent K h x hh
  refine ⟨e, ?_⟩
  simp_rw [e]
  rw [integral_sub_right_eq_self (fun x => max (h - |x|) 0) K]
  rw [← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Set.Ioc (-h) h)]
  swap
  · intro x hx
    simp only [Set.mem_Ioc, not_and_or, not_lt, not_le] at hx
    apply max_eq_right
    rcases hx with hx | hx
    · have : h ≤ |x| := by rw [abs_of_neg (by linarith)]; linarith
      linarith
    · have : h ≤ |x| := by rw [abs_of_pos (by linarith)]; linarith
      linarith
  rw [← intervalIntegral.integral_of_le (by linarith)]
  have hc : Continuous (fun x : ℝ => max (h - |x|) 0) := by fun_prop
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := 0)
    (hc.intervalIntegrable _ _) (hc.intervalIntegrable _ _)]
  have e1 : ∫ x in (-h)..0, max (h - |x|) 0 = ∫ x in (-h)..0, (h + x) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by linarith)] at hx
    simp only
    rw [abs_of_nonpos hx.2, max_eq_left (by linarith [hx.1])]
    ring
  have e2 : ∫ x in (0:ℝ)..h, max (h - |x|) 0 = ∫ x in (0:ℝ)..h, (h - x) := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by linarith)] at hx
    simp only
    rw [abs_of_nonneg hx.1, max_eq_left (by linarith [hx.2])]
  rw [e1, e2]
  rw [intervalIntegral.integral_add intervalIntegrable_const intervalIntegral.intervalIntegrable_id,
    intervalIntegral.integral_sub intervalIntegrable_const intervalIntegral.intervalIntegrable_id]
  simp [integral_id]
  ring

-- The picture: the 90/100/110 butterfly pays 0, 0, 0, 5, 10, 5, 0, 0, 0
-- when Acme finishes at 80, 85, 90, 95, 100, 105, 110, 115, 120.
example : (List.map (fun x : ℤ => max (x - 90) 0 - 2 * max (x - 100) 0 + max (x - 110) 0)
    [80, 85, 90, 95, 100, 105, 110, 115, 120]) = [0, 0, 0, 5, 10, 5, 0, 0, 0] := by decide
-- Payoff less its price of $1.86 at 80 and at 100: -1.86 and 8.14 (in cents).
example : (0 : ℤ) - 186 = -186 ∧ (1000 : ℤ) - 186 = 814 := by decide
-- The tent's area: half-width 10, height 10, area 10 × 10 = 100 square dollars.
example : (10 : ℤ) * 10 = 100 := by decide
-- Above K + h the slopes cancel: +1 - 2 + 1 = 0.
example : (1 : ℤ) - 2 + 1 = 0 := by decide
-- The house market at K = 100: K σ √T = 100 × 0.20 × 1 = 20.
example : (100 : ℚ) * (1 / 5) * 1 = 20 := by norm_num
-- d₂ at K = S = 100: (ln 1 + (0.05 - 0.02 - 0.02) × 1) / 0.20 = 0.05.
example : ((5 / 100 : ℚ) - 2 / 100 - (1 / 5) ^ 2 / 2) * 1 / (1 / 5) = 1 / 20 := by norm_num

#print axioms call_bend_in_strike_eq_discounted_density
#print axioms call_slope_in_strike_eq_neg_discounted_chance_above
#print axioms butterfly_payoff_is_tent_of_area_sq
