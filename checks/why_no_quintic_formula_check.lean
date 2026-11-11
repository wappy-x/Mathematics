-- Why there is no quintic formula: for every degree from 5 up there is a polynomial with rational coefficients having a complex root that no radical expression writes, because the shuffles of 5 or more roots never peel down to nothing while those of 3 and 4 do.
import Mathlib.FieldTheory.AbelRuffini
import Mathlib.GroupTheory.Solvable
import Mathlib.GroupTheory.SpecificGroups.Alternating.Centralizer
import Mathlib.Basic.Complex.Basic
import Mathlib.GroupTheory.SpecificGroups.Alternating.Simple
import Mathlib.Analysis.Calculus.LocalExtr.Polynomial
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.Eisenstein.Criterion
import Mathlib.RingTheory.Int.Basic
import Mathlib.RingTheory.Polynomial.GaussLemma

open Polynomial Equiv

section QuinticHelper

open Function Polynomial.Gal Ideal

attribute [local instance] splits_ℚ_ℂ

/-- The quintic `X ^ 5 - a X + b`. -/
noncomputable def Φ (R : Type*) [CommRing R] (a b : ℕ) : R[X] :=
  X ^ 5 - C (a : R) * X + C (b : R)

theorem map_Phi {R : Type*} [CommRing R] (a b : ℕ) {S : Type*} [CommRing S] (f : R →+* S) :
    (Φ R a b).map f = Φ S a b := by simp [Φ]

theorem coeff_zero_Phi {R : Type*} [CommRing R] (a b : ℕ) : (Φ R a b).coeff 0 = (b : R) := by
  simp [Φ, coeff_X_pow]

theorem coeff_five_Phi {R : Type*} [CommRing R] (a b : ℕ) : (Φ R a b).coeff 5 = 1 := by
  simp [Φ, -map_natCast]

theorem degree_Phi {R : Type*} [CommRing R] [Nontrivial R] (a b : ℕ) :
    (Φ R a b).degree = ((5 : ℕ) : WithBot ℕ) := by
  suffices degree (X ^ 5 - C (a : R) * X) = ((5 : ℕ) : WithBot ℕ) by
    rwa [Φ, degree_add_eq_left_of_degree_lt]
    convert! (degree_C_le (R := R)).trans_lt (WithBot.coe_lt_coe.mpr (show 0 < 5 by simp))
  rw [degree_sub_eq_left_of_degree_lt] <;> rw [degree_X_pow]
  exact (degree_C_mul_X_le (a : R)).trans_lt (WithBot.coe_lt_coe.mpr (show 1 < 5 by simp))

theorem natDegree_Phi {R : Type*} [CommRing R] [Nontrivial R] (a b : ℕ) :
    (Φ R a b).natDegree = 5 :=
  natDegree_eq_of_degree_eq_some (degree_Phi a b)

theorem monic_Phi {R : Type*} [CommRing R] [Nontrivial R] (a b : ℕ) : (Φ R a b).Monic := by
  show (Φ R a b).leadingCoeff = 1
  rw [Polynomial.leadingCoeff, natDegree_Phi, coeff_five_Phi]

theorem irreducible_Phi (a b : ℕ) (p : ℕ) (hp : p.Prime) (hpa : p ∣ a) (hpb : p ∣ b)
    (hp2b : ¬p ^ 2 ∣ b) : Irreducible (Φ ℚ a b) := by
  rw [← map_Phi a b (Int.castRingHom ℚ), ← IsPrimitive.Int.irreducible_iff_irreducible_map_cast]
  on_goal 1 =>
    apply irreducible_of_eisenstein_criterion
    · rwa [span_singleton_prime (Int.natCast_ne_zero.mpr hp.ne_zero), Int.prime_iff_natAbs_prime]
    · rw [(monic_Phi a b).leadingCoeff, mem_span_singleton]
      exact mod_cast mt Nat.dvd_one.mp hp.ne_one
    · intro n hn
      rw [mem_span_singleton]
      rw [degree_Phi] at hn; norm_cast at hn
      interval_cases n <;>
      simp +decide only [Φ, coeff_X_pow, coeff_C, Int.natCast_dvd_natCast.mpr,
        hpb, ite_true, coeff_C_mul, ite_false, coeff_X_zero, hpa, coeff_add, zero_add, mul_zero,
        coeff_sub, add_zero, zero_sub, dvd_neg, neg_zero, dvd_mul_of_dvd_left]
    · simp only [degree_Phi, ← WithBot.coe_zero]
      decide
    · rw [coeff_zero_Phi, span_singleton_pow, mem_span_singleton]
      exact mt Int.natCast_dvd_natCast.mp hp2b
  all_goals exact Monic.isPrimitive (monic_Phi a b)

attribute [local simp] map_ofNat in
theorem real_roots_Phi_le (a b : ℕ) : Fintype.card ((Φ ℚ a b).rootSet ℝ) ≤ 3 := by
  rw [← map_Phi a b (algebraMap ℤ ℚ), Φ, ← one_mul (X ^ 5), ← C_1]
  apply (card_rootSet_le_derivative _).trans
    (Nat.succ_le_succ ((card_rootSet_le_derivative _).trans (Nat.succ_le_succ _)))
  suffices (Polynomial.rootSet (C (20 : ℚ) * X ^ 3) ℝ).Subsingleton by
    norm_num [Fintype.card_le_one_iff_subsingleton, ← mul_assoc] at *
    exact this
  rw [rootSet_C_mul_X_pow] <;>
  norm_num

theorem real_roots_Phi_ge_aux (a b : ℕ) (hab : b < a) :
    ∃ x y : ℝ, x ≠ y ∧ aeval x (Φ ℚ a b) = 0 ∧ aeval y (Φ ℚ a b) = 0 := by
  let f : ℝ → ℝ := fun x : ℝ => aeval x (Φ ℚ a b)
  have hf : f = fun x : ℝ => x ^ 5 - a * x + b := by simp [f, Φ]
  have hc : ∀ s : Set ℝ, ContinuousOn f s := fun s => (Φ ℚ a b).continuousOn_aeval
  have ha : (1 : ℝ) ≤ a := Nat.one_le_cast.mpr (Nat.one_le_of_lt hab)
  have hle : (0 : ℝ) ≤ 1 := zero_le_one
  have hf0 : 0 ≤ f 0 := by simp [hf]
  by_cases hb : (1 : ℝ) - a + b < 0
  · have hf1 : f 1 < 0 := by simp [hf, hb]
    have hfa : 0 ≤ f a := by
      simp_rw [hf, ← sq]
      refine add_nonneg (sub_nonneg.mpr (pow_right_mono₀ ha ?_)) ?_ <;> norm_num
    obtain ⟨x, ⟨-, hx1⟩, hx2⟩ := intermediate_value_Ico' hle (hc _) (Set.mem_Ioc.mpr ⟨hf1, hf0⟩)
    obtain ⟨y, ⟨hy1, -⟩, hy2⟩ := intermediate_value_Ioc ha (hc _) (Set.mem_Ioc.mpr ⟨hf1, hfa⟩)
    exact ⟨x, y, (hx1.trans hy1).ne, hx2, hy2⟩
  · replace hb : (b : ℝ) = a - 1 := by linarith [show (b : ℝ) + 1 ≤ a from mod_cast hab]
    have hf1 : f 1 = 0 := by simp [hf, hb]
    have hfa :=
      calc
        f (-a) = (a : ℝ) ^ 2 - (a : ℝ) ^ 5 + b := by
          norm_num [hf, ← sq, sub_eq_add_neg, add_comm, Odd.neg_pow (by decide : Odd 5)]
        _ ≤ (a : ℝ) ^ 2 - (a : ℝ) ^ 3 + (a - 1) := by gcongr <;> linarith
        _ = -((a : ℝ) - 1) ^ 2 * (a + 1) := by ring
        _ ≤ 0 := by nlinarith
    have ha' := neg_nonpos.mpr (hle.trans ha)
    obtain ⟨x, ⟨-, hx1⟩, hx2⟩ := intermediate_value_Icc ha' (hc _) (Set.mem_Icc.mpr ⟨hfa, hf0⟩)
    exact ⟨x, 1, (hx1.trans_lt zero_lt_one).ne, hx2, hf1⟩

theorem real_roots_Phi_ge (a b : ℕ) (hab : b < a) : 2 ≤ Fintype.card ((Φ ℚ a b).rootSet ℝ) := by
  have q_ne_zero : Φ ℚ a b ≠ 0 := (monic_Phi a b).ne_zero
  obtain ⟨x, y, hxy, hx, hy⟩ := real_roots_Phi_ge_aux a b hab
  have key : ↑({x, y} : Finset ℝ) ⊆ (Φ ℚ a b).rootSet ℝ := by
    simp [Set.insert_subset, mem_rootSet_of_ne q_ne_zero, hx, hy]
  convert! Fintype.card_le_of_embedding (Set.embeddingOfSubset _ _ key)
  simp only [Finset.coe_sort_coe, Fintype.card_coe, Finset.card_singleton,
    Finset.card_insert_of_notMem (mt Finset.mem_singleton.mp hxy)]

theorem complex_roots_Phi (a b : ℕ) (h : (Φ ℚ a b).Separable) :
    Fintype.card ((Φ ℚ a b).rootSet ℂ) = 5 :=
  (card_rootSet_eq_natDegree h (IsAlgClosed.splits _)).trans (natDegree_Phi a b)

theorem gal_Phi (a b : ℕ) (hab : b < a) (h_irred : Irreducible (Φ ℚ a b)) :
    Bijective (galActionHom (Φ ℚ a b) ℂ) := by
  apply galActionHom_bijective_of_prime_degree' h_irred
  · simp only [natDegree_Phi]; decide
  · rw [complex_roots_Phi a b h_irred.separable, Nat.succ_le_succ_iff]
    exact (real_roots_Phi_le a b).trans (Nat.le_succ 3)
  · simp_rw [complex_roots_Phi a b h_irred.separable, Nat.succ_le_succ_iff]
    exact real_roots_Phi_ge a b hab

theorem not_solvable_by_rad (a b : ℕ) (p : ℕ) (x : ℂ) (hx : aeval x (Φ ℚ a b) = 0) (hab : b < a)
    (hp : p.Prime) (hpa : p ∣ a) (hpb : p ∣ b) (hp2b : ¬p ^ 2 ∣ b) : x ∉ solvableByRad ℚ ℂ := by
  have h_irred := irreducible_Phi a b p hp hpa hpb hp2b
  apply mt (isSolvable_gal_of_irreducible · h_irred hx)
  intro h
  refine Equiv.Perm.not_isSolvable _ (le_of_eq ?_)
    (Group.isSolvable_of_surjective (gal_Phi a b hab h_irred).2)
  rw_mod_cast [Cardinal.mk_fintype, complex_roots_Phi a b h_irred.separable]

theorem not_solvable_by_rad' (x : ℂ) (hx : aeval x (Φ ℚ 4 2) = 0) : x ∉ solvableByRad ℚ ℂ := by
  apply not_solvable_by_rad 4 2 2 x hx <;> decide

/-- A complex root of `X ^ 5 - 4 X + 2` that is not solvable by radicals. -/
theorem exists_root_not_solvable :
    ∃ x : ℂ, aeval x (Φ ℚ 4 2) = 0 ∧ x ∉ solvableByRad ℚ ℂ := by
  obtain ⟨x, hx⟩ := (IsAlgClosed.splits (Φ ℂ 4 2)).exists_eval_eq_zero (by simp [degree_Phi])
  rw [← map_Phi 4 2 (algebraMap ℚ ℂ), eval_map] at hx
  exact ⟨x, hx, not_solvable_by_rad' x hx⟩

end QuinticHelper

#print axioms Φ
#print axioms map_Phi
#print axioms coeff_zero_Phi
#print axioms coeff_five_Phi
#print axioms degree_Phi
#print axioms natDegree_Phi
#print axioms monic_Phi
#print axioms irreducible_Phi
#print axioms real_roots_Phi_le
#print axioms real_roots_Phi_ge_aux
#print axioms real_roots_Phi_ge
#print axioms complex_roots_Phi
#print axioms gal_Phi
#print axioms not_solvable_by_rad
#print axioms not_solvable_by_rad'
#print axioms exists_root_not_solvable


/-- Abel and Ruffini: no radical formula solves every equation of degree 5 or more. For every
degree n from 5 up there is a polynomial with rational coefficients, of exactly that degree, with
a complex root that cannot be written from the rational numbers by plus, minus, times, divide
and nth roots (it lies outside `solvableByRad ℚ ℂ`). The root exists; only its radical spelling
fails. -/
theorem no_radical_formula_solves_every_equation_of_degree_five_or_more (n : ℕ) (hn : 5 ≤ n) :
    ∃ p : ℚ[X], p.natDegree = n ∧ ∃ x : ℂ, aeval x p = 0 ∧ x ∉ solvableByRad ℚ ℂ := by
  obtain ⟨x, hx, hxr⟩ := exists_root_not_solvable
  refine ⟨Φ ℚ 4 2 * X ^ (n - 5), ?_, x, ?_, hxr⟩
  · rw [natDegree_mul (monic_Phi 4 2).ne_zero (pow_ne_zero _ X_ne_zero),
      natDegree_Phi, natDegree_X_pow]
    omega
  · simp [hx]

/-- The group half. The shuffles of n roots peel down to the do-nothing shuffle (the group of all
permutations of n things is solvable) exactly when n is at most 4: the chain ends for 3 and 4
roots, and jams for 5 roots and more. -/
theorem shuffles_of_n_roots_peel_to_nothing_iff_n_le_four (n : ℕ) :
    Group.IsSolvable (Perm (Fin n)) ↔ n ≤ 4 := by
  constructor
  · intro h
    by_contra hn
    refine Equiv.Perm.not_isSolvable (Fin n) ?_ h
    rw [Cardinal.mk_fin]
    exact_mod_cast (by omega : 5 ≤ n)
  · intro hn
    exact Equiv.Perm.isSolvable (by simpa using hn)

/-- The jam at 60. Peeling the 120 shuffles of five roots (taking the subgroup their commutators
generate) gives exactly the 60 even shuffles, and peeling those 60 gives all 60 back again. -/
theorem peel_of_five_shuffles_is_the_even_sixty_and_stays_there :
    commutator (Perm (Fin 5)) = alternatingGroup (Fin 5) ∧
      commutator (alternatingGroup (Fin 5)) = ⊤ := by
  exact ⟨alternatingGroup.commutator_perm_eq (by simp),
    commutator_alternatingGroup_eq_top (by simp)⟩

-- x^5 - x - 1 at x = 1 and x = 2: -1 and 29, so a root lies between.
example : (1 : ℤ) ^ 5 - 1 - 1 = -1 ∧ (2 : ℤ) ^ 5 - 2 - 1 = 29 := by norm_num
-- x^5 - 2 at x = 1 and x = 2: -1 and 30.
example : (1 : ℤ) ^ 5 - 2 = -1 ∧ (2 : ℤ) ^ 5 - 2 = 30 := by norm_num
-- The shuffles of 3, 4 and 5 roots: 6, 24 and 120.
example : Fintype.card (Perm (Fin 3)) = 6 ∧ Fintype.card (Perm (Fin 4)) = 24 ∧
    Fintype.card (Perm (Fin 5)) = 120 := by
  norm_num [Fintype.card_perm, Nat.factorial]
-- The even shuffles of five roots: 60, counted by sign.
example : (Finset.univ.filter fun σ : Perm (Fin 5) => Perm.sign σ = 1).card = 60 := by decide
-- The code's pair: the double swaps [1, 3, 2, 5, 4] and [2, 1, 3, 5, 4] (places 1 to 5 written
-- here as 0 to 4) have as commutator the three-place cycle [2, 3, 1, 4, 5].
example : ∀ i : Fin 5,
    ((swap 1 2 * swap 3 4) * (swap 0 1 * swap 3 4) * (swap 1 2 * swap 3 4)⁻¹ *
      (swap 0 1 * swap 3 4)⁻¹ : Perm (Fin 5)) i = ![1, 2, 0, 3, 4] i := by decide
-- Both double swaps are even.
example : Perm.sign (swap 1 2 * swap 3 4 : Perm (Fin 5)) = 1 ∧
    Perm.sign (swap 0 1 * swap 3 4 : Perm (Fin 5)) = 1 := by decide
-- There are 20 three-place cycles among the shuffles of five roots.
example : (Finset.univ.filter fun σ : Perm (Fin 5) => σ.support.card = 3).card = 20 := by decide

#print axioms no_radical_formula_solves_every_equation_of_degree_five_or_more
#print axioms shuffles_of_n_roots_peel_to_nothing_iff_n_le_four
#print axioms peel_of_five_shuffles_is_the_even_sixty_and_stays_there
