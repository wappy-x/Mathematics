-- Quasi-Monte Carlo and sparse grids: the one-dimensional Koksma inequality, the van der Corput discrepancy bound, and the card's whole-number point counts.
import Mathlib.Analysis.BoundedVariation
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Data.Nat.Digits.Lemmas
import Mathlib.Data.Nat.Log

open MeasureTheory

/-- The radical inverse `φ_p(i)`: write `i` in base `p` with digits `a_0, a_1, …`
(counting from the right) and mirror them after the point, `φ_p(i) = ∑ a_r p^(-r-1)`.
With `p = 2` this is the van der Corput sequence; one prime per coordinate gives Halton. -/
def radicalInverse (p i : ℕ) : ℚ :=
  ((Nat.digits p i).zipIdx.map fun ar => (ar.1 : ℚ) / (p : ℚ) ^ (ar.2 + 1)).sum

theorem qmc_zipIdx_sum_succ (l : List ℕ) (i : ℕ) :
    ((l.zipIdx (i + 1)).map fun ar => (ar.1 : ℚ) / (2 : ℚ) ^ (ar.2 + 1)).sum
      = ((l.zipIdx i).map fun ar => (ar.1 : ℚ) / (2 : ℚ) ^ (ar.2 + 1)).sum / 2 := by
  induction l generalizing i with
  | nil => simp
  | cons a l ih =>
    simp only [List.zipIdx_cons, List.map_cons, List.sum_cons]
    rw [ih (i + 1)]
    rw [pow_succ (2:ℚ) (i + 1)]
    field_simp

#print axioms qmc_zipIdx_sum_succ

theorem qmc_radicalInverse_two_rec (n : ℕ) :
    radicalInverse 2 n = (((n % 2 : ℕ) : ℚ) + radicalInverse 2 (n / 2)) / 2 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp [radicalInverse]
  · unfold radicalInverse
    rw [Nat.digits_def' (by norm_num) hn]
    simp only [List.zipIdx_cons, List.map_cons, List.sum_cons, Nat.cast_ofNat, zero_add]
    rw [qmc_zipIdx_sum_succ]
    ring

#print axioms qmc_radicalInverse_two_rec

theorem qmc_radicalInverse_two_mem (n : ℕ) : 0 ≤ radicalInverse 2 n ∧ radicalInverse 2 n < 1 := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp [radicalInverse]
    · obtain ⟨h0, h1⟩ := ih (n / 2) (Nat.div_lt_self hn (by norm_num))
      rw [qmc_radicalInverse_two_rec]
      have : ((n % 2 : ℕ) : ℚ) ≤ 1 := by exact_mod_cast Nat.le_of_lt_succ (Nat.mod_lt n (by norm_num))
      have : (0:ℚ) ≤ ((n % 2 : ℕ) : ℚ) := by positivity
      constructor <;> linarith

#print axioms qmc_radicalInverse_two_mem

theorem qmc_grid_sub (m : ℕ) : ∀ i : ℕ, i < 2 ^ m → ∃ j : ℕ, j < 2 ^ m ∧ radicalInverse 2 i = (j : ℚ) / 2 ^ m := by
  induction m with
  | zero =>
    intro i hi
    refine ⟨0, by simp, ?_⟩
    have : i = 0 := by simp at hi; omega
    subst this; simp [radicalInverse]
  | succ m ih =>
    intro i hi
    obtain ⟨j, hj, hr⟩ := ih (i / 2) (by rw [pow_succ] at hi; omega)
    refine ⟨i % 2 * 2 ^ m + j, ?_, ?_⟩
    · have : i % 2 ≤ 1 := Nat.le_of_lt_succ (Nat.mod_lt i (by norm_num))
      rw [pow_succ]; nlinarith
    · rw [qmc_radicalInverse_two_rec, hr]
      push_cast
      rw [pow_succ]
      field_simp

#print axioms qmc_grid_sub

theorem qmc_grid_sup (m : ℕ) : ∀ j : ℕ, j < 2 ^ m → ∃ i : ℕ, i < 2 ^ m ∧ radicalInverse 2 i = (j : ℚ) / 2 ^ m := by
  induction m with
  | zero =>
    intro j hj
    refine ⟨0, by simp, ?_⟩
    have : j = 0 := by simp at hj; omega
    subst this; simp [radicalInverse]
  | succ m ih =>
    intro j hj
    obtain ⟨i, hi, hr⟩ := ih (j % 2 ^ m) (Nat.mod_lt _ (by positivity))
    have hb : j / 2 ^ m < 2 := by
      rw [Nat.div_lt_iff_lt_mul (by positivity)]; rw [pow_succ] at hj; linarith
    refine ⟨2 * i + j / 2 ^ m, ?_, ?_⟩
    · rw [pow_succ]
      generalize 2 ^ m = P at hi hb ⊢
      omega
    · rw [qmc_radicalInverse_two_rec]
      have e1 : (2 * i + j / 2 ^ m) % 2 = j / 2 ^ m := by
        generalize j / 2 ^ m = b at hb ⊢; omega
      have e2 : (2 * i + j / 2 ^ m) / 2 = i := by
        generalize j / 2 ^ m = b at hb ⊢; omega
      rw [e1, e2, hr]
      have hj' : (j : ℚ) = ((j / 2 ^ m : ℕ) : ℚ) * 2 ^ m + ((j % 2 ^ m : ℕ) : ℚ) := by
        exact_mod_cast (Nat.div_add_mod' j (2 ^ m)).symm
      rw [hj', pow_succ]
      field_simp

#print axioms qmc_grid_sup

theorem qmc_grid_eq (m : ℕ) :
    (Finset.range (2 ^ m)).image (radicalInverse 2) =
      (Finset.range (2 ^ m)).image (fun j : ℕ => (j : ℚ) / 2 ^ m) := by
  ext x
  simp only [Finset.mem_image, Finset.mem_range]
  constructor
  · rintro ⟨i, hi, rfl⟩
    obtain ⟨j, hj, h⟩ := qmc_grid_sub m i hi
    exact ⟨j, hj, h.symm⟩
  · rintro ⟨j, hj, rfl⟩
    exact qmc_grid_sup m j hj

#print axioms qmc_grid_eq

theorem qmc_shift (m : ℕ) : ∀ q i : ℕ, i < 2 ^ m →
    radicalInverse 2 (2 ^ m * q + i) = radicalInverse 2 i + radicalInverse 2 q / 2 ^ m := by
  induction m with
  | zero =>
    intro q i hi
    have : i = 0 := by simp at hi; omega
    subst this; simp [radicalInverse]
  | succ m ih =>
    intro q i hi
    have hi2 : i / 2 < 2 ^ m := by rw [pow_succ] at hi; omega
    rw [qmc_radicalInverse_two_rec, qmc_radicalInverse_two_rec i]
    have e0 : 2 ^ (m + 1) * q + i = 2 * (2 ^ m * q) + i := by ring
    have e1 : (2 ^ (m + 1) * q + i) % 2 = i % 2 := by
      rw [e0]; generalize 2 ^ m * q = R; omega
    have e2 : (2 ^ (m + 1) * q + i) / 2 = 2 ^ m * q + i / 2 := by
      rw [e0]; generalize 2 ^ m * q = R; omega
    rw [e1, e2, ih q (i / 2) hi2, pow_succ]
    field_simp
    ring

#print axioms qmc_shift

theorem qmc_sum_transfer (m : ℕ) (g : ℚ → ℝ) :
    ∑ i ∈ Finset.range (2 ^ m), g (radicalInverse 2 i)
      = ∑ j ∈ Finset.range (2 ^ m), g ((j : ℚ) / 2 ^ m) := by
  have hgrid : Set.InjOn (fun j : ℕ => (j : ℚ) / 2 ^ m) (Finset.range (2 ^ m) : Set ℕ) := by
    intro a _ b _ h
    have h2 : (2 : ℚ) ^ m ≠ 0 := by positivity
    simp only at h
    rw [div_left_inj' h2] at h
    exact_mod_cast h
  have hcard : ((Finset.range (2 ^ m)).image (radicalInverse 2)).card
      = (Finset.range (2 ^ m)).card := by
    rw [qmc_grid_eq, Finset.card_image_of_injOn hgrid]
  have hinj := Finset.card_image_iff.mp hcard
  rw [← Finset.sum_image (f := g) hinj, qmc_grid_eq,
    Finset.sum_image hgrid]

#print axioms qmc_sum_transfer

theorem qmc_block (m : ℕ) (c : ℚ) (hc0 : 0 ≤ c) (hc1 : 2 ^ m * c < 1) (t : ℝ)
    (ht : t ∈ Set.Icc (0 : ℝ) 1) :
    |(∑ j ∈ Finset.range (2 ^ m),
        if ((((j : ℚ) / 2 ^ m + c : ℚ)) : ℝ) < t then (1 : ℝ) else 0) - 2 ^ m * t| ≤ 1 := by
  obtain ⟨t0, t1⟩ := ht
  have hP : (0 : ℝ) < 2 ^ m := by positivity
  have hfilter : (Finset.range (2 ^ m)).filter
      (fun j : ℕ => ((((j : ℚ) / 2 ^ m + c : ℚ)) : ℝ) < t)
        = Finset.range (min (2 ^ m) ⌈(2 : ℝ) ^ m * (t - c)⌉₊) := by
    ext j
    simp only [Finset.mem_filter, Finset.mem_range, lt_min_iff, Nat.lt_ceil]
    have : ((((j : ℚ) / 2 ^ m + c : ℚ)) : ℝ) < t ↔ (j : ℝ) < (2 : ℝ) ^ m * (t - c) := by
      push_cast
      rw [← lt_sub_iff_add_lt, div_lt_iff₀ hP, mul_comm]
    rw [this]
  rw [← Finset.natCast_card_filter, hfilter, Finset.card_range]
  have hc1' : (2 : ℝ) ^ m * (c : ℝ) < 1 := by exact_mod_cast hc1
  have hc0' : (0 : ℝ) ≤ c := by exact_mod_cast hc0
  push_cast
  set x : ℝ := (2 : ℝ) ^ m * (t - c) with hx
  rw [abs_le]
  constructor
  · have h1 : (2 : ℝ) ^ m * t - 1 ≤ min ((2 : ℝ) ^ m) (⌈x⌉₊ : ℝ) := by
      apply le_min
      · nlinarith
      · have := Nat.le_ceil x
        rw [hx] at this; nlinarith
    linarith
  · have h1 : min ((2 : ℝ) ^ m) (⌈x⌉₊ : ℝ) ≤ ⌈x⌉₊ := min_le_right _ _
    have h3 : (0 : ℝ) ≤ 2 ^ m * t := by positivity
    rcases le_or_gt x 0 with hx0 | hx0
    · have : ⌈x⌉₊ = 0 := Nat.ceil_eq_zero.mpr hx0
      rw [this, Nat.cast_zero] at h1 ⊢
      linarith
    · have h2 := Nat.ceil_lt_add_one hx0.le
      have : x ≤ 2 ^ m * t := by rw [hx]; nlinarith
      linarith

#print axioms qmc_block

theorem qmc_count_double (n : ℕ) : (Nat.digits 2 (2 * n)).count 1 = (Nat.digits 2 n).count 1 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  · rw [Nat.digits_def' (by norm_num) (by omega)]
    have e1 : 2 * n % 2 = 0 := by omega
    have e2 : 2 * n / 2 = n := by omega
    rw [e1, e2]; simp

#print axioms qmc_count_double

theorem qmc_count_double_add_one (n : ℕ) :
    (Nat.digits 2 (2 * n + 1)).count 1 = (Nat.digits 2 n).count 1 + 1 := by
  rw [Nat.digits_def' (by norm_num) (by omega)]
  have e1 : (2 * n + 1) % 2 = 1 := by omega
  have e2 : (2 * n + 1) / 2 = n := by omega
  rw [e1, e2]; simp

#print axioms qmc_count_double_add_one

theorem qmc_count_pow_mul (m k : ℕ) : (Nat.digits 2 (2 ^ m * k)).count 1 = (Nat.digits 2 k).count 1 := by
  induction m with
  | zero => simp
  | succ m ih => rw [pow_succ, mul_comm (2 ^ m) 2, mul_assoc, qmc_count_double, ih]

#print axioms qmc_count_pow_mul

theorem qmc_main (t : ℝ) (ht : t ∈ Set.Icc (0 : ℝ) 1) (N : ℕ) :
    |(∑ i ∈ Finset.range N, if ((radicalInverse 2 i : ℚ) : ℝ) < t then (1 : ℝ) else 0) - N * t|
      ≤ ((Nat.digits 2 N).count 1 : ℝ) := by
  induction N using Nat.strong_induction_on with
  | _ N ih =>
    rcases Nat.eq_zero_or_pos N with rfl | hN
    · simp
    obtain ⟨m, k, hk, hNk⟩ := Nat.exists_eq_pow_mul_and_not_dvd hN.ne' 2 (by norm_num)
    obtain ⟨q, rfl⟩ : ∃ q, k = 2 * q + 1 := ⟨k / 2, by omega⟩
    set A := 2 ^ m * (2 * q) with hA
    have hNA : N = A + 2 ^ m := by rw [hNk, hA]; ring
    have hAlt : A < N := by rw [hNA]; have := Nat.one_le_two_pow (n := m); omega
    have hcN : (Nat.digits 2 N).count 1 = (Nat.digits 2 q).count 1 + 1 := by
      rw [hNk, qmc_count_pow_mul, qmc_count_double_add_one]
    have hcA : (Nat.digits 2 A).count 1 = (Nat.digits 2 q).count 1 := by
      rw [hA, qmc_count_pow_mul, qmc_count_double]
    have hIH := ih A hAlt
    rw [hNA, Finset.sum_range_add]
    have hblock : ∑ x ∈ Finset.range (2 ^ m),
        (if ((radicalInverse 2 (A + x) : ℚ) : ℝ) < t then (1 : ℝ) else 0)
        = ∑ j ∈ Finset.range (2 ^ m),
          if ((((j : ℚ) / 2 ^ m + radicalInverse 2 (2 * q) / 2 ^ m : ℚ)) : ℝ) < t
            then (1 : ℝ) else 0 := by
      rw [← qmc_sum_transfer m
        (fun y : ℚ => if (((y + radicalInverse 2 (2 * q) / 2 ^ m : ℚ)) : ℝ) < t
            then (1 : ℝ) else 0)]
      apply Finset.sum_congr rfl
      intro i hi
      rw [Finset.mem_range] at hi
      rw [hA, qmc_shift m (2 * q) i hi]
    have hB := qmc_block m (radicalInverse 2 (2 * q) / 2 ^ m)
      (by have := (qmc_radicalInverse_two_mem (2 * q)).1; positivity)
      (by have := (qmc_radicalInverse_two_mem (2 * q)).2
          rw [mul_div_cancel₀ _ (by positivity)]; exact this) t ht
    rw [hblock]
    rw [← hNA, hcN]
    rw [hcA] at hIH
    have e : ((A + 2 ^ m : ℕ) : ℝ) = (A : ℝ) + 2 ^ m := by push_cast; ring
    rw [hNA, e, Nat.cast_add, Nat.cast_one]
    calc _ = |((∑ i ∈ Finset.range A, if ((radicalInverse 2 i : ℚ) : ℝ) < t then (1 : ℝ) else 0)
              - A * t) + ((∑ j ∈ Finset.range (2 ^ m),
          if ((((j : ℚ) / 2 ^ m + radicalInverse 2 (2 * q) / 2 ^ m : ℚ)) : ℝ) < t
            then (1 : ℝ) else 0) - 2 ^ m * t)| := by congr 1; ring
      _ ≤ _ := abs_add_le _ _
      _ ≤ _ := add_le_add hIH hB

#print axioms qmc_main

theorem qmc_closed_count (N : ℕ) (u : Fin N → ℝ) (hu : ∀ i, u i ∈ Set.Ico (0 : ℝ) 1)
    (D : ℝ) (hD : ∀ t ∈ Set.Icc (0 : ℝ) 1,
      |(∑ i, if u i < t then (1 : ℝ) else 0) / N - t| ≤ D)
    (a : ℝ) (ha : a ∈ Set.Icc (0 : ℝ) 1) :
    |(∑ i, if u i ≤ a then (1 : ℝ) else 0) / N - a| ≤ D := by
  obtain ⟨ha0, ha1⟩ := ha
  rcases eq_or_lt_of_le ha1 with rfl | ha1
  · have : (∑ i, if u i ≤ (1 : ℝ) then (1 : ℝ) else 0) = ∑ i, if u i < (1 : ℝ) then (1 : ℝ) else 0 := by
      apply Finset.sum_congr rfl
      intro i _
      simp [(hu i).2, (hu i).2.le]
    rw [this]
    exact hD 1 ⟨zero_le_one, le_rfl⟩
  · have hev : ∀ᶠ s in nhdsWithin a (Set.Ioi a),
        (∑ i, if u i < s then (1 : ℝ) else 0) = ∑ i, if u i ≤ a then (1 : ℝ) else 0 := by
      have : ∀ i, ∀ᶠ s in nhdsWithin a (Set.Ioi a),
          (if u i < s then (1 : ℝ) else 0) = if u i ≤ a then (1 : ℝ) else 0 := by
        intro i
        by_cases h : u i ≤ a
        · filter_upwards [self_mem_nhdsWithin] with s hs
          have : u i < s := lt_of_le_of_lt h hs
          simp [h, this]
        · replace h := not_le.mp h
          filter_upwards [Ioo_mem_nhdsGT h] with s hs
          have h1 : ¬ u i < s := not_lt.mpr hs.2.le
          have h2 : ¬ u i ≤ a := not_le.mpr h
          simp [h1, h2]
      filter_upwards [Filter.eventually_all.mpr this] with s hs
      exact Finset.sum_congr rfl (fun i _ => hs i)
    have hcont : Filter.Tendsto
        (fun s => |(∑ i, if u i ≤ a then (1 : ℝ) else 0) / N - s|)
        (nhdsWithin a (Set.Ioi a))
        (nhds (|(∑ i, if u i ≤ a then (1 : ℝ) else 0) / N - a|)) :=
      ((continuous_const.sub continuous_id).abs.tendsto a).mono_left nhdsWithin_le_nhds
    have hlim : Filter.Tendsto
        (fun s => |(∑ i, if u i < s then (1 : ℝ) else 0) / N - s|)
        (nhdsWithin a (Set.Ioi a))
        (nhds (|(∑ i, if u i ≤ a then (1 : ℝ) else 0) / N - a|)) :=
      hcont.congr' (hev.mono fun s hs => by simp only [hs])
    apply le_of_tendsto hlim
    filter_upwards [Ioo_mem_nhdsGT ha1] with s hs
    exact hD s ⟨by linarith [hs.1], hs.2.le⟩

#print axioms qmc_closed_count

theorem qmc_step (N : ℕ) (hN : 0 < N) (u : Fin N → ℝ) (hu : ∀ i, u i ∈ Set.Ico (0 : ℝ) 1)
    (D : ℝ) (hD : ∀ t ∈ Set.Icc (0 : ℝ) 1,
      |(∑ i, if u i < t then (1 : ℝ) else 0) / N - t| ≤ D)
    (a : ℝ) (ha : a ∈ Set.Icc (0 : ℝ) 1) (g : ℝ → ℝ)
    (hg1 : ∀ x ∈ Set.Ioc a 1, g x = 1) (hg0 : ∀ x ∈ Set.Ico 0 a, g x = 0)
    (hga : g a = 0 ∨ g a = 1) :
    IntervalIntegrable g volume 0 1 ∧ |(∑ i, g (u i)) / N - ∫ x in (0 : ℝ)..1, g x| ≤ D := by
  obtain ⟨ha0, ha1⟩ := ha
  have hI1 : IntervalIntegrable g volume a 1 := by
    refine (intervalIntegrable_const (c := (1 : ℝ))).congr_uIoo ?_
    intro x hx
    rw [Set.uIoo_of_le ha1] at hx
    exact (hg1 x ⟨hx.1, hx.2.le⟩).symm
  have hI0 : IntervalIntegrable g volume 0 a := by
    refine (intervalIntegrable_const (c := (0 : ℝ))).congr_uIoo ?_
    intro x hx
    rw [Set.uIoo_of_le ha0] at hx
    exact (hg0 x ⟨hx.1.le, hx.2⟩).symm
  have hint : ∫ x in (0 : ℝ)..1, g x = 1 - a := by
    rw [← intervalIntegral.integral_add_adjacent_intervals hI0 hI1]
    have e0 : ∫ x in (0 : ℝ)..a, g x = ∫ x in (0 : ℝ)..a, (0 : ℝ) := by
      apply intervalIntegral.integral_congr_uIoo
      intro x hx
      rw [Set.uIoo_of_le ha0] at hx
      exact hg0 x ⟨hx.1.le, hx.2⟩
    have e1 : ∫ x in a..1, g x = ∫ x in a..1, (1 : ℝ) := by
      apply intervalIntegral.integral_congr_uIoo
      intro x hx
      rw [Set.uIoo_of_le ha1] at hx
      exact hg1 x ⟨hx.1, hx.2.le⟩
    rw [e0, e1]
    simp
  refine ⟨hI0.trans hI1, ?_⟩
  rw [hint]
  have hNpos : (0 : ℝ) < N := by exact_mod_cast hN
  have key : ∀ S : ℝ, (∑ i, g (u i)) = N - S → |S / N - a| ≤ D →
      |(∑ i, g (u i)) / N - (1 - a)| ≤ D := by
    intro S hS hSD
    rw [hS]
    have : ((N : ℝ) - S) / N - (1 - a) = -(S / N - a) := by field_simp; ring
    rw [this, abs_neg]
    exact hSD
  rcases hga with hga | hga
  · apply key (∑ i, if u i ≤ a then (1 : ℝ) else 0)
    · have : ∀ i, g (u i) = 1 - if u i ≤ a then (1 : ℝ) else 0 := by
        intro i
        by_cases h : u i ≤ a
        · rw [if_pos h]
          rcases eq_or_lt_of_le h with h' | h'
          · rw [h', hga]; ring
          · rw [hg0 _ ⟨(hu i).1, h'⟩]; ring
        · rw [if_neg h, hg1 _ ⟨not_le.mp h, (hu i).2.le⟩]; ring
      simp only [this, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ,
        Fintype.card_fin, nsmul_eq_mul, mul_one]
    · exact qmc_closed_count N u hu D hD a ⟨ha0, ha1⟩
  · apply key (∑ i, if u i < a then (1 : ℝ) else 0)
    · have : ∀ i, g (u i) = 1 - if u i < a then (1 : ℝ) else 0 := by
        intro i
        by_cases h : u i < a
        · rw [if_pos h, hg0 _ ⟨(hu i).1, h⟩]; ring
        · rw [if_neg h]
          rcases eq_or_lt_of_le (not_lt.mp h) with h' | h'
          · rw [← h', hga]; ring
          · rw [hg1 _ ⟨h', (hu i).2.le⟩]; ring
      simp only [this, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ,
        Fintype.card_fin, nsmul_eq_mul, mul_one]
    · exact hD a ⟨ha0, ha1⟩

#print axioms qmc_step

theorem qmc_level (N : ℕ) (hN : 0 < N) (u : Fin N → ℝ) (hu : ∀ i, u i ∈ Set.Ico (0 : ℝ) 1)
    (D : ℝ) (hD : ∀ t ∈ Set.Icc (0 : ℝ) 1,
      |(∑ i, if u i < t then (1 : ℝ) else 0) / N - t| ≤ D)
    (φ : ℝ → ℝ) (hφ : MonotoneOn φ (Set.Icc 0 1)) (c : ℝ) :
    IntervalIntegrable (fun x => if x ∈ Set.Icc (0 : ℝ) 1 ∧ c ≤ φ x then (1 : ℝ) else 0) volume 0 1 ∧
      |(∑ i, (fun x => if x ∈ Set.Icc (0 : ℝ) 1 ∧ c ≤ φ x then (1 : ℝ) else 0) (u i)) / N
        - ∫ x in (0 : ℝ)..1, (fun x => if x ∈ Set.Icc (0 : ℝ) 1 ∧ c ≤ φ x then (1 : ℝ) else 0) x|
        ≤ D := by
  set S : Set ℝ := {x | x ∈ Set.Icc (0 : ℝ) 1 ∧ c ≤ φ x} with hS
  have hga : ∀ y, (fun x => if x ∈ Set.Icc (0 : ℝ) 1 ∧ c ≤ φ x then (1 : ℝ) else 0) y = 0 ∨
      (fun x => if x ∈ Set.Icc (0 : ℝ) 1 ∧ c ≤ φ x then (1 : ℝ) else 0) y = 1 := by
    intro y; simp only; split_ifs <;> simp
  by_cases hne : S.Nonempty
  · have hbdd : BddBelow S := ⟨0, fun x hx => hx.1.1⟩
    set a := sInf S with ha
    have ha0 : 0 ≤ a := le_csInf hne (fun x hx => hx.1.1)
    have ha1 : a ≤ 1 := by
      obtain ⟨x, hx⟩ := hne
      exact (csInf_le hbdd hx).trans hx.1.2
    apply qmc_step N hN u hu D hD a ⟨ha0, ha1⟩ _ _ _ (hga a)
    · intro x hx
      obtain ⟨y, hyS, hyx⟩ := exists_lt_of_csInf_lt hne hx.1
      have hxI : x ∈ Set.Icc (0 : ℝ) 1 := ⟨ha0.trans hx.1.le, hx.2⟩
      have : c ≤ φ x := hyS.2.trans (hφ hyS.1 hxI hyx.le)
      exact if_pos ⟨hxI, this⟩
    · intro x hx
      rw [if_neg]
      intro hxS
      have := csInf_le hbdd hxS
      linarith [hx.2]
  · apply qmc_step N hN u hu D hD 1 ⟨zero_le_one, le_rfl⟩ _ _ _ (hga 1)
    · intro x hx
      exact absurd (hx.1.trans_le hx.2) (lt_irrefl _)
    · intro x hx
      rw [if_neg]
      intro hxS
      exact hne ⟨x, hxS⟩

#print axioms qmc_level

theorem qmc_floor_count (M : ℕ) (y : ℝ) (hy0 : 0 ≤ y) (hyM : y ≤ M) :
    (∑ k ∈ Finset.range M, if (k : ℝ) + 1 ≤ y then (1 : ℝ) else 0) = ⌊y⌋₊ := by
  rw [← Finset.natCast_card_filter]
  congr 1
  have hfl : ⌊y⌋₊ ≤ M := Nat.floor_le_of_le hyM
  have : (Finset.range M).filter (fun k : ℕ => (k : ℝ) + 1 ≤ y) = Finset.range ⌊y⌋₊ := by
    ext k
    simp only [Finset.mem_filter, Finset.mem_range]
    have hk : (k : ℝ) + 1 ≤ y ↔ k < ⌊y⌋₊ := by
      rw [Nat.lt_iff_add_one_le, Nat.le_floor_iff hy0]
      push_cast
      rfl
    rw [hk]
    omega
  rw [this, Finset.card_range]

#print axioms qmc_floor_count

theorem qmc_monotone (N : ℕ) (hN : 0 < N) (u : Fin N → ℝ) (hu : ∀ i, u i ∈ Set.Ico (0 : ℝ) 1)
    (D : ℝ) (hD : ∀ t ∈ Set.Icc (0 : ℝ) 1,
      |(∑ i, if u i < t then (1 : ℝ) else 0) / N - t| ≤ D)
    (f : ℝ → ℝ) (hf : MonotoneOn f (Set.Icc 0 1)) :
    |(∑ i, f (u i)) / N - ∫ x in (0 : ℝ)..1, f x| ≤ D * (f 1 - f 0) := by
  have h0 : (0 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := ⟨le_rfl, zero_le_one⟩
  have h1 : (1 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := ⟨zero_le_one, le_rfl⟩
  have hΔ : f 0 ≤ f 1 := hf h0 h1 zero_le_one
  have hD0 : 0 ≤ D := (abs_nonneg _).trans (hD 0 h0)
  have hNpos : (0 : ℝ) < N := by exact_mod_cast hN
  have hfi : IntervalIntegrable f volume 0 1 :=
    MonotoneOn.intervalIntegrable (by rwa [Set.uIcc_of_le zero_le_one])
  have hbound : ∀ x ∈ Set.Icc (0 : ℝ) 1, f 0 ≤ f x ∧ f x ≤ f 1 := fun x hx =>
    ⟨hf h0 hx hx.1, hf hx h1 hx.2⟩
  rcases eq_or_lt_of_le hΔ with hΔ | hΔ
  · have hc : ∀ x ∈ Set.Icc (0 : ℝ) 1, f x = f 0 := fun x hx =>
      le_antisymm ((hbound x hx).2.trans hΔ.ge) (hbound x hx).1
    have hs : (∑ i, f (u i)) = N * f 0 := by
      rw [Finset.sum_congr rfl (fun i _ => hc _ (Set.Ico_subset_Icc_self (hu i)))]
      simp
    have hi : ∫ x in (0 : ℝ)..1, f x = f 0 := by
      rw [intervalIntegral.integral_congr (g := fun _ => f 0)
        (fun x hx => hc x (by rwa [Set.uIcc_of_le zero_le_one] at hx))]
      simp
    rw [hs, hi, ← hΔ]
    field_simp
    simp
  · set Δ := f 1 - f 0 with hΔdef
    have hΔpos : 0 < Δ := by rw [hΔdef]; linarith
    apply le_of_forall_pos_lt_add
    intro ε hε
    obtain ⟨M, hM⟩ := exists_nat_gt (2 * Δ / ε)
    have hMpos : (0 : ℝ) < M := lt_trans (div_pos (by linarith) hε) hM
    have hMε : 2 * Δ / M < ε := by
      rw [div_lt_iff₀ hMpos]
      rw [div_lt_iff₀ hε] at hM
      linarith
    have hcM : 0 ≤ Δ / M := div_nonneg hΔpos.le hMpos.le
    suffices hsuff : |(∑ i, f (u i)) / N - ∫ x in (0 : ℝ)..1, f x| ≤ D * Δ + 2 * Δ / M by
      linarith
    set φ : ℝ → ℝ := fun x => M * (f x - f 0) / Δ with hφdef
    have hφ : MonotoneOn φ (Set.Icc 0 1) := fun x hx y hy hxy =>
      div_le_div_of_nonneg_right
        (mul_le_mul_of_nonneg_left (sub_le_sub_right (hf hx hy hxy) _) hMpos.le) hΔpos.le
    set ind : ℕ → ℝ → ℝ := fun k x =>
      if x ∈ Set.Icc (0 : ℝ) 1 ∧ ((k : ℝ) + 1) ≤ φ x then 1 else 0 with hinddef
    have hlev : ∀ k : ℕ, IntervalIntegrable (ind k) volume 0 1 ∧
        |(∑ i, ind k (u i)) / N - ∫ x in (0 : ℝ)..1, ind k x| ≤ D :=
      fun k => qmc_level N hN u hu D hD φ hφ ((k : ℝ) + 1)
    set step : ℝ → ℝ := fun x => f 0 + Δ / M * ∑ k ∈ Finset.range M, ind k x with hstepdef
    have hstep_close : ∀ x ∈ Set.Icc (0 : ℝ) 1, |f x - step x| ≤ Δ / M := by
      intro x hx
      have hy0 : 0 ≤ φ x :=
        div_nonneg (mul_nonneg hMpos.le (sub_nonneg.mpr (hbound x hx).1)) hΔpos.le
      have hyM : φ x ≤ M := by
        rw [hφdef, div_le_iff₀ hΔpos]
        have := (hbound x hx).2
        nlinarith
      have hsum : ∑ k ∈ Finset.range M, ind k x = ⌊φ x⌋₊ := by
        rw [← qmc_floor_count M (φ x) hy0 hyM]
        apply Finset.sum_congr rfl
        intro k _
        rw [hinddef]
        by_cases h : (k : ℝ) + 1 ≤ φ x <;> simp [h, hx]
      have hfx : f x = f 0 + Δ / M * φ x := by
        rw [hφdef]; field_simp; ring
      rw [hstepdef]
      simp only
      rw [hsum, hfx]
      have h1 := Nat.floor_le hy0
      have h2 := Nat.lt_floor_add_one (φ x)
      rw [show f 0 + Δ / M * φ x - (f 0 + Δ / M * ⌊φ x⌋₊) = Δ / M * (φ x - ⌊φ x⌋₊) by ring]
      rw [abs_of_nonneg (mul_nonneg hcM (by linarith))]
      have : φ x - ⌊φ x⌋₊ ≤ 1 := by linarith
      calc Δ / M * (φ x - ⌊φ x⌋₊) ≤ Δ / M * 1 := mul_le_mul_of_nonneg_left this hcM
        _ = Δ / M := mul_one _
    have hsum_int : IntervalIntegrable (fun x => ∑ k ∈ Finset.range M, ind k x) volume 0 1 := by
      have := IntervalIntegrable.sum (Finset.range M) (fun k _ => (hlev k).1)
      convert this using 1
      ext x
      simp [Finset.sum_apply]
    have hstep_int : IntervalIntegrable step volume 0 1 :=
      intervalIntegrable_const.add (hsum_int.const_mul _)
    have hEstep : (∑ i, step (u i)) / N - ∫ x in (0 : ℝ)..1, step x
        = Δ / M * ∑ k ∈ Finset.range M,
            ((∑ i, ind k (u i)) / N - ∫ x in (0 : ℝ)..1, ind k x) := by
      have hint : ∫ x in (0 : ℝ)..1, step x
          = f 0 + Δ / M * ∑ k ∈ Finset.range M, ∫ x in (0 : ℝ)..1, ind k x := by
        rw [hstepdef]
        rw [intervalIntegral.integral_add intervalIntegrable_const (hsum_int.const_mul _),
          intervalIntegral.integral_const_mul,
          intervalIntegral.integral_finsetSum (fun k _ => (hlev k).1)]
        simp
      rw [hint, Finset.sum_sub_distrib, ← Finset.sum_div]
      rw [hstepdef]
      simp only
      rw [Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_comm (s := Finset.univ)]
      simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
      field_simp
      ring
    have hEstep_le : |(∑ i, step (u i)) / N - ∫ x in (0 : ℝ)..1, step x| ≤ D * Δ := by
      rw [hEstep, abs_mul, abs_of_nonneg hcM]
      calc Δ / M * |∑ k ∈ Finset.range M, ((∑ i, ind k (u i)) / N - ∫ x in (0 : ℝ)..1, ind k x)|
          ≤ Δ / M * ∑ k ∈ Finset.range M,
              |(∑ i, ind k (u i)) / N - ∫ x in (0 : ℝ)..1, ind k x| :=
            mul_le_mul_of_nonneg_left (Finset.abs_sum_le_sum_abs _ _) hcM
        _ ≤ Δ / M * ∑ k ∈ Finset.range M, D :=
            mul_le_mul_of_nonneg_left (Finset.sum_le_sum fun k _ => (hlev k).2) hcM
        _ = D * Δ := by
            simp only [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
            field_simp
    have havg : |(∑ i, f (u i)) / N - (∑ i, step (u i)) / N| ≤ Δ / M := by
      rw [← sub_div, ← Finset.sum_sub_distrib, abs_div, abs_of_pos hNpos, div_le_iff₀ hNpos]
      calc |∑ i, (f (u i) - step (u i))| ≤ ∑ i, |f (u i) - step (u i)| :=
            Finset.abs_sum_le_sum_abs _ _
        _ ≤ ∑ _i : Fin N, Δ / M :=
            Finset.sum_le_sum fun i _ => hstep_close _ (Set.Ico_subset_Icc_self (hu i))
        _ = Δ / M * N := by simp; ring
    have hintd : |(∫ x in (0 : ℝ)..1, step x) - ∫ x in (0 : ℝ)..1, f x| ≤ Δ / M := by
      rw [abs_sub_comm, ← intervalIntegral.integral_sub hfi hstep_int]
      have := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := 1) (C := Δ / M)
        (f := fun x => f x - step x) (fun x hx => by
          rw [Real.norm_eq_abs]
          rw [Set.uIoc_of_le zero_le_one] at hx
          exact hstep_close x (Set.Ioc_subset_Icc_self hx))
      simpa using this
    calc |(∑ i, f (u i)) / N - ∫ x in (0 : ℝ)..1, f x|
        = |((∑ i, f (u i)) / N - (∑ i, step (u i)) / N)
            + ((∑ i, step (u i)) / N - ∫ x in (0 : ℝ)..1, step x)
            + ((∫ x in (0 : ℝ)..1, step x) - ∫ x in (0 : ℝ)..1, f x)| := by ring_nf
      _ ≤ _ := abs_add_three _ _ _
      _ ≤ Δ / M + D * Δ + Δ / M := add_le_add (add_le_add havg hEstep_le) hintd
      _ = D * Δ + 2 * Δ / M := by ring

#print axioms qmc_monotone

/-- **Koksma's inequality in one dimension.** Let `f` have bounded variation on `[0, 1]`,
and let `u_0, …, u_(N-1)` be `N` points in `[0, 1)`. If the local discrepancy
`K(t)/N - t` (with `K(t)` the number of points below `t`) is at most `D` in size for every
`t` in `[0, 1]`, then the average of `f` over the points misses `∫₀¹ f` by at most
`D` times the variation of `f`: `|Q_N - I| ≤ D*_N V(f)`. -/
theorem koksma_inequality (f : ℝ → ℝ) (hf : BoundedVariationOn f (Set.Icc 0 1))
    (N : ℕ) (hN : 0 < N) (u : Fin N → ℝ) (hu : ∀ i, u i ∈ Set.Ico (0 : ℝ) 1)
    (D : ℝ) (hD : ∀ t ∈ Set.Icc (0 : ℝ) 1,
      |((Finset.univ.filter (fun i => u i < t)).card : ℝ) / N - t| ≤ D) :
    |(∑ i, f (u i)) / N - ∫ x in (0 : ℝ)..1, f x|
      ≤ D * (eVariationOn f (Set.Icc 0 1)).toReal := by
  obtain ⟨p, q, hp, hq, hfpq, hvar⟩ := hf.locallyBoundedVariationOn.exists_monotoneOn_sub_monotoneOn'
  have h0 : (0 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := ⟨le_rfl, zero_le_one⟩
  have h1 : (1 : ℝ) ∈ Set.Icc (0 : ℝ) 1 := ⟨zero_le_one, le_rfl⟩
  have hV := hvar 0 h0 1 h1
  rw [variationOnFromTo.eq_of_le _ _ zero_le_one, Set.inter_self] at hV
  rw [← hV]
  have hD' : ∀ t ∈ Set.Icc (0 : ℝ) 1, |(∑ i, if u i < t then (1 : ℝ) else 0) / N - t| ≤ D := by
    intro t ht
    have := hD t ht
    rwa [Finset.natCast_card_filter] at this
  have Ep := qmc_monotone N hN u hu D hD' p hp
  have Eq := qmc_monotone N hN u hu D hD' q hq
  have hpi : IntervalIntegrable p volume 0 1 :=
    MonotoneOn.intervalIntegrable (by rwa [Set.uIcc_of_le zero_le_one])
  have hqi : IntervalIntegrable q volume 0 1 :=
    MonotoneOn.intervalIntegrable (by rwa [Set.uIcc_of_le zero_le_one])
  have hsplit : (∑ i, f (u i)) / N - ∫ x in (0 : ℝ)..1, f x
      = ((∑ i, p (u i)) / N - ∫ x in (0 : ℝ)..1, p x)
        - ((∑ i, q (u i)) / N - ∫ x in (0 : ℝ)..1, q x) := by
    rw [hfpq]
    simp only [Pi.sub_apply]
    rw [Finset.sum_sub_distrib, intervalIntegral.integral_sub hpi hqi]
    ring
  rw [hsplit]
  calc _ ≤ |(∑ i, p (u i)) / N - ∫ x in (0 : ℝ)..1, p x|
        + |(∑ i, q (u i)) / N - ∫ x in (0 : ℝ)..1, q x| := abs_sub _ _
    _ ≤ D * (p 1 - p 0) + D * (q 1 - q 0) := add_le_add Ep Eq
    _ = D * (p 1 - p 0 + (q 1 - q 0)) := by ring

/-- **Van der Corput's discrepancy bound.** For the first `N` van der Corput points
`φ_2(0), …, φ_2(N - 1)`, the local discrepancy at every `t` in `[0, 1]` is at most the number
of 1s in `N`'s binary digits, divided by `N`; and that is at most `(log₂ N + 1)/N`. -/
theorem van_der_corput_discrepancy_le_ones_div (N : ℕ) (hN : 0 < N) (t : ℝ)
    (ht : t ∈ Set.Icc (0 : ℝ) 1) :
    |(((Finset.range N).filter (fun i => ((radicalInverse 2 i : ℚ) : ℝ) < t)).card : ℝ) / N - t|
        ≤ ((Nat.digits 2 N).count 1 : ℝ) / N ∧
      ((Nat.digits 2 N).count 1 : ℝ) / N ≤ ((Nat.log 2 N : ℝ) + 1) / N := by
  have hNpos : (0 : ℝ) < N := by exact_mod_cast hN
  constructor
  · rw [Finset.natCast_card_filter]
    have h := qmc_main t ht N
    have : (∑ i ∈ Finset.range N, if ((radicalInverse 2 i : ℚ) : ℝ) < t then (1 : ℝ) else 0) / N - t
        = ((∑ i ∈ Finset.range N, if ((radicalInverse 2 i : ℚ) : ℝ) < t then (1 : ℝ) else 0)
            - N * t) / N := by field_simp
    rw [this, abs_div, abs_of_pos hNpos]
    exact div_le_div_of_nonneg_right h hNpos.le
  · apply div_le_div_of_nonneg_right _ hNpos.le
    have h1 := List.count_le_length (a := 1) (l := Nat.digits 2 N)
    rw [Nat.length_digits 2 N (by norm_num) hN.ne'] at h1
    exact_mod_cast h1

/-- The first `2^m` van der Corput points are exactly the grid `0, 1/2^m, 2/2^m, …, (2^m - 1)/2^m`. -/
theorem van_der_corput_first_pow_two_is_grid (m : ℕ) :
    (Finset.range (2 ^ m)).image (radicalInverse 2) =
      (Finset.range (2 ^ m)).image (fun j : ℕ => (j : ℚ) / 2 ^ m) := by
  exact qmc_grid_eq m

/-- New points a one-dimensional rule at level `l` adds to level `l - 1`:
the midpoint (1), then the two ends (2), then `2^(l-2)` midpoints. -/
def newPoints (l : ℕ) : ℕ := if l = 1 then 1 else if l = 2 then 2 else 2 ^ (l - 2)

/-- The card's count formula for a sparse grid in `d` dimensions at level `k`:
the sum, over level vectors `ℓ` with every `ℓ_j ≥ 1` and `|ℓ| ≤ k + d`, of `∏ newPoints ℓ_j`. -/
def sparseCount : ℕ → ℕ → ℕ
  | 0, _ => 1
  | d + 1, k => ((List.range (k + 1)).map fun j => newPoints (j + 1) * sparseCount d (k - j)).sum

-- van der Corput point 6: 6 = 110 in binary, mirrored 0.011 = 3/8
example : radicalInverse 2 6 = 3 / 8 := by
  norm_num [radicalInverse, List.range_succ]

-- the first eight van der Corput points
example : (List.range 8).map (radicalInverse 2) = [0, 1/2, 1/4, 3/4, 1/8, 5/8, 3/8, 7/8] := by
  norm_num [radicalInverse, List.range_succ]

-- Halton's base-3 coordinate: 0, 1/3, 2/3, 1/9
example : (List.range 4).map (radicalInverse 3) = [0, 1/3, 2/3, 1/9] := by
  norm_num [radicalInverse, List.range_succ]

-- N = 1000 has six 1s in binary, so the bound is 6/N
example : (Nat.digits 2 1000).count 1 = 6 := by
  norm_num

-- sparse grid sizes in 5 dimensions at levels 0 to 5, and the 2-D level-4 grid's 65 points
example : (List.range 6).map (sparseCount 5) = [1, 11, 61, 241, 801, 2433] := by
  decide

example : sparseCount 2 4 = 65 ∧ 17 ^ 2 = 289 := by
  decide

-- full grids of the same fineness: (2^k + 1)^5 points
example : (List.range 6).map (fun k => if k = 0 then 1 else (2 ^ k + 1) ^ 5)
    = [1, 243, 3125, 59049, 1419857, 39135393] := by
  decide

#print axioms koksma_inequality
#print axioms van_der_corput_discrepancy_le_ones_div
#print axioms van_der_corput_first_pow_two_is_grid
