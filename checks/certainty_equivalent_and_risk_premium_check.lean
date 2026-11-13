-- Risk premium: for a risk-averse (concave, strictly increasing) utility the certainty equivalent of a finite gamble exists, is unique, and never exceeds the gamble's average, so the risk premium is never negative.
import Mathlib.Analysis.Convex.Jensen
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Finset

/-- The risk premium is never negative for a risk-averse saver. Take a gamble with finitely
many outcomes `w i` and probabilities `p i` (nonnegative, summing to 1), and a utility `u`
that bends downward (concave) and is strictly increasing on an interval `s` holding every
outcome. If `c` in `s` is a certainty equivalent, meaning `u c` equals the expected utility,
then the risk premium, average wealth minus `c`, is at least zero. -/
theorem risk_premium_nonneg {ι : Type*} (t : Finset ι) (p w : ι → ℝ) (s : Set ℝ) (u : ℝ → ℝ)
    (hconc : ConcaveOn ℝ s u) (hmono : StrictMonoOn u s)
    (hp : ∀ i ∈ t, 0 ≤ p i) (hsum : ∑ i ∈ t, p i = 1) (hw : ∀ i ∈ t, w i ∈ s)
    (c : ℝ) (hc : c ∈ s) (hce : u c = ∑ i ∈ t, p i * u (w i)) :
    0 ≤ (∑ i ∈ t, p i * w i) - c := by
  have hmem : (∑ i ∈ t, p i * w i) ∈ s := by
    have := hconc.1.sum_mem hp hsum hw
    simpa [smul_eq_mul] using this
  have hj := hconc.le_map_sum hp hsum hw
  simp only [smul_eq_mul] at hj
  have : c ≤ ∑ i ∈ t, p i * w i := (hmono.le_iff_le hc hmem).1 (hce ▸ hj)
  linarith

/-- The certainty equivalent exists and is unique. If the utility `u` is continuous and
strictly increasing on an interval `s` that holds every outcome of a finite gamble, then
exactly one sure sum `c` in `s` has utility equal to the gamble's expected utility. -/
theorem certainty_equivalent_exists_unique {ι : Type*} (t : Finset ι) (p w : ι → ℝ)
    (s : Set ℝ) (u : ℝ → ℝ) (hs : Convex ℝ s)
    (hcont : ContinuousOn u s) (hmono : StrictMonoOn u s)
    (hp : ∀ i ∈ t, 0 ≤ p i) (hsum : ∑ i ∈ t, p i = 1) (hw : ∀ i ∈ t, w i ∈ s) :
    ∃! c, c ∈ s ∧ u c = ∑ i ∈ t, p i * u (w i) := by
  have hne : t.Nonempty := by
    rcases Finset.eq_empty_or_nonempty t with h | h
    · subst h; simp at hsum
    · exact h
  obtain ⟨m, hm, hmin⟩ := Finset.exists_min_image t w hne
  obtain ⟨M, hM, hmax⟩ := Finset.exists_max_image t w hne
  have hlo : u (w m) ≤ ∑ i ∈ t, p i * u (w i) := by
    calc u (w m) = ∑ i ∈ t, p i * u (w m) := by rw [← Finset.sum_mul, hsum, one_mul]
      _ ≤ ∑ i ∈ t, p i * u (w i) := by
        apply Finset.sum_le_sum
        intro i hi
        exact mul_le_mul_of_nonneg_left
          ((hmono.le_iff_le (hw m hm) (hw i hi)).2 (hmin i hi)) (hp i hi)
  have hhi : ∑ i ∈ t, p i * u (w i) ≤ u (w M) := by
    calc ∑ i ∈ t, p i * u (w i) ≤ ∑ i ∈ t, p i * u (w M) := by
          apply Finset.sum_le_sum
          intro i hi
          exact mul_le_mul_of_nonneg_left
            ((hmono.le_iff_le (hw i hi) (hw M hM)).2 (hmax i hi)) (hp i hi)
      _ = u (w M) := by rw [← Finset.sum_mul, hsum, one_mul]
  have hsub : Set.Icc (w m) (w M) ⊆ s := hs.ordConnected.out (hw m hm) (hw M hM)
  have hle : w m ≤ w M := hmin M hM
  obtain ⟨c, hcI, hcu⟩ :=
    intermediate_value_Icc hle (hcont.mono hsub) ⟨hlo, hhi⟩
  refine ⟨c, ⟨hsub hcI, hcu⟩, ?_⟩
  rintro y ⟨hy, hyu⟩
  exact hmono.injOn hy (hsub hcI) (hyu.trans hcu.symm)

/-- For a log investor facing an even coin between positive outcomes `a` and `b`, the
certainty equivalent `exp (E[ln W])` is the geometric mean `√(a b)`. -/
theorem log_certainty_equivalent_coin_eq_geometric_mean (a b : ℝ) (ha : 0 < a) (hb : 0 < b) :
    Real.exp ((1 / 2) * Real.log a + (1 / 2) * Real.log b) = Real.sqrt (a * b) := by
  rw [Real.sqrt_eq_rpow, Real.rpow_def_of_pos (mul_pos ha hb), Real.log_mul ha.ne' hb.ne']
  ring_nf

-- The coin: $150 or $50 at even odds. Average wealth is $100.
example : (1 / 2 : ℚ) * 150 + (1 / 2) * 50 = 100 := by norm_num
-- Its variance is 2500 dollars squared.
example : (1 / 2 : ℚ) * (150 - 100) ^ 2 + (1 / 2) * (50 - 100) ^ 2 = 2500 := by norm_num
-- Power utility at gamma = 2: the certainty equivalent is the harmonic mean, $75.
example : (2 : ℚ) / (1 / 150 + 1 / 50) = 75 := by norm_num
-- With u(W) = -1/W, the sure $75 has exactly the coin's expected utility.
example : -(1 : ℚ) / 75 = (1 / 2) * (-1 / 150) + (1 / 2) * (-1 / 50) := by norm_num
-- So the risk premium at gamma = 2 is $25.
example : (100 : ℚ) - 75 = 25 := by norm_num
-- Arrow-Pratt for the coin: one half times 1/100 times 2500 is $12.50.
example : (1 / 2 : ℚ) * (1 / 100) * 2500 = 25 / 2 := by norm_num
-- Insurance: average loss is a 10% chance of $60, which is $6.
example : (1 / 10 : ℚ) * 60 = 6 := by norm_num
-- Log certainty equivalent of the coin is √(150 · 50) = √7500, which lies between $86.60 and
-- $86.61: in cents, 8660² < 7500 · 100² < 8661².
example : (8660 : ℕ) ^ 2 < 150 * 50 * 100 ^ 2 ∧ 150 * 50 * 100 ^ 2 < (8661 : ℕ) ^ 2 := by norm_num
-- Ten times the coin ($1,500 or $500): the product under the square root is 100 times larger,
-- so the log certainty equivalent is ten times larger ($866.03).
example : (1500 : ℕ) * 500 = 10 ^ 2 * (150 * 50) := by norm_num
-- Insuring at $8.00 beats keeping the risk for a log saver: ln 92 > 0.9 ln 100 + 0.1 ln 40,
-- which, multiplied by 10 and exponentiated, is 92¹⁰ > 100⁹ · 40.
example : (100 : ℕ) ^ 9 * 40 < 92 ^ 10 := by norm_num

#print axioms risk_premium_nonneg
#print axioms certainty_equivalent_exists_unique
#print axioms log_certainty_equivalent_coin_eq_geometric_mean
