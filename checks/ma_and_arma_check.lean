-- Moving average and ARMA: in an MA(q) model the covariance of sales h months apart is sigma squared times the sum of shared echo-weight products and is exactly zero beyond lag q, an ARMA(1,1) echo shrinks by the factor phi each month, and the twin weights give the same correlogram.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Algebra.BigOperators.Intervals

open MeasureTheory ProbabilityTheory Finset

/-- MA(q) autocovariance and cut-off. Let the surprises `ε t` have average 0, one fixed variance
`σ^2`, and be uncorrelated across months. Let sales be `X t = m + ∑_{j=0}^{q} θ_j ε_{t-j}` with
`θ_0 = 1`. Then for a gap of `h ≤ q` months the covariance of sales `h` months apart is
`σ^2 ∑_{k=0}^{q-h} θ_k θ_{k+h}`, the same in every month, and for every gap `h > q` it is exactly 0. -/
theorem ma_autocovariance_cuts_off_after_q
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : ℤ → Ω → ℝ) (σ m : ℝ) (q : ℕ) (θ : ℕ → ℝ) (X : ℤ → Ω → ℝ)
    (hL2 : ∀ t, MemLp (ε t) 2 P)
    (hmean : ∀ t, P[ε t] = 0)
    (hvar : ∀ t, Var[ε t; P] = σ ^ 2)
    (huncorr : ∀ s t, s ≠ t → cov[ε s, ε t; P] = 0)
    (hθ0 : θ 0 = 1)
    (hX : ∀ t ω, X t ω = m + ∑ j ∈ range (q + 1), θ j * ε (t - j) ω) :
    ∀ (t : ℤ) (h : ℕ),
      (h ≤ q → cov[X t, X (t - h); P] = σ ^ 2 * ∑ k ∈ range (q - h + 1), θ k * θ (k + h)) ∧
      (q < h → cov[X t, X (t - h); P] = 0) := by
  have hc : ∀ a b : ℤ, cov[ε a, ε b; P] = if a = b then σ ^ 2 else 0 := by
    intro a b
    split_ifs with hab
    · subst hab; rw [covariance_self (hL2 a).aemeasurable, hvar]
    · exact huncorr a b hab
  have hY : ∀ s : ℤ, ∀ j ∈ range (q + 1), MemLp (fun ω => θ j * ε (s - j) ω) 2 P :=
    fun s j _ => (hL2 (s - j)).const_mul (θ j)
  have hXeq : ∀ s : ℤ, X s = fun ω => (∑ j ∈ range (q + 1), θ j * ε (s - j) ω) + m := by
    intro s; funext ω; rw [hX, add_comm]
  have hInt : ∀ s : ℤ, Integrable (fun ω => ∑ j ∈ range (q + 1), θ j * ε (s - j) ω) P :=
    fun s => (memLp_finsetSum' _ (hY s)).integrable one_le_two |>.congr
      (Filter.Eventually.of_forall fun ω => by simp)
  have key : ∀ t : ℤ, ∀ h : ℕ, cov[X t, X (t - h); P] =
      ∑ j ∈ range (q + 1), if j + h < q + 1 then σ ^ 2 * (θ j * θ (j + h)) else 0 := by
    intro t h
    rw [hXeq, hXeq, covariance_add_const_left (hInt _), covariance_add_const_right (hInt _),
      covariance_fun_sum_fun_sum' (hY _) (hY _)]
    simp_rw [covariance_const_mul_left, covariance_const_mul_right, hc]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun j _ => ?_
    have : ∀ i : ℕ, (t - (i : ℤ) = t - (h : ℤ) - (j : ℤ)) ↔ (j + h = i) := by
      intro i; constructor <;> intro H <;> omega
    simp_rw [this]
    simp only [mul_ite, mul_zero]
    rw [Finset.sum_ite_eq]
    simp only [Finset.mem_range]
    split_ifs <;> ring
  intro t h
  rw [key, ← Finset.sum_filter]
  constructor
  · intro hh
    have : (range (q + 1)).filter (fun j => j + h < q + 1) = range (q - h + 1) := by
      ext j; simp; omega
    rw [this, Finset.mul_sum]
  · intro hh
    have : (range (q + 1)).filter (fun j => j + h < q + 1) = ∅ := by
      ext j; simp; omega
    rw [this, Finset.sum_empty]

/-- ARMA(1,1) echo of one surprise. Follow a single unit surprise through
`X_t = φ X_{t-1} + ε_t + θ₁ ε_{t-1}`: its weight is 1 in month 0, `φ + θ₁` in month 1, and after
that each month carries the share `φ` of the month before. Then its weight `j ≥ 1` months on is
`ψ_j = φ^(j-1) (φ + θ₁)`: the echo shrinks by the factor `φ` each month instead of stopping. -/
theorem arma11_echo_weights (φ θ₁ : ℝ) (ψ : ℕ → ℝ)
    (h0 : ψ 0 = 1) (h1 : ψ 1 = φ * ψ 0 + θ₁) (hrec : ∀ j, ψ (j + 2) = φ * ψ (j + 1)) :
    ∀ j, 1 ≤ j → ψ j = φ ^ (j - 1) * (φ + θ₁) := by
  intro j hj
  induction j with
  | zero => omega
  | succ n ih =>
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp [h1, h0]
    · obtain ⟨k, rfl⟩ : ∃ k, n = k + 1 := ⟨n - 1, by omega⟩
      rw [hrec, ih (by omega)]
      simp [pow_succ]; ring

/-- Two models, one correlogram. The MA(2) with echo weights `1, θ₁, θ₂` and surprise standard
deviation `σ`, and its twin with weights `1, θ₁/θ₂, 1/θ₂` and standard deviation `σ θ₂`, have the
same autocovariance at lags 0, 1 and 2 (by the Step 2 formula), so no record can tell them apart. -/
theorem ma2_twin_same_autocovariance (σ θ₁ θ₂ : ℝ) (hθ₂ : θ₂ ≠ 0) :
    (σ * θ₂) ^ 2 * (1 + (θ₁ / θ₂) ^ 2 + (1 / θ₂) ^ 2) = σ ^ 2 * (1 + θ₁ ^ 2 + θ₂ ^ 2) ∧
    (σ * θ₂) ^ 2 * (θ₁ / θ₂ + θ₁ / θ₂ * (1 / θ₂)) = σ ^ 2 * (θ₁ + θ₁ * θ₂) ∧
    (σ * θ₂) ^ 2 * (1 / θ₂) = σ ^ 2 * θ₂ := by
  refine ⟨?_, ?_, ?_⟩ <;> field_simp <;> ring

/-- The shop's echo weights 1, 0.6, 0.3 written as exact fractions. -/
def shopθ : ℕ → ℚ := fun j => if j = 0 then 1 else if j = 1 then 3 / 5 else if j = 2 then 3 / 10 else 0

-- The shop (σ = 40, q = 2): γ(0) = 2320, γ(1) = 1248, γ(2) = 480, from the formula in the main theorem.
example : (40 : ℚ) ^ 2 * ∑ k ∈ range (2 - 0 + 1), shopθ k * shopθ (k + 0) = 2320 := by
  norm_num [shopθ, Finset.sum_range_succ]
example : (40 : ℚ) ^ 2 * ∑ k ∈ range (2 - 1 + 1), shopθ k * shopθ (k + 1) = 1248 := by
  norm_num [shopθ, Finset.sum_range_succ]
example : (40 : ℚ) ^ 2 * ∑ k ∈ range (2 - 2 + 1), shopθ k * shopθ (k + 2) = 480 := by
  norm_num [shopθ, Finset.sum_range_succ]
-- ρ(1) = 1248/2320 and ρ(2) = 480/2320 in lowest terms.
example : (1248 : ℚ) / 2320 = 78 / 145 ∧ (480 : ℚ) / 2320 = 6 / 29 := by norm_num
-- The twin: weights 1, 2, 10/3 with surprise sd 12 give 2320, 1248, 480 again.
example : (12 : ℚ) ^ 2 * (1 + 2 ^ 2 + (10 / 3) ^ 2) = 2320 ∧
    (12 : ℚ) ^ 2 * (2 + 2 * (10 / 3)) = 1248 ∧ (12 : ℚ) ^ 2 * (10 / 3) = 480 := by norm_num
-- The ARMA(1,1) shop (φ = 1/2, θ₁ = 3/10): a +100 surprise echoes 80, 40, 20, 10, 5.
example : [1, 2, 3, 4, 5].map (fun j : ℕ => (100 : ℚ) * (1 / 2) ^ (j - 1) * (1 / 2 + 3 / 10)) =
    [80, 40, 20, 10, 5] := by
  norm_num
-- Its variance 1600 (1 + 2 φ θ₁ + θ₁²)/(1 − φ²) = 8896/3 and ρ(1) = (1 + φθ₁)(φ + θ₁)/(1 + 2φθ₁ + θ₁²) = 92/139.
example : (1600 : ℚ) * (1 + 2 * (1 / 2) * (3 / 10) + (3 / 10) ^ 2) / (1 - (1 / 2) ^ 2) = 8896 / 3 ∧
    (1 + 1 / 2 * (3 / 10) : ℚ) * (1 / 2 + 3 / 10) / (1 + 2 * (1 / 2) * (3 / 10) + (3 / 10) ^ 2) = 92 / 139 := by
  norm_num

#print axioms ma_autocovariance_cuts_off_after_q
#print axioms arma11_echo_weights
#print axioms ma2_twin_same_autocovariance
