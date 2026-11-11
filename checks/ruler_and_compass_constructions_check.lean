-- Ruler and compass: the points built from 0 and 1 by ruler and compass give exactly the real lengths reachable from 1 by the four operations and square roots, so a real root of a fraction-coefficient cubic with no fraction root, such as the 7-gon's cosine, cos 20° or the cube root of 2, can never be built.
import Mathlib.LinearAlgebra.AffineSpace.AffineSubspace.Defs
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.LinearAlgebra.AffineSpace.AffineSubspace.Basic
import Mathlib.Algebra.Field.Subfield.Basic
import Mathlib.RingTheory.Coprime.Lemmas
import Mathlib.Tactic.IntervalCases

open Real

/-- The points of the plane (the complex numbers) that ruler and compass build from the two
starting points 0 and 1 in finitely many steps. The ruler draws the line through two different
known points; the compass draws the circle about one known point through another. A new point is
a crossing of two different lines, of a line and a circle, or of two different circles. -/
inductive Constructible : ℂ → Prop
  | zero : Constructible 0
  | one : Constructible 1
  | lineLine {a b c d z : ℂ} : Constructible a → Constructible b → Constructible c →
      Constructible d → a ≠ b → c ≠ d → line[ℝ, a, b] ≠ line[ℝ, c, d] →
      z ∈ line[ℝ, a, b] → z ∈ line[ℝ, c, d] → Constructible z
  | lineCircle {a b c d z : ℂ} : Constructible a → Constructible b → Constructible c →
      Constructible d → a ≠ b → z ∈ line[ℝ, a, b] → dist z c = dist d c → Constructible z
  | circleCircle {a b c d z : ℂ} : Constructible a → Constructible b → Constructible c →
      Constructible d → (a, dist b a) ≠ (c, dist d c) →
      dist z a = dist b a → dist z c = dist d c → Constructible z

/-- The real numbers reachable from 1 by adding, subtracting, multiplying, dividing by anything
but zero, and taking the square root of a number that is not negative. -/
inductive SqrtReachable : ℝ → Prop
  | one : SqrtReachable 1
  | add {x y : ℝ} : SqrtReachable x → SqrtReachable y → SqrtReachable (x + y)
  | sub {x y : ℝ} : SqrtReachable x → SqrtReachable y → SqrtReachable (x - y)
  | mul {x y : ℝ} : SqrtReachable x → SqrtReachable y → SqrtReachable (x * y)
  | div {x y : ℝ} : SqrtReachable x → SqrtReachable y → y ≠ 0 → SqrtReachable (x / y)
  | sqrt {x : ℝ} : SqrtReachable x → 0 ≤ x → SqrtReachable (Real.sqrt x)

namespace RCHelp

theorem sr_zero : SqrtReachable 0 := by
  have := SqrtReachable.sub SqrtReachable.one SqrtReachable.one
  simpa using this

theorem sr_neg {x : ℝ} (h : SqrtReachable x) : SqrtReachable (-x) := by
  have := SqrtReachable.sub sr_zero h
  simpa using this

theorem sr_div' {x y : ℝ} (hx : SqrtReachable x) (hy : SqrtReachable y) :
    SqrtReachable (x / y) := by
  by_cases h : y = 0
  · subst h; simpa using sr_zero
  · exact SqrtReachable.div hx hy h

theorem sr_two : SqrtReachable 2 := by
  have := SqrtReachable.add SqrtReachable.one SqrtReachable.one
  norm_num at this; exact this

/-- A real root of a quadratic with reachable coefficients is reachable. -/
theorem sr_quad {A B C t : ℝ} (hA : SqrtReachable A) (hB : SqrtReachable B)
    (hC : SqrtReachable C) (hA0 : A ≠ 0) (h : A * t ^ 2 + 2 * B * t + C = 0) :
    SqrtReachable t := by
  have hsq : (A * t + B) ^ 2 = B ^ 2 - A * C := by linear_combination A * h
  have hD : SqrtReachable (B ^ 2 - A * C) :=
    SqrtReachable.sub (by simpa [pow_two] using SqrtReachable.mul hB hB) (SqrtReachable.mul hA hC)
  have hs : SqrtReachable (Real.sqrt (B ^ 2 - A * C)) :=
    SqrtReachable.sqrt hD (by rw [← hsq]; positivity)
  have habs : |A * t + B| = Real.sqrt (B ^ 2 - A * C) := by
    rw [← hsq, Real.sqrt_sq_eq_abs]
  have hlin : SqrtReachable (A * t + B) := by
    rcases abs_choice (A * t + B) with h1 | h1
    · rw [← h1, habs]; exact hs
    · have : A * t + B = -|A * t + B| := by linarith
      rw [this, habs]; exact sr_neg hs
  have : t = ((A * t + B) - B) / A := by field_simp; ring
  rw [this]
  exact sr_div' (SqrtReachable.sub hlin hB) hA

/-- A crossing of a line and a circle, in coordinates, case e1 ≠ 0. -/
theorem sr_lc_aux {e1 e2 h p1 p2 R x y : ℝ} (he1 : SqrtReachable e1) (he2 : SqrtReachable e2)
    (hh : SqrtReachable h) (hp1 : SqrtReachable p1) (hp2 : SqrtReachable p2)
    (hR : SqrtReachable R) (h0 : e1 ≠ 0) (hl : x * e1 + y * e2 = h)
    (hc : (x - p1) ^ 2 + (y - p2) ^ 2 = R) : SqrtReachable x ∧ SqrtReachable y := by
  have hx : x = (h - y * e2) / e1 := by field_simp; linarith
  have hy : SqrtReachable y := by
    refine sr_quad (A := e1 ^ 2 + e2 ^ 2) (B := -e2 * (h - p1 * e1) - e1 ^ 2 * p2)
      (C := (h - p1 * e1) ^ 2 + e1 ^ 2 * p2 ^ 2 - R * e1 ^ 2) ?_ ?_ ?_ ?_ ?_
    · simp only [pow_two]
      exact SqrtReachable.add (SqrtReachable.mul he1 he1) (SqrtReachable.mul he2 he2)
    · simp only [pow_two]
      exact SqrtReachable.sub (SqrtReachable.mul (sr_neg he2)
        (SqrtReachable.sub hh (SqrtReachable.mul hp1 he1)))
        (SqrtReachable.mul (SqrtReachable.mul he1 he1) hp2)
    · simp only [pow_two]
      have hq := SqrtReachable.sub hh (SqrtReachable.mul hp1 he1)
      exact SqrtReachable.sub (SqrtReachable.add (SqrtReachable.mul hq hq)
        (SqrtReachable.mul (SqrtReachable.mul he1 he1) (SqrtReachable.mul hp2 hp2)))
        (SqrtReachable.mul hR (SqrtReachable.mul he1 he1))
    · positivity
    · rw [hx] at hc
      field_simp at hc
      linear_combination hc
  refine ⟨?_, hy⟩
  rw [hx]
  exact sr_div' (SqrtReachable.sub hh (SqrtReachable.mul hy he2)) he1

theorem sr_lc {e1 e2 h p1 p2 R x y : ℝ} (he1 : SqrtReachable e1) (he2 : SqrtReachable e2)
    (hh : SqrtReachable h) (hp1 : SqrtReachable p1) (hp2 : SqrtReachable p2)
    (hR : SqrtReachable R) (h0 : e1 ≠ 0 ∨ e2 ≠ 0) (hl : x * e1 + y * e2 = h)
    (hc : (x - p1) ^ 2 + (y - p2) ^ 2 = R) : SqrtReachable x ∧ SqrtReachable y := by
  rcases h0 with h0 | h0
  · exact sr_lc_aux he1 he2 hh hp1 hp2 hR h0 hl hc
  · have := sr_lc_aux (x := y) (y := x) he2 he1 hh hp2 hp1 hR h0 (by linarith) (by linarith)
    exact ⟨this.2, this.1⟩

theorem sr_sq {x : ℝ} (h : SqrtReachable x) : SqrtReachable (x ^ 2) := by
  simpa [pow_two] using SqrtReachable.mul h h

macro "sr_tac" : tactic => `(tactic| (repeat (first | assumption | exact SqrtReachable.one | exact sr_zero | exact sr_two | apply SqrtReachable.add | apply SqrtReachable.sub | apply sr_div' | apply SqrtReachable.mul | apply sr_neg | apply sr_sq)))

theorem ne_coords {a b : ℂ} (h : a ≠ b) : b.re - a.re ≠ 0 ∨ b.im - a.im ≠ 0 := by
  by_contra h'
  push Not at h'
  apply h
  apply Complex.ext <;> linarith [h'.1, h'.2]

theorem mem_line_of {a b z : ℂ} (t : ℝ) (h : z = a + t * (b - a)) : z ∈ line[ℝ, a, b] := by
  rw [mem_affineSpan_pair_iff_exists_lineMap_eq]
  refine ⟨t, ?_⟩
  rw [AffineMap.lineMap_apply_module', h, Complex.real_smul]; ring

theorem mem_line_iff {a b z : ℂ} (hab : a ≠ b) : z ∈ line[ℝ, a, b] ↔
    (z.re - a.re) * (b.im - a.im) = (z.im - a.im) * (b.re - a.re) := by
  constructor
  · intro h
    rw [mem_affineSpan_pair_iff_exists_lineMap_eq] at h
    obtain ⟨t, rfl⟩ := h
    simp [AffineMap.lineMap_apply_module', Complex.real_smul]
    ring
  · intro h
    have hw : (b.re - a.re) ^ 2 + (b.im - a.im) ^ 2 ≠ 0 := by
      intro h0
      apply hab
      have h1 : b.re - a.re = 0 := by nlinarith [sq_nonneg (b.re - a.re), sq_nonneg (b.im - a.im)]
      have h2 : b.im - a.im = 0 := by nlinarith [sq_nonneg (b.re - a.re), sq_nonneg (b.im - a.im)]
      apply Complex.ext <;> linarith
    apply mem_line_of (((z.re - a.re) * (b.re - a.re) + (z.im - a.im) * (b.im - a.im)) /
      ((b.re - a.re) ^ 2 + (b.im - a.im) ^ 2))
    apply Complex.ext
    · simp only [Complex.add_re, Complex.mul_re, Complex.ofReal_re, Complex.ofReal_im,
        Complex.sub_re, Complex.sub_im, zero_mul, sub_zero]
      field_simp
      linear_combination (b.im - a.im) * h
    · simp only [Complex.add_im, Complex.mul_im, Complex.ofReal_re, Complex.ofReal_im,
        Complex.sub_re, Complex.sub_im, zero_mul, add_zero]
      field_simp
      linear_combination -(b.re - a.re) * h

theorem dist_sq_eq {z c d : ℂ} (h : dist z c = dist d c) :
    (z.re - c.re) ^ 2 + (z.im - c.im) ^ 2 = (d.re - c.re) ^ 2 + (d.im - c.im) ^ 2 := by
  have h2 : dist z c ^ 2 = dist d c ^ 2 := by rw [h]
  simp only [Complex.dist_eq, Complex.sq_norm, Complex.normSq_apply, Complex.sub_re,
    Complex.sub_im] at h2
  linear_combination h2

/-- Every point that ruler and compass build has reachable coordinates. -/
theorem constructible_coords {z : ℂ} (h : Constructible z) :
    SqrtReachable z.re ∧ SqrtReachable z.im := by
  induction h with
  | zero => simpa using sr_zero
  | one => simpa using ⟨SqrtReachable.one, sr_zero⟩
  | @lineLine a b c d z _ _ _ _ hab hcd hne hz1 hz2 iha ihb ihc ihd =>
    rw [mem_line_iff hab] at hz1
    rw [mem_line_iff hcd] at hz2
    obtain ⟨ar, ai⟩ := iha
    obtain ⟨br, bi⟩ := ihb
    obtain ⟨cr, ci⟩ := ihc
    obtain ⟨dr, di⟩ := ihd
    set w1 := b.re - a.re with hw1
    set w2 := b.im - a.im with hw2
    set v1 := d.re - c.re with hv1
    set v2 := d.im - c.im with hv2
    by_cases hD : w1 * v2 - w2 * v1 = 0
    · exfalso
      apply hne
      have hX1 : ((z.re - c.re) * w2 - (z.im - c.im) * w1) * v1 = 0 := by
        linear_combination w1 * hz2 - (z.re - c.re) * hD
      have hX2 : ((z.re - c.re) * w2 - (z.im - c.im) * w1) * v2 = 0 := by
        linear_combination w2 * hz2 - (z.im - c.im) * hD
      have hX : (z.re - c.re) * w2 - (z.im - c.im) * w1 = 0 := by
        rcases ne_coords hcd with h | h
        · exact (mul_eq_zero.mp hX1).resolve_right h
        · exact (mul_eq_zero.mp hX2).resolve_right h
      have hc : c ∈ line[ℝ, a, b] := by
        rw [mem_line_iff hab]
        linear_combination hz1 - hX
      have hd : d ∈ line[ℝ, a, b] := by
        rw [mem_line_iff hab]
        rw [mem_line_iff hab] at hc
        linear_combination hc - hD
      exact (affineSpan_pair_eq_of_mem_of_mem_of_ne hc hd hcd).symm
    · have e1 : z.re = (w1 * (c.re * v2 - c.im * v1) - v1 * (a.re * w2 - a.im * w1)) /
          (w1 * v2 - w2 * v1) := by
        rw [eq_div_iff hD]
        linear_combination (-v1) * hz1 + w1 * hz2
      have e2 : z.im = (w2 * (c.re * v2 - c.im * v1) - v2 * (a.re * w2 - a.im * w1)) /
          (w1 * v2 - w2 * v1) := by
        rw [eq_div_iff hD]
        linear_combination (-v2) * hz1 + w2 * hz2
      rw [e1, e2]
      constructor <;> sr_tac
  | @lineCircle a b c d z _ _ _ _ hab hz1 hz2 iha ihb ihc ihd =>
    rw [mem_line_iff hab] at hz1
    have hc := dist_sq_eq hz2
    obtain ⟨ar, ai⟩ := iha
    obtain ⟨br, bi⟩ := ihb
    obtain ⟨cr, ci⟩ := ihc
    obtain ⟨dr, di⟩ := ihd
    refine sr_lc (e1 := b.im - a.im) (e2 := -(b.re - a.re))
      (h := a.re * (b.im - a.im) - a.im * (b.re - a.re)) (by sr_tac) (by sr_tac) (by sr_tac)
      cr ci (by sr_tac) ?_ (by linear_combination hz1) hc
    rcases ne_coords hab with h | h
    · exact Or.inr (neg_ne_zero.mpr h)
    · exact Or.inl h
  | @circleCircle a b c d z _ _ _ _ hne hz1 hz2 iha ihb ihc ihd =>
    obtain ⟨ar, ai⟩ := iha
    obtain ⟨br, bi⟩ := ihb
    obtain ⟨cr, ci⟩ := ihc
    obtain ⟨dr, di⟩ := ihd
    have hac : a ≠ c := by
      rintro rfl
      apply hne
      rw [← hz1, ← hz2]
    have h1 := dist_sq_eq hz1
    have h2 := dist_sq_eq hz2
    refine sr_lc (e1 := 2 * (c.re - a.re)) (e2 := 2 * (c.im - a.im))
      (h := ((b.re - a.re) ^ 2 + (b.im - a.im) ^ 2) - ((d.re - c.re) ^ 2 + (d.im - c.im) ^ 2)
        + c.re ^ 2 - a.re ^ 2 + c.im ^ 2 - a.im ^ 2) (by sr_tac) (by sr_tac) (by sr_tac)
      ar ai (by sr_tac) ?_ (by linear_combination h1 - h2) h1
    rcases ne_coords hac with h | h
    · exact Or.inl (mul_ne_zero two_ne_zero h)
    · exact Or.inr (mul_ne_zero two_ne_zero h)

end RCHelp

open RCHelp

#print axioms sr_zero
#print axioms sr_neg
#print axioms sr_div'
#print axioms sr_two
#print axioms sr_quad
#print axioms sr_lc_aux
#print axioms sr_lc
#print axioms sr_sq
#print axioms ne_coords
#print axioms mem_line_of
#print axioms mem_line_iff
#print axioms dist_sq_eq
#print axioms constructible_coords

namespace RCHelp

/-- Fields reached from the fractions by adjoining square roots one at a time. -/
inductive Tower : Subfield ℝ → Prop
  | base : Tower (Rat.castHom ℝ).fieldRange
  | step {K : Subfield ℝ} {s : ℝ} : Tower K → s * s ∈ K →
      Tower (Subfield.closure (insert s (K : Set ℝ)))

theorem adjoin_repr {K : Subfield ℝ} {s x : ℝ} (hs : s * s ∈ K)
    (hx : x ∈ Subfield.closure (insert s (K : Set ℝ))) :
    ∃ p ∈ K, ∃ q ∈ K, x = p + q * s := by
  induction hx using Subfield.closure_induction with
  | mem x hx =>
    rcases hx with rfl | hx
    · exact ⟨0, zero_mem _, 1, one_mem _, by ring⟩
    · exact ⟨x, hx, 0, zero_mem _, by ring⟩
  | one => exact ⟨1, one_mem _, 0, zero_mem _, by ring⟩
  | add x y _ _ ihx ihy =>
    obtain ⟨p, hp, q, hq, rfl⟩ := ihx
    obtain ⟨p', hp', q', hq', rfl⟩ := ihy
    exact ⟨p + p', add_mem hp hp', q + q', add_mem hq hq', by ring⟩
  | neg x _ ihx =>
    obtain ⟨p, hp, q, hq, rfl⟩ := ihx
    exact ⟨-p, neg_mem hp, -q, neg_mem hq, by ring⟩
  | mul x y _ _ ihx ihy =>
    obtain ⟨p, hp, q, hq, rfl⟩ := ihx
    obtain ⟨p', hp', q', hq', rfl⟩ := ihy
    refine ⟨p * p' + q * q' * (s * s), add_mem (mul_mem hp hp') (mul_mem (mul_mem hq hq') hs),
      p * q' + q * p', add_mem (mul_mem hp hq') (mul_mem hq hp'), by ring⟩
  | inv x _ ihx =>
    obtain ⟨p, hp, q, hq, rfl⟩ := ihx
    by_cases hD : p * p - q * q * (s * s) = 0
    · by_cases hq0 : q = 0
      · subst hq0
        have : p = 0 := by simpa [mul_self_eq_zero] using hD
        subst this
        exact ⟨0, zero_mem _, 0, zero_mem _, by simp⟩
      · by_cases hps : p + q * s = 0
        · exact ⟨0, zero_mem _, 0, zero_mem _, by rw [hps]; simp⟩
        · have hfac : (p + q * s) * (p - q * s) = 0 := by linear_combination hD
          have hm : p - q * s = 0 := (mul_eq_zero.mp hfac).resolve_left hps
          have hsK : s ∈ K := by
            have : s = p / q := by field_simp; linarith
            rw [this]; exact div_mem hp hq
          exact ⟨(p + q * s)⁻¹, inv_mem (add_mem hp (mul_mem hq hsK)), 0, zero_mem _, by ring⟩
    · refine ⟨p / (p * p - q * q * (s * s)), div_mem hp ?_, -q / (p * p - q * q * (s * s)),
        div_mem (neg_mem hq) ?_, ?_⟩
      · exact sub_mem (mul_mem hp hp) (mul_mem (mul_mem hq hq) hs)
      · exact sub_mem (mul_mem hp hp) (mul_mem (mul_mem hq hq) hs)
      · have hps : p + q * s ≠ 0 := by
          intro h0
          apply hD
          have : p = -(q * s) := by linarith
          rw [this]; ring
        have hD2 : p * p - q * q * (s * s) = (p + q * s) * (p - q * s) := by ring
        rw [hD2] at hD ⊢
        have hm : p - q * s ≠ 0 := fun h0 => hD (by rw [h0, mul_zero])
        field_simp
        ring

theorem tower_merge {K1 K2 : Subfield ℝ} (h1 : Tower K1) (h2 : Tower K2) :
    ∃ K, Tower K ∧ K1 ≤ K ∧ K2 ≤ K := by
  induction h2 with
  | base =>
    refine ⟨K1, h1, le_rfl, ?_⟩
    rintro _ ⟨q, rfl⟩
    exact SubfieldClass.ratCast_mem K1 q
  | @step K2 s _ hs ih =>
    obtain ⟨K, hK, h1K, h2K⟩ := ih
    refine ⟨Subfield.closure (insert s (K : Set ℝ)), Tower.step hK (h2K hs), ?_, ?_⟩
    · exact le_trans h1K (fun x hx => Subfield.subset_closure (Set.mem_insert_of_mem _ hx))
    · exact Subfield.closure_mono (Set.insert_subset_insert h2K)

theorem sr_tower {x : ℝ} (h : SqrtReachable x) : ∃ K, Tower K ∧ x ∈ K := by
  induction h with
  | one => exact ⟨_, Tower.base, one_mem _⟩
  | add _ _ ihx ihy =>
    obtain ⟨K1, h1, hx⟩ := ihx
    obtain ⟨K2, h2, hy⟩ := ihy
    obtain ⟨K, hK, l1, l2⟩ := tower_merge h1 h2
    exact ⟨K, hK, add_mem (l1 hx) (l2 hy)⟩
  | sub _ _ ihx ihy =>
    obtain ⟨K1, h1, hx⟩ := ihx
    obtain ⟨K2, h2, hy⟩ := ihy
    obtain ⟨K, hK, l1, l2⟩ := tower_merge h1 h2
    exact ⟨K, hK, sub_mem (l1 hx) (l2 hy)⟩
  | mul _ _ ihx ihy =>
    obtain ⟨K1, h1, hx⟩ := ihx
    obtain ⟨K2, h2, hy⟩ := ihy
    obtain ⟨K, hK, l1, l2⟩ := tower_merge h1 h2
    exact ⟨K, hK, mul_mem (l1 hx) (l2 hy)⟩
  | div _ _ _ ihx ihy =>
    obtain ⟨K1, h1, hx⟩ := ihx
    obtain ⟨K2, h2, hy⟩ := ihy
    obtain ⟨K, hK, l1, l2⟩ := tower_merge h1 h2
    exact ⟨K, hK, div_mem (l1 hx) (l2 hy)⟩
  | @sqrt x _ hx0 ihx =>
    obtain ⟨K, hK, hx⟩ := ihx
    refine ⟨_, Tower.step (s := Real.sqrt x) hK ?_, Subfield.subset_closure (Set.mem_insert _ _)⟩
    rw [Real.mul_self_sqrt hx0]; exact hx

/-- If a cubic has two different roots, the third root (from the sum of the roots) is a root. -/
theorem third_root {a b c d x1 x2 : ℝ} (ha : a ≠ 0) (hne : x1 ≠ x2)
    (h1 : a * x1 ^ 3 + b * x1 ^ 2 + c * x1 + d = 0) (h2 : a * x2 ^ 3 + b * x2 ^ 2 + c * x2 + d = 0) :
    a * (-b / a - x1 - x2) ^ 3 + b * (-b / a - x1 - x2) ^ 2 + c * (-b / a - x1 - x2) + d = 0 := by
  have he : a * (x1 ^ 2 + x1 * x2 + x2 ^ 2) + b * (x1 + x2) + c = 0 := by
    have : (x1 - x2) * (a * (x1 ^ 2 + x1 * x2 + x2 ^ 2) + b * (x1 + x2) + c) = 0 := by
      linear_combination h1 - h2
    exact (mul_eq_zero.mp this).resolve_left (sub_ne_zero.mpr hne)
  set r := -b / a - x1 - x2 with hr_def
  have hr : a * (r + x1 + x2) + b = 0 := by rw [hr_def]; field_simp; ring
  linear_combination h1 + (r - x1) * he + (r - x1) * (r - x2) * hr

theorem cubic_descend {K : Subfield ℝ} {s : ℝ} (hs : s * s ∈ K) {a b c d : ℝ} (ha0 : a ≠ 0)
    (ha : a ∈ K) (hb : b ∈ K) (hc : c ∈ K) (hd : d ∈ K) {x : ℝ}
    (hx : x ∈ Subfield.closure (insert s (K : Set ℝ)))
    (hf : a * x ^ 3 + b * x ^ 2 + c * x + d = 0) :
    ∃ y ∈ K, a * y ^ 3 + b * y ^ 2 + c * y + d = 0 := by
  obtain ⟨p, hp, q, hq, rfl⟩ := adjoin_repr hs hx
  by_cases hsK : s ∈ K
  · exact ⟨p + q * s, add_mem hp (mul_mem hq hsK), hf⟩
  by_cases hq0 : q = 0
  · subst hq0
    exact ⟨p, hp, by simpa using hf⟩
  set t := s * s with ht
  set A := a * (p ^ 3 + 3 * p * q ^ 2 * t) + b * (p ^ 2 + q ^ 2 * t) + c * p + d with hA
  set B := a * (3 * p ^ 2 * q + q ^ 3 * t) + b * (2 * p * q) + c * q with hB
  have hAK : A ∈ K := by
    rw [hA]
    have h3 : (3 : ℝ) ∈ K := by simp
    simp only [pow_succ, pow_zero, one_mul]
    repeat (first | assumption | apply add_mem | apply mul_mem)
  have hBK : B ∈ K := by
    rw [hB]
    have h3 : (3 : ℝ) ∈ K := by simp
    have h2 : (2 : ℝ) ∈ K := by simp
    simp only [pow_succ, pow_zero, one_mul]
    repeat (first | assumption | apply add_mem | apply mul_mem)
  have hsplit : a * (p + q * s) ^ 3 + b * (p + q * s) ^ 2 + c * (p + q * s) + d = A + B * s := by
    rw [hA, hB, ht]; ring
  have hB0 : B = 0 := by
    by_contra hB0
    apply hsK
    have hAB : A + B * s = 0 := hsplit ▸ hf
    have : s = -A / B := by
      rw [eq_div_iff hB0]
      linear_combination hAB
    rw [this]; exact div_mem (neg_mem hAK) hBK
  have hA0 : A = 0 := by rw [hsplit, hB0] at hf; simpa using hf
  have hconj : a * (p - q * s) ^ 3 + b * (p - q * s) ^ 2 + c * (p - q * s) + d = 0 := by
    have : a * (p - q * s) ^ 3 + b * (p - q * s) ^ 2 + c * (p - q * s) + d = A - B * s := by
      rw [hA, hB, ht]; ring
    rw [this, hA0, hB0]; ring
  have hs0 : s ≠ 0 := by
    rintro rfl; exact hsK (zero_mem _)
  have hne : p + q * s ≠ p - q * s := by
    intro h
    have : q * s = 0 := by linarith
    rcases mul_eq_zero.mp this with h' | h'
    · exact hq0 h'
    · exact hs0 h'
  refine ⟨-b / a - (p + q * s) - (p - q * s), ?_, third_root ha0 hne hf hconj⟩
  have : -b / a - (p + q * s) - (p - q * s) = -b / a - (p + p) := by ring
  rw [this]
  exact sub_mem (div_mem (neg_mem hb) ha) (add_mem hp hp)

theorem tower_cubic {K : Subfield ℝ} (hK : Tower K) (a b c d : ℚ) (ha : a ≠ 0) :
    ∀ x ∈ K, (a : ℝ) * x ^ 3 + (b : ℝ) * x ^ 2 + (c : ℝ) * x + (d : ℝ) = 0 →
      ∃ q : ℚ, a * q ^ 3 + b * q ^ 2 + c * q + d = 0 := by
  induction hK with
  | base =>
    rintro _ ⟨q, rfl⟩ hx
    refine ⟨q, ?_⟩
    have : ((a * q ^ 3 + b * q ^ 2 + c * q + d : ℚ) : ℝ) = 0 := by
      simpa using hx
    exact_mod_cast this
  | @step K s _ hs ih =>
    intro x hx hf
    obtain ⟨y, hy, hfy⟩ := cubic_descend hs (by exact_mod_cast ha)
      (SubfieldClass.ratCast_mem K a) (SubfieldClass.ratCast_mem K b)
      (SubfieldClass.ratCast_mem K c) (SubfieldClass.ratCast_mem K d) hx hf
    exact ih y hy hfy

end RCHelp

open RCHelp

#print axioms Tower
#print axioms adjoin_repr
#print axioms tower_merge
#print axioms sr_tower
#print axioms third_root
#print axioms cubic_descend
#print axioms tower_cubic

namespace RCHelp

theorem dist_of_sq {z c d : ℂ}
    (h : (z.re - c.re) ^ 2 + (z.im - c.im) ^ 2 = (d.re - c.re) ^ 2 + (d.im - c.im) ^ 2) :
    dist z c = dist d c := by
  rw [← sq_eq_sq₀ dist_nonneg dist_nonneg]
  simp only [Complex.dist_eq, Complex.sq_norm, Complex.normSq_apply, Complex.sub_re,
    Complex.sub_im]
  linear_combination h

theorem c_neg {w : ℂ} (hw : Constructible w) : Constructible (-w) := by
  by_cases h0 : w = 0
  · subst h0; simpa using Constructible.zero
  refine Constructible.lineCircle (a := 0) (b := w) (c := 0) (d := w) Constructible.zero hw
    Constructible.zero hw (Ne.symm h0) (mem_line_of (-1) (by push_cast; ring)) ?_
  simp [dist_zero_right]

theorem c_double {w : ℂ} (hw : Constructible w) : Constructible (2 * w) := by
  by_cases h0 : w = 0
  · subst h0; simpa using Constructible.zero
  refine Constructible.lineCircle (a := 0) (b := w) (c := w) (d := 0) Constructible.zero hw
    hw Constructible.zero (Ne.symm h0) (mem_line_of 2 (by push_cast; ring)) ?_
  apply dist_of_sq
  simp
  ring

/-- The two points that the circles about u through v and about v through u share. -/
noncomputable def eqv (u v : ℂ) (σ : ℝ) : ℂ :=
  (u + v) / 2 + Complex.I * ((σ * Real.sqrt 3 / 2 : ℝ) : ℂ) * (v - u)

theorem eqv_re (u v : ℂ) (σ : ℝ) :
    (eqv u v σ).re = (u.re + v.re) / 2 - σ * Real.sqrt 3 / 2 * (v.im - u.im) := by
  simp [eqv]; ring

theorem eqv_im (u v : ℂ) (σ : ℝ) :
    (eqv u v σ).im = (u.im + v.im) / 2 + σ * Real.sqrt 3 / 2 * (v.re - u.re) := by
  simp [eqv]

theorem c_eqv {u v : ℂ} (hu : Constructible u) (hv : Constructible v) (hne : u ≠ v) (σ : ℝ)
    (hσ : σ = 1 ∨ σ = -1) : Constructible (eqv u v σ) := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have hσ2 : σ ^ 2 = 1 := by rcases hσ with rfl | rfl <;> norm_num
  refine Constructible.circleCircle (a := u) (b := v) (c := v) (d := u) hu hv hv hu ?_ ?_ ?_
  · intro h; exact hne (Prod.ext_iff.mp h).1
  · apply dist_of_sq
    rw [eqv_re, eqv_im]
    linear_combination (3 / 4 * (v.im - u.im) ^ 2 + 3 / 4 * (v.re - u.re) ^ 2) * hσ2
      + (σ ^ 2 / 4 * (v.im - u.im) ^ 2 + σ ^ 2 / 4 * (v.re - u.re) ^ 2) * h3
  · apply dist_of_sq
    rw [eqv_re, eqv_im]
    linear_combination (3 / 4 * (v.im - u.im) ^ 2 + 3 / 4 * (v.re - u.re) ^ 2) * hσ2
      + (σ ^ 2 / 4 * (v.im - u.im) ^ 2 + σ ^ 2 / 4 * (v.re - u.re) ^ 2) * h3

theorem c_mid {u v : ℂ} (hu : Constructible u) (hv : Constructible v) (hne : u ≠ v) :
    Constructible ((u + v) / 2) := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have h3p : 0 < Real.sqrt 3 := by positivity
  have hw : (v.re - u.re) ^ 2 + (v.im - u.im) ^ 2 ≠ 0 := by
    rcases ne_coords hne with h | h
    · have := pow_pos (abs_pos.mpr h) 2
      rw [sq_abs] at this
      positivity
    · have := pow_pos (abs_pos.mpr h) 2
      rw [sq_abs] at this
      positivity
  have hP := c_eqv hu hv hne 1 (Or.inl rfl)
  have hQ := c_eqv hu hv hne (-1) (Or.inr rfl)
  have hPQ : eqv u v 1 ≠ eqv u v (-1) := by
    intro h
    have h1 := congrArg Complex.re h
    have h2 := congrArg Complex.im h
    rw [eqv_re, eqv_re] at h1
    rw [eqv_im, eqv_im] at h2
    apply hw
    have e1 : Real.sqrt 3 * (v.im - u.im) = 0 := by linarith
    have e2 : Real.sqrt 3 * (v.re - u.re) = 0 := by linarith
    have f1 : v.im - u.im = 0 := (mul_eq_zero.mp e1).resolve_left h3p.ne'
    have f2 : v.re - u.re = 0 := (mul_eq_zero.mp e2).resolve_left h3p.ne'
    rw [f1, f2]; ring
  refine Constructible.lineLine (a := u) (b := v) (c := eqv u v 1) (d := eqv u v (-1))
    hu hv hP hQ hne hPQ ?_ (mem_line_of (1 / 2) (by push_cast; ring)) ?_
  · intro h
    have hm : eqv u v 1 ∈ line[ℝ, u, v] := by
      rw [h]; exact left_mem_affineSpan_pair _ _ _
    rw [mem_line_iff hne, eqv_re, eqv_im] at hm
    apply hw
    have : Real.sqrt 3 * ((v.re - u.re) ^ 2 + (v.im - u.im) ^ 2) = 0 := by
      linear_combination -2 * hm
    exact (mul_eq_zero.mp this).resolve_left h3p.ne'
  · apply mem_line_of (1 / 2)
    simp only [eqv]
    push_cast
    ring

theorem c_add {u v : ℂ} (hu : Constructible u) (hv : Constructible v) :
    Constructible (u + v) := by
  by_cases h : u = v
  · subst h
    have := c_double hu
    rwa [two_mul] at this
  · have := c_double (c_mid hu hv h)
    rwa [mul_div_cancel₀ _ two_ne_zero] at this

theorem c_sub {u v : ℂ} (hu : Constructible u) (hv : Constructible v) :
    Constructible (u - v) := by
  rw [sub_eq_add_neg]; exact c_add hu (c_neg hv)

theorem c_mulI {w : ℂ} (hw : Constructible w) : Constructible (Complex.I * w) := by
  by_cases h0 : w = 0
  · subst h0; simpa using Constructible.zero
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have h3p : 0 < Real.sqrt 3 := by positivity
  have hn : -w ≠ w := by
    intro h; apply h0
    have : (2 : ℂ) * w = 0 := by linear_combination -h
    simpa using this
  have hP := c_eqv (c_neg hw) hw hn 1 (Or.inl rfl)
  have hQ := c_eqv (c_neg hw) hw hn (-1) (Or.inr rfl)
  have hPQ : eqv (-w) w 1 ≠ eqv (-w) w (-1) := by
    intro h
    have h1 := congrArg Complex.re h
    have h2 := congrArg Complex.im h
    rw [eqv_re, eqv_re] at h1
    rw [eqv_im, eqv_im] at h2
    apply h0
    simp at h1 h2
    have hi : w.im = 0 := h1.resolve_left (by intro h; linarith)
    have hr : w.re = 0 := h2.resolve_left (by intro h; linarith)
    apply Complex.ext <;> simp [hi, hr]
  refine Constructible.lineCircle (a := eqv (-w) w 1) (b := eqv (-w) w (-1)) (c := 0) (d := w)
    hP hQ Constructible.zero hw hPQ ?_ ?_
  · rw [mem_line_iff hPQ, eqv_re, eqv_re, eqv_im, eqv_im]
    simp
    ring
  · apply dist_of_sq
    simp
    ring

theorem c_ofI {t : ℝ} (h : Constructible (Complex.I * t)) : Constructible (t : ℂ) := by
  refine Constructible.lineCircle (a := 0) (b := 1) (c := 0) (d := Complex.I * t)
    Constructible.zero Constructible.one Constructible.zero h zero_ne_one
    (mem_line_of t (by ring)) ?_
  apply dist_of_sq
  simp

theorem c_mul_real {x y : ℝ} (hx : Constructible (x : ℂ)) (hy : Constructible (y : ℂ)) :
    Constructible ((x * y : ℝ) : ℂ) := by
  by_cases hy0 : y = 0
  · subst hy0; simpa using Constructible.zero
  have hI : Constructible Complex.I := by simpa using c_mulI Constructible.one
  have hP : Constructible (1 + Complex.I * x) := c_add Constructible.one (c_mulI hx)
  have hQ : Constructible (y + Complex.I) := c_add hy hI
  have h0P : (0 : ℂ) ≠ 1 + Complex.I * x := by
    intro h; have := congrArg Complex.re h; simp at this
  have hyQ : (y : ℂ) ≠ y + Complex.I := by
    intro h; have := congrArg Complex.im h; simp at this
  have hz : Constructible (y + Complex.I * ((x * y : ℝ) : ℂ)) := by
    refine Constructible.lineLine (a := 0) (b := 1 + Complex.I * x) (c := y)
      (d := y + Complex.I) Constructible.zero hP hy hQ h0P hyQ ?_
      (mem_line_of y (by push_cast; ring)) (mem_line_of (x * y) (by push_cast; ring))
    intro h
    have hm : (0 : ℂ) ∈ line[ℝ, (y : ℂ), y + Complex.I] := by
      rw [← h]; exact left_mem_affineSpan_pair _ _ _
    rw [mem_line_iff hyQ] at hm
    simp at hm
    exact hy0 hm
  apply c_ofI
  have := c_sub hz hy
  simpa using this

theorem c_div_real {x y : ℝ} (hx : Constructible (x : ℂ)) (hy : Constructible (y : ℂ)) :
    Constructible ((x / y : ℝ) : ℂ) := by
  by_cases hy0 : y = 0
  · subst hy0; simpa using Constructible.zero
  have hI : Constructible Complex.I := by simpa using c_mulI Constructible.one
  have hP : Constructible (y + Complex.I * x) := c_add hy (c_mulI hx)
  have hQ : Constructible (1 + Complex.I) := c_add Constructible.one hI
  have h0P : (0 : ℂ) ≠ y + Complex.I * x := by
    intro h; have := congrArg Complex.re h; simp at this; exact hy0 this.symm
  have h1Q : (1 : ℂ) ≠ 1 + Complex.I := by
    intro h; have := congrArg Complex.im h; simp at this
  have hyc : (y : ℂ) ≠ 0 := by exact_mod_cast hy0
  have hz : Constructible (1 + Complex.I * ((x / y : ℝ) : ℂ)) := by
    refine Constructible.lineLine (a := 0) (b := y + Complex.I * x) (c := 1)
      (d := 1 + Complex.I) Constructible.zero hP Constructible.one hQ h0P h1Q ?_
      (mem_line_of (1 / y) (by push_cast; field_simp; ring)) (mem_line_of (x / y) (by push_cast; ring))
    intro h
    have hm : (0 : ℂ) ∈ line[ℝ, (1 : ℂ), 1 + Complex.I] := by
      rw [← h]; exact left_mem_affineSpan_pair _ _ _
    rw [mem_line_iff h1Q] at hm
    simp at hm
  apply c_ofI
  have := c_sub hz Constructible.one
  simpa using this

theorem c_sqrt_real {x : ℝ} (hx : Constructible (x : ℂ)) (hx0 : 0 ≤ x) :
    Constructible ((Real.sqrt x : ℝ) : ℂ) := by
  have hI : Constructible Complex.I := by simpa using c_mulI Constructible.one
  have h2 : Constructible ((2 : ℝ) : ℂ) := by
    have := c_add Constructible.one Constructible.one
    norm_num at this; exact_mod_cast this
  have hm : Constructible (((x - 1) / 2 : ℝ) : ℂ) := by
    apply c_div_real _ h2
    have := c_sub hx Constructible.one
    exact_mod_cast this
  have hs : Real.sqrt x ^ 2 = x := Real.sq_sqrt hx0
  apply c_ofI
  refine Constructible.lineCircle (a := 0) (b := Complex.I) (c := (((x - 1) / 2 : ℝ) : ℂ))
    (d := x) Constructible.zero hI hm hx Complex.I_ne_zero.symm (mem_line_of (Real.sqrt x) (by ring)) ?_
  apply dist_of_sq
  simp
  linear_combination hs

theorem sr_constructible {x : ℝ} (h : SqrtReachable x) : Constructible (x : ℂ) := by
  induction h with
  | one => simpa using Constructible.one
  | add _ _ ihx ihy => push_cast; exact c_add ihx ihy
  | sub _ _ ihx ihy => push_cast; exact c_sub ihx ihy
  | mul _ _ ihx ihy => exact c_mul_real ihx ihy
  | div _ _ _ ihx ihy => exact c_div_real ihx ihy
  | sqrt _ hx0 ihx => exact c_sqrt_real ihx hx0

end RCHelp

open RCHelp

#print axioms dist_of_sq
#print axioms c_neg
#print axioms c_double
#print axioms eqv
#print axioms eqv_re
#print axioms eqv_im
#print axioms c_eqv
#print axioms c_mid
#print axioms c_add
#print axioms c_sub
#print axioms c_mulI
#print axioms c_ofI
#print axioms c_mul_real
#print axioms c_div_real
#print axioms c_sqrt_real
#print axioms sr_constructible

namespace RCHelp

/-- Rational root test for a cubic with whole-number coefficients. -/
theorem rat_root {a3 a2 a1 a0 : ℤ} (q : ℚ)
    (h : (a3 : ℚ) * q ^ 3 + (a2 : ℚ) * q ^ 2 + (a1 : ℚ) * q + (a0 : ℚ) = 0) :
    q.num ∣ a0 ∧ (q.den : ℤ) ∣ a3 := by
  have hd : (q.den : ℚ) ≠ 0 := by exact_mod_cast q.den_nz
  have key : a3 * q.num ^ 3 + a2 * q.num ^ 2 * q.den + a1 * q.num * q.den ^ 2
      + a0 * (q.den : ℤ) ^ 3 = 0 := by
    have hq := Rat.num_div_den q
    rw [← hq] at h
    field_simp at h
    exact_mod_cast (by linear_combination h :
      (a3 : ℚ) * q.num ^ 3 + a2 * q.num ^ 2 * q.den + a1 * q.num * q.den ^ 2
        + a0 * (q.den : ℚ) ^ 3 = 0)
  have cop : IsCoprime q.num (q.den : ℤ) := Rat.isCoprime_num_den q
  constructor
  · apply (cop.pow_right (n := 3)).dvd_of_dvd_mul_right
    exact ⟨-(a3 * q.num ^ 2 + a2 * q.num * q.den + a1 * q.den ^ 2), by linear_combination key⟩
  · apply (cop.symm.pow_right (n := 3)).dvd_of_dvd_mul_right
    exact ⟨-(a2 * q.num ^ 2 + a1 * q.num * q.den + a0 * q.den ^ 2), by linear_combination key⟩

theorem num_unit {q : ℚ} (h : q.num ∣ -1) : q.num = 1 ∨ q.num = -1 := by
  have : IsUnit q.num := isUnit_of_dvd_one (by simpa using h)
  exact Int.isUnit_iff.mp this

theorem no_rat_root_seven (q : ℚ) : (8 : ℚ) * q ^ 3 + 4 * q ^ 2 + (-4) * q + (-1) ≠ 0 := by
  intro h
  obtain ⟨hn, hd⟩ := rat_root (a3 := 8) (a2 := 4) (a1 := -4) (a0 := -1) q (by push_cast; linarith)
  have hn' := num_unit hn
  have hd' : q.den ∣ 8 := by exact_mod_cast hd
  have hdle : q.den ≤ 8 := Nat.le_of_dvd (by norm_num) hd'
  have hpos := q.den_pos
  rw [← Rat.num_div_den q] at h
  generalize q.num = N at h hn'
  generalize q.den = D at h hd' hdle hpos
  interval_cases D <;> rcases hn' with rfl | rfl <;> norm_num at h

theorem no_rat_root_nine (q : ℚ) : (8 : ℚ) * q ^ 3 + 0 * q ^ 2 + (-6) * q + (-1) ≠ 0 := by
  intro h
  obtain ⟨hn, hd⟩ := rat_root (a3 := 8) (a2 := 0) (a1 := -6) (a0 := -1) q (by push_cast; linarith)
  have hn' := num_unit hn
  have hd' : q.den ∣ 8 := by exact_mod_cast hd
  have hdle : q.den ≤ 8 := Nat.le_of_dvd (by norm_num) hd'
  have hpos := q.den_pos
  rw [← Rat.num_div_den q] at h
  generalize q.num = N at h hn'
  generalize q.den = D at h hd' hdle hpos
  interval_cases D <;> rcases hn' with rfl | rfl <;> norm_num at h

theorem no_rat_root_cube (q : ℚ) : (1 : ℚ) * q ^ 3 + 0 * q ^ 2 + 0 * q + (-2) ≠ 0 := by
  intro h
  obtain ⟨hn, hd⟩ := rat_root (a3 := 1) (a2 := 0) (a1 := 0) (a0 := -2) q (by push_cast; linarith)
  have hd' : q.den ∣ 1 := by exact_mod_cast hd
  have hd1 : q.den = 1 := Nat.dvd_one.mp hd'
  have hq : q = (q.num : ℚ) := by
    rw [← Rat.num_div_den q, hd1]; simp
  rw [hq] at h
  have hz : q.num ^ 3 = 2 := by
    have : ((q.num ^ 3 : ℤ) : ℚ) = ((2 : ℤ) : ℚ) := by push_cast; linarith
    exact_mod_cast this
  generalize q.num = N at hz
  have hle : N ≤ 1 := by
    by_contra hc; push Not at hc
    nlinarith [sq_nonneg N]
  have hge : -1 ≤ N := by
    by_contra hc; push Not at hc
    nlinarith [sq_nonneg N]
  interval_cases N <;> norm_num at hz

theorem cos_seven_cubic :
    (8 : ℝ) * Real.cos (2 * π / 7) ^ 3 + 4 * Real.cos (2 * π / 7) ^ 2
      + (-4) * Real.cos (2 * π / 7) + (-1) = 0 := by
  set θ := 2 * π / 7 with hθ
  have h43 : Real.cos (2 * (2 * θ)) = Real.cos (3 * θ) := by
    have : 2 * (2 * θ) = 2 * π - 3 * θ := by rw [hθ]; ring
    rw [this, Real.cos_two_pi_sub]
  rw [Real.cos_two_mul, Real.cos_two_mul, Real.cos_three_mul] at h43
  have hlt : Real.cos θ < 1 := by
    have := Real.cos_lt_cos_of_nonneg_of_le_pi (x := 0) (y := θ) le_rfl
      (by rw [hθ]; linarith [Real.pi_pos]) (by rw [hθ]; positivity)
    simpa using this
  have hfac : (Real.cos θ - 1) * (8 * Real.cos θ ^ 3 + 4 * Real.cos θ ^ 2 - 4 * Real.cos θ - 1)
      = 0 := by linear_combination h43
  have := (mul_eq_zero.mp hfac).resolve_left (by linarith)
  linear_combination this

theorem cos_nine_cubic :
    (8 : ℝ) * Real.cos (π / 9) ^ 3 + 0 * Real.cos (π / 9) ^ 2
      + (-6) * Real.cos (π / 9) + (-1) = 0 := by
  have h := Real.cos_three_mul (π / 9)
  have : 3 * (π / 9) = π / 3 := by ring
  rw [this, Real.cos_pi_div_three] at h
  linear_combination -2 * h

theorem cube_root_two_cubic :
    (1 : ℝ) * ((2 : ℝ) ^ ((1 : ℝ) / 3)) ^ 3 + 0 * ((2 : ℝ) ^ ((1 : ℝ) / 3)) ^ 2
      + 0 * ((2 : ℝ) ^ ((1 : ℝ) / 3)) + (-2) = 0 := by
  have : ((2 : ℝ) ^ ((1 : ℝ) / 3)) ^ 3 = 2 := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul (by norm_num)]
    norm_num
  rw [this]; ring

end RCHelp

open RCHelp

#print axioms rat_root
#print axioms num_unit
#print axioms no_rat_root_seven
#print axioms no_rat_root_nine
#print axioms no_rat_root_cube
#print axioms cos_seven_cubic
#print axioms cos_nine_cubic
#print axioms cube_root_two_cubic

/-- A length that solves a cubic a x³ + b x² + c x + d = 0 with fraction coefficients
(a not zero) and no fraction root can never be built with ruler and compass. -/
theorem cubic_root_without_fraction_root_not_constructible (a b c d : ℚ) (ha : a ≠ 0)
    (hno : ∀ q : ℚ, a * q ^ 3 + b * q ^ 2 + c * q + d ≠ 0)
    (x : ℝ) (hx : (a : ℝ) * x ^ 3 + (b : ℝ) * x ^ 2 + (c : ℝ) * x + (d : ℝ) = 0) :
    ¬ Constructible (x : ℂ) := by
  intro hC
  have hx' : SqrtReachable x := by simpa using (RCHelp.constructible_coords hC).1
  obtain ⟨K, hK, hxK⟩ := RCHelp.sr_tower hx'
  obtain ⟨q, hq⟩ := RCHelp.tower_cubic hK a b c d ha x hxK hx
  exact hno q hq

/-- Ruler and compass build exactly the real numbers reachable from 1 by adding, subtracting,
multiplying, dividing and taking square roots. -/
theorem constructible_iff_sqrt_reachable (x : ℝ) : Constructible (x : ℂ) ↔ SqrtReachable x := by
  exact ⟨fun h => by simpa using (RCHelp.constructible_coords h).1, RCHelp.sr_constructible⟩

/-- The ancient problems that cannot be solved: the regular 7-gon's cosine cos(360°/7), the
cosine of 20° that trisecting 60° needs, and the side of a cube of volume 2 (the cube root of 2)
can none of them be built with ruler and compass. -/
theorem seven_gon_trisection_and_cube_doubling_impossible :
    ¬ Constructible (Real.cos (2 * π / 7) : ℂ) ∧ ¬ Constructible (Real.cos (π / 9) : ℂ) ∧
      ¬ Constructible (((2 : ℝ) ^ ((1 : ℝ) / 3) : ℝ) : ℂ) := by
  refine ⟨?_, ?_, ?_⟩
  · exact cubic_root_without_fraction_root_not_constructible 8 4 (-4) (-1) (by norm_num)
      RCHelp.no_rat_root_seven _ (by push_cast; exact RCHelp.cos_seven_cubic)
  · exact cubic_root_without_fraction_root_not_constructible 8 0 (-6) (-1) (by norm_num)
      RCHelp.no_rat_root_nine _ (by push_cast; exact RCHelp.cos_nine_cubic)
  · exact cubic_root_without_fraction_root_not_constructible 1 0 0 (-2) (by norm_num)
      RCHelp.no_rat_root_cube _ (by push_cast; exact RCHelp.cube_root_two_cubic)

-- The 7-gon's cubic 8c³ + 4c² − 4c − 1 = 0: none of the candidates ±1, ±1/2, ±1/4, ±1/8 is a root.
example : ∀ q ∈ ({1, -1, 1/2, -1/2, 1/4, -1/4, 1/8, -1/8} : Finset ℚ),
    8 * q ^ 3 + 4 * q ^ 2 - 4 * q - 1 ≠ 0 := by
  norm_num
-- Trisecting 60°: 8x³ − 6x − 1 = 0 has none of the same candidates as a root.
example : ∀ q ∈ ({1, -1, 1/2, -1/2, 1/4, -1/4, 1/8, -1/8} : Finset ℚ),
    8 * q ^ 3 - 6 * q - 1 ≠ 0 := by
  norm_num
-- Doubling the cube: x³ − 2 = 0 has none of ±1, ±2 as a root.
example : ∀ q ∈ ({1, -1, 2, -2} : Finset ℚ), q ^ 3 - 2 ≠ 0 := by
  norm_num
-- The 180° control: 4x³ − 3x + 1 = 0 does have the fraction roots −1 and 1/2.
example : 4 * (-1 : ℚ) ^ 3 - 3 * (-1) + 1 = 0 ∧ 4 * (1/2 : ℚ) ^ 3 - 3 * (1/2) + 1 = 0 := by
  norm_num
-- Gauss's first pairing: A, B = (−1 ± √17)/2 add to −1 and multiply to −4.
example : (-1 + Real.sqrt 17) / 2 + (-1 - Real.sqrt 17) / 2 = -1 ∧
    (-1 + Real.sqrt 17) / 2 * ((-1 - Real.sqrt 17) / 2) = -4 := by
  constructor
  · ring
  · ring_nf
    norm_num
-- Fermat primes 2^(2^j) + 1: 3, 5, 17 and 257 are prime; 17 − 1 = 16 halves four times.
example : 2 ^ (2 ^ 0) + 1 = 3 ∧ 2 ^ (2 ^ 1) + 1 = 5 ∧ 2 ^ (2 ^ 2) + 1 = 17 ∧ 2 ^ (2 ^ 3) + 1 = 257 := by
  norm_num
example : Nat.Prime 3 ∧ Nat.Prime 5 ∧ Nat.Prime 17 ∧ Nat.Prime 257 := by
  norm_num
example : 17 - 1 = 2 ^ 4 ∧ 7 - 1 = 2 * 3 := by
  norm_num

#print axioms cubic_root_without_fraction_root_not_constructible
#print axioms constructible_iff_sqrt_reachable
#print axioms seven_gon_trisection_and_cube_doubling_impossible
