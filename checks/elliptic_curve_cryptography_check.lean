-- Elliptic curves: in any group of points, both sides of Diffie-Hellman reach the same point (d_L d_B mod n)G, a correctly made ECDSA signature always checks, and baby step, giant step needs at most 2w steps.
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Algebra.Field.ZMod
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- Key agreement (ECDH) gives both sides the same point. In any group of points,
with base point G of order n, the laptop's d_L Q_B and the bank's d_B Q_L are the
same point, and it equals (d_L d_B mod n) G. -/
theorem ecdh_shared_point {A : Type*} [AddCommGroup A] (G : A) (n dL dB : ℕ)
    (hn : addOrderOf G = n) :
    dL • (dB • G) = dB • (dL • G) ∧ dB • (dL • G) = ((dL * dB) % n) • G := by
  refine ⟨?_, ?_⟩
  · rw [smul_smul, smul_smul, mul_comm]
  · rw [smul_smul, ← hn, mod_addOrderOf_nsmul, mul_comm]

/-- A correctly made ECDSA signature always checks. With base point G of prime order n,
signing key d_S, public key Q_S = d_S G, one-time number k, hash z, first half r, and
s = k⁻¹ (z + r d_S) mod n with s invertible, the checker's point
u₁ G + u₂ Q_S, where u₁ = z s⁻¹ and u₂ = r s⁻¹ mod n, is exactly k G. -/
theorem ecdsa_valid_signature_checks {A : Type*} [AddCommGroup A] (G : A) (n : ℕ)
    [Fact n.Prime] (hn : addOrderOf G = n) (dS k z r s : ZMod n)
    (hs_def : s = k⁻¹ * (z + r * dS)) (hs : s ≠ 0) :
    (z * s⁻¹).val • G + (r * s⁻¹).val • (dS.val • G) = k.val • G := by
  have key : ∀ m : ℕ, m • G = ((m : ZMod n).val) • G := by
    intro m
    rw [ZMod.val_natCast, ← hn, mod_addOrderOf_nsmul]
  have hk : k ≠ 0 := by
    rintro rfl
    simp at hs_def
    exact hs hs_def
  have hX : z + r * dS = k * s := by
    rw [hs_def, ← mul_assoc, mul_inv_cancel₀ hk, one_mul]
  have hsum : z * s⁻¹ + r * s⁻¹ * dS = k := by
    calc z * s⁻¹ + r * s⁻¹ * dS = (z + r * dS) * s⁻¹ := by ring
      _ = k := by rw [hX, mul_assoc, mul_inv_cancel₀ hs, mul_one]
  rw [smul_smul, ← add_nsmul, key]
  congr 2
  push_cast
  simp only [ZMod.natCast_val, ZMod.cast_id', id]
  rw [← hsum]

/-- Baby step, giant step covers every key. If w is a whole number with w² ≥ n,
every key below n can be written as i w + j with i and j both below w, so at most
w baby steps and w giant steps find it. -/
theorem baby_step_giant_step_split (n w k : ℕ) (hw : n ≤ w * w) (hk : k < n) :
    ∃ i < w, ∃ j < w, k = i * w + j := by
  have hw0 : 0 < w := by
    rcases Nat.eq_zero_or_pos w with h | h
    · subst h; omega
    · exact h
  refine ⟨k / w, ?_, k % w, Nat.mod_lt _ hw0, (Nat.div_add_mod' k w).symm⟩
  exact (Nat.div_lt_iff_lt_mul hw0).2 (by omega)

/-! Worked numbers from the card: the toy curve y² = x³ + 2x + 2 mod 17, n = 19. -/

-- The points of the worked table lie on the toy curve.
example : ((1 : ZMod 17))^2 = (5 : ZMod 17)^3 + 2 * 5 + 2 := by decide
example : ((4 : ZMod 17))^2 = (16 : ZMod 17)^3 + 2 * 16 + 2 := by decide
example : ((6 : ZMod 17))^2 = (0 : ZMod 17)^3 + 2 * 0 + 2 := by decide
example : ((16 : ZMod 17))^2 = (3 : ZMod 17)^3 + 2 * 3 + 2 := by decide
example : ((11 : ZMod 17))^2 = (7 : ZMod 17)^3 + 2 * 7 + 2 := by decide
example : ((6 : ZMod 17))^2 = (7 : ZMod 17)^3 + 2 * 7 + 2 := by decide
example : ((3 : ZMod 17))^2 = (6 : ZMod 17)^3 + 2 * 6 + 2 := by decide
example : ((6 : ZMod 17))^2 = (10 : ZMod 17)^3 + 2 * 10 + 2 := by decide

-- Testing every pair (x, y) mod 17 finds 18 points; with O that is 19.
example : ((Finset.univ : Finset (ZMod 17 × ZMod 17)).filter
    (fun q => q.2 ^ 2 = q.1 ^ 3 + 2 * q.1 + 2)).card + 1 = 19 := by decide

-- Slopes in the double-and-add table, mod 17.
example : (13 : ZMod 17) * (2 * 1) = 3 * 5 ^ 2 + 2 := by decide
example : (2 : ZMod 17) * (5 - 6) = 1 - 3 := by decide
example : (11 : ZMod 17) * (2 * 6) = 3 * 10 ^ 2 + 2 := by decide
example : (10 : ZMod 17) * (2 * 13) = 3 * 16 ^ 2 + 2 := by decide
example : (15 : ZMod 17) * (5 - 0) = 1 - 11 := by decide

-- Shared point: 13 × 7 = 91, and 91 mod 19 = 15.
example : 13 * 7 % 19 = 15 := by norm_num

-- Signing with k = 10, z = 5, r = 7, d_S = 9: 1/k = 2 and s = 3.
example : (10 : ZMod 19) * 2 = 1 := by decide
example : (2 : ZMod 19) * (5 + 7 * 9) = 3 := by decide
-- Checking: 1/s = 13, u₁ = 8, u₂ = 15, and 8 + 15 × 9 leaves 10 = k mod 19.
example : (3 : ZMod 19) * 13 = 1 := by decide
example : (5 : ZMod 19) * 13 = 8 ∧ (7 : ZMod 19) * 13 = 15 := by decide
example : (8 + 15 * 9) % 19 = 10 := by norm_num

-- The 32-bit toy group: w = 65,536 is the whole number at or just above √n.
example : 65535 * 65535 < 4294956467 ∧ 4294956467 ≤ 65536 * 65536 := by norm_num
-- The key 3,141,592,653 = 47,936 w + 58,957, so 47,936 giant steps find it,
-- and 65,536 + 47,936 = 113,472 steps in all.
example : 3141592653 = 47936 * 65536 + 58957 ∧ 65536 + 47936 = 113472 := by norm_num

#print axioms ecdh_shared_point
#print axioms ecdsa_valid_signature_checks
#print axioms baby_step_giant_step_split
