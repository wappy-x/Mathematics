-- AES: a forged GCM tag works for at most n + 1 values of the hash key, the mix step spreads a one-byte change to every byte of a column, and the S-box reciprocal is a bijection.
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Data.Matrix.Mul
import Mathlib.Algebra.Group.Basic

open Finset Matrix

/-- GCM forgery bound (Step 5). Read n + 1 blocks as elements of a finite field and form
GHASH_H(B) = B_1 H^(n+1) + B_2 H^n + ... + B_(n+1) H. If a forger changes at least one block
(B' ≠ B) and picks any tag change Δ, the forgery works only when
GHASH_H(B') = GHASH_H(B) + Δ, and that happens for at most n + 1 of the field's elements H.
So with H unknown and uniform, the chance is at most (n + 1) / |F|; for GF(2^128), (n + 1) / 2^128. -/
theorem gcm_forgery_works_for_at_most_n_plus_one_hash_keys
    {F : Type*} [Field F] [Fintype F] [DecidableEq F]
    (n : ℕ) (B B' : Fin (n + 1) → F) (hB : B ≠ B') (Δ : F) :
    (univ.filter (fun H : F =>
        ∑ j : Fin (n + 1), B' j * H ^ (n + 1 - (j : ℕ)) =
          ∑ j : Fin (n + 1), B j * H ^ (n + 1 - (j : ℕ)) + Δ)).card ≤ n + 1 := by
  classical
  set P : Polynomial F :=
    (∑ j : Fin (n + 1), Polynomial.C (B' j - B j) * Polynomial.X ^ (n + 1 - (j : ℕ)))
      - Polynomial.C Δ with hP
  obtain ⟨j0, hj0⟩ : ∃ j0, B j0 ≠ B' j0 := by
    by_contra h
    push Not at h
    exact hB (funext h)
  have hcoeff : P.coeff (n + 1 - (j0 : ℕ)) = B' j0 - B j0 := by
    rw [hP, Polynomial.coeff_sub, Polynomial.finsetSum_coeff, Polynomial.coeff_C]
    have hne : n + 1 - (j0 : ℕ) ≠ 0 := by have := j0.isLt; omega
    rw [Finset.sum_eq_single j0]
    · rw [Polynomial.coeff_C_mul_X_pow]
      simp only [hne, ↓reduceIte, sub_zero]
    · intro b _ hb
      have hne' : n + 1 - (j0 : ℕ) ≠ n + 1 - (b : ℕ) := by
        intro h
        apply hb
        have := b.isLt
        have := j0.isLt
        exact Fin.ext (by omega)
      rw [Polynomial.coeff_C_mul_X_pow]
      simp only [hne', ↓reduceIte]
    · intro h; exact absurd (Finset.mem_univ j0) h
  have hP0 : P ≠ 0 := by
    intro h
    rw [h, Polynomial.coeff_zero] at hcoeff
    exact hj0 (sub_eq_zero.mp hcoeff.symm).symm
  have hdeg : P.natDegree ≤ n + 1 := by
    rw [hP]
    refine (Polynomial.natDegree_sub_le _ _).trans (max_le ?_ ?_)
    · apply Polynomial.natDegree_sum_le_of_forall_le
      intro j _
      exact (Polynomial.natDegree_C_mul_X_pow_le _ _).trans (by omega)
    · simp
  have hsub : (univ.filter (fun H : F =>
        ∑ j : Fin (n + 1), B' j * H ^ (n + 1 - (j : ℕ)) =
          ∑ j : Fin (n + 1), B j * H ^ (n + 1 - (j : ℕ)) + Δ)) ⊆ P.roots.toFinset := by
    intro H hH
    rw [Finset.mem_filter] at hH
    rw [Multiset.mem_toFinset, Polynomial.mem_roots hP0, Polynomial.IsRoot.def, hP]
    simp only [Polynomial.eval_sub, Polynomial.eval_finsetSum, Polynomial.eval_mul,
      Polynomial.eval_C, Polynomial.eval_pow, Polynomial.eval_X, sub_mul,
      Finset.sum_sub_distrib]
    rw [hH.2]; ring
  calc _ ≤ P.roots.toFinset.card := Finset.card_le_card hsub
    _ ≤ Multiset.card P.roots := Multiset.toFinset_card_le _
    _ ≤ P.natDegree := Polynomial.card_roots' _
    _ ≤ n + 1 := hdeg

/-- Diffusion in the mix step (Step 3). If every entry of the mix matrix M is nonzero, then
changing one byte of a column by a nonzero difference δ changes every byte of the mixed column. -/
theorem mix_step_changes_every_byte_of_the_column
    {F ι : Type*} [Field F] [Fintype ι] [DecidableEq ι]
    (M : Matrix ι ι F) (hM : ∀ i j, M i j ≠ 0)
    (x : ι → F) (j : ι) (δ : F) (hδ : δ ≠ 0) :
    ∀ i, (M *ᵥ (x + Pi.single j δ)) i ≠ (M *ᵥ x) i := by
  intro i
  rw [Matrix.mulVec_add, Pi.add_apply, Matrix.mulVec_single]
  simp only [Pi.smul_apply, Matrix.col_apply, MulOpposite.smul_eq_mul_unop,
    MulOpposite.unop_op, ne_eq, add_eq_left]
  exact mul_ne_zero (hM i j) hδ

/-- The S-box can be undone (Step 1). In a field, "replace each element by its reciprocal,
and send 0 to 0" is a bijection. -/
theorem reciprocal_map_is_bijection {F : Type*} [Field F] :
    Function.Bijective (fun x : F => x⁻¹) := by
  exact inv_involutive.bijective

-- Bit-mix of ed in the S-box: ed ⊕ db ⊕ b7 ⊕ 6f ⊕ de ⊕ 63 = 53 (bytes as 8-bit vectors).
example : (0xed#8 ^^^ 0xdb#8 ^^^ 0xb7#8 ^^^ 0x6f#8 ^^^ 0xde#8 ^^^ 0x63#8) = 0x53#8 := by decide
-- The rotations of ed by 1, 2, 3, 4 places are db, b7, 6f, de.
example : (0xed#8).rotateLeft 1 = 0xdb#8 ∧ (0xed#8).rotateLeft 2 = 0xb7#8 ∧
    (0xed#8).rotateLeft 3 = 0x6f#8 ∧ (0xed#8).rotateLeft 4 = 0xde#8 := by decide
-- 02 · 63 = c6 and 02 · 53 = a6 (shift left, top bit was 0); 03 · 53 = a6 ⊕ 53 = f5.
example : (0x63#8) <<< 1 = 0xc6#8 ∧ (0x53#8) <<< 1 = 0xa6#8 ∧ (0xa6#8 ^^^ 0x53#8) = 0xf5#8 := by decide
-- Top byte of the mixed column: c6 ⊕ f5 = 33, 33 ⊕ e0 = d3, d3 ⊕ 8c = 5f.
example : (0xc6#8 ^^^ 0xf5#8) = 0x33#8 ∧ (0x33#8 ^^^ 0xe0#8) = 0xd3#8 ∧
    (0xd3#8 ^^^ 0x8c#8) = 0x5f#8 := by decide
-- Add round key 1: 5f ⊕ 10, 72 ⊕ 11, 64 ⊕ 12, 15 ⊕ 13 = 4f 63 76 06.
example : (0x5f#8 ^^^ 0x10#8) = 0x4f#8 ∧ (0x72#8 ^^^ 0x11#8) = 0x63#8 ∧
    (0x64#8 ^^^ 0x12#8) = 0x76#8 ∧ (0x15#8 ^^^ 0x13#8) = 0x06#8 := by decide
-- The 4 GB backup: 4 · 2^30 bytes, 268,435,456 blocks, 268,435,458 AES calls,
-- 268,435,457 GHASH multiplications, 12 + 16 = 28 bytes stored beside it.
example : 4 * 2 ^ 30 = 4294967296 ∧ 4294967296 / 16 = 268435456 ∧
    268435456 + 2 = 268435458 ∧ 268435456 + 1 = 268435457 ∧ 12 + 16 = 28 := by norm_num
-- n + 1 = 268,435,457 is just over 2^28, so the forgery bound is about 2^28 / 2^128 = 2^-100.
example : 2 ^ 28 < 268435457 ∧ 268435457 < 2 ^ 29 := by norm_num
-- Pad versus random: (2^28)^2 / 2^129 = 2^-73.
example : ((2 : ℚ) ^ 28) ^ 2 / 2 ^ 129 = 1 / 2 ^ 73 := by norm_num
-- One GCM message holds at most (2^32 - 2) · 16 = 68,719,476,704 bytes.
example : (2 ^ 32 - 2) * 16 = 68719476704 := by norm_num
-- Random nonces, 2^32 messages: 2^97 / (2^32 · (2^32 - 1)) rounds down to 8,589,934,594.
example : 2 ^ 97 / (2 ^ 32 * (2 ^ 32 - 1)) = 8589934594 := by norm_num

#print axioms gcm_forgery_works_for_at_most_n_plus_one_hash_keys
#print axioms mix_step_changes_every_byte_of_the_column
#print axioms reciprocal_map_is_bijection
