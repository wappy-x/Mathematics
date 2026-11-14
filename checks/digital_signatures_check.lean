-- Digital signatures: an honest ECDSA signature on an elliptic curve over a prime field always verifies, two signatures made with one reused nonce give away the private key, and without a hash anyone can forge a valid signature from the public key alone.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Algebra.Field.ZMod
import Mathlib.Tactic.NormNum.Prime

open WeierstrassCurve

/-- `x(P) mod n`: the x-coordinate of a curve point over `ZMod p`, read as a whole number from
0 to p − 1, then reduced mod n. The point at infinity has no x-coordinate. -/
def xModN {p : ℕ} (n : ℕ) {W : Affine (ZMod p)} : W.Point → Option (ZMod n)
  | .zero => none
  | .some x _ _ => some ((x.val : ℕ) : ZMod n)

/-- The verifier's check on the signature `(r, s)` for the hash value `z`, with base point `G`
and public key `Q`: both halves lie in 1 … n − 1, and with `w = s⁻¹`, `u₁ = z w`, `u₂ = r w`
(mod n), the point `u₁ G + u₂ Q` is not the point at infinity and its x-coordinate mod n is `r`. -/
def ecdsaVerify {p n : ℕ} [Fact p.Prime] (W : Affine (ZMod p)) (G Q : W.Point)
    (z r s : ZMod n) : Prop :=
  r ≠ 0 ∧ s ≠ 0 ∧ xModN n ((z * s⁻¹).val • G + (r * s⁻¹).val • Q) = some r

/-- An honest signature always verifies. Take any curve over the prime field `ZMod p`, a base
point `G` with exactly `n` multiples (n prime), a private key `d` and a nonce `k` from 1 to n − 1,
and any hash value `z`. Sign: `R = kG`, `r = x(R) mod n`, `s = k⁻¹ (z + r d) mod n`, with
`r` and `s` not zero. Then the laptop's check with the public key `Q = dG` accepts `(r, s)`. -/
theorem honest_signature_verifies {p n : ℕ} [Fact p.Prime] [Fact n.Prime]
    (W : Affine (ZMod p)) (G : W.Point) (hG : addOrderOf G = n)
    (d k z r : ZMod n) (hd : d ≠ 0) (hk : k ≠ 0)
    (hR : xModN n (k.val • G) = some r) (hr : r ≠ 0) (hs : k⁻¹ * (z + r * d) ≠ 0) :
    ecdsaVerify W G (d.val • G) z r (k⁻¹ * (z + r * d)) := by
  have hn : n.Prime := Fact.out
  have : NeZero n := ⟨hn.ne_zero⟩
  have hzrd : z + r * d ≠ 0 := by
    intro h; apply hs; rw [h, mul_zero]
  have hcast : ∀ m : ℕ, m • G = ((m : ZMod n).val) • G := by
    intro m
    rw [ZMod.val_natCast, ← hG, mod_addOrderOf_nsmul]
  refine ⟨hr, hs, ?_⟩
  have key : (z * (k⁻¹ * (z + r * d))⁻¹).val • G
      + (r * (k⁻¹ * (z + r * d))⁻¹).val • (d.val • G) = k.val • G := by
    rw [smul_smul, ← add_nsmul, hcast]
    congr 2
    push_cast
    simp only [ZMod.natCast_zmod_val]
    field_simp
  rw [key]
  exact hR

/-- One reused nonce gives the key away. If two files with different hashes `z₁ ≠ z₂` are signed
with the same nonce `k` and key `d` (so both carry the same `r ≠ 0`), then anyone can compute
`k = (z₁ − z₂) / (s₁ − s₂)` and `d = (s₁ k − z₁) / r` mod n. -/
theorem reused_nonce_reveals_key {n : ℕ} [Fact n.Prime]
    (d k r z₁ z₂ s₁ s₂ : ZMod n) (hk : k ≠ 0) (hr : r ≠ 0) (hz : z₁ ≠ z₂)
    (h₁ : s₁ = k⁻¹ * (z₁ + r * d)) (h₂ : s₂ = k⁻¹ * (z₂ + r * d)) :
    k = (z₁ - z₂) / (s₁ - s₂) ∧ d = (s₁ * k - z₁) / r := by
  have hzz : z₁ - z₂ ≠ 0 := sub_ne_zero.mpr hz
  have hss : s₁ - s₂ = k⁻¹ * (z₁ - z₂) := by rw [h₁, h₂]; ring
  constructor
  · rw [hss]; field_simp
  · rw [h₁]; field_simp; ring

/-- Without a hash, anyone holding only the public key can forge. Pick any `a` and any `b ≠ 0`,
make `R = aG + bQ`, and set `r = x(R) mod n`, `s = r b⁻¹`, `z = a s`. If `r ≠ 0`, the
verifier accepts `(r, s)` for the "message" `z`. -/
theorem unhashed_signature_forgery {p n : ℕ} [Fact p.Prime] [Fact n.Prime]
    (W : Affine (ZMod p)) (G Q : W.Point) (a b r : ZMod n) (hb : b ≠ 0)
    (hR : xModN n (a.val • G + b.val • Q) = some r) (hr : r ≠ 0) :
    ecdsaVerify W G Q (a * (r * b⁻¹)) r (r * b⁻¹) := by
  have hs : r * b⁻¹ ≠ 0 := mul_ne_zero hr (inv_ne_zero hb)
  refine ⟨hr, hs, ?_⟩
  have e1 : a * (r * b⁻¹) * (r * b⁻¹)⁻¹ = a := by field_simp
  have e2 : r * (r * b⁻¹)⁻¹ = b := by field_simp
  rw [e1, e2]
  exact hR

-- The toy sizes: p = 1,000,003 and n = 999,007 are prime.
example : Nat.Prime 1000003 := by norm_num
example : Nat.Prime 999007 := by norm_num

-- G = (100, 2), Q = (407658, 775843) and R = (998774, 736591) lie on y² = x³ + 7 mod p.
example : 2 ^ 2 % 1000003 = (100 ^ 3 + 7) % 1000003 := by norm_num
example : 775843 ^ 2 % 1000003 = (407658 ^ 3 + 7) % 1000003 := by norm_num
example : 736591 ^ 2 % 1000003 = (998774 ^ 3 + 7) % 1000003 := by norm_num

-- Signing update 1: r = 998,774 mod n, 1/k = 418,130, z1 + r d = 242,542, s1 = 889,862.
example : 998774 % 999007 = 998774 := by norm_num
example : 90210 * 418130 % 999007 = 1 := by norm_num
example : (744550 + 998774 * 512377) % 999007 = 242542 := by norm_num
example : 418130 * 242542 % 999007 = 889862 := by norm_num

-- The laptop's numbers: w = 962,102, u1 = 69,785, u2 = 606,809.
example : 889862 * 962102 % 999007 = 1 := by norm_num
example : 744550 * 962102 % 999007 = 69785 := by norm_num
example : 998774 * 962102 % 999007 = 606809 := by norm_num

-- Update 2 with the same nonce: s2 = 327,463.
example : 418130 * ((302248 + 998774 * 512377) % 999007) % 999007 = 327463 := by norm_num

-- Nonce reuse: s1 − s2 = 562,399, z1 − z2 = 442,302, k = 90,210 and d = 512,377 come back.
example : 889862 - 327463 = 562399 := by norm_num
example : 744550 - 302248 = 442302 := by norm_num
example : 562399 * 90210 % 999007 = 442302 := by norm_num
example : 889862 * 90210 % 999007 = (744550 + 998774 * 512377) % 999007 := by norm_num

-- The no-hash forgery with a = 1,234 and b = 5,678: s = r / b and z = a s.
example : 874587 * 5678 % 999007 = 840196 := by norm_num
example : 1234 * 874587 % 999007 = 312798 := by norm_num

#print axioms honest_signature_verifies
#print axioms reused_nonce_reveals_key
#print axioms unhashed_signature_forgery
