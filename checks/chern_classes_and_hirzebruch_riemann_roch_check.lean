-- Chern classes and Hirzebruch-Riemann-Roch: on projective n-space the Hirzebruch-Riemann-Roch number of O(d) is the binomial coefficient (d + n choose n), and on the plane it equals the Cech count of monomials.
import Mathlib.RingTheory.PowerSeries.Exp
import Mathlib.RingTheory.PowerSeries.Inverse
import Mathlib.RingTheory.PowerSeries.Derivative
import Mathlib.RingTheory.Binomial
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum

open PowerSeries

/-- The Todd series of one Chern root, `H / (1 - e^(-H))`: the inverse of `(1 - e^(-H)) / H`,
whose coefficient of `H^k` is `(-1)^k / (k + 1)!`. -/
noncomputable def toddSeries : PowerSeries ℚ :=
  (PowerSeries.mk fun k : ℕ => ((-1 : ℚ) ^ k / ((k + 1).factorial : ℚ)))⁻¹

lemma todd_denom_mul_toddSeries : (PowerSeries.mk fun k : ℕ => ((-1 : ℚ) ^ k / ((k + 1).factorial : ℚ))) * toddSeries = 1 := by
  apply PowerSeries.mul_inv_cancel
  simp

#print axioms todd_denom_mul_toddSeries

lemma one_sub_exp_neg : 1 - rescale (-1 : ℚ) (exp ℚ) = X * (PowerSeries.mk fun k : ℕ => ((-1 : ℚ) ^ k / ((k + 1).factorial : ℚ))) := by
  ext k
  cases k with
  | zero => rw [map_sub, coeff_zero_X_mul, coeff_rescale, coeff_exp]; simp
  | succ k =>
    rw [coeff_succ_X_mul]
    simp [coeff_exp, pow_succ]
    ring

#print axioms one_sub_exp_neg

lemma exp_neg_eq : rescale (-1 : ℚ) (exp ℚ) = (PowerSeries.mk fun k : ℕ => ((-1 : ℚ) ^ k / ((k + 1).factorial : ℚ))) + X * d⁄dX (PowerSeries.mk fun k : ℕ => ((-1 : ℚ) ^ k / ((k + 1).factorial : ℚ))) := by
  ext k
  cases k with
  | zero => simp
  | succ k =>
    rw [map_add, coeff_succ_X_mul, coeff_derivative]
    simp only [coeff_mk, coeff_rescale, coeff_exp, Algebra.algebraMap_self, RingHom.id_apply]
    rw [Nat.factorial_succ (k + 1)]
    push_cast
    field_simp
    ring

#print axioms exp_neg_eq

lemma deriv_toddSeries :
    d⁄dX (PowerSeries.mk fun k : ℕ => ((-1 : ℚ) ^ k / ((k + 1).factorial : ℚ))) * toddSeries ^ 2 + d⁄dX toddSeries = 0 := by
  have h1 : d⁄dX ((PowerSeries.mk fun k : ℕ => ((-1 : ℚ) ^ k / ((k + 1).factorial : ℚ))) * toddSeries) = 0 := by
    rw [todd_denom_mul_toddSeries]; exact derivative_one
  rw [Derivation.leibniz, smul_eq_mul, smul_eq_mul] at h1
  linear_combination toddSeries * h1 - d⁄dX toddSeries * todd_denom_mul_toddSeries

#print axioms deriv_toddSeries

lemma hrr_base (n : ℕ) :
    coeff (n + 1) (rescale (-1 : ℚ) (exp ℚ) * toddSeries ^ (n + 2)) = 0 := by
  have key : rescale (-1 : ℚ) (exp ℚ) * toddSeries ^ (n + 2) =
      toddSeries ^ (n + 1) - X * (d⁄dX toddSeries * toddSeries ^ n) := by
    rw [exp_neg_eq]
    linear_combination toddSeries ^ (n + 1) * todd_denom_mul_toddSeries +
      X * toddSeries ^ n * deriv_toddSeries
  have hd := coeff_derivative (toddSeries ^ (n + 1)) n
  rw [derivative_pow, Nat.add_sub_cancel, ← map_natCast (C (R := ℚ)), mul_assoc,
    coeff_C_mul] at hd
  rw [key, map_sub, coeff_succ_X_mul, mul_comm (d⁄dX toddSeries)]
  have hn : ((n + 1 : ℕ) : ℚ) ≠ 0 := by positivity
  push_cast at hd hn
  have := mul_left_cancel₀ hn (hd.trans (mul_comm _ _))
  rw [this, sub_self]

#print axioms hrr_base

lemma hrr_step (n : ℕ) (d : ℤ) :
    coeff (n + 1) (rescale (d : ℚ) (exp ℚ) * toddSeries ^ (n + 1 + 1)) =
      coeff (n + 1) (rescale ((d - 1 : ℤ) : ℚ) (exp ℚ) * toddSeries ^ (n + 1 + 1)) +
      coeff n (rescale (d : ℚ) (exp ℚ) * toddSeries ^ (n + 1)) := by
  have hE : rescale ((d - 1 : ℤ) : ℚ) (exp ℚ) =
      rescale (d : ℚ) (exp ℚ) * rescale (-1 : ℚ) (exp ℚ) := by
    rw [exp_mul_exp_eq_exp_add]; push_cast; ring_nf
  have key : rescale (d : ℚ) (exp ℚ) * toddSeries ^ (n + 1 + 1) =
      rescale ((d - 1 : ℤ) : ℚ) (exp ℚ) * toddSeries ^ (n + 1 + 1) +
      X * (rescale (d : ℚ) (exp ℚ) * toddSeries ^ (n + 1)) := by
    rw [hE]
    linear_combination (rescale (d : ℚ) (exp ℚ) * toddSeries ^ (n + 2)) * one_sub_exp_neg +
      X * rescale (d : ℚ) (exp ℚ) * toddSeries ^ (n + 1) * todd_denom_mul_toddSeries
  rw [key, map_add, coeff_succ_X_mul]

#print axioms hrr_step

/-- Hirzebruch-Riemann-Roch on projective n-space: the Euler sequence gives the tangent bundle
plus a trivial bundle n + 1 Chern roots all equal to H, so `ch(O(d)) td(P^n) = e^(dH) (H / (1 - e^(-H)))^(n + 1)`.
Its point part, the coefficient of `H^n`, is the binomial coefficient `(d + n choose n)` for every
integer d, negative ones included: the number of degree-d forms when d is at least 0. -/
theorem hrr_projective_space_line_bundle (n : ℕ) (d : ℤ) :
    coeff n (rescale (d : ℚ) (exp ℚ) * toddSeries ^ (n + 1)) = ((Ring.choose (d + n) n : ℤ) : ℚ) := by
  induction n generalizing d with
  | zero =>
    have h0 : constantCoeff toddSeries = 1 := by
      rw [toddSeries, constantCoeff_inv]; simp
    rw [zero_add, pow_one, coeff_zero_eq_constantCoeff_apply, map_mul, h0,
      ← coeff_zero_eq_constantCoeff_apply, coeff_rescale, coeff_exp]
    simp
  | succ n ih =>
    induction d using Int.inductionOn' (b := -1) with
    | zero =>
      have := hrr_base n
      rw [show ((n + 1 : ℕ) : ℤ) = (n : ℤ) + 1 by push_cast; ring,
        show (-1 : ℤ) + ((n : ℤ) + 1) = ((n : ℕ) : ℤ) by ring, Ring.choose_natCast,
        Nat.choose_eq_zero_of_lt (Nat.lt_succ_self n)]
      simpa using this
    | succ k _ hk =>
      rw [hrr_step, ih, show ((k + 1 - 1 : ℤ)) = k by ring, hk]
      rw [show (k + 1 : ℤ) + ((n + 1 : ℕ) : ℤ) = (k + n + 1) + 1 by push_cast; ring,
        show (k : ℤ) + ((n + 1 : ℕ) : ℤ) = (k + n) + 1 by push_cast; ring,
        show (k + 1 : ℤ) + (n : ℤ) = (k + n) + 1 by ring, Ring.choose_succ_succ (k + n + 1)]
      push_cast; ring
    | pred k _ hk =>
      have h := hrr_step n k
      rw [hk, ih] at h
      rw [show (k : ℤ) + ((n + 1 : ℕ) : ℤ) = (k + n) + 1 by push_cast; ring,
        Ring.choose_succ_succ (k + n)] at h
      rw [show (k - 1 : ℤ) + ((n + 1 : ℕ) : ℤ) = k + n by push_cast; ring]
      push_cast at h ⊢
      linarith

lemma toddSeries_coeff_low :
    coeff 0 toddSeries = 1 ∧ coeff 1 toddSeries = 1 / 2 ∧ coeff 2 toddSeries = 1 / 12 := by
  have h0 := congrArg (coeff 0) todd_denom_mul_toddSeries
  have h1 := congrArg (coeff 1) todd_denom_mul_toddSeries
  have h2 := congrArg (coeff 2) todd_denom_mul_toddSeries
  simp only [coeff_mul, Finset.Nat.sum_antidiagonal_succ, Finset.Nat.antidiagonal_zero, Finset.sum_singleton,
    coeff_mk, coeff_one] at h0 h1 h2
  norm_num [Nat.factorial] at h0 h1 h2
  rw [h0] at h1 h2
  rw [← coeff_zero_eq_constantCoeff_apply] at h0
  refine ⟨h0, ?_, ?_⟩
  · linarith
  · linarith

#print axioms toddSeries_coeff_low

/-- The Todd class of the plane: cubing the one-root series and cutting off above `H^2` gives
`td(P^2) = 1 + (3/2) H + H^2`, the same as `1 + c_1/2 + (c_1^2 + c_2)/12` with `c_1 = 3`, `c_2 = 3`. -/
theorem todd_class_projective_plane :
    coeff 0 (toddSeries ^ 3) = 1 ∧ coeff 1 (toddSeries ^ 3) = 3 / 2 ∧ coeff 2 (toddSeries ^ 3) = 1 := by
  obtain ⟨h0, h1, h2⟩ := toddSeries_coeff_low
  simp only [pow_succ, pow_zero, one_mul, coeff_mul, Finset.Nat.sum_antidiagonal_succ,
    Finset.Nat.antidiagonal_zero, Finset.sum_singleton, h0, h1, h2]
  rw [coeff_zero_eq_constantCoeff_apply] at h0
  norm_num

lemma sum_range_sub_eq_choose (m : ℕ) :
    ∑ a ∈ Finset.range (m + 1), (m + 1 - a) = Nat.choose (m + 2) 2 := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ']
    simp only [Nat.add_sub_add_right] at ih ⊢
    have h : Nat.choose (m + 1 + 2) 2 = Nat.choose (m + 2) 1 + Nat.choose (m + 2) 2 :=
      Nat.choose_succ_succ (m + 2) 1
    rw [Nat.choose_one_right] at h
    rw [ih, h]
    omega

#print axioms sum_range_sub_eq_choose

lemma ncard_nonneg_triples (m : ℕ) :
    {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = m ∧ 0 ≤ p.1 ∧ 0 ≤ p.2.1 ∧ 0 ≤ p.2.2}.ncard =
      Nat.choose (m + 2) 2 := by
  let f : (Σ _ : ℕ, ℕ) → ℤ × ℤ × ℤ := fun x => ((x.1 : ℤ), (x.2 : ℤ), (m : ℤ) - x.1 - x.2)
  have hS : {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = m ∧ 0 ≤ p.1 ∧ 0 ≤ p.2.1 ∧ 0 ≤ p.2.2} =
      ↑(((Finset.range (m + 1)).sigma fun a => Finset.range (m + 1 - a)).image f) := by
    ext ⟨x, y, z⟩
    simp only [Set.mem_ofPred_eq, Finset.coe_image, Set.mem_image, Finset.mem_coe,
      Finset.mem_sigma, Finset.mem_range, f, Sigma.exists, Prod.mk.injEq]
    constructor
    · rintro ⟨h, hx, hy, hz⟩
      exact ⟨x.toNat, y.toNat, ⟨by omega, by omega⟩, by omega, by omega, by omega⟩
    · rintro ⟨a, b, ⟨ha, hb⟩, rfl, rfl, rfl⟩
      omega
  rw [hS, Set.ncard_coe_finset, Finset.card_image_of_injective, Finset.card_sigma]
  · simp only [Finset.card_range]
    exact sum_range_sub_eq_choose m
  · rintro ⟨a, b⟩ ⟨a', b'⟩ h
    simp only [f, Prod.mk.injEq, Nat.cast_inj] at h
    obtain ⟨rfl, rfl, -⟩ := h
    rfl

#print axioms ncard_nonneg_triples

lemma ncard_neg_triples (m : ℕ) :
    {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = -3 - m ∧ p.1 ≤ -1 ∧ p.2.1 ≤ -1 ∧ p.2.2 ≤ -1}.ncard =
      Nat.choose (m + 2) 2 := by
  let g : ℤ × ℤ × ℤ → ℤ × ℤ × ℤ := fun p => (-1 - p.1, -1 - p.2.1, -1 - p.2.2)
  have hg : g.Injective := by
    rintro ⟨a, b, c⟩ ⟨a', b', c'⟩ h
    simp only [g, Prod.mk.injEq] at h
    obtain ⟨h1, h2, h3⟩ := h
    simp only [Prod.mk.injEq]
    omega
  have hS : {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = -3 - m ∧ p.1 ≤ -1 ∧ p.2.1 ≤ -1 ∧ p.2.2 ≤ -1} =
      g '' {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = m ∧ 0 ≤ p.1 ∧ 0 ≤ p.2.1 ∧ 0 ≤ p.2.2} := by
    ext ⟨x, y, z⟩
    simp only [Set.mem_ofPred_eq, Set.mem_image, Prod.exists, g, Prod.mk.injEq]
    constructor
    · rintro ⟨h, hx, hy, hz⟩
      exact ⟨-1 - x, -1 - y, -1 - z, by omega, by omega, by omega, by omega⟩
    · rintro ⟨a, b, c, ⟨h, ha, hb, hc⟩, rfl, rfl, rfl⟩
      omega
  rw [hS, Set.ncard_image_of_injective _ hg, ncard_nonneg_triples]

#print axioms ncard_neg_triples

/-- On the plane the Hirzebruch-Riemann-Roch number of O(d) equals the Cech count, for every integer d:
the monomials `x^a y^b z^c` of degree d with all powers at least 0 (h^0) plus the Laurent monomials
of degree d with all powers at most -1 (h^2). -/
theorem hrr_matches_cech_count_on_plane (d : ℤ) :
    (({p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = d ∧ 0 ≤ p.1 ∧ 0 ≤ p.2.1 ∧ 0 ≤ p.2.2}.ncard +
      {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = d ∧ p.1 ≤ -1 ∧ p.2.1 ≤ -1 ∧ p.2.2 ≤ -1}.ncard : ℕ) : ℚ) =
      coeff 2 (rescale (d : ℚ) (exp ℚ) * toddSeries ^ 3) := by
  rw [show toddSeries ^ 3 = toddSeries ^ (2 + 1) from rfl, hrr_projective_space_line_bundle]
  rcases le_or_gt 0 d with hd | hd
  · obtain ⟨m, rfl⟩ : ∃ m : ℕ, d = m := ⟨d.toNat, by omega⟩
    have hE : {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = (m : ℤ) ∧ p.1 ≤ -1 ∧ p.2.1 ≤ -1 ∧ p.2.2 ≤ -1}
        = ∅ := by
      ext p; simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]; omega
    rw [hE, Set.ncard_empty, ncard_nonneg_triples, add_zero,
      show (m : ℤ) + ((2 : ℕ) : ℤ) = ((m + 2 : ℕ) : ℤ) by push_cast; ring, Ring.choose_natCast]
    push_cast; rfl
  · have hE : {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = d ∧ 0 ≤ p.1 ∧ 0 ≤ p.2.1 ∧ 0 ≤ p.2.2}
        = ∅ := by
      ext p; simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]; omega
    rw [hE, Set.ncard_empty, zero_add]
    rcases le_or_gt d (-3) with hd3 | hd3
    · obtain ⟨m, rfl⟩ : ∃ m : ℕ, d = -3 - m := ⟨(-3 - d).toNat, by omega⟩
      rw [ncard_neg_triples, show (-3 - (m : ℤ)) + ((2 : ℕ) : ℤ) = -((m + 1 : ℕ) : ℤ) by
        push_cast; ring, Ring.choose_neg,
        show ((m + 1 : ℕ) : ℤ) + ((2 : ℕ) : ℤ) - 1 = ((m + 2 : ℕ) : ℤ) by push_cast; ring,
        Ring.choose_natCast]
      simp [Int.negOnePow_even 2 even_two]
    · have hE2 : {p : ℤ × ℤ × ℤ | p.1 + p.2.1 + p.2.2 = d ∧ p.1 ≤ -1 ∧ p.2.1 ≤ -1 ∧ p.2.2 ≤ -1}
          = ∅ := by
        ext p; simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]; omega
      rw [hE2, Set.ncard_empty]
      obtain ⟨k, hk, rfl⟩ : ∃ k : ℕ, k < 2 ∧ d = (k : ℤ) - 2 := ⟨(d + 2).toNat, by omega, by omega⟩
      rw [show (k : ℤ) - 2 + ((2 : ℕ) : ℤ) = (k : ℤ) by push_cast; ring, Ring.choose_natCast,
        Nat.choose_eq_zero_of_lt hk]
      simp

-- chi(O(3)) on the plane: 9/2 + 3 * 3/2 + 1 = 10 plane cubics, and (d + 1)(d + 2)/2 at d = 3
example : (9 : ℚ) / 2 + 3 * (3 / 2) + 1 = 10 := by norm_num
example : ((3 : ℤ) + 1) * (3 + 2) / 2 = 10 := by norm_num
example : Nat.choose (3 + 2) 2 = 10 := by decide
-- at d = -4 the formula gives 3, all of it h^2
example : ((-4 : ℤ) + 1) * (-4 + 2) / 2 = 3 := by norm_num
-- c(T) = (1 + H)^3 = 1 + 3H + 3H^2, so c_1 = 3 and the Euler number c_2 = 3
example : Nat.choose 3 1 = 3 ∧ Nat.choose 3 2 = 3 := by decide
-- the Todd class from Chern classes: c_1/2 = 3/2 and (c_1^2 + c_2)/12 = (9 + 3)/12 = 1
example : (3 : ℚ) / 2 = 3 / 2 ∧ ((3 : ℚ) ^ 2 + 3) / 12 = 1 := by norm_num
-- c_2 from ch(T) = 2 + 3H + (3/2)H^2: c_2 = (9 - 3)/2 = 3
example : ((3 : ℚ) ^ 2 - 2 * (3 / 2)) / 2 = 3 := by norm_num
-- chi(T) = 2 + 9/2 + 3/2 = 8, and by the Euler sequence 3 * 3 - 1 = 8
example : (2 : ℚ) * 1 + 3 * (3 / 2) + 3 / 2 = 8 := by norm_num
example : 3 * 3 - 1 = 8 := by decide
-- Noether on the plane: K^2 + e = 9 + 3 = 12
example : (9 : ℤ) + 3 = 12 := by norm_num
-- the cubic surface: c(T_S) = (1 + h)^4 / (1 + 3h) = 1 + h + 3h^2, with h^2 = 3
example : (4 : ℤ) - 3 = 1 ∧ (6 : ℤ) - 4 * 3 + 9 = 3 := by norm_num
example : (1 : ℤ) ^ 2 * 3 = 3 ∧ (3 : ℤ) * 3 = 9 := by norm_num
-- by blow-ups: K^2 = 9 - 6 = 3 and e = 3 + 6 = 9
example : (9 : ℤ) - 6 = 3 ∧ (3 : ℤ) + 6 = 9 := by norm_num
-- chi(O_S) = (3 + 9)/12 = 1 and chi(-K) = 1 + K^2 = 4 = 10 - 6 cubics through 6 points
example : ((3 : ℚ) + 9) / 12 = 1 ∧ (1 : ℤ) + 3 = 4 ∧ (10 : ℤ) - 6 = 4 := by norm_num
-- what breaks: no Todd class gives 9/2; td cut to 1 + c_1/2 gives 9
example : (9 : ℚ) / 2 + 3 * (3 / 2) = 9 := by norm_num
-- the open plane: polynomials of degree at most 3, 6, 9 number 10, 28, 55
example : Nat.choose (3 + 2) 2 = 10 ∧ Nat.choose (6 + 2) 2 = 28 ∧ Nat.choose (9 + 2) 2 = 55 := by decide

#print axioms hrr_projective_space_line_bundle
#print axioms todd_class_projective_plane
#print axioms hrr_matches_cech_count_on_plane
