-- Spreads over the curve: for fixed positive payments at future dates, exactly one constant spread added to every zero rate reprices a bond at any positive market price, its sign is set by whether the market price is below or above the curve's price, and an asset swap priced on the curve has spread equal to the price gap divided by the face times the annuity.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Finset Real

/-! A bond makes payments `C i` at dates `t i` (in years). The curve supplies a continuously
compounded zero rate `r i` for each payment date. With a spread `z` added to every zero rate the
bond is priced at `V(z) = ∑ i, C i * exp (-(r i + z) * t i)`. The z-spread is the `z` with
`V(z) = P`, the market price. -/

theorem zspread_value_strictAnti {ι : Type*} [Fintype ι] [Nonempty ι]
    (C t r : ι → ℝ) (hC : ∀ i, 0 < C i) (ht : ∀ i, 0 < t i) :
    StrictAnti (fun z : ℝ => ∑ i, C i * exp (-(r i + z) * t i)) := by
  intro a b hab
  apply Finset.sum_lt_sum_of_nonempty Finset.univ_nonempty
  intro i _
  apply mul_lt_mul_of_pos_left _ (hC i)
  apply exp_lt_exp.mpr
  nlinarith [ht i]

theorem zspread_value_continuous {ι : Type*} [Fintype ι]
    (C t r : ι → ℝ) :
    Continuous (fun z : ℝ => ∑ i, C i * exp (-(r i + z) * t i)) := by
  fun_prop

#print axioms zspread_value_strictAnti
#print axioms zspread_value_continuous

/-- One spread fits, and only one: if every payment is positive and lands in the future, then for
any positive market price `P` there is exactly one constant spread `z` which, added to every zero
rate on the curve, reprices the bond at `P`. -/
theorem z_spread_exists_unique {ι : Type*} [Fintype ι] [Nonempty ι]
    (C t r : ι → ℝ) (hC : ∀ i, 0 < C i) (ht : ∀ i, 0 < t i)
    (P : ℝ) (hP : 0 < P) :
    ∃! z : ℝ, ∑ i, C i * exp (-(r i + z) * t i) = P := by
  set V : ℝ → ℝ := fun z => ∑ i, C i * exp (-(r i + z) * t i) with hV
  have hanti := zspread_value_strictAnti C t r hC ht
  have hcont := zspread_value_continuous C t r
  obtain ⟨i0⟩ := ‹Nonempty ι›
  -- low spread: price at least P
  set z1 : ℝ := -r i0 - log (P / C i0) / t i0 with hz1
  have hV1 : P ≤ V z1 := by
    have hterm : C i0 * exp (-(r i0 + z1) * t i0) = P := by
      have : -(r i0 + z1) * t i0 = log (P / C i0) := by
        rw [hz1]; field_simp [(ht i0).ne']; ring
      rw [this, exp_log (div_pos hP (hC i0))]
      field_simp [(hC i0).ne']
    have hle : C i0 * exp (-(r i0 + z1) * t i0) ≤ V z1 := by
      simp only [hV]
      exact Finset.single_le_sum (f := fun i => C i * exp (-(r i + z1) * t i))
        (fun i _ => (mul_pos (hC i) (exp_pos _)).le) (Finset.mem_univ i0)
    linarith
  -- high spread: price at most P
  set n : ℝ := (Fintype.card ι : ℝ) with hn
  have hnpos : 0 < n := by rw [hn]; exact_mod_cast Fintype.card_pos
  set a : ι → ℝ := fun i => -r i - log (P / (n * C i)) / t i with ha
  set z2 : ℝ := ∑ i, |a i| with hz2
  have hV2 : V z2 ≤ P := by
    have hterm : ∀ i, C i * exp (-(r i + z2) * t i) ≤ P / n := by
      intro i
      have hai : a i ≤ z2 := by
        calc a i ≤ |a i| := le_abs_self _
          _ ≤ z2 := Finset.single_le_sum (f := fun i => |a i|) (fun i _ => abs_nonneg _)
                (Finset.mem_univ i)
      have hpos : 0 < P / (n * C i) := div_pos hP (mul_pos hnpos (hC i))
      have hexp : -(r i + z2) * t i ≤ log (P / (n * C i)) := by
        have h1 : -r i - log (P / (n * C i)) / t i ≤ z2 := hai
        have h2 : -(r i + z2) ≤ log (P / (n * C i)) / t i := by linarith
        have h3 := (le_div_iff₀ (ht i)).mp h2
        linarith
      have := exp_le_exp.mpr hexp
      rw [exp_log hpos] at this
      calc C i * exp (-(r i + z2) * t i) ≤ C i * (P / (n * C i)) :=
            mul_le_mul_of_nonneg_left this (hC i).le
        _ = P / n := by field_simp [(hC i).ne', hnpos.ne']
    calc V z2 = ∑ i, C i * exp (-(r i + z2) * t i) := rfl
      _ ≤ ∑ _i : ι, P / n := Finset.sum_le_sum (fun i _ => hterm i)
      _ = P := by
        rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul, ← hn]
        field_simp [hnpos.ne']
  obtain ⟨z, hz⟩ := intermediate_value_univ z2 z1 hcont ⟨hV2, hV1⟩
  refine ⟨z, hz, ?_⟩
  intro y hy
  exact hanti.injective (hy.trans hz.symm)

/-- The boundary cases: with the same fixed positive payments at future dates, the z-spread of a
market price `P` is positive exactly when `P` is below the curve's own price `V(0)`, zero exactly
when `P` equals it, and negative exactly when `P` is above it. -/
theorem z_spread_sign {ι : Type*} [Fintype ι] [Nonempty ι]
    (C t r : ι → ℝ) (hC : ∀ i, 0 < C i) (ht : ∀ i, 0 < t i)
    (P z : ℝ) (hz : ∑ i, C i * exp (-(r i + z) * t i) = P) :
    (0 < z ↔ P < ∑ i, C i * exp (-r i * t i)) ∧
    (z = 0 ↔ P = ∑ i, C i * exp (-r i * t i)) ∧
    (z < 0 ↔ ∑ i, C i * exp (-r i * t i) < P) := by
  have hanti := zspread_value_strictAnti C t r hC ht
  have h0 : (fun z : ℝ => ∑ i, C i * exp (-(r i + z) * t i)) 0 =
      ∑ i, C i * exp (-r i * t i) := by simp
  have hzV : (fun z : ℝ => ∑ i, C i * exp (-(r i + z) * t i)) z = P := hz
  rw [← h0, ← hzV]
  exact ⟨(StrictAnti.lt_iff_gt hanti).symm, (StrictAnti.injective hanti).eq_iff.symm,
    (StrictAnti.lt_iff_gt hanti).symm⟩

/-- The asset swap. Annual coupons `c` and face `F` paid at whole years `1, …, n`; the curve's
discount factor for year `k` is `D k = exp (-(r k) * k)`, so `D 0 = 1`. The floating payment for
the year ending at `k + 1` is the curve's forward, `F * (D k / D (k + 1) - 1)`. Then the floating
leg is worth par minus par at the end, `F * (1 - D n)`, whatever the curve; and the package (pay
`F`, receive the bond at market price `P`, receive floating plus `A` on `F`, pay the coupons) is
worth zero exactly when `A` is the price gap `V(0) - P` divided by `F` times the annuity
`∑ D k`, where `V(0) = c * ∑ D k + F * D n` is the bond priced on the curve. -/
theorem asset_swap_spread_formula (r : ℕ → ℝ) (c F P A : ℝ) (n : ℕ)
    (hF : 0 < F) (hn : 0 < n) :
    let D : ℕ → ℝ := fun k => exp (-(r k) * k)
    (∑ k ∈ range n, F * (D k / D (k + 1) - 1) * D (k + 1) = F * (1 - D n)) ∧
    (-F + P + ∑ k ∈ range n, (F * (D k / D (k + 1) - 1) + A * F) * D (k + 1)
        - ∑ k ∈ range n, c * D (k + 1) = 0 ↔
      A = ((∑ k ∈ range n, c * D (k + 1) + F * D n) - P) /
          (F * ∑ k ∈ range n, D (k + 1))) := by
  intro D
  have hDpos : ∀ k, 0 < D k := fun k => exp_pos _
  have hD0 : D 0 = 1 := by simp [D]
  have hterm : ∀ k, F * (D k / D (k + 1) - 1) * D (k + 1) = F * (D k - D (k + 1)) := by
    intro k
    field_simp [(hDpos (k + 1)).ne']
  have hfloat : ∑ k ∈ range n, F * (D k / D (k + 1) - 1) * D (k + 1) = F * (1 - D n) := by
    simp_rw [hterm]
    rw [← Finset.mul_sum, Finset.sum_range_sub' D n, hD0]
  refine ⟨hfloat, ?_⟩
  set S := ∑ k ∈ range n, D (k + 1) with hS
  have hSpos : 0 < S := by
    apply Finset.sum_pos (fun k _ => hDpos (k + 1))
    exact ⟨0, Finset.mem_range.mpr hn⟩
  have hsplit : ∑ k ∈ range n, (F * (D k / D (k + 1) - 1) + A * F) * D (k + 1)
      = F * (1 - D n) + A * F * S := by
    rw [← hfloat, hS, Finset.mul_sum, ← Finset.sum_add_distrib]
    apply Finset.sum_congr rfl
    intro k _
    ring
  have hc : ∑ k ∈ range n, c * D (k + 1) = c * S := by rw [hS, Finset.mul_sum]
  rw [hsplit, hc]
  have hFS : 0 < F * S := mul_pos hF hSpos
  rw [eq_div_iff hFS.ne']
  constructor <;> intro h <;> linarith

/-! The card's exact arithmetic. -/

-- One basis point is one hundredth of one percent, so 120 basis points is 1.20% a year.
example : (120 : ℚ) * (1 / 100 / 100) = 12 / 1000 := by norm_num

-- Northwind's five payments per 100 of face: four coupons of 4, then 4 plus the face of 100.
example : (4 : ℚ) + 100 = 104 := by norm_num

-- The gap, curve minus market: 100.2398 - 94.8330 = 5.4068.
example : (1002398 / 10000 : ℚ) - 948330 / 10000 = 54068 / 10000 := by norm_num

-- Price given up against the curve, per 100 of face, at 60, 120, 180, 240 and 300 bp.
example : (10024 / 100 : ℚ) - 9750 / 100 = 274 / 100 := by norm_num
example : (10024 / 100 : ℚ) - 9483 / 100 = 541 / 100 := by norm_num
example : (10024 / 100 : ℚ) - 9224 / 100 = 800 / 100 := by norm_num
example : (10024 / 100 : ℚ) - 8973 / 100 = 1051 / 100 := by norm_num
example : (10024 / 100 : ℚ) - 8729 / 100 = 1295 / 100 := by norm_num

-- The I-spread: yield 5.2001% less par rate 3.9466% is 1.2535%, that is 125.35 basis points.
example : ((52001 : ℚ) / 1000000 - 39466 / 1000000) * 10000 = 12535 / 100 := by norm_num

#print axioms z_spread_exists_unique
#print axioms z_spread_sign
#print axioms asset_swap_spread_formula
