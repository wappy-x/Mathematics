-- AIC and BIC: for a die's counts, the free model's best fit is the observed shares, each criterion's difference is its price minus the gain G, BIC's price per parameter beats AIC's exactly from n = 8 on, and any real load eventually wins under BIC.
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.ExponentialBounds
import Mathlib.Algebra.BigOperators.Field

open Finset Filter

/-- The log-likelihood of a die's counts `c j` (face `j` came up `c j` times) under chances
`θ j`: `ℓ(θ) = ∑ⱼ cⱼ ln θⱼ`. -/
noncomputable def logLik (c : Fin 6 → ℕ) (θ : Fin 6 → ℝ) : ℝ :=
  ∑ j, (c j : ℝ) * Real.log (θ j)

/-- The number of rolls `n = c₁ + ⋯ + c₆`. -/
def rolls (c : Fin 6 → ℕ) : ℕ := ∑ j, c j

/-- The free model's fitted chances: the observed shares `cⱼ / n`. -/
noncomputable def freeFit (c : Fin 6 → ℕ) : Fin 6 → ℝ := fun j => (c j : ℝ) / rolls c

/-- The fair model's chances: `1/6` for every face, nothing to fit. -/
noncomputable def fair : Fin 6 → ℝ := fun _ => 1 / 6

/-- The free model's gain in fit, cell by cell: `G = 2 ∑ⱼ cⱼ ln(cⱼ / (n/6))`. -/
noncomputable def gain (c : Fin 6 → ℕ) : ℝ :=
  2 * ∑ j, (c j : ℝ) * Real.log ((c j : ℝ) / ((rolls c : ℝ) / 6))

/-- Akaike's score: `AIC = -2ℓ̂ + 2k`. -/
noncomputable def aic (ℓ : ℝ) (k : ℕ) : ℝ := -2 * ℓ + 2 * k

/-- Schwarz's score: `BIC = -2ℓ̂ + k ln n`. -/
noncomputable def bic (ℓ : ℝ) (k n : ℕ) : ℝ := -2 * ℓ + k * Real.log n


/-- Helper: the gain is twice the log-likelihood gap, for any counts. -/
theorem aicbic_gain_eq (c : Fin 6 → ℕ) :
    gain c = 2 * (logLik c (freeFit c) - logLik c fair) := by
  unfold gain logLik freeFit fair
  rw [← Finset.sum_sub_distrib]
  congr 1
  refine Finset.sum_congr rfl (fun j _ => ?_)
  by_cases hj : c j = 0
  · simp [hj]
  · have hcj : (0 : ℝ) < c j := by exact_mod_cast Nat.pos_of_ne_zero hj
    have hn : (0 : ℝ) < rolls c := by
      have : c j ≤ rolls c := by
        unfold rolls
        exact Finset.single_le_sum (fun i _ => Nat.zero_le (c i)) (Finset.mem_univ j)
      exact_mod_cast lt_of_lt_of_le (Nat.pos_of_ne_zero hj) this
    rw [← mul_sub, ← Real.log_div (by positivity) (by norm_num)]
    congr 2
    field_simp

/-- Helper: the rolls of scaled counts. -/
theorem aicbic_rolls_scale (c : Fin 6 → ℕ) (t : ℕ) :
    ((rolls fun j => t * c j : ℕ) : ℝ) = t * rolls c := by
  unfold rolls
  rw [← Finset.mul_sum]
  push_cast
  ring

/-- **The die's two scores: price minus gain.** Take a die's counts `c₁, …, c₆`, all positive
(the fitted chances lie inside their range), from `n` rolls. Among all chances `θ` inside
their range that add to 1, the free model's best log-likelihood is reached at the observed
shares `cⱼ / n`. Its gain over the fair model, `G = 2(ℓ̂_free - ℓ̂_fair)`, equals the cell-by-cell
sum `2 ∑ⱼ cⱼ ln(cⱼ/(n/6))` and is never negative: the free model always fits at least as well.
Scoring both models on the same rolls, with 5 free parameters against 0,
`ΔAIC = AIC_free - AIC_fair = 2·5 - G` and `ΔBIC = BIC_free - BIC_fair = 5 ln n - G`. -/
theorem aic_bic_difference_eq_price_minus_gain (c : Fin 6 → ℕ) (hc : ∀ j, 0 < c j) :
    IsGreatest {ℓ | ∃ θ : Fin 6 → ℝ, (∀ j, 0 < θ j) ∧ ∑ j, θ j = 1 ∧ ℓ = logLik c θ}
        (logLik c (freeFit c)) ∧
      gain c = 2 * (logLik c (freeFit c) - logLik c fair) ∧
      0 ≤ gain c ∧
      aic (logLik c (freeFit c)) 5 - aic (logLik c fair) 0 = 2 * 5 - gain c ∧
      bic (logLik c (freeFit c)) 5 (rolls c) - bic (logLik c fair) 0 (rolls c)
        = 5 * Real.log (rolls c) - gain c := by
  have hn : (0 : ℝ) < rolls c := by
    have : 0 < rolls c := by
      unfold rolls
      exact Finset.sum_pos (fun j _ => hc j) Finset.univ_nonempty
    exact_mod_cast this
  have hmax : IsGreatest {ℓ | ∃ θ : Fin 6 → ℝ, (∀ j, 0 < θ j) ∧ ∑ j, θ j = 1 ∧ ℓ = logLik c θ}
      (logLik c (freeFit c)) := by
    constructor
    · refine ⟨freeFit c, fun j => ?_, ?_, rfl⟩
      · unfold freeFit
        have : (0 : ℝ) < c j := by exact_mod_cast hc j
        positivity
      · unfold freeFit
        rw [← Finset.sum_div]
        have : ((∑ j, (c j : ℝ))) = rolls c := by unfold rolls; push_cast; rfl
        rw [this, div_self hn.ne']
    · rintro ℓ ⟨θ, hθ, hs, rfl⟩
      rw [← sub_nonpos]
      unfold logLik
      rw [← Finset.sum_sub_distrib]
      calc ∑ j, ((c j : ℝ) * Real.log (θ j) - (c j : ℝ) * Real.log (freeFit c j))
          ≤ ∑ j, ((rolls c : ℝ) * θ j - c j) := by
            refine Finset.sum_le_sum (fun j _ => ?_)
            have ha : (0 : ℝ) < c j := by exact_mod_cast hc j
            have hp : 0 < freeFit c j := by unfold freeFit; positivity
            have h := Real.log_le_sub_one_of_pos (div_pos (hθ j) hp)
            rw [Real.log_div (hθ j).ne' hp.ne'] at h
            have h2 := mul_le_mul_of_nonneg_left h ha.le
            have h3 : (c j : ℝ) * (θ j / freeFit c j - 1) = (rolls c : ℝ) * θ j - c j := by
              unfold freeFit
              field_simp
            rw [mul_sub, h3] at h2
            exact h2
        _ = 0 := by
            rw [Finset.sum_sub_distrib, ← Finset.mul_sum, hs]
            have : ((∑ j, (c j : ℝ))) = rolls c := by unfold rolls; push_cast; rfl
            rw [this, mul_one, sub_self]
  have hg := aicbic_gain_eq c
  have hfair : logLik c fair ≤ logLik c (freeFit c) :=
    hmax.2 ⟨fair, fun _ => by unfold fair; norm_num, by simp [fair], rfl⟩
  refine ⟨hmax, hg, by rw [hg]; linarith, ?_, ?_⟩
  · unfold aic; rw [hg]; push_cast; ring
  · unfold bic; rw [hg]; push_cast; ring

/-- **BIC charges more than AIC exactly from n = 8 on.** Per parameter, BIC's price `ln n`
exceeds AIC's price 2 exactly when the sample size `n` is at least 8, since `ln n` passes 2
at `n = e² ≈ 7.389`. -/
theorem bic_price_gt_aic_price_iff (n : ℕ) : (2 : ℝ) < Real.log n ↔ 8 ≤ n := by
  have he2 : Real.exp 2 = Real.exp 1 ^ 2 := by rw [← Real.exp_nat_mul]; norm_num
  have hlo : (7 : ℝ) < Real.exp 2 := by
    rw [he2]; nlinarith [Real.exp_one_gt_d9]
  have hhi : Real.exp 2 < 8 := by
    rw [he2]; nlinarith [Real.exp_one_lt_d9, Real.exp_pos 1]
  constructor
  · intro h
    by_contra hn
    push Not at hn
    rcases Nat.eq_zero_or_pos n with h0 | hpos
    · subst h0; simp at h; linarith
    · have hnr : (0 : ℝ) < n := by exact_mod_cast hpos
      rw [Real.lt_log_iff_exp_lt hnr] at h
      have : (n : ℝ) ≤ 7 := by exact_mod_cast Nat.lt_succ_iff.mp hn
      linarith
  · intro h
    have hnr : (8 : ℝ) ≤ n := by exact_mod_cast h
    rw [Real.lt_log_iff_exp_lt (by linarith)]
    linarith

/-- **Same shares, more rolls: the gain grows in step with n, and BIC always gets there.**
Multiplying every count by `t` multiplies the gain by `t`. So if the counts show any real load
(`G > 0`), then for all large enough `t` the free model's BIC on the counts `t·cⱼ` is below the
fair model's: the gain eventually beats BIC's price `5 ln(t n)`, which grows only as a log. -/
theorem gain_scales_and_bic_eventually_picks_free (c : Fin 6 → ℕ) (hG : 0 < gain c) :
    (∀ t : ℕ, gain (fun j => t * c j) = t * gain c) ∧
      ∀ᶠ t : ℕ in atTop,
        bic (logLik (fun j => t * c j) (freeFit fun j => t * c j)) 5 (rolls fun j => t * c j)
          < bic (logLik (fun j => t * c j) fair) 0 (rolls fun j => t * c j) := by
  have hscale : ∀ t : ℕ, gain (fun j => t * c j) = t * gain c := by
    intro t
    unfold gain
    rw [aicbic_rolls_scale]
    rw [Finset.mul_sum, Finset.mul_sum, Finset.mul_sum]
    refine Finset.sum_congr rfl (fun j _ => ?_)
    rcases Nat.eq_zero_or_pos t with h0 | ht
    · subst h0; simp
    · have htr : (t : ℝ) ≠ 0 := by exact_mod_cast ht.ne'
      push_cast
      have : (t : ℝ) * c j / (t * rolls c / 6) = c j / (rolls c / 6) := by
        field_simp
      rw [this]; ring
  refine ⟨hscale, ?_⟩
  set G := gain c with hGdef
  have hn : (0 : ℝ) < rolls c := by
    rcases Nat.eq_zero_or_pos (rolls c) with h0 | hpos
    · exfalso
      have hz : ∀ j, c j = 0 := by
        intro j
        have : c j ≤ rolls c := by
          unfold rolls
          exact Finset.single_le_sum (fun i _ => Nat.zero_le (c i)) (Finset.mem_univ j)
        omega
      have : gain c = 0 := by unfold gain; simp [hz]
      linarith
    · exact_mod_cast hpos
  set n : ℝ := (rolls c : ℝ) with hndef
  have hε : 0 < G / (10 * n) := by positivity
  have hlog := (Real.isLittleO_log_id_atTop.bound hε)
  have htend : Tendsto (fun t : ℕ => (t : ℝ) * n) atTop atTop :=
    Tendsto.atTop_mul_const hn tendsto_natCast_atTop_atTop
  filter_upwards [htend.eventually hlog, eventually_ge_atTop 1] with t ht ht1
  have htr : (1 : ℝ) ≤ t := by exact_mod_cast ht1
  have hg := aicbic_gain_eq (fun j => t * c j)
  rw [hscale t] at hg
  unfold bic
  rw [aicbic_rolls_scale]
  simp only [id, Real.norm_eq_abs] at ht
  have hpos : (0 : ℝ) < t * n := by positivity
  rw [abs_of_pos hpos] at ht
  have hl := le_trans (le_abs_self _) ht
  have key : 5 * Real.log (t * n) ≤ t * G / 2 := by
    have : G / (10 * n) * (t * n) = t * G / 10 := by field_simp
    nlinarith
  push_cast
  nlinarith

/-- The card's die: counts 88, 97, 100, 104, 99, 112. -/
def dieCounts : Fin 6 → ℕ := ![88, 97, 100, 104, 99, 112]

-- 600 rolls in all.
example : rolls dieCounts = 600 := by decide

-- Pearson's X² numerator: (−12)² + (−3)² + 0² + 4² + (−1)² + 12² = 314, so X² = 314/100 = 3.14.
example : ∑ j, ((dieCounts j : ℤ) - 100) ^ 2 = 314 := by decide

-- Four and ten times the rolls, same shares: 2,400 and 6,000 rolls.
example : rolls (fun j => 4 * dieCounts j) = 2400 := by decide
example : rolls (fun j => 10 * dieCounts j) = 6000 := by decide

-- The heavier six, 85, 90, 95, 100, 100, 130, is still 600 rolls.
example : rolls ![85, 90, 95, 100, 100, 130] = 600 := by decide

-- AIC's price for 5 parameters is 2 × 5 = 10; counting six chances wrongly gives 12.
example : 2 * 5 = 10 ∧ 2 * 6 = 12 := by norm_num

-- AICc's extra penalty 2k(k+1)/(n−k−1) for k = 5, n = 600 is 60/594 = 10/99 (0.1010).
example : (2 * 5 * (5 + 1) : ℚ) / (600 - 5 - 1) = 10 / 99 := by norm_num

-- The uniform prior's height on the five free chances is 5! = 120.
example : Nat.factorial 5 = 120 := by decide

#print axioms aicbic_gain_eq
#print axioms aicbic_rolls_scale
#print axioms aic_bic_difference_eq_price_minus_gain
#print axioms bic_price_gt_aic_price_iff
#print axioms gain_scales_and_bic_eventually_picks_free
