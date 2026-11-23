-- Permanent against determinant: for a square grid of 0s and 1s the permanent counts the perfect matchings (even plus odd) while the determinant takes even minus odd, a fixed sign pattern turns permanents into determinants at size 2 but at no size from 3 up, and Ryser's formula gives the permanent as a signed sum over column sets.
import Mathlib.LinearAlgebra.Matrix.Permanent
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Fintype.Powerset

open Matrix Equiv Finset

namespace PermanentVersusDeterminant

/-- The card's pairings that work: permutations `σ` giving row `i` the column `σ i`, with every
chosen entry equal to 1 (every lead paired with a follow they have practised with). -/
def workingPairings {n : ℕ} (A : Matrix (Fin n) (Fin n) ℤ) : Finset (Perm (Fin n)) :=
  univ.filter fun σ => ∀ i, A i (σ i) = 1

/-- The working pairings with sign `+1` (an even count of pairs out of order). -/
def evenPairings {n : ℕ} (A : Matrix (Fin n) (Fin n) ℤ) : Finset (Perm (Fin n)) :=
  (workingPairings A).filter fun σ => Perm.sign σ = 1

/-- The working pairings with sign `-1` (an odd count of pairs out of order). -/
def oddPairings {n : ℕ} (A : Matrix (Fin n) (Fin n) ℤ) : Finset (Perm (Fin n)) :=
  (workingPairings A).filter fun σ => Perm.sign σ = -1

/-- Same sum, different signs. For a square grid `A` of 0s and 1s, with ordinary whole-number
arithmetic, the permanent counts the perfect matchings (the pairings in which every chosen entry
is 1); that count splits into even and odd pairings, the permanent is even plus odd, and the
determinant is even minus odd. -/
theorem permanent_counts_matchings_determinant_signs_them {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℤ) (h01 : ∀ i j, A i j = 0 ∨ A i j = 1) :
    A.permanent = ((workingPairings A).card : ℤ) ∧
      A.permanent = ((evenPairings A).card : ℤ) + ((oddPairings A).card : ℤ) ∧
      A.det = ((evenPairings A).card : ℤ) - ((oddPairings A).card : ℤ) := by
  have hprod : ∀ σ : Perm (Fin n),
      ∏ i, A i (σ i) = if ∀ i, A i (σ i) = 1 then 1 else 0 := by
    intro σ
    split_ifs with h
    · exact Finset.prod_eq_one (fun i _ => h i)
    · push Not at h
      obtain ⟨i, hi⟩ := h
      exact Finset.prod_eq_zero (Finset.mem_univ i) ((h01 i (σ i)).resolve_right hi)
  have hperm : A.permanent = ∑ σ : Perm (Fin n), ∏ i, A i (σ i) := by
    rw [← permanent_transpose]; rfl
  have hdet : A.det = ∑ σ : Perm (Fin n), (Perm.sign σ : ℤ) * ∏ i, A i (σ i) := by
    rw [← det_transpose, det_apply']; rfl
  have hodd : (workingPairings A).filter (fun σ => ¬ Perm.sign σ = 1) = oddPairings A := by
    unfold oddPairings
    apply Finset.filter_congr
    intro σ _
    rcases Int.units_eq_one_or (Perm.sign σ) with h | h <;> simp [h]
  have hcard : (workingPairings A).card = (evenPairings A).card + (oddPairings A).card := by
    rw [← hodd, evenPairings, Finset.card_filter_add_card_filter_not]
  have h1 : A.permanent = ((workingPairings A).card : ℤ) := by
    rw [hperm]; simp_rw [hprod]; rw [Finset.sum_boole]; rfl
  refine ⟨h1, by rw [h1, hcard]; push_cast; ring, ?_⟩
  rw [hdet]
  simp_rw [hprod, mul_ite, mul_one, mul_zero]
  rw [← Finset.sum_filter]
  change ∑ σ ∈ workingPairings A, (Perm.sign σ : ℤ) = _
  rw [← Finset.sum_filter_add_sum_filter_not (workingPairings A) (fun σ => Perm.sign σ = 1), hodd]
  have he : ∑ σ ∈ evenPairings A, (Perm.sign σ : ℤ) = (evenPairings A).card := by
    rw [Finset.sum_congr rfl (g := fun _ => (1 : ℤ))]
    · simp
    · intro σ hσ; simp [(Finset.mem_filter.1 hσ).2]
  have ho : ∑ σ ∈ oddPairings A, (Perm.sign σ : ℤ) = -(oddPairings A).card := by
    rw [Finset.sum_congr rfl (g := fun _ => (-1 : ℤ))]
    · simp
    · intro σ hσ; simp [(Finset.mem_filter.1 hσ).2]
  rw [← evenPairings, he, ho]; ring

lemma det_signed_perm_matrix {n : ℕ} (s : Matrix (Fin n) (Fin n) ℤ) (σ : Perm (Fin n)) :
    (Matrix.of fun i j => s i j *
      (Matrix.of fun i j => if i = σ j then (1 : ℤ) else 0 : Matrix (Fin n) (Fin n) ℤ) i j).det =
      (Perm.sign σ : ℤ) * ∏ i, s (σ i) i := by
  rw [det_apply', Finset.sum_eq_single σ]
  · simp
  · intro τ _ hτ
    obtain ⟨i, hi⟩ : ∃ i, τ i ≠ σ i := by
      by_contra h; push Not at h; exact hτ (Equiv.ext h)
    rw [Finset.prod_eq_zero (Finset.mem_univ i) (by simp [hi]), mul_zero]
  · intro h; exact absurd (Finset.mem_univ σ) h

lemma permanent_perm_matrix {n : ℕ} (σ : Perm (Fin n)) :
    (Matrix.of fun i j => if i = σ j then (1 : ℤ) else 0 : Matrix (Fin n) (Fin n) ℤ).permanent
      = 1 := by
  rw [permanent, Finset.sum_eq_single σ]
  · simp
  · intro τ _ hτ
    obtain ⟨i, hi⟩ : ∃ i, τ i ≠ σ i := by
      by_contra h; push Not at h; exact hτ (Equiv.ext h)
    exact Finset.prod_eq_zero (Finset.mem_univ i) (by simp [hi])
  · intro h; exact absurd (Finset.mem_univ σ) h

#print axioms det_signed_perm_matrix
#print axioms permanent_perm_matrix

/-- Pólya's sign trick. At size 2 one fixed sign pattern turns every permanent into a
determinant: perm `[[a, b], [c, d]]` = det `[[a, -b], [c, d]]`. At size 3 it fails: every
3 by 3 grid of `+1`s and `-1`s has determinant at most 4 in size, short of the all-ones
permanent 6. And at every size from 3 up, no grid `s` of `+1`s and `-1`s makes the determinant
of the signed grid (entry `s i j * A i j`) equal the permanent of `A` for every grid `A`. -/
theorem sign_pattern_works_at_two_fails_from_three :
    (∀ a b c d : ℤ, (!![a, -b; c, d] : Matrix (Fin 2) (Fin 2) ℤ).det =
        (!![a, b; c, d] : Matrix (Fin 2) (Fin 2) ℤ).permanent) ∧
      (∀ M : Matrix (Fin 3) (Fin 3) ℤ, (∀ i j, M i j = 1 ∨ M i j = -1) → |M.det| ≤ 4) ∧
      ∀ n : ℕ, 3 ≤ n → ¬ ∃ s : Matrix (Fin n) (Fin n) ℤ, (∀ i j, s i j = 1 ∨ s i j = -1) ∧
        ∀ A : Matrix (Fin n) (Fin n) ℤ, (Matrix.of fun i j => s i j * A i j).det = A.permanent := by
  refine ⟨?_, ?_, ?_⟩
  · intro a b c d
    rw [det_fin_two_of, permanent,
      show (univ : Finset (Perm (Fin 2))) = {1, swap 0 1} from by decide,
      Finset.sum_pair (by decide)]
    simp [Fin.prod_univ_two]
    ring
  · intro M hM
    rw [det_fin_three]
    rcases hM 0 0 with h00 | h00 <;> rcases hM 0 1 with h01 | h01 <;>
      rcases hM 0 2 with h02 | h02 <;> rcases hM 1 0 with h10 | h10 <;>
      rcases hM 1 1 with h11 | h11 <;> rcases hM 1 2 with h12 | h12 <;>
      rcases hM 2 0 with h20 | h20 <;> rcases hM 2 1 with h21 | h21 <;>
      rcases hM 2 2 with h22 | h22 <;>
      simp only [h00, h01, h02, h10, h11, h12, h20, h21, h22] <;> norm_num
  · rintro n hn ⟨s, hs, hA⟩
    have key : ∀ σ : Perm (Fin n), (Perm.sign σ : ℤ) * ∏ i, s (σ i) i = 1 := by
      intro σ
      have h := hA (Matrix.of fun i j => if i = σ j then (1 : ℤ) else 0)
      rw [det_signed_perm_matrix, permanent_perm_matrix] at h
      exact h
    obtain ⟨a, b, c, hab, hbc, hac⟩ : ∃ a b c : Fin n, a ≠ b ∧ b ≠ c ∧ a ≠ c :=
      ⟨⟨0, by omega⟩, ⟨1, by omega⟩, ⟨2, by omega⟩, by simp [Fin.ext_iff],
        by simp [Fin.ext_iff], by simp [Fin.ext_iff]⟩
    have heven : ∀ σ : Perm (Fin n), Perm.sign σ = 1 → ∏ i, s (σ i) i = 1 := by
      intro σ h; have := key σ; rw [h] at this; simpa using this
    have hoddp : ∀ σ : Perm (Fin n), Perm.sign σ = -1 → ∏ i, s (σ i) i = -1 := by
      intro σ h; have := key σ; rw [h] at this; simp at this; linarith
    have e1 := heven 1 (by simp)
    have e2 := heven (swap a b * swap b c) (by simp [Perm.sign_mul, Perm.sign_swap hab, Perm.sign_swap hbc])
    have e3 := heven (swap b c * swap a b) (by simp [Perm.sign_mul, Perm.sign_swap hab, Perm.sign_swap hbc])
    have o1 := hoddp (swap a b) (Perm.sign_swap hab)
    have o2 := hoddp (swap b c) (Perm.sign_swap hbc)
    have o3 := hoddp (swap a c) (Perm.sign_swap hac)
    have latin : (∏ i, s ((1 : Perm (Fin n)) i) i) * (∏ i, s ((swap a b * swap b c) i) i) *
        (∏ i, s ((swap b c * swap a b) i) i) =
        (∏ i, s (swap a b i) i) * (∏ i, s (swap b c i) i) * (∏ i, s (swap a c i) i) := by
      simp only [← Finset.prod_mul_distrib]
      apply Finset.prod_congr rfl
      intro i _
      by_cases ha : i = a
      · subst ha
        simp only [Perm.one_apply, Perm.mul_apply, swap_apply_left, swap_apply_right, swap_apply_of_ne_of_ne, ne_eq, hab, hbc, hac, hab.symm, hbc.symm, hac.symm, not_false_eq_true]
        ring
      by_cases hb : i = b
      · subst hb
        simp only [Perm.one_apply, Perm.mul_apply, swap_apply_left, swap_apply_right, swap_apply_of_ne_of_ne, ne_eq, hab, hbc, hac, hab.symm, hbc.symm, hac.symm, not_false_eq_true]
        ring
      by_cases hc : i = c
      · subst hc
        simp only [Perm.one_apply, Perm.mul_apply, swap_apply_left, swap_apply_right, swap_apply_of_ne_of_ne, ne_eq, hab, hbc, hac, hab.symm, hbc.symm, hac.symm, not_false_eq_true]
        ring
      simp only [Perm.one_apply, Perm.mul_apply, swap_apply_of_ne_of_ne, ne_eq, ha, hb, hc, not_false_eq_true]
    rw [e1, e2, e3, o1, o2, o3] at latin
    norm_num at latin

lemma superset_sign_sum (n : ℕ) (T : Finset (Fin n)) :
    ∑ S : Finset (Fin n), (if T ⊆ S then (-1 : ℤ) ^ (n - S.card) else 0) =
      if T = univ then 1 else 0 := by
  rw [(Fintype.sum_bijective compl compl_involutive.bijective
    (fun U => if T ⊆ Uᶜ then (-1 : ℤ) ^ (n - Uᶜ.card) else 0)
    (fun S => if T ⊆ S then (-1 : ℤ) ^ (n - S.card) else 0) (fun _ => rfl)).symm]
  have h : ∀ U : Finset (Fin n), (if T ⊆ Uᶜ then (-1 : ℤ) ^ (n - Uᶜ.card) else 0) =
      if U ⊆ Tᶜ then (-1 : ℤ) ^ U.card else 0 := by
    intro U
    have hc : n - Uᶜ.card = U.card := by
      rw [Finset.card_compl, Fintype.card_fin,
        Nat.sub_sub_self (by simpa using Finset.card_le_univ U)]
    simp only [Finset.subset_compl_comm, hc]
  simp_rw [h]
  rw [← Finset.sum_filter, Finset.filter_subset_univ, Finset.sum_powerset_neg_one_pow_card]
  simp only [Finset.compl_eq_empty_iff]

lemma bijective_of_image_univ {n : ℕ} {f : Fin n → Fin n}
    (hf : f ∈ (univ : Finset (Fin n → Fin n)).filter (fun f => univ.image f = univ)) :
    Function.Bijective f := by
  have hs : Function.Surjective f := by
    intro x
    have : x ∈ univ.image f := by rw [(Finset.mem_filter.1 hf).2]; exact mem_univ x
    simpa using this
  exact ⟨Finite.injective_iff_surjective.2 hs, hs⟩

lemma ryser_aux {n : ℕ} (A : Fin n → Fin n → ℤ) :
    ∑ σ : Perm (Fin n), ∏ i, A i (σ i) =
      ∑ S : Finset (Fin n), (-1) ^ (n - S.card) * ∏ i, ∑ j ∈ S, A i j := by
  have h1 : ∀ S : Finset (Fin n),
      (-1 : ℤ) ^ (n - S.card) * ∏ i, ∑ j ∈ S, A i j =
        ∑ f : Fin n → Fin n, (∏ i, A i (f i)) *
          (if univ.image f ⊆ S then (-1 : ℤ) ^ (n - S.card) else 0) := by
    intro S
    rw [← Finset.sum_prod_piFinset, Finset.mul_sum]
    simp_rw [mul_ite, mul_zero]
    rw [← Finset.sum_filter]
    apply Finset.sum_congr
    · ext f; simp [Finset.image_subset_iff]
    · intro f _; ring
  simp_rw [h1]
  rw [Finset.sum_comm]
  simp_rw [← Finset.mul_sum, superset_sign_sum, mul_ite, mul_one, mul_zero]
  rw [← Finset.sum_filter]
  symm
  apply Finset.sum_bij' (fun f hf => Equiv.ofBijective f (bijective_of_image_univ hf))
    (fun σ _ => ⇑σ)
  case hi => intro f _; exact mem_univ _
  case hj =>
    intro σ _
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    exact Finset.image_univ_of_surjective σ.surjective
  case left_neg => intro f _; rfl
  case right_neg => intro σ _; ext x; rfl
  case h => intro f _; rfl

#print axioms superset_sign_sum
#print axioms bijective_of_image_univ
#print axioms ryser_aux

/-- Ryser's formula (1963). For each set `S` of columns, multiply the row sums restricted to `S`,
with sign `(-1)^(n - |S|)`; adding over all column sets gives the permanent. -/
theorem ryser_formula {n : ℕ} (A : Matrix (Fin n) (Fin n) ℤ) :
    A.permanent = ∑ S : Finset (Fin n), (-1) ^ (n - S.card) * ∏ i, ∑ j ∈ S, A i j := by
  rw [← permanent_transpose]
  exact ryser_aux (fun i j => A i j)

/-! The card's whole-number worked examples. -/

/-- The rotating class: lead `i` has practised with follows `i`, `i + 1` and `i + 2`,
wrapping round the circle. -/
def dance (n : ℕ) : Matrix (Fin n) (Fin n) ℤ :=
  Matrix.of fun i j => if ((j : ℕ) + n - i) % n ≤ 2 then 1 else 0

-- Four couples: 24 permutations, 9 working pairings, 6 even and 3 odd,
-- so the permanent is 9 and the determinant is 6 - 3 = 3.
example : Fintype.card (Perm (Fin 4)) = 24 := by decide
example : (workingPairings (dance 4)).card = 9 := by decide
example : (evenPairings (dance 4)).card = 6 := by decide
example : (oddPairings (dance 4)).card = 3 := by decide
example : (dance 4).permanent = 9 := by decide
example : (dance 4).det = 3 := by decide

-- Eight couples: 8! = 40,320 permutations; 26 even and 23 odd pairings give
-- permanent 26 + 23 = 49 and determinant 26 - 23 = 3. Mod 2 they agree: both odd.
example : Fintype.card (Perm (Fin 8)) = 40320 := by
  rw [Fintype.card_perm, Fintype.card_fin]; decide
example : (26 + 23 : ℤ) = 49 ∧ (26 - 23 : ℤ) = 3 := by norm_num
example : 49 % 2 = 3 % 2 := by norm_num

-- Elimination keeps the determinant but not the permanent. On [[1, 2], [3, 4]] the permanent
-- is 10 and the determinant -2; after row 2 minus 3 times row 1 both are -2. The permanent fell
-- by 3 times perm [[1, 2], [1, 2]] = 3 * 4 = 12.
example : (!![1, 2; 3, 4] : Matrix (Fin 2) (Fin 2) ℤ).permanent = 10 := by decide
example : (!![1, 2; 3, 4] : Matrix (Fin 2) (Fin 2) ℤ).det = -2 := by decide
example : (!![1, 2; 0, -2] : Matrix (Fin 2) (Fin 2) ℤ).permanent = -2 := by decide
example : (!![1, 2; 0, -2] : Matrix (Fin 2) (Fin 2) ℤ).det = -2 := by decide
example : (!![1, 2; 1, 2] : Matrix (Fin 2) (Fin 2) ℤ).permanent = 4 := by decide

-- The sign trick at n = 2: det [[1, -2], [3, 4]] = 10, the permanent of [[1, 2], [3, 4]].
example : (!![1, -2; 3, 4] : Matrix (Fin 2) (Fin 2) ℤ).det = 10 := by decide

-- At n = 3 the all-ones permanent is 3! = 6; there are 2^9 = 512 sign patterns to try.
example : (Matrix.of fun _ _ => (1 : ℤ) : Matrix (Fin 3) (Fin 3) ℤ).permanent = 6 := by decide
example : 2 ^ 9 = 512 := by norm_num

-- Ryser's formula on the four-couple class also gives 9.
example : ∑ S : Finset (Fin 4), (-1 : ℤ) ^ (4 - S.card) * ∏ i, ∑ j ∈ S, dance 4 i j = 9 := by
  decide

-- Counted work at n = 8: every pairing 8! * 7 = 282,240, Ryser (2^8 - 1) * 8 = 2,040,
-- elimination 2 * (1^2 + ... + 7^2) = 280.
example : 40320 * 7 = 282240 := by norm_num
example : (2 ^ 8 - 1) * 8 = 2040 := by norm_num
example : 2 * ∑ m ∈ range 8, m ^ 2 = 280 := by decide

-- At n = 32: Ryser (2^32 - 1) * 32 = 137,438,953,440 and elimination 20,832.
example : (2 ^ 32 - 1) * 32 = 137438953440 := by norm_num
example : 2 * ∑ m ∈ range 32, m ^ 2 = 20832 := by decide

#print axioms permanent_counts_matchings_determinant_signs_them
#print axioms sign_pattern_works_at_two_fails_from_three
#print axioms ryser_formula

end PermanentVersusDeterminant
