-- Chain rule: if the inner function has a rate at t and the outer function has a rate at the value handed over, the composite's rate is the product of the two, and the card's fuel bill rises at 14.76 dollars per hour.
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.TangentCone.Real
import Mathlib.Analysis.Calculus.Deriv.Add

/-- The card's distance function: km driven by hour `t`, `s(t) = 60t + 20t²`. -/
noncomputable def driveDist (t : ℝ) : ℝ := 60 * t + 20 * t ^ 2

/-- The card's fuel function: litres burned by km `x`, `G(x) = 0.05x + 0.0002x²`. -/
noncomputable def fuelUsed (x : ℝ) : ℝ := (1 / 20) * x + (1 / 5000) * x ^ 2

/-- The card's road with a corner at km 80: 0.06 L/km on the flat, 0.09 L/km up the climb. -/
noncomputable def fuelCorner (x : ℝ) : ℝ := if x ≤ 80 then (3 / 50) * x else 24 / 5 + (9 / 100) * (x - 80)

/-- Helper: the distance function's rate is `60 + 40t`. -/
theorem driveDist_hasDerivAt (t : ℝ) : HasDerivAt driveDist (60 + 40 * t) t := by
  unfold driveDist
  have h : HasDerivAt (fun x : ℝ => 60 * x + 20 * x ^ 2) (60 * 1 + 20 * ((2 : ℕ) * t ^ (2 - 1))) t :=
    HasDerivAt.add ((hasDerivAt_id' t).const_mul (60 : ℝ)) ((hasDerivAt_pow 2 t).const_mul (20 : ℝ))
  convert h using 1
  norm_num
  ring

/-- Helper: the fuel function's rate is `1/20 + x/2500`. -/
theorem fuelUsed_hasDerivAt (x : ℝ) : HasDerivAt fuelUsed (1 / 20 + (1 / 2500) * x) x := by
  unfold fuelUsed
  have h : HasDerivAt (fun y : ℝ => (1 / 20) * y + (1 / 5000) * y ^ 2)
      ((1 / 20) * 1 + (1 / 5000) * ((2 : ℕ) * x ^ (2 - 1))) x :=
    HasDerivAt.add ((hasDerivAt_id' x).const_mul (1 / 20 : ℝ))
      ((hasDerivAt_pow 2 x).const_mul (1 / 5000 : ℝ))
  convert h using 1
  norm_num
  ring

/-- Chain rule: if the inner function `g` has rate `g'` at `t`, and the outer function `f`
has rate `f'` at the value handed over, `g t`, then `f` after `g` has rate `f' * g'` at `t`:
the outer rate, read at `g t`, times the inner rate. -/
theorem chain_rule_rates_multiply (f g : ℝ → ℝ) (f' g' t : ℝ)
    (hg : HasDerivAt g g' t) (hf : HasDerivAt f f' (g t)) :
    HasDerivAt (fun x => f (g x)) (f' * g') t := by
  exact hf.comp t hg

/-- The drive: with price 1.80 dollars per litre, the fuel bill `C(t) = 1.80 · G(s(t))`
grows at `1.80 × 0.082 × 100 = 14.76` dollars per hour at one hour. -/
theorem fuel_bill_rate_at_one_hour :
    HasDerivAt (fun t => (9 / 5 : ℝ) * fuelUsed (driveDist t)) (369 / 25) 1 := by
  have h80 : driveDist 1 = 80 := by norm_num [driveDist]
  have hf := fuelUsed_hasDerivAt (driveDist 1)
  have h : HasDerivAt (fun t => (9 / 5 : ℝ) * fuelUsed (driveDist t))
      ((9 / 5) * ((1 / 20 + (1 / 2500) * driveDist 1) * (60 + 40 * 1))) 1 :=
    (hf.comp (1 : ℝ) (driveDist_hasDerivAt 1)).const_mul (9 / 5 : ℝ)
  convert h using 1
  rw [h80]
  norm_num

/-- When the burn rate jumps at km 80 (0.06 L/km before, 0.09 L/km after), the fuel bill
has no single rate at one hour, when the car is at km 80. -/
theorem fuel_bill_no_rate_at_corner :
    ¬ DifferentiableAt ℝ (fun t => (9 / 5 : ℝ) * fuelCorner (driveDist t)) 1 := by
  intro hd
  have hD := hd.hasDerivAt
  set D := deriv (fun t => (9 / 5 : ℝ) * fuelCorner (driveDist t)) 1
  -- Left piece: on [0, 1] the car is at or before km 80.
  have hL : HasDerivWithinAt (fun t => (9 / 5 : ℝ) * fuelCorner (driveDist t))
      ((9 / 5 : ℝ) * ((3 / 50) * (60 + 40 * 1))) (Set.Icc 0 1) 1 := by
    have h0 : HasDerivAt (fun x => (3 / 50 : ℝ) * driveDist x) ((3 / 50) * (60 + 40 * 1)) 1 :=
      (driveDist_hasDerivAt 1).const_mul (3 / 50 : ℝ)
    have h : HasDerivWithinAt (fun x => (9 / 5 : ℝ) * ((3 / 50) * driveDist x))
        ((9 / 5 : ℝ) * ((3 / 50) * (60 + 40 * 1))) (Set.Icc (0 : ℝ) 1) 1 :=
      (h0.const_mul (9 / 5 : ℝ)).hasDerivWithinAt
    refine h.congr_of_mem ?_ (by norm_num)
    intro x hx
    have hle : driveDist x ≤ 80 := by
      simp only [driveDist]; nlinarith [hx.1, hx.2]
    simp [fuelCorner, hle]
  -- Right piece: on [1, 2] the car is at or past km 80.
  have hR : HasDerivWithinAt (fun t => (9 / 5 : ℝ) * fuelCorner (driveDist t))
      ((9 / 5 : ℝ) * ((9 / 100) * (60 + 40 * 1))) (Set.Icc 1 2) 1 := by
    have h0 : HasDerivAt (fun x => driveDist x - 80) (60 + 40 * 1) 1 :=
      (driveDist_hasDerivAt 1).sub_const (80 : ℝ)
    have h1 : HasDerivAt (fun x => (9 / 100 : ℝ) * (driveDist x - 80)) ((9 / 100) * (60 + 40 * 1)) 1 :=
      h0.const_mul (9 / 100 : ℝ)
    have h1' : HasDerivAt (fun x => (24 / 5 : ℝ) + (9 / 100) * (driveDist x - 80))
        ((9 / 100) * (60 + 40 * 1)) 1 := h1.const_add (24 / 5 : ℝ)
    have h2 : HasDerivWithinAt (fun x => (9 / 5 : ℝ) * ((24 / 5) + (9 / 100) * (driveDist x - 80)))
        ((9 / 5 : ℝ) * ((9 / 100) * (60 + 40 * 1))) (Set.Icc (1 : ℝ) 2) 1 :=
      (h1'.const_mul (9 / 5 : ℝ)).hasDerivWithinAt
    refine h2.congr_of_mem ?_ (by norm_num)
    intro x hx
    have hge : 80 ≤ driveDist x := by
      simp only [driveDist]; nlinarith [hx.1, hx.2]
    by_cases hle : driveDist x ≤ 80
    · have heq : driveDist x = 80 := le_antisymm hle hge
      simp only [fuelCorner, heq]
      norm_num
    · simp [fuelCorner, hle]
  have eL := (uniqueDiffOn_Icc (by norm_num : (0 : ℝ) < 1) 1 (by norm_num)).eq_deriv _
    hD.hasDerivWithinAt hL
  have eR := (uniqueDiffOn_Icc (by norm_num : (1 : ℝ) < 2) 1 (by norm_num)).eq_deriv _
    hD.hasDerivWithinAt hR
  rw [eL] at eR
  norm_num at eR

-- Worked numbers, by hand.
-- Distance at 1 h: 60 × 1 + 20 × 1 × 1 = 80 km.
example : (60 : ℚ) * 1 + 20 * 1 * 1 = 80 := by norm_num
-- Speed at 1 h: 60 + 40 × 1 = 100 km/h.
example : (60 : ℚ) + 40 * 1 = 100 := by norm_num
-- Fuel burned by 80 km: 0.05 × 80 + 0.0002 × 80 × 80 = 5.28 L.
example : (1 / 20 : ℚ) * 80 + (1 / 5000) * 80 * 80 = 132 / 25 := by norm_num
-- Burn rate at 80 km: 0.05 + 0.0004 × 80 = 0.082 L/km.
example : (1 / 20 : ℚ) + (1 / 2500) * 80 = 41 / 500 := by norm_num
-- Bill at 1 h: 1.80 × 5.28 = 9.504 dollars.
example : (9 / 5 : ℚ) * (132 / 25) = 1188 / 125 := by norm_num
-- Cost rate: 1.80 × 0.082 × 100 = 14.76 dollars per hour.
example : (9 / 5 : ℚ) * (41 / 500) * 100 = 369 / 25 := by norm_num
-- Corner rates: 1.80 × 0.06 × 100 = 10.80 from the left, 1.80 × 0.09 × 100 = 16.20 from the right.
example : (9 / 5 : ℚ) * (3 / 50) * 100 = 54 / 5 ∧ (9 / 5 : ℚ) * (9 / 100) * 100 = 81 / 5 := by norm_num

#print axioms driveDist_hasDerivAt
#print axioms fuelUsed_hasDerivAt
#print axioms chain_rule_rates_multiply
#print axioms fuel_bill_rate_at_one_hour
#print axioms fuel_bill_no_rate_at_corner
