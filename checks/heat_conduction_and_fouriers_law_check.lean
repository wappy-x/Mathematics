-- Fourier's law: in a settled layered wall where each layer obeys q = -k dT/dx with one common flux q, the temperature falls in a straight line inside each layer and the flux equals the temperature difference over the sum of the film and layer resistances.
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

open Set

/-- Helper: the joints of the wall are in order. -/
theorem heat_x_mono (n : ℕ) (x : ℕ → ℝ) (hx : ∀ i < n, x i < x (i + 1)) :
    ∀ i j, i ≤ j → j ≤ n → x i ≤ x j := by
  intro i j hij hjn
  induction j, hij using Nat.le_induction with
  | base => exact le_rfl
  | succ m him ih =>
    exact le_trans (ih (by omega)) (hx m (by omega)).le

/-- Helper: the straight-line law inside one layer (mean value theorem). -/
theorem heat_layer_line (a b k q : ℝ) (T : ℝ → ℝ) (hab : a < b) (hk : 0 < k)
    (hcont : ContinuousOn T (Icc a b))
    (hfourier : ∀ y ∈ Ioo a b, DifferentiableAt ℝ T y ∧ q = -k * deriv T y) :
    ∀ y ∈ Icc a b, T y = T a - q * (y - a) / k := by
  intro y hy
  rcases eq_or_lt_of_le hy.1 with h | h
  · subst h; simp
  · obtain ⟨c, hc, hd⟩ := exists_deriv_eq_slope T h
      (hcont.mono (Icc_subset_Icc le_rfl hy.2))
      (fun z hz => (hfourier z ⟨hz.1, lt_of_lt_of_le hz.2 hy.2⟩).1.differentiableWithinAt)
    have hq := (hfourier c ⟨hc.1, lt_of_lt_of_le hc.2 hy.2⟩).2
    rw [hd] at hq
    have hya : y - a ≠ 0 := by linarith
    have hk' : k ≠ 0 := hk.ne'
    rw [hq]
    field_simp
    ring

/-- Helper: the drop across layer `i` is the flux times the layer's resistance. -/
theorem heat_layer_drop (n : ℕ) (x k : ℕ → ℝ) (T : ℝ → ℝ) (q : ℝ)
    (hx : ∀ i < n, x i < x (i + 1)) (hk : ∀ i < n, 0 < k i)
    (hcont : ContinuousOn T (Icc (x 0) (x n)))
    (hfourier : ∀ i < n, ∀ y ∈ Ioo (x i) (x (i + 1)),
      DifferentiableAt ℝ T y ∧ q = -k i * deriv T y)
    (i : ℕ) (hi : i < n) :
    T (x i) - T (x (i + 1)) = q * ((x (i + 1) - x i) / k i) := by
  have h0 := heat_x_mono n x hx 0 i (Nat.zero_le _) hi.le
  have h1 := heat_x_mono n x hx (i + 1) n hi le_rfl
  have hl := heat_layer_line (x i) (x (i + 1)) (k i) q T (hx i hi) (hk i hi)
    (hcont.mono (Icc_subset_Icc h0 h1)) (hfourier i hi) (x (i + 1))
    ⟨(hx i hi).le, le_rfl⟩
  rw [hl]
  have hk' : k i ≠ 0 := (hk i hi).ne'
  field_simp
  ring

/-- Helper: the whole wall's drop is the flux times the sum of layer resistances. -/
theorem heat_wall_drop (n : ℕ) (x k : ℕ → ℝ) (T : ℝ → ℝ) (q : ℝ)
    (hx : ∀ i < n, x i < x (i + 1)) (hk : ∀ i < n, 0 < k i)
    (hcont : ContinuousOn T (Icc (x 0) (x n)))
    (hfourier : ∀ i < n, ∀ y ∈ Ioo (x i) (x (i + 1)),
      DifferentiableAt ℝ T y ∧ q = -k i * deriv T y) :
    T (x 0) - T (x n) = q * ∑ i ∈ Finset.range n, (x (i + 1) - x i) / k i := by
  have key : ∀ m ≤ n, T (x 0) - T (x m) = q * ∑ i ∈ Finset.range m, (x (i + 1) - x i) / k i := by
    intro m hm
    induction m with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_range_succ, mul_add, ← ih (by omega),
        ← heat_layer_drop n x k T q hx hk hcont hfourier m (by omega)]
      ring
  exact key n le_rfl

/-- Helper: the sum of layer resistances is positive. -/
theorem heat_sum_pos (n : ℕ) (hn : 0 < n) (x k : ℕ → ℝ)
    (hx : ∀ i < n, x i < x (i + 1)) (hk : ∀ i < n, 0 < k i) :
    0 < ∑ i ∈ Finset.range n, (x (i + 1) - x i) / k i := by
  apply Finset.sum_pos
  · intro i hi
    have hi' := Finset.mem_range.mp hi
    exact div_pos (by linarith [hx i hi']) (hk i hi')
  · exact ⟨0, Finset.mem_range.mpr hn⟩

#print axioms heat_x_mono
#print axioms heat_layer_line
#print axioms heat_layer_drop
#print axioms heat_wall_drop
#print axioms heat_sum_pos

/-- Through layers in series, the steady heat flux is the temperature difference over the total
resistance. The wall has `n ≥ 1` layers; layer `i` runs from `x i` to `x (i+1)` and has constant
conductivity `k i > 0`. The temperature `T` is continuous across the whole wall (so it matches at
each joint). In steady state one flux `q` crosses every plane, and inside each layer Fourier's law
`q = -k i * T'` holds. The air films on the two faces have resistances `R_si, R_se ≥ 0`:
the heat crossing a film is its temperature difference over its resistance. Then
`q = (T_in - T_out) / (R_si + ∑ (x (i+1) - x i) / k i + R_se)`. -/
theorem series_resistances_give_flux (n : ℕ) (hn : 0 < n) (x k : ℕ → ℝ) (T : ℝ → ℝ)
    (q T_in T_out R_si R_se : ℝ)
    (hx : ∀ i < n, x i < x (i + 1)) (hk : ∀ i < n, 0 < k i)
    (hRsi : 0 ≤ R_si) (hRse : 0 ≤ R_se)
    (hcont : ContinuousOn T (Icc (x 0) (x n)))
    (hfourier : ∀ i < n, ∀ y ∈ Ioo (x i) (x (i + 1)),
      DifferentiableAt ℝ T y ∧ q = -k i * deriv T y)
    (hin : T_in - T (x 0) = q * R_si) (hout : T (x n) - T_out = q * R_se) :
    q = (T_in - T_out) / (R_si + ∑ i ∈ Finset.range n, (x (i + 1) - x i) / k i + R_se) := by
  have hw := heat_wall_drop n x k T q hx hk hcont hfourier
  have hs := heat_sum_pos n hn x k hx hk
  have hR : 0 < R_si + ∑ i ∈ Finset.range n, (x (i + 1) - x i) / k i + R_se := by linarith
  rw [eq_div_iff hR.ne']
  linarith

/-- Inside one layer of constant conductivity `k > 0`, with one flux `q` crossing it
(`q = -k * T'` everywhere inside), the temperature is a straight line falling at slope `q / k`:
`T y = T a - q * (y - a) / k` for every `y` in the layer. So the drop across a layer of thickness
`d = b - a` is `q * (d / k)`, the flux times the layer's resistance. -/
theorem layer_temperature_is_straight_line (a b k q : ℝ) (T : ℝ → ℝ) (hab : a < b) (hk : 0 < k)
    (hcont : ContinuousOn T (Icc a b))
    (hfourier : ∀ y ∈ Ioo a b, DifferentiableAt ℝ T y ∧ q = -k * deriv T y) :
    ∀ y ∈ Icc a b, T y = T a - q * (y - a) / k := by
  exact heat_layer_line a b k q T hab hk hcont hfourier

/-- In the same settled series wall, each layer's share of the whole temperature difference is its
resistance over the total resistance: the drop across layer `j` is
`(T_in - T_out) * ((x (j+1) - x j) / k j) / (R_si + ∑ R_i + R_se)`. So the layer with the biggest
resistance takes the biggest share of the drop. -/
theorem layer_drop_is_share_of_resistance (n : ℕ) (hn : 0 < n) (x k : ℕ → ℝ) (T : ℝ → ℝ)
    (q T_in T_out R_si R_se : ℝ)
    (hx : ∀ i < n, x i < x (i + 1)) (hk : ∀ i < n, 0 < k i)
    (hRsi : 0 ≤ R_si) (hRse : 0 ≤ R_se)
    (hcont : ContinuousOn T (Icc (x 0) (x n)))
    (hfourier : ∀ i < n, ∀ y ∈ Ioo (x i) (x (i + 1)),
      DifferentiableAt ℝ T y ∧ q = -k i * deriv T y)
    (hin : T_in - T (x 0) = q * R_si) (hout : T (x n) - T_out = q * R_se)
    (j : ℕ) (hj : j < n) :
    T (x j) - T (x (j + 1)) = (T_in - T_out) * ((x (j + 1) - x j) / k j) /
      (R_si + ∑ i ∈ Finset.range n, (x (i + 1) - x i) / k i + R_se) := by
  rw [heat_layer_drop n x k T q hx hk hcont hfourier j hj, mul_div_right_comm,
    ← series_resistances_give_flux n hn x k T q T_in T_out R_si R_se hx hk hRsi hRse hcont
      hfourier hin hout]

/-! The card's wall, in exact fractions: films 13/100 and 4/100 m² K/W; plaster 15 mm at k = 40/100,
block 85 mm at k = 15/100, mineral wool 100 mm at k = 35/1000, brick 100 mm at k = 77/100. -/

-- Plaster resistance: 0.015 ÷ 0.40 is exactly 0.0375 = 3/80 m² K/W.
example : ((15 : ℚ) / 1000) / (40 / 100) = 3 / 80 := by norm_num

-- Total resistance with films, exactly; the card rounds it to 3.7612 m² K/W.
example : (13 : ℚ) / 100 + (15 / 1000) / (40 / 100) + (85 / 1000) / (15 / 100)
    + (100 / 1000) / (35 / 1000) + (100 / 1000) / (77 / 100) + 4 / 100 = 347533 / 92400 := by
  norm_num

example : (75223 : ℚ) / 20000 ≤ 347533 / 92400 ∧ (347533 : ℚ) / 92400 < 75225 / 20000 := by
  norm_num

-- Flux 20 ÷ R rounds to 5.3175 W/m²; through 10 m² it rounds to 53.17 W.
example : (106349 : ℚ) / 20000 ≤ 20 / (347533 / 92400) ∧
    (20 : ℚ) / (347533 / 92400) < 106351 / 20000 := by norm_num

example : (10633 : ℚ) / 200 ≤ 20 / (347533 / 92400) * 10 ∧
    (20 : ℚ) / (347533 / 92400) * 10 < 10635 / 200 := by norm_num

-- Drop across the mineral wool, flux times its resistance 100/35: rounds to 15.193 K.
example : (30385 : ℚ) / 2000 ≤ 20 / (347533 / 92400) * (100 / 35) ∧
    (20 : ℚ) / (347533 / 92400) * (100 / 35) < 30387 / 2000 := by norm_num

#print axioms series_resistances_give_flux
#print axioms layer_temperature_is_straight_line
#print axioms layer_drop_is_share_of_resistance
