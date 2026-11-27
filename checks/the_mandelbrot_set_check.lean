-- The Mandelbrot set: c has a bounded orbit of 0 under z² + c exactly when every point of that orbit stays within 2 of 0, the main cardioid c = λ/2 − λ²/4 is where a fixed point has multiplier λ, and a 2-cycle of z² + c has multiplier 4(c + 1).
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Topology.Bornology.Basic
import Mathlib.Logic.Function.Iterate

open Complex

/-- The Mandelbrot set M: every complex c for which the orbit of 0 under z ↦ z² + c,
that is 0, c, c² + c, …, is a bounded set. -/
def mandelbrotSet : Set ℂ :=
  {c | Bornology.IsBounded (Set.range fun n : ℕ => (fun z : ℂ => z ^ 2 + c)^[n] 0)}

theorem deriv_sq_add_const (c p : ℂ) : deriv (fun z : ℂ => z ^ 2 + c) p = 2 * p := by
  simp

#print axioms deriv_sq_add_const

theorem norm_iterate_escape (c : ℂ) (n : ℕ) (r : ℝ) (hr : 2 < r) (hc : ‖c‖ ≤ r)
    (hn : r ≤ ‖(fun z : ℂ => z ^ 2 + c)^[n] 0‖) (k : ℕ) :
    r + k * (r * (r - 2)) ≤ ‖(fun z : ℂ => z ^ 2 + c)^[n + k] 0‖ := by
  induction k with
  | zero => simpa using hn
  | succ k ih =>
    rw [← add_assoc, Function.iterate_succ_apply']
    set w := (fun z : ℂ => z ^ 2 + c)^[n + k] 0
    have h1 : ‖w‖ ^ 2 - ‖c‖ ≤ ‖w ^ 2 + c‖ := by
      have := norm_sub_le (w ^ 2 + c) c
      simp only [add_sub_cancel_right, norm_pow] at this
      linarith
    have hk : (0 : ℝ) ≤ k * (r * (r - 2)) := by positivity
    have hw : r ≤ ‖w‖ := by linarith
    push_cast
    show r + (k + 1) * (r * (r - 2)) ≤ ‖w ^ 2 + c‖
    nlinarith

#print axioms norm_iterate_escape

/-- c is in the Mandelbrot set exactly when every point zₙ of the orbit of 0 under z² + c
stays within distance 2 of 0. So M lies inside the disc of radius 2 (take n = 1, z₁ = c),
and one step strictly past 2 proves escape. -/
theorem mem_mandelbrotSet_iff_forall_norm_le_two (c : ℂ) :
    c ∈ mandelbrotSet ↔ ∀ n : ℕ, ‖(fun z : ℂ => z ^ 2 + c)^[n] 0‖ ≤ 2 := by
  rw [mandelbrotSet, Set.mem_ofPred_eq]
  constructor
  · intro h
    obtain ⟨C, hC⟩ := isBounded_iff_forall_norm_le.1 h
    have hC' : ∀ n, ‖(fun z : ℂ => z ^ 2 + c)^[n] 0‖ ≤ C := fun n => hC _ ⟨n, rfl⟩
    by_contra hne
    push Not at hne
    obtain ⟨m, hm⟩ := hne
    -- find n and r with 2 < r, ‖c‖ ≤ r, r ≤ ‖z_n‖
    obtain ⟨n, r, hr, hcr, hnr⟩ : ∃ n : ℕ, ∃ r : ℝ, 2 < r ∧ ‖c‖ ≤ r ∧
        r ≤ ‖(fun z : ℂ => z ^ 2 + c)^[n] 0‖ := by
      by_cases hc : 2 < ‖c‖
      · exact ⟨1, ‖c‖, hc, le_rfl, by simp⟩
      · exact ⟨m, _, hm, by push Not at hc; linarith, le_rfl⟩
    have hd : 0 < r * (r - 2) := by nlinarith
    obtain ⟨k, hk⟩ := exists_nat_gt (C / (r * (r - 2)))
    have := norm_iterate_escape c n r hr hcr hnr k
    have h2 := hC' (n + k)
    rw [div_lt_iff₀ hd] at hk
    nlinarith
  · intro h
    exact isBounded_iff_forall_norm_le.2 ⟨2, by rintro _ ⟨n, rfl⟩; exact h n⟩

/-- The main cardioid. The map z² + c has a fixed point p (p² + c = p) whose multiplier,
the derivative 2p there, equals λ exactly when c = λ/2 − λ²/4. -/
theorem exists_fixed_point_with_multiplier_iff_cardioid (c lam : ℂ) :
    (∃ p : ℂ, p ^ 2 + c = p ∧ deriv (fun z : ℂ => z ^ 2 + c) p = lam) ↔
      c = lam / 2 - lam ^ 2 / 4 := by
  simp only [deriv_sq_add_const]
  constructor
  · rintro ⟨p, h1, h2⟩
    subst h2
    linear_combination h1
  · intro h
    refine ⟨lam / 2, ?_, by ring⟩
    rw [h]; ring

/-- The period-2 disc. If a ≠ b form a 2-cycle of z² + c (a goes to b and b goes back to a),
then a + b = −1 and ab = c + 1, so the cycle's multiplier, the product of the derivatives
at its two points, is 4(c + 1). It attracts exactly when |c + 1| < 1/4. -/
theorem two_cycle_multiplier (c a b : ℂ) (hab : a ≠ b) (ha : a ^ 2 + c = b)
    (hb : b ^ 2 + c = a) :
    a + b = -1 ∧ a * b = c + 1 ∧
      deriv (fun z : ℂ => z ^ 2 + c) a * deriv (fun z : ℂ => z ^ 2 + c) b = 4 * (c + 1) := by
  have hs : a + b = -1 := by
    have h : (a - b) * (a + b + 1) = 0 := by linear_combination ha - hb
    rcases mul_eq_zero.1 h with h | h
    · exact absurd (sub_eq_zero.1 h) hab
    · linear_combination h
  have hp : a * b = c + 1 := by linear_combination a * hs - ha - hs
  refine ⟨hs, hp, ?_⟩
  simp only [deriv_sq_add_const]
  linear_combination 4 * hp

-- Worked numbers. c = i: the orbit of 0 is 0, i, −1 + i, −i, −1 + i, a 2-cycle, so i is in M.
example : (fun z : ℂ => z ^ 2 + I)^[2] 0 = -1 + I := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : (fun z : ℂ => z ^ 2 + I)^[3] 0 = -I := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : (fun z : ℂ => z ^ 2 + I)^[4] 0 = -1 + I := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : I ∈ mandelbrotSet := by
  have h : ∀ n : ℕ, (fun z : ℂ => z ^ 2 + I)^[n] 0 ∈ ({0, I, -1 + I, -I} : Set ℂ) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Function.iterate_succ_apply']
      rcases ih with h | h | h | h <;> rw [h]
      · simp
      · have e : I ^ 2 + I = -1 + I := by rw [I_sq]
        rw [e]; simp
      · have e : (-1 + I) ^ 2 + I = -I := by ring_nf; rw [I_sq]; ring
        rw [e]; simp
      · have e : (-I) ^ 2 + I = -1 + I := by rw [neg_sq, I_sq]
        rw [e]; simp
  exact (Set.toFinite ({0, I, -1 + I, -I} : Set ℂ)).isBounded.subset
    (by rintro _ ⟨n, rfl⟩; exact h n)
-- The 2-cycle −1 + i, −i has multiplier 4(−1 + i)(−i) = 4 + 4i: it repels, yet i is in M.
example : 4 * (-1 + I) * (-I) = 4 + 4 * I := by norm_num [Complex.ext_iff]
-- c = 1: the orbit of 0 is 0, 1, 2, 5, 26, past 2 at step 3, so 1 is not in M.
example : (fun z : ℂ => z ^ 2 + 1)^[2] 0 = 2 := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : (fun z : ℂ => z ^ 2 + 1)^[3] 0 = 5 := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : (fun z : ℂ => z ^ 2 + 1)^[4] 0 = 26 := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : (1 : ℂ) ∉ mandelbrotSet := by
  rw [mem_mandelbrotSet_iff_forall_norm_le_two]
  intro h
  have h3 := h 3
  have : (fun z : ℂ => z ^ 2 + 1)^[3] 0 = 5 := by
    simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
    norm_num [Complex.ext_iff, pow_two]
  rw [this] at h3
  norm_num at h3
-- Example c = −1: 0 goes to −1 and back; the start 2 runs off as 2, 3, 8, 63.
example : (fun z : ℂ => z ^ 2 - 1)^[2] 0 = 0 := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : (fun z : ℂ => z ^ 2 - 1)^[3] 2 = 63 := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
-- c = −2: the orbit 0, −2, 2, 2 sits exactly on 2, and −2 is in M.
example : (fun z : ℂ => z ^ 2 + -2)^[3] 0 = 2 := by
  simp only [Function.iterate_succ_apply', Function.iterate_zero, id]
  norm_num [Complex.ext_iff, pow_two]
example : (-2 : ℂ) ∈ mandelbrotSet := by
  have h : ∀ n : ℕ, (fun z : ℂ => z ^ 2 + -2)^[n] 0 ∈ ({0, -2, 2} : Set ℂ) := by
    intro n
    induction n with
    | zero => simp
    | succ n ih =>
      rw [Function.iterate_succ_apply']
      rcases ih with h | h | h <;> rw [h]
      · simp
      · right; right; norm_num
      · right; right; norm_num
  exact (Set.toFinite ({0, -2, 2} : Set ℂ)).isBounded.subset
    (by rintro _ ⟨n, rfl⟩; exact h n)
-- The cardioid at λ = 1 gives the cusp 1/4, at λ = −1 the back −3/4, where |c + 1| = 1/4.
example : (1 : ℂ) / 2 - 1 ^ 2 / 4 = 1 / 4 := by norm_num [Complex.ext_iff]
example : (-1 : ℂ) / 2 - (-1) ^ 2 / 4 = -3 / 4 := by norm_num [Complex.ext_iff]
example : ‖(-3 / 4 : ℂ) + 1‖ = 1 / 4 := by norm_num [Complex.ext_iff]

#print axioms mem_mandelbrotSet_iff_forall_norm_le_two
#print axioms exists_fixed_point_with_multiplier_iff_cardioid
#print axioms two_cycle_multiplier
