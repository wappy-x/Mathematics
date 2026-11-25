-- Cech cohomology: the monomials that survive in the Cech complex of O(d) on projective space are counted by binomial coefficients, and they give a plane curve of degree e its genus (e - 1)(e - 2)/2.
import Mathlib.Data.Set.Card
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Int.Interval
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Sym.Card
import Mathlib.Data.Finsupp.Multiset

open Finset

/-- Stars and bars over the integers: the nonnegative integer vectors of length `k` with
sum `m` are as many as the multisets of size `m` drawn from `k` letters. -/
theorem nonneg_vector_count (k m : ℕ) :
    Set.ncard {a : Fin k → ℤ | (∀ j, 0 ≤ a j) ∧ ∑ j, a j = (m : ℤ)} =
      Fintype.card (Sym (Fin k) m) := by
  rw [← Nat.card_coe_set_eq, ← Nat.card_eq_fintype_card]
  refine Nat.card_congr ((?_ : _ ≃ {P : Fin k → ℕ // ∑ i, P i = m}).trans
    (Sym.equivNatSumOfFintype (Fin k) m).symm)
  refine
    { toFun := fun a => ⟨fun j => (a.1 j).toNat, ?_⟩
      invFun := fun P => ⟨fun j => (P.1 j : ℤ), ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · obtain ⟨a, ha0, hsum⟩ := a
    have : ((∑ j, (a j).toNat : ℕ) : ℤ) = (m : ℤ) := by
      rw [Nat.cast_sum, ← hsum]
      exact Finset.sum_congr rfl fun j _ => Int.toNat_of_nonneg (ha0 j)
    exact_mod_cast this
  · refine ⟨fun j => Int.natCast_nonneg _, ?_⟩
    rw [← Nat.cast_sum, P.2]
  · rintro ⟨a, ha0, hsum⟩
    ext j
    simp [Int.toNat_of_nonneg (ha0 j)]
  · rintro ⟨P, hP⟩
    ext j
    simp

/-- The same count as a binomial coefficient, in length `n + 1`. -/
theorem nonneg_vector_count_choose (n d : ℕ) :
    Set.ncard {a : Fin (n + 1) → ℤ | (∀ j, 0 ≤ a j) ∧ ∑ j, a j = (d : ℤ)} =
      Nat.choose (d + n) n := by
  rw [nonneg_vector_count, Sym.card_sym_eq_choose, Fintype.card_fin,
    show n + 1 + d - 1 = d + n by omega, Nat.choose_symm_add]

/-- The top-class count for every degree `d`: the integer vectors of length `n + 1` with all
entries at most `-1` and sum `d` number `(-d - 1).toNat choose n`; both sides are zero when
`d > -n - 1` and `n ≥ 1`. -/
theorem negative_vector_count (n : ℕ) (d : ℤ) (hn : 1 ≤ n ∨ d ≤ -(n : ℤ) - 1) :
    Set.ncard {a : Fin (n + 1) → ℤ | (∀ j, a j ≤ -1) ∧ ∑ j, a j = d} =
      Nat.choose (-d - 1).toNat n := by
  by_cases hd : d ≤ -(n : ℤ) - 1
  · set m : ℕ := (-d - n - 1).toNat with hm
    have hm' : (m : ℤ) = -d - n - 1 := Int.toNat_of_nonneg (by omega)
    have key : Set.ncard {a : Fin (n + 1) → ℤ | (∀ j, a j ≤ -1) ∧ ∑ j, a j = d} =
        Set.ncard {a : Fin (n + 1) → ℤ | (∀ j, 0 ≤ a j) ∧ ∑ j, a j = (m : ℤ)} := by
      refine Set.ncard_congr (fun a _ => fun j => -1 - a j) ?_ ?_ ?_
      · rintro a ⟨ha, hsum⟩
        refine ⟨fun j => show 0 ≤ -1 - a j by have := ha j; omega, ?_⟩
        rw [Finset.sum_sub_distrib, hsum, hm']
        simp
        omega
      · intro a b _ _ hab
        funext j
        have : -1 - a j = -1 - b j := congrFun hab j
        omega
      · rintro b ⟨hb, hsum⟩
        refine ⟨fun j => -1 - b j, ⟨fun j => show -1 - b j ≤ -1 by have := hb j; omega, ?_⟩, ?_⟩
        · rw [Finset.sum_sub_distrib, hsum, hm']
          simp
          omega
        · funext j
          show -1 - (-1 - b j) = b j
          omega
    rw [key, nonneg_vector_count_choose]
    congr 1
    omega
  · push Not at hd
    have hempty : {a : Fin (n + 1) → ℤ | (∀ j, a j ≤ -1) ∧ ∑ j, a j = d} = ∅ := by
      ext a
      simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_and]
      intro ha hsum
      have : ∑ j, a j ≤ ∑ _j : Fin (n + 1), (-1 : ℤ) := Finset.sum_le_sum fun j _ => ha j
      simp at this
      omega
    rw [hempty, Set.ncard_empty, Nat.choose_eq_zero_of_lt]
    omega

#print axioms nonneg_vector_count
#print axioms nonneg_vector_count_choose
#print axioms negative_vector_count

/-- The top classes of `O(d)` on projective n-space: the Laurent monomials
`x_0^{a_0} ⋯ x_n^{a_n}` of degree `d` with every exponent at most `-1` (one class each in
`H^n(P^n, O(d))`) number exactly `(-d - 1) choose n`, whenever `d ≤ -n - 1`. -/
theorem top_class_count_eq_choose (n : ℕ) (d : ℤ) (hd : d ≤ -(n : ℤ) - 1) :
    Set.ncard {a : Fin (n + 1) → ℤ | (∀ j, a j ≤ -1) ∧ ∑ j, a j = d} =
      Nat.choose (-d - 1).toNat n := by
  exact negative_vector_count n d (Or.inr hd)

/-- The global sections of `O(d)` on projective n-space: the monomials
`x_0^{a_0} ⋯ x_n^{a_n}` of degree `d ≥ 0` with every exponent at least `0`
(one each in `H^0(P^n, O(d))`) number exactly `(d + n) choose n`. -/
theorem global_section_count_eq_choose (n d : ℕ) :
    Set.ncard {a : Fin (n + 1) → ℤ | (∀ j, 0 ≤ a j) ∧ ∑ j, a j = (d : ℤ)} =
      Nat.choose (d + n) n := by
  exact nonneg_vector_count_choose n d

/-- The genus of a plane curve of degree `e ≥ 1`: the top classes of `O(-e)` on the plane,
the monomials `x^a y^b z^c` with `a, b, c ≤ -1` and `a + b + c = -e`, number exactly
`(e - 1)(e - 2)/2`. -/
theorem plane_curve_genus_from_top_classes (e : ℕ) (he : 1 ≤ e) :
    Set.ncard {a : Fin 3 → ℤ | (∀ j, a j ≤ -1) ∧ ∑ j, a j = -(e : ℤ)} =
      (e - 1) * (e - 2) / 2 := by
  rw [negative_vector_count 2 (-(e : ℤ)) (Or.inl (by omega)), Nat.choose_two_right,
    show (-(-(e : ℤ)) - 1).toNat = e - 1 by omega, Nat.sub_sub]

-- The card's worked numbers, by enumerating the exponents (every surviving exponent of a
-- top class lies between d and -1, and of a global section between 0 and d).

-- O(-2) on the line: one class, 1/(xy).
example : ((Fintype.piFinset fun _ : Fin 2 => Finset.Icc (-2 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -2)).card = 1 := by decide
-- O(-3) on the line: two classes, 1/(x^2 y) and 1/(x y^2).
example : ((Fintype.piFinset fun _ : Fin 2 => Finset.Icc (-3 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -3)).card = 2 := by decide
-- O(-4) on the line: three classes, matching h^0(O(2)) = 3 on the line (Serre duality).
example : ((Fintype.piFinset fun _ : Fin 2 => Finset.Icc (-4 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -4)).card = 3 := by decide
example : ((Fintype.piFinset fun _ : Fin 2 => Finset.Icc (0 : ℤ) 2).filter
    (fun a => ∑ j, a j = 2)).card = 3 := by decide
-- O(3) on the line: four global sections, x^3, x^2 y, x y^2, y^3.
example : ((Fintype.piFinset fun _ : Fin 2 => Finset.Icc (0 : ℤ) 3).filter
    (fun a => ∑ j, a j = 3)).card = 4 := by decide
-- O(-3) on the plane: one top class, 1/(xyz).
example : ((Fintype.piFinset fun _ : Fin 3 => Finset.Icc (-3 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -3)).card = 1 := by decide
-- The figure: six global sections of O(2) on the plane, three classes of O(-4).
example : ((Fintype.piFinset fun _ : Fin 3 => Finset.Icc (0 : ℤ) 2).filter
    (fun a => ∑ j, a j = 2)).card = 6 := by decide
example : ((Fintype.piFinset fun _ : Fin 3 => Finset.Icc (-4 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -4)).card = 3 := by decide
-- Serre duality on the plane at d = -5: six top classes, six global sections of O(2).
example : ((Fintype.piFinset fun _ : Fin 3 => Finset.Icc (-5 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -5)).card = 6 := by decide
-- Plane curves of degree e = 1 to 5: genus 0, 0, 1, 3, 6.
example : ((Fintype.piFinset fun _ : Fin 3 => Finset.Icc (-1 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -1)).card = 0 := by decide
example : ((Fintype.piFinset fun _ : Fin 3 => Finset.Icc (-2 : ℤ) (-1)).filter
    (fun a => ∑ j, a j = -2)).card = 0 := by decide
example : (List.map (fun e : ℕ => (e - 1) * (e - 2) / 2) [1, 2, 3, 4, 5]) = [0, 0, 1, 3, 6] := by
  decide
-- The binomial counts behind the examples.
example : Nat.choose 1 1 = 1 ∧ Nat.choose 2 1 = 2 ∧ Nat.choose (3 + 1) 1 = 4 ∧
    Nat.choose 2 2 = 1 ∧ Nat.choose (2 + 2) 2 = 6 ∧ Nat.choose 4 2 = 6 := by decide

#print axioms top_class_count_eq_choose
#print axioms global_section_count_eq_choose
#print axioms plane_curve_genus_from_top_classes
