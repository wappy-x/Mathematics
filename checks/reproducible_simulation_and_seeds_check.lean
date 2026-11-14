-- Seeds: with N streams of L draws started at independent uniform places on a loop of P states, the chance that two streams share a state is at most N(N-1)/2 times (2L-1)/P.
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Basic.Real.Basic
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Tactic.NormNum
import Mathlib.Data.Int.Interval
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic

theorem overlap_diff_mem (L P : ℕ) (a b : ZMod P) (h : ∃ i < L, ∃ j < L, a + (i : ZMod P) = b + (j : ZMod P)) :
    b - a ∈ (Finset.Ioo (-(L : ℤ)) L).image (fun d : ℤ => (d : ZMod P)) := by
  obtain ⟨i, hi, j, hj, h⟩ := h
  refine Finset.mem_image.mpr ⟨(i : ℤ) - j, Finset.mem_Ioo.mpr ⟨by omega, by omega⟩, ?_⟩
  push_cast
  linear_combination h

theorem card_Ioo_neg (L : ℕ) : (Finset.Ioo (-(L : ℤ)) L).card = 2 * L - 1 := by
  rw [Int.card_Ioo]; omega

theorem pair_overlap_card_le (N L P : ℕ) [NeZero P] (i j : Fin N) (hij : i ≠ j) :
    (Finset.univ.filter (fun s : Fin N → ZMod P =>
        ∃ a < L, ∃ b < L, s i + (a : ZMod P) = s j + (b : ZMod P))).card
      ≤ (2 * L - 1) * P ^ (N - 1) := by
  classical
  set D := (Finset.Ioo (-(L : ℤ)) L).image (fun d : ℤ => (d : ZMod P))
  have hD : D.card ≤ 2 * L - 1 := (Finset.card_image_le).trans (card_Ioo_neg L).le
  let f : (Fin N → ZMod P) → ZMod P × ({k : Fin N // k ≠ j} → ZMod P) :=
    fun s => (s j - s i, fun k => s k)
  refine (Finset.card_le_card_of_injOn (t := D ×ˢ (Finset.univ)) f ?_ ?_).trans ?_
  rotate_left 2
  · rw [Finset.card_product, Finset.card_univ, Fintype.card_fun, ZMod.card]
    have : Fintype.card {k : Fin N // k ≠ j} = N - 1 := by simp
    rw [this]
    exact Nat.mul_le_mul_right _ hD
  · intro s hs
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hs
    simp only [Finset.coe_product, Finset.coe_univ, Set.mem_prod, Finset.mem_coe, Set.mem_univ, and_true, f]
    exact overlap_diff_mem L P (s i) (s j) hs
  · intro s _ t _ hst
    simp only [f, Prod.mk.injEq] at hst
    obtain ⟨h1, h2⟩ := hst
    have hi : s i = t i := congrFun h2 ⟨i, hij⟩
    funext k
    by_cases hk : k = j
    · subst hk; rw [hi] at h1; simpa using h1
    · exact congrFun h2 ⟨k, hk⟩

theorem lt_sum_card_Ioi (N : ℕ) : (∑ i : Fin N, (Finset.Ioi i).card) * 2 = N * (N - 1) := by
  simp only [Fin.card_Ioi]
  rw [Fin.sum_univ_eq_sum_range (fun i => N - 1 - i) N, Finset.sum_range_reflect (fun i => i) N]
  exact Finset.sum_range_id_mul_two N

#print axioms overlap_diff_mem
#print axioms card_Ioo_neg
#print axioms pair_overlap_card_le
#print axioms lt_sum_card_Ioi

/-- The overlap bound. Put each of `N` streams at an independent, uniformly random start on a
loop of `P` positions (`ZMod P`), and let each stream use the `L` positions from its start on.
The share of all `P ^ N` choices of starts in which two different streams share a position
is at most the number of pairs, `N(N-1)/2`, times `(2L - 1)/P`. -/
theorem stream_overlap_probability_le (N L P : ℕ) [NeZero P] :
    ((Finset.univ.filter (fun s : Fin N → ZMod P =>
        ∃ i j : Fin N, i ≠ j ∧ ∃ a < L, ∃ b < L, s i + (a : ZMod P) = s j + (b : ZMod P))).card : ℝ)
      / (P : ℝ) ^ N
    ≤ ((N : ℝ) * ((N : ℝ) - 1) / 2) * ((2 * L - 1 : ℕ) : ℝ) / (P : ℝ) := by
  classical
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp
  set S := Finset.univ.filter (fun s : Fin N → ZMod P =>
        ∃ i j : Fin N, i ≠ j ∧ ∃ a < L, ∃ b < L, s i + (a : ZMod P) = s j + (b : ZMod P))
  let T : Fin N → Fin N → Finset (Fin N → ZMod P) := fun i j =>
    Finset.univ.filter (fun s : Fin N → ZMod P =>
        ∃ a < L, ∃ b < L, s i + (a : ZMod P) = s j + (b : ZMod P))
  have hsub : S ⊆ Finset.univ.biUnion (fun i => (Finset.Ioi i).biUnion (fun j => T i j)) := by
    intro s hs
    simp only [S, Finset.mem_filter, Finset.mem_univ, true_and] at hs
    obtain ⟨i, j, hij, a, ha, b, hb, h⟩ := hs
    simp only [Finset.mem_biUnion, Finset.mem_univ, true_and, Finset.mem_Ioi, T,
      Finset.mem_filter]
    rcases lt_or_gt_of_ne hij with hlt | hgt
    · exact ⟨i, j, hlt, a, ha, b, hb, h⟩
    · exact ⟨j, i, hgt, b, hb, a, ha, h.symm⟩
  have hcard : S.card ≤ ∑ i : Fin N, (Finset.Ioi i).card * ((2 * L - 1) * P ^ (N - 1)) := by
    refine (Finset.card_le_card hsub).trans ((Finset.card_biUnion_le).trans ?_)
    refine Finset.sum_le_sum fun i _ => (Finset.card_biUnion_le).trans ?_
    rw [← smul_eq_mul, ← Finset.sum_const]
    refine Finset.sum_le_sum fun j hj => ?_
    exact pair_overlap_card_le N L P i j (ne_of_lt (Finset.mem_Ioi.mp hj))
  rw [← Finset.sum_mul] at hcard
  have hnat : S.card * 2 ≤ N * (N - 1) * ((2 * L - 1) * P ^ (N - 1)) := by
    rw [← lt_sum_card_Ioi N]; nlinarith
  have hreal : (S.card : ℝ) * 2 ≤ (N : ℝ) * ((N : ℝ) - 1) * (((2 * L - 1 : ℕ) : ℝ) * (P : ℝ) ^ (N - 1)) := by
    have := (Nat.cast_le (α := ℝ)).mpr hnat
    push_cast [Nat.cast_sub (show 1 ≤ N from hN)] at this
    simpa using this
  have hP : (0 : ℝ) < P := by exact_mod_cast Nat.pos_of_ne_zero (NeZero.ne P)
  have hpow : (P : ℝ) ^ N = (P : ℝ) ^ (N - 1) * P := by
    rw [← pow_succ]; congr 1; omega
  rw [div_le_iff₀ (by positivity), hpow]
  have : ((N : ℝ) * ((N : ℝ) - 1) / 2) * ((2 * L - 1 : ℕ) : ℝ) / (P : ℝ) * ((P : ℝ) ^ (N - 1) * P)
      = (N : ℝ) * ((N : ℝ) - 1) * (((2 * L - 1 : ℕ) : ℝ) * (P : ℝ) ^ (N - 1)) / 2 := by
    field_simp
  rw [this]
  linarith

/-- One pair. Fix where stream A starts on a loop of `P` positions. Stream B, also `L` long,
shares a position with A for exactly `2L - 1` starting places: within `L - 1` before A's start,
at it, or within `L - 1` after it (as long as those places are all different, `2L - 1 ≤ P`). -/
theorem one_pair_overlap_positions (L P : ℕ) [NeZero P] (hL : 0 < L) (hLP : 2 * L - 1 ≤ P)
    (a : ZMod P) :
    (Finset.univ.filter (fun b : ZMod P =>
        ∃ i < L, ∃ j < L, a + (i : ZMod P) = b + (j : ZMod P))).card = 2 * L - 1 := by
  classical
  have hset : Finset.univ.filter (fun b : ZMod P =>
        ∃ i < L, ∃ j < L, a + (i : ZMod P) = b + (j : ZMod P))
      = (Finset.Ioo (-(L : ℤ)) L).image (fun d : ℤ => a + (d : ZMod P)) := by
    ext b
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_image, Finset.mem_Ioo]
    constructor
    · intro h
      obtain ⟨i, hi, j, hj, h⟩ := h
      refine ⟨(i : ℤ) - j, ⟨by omega, by omega⟩, ?_⟩
      push_cast
      linear_combination h
    · rintro ⟨d, ⟨h1, h2⟩, rfl⟩
      rcases le_or_gt 0 d with hd | hd
      · refine ⟨d.toNat, by omega, 0, hL, ?_⟩
        have : ((d.toNat : ℕ) : ZMod P) = (d : ZMod P) := by
          rw [← Int.cast_natCast, Int.toNat_of_nonneg hd]
        simp [this]
      · refine ⟨0, hL, (-d).toNat, by omega, ?_⟩
        have : (((-d).toNat : ℕ) : ZMod P) = ((-d : ℤ) : ZMod P) := by
          rw [← Int.cast_natCast, Int.toNat_of_nonneg (by omega)]
        rw [this]; push_cast; ring
  rw [hset, Finset.card_image_of_injOn, card_Ioo_neg]
  intro x hx y hy hxy
  simp only [Finset.coe_Ioo, Set.mem_Ioo] at hx hy
  simp only [add_right_inj] at hxy
  rw [ZMod.intCast_eq_intCast_iff_dvd_sub] at hxy
  have := Int.eq_zero_of_abs_lt_dvd hxy (by rw [abs_lt]; constructor <;> omega)
  omega

/-- The counter's loop. A counter that steps by an odd number `γ` and keeps the remainder after
dividing by `2 ^ k` comes back to its start only after `2 ^ k` steps, so its states form one loop
of length `2 ^ k` (for SplitMix64, `k = 64`). -/
theorem odd_step_counter_period (k γ : ℕ) (hγ : Odd γ) :
    addOrderOf (γ : ZMod (2 ^ k)) = 2 ^ k := by
  have hc : Nat.Coprime (2 ^ k) γ := (Nat.coprime_two_left.mpr hγ).pow_left k
  rw [ZMod.addOrderOf_coe _ (by positivity), hc, Nat.div_one]

/-- SplitMix64's scrambler, as in the card's code. -/
def splitmixMix (z : ℕ) : ℕ :=
  let z := ((z ^^^ (z >>> 30)) * 0xBF58476D1CE4E5B9) % 2 ^ 64
  let z := ((z ^^^ (z >>> 27)) * 0x94D049BB133111EB) % 2 ^ 64
  z ^^^ (z >>> 31)

-- From seed 0, the first output is e220a8397b1dcdaf, as on the Random numbers card.
example : splitmixMix ((0 + 0x9E3779B97F4A7C15) % 2 ^ 64) = 0xE220A8397B1DCDAF := by decide

-- The step gamma is odd, and 0xF1DE83E19937733D is its inverse: the product leaves 1 after dividing by 2^64.
example : Odd 0x9E3779B97F4A7C15 := by decide
example : (0x9E3779B97F4A7C15 * 0xF1DE83E19937733D) % 2 ^ 64 = 1 := by norm_num

-- The four stream seeds are the first four outputs from the master seed 20261111.
example : [1, 2, 3, 4].map (fun k => splitmixMix ((20261111 + k * 0x9E3779B97F4A7C15) % 2 ^ 64))
    = [0xFBFC5102A7266B8B, 0x4D299F0370E6186B, 0xE0300AA22B3714F3, 0x43207C09B5D5E859] := by decide

-- Placed on the loop, the nearest two starts are 2144390933074202976 draws apart, far more than 200000.
example :
    let pos := [0xFBFC5102A7266B8B, 0x4D299F0370E6186B, 0xE0300AA22B3714F3, 0x43207C09B5D5E859].map
      (fun s => s * 0xF1DE83E19937733D % 2 ^ 64)
    ((List.finRange 4).flatMap fun i => (List.finRange 4).filterMap fun j =>
        if i = j then none else some ((pos[j]! + 2 ^ 64 - pos[i]!) % 2 ^ 64)).min?
      = some 2144390933074202976 := by decide

-- Worked numbers, by hand.
example : 78690 + 78519 + 78306 + 78549 = 314064 := by norm_num
example : 4 * 100000 = 400000 ∧ 2 * 400000 = 800000 := by norm_num
example : 4 * 3 / 2 = 6 := by norm_num
example : 2 * 200000 - 1 = 399999 := by norm_num
-- The toy loop of 256 with segments of 10: 19 clashing seeds for each of 256 seeds.
example : 256 * (2 * 10 - 1) = 4864 := by norm_num
-- 10,000 streams make 49,995,000 pairs.
example : 10000 * 9999 / 2 = 49995000 := by norm_num

#print axioms stream_overlap_probability_le
#print axioms one_pair_overlap_positions
#print axioms odd_step_counter_period
