-- Inflation-linked bonds: valued at any steady inflation rate, a linker's indexed payments discounted at the Fisher nominal yield are worth exactly the settlement index ratio times the real price, every positive real price has exactly one real yield, and the deflation floor never repays less than the original face.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Field

open Finset

/-- On yields above -200% with a stub fraction `0 < ρ ≤ 1`, the stub discount factor is positive. -/
lemma ilb_stub_pos {ρ y : ℝ} (hρ0 : 0 < ρ) (hρ1 : ρ ≤ 1) (hy : -2 < y) :
    0 < 1 + ρ * (y / 2) := by
  have h : 0 < 1 + y / 2 := by linarith
  nlinarith [mul_pos hρ0 h]

#print axioms ilb_stub_pos

/-- Inflation cancels out of a linker's price. Payment `k` of the bond (with `k = 0` the next
coupon and `k = n` the last) has the fixed real amount `X k`, in dollars of the dated day, and is
due `ρ + k` half-years after settlement, where `ρ = r/s` is the stub to the next coupon. Let
inflation run at the steady yearly rate `π > -1`, so one half-year of inflation is
`g = √(1 + π)` and the index ratio on payment `k`'s date is `I_s · g^(ρ + k)`, with `I_s` the
index ratio on the settlement day. Discount each indexed payment at the Fisher nominal yield:
the stub by `(1 + ρ·y/2)·g^ρ` and each later half-year by `(1 + y/2)·g`, where `y` is the real
yield. Then every power of `g` cancels and the total is the settlement index ratio times the
real dirty price `P + A = ∑ X k / ((1 + ρ·y/2)(1 + y/2)^k)`, whatever `π` is. -/
theorem nominal_value_eq_index_ratio_mul_real_price
    (n : ℕ) (X : ℕ → ℝ) (y ρ Is π : ℝ) (hπ : -1 < π) :
    ∑ k ∈ range (n + 1),
        X k * (Is * Real.sqrt (1 + π) ^ (ρ + k)) /
          ((1 + ρ * (y / 2)) * Real.sqrt (1 + π) ^ ρ * ((1 + y / 2) * Real.sqrt (1 + π)) ^ k)
      = Is * ∑ k ∈ range (n + 1), X k / ((1 + ρ * (y / 2)) * (1 + y / 2) ^ k) := by
  have hg : 0 < Real.sqrt (1 + π) := Real.sqrt_pos.mpr (by linarith)
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl (fun k _ => ?_)
  have ha : Real.sqrt (1 + π) ^ ρ ≠ 0 := (Real.rpow_pos_of_pos hg ρ).ne'
  have hb : Real.sqrt (1 + π) ^ k ≠ 0 := (pow_pos hg k).ne'
  rw [Real.rpow_add hg, Real.rpow_natCast, mul_pow]
  calc X k * (Is * (Real.sqrt (1 + π) ^ ρ * Real.sqrt (1 + π) ^ k)) /
        ((1 + ρ * (y / 2)) * Real.sqrt (1 + π) ^ ρ * ((1 + y / 2) ^ k * Real.sqrt (1 + π) ^ k))
      = (X k * Is) * (Real.sqrt (1 + π) ^ ρ * Real.sqrt (1 + π) ^ k) /
        (((1 + ρ * (y / 2)) * (1 + y / 2) ^ k) * (Real.sqrt (1 + π) ^ ρ * Real.sqrt (1 + π) ^ k)) := by
        ring_nf
    _ = (X k * Is) / ((1 + ρ * (y / 2)) * (1 + y / 2) ^ k) :=
        mul_div_mul_right _ _ (mul_ne_zero ha hb)
    _ = Is * (X k / ((1 + ρ * (y / 2)) * (1 + y / 2) ^ k)) := by ring

/-- One real yield for each price. A linker with real coupon `c > 0` per 100 pays `c/2` at
each of the payments `k = 0, …, n - 1` and `c/2 + 100` at the last one, `k = n`, with at least
one whole half-year after the next coupon (`1 ≤ n`). The stub to the next coupon is the
fraction `ρ = r/s` of a half-year, `0 < ρ ≤ 1`, discounted with the Treasury's simple stub
`1 + ρ·y/2`. Then for every positive real dirty price `p` there is exactly one real yield
`y > -200%` at which the dirty price equals `p`. -/
theorem exists_unique_real_yield (n : ℕ) (hn : 1 ≤ n) (c ρ p : ℝ) (hc : 0 < c)
    (hρ0 : 0 < ρ) (hρ1 : ρ ≤ 1) (hp : 0 < p) :
    ∃! y : ℝ, -2 < y ∧
      ∑ k ∈ range (n + 1),
        (c / 2 + if k = n then 100 else 0) / ((1 + ρ * (y / 2)) * (1 + y / 2) ^ k) = p := by
  have ha : ∀ k, 0 < c / 2 + (if k = n then (100 : ℝ) else 0) := by
    intro k; split_ifs <;> linarith
  let f : ℝ → ℝ := fun y => ∑ k ∈ range (n + 1),
    (c / 2 + if k = n then 100 else 0) / ((1 + ρ * (y / 2)) * (1 + y / 2) ^ k)
  have hanti : StrictAntiOn f (Set.Ioi (-2)) := by
    intro y1 hy1 y2 hy2 h12
    simp only [Set.mem_Ioi] at hy1 hy2
    apply Finset.sum_lt_sum_of_nonempty ⟨0, by simp⟩
    intro k _
    have hA1 := ilb_stub_pos hρ0 hρ1 hy1
    have hB1 : 0 < 1 + y1 / 2 := by linarith
    have hBk : (1 + y1 / 2) ^ k ≤ (1 + y2 / 2) ^ k := pow_le_pow_left₀ hB1.le (by linarith) k
    have hBk1 : 0 < (1 + y1 / 2) ^ k := pow_pos hB1 k
    have hA12 : 1 + ρ * (y1 / 2) < 1 + ρ * (y2 / 2) := by nlinarith
    apply div_lt_div_of_pos_left (ha k) (mul_pos hA1 hBk1)
    calc (1 + ρ * (y1 / 2)) * (1 + y1 / 2) ^ k
        < (1 + ρ * (y2 / 2)) * (1 + y1 / 2) ^ k := mul_lt_mul_of_pos_right hA12 hBk1
      _ ≤ (1 + ρ * (y2 / 2)) * (1 + y2 / 2) ^ k :=
          mul_le_mul_of_nonneg_left hBk (by linarith)
  -- an upper yield where the price is at most p
  set T : ℝ := ∑ k ∈ range (n + 1), (c / 2 + if k = n then (100 : ℝ) else 0) with hT
  have hT0 : 0 < T := Finset.sum_pos (fun k _ => ha k) ⟨0, by simp⟩
  set yhi : ℝ := 2 * T / (ρ * p) with hyhi
  have hyhi0 : 0 ≤ yhi := by positivity
  have hAhi : 1 + ρ * (yhi / 2) = 1 + T / p := by
    rw [hyhi]; field_simp
  have hfhi : f yhi ≤ p := by
    have hA : 0 < 1 + ρ * (yhi / 2) := by positivity
    calc f yhi ≤ ∑ k ∈ range (n + 1),
          (c / 2 + if k = n then (100 : ℝ) else 0) / (1 + ρ * (yhi / 2)) := by
          apply Finset.sum_le_sum
          intro k _
          apply div_le_div_of_nonneg_left (ha k).le hA
          have : 1 ≤ (1 + yhi / 2) ^ k := one_le_pow₀ (by linarith)
          nlinarith
      _ = T / (1 + T / p) := by rw [← Finset.sum_div, hAhi]
      _ ≤ p := by
          rw [div_le_iff₀ (by positivity)]
          field_simp
          nlinarith
  -- a lower yield where the price is at least p
  set ylo : ℝ := -2 * p / (p + 100) with hylo
  have hBlo : 1 + ylo / 2 = 100 / (p + 100) := by
    rw [hylo]; field_simp; ring
  have hylo2 : -2 < ylo := by
    rw [hylo, lt_div_iff₀ (by linarith)]; linarith
  have hylo0 : ylo ≤ 0 := by
    rw [hylo]; apply div_nonpos_of_nonpos_of_nonneg <;> linarith
  have hflo : p ≤ f ylo := by
    have hA : 0 < 1 + ρ * (ylo / 2) := ilb_stub_pos hρ0 hρ1 hylo2
    have hA1 : 1 + ρ * (ylo / 2) ≤ 1 := by nlinarith
    have hB : 0 < 1 + ylo / 2 := by linarith
    have hB1 : 1 + ylo / 2 ≤ 1 := by linarith
    have hBn : (1 + ylo / 2) ^ n ≤ 1 + ylo / 2 := pow_le_of_le_one hB.le hB1 (by omega)
    have hBn0 : 0 < (1 + ylo / 2) ^ n := pow_pos hB n
    have hterm : p ≤ (c / 2 + if n = n then (100 : ℝ) else 0) /
        ((1 + ρ * (ylo / 2)) * (1 + ylo / 2) ^ n) := by
      simp only [ite_true]
      calc p ≤ 100 / (1 + ylo / 2) := by
            rw [hBlo, div_div_eq_mul_div, le_div_iff₀ (by positivity)]
            nlinarith
        _ ≤ (c / 2 + 100) / (1 + ylo / 2) := by
            apply div_le_div_of_nonneg_right (by linarith) hB.le
        _ ≤ (c / 2 + 100) / ((1 + ρ * (ylo / 2)) * (1 + ylo / 2) ^ n) := by
            apply div_le_div_of_nonneg_left (by linarith) (mul_pos hA hBn0)
            calc (1 + ρ * (ylo / 2)) * (1 + ylo / 2) ^ n ≤ 1 * (1 + ylo / 2) ^ n :=
                  mul_le_mul_of_nonneg_right hA1 hBn0.le
              _ ≤ 1 + ylo / 2 := by rw [one_mul]; exact hBn
    refine hterm.trans ?_
    have hnonneg : ∀ k ∈ range (n + 1), 0 ≤ (c / 2 + if k = n then (100 : ℝ) else 0) /
        ((1 + ρ * (ylo / 2)) * (1 + ylo / 2) ^ k) := fun k _ =>
      div_nonneg (ha k).le (mul_pos hA (pow_pos hB k)).le
    exact Finset.single_le_sum (f := fun k => (c / 2 + if k = n then (100 : ℝ) else 0) /
        ((1 + ρ * (ylo / 2)) * (1 + ylo / 2) ^ k)) hnonneg (by simp)
  have hle : ylo ≤ yhi := by linarith
  have hcont : ContinuousOn f (Set.Icc ylo yhi) := by
    apply continuousOn_finsetSum
    intro k _
    apply ContinuousOn.div continuousOn_const (by fun_prop)
    intro y hy
    have hy2 : -2 < y := lt_of_lt_of_le hylo2 hy.1
    exact (mul_pos (ilb_stub_pos hρ0 hρ1 hy2) (pow_pos (by linarith) k)).ne'
  obtain ⟨y, hyI, hfy⟩ := intermediate_value_Icc' hle hcont ⟨hfhi, hflo⟩
  have hy2 : -2 < y := lt_of_lt_of_le hylo2 hyI.1
  refine ⟨y, ⟨hy2, hfy⟩, fun y' hy' => ?_⟩
  exact hanti.injOn (Set.mem_Ioi.mpr hy'.1) (Set.mem_Ioi.mpr hy2) (hy'.2.trans hfy.symm)

/-- The deflation floor. At maturity the principal repaid on original face `F ≥ 0` at final
index ratio `I` is `F · max(I, 1)`: never less than the original face, equal to `F · I` when
prices have not fallen (`I ≥ 1`), and equal to `F` when they have (`I ≤ 1`). -/
theorem principal_floor (F I : ℝ) (hF : 0 ≤ F) :
    F ≤ F * max I 1 ∧ (1 ≤ I → F * max I 1 = F * I) ∧ (I ≤ 1 → F * max I 1 = F) := by
  refine ⟨?_, fun h => by rw [max_eq_left h], fun h => by rw [max_eq_right h, mul_one]⟩
  calc F = F * 1 := (mul_one F).symm
    _ ≤ F * max I 1 := mul_le_mul_of_nonneg_left (le_max_right I 1) hF

/-- The Treasury's reference index, in units of 0.00001, from CPI levels in thousandths:
interpolate `day - 1` of `days` steps from `m0` towards `m1`, cut to six decimals, round to five. -/
def refIndex (m0 m1 day days : ℕ) : ℕ :=
  ((m0 * days + (day - 1) * (m1 - m0)) * 1000 / days + 5) / 10

/-- The index ratio, in units of 0.00001: cut to six decimals, then round to five. -/
def indexRatio (ref base : ℕ) : ℕ :=
  (ref * 1000000 / base + 5) / 10

-- The Treasury's own example: reference CPI 154.63333 on 15 April, index ratio 1.00011 on 16 April.
example : refIndex 154400 154900 15 30 = 15463333 := by decide
example : indexRatio (refIndex 154400 154900 16 30) (refIndex 154400 154900 15 30) = 100011 := by
  decide

-- The card's linker: base 320.42000 on 15 Jul 2026, 320.90000 on 31 Jul 2026, 324.14000 on 15 Jan 2027.
example : refIndex 320000 320930 15 31 = 32042000 := by decide
example : refIndex 320000 320930 31 31 = 32090000 := by decide
example : refIndex 324000 324310 15 31 = 32414000 := by decide

-- Index ratios 1.00150 at settlement and 1.01161 on the first coupon date.
example : indexRatio 32090000 32042000 = 100150 := by decide
example : indexRatio 32414000 32042000 = 101161 := by decide

-- Days in the half-year s = 184 (15 Jul to 15 Jan) and to the next coupon r = 168 (31 Jul to 15 Jan).
example : (31 - 15) + 31 + 30 + 31 + 30 + 31 + 15 = 184 := by decide
example : 31 + 30 + 31 + 30 + 31 + 15 = 168 := by decide

-- Real accrued per 100: (184 - 168)/184 of the 0.50 half-coupon, exactly 1/23 = 0.043478...
example : ((184 - 168 : ℚ) / 184) * (1 / 2) = 1 / 23 := by norm_num

-- First coupon on $1,000: 10 × 0.50 × 1.01161 = $5.05805.
example : (1000 / 100 : ℚ) * (1 / 2) * (101161 / 100000) = 505805 / 100000 := by norm_num

-- The floor: a final ratio of 0.95 repays $1,000, not $950; a final ratio of 1.30 repays $1,300.
example : (1000 : ℚ) * max (95 / 100) 1 = 1000 := by norm_num
example : (1000 : ℚ) * max (130 / 100) 1 = 1300 := by norm_num

#print axioms nominal_value_eq_index_ratio_mul_real_price
#print axioms exists_unique_real_yield
#print axioms principal_floor
