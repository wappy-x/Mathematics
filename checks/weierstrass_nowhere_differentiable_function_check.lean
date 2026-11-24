-- Weierstrass's monster: the sum of the sawtooth layers (3/4)^n φ(4^n x) is continuous at every point and has a derivative at none, its chord slopes at 0 are (3^m - 1)/2, and at every point a step of ±(1/4)·4^(-m) gives a chord slope of size at least (3^m + 1)/2.
import Mathlib.Algebra.Order.Round
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Normed.Group.FunctionSeries
import Mathlib.Algebra.Field.GeomSum

/-! ### How the card's objects are written here

The sawtooth φ(t), the distance from `t` to the nearest whole number, is `|t - round t|`
(Mathlib's `abs_sub_round_eq_min` shows this is `min (fract t) (1 - fract t)`).

The monster is `f x = ∑ (3/4)^n φ(4^n x)` over `n = 0, 1, 2, …`, written with Mathlib's
infinite sum `∑'`. A step of `4^(-m)` is written `((4:ℝ) ^ m)⁻¹`. -/

/-- The sawtooth: the distance from `t` to the nearest whole number. -/
noncomputable def sawtooth (t : ℝ) : ℝ := |t - round t|

/-- Weierstrass's monster in Rudin's sawtooth form: `f x = ∑_{n ≥ 0} (3/4)^n φ(4^n x)`. -/
noncomputable def monster (x : ℝ) : ℝ := ∑' n : ℕ, (3 / 4 : ℝ) ^ n * sawtooth ((4 : ℝ) ^ n * x)

/-! ### Helper lemmas -/

lemma sawtooth_nonneg (t : ℝ) : 0 ≤ sawtooth t := abs_nonneg _

lemma sawtooth_le_half (t : ℝ) : sawtooth t ≤ 1 / 2 := abs_sub_round t

lemma sawtooth_add_int (t : ℝ) (z : ℤ) : sawtooth (t + z) = sawtooth t := by
  unfold sawtooth
  rw [round_add_intCast]
  push_cast
  ring_nf

lemma sawtooth_sub_int (t : ℝ) (z : ℤ) : sawtooth (t - z) = sawtooth t := by
  unfold sawtooth
  rw [round_sub_intCast]
  push_cast
  ring_nf

lemma sawtooth_lipschitz (s t : ℝ) : sawtooth s - sawtooth t ≤ |s - t| := by
  unfold sawtooth
  have h1 := round_le s (round t)
  have h2 : |s - (round t : ℝ)| ≤ |s - t| + |t - round t| := by
    have := abs_sub_le s t (round t : ℝ)
    linarith
  linarith

lemma sawtooth_continuous : Continuous sawtooth := by
  have : LipschitzWith 1 sawtooth := by
    apply LipschitzWith.of_dist_le_mul
    intro s t
    rw [Real.dist_eq, Real.dist_eq, NNReal.coe_one, one_mul]
    rw [abs_le]
    constructor
    · have := sawtooth_lipschitz t s
      rw [abs_sub_comm] at this
      linarith
    · exact sawtooth_lipschitz s t
  exact this.continuous

lemma sawtooth_eq_of_near (t : ℝ) (c : ℤ) (h : |t - c| ≤ 1 / 2) : sawtooth t = |t - c| := by
  unfold sawtooth
  apply le_antisymm (round_le t c)
  by_cases hc : round t = c
  · rw [hc]
  · have h1 : (1 : ℝ) ≤ |(round t : ℝ) - c| := by
      have : (1 : ℤ) ≤ |round t - c| := Int.one_le_abs (sub_ne_zero.mpr hc)
      exact_mod_cast this
    have h2 : |(round t : ℝ) - c| ≤ |(round t : ℝ) - t| + |t - c| := abs_sub_le _ _ _
    rw [abs_sub_comm (round t : ℝ) t] at h2
    linarith

lemma sawtooth_piece (a b : ℝ) (j : ℤ) (ha1 : (j : ℝ) / 2 ≤ a) (ha2 : a ≤ ((j : ℝ) + 1) / 2)
    (hb1 : (j : ℝ) / 2 ≤ b) (hb2 : b ≤ ((j : ℝ) + 1) / 2) :
    |sawtooth b - sawtooth a| = |b - a| := by
  rcases Int.even_or_odd' j with ⟨i, rfl | rfl⟩
  · push_cast at ha1 ha2 hb1 hb2
    have ea : sawtooth a = a - i := by
      rw [sawtooth_eq_of_near a i (by rw [abs_le]; constructor <;> linarith)]
      rw [abs_of_nonneg (by linarith)]
    have eb : sawtooth b = b - i := by
      rw [sawtooth_eq_of_near b i (by rw [abs_le]; constructor <;> linarith)]
      rw [abs_of_nonneg (by linarith)]
    rw [ea, eb]; ring_nf
  · push_cast at ha1 ha2 hb1 hb2
    have ea : sawtooth a = (i + 1) - a := by
      rw [sawtooth_eq_of_near a (i + 1) (by push_cast; rw [abs_le]; constructor <;> linarith)]
      push_cast
      rw [abs_of_nonpos (by linarith)]; ring
    have eb : sawtooth b = (i + 1) - b := by
      rw [sawtooth_eq_of_near b (i + 1) (by push_cast; rw [abs_le]; constructor <;> linarith)]
      push_cast
      rw [abs_of_nonpos (by linarith)]; ring
    rw [ea, eb, abs_sub_comm b a]; ring_nf

/-- Both points lie in one half-unit piece `[j/2, (j+1)/2]`. -/
def SamePiece (a b : ℝ) : Prop :=
  ∃ j : ℤ, (j : ℝ) / 2 ≤ a ∧ a ≤ ((j : ℝ) + 1) / 2 ∧ (j : ℝ) / 2 ≤ b ∧ b ≤ ((j : ℝ) + 1) / 2

lemma samePiece_div_four (a b : ℝ) (h : SamePiece (4 * a) (4 * b)) : SamePiece a b := by
  obtain ⟨k, h1, h2, h3, h4⟩ := h
  refine ⟨k / 4, ?_⟩
  have e1 : ((k / 4 : ℤ) : ℝ) * 4 ≤ k := by
    have : k / 4 * 4 ≤ k := Int.ediv_mul_le k (by norm_num)
    exact_mod_cast this
  have e2 : (k : ℝ) + 1 ≤ ((k / 4 : ℤ) : ℝ) * 4 + 4 := by
    have : k < (k / 4 + 1) * 4 := by omega
    have : k + 1 ≤ k / 4 * 4 + 4 := by linarith
    exact_mod_cast this
  refine ⟨by linarith, by linarith, by linarith, by linarith⟩

lemma samePiece_descend (a b : ℝ) (i : ℕ) (h : SamePiece ((4 : ℝ) ^ i * a) ((4 : ℝ) ^ i * b)) :
    SamePiece a b := by
  induction i generalizing a b with
  | zero => simpa using h
  | succ i ih =>
    apply ih
    apply samePiece_div_four
    rw [pow_succ] at h
    convert h using 1 <;> ring

lemma four_pow_mul_inv_int (n m : ℕ) (h : m + 1 ≤ n) :
    ∃ z : ℤ, (4 : ℝ) ^ n * ((4 : ℝ) ^ (m + 1))⁻¹ = z := by
  refine ⟨4 ^ (n - (m + 1)), ?_⟩
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le h
  rw [Nat.add_sub_cancel_left]
  push_cast
  rw [pow_add]
  field_simp

lemma summable_layers (x : ℝ) :
    Summable (fun n : ℕ => (3 / 4 : ℝ) ^ n * sawtooth ((4 : ℝ) ^ n * x)) := by
  apply Summable.of_nonneg_of_le
  · intro n; exact mul_nonneg (by positivity) (sawtooth_nonneg _)
  · intro n
    have := sawtooth_le_half ((4 : ℝ) ^ n * x)
    have hp : (0 : ℝ) ≤ (3 / 4) ^ n := by positivity
    calc (3 / 4 : ℝ) ^ n * sawtooth ((4 : ℝ) ^ n * x) ≤ (3 / 4) ^ n * 1 :=
          mul_le_mul_of_nonneg_left (by linarith) hp
      _ = (3 / 4) ^ n := mul_one _
  · exact summable_geometric_of_lt_one (by norm_num) (by norm_num)

lemma monster_sub (x y : ℝ) : monster y - monster x =
    ∑' n : ℕ, (3 / 4 : ℝ) ^ n * (sawtooth ((4 : ℝ) ^ n * y) - sawtooth ((4 : ℝ) ^ n * x)) := by
  unfold monster
  rw [← (summable_layers y).tsum_sub (summable_layers x)]
  congr 1; ext n; ring

lemma geom_three (m : ℕ) : ∑ n ∈ Finset.range m, (3 : ℝ) ^ n = ((3 : ℝ) ^ m - 1) / 2 := by
  rw [geom_sum_eq (by norm_num : (3 : ℝ) ≠ 1)]
  norm_num

lemma chord_floor_core (x δ : ℝ) (m : ℕ) (hδ : |δ| = ((4 : ℝ) ^ (m + 1))⁻¹)
    (hint : ∀ n, m + 1 ≤ n → ∃ z : ℤ, (4 : ℝ) ^ n * δ = z)
    (hp : SamePiece ((4 : ℝ) ^ m * x) ((4 : ℝ) ^ m * (x + δ))) :
    ((3 : ℝ) ^ m + 1) / 2 ≤ |(monster (x + δ) - monster x) / δ| := by
  have hδpos : 0 < |δ| := by rw [hδ]; positivity
  have hδ0 : δ ≠ 0 := abs_pos.mp hδpos
  set d : ℕ → ℝ := fun n => sawtooth ((4 : ℝ) ^ n * (x + δ)) - sawtooth ((4 : ℝ) ^ n * x) with hd
  have hhigh : ∀ n, m + 1 ≤ n → d n = 0 := by
    intro n hn
    obtain ⟨z, hz⟩ := hint n hn
    simp only [hd]
    rw [mul_add, hz, sawtooth_add_int, sub_self]
  have hlow : ∀ n, n ≤ m → |d n| = (4 : ℝ) ^ n * |δ| := by
    intro n hn
    have hs : SamePiece ((4 : ℝ) ^ n * x) ((4 : ℝ) ^ n * (x + δ)) := by
      apply samePiece_descend _ _ (m - n)
      have e : (4 : ℝ) ^ (m - n) * (4 : ℝ) ^ n = (4 : ℝ) ^ m := by
        rw [← pow_add, Nat.sub_add_cancel hn]
      rw [← mul_assoc, ← mul_assoc, e]
      exact hp
    obtain ⟨j, h1, h2, h3, h4⟩ := hs
    simp only [hd]
    rw [sawtooth_piece _ _ j h1 h2 h3 h4]
    rw [show (4 : ℝ) ^ n * (x + δ) - (4 : ℝ) ^ n * x = (4 : ℝ) ^ n * δ by ring, abs_mul,
      abs_of_pos (by positivity)]
  have hsum : monster (x + δ) - monster x = ∑ n ∈ Finset.range (m + 1), (3 / 4 : ℝ) ^ n * d n := by
    rw [monster_sub]
    apply tsum_eq_sum
    intro n hn
    rw [Finset.mem_range, not_lt] at hn
    show (3 / 4 : ℝ) ^ n * d n = 0
    rw [hhigh n hn, mul_zero]
  set e : ℕ → ℝ := fun n => (3 / 4 : ℝ) ^ n * d n / δ with he
  have habs : ∀ n, n ≤ m → |e n| = (3 : ℝ) ^ n := by
    intro n hn
    simp only [he]
    rw [abs_div, abs_mul, hlow n hn, abs_of_pos (by positivity : (0 : ℝ) < (3 / 4) ^ n)]
    field_simp
    rw [← mul_pow]; norm_num
  have hdiv : (monster (x + δ) - monster x) / δ = ∑ n ∈ Finset.range (m + 1), e n := by
    rw [hsum, div_eq_mul_inv, Finset.sum_mul]; simp only [he, div_eq_mul_inv]
  rw [hdiv, Finset.sum_range_succ]
  have hrest : |∑ n ∈ Finset.range m, e n| ≤ ∑ n ∈ Finset.range m, (3 : ℝ) ^ n := by
    refine (Finset.abs_sum_le_sum_abs _ _).trans (le_of_eq ?_)
    apply Finset.sum_congr rfl
    intro n hn
    rw [Finset.mem_range] at hn
    exact habs n hn.le
  rw [geom_three] at hrest
  have hm := habs m le_rfl
  have tri : |e m| ≤ |∑ n ∈ Finset.range m, e n + e m| + |∑ n ∈ Finset.range m, e n| := by
    have := abs_sub_le (e m) (∑ n ∈ Finset.range m, e n + e m) 0
    simp only [sub_zero] at this
    rw [show e m - (∑ n ∈ Finset.range m, e n + e m) = -(∑ n ∈ Finset.range m, e n) by ring,
      abs_neg] at this
    linarith [abs_nonneg (∑ n ∈ Finset.range m, e n + e m)]
  linarith

lemma chord_floor (x : ℝ) (m : ℕ) :
    ∃ δ : ℝ, (δ = ((4 : ℝ) ^ (m + 1))⁻¹ ∨ δ = -((4 : ℝ) ^ (m + 1))⁻¹) ∧
      ((3 : ℝ) ^ m + 1) / 2 ≤ |(monster (x + δ) - monster x) / δ| := by
  have hq : (4 : ℝ) ^ m * ((4 : ℝ) ^ (m + 1))⁻¹ = 1 / 4 := by
    rw [pow_succ]; field_simp
  have hint : ∀ s : ℝ, (s = 1 ∨ s = -1) → ∀ n, m + 1 ≤ n →
      ∃ z : ℤ, (4 : ℝ) ^ n * (s * ((4 : ℝ) ^ (m + 1))⁻¹) = z := by
    intro s hs n hn
    obtain ⟨z, hz⟩ := four_pow_mul_inv_int n m hn
    rcases hs with rfl | rfl
    · exact ⟨z, by rw [one_mul, hz]⟩
    · exact ⟨-z, by push_cast; rw [← hz]; ring⟩
  set y := (4 : ℝ) ^ m * x with hy
  set j := ⌊2 * y⌋ with hj
  have hj1 : (j : ℝ) ≤ 2 * y := Int.floor_le _
  have hj2 : 2 * y < (j : ℝ) + 1 := Int.lt_floor_add_one _
  by_cases hc : 2 * y - j < 1 / 2
  · refine ⟨((4 : ℝ) ^ (m + 1))⁻¹, Or.inl rfl, ?_⟩
    apply chord_floor_core
    · rw [abs_of_pos (by positivity)]
    · intro n hn
      have := hint 1 (Or.inl rfl) n hn
      simpa using this
    · refine ⟨j, by linarith, by linarith, ?_, ?_⟩
      · rw [mul_add, hq]; linarith
      · rw [mul_add, hq]; linarith
  · refine ⟨-((4 : ℝ) ^ (m + 1))⁻¹, Or.inr rfl, ?_⟩
    apply chord_floor_core
    · rw [abs_neg, abs_of_pos (by positivity)]
    · intro n hn
      have := hint (-1) (Or.inr rfl) n hn
      simpa using this
    · refine ⟨j, by linarith, by linarith, ?_, ?_⟩
      · rw [mul_add, mul_neg, hq]; linarith
      · rw [mul_add, mul_neg, hq]; linarith

lemma monster_zero : monster 0 = 0 := by
  unfold monster
  simp [sawtooth]

lemma chord_zero (m : ℕ) :
    (monster ((4 : ℝ) ^ m)⁻¹ - monster 0) / ((4 : ℝ) ^ m)⁻¹ = ((3 : ℝ) ^ m - 1) / 2 := by
  have hval : monster ((4 : ℝ) ^ m)⁻¹ =
      ∑ n ∈ Finset.range m, (3 / 4 : ℝ) ^ n * ((4 : ℝ) ^ n * ((4 : ℝ) ^ m)⁻¹) := by
    unfold monster
    rw [tsum_eq_sum (s := Finset.range m)]
    · apply Finset.sum_congr rfl
      intro n hn
      rw [Finset.mem_range] at hn
      congr 1
      have hle : (4 : ℝ) ^ n * 4 ≤ (4 : ℝ) ^ m := by
        rw [← pow_succ]; exact pow_le_pow_right₀ (by norm_num) hn
      have h0 : 0 ≤ (4 : ℝ) ^ n * ((4 : ℝ) ^ m)⁻¹ := by positivity
      have h1 : (4 : ℝ) ^ n * ((4 : ℝ) ^ m)⁻¹ ≤ 1 / 2 := by
        have : (0 : ℝ) < (4 : ℝ) ^ n := by positivity
        rw [mul_inv_le_iff₀ (by positivity)]; linarith
      rw [sawtooth_eq_of_near _ 0 (by rw [Int.cast_zero, sub_zero, abs_of_nonneg h0]; exact h1)]
      rw [Int.cast_zero, sub_zero, abs_of_nonneg h0]
    · intro n hn
      rw [Finset.mem_range, not_lt] at hn
      obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le hn
      have : (4 : ℝ) ^ (m + k) * ((4 : ℝ) ^ m)⁻¹ = ((4 ^ k : ℤ) : ℝ) := by
        push_cast; rw [pow_add]; field_simp
      rw [this, sawtooth, round_intCast, sub_self, abs_zero, mul_zero]
  have hs : ∑ n ∈ Finset.range m, (3 / 4 : ℝ) ^ n * ((4 : ℝ) ^ n * ((4 : ℝ) ^ m)⁻¹) =
      (∑ n ∈ Finset.range m, (3 : ℝ) ^ n) * ((4 : ℝ) ^ m)⁻¹ := by
    rw [Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro n _
    rw [← mul_assoc, ← mul_pow]; norm_num
  rw [hval, monster_zero, sub_zero, hs, mul_div_assoc, div_self (by positivity), mul_one,
    geom_three]

lemma monster_continuous : Continuous monster := by
  apply continuous_tsum (u := fun n : ℕ => (3 / 4 : ℝ) ^ n)
  · intro n
    exact continuous_const.mul (sawtooth_continuous.comp (continuous_const.mul continuous_id))
  · exact summable_geometric_of_lt_one (by norm_num) (by norm_num)
  · intro n x
    rw [Real.norm_eq_abs, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < (3 / 4) ^ n),
      abs_of_nonneg (sawtooth_nonneg _)]
    have := sawtooth_le_half ((4 : ℝ) ^ n * x)
    have hp : (0 : ℝ) < (3 / 4) ^ n := by positivity
    nlinarith

lemma monster_not_differentiable (x : ℝ) : ¬ DifferentiableAt ℝ monster x := by
  intro hdiff
  have hT := (hasDerivAt_iff_tendsto_slope_zero.mp hdiff.hasDerivAt)
  set f' := deriv monster x
  choose δ hδ hfloor using fun m : ℕ => chord_floor x m
  have habsδ : ∀ m, |δ m| = ((4 : ℝ) ^ (m + 1))⁻¹ := by
    intro m
    rcases hδ m with h | h <;> rw [h]
    · rw [abs_of_pos (by positivity)]
    · rw [abs_neg, abs_of_pos (by positivity)]
  have hδT : Filter.Tendsto δ Filter.atTop (nhdsWithin 0 {0}ᶜ) := by
    rw [tendsto_nhdsWithin_iff]
    constructor
    · rw [tendsto_zero_iff_norm_tendsto_zero]
      simp only [Real.norm_eq_abs, habsδ]
      exact tendsto_inv_atTop_zero.comp ((tendsto_pow_atTop_atTop_of_one_lt
        (by norm_num : (1 : ℝ) < 4)).comp (Filter.tendsto_add_atTop_nat 1))
    · refine Filter.Eventually.of_forall (fun m => ?_)
      show δ m ≠ 0
      intro h0
      have := habsδ m
      rw [h0, abs_zero] at this
      have : (0 : ℝ) < ((4 : ℝ) ^ (m + 1))⁻¹ := by positivity
      linarith
  have hS := (continuous_abs.tendsto f').comp (hT.comp hδT)
  have h1 : ∀ᶠ m in Filter.atTop, |(δ m)⁻¹ • (monster (x + δ m) - monster x)| < |f'| + 1 :=
    hS (gt_mem_nhds (by linarith))
  have h2 : ∀ᶠ m : ℕ in Filter.atTop, 2 * |f'| + 2 ≤ (3 : ℝ) ^ m :=
    (tendsto_pow_atTop_atTop_of_one_lt (by norm_num : (1 : ℝ) < 3)).eventually_ge_atTop _
  obtain ⟨m, hm1, hm2⟩ := (h1.and h2).exists
  have h3 := hfloor m
  rw [smul_eq_mul, ← div_eq_inv_mul] at hm1
  linarith

/-- The card's main claim: the sum of sawtooth layers, each 4 times faster and 3/4 as tall,
is continuous at every point and has a derivative at no point. -/
theorem monster_continuous_and_nowhere_differentiable :
    Continuous monster ∧ ∀ x : ℝ, ¬ DifferentiableAt ℝ monster x := by
  exact ⟨monster_continuous, monster_not_differentiable⟩

/-- Step 2: at `x = 0` with the step `h = 4^(-m)`, the chord slope is
`1 + 3 + ⋯ + 3^(m-1) = (3^m - 1)/2`. -/
theorem monster_chord_slope_at_zero (m : ℕ) :
    (monster ((4 : ℝ) ^ m)⁻¹ - monster 0) / ((4 : ℝ) ^ m)⁻¹ = ((3 : ℝ) ^ m - 1) / 2 := by
  exact chord_zero m

/-- Step 3: at every point `x` and every zoom level `m`, one of the two steps
`δ = ±(1/4)·4^(-m)` gives a chord slope of size at least `(3^m + 1)/2`. -/
theorem monster_chord_slope_floor (x : ℝ) (m : ℕ) :
    ∃ δ : ℝ, (δ = ((4 : ℝ) ^ (m + 1))⁻¹ ∨ δ = -((4 : ℝ) ^ (m + 1))⁻¹) ∧
      ((3 : ℝ) ^ m + 1) / 2 ≤ |(monster (x + δ) - monster x) / δ| := by
  exact chord_floor x m

-- The chord slopes at 0 for m = 1 to 8: (3^m - 1)/2 = 1, 4, 13, 40, 121, 364, 1093, 3280.
example : (List.range 8).map (fun k => (3 ^ (k + 1) - 1) / 2) =
    [1, 4, 13, 40, 121, 364, 1093, 3280] := by decide

-- The proof's floors (3^m + 1)/2 for m = 1 to 8: 2, 5, 14, 41, 122, 365, 1094, 3281.
example : (List.range 8).map (fun k => (3 ^ (k + 1) + 1) / 2) =
    [2, 5, 14, 41, 122, 365, 1094, 3281] := by decide

-- Worked numbers by hand, step 1/64 at 0: layers add 1/64 + 3/64 + 9/64 = 13/64, slope 13.
example : (1 : ℚ) * (1 / 64) + 3 / 4 * (1 / 16) + 9 / 16 * (1 / 4) = 13 / 64 := by norm_num
example : (13 / 64 : ℚ) / (1 / 64) = 13 := by norm_num
example : 1 + 3 + 9 = (3 ^ 3 - 1) / 2 := by decide

-- Only 5 layers: the chord slope at 0 freezes at 1 + 3 + 9 + 27 + 81 = 121.
example : ∑ n ∈ Finset.range 5, 3 ^ n = 121 := by decide

-- The caps 1/2·(3/4)^n add to 2; after N layers 2·(3/4)^N is left, first below 1/1000 at N = 27.
example : 2 * (3 / 4 : ℚ) ^ 27 < 1 / 1000 ∧ 1 / 1000 ≤ 2 * (3 / 4 : ℚ) ^ 26 := by norm_num

-- At x = 1/3 every layer reads 1/3, because 4^n is 1 more than a multiple of 3.
example : ∀ n < 27, 4 ^ n % 3 = 1 := by decide

#print axioms sawtooth_nonneg
#print axioms sawtooth_le_half
#print axioms sawtooth_add_int
#print axioms sawtooth_sub_int
#print axioms sawtooth_lipschitz
#print axioms sawtooth_continuous
#print axioms sawtooth_eq_of_near
#print axioms sawtooth_piece
#print axioms samePiece_div_four
#print axioms samePiece_descend
#print axioms four_pow_mul_inv_int
#print axioms summable_layers
#print axioms monster_sub
#print axioms geom_three
#print axioms chord_floor_core
#print axioms chord_floor
#print axioms monster_zero
#print axioms chord_zero
#print axioms monster_continuous
#print axioms monster_not_differentiable
#print axioms monster_continuous_and_nowhere_differentiable
#print axioms monster_chord_slope_at_zero
#print axioms monster_chord_slope_floor
