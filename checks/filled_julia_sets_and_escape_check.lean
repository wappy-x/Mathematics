-- Filled Julia sets: for the rule z ↦ z² + c, an orbit that gets farther from 0 than both 2 and |c| runs off to infinity, so the starts with bounded orbits form a closed, bounded set, which for c = 0 is the closed unit disc with the unit circle as its edge.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Normed.Group.Bounded
import Mathlib.Topology.Order.Basic
import Mathlib.NumberTheory.Real.GoldenRatio
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.Normed.Module.RCLike.Real

open Filter Metric Set

/-- **The escape test.** Iterate the rule f(z) = z² + c from a start z₀, giving the orbit
z₀, z₁, z₂, …, where zₙ is f applied n times. If at some step n the orbit is strictly farther
from 0 than both 2 and |c|, then from there on each step multiplies its distance from 0 by at
least λ = |zₙ| − 1 > 1: |zₙ₊ₖ| ≥ λᵏ · |zₙ| for every k. So the orbit runs off to infinity:
|zₘ| grows without bound as m grows. -/
theorem escape_past_radius (c z₀ : ℂ) (n : ℕ)
    (h : max 2 ‖c‖ < ‖(fun z : ℂ => z ^ 2 + c)^[n] z₀‖) :
    (∀ k : ℕ, (‖(fun z : ℂ => z ^ 2 + c)^[n] z₀‖ - 1) ^ k * ‖(fun z : ℂ => z ^ 2 + c)^[n] z₀‖
        ≤ ‖(fun z : ℂ => z ^ 2 + c)^[n + k] z₀‖) ∧
      Tendsto (fun m : ℕ => ‖(fun z : ℂ => z ^ 2 + c)^[m] z₀‖) atTop atTop := by
  set r := ‖(fun z : ℂ => z ^ 2 + c)^[n] z₀‖ with hr
  have h2 : (2 : ℝ) < r := lt_of_le_of_lt (le_max_left _ _) h
  have hc : ‖c‖ < r := lt_of_le_of_lt (le_max_right _ _) h
  have key : ∀ k : ℕ, (r - 1) ^ k * r ≤ ‖(fun z : ℂ => z ^ 2 + c)^[n + k] z₀‖ := by
    intro k
    induction k with
    | zero => simp [hr]
    | succ k ih =>
      set y := (fun z : ℂ => z ^ 2 + c)^[n + k] z₀ with hy
      have hpow : (1 : ℝ) ≤ (r - 1) ^ k := one_le_pow₀ (by linarith)
      have hyr : r ≤ ‖y‖ := le_trans (by nlinarith) ih
      have hstep : (fun z : ℂ => z ^ 2 + c)^[n + (k + 1)] z₀ = y ^ 2 + c := by
        rw [← add_assoc, Function.iterate_succ_apply']
      rw [hstep]
      have h1 : ‖y ^ 2‖ - ‖c‖ ≤ ‖y ^ 2 + c‖ := by
        have := norm_sub_le (y ^ 2 + c) c
        rw [add_sub_cancel_right] at this
        linarith
      rw [norm_pow] at h1
      have hy0 : 0 ≤ ‖y‖ := norm_nonneg _
      have : (r - 1) ^ (k + 1) * r = ((r - 1) ^ k * r) * (r - 1) := by ring
      rw [this]
      have hA : ((r - 1) ^ k * r) * (r - 1) ≤ ‖y‖ * (r - 1) :=
        mul_le_mul_of_nonneg_right ih (by linarith)
      nlinarith
  refine ⟨key, ?_⟩
  have hlim : Tendsto (fun k : ℕ => (r - 1) ^ k * r) atTop atTop :=
    (tendsto_pow_atTop_atTop_of_one_lt (by linarith : (1 : ℝ) < r - 1)).atTop_mul_const
      (by linarith)
  have hk : Tendsto (fun k : ℕ => ‖(fun z : ℂ => z ^ 2 + c)^[k + n] z₀‖) atTop atTop := by
    refine tendsto_atTop_mono (fun k => ?_) hlim
    rw [add_comm]; exact key k
  exact (tendsto_add_atTop_iff_nat (f := fun m : ℕ => ‖(fun z : ℂ => z ^ 2 + c)^[m] z₀‖) n).1 hk

/-- **The filled Julia set is closed and bounded.** For the rule f(z) = z² + c, let K be the
filled Julia set: the starts whose orbit never passes the escape radius R = max(2, |c|). Then
K is exactly the set of starts whose orbit stays bounded; K is closed; K lies inside the closed
disc of radius R, so it is bounded; a start is in K exactly when its image f(z) is; and K is
symmetric through 0. -/
theorem filled_julia_set_closed_bounded (c : ℂ) :
    let K : Set ℂ := {z | ∀ n : ℕ, ‖(fun w : ℂ => w ^ 2 + c)^[n] z‖ ≤ max 2 ‖c‖}
    K = {z | BddAbove (range fun n : ℕ => ‖(fun w : ℂ => w ^ 2 + c)^[n] z‖)} ∧
      IsClosed K ∧ K ⊆ closedBall 0 (max 2 ‖c‖) ∧ Bornology.IsBounded K ∧
      (∀ z, z ^ 2 + c ∈ K ↔ z ∈ K) ∧ (∀ z, -z ∈ K ↔ z ∈ K) := by
  intro K
  set f : ℂ → ℂ := fun w : ℂ => w ^ 2 + c with hf
  set R : ℝ := max 2 ‖c‖ with hR
  have hK : ∀ z, z ∈ K ↔ ∀ n : ℕ, ‖f^[n] z‖ ≤ R := fun z => Iff.rfl
  have hbig : ∀ z, R < ‖z‖ → R < ‖f z‖ := by
    intro z hz
    have := (escape_past_radius c z 0 (by rw [Function.iterate_zero_apply]; exact hz)).1 1
    simp only [Function.iterate_zero, id, zero_add, Function.iterate_one, pow_one] at this
    have h2 : (2 : ℝ) < ‖z‖ := lt_of_le_of_lt (le_max_left _ _) hz
    have : ‖z‖ ≤ ‖f z‖ := le_trans (by nlinarith) this
    linarith
  have hfK : ∀ z, f z ∈ K ↔ z ∈ K := by
    intro z
    rw [hK, hK]
    constructor
    · intro H n
      cases n with
      | zero =>
        simp only [Function.iterate_zero, id]
        by_contra hz
        have := hbig z (lt_of_not_ge hz)
        have h0 := H 0
        simp only [Function.iterate_zero, id] at h0
        linarith
      | succ n =>
        rw [Function.iterate_succ_apply]
        exact H n
    · intro H n
      rw [← Function.iterate_succ_apply]
      exact H (n + 1)
  refine ⟨?_, ?_, ?_, ?_, hfK, ?_⟩
  · ext z
    simp only [mem_ofPred_eq]
    constructor
    · intro H
      exact ⟨R, by rintro _ ⟨n, rfl⟩; exact H n⟩
    · intro H n
      by_contra hn
      have := (escape_past_radius c z n (lt_of_not_ge hn)).2
      exact not_bddAbove_of_tendsto_atTop this H
  · have : K = ⋂ n : ℕ, {z | ‖f^[n] z‖ ≤ R} := by
      ext z; simp [hK]
    rw [this]
    refine isClosed_iInter fun n => ?_
    have hc : Continuous f := by rw [hf]; fun_prop
    exact isClosed_le ((hc.iterate n).norm) continuous_const
  · intro z hz
    have := hz 0
    simpa only [Function.iterate_zero_apply, mem_closedBall_zero_iff] using this
  · refine (Metric.isBounded_closedBall (x := (0 : ℂ)) (r := R)).subset ?_
    intro z hz
    have := hz 0
    simpa only [Function.iterate_zero_apply, mem_closedBall_zero_iff] using this
  · intro z
    have : f (-z) = f z := by simp [hf]
    rw [← hfK, this, hfK]

/-- **The case c = 0 by hand.** For the rule f(z) = z², which only squares, the filled Julia
set (starts whose orbit never passes the escape radius max(2, 0) = 2) is the closed unit disc
|z| ≤ 1, and the Julia set, its boundary, is the unit circle |z| = 1. -/
theorem filled_julia_set_of_zero :
    let K : Set ℂ := {z | ∀ n : ℕ, ‖(fun w : ℂ => w ^ 2 + 0)^[n] z‖ ≤ max 2 ‖(0 : ℂ)‖}
    K = closedBall 0 1 ∧ frontier K = sphere 0 1 := by
  intro K
  have hit : ∀ (n : ℕ) (z : ℂ), (fun w : ℂ => w ^ 2 + 0)^[n] z = z ^ (2 ^ n) := by
    intro n
    induction n with
    | zero => intro z; simp
    | succ n ih =>
      intro z
      rw [Function.iterate_succ_apply', ih, add_zero, ← pow_mul, pow_succ]
  have hmax : max 2 ‖(0 : ℂ)‖ = (2 : ℝ) := by simp
  have hKeq : K = closedBall 0 1 := by
    ext z
    rw [mem_closedBall_zero_iff]
    show (∀ n : ℕ, ‖(fun w : ℂ => w ^ 2 + 0)^[n] z‖ ≤ max 2 ‖(0 : ℂ)‖) ↔ ‖z‖ ≤ 1
    simp only [hit, hmax, norm_pow]
    constructor
    · intro H
      by_contra hz
      rw [not_le] at hz
      obtain ⟨m, hm⟩ := ((tendsto_pow_atTop_atTop_of_one_lt hz).eventually_gt_atTop 2).exists
      have hle : ‖z‖ ^ m ≤ ‖z‖ ^ (2 ^ m) :=
        pow_le_pow_right₀ hz.le (Nat.lt_two_pow_self).le
      linarith [H m]
    · intro hz n
      have : ‖z‖ ^ (2 ^ n) ≤ 1 := pow_le_one₀ (norm_nonneg _) hz
      linarith
  refine ⟨hKeq, ?_⟩
  rw [hKeq]
  exact frontier_closedBall (0 : ℂ) one_ne_zero

-- The card's exact worked numbers, for the rule "square, then subtract 1" (c = −1).
-- The 2-cycle: 0 goes to −1 and back to 0.
example : (0 : ℤ) ^ 2 - 1 = -1 ∧ (-1 : ℤ) ^ 2 - 1 = 0 := by norm_num
example : ((fun z : ℂ => z ^ 2 + (-1))^[2]) 0 = 0 := by norm_num
-- Start 2 runs off: 2, 3, 8, 63.
example : (2 : ℤ) ^ 2 - 1 = 3 ∧ (3 : ℤ) ^ 2 - 1 = 8 ∧ (8 : ℤ) ^ 2 - 1 = 63 := by norm_num
-- Start 1.5 = 3/2: 1.25, 0.5625, then −0.68359375 (printed −0.683594).
example : ((3 : ℚ) / 2) ^ 2 - 1 = 5 / 4 ∧ ((5 : ℚ) / 4) ^ 2 - 1 = 9 / 16 ∧
    ((9 : ℚ) / 16) ^ 2 - 1 = -175 / 256 := by norm_num
-- Start 1.7 = 17/10: 1.89, then 2.5721, past the radius max(2, 1) = 2 at step 2.
example : ((17 : ℚ) / 10) ^ 2 - 1 = 189 / 100 ∧ ((189 : ℚ) / 100) ^ 2 - 1 = 25721 / 10000 ∧
    max 2 1 < (25721 : ℚ) / 10000 := by norm_num
-- The guaranteed growth 2.5721 × 1.5721 = 4.04359841 is below the real next value 5.61569841.
example : (25721 : ℚ) / 10000 * (25721 / 10000 - 1) = 404359841 / 100000000 ∧
    ((25721 : ℚ) / 10000) ^ 2 - 1 = 561569841 / 100000000 ∧
    (404359841 : ℚ) / 100000000 ≤ 561569841 / 100000000 := by norm_num
-- Mistake 2: with c = −2 the start 2 stays at 2 (length exactly 2, not more).
example : (2 : ℤ) ^ 2 - 2 = 2 := by norm_num
-- The edge on the real line for c = −1 is the golden ratio φ, a fixed point: φ² − 1 = φ.
example : Real.goldenRatio ^ 2 - 1 = Real.goldenRatio := by
  rw [Real.goldenRatio_sq]; norm_num

#print axioms escape_past_radius
#print axioms filled_julia_set_closed_bounded
#print axioms filled_julia_set_of_zero
