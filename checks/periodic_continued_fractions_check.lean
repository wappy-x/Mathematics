-- Periodic continued fractions: a real number's continued fraction steps go on forever and repeat exactly when the number is (P + root D)/Q with whole P, Q, D and D not a square, that is, a quadratic irrational.
import Mathlib.Algebra.ContinuedFractions.Computation.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.ContinuedFractions.Computation.Translations
import Mathlib.Algebra.ContinuedFractions.Computation.TerminatesIffRat
import Mathlib.Algebra.ContinuedFractions.Computation.ApproximationCorollaries
import Mathlib.Order.Interval.Set.Infinite
import Mathlib.Tactic.LinearCombination

namespace PeriodicContinuedFractions

/-- The steps of `x` (the whole parts the flip-and-peel writes down after the first one, Mathlib's
`GenContFract.of x`) **repeat forever**: the list never stops, and from some step `N` on it repeats
with a block of length `p ≥ 1`. -/
def StepsRepeatForever (x : ℝ) : Prop :=
  ¬ (GenContFract.of x).Terminates ∧
    ∃ N p : ℕ, 0 < p ∧ ∀ n, N ≤ n →
      (GenContFract.of x).partDens.get? (n + p) = (GenContFract.of x).partDens.get? n

noncomputable def cq (x : ℝ) : ℕ → ℝ
  | 0 => x
  | n + 1 => (Int.fract (cq x n))⁻¹

theorem cq_zero (x : ℝ) : cq x 0 = x := rfl
theorem cq_succ (x : ℝ) (n : ℕ) : cq x (n + 1) = (Int.fract (cq x n))⁻¹ := rfl

theorem cq_add (x : ℝ) (k n : ℕ) : cq (cq x k) n = cq x (k + n) := by
  induction n with
  | zero => rfl
  | succ n ih => rw [cq_succ, ih, ← Nat.add_assoc, cq_succ]

theorem irr_fract_inv {z : ℝ} (h : Irrational z) : Irrational (Int.fract z)⁻¹ := by
  rw [Int.fract]; exact (h.sub_intCast _).inv

theorem irr_cq {x : ℝ} (h : Irrational x) (n : ℕ) : Irrational (cq x n) := by
  induction n with
  | zero => exact h
  | succ n ih => exact irr_fract_inv ih

theorem fract_ne_zero_of_irr {z : ℝ} (h : Irrational z) : Int.fract z ≠ 0 := by
  intro h0
  rw [Int.fract, sub_eq_zero] at h0
  exact h.ne_int _ h0

theorem one_lt_cq_succ {x : ℝ} (h : Irrational x) (n : ℕ) : 1 < cq x (n + 1) := by
  rw [cq_succ]
  have h1 := fract_ne_zero_of_irr (irr_cq h n)
  have h2 := Int.fract_nonneg (cq x n)
  have h3 := Int.fract_lt_one (cq x n)
  exact (one_lt_inv₀ (lt_of_le_of_ne h2 (Ne.symm h1))).2 h3

theorem one_le_floor_cq_succ {x : ℝ} (h : Irrational x) (n : ℕ) : 1 ≤ ⌊cq x (n + 1)⌋ := by
  have := one_lt_cq_succ h n
  exact Int.le_floor.2 (by exact_mod_cast this.le)

theorem stream_eq {x : ℝ} (h : Irrational x) (n : ℕ) :
    GenContFract.IntFractPair.stream x n = some (GenContFract.IntFractPair.of (cq x n)) := by
  induction n with
  | zero => exact GenContFract.IntFractPair.stream_zero x
  | succ n ih =>
    exact GenContFract.IntFractPair.stream_succ_of_some ih (fract_ne_zero_of_irr (irr_cq h n))

theorem s_get {x : ℝ} (h : Irrational x) (n : ℕ) :
    (GenContFract.of x).s.get? n = some ⟨1, (⌊cq x (n + 1)⌋ : ℝ)⟩ :=
  GenContFract.get?_of_eq_some_of_succ_get?_intFractPair_stream (stream_eq h (n + 1))

theorem partDens_get {x : ℝ} (h : Irrational x) (n : ℕ) :
    (GenContFract.of x).partDens.get? n = some (⌊cq x (n + 1)⌋ : ℝ) := by
  simp [GenContFract.partDens, s_get h n]

theorem not_terminates {x : ℝ} (h : Irrational x) : ¬ (GenContFract.of x).Terminates := by
  rw [GenContFract.terminates_iff_rat]
  rintro ⟨q, rfl⟩
  exact h ⟨q, rfl⟩

theorem irr_of_not_terminates {x : ℝ} (h : ¬ (GenContFract.of x).Terminates) : Irrational x := by
  rintro ⟨q, rfl⟩
  exact h ((GenContFract.terminates_iff_rat _).2 ⟨q, rfl⟩)

theorem eq_of_floors {y z : ℝ} (hy : Irrational y) (hz : Irrational z)
    (h : ∀ n, ⌊cq y n⌋ = ⌊cq z n⌋) : y = z := by
  have hof : GenContFract.of y = GenContFract.of z := by
    have h1 : (GenContFract.of y).h = (GenContFract.of z).h := by
      rw [GenContFract.of_h_eq_floor, GenContFract.of_h_eq_floor]
      exact_mod_cast h 0
    have h2 : (GenContFract.of y).s = (GenContFract.of z).s := by
      apply Stream'.Seq.ext
      intro n
      rw [s_get hy, s_get hz, h (n + 1)]
    cases hgy : GenContFract.of y
    cases hgz : GenContFract.of z
    rw [hgy, hgz] at h1 h2
    simp_all
  have ty := GenContFract.of_convergence (v := y)
  have tz := GenContFract.of_convergence (v := z)
  rw [hof] at ty
  exact tendsto_nhds_unique ty tz


theorem mul_fract_inv {z : ℝ} (h : Irrational z) :
    z * (Int.fract z)⁻¹ = ⌊z⌋ * (Int.fract z)⁻¹ + 1 := by
  have h1 := fract_ne_zero_of_irr h
  have h2 : z * (Int.fract z)⁻¹ = (⌊z⌋ + Int.fract z) * (Int.fract z)⁻¹ := by
    rw [Int.floor_add_fract]
  rw [h2, add_mul, mul_inv_cancel₀ h1]

theorem mobius {y : ℝ} (hy : Irrational y) (n : ℕ) :
    ∃ A B C D : ℤ, 0 < C ∧ 0 ≤ D ∧ y * (C * cq y (n + 1) + D) = A * cq y (n + 1) + B := by
  induction n with
  | zero =>
    refine ⟨⌊y⌋, 1, 1, 0, one_pos, le_refl _, ?_⟩
    have := mul_fract_inv hy
    simp only [cq_succ, cq_zero, Int.cast_one, Int.cast_zero, one_mul, add_zero]
    exact this
  | succ n ih =>
    obtain ⟨A, B, C, D, hC, hD, hE⟩ := ih
    set z := cq y (n + 1) with hz
    have hzw : z * cq y (n + 1 + 1) = ⌊z⌋ * cq y (n + 1 + 1) + 1 := by
      rw [cq_succ]; exact mul_fract_inv (irr_cq hy _)
    have hf : 1 ≤ ⌊z⌋ := one_le_floor_cq_succ hy n
    refine ⟨A * ⌊z⌋ + B, A, C * ⌊z⌋ + D, C, by nlinarith, hC.le, ?_⟩
    set w := cq y (n + 1 + 1)
    push_cast
    linear_combination w * hE + (A - y * C) * hzw

def IsQuad (x : ℝ) : Prop := ∃ a b c : ℤ, a ≠ 0 ∧ (a : ℝ) * x ^ 2 + b * x + c = 0

theorem quad_back {z : ℝ} (hz : Irrational z) (hq : IsQuad (Int.fract z)⁻¹) : IsQuad z := by
  obtain ⟨a, b, c, ha, he⟩ := hq
  have hf := fract_ne_zero_of_irr hz
  set m := ⌊z⌋
  have ht : Int.fract z = z - m := rfl
  rw [ht] at hf he
  have he2 : (a : ℝ) + b * (z - m) + c * (z - m) ^ 2 = 0 := by
    have := congrArg (· * (z - m) ^ 2) he
    simp only [zero_mul] at this
    rw [← this]; field_simp
  have hc : c ≠ 0 := by
    rintro rfl
    have hb : b ≠ 0 := by
      rintro rfl; simp at he2; exact ha he2
    apply hz
    refine ⟨(m - a / b : ℚ), ?_⟩
    push_cast
    have hb' : (b : ℝ) ≠ 0 := by exact_mod_cast hb
    field_simp
    simp at he2
    linear_combination -he2
  exact ⟨c, b - 2 * c * m, a - b * m + c * m ^ 2, hc, by push_cast; linear_combination he2⟩

theorem quad_of_cq {x : ℝ} (hx : Irrational x) (n : ℕ) (h : IsQuad (cq x n)) : IsQuad x := by
  induction n with
  | zero => exact h
  | succ n ih => exact ih (quad_back (irr_cq hx n) h)

theorem periodic_quad {x : ℝ} (h : StepsRepeatForever x) : Irrational x ∧ IsQuad x := by
  obtain ⟨hT, N, p, hp, hper⟩ := h
  have hx := irr_of_not_terminates hT
  refine ⟨hx, ?_⟩
  set y := cq x (N + 1)
  have hy : Irrational y := irr_cq hx _
  have hyy : cq y p = y := by
    symm
    apply eq_of_floors hy (irr_cq hy p)
    intro n
    have := hper (N + n) (by omega)
    rw [partDens_get hx, partDens_get hx] at this
    have h2 : ⌊cq x (N + n + p + 1)⌋ = ⌊cq x (N + n + 1)⌋ := by
      simpa using this
    rw [cq_add, cq_add, cq_add]
    rw [show N + 1 + (p + n) = N + n + p + 1 by omega, show N + 1 + n = N + n + 1 by omega, h2]
  obtain ⟨k, rfl⟩ : ∃ k, p = k + 1 := ⟨p - 1, by omega⟩
  obtain ⟨A, B, C, D, hC, -, hE⟩ := mobius hy k
  rw [hyy] at hE
  have hq : IsQuad y := ⟨C, D - A, -B, hC.ne', by push_cast; linear_combination hE⟩
  exact quad_of_cq hx _ hq


theorem flip_aux (P Q a : ℤ) (D : ℕ) (s : ℝ) (hs : s ^ 2 = D) (hQ : Q ≠ 0) (hD : ¬ IsSquare D)
    (hdiv : Q ∣ (D : ℤ) - P ^ 2) :
    Q ∣ (D : ℤ) - (a * Q - P) ^ 2 ∧
      ((D : ℤ) - (a * Q - P) ^ 2) / Q ≠ 0 ∧
      ((P + s) / Q - a)⁻¹ =
        ((a * Q - P : ℤ) + s) / ((((D : ℤ) - (a * Q - P) ^ 2) / Q : ℤ) : ℝ) ∧
      ((D : ℤ) - (a * Q - P) ^ 2) / Q ∣ (D : ℤ) - (a * Q - P) ^ 2 := by
  have hdiv' : Q ∣ (D : ℤ) - (a * Q - P) ^ 2 := by
    have : (D : ℤ) - (a * Q - P) ^ 2 = ((D : ℤ) - P ^ 2) + Q * (2 * a * P - a ^ 2 * Q) := by ring
    rw [this]; exact dvd_add hdiv (dvd_mul_right _ _)
  set P' := a * Q - P with hP'
  have hne : (D : ℤ) - P' ^ 2 ≠ 0 := by
    intro h0
    apply hD
    refine ⟨P'.natAbs, ?_⟩
    have : (D : ℤ) = ((P'.natAbs * P'.natAbs : ℕ) : ℤ) := by
      rw [Int.natAbs_mul_self]; linear_combination h0
    exact_mod_cast this
  obtain ⟨k, hk⟩ := hdiv'
  have hk0 : k ≠ 0 := by rintro rfl; simp at hk; exact hne hk
  refine ⟨⟨k, hk⟩, ?_, ?_, ?_⟩
  · rw [hk, Int.mul_ediv_cancel_left _ hQ]; exact hk0
  · rw [hk, Int.mul_ediv_cancel_left _ hQ]
    have hkR : (D : ℝ) - (P' : ℝ) ^ 2 = Q * k := by exact_mod_cast hk
    have hQR : (Q : ℝ) ≠ 0 := by exact_mod_cast hQ
    have hkR0 : (k : ℝ) ≠ 0 := by exact_mod_cast hk0
    have hsP : s - P' ≠ 0 := by
      intro h0
      have : s = P' := by linarith
      apply hne
      have h2 : (D : ℝ) - (P' : ℝ) ^ 2 = 0 := by rw [← hs, this]; ring
      exact_mod_cast h2
    have e1 : (P + s) / Q - a = (s - P') / Q := by
      rw [hP']; push_cast; field_simp; ring
    rw [e1, inv_div, div_eq_div_iff hsP hkR0]
    linear_combination -hkR - hs
  · rw [hk, Int.mul_ediv_cancel_left _ hQ]; exact Dvd.intro_left _ rfl

theorem form_irr {P Q : ℤ} {s : ℝ} (hs : Irrational s) (hQ : Q ≠ 0) : Irrational ((P + s) / Q) :=
  (hs.intCast_add P).div_intCast hQ

theorem quad_of_form {x : ℝ} {P Q : ℤ} {D : ℕ} (hQ : Q ≠ 0) (hD : ¬ IsSquare D)
    (hx : x = (P + Real.sqrt D) / Q) : Irrational x ∧ IsQuad x := by
  have hs : Irrational (Real.sqrt D) := irrational_sqrt_natCast_iff.2 hD
  refine ⟨hx ▸ form_irr hs hQ, Q ^ 2, -2 * P * Q, P ^ 2 - D, pow_ne_zero _ hQ, ?_⟩
  have hQR : (Q : ℝ) ≠ 0 := by exact_mod_cast hQ
  have h1 : (Q : ℝ) * x = P + Real.sqrt D := by rw [hx]; field_simp
  have h2 : Real.sqrt D ^ 2 = D := Real.sq_sqrt (Nat.cast_nonneg _)
  push_cast
  linear_combination (Q * x - P + Real.sqrt D) * h1 + h2

theorem form_of_quad {x : ℝ} (hx : Irrational x) (hq : IsQuad x) :
    ∃ (P Q : ℤ) (D : ℕ), Q ≠ 0 ∧ ¬ IsSquare D ∧ Q ∣ (D : ℤ) - P ^ 2 ∧
        x = (P + Real.sqrt D) / Q := by
  obtain ⟨a, b, c, ha, he⟩ := hq
  have hsq : ((2 * a * x + b) : ℝ) ^ 2 = ((b ^ 2 - 4 * a * c : ℤ) : ℝ) := by
    push_cast; linear_combination 4 * a * he
  have hΔ : 0 ≤ b ^ 2 - 4 * a * c := by
    have : (0 : ℝ) ≤ ((b ^ 2 - 4 * a * c : ℤ) : ℝ) := by rw [← hsq]; positivity
    exact_mod_cast this
  set D : ℕ := (b ^ 2 - 4 * a * c).toNat with hDdef
  have hDZ : (D : ℤ) = b ^ 2 - 4 * a * c := Int.toNat_of_nonneg hΔ
  have hDR : (D : ℝ) = ((b ^ 2 - 4 * a * c : ℤ) : ℝ) := by exact_mod_cast hDZ
  have hsqrt : Real.sqrt D = |2 * a * x + b| := by
    rw [hDR, ← hsq, Real.sqrt_sq_eq_abs]
  have haR : (a : ℝ) ≠ 0 := by exact_mod_cast ha
  have hD : ¬ IsSquare D := by
    rintro ⟨r, hr⟩
    have : Real.sqrt D = r := by
      rw [hr]; push_cast; rw [Real.sqrt_mul_self (Nat.cast_nonneg _)]
    rw [hsqrt] at this
    rcases abs_cases (2 * (a : ℝ) * x + b) with ⟨h1, -⟩ | ⟨h1, -⟩
    · apply hx
      refine ⟨((r : ℚ) - b) / (2 * a), ?_⟩
      push_cast; field_simp; linarith
    · apply hx
      refine ⟨(-(r : ℚ) - b) / (2 * a), ?_⟩
      push_cast; field_simp; linarith
  rcases abs_cases (2 * (a : ℝ) * x + b) with ⟨h1, -⟩ | ⟨h1, -⟩
  · refine ⟨-b, 2 * a, D, by positivity, hD, ⟨-2 * c, by rw [hDZ]; ring⟩, ?_⟩
    rw [hsqrt, h1]; push_cast; field_simp; ring
  · refine ⟨b, -2 * a, D, by simpa using ha, hD, ⟨2 * c, by rw [hDZ]; ring⟩, ?_⟩
    rw [hsqrt, h1]; push_cast; field_simp; ring


theorem periodic_of_eq {x : ℝ} (hx : Irrational x) {i j : ℕ} (hij : i < j)
    (he : cq x i = cq x j) : StepsRepeatForever x := by
  refine ⟨not_terminates hx, i, j - i, by omega, fun n hn => ?_⟩
  rw [partDens_get hx, partDens_get hx]
  have h1 : cq x (n + (j - i) + 1) = cq (cq x j) (n + 1 - i) := by
    rw [cq_add]; congr 1; omega
  have h2 : cq x (n + 1) = cq (cq x i) (n + 1 - i) := by
    rw [cq_add]; congr 1; omega
  rw [h1, h2, he]

noncomputable def PQ (x : ℝ) (D : ℕ) (P0 Q0 : ℤ) : ℕ → ℤ × ℤ
  | 0 => (P0, Q0)
  | n + 1 =>
    (⌊cq x n⌋ * (PQ x D P0 Q0 n).2 - (PQ x D P0 Q0 n).1,
      ((D : ℤ) - (⌊cq x n⌋ * (PQ x D P0 Q0 n).2 - (PQ x D P0 Q0 n).1) ^ 2) / (PQ x D P0 Q0 n).2)

theorem PQ_succ (x : ℝ) (D : ℕ) (P0 Q0 : ℤ) (n : ℕ) :
    PQ x D P0 Q0 (n + 1) =
    (⌊cq x n⌋ * (PQ x D P0 Q0 n).2 - (PQ x D P0 Q0 n).1,
      ((D : ℤ) - (⌊cq x n⌋ * (PQ x D P0 Q0 n).2 - (PQ x D P0 Q0 n).1) ^ 2) / (PQ x D P0 Q0 n).2) :=
  rfl

theorem PQ_inv {x : ℝ} {P0 Q0 : ℤ} {D : ℕ} (hQ : Q0 ≠ 0) (hD : ¬ IsSquare D)
    (hdiv : Q0 ∣ (D : ℤ) - P0 ^ 2) (hx : x = (P0 + Real.sqrt D) / Q0) (n : ℕ) :
    (PQ x D P0 Q0 n).2 ≠ 0 ∧ (PQ x D P0 Q0 n).2 ∣ (D : ℤ) - (PQ x D P0 Q0 n).1 ^ 2 ∧
      cq x n = ((PQ x D P0 Q0 n).1 + Real.sqrt D) / (PQ x D P0 Q0 n).2 ∧
      ((PQ x D P0 Q0 (n + 1)).1 + -Real.sqrt D) / (PQ x D P0 Q0 (n + 1)).2 =
        (((PQ x D P0 Q0 n).1 + -Real.sqrt D) / (PQ x D P0 Q0 n).2 - ⌊cq x n⌋)⁻¹ := by
  have hs : Real.sqrt D ^ 2 = D := Real.sq_sqrt (Nat.cast_nonneg _)
  have hs' : (-Real.sqrt D) ^ 2 = D := by rw [neg_sq, hs]
  induction n with
  | zero =>
    refine ⟨hQ, hdiv, hx, ?_⟩
    obtain ⟨-, -, h3, -⟩ := flip_aux P0 Q0 ⌊cq x 0⌋ D _ hs' hQ hD hdiv
    exact h3.symm
  | succ n ih =>
    obtain ⟨hQn, hdn, hxn, -⟩ := ih
    obtain ⟨-, h2, h3, h4⟩ := flip_aux _ _ ⌊cq x n⌋ D _ hs hQn hD hdn
    have hxn1 : cq x (n + 1) = ((PQ x D P0 Q0 (n + 1)).1 + Real.sqrt D) / (PQ x D P0 Q0 (n + 1)).2 := by
      rw [cq_succ, PQ_succ, ← h3, hxn]; rfl
    obtain ⟨-, -, h3', -⟩ := flip_aux _ _ ⌊cq x (n + 1)⌋ D _ hs' h2 hD h4
    exact ⟨h2, h4, hxn1, h3'.symm⟩


theorem lagrange {x : ℝ} {P0 Q0 : ℤ} {D : ℕ} (hQ : Q0 ≠ 0) (hD : ¬ IsSquare D)
    (hdiv : Q0 ∣ (D : ℤ) - P0 ^ 2) (hx : x = (P0 + Real.sqrt D) / Q0) : StepsRepeatForever x := by
  have hsD : Irrational (Real.sqrt D) := irrational_sqrt_natCast_iff.2 hD
  have hxi : Irrational x := hx ▸ form_irr hsD hQ
  have hinv := PQ_inv hQ hD hdiv hx
  set P : ℕ → ℤ := fun n => (PQ x D P0 Q0 n).1 with hPdef
  set Q : ℕ → ℤ := fun n => (PQ x D P0 Q0 n).2 with hQdef
  set y : ℕ → ℝ := fun n => ((P n : ℝ) + -Real.sqrt D) / Q n with hydef
  set s := Real.sqrt D with hs
  have hQn : ∀ n, Q n ≠ 0 := fun n => (hinv n).1
  have hQnR : ∀ n, (Q n : ℝ) ≠ 0 := fun n => by exact_mod_cast hQn n
  have hcq : ∀ n, cq x n = (P n + s) / Q n := fun n => (hinv n).2.2.1
  have hy : ∀ n, y (n + 1) = (y n - ⌊cq x n⌋)⁻¹ := fun n => (hinv n).2.2.2
  have hyi : ∀ n, Irrational (y n) := fun n => form_irr hsD.neg (hQn n)
  have hsp : 0 < s := lt_of_le_of_ne (Real.sqrt_nonneg _) (Ne.symm hsD.ne_zero)
  have hdiff : ∀ n, cq x n - y n = 2 * s / Q n := by
    intro n; rw [hcq]; simp only [y]; field_simp; ring
  have hu : ∀ n, 0 < cq x n - ⌊cq x n⌋ ∧ cq x n - ⌊cq x n⌋ < 1 := by
    intro n
    have h1 := fract_ne_zero_of_irr (irr_cq hxi n)
    exact ⟨lt_of_le_of_ne (Int.fract_nonneg _) (Ne.symm h1), Int.fract_lt_one _⟩
  have hfl : ∀ n, (1 : ℝ) ≤ ⌊cq x (n + 1)⌋ := fun n => by exact_mod_cast one_le_floor_cq_succ hxi n
  have hcq1 : ∀ n, 1 < cq x (n + 1) := one_lt_cq_succ hxi
  have hcqs : ∀ n, cq x (n + 1) = (cq x n - ⌊cq x n⌋)⁻¹ := fun n => rfl
  -- some conjugate becomes negative
  have hA : ∃ M, y (M + 1) < 0 := by
    by_contra hA
    simp only [not_exists, not_lt] at hA
    have hpos : ∀ M, 0 < y (M + 1) := fun M => lt_of_le_of_ne (hA M) (Ne.symm (hyi _).ne_zero)
    have hgt : ∀ n, 0 < y (n + 1) - ⌊cq x (n + 1)⌋ := by
      intro n
      have := hpos (n + 1)
      rw [hy] at this
      exact inv_pos.1 this
    have hlt : ∀ n, y (n + 1) - ⌊cq x (n + 1)⌋ < 1 := by
      intro n
      have h1 := hgt (n + 1)
      have h2 := hfl (n + 1)
      have h3 : 1 < y (n + 1 + 1) := by linarith
      rw [hy] at h3
      exact (one_lt_inv₀ (hgt n)).1 h3
    have hdec : ∀ n, (Q (n + 2)).natAbs < (Q (n + 1)).natAbs := by
      intro n
      set u := cq x (n + 1) - ⌊cq x (n + 1)⌋
      set v := y (n + 1) - ⌊cq x (n + 1)⌋
      have hu0 := (hu (n + 1)).1
      have hu1 := (hu (n + 1)).2
      have hv0 := hgt n
      have hv1 := hlt n
      have h1 : u - v = 2 * s / Q (n + 1) := by rw [← hdiff]; ring
      have h2 : u⁻¹ - v⁻¹ = 2 * s / Q (n + 2) := by rw [← hdiff, ← hcqs, ← hy]
      have h1' : (Q (n + 1) : ℝ) * (u - v) = 2 * s := by
        rw [h1]; field_simp [hQnR (n + 1)]
      have h2' : (Q (n + 2) : ℝ) * (v - u) = 2 * s * u * v := by
        have hu' : u ≠ 0 := ne_of_gt hu0
        have hv' : v ≠ 0 := ne_of_gt hv0
        have e : v - u = u * v * (u⁻¹ - v⁻¹) := by field_simp
        rw [e, h2]; field_simp [hQnR (n + 2)]
      have hvu : v - u ≠ 0 := by
        intro h0
        have : u - v = 0 := by linarith
        rw [this, mul_zero] at h1'
        linarith
      have h3 : (Q (n + 2) : ℝ) = -((Q (n + 1) : ℝ) * u * v) := by
        have : (v - u) * ((Q (n + 2) : ℝ) + (Q (n + 1) : ℝ) * u * v) = 0 := by
          linear_combination h2' - u * v * h1'
        rcases mul_eq_zero.1 this with h | h
        · exact absurd h hvu
        · linarith
      have h4 : |(Q (n + 2) : ℝ)| < |(Q (n + 1) : ℝ)| := by
        rw [h3, abs_neg, abs_mul, abs_mul, abs_of_pos hu0, abs_of_pos hv0]
        have hq : 0 < |(Q (n + 1) : ℝ)| := abs_pos.2 (hQnR _)
        have huv : u * v < 1 := by nlinarith
        nlinarith
      have h5 : |Q (n + 2)| < |Q (n + 1)| := by exact_mod_cast h4
      have h6 : ((Q (n + 2)).natAbs : ℤ) < (Q (n + 1)).natAbs := by
        rw [Int.natCast_natAbs, Int.natCast_natAbs]; exact h5
      exact_mod_cast h6
    have hind : ∀ n, (Q (n + 1)).natAbs + n ≤ (Q 1).natAbs := by
      intro n
      induction n with
      | zero => simp
      | succ n ih =>
        have := hdec n
        show (Q (n + 2)).natAbs + (n + 1) ≤ _
        omega
    have := hind ((Q 1).natAbs + 1)
    omega
  obtain ⟨M, hM⟩ := hA
  have hstep : ∀ n, y (n + 1) < 0 → -1 < y (n + 2) ∧ y (n + 2) < 0 := by
    intro n hn
    have ha := hfl n
    rw [show n + 2 = n + 1 + 1 from rfl, hy]
    set t := y (n + 1) - ⌊cq x (n + 1)⌋
    have ht : t < -1 := by simp only [t]; linarith
    have htt : t * t⁻¹ = 1 := mul_inv_cancel₀ (by linarith)
    have hneg : t⁻¹ < 0 := inv_lt_zero.2 (by linarith)
    exact ⟨by nlinarith, hneg⟩
  have hneg : ∀ k, y (M + 1 + k) < 0 := by
    intro k
    induction k with
    | zero => exact hM
    | succ k ih =>
      have := (hstep (M + k) (by rw [show M + k + 1 = M + 1 + k by omega]; exact ih)).2
      rwa [show M + k + 2 = M + 1 + (k + 1) by omega] at this
  have hbd : ∀ n, M + 2 ≤ n → -1 < y n ∧ y n < 0 := by
    intro n hn
    have := hstep (M + (n - (M + 2))) (by
      rw [show M + (n - (M + 2)) + 1 = M + 1 + (n - (M + 2)) by omega]; exact hneg _)
    rwa [show M + (n - (M + 2)) + 2 = n by omega] at this
  set K : ℤ := ⌈2 * s⌉
  have hK : 2 * s ≤ K := Int.le_ceil _
  have hmaps : Set.MapsTo (PQ x D P0 Q0) (Set.Ici (M + 2)) (Set.Icc 0 K ×ˢ Set.Icc 0 K) := by
    intro n hn
    simp only [Set.mem_Ici] at hn
    obtain ⟨hy1, hy2⟩ := hbd n hn
    have hc1 : 1 < cq x n := by
      have := hcq1 (n - 1); rwa [Nat.sub_add_cancel (by omega)] at this
    have hQpos : (0 : ℝ) < Q n := by
      by_contra hc
      have hc := not_lt.1 hc
      have h1 := hdiff n
      have h2 : 2 * s / Q n ≤ 0 := div_nonpos_of_nonneg_of_nonpos (by linarith) hc
      linarith
    have e1 : (Q n : ℝ) < P n + s := by
      rw [hcq] at hc1; exact (one_lt_div hQpos).1 hc1
    have e2 : (P n : ℝ) + -s < 0 := by
      by_contra hc
      have hc := not_lt.1 hc
      have : 0 ≤ y n := div_nonneg hc hQpos.le
      linarith
    have e3 : -(Q n : ℝ) < P n + -s := by
      have := (lt_div_iff₀ hQpos).1 hy1
      linarith
    have hP0 : (0 : ℝ) ≤ P n := by linarith
    have hPK : (P n : ℝ) ≤ K := by linarith
    have hQK : (Q n : ℝ) ≤ K := by linarith
    refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩⟩
    · exact_mod_cast hP0
    · exact_mod_cast hPK
    · exact_mod_cast hQpos.le
    · exact_mod_cast hQK
  obtain ⟨i, -, j, -, hij, he⟩ := (Set.Ici_infinite (M + 2)).exists_ne_map_eq_of_mapsTo hmaps
    ((Set.finite_Icc 0 K).prod (Set.finite_Icc 0 K))
  have hcij : cq x i = cq x j := by
    rw [hcq, hcq]
    simp only [P, Q, he]
  rcases Nat.lt_or_gt_of_ne hij with h | h
  · exact periodic_of_eq hxi h hcij
  · exact periodic_of_eq hxi h hcij.symm

#print axioms cq_zero
#print axioms cq_succ
#print axioms cq_add
#print axioms irr_fract_inv
#print axioms irr_cq
#print axioms fract_ne_zero_of_irr
#print axioms one_lt_cq_succ
#print axioms one_le_floor_cq_succ
#print axioms stream_eq
#print axioms s_get
#print axioms partDens_get
#print axioms not_terminates
#print axioms irr_of_not_terminates
#print axioms eq_of_floors
#print axioms mul_fract_inv
#print axioms mobius
#print axioms quad_back
#print axioms quad_of_cq
#print axioms periodic_quad
#print axioms flip_aux
#print axioms form_irr
#print axioms quad_of_form
#print axioms form_of_quad
#print axioms periodic_of_eq
#print axioms PQ_succ
#print axioms PQ_inv
#print axioms lagrange

/-- **The theorem (Euler and Lagrange).** The steps of a real number `x` repeat forever exactly
when `x = (P + √D)/Q` for whole numbers `P`, `Q ≠ 0` and `D`, with `D` not a square and `Q`
dividing `D − P²`. -/
theorem steps_repeat_forever_iff_P_plus_root_D_over_Q (x : ℝ) :
    StepsRepeatForever x ↔
      ∃ (P Q : ℤ) (D : ℕ), Q ≠ 0 ∧ ¬ IsSquare D ∧ Q ∣ (D : ℤ) - P ^ 2 ∧
        x = (P + Real.sqrt D) / Q := by
  constructor
  · intro h
    obtain ⟨hi, hq⟩ := periodic_quad h
    exact form_of_quad hi hq
  · rintro ⟨P, Q, D, hQ, hD, hdiv, hx⟩
    exact lagrange hQ hD hdiv hx

/-- **The bold claim.** A continued fraction repeats forever exactly when its number is a
quadratic irrational: a root of a quadratic `a x² + b x + c = 0` with whole-number coefficients
(`a ≠ 0`) that is not itself a fraction. -/
theorem steps_repeat_forever_iff_quadratic_irrational (x : ℝ) :
    StepsRepeatForever x ↔
      Irrational x ∧ ∃ a b c : ℤ, a ≠ 0 ∧ (a : ℝ) * x ^ 2 + b * x + c = 0 := by
  rw [steps_repeat_forever_iff_P_plus_root_D_over_Q]
  constructor
  · rintro ⟨P, Q, D, hQ, hD, -, hx⟩
    exact quad_of_form hQ hD hx
  · rintro ⟨hi, hq⟩
    exact form_of_quad hi hq

/-- **The flip keeps the shape (Step 3).** Take `x = (P + √D)/Q` with `Q ≠ 0`, `D` not a square
and `Q` dividing `D − P²`, and any whole number `a` (such as the step, `x`'s whole part). With
new `P = aQ − P`: `Q` divides `D − (new P)²`, so new `Q = (D − (new P)²)/Q` is a whole number;
it is not zero; and flipping the leftover gives `1/(x − a) = (new P + √D)/new Q`. -/
theorem flip_keeps_the_shape (P Q a : ℤ) (D : ℕ) (hQ : Q ≠ 0) (hD : ¬ IsSquare D)
    (hdiv : Q ∣ (D : ℤ) - P ^ 2) :
    Q ∣ (D : ℤ) - (a * Q - P) ^ 2 ∧
      ((D : ℤ) - (a * Q - P) ^ 2) / Q ≠ 0 ∧
      ((P + Real.sqrt D) / Q - a)⁻¹ =
        ((a * Q - P : ℤ) + Real.sqrt D) / ((((D : ℤ) - (a * Q - P) ^ 2) / Q : ℤ) : ℝ) := by
  obtain ⟨h1, h2, h3, -⟩ :=
    flip_aux P Q a D (Real.sqrt D) (Real.sq_sqrt (Nat.cast_nonneg _)) hQ hD hdiv
  exact ⟨h1, h2, h3⟩

/-! ### The card's worked numbers, in whole numbers -/

/-- One exact step on the pair `(P, Q)` for `(P + √D)/Q` with `Q > 0`, where `r` is the whole part
of `√D`: the step `a` is the whole part, `(P + r) ÷ Q` rounded down; then new `P = aQ − P` and
new `Q = (D − new P²)/Q`. -/
def step (D r : ℤ) (PQ : ℤ × ℤ) : ℤ × (ℤ × ℤ) :=
  let a := (PQ.1 + r) / PQ.2
  let P' := a * PQ.2 - PQ.1
  (a, (P', (D - P' ^ 2) / PQ.2))

/-- The whole part of root 7 is 2: 2² ≤ 7 < 3². -/
example : (2 : ℤ) ^ 2 ≤ 7 ∧ (7 : ℤ) < 3 ^ 2 := by
  decide

/-- Root 7 by hand: from `(P, Q) = (0, 1)` the steps are 2, 1, 1, 1, 4 and the pairs run
(2, 3), (1, 2), (1, 3), (2, 1), then (2, 3) again: repeat length 4. -/
example : step 7 2 (0, 1) = (2, (2, 3)) ∧ step 7 2 (2, 3) = (1, (1, 2)) ∧
    step 7 2 (1, 2) = (1, (1, 3)) ∧ step 7 2 (1, 3) = (1, (2, 1)) ∧
    step 7 2 (2, 1) = (4, (2, 3)) := by
  decide

/-- The table's arithmetic: 2 × 1 − 0 = 2, (7 − 4)/1 = 3; 1 × 3 − 2 = 1, (7 − 1)/3 = 2;
1 × 2 − 1 = 1, (7 − 1)/2 = 3; 1 × 3 − 1 = 2, (7 − 4)/3 = 1; 4 × 1 − 2 = 2, (7 − 4)/1 = 3. -/
example : (2 * 1 - 0 : ℤ) = 2 ∧ (7 - 4) / 1 = (3 : ℤ) ∧ (1 * 3 - 2 : ℤ) = 1 ∧ (7 - 1) / 3 = (2 : ℤ) ∧
    (1 * 2 - 1 : ℤ) = 1 ∧ (7 - 1) / 2 = (3 : ℤ) ∧ (1 * 3 - 1 : ℤ) = 2 ∧ (7 - 4) / 3 = (1 : ℤ) ∧
    (4 * 1 - 2 : ℤ) = 2 ∧ (7 - 4) / 1 = (3 : ℤ) := by
  decide

/-- Folding blocks into quadratics with the stops rule: the block 1, 2 has last two stops 1/1 and
3/2, giving 2y² − 2y − 1 = 0; root 7's block 1, 1, 1, 4 has last two stops 3/2 and 14/9, giving
9y² − 12y − 3 = 0 (coefficients: last bottom, bottom before minus last top, minus top before).
Its discriminant 12² + 4 × 9 × 3 = 252 = 6² × 7. -/
example : (1 - 3 : ℤ) = -2 ∧ (2 - 14 : ℤ) = -12 ∧
    (-12 : ℤ) ^ 2 - 4 * 9 * (-3) = 252 ∧ (252 : ℤ) = 6 ^ 2 * 7 := by
  decide

/-- Pell's equation: root 7's stop at its block's end is 8/3, and 8² − 7 × 3² = 1. -/
example : (8 : ℤ) ^ 2 - 7 * 3 ^ 2 = 1 := by
  norm_num

/-- A4 paper: 297/210 is exactly root 2's stop 99/70. -/
example : (297 : ℚ) / 210 = 99 / 70 := by
  norm_num

/-- The golden ratio's stops 1/1, 2/1, 3/2, 5/3, 8/5, 13/8 all have p² − pq − q² = ±1. -/
example : [(1, 1), (2, 1), (3, 2), (5, 3), (8, 5), (13, 8)].all
    (fun (pq : ℤ × ℤ) => pq.1 ^ 2 - pq.1 * pq.2 - pq.2 ^ 2 = 1 ∨
      pq.1 ^ 2 - pq.1 * pq.2 - pq.2 ^ 2 = -1) = true := by
  decide

#print axioms steps_repeat_forever_iff_P_plus_root_D_over_Q
#print axioms steps_repeat_forever_iff_quadratic_irrational
#print axioms flip_keeps_the_shape

end PeriodicContinuedFractions
