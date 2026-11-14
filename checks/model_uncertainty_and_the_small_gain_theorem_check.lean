-- Writing down model error: at each frequency, if the envelope times the complementary sensitivity has size below 1, no error inside the envelope can put the true loop gain on −1, and the bound is exact for the worst error.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

/-- The small gain rule for a percentage error, frequency by frequency (the disc picture on
the Nyquist plot). Let `L ω` be the nominal loop gain, `W ω` the envelope and `Δ ω` the
unknown error at frequency `ω`. If the nominal loop never touches −1 (`1 + L ω ≠ 0`), the
envelope times the complementary sensitivity `T = L / (1 + L)` has size below 1 at every
frequency, and the error has size at most 1 at every frequency, then the true loop gain
`L (1 + W Δ)` never reaches −1 at any frequency. -/
theorem small_gain_true_loop_gain_avoids_minus_one
    (L W Δ : ℝ → ℂ)
    (hnom : ∀ ω, 1 + L ω ≠ 0)
    (hgain : ∀ ω, ‖W ω * (L ω / (1 + L ω))‖ < 1)
    (hΔ : ∀ ω, ‖Δ ω‖ ≤ 1) :
    ∀ ω, 1 + L ω * (1 + W ω * Δ ω) ≠ 0 := by
  intro ω
  have h1 := hnom ω
  have hlt : ‖W ω * (L ω / (1 + L ω)) * Δ ω‖ < 1 := by
    rw [norm_mul]
    calc ‖W ω * (L ω / (1 + L ω))‖ * ‖Δ ω‖ ≤ ‖W ω * (L ω / (1 + L ω))‖ * 1 :=
          mul_le_mul_of_nonneg_left (hΔ ω) (norm_nonneg _)
      _ < 1 := by rw [mul_one]; exact hgain ω
  have hne : 1 + W ω * (L ω / (1 + L ω)) * Δ ω ≠ 0 := by
    intro h
    have : W ω * (L ω / (1 + L ω)) * Δ ω = -1 := by linear_combination h
    rw [this, norm_neg, norm_one] at hlt
    exact lt_irrefl _ hlt
  have key : 1 + L ω * (1 + W ω * Δ ω)
      = (1 + L ω) * (1 + W ω * (L ω / (1 + L ω)) * Δ ω) := by
    field_simp
    ring
  rw [key]
  exact mul_ne_zero h1 hne

/-- Pulling the error out of the loop (Step 2). With the setpoint at zero, the controller
sends `u = −C y`, and the true motor answers `y = P₀ u + P₀ W p`, where `p` is the error's
output and `u` is what it sees. If the nominal loop `1 + P₀ C` is not zero, the error sees the
rest of the loop as one block: `u = −W T p`, with `T = P₀ C / (1 + P₀ C)`. -/
theorem error_sees_minus_W_T
    (P₀ C W u y p : ℂ)
    (hnom : 1 + P₀ * C ≠ 0)
    (hu : u = -C * y)
    (hy : y = P₀ * u + P₀ * W * p) :
    u = -(W * (P₀ * C / (1 + P₀ * C))) * p := by
  have h : u * (1 + P₀ * C) = -(C * P₀ * W * p) := by
    rw [hy] at hu
    linear_combination hu
  field_simp
  linear_combination h

/-- The rule cannot be improved (Step 4). If the nominal loop does not touch −1 and the
envelope times the complementary sensitivity has size exactly 1 at some frequency, then an
error of size exactly 1 with the right phase puts the true loop gain `L (1 + W Δ)` on −1. -/
theorem small_gain_exact_for_worst_error
    (L W : ℂ)
    (hnom : 1 + L ≠ 0)
    (hpeak : ‖W * (L / (1 + L))‖ = 1) :
    ∃ Δ : ℂ, ‖Δ‖ = 1 ∧ 1 + L * (1 + W * Δ) = 0 := by
  have hx : W * (L / (1 + L)) ≠ 0 := by
    intro h
    rw [h, norm_zero] at hpeak
    exact zero_ne_one hpeak
  refine ⟨-(W * (L / (1 + L)))⁻¹, ?_, ?_⟩
  · rw [norm_neg, norm_inv, hpeak, inv_one]
  · have hLW : L * W = (1 + L) * (W * (L / (1 + L))) := by
      field_simp
    have hinv := mul_inv_cancel₀ hx
    linear_combination (-(W * (L / (1 + L)))⁻¹) * hLW - (1 + L) * hinv

-- The card's exact numbers. J₀ = 0.20 = 1/5, J = 0.40 = 2/5, b = 0.40 = 2/5, τₐ = 0.020 = 1/50,
-- Kp = 10, Ki = 50.

-- For the doubled inertia, the percentage error (J₀ − J) s / (J s + b) is −(0.5 s / (s + 1)),
-- so its size is exactly the envelope W(s) = 0.5 s / (s + 1).
example (s : ℂ) (hs : s + 1 ≠ 0) :
    ((1 / 5 : ℂ) - 2 / 5) * s / (2 / 5 * s + 2 / 5) = -((1 / 2) * s / (s + 1)) := by
  have h : (2 / 5 * s + 2 / 5 : ℂ) = 2 / 5 * (s + 1) := by ring
  rw [h]
  field_simp
  ring

-- Routh's decisive term: b + Kp − τₐ Ki = 0.4 + 10 − 0.02 × 50 = 9.4.
example : (2 / 5 : ℚ) + 10 - 1 / 50 * 50 = 47 / 5 := by norm_num

-- For the cubic J τₐ s³ + (J + b τₐ) s² + (b + Kp) s + Ki, Routh's product test
-- (J + b τₐ)(b + Kp) − J τₐ Ki equals 9.4 J plus a positive constant.
example (J : ℚ) :
    (J + 2 / 5 * (1 / 50)) * (2 / 5 + 10) - J * (1 / 50) * 50
      = 47 / 5 * J + 2 / 5 * (1 / 50) * (2 / 5 + 10) := by
  ring

#print axioms small_gain_true_loop_gain_avoids_minus_one
#print axioms error_sees_minus_W_T
#print axioms small_gain_exact_for_worst_error
