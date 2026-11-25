-- De Giorgi-Nash-Moser: De Giorgi's iteration lemma (an excess that controls the next one to a power above 1 collapses to zero once it starts small enough), the oscillation decay that turns a fixed shrink factor per halving into Hölder continuity, and Kellogg's exponent for the checkerboard conductor.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum.RealSqrt

open Filter Topology Real

/-! Mathlib has no Sobolev space `H¹`, no weak solutions of divergence-form equations and no
De Giorgi theory, so the theorem on boundedness and Hölder continuity of weak solutions is not
stated here. This file states exactly the parts of the card that are elementary facts about
real numbers: the iteration lemma of Step 3, the oscillation-to-Hölder step of Step 4, and
the checkerboard exponent of Step 5 (Kellogg's formula). -/

/-- **De Giorgi's iteration lemma** (Step 3). Let `Y₀, Y₁, …` be nonnegative numbers (squared
excesses) with `Y_{j+1} ≤ C bʲ Y_j^{1+ε}`, where `C > 0`, `b > 1` and `ε > 0`. If the start is
small, `Y₀ ≤ C^{-1/ε} b^{-1/ε²}`, then `Y_j ≤ Y₀ b^{-j/ε}` for every `j`, so `Y_j → 0`. -/
theorem de_giorgi_iteration_lemma {C b ε : ℝ} (hC : 0 < C) (hb : 1 < b) (hε : 0 < ε)
    (Y : ℕ → ℝ) (hY : ∀ j, 0 ≤ Y j)
    (hstep : ∀ j : ℕ, Y (j + 1) ≤ C * b ^ j * Y j ^ (1 + ε))
    (hsmall : Y 0 ≤ C ^ (-1 / ε) * b ^ (-1 / ε ^ 2)) :
    (∀ j : ℕ, Y j ≤ Y 0 * b ^ (-(j : ℝ) / ε)) ∧ Tendsto Y atTop (𝓝 0) := by
  have hb0 : 0 < b := by linarith
  have hL0 : 0 ≤ Y 0 := hY 0
  set D : ℝ := b ^ (-1 / ε) with hD
  have hD0 : 0 < D := Real.rpow_pos_of_pos hb0 _
  have hD1 : D < 1 := Real.rpow_lt_one_of_one_lt_of_neg hb (by
    have : 0 < 1 / ε := by positivity
    rw [neg_div]; linarith)
  have hDε : D ^ ε = b⁻¹ := by
    rw [hD, ← Real.rpow_mul hb0.le]
    have e : -1 / ε * ε = -1 := by field_simp
    rw [e, Real.rpow_neg_one]
  have hkey : C * Y 0 ^ ε ≤ D := by
    have h1 : Y 0 ^ ε ≤ (C ^ (-1 / ε) * b ^ (-1 / ε ^ 2)) ^ ε :=
      Real.rpow_le_rpow hL0 hsmall hε.le
    rw [Real.mul_rpow (by positivity) (by positivity), ← Real.rpow_mul hC.le,
      ← Real.rpow_mul hb0.le] at h1
    have e1 : -1 / ε * ε = -1 := by field_simp
    have e2 : -1 / ε ^ 2 * ε = -1 / ε := by field_simp
    rw [e1, e2, Real.rpow_neg_one] at h1
    calc C * Y 0 ^ ε ≤ C * (C⁻¹ * b ^ (-1 / ε)) := by gcongr
      _ = D := by rw [hD]; field_simp
  have hgeom : ∀ j : ℕ, Y j ≤ Y 0 * D ^ j := by
    intro j
    induction j with
    | zero => simp
    | succ j ih =>
      have hDj : 0 < D ^ j := pow_pos hD0 j
      have h1 : Y j ^ (1 + ε) ≤ (Y 0 * D ^ j) ^ (1 + ε) :=
        Real.rpow_le_rpow (hY j) ih (by linarith)
      have h2 : (Y 0 * D ^ j) ^ (1 + ε) = Y 0 * Y 0 ^ ε * (D ^ j * b⁻¹ ^ j) := by
        rw [Real.mul_rpow hL0 hDj.le, Real.rpow_add' hL0 (by linarith), Real.rpow_one,
          Real.rpow_add hDj, Real.rpow_one, ← Real.rpow_pow_comm hD0.le, hDε]
      calc Y (j + 1) ≤ C * b ^ j * Y j ^ (1 + ε) := hstep j
        _ ≤ C * b ^ j * (Y 0 * D ^ j) ^ (1 + ε) := by gcongr
        _ = (C * Y 0 ^ ε) * (Y 0 * D ^ j) * (b ^ j * b⁻¹ ^ j) := by rw [h2]; ring
        _ = (C * Y 0 ^ ε) * (Y 0 * D ^ j) := by
          rw [← mul_pow, mul_inv_cancel₀ hb0.ne', one_pow, mul_one]
        _ ≤ D * (Y 0 * D ^ j) := by gcongr
        _ = Y 0 * D ^ (j + 1) := by ring
  have hconv : ∀ j : ℕ, b ^ (-(j : ℝ) / ε) = D ^ j := by
    intro j
    rw [hD, ← Real.rpow_natCast, ← Real.rpow_mul hb0.le]
    congr 1
    ring
  refine ⟨fun j => by rw [hconv j]; exact hgeom j, ?_⟩
  have hlim : Tendsto (fun j : ℕ => Y 0 * D ^ j) atTop (𝓝 (Y 0 * 0)) :=
    (tendsto_pow_atTop_nhds_zero_of_lt_one hD0.le hD1).const_mul _
  rw [mul_zero] at hlim
  exact squeeze_zero hY hgeom hlim

/-- **The oscillation shrinks by a fixed factor, so the solution is Hölder** (Step 4). If
halving the ball keeps at most the fraction `1 - γ/2` of the oscillation, with `0 < γ < 2`,
then on the ball of radius `2⁻ⁿ r` the oscillation is at most `(2⁻ⁿ)^α` times the first, with
`α = log₂ (1 / (1 - γ/2)) > 0`. Here `osc n` is the oscillation on `B(x₀, 2⁻ⁿ r)`. -/
theorem oscillation_decay_gives_holder {γ : ℝ} (hγ0 : 0 < γ) (hγ2 : γ < 2) (osc : ℕ → ℝ)
    (hhalve : ∀ n : ℕ, osc (n + 1) ≤ (1 - γ / 2) * osc n) :
    0 < Real.logb 2 (1 / (1 - γ / 2)) ∧
      ∀ n : ℕ, osc n ≤ ((1 / 2 : ℝ) ^ n) ^ Real.logb 2 (1 / (1 - γ / 2)) * osc 0 := by
  set q : ℝ := 1 - γ / 2 with hq
  have hq0 : 0 < q := by rw [hq]; linarith
  have hq1 : q < 1 := by rw [hq]; linarith
  have hinv : 1 < 1 / q := by rw [lt_div_iff₀ hq0]; linarith
  refine ⟨Real.logb_pos (by norm_num) hinv, ?_⟩
  have hpow : ∀ n : ℕ, ((1 / 2 : ℝ) ^ n) ^ Real.logb 2 (1 / q) = q ^ n := by
    intro n
    rw [← Real.rpow_pow_comm (by norm_num), one_div (2 : ℝ), Real.inv_rpow (by norm_num),
      Real.rpow_logb (by norm_num) (by norm_num) (by positivity), one_div, inv_inv]
  intro n
  rw [hpow n]
  induction n with
  | zero => simp
  | succ n ih =>
    calc osc (n + 1) ≤ q * osc n := hhalve n
      _ ≤ q * (q ^ n * osc 0) := mul_le_mul_of_nonneg_left ih hq0.le
      _ = q ^ (n + 1) * osc 0 := by ring

/-- **Kellogg's formula for the checkerboard** (Step 5). With conductivity `Λ` on two opposite
quadrants and `λ` on the other two, `0 < λ ≤ Λ`, the piece `r^α cos(α(θ - π/4))` on a good tile
meets `-A r^α sin(α(θ - 3π/4))` on a poor tile at the edge `θ = π/2` with continuous potential,
`cos(απ/4) = A sin(απ/4)`, and continuous current, `Λ α sin(απ/4) = λ A α cos(απ/4)`. The
smallest positive exponent for which some amplitude `A` does this is
`α = (4/π) arctan √(λ/Λ)`, and the amplitude there is `A = √(Λ/λ)`. -/
theorem checkerboard_exponent_kellogg {lam Lam : ℝ} (hlam : 0 < lam) (hle : lam ≤ Lam) :
    IsLeast {α : ℝ | 0 < α ∧ ∃ A : ℝ,
        Real.cos (α * π / 4) = A * Real.sin (α * π / 4) ∧
        Lam * α * Real.sin (α * π / 4) = lam * (A * α * Real.cos (α * π / 4))}
      (4 / π * Real.arctan (Real.sqrt (lam / Lam))) ∧
    ∀ A : ℝ, Real.cos (4 / π * Real.arctan (Real.sqrt (lam / Lam)) * π / 4) =
        A * Real.sin (4 / π * Real.arctan (Real.sqrt (lam / Lam)) * π / 4) →
      A = Real.sqrt (Lam / lam) := by
  have hLam : 0 < Lam := lt_of_lt_of_le hlam hle
  set s : ℝ := Real.sqrt (lam / Lam) with hsdef
  have hs0 : 0 < s := Real.sqrt_pos.2 (div_pos hlam hLam)
  have hs2 : s ^ 2 = lam / Lam := Real.sq_sqrt (div_pos hlam hLam).le
  have hlam' : Lam * s ^ 2 = lam := by rw [hs2]; field_simp
  have ht : 4 / π * Real.arctan s * π / 4 = Real.arctan s := by
    field_simp [Real.pi_ne_zero]
  have hsin : Real.sin (Real.arctan s) = s * Real.cos (Real.arctan s) := by
    rw [Real.sin_arctan, Real.cos_arctan]; ring
  have hcos : 0 < Real.cos (Real.arctan s) := Real.cos_arctan_pos s
  have hAs : Real.sqrt (Lam / lam) * s = 1 := by
    rw [hsdef, ← Real.sqrt_mul (by positivity)]
    rw [show Lam / lam * (lam / Lam) = 1 by field_simp, Real.sqrt_one]
  have hLs : lam * Real.sqrt (Lam / lam) = Lam * s := by
    calc lam * Real.sqrt (Lam / lam) = Lam * s ^ 2 * Real.sqrt (Lam / lam) := by rw [hlam']
      _ = Lam * s * (Real.sqrt (Lam / lam) * s) := by ring
      _ = Lam * s := by rw [hAs, mul_one]
  refine ⟨⟨⟨?_, Real.sqrt (Lam / lam), ?_, ?_⟩, ?_⟩, ?_⟩
  · have : 0 < Real.arctan s := Real.arctan_pos.2 hs0
    have := Real.pi_pos
    positivity
  · rw [ht, hsin, ← mul_assoc, hAs, one_mul]
  · rw [ht, hsin]
    linear_combination (-(4 / π * Real.arctan s) * Real.cos (Real.arctan s)) * hLs
  · rintro α ⟨hα, A, h1, h2⟩
    by_contra hlt
    rw [not_le] at hlt
    set t : ℝ := α * π / 4 with htdef
    have hpi := Real.pi_pos
    have ht0 : 0 < t := by positivity
    have htl : t < Real.arctan s := by
      calc t = α * π / 4 := rfl
        _ < 4 / π * Real.arctan s * π / 4 := by gcongr
        _ = Real.arctan s := ht
    have htp : t < π / 2 := htl.trans (Real.arctan_lt_pi_div_two s)
    have hct : 0 < Real.cos t := Real.cos_pos_of_mem_Ioo ⟨by linarith, htp⟩
    have htan0 : 0 < Real.tan t := Real.tan_pos_of_pos_of_lt_pi_div_two ht0 htp
    have htan1 : Real.tan t < s := by
      have := Real.tan_lt_tan_of_lt_of_lt_pi_div_two (by linarith) (Real.arctan_lt_pi_div_two s) htl
      rwa [Real.tan_arctan] at this
    have h3 : α * (Lam * Real.sin t ^ 2 - lam * Real.cos t ^ 2) = 0 := by
      linear_combination (Real.sin t) * h2 - (lam * α * Real.cos t) * h1
    have h4 : Lam * Real.sin t ^ 2 = lam * Real.cos t ^ 2 := by
      rcases mul_eq_zero.1 h3 with h | h
      · linarith
      · linarith
    have hsin_t : Real.sin t = Real.tan t * Real.cos t := by
      rw [Real.tan_eq_sin_div_cos]; field_simp
    rw [hsin_t] at h4
    have hc2 : 0 < Real.cos t ^ 2 := by positivity
    have h5 : Lam * Real.tan t ^ 2 = lam := by
      have : (Lam * Real.tan t ^ 2 - lam) * Real.cos t ^ 2 = 0 := by linear_combination h4
      rcases mul_eq_zero.1 this with h | h
      · linarith
      · linarith
    have h6 : Real.tan t ^ 2 < s ^ 2 := by nlinarith
    have := mul_lt_mul_of_pos_left h6 hLam
    linarith
  · intro A hA'
    rw [ht, hsin] at hA'
    have hprod : (A * s - 1) * Real.cos (Real.arctan s) = 0 := by linear_combination -hA'
    have hA1 : A * s = 1 := by
      rcases mul_eq_zero.1 hprod with h | h
      · linarith
      · linarith
    calc A = A * (Real.sqrt (Lam / lam) * s) := by rw [hAs, mul_one]
      _ = Real.sqrt (Lam / lam) * (A * s) := by ring
      _ = Real.sqrt (Lam / lam) := by rw [hA1, mul_one]

/-! The card's exact worked numbers. -/

-- Contrast 100: λ/Λ = 1/100, so √(λ/Λ) = 1/10 and the poor-tile amplitude √(Λ/λ) = 10.
example : Real.sqrt ((1 : ℝ) / 100) = 1 / 10 := by norm_num
example : Real.sqrt ((100 : ℝ) / 1) = 10 := by norm_num

-- Iteration with C = b = 4, ε = 1/2: the threshold C^(-1/ε) b^(-1/ε²) = 4⁻² · 4⁻⁴ = 1/4096,
-- and the decay there is b^(1/ε) = 4² = 16 per step.
example : ((4 : ℚ)⁻¹) ^ 2 * ((4 : ℚ)⁻¹) ^ 4 = 1 / 4096 := by norm_num
example : (4 : ℕ) ^ 2 = 16 := by decide

-- At the threshold the decay is exactly geometric: Y₁ = 4 · 4⁰ · Y₀^(3/2) = Y₀/16 and
-- Y₂ = 4 · 4¹ · Y₁^(3/2) = Y₁/16, using √(1/4096) = 1/64 and √(1/65536) = 1/256.
example : Real.sqrt ((1 : ℝ) / 4096) = 1 / 64 := by norm_num
example : Real.sqrt ((1 : ℝ) / 65536) = 1 / 256 := by norm_num
example : (4 : ℚ) * 4 ^ 0 * ((1 / 4096) * (1 / 64)) = (1 / 4096) / 16 := by norm_num
example : (4 : ℚ) * 4 ^ 1 * ((1 / 65536) * (1 / 256)) = (1 / 65536) / 16 := by norm_num

-- A uniform sheet (α = 1) keeps 1/2 of the oscillation per halving; its Harnack ratio
-- (1 + 1/2)/(1 - 1/2) is 3.
example : ((1 : ℚ) + 1 / 2) / (1 - 1 / 2) = 3 := by norm_num

#print axioms de_giorgi_iteration_lemma
#print axioms oscillation_decay_gives_holder
#print axioms checkerboard_exponent_kellogg
