-- Pell's equation: the positive solutions of x^2 - d y^2 = 1 are exactly the continued-fraction convergents of root d at block ends with the right sign, the expansion of root d repeats in blocks ending in twice its whole part, and every solution is a power of the smallest one.
import Mathlib.Algebra.ContinuedFractions.Computation.Basic
import Mathlib.Algebra.ContinuedFractions.Translations
import Mathlib.Algebra.Order.Floor.Defs
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.Group.Even
import Mathlib.Order.Bounds.Defs
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.Pell
import Mathlib.NumberTheory.DiophantineApproximation.ContinuedFractions
import Mathlib.Algebra.ContinuedFractions.Computation.ApproximationCorollaries
import Mathlib.Algebra.ContinuedFractions.ContinuantsRecurrence
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.Tactic

open Real

namespace PellCF

/-- One step of the integer recursion `(P, Q) ↦ (a Q - P, (d - (a Q - P)^2) / Q)`. -/
noncomputable def step (d : ℕ) (pq : ℤ × ℤ) : ℤ × ℤ :=
  (⌊((pq.1 : ℝ) + √(d : ℝ)) / pq.2⌋ * pq.2 - pq.1,
   ((d : ℤ) - (⌊((pq.1 : ℝ) + √(d : ℝ)) / pq.2⌋ * pq.2 - pq.1) ^ 2) / pq.2)

noncomputable def PQ (d n : ℕ) : ℤ × ℤ := (step d)^[n] (0, 1)

noncomputable def X (d n : ℕ) : ℝ := (((PQ d n).1 : ℝ) + √(d : ℝ)) / (PQ d n).2

noncomputable def Y (d n : ℕ) : ℝ := (((PQ d n).1 : ℝ) - √(d : ℝ)) / (PQ d n).2

noncomputable def A (d n : ℕ) : ℤ := ⌊X d n⌋

lemma PQ_succ (d n : ℕ) : PQ d (n + 1) = step d (PQ d n) := by
  unfold PQ; rw [Function.iterate_succ_apply']

lemma PQ_add (d i m : ℕ) : PQ d (i + m) = (step d)^[i] (PQ d m) := by
  unfold PQ; rw [Function.iterate_add_apply]

lemma P_succ (d n : ℕ) : (PQ d (n + 1)).1 = A d n * (PQ d n).2 - (PQ d n).1 := by
  rw [PQ_succ]; rfl

lemma Q_succ (d n : ℕ) :
    (PQ d (n + 1)).2 = ((d : ℤ) - (PQ d (n + 1)).1 ^ 2) / (PQ d n).2 := by
  rw [P_succ, PQ_succ]; rfl

lemma PQ_zero (d : ℕ) : PQ d 0 = (0, 1) := rfl

lemma X_zero (d : ℕ) : X d 0 = √(d : ℝ) := by
  simp [X, PQ_zero]

lemma A_zero (d : ℕ) : A d 0 = Nat.sqrt d := by
  rw [A, X_zero, Real.floor_real_sqrt_eq_nat_sqrt]

lemma irr (d : ℕ) (hd : ¬ IsSquare d) : Irrational (√(d : ℝ)) :=
  irrational_sqrt_natCast_iff.mpr hd

lemma lin_indep (d : ℕ) (hd : ¬ IsSquare d) (u v : ℤ) (h : (u : ℝ) + v * √(d : ℝ) = 0) :
    u = 0 ∧ v = 0 := by
  have hv : v = 0 := by
    by_contra hv
    have hv' : (v : ℝ) ≠ 0 := by exact_mod_cast hv
    have : √(d : ℝ) = ((-u : ℤ) : ℝ) / (v : ℝ) := by
      push_cast; field_simp; linarith
    exact (irrational_iff_ne_rational _).mp (irr d hd) (-u) v hv this
  subst hv
  simp at h
  exact ⟨by exact_mod_cast h, rfl⟩

lemma d_sub_sq_ne (d : ℕ) (hd : ¬ IsSquare d) (P : ℤ) : (d : ℤ) - P ^ 2 ≠ 0 := by
  intro h
  apply hd
  refine ⟨P.natAbs, ?_⟩
  have : (d : ℤ) = (P.natAbs : ℤ) * (P.natAbs : ℤ) := by
    rw [Int.natAbs_mul_self' P]; linarith
  exact_mod_cast this

lemma d_ge_two (d : ℕ) (hd : ¬ IsSquare d) : 2 ≤ d := by
  by_contra h
  interval_cases d
  · exact hd ⟨0, rfl⟩
  · exact hd ⟨1, rfl⟩

lemma s_pos (d : ℕ) (hd : ¬ IsSquare d) : 1 ≤ Nat.sqrt d := by
  rw [Nat.le_sqrt]; have := d_ge_two d hd; omega

lemma sqrt_gt_one (d : ℕ) (hd : ¬ IsSquare d) : 1 < √(d : ℝ) := by
  have h2 : (2 : ℝ) ≤ d := by exact_mod_cast d_ge_two d hd
  rw [show (1 : ℝ) = √1 by simp]
  exact Real.sqrt_lt_sqrt (by norm_num) (by linarith)

lemma sqrt_sq_d (d : ℕ) : √(d : ℝ) ^ 2 = d := Real.sq_sqrt (Nat.cast_nonneg _)

lemma Q_inv (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    (PQ d n).2 ≠ 0 ∧ (PQ d n).2 ∣ (d : ℤ) - (PQ d n).1 ^ 2 := by
  induction n with
  | zero => simp [PQ_zero]
  | succ n ih =>
    obtain ⟨hQ, hdvd⟩ := ih
    have hdvd' : (PQ d n).2 ∣ (d : ℤ) - (PQ d (n + 1)).1 ^ 2 := by
      rw [P_succ]
      have : (d : ℤ) - (A d n * (PQ d n).2 - (PQ d n).1) ^ 2 =
          ((d : ℤ) - (PQ d n).1 ^ 2) + (PQ d n).2 * (2 * A d n * (PQ d n).1 - A d n ^ 2 * (PQ d n).2) := by
        ring
      rw [this]; exact dvd_add hdvd (dvd_mul_right _ _)
    obtain ⟨k, hk⟩ := hdvd'
    have hq : (PQ d (n + 1)).2 = k := by
      rw [Q_succ, hk, Int.mul_ediv_cancel_left _ hQ]
    have hne := d_sub_sq_ne d hd (PQ d (n + 1)).1
    refine ⟨?_, ?_⟩
    · rw [hq]; rintro rfl; apply hne; rw [hk]; ring
    · rw [hk, hq]; exact dvd_mul_left _ _

lemma QQ (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    (PQ d n).2 * (PQ d (n + 1)).2 = (d : ℤ) - (PQ d (n + 1)).1 ^ 2 := by
  have hdvd : (PQ d n).2 ∣ (d : ℤ) - (PQ d (n + 1)).1 ^ 2 := by
    rw [P_succ]
    have : (d : ℤ) - (A d n * (PQ d n).2 - (PQ d n).1) ^ 2 =
        ((d : ℤ) - (PQ d n).1 ^ 2) + (PQ d n).2 * (2 * A d n * (PQ d n).1 - A d n ^ 2 * (PQ d n).2) := by
      ring
    rw [this]; exact dvd_add (Q_inv d hd n).2 (dvd_mul_right _ _)
  rw [Q_succ]; exact Int.mul_ediv_cancel' hdvd

lemma QQ_real (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    ((PQ d n).2 : ℝ) * (PQ d (n + 1)).2 = (d : ℝ) - ((PQ d (n + 1)).1 : ℝ) ^ 2 := by
  exact_mod_cast QQ d hd n

lemma fract_ne (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : Int.fract (X d n) ≠ 0 := by
  intro h
  rw [Int.fract, sub_eq_zero] at h
  have hQ : ((PQ d n).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd n).1
  rw [X] at h
  field_simp at h
  have := lin_indep d hd ((PQ d n).1 - ⌊X d n⌋ * (PQ d n).2) 1 (by push_cast; rw [X]; linarith)
  simp at this

lemma X_succ (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : X d (n + 1) = (X d n - A d n)⁻¹ := by
  have hQ : ((PQ d n).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd n).1
  have hQ' : ((PQ d (n + 1)).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd (n + 1)).1
  have hP : ((PQ d (n + 1)).1 : ℝ) = A d n * (PQ d n).2 - (PQ d n).1 := by
    exact_mod_cast P_succ d n
  have hne : √(d : ℝ) - (PQ d (n + 1)).1 ≠ 0 := by
    intro h
    have := lin_indep d hd (-(PQ d (n + 1)).1) 1 (by push_cast; linarith)
    simp at this
  have hQQ := QQ_real d hd n
  have hs := sqrt_sq_d d
  have e : X d n - A d n = (√(d : ℝ) - (PQ d (n + 1)).1) / (PQ d n).2 := by
    rw [X, hP]; field_simp; ring
  rw [e, inv_div, X]
  rw [div_eq_div_iff hQ' hne]
  linear_combination -hQQ + hs

lemma Y_succ (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : Y d (n + 1) = (Y d n - A d n)⁻¹ := by
  have hQ : ((PQ d n).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd n).1
  have hQ' : ((PQ d (n + 1)).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd (n + 1)).1
  have hP : ((PQ d (n + 1)).1 : ℝ) = A d n * (PQ d n).2 - (PQ d n).1 := by
    exact_mod_cast P_succ d n
  have hne : -√(d : ℝ) - (PQ d (n + 1)).1 ≠ 0 := by
    intro h
    have := lin_indep d hd ((PQ d (n + 1)).1) 1 (by push_cast; linarith)
    simp at this
  have hQQ := QQ_real d hd n
  have hs := sqrt_sq_d d
  have e : Y d n - A d n = (-√(d : ℝ) - (PQ d (n + 1)).1) / (PQ d n).2 := by
    rw [Y, hP]; field_simp; ring
  rw [e, inv_div, Y]
  rw [div_eq_div_iff hQ' hne]
  linear_combination -hQQ + hs


lemma A_eq (d n : ℕ) : (A d n : ℝ) = ⌊X d n⌋ := rfl

lemma fract_X (d n : ℕ) : Int.fract (X d n) = X d n - A d n := rfl

lemma X_gt_one (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : 1 < X d (n + 1) := by
  rw [X_succ d hd n, ← fract_X]
  have h0 : 0 < Int.fract (X d n) :=
    lt_of_le_of_ne (Int.fract_nonneg _) (Ne.symm (fract_ne d hd n))
  exact (one_lt_inv₀ h0).mpr (Int.fract_lt_one _)

lemma A_pos (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : 1 ≤ A d n := by
  cases n with
  | zero => rw [A_zero]; exact_mod_cast s_pos d hd
  | succ n => exact Int.le_floor.mpr (by exact_mod_cast (X_gt_one d hd n).le)

lemma inv_bounds (t : ℝ) (ht : t < -1) : -1 < t⁻¹ ∧ t⁻¹ < 0 := by
  have hneg : t⁻¹ < 0 := inv_lt_zero.mpr (by linarith)
  refine ⟨?_, hneg⟩
  have hm : t * t⁻¹ = 1 := mul_inv_cancel₀ (by linarith)
  nlinarith

lemma Y_zero (d : ℕ) : Y d 0 = -√(d : ℝ) := by
  simp [Y, PQ_zero]

lemma Y_bounds (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : -1 < Y d (n + 1) ∧ Y d (n + 1) < 0 := by
  induction n with
  | zero =>
    rw [Y_succ d hd 0]
    apply inv_bounds
    rw [Y_zero, A_zero]
    have := sqrt_gt_one d hd
    have : (0 : ℝ) ≤ ((Nat.sqrt d : ℤ) : ℝ) := by exact_mod_cast Nat.zero_le _
    linarith
  | succ n ih =>
    rw [Y_succ d hd (n + 1)]
    apply inv_bounds
    have : (1 : ℝ) ≤ A d (n + 1) := by exact_mod_cast A_pos d hd (n + 1)
    linarith [ih.2]

lemma bounds (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    0 < (PQ d (n + 1)).2 ∧ 0 < (PQ d (n + 1)).1 ∧ (PQ d (n + 1)).1 ≤ Nat.sqrt d ∧
      (PQ d (n + 1)).2 ≤ 2 * Nat.sqrt d + 1 ∧
      √(d : ℝ) - (PQ d (n + 1)).2 < (PQ d (n + 1)).1 := by
  have hX := X_gt_one d hd n
  have hY := Y_bounds d hd n
  have hQne : ((PQ d (n + 1)).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd (n + 1)).1
  have hr1 : 1 < √(d : ℝ) := sqrt_gt_one d hd
  have hu : X d (n + 1) * ((PQ d (n + 1)).2 : ℝ) = (PQ d (n + 1)).1 + √(d : ℝ) := by
    rw [X, div_mul_cancel₀ _ hQne]
  have hv : Y d (n + 1) * ((PQ d (n + 1)).2 : ℝ) = (PQ d (n + 1)).1 - √(d : ℝ) := by
    rw [Y, div_mul_cancel₀ _ hQne]
  have hQpos : (0 : ℝ) < (PQ d (n + 1)).2 := by
    rcases lt_or_gt_of_ne hQne with h | h
    · exfalso
      nlinarith [mul_lt_mul_of_neg_right hX h, mul_lt_mul_of_neg_right hY.2 h]
    · exact h
  have h1 : ((PQ d (n + 1)).2 : ℝ) < (PQ d (n + 1)).1 + √(d : ℝ) := by nlinarith
  have h2 : ((PQ d (n + 1)).1 : ℝ) < √(d : ℝ) := by nlinarith
  have h3 : -((PQ d (n + 1)).2 : ℝ) < (PQ d (n + 1)).1 - √(d : ℝ) := by nlinarith
  have hP0 : (0 : ℝ) < (PQ d (n + 1)).1 := by linarith
  have hsr : √(d : ℝ) < (Nat.sqrt d : ℝ) + 1 := Real.real_sqrt_lt_nat_sqrt_succ
  refine ⟨by exact_mod_cast hQpos, by exact_mod_cast hP0, ?_, ?_, by linarith⟩
  · have : (PQ d (n + 1)).1 ≤ ⌊√(d : ℝ)⌋ := Int.le_floor.mpr h2.le
    rwa [Real.floor_real_sqrt_eq_nat_sqrt] at this
  · have : ((PQ d (n + 1)).2 : ℝ) < 2 * ((Nat.sqrt d : ℤ) : ℝ) + 2 := by push_cast; linarith
    have : (PQ d (n + 1)).2 < 2 * (Nat.sqrt d : ℤ) + 2 := by exact_mod_cast this
    omega

lemma stream_gen (Z : ℕ → ℝ) (h1 : ∀ i, Int.fract (Z i) ≠ 0)
    (h2 : ∀ i, (Int.fract (Z i))⁻¹ = Z (i + 1)) (n : ℕ) :
    GenContFract.IntFractPair.stream (Z 0) n = some (GenContFract.IntFractPair.of (Z n)) := by
  induction n with
  | zero => exact GenContFract.IntFractPair.stream_zero _
  | succ n ih =>
    rw [GenContFract.IntFractPair.stream_succ_of_some ih (h1 n)]
    show some (GenContFract.IntFractPair.of (Int.fract (Z n))⁻¹) = _
    rw [h2 n]

lemma s_get (d : ℕ) (hd : ¬ IsSquare d) (m i : ℕ) :
    (GenContFract.of (X d m)).s.get? i = some ⟨1, (A d (m + i + 1) : ℝ)⟩ := by
  have hs := stream_gen (fun k => X d (m + k)) (fun k => fract_ne d hd (m + k))
    (fun k => by rw [fract_X, ← X_succ d hd]; rfl) (i + 1)
  simp only [add_zero] at hs
  rw [GenContFract.get?_of_eq_some_of_succ_get?_intFractPair_stream hs]
  rfl

lemma partDens_get (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    (GenContFract.of (√(d : ℝ))).partDens.get? n = some (A d (n + 1) : ℝ) := by
  rw [← X_zero, GenContFract.partDen_eq_s_b (s_get d hd 0 n), zero_add]

lemma PQ_one (d : ℕ) : PQ d 1 = ((Nat.sqrt d : ℤ), (d : ℤ) - (Nat.sqrt d : ℤ) ^ 2) := by
  have hP : (PQ d 1).1 = Nat.sqrt d := by
    rw [P_succ, A_zero, PQ_zero]; simp
  refine Prod.ext hP ?_
  rw [Q_succ, hP, PQ_zero]; simp

lemma per_of_PQ (d n : ℕ) (h : PQ d (n + 1) = PQ d 1) (i : ℕ) :
    PQ d (i + 1 + n) = PQ d (i + 1) := by
  rw [show i + 1 + n = i + (n + 1) by omega, PQ_add, h, ← PQ_add]

lemma Q_one_of_PQ (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) (h : PQ d (n + 1) = PQ d 1) :
    (PQ d n).2 = 1 := by
  have e1 := QQ d hd n
  have e0 := QQ d hd 0
  rw [h] at e1
  rw [PQ_zero] at e0
  simp only [one_mul] at e0
  have hne : (PQ d 1).2 ≠ 0 := (Q_inv d hd 1).1
  have : (PQ d n).2 * (PQ d 1).2 = 1 * (PQ d 1).2 := by rw [e1, e0]; ring
  exact mul_right_cancel₀ hne this

lemma PQ_of_Q_one (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) (h : (PQ d (n + 1)).2 = 1) :
    PQ d (n + 2) = PQ d 1 := by
  obtain ⟨-, -, hle, -, hgt⟩ := bounds d hd n
  rw [h] at hgt
  have hs : (Nat.sqrt d : ℝ) ≤ √(d : ℝ) := Real.nat_sqrt_le_real_sqrt
  have hP : (PQ d (n + 1)).1 = Nat.sqrt d := by
    have : ((Nat.sqrt d : ℤ) : ℝ) - 1 < (PQ d (n + 1)).1 := by push_cast at hgt ⊢; linarith
    have : (Nat.sqrt d : ℤ) - 1 < (PQ d (n + 1)).1 := by exact_mod_cast this
    omega
  have hA : A d (n + 1) = 2 * Nat.sqrt d := by
    rw [A, X, hP, h]
    simp only [Int.cast_one, div_one, Int.cast_natCast]
    rw [Int.floor_natCast_add, Real.floor_real_sqrt_eq_nat_sqrt]; ring
  have hP2 : (PQ d (n + 2)).1 = Nat.sqrt d := by
    rw [P_succ, hA, h, hP]; ring
  rw [PQ_one]
  refine Prod.ext hP2 ?_
  rw [Q_succ, hP2, h]; simp

lemma back (d : ℕ) (hd : ¬ IsSquare d) (m n : ℕ) (h : PQ d (m + 2) = PQ d (n + 2)) :
    PQ d (m + 1) = PQ d (n + 1) := by
  have key : ∀ k, A d (k + 1) = ⌊-(Y d (k + 2))⁻¹⌋ := by
    intro k
    rw [Y_succ d hd (k + 1), inv_inv]
    have hb := Y_bounds d hd k
    symm
    rw [Int.floor_eq_iff]
    constructor <;> linarith
  have hY : Y d (m + 2) = Y d (n + 2) := by unfold Y; rw [h]
  have hA : A d (m + 1) = A d (n + 1) := by rw [key m, key n, hY]
  have hQ : (PQ d (m + 1)).2 = (PQ d (n + 1)).2 := by
    have e1 := QQ d hd (m + 1)
    have e2 := QQ d hd (n + 1)
    rw [h] at e1
    have hne : (PQ d (n + 2)).2 ≠ 0 := (Q_inv d hd (n + 2)).1
    exact mul_right_cancel₀ hne (e1.trans e2.symm)
  have e1 := P_succ d (m + 1)
  have e2 := P_succ d (n + 1)
  rw [h] at e1
  refine Prod.ext ?_ hQ
  rw [hA, hQ] at e1
  linarith

lemma eqPQ (d : ℕ) (hd : ¬ IsSquare d) (m n : ℕ) (h : X d m = X d n) : PQ d m = PQ d n := by
  have hQm : ((PQ d m).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd m).1
  have hQn : ((PQ d n).2 : ℝ) ≠ 0 := by exact_mod_cast (Q_inv d hd n).1
  unfold X at h
  rw [div_eq_div_iff hQm hQn] at h
  have := lin_indep d hd ((PQ d m).1 * (PQ d n).2 - (PQ d n).1 * (PQ d m).2)
    ((PQ d n).2 - (PQ d m).2) (by push_cast; linarith)
  obtain ⟨h1, h2⟩ := this
  have hq : (PQ d m).2 = (PQ d n).2 := by linarith
  refine Prod.ext ?_ hq
  rw [hq] at h1
  have hne : (PQ d n).2 ≠ 0 := (Q_inv d hd n).1
  have : ((PQ d m).1 - (PQ d n).1) * (PQ d n).2 = 0 := by linarith
  rcases mul_eq_zero.mp this with h | h
  · linarith
  · exact absurd h hne

lemma desc (d : ℕ) (hd : ¬ IsSquare d) (k : ℕ) :
    ∀ i, PQ d (i + 1) = PQ d (i + k + 1) → PQ d 1 = PQ d (k + 1) := by
  intro i
  induction i with
  | zero => simp
  | succ i ih =>
    intro h
    apply ih
    have := back d hd i (i + k) (by rw [show i + 2 = i + 1 + 1 by ring, h]; congr 1; ring)
    exact this

lemma exists_period (d : ℕ) (hd : ¬ IsSquare d) : ∃ L, 0 < L ∧ PQ d (L + 1) = PQ d 1 := by
  let t : Finset (ℤ × ℤ) := (Finset.Icc 1 (Nat.sqrt d : ℤ)) ×ˢ (Finset.Icc (1 : ℤ) (2 * (Nat.sqrt d : ℤ) + 1))
  have hmaps : ∀ a ∈ Finset.range (t.card + 1), PQ d (a + 1) ∈ t := by
    intro a _
    obtain ⟨h1, h2, h3, h4, -⟩ := bounds d hd a
    simp only [t, Finset.mem_product, Finset.mem_Icc]
    omega
  obtain ⟨i, -, j, -, hij, heq⟩ :=
    Finset.exists_ne_map_eq_of_card_lt_of_maps_to (by simp) hmaps
  rcases lt_or_gt_of_ne hij with h | h
  · refine ⟨j - i, by omega, ?_⟩
    exact (desc d hd (j - i) i (by rw [heq]; congr 1; omega)).symm
  · refine ⟨i - j, by omega, ?_⟩
    exact (desc d hd (i - j) j (by rw [← heq]; congr 1; omega)).symm


lemma P_A_of_Q_one (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) (h : (PQ d (n + 1)).2 = 1) :
    (PQ d (n + 1)).1 = Nat.sqrt d ∧ A d (n + 1) = 2 * Nat.sqrt d := by
  obtain ⟨-, -, hle, -, hgt⟩ := bounds d hd n
  rw [h] at hgt
  have hs : (Nat.sqrt d : ℝ) ≤ √(d : ℝ) := Real.nat_sqrt_le_real_sqrt
  have hP : (PQ d (n + 1)).1 = Nat.sqrt d := by
    have : ((Nat.sqrt d : ℤ) : ℝ) - 1 < (PQ d (n + 1)).1 := by push_cast at hgt ⊢; linarith
    have : (Nat.sqrt d : ℤ) - 1 < (PQ d (n + 1)).1 := by exact_mod_cast this
    omega
  refine ⟨hP, ?_⟩
  rw [A, X, hP, h]
  simp only [Int.cast_one, div_one, Int.cast_natCast]
  rw [Int.floor_natCast_add, Real.floor_real_sqrt_eq_nat_sqrt]; ring

/-- `n` is a period of the partial denominators of root d. -/
def Per (d n : ℕ) : Prop :=
  ∀ i : ℕ, (GenContFract.of (√(d : ℝ))).partDens.get? (i + n) =
    (GenContFract.of (√(d : ℝ))).partDens.get? i

lemma per_iff_A (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    Per d n ↔ ∀ i, A d (i + n + 1) = A d (i + 1) := by
  unfold Per
  simp only [partDens_get d hd, Option.some.injEq, Int.cast_inj]

lemma per_of_PQ' (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) (h : PQ d (n + 1) = PQ d 1) : Per d n := by
  rw [per_iff_A d hd]
  intro i
  unfold A X
  rw [show i + n + 1 = i + 1 + n by omega, per_of_PQ d n h i]

lemma PQ_of_per (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) (h : Per d n) : PQ d (n + 1) = PQ d 1 := by
  rw [per_iff_A d hd] at h
  have heq : GenContFract.of (X d 1) = GenContFract.of (X d (n + 1)) := by
    ext1
    · rw [GenContFract.of_h_eq_floor, GenContFract.of_h_eq_floor]
      have := h 0
      simp only [zero_add] at this
      change ((A d 1 : ℤ) : ℝ) = ((A d (n + 1) : ℤ) : ℝ)
      rw [this]
    · apply Stream'.Seq.ext
      intro i
      rw [s_get d hd, s_get d hd]
      have := h (i + 1)
      rw [show 1 + i + 1 = i + 1 + 1 by omega, show n + 1 + i + 1 = i + 1 + n + 1 by omega, this]
  have t1 := GenContFract.of_convergence (v := X d 1)
  have t2 := GenContFract.of_convergence (v := X d (n + 1))
  rw [heq] at t1
  exact (eqPQ d hd _ _ (tendsto_nhds_unique t1 t2)).symm

lemma per_mul (d ℓ : ℕ) (h : Per d ℓ) (j : ℕ) : Per d (j * ℓ) := by
  induction j with
  | zero => intro i; simp
  | succ j ih =>
    intro i
    rw [show i + (j + 1) * ℓ = (i + j * ℓ) + ℓ by ring, h, ih]

lemma per_sub (d a b : ℕ) (hab : Per d (a + b)) (hb : Per d b) : Per d a := by
  intro i
  rw [← hb (i + a), ← hab i, add_assoc]

lemma dvd_of_per (d ℓ : ℕ)
    (hℓ : IsLeast {n : ℕ | 0 < n ∧ ∀ i : ℕ,
      (GenContFract.of (√(d : ℝ))).partDens.get? (i + n) =
        (GenContFract.of (√(d : ℝ))).partDens.get? i} ℓ)
    (m : ℕ) (hm : Per d m) : ℓ ∣ m := by
  have hpos : 0 < ℓ := hℓ.1.1
  have hper : Per d ℓ := hℓ.1.2
  have hmod : Per d (m % ℓ) := by
    apply per_sub d (m % ℓ) (m / ℓ * ℓ) _ (per_mul d ℓ hper _)
    rw [show m % ℓ + m / ℓ * ℓ = m by rw [mul_comm]; exact Nat.mod_add_div m ℓ]
    exact hm
  apply Nat.dvd_of_mod_eq_zero
  by_contra hne
  have := hℓ.2 ⟨Nat.pos_of_ne_zero hne, hmod⟩
  have := Nat.mod_lt m hpos
  omega

/-- Numerators `p_(n-1)` of the convergents, with `p_(-1) = 1`. -/
noncomputable def pm (d : ℕ) : ℕ → ℤ
  | 0 => 1
  | 1 => A d 0
  | (n + 2) => A d (n + 1) * pm d (n + 1) + pm d n

/-- Denominators `q_(n-1)` of the convergents, with `q_(-1) = 0`. -/
noncomputable def qm (d : ℕ) : ℕ → ℤ
  | 0 => 0
  | 1 => 1
  | (n + 2) => A d (n + 1) * qm d (n + 1) + qm d n

lemma contsAux_eq (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    (GenContFract.of (√(d : ℝ))).contsAux n = ⟨(pm d n : ℝ), (qm d n : ℝ)⟩ ∧
    (GenContFract.of (√(d : ℝ))).contsAux (n + 1) = ⟨(pm d (n + 1) : ℝ), (qm d (n + 1) : ℝ)⟩ := by
  induction n with
  | zero =>
    refine ⟨?_, ?_⟩
    · rw [GenContFract.zeroth_contAux_eq_one_zero]; simp [pm, qm]
    · rw [GenContFract.first_contAux_eq_h_one, GenContFract.of_h_eq_floor]
      simp only [pm, qm, Int.cast_one]
      rw [← X_zero]; rfl
  | succ n ih =>
    refine ⟨ih.2, ?_⟩
    have hs : (GenContFract.of (√(d : ℝ))).s.get? n = some ⟨1, (A d (n + 1) : ℝ)⟩ := by
      rw [← X_zero, s_get d hd 0 n, zero_add]
    rw [GenContFract.contsAux_recurrence hs ih.1 ih.2]
    simp only [pm, qm]
    push_cast
    ring_nf

lemma nums_eq (d : ℕ) (hd : ¬ IsSquare d) (k : ℕ) :
    (GenContFract.of (√(d : ℝ))).nums k = (pm d (k + 1) : ℝ) := by
  rw [GenContFract.num_eq_conts_a, GenContFract.nth_cont_eq_succ_nth_contAux,
    (contsAux_eq d hd (k + 1)).1]

lemma dens_eq (d : ℕ) (hd : ¬ IsSquare d) (k : ℕ) :
    (GenContFract.of (√(d : ℝ))).dens k = (qm d (k + 1) : ℝ) := by
  rw [GenContFract.den_eq_conts_b, GenContFract.nth_cont_eq_succ_nth_contAux,
    (contsAux_eq d hd (k + 1)).1]

lemma det (d : ℕ) (n : ℕ) :
    pm d (n + 1) * qm d n - pm d n * qm d (n + 1) = (-1) ^ (n + 1) := by
  induction n with
  | zero => simp [pm, qm]
  | succ n ih =>
    simp only [pm, qm] at ih ⊢
    rw [pow_succ]
    linear_combination (-1) * ih

lemma EF (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    pm d (n + 1) * (PQ d (n + 1)).1 + pm d n * (PQ d (n + 1)).2 = d * qm d (n + 1) ∧
    qm d (n + 1) * (PQ d (n + 1)).1 + qm d n * (PQ d (n + 1)).2 = pm d (n + 1) := by
  induction n with
  | zero =>
    rw [PQ_one]; simp only [pm, qm, A_zero]; constructor <;> ring
  | succ n ih =>
    obtain ⟨E, F⟩ := ih
    have hQQ := QQ d hd (n + 1)
    have hP2 := P_succ d (n + 1)
    have hQ : (PQ d (n + 1)).2 ≠ 0 := (Q_inv d hd (n + 1)).1
    rw [hP2] at hQQ
    simp only [pm, qm]
    rw [hP2]
    constructor
    · have key : (PQ d (n + 1)).2 *
          ((A d (n + 1) * pm d (n + 1) + pm d n) * (A d (n + 1) * (PQ d (n + 1)).2 - (PQ d (n + 1)).1)
            + pm d (n + 1) * (PQ d (n + 1 + 1)).2 - d * (A d (n + 1) * qm d (n + 1) + qm d n)) = 0 := by
        linear_combination pm d (n + 1) * hQQ + (A d (n + 1) * (PQ d (n + 1)).2 - (PQ d (n + 1)).1) * E
          - (d : ℤ) * F
      rcases mul_eq_zero.mp key with h | h
      · exact absurd h hQ
      · linarith
    · have key : (PQ d (n + 1)).2 *
          ((A d (n + 1) * qm d (n + 1) + qm d n) * (A d (n + 1) * (PQ d (n + 1)).2 - (PQ d (n + 1)).1)
            + qm d (n + 1) * (PQ d (n + 1 + 1)).2 - (A d (n + 1) * pm d (n + 1) + pm d n)) = 0 := by
        linear_combination qm d (n + 1) * hQQ + (A d (n + 1) * (PQ d (n + 1)).2 - (PQ d (n + 1)).1) * F
          - E
      rcases mul_eq_zero.mp key with h | h
      · exact absurd h hQ
      · linarith

lemma norm_eq (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) :
    pm d (n + 1) ^ 2 - d * qm d (n + 1) ^ 2 = (-1) ^ (n + 1) * (PQ d (n + 1)).2 := by
  obtain ⟨E, F⟩ := EF d hd n
  have D := det d n
  linear_combination -pm d (n + 1) * F + qm d (n + 1) * E + (PQ d (n + 1)).2 * D

lemma pm_pos (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : 1 ≤ pm d n ∧ 1 ≤ pm d (n + 1) := by
  induction n with
  | zero => exact ⟨le_refl _, by simp only [pm]; exact A_pos d hd 0⟩
  | succ n ih =>
    refine ⟨ih.2, ?_⟩
    simp only [pm]
    have := A_pos d hd (n + 1)
    nlinarith [ih.1, ih.2]

lemma qm_pos (d : ℕ) (hd : ¬ IsSquare d) (n : ℕ) : 0 ≤ qm d n ∧ 1 ≤ qm d (n + 1) := by
  induction n with
  | zero => simp [qm]
  | succ n ih =>
    refine ⟨by linarith [ih.2], ?_⟩
    simp only [qm]
    have := A_pos d hd (n + 1)
    nlinarith [ih.1, ih.2]

lemma coprime_pq (d k : ℕ) : IsCoprime (pm d (k + 1)) (qm d (k + 1)) := by
  have D := det d k
  have e : ((-1 : ℤ) ^ (k + 1)) ^ 2 = 1 := by
    rw [← pow_mul]; exact Even.neg_one_pow ⟨k + 1, by ring⟩
  refine ⟨(-1) ^ (k + 1) * qm d k, -((-1) ^ (k + 1)) * pm d k, ?_⟩
  linear_combination (-1) ^ (k + 1) * D + e

lemma approx (d : ℕ) (hd : ¬ IsSquare d) (x y : ℕ) (hy : 0 < y)
    (h : (x : ℤ) ^ 2 - d * (y : ℤ) ^ 2 = 1) :
    |√(d : ℝ) - (x : ℝ) / y| < 1 / (2 * (y : ℝ) ^ 2) := by
  have hr := sqrt_gt_one d hd
  have hs := sqrt_sq_d d
  have hyR : (0 : ℝ) < y := by exact_mod_cast hy
  have hR : (x : ℝ) ^ 2 - d * (y : ℝ) ^ 2 = 1 := by exact_mod_cast h
  have hx0 : (0 : ℝ) ≤ x := Nat.cast_nonneg _
  have hyr : 0 < (y : ℝ) * √(d : ℝ) := by positivity
  have hprod : ((x : ℝ) - y * √(d : ℝ)) * (x + y * √(d : ℝ)) = 1 := by
    linear_combination hR - (y : ℝ) ^ 2 * hs
  have hpos : 0 < (x : ℝ) - y * √(d : ℝ) := by
    by_contra hc
    push Not at hc
    nlinarith
  have hbig : 2 * (y : ℝ) < x + y * √(d : ℝ) := by nlinarith
  have e : √(d : ℝ) - (x : ℝ) / y = -(((x : ℝ) - y * √(d : ℝ)) / y) := by
    field_simp; ring
  rw [e, abs_neg, abs_of_pos (div_pos hpos hyR), div_lt_div_iff₀ hyR (by positivity)]
  nlinarith

lemma legendre (d : ℕ) (hd : ¬ IsSquare d) (x y : ℕ) (hy : 0 < y)
    (h : (x : ℤ) ^ 2 - d * (y : ℤ) ^ 2 = 1) :
    ∃ k, (x : ℤ) = pm d (k + 1) ∧ (y : ℤ) = qm d (k + 1) := by
  have hcop : IsCoprime (x : ℤ) (y : ℤ) := ⟨x, -(d * y), by linear_combination h⟩
  have hcop' : Nat.Coprime (x : ℤ).natAbs (y : ℤ).natAbs := Int.isCoprime_iff_gcd_eq_one.mp hcop
  have hy' : (0 : ℤ) < y := by exact_mod_cast hy
  set q : ℚ := ((x : ℤ) : ℚ) / ((y : ℤ) : ℚ) with hq
  have hden : (q.den : ℝ) = y := by
    have h1 : (q.den : ℤ) = y := Rat.den_div_eq_of_coprime hy' hcop'
    exact_mod_cast h1
  have hqR : (q : ℝ) = (x : ℝ) / y := by rw [hq]; push_cast; ring
  obtain ⟨k, hk⟩ := Real.exists_convs_eq_rat (ξ := √(d : ℝ)) (q := q)
    (by rw [hden, hqR]; exact approx d hd x y hy h)
  rw [GenContFract.conv_eq_num_div_den, nums_eq d hd, dens_eq d hd, hqR] at hk
  have hk' : ((pm d (k + 1) : ℚ) / (qm d (k + 1) : ℚ)) = ((x : ℤ) : ℚ) / ((y : ℤ) : ℚ) := by
    have : (((pm d (k + 1) : ℚ) / (qm d (k + 1) : ℚ) : ℚ) : ℝ) = ((((x : ℤ) : ℚ) / ((y : ℤ) : ℚ) : ℚ) : ℝ) := by
      push_cast; exact hk
    exact_mod_cast this
  have hq1 : 0 < qm d (k + 1) := (qm_pos d hd k).2
  have hc1 : Nat.Coprime (pm d (k + 1)).natAbs (qm d (k + 1)).natAbs :=
    Int.isCoprime_iff_gcd_eq_one.mp (coprime_pq d k)
  obtain ⟨e1, e2⟩ := Rat.div_int_inj hq1 hy' hc1 hcop' hk'
  exact ⟨k, e1.symm, e2.symm⟩

lemma pow_real (d : ℕ) (a : Pell.Solution₁ (d : ℤ)) (n : ℕ) :
    (((a ^ n).x : ℤ) : ℝ) + ((a ^ n).y : ℝ) * √(d : ℝ) = ((a.x : ℝ) + (a.y : ℝ) * √(d : ℝ)) ^ n := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [pow_succ a n, Pell.Solution₁.x_mul, Pell.Solution₁.y_mul, pow_succ, ← ih]
    push_cast
    linear_combination (-(((a ^ n).y : ℝ) * (a.y : ℝ))) * sqrt_sq_d d


#print axioms step
#print axioms PQ
#print axioms X
#print axioms Y
#print axioms A
#print axioms PQ_succ
#print axioms PQ_add
#print axioms P_succ
#print axioms Q_succ
#print axioms PQ_zero
#print axioms X_zero
#print axioms A_zero
#print axioms irr
#print axioms lin_indep
#print axioms d_sub_sq_ne
#print axioms d_ge_two
#print axioms s_pos
#print axioms sqrt_gt_one
#print axioms sqrt_sq_d
#print axioms Q_inv
#print axioms QQ
#print axioms QQ_real
#print axioms fract_ne
#print axioms X_succ
#print axioms Y_succ
#print axioms A_eq
#print axioms fract_X
#print axioms X_gt_one
#print axioms A_pos
#print axioms inv_bounds
#print axioms Y_zero
#print axioms Y_bounds
#print axioms bounds
#print axioms stream_gen
#print axioms s_get
#print axioms partDens_get
#print axioms PQ_one
#print axioms per_of_PQ
#print axioms Q_one_of_PQ
#print axioms PQ_of_Q_one
#print axioms back
#print axioms eqPQ
#print axioms desc
#print axioms exists_period
#print axioms P_A_of_Q_one
#print axioms Per
#print axioms per_iff_A
#print axioms per_of_PQ'
#print axioms PQ_of_per
#print axioms per_mul
#print axioms per_sub
#print axioms dvd_of_per
#print axioms pm
#print axioms qm
#print axioms contsAux_eq
#print axioms nums_eq
#print axioms dens_eq
#print axioms det
#print axioms EF
#print axioms norm_eq
#print axioms pm_pos
#print axioms qm_pos
#print axioms coprime_pq
#print axioms approx
#print axioms legendre
#print axioms pow_real

end PellCF

/-- The card's main claim (Steps 3 and 4). Let d be a whole number that is not a perfect
square, and let `ℓ` be the period of the continued fraction of root d: the least block
length after which the partial quotients `a_1, a_2, …` repeat. (Mathlib's
`(GenContFract.of √d).partDens` lists `a_1, a_2, …` from index 0, and its `nums k`,
`dens k` are the card's `p_k`, `q_k`.) Then a pair of positive whole numbers (x, y)
solves `x^2 - d y^2 = 1` exactly when it is the convergent `p_k / q_k` cut off at the end
of j blocks, `k = j ℓ - 1`, with `j ℓ` even. So every solution is a block-end
convergent, and a block end gives `+1` exactly when the number of terms used is even. -/
theorem pell_solutions_are_block_end_convergents (d : ℕ) (hd : ¬ IsSquare d) (ℓ : ℕ)
    (hℓ : IsLeast {n : ℕ | 0 < n ∧ ∀ i : ℕ,
      (GenContFract.of (√(d : ℝ))).partDens.get? (i + n) =
        (GenContFract.of (√(d : ℝ))).partDens.get? i} ℓ)
    (x y : ℕ) :
    (0 < x ∧ 0 < y ∧ (x : ℤ) ^ 2 - d * (y : ℤ) ^ 2 = 1) ↔
      ∃ j : ℕ, 1 ≤ j ∧ Even (j * ℓ) ∧
        (x : ℝ) = (GenContFract.of (√(d : ℝ))).nums (j * ℓ - 1) ∧
        (y : ℝ) = (GenContFract.of (√(d : ℝ))).dens (j * ℓ - 1) := by
  have hℓpos : 0 < ℓ := hℓ.1.1
  constructor
  · rintro ⟨hx, hy, h⟩
    obtain ⟨k, hxk, hyk⟩ := PellCF.legendre d hd x y hy h
    have hN := PellCF.norm_eq d hd k
    rw [← hxk, ← hyk, h] at hN
    have hQpos := (PellCF.bounds d hd k).1
    have hsign : ((-1 : ℤ) ^ (k + 1)) = 1 := by
      rcases neg_one_pow_eq_or ℤ (k + 1) with h1 | h1
      · exact h1
      · rw [h1] at hN; linarith
    rw [hsign, one_mul] at hN
    have hper := PellCF.per_of_PQ' d hd (k + 1) (PellCF.PQ_of_Q_one d hd k hN.symm)
    obtain ⟨c, hc⟩ := PellCF.dvd_of_per d ℓ hℓ (k + 1) hper
    have hc1 : 1 ≤ c := by
      rcases Nat.eq_zero_or_pos c with h0 | h0
      · rw [h0, mul_zero] at hc; omega
      · exact h0
    refine ⟨c, hc1, ?_, ?_, ?_⟩
    · rw [mul_comm, ← hc]; exact (neg_one_pow_eq_one_iff_even (by norm_num)).mp hsign
    · rw [mul_comm, ← hc, Nat.add_sub_cancel, PellCF.nums_eq d hd, ← hxk]; norm_cast
    · rw [mul_comm, ← hc, Nat.add_sub_cancel, PellCF.dens_eq d hd, ← hyk]; norm_cast
  · rintro ⟨j, hj, heven, hx, hy⟩
    obtain ⟨k, hk⟩ : ∃ k, j * ℓ = k + 1 :=
      ⟨j * ℓ - 1, by have := Nat.mul_le_mul hj hℓpos; omega⟩
    rw [hk, Nat.add_sub_cancel] at hx hy
    rw [hk] at heven
    have hper := PellCF.per_mul d ℓ hℓ.1.2 j
    rw [hk] at hper
    have hQ := PellCF.Q_one_of_PQ d hd (k + 1) (PellCF.PQ_of_per d hd (k + 1) hper)
    have hN := PellCF.norm_eq d hd k
    rw [hQ, Even.neg_one_pow heven, mul_one] at hN
    rw [PellCF.nums_eq d hd] at hx
    rw [PellCF.dens_eq d hd] at hy
    have hx' : (x : ℤ) = PellCF.pm d (k + 1) := by exact_mod_cast hx
    have hy' : (y : ℤ) = PellCF.qm d (k + 1) := by exact_mod_cast hy
    have hp := (PellCF.pm_pos d hd k).2
    have hq := (PellCF.qm_pos d hd k).2
    refine ⟨by omega, by omega, ?_⟩
    rw [hx', hy']; exact hN

/-- Step 2: for every whole number d that is not a perfect square, the continued fraction
of root d repeats straight after `a_0`: there is a block length `ℓ ≥ 1` with
`a_(k+ℓ) = a_k` for every `k ≥ 1`, and the block ends in `a_ℓ = 2 a_0`, twice the whole
part of root d. (In Mathlib's indexing `a_k` is `partDens.get? (k - 1)`.) -/
theorem sqrt_continued_fraction_periodic_ends_in_twice_whole_part (d : ℕ)
    (hd : ¬ IsSquare d) :
    ∃ ℓ : ℕ, 0 < ℓ ∧
      (∀ i : ℕ, (GenContFract.of (√(d : ℝ))).partDens.get? (i + ℓ) =
        (GenContFract.of (√(d : ℝ))).partDens.get? i) ∧
      (GenContFract.of (√(d : ℝ))).partDens.get? (ℓ - 1) = some (2 * (Nat.sqrt d : ℝ)) := by
  obtain ⟨L, hL, hper⟩ := PellCF.exists_period d hd
  refine ⟨L, hL, PellCF.per_of_PQ' d hd L hper, ?_⟩
  obtain ⟨k, rfl⟩ : ∃ k, L = k + 1 := ⟨L - 1, by omega⟩
  rw [Nat.add_sub_cancel, PellCF.partDens_get d hd]
  have hQ := PellCF.Q_one_of_PQ d hd (k + 1) hper
  rw [(PellCF.P_A_of_Q_one d hd k hQ).2]
  push_cast; rfl

/-- Step 5: let d be a whole number that is not a perfect square and let `(x_1, y_1)` be
the smallest solution of `x^2 - d y^2 = 1` in positive whole numbers (the fundamental
solution). Then the positive solutions are exactly the pairs (x, y) with
`x + y √d = (x_1 + y_1 √d)^n` for some `n ≥ 1`. -/
theorem pell_solutions_are_powers_of_fundamental (d : ℕ) (hd : ¬ IsSquare d)
    (x₁ y₁ : ℕ) (hx₁ : 0 < x₁) (hy₁ : 0 < y₁)
    (hsol : (x₁ : ℤ) ^ 2 - d * (y₁ : ℤ) ^ 2 = 1)
    (hmin : ∀ x y : ℕ, 0 < x → 0 < y → (x : ℤ) ^ 2 - d * (y : ℤ) ^ 2 = 1 → x₁ ≤ x)
    (x y : ℕ) :
    (0 < x ∧ 0 < y ∧ (x : ℤ) ^ 2 - d * (y : ℤ) ^ 2 = 1) ↔
      ∃ n : ℕ, 1 ≤ n ∧ (x : ℝ) + y * √(d : ℝ) = ((x₁ : ℝ) + y₁ * √(d : ℝ)) ^ n := by
  have hd2 : (2 : ℤ) ≤ d := by exact_mod_cast PellCF.d_ge_two d hd
  set a₁ : Pell.Solution₁ (d : ℤ) := Pell.Solution₁.mk x₁ y₁ hsol with ha₁
  have hax : a₁.x = x₁ := Pell.Solution₁.x_mk _ _ _
  have hay : a₁.y = y₁ := Pell.Solution₁.y_mk _ _ _
  have hfund : Pell.IsFundamental a₁ := by
    refine ⟨?_, ?_, ?_⟩
    · rw [hax]
      have hy : (1 : ℤ) ≤ y₁ := by exact_mod_cast hy₁
      have hx : (0 : ℤ) ≤ x₁ := by positivity
      nlinarith
    · rw [hay]; exact_mod_cast hy₁
    · intro b hb
      have hby := Pell.Solution₁.y_ne_zero_of_one_lt_x hb
      have hm := hmin b.x.natAbs b.y.natAbs (Int.natAbs_pos.mpr (by omega))
        (Int.natAbs_pos.mpr hby) (by
          rw [Int.natCast_natAbs, Int.natCast_natAbs, sq_abs, sq_abs]; exact b.prop)
      rw [hax]
      have e : (b.x.natAbs : ℤ) = b.x := Int.natAbs_of_nonneg (by omega)
      have : (x₁ : ℤ) ≤ (b.x.natAbs : ℤ) := by exact_mod_cast hm
      omega
  have hax0 : 0 < a₁.x := by rw [hax]; exact_mod_cast hx₁
  have hay0 : 0 < a₁.y := by rw [hay]; exact_mod_cast hy₁
  constructor
  · rintro ⟨hx, hy, h⟩
    set a : Pell.Solution₁ (d : ℤ) := Pell.Solution₁.mk x y h with ha
    have hax' : a.x = x := Pell.Solution₁.x_mk _ _ _
    have hay' : a.y = y := Pell.Solution₁.y_mk _ _ _
    obtain ⟨n, hn⟩ := hfund.eq_pow_of_nonneg (a := a) (by rw [hax']; exact_mod_cast hx)
      (by rw [hay']; positivity)
    have hn1 : 1 ≤ n := by
      rcases Nat.eq_zero_or_pos n with h0 | h0
      · rw [h0, pow_zero] at hn
        have : a.y = 0 := by rw [hn]; rfl
        rw [hay'] at this; omega
      · exact h0
    refine ⟨n, hn1, ?_⟩
    have hp := PellCF.pow_real d a₁ n
    rw [← hn, hax', hay', hax, hay] at hp
    push_cast at hp
    exact hp
  · rintro ⟨n, hn1, heq⟩
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
    have hp := PellCF.pow_real d a₁ (m + 1)
    rw [hax, hay] at hp
    push_cast at hp
    rw [← heq] at hp
    obtain ⟨e1, e2⟩ := PellCF.lin_indep d hd ((a₁ ^ (m + 1)).x - x) ((a₁ ^ (m + 1)).y - y)
      (by push_cast; linarith)
    have hbx := Pell.Solution₁.x_pow_pos hax0 (m + 1)
    have hby := Pell.Solution₁.y_pow_succ_pos hax0 hay0 m
    have hprop := (a₁ ^ (m + 1)).prop
    have ex : (a₁ ^ (m + 1)).x = x := by linarith
    have ey : (a₁ ^ (m + 1)).y = y := by linarith
    have hby' : 0 < (a₁ ^ (m + 1)).y := hby
    rw [ex] at hbx
    rw [ey] at hby'
    rw [ex, ey] at hprop
    exact ⟨by exact_mod_cast hbx, by exact_mod_cast hby', hprop⟩

-- The card's worked whole-number examples.

-- Fermat's challenge: the smallest solution for 61 has a ten-digit x.
example : (1766319049 : ℤ) ^ 2 - 61 * 226153980 ^ 2 = 1 := by norm_num
-- Small neighbours: 60, 62, 13.
example : (31 : ℤ) ^ 2 - 60 * 4 ^ 2 = 1 := by norm_num
example : (63 : ℤ) ^ 2 - 62 * 8 ^ 2 = 1 := by norm_num
example : (649 : ℤ) ^ 2 - 13 * 180 ^ 2 = 1 := by norm_num
-- The whole part of root 61 is 7, so the block ends in 14.
example : Nat.sqrt 61 = 7 := (Nat.eq_sqrt.2 (by norm_num)).symm
-- The first update steps for 61: c_1 = 12, c_2 = 3, c_3 = 4.
example : (61 - 7 ^ 2) / 1 = 12 ∧ (61 - 5 ^ 2) / 12 = 3 ∧ (61 - 7 ^ 2) / 3 = 4 ∧
    14 / 12 = 1 ∧ 12 / 3 = 4 ∧ 14 / 4 = 3 := by decide
-- The table column p_k^2 - 61 q_k^2 for k = 0 .. 11.
example : (7 : ℤ) ^ 2 - 61 * 1 ^ 2 = -12 ∧ (8 : ℤ) ^ 2 - 61 * 1 ^ 2 = 3 ∧
    (39 : ℤ) ^ 2 - 61 * 5 ^ 2 = -4 ∧ (125 : ℤ) ^ 2 - 61 * 16 ^ 2 = 9 ∧
    (164 : ℤ) ^ 2 - 61 * 21 ^ 2 = -5 ∧ (453 : ℤ) ^ 2 - 61 * 58 ^ 2 = 5 ∧
    (1070 : ℤ) ^ 2 - 61 * 137 ^ 2 = -9 ∧ (1523 : ℤ) ^ 2 - 61 * 195 ^ 2 = 4 ∧
    (5639 : ℤ) ^ 2 - 61 * 722 ^ 2 = -3 ∧ (24079 : ℤ) ^ 2 - 61 * 3083 ^ 2 = 12 ∧
    (29718 : ℤ) ^ 2 - 61 * 3805 ^ 2 = -1 ∧ (440131 : ℤ) ^ 2 - 61 * 56353 ^ 2 = 12 := by
  norm_num
-- The convergent recurrence p_k = a_k p_(k-1) + p_(k-2) along 7; 1, 4, 3, 1, 2, 2, 1, 3, 4, 1, 14.
example : 1 * 7 + 1 = 8 ∧ 4 * 8 + 7 = 39 ∧ 3 * 39 + 8 = 125 ∧ 1 * 125 + 39 = 164 ∧
    2 * 164 + 125 = 453 ∧ 2 * 453 + 164 = 1070 ∧ 1 * 1070 + 453 = 1523 ∧
    3 * 1523 + 1070 = 5639 ∧ 4 * 5639 + 1523 = 24079 ∧ 1 * 24079 + 5639 = 29718 ∧
    14 * 29718 + 24079 = 440131 := by norm_num
example : 1 * 1 + 0 = 1 ∧ 4 * 1 + 1 = 5 ∧ 3 * 5 + 1 = 16 ∧ 1 * 16 + 5 = 21 ∧
    2 * 21 + 16 = 58 ∧ 2 * 58 + 21 = 137 ∧ 1 * 137 + 58 = 195 ∧ 3 * 195 + 137 = 722 ∧
    4 * 722 + 195 = 3083 ∧ 1 * 3083 + 722 = 3805 ∧ 14 * 3805 + 3083 = 56353 := by norm_num
-- Squaring the one-block answer gives the two-block answer.
example : (29718 : ℕ) ^ 2 + 61 * 3805 ^ 2 = 1766319049 ∧
    2 * 29718 * 3805 = 226153980 := by norm_num
-- The fundamental unit (39 + 5 root 61)/2 has norm -1; its cube is 29718 + 3805 root 61:
-- (39 + 5√61)^3 = 8 (29718 + 3805 √61).
example : (39 : ℤ) ^ 2 - 61 * 5 ^ 2 = -4 ∧
    (39 : ℤ) ^ 3 + 3 * 39 * 5 ^ 2 * 61 = 8 * 29718 ∧
    3 * (39 : ℤ) ^ 2 * 5 + 5 ^ 3 * 61 = 8 * 3805 := by norm_num
-- The second solution, from convergent k = 43, is the square of the first.
example : (1766319049 : ℕ) ^ 2 + 61 * 226153980 ^ 2 = 6239765965720528801 ∧
    2 * 1766319049 * 226153980 = 798920165762330040 := by norm_num

#print axioms pell_solutions_are_block_end_convergents
#print axioms sqrt_continued_fraction_periodic_ends_in_twice_whole_part
#print axioms pell_solutions_are_powers_of_fundamental
