-- Finding a pattern in text: for a prime clock p larger than every letter code, two different words of m letters share a Rabin–Karp fingerprint for at most m − 1 of the p bases, the fingerprint rolls one place in a few steps, and every shorter border of a word is a border of its longest border.
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Nat.Find
import Mathlib.Data.Rat.Defs
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.Field.ZMod

open Finset

/-- Rabin–Karp's fingerprint of a word `w` of `m` letter codes, with base `b` on the clock
of size `p`: `w₀ b^(m-1) + w₁ b^(m-2) + … + w_(m-1)`, reduced mod `p`. -/
def fingerprint {p m : ℕ} (w : Fin m → ℕ) (b : ZMod p) : ZMod p :=
  ∑ j : Fin m, (w j : ZMod p) * b ^ (m - 1 - (j : ℕ))

/-- The window of `m` letters of the text `T` that starts at position `s`. -/
def window (m : ℕ) (T : ℕ → ℕ) (s : ℕ) : Fin m → ℕ := fun j => T (s + j)

/-- Rabin–Karp's false-match bound. Let `p` be a prime larger than every letter code, and let
`w ≠ P` be two different words of `m` letters. Over a base `b` drawn uniformly at random from
`0` to `p - 1`, the chance that `w` and `P` get the same fingerprint is at most `(m - 1)/p`. -/
theorem rabin_karp_false_match_chance_le (p : ℕ) [Fact p.Prime] (m : ℕ) (w P : Fin m → ℕ)
    (hw : ∀ j, w j < p) (hP : ∀ j, P j < p) (hne : w ≠ P) :
    ((univ.filter (fun b : ZMod p => fingerprint w b = fingerprint P b)).card : ℚ) / p
      ≤ ((m - 1 : ℕ) : ℚ) / p := by
  classical
  have hp : (0 : ℚ) < p := by exact_mod_cast (Fact.out : p.Prime).pos
  apply div_le_div_of_nonneg_right _ hp.le
  norm_cast
  obtain ⟨j0, hj0⟩ : ∃ j0, w j0 ≠ P j0 := by
    by_contra h
    push Not at h
    exact hne (funext h)
  have hcast : ∀ j, ((w j : ZMod p) - (P j : ZMod p) = 0) → w j = P j := by
    intro j h
    have h' : (w j : ZMod p) = (P j : ZMod p) := sub_eq_zero.mp h
    have := congrArg ZMod.val h'
    rwa [ZMod.val_cast_of_lt (hw j), ZMod.val_cast_of_lt (hP j)] at this
  set q : Polynomial (ZMod p) := ∑ j : Fin m,
    Polynomial.C ((w j : ZMod p) - (P j : ZMod p)) * Polynomial.X ^ (m - 1 - (j : ℕ)) with hq
  have heval : ∀ b : ZMod p, q.eval b = fingerprint w b - fingerprint P b := by
    intro b
    simp only [hq, Polynomial.eval_finsetSum, Polynomial.eval_mul, Polynomial.eval_C,
      Polynomial.eval_pow, Polynomial.eval_X, fingerprint, ← Finset.sum_sub_distrib, sub_mul]
  have hcoeff : q.coeff (m - 1 - (j0 : ℕ)) = (w j0 : ZMod p) - (P j0 : ZMod p) := by
    simp only [hq, Polynomial.finsetSum_coeff, Polynomial.coeff_C_mul_X_pow]
    rw [Finset.sum_eq_single j0]
    · simp
    · intro j _ hj
      have h1 := j.isLt
      have h2 := j0.isLt
      have : m - 1 - (j0 : ℕ) ≠ m - 1 - (j : ℕ) := by
        intro h
        apply hj
        ext
        omega
      simp [this]
    · simp
  have hq0 : q ≠ 0 := by
    intro h
    have : q.coeff (m - 1 - (j0 : ℕ)) = 0 := by rw [h]; simp
    rw [hcoeff] at this
    exact hj0 (hcast j0 this)
  have hdeg : q.natDegree ≤ m - 1 := by
    apply Polynomial.natDegree_sum_le_of_forall_le
    intro j _
    exact (Polynomial.natDegree_C_mul_X_pow_le _ _).trans (Nat.sub_le _ _)
  calc (univ.filter (fun b : ZMod p => fingerprint w b = fingerprint P b)).card
      ≤ q.roots.toFinset.card := by
        apply Finset.card_le_card
        intro b hb
        simp only [Finset.mem_filter] at hb
        rw [Multiset.mem_toFinset, Polynomial.mem_roots hq0, Polynomial.IsRoot, heval, hb.2,
          sub_self]
    _ ≤ Multiset.card q.roots := Multiset.toFinset_card_le _
    _ ≤ q.natDegree := Polynomial.card_roots' q
    _ ≤ m - 1 := hdeg

/-- The rolling update. Sliding the window one place drops the first letter and adds the next:
`H_(s+1) = ((H_s - T_s b^(m-1)) b + T_(s+m)) mod p`, for a pattern of at least one letter. -/
theorem fingerprint_roll (p m : ℕ) (hm : 0 < m) (T : ℕ → ℕ) (s : ℕ) (b : ZMod p) :
    fingerprint (window m T (s + 1)) b
      = (fingerprint (window m T s) b - (T s : ZMod p) * b ^ (m - 1)) * b + (T (s + m) : ZMod p) := by
  obtain ⟨n, rfl⟩ : ∃ n, m = n + 1 := ⟨m - 1, by omega⟩
  simp only [fingerprint, window, Fin.sum_univ_eq_sum_range (fun j =>
      ((T (s + 1 + j) : ℕ) : ZMod p) * b ^ (n + 1 - 1 - j)),
    Fin.sum_univ_eq_sum_range (fun j => ((T (s + j) : ℕ) : ZMod p) * b ^ (n + 1 - 1 - j))]
  rw [Finset.sum_range_succ, Finset.sum_range_succ']
  simp only [Nat.add_sub_cancel, add_zero, Nat.sub_zero, Nat.sub_self, pow_zero, mul_one,
    add_sub_cancel_right, Finset.sum_mul]
  have : s + 1 + n = s + (n + 1) := by omega
  rw [this]
  congr 1
  apply Finset.sum_congr rfl
  intro j hj
  rw [Finset.mem_range] at hj
  have e1 : s + 1 + j = s + (j + 1) := by omega
  have e2 : n - j = (n - (j + 1)) + 1 := by omega
  rw [e1, e2, pow_succ, mul_assoc]

/-- Why KMP's fallback skips no match: if `v` and `x` are both borders of `u` (each is a prefix
and an ending of `u`) and `v` is no longer than `x`, then `v` is a border of `x`. So following
longest borders down visits every border of `u`. -/
theorem border_of_shorter_border {α : Type*} (u v x : List α)
    (hv : v <+: u ∧ v <:+ u) (hx : x <+: u ∧ x <:+ u) (hlen : v.length ≤ x.length) :
    v <+: x ∧ v <:+ x := by
  exact ⟨List.prefix_of_prefix_length_le hv.1 hx.1 hlen,
    List.suffix_of_suffix_length_le hv.2 hx.2 hlen⟩

/-- The length of the longest proper border of `u`, found by brute force:
the largest `k < u.length` whose first `k` letters are also an ending of `u`. -/
def longestProperBorder (u : List ℕ) : ℕ :=
  Nat.findGreatest (fun k => k < u.length ∧ u.take k <:+ u) u.length

/-- The failure table `π[q]` for `q = 0, …, m - 1`: the longest proper border of `P[0..q]`. -/
def failureTable (P : List ℕ) : List ℕ :=
  (List.range P.length).map (fun q => longestProperBorder (P.take (q + 1)))

-- The failure table of ABABAC (A = 1, B = 2, C = 3) is 0, 0, 1, 2, 3, 0.
example : failureTable [1, 2, 1, 2, 1, 3] = [0, 0, 1, 2, 3, 0] := by decide

-- By hand, base 10 mod 101: the pattern ABABAC has fingerprint 121213 mod 101 = 13.
example : fingerprint (p := 101) ![1, 2, 1, 2, 1, 3] 10 = 13 := by decide

-- The 9 windows of the hand log ABABABACABABAC have fingerprints 12 21 13 31 11 11 13 31 13.
example : (List.range 9).map (fun s => fingerprint (p := 101)
    (window 6 (fun i => [1, 2, 1, 2, 1, 2, 1, 3, 1, 2, 1, 2, 1, 3].getD i 0) s) 10)
      = [12, 21, 13, 31, 11, 11, 13, 31, 13] := by decide

-- The roll from window 0 to window 1: (121212 - 1 × 100000) × 10 + 1 = 212121.
example : (121212 - 1 * 100000) * 10 + 1 = 212121 := by decide

-- Window 6, ACABAB, is a false hit: a different word with the pattern's fingerprint 13.
example : fingerprint (p := 101) ![1, 3, 1, 2, 1, 2] 10 = 13 := by decide

-- The bound is reached: BAACCA shares ABABAC's fingerprint for exactly 5 of the 101 bases.
example : (univ.filter (fun b : ZMod 101 =>
    fingerprint ![2, 1, 1, 3, 3, 1] b = fingerprint ![1, 2, 1, 2, 1, 3] b)).card = 5 := by decide

#print axioms rabin_karp_false_match_chance_le
#print axioms fingerprint_roll
#print axioms border_of_shorter_border
