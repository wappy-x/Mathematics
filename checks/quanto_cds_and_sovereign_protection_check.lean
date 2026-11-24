-- Quanto CDS: with the euro dropping by gam at the default instant, the drift a = rd - rf + gam * lam keeps a euro deposit fair in dollars, both legs of the euro contract carry one shared weight, the euro spread is (1 - gam) times the dollar spread, and the drop is one minus the ratio of the two quotes.
import Mathlib

open Real

/-- The drift that keeps a euro deposit fair. Between jumps the euro drifts at
`a = rd - rf + gam * lam` in dollars; at a default, which arrives at hazard `lam`, it drops by
the fraction `gam`; after default it drifts at `rd - rf`. Averaged over the default date, the
deposit's dollar value, discounted at `rd` and divided by today's rate, is 1 at every date `t`:
the survivors' value plus the defaulted paths' value, integrated over the default date `s`. -/
theorem euro_deposit_stays_fair (rd rf lam gam t : ℝ) :
    exp ((rd - rf + gam * lam + rf - rd) * t) * exp (-lam * t) +
      (∫ s in (0)..t, lam * exp (-lam * s) * ((1 - gam) * exp ((rd - rf + gam * lam + rf - rd) * s))) = 1 := by
  have hpt : ∀ s : ℝ, lam * exp (-lam * s) * ((1 - gam) * exp ((rd - rf + gam * lam + rf - rd) * s)) =
      (1 - gam) * lam * exp (-((1 - gam) * lam) * s) := by
    intro s
    have : exp (-lam * s) * exp ((rd - rf + gam * lam + rf - rd) * s) = exp (-((1 - gam) * lam) * s) := by
      rw [← exp_add]; congr 1; ring
    linear_combination (1 - gam) * lam * this
  simp only [hpt]
  have hderiv : ∀ s ∈ Set.uIcc 0 t, HasDerivAt (fun s => -exp (-((1 - gam) * lam) * s))
      ((1 - gam) * lam * exp (-((1 - gam) * lam) * s)) s := by
    intro s _
    have := (((hasDerivAt_id' s).const_mul (-((1 - gam) * lam))).exp).neg
    convert this using 1
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv
    ((by fun_prop : Continuous fun s => (1 - gam) * lam * exp (-((1 - gam) * lam) * s)).intervalIntegrable _ _)]
  have h1 : exp ((rd - rf + gam * lam + rf - rd) * t) * exp (-lam * t) = exp (-((1 - gam) * lam) * t) := by
    rw [← exp_add]; congr 1; ring
  rw [h1]
  simp

/-- The shared weight. Today's dollar value of one euro due at `t`, counted only if the name is
alive: discount `e^(-rd t)`, average rate `X0 e^(a t)` with `a = rd - rf + gam * lam`, survival
`e^(-lam t)`. It equals `X0 e^(-(rf + (1 - gam) lam) t)`: a euro deposit discounted at `rf` on
a name whose hazard is `(1 - gam) lam`, the euro-world hazard. -/
theorem shared_weight (rd rf lam gam X0 t : ℝ) :
    exp (-rd * t) * (X0 * exp ((rd - rf + gam * lam) * t)) * exp (-lam * t) =
      X0 * exp (-(rf + (1 - gam) * lam) * t) := by
  have : exp (-rd * t) * exp ((rd - rf + gam * lam) * t) * exp (-lam * t) =
      exp (-(rf + (1 - gam) * lam) * t) := by
    rw [← exp_add, ← exp_add]; congr 1; ring
  linear_combination X0 * this

/-- The euro spread from the two legs. Premiums paid continuously at spread `s`, and a payout of
`1 - R` euros after the drop `gam`, both weighted by the shared weight, balance over a tenor
`T > 0` (with `X0 > 0`) exactly when `s = (1 - R) * ((1 - gam) * lam)`: the credit triangle run
at the euro-world hazard, which is `1 - gam` times the dollar triangle `(1 - R) * lam`. With
`gam = 0`, `rf = rd` and `X0 = 1` the same statement is the dollar contract. -/
theorem euro_spread_from_legs (T rd rf lam gam R s X0 : ℝ) (hT : 0 < T) (hX : 0 < X0) :
    s * (∫ t in (0)..T, exp (-rd * t) * (X0 * exp ((rd - rf + gam * lam) * t)) * exp (-lam * t)) =
        ∫ t in (0)..T, (1 - R) * (1 - gam) * (exp (-rd * t) * (X0 * exp ((rd - rf + gam * lam) * t))) *
          (lam * exp (-lam * t)) ↔
      s = (1 - R) * ((1 - gam) * lam) := by
  have hw : ∀ t : ℝ, (1 - R) * (1 - gam) * (exp (-rd * t) * (X0 * exp ((rd - rf + gam * lam) * t))) *
      (lam * exp (-lam * t)) =
      (1 - R) * ((1 - gam) * lam) * (exp (-rd * t) * (X0 * exp ((rd - rf + gam * lam) * t)) * exp (-lam * t)) := by
    intro t; ring
  simp only [hw]
  rw [intervalIntegral.integral_const_mul]
  have hI : 0 < ∫ t in (0)..T, exp (-rd * t) * (X0 * exp ((rd - rf + gam * lam) * t)) * exp (-lam * t) := by
    apply intervalIntegral.intervalIntegral_pos_of_pos_on
    · exact (by fun_prop : Continuous fun t =>
        exp (-rd * t) * (X0 * exp ((rd - rf + gam * lam) * t)) * exp (-lam * t)).intervalIntegrable _ _
    · intro t _; positivity
    · exact hT
  constructor
  · intro h
    exact mul_right_cancel₀ hI.ne' h
  · intro h; rw [h]

/-- The inverse. When the dollar spread is not zero, the euro spread is `1 - gam` times the dollar
spread exactly when the drop is one minus the ratio of the two spreads. -/
theorem drop_from_two_quotes (sU sE gam : ℝ) (hU : sU ≠ 0) :
    sE = (1 - gam) * sU ↔ gam = 1 - sE / sU := by
  constructor
  · intro h; rw [h]; field_simp; ring
  · intro h; rw [h]; field_simp; ring

-- The Republic: 0.6 × 2.5% = 150 bp; euro-world hazard 0.8 × 2.5% = 2%; 0.6 × 2% = 0.8 × 150 bp = 120 bp.
example : (3 / 5 : ℚ) * (1 / 40) = 150 / 10000 ∧ (4 / 5 : ℚ) * (1 / 40) = 2 / 100 ∧
    (3 / 5 : ℚ) * (2 / 100) = 120 / 10000 ∧ (4 / 5 : ℚ) * (150 / 10000) = 120 / 10000 := by norm_num
-- The drop from the two quotes: 1 - 120/150 = 0.2.
example : 1 - (120 / 150 : ℚ) = 1 / 5 := by norm_num
-- Step 0: $6.60m against EUR 6.00m at $0.88 = $5.28m.
example : (3 / 5 : ℚ) * 11 = 33 / 5 ∧ (11 / 10 : ℚ) * (4 / 5) = 22 / 25 ∧
    (3 / 5 : ℚ) * 10 * (22 / 25) = 132 / 25 := by norm_num
-- Step 1: a = 0.04 - 0.02 + 0.2 × 0.025 = 2.5%, against a jump term of 0.5%.
example : (4 / 100 - 2 / 100 + (1 / 5) * (1 / 40) : ℚ) = 25 / 1000 ∧ (1 / 5 : ℚ) * (1 / 40) = 5 / 1000 := by
  norm_num
-- What breaks: 150/120 - 1 = 25%; 120 × 1.10 = 132 bp, drop 12%; 120 bp / 0.6 = 2%.
example : (150 / 120 : ℚ) - 1 = 1 / 4 ∧ (120 : ℚ) * (11 / 10) = 132 ∧ 1 - (132 / 150 : ℚ) = 3 / 25 ∧
    (120 / 10000 : ℚ) / (3 / 5) = 2 / 100 := by norm_num
-- Try changing: drop 0.5 gives 75 bp; recovery 25% gives 187.5 and 150 bp; drop -0.1 gives 165 bp.
example : (3 / 5 : ℚ) * (1 / 40) * (1 / 2) = 75 / 10000 ∧ (3 / 4 : ℚ) * (1 / 40) = 1875 / 100000 ∧
    (3 / 4 : ℚ) * (1 / 40) * (4 / 5) = 150 / 10000 ∧ (3 / 5 : ℚ) * (1 / 40) * (11 / 10) = 165 / 10000 := by
  norm_num
-- Italy, first week of May 2012: 1 - 350/440 = 9/44, about 20.45%.
example : 1 - (350 / 440 : ℚ) = 9 / 44 := by norm_num

#print axioms euro_deposit_stays_fair
#print axioms shared_weight
#print axioms euro_spread_from_legs
#print axioms drop_from_two_quotes
