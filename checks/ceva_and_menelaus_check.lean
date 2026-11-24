-- Ceva and Menelaus: in a flat plane, lines from a triangle's corners to points on the opposite side lines meet in one point (or are all parallel) exactly when the signed side ratios multiply to 1, three points on the side lines lie on one line exactly when their signed ratios multiply to -1, and the three altitudes always meet.
import Mathlib.LinearAlgebra.AffineSpace.Ceva
import Mathlib.LinearAlgebra.AffineSpace.FiniteDimensional
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum

open scoped Affine RealInnerProductSpace

/-! A point a fraction `t` of the way from `U` to `V` is `AffineMap.lineMap U V t`; its signed
ratio `UX/XV` is `t / (1 - t)`, as defined on the card. Corners `A`, `B`, `C` form a triangle
(affinely independent) in the flat plane `ℝ²`. -/

lemma ceva_indep3 {A B C : EuclideanSpace ℝ (Fin 2)} (h : AffineIndependent ℝ ![A, B, C])
    {a b c : ℝ} (hs : a + b + c = 0) (hv : a • A + b • B + c • C = 0) :
    a = 0 ∧ b = 0 ∧ c = 0 := by
  have := h.eq_zero_of_sum_eq_zero (s := Finset.univ) (w := ![a, b, c])
    (by simpa [Fin.sum_univ_three] using hs) (by simpa [Fin.sum_univ_three] using hv)
  exact ⟨this 0 (by simp), this 1 (by simp), this 2 (by simp)⟩

#print axioms ceva_indep3

/-- **Ceva's theorem and its converse.** Let `D`, `E`, `F` sit fractions `d`, `e`, `f` of the way
along sides `BC`, `CA`, `AB`, none at a corner. Then the signed ratios multiply to 1,
`AF/FB · BD/DC · CE/EA = 1`, exactly when the lines `AD`, `BE`, `CF` meet in one point or are
all parallel. -/
theorem ceva_product_eq_one_iff_concurrent_or_parallel
    {A B C D E F : EuclideanSpace ℝ (Fin 2)} {d e f : ℝ}
    (hABC : AffineIndependent ℝ ![A, B, C])
    (hD : D = AffineMap.lineMap B C d) (hE : E = AffineMap.lineMap C A e)
    (hF : F = AffineMap.lineMap A B f)
    (hd0 : d ≠ 0) (hd1 : d ≠ 1) (he0 : e ≠ 0) (he1 : e ≠ 1) (hf0 : f ≠ 0) (hf1 : f ≠ 1) :
    f / (1 - f) * (d / (1 - d)) * (e / (1 - e)) = 1 ↔
      ((∃ P, P ∈ line[ℝ, A, D] ∧ P ∈ line[ℝ, B, E] ∧ P ∈ line[ℝ, C, F]) ∨
        (line[ℝ, A, D] ∥ line[ℝ, B, E] ∧ line[ℝ, B, E] ∥ line[ℝ, C, F])) := by
  have hd1' : 1 - d ≠ 0 := sub_ne_zero.mpr (Ne.symm hd1)
  have he1' : 1 - e ≠ 0 := sub_ne_zero.mpr (Ne.symm he1)
  have hf1' : 1 - f ≠ 0 := sub_ne_zero.mpr (Ne.symm hf1)
  rw [div_mul_div_comm, div_mul_div_comm,
    div_eq_one_iff_eq (mul_ne_zero (mul_ne_zero hf1' hd1') he1')]
  subst hD hE hF
  constructor
  · intro hprod
    by_cases hΔ : (1 - d) * (1 - e) + d = 0
    · right
      have hfe : f * (1 - e) = 1 := by
        apply mul_left_cancel₀ hd0
        first | linear_combination -hprod - (1 - f) * hΔ | linear_combination hprod + (1 - f) * hΔ
      constructor
      · rw [AffineSubspace.affineSpan_pair_parallel_iff_vectorSpan_eq, vectorSpan_pair,
          vectorSpan_pair, Submodule.span_singleton_eq_span_singleton]
        refine ⟨Units.mk0 (-1 / (1 - d)) (div_ne_zero (neg_ne_zero.mpr one_ne_zero) hd1'), ?_⟩
        simp only [Units.smul_mk0, vsub_eq_sub, AffineMap.lineMap_apply_module]
        match_scalars <;> field_simp <;>
          first | ring1 | linear_combination hΔ | linear_combination -hΔ
      · rw [AffineSubspace.affineSpan_pair_parallel_iff_vectorSpan_eq, vectorSpan_pair,
          vectorSpan_pair, Submodule.span_singleton_eq_span_singleton]
        refine ⟨Units.mk0 (-f) (neg_ne_zero.mpr hf0), ?_⟩
        simp only [Units.smul_mk0, vsub_eq_sub, AffineMap.lineMap_apply_module]
        match_scalars <;>
          first | ring1 | linear_combination hfe | linear_combination -hfe
    · left
      refine ⟨(1 - (1 - e) / ((1 - d) * (1 - e) + d)) • A
        + ((1 - e) / ((1 - d) * (1 - e) + d) * (1 - d)) • B
        + ((1 - e) / ((1 - d) * (1 - e) + d) * d) • C, ?_, ?_, ?_⟩ <;>
        rw [mem_affineSpan_pair_iff_exists_lineMap_eq]
      · refine ⟨(1 - e) / ((1 - d) * (1 - e) + d), ?_⟩
        simp only [AffineMap.lineMap_apply_module]
        match_scalars <;> field_simp <;> ring1
      · refine ⟨d / ((1 - d) * (1 - e) + d), ?_⟩
        simp only [AffineMap.lineMap_apply_module]
        match_scalars <;> field_simp <;> ring1
      · refine ⟨(1 - d) * (1 - e) / (((1 - d) * (1 - e) + d) * f), ?_⟩
        simp only [AffineMap.lineMap_apply_module]
        match_scalars <;> field_simp <;>
          first | ring1 | linear_combination hprod | linear_combination -hprod
  · rintro (⟨P, h1, h2, h3⟩ | ⟨h1, h2⟩)
    · rw [mem_affineSpan_pair_iff_exists_lineMap_eq] at h1 h2 h3
      obtain ⟨s, rfl⟩ := h1
      obtain ⟨t, ht⟩ := h2
      obtain ⟨w, hw⟩ := h3
      simp only [AffineMap.lineMap_apply_module] at ht hw
      obtain ⟨ha, hb, hc⟩ := ceva_indep3 hABC (a := t * e - (1 - s))
        (b := (1 - t) - s * (1 - d)) (c := t * (1 - e) - s * d) (by ring)
        (by linear_combination (norm := module) ht)
      obtain ⟨hwa, hwb, hwc⟩ := ceva_indep3 hABC (a := w * (1 - f) - (1 - s))
        (b := w * f - s * (1 - d)) (c := (1 - w) - s * d) (by ring)
        (by linear_combination (norm := module) hw)
      have hs : s ≠ 0 := by
        rintro rfl
        apply he1'
        linear_combination hc + (1 - e) * hb
      have ht0 : t ≠ 0 := by
        rintro rfl
        apply hd0
        linear_combination d * hb - (1 - d) * hc
      have hw0 : w ≠ 0 := by
        rintro rfl
        have : s * (1 - d) = 0 := by linear_combination -hwb
        rcases mul_eq_zero.mp this with h | h
        · exact hs h
        · exact hd1' h
      apply mul_left_cancel₀ (mul_ne_zero (mul_ne_zero hs hw0) ht0)
      linear_combination (s * d * t * e) * hwb - (s * (1 - d) * t * e) * hc
        - (s * (1 - d) * t * (1 - e)) * (hwa - ha)
    · rw [AffineSubspace.affineSpan_pair_parallel_iff_vectorSpan_eq, vectorSpan_pair,
        vectorSpan_pair, Submodule.span_singleton_eq_span_singleton] at h1 h2
      obtain ⟨z, hz⟩ := h1
      obtain ⟨z', hz'⟩ := h2
      simp only [Units.smul_def, vsub_eq_sub, AffineMap.lineMap_apply_module] at hz hz'
      obtain ⟨ha, hb, hc⟩ := ceva_indep3 hABC (a := (z : ℝ) + e)
        (b := -(z : ℝ) * (1 - d) - 1) (c := -(z : ℝ) * d + (1 - e)) (by ring)
        (by linear_combination (norm := module) hz)
      obtain ⟨ha', hb', hc'⟩ := ceva_indep3 hABC (a := -(z' : ℝ) * e + (1 - f))
        (b := (z' : ℝ) + f) (c := -(z' : ℝ) * (1 - e) - 1) (by ring)
        (by linear_combination (norm := module) hz')
      have h1 : f * (1 - e) = 1 := by linear_combination hc' + (1 - e) * hb'
      have h2 : e * (1 - d) = 1 := by linear_combination hb + (1 - d) * ha
      linear_combination (-d) * h1 + (1 - f) * h2

/-- **Menelaus' theorem and its converse.** Let `L`, `M`, `N` sit fractions `l`, `m`, `n` of the
way along the side lines `BC`, `CA`, `AB` (inside the side or beyond it), none at a corner. Then
`L`, `M`, `N` lie on one straight line exactly when the signed ratios multiply to -1,
`AN/NB · BL/LC · CM/MA = -1`. -/
theorem menelaus_collinear_iff_product_eq_neg_one
    {A B C L M N : EuclideanSpace ℝ (Fin 2)} {l m n : ℝ}
    (hABC : AffineIndependent ℝ ![A, B, C])
    (hL : L = AffineMap.lineMap B C l) (hM : M = AffineMap.lineMap C A m)
    (hN : N = AffineMap.lineMap A B n)
    (hl0 : l ≠ 0) (hl1 : l ≠ 1) (hm0 : m ≠ 0) (hm1 : m ≠ 1) (hn0 : n ≠ 0) (hn1 : n ≠ 1) :
    Collinear ℝ {L, M, N} ↔ n / (1 - n) * (l / (1 - l)) * (m / (1 - m)) = -1 := by
  have hl1' : 1 - l ≠ 0 := sub_ne_zero.mpr (Ne.symm hl1)
  have hm1' : 1 - m ≠ 0 := sub_ne_zero.mpr (Ne.symm hm1)
  have hn1' : 1 - n ≠ 0 := sub_ne_zero.mpr (Ne.symm hn1)
  rw [div_mul_div_comm, div_mul_div_comm, div_eq_iff (mul_ne_zero (mul_ne_zero hn1' hl1') hm1')]
  subst hL hM hN
  have hMN : AffineMap.lineMap C A m ≠ AffineMap.lineMap A B n := by
    intro h
    simp only [AffineMap.lineMap_apply_module] at h
    obtain ⟨-, hb, -⟩ := ceva_indep3 hABC (a := m - (1 - n)) (b := -n) (c := 1 - m) (by ring)
      (by linear_combination (norm := module) h)
    exact hn0 (neg_eq_zero.mp hb)
  constructor
  · intro hcol
    have h := hcol.mem_affineSpan_of_mem_of_ne (p₃ := AffineMap.lineMap B C l) (by simp) (by simp) (by simp) hMN
    rw [mem_affineSpan_pair_iff_exists_lineMap_eq] at h
    obtain ⟨r, hr⟩ := h
    simp only [AffineMap.lineMap_apply_module] at hr
    obtain ⟨ha, hb, hc⟩ := ceva_indep3 hABC (a := (1 - r) * m + r * (1 - n))
      (b := r * n - (1 - l)) (c := (1 - r) * (1 - m) - l) (by ring)
      (by linear_combination (norm := module) hr)
    linear_combination n * (1 - m) * ha - n * m * hc - (1 - n) * (1 - m) * hb
  · intro h
    apply collinear_insert_of_mem_affineSpan_pair
    rw [mem_affineSpan_pair_iff_exists_lineMap_eq]
    refine ⟨(1 - l) / n, ?_⟩
    simp only [AffineMap.lineMap_apply_module]
    match_scalars <;> field_simp <;> first | linear_combination h | linear_combination -h

/-- **The altitudes always meet (the orthocentre exists).** In every triangle there is a point
`H` on all three altitudes: `AH` is at right angles to `BC`, `BH` to `CA`, and `CH` to `AB`. -/
theorem altitudes_meet
    {A B C : EuclideanSpace ℝ (Fin 2)} (hABC : AffineIndependent ℝ ![A, B, C]) :
    ∃ H : EuclideanSpace ℝ (Fin 2),
      ⟪H -ᵥ A, C -ᵥ B⟫ = 0 ∧ ⟪H -ᵥ B, A -ᵥ C⟫ = 0 ∧ ⟪H -ᵥ C, B -ᵥ A⟫ = 0 := by
  have hdet : (C.ofLp 0 - B.ofLp 0) * (A.ofLp 1 - C.ofLp 1)
      - (C.ofLp 1 - B.ofLp 1) * (A.ofLp 0 - C.ofLp 0) ≠ 0 := by
    intro hdet
    obtain ⟨hp1, hq1, -⟩ := ceva_indep3 hABC (a := -(C.ofLp 1 - B.ofLp 1))
      (b := -(A.ofLp 1 - C.ofLp 1)) (c := (A.ofLp 1 - C.ofLp 1) + (C.ofLp 1 - B.ofLp 1))
      (by ring) (by
        ext i; fin_cases i <;> simp <;>
          first | ring1 | linear_combination hdet | linear_combination -hdet)
    obtain ⟨hp0, hq0, -⟩ := ceva_indep3 hABC (a := -(C.ofLp 0 - B.ofLp 0))
      (b := -(A.ofLp 0 - C.ofLp 0)) (c := (A.ofLp 0 - C.ofLp 0) + (C.ofLp 0 - B.ofLp 0))
      (by ring) (by
        ext i; fin_cases i <;> simp <;>
          first | ring1 | linear_combination hdet | linear_combination -hdet)
    obtain ⟨-, h1, -⟩ := ceva_indep3 hABC (a := 0) (b := 1) (c := -1) (by ring) (by
        ext i; fin_cases i <;> simp <;>
          first | linear_combination hp0 | linear_combination hp1)
    exact one_ne_zero h1
  set det := (C.ofLp 0 - B.ofLp 0) * (A.ofLp 1 - C.ofLp 1)
      - (C.ofLp 1 - B.ofLp 1) * (A.ofLp 0 - C.ofLp 0) with hdet_def
  set α := (C.ofLp 0 - B.ofLp 0) * A.ofLp 0 + (C.ofLp 1 - B.ofLp 1) * A.ofLp 1
  set β := (A.ofLp 0 - C.ofLp 0) * B.ofLp 0 + (A.ofLp 1 - C.ofLp 1) * B.ofLp 1
  refine ⟨!₂[(α * (A.ofLp 1 - C.ofLp 1) - β * (C.ofLp 1 - B.ofLp 1)) / det,
    ((C.ofLp 0 - B.ofLp 0) * β - (A.ofLp 0 - C.ofLp 0) * α) / det], ?_, ?_, ?_⟩ <;>
    simp only [vsub_eq_sub, PiLp.inner_apply, Fin.sum_univ_two, PiLp.sub_apply] <;>
    simp [α, β] <;> field_simp <;> rw [hdet_def] <;> ring

/-! The card's worked numbers: triangle A (0, 0), B (6, 0), C (2, 4), exact fractions. -/

-- A signed ratio t/(1 - t): the altitude feet F, D, E sit 1/3, 3/4, 2/5 of the way along AB, BC, CA.
example : (1/3 : ℚ) / (1 - 1/3) = 1/2 := by norm_num
example : (3/4 : ℚ) / (1 - 3/4) = 3 := by norm_num
example : (2/5 : ℚ) / (1 - 2/5) = 2/3 := by norm_num
-- Medians: each side cut in half, ratios 1, 1, 1, product 1.
example : (1/2 : ℚ) / (1 - 1/2) = 1 := by norm_num
example : (1 : ℚ) * 1 * 1 = 1 := by norm_num
-- Altitudes: 1/2 × 3 × 2/3 = 1.
example : (1/2 : ℚ) * 3 * (2/3) = 1 := by norm_num
-- H (2, 2) lies on all three altitudes: AH ⟂ BC, BH ⟂ CA, CH ⟂ AB.
example : (2 - 0 : ℚ) * (2 - 6) + (2 - 0) * (4 - 0) = 0 := by norm_num
example : (2 - 6 : ℚ) * (0 - 2) + (2 - 0) * (0 - 4) = 0 := by norm_num
example : (2 - 2 : ℚ) * (6 - 0) + (2 - 4) * (0 - 0) = 0 := by norm_num
-- Areas round H: ABH 6, BCH 4, CAH 2, adding to 12; their ratios are the altitude ratios.
example : (6 : ℚ) + 4 + 2 = 12 ∧ (2 : ℚ) / 4 = 1/2 ∧ (6 : ℚ) / 2 = 3 ∧ (4 : ℚ) / 6 = 2/3 := by
  norm_num
-- Transversal: N (9, 0) at t = 3/2 on AB, L at t = 1/4 on BC, M at t = 1/2 on CA.
example : (3/2 : ℚ) / (1 - 3/2) = -3 := by norm_num
example : (1/4 : ℚ) / (1 - 1/4) = 1/3 := by norm_num
example : (-3 : ℚ) * (1/3) * 1 = -1 := by norm_num
-- L (5, 1), M (1, 2), N (9, 0) are on one line: the cross product of L - N and M - N is 0.
example : (5 - 9 : ℚ) * (2 - 0) - (1 - 0) * (1 - 9) = 0 := by norm_num
-- Slips: one ratio flipped gives 1/9; the transversal's signs dropped give 1.
example : (1/2 : ℚ) * (1/3) * (2/3) = 1/9 := by norm_num
example : (3 : ℚ) * (1/3) * 1 = 1 := by norm_num
-- Mixed lines (two medians with the altitude from C): 1/2 × 1 × 1 = 1/2, not 1.
example : (1/2 : ℚ) * 1 * 1 ≠ 1 := by norm_num
-- Parallel through C meets AB at K (18, 0): BN/NK = 3/9 = 1/3 and KN/NA = 9/9 = 1.
example : (3 : ℚ) / 9 = 1/3 ∧ (9 : ℚ) / 9 = 1 := by norm_num

#print axioms ceva_product_eq_one_iff_concurrent_or_parallel
#print axioms menelaus_collinear_iff_product_eq_neg_one
#print axioms altitudes_meet
