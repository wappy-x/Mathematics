-- Mixing tanks: a stirred tank whose sugar obeys S' = q·c_in − q·S/V must follow S = V·c_in + (S(0) − V·c_in)·e^(−t/(V/q)), that formula does solve the equation and heads to V·c_in, and with 5 L/min in and 4 L/min out the tank must follow S = (200 + t)/20 − 6·(200/(200 + t))^4.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Pow

open Real Set Filter Topology

/-- Helper: a function with zero right-derivative on `[0, ∞)` is constant there. -/
lemma mt_const_of_deriv_zero (f : ℝ → ℝ)
    (hf : ∀ t, 0 ≤ t → HasDerivWithinAt f 0 (Ici 0) t) : ∀ t, 0 ≤ t → f t = f 0 := by
  intro t ht
  have hcont : ContinuousOn f (Icc 0 t) := fun x hx =>
    ((hf x hx.1).continuousWithinAt).mono Icc_subset_Ici_self
  exact constant_of_has_deriv_right_zero hcont
    (fun x hx => (hf x hx.1).mono (Ici_subset_Ici.2 hx.1)) t ⟨ht, le_rfl⟩

/-- A well-mixed tank of fixed volume V > 0 is fed and drained at the same flow q > 0, the feed
carrying c_in per litre, with nothing made or destroyed inside. If, from the start t = 0 on, the
amount S changes at the rate in minus the rate out, S' = q·c_in − q·(S/V), and starts at S₀, then
at every time t ≥ 0 it equals S∞ + (S₀ − S∞)·e^(−t/τ), with S∞ = V·c_in and τ = V/q. -/
theorem mixing_tank_amount_eq_formula
    (V q c_in S₀ : ℝ) (hV : 0 < V) (hq : 0 < q) (S : ℝ → ℝ)
    (hS : ∀ t, 0 ≤ t → HasDerivWithinAt S (q * c_in - q * (S t / V)) (Ici 0) t)
    (h0 : S 0 = S₀) :
    ∀ t, 0 ≤ t → S t = V * c_in + (S₀ - V * c_in) * exp (-t / (V / q)) := by
  intro t ht
  have hVq : 0 < V / q := div_pos hV hq
  set τ := V / q with hτ
  let g : ℝ → ℝ := fun t => (S t - V * c_in) * exp (t / τ)
  have hg : ∀ t, 0 ≤ t → HasDerivWithinAt g 0 (Ici 0) t := by
    intro t ht
    have h1 := (hS t ht).sub_const (V * c_in)
    have h2 : HasDerivAt (fun t => exp (t / τ)) (exp (t / τ) * (1 / τ)) t := by
      have := ((hasDerivAt_id t).div_const τ).exp
      simpa using this
    have h3 := h1.mul h2.hasDerivWithinAt
    convert h3 using 1
    rw [hτ]
    field_simp
    ring
  have key := mt_const_of_deriv_zero g hg t ht
  simp only [g, h0, zero_div, exp_zero, mul_one] at key
  have he : exp (t / τ) * exp (-t / τ) = 1 := by
    rw [← exp_add, neg_div, add_neg_cancel, exp_zero]
  calc S t = V * c_in + (S t - V * c_in) * exp (t / τ) * exp (-t / τ) := by
        rw [mul_assoc, he]; ring
    _ = V * c_in + (S₀ - V * c_in) * exp (-t / τ) := by rw [key]

/-- The formula really is a solution: S(t) = V·c_in + (S₀ − V·c_in)·e^(−t/(V/q)) starts at S₀,
changes at rate q·c_in − q·(S/V) at every time, and heads to V·c_in, the level where the tank is
as strong as the feed. -/
theorem mixing_tank_formula_solves_and_settles
    (V q c_in S₀ : ℝ) (hV : 0 < V) (hq : 0 < q) :
    let S : ℝ → ℝ := fun t => V * c_in + (S₀ - V * c_in) * exp (-t / (V / q))
    S 0 = S₀ ∧ (∀ t, HasDerivAt S (q * c_in - q * (S t / V)) t) ∧
      Tendsto S atTop (𝓝 (V * c_in)) := by
  intro S
  refine ⟨by simp [S], fun t => ?_, ?_⟩
  · have hd : HasDerivAt (fun x : ℝ => -x / (V / q)) (-1 / (V / q)) t :=
      (hasDerivAt_neg t).div_const (V / q)
    have := ((hd.exp).const_mul (S₀ - V * c_in)).const_add (V * c_in)
    simp only [S]
    convert this using 1
    field_simp
    ring
  · have hlin : Tendsto (fun t : ℝ => -t / (V / q)) atTop atBot :=
      tendsto_neg_atTop_atBot.atBot_div_const (div_pos hV hq)
    have := ((tendsto_exp_atBot.comp hlin).const_mul (S₀ - V * c_in)).const_add (V * c_in)
    simpa using this

/-- Unequal flows: the 200 L brewing tank with 4 kg of sugar is fed 5 L/min of syrup at 1/20 kg/L
but drained at only 4 L/min, so at time t it holds 200 + t litres and the sugar obeys
S' = 1/4 − 4·S/(200 + t). Then for every t ≥ 0, S(t) = (200 + t)/20 − 6·(200/(200 + t))^4. -/
theorem unequal_flow_tank_amount_eq_formula
    (S : ℝ → ℝ)
    (hS : ∀ t, 0 ≤ t → HasDerivWithinAt S (1 / 4 - 4 * (S t / (200 + t))) (Ici 0) t)
    (h0 : S 0 = 4) :
    ∀ t, 0 ≤ t → S t = (200 + t) / 20 - 6 * (200 / (200 + t)) ^ 4 := by
  let g : ℝ → ℝ := fun t => (S t - (200 + t) / 20) * (200 + t) ^ 4
  have hg : ∀ t, 0 ≤ t → HasDerivWithinAt g 0 (Ici 0) t := by
    intro t ht
    have hp : (200 + t) ≠ 0 := by positivity
    have hl : HasDerivAt (fun t : ℝ => 200 + t) 1 t := (hasDerivAt_id t).const_add 200
    have h1 := (hS t ht).sub (hl.div_const 20).hasDerivWithinAt
    have h2 := (hl.pow 4).hasDerivWithinAt (s := Ici 0)
    have h3 := h1.mul h2
    convert h3 using 1
    simp only [Pi.sub_apply, Pi.pow_apply, Nat.cast_ofNat]
    field_simp
    ring
  intro t ht
  have key := mt_const_of_deriv_zero g hg t ht
  simp only [g] at key
  rw [h0] at key
  have hpos : (0 : ℝ) < 200 + t := by positivity
  have k2 : S t - (200 + t) / 20 = -6 * 200 ^ 4 / (200 + t) ^ 4 := by
    rw [eq_div_iff (by positivity)]
    norm_num at key ⊢
    linarith
  have k3 : -6 * 200 ^ 4 / (200 + t) ^ 4 = -(6 * (200 / (200 + t)) ^ 4) := by
    rw [div_pow]; ring
  linarith

-- The brewery's formula: V = 200 L, q = 5 L/min, c_in = 1/20 kg/L, S₀ = 4 kg give
-- S = 10 − 6·e^(−t/40).
example (t : ℝ) :
    (200 : ℝ) * (1 / 20) + (4 - 200 * (1 / 20)) * exp (-t / (200 / 5)) = 10 - 6 * exp (-t / 40) := by
  norm_num
  ring

-- Worked numbers: sugar in 5 × 1/20 = 1/4 kg/min; out at the start 5 × 4/200 = 1/10 kg/min;
-- net 1/4 − 1/10 = 3/20 kg/min; level where in = out 1/20 × 200 = 10 kg; time constant
-- 200/5 = 40 min; constant C from 4 = 10 + C is −6.
example : (5 : ℚ) * (1 / 20) = 1 / 4 ∧ (5 : ℚ) * (4 / 200) = 1 / 10 ∧
    (1 / 4 : ℚ) - 1 / 10 = 3 / 20 ∧ (1 / 20 : ℚ) * 200 = 10 ∧ (200 : ℚ) / 5 = 40 ∧
    (4 : ℚ) = 10 + (-6) := by
  norm_num

-- The start's rate from the formula, 6/40, matches the bookkeeping, 3/20 kg/min.
example : (6 : ℚ) / 40 = 3 / 20 := by norm_num

-- The drug drip: 20 mg/h into 40 L cleared at 5 L/h settles at 20/(5/40) = 160 mg = 4 mg/L,
-- which is rate in over clearance, 20/5; the time constant is 40/5 = 8 h.
example : (20 : ℚ) / (5 / 40) = 160 ∧ (160 : ℚ) / 40 = 4 ∧ (20 : ℚ) / 5 = 4 ∧ (40 : ℚ) / 5 = 8 := by
  norm_num

-- Unequal flows: the start fixes C by 200^4 × 4 = (1/20) × 200^5 + C with C = −6 × 200^4,
-- and at 60 minutes the tank holds 200 + 60 = 260 L.
example : (200 : ℚ) ^ 4 * 4 = 1 / 20 * 200 ^ 5 + (-6 * 200 ^ 4) ∧ (200 : ℚ) + 60 = 260 := by
  norm_num

-- The usual mistake, outflow 5S instead of 5S/200: the level where in = out is 1/4 ÷ 5 = 1/20 kg.
example : (1 / 4 : ℚ) / 5 = 1 / 20 := by rw [div_div]; norm_num

#print axioms mt_const_of_deriv_zero
#print axioms mixing_tank_amount_eq_formula
#print axioms mixing_tank_formula_solves_and_settles
#print axioms unequal_flow_tank_amount_eq_formula
