-- The Black-Scholes assumptions: the daily hedging ledger's leftover is exactly the sum of the daily tracking errors carried forward with interest, and an overnight gap always bills the hedger a positive amount for the bend of the option's curve.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Order.Interval.Set.UnorderedInterval
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Convex.Basic

open Real

namespace BlackScholesAssumptions

/-! Notation, as on the card. Days are counted `0, 1, …, n`; `S i` is the share price on day `i`,
`v i` the contract's mark, `δ i` the share count the mark prescribes, `V i` the hedging account's
worth, `h` one trading day as a fraction of a year, `r` the bank rate and `q` the dividend yield,
so `exp (r * h)` is one day's bank growth `R` and `exp (q * h) - 1` one day's dividend per dollar
of shares. -/

/-- One day's **defect** `D_i`: what the account earned (the shares' move, their dividend, the
interest on the cash `v i - δ i * S i`) minus what the mark did. -/
noncomputable def dayDefect (S v δ : ℕ → ℝ) (r q h : ℝ) (i : ℕ) : ℝ :=
  δ i * (S (i + 1) - S i) + δ i * S i * (exp (q * h) - 1)
    + (exp (r * h) - 1) * (v i - δ i * S i) - (v (i + 1) - v i)

/-- **The leftover is the daily misses, carried forward with interest** (Why it works, Step 2).
Let the account follow the card's ledger: hold the mark's share count `δ i` for a day, keep the
rest in the bank, so `V (i+1) = δ i S (i+1) + (V i - δ i S i) R + δ i S i (e^{qh} - 1)`. Let the
account start at the mark (`V 0 = v 0`, the premium) and let the mark on the last day `n` be the
call's payoff `max (S n - K) 0`. Then, for every price path, every mark and every choice of share
counts:
1. the account's surplus over the mark obeys `E (i+1) = R E i + D i` each day, and
2. the leftover `V n - max (S n - K) 0` is exactly `∑ e^{r(T - t_{i+1})} D i`, with
   `T = n h` and `t_{i+1} = (i+1) h`.
No limit and no model assumption is used: this is finite arithmetic on the prices that occurred. -/
theorem leftover_eq_sum_of_carried_defects
    (S v δ V : ℕ → ℝ) (r q h K : ℝ) (n : ℕ)
    (hV : ∀ i, V (i + 1) =
      δ i * S (i + 1) + (V i - δ i * S i) * exp (r * h) + δ i * S i * (exp (q * h) - 1))
    (hV0 : V 0 = v 0)
    (hvT : v n = max (S n - K) 0) :
    (∀ i, V (i + 1) - v (i + 1) = exp (r * h) * (V i - v i) + dayDefect S v δ r q h i) ∧
      V n - max (S n - K) 0 =
        ∑ i ∈ Finset.range n,
          exp (r * ((n : ℝ) * h - ((i : ℝ) + 1) * h)) * dayDefect S v δ r q h i := by
  have step : ∀ i, V (i + 1) - v (i + 1) = exp (r * h) * (V i - v i) + dayDefect S v δ r q h i := by
    intro i
    rw [hV i]
    unfold dayDefect
    ring
  refine ⟨step, ?_⟩
  have key : ∀ m : ℕ, V m - v m =
      ∑ i ∈ Finset.range m,
        exp (r * ((m : ℝ) * h - ((i : ℝ) + 1) * h)) * dayDefect S v δ r q h i := by
    intro m
    induction m with
    | zero => simp [hV0]
    | succ m ih =>
      rw [step m, ih, Finset.sum_range_succ, Finset.mul_sum]
      congr 1
      · apply Finset.sum_congr rfl
        intro i _
        rw [← mul_assoc, ← exp_add]
        congr 2
        push_cast
        ring
      · push_cast
        have : r * (((m : ℝ) + 1) * h - ((m : ℝ) + 1) * h) = 0 := by ring
        rw [this, exp_zero, one_mul]
  rw [← hvT]
  exact key n

/-- **A gap splits into a stale slope and a bill for the bend, and the bill is always positive**
(Why it works, Step 3). Fix a date and let `f` be the mark as a function of the price. Let `s` be
the price just before an overnight gap and `J ≠ 0` the jump in dollars. Suppose that on the
segment from `s` to `s + J` the mark is twice differentiable with strictly positive second
derivative (the bend `Γ`). Then:
1. for any share count `δ_old` carried in from yesterday, the gap's defect
   `δ_old J - (f (s + J) - f s)` equals `(δ_old - δ_*) J - B`, where `δ_* = f' s` is the share
   count the mark prescribes at `s` and `B = f (s + J) - f s - δ_* J` is the bend's bill; and
2. the bill `B` is strictly positive, whichever way the price jumped. -/
theorem gap_defect_splits_and_bend_bill_pos
    (f : ℝ → ℝ) (s J : ℝ) (hJ : J ≠ 0)
    (hdiff : ∀ x ∈ Set.uIcc s (s + J),
      DifferentiableAt ℝ f x ∧ DifferentiableAt ℝ (deriv f) x)
    (hbend : ∀ x ∈ Set.uIcc s (s + J), 0 < deriv (deriv f) x) :
    (∀ δold : ℝ, δold * J - (f (s + J) - f s) =
        (δold - deriv f s) * J - (f (s + J) - f s - deriv f s * J)) ∧
      0 < f (s + J) - f s - deriv f s * J := by
  refine ⟨fun δold => by ring, ?_⟩
  have hmono : StrictMonoOn (deriv f) (Set.uIcc s (s + J)) := by
    apply strictMonoOn_of_deriv_pos (convex_uIcc s (s + J))
    · intro x hx
      exact (hdiff x hx).2.continuousAt.continuousWithinAt
    · intro x hx
      exact hbend x (interior_subset hx)
  have hcont : ContinuousOn f (Set.uIcc s (s + J)) := fun x hx =>
    (hdiff x hx).1.continuousAt.continuousWithinAt
  rcases lt_or_gt_of_ne hJ with hneg | hpos
  · have hlt : s + J < s := by linarith
    have hu : Set.uIcc s (s + J) = Set.Icc (s + J) s := Set.uIcc_of_ge hlt.le
    obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope f hlt (hu ▸ hcont)
      (fun x hx => (hdiff x (hu ▸ Set.Ioo_subset_Icc_self hx)).1.differentiableWithinAt)
    have hcs : deriv f c < deriv f s := by
      apply hmono (hu ▸ Set.Ioo_subset_Icc_self hc)
      · rw [hu]; exact ⟨hlt.le, le_rfl⟩
      · exact hc.2
    have hne : s - (s + J) ≠ 0 := by linarith
    have heq : f (s + J) - f s = deriv f c * J := by
      rw [hcd]; field_simp; ring
    rw [heq]
    nlinarith
  · have hlt : s < s + J := by linarith
    have hu : Set.uIcc s (s + J) = Set.Icc s (s + J) := Set.uIcc_of_le hlt.le
    obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope f hlt (hu ▸ hcont)
      (fun x hx => (hdiff x (hu ▸ Set.Ioo_subset_Icc_self hx)).1.differentiableWithinAt)
    have hcs : deriv f s < deriv f c := by
      apply hmono
      · rw [hu]; exact ⟨le_rfl, hlt.le⟩
      · exact hu ▸ Set.Ioo_subset_Icc_self hc
      · exact hc.1
    have hne : s + J - s ≠ 0 := by linarith
    have heq : f (s + J) - f s = deriv f c * J := by
      rw [hcd]; field_simp; ring
    rw [heq]
    nlinarith

/-! The card's worked numbers, in exact whole units. -/

-- The switch world's variance: ½ · 0.20² + ½ · 0.30² = 0.065 = 13/200.
example : (1 / 2 : ℚ) * (20 / 100) ^ 2 + (1 / 2) * (30 / 100) ^ 2 = 13 / 200 := by norm_num

-- The gap between two prices, in millionths of a dollar: 11.311639 - 9.227006 = 2.084633.
example : (11311639 : ℤ) - 9227006 = 2084633 := by norm_num

-- The traced record, in cents: the account holds 176, the call pays 233, a leftover of -57.
example : (176 : ℤ) - 233 = -57 := by norm_num

-- At month six, in cents: the gap column (-232) sits 212 below the first column (-20).
example : (-20 : ℤ) - (-232) = 212 := by norm_num

#print axioms leftover_eq_sum_of_carried_defects
#print axioms gap_defect_splits_and_bend_bill_pos

end BlackScholesAssumptions
