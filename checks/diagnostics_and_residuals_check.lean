-- Diagnostics: for a least squares straight line, deleting one sale divides its residual by one minus its leverage, Cook's distance is read off one fit as (r²/2)·h/(1 − h), and with independent errors of spread σ a residual's variance is σ²(1 − h), with the card's mansion checked exactly.
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum

open Finset MeasureTheory ProbabilityTheory

namespace Diagnostics

/-! Sales are numbered by `Fin n`: sale `j` has floor area `x j` and price `y j`. Every fit below
is taken over a set `s` of sales: `Finset.univ` is all of them, and `univ.erase i` is every sale
except sale `i`. The formulas are the card's own: the line through the averages with slope
`b = Σ (x_j − x̄) y_j / S_xx`, and the leverage `h_i = 1/n + (x_i − x̄)²/S_xx`. -/

/-- The average of `v` over the sales in `s`. -/
noncomputable def avg {n : ℕ} (s : Finset (Fin n)) (v : Fin n → ℝ) : ℝ :=
  (∑ j ∈ s, v j) / s.card

/-- `S_xx`: the total squared distance of the areas in `s` from their average. -/
noncomputable def sxx {n : ℕ} (s : Finset (Fin n)) (x : Fin n → ℝ) : ℝ :=
  ∑ j ∈ s, (x j - avg s x) ^ 2

/-- The least squares slope through the sales in `s`: `Σ (x_j − x̄) y_j / S_xx`. -/
noncomputable def slope {n : ℕ} (s : Finset (Fin n)) (x y : Fin n → ℝ) : ℝ :=
  (∑ j ∈ s, (x j - avg s x) * y j) / sxx s x

/-- The price the least squares line through the sales in `s` gives at area `t`:
`ȳ + b (t − x̄)`. -/
noncomputable def lineAt {n : ℕ} (s : Finset (Fin n)) (x y : Fin n → ℝ) (t : ℝ) : ℝ :=
  avg s y + slope s x y * (t - avg s x)

/-- The leverage of sale `i` in the fit to all `n` sales: `1/n + (x_i − x̄)²/S_xx`. -/
noncomputable def leverage {n : ℕ} (x : Fin n → ℝ) (i : Fin n) : ℝ :=
  1 / n + (x i - avg univ x) ^ 2 / sxx univ x

/-! Helper lemmas for the proofs below. -/

theorem sum_erase_univ {n : ℕ} (f : Fin n → ℝ) (i : Fin n) :
    ∑ j ∈ univ.erase i, f j = ∑ j, f j - f i := by
  rw [← Finset.sum_erase_add _ _ (mem_univ i)]; ring

theorem card_erase_univ {n : ℕ} (i : Fin n) : (((univ : Finset (Fin n)).erase i).card : ℝ) = n - 1 := by
  rw [card_erase_of_mem (mem_univ i), card_univ, Fintype.card_fin,
    Nat.cast_sub (by have := i.pos; omega)]
  simp

theorem slope_num_eq {n : ℕ} (s : Finset (Fin n)) (x y : Fin n → ℝ) :
    ∑ j ∈ s, (x j - avg s x) * y j = ∑ j ∈ s, x j * y j - avg s x * ∑ j ∈ s, y j := by
  simp only [sub_mul, sum_sub_distrib, mul_sum]

theorem sxx_eq {n : ℕ} (s : Finset (Fin n)) (x : Fin n → ℝ) :
    sxx s x = ∑ j ∈ s, x j ^ 2 - (∑ j ∈ s, x j) ^ 2 / s.card := by
  unfold sxx avg
  rcases Nat.eq_zero_or_pos s.card with h | h
  · rw [card_eq_zero.mp h]; simp
  · have hc : (s.card : ℝ) ≠ 0 := by positivity
    have e : ∀ j ∈ s, (x j - (∑ k ∈ s, x k) / s.card) ^ 2 =
        x j ^ 2 - 2 * ((∑ k ∈ s, x k) / s.card) * x j + ((∑ k ∈ s, x k) / s.card) ^ 2 :=
      fun j _ => by ring
    rw [sum_congr rfl e, sum_add_distrib, sum_sub_distrib, ← mul_sum, sum_const, nsmul_eq_mul]
    field_simp
    ring

theorem sxx_pos {n : ℕ} (s : Finset (Fin n)) (x : Fin n → ℝ) {j k : Fin n} (hj : j ∈ s)
    (hk : k ∈ s) (h : x j ≠ x k) : 0 < sxx s x := by
  unfold sxx
  apply lt_of_le_of_ne (sum_nonneg fun _ _ => sq_nonneg _)
  intro h0
  have hz := (sum_eq_zero_iff_of_nonneg (fun _ _ => sq_nonneg _)).mp h0.symm
  have e1 : x j - avg s x = 0 := pow_eq_zero_iff two_ne_zero |>.mp (hz j hj)
  have e2 : x k - avg s x = 0 := pow_eq_zero_iff two_ne_zero |>.mp (hz k hk)
  exact h (by linarith)

theorem setup_facts {n : ℕ} (x : Fin n → ℝ) (i : Fin n)
    (hx : ∃ j k, j ≠ i ∧ k ≠ i ∧ x j ≠ x k) :
    (3 : ℝ) ≤ n ∧ 0 < sxx univ x ∧ 0 < sxx (univ.erase i) x := by
  obtain ⟨j, k, hj, hk, hjk⟩ := hx
  refine ⟨?_, sxx_pos univ x (mem_univ j) (mem_univ k) hjk,
    sxx_pos (univ.erase i) x (mem_erase.mpr ⟨hj, mem_univ j⟩) (mem_erase.mpr ⟨hk, mem_univ k⟩) hjk⟩
  have : ({i, j, k} : Finset (Fin n)).card = 3 := by
    rw [card_insert_of_notMem, card_pair]
    · intro h; exact hjk (h ▸ rfl)
    · simp [hj.symm, hk.symm]
  have := this ▸ card_le_univ ({i, j, k} : Finset (Fin n))
  rw [Fintype.card_fin] at this
  exact_mod_cast this

theorem one_sub_leverage_eq {n : ℕ} (x : Fin n → ℝ) (i : Fin n)
    (hx : ∃ j k, j ≠ i ∧ k ≠ i ∧ x j ≠ x k) :
    1 - leverage x i = ((n : ℝ) - 1) * sxx (univ.erase i) x / (n * sxx univ x) := by
  obtain ⟨hn, hS, hS'⟩ := setup_facts x i hx
  unfold leverage
  simp only [sxx_eq] at hS hS' ⊢
  unfold avg
  simp only [sum_erase_univ, card_erase_univ, card_univ, Fintype.card_fin] at hS' hS ⊢
  generalize ∑ j, x j = A at *
  generalize ∑ j, x j ^ 2 = C at *
  generalize x i = a at *
  generalize (n : ℝ) = N at *
  have hN : N ≠ 0 := by intro h; rw [h] at hn; norm_num at hn
  have hN1 : N - 1 ≠ 0 := by intro h; linarith
  have hP0 : N * C - A ^ 2 ≠ 0 := by
    have : N * C - A ^ 2 = N * (C - A ^ 2 / N) := by field_simp
    rw [this]; positivity
  field_simp
  ring

theorem one_sub_leverage_pos {n : ℕ} (x : Fin n → ℝ) (i : Fin n)
    (hx : ∃ j k, j ≠ i ∧ k ≠ i ∧ x j ≠ x k) : 0 < 1 - leverage x i := by
  obtain ⟨hn, hS, hS'⟩ := setup_facts x i hx
  rw [one_sub_leverage_eq x i hx]
  have : (0 : ℝ) < n - 1 := by linarith
  positivity

theorem lineAt_sub {n : ℕ} (s s' : Finset (Fin n)) (x y : Fin n → ℝ) (t : ℝ) :
    lineAt s x y t - lineAt s' x y t =
      (avg s y - slope s x y * avg s x - (avg s' y - slope s' x y * avg s' x)) +
        (slope s x y - slope s' x y) * t := by
  unfold lineAt; ring

theorem sum_affine_sq {n : ℕ} (p q : ℝ) (x : Fin n → ℝ) :
    ∑ j, (p + q * x j) ^ 2 = n * p ^ 2 + 2 * p * q * ∑ j, x j + q ^ 2 * ∑ j, x j ^ 2 := by
  have e : ∀ j, (p + q * x j) ^ 2 = p ^ 2 + (2 * p * q) * x j + q ^ 2 * x j ^ 2 :=
    fun j => by ring
  rw [sum_congr rfl (fun j _ => e j), sum_add_distrib, sum_add_distrib, ← mul_sum, ← mul_sum,
    sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]

theorem cook_core {n : ℕ} (x y : Fin n → ℝ) (i : Fin n)
    (hx : ∃ j k, j ≠ i ∧ k ≠ i ∧ x j ≠ x k) :
    ∑ j, (lineAt univ x y (x j) - lineAt (univ.erase i) x y (x j)) ^ 2 =
      (y i - lineAt univ x y (x i)) ^ 2 * leverage x i / (1 - leverage x i) ^ 2 := by
  obtain ⟨hn, hS, hS'⟩ := setup_facts x i hx
  have hlev : leverage x i = 1 - (1 - leverage x i) := by ring
  rw [hlev, one_sub_leverage_eq x i hx]
  simp only [lineAt_sub]
  rw [sum_affine_sq]
  unfold lineAt slope
  rw [slope_num_eq, slope_num_eq, sxx_eq, sxx_eq]
  rw [sxx_eq] at hS hS'
  unfold avg
  simp only [sum_erase_univ, card_erase_univ, card_univ, Fintype.card_fin] at hS' hS ⊢
  generalize ∑ j, x j = A at *
  generalize ∑ j, y j = B at *
  generalize ∑ j, x j ^ 2 = C at *
  generalize ∑ j, x j * y j = D at *
  generalize x i = a at *
  generalize y i = b at *
  generalize (n : ℝ) = N at *
  have hN : N ≠ 0 := by intro h; rw [h] at hn; norm_num at hn
  have hN1 : N - 1 ≠ 0 := by intro h; linarith
  generalize hS0 : C - A ^ 2 / N = S at *
  generalize hS1 : C - a ^ 2 - (A - a) ^ 2 / (N - 1) = S' at *
  have hSne : S ≠ 0 := hS.ne'
  have hS'ne : S' ≠ 0 := hS'.ne'
  field_simp
  subst hS0 hS1
  field_simp
  ring

theorem residual_coeffs {n : ℕ} (x : Fin n → ℝ) (hx : ∃ j k, x j ≠ x k) (β₀ β₁ : ℝ)
    (v : Fin n → ℝ) (i : Fin n) :
    (β₀ + β₁ * x i + v i) - lineAt univ x (fun j => β₀ + β₁ * x j + v j) (x i) =
      ∑ j, ((if j = i then (1 : ℝ) else 0) -
        ((1 / n - (x i - avg univ x) / sxx univ x * avg univ x) +
          (x i - avg univ x) / sxx univ x * x j)) * v j := by
  obtain ⟨j, k, hjk⟩ := hx
  have hS := sxx_pos univ x (mem_univ j) (mem_univ k) hjk
  have hn : (1 : ℝ) ≤ n := by
    have := j.pos; exact_mod_cast this
  have e1 : ∀ j', ((if j' = i then (1 : ℝ) else 0) -
        ((1 / n - (x i - avg univ x) / sxx univ x * avg univ x) +
          (x i - avg univ x) / sxx univ x * x j')) * v j' =
      (if j' = i then v j' else 0) - (1 / n - (x i - avg univ x) / sxx univ x * avg univ x) * v j'
        - (x i - avg univ x) / sxx univ x * (x j' * v j') := by
    intro j'; split_ifs <;> ring
  rw [sum_congr rfl (fun j' _ => e1 j'), sum_sub_distrib, sum_sub_distrib, sum_ite_eq', ← mul_sum,
    ← mul_sum]
  simp only [mem_univ, ite_true]
  unfold lineAt slope
  rw [slope_num_eq]
  have e2 : ∑ j', x j' * (β₀ + β₁ * x j' + v j') =
      β₀ * ∑ j', x j' + β₁ * ∑ j', x j' ^ 2 + ∑ j', x j' * v j' := by
    have : ∀ j', x j' * (β₀ + β₁ * x j' + v j') = β₀ * x j' + β₁ * x j' ^ 2 + x j' * v j' :=
      fun j' => by ring
    rw [sum_congr rfl (fun j' _ => this j'), sum_add_distrib, sum_add_distrib, ← mul_sum, ← mul_sum]
  rw [e2]
  rw [sxx_eq] at hS ⊢
  unfold avg
  have e3 : ∑ j', (β₀ + β₁ * x j' + v j') = n * β₀ + β₁ * ∑ j', x j' + ∑ j', v j' := by
    rw [sum_add_distrib, sum_add_distrib, ← mul_sum, sum_const, card_univ, Fintype.card_fin,
      nsmul_eq_mul]
  rw [e3]
  simp only [card_univ, Fintype.card_fin] at hS ⊢
  generalize ∑ j, x j = A at *
  generalize ∑ j, x j ^ 2 = C at *
  generalize ∑ j, x j * v j = F at *
  generalize ∑ j, v j = E at *
  generalize x i = a at *
  generalize v i = c at *
  generalize (n : ℝ) = N at *
  have hN : N ≠ 0 := by intro h; rw [h] at hn; norm_num at hn
  generalize hS0 : C - A ^ 2 / N = S at *
  have hSne : S ≠ 0 := hS.ne'
  field_simp
  subst hS0
  field_simp
  ring

theorem residual_coeffs_sq {n : ℕ} (x : Fin n → ℝ) (hx : ∃ j k, x j ≠ x k) (i : Fin n) :
    ∑ j, ((if j = i then (1 : ℝ) else 0) -
        ((1 / n - (x i - avg univ x) / sxx univ x * avg univ x) +
          (x i - avg univ x) / sxx univ x * x j)) ^ 2 = 1 - leverage x i := by
  obtain ⟨j, k, hjk⟩ := hx
  have hS := sxx_pos univ x (mem_univ j) (mem_univ k) hjk
  have hn : (1 : ℝ) ≤ n := by
    have := j.pos; exact_mod_cast this
  have e : ∀ (p q : ℝ) (j' : Fin n), ((if j' = i then (1 : ℝ) else 0) - (p + q * x j')) ^ 2 =
      (if j' = i then 1 - 2 * (p + q * x j') else 0) + (p + q * x j') ^ 2 := by
    intro p q j'; split_ifs <;> ring
  rw [sum_congr rfl (fun j' _ => e _ _ j'), sum_add_distrib, sum_ite_eq', sum_affine_sq]
  simp only [mem_univ, ite_true]
  unfold leverage
  rw [sxx_eq] at hS ⊢
  unfold avg
  simp only [card_univ, Fintype.card_fin] at hS ⊢
  generalize ∑ j, x j = A at *
  generalize ∑ j, x j ^ 2 = C at *
  generalize x i = a at *
  generalize (n : ℝ) = N at *
  have hN : N ≠ 0 := by intro h; rw [h] at hn; norm_num at hn
  generalize hS0 : C - A ^ 2 / N = S at *
  have hSne : S ≠ 0 := hS.ne'
  field_simp
  subst hS0
  field_simp
  ring

/-- **Deleting a sale divides its residual by one minus its leverage (Step 3).** Take any `n`
sales with areas `x` and prices `y`, and any sale `i`, such that the other sales do not all have
the same area (so the line without sale `i` exists). Then sale `i`'s miss from the line fitted
without it, `y_i − ŷ_(i)`, equals its ordinary residual `e_i = y_i − ŷ_i` divided by `1 − h_i`.
One fit gives every deleted residual, with no refitting. -/
theorem deleted_residual_eq_residual_div_one_sub_leverage {n : ℕ} (x y : Fin n → ℝ)
    (i : Fin n) (hx : ∃ j k, j ≠ i ∧ k ≠ i ∧ x j ≠ x k) :
    y i - lineAt (univ.erase i) x y (x i) =
      (y i - lineAt univ x y (x i)) / (1 - leverage x i) := by
  obtain ⟨j, k, hj, hk, hjk⟩ := hx
  have hS' := sxx_pos (univ.erase i) x (mem_erase.mpr ⟨hj, mem_univ j⟩)
    (mem_erase.mpr ⟨hk, mem_univ k⟩) hjk
  have hS := sxx_pos univ x (mem_univ j) (mem_univ k) hjk
  have hn : (3 : ℝ) ≤ n := by
    have : ({i, j, k} : Finset (Fin n)).card = 3 := by
      rw [card_insert_of_notMem, card_pair]
      · intro h; exact hjk (h ▸ rfl)
      · simp [hj.symm, hk.symm]
    have := this ▸ card_le_univ ({i, j, k} : Finset (Fin n))
    rw [Fintype.card_fin] at this
    exact_mod_cast this
  rw [sxx_eq] at hS hS'
  unfold lineAt slope leverage
  rw [slope_num_eq, slope_num_eq, sxx_eq, sxx_eq]
  unfold avg
  simp only [sum_erase_univ, card_erase_univ, card_univ, Fintype.card_fin] at hS' hS ⊢
  generalize ∑ j, x j = A at *
  generalize ∑ j, y j = B at *
  generalize ∑ j, x j ^ 2 = C at *
  generalize ∑ j, x j * y j = D at *
  generalize x i = a at *
  generalize y i = b at *
  generalize (n : ℝ) = N at *
  have hN : N ≠ 0 := by intro h; rw [h] at hn; norm_num at hn
  have hN1 : N - 1 ≠ 0 := by intro h; linarith
  have hP0 : N * C - A ^ 2 ≠ 0 := by
    have : N * C - A ^ 2 = N * (C - A ^ 2 / N) := by field_simp
    rw [this]; positivity
  have key : 1 - (1 / N + (a - A / N) ^ 2 / (C - A ^ 2 / N)) =
      (N - 1) * (C - a ^ 2 - (A - a) ^ 2 / (N - 1)) / (N * (C - A ^ 2 / N)) := by
    field_simp
    ring
  rw [key]
  generalize hS0 : C - A ^ 2 / N = S at *
  generalize hS1 : C - a ^ 2 - (A - a) ^ 2 / (N - 1) = S' at *
  rw [eq_div_iff (by positivity)]
  have h0 : N * S = N * C - A ^ 2 := by rw [← hS0]; field_simp
  have h1 : (N - 1) * S' = (N - 1) * (C - a ^ 2) - (A - a) ^ 2 := by rw [← hS1]; field_simp
  field_simp
  linear_combination (N * (b * (N - 1) - (B - b))) * h1 - ((N - 1) * (b * N - B)) * h0

/-- **Cook's distance from one fit (Step 4).** With the same `n` sales and the same condition
on sale `i`, let `e_j` be the residuals of the fit to all sales, `s² = Σ e_j² / (n − 2)` with
`p = 2` numbers estimated, and `r_i = e_i / (s √(1 − h_i))` the studentized residual. Then
Cook's distance, the sum over all sales of the squared shift in fitted price when sale `i` is
deleted, divided by `p s²`, equals `(r_i² / p) · h_i / (1 − h_i)`. -/
theorem cooks_distance_eq_from_one_fit {n : ℕ} (x y : Fin n → ℝ) (i : Fin n)
    (hx : ∃ j k, j ≠ i ∧ k ≠ i ∧ x j ≠ x k) :
    let e : Fin n → ℝ := fun j => y j - lineAt univ x y (x j)
    let s : ℝ := Real.sqrt ((∑ j, e j ^ 2) / ((n : ℝ) - 2))
    let r : ℝ := e i / (s * Real.sqrt (1 - leverage x i))
    (∑ j, (lineAt univ x y (x j) - lineAt (univ.erase i) x y (x j)) ^ 2) / (2 * s ^ 2) =
      r ^ 2 / 2 * (leverage x i / (1 - leverage x i)) := by
  intro e s r
  have h1 := one_sub_leverage_pos x i hx
  rw [cook_core x y i hx]
  have hr : r ^ 2 = e i ^ 2 / (s ^ 2 * (1 - leverage x i)) := by
    simp only [r, div_pow, mul_pow, Real.sq_sqrt h1.le]
  rw [hr]
  show (y i - lineAt univ x y (x i)) ^ 2 * leverage x i / (1 - leverage x i) ^ 2 / (2 * s ^ 2) =
    (y i - lineAt univ x y (x i)) ^ 2 / (s ^ 2 * (1 - leverage x i)) / 2 *
      (leverage x i / (1 - leverage x i))
  by_cases hs : s ^ 2 = 0
  · rw [hs]; simp
  · field_simp

/-- **A high-leverage residual has a small spread (Step 2).** Suppose the prices are a true
straight line plus errors, `y_j = β₀ + β₁ x_j + ε_j`, where the areas are not all equal and the
errors `ε_j` are independent random variables with finite variance, mean 0 and the same
variance `σ²`. Then the residual of sale `i` from the least squares line through all `n` sales
has variance `σ² (1 − h_i)`. -/
theorem variance_residual_eq_mul_one_sub_leverage {Ω : Type*} [MeasurableSpace Ω]
    {P : Measure Ω} [IsProbabilityMeasure P] {n : ℕ} (x : Fin n → ℝ)
    (hx : ∃ j k, x j ≠ x k) (β₀ β₁ σ : ℝ) (ε : Fin n → Ω → ℝ)
    (hind : iIndepFun ε P) (hL2 : ∀ j, MemLp (ε j) 2 P)
    (hmean : ∀ j, ∫ ω, ε j ω ∂P = 0) (hvar : ∀ j, variance (ε j) P = σ ^ 2) (i : Fin n) :
    variance (fun ω => (β₀ + β₁ * x i + ε i ω) -
        lineAt univ x (fun j => β₀ + β₁ * x j + ε j ω) (x i)) P =
      σ ^ 2 * (1 - leverage x i) := by
  have hfun : (fun ω => (β₀ + β₁ * x i + ε i ω) -
        lineAt univ x (fun j => β₀ + β₁ * x j + ε j ω) (x i)) =
      ∑ j, (fun ω => ((if j = i then (1 : ℝ) else 0) -
        ((1 / n - (x i - avg univ x) / sxx univ x * avg univ x) +
          (x i - avg univ x) / sxx univ x * x j)) * ε j ω) := by
    funext ω
    rw [residual_coeffs x hx β₀ β₁ (fun j => ε j ω) i, Finset.sum_apply]
  rw [hfun, IndepFun.variance_sum]
  · simp only [variance_const_mul, hvar]
    rw [← sum_mul, residual_coeffs_sq x hx i]
    ring
  · intro j _
    exact (hL2 j).const_mul _
  · intro j _ k _ hjk
    exact (hind.indepFun hjk).comp (measurable_const_mul _) (measurable_const_mul _)

end Diagnostics

-- The card's nine sales: areas 80, 100, 110, 120, 140, 150, 170, 190, 600 square metres,
-- prices 350, 390, 450, 440, 530, 540, 610, 650, 1400 thousand dollars.
example : (80 + 100 + 110 + 120 + 140 + 150 + 170 + 190 + 600 : ℕ) = 1660 ∧
    (350 + 390 + 450 + 440 + 530 + 540 + 610 + 650 + 1400 : ℕ) = 5360 := by decide
-- Average area 1660/9 (the card's 184.44); S_xx = Σ x² − (Σ x)²/9 = 1834400/9 (203,822.22).
example : (80 ^ 2 + 100 ^ 2 + 110 ^ 2 + 120 ^ 2 + 140 ^ 2 + 150 ^ 2 + 170 ^ 2 + 190 ^ 2 + 600 ^ 2 : ℕ)
    = 510000 := by decide
example : (510000 : ℚ) - 1660 ^ 2 / 9 = 1834400 / 9 := by norm_num
-- The mansion's leverage: 1/9 + (600 − 1660/9)² / (1834400/9) = 4395/4586 (the card's 0.9584).
example : (1 : ℚ) / 9 + (600 - 1660 / 9) ^ 2 / (1834400 / 9) = 4395 / 4586 := by norm_num
-- Slope of the nine-sale line: (Σ xy − Σx Σy / 9) / S_xx = 36277/18344 (the card's 1.9776).
example : (80 * 350 + 100 * 390 + 110 * 450 + 120 * 440 + 140 * 530 + 150 * 540 + 170 * 610 +
    190 * 650 + 600 * 1400 : ℕ) = 1391700 := by decide
example : ((1391700 : ℚ) - 1660 * 5360 / 9) / (1834400 / 9) = 36277 / 18344 := by norm_num
-- The mansion's residual: 1400 − (5360/9 + slope × (600 − 1660/9)) = −79595/4586 (the card's −17.4).
example : (1400 : ℚ) - (5360 / 9 + 36277 / 18344 * (600 - 1660 / 9)) = -79595 / 4586 := by norm_num
-- The eight-house line: average area 1060/8, average price 3960/8, S_xx = 150000 − 1060²/8 = 9550,
-- slope (551700 − 1060 × 3960/8) / 9550 = 540/191 (the card's 2.8272).
example : (150000 : ℚ) - 1060 ^ 2 / 8 = 9550 := by norm_num
example : ((551700 : ℚ) - 1060 * 3960 / 8) / 9550 = 540 / 191 := by norm_num
-- It prices the mansion at 346995/191 (the card's 1,816.7).
example : (3960 : ℚ) / 8 + 540 / 191 * (600 - 1060 / 8) = 346995 / 191 := by norm_num
-- Step 3 on the mansion, exactly: 1400 − 346995/191 = (−79595/4586) / (1 − 4395/4586) = −79595/191
-- (the card's −416.7 = −17.4 / 0.0416).
example : (1400 : ℚ) - 346995 / 191 = (-79595 / 4586) / (1 - 4395 / 4586) ∧
    (1400 : ℚ) - 346995 / 191 = -79595 / 191 := by norm_num
-- Flag line for leverage, 2p/n = 4/9 (the card's 0.444); the mansion's 4395/4586 is above it.
example : (4 : ℚ) / 9 < 4395 / 4586 := by norm_num

open Diagnostics

#print axioms deleted_residual_eq_residual_div_one_sub_leverage
#print axioms cooks_distance_eq_from_one_fit
#print axioms variance_residual_eq_mul_one_sub_leverage
#print axioms sum_erase_univ
#print axioms card_erase_univ
#print axioms slope_num_eq
#print axioms sxx_eq
#print axioms sxx_pos
#print axioms setup_facts
#print axioms one_sub_leverage_eq
#print axioms one_sub_leverage_pos
#print axioms lineAt_sub
#print axioms sum_affine_sq
#print axioms cook_core
#print axioms residual_coeffs
#print axioms residual_coeffs_sq
