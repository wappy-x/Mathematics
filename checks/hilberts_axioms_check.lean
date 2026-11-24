-- Hilbert's axioms: two equal circles in the real plane cross exactly when their centres are at most two radii apart, Euclid's two 4 cm circles share no point with fraction coordinates, and Pasch's rule holds in the real plane.
import Mathlib.Analysis.Convex.Between
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic

/-- Helper: if `a` and `b` have opposite signs, some `t ∈ [0, 1]` makes `(1 - t) a + t b = 0`. -/
theorem hilbert_pasch_zero_between (a b : ℝ) (h : a * b < 0) :
    ∃ t ∈ Set.Icc (0 : ℝ) 1, (1 - t) * a + t * b = 0 := by
  rcases lt_or_gt_of_ne (show a ≠ 0 by rintro rfl; simp at h) with ha | ha
  · have hb : 0 < b := by nlinarith
    have hab : a - b < 0 := by linarith
    have hne : a - b ≠ 0 := hab.ne
    refine ⟨a / (a - b), ⟨div_nonneg_of_nonpos ha.le hab.le, ?_⟩, ?_⟩
    · rw [div_le_one_of_neg hab]; linarith
    · field_simp; ring
  · have hb : b < 0 := by nlinarith
    have hab : 0 < a - b := by linarith
    have hne : a - b ≠ 0 := hab.ne'
    refine ⟨a / (a - b), ⟨div_nonneg ha.le hab.le, ?_⟩, ?_⟩
    · rw [div_le_one hab]; linarith
    · field_simp; ring

/-- The formula and its condition. Two circles of radius r ≥ 0, centred at A = (0, 0) and
B = (d, 0) with gap d > 0, share a point of the real plane exactly when d ≤ 2r. Every shared
point (x, y) sits halfway between the centres, x = d/2, at a height with y² = r² − d²/4. -/
theorem circles_cross_iff_gap_le_two_radii (r d : ℝ) (hr : 0 ≤ r) (hd : 0 < d) :
    ((∃ x y : ℝ, x ^ 2 + y ^ 2 = r ^ 2 ∧ (x - d) ^ 2 + y ^ 2 = r ^ 2) ↔ d ≤ 2 * r) ∧
      ∀ x y : ℝ, (x ^ 2 + y ^ 2 = r ^ 2 ∧ (x - d) ^ 2 + y ^ 2 = r ^ 2) ↔
        (x = d / 2 ∧ y ^ 2 = r ^ 2 - d ^ 2 / 4) := by
  have key : ∀ x y : ℝ, (x ^ 2 + y ^ 2 = r ^ 2 ∧ (x - d) ^ 2 + y ^ 2 = r ^ 2) ↔
      (x = d / 2 ∧ y ^ 2 = r ^ 2 - d ^ 2 / 4) := by
    intro x y
    constructor
    · rintro ⟨h1, h2⟩
      have hx : x = d / 2 := by
        have h3 : d * (2 * x - d) = 0 := by linear_combination h1 - h2
        rcases mul_eq_zero.1 h3 with h | h
        · linarith
        · linarith
      refine ⟨hx, ?_⟩
      subst hx
      linear_combination h1
    · rintro ⟨hx, hy⟩
      subst hx
      constructor
      · linear_combination hy
      · linear_combination hy
  refine ⟨⟨?_, ?_⟩, key⟩
  · rintro ⟨x, y, h⟩
    obtain ⟨-, hy⟩ := (key x y).1 h
    by_contra hc
    push Not at hc
    nlinarith [sq_nonneg y]
  · intro h
    have hnn : 0 ≤ r ^ 2 - d ^ 2 / 4 := by nlinarith
    exact ⟨d / 2, Real.sqrt (r ^ 2 - d ^ 2 / 4), (key _ _).2 ⟨rfl, Real.sq_sqrt hnn⟩⟩

/-- Step 2, the continuity gap in Euclid I.1. In the fraction plane (both coordinates
rational), the circles of radius 4 about A = (0, 0) and B = (4, 0) share no point: the
crossing would need y² = 12, and 12 is not the square of a fraction. -/
theorem fraction_plane_euclid_circles_do_not_meet :
    ¬ ∃ x y : ℚ, x ^ 2 + y ^ 2 = 4 ^ 2 ∧ (x - 4) ^ 2 + y ^ 2 = 4 ^ 2 := by
  rintro ⟨x, y, h1, h2⟩
  have hx : x = 2 := by linear_combination (h1 - h2) / 8
  subst hx
  have hy : y * y = 12 := by linear_combination h1
  have h := (Rat.exists_mul_self 12).1 ⟨y, hy⟩
  rw [Rat.sqrt] at h
  norm_num at h

/-- Pasch's rule in the real plane. For a triangle ABC (three points not on one line) and a
line ℓ in its plane that passes through none of the corners: if ℓ meets segment AB, then ℓ
meets segment BC or segment CA. -/
theorem pasch_real_plane (A B C : EuclideanSpace ℝ (Fin 2))
    (hABC : AffineIndependent ℝ ![A, B, C])
    (ℓ : AffineSubspace ℝ (EuclideanSpace ℝ (Fin 2))) (hℓ : Module.finrank ℝ ℓ.direction = 1)
    (hA : A ∉ ℓ) (hB : B ∉ ℓ) (hC : C ∉ ℓ)
    (hAB : ∃ D ∈ ℓ, Wbtw ℝ A D B) :
    (∃ E ∈ ℓ, Wbtw ℝ B E C) ∨ (∃ E ∈ ℓ, Wbtw ℝ C E A) := by
  obtain ⟨D, hDl, hD⟩ := hAB
  obtain ⟨v, hv0, -⟩ := finrank_eq_one_iff'.1 hℓ
  set u : EuclideanSpace ℝ (Fin 2) := (v : EuclideanSpace ℝ (Fin 2)) with hu
  have hu0 : u ≠ 0 := by
    intro h; apply hv0; ext1; simpa [hu] using h
  have humem : u ∈ ℓ.direction := v.2
  let f : EuclideanSpace ℝ (Fin 2) → ℝ := fun p => u 1 * (p 0 - D 0) - u 0 * (p 1 - D 1)
  have hf_line : ∀ p q : EuclideanSpace ℝ (Fin 2), ∀ t : ℝ,
      f (AffineMap.lineMap p q t) = (1 - t) * f p + t * f q := by
    intro p q t
    simp only [f, AffineMap.lineMap_apply_module, PiLp.add_apply, PiLp.smul_apply, smul_eq_mul]
    ring
  have hf_mem : ∀ p, f p = 0 → p ∈ ℓ := by
    intro p hp
    rw [← AffineSubspace.vsub_right_mem_direction_iff_mem hDl p]
    have hw : p -ᵥ D = (p 0 - D 0) • (u 0)⁻¹ • u ∨ p -ᵥ D = (p 1 - D 1) • (u 1)⁻¹ • u := by
      by_cases h0 : u 0 = 0
      · have h1 : u 1 ≠ 0 := by
          intro h1; apply hu0; ext i; fin_cases i <;> simp [h0, h1]
        right
        ext i; fin_cases i
        · simp only [f, h0] at hp
          simp [vsub_eq_sub, h0]
          have : p 0 - D 0 = 0 := by
            rcases mul_eq_zero.1 (by linarith : u 1 * (p 0 - D 0) = 0) with h | h
            · exact absurd h h1
            · exact h
          linarith
        · simp [vsub_eq_sub]; field_simp
      · left
        ext i; fin_cases i
        · simp [vsub_eq_sub]; field_simp
        · simp [vsub_eq_sub]
          simp only [f] at hp
          field_simp
          linear_combination -hp
    rcases hw with hw | hw <;> rw [hw] <;>
      exact ℓ.direction.smul_mem _ (ℓ.direction.smul_mem _ humem)
  have hfA : f A ≠ 0 := fun h => hA (hf_mem A h)
  have hfB : f B ≠ 0 := fun h => hB (hf_mem B h)
  have hfC : f C ≠ 0 := fun h => hC (hf_mem C h)
  obtain ⟨t, ⟨ht0, ht1⟩, hDt⟩ := hD
  have heq : (1 - t) * f A + t * f B = 0 := by
    rw [← hf_line, hDt]
    simp [f]
  have hAB' : f A * f B < 0 := by
    by_contra hc
    push Not at hc
    rcases eq_or_lt_of_le ht1 with h1 | h1
    · subst h1
      simp at heq
      exact hfB heq
    · have hpos : 0 < (1 - t) * f A ^ 2 := mul_pos (by linarith) (by positivity)
      have h2 : ((1 - t) * f A + t * f B) * f A = 0 := by rw [heq]; ring
      nlinarith [mul_nonneg ht0 hc]
  by_cases hBC : f B * f C < 0
  · left
    obtain ⟨s, hs, hs0⟩ := hilbert_pasch_zero_between (f B) (f C) hBC
    exact ⟨AffineMap.lineMap B C s, hf_mem _ (by rw [hf_line]; exact hs0), s, hs, rfl⟩
  · right
    have hBC' : 0 < f B * f C := lt_of_le_of_ne (not_lt.1 hBC) (mul_ne_zero hfB hfC).symm
    have hprod := mul_neg_of_neg_of_pos hAB' hBC'
    have hCA : f C * f A < 0 := by
      by_contra hc
      push Not at hc
      nlinarith [mul_nonneg hc (sq_nonneg (f B))]
    obtain ⟨s, hs, hs0⟩ := hilbert_pasch_zero_between (f C) (f A) hCA
    exact ⟨AffineMap.lineMap C A s, hf_mem _ (by rw [hf_line]; exact hs0), s, hs, rfl⟩

-- Hilbert's five groups: connection 7, order 5, parallels 1, congruence 6, continuity 1.
example : 7 + 5 + 1 + 6 + 1 = 20 := by decide
-- r = d = 4: subtracting the circle equations gives 8x − 16 = 0, so x = 2, and y² = 16 − 4 = 12.
example : (8 : ℚ) * 2 - 16 = 0 := by norm_num
example : (4 : ℚ) ^ 2 - 4 ^ 2 / 4 = 12 := by norm_num
-- The closest fraction with q up to 30 is 97/28: 97² = 12 · 28² + 1, close to 12 but not equal.
example : (97 : ℤ) ^ 2 = 12 * 28 ^ 2 + 1 := by norm_num
-- Control: radius 5, centres 6 apart, y² = 25 − 9 = 16, crossing at the fraction point (3, 4).
example : (3 : ℚ) ^ 2 + 4 ^ 2 = 5 ^ 2 ∧ ((3 : ℚ) - 6) ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num
-- Centres 9 apart with radius 4: y² = 16 − 81/4 = −17/4 < 0, no crossing.
example : (4 : ℚ) ^ 2 - 9 ^ 2 / 4 = -17 / 4 := by norm_num
example : ¬ ((9 : ℚ) ≤ 2 * 4) := by norm_num

#print axioms hilbert_pasch_zero_between
#print axioms circles_cross_iff_gap_le_two_radii
#print axioms fraction_plane_euclid_circles_do_not_meet
#print axioms pasch_real_plane
