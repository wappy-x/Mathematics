-- Two shape puzzles settled: Hammersley's sofa, two quarter discs and a block with a half-disc hole of radius r, has area π/2 + 2r − (π/2)r², largest at r = 2/π where it is π/2 + 2/π, and every cube of side below 3√2/4, which exceeds 1, passes through a hole in a unit cube.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory Real Matrix

/-! The plane is `ℝ × ℝ` with Lebesgue measure `volume` (area). Space is `Fin 3 → ℝ`, and a
turn of space is a matrix in Mathlib's `specialOrthogonalGroup`, acting by `*ᵥ`. The shadow of a
point along the third axis drops its third coordinate. The two deep results of the card, Baek's
claimed proof that Gerver's sofa is largest and the Noperthedron, are not stated here. -/

/-- Hammersley's sofa with hole radius `r`, in a hallway of width 1: two quarter discs of
radius 1 centred at `(−r, 0)` and `(r, 0)`, the block `[−r, r] × [0, 1]` between them, and the
half-disc hole of radius `r` about `(0, 0)` cut out of the block. -/
def hammersleySofa (r : ℝ) : Set (ℝ × ℝ) :=
  ({p | p.1 ≤ -r ∧ 0 ≤ p.2 ∧ (p.1 + r) ^ 2 + p.2 ^ 2 ≤ 1} ∪
    {p | r ≤ p.1 ∧ 0 ≤ p.2 ∧ (p.1 - r) ^ 2 + p.2 ^ 2 ≤ 1} ∪
    {p | -r ≤ p.1 ∧ p.1 ≤ r ∧ 0 ≤ p.2 ∧ p.2 ≤ 1}) \
  {p | p.1 ^ 2 + p.2 ^ 2 < r ^ 2}

/-- The shadow of a point of space along the third axis: its first two coordinates. -/
def shadow (x : Fin 3 → ℝ) : Fin 2 → ℝ := ![x 0, x 1]

/-- The solid cube of side `s` centred at the origin. -/
def cube (s : ℝ) : Set (Fin 3 → ℝ) := {x | ∀ i, |x i| ≤ s / 2}

/-- Rupert's property in its shadow form: the solid `P'` passes through a hole in the solid `P`
when, for some turns `Q₁`, `Q₂` of space and some sideways shift `t`, the shadow of the turned
`P'`, shifted by `t`, lies strictly inside (in the interior of) the shadow of the turned `P`. -/
def PassesThrough (P' P : Set (Fin 3 → ℝ)) : Prop :=
  ∃ Q₁ ∈ specialOrthogonalGroup (Fin 3) ℝ, ∃ Q₂ ∈ specialOrthogonalGroup (Fin 3) ℝ,
    ∃ t : Fin 2 → ℝ,
      (fun x => shadow (Q₁ *ᵥ x) + t) '' P' ⊆ interior ((fun x => shadow (Q₂ *ᵥ x)) '' P)

lemma volume_slice_disc (c : ℝ) :
    volume {y : ℝ | 0 ≤ y ∧ c + y ^ 2 ≤ 1} = ENNReal.ofReal (√(1 - c)) := by
  by_cases h : 0 ≤ 1 - c
  · have : {y : ℝ | 0 ≤ y ∧ c + y ^ 2 ≤ 1} = Set.Icc 0 (√(1 - c)) := by
      ext y
      simp only [Set.mem_ofPred_eq, Set.mem_Icc]
      constructor
      · rintro ⟨hy, hc⟩
        exact ⟨hy, (Real.le_sqrt hy h).2 (by linarith)⟩
      · rintro ⟨hy, hc⟩
        exact ⟨hy, by linarith [(Real.le_sqrt hy h).1 hc]⟩
    rw [this, Real.volume_Icc, sub_zero]
  · have : {y : ℝ | 0 ≤ y ∧ c + y ^ 2 ≤ 1} = ∅ := by
      ext y
      simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_and, not_le]
      intro _
      nlinarith [sq_nonneg y]
    rw [this, Real.sqrt_eq_zero'.2 (by linarith)]
    simp

#print axioms volume_slice_disc

lemma volume_slice_mid (d : ℝ) :
    volume {y : ℝ | 0 ≤ y ∧ y ≤ 1 ∧ d ≤ y ^ 2} = ENNReal.ofReal (1 - √d) := by
  have : {y : ℝ | 0 ≤ y ∧ y ≤ 1 ∧ d ≤ y ^ 2} = Set.Icc (√d) 1 := by
    ext y
    simp only [Set.mem_ofPred_eq, Set.mem_Icc, Real.sqrt_le_iff]
    tauto
  rw [this, Real.volume_Icc]

#print axioms volume_slice_mid

/-- The height of Hammersley's sofa above the point `x`. -/

noncomputable def sofaHeight (r x : ℝ) : ℝ :=
  if x ≤ -r then √(1 - (x + r) ^ 2) else if x ≤ r then 1 - √(r ^ 2 - x ^ 2)
  else √(1 - (x - r) ^ 2)

lemma volume_sofa_slice (r x : ℝ) (h0 : 0 ≤ r) :
    volume (Prod.mk x ⁻¹' hammersleySofa r) = ENNReal.ofReal (sofaHeight r x) := by
  unfold sofaHeight
  split_ifs with ha hb
  · rw [← volume_slice_disc]
    congr 1
    ext y
    simp only [hammersleySofa, Set.mem_preimage, Set.mem_sdiff, Set.mem_union, Set.mem_ofPred_eq,
      not_lt]
    constructor
    · rintro ⟨(⟨⟨-, hy, hc⟩ | ⟨hx, hy, hc⟩⟩ | ⟨hx1, hx2, hy, hy1⟩), -⟩
      · exact ⟨hy, hc⟩
      · exact ⟨hy, by nlinarith⟩
      · exact ⟨hy, by nlinarith⟩
    · rintro ⟨hy, hc⟩
      exact ⟨Or.inl (Or.inl ⟨ha, hy, hc⟩), by nlinarith⟩
  · rw [← volume_slice_mid]
    congr 1
    ext y
    simp only [hammersleySofa, Set.mem_preimage, Set.mem_sdiff, Set.mem_union, Set.mem_ofPred_eq,
      not_lt]
    constructor
    · rintro ⟨(⟨⟨hx, hy, hc⟩ | ⟨hx, hy, hc⟩⟩ | ⟨hx1, hx2, hy, hy1⟩), hh⟩
      · exact absurd hx ha
      · exact ⟨hy, by nlinarith, by linarith⟩
      · exact ⟨hy, hy1, by linarith⟩
    · rintro ⟨hy, hy1, hd⟩
      exact ⟨Or.inr ⟨by linarith, hb, hy, hy1⟩, by linarith⟩
  · rw [← volume_slice_disc]
    congr 1
    ext y
    simp only [hammersleySofa, Set.mem_preimage, Set.mem_sdiff, Set.mem_union, Set.mem_ofPred_eq,
      not_lt]
    constructor
    · rintro ⟨(⟨⟨hx, hy, hc⟩ | ⟨hx, hy, hc⟩⟩ | ⟨hx1, hx2, hy, hy1⟩), -⟩
      · exact absurd hx ha
      · exact ⟨hy, hc⟩
      · exact absurd hx2 hb
    · rintro ⟨hy, hc⟩
      exact ⟨Or.inl (Or.inr ⟨by linarith, hy, hc⟩), by nlinarith⟩

#print axioms volume_sofa_slice

lemma measurableSet_hammersleySofa (r : ℝ) : MeasurableSet (hammersleySofa r) := by
  unfold hammersleySofa
  measurability

#print axioms measurableSet_hammersleySofa

lemma integral_sqrt_one_sub_sq_halves :
    (∫ x in (-1 : ℝ)..0, √(1 - x ^ 2)) = π / 4 ∧ (∫ x in (0 : ℝ)..1, √(1 - x ^ 2)) = π / 4 := by
  have hc : Continuous fun x : ℝ => √(1 - x ^ 2) := by fun_prop
  have hsum := intervalIntegral.integral_add_adjacent_intervals
    (hc.intervalIntegrable (μ := volume) (-1) 0) (hc.intervalIntegrable (μ := volume) 0 1)
  rw [integral_sqrt_one_sub_sq] at hsum
  have hsym : (∫ x in (0 : ℝ)..1, √(1 - x ^ 2)) = ∫ x in (-1 : ℝ)..0, √(1 - x ^ 2) := by
    have := intervalIntegral.integral_comp_neg (a := (0 : ℝ)) (b := 1) (fun x : ℝ => √(1 - x ^ 2))
    simpa using this
  constructor <;> linarith

#print axioms integral_sqrt_one_sub_sq_halves

lemma integral_sqrt_sq_sub_sq (r : ℝ) (h0 : 0 ≤ r) :
    (∫ x in (-r)..r, √(r ^ 2 - x ^ 2)) = π / 2 * r ^ 2 := by
  rcases h0.eq_or_lt with rfl | hr
  · simp
  have hpt : ∀ x : ℝ, √(r ^ 2 - x ^ 2) = r * √(1 - (x / r) ^ 2) := by
    intro x
    have : r ^ 2 - x ^ 2 = r ^ 2 * (1 - (x / r) ^ 2) := by field_simp
    rw [this, Real.sqrt_mul (by positivity), Real.sqrt_sq hr.le]
  simp_rw [hpt]
  rw [intervalIntegral.integral_const_mul,
    intervalIntegral.integral_comp_div (fun x : ℝ => √(1 - x ^ 2)) hr.ne',
    neg_div, div_self hr.ne', integral_sqrt_one_sub_sq]
  ring

#print axioms integral_sqrt_sq_sub_sq

lemma continuous_sofaHeight (r : ℝ) (h0 : 0 ≤ r) : Continuous (sofaHeight r) := by
  unfold sofaHeight
  refine Continuous.if_le (by fun_prop) (Continuous.if_le (by fun_prop) (by fun_prop)
    (by fun_prop) (by fun_prop) ?_) (by fun_prop) (by fun_prop) ?_
  · intro x hx
    rw [hx]; simp
  · intro x hx
    rw [hx]
    split_ifs with h
    · simp
    · exact absurd (by linarith) h

#print axioms continuous_sofaHeight

lemma integral_sofaHeight (r : ℝ) (h0 : 0 ≤ r) :
    ∫ x, sofaHeight r x = π / 2 + 2 * r - π / 2 * r ^ 2 := by
  have hc := continuous_sofaHeight r h0
  have s1 := intervalIntegral.integral_add_adjacent_intervals
    (hc.intervalIntegrable (μ := volume) (-r - 1) (-r)) (hc.intervalIntegrable (-r) (r + 1))
  have s2 := intervalIntegral.integral_add_adjacent_intervals
    (hc.intervalIntegrable (μ := volume) (-r) r) (hc.intervalIntegrable r (r + 1))
  rw [← MeasureTheory.setIntegral_eq_integral_of_forall_compl_eq_zero
    (s := Set.Ioc (-r - 1) (r + 1)), ← intervalIntegral.integral_of_le (by linarith), ← s1, ← s2]
  · have e1 : (∫ x in (-r - 1)..(-r), sofaHeight r x) = π / 4 := by
      rw [intervalIntegral.integral_congr (g := fun x => √(1 - (x + r) ^ 2))]
      · rw [intervalIntegral.integral_comp_add_right (fun x : ℝ => √(1 - x ^ 2)) r]
        rw [show -r - 1 + r = -1 by ring, neg_add_cancel]
        exact integral_sqrt_one_sub_sq_halves.1
      · intro x hx
        rw [Set.uIcc_of_le (by linarith), Set.mem_Icc] at hx
        simp [sofaHeight, hx.2]
    have e2 : (∫ x in (-r)..r, sofaHeight r x) = 2 * r - π / 2 * r ^ 2 := by
      rw [intervalIntegral.integral_congr (g := fun x => 1 - √(r ^ 2 - x ^ 2))]
      · rw [intervalIntegral.integral_sub (continuous_const.intervalIntegrable _ _)
          ((by fun_prop : Continuous fun x : ℝ => √(r ^ 2 - x ^ 2)).intervalIntegrable _ _),
          integral_sqrt_sq_sub_sq r h0]
        simp; ring
      · intro x hx
        rw [Set.uIcc_of_le (by linarith), Set.mem_Icc] at hx
        unfold sofaHeight
        split_ifs with h h'
        · have : x = -r := le_antisymm h hx.1
          subst this; simp
        · rfl
        · exact absurd hx.2 h'
    have e3 : (∫ x in r..(r + 1), sofaHeight r x) = π / 4 := by
      rw [intervalIntegral.integral_congr (g := fun x => √(1 - (x - r) ^ 2))]
      · rw [intervalIntegral.integral_comp_sub_right (fun x : ℝ => √(1 - x ^ 2)) r]
        rw [sub_self, show r + 1 - r = 1 by ring]
        exact integral_sqrt_one_sub_sq_halves.2
      · intro x hx
        rw [Set.uIcc_of_le (by linarith), Set.mem_Icc] at hx
        unfold sofaHeight
        split_ifs with h h'
        · have : x = 0 ∧ r = 0 := ⟨by linarith, by linarith⟩
          obtain ⟨rfl, rfl⟩ := this
          simp
        · have : x = r := le_antisymm h' hx.1
          subst this; simp
        · rfl
    rw [e1, e2, e3]; ring
  · intro x hx
    simp only [Set.mem_Ioc, not_and_or, not_lt, not_le] at hx
    unfold sofaHeight
    rcases hx with hx | hx <;> split_ifs <;>
      first | (exfalso; linarith) | exact Real.sqrt_eq_zero'.2 (by nlinarith)

#print axioms integral_sofaHeight

lemma volume_hammersleySofa (r : ℝ) (h0 : 0 ≤ r) (h1 : r ≤ 1) :
    volume (hammersleySofa r) = ENNReal.ofReal (π / 2 + 2 * r - π / 2 * r ^ 2) := by
  rw [Measure.volume_eq_prod, Measure.prod_apply (measurableSet_hammersleySofa r)]
  simp_rw [volume_sofa_slice r _ h0]
  rw [← MeasureTheory.ofReal_integral_eq_lintegral_ofReal, integral_sofaHeight r h0]
  · refine (continuous_sofaHeight r h0).integrable_of_hasCompactSupport ?_
    refine HasCompactSupport.intro (K := Set.Icc (-r - 1) (r + 1)) isCompact_Icc ?_
    intro x hx
    simp only [Set.mem_Icc, not_and_or, not_le] at hx
    unfold sofaHeight
    rcases hx with hx | hx <;> split_ifs <;>
      first | (exfalso; linarith) | exact Real.sqrt_eq_zero'.2 (by nlinarith)
  · refine Filter.Eventually.of_forall fun x => ?_
    simp only [Pi.zero_apply]
    unfold sofaHeight
    split_ifs
    · positivity
    · have : √(r ^ 2 - x ^ 2) ≤ √(r ^ 2) := Real.sqrt_le_sqrt (by nlinarith)
      rw [Real.sqrt_sq h0] at this
      linarith
    · positivity

#print axioms volume_hammersleySofa

lemma sofa_area_completed_square (r : ℝ) :
    π / 2 + 2 * r - π / 2 * r ^ 2 = π / 2 + 2 / π - π / 2 * (r - 2 / π) ^ 2 := by
  have := Real.pi_pos.ne'
  field_simp
  ring

#print axioms sofa_area_completed_square

/-- Hammersley's best hole. Among Hammersley's sofas with hole radius `r` from 0 to 1, the
largest area is `π/2 + 2/π`, and only the hole of radius `2/π` reaches it. -/
theorem hammersley_sofa_largest_at_two_over_pi :
    IsGreatest ((fun r => volume (hammersleySofa r)) '' Set.Icc 0 1)
        (ENNReal.ofReal (π / 2 + 2 / π)) ∧
      ∀ r ∈ Set.Icc (0 : ℝ) 1,
        volume (hammersleySofa r) = ENNReal.ofReal (π / 2 + 2 / π) → r = 2 / π := by
  have hpi := Real.two_le_pi
  have hpos := Real.pi_pos
  refine ⟨⟨⟨2 / π, ⟨by positivity, (div_le_one hpos).2 (by linarith)⟩, ?_⟩, ?_⟩, ?_⟩
  · simp only
    rw [volume_hammersleySofa _ (by positivity) ((div_le_one hpos).2 (by linarith)), sofa_area_completed_square]
    simp
  · rintro _ ⟨r, hr, rfl⟩
    simp only
    rw [volume_hammersleySofa r hr.1 hr.2, sofa_area_completed_square]
    apply ENNReal.ofReal_le_ofReal
    nlinarith [sq_nonneg (r - 2 / π)]
  · intro r hr h
    have hA : 0 ≤ π / 2 + 2 * r - π / 2 * r ^ 2 := by
      have : 0 ≤ π / 2 * (1 - r ^ 2) := mul_nonneg (by positivity) (by nlinarith [hr.1, hr.2])
      nlinarith [hr.1]
    rw [volume_hammersleySofa r hr.1 hr.2, ENNReal.ofReal_eq_ofReal_iff hA (by positivity),
      sofa_area_completed_square] at h
    have h2 : π / 2 * (r - 2 / π) ^ 2 = 0 := by linarith
    rcases mul_eq_zero.1 h2 with h3 | h3
    · linarith
    · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h3
      linarith


/-- Hammersley's area, piece by piece (Step 2). For a hole radius `r` from 0 to 1, the two
quarter discs give `π/2`, the block gives `2r`, and the hole removes `πr²/2`, so the sofa's
area is `A(r) = π/2 + 2r − (π/2) r²`. -/
theorem hammersley_sofa_area (r : ℝ) (h0 : 0 ≤ r) (h1 : r ≤ 1) :
    volume (hammersleySofa r) = ENNReal.ofReal (π / 2 + 2 * r - π / 2 * r ^ 2) := by
  exact volume_hammersleySofa r h0 h1

/-- Prince Rupert's cube, with Nieuwland's tunnel (Step 5). The number `3√2/4` is larger than
1, and every cube of side below `3√2/4` passes through a hole in a unit cube; in particular a
unit cube passes through a hole in another unit cube. -/
theorem nieuwland_cube_passes :
    1 < 3 * √2 / 4 ∧ ∀ s : ℝ, s < 3 * √2 / 4 → PassesThrough (cube s) (cube 1) := by
  have h2 : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have h2pos : 0 < √2 := by positivity
  refine ⟨?_, ?_⟩
  · nlinarith
  intro s hs
  refine ⟨!![√2/2, √2/2, 0; -(√2/2), √2/2, 0; 0, 0, 1], ?_,
    !![2/3, 1/3, -2/3; 1/3, 2/3, 2/3; 2/3, -2/3, 1/3], ?_, 0, ?_⟩
  · rw [mem_specialOrthogonalGroup_iff, mem_orthogonalGroup_iff]
    refine ⟨?_, ?_⟩
    · ext i j
      fin_cases i <;> fin_cases j <;>
        simp [Matrix.mul_apply, Fin.sum_univ_three] <;> nlinarith
    · simp [Matrix.det_fin_three]; nlinarith
  · rw [mem_specialOrthogonalGroup_iff, mem_orthogonalGroup_iff]
    refine ⟨?_, ?_⟩
    · ext i j
      fin_cases i <;> fin_cases j <;>
        simp [Matrix.mul_apply, Fin.sum_univ_three] <;> norm_num
    · simp [Matrix.det_fin_three]; norm_num
  · -- the open diamond |p 0| + |p 1| < 3/4 lies in the shadow of the turned unit cube
    let D : Set (Fin 2 → ℝ) := {p | |p 0| + |p 1| < 3 / 4}
    have hDopen : IsOpen D := isOpen_lt (by fun_prop) continuous_const
    have hD : D ⊆ (fun x => shadow (!![2/3, 1/3, -2/3; 1/3, 2/3, 2/3; 2/3, -2/3, 1/3] *ᵥ x)) ''
        cube 1 := by
      intro p hp
      simp only [D, Set.mem_ofPred_eq] at hp
      refine ⟨![(2 * p 0 + p 1) / 3, (p 0 + 2 * p 1) / 3, (2 * p 1 - 2 * p 0) / 3], ?_, ?_⟩
      · intro i
        fin_cases i <;> simp <;> rw [abs_le] <;> constructor <;>
          cases abs_cases (p 0) <;> cases abs_cases (p 1) <;> linarith
      · ext i
        fin_cases i <;> simp [shadow, Matrix.mulVec, dotProduct, Fin.sum_univ_three] <;> ring
    refine subset_trans ?_ (interior_maximal hD hDopen)
    rintro _ ⟨x, hx, rfl⟩
    have h0 := hx 0
    have h1 := hx 1
    simp only [D, Set.mem_ofPred_eq]
    simp [shadow, Matrix.mulVec, dotProduct, Fin.sum_univ_three]
    rw [abs_le] at h0 h1
    have key : |x 0 + x 1| + |x 1 - x 0| ≤ s := by
      cases abs_cases (x 0 + x 1) <;> cases abs_cases (x 1 - x 0) <;> linarith
    have e1 : √2 / 2 * x 0 + √2 / 2 * x 1 = √2 / 2 * (x 0 + x 1) := by ring
    have e2 : -(√2 / 2 * x 0) + √2 / 2 * x 1 = √2 / 2 * (x 1 - x 0) := by ring
    have hpos : (0 : ℝ) ≤ √2 / 2 := by positivity
    rw [e1, e2, abs_mul, abs_mul, abs_of_nonneg hpos, ← mul_add]
    calc √2 / 2 * (|x 0 + x 1| + |x 1 - x 0|) ≤ √2 / 2 * s := by gcongr
      _ < √2 / 2 * (3 * √2 / 4) := by gcongr
      _ = 3 / 4 := by nlinarith

-- The Noperthedron's first corner C1 is exactly distance 1 from the centre.
example : (152024884 : ℕ) ^ 2 + 210152163 ^ 2 = 259375205 ^ 2 := by norm_num
-- Three corners, each turned 15 ways and reflected through the centre: 90 corners.
example : 3 * (15 * 2) = 90 := by norm_num
-- The split: boxes ruled out by the global and the local theorem.
example : (17492530 : ℕ) + 622715 = 18115245 := by norm_num
-- Nieuwland's square: each side squared is (3/4)^2 + (3/4)^2 = 9/8.
example : (3 / 4 : ℚ) ^ 2 + (3 / 4) ^ 2 = 9 / 8 := by norm_num
-- The smallest edge test value 1/4 gives side 3√2 × 1/4, whose square is 18 × (1/4)^2 = 9/8.
example : (18 : ℚ) * (1 / 4) ^ 2 = 9 / 8 := by norm_num
-- A hole as wide as the hallway, r = 1: area π/2 + 2 − π/2 = 2.
example : π / 2 + 2 * 1 - π / 2 * 1 ^ 2 = 2 := by norm_num

#print axioms hammersley_sofa_largest_at_two_over_pi
#print axioms hammersley_sofa_area
#print axioms nieuwland_cube_passes
