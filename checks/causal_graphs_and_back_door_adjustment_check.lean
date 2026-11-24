-- Causal graphs: in the three-dot graph Z → T, Z → Y, T → Y, cutting the arrow into the treatment gives exactly the back-door formula, holding a mediator fixed erases the whole effect, and the 1986 kidney-stone counts adjust to 83.3 percent for A against 77.9 percent for B.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Finset

/-- The back-door formula for the three-dot graph Z → T, Z → Y, T → Y.
The graph says the joint chances factor as `P(z, t, y) = P(z) P(t | z) P(y | t, z)`, with
`pZ`, `pT`, `pY` three probability tables. Forcing every patient onto treatment `t`
(`do(T = t)`) cuts the arrow Z → T: the doctor's factor `P(t' | z)` becomes 1 for `t' = t` and
0 otherwise, and the other factors stay. If every size group got every treatment (positivity),
the forced-world chance of outcome `y` equals the back-door formula computed from the joint
table alone: the rate of `y` among patients on `t` with size `z`, averaged over `z` with weights
equal to each size group's share of all patients. -/
theorem back_door_formula_three_dot_graph {Z T Y : Type*} [Fintype Z] [Fintype T] [Fintype Y]
    [DecidableEq T]
    (pZ : Z → ℝ) (pT : Z → T → ℝ) (pY : T → Z → Y → ℝ)
    (hZ0 : ∀ z, 0 ≤ pZ z) (hZ1 : ∑ z, pZ z = 1)
    (hT0 : ∀ z s, 0 ≤ pT z s) (hT1 : ∀ z, ∑ s, pT z s = 1)
    (hY0 : ∀ s z w, 0 ≤ pY s z w) (hY1 : ∀ s z, ∑ w, pY s z w = 1)
    (hpos : ∀ z s, 0 < pZ z → 0 < pT z s)
    (t : T) (y : Y) :
    let P : Z → T → Y → ℝ := fun z s w => pZ z * pT z s * pY s z w
    let Pdo : Z → T → Y → ℝ := fun z s w => pZ z * (if s = t then 1 else 0) * pY s z w
    (∑ z, ∑ s, Pdo z s y) = ∑ z, (P z t y / ∑ w, P z t w) * (∑ s, ∑ w, P z s w) := by
  intro P Pdo
  refine Finset.sum_congr rfl fun z _ => ?_
  have hL : ∑ s, Pdo z s y = pZ z * pY t z y := by
    simp only [Pdo, mul_ite, mul_one, mul_zero, ite_mul, zero_mul]
    rw [Finset.sum_ite_eq' Finset.univ t]
    simp
  have hden : ∑ w, P z t w = pZ z * pT z t := by
    simp only [P]
    rw [← Finset.mul_sum, hY1, mul_one]
  have htot : ∑ s, ∑ w, P z s w = pZ z := by
    simp only [P]
    simp_rw [← Finset.mul_sum, hY1, mul_one]
    rw [← Finset.mul_sum, hT1, mul_one]
  rw [hL, hden, htot]
  rcases (hZ0 z).lt_or_eq with h | h
  · have ht := hpos z t h
    simp only [P]
    rw [mul_div_cancel_left₀ _ (mul_pos h ht).ne']
    exact mul_comm _ _
  · rw [← h]; simp [P]

/-- Holding a mediator fixed erases the whole effect. Take the graph Z → T, Z → M, T → M,
Z → Y, M → Y, where the treatment reaches the outcome only through the mediator `M`, so the
joint chances factor as `P(z) P(t | z) P(m | t, z) P(y | z, m)`. If every (size, mediator)
group got every treatment (positivity), the adjustment formula with the set {Z, M} in place of
{Z} gives the same rate for every treatment: the adjusted gap between any two treatments is
zero, whatever the true effect. -/
theorem mediator_adjustment_erases_effect {Z T M Y : Type*} [Fintype Z] [Fintype T]
    [Fintype M] [Fintype Y]
    (pZ : Z → ℝ) (pT : Z → T → ℝ) (pM : T → Z → M → ℝ) (pY : Z → M → Y → ℝ)
    (hZ0 : ∀ z, 0 ≤ pZ z) (hZ1 : ∑ z, pZ z = 1)
    (hT0 : ∀ z s, 0 ≤ pT z s) (hT1 : ∀ z, ∑ s, pT z s = 1)
    (hM0 : ∀ s z m, 0 ≤ pM s z m) (hM1 : ∀ s z, ∑ m, pM s z m = 1)
    (hY0 : ∀ z m w, 0 ≤ pY z m w) (hY1 : ∀ z m, ∑ w, pY z m w = 1)
    (hpos : ∀ z m, 0 < ∑ s, pZ z * pT z s * pM s z m → ∀ s, 0 < pZ z * pT z s * pM s z m)
    (t₁ t₂ : T) (y : Y) :
    let P : Z → T → M → Y → ℝ := fun z s m w => pZ z * pT z s * pM s z m * pY z m w
    let adj : T → ℝ := fun t =>
      ∑ z, ∑ m, (P z t m y / ∑ w, P z t m w) * (∑ s, ∑ w, P z s m w)
    adj t₁ = adj t₂ := by
  intro P adj
  have key : ∀ t, adj t = ∑ z, ∑ m, pY z m y * ∑ s, pZ z * pT z s * pM s z m := by
    intro t
    refine Finset.sum_congr rfl fun z _ => Finset.sum_congr rfl fun m _ => ?_
    have hden : ∀ s, ∑ w, P z s m w = pZ z * pT z s * pM s z m := by
      intro s
      simp only [P]
      rw [← Finset.mul_sum, hY1, mul_one]
    simp_rw [hden]
    have hnn : 0 ≤ ∑ s, pZ z * pT z s * pM s z m :=
      Finset.sum_nonneg fun s _ => mul_nonneg (mul_nonneg (hZ0 z) (hT0 z s)) (hM0 s z m)
    rcases hnn.lt_or_eq with h | h
    · have ht := hpos z m h t
      simp only [P]
      rw [mul_div_cancel_left₀ _ ht.ne']
    · rw [← h]; simp
  exact (key t₁).trans (key t₂).symm

/-! ### The card's worked numbers: the 1986 kidney-stone counts, as exact fractions
Cured / treated: A small 81/87, A large 192/263; B small 234/270, B large 55/80. -/

-- The four groups add up to the pooled counts and the size shares: 357 small, 343 large, 700 in all.
example :
    81 + 192 = 273 ∧ 87 + 263 = 350 ∧ 234 + 55 = 289 ∧ 270 + 80 = 350 ∧
    87 + 270 = 357 ∧ 263 + 80 = 343 ∧ 357 + 343 = 700 := by
  norm_num

-- The plain rate on A weights the size groups by A's own mix, 87/350 small and 263/350 large.
example : (87 : ℚ) / 350 * (81 / 87) + 263 / 350 * (192 / 263) = 273 / 350 := by
  norm_num

-- Back-door rate for A: 81/87 × 357/700 + 192/263 × 343/700 rounds to 0.8325.
example :
    (16649 : ℚ) / 20000 ≤ 81 / 87 * (357 / 700) + 192 / 263 * (343 / 700) ∧
    (81 : ℚ) / 87 * (357 / 700) + 192 / 263 * (343 / 700) < 16651 / 20000 := by
  norm_num

-- Back-door rate for B: 234/270 × 357/700 + 55/80 × 343/700 rounds to 0.7789.
example :
    (15577 : ℚ) / 20000 ≤ 234 / 270 * (357 / 700) + 55 / 80 * (343 / 700) ∧
    (234 : ℚ) / 270 * (357 / 700) + 55 / 80 * (343 / 700) < 15579 / 20000 := by
  norm_num

-- The reversal: B ahead on the plain rates, A ahead by +5.4 points (to one decimal) after adjusting.
example :
    (273 : ℚ) / 350 < 289 / 350 ∧
    (107 : ℚ) / 2000 ≤ (81 / 87 * (357 / 700) + 192 / 263 * (343 / 700)) -
      (234 / 270 * (357 / 700) + 55 / 80 * (343 / 700)) ∧
    (81 / 87 * (357 / 700) + 192 / 263 * (343 / 700)) -
      (234 / 270 * (357 / 700) + 55 / 80 * (343 / 700)) < (109 : ℚ) / 2000 := by
  norm_num

#print axioms back_door_formula_three_dot_graph
#print axioms mediator_adjustment_erases_effect
