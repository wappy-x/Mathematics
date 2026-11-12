-- Subgradients: for a convex function of one variable the subgradients at an inside point are exactly the slopes from the left slope to the right slope, a point is a minimum exactly when 0 is a subgradient, and for a maximum of lines the subgradients run from the smallest to the largest active slope.
import Mathlib.Analysis.Convex.Deriv
import Mathlib.Order.ConditionallyCompleteLattice.Finset

open Set

/-- The subdifferential of `f` at `x`, with `f` taken on the allowed range `S` only:
every slope `g` such that the line through `(x, f x)` with slope `g` stays on or below
the graph at every point `y` of `S`. -/
def subdifferential (f : ℝ → ℝ) (S : Set ℝ) (x : ℝ) : Set ℝ :=
  {g | ∀ y ∈ S, f x + g * (y - x) ≤ f y}

/-- For a function that is convex on its range, at a point strictly inside the range,
the subgradients are exactly the numbers from the slope just to the left
(the left derivative) to the slope just to the right (the right derivative). -/
theorem subdifferential_eq_icc_left_right_slopes {S : Set ℝ} {f : ℝ → ℝ} {x : ℝ}
    (hf : ConvexOn ℝ S f) (hx : x ∈ interior S) :
    subdifferential f S x = Icc (derivWithin f (Iio x) x) (derivWithin f (Ioi x) x) := by
  ext g
  simp only [subdifferential, mem_ofPred_eq, mem_Icc]
  have hxS : x ∈ S := interior_subset hx
  obtain ⟨l, u, hxlu, hlu⟩ :=
    mem_nhds_iff_exists_Ioo_subset.mp (mem_interior_iff_mem_nhds.mp hx)
  rw [hf.rightDeriv_eq_sInf_slope_of_mem_interior hx,
    hf.leftDeriv_eq_sSup_slope_of_mem_interior hx]
  constructor
  · intro h
    constructor
    · refine csSup_le ⟨slope f x ((l + x) / 2), (l + x) / 2,
        ⟨hlu ⟨by linarith [hxlu.1, hxlu.2], by linarith [hxlu.1, hxlu.2]⟩, by linarith [hxlu.1, hxlu.2]⟩, rfl⟩ ?_
      rintro _ ⟨y, ⟨hyS, hyx⟩, rfl⟩
      have := h y hyS
      rw [slope_def_field, div_le_iff_of_neg (by linarith)]
      linarith
    · refine le_csInf ⟨slope f x ((x + u) / 2), (x + u) / 2,
        ⟨hlu ⟨by linarith [hxlu.1, hxlu.2], by linarith [hxlu.1, hxlu.2]⟩, by linarith [hxlu.1, hxlu.2]⟩, rfl⟩ ?_
      rintro _ ⟨y, ⟨hyS, hxy⟩, rfl⟩
      have := h y hyS
      rw [slope_def_field, le_div_iff₀ (by linarith)]
      linarith
  · rintro ⟨hL, hR⟩ y hyS
    rw [← hf.rightDeriv_eq_sInf_slope_of_mem_interior hx] at hR
    rw [← hf.leftDeriv_eq_sSup_slope_of_mem_interior hx] at hL
    rcases lt_trichotomy y x with hyx | rfl | hxy
    · have h1 := hf.slope_le_leftDeriv_of_mem_interior hyS hx hyx
      rw [slope_def_field, div_le_iff₀ (by linarith)] at h1
      nlinarith
    · simp
    · have h1 := hf.rightDeriv_le_slope_of_mem_interior hx hyS hxy
      rw [slope_def_field, le_div_iff₀ (by linarith)] at h1
      nlinarith

/-- The zero-subgradient rule: a point is a lowest point of `f` on the range `S`
exactly when 0 is a subgradient there, that is, when a flat line through it fits under the graph. -/
theorem is_min_on_iff_zero_mem_subdifferential {S : Set ℝ} {f : ℝ → ℝ} {x : ℝ} :
    IsMinOn f S x ↔ (0 : ℝ) ∈ subdifferential f S x := by
  simp only [subdifferential, mem_ofPred_eq, zero_mul, add_zero, IsMinOn, IsMinFilter,
    Filter.eventually_principal]

/-- The rule for a maximum of finitely many lines `f t = max_i (a_i t + b_i)`: at `x` the
subgradients run from the smallest to the largest slope among the active lines,
the lines that reach the top at `x`. -/
theorem subdifferential_max_of_lines {ι : Type*} [Finite ι] [Nonempty ι] (a b : ι → ℝ) (x : ℝ) :
    subdifferential (fun t => ⨆ i, a i * t + b i) univ x =
      Icc (sInf (a '' {i | a i * x + b i = ⨆ j, a j * x + b j}))
          (sSup (a '' {i | a i * x + b i = ⨆ j, a j * x + b j})) := by
  have hle : ∀ t i, a i * t + b i ≤ ⨆ j, a j * t + b j :=
    fun t i => le_ciSup (f := fun j => a j * t + b j) (Finite.bddAbove_range _) i
  set A := {i | a i * x + b i = ⨆ j, a j * x + b j} with hA
  have hAne : A.Nonempty := by
    obtain ⟨i, hi⟩ := exists_eq_ciSup_of_finite (f := fun j => a j * x + b j)
    exact ⟨i, hi⟩
  have hfin : (a '' A).Finite := (Set.toFinite A).image a
  have hne : (a '' A).Nonempty := hAne.image a
  obtain ⟨i1, hi1A, hi1⟩ := hne.csSup_mem hfin
  obtain ⟨i0, hi0A, hi0⟩ := hne.csInf_mem hfin
  have hmax : ∀ i ∈ A, a i ≤ sSup (a '' A) := fun i hi => le_csSup hfin.bddAbove ⟨i, hi, rfl⟩
  have hmin : ∀ i ∈ A, sInf (a '' A) ≤ a i := fun i hi => csInf_le hfin.bddBelow ⟨i, hi, rfl⟩
  have hcont : ∀ i, Continuous fun y : ℝ => a i * y + b i := fun i => by fun_prop
  ext g
  have hcont' : Continuous fun y : ℝ => (⨆ j, a j * x + b j) + g * (y - x) := by fun_prop
  simp only [subdifferential, mem_ofPred_eq, mem_univ, true_imp_iff, mem_Icc]
  constructor
  · intro h
    by_contra hcon
    rw [not_and_or, not_le, not_le] at hcon
    rcases hcon with hlt | hlt
    · have hev : ∀ i, ∀ᶠ y in nhdsWithin x (Iio x),
          a i * y + b i < (⨆ j, a j * x + b j) + g * (y - x) := by
        intro i
        by_cases hi : i ∈ A
        · filter_upwards [self_mem_nhdsWithin] with y hy
          have e : a i * x + b i = ⨆ j, a j * x + b j := hi
          have hai := hmin i hi
          have hy' : y - x < 0 := by rw [mem_Iio] at hy; linarith
          nlinarith
        · have hlt' : a i * x + b i < ⨆ j, a j * x + b j := lt_of_le_of_ne (hle x i) hi
          exact Filter.Tendsto.eventually_lt
            (((hcont i).tendsto x).mono_left nhdsWithin_le_nhds)
            ((hcont'.tendsto x).mono_left nhdsWithin_le_nhds) (by simpa using hlt')
      obtain ⟨y, hy⟩ := (Filter.eventually_all.2 hev).exists
      obtain ⟨k, hk⟩ := exists_eq_ciSup_of_finite (f := fun j => a j * y + b j)
      have h1 := h y
      have h2 := hy k
      linarith
    · have hev : ∀ i, ∀ᶠ y in nhdsWithin x (Ioi x),
          a i * y + b i < (⨆ j, a j * x + b j) + g * (y - x) := by
        intro i
        by_cases hi : i ∈ A
        · filter_upwards [self_mem_nhdsWithin] with y hy
          have e : a i * x + b i = ⨆ j, a j * x + b j := hi
          have hai := hmax i hi
          have hy' : 0 < y - x := by rw [mem_Ioi] at hy; linarith
          nlinarith
        · have hlt' : a i * x + b i < ⨆ j, a j * x + b j := lt_of_le_of_ne (hle x i) hi
          exact Filter.Tendsto.eventually_lt
            (((hcont i).tendsto x).mono_left nhdsWithin_le_nhds)
            ((hcont'.tendsto x).mono_left nhdsWithin_le_nhds) (by simpa using hlt')
      obtain ⟨y, hy⟩ := (Filter.eventually_all.2 hev).exists
      obtain ⟨k, hk⟩ := exists_eq_ciSup_of_finite (f := fun j => a j * y + b j)
      have h1 := h y
      have h2 := hy k
      linarith
  · rintro ⟨h0, h1⟩ y
    rcases le_total y x with hyx | hxy
    · have e : a i0 * x + b i0 = ⨆ j, a j * x + b j := hi0A
      have := hle y i0
      rw [← hi0] at h0
      nlinarith
    · have e : a i1 * x + b i1 = ⨆ j, a j * x + b j := hi1A
      have := hle y i1
      rw [← hi1] at h1
      nlinarith

-- The card's worked numbers, in whole pounds and kilos.
-- The three price lines at 40 kg read 360, 360 and 180.
example : (9 * 40 : ℤ) = 360 ∧ (14 * 40 - 200 : ℤ) = 360 ∧ (20 * 40 - 620 : ℤ) = 180 := by norm_num
-- The Kenyan bill C(q) = max(9q, 14q - 200, 20q - 620) at 0, 40, 70 and 100 kg.
example : max (max (9 * 0) (14 * 0 - 200)) (20 * 0 - 620) = (0 : ℤ) ∧
    max (max (9 * 40) (14 * 40 - 200)) (20 * 40 - 620) = (360 : ℤ) ∧
    max (max (9 * 70) (14 * 70 - 200)) (20 * 70 - 620) = (780 : ℤ) ∧
    max (max (9 * 100) (14 * 100 - 200)) (20 * 100 - 620) = (1380 : ℤ) := by norm_num
-- The net bill F(q) = C(q) + 12 (100 - q) at 0, 40, 70 and 100 kg, and at 38 kg.
example : (0 + 12 * (100 - 0) : ℤ) = 1200 ∧ (360 + 12 * (100 - 40) : ℤ) = 1080 ∧
    (780 + 12 * (100 - 70) : ℤ) = 1140 ∧ (1380 + 12 * (100 - 100) : ℤ) = 1380 ∧
    (9 * 38 + 12 * (100 - 38) : ℤ) = 1086 := by norm_num
-- The net slopes at 40 kg: [9 - 12, 14 - 12] = [-3, 2], which contains 0.
example : (9 - 12 : ℤ) = -3 ∧ (14 - 12 : ℤ) = 2 ∧ (-3 : ℤ) ≤ 0 ∧ (0 : ℤ) ≤ 2 := by norm_num
-- Brazilian at £18: 40 kg costs £1,440 but 70 kg costs £1,320.
example : (360 + 18 * (100 - 40) : ℤ) = 1440 ∧ (780 + 18 * (100 - 70) : ℤ) = 1320 := by norm_num
-- Discount tier min(14q, 9q + 200): 40 kg costs £1,280, 100 kg costs £1,100.
example : min (14 * 40) (9 * 40 + 200) + 12 * (100 - 40) = (1280 : ℤ) ∧
    min (14 * 100) (9 * 100 + 200) + 12 * (100 - 100) = (1100 : ℤ) := by norm_num
-- Brazilian at £15: 70 kg costs £1,230; at £8: 0 kg costs £800.
example : (780 + 15 * (100 - 70) : ℤ) = 1230 ∧ (0 + 8 * (100 - 0) : ℤ) = 800 := by norm_num

#print axioms subdifferential_eq_icc_left_right_slopes
#print axioms is_min_on_iff_zero_mem_subdifferential
#print axioms subdifferential_max_of_lines
