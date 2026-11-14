-- A moving hedge ratio: each Kalman update is the exact precision-weighted combination of yesterday's belief and today's price reading, the filter's estimate is the last coefficient of the whole-path penalised regression, and with Q equal to the reading variance the weights are Fibonacci ratios that settle at (√5 - 1)/2.
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.SpecificLimits.Basic

open Filter Topology Finset

namespace KalmanHedge

/-- One day of the filter. Yesterday's estimate `m` and variance `P`, today's prices `A` and `B`,
step variance `Q` and price-noise variance `R`. With the prediction variance `p = P + Q`,
`S = B² p + R`, gain `K = p B / S` and surprise `e = A - m B`, the new estimate is `m + K e`
and the new variance is `p R / S`. -/
noncomputable def kalmanStep (Q R m P A B : ℝ) : ℝ × ℝ :=
  let p := P + Q
  let S := B ^ 2 * p + R
  (m + p * B / S * (A - m * B), p * R / S)

/-- The filter run from the starting belief `(m₀, P₀)`; day `t + 1` uses the prices `A (t+1)`
and `B (t+1)`. The first coordinate is the estimate `m_t`, the second its variance `P_t`. -/
noncomputable def kalmanFilter (m₀ P₀ Q R : ℝ) (A B : ℕ → ℝ) : ℕ → ℝ × ℝ
  | 0 => (m₀, P₀)
  | t + 1 => kalmanStep Q R (kalmanFilter m₀ P₀ Q R A B t).1 (kalmanFilter m₀ P₀ Q R A B t).2
      (A (t + 1)) (B (t + 1))

/-- The weight on today's reading, `K B = (P + Q) B² / (B² (P + Q) + R)`. -/
noncomputable def kalmanWeight (Q R P B : ℝ) : ℝ :=
  (P + Q) * B ^ 2 / (B ^ 2 * (P + Q) + R)

/-- The whole-path penalised regression of Step 4, over the ratios `β 0, …, β t`:
`(β₀ - m₀)²/P₀ + Σ_{j=1}^{t} (β_j - β_{j-1})²/Q + Σ_{j=1}^{t} (A_j - β_j B_j)²/R`. -/
noncomputable def pathCost (m₀ P₀ Q R : ℝ) (A B : ℕ → ℝ) (t : ℕ) (β : ℕ → ℝ) : ℝ :=
  (β 0 - m₀) ^ 2 / P₀ +
    ∑ j ∈ range t, ((β (j + 1) - β j) ^ 2 / Q + (A (j + 1) - β (j + 1) * B (j + 1)) ^ 2 / R)

/-- **One day's update is the exact posterior (Step 3 and the detailed proof).** Take
yesterday's estimate `m` and variance `P`, step variance `Q` and price-noise variance `R > 0`,
with prediction variance `p = P + Q > 0`, and today's prices `A`, `B`. Let `(m', P')` be the
filter's update and `S = B² p + R`. Then:
precisions add, `1/P' = 1/p + B²/R`;
the exponent of prior times likelihood is a single bell curve centred at `m'` with variance `P'`,
`(b - m)²/p + (A - B b)²/R = (b - m')²/P' + (A - m B)²/S` for every candidate ratio `b`;
when `B ≠ 0`, the new estimate is the weighted average of yesterday's estimate and today's
reading `A/B`, with weight `w = p B²/S` on the reading;
when `B = 0`, the reading gets zero weight: the estimate and variance after the update are
`m` and `p`. -/
theorem kalman_update_is_precision_weighted_posterior (Q R m P A B : ℝ)
    (hp : 0 < P + Q) (hR : 0 < R) :
    1 / (kalmanStep Q R m P A B).2 = 1 / (P + Q) + B ^ 2 / R ∧
    (∀ b : ℝ, (b - m) ^ 2 / (P + Q) + (A - B * b) ^ 2 / R
        = (b - (kalmanStep Q R m P A B).1) ^ 2 / (kalmanStep Q R m P A B).2
          + (A - m * B) ^ 2 / (B ^ 2 * (P + Q) + R)) ∧
    (B ≠ 0 → (kalmanStep Q R m P A B).1
        = (1 - kalmanWeight Q R P B) * m + kalmanWeight Q R P B * (A / B)) ∧
    (B = 0 → kalmanStep Q R m P A B = (m, P + Q)) := by
  have hS : 0 < B ^ 2 * (P + Q) + R :=
    add_pos_of_nonneg_of_pos (mul_nonneg (sq_nonneg B) hp.le) hR
  have hp' := hp.ne'
  have hS' := hS.ne'
  have hR' := hR.ne'
  simp only [kalmanStep, kalmanWeight]
  refine ⟨?_, ?_, ?_, ?_⟩
  · field_simp
    ring
  · intro b
    field_simp
    ring
  · intro hB
    field_simp
    ring
  · intro hB
    subst hB
    simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, zero_mul, zero_add,
      mul_zero, zero_div, sub_zero, add_zero, Prod.mk.injEq, true_and]
    field_simp

lemma pathCost_succ (m₀ P₀ Q R : ℝ) (A B : ℕ → ℝ) (t : ℕ) (β : ℕ → ℝ) :
    pathCost m₀ P₀ Q R A B (t + 1) β = pathCost m₀ P₀ Q R A B t β +
      ((β (t + 1) - β t) ^ 2 / Q + (A (t + 1) - β (t + 1) * B (t + 1)) ^ 2 / R) := by
  simp only [pathCost, Finset.sum_range_succ]
  ring

lemma pathCost_congr (m₀ P₀ Q R : ℝ) (A B : ℕ → ℝ) (t : ℕ) (β γ : ℕ → ℝ)
    (h : ∀ j ≤ t, β j = γ j) :
    pathCost m₀ P₀ Q R A B t β = pathCost m₀ P₀ Q R A B t γ := by
  unfold pathCost
  rw [h 0 (Nat.zero_le _)]
  congr 1
  refine Finset.sum_congr rfl fun j hj => ?_
  have hj := Finset.mem_range.mp hj
  rw [h j (by omega), h (j + 1) (by omega)]

lemma kalman_dp (m₀ P₀ Q R : ℝ) (A B : ℕ → ℝ) (hP₀ : 0 < P₀) (hQ : 0 < Q) (hR : 0 < R) :
    ∀ t : ℕ, 0 < (kalmanFilter m₀ P₀ Q R A B t).2 ∧ ∃ c : ℝ,
      (∀ β : ℕ → ℝ, (β t - (kalmanFilter m₀ P₀ Q R A B t).1) ^ 2
          / (kalmanFilter m₀ P₀ Q R A B t).2 + c ≤ pathCost m₀ P₀ Q R A B t β) ∧
      ∀ x : ℝ, ∃ β : ℕ → ℝ, β t = x ∧ pathCost m₀ P₀ Q R A B t β
          = (x - (kalmanFilter m₀ P₀ Q R A B t).1) ^ 2 / (kalmanFilter m₀ P₀ Q R A B t).2 + c := by
  intro t
  induction t with
  | zero =>
    refine ⟨by simpa [kalmanFilter] using hP₀, 0, ?_, ?_⟩
    · intro β
      simp [pathCost, kalmanFilter]
    · intro x
      exact ⟨fun _ => x, rfl, by simp [pathCost, kalmanFilter]⟩
  | succ t ih =>
    obtain ⟨hP, c, hlow, hatt⟩ := ih
    have hstep : kalmanFilter m₀ P₀ Q R A B (t + 1) = kalmanStep Q R (kalmanFilter m₀ P₀ Q R A B t).1
        (kalmanFilter m₀ P₀ Q R A B t).2 (A (t + 1)) (B (t + 1)) := rfl
    rw [hstep]
    set m := (kalmanFilter m₀ P₀ Q R A B t).1 with hm
    set P := (kalmanFilter m₀ P₀ Q R A B t).2 with hPdef
    have hpq : 0 < P + Q := by linarith
    obtain ⟨_, hsq, _, _⟩ :=
      kalman_update_is_precision_weighted_posterior Q R m P (A (t + 1)) (B (t + 1)) hpq hR
    have hP' := hP.ne'
    have hQ' := hQ.ne'
    have hpq' := hpq.ne'
    have key : ∀ y x : ℝ, (y - m) ^ 2 / P + (x - y) ^ 2 / Q
        = (x - m) ^ 2 / (P + Q) + (P + Q) / (P * Q) * (y - (Q * m + P * x) / (P + Q)) ^ 2 := by
      intro y x
      field_simp
      ring
    have hS : 0 < B (t + 1) ^ 2 * (P + Q) + R :=
      add_pos_of_nonneg_of_pos (mul_nonneg (sq_nonneg _) hpq.le) hR
    refine ⟨?_, c + (A (t + 1) - m * B (t + 1)) ^ 2 / (B (t + 1) ^ 2 * (P + Q) + R), ?_, ?_⟩
    · simp only [kalmanStep]
      exact div_pos (mul_pos hpq hR) hS
    · intro β
      rw [pathCost_succ]
      have h1 := hlow β
      have h2 := key (β t) (β (t + 1))
      have h3 := hsq (β (t + 1))
      rw [mul_comm (B (t + 1)) (β (t + 1))] at h3
      have hnn : 0 ≤ (P + Q) / (P * Q) * (β t - (Q * m + P * β (t + 1)) / (P + Q)) ^ 2 :=
        mul_nonneg (div_nonneg hpq.le (mul_pos hP hQ).le) (sq_nonneg _)
      linarith
    · intro x
      obtain ⟨β', hβ't, hβ'c⟩ := hatt ((Q * m + P * x) / (P + Q))
      refine ⟨fun j => if j ≤ t then β' j else x, by simp, ?_⟩
      rw [pathCost_succ, pathCost_congr m₀ P₀ Q R A B t _ β' (fun j hj => by simp [hj]), hβ'c]
      simp only [show ¬ (t + 1 ≤ t) by omega, le_refl, ↓reduceIte, hβ't]
      have h2 := key ((Q * m + P * x) / (P + Q)) x
      simp only [sub_self, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero,
        add_zero] at h2
      have h3 := hsq x
      rw [mul_comm (B (t + 1)) x] at h3
      linarith

#print axioms pathCost_succ
#print axioms pathCost_congr
#print axioms kalman_dp

/-- **The filter is a regression (Step 4).** With a starting variance `P₀ > 0`, a step
variance `Q > 0` and a price-noise variance `R > 0`, and any prices `A`, `B`: on every day `t`
the whole-path penalised regression over `β 0, …, β t` has a minimiser, and every minimiser's
last unknown `β t` is exactly the filter's estimate `m_t`. -/
theorem kalman_estimate_is_whole_path_regression (m₀ P₀ Q R : ℝ) (A B : ℕ → ℝ)
    (hP₀ : 0 < P₀) (hQ : 0 < Q) (hR : 0 < R) (t : ℕ) :
    (∃ β : ℕ → ℝ, ∀ γ : ℕ → ℝ, pathCost m₀ P₀ Q R A B t β ≤ pathCost m₀ P₀ Q R A B t γ) ∧
    ∀ β : ℕ → ℝ, (∀ γ : ℕ → ℝ, pathCost m₀ P₀ Q R A B t β ≤ pathCost m₀ P₀ Q R A B t γ) →
      β t = (kalmanFilter m₀ P₀ Q R A B t).1 := by
  obtain ⟨hP, c, hlow, hatt⟩ := kalman_dp m₀ P₀ Q R A B hP₀ hQ hR t
  set m := (kalmanFilter m₀ P₀ Q R A B t).1 with hm
  set P := (kalmanFilter m₀ P₀ Q R A B t).2 with hPdef
  obtain ⟨β₀, _, hβ₀c⟩ := hatt m
  simp only [sub_self, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, zero_div,
    zero_add] at hβ₀c
  refine ⟨⟨β₀, fun γ => ?_⟩, fun β hβ => ?_⟩
  · rw [hβ₀c]
    have h1 := hlow γ
    have h2 : 0 ≤ (γ t - m) ^ 2 / P := div_nonneg (sq_nonneg _) hP.le
    linarith
  · have h1 := hβ β₀
    have h2 := hlow β
    rw [hβ₀c] at h1
    have h3 : 0 ≤ (β t - m) ^ 2 / P := div_nonneg (sq_nonneg _) hP.le
    have h4 : (β t - m) ^ 2 / P = 0 := by linarith
    have h5 : (β t - m) ^ 2 = 0 := by
      rcases div_eq_zero_iff.mp h4 with h | h
      · exact h
      · exact absurd h hP.ne'
    have h6 : β t - m = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h5
    linarith

lemma fib_ratio_succ (d : ℕ) :
    (Nat.fib (2 * (d + 1) + 1) : ℝ) / Nat.fib (2 * (d + 1) + 2)
      = ((Nat.fib (2 * d + 1) : ℝ) / Nat.fib (2 * d + 2) + 1)
        / ((Nat.fib (2 * d + 1) : ℝ) / Nat.fib (2 * d + 2) + 2) := by
  have e1 : Nat.fib (2 * (d + 1) + 1) = Nat.fib (2 * d + 1) + Nat.fib (2 * d + 2) := by
    rw [show 2 * (d + 1) + 1 = (2 * d + 1) + 2 by ring, Nat.fib_add_two]
  have e2 : Nat.fib (2 * (d + 1) + 2) = Nat.fib (2 * d + 2) + Nat.fib (2 * (d + 1) + 1) := by
    rw [show 2 * (d + 1) + 2 = (2 * d + 2) + 2 by ring, Nat.fib_add_two,
      show 2 * d + 2 + 1 = 2 * (d + 1) + 1 by ring]
  have hb : (0 : ℝ) < Nat.fib (2 * d + 2) := by
    exact_mod_cast Nat.fib_pos.mpr (by omega)
  have ha : (0 : ℝ) ≤ Nat.fib (2 * d + 1) := Nat.cast_nonneg _
  rw [e2, e1]
  push_cast
  have hb' := hb.ne'
  have h1 : (Nat.fib (2 * d + 1) : ℝ) / Nat.fib (2 * d + 2) + 2 ≠ 0 := by positivity
  field_simp
  ring

lemma fib_ratio_nonneg (d : ℕ) : (0 : ℝ) ≤ (Nat.fib (2 * d + 1) : ℝ) / Nat.fib (2 * d + 2) := by
  positivity

lemma fib_ratio_tendsto :
    Tendsto (fun d : ℕ => (Nat.fib (2 * d + 1) : ℝ) / Nat.fib (2 * d + 2)) atTop
      (𝓝 ((Real.sqrt 5 - 1) / 2)) := by
  set k := (Real.sqrt 5 - 1) / 2 with hk
  have h5 := Real.sq_sqrt (show (0 : ℝ) ≤ 5 by norm_num)
  have hs : 2 < Real.sqrt 5 := by
    rw [show (2 : ℝ) = Real.sqrt (2 ^ 2) by rw [Real.sqrt_sq (by norm_num)]]
    exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
  have hkq : k ^ 2 + k - 1 = 0 := by rw [hk]; nlinarith
  have hkpos : 0 < k := by rw [hk]; linarith
  set r := fun d : ℕ => (Nat.fib (2 * d + 1) : ℝ) / Nat.fib (2 * d + 2) with hr
  have bound : ∀ d : ℕ, |r d - k| ≤ |r 0 - k| * (1 / 4 : ℝ) ^ d := by
    intro d
    induction d with
    | zero => simp
    | succ d ih =>
      have hrs : r (d + 1) = (r d + 1) / (r d + 2) := fib_ratio_succ d
      have hx : 0 ≤ r d := fib_ratio_nonneg d
      have hx2 : r d + 2 ≠ 0 := by positivity
      have hk2 : k + 2 ≠ 0 := by positivity
      have e : r (d + 1) - k = (r d - k) / ((r d + 2) * (k + 2)) := by
        rw [hrs]
        field_simp
        linear_combination (-(r d + 2)) * hkq
      have hpos : 0 < (r d + 2) * (k + 2) := by positivity
      have h4 : 4 ≤ (r d + 2) * (k + 2) := by nlinarith
      rw [e, abs_div, abs_of_pos hpos, div_le_iff₀ hpos, pow_succ]
      have hM : 0 ≤ |r 0 - k| * (1 / 4 : ℝ) ^ d := by positivity
      nlinarith [mul_le_mul_of_nonneg_left h4 hM]
  have hlim : Tendsto (fun d : ℕ => |r 0 - k| * (1 / 4 : ℝ) ^ d) atTop (𝓝 0) := by
    simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num)
      (by norm_num : (1 / 4 : ℝ) < 1)).const_mul |r 0 - k|
  rw [tendsto_iff_norm_sub_tendsto_zero]
  exact squeeze_zero (fun d => norm_nonneg _) (fun d => by rw [Real.norm_eq_abs]; exact bound d) hlim

lemma kalman_var_fib (m₀ P₀ Q R b : ℝ) (A B : ℕ → ℝ)
    (hB : ∀ t, B t = b) (hb : b ≠ 0) (hQ : 0 < Q) (hR : R = Q * b ^ 2) (hP₀ : P₀ = Q) :
    ∀ t : ℕ, (kalmanFilter m₀ P₀ Q R A B t).2
      = Q * ((Nat.fib (2 * t + 1) : ℝ) / Nat.fib (2 * t + 2)) := by
  intro t
  induction t with
  | zero => simp [kalmanFilter, hP₀]
  | succ t ih =>
    show (kalmanStep Q R (kalmanFilter m₀ P₀ Q R A B t).1 (kalmanFilter m₀ P₀ Q R A B t).2
      (A (t + 1)) (B (t + 1))).2 = _
    simp only [kalmanStep]
    rw [ih, hB, hR, fib_ratio_succ]
    have hx := fib_ratio_nonneg t
    have hb2 : 0 < b ^ 2 := by positivity
    have hQ' := hQ.ne'
    have hb2' := hb2.ne'
    have h1 : (Nat.fib (2 * t + 1) : ℝ) / Nat.fib (2 * t + 2) + 2 ≠ 0 := by positivity
    have h2 : b ^ 2 * (Q * ((Nat.fib (2 * t + 1) : ℝ) / Nat.fib (2 * t + 2)) + Q) + Q * b ^ 2 ≠ 0 := by
      positivity
    field_simp
    ring

lemma kalman_weight_fib (m₀ P₀ Q R b : ℝ) (A B : ℕ → ℝ)
    (hB : ∀ t, B t = b) (hb : b ≠ 0) (hQ : 0 < Q) (hR : R = Q * b ^ 2) (hP₀ : P₀ = Q) (e : ℕ) :
    kalmanWeight Q R (kalmanFilter m₀ P₀ Q R A B e).2 (B (e + 1))
      = (Nat.fib (2 * (e + 1) + 1) : ℝ) / Nat.fib (2 * (e + 1) + 2) := by
  rw [kalman_var_fib m₀ P₀ Q R b A B hB hb hQ hR hP₀ e, fib_ratio_succ, kalmanWeight, hB, hR]
  have hx := fib_ratio_nonneg e
  have hb2 : 0 < b ^ 2 := by positivity
  have hQ' := hQ.ne'
  have hb2' := hb2.ne'
  have h1 : (Nat.fib (2 * e + 1) : ℝ) / Nat.fib (2 * e + 2) + 2 ≠ 0 := by positivity
  have h2 : b ^ 2 * (Q * ((Nat.fib (2 * e + 1) : ℝ) / Nat.fib (2 * e + 2)) + Q) + Q * b ^ 2 ≠ 0 := by
    positivity
  field_simp
  ring

#print axioms fib_ratio_succ
#print axioms fib_ratio_nonneg
#print axioms fib_ratio_tendsto
#print axioms kalman_var_fib
#print axioms kalman_weight_fib

/-- **Fibonacci weights and the golden ratio (Worked numbers).** Hold `B` fixed at `b ≠ 0`,
take `Q > 0`, set the reading variance `R/b²` equal to `Q`, and start from `P₀ = Q`. Then for
any prices `A`, the weight on day `d` (`d = 1, 2, …`) is `F(2d+1)/F(2d+2)`, a ratio of
Fibonacci numbers: `2/3, 5/8, 13/21, 34/55, …`. These weights tend to `(√5 - 1)/2`. -/
theorem kalman_weights_are_fibonacci_ratios (m₀ P₀ Q R b : ℝ) (A B : ℕ → ℝ)
    (hB : ∀ t, B t = b) (hb : b ≠ 0) (hQ : 0 < Q) (hR : R = Q * b ^ 2) (hP₀ : P₀ = Q) :
    (∀ d : ℕ, 1 ≤ d →
      kalmanWeight Q R (kalmanFilter m₀ P₀ Q R A B (d - 1)).2 (B d)
        = (Nat.fib (2 * d + 1) : ℝ) / Nat.fib (2 * d + 2)) ∧
    Tendsto (fun d : ℕ => kalmanWeight Q R (kalmanFilter m₀ P₀ Q R A B d).2 (B (d + 1)))
      atTop (𝓝 ((Real.sqrt 5 - 1) / 2)) := by
  refine ⟨fun d hd => ?_, ?_⟩
  · obtain ⟨e, rfl⟩ : ∃ e, d = e + 1 := ⟨d - 1, by omega⟩
    rw [show e + 1 - 1 = e by omega]
    exact kalman_weight_fib m₀ P₀ Q R b A B hB hb hQ hR hP₀ e
  · have hw : (fun d : ℕ => kalmanWeight Q R (kalmanFilter m₀ P₀ Q R A B d).2 (B (d + 1)))
        = fun d : ℕ => (Nat.fib (2 * (d + 1) + 1) : ℝ) / Nat.fib (2 * (d + 1) + 2) := by
      funext d
      exact kalman_weight_fib m₀ P₀ Q R b A B hB hb hQ hR hP₀ d
    rw [hw]
    exact (tendsto_add_atTop_iff_nat 1).mpr fib_ratio_tendsto

/-! The card's hand example, as exact fractions: `B = 100` every day, `m₀ = 13/10`,
`P₀ = Q = 1/10000`, `R = 1`, and A's prices 129, 127, 126, 124. -/

-- Day 1 weight: prediction 2 units against a reading of 1 unit, 2/(2 + 1) = 2/3.
example : ((1 : ℚ) / 10000 + 1 / 10000) * 100 ^ 2 / (100 ^ 2 * (1 / 10000 + 1 / 10000) + 1)
    = 2 / 3 := by norm_num
-- Each weight gives the next as (k + 1)/(k + 2): 2/3 → 5/8 → 13/21 → 34/55.
example : ((2 : ℚ) / 3 + 1) / (2 / 3 + 2) = 5 / 8 := by norm_num
example : ((5 : ℚ) / 8 + 1) / (5 / 8 + 2) = 13 / 21 := by norm_num
example : ((13 : ℚ) / 21 + 1) / (13 / 21 + 2) = 34 / 55 := by norm_num
-- Those are Fibonacci numbers F(3)/F(4), F(5)/F(6), F(7)/F(8), F(9)/F(10).
example : Nat.fib 3 = 2 ∧ Nat.fib 4 = 3 ∧ Nat.fib 5 = 5 ∧ Nat.fib 6 = 8 ∧
    Nat.fib 7 = 13 ∧ Nat.fib 8 = 21 ∧ Nat.fib 9 = 34 ∧ Nat.fib 10 = 55 := by decide
-- Day 1: surprise 129 - 1.30 × 100 = -1; estimate 1.30 + (2/3)(-1)/100 = 97/75;
-- variance (2/3)(1/10000) = 1/15000.
example : (129 : ℚ) - 13 / 10 * 100 = -1 := by norm_num
example : (13 : ℚ) / 10 + 2 / 3 * (-1) / 100 = 97 / 75 := by norm_num
example : (2 : ℚ) / 3 * (1 / 10000) = 1 / 15000 := by norm_num
-- Day 2: surprise 127 - (97/75) × 100 = -7/3; estimate 97/75 + (5/8)(-7/3)/100 = 1023/800.
example : (127 : ℚ) - 97 / 75 * 100 = -7 / 3 := by norm_num
example : (97 : ℚ) / 75 + 5 / 8 * (-7 / 3) / 100 = 1023 / 800 := by norm_num
-- Day 3: surprise 126 - (1023/800) × 100 = -15/8; estimate 1023/800 + (13/21)(-15/8)/100 = 887/700.
example : (126 : ℚ) - 1023 / 800 * 100 = -15 / 8 := by norm_num
example : (1023 : ℚ) / 800 + 13 / 21 * (-15 / 8) / 100 = 887 / 700 := by norm_num
-- Day 4: surprise 124 - (887/700) × 100 = -19/7; estimate 887/700 + (34/55)(-19/7)/100 = 6877/5500,
-- the card's 1.250364.
example : (124 : ℚ) - 887 / 700 * 100 = -19 / 7 := by norm_num
example : (887 : ℚ) / 700 + 34 / 55 * (-19 / 7) / 100 = 6877 / 5500 := by norm_num
-- The same four days run through the filter's definition give 6877/5500.
example : (kalmanFilter (13 / 10) (1 / 10000) (1 / 10000) 1
    (fun t => if t = 1 then 129 else if t = 2 then 127 else if t = 3 then 126 else 124)
    (fun _ => 100) 4).1 = 6877 / 5500 := by
  norm_num [kalmanFilter, kalmanStep]
-- The two-day rolling window on day 4: (126 + 124)/(2 × 100) = 5/4.
example : ((126 : ℚ) + 124) / (2 * 100) = 5 / 4 := by norm_num
-- The steady weight k = (√5 - 1)/2 solves k² + k - 1 = 0.
example : ((Real.sqrt 5 - 1) / 2) ^ 2 + (Real.sqrt 5 - 1) / 2 - 1 = 0 := by
  have h := Real.sq_sqrt (show (0 : ℝ) ≤ 5 by norm_num)
  nlinarith [h]
-- The 60-day window's average day is (0 + 1 + … + 59)/60 = 59/2 days old, and at a drift of
-- 0.2/250 a day it lags by 59/2500 (the card's 0.023600).
example : (∑ i ∈ range 60, i) = 1770 := by decide
example : (1770 : ℚ) / 60 = 59 / 2 := by norm_num
example : (1 : ℚ) / 5 / 250 * (59 / 2) = 59 / 2500 := by norm_num

#print axioms kalman_update_is_precision_weighted_posterior
#print axioms kalman_estimate_is_whole_path_regression
#print axioms kalman_weights_are_fibonacci_ratios

end KalmanHedge
