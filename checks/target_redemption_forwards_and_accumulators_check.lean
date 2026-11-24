-- TARFs and accumulators: under the exact-target rule the gains a target redemption forward pays add up to the banked total cut off at the target, the doubled losing fixings are extra sold puts, and on a fixed path the client's value never falls as spot rises.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Order.Monotone.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

noncomputable section

namespace TARF

/-- The gain at a fixing: how far the fixing `s` sat above the strike `K`, `max (s - K) 0`. -/
def gain (s K : ℝ) : ℝ := max (s - K) 0

/-- The loss at a fixing: how far the fixing `s` sat below the strike `K`, `max (K - s) 0`. -/
def loss (s K : ℝ) : ℝ := max (K - s) 0

/-- The gain banked before fixing `i` (fixings counted from 0): the gain `B₀` banked before
the first fixing plus the gains of fixings `0, …, i - 1` on the path of fixings `S`. -/
def banked (S : ℕ → ℝ) (K B₀ : ℝ) (i : ℕ) : ℝ :=
  B₀ + ∑ j ∈ range i, gain (S j) K

/-- The gain paid at fixing `i` under the exact-target rule: while the banked gain is still
below the target `G`, the client is paid the gain but never more than what is left of the
target; once the target has been reached, the contract is over and pays nothing. -/
def paid (S : ℕ → ℝ) (K B₀ G : ℝ) (i : ℕ) : ℝ :=
  if banked S K B₀ i < G then min (gain (S i) K) (G - banked S K B₀ i) else 0

/-- The client's value on one path, per euro: at each live fixing, the capped gain paid minus
the leverage `lev` times the loss, discounted by `D i`. Today's spot is `S₀` and the path's
fixings are `S₀ * R i`, where `R i` is the path's growth up to fixing `i`. -/
def pathValue (D R : ℕ → ℝ) (K B₀ G lev S₀ : ℝ) (n : ℕ) : ℝ :=
  ∑ i ∈ range n, D i * (paid (fun j => S₀ * R j) K B₀ G i
    - (if banked (fun j => S₀ * R j) K B₀ i < G then lev * loss (S₀ * R i) K else 0))

theorem gain_nonneg (s K : ℝ) : 0 ≤ gain s K := le_max_right _ _

theorem loss_nonneg (s K : ℝ) : 0 ≤ loss s K := le_max_right _ _

theorem banked_zero (S : ℕ → ℝ) (K B₀ : ℝ) : banked S K B₀ 0 = B₀ := by
  simp [banked]

theorem banked_succ (S : ℕ → ℝ) (K B₀ : ℝ) (i : ℕ) :
    banked S K B₀ (i + 1) = banked S K B₀ i + gain (S i) K := by
  simp only [banked, sum_range_succ]
  ring

theorem paid_eq_capped_diff (S : ℕ → ℝ) (K B₀ G : ℝ) (i : ℕ) :
    paid S K B₀ G i = min (banked S K B₀ (i + 1)) G - min (banked S K B₀ i) G := by
  have hg := gain_nonneg (S i) K
  unfold paid
  rw [banked_succ]
  split_ifs with h
  · simp only [min_def]
    split_ifs <;> linarith
  · simp only [min_def]
    split_ifs <;> linarith

theorem banked_mono_spot (R : ℕ → ℝ) (K B₀ : ℝ) (hR : ∀ i, 0 < R i) {x y : ℝ} (hxy : x ≤ y)
    (i : ℕ) : banked (fun j => x * R j) K B₀ i ≤ banked (fun j => y * R j) K B₀ i := by
  unfold banked
  gcongr with j _
  unfold gain
  have := mul_le_mul_of_nonneg_right hxy (hR j).le
  exact max_le_max (by linarith) le_rfl

theorem summation_by_parts_mono (d c c' : ℕ → ℝ) (hd : Antitone d) (h0 : c 0 = c' 0)
    (hc : ∀ i, c i ≤ c' i) (n : ℕ) :
    d n * (c' n - c n) ≤
      ∑ i ∈ range n, d i * (c' (i + 1) - c' i) - ∑ i ∈ range n, d i * (c (i + 1) - c i) := by
  induction n with
  | zero => simp [h0]
  | succ n ih =>
    rw [sum_range_succ, sum_range_succ]
    have hdn : d (n + 1) ≤ d n := hd (Nat.le_succ n)
    have := mul_le_mul_of_nonneg_right hdn (sub_nonneg.2 (hc (n + 1)))
    nlinarith

/-- The target caps the client's total gain. On any path of fixings, the gains paid under the
exact-target rule add up to the banked total cut off at the target, minus what was banked
before the first fixing (also cut off): `min (B_n, G) - min (B₀, G)`. So on a contract still
alive at the start (`B₀ ≤ G`) no path pays the client more than the target that was left,
`G - B₀`; with nothing banked, no more than `G`. -/
theorem total_paid_gain_eq_banked_capped_at_target (S : ℕ → ℝ) (K B₀ G : ℝ) (n : ℕ) :
    ∑ i ∈ range n, paid S K B₀ G i = min (banked S K B₀ n) G - min B₀ G ∧
      (B₀ ≤ G → ∑ i ∈ range n, paid S K B₀ G i ≤ G - B₀) := by
  have htel : ∑ i ∈ range n, paid S K B₀ G i = min (banked S K B₀ n) G - min B₀ G := by
    simp only [paid_eq_capped_diff]
    rw [sum_range_sub (fun i => min (banked S K B₀ i) G), banked_zero]
  refine ⟨htel, fun h => ?_⟩
  rw [htel, min_eq_left h]
  have := min_le_right (banked S K B₀ n) G
  linarith

/-- The doubled losses are extra puts: at any fixing, the leveraged cash flow
`gain - lev * loss` is a forward at the strike, `s - K`, minus `lev - 1` puts struck at `K`. -/
theorem leveraged_cash_eq_forward_minus_puts (s K lev : ℝ) :
    gain s K - lev * loss s K = (s - K) - (lev - 1) * loss s K := by
  unfold gain loss
  rcases le_total s K with h | h
  · rw [max_eq_right (by linarith : s - K ≤ 0), max_eq_left (by linarith : 0 ≤ K - s)]
    ring
  · rw [max_eq_left (by linarith : 0 ≤ s - K), max_eq_right (by linarith : K - s ≤ 0)]
    ring

/-- The delta is never negative. Keep the random path fixed (each fixing is today's spot times a
positive growth `R i`), let the dollar rate be positive so the discount factors are positive and
fall from one fixing to the next, and let the leverage be nonnegative. Then under the exact-target
rule the client's value on the path never falls as today's spot rises, whatever has been banked. -/
theorem path_value_monotone_in_spot (D R : ℕ → ℝ) (K B₀ G lev : ℝ) (n : ℕ)
    (hR : ∀ i, 0 < R i) (hD : ∀ i, 0 < D i) (hDdec : StrictAnti D) (hlev : 0 ≤ lev) :
    Monotone (fun S₀ => pathValue D R K B₀ G lev S₀ n) := by
  intro x y hxy
  have hB := banked_mono_spot R K B₀ hR hxy
  have split : ∀ S₀, pathValue D R K B₀ G lev S₀ n =
      ∑ i ∈ range n, D i * paid (fun j => S₀ * R j) K B₀ G i
        - ∑ i ∈ range n, D i * (if banked (fun j => S₀ * R j) K B₀ i < G then
            lev * loss (S₀ * R i) K else 0) := by
    intro S₀
    unfold pathValue
    rw [← sum_sub_distrib]
    refine sum_congr rfl fun i _ => ?_
    ring
  show pathValue D R K B₀ G lev x n ≤ pathValue D R K B₀ G lev y n
  rw [split x, split y]
  have h1 : ∑ i ∈ range n, D i * paid (fun j => x * R j) K B₀ G i ≤
      ∑ i ∈ range n, D i * paid (fun j => y * R j) K B₀ G i := by
    simp only [paid_eq_capped_diff]
    have key := summation_by_parts_mono D
      (fun i => min (banked (fun j => x * R j) K B₀ i) G)
      (fun i => min (banked (fun j => y * R j) K B₀ i) G) hDdec.antitone
      (by simp [banked_zero]) (fun i => min_le_min_right G (hB i)) n
    have hpos : 0 ≤ D n * (min (banked (fun j => y * R j) K B₀ n) G
        - min (banked (fun j => x * R j) K B₀ n) G) :=
      mul_nonneg (hD n).le (sub_nonneg.2 (min_le_min_right G (hB n)))
    linarith
  have h2 : ∑ i ∈ range n, D i * (if banked (fun j => y * R j) K B₀ i < G then
        lev * loss (y * R i) K else 0) ≤
      ∑ i ∈ range n, D i * (if banked (fun j => x * R j) K B₀ i < G then
        lev * loss (x * R i) K else 0) := by
    refine sum_le_sum fun i _ => ?_
    refine mul_le_mul_of_nonneg_left ?_ (hD i).le
    have hl : loss (y * R i) K ≤ loss (x * R i) K := by
      unfold loss
      have := mul_le_mul_of_nonneg_right hxy (hR i).le
      exact max_le_max (by linarith) le_rfl
    have hBi := hB i
    split_ifs with hy hx hx
    · exact mul_le_mul_of_nonneg_left hl hlev
    · exact absurd (lt_of_le_of_lt hBi hy) hx
    · exact mul_nonneg hlev (loss_nonneg _ _)
    · exact le_rfl
  linarith

-- The most the client can gain: a target of 0.10 dollars per euro on 1,000,000 euros.
example : (1 / 10 : ℚ) * 1000000 = 100000 := by norm_num

-- No-target value at 1.08: the strip of forwards 372,702 less the twelve puts 202,714.
example : (372702 : ℤ) - 202714 = 169988 := by norm_num

-- What the target takes away at 1.08: 169,988 - (-258,829).
example : (169988 : ℤ) - (-258829) = 428817 := by norm_num

-- With 0.09 banked, 0.01 of target is left, so a fixing at 1.08 + 0.01 = 1.09 or higher ends it.
example : (108 / 100 : ℚ) + (1 / 10 - 9 / 100) = 109 / 100 := by norm_num

-- Forty bisection rounds on [1.00, 1.10] leave a bracket narrower than half a unit in the sixth decimal.
example : (1 / 10 : ℚ) / 2 ^ 40 < 1 / (2 * 10 ^ 6) := by norm_num

#print axioms gain_nonneg
#print axioms loss_nonneg
#print axioms banked_zero
#print axioms banked_succ
#print axioms paid_eq_capped_diff
#print axioms banked_mono_spot
#print axioms summation_by_parts_mono
#print axioms total_paid_gain_eq_banked_capped_at_target
#print axioms leveraged_cash_eq_forward_minus_puts
#print axioms path_value_monotone_in_spot

end TARF

end
