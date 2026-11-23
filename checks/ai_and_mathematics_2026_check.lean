-- Machines that prove: a sum a^n + b^n with a even and b odd can never equal c^n with c even, so the calculator's near miss 1782^12 + 1841^12 against 1922^12 is no counterexample even though both sides agree to ten digits; the Fermat formalisation's one-line Lean statement is exactly Mathlib's Fermat's last theorem; and the blow-up toy y = 1/(1 - t) solves y' = y^2 from y(0) = 1 and becomes infinite as t rises to 1.
import Mathlib.NumberTheory.FLT.Basic
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

open Filter Topology

/-- The near miss is no counterexample (General Overview). If a is even, b is odd and c is
even, then for every power n ≥ 1 the sum a^n + b^n is odd and c^n is even, so
a^n + b^n ≠ c^n, however many leading digits the two sides share. -/
theorem pow_add_pow_ne_pow_of_even_odd_even (n a b c : ℕ) (hn : 0 < n)
    (ha : Even a) (hb : Odd b) (hc : Even c) : a ^ n + b ^ n ≠ c ^ n := by
  have h1 : Even (a ^ n) := ha.pow_of_ne_zero hn.ne'
  have h2 : Odd (b ^ n) := hb.pow
  have h3 : Even (c ^ n) := hc.pow_of_ne_zero hn.ne'
  intro h
  have h4 : Odd (a ^ n + b ^ n) := h1.add_odd h2
  rw [h] at h4
  exact (Nat.not_even_iff_odd.mpr h4) h3

/-- The statement field, checked for Fermat (Step 1). The formalisation's one-line theorem,
"for whole numbers n ≥ 3 and positive whole numbers a, b, c, a^n + b^n ≠ c^n", says exactly
what Mathlib's own `FermatLastTheorem` says: each implies the other. -/
theorem fermat_one_line_iff_fermatLastTheorem :
    (∀ n : ℕ, 3 ≤ n → ∀ a b c : ℕ, 0 < a → 0 < b → 0 < c → a ^ n + b ^ n ≠ c ^ n) ↔
      FermatLastTheorem := by
  constructor
  · intro h n hn a b c ha hb hc
    exact h n hn a b c (Nat.pos_of_ne_zero ha) (Nat.pos_of_ne_zero hb) (Nat.pos_of_ne_zero hc)
  · intro h n hn a b c ha hb hc
    exact h n hn a b c ha.ne' hb.ne' hc.ne'

/-- The blow-up toy (the Navier-Stokes paragraph). The quantity y(t) = 1/(1 - t) starts at
y(0) = 1, grows at the rate y² at every time t before 1, and becomes infinite as t rises
to 1: it breaks down in finite time. -/
theorem blow_up_toy :
    (1 / (1 - (0 : ℝ)) = 1) ∧
    (∀ t : ℝ, t < 1 → HasDerivAt (fun s : ℝ => 1 / (1 - s)) ((1 / (1 - t)) ^ 2) t) ∧
    Tendsto (fun t : ℝ => 1 / (1 - t)) (𝓝[<] 1) atTop := by
  refine ⟨by norm_num, ?_, ?_⟩
  · intro t ht
    have hne : (1 - t) ≠ 0 := by linarith
    have hd : HasDerivAt (fun s : ℝ => 1 - s) (-1) t := by
      have := HasDerivAt.const_sub (1 : ℝ) (hasDerivAt_id' t)
      simpa only [neg_one_mul] using this
    have := (hasDerivAt_const t (1 : ℝ)).div hd hne
    convert this using 1
    field_simp
    ring
  · have h1 : Tendsto (fun t : ℝ => 1 - t) (𝓝[<] 1) (𝓝[>] 0) := by
      apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
      · have : Tendsto (fun t : ℝ => 1 - t) (𝓝 1) (𝓝 (1 - 1)) :=
          tendsto_const_nhds.sub tendsto_id
        simpa using this.mono_left nhdsWithin_le_nhds
      · filter_upwards [self_mem_nhdsWithin] with t ht
        simp only [Set.mem_Ioi]
        exact sub_pos.mpr ht
    have := tendsto_inv_nhdsGT_zero.comp h1
    simp only [one_div]
    exact this

/-! The card's worked numbers. -/

-- The near miss, digit for digit.
example : (1782 : ℕ) ^ 12 + 1841 ^ 12 = 2541210258614589176288669958142428526657 ∧
    (1922 : ℕ) ^ 12 = 2541210259314801410819278649643651567616 := by norm_num
-- A ten-digit screen shows both as 2.541210259e39: both lie in [25412102585, 25412102595) × 10^29.
example : 25412102585 * 10 ^ 29 ≤ (1782 : ℕ) ^ 12 + 1841 ^ 12 ∧
    (1782 : ℕ) ^ 12 + 1841 ^ 12 < 25412102595 * 10 ^ 29 ∧
    25412102585 * 10 ^ 29 ≤ (1922 : ℕ) ^ 12 ∧ (1922 : ℕ) ^ 12 < 25412102595 * 10 ^ 29 := by
  norm_num
-- Left minus right, exactly.
example : ((1782 : ℤ) ^ 12 + 1841 ^ 12) - 1922 ^ 12 = -700212234530608691501223040959 := by
  norm_num
-- Last digits 7 and 6; the left side is odd, the right side even.
example : (1782 ^ 12 + 1841 ^ 12) % 10 = 7 ∧ 1922 ^ 12 % 10 = 6 ∧
    (1782 ^ 12 + 1841 ^ 12) % 2 = 1 ∧ 1922 ^ 12 % 2 = 0 := by norm_num
-- The residues modulo 1,000,003, 1,000,033 and 1,000,037, side by side.
example : ((1782 ^ 12 + 1841 ^ 12) % 1000003, 1922 ^ 12 % 1000003) = (910620, 310826) ∧
    ((1782 ^ 12 + 1841 ^ 12) % 1000033, 1922 ^ 12 % 1000033) = (174601, 204971) ∧
    ((1782 ^ 12 + 1841 ^ 12) % 1000037, 1922 ^ 12 % 1000037) = (654209, 677649) := by
  norm_num
-- The near miss's bases: 1782 even, 1841 odd, 1922 even, so the main theorem covers it.
example : Even 1782 ∧ Odd 1841 ∧ Even 1922 := by decide
-- Euclid's formula count of right triangles with whole sides and c ≤ 100: 52.
example : ((Finset.Ico 2 11).sum fun m => ((Finset.Ico 1 m).filter
    (fun j => (m - j) % 2 = 1 ∧ Nat.gcd m j = 1)).sum fun j => 100 / (m * m + j * j)) = 52 := by
  decide
-- The closest cube miss: 6^3 + 8^3 - 9^3 = -1.
example : (6 : ℤ) ^ 3 + 8 ^ 3 - 9 ^ 3 = -1 := by norm_num
-- The proved bounds rise: one third < two fifths < five twelfths < two thirds.
example : (1 : ℚ) / 3 < 2 / 5 ∧ (2 : ℚ) / 5 < 5 / 12 ∧ (5 : ℚ) / 12 < 2 / 3 := by norm_num
-- The 3 by 3 grid: 12 pairs at distance 1 (6 across, 6 up), counting vectors (1,0) and (0,1).
example : ((Finset.range 3 ×ˢ Finset.range 3).offDiag.filter (fun pq : (ℕ × ℕ) × (ℕ × ℕ) =>
    ((pq.1.1 : ℤ) - pq.2.1) ^ 2 + ((pq.1.2 : ℤ) - pq.2.2) ^ 2 = 1)).card / 2 = 12 ∧
    (3 - 1) * 3 + 3 * (3 - 1) = 12 := by decide +kernel
-- The blow-up toy's exact values: 2 at t = 1/2, 10 at t = 9/10, 100 at t = 99/100,
-- 1,000 at t = 999/1000.
example : (1 : ℚ) / (1 - 1 / 2) = 2 ∧ (1 : ℚ) / (1 - 9 / 10) = 10 ∧
    (1 : ℚ) / (1 - 99 / 100) = 100 ∧ (1 : ℚ) / (1 - 999 / 1000) = 1000 := by norm_num

#print axioms pow_add_pow_ne_pow_of_even_odd_even
#print axioms fermat_one_line_iff_fermatLastTheorem
#print axioms blow_up_toy
