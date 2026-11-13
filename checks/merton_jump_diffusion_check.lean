-- Merton jump-diffusion: the compensator identity, the branch yield that matches each jump count's average price, and the fact that the branch forwards average back to the forward.
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real Nat

/-- The compensator identity (Step 1): averaging the jump factor `(1 + k)^n` over a
Poisson count with mean `λ T`, using the weights `w_n = e^(-λT) (λT)^n / n!`, gives
`e^(λ k T)`. The series converges and its sum is exactly `e^(λ k T)`. -/
theorem merton_compensator_identity (lam T k : ℝ) :
    HasSum (fun n : ℕ => Real.exp (-(lam * T)) * (lam * T) ^ n / (n ! : ℝ) * (1 + k) ^ n)
      (Real.exp (lam * k * T)) := by
  have h := NormedSpace.expSeries_div_hasSum_exp (𝔸 := ℝ) (lam * T * (1 + k))
  rw [← Real.exp_eq_exp_ℝ] at h
  have h2 := h.mul_left (Real.exp (-(lam * T)))
  have he : Real.exp (-(lam * T)) * Real.exp (lam * T * (1 + k)) = Real.exp (lam * k * T) := by
    rw [← Real.exp_add]; congr 1; ring
  rw [he] at h2
  convert h2 using 1
  funext n
  simp only [mul_pow]; ring

/-- The branch centre (Step 3): with `k = e^(μ_J + δ²/2) - 1` and `n` jumps, the average
ending price `S e^((r - q - λk)T) e^(n(μ_J + δ²/2))` equals `S e^((r - q - λk)T) (1 + k)^n`,
and that is the forward of a stock with yield `q_n = q + λk - n ln(1 + k) / T`. -/
theorem merton_branch_yield (S r q lam muJ delta T : ℝ) (hT : 0 < T) (n : ℕ) :
    let k := Real.exp (muJ + delta ^ 2 / 2) - 1
    let qn := q + lam * k - (n : ℝ) * Real.log (1 + k) / T
    S * Real.exp ((r - q - lam * k) * T) * Real.exp ((n : ℝ) * (muJ + delta ^ 2 / 2))
        = S * Real.exp ((r - q - lam * k) * T) * (1 + k) ^ n ∧
      S * Real.exp ((r - q - lam * k) * T) * (1 + k) ^ n = S * Real.exp ((r - qn) * T) := by
  intro k qn
  have hk : 1 + k = Real.exp (muJ + delta ^ 2 / 2) := by simp [k]
  refine ⟨?_, ?_⟩
  · rw [hk, Real.exp_nat_mul]
  · rw [hk, ← Real.exp_nat_mul, mul_assoc, ← Real.exp_add]
    congr 2
    simp only [qn, hk, Real.log_exp]
    field_simp
    ring

/-- The branch forwards average to the forward (Steps 1 and 5): weighting each branch's
forward `S e^((r - q_n)T)` by the Poisson chance `w_n` of exactly `n` jumps gives the
forward `F = S e^((r - q)T)`, so the compensator puts the average ending price on `F`. -/
theorem merton_branch_forwards_average (S r q lam muJ delta T : ℝ) (hT : 0 < T) :
    let k := Real.exp (muJ + delta ^ 2 / 2) - 1
    HasSum (fun n : ℕ => Real.exp (-(lam * T)) * (lam * T) ^ n / (n ! : ℝ) *
        (S * Real.exp ((r - (q + lam * k - (n : ℝ) * Real.log (1 + k) / T)) * T)))
      (S * Real.exp ((r - q) * T)) := by
  intro k
  have h1 := (merton_compensator_identity lam T k).mul_left (S * Real.exp ((r - q - lam * k) * T))
  have he : S * Real.exp ((r - q - lam * k) * T) * Real.exp (lam * k * T) = S * Real.exp ((r - q) * T) := by
    rw [mul_assoc, ← Real.exp_add]; congr 2; ring
  rw [he] at h1
  convert h1 using 1
  funext n
  have h2 := (merton_branch_yield S r q lam muJ delta T hT n).2
  rw [← h2]
  ring

/-- One-jump branch width (Step 0): `0.2² + 0.15² = 0.25²`, so `σ_1 = 25%`. -/
example : (1 / 5 : ℚ) ^ 2 + (3 / 20 : ℚ) ^ 2 = (1 / 4 : ℚ) ^ 2 := by norm_num

/-- Two-jump branch variance: `0.04 + 2 × 0.0225 = 0.085`. -/
example : (1 / 5 : ℚ) ^ 2 + 2 * (3 / 20 : ℚ) ^ 2 = 17 / 200 := by norm_num

/-- Each jump's log-average `μ_J + δ²/2 = -0.10 + 0.15²/2 = -0.08875`. -/
example : (-1 / 10 : ℚ) + (3 / 20 : ℚ) ^ 2 / 2 = -71 / 800 := by norm_num

#print axioms merton_compensator_identity
#print axioms merton_branch_yield
#print axioms merton_branch_forwards_average
