-- The one-time pad: with a uniformly random key as long as the message, added bit by bit mod 2, seeing the ciphertext leaves the odds of every message unchanged, and no cipher is perfectly secret with fewer keys than messages.
import Mathlib.Data.ZMod.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Abel
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

open Finset

/-- Exactly one key k turns m into c (namely k = c - m), so summing a times the indicator over all keys gives a. -/
theorem otp_sum_indicator (n : ℕ) (a : ℝ) (m c : Fin n → ZMod 2) :
    ∑ k : Fin n → ZMod 2, a * (if m + k = c then 1 else 0) = a := by
  have h : ∀ k : Fin n → ZMod 2, (m + k = c) ↔ (c - m = k) := by
    intro k; constructor <;> intro h <;> [rw [← h]; rw [← h]] <;> abel
  simp only [h, mul_ite, mul_one, mul_zero]
  rw [Finset.sum_ite_eq]; simp

#print axioms otp_sum_indicator

/-- Perfect secrecy of the one-time pad. Messages, keys and ciphertexts are strings of `n` bits,
and XOR is addition mod 2 in each bit, so c = m + k. The message M has any prior p (chances 0 or
more, adding to 1). The key K is chosen uniformly, each of the 2^n keys with chance 1/2^n,
independently of the message. Then for every message m and every ciphertext c, the eavesdropper's
odds after seeing c equal the odds before:
P(M = m | C = c) = P(M = m ∧ C = c) / P(C = c) = P(M = m). -/
theorem one_time_pad_perfect_secrecy (n : ℕ) (p : (Fin n → ZMod 2) → ℝ)
    (hp_nonneg : ∀ m, 0 ≤ p m) (hp_sum : ∑ m, p m = 1)
    (m c : Fin n → ZMod 2) :
    (∑ k : Fin n → ZMod 2, p m * (1 / 2 ^ n) * (if m + k = c then 1 else 0)) /
      (∑ m' : Fin n → ZMod 2, ∑ k : Fin n → ZMod 2,
        p m' * (1 / 2 ^ n) * (if m' + k = c then 1 else 0)) = p m := by
  simp only [otp_sum_indicator]
  rw [← Finset.sum_mul, hp_sum]
  field_simp

/-- Unlocking works and the ciphertext is uniform whatever was sent. Adding the same pad twice
gives the message back, (m ⊕ k) ⊕ k = m. And for a uniformly random key, whatever message m was
sent, every ciphertext c has the same chance: P(C = c | M = m) = P(K = m ⊕ c) = 1/2^n. -/
theorem one_time_pad_decrypts_and_ciphertext_uniform (n : ℕ) (m k c : Fin n → ZMod 2) :
    (m + k) + k = m ∧
      ∑ k' : Fin n → ZMod 2, (1 / 2 ^ n : ℝ) * (if m + k' = c then 1 else 0) = 1 / 2 ^ n := by
  refine ⟨?_, otp_sum_indicator n _ m c⟩
  have h2 : ∀ x : ZMod 2, x + x = 0 := by decide
  funext i
  simp only [Pi.add_apply, add_assoc, h2, add_zero]

/-- Shannon's bound: perfect secrecy needs at least as many keys as messages. Take any cipher:
finitely many messages, keys and ciphertexts, an encryption rule `enc k m`, and decryption that
works (for each key, different messages give different ciphertexts). Every message is possible
(chance above zero), and the key is drawn from any distribution q, independently of the message.
If the cipher is perfectly secret, P(M = m | C = c) = P(M = m) for every message m and every
ciphertext c that can occur, then the number of keys is at least the number of messages. -/
theorem perfect_secrecy_needs_as_many_keys_as_messages
    {Msg Key Ciph : Type*} [Fintype Msg] [Fintype Key] [Fintype Ciph] [DecidableEq Ciph]
    (enc : Key → Msg → Ciph) (hdec : ∀ k, Function.Injective (enc k))
    (p : Msg → ℝ) (hp_pos : ∀ m, 0 < p m) (hp_sum : ∑ m, p m = 1)
    (q : Key → ℝ) (hq_nonneg : ∀ k, 0 ≤ q k) (hq_sum : ∑ k, q k = 1)
    (hsecret : ∀ m c,
      (∑ m', ∑ k, p m' * q k * (if enc k m' = c then 1 else 0)) ≠ 0 →
        (∑ k, p m * q k * (if enc k m = c then 1 else 0)) /
          (∑ m', ∑ k, p m' * q k * (if enc k m' = c then 1 else 0)) = p m) :
    Fintype.card Msg ≤ Fintype.card Key := by
  obtain ⟨m0, -, -⟩ := Finset.exists_ne_zero_of_sum_ne_zero (s := Finset.univ) (f := p)
    (by rw [hp_sum]; norm_num)
  obtain ⟨k0, -, hk0⟩ := Finset.exists_ne_zero_of_sum_ne_zero (s := Finset.univ) (f := q)
    (by rw [hq_sum]; norm_num)
  set c := enc k0 m0 with hc
  have hterm : ∀ m' k, 0 ≤ p m' * q k * (if enc k m' = c then (1 : ℝ) else 0) := by
    intro m' k
    have := (hp_pos m').le
    have := hq_nonneg k
    split_ifs <;> positivity
  have hpos : 0 < ∑ m', ∑ k, p m' * q k * (if enc k m' = c then (1 : ℝ) else 0) := by
    have h1 : p m0 * q k0 * (if enc k0 m0 = c then (1 : ℝ) else 0)
        ≤ ∑ k, p m0 * q k * (if enc k m0 = c then (1 : ℝ) else 0) :=
      Finset.single_le_sum (f := fun k => p m0 * q k * (if enc k m0 = c then (1 : ℝ) else 0))
        (fun k _ => hterm m0 k) (Finset.mem_univ k0)
    have h2 : ∑ k, p m0 * q k * (if enc k m0 = c then (1 : ℝ) else 0)
        ≤ ∑ m', ∑ k, p m' * q k * (if enc k m' = c then (1 : ℝ) else 0) :=
      Finset.single_le_sum
        (f := fun m' => ∑ k, p m' * q k * (if enc k m' = c then (1 : ℝ) else 0))
        (fun m' _ => Finset.sum_nonneg (fun k _ => hterm m' k)) (Finset.mem_univ m0)
    have h0 : 0 < p m0 * q k0 * (if enc k0 m0 = c then (1 : ℝ) else 0) := by
      simp only [c, ite_true, mul_one]
      exact mul_pos (hp_pos m0) (lt_of_le_of_ne (hq_nonneg k0) (Ne.symm hk0))
    linarith
  have hex : ∀ m, ∃ k, enc k m = c := by
    intro m
    have hs := hsecret m c hpos.ne'
    have hnum : (∑ k, p m * q k * (if enc k m = c then (1 : ℝ) else 0)) ≠ 0 := by
      intro h0
      rw [h0, zero_div] at hs
      exact (hp_pos m).ne' hs.symm
    obtain ⟨k, -, hk⟩ := Finset.exists_ne_zero_of_sum_ne_zero hnum
    refine ⟨k, ?_⟩
    by_contra hne
    exact hk (by simp [hne])
  choose f hf using hex
  apply Fintype.card_le_of_injective f
  intro m1 m2 h
  apply hdec (f m1)
  rw [hf m1, h, hf m2]

-- Character 10 of the order, bit by bit: '7' = 0x37, pad byte 0x42, ciphertext byte 0x75.
example : (0x37 : ℕ) ^^^ 0x42 = 0x75 := by decide
-- Unlocking at the bank: 0x75 ⊕ 0x42 = 0x37 = '7'.
example : (0x75 : ℕ) ^^^ 0x42 = 0x37 := by decide
-- The key that would make that byte a '9' (0x39) is 0x4C.
example : (0x75 : ℕ) ^^^ 0x39 = 0x4C := by decide
-- Keys of 20 bytes: 256^20 = 2^160.
example : (256 : ℕ) ^ 20 = 2 ^ 160 := by norm_num

-- The card's 20-byte example, written as byte values.
-- m  = "TRANSFER 750 TO BOB.", m2 = "TRANSFER 200 TO ANN.", alt = "TRANSFER 950 TO EVE."
-- k  = the pad, kalt = the pad that turns the same c into alt.
def otpM : List ℕ := [0x54, 0x52, 0x41, 0x4E, 0x53, 0x46, 0x45, 0x52, 0x20, 0x37,
  0x35, 0x30, 0x20, 0x54, 0x4F, 0x20, 0x42, 0x4F, 0x42, 0x2E]
def otpM2 : List ℕ := [0x54, 0x52, 0x41, 0x4E, 0x53, 0x46, 0x45, 0x52, 0x20, 0x32,
  0x30, 0x30, 0x20, 0x54, 0x4F, 0x20, 0x41, 0x4E, 0x4E, 0x2E]
def otpAlt : List ℕ := [0x54, 0x52, 0x41, 0x4E, 0x53, 0x46, 0x45, 0x52, 0x20, 0x39,
  0x35, 0x30, 0x20, 0x54, 0x4F, 0x20, 0x45, 0x56, 0x45, 0x2E]
def otpK : List ℕ := [0x23, 0x5D, 0x8E, 0xF2, 0x49, 0x03, 0xAE, 0x2D, 0xF4, 0x42,
  0x6D, 0xE0, 0x18, 0x65, 0x39, 0x49, 0xA9, 0x43, 0xC3, 0x19]
def otpKAlt : List ℕ := [0x23, 0x5D, 0x8E, 0xF2, 0x49, 0x03, 0xAE, 0x2D, 0xF4, 0x4C,
  0x6D, 0xE0, 0x18, 0x65, 0x39, 0x49, 0xAE, 0x5A, 0xC4, 0x19]
def otpXor (a b : List ℕ) : List ℕ := List.zipWith (· ^^^ ·) a b

-- c = m ⊕ k begins 77 0F CF BC 1A, and c ⊕ k gives the order back.
example : (otpXor otpM otpK).take 5 = [0x77, 0x0F, 0xCF, 0xBC, 0x1A] := by decide
example : otpXor (otpXor otpM otpK) otpK = otpM := by decide
-- The same c, under a different pad, spells "TRANSFER 950 TO EVE.".
example : otpXor otpAlt otpKAlt = otpXor otpM otpK ∧ otpKAlt ≠ otpK := by decide
-- Pad reused for "TRANSFER 200 TO ANN.": c ⊕ c2 = m ⊕ m2, 15 of its 20 bytes are 00,
-- and XORing on the known order m recovers m2.
example : otpXor (otpXor otpM otpK) (otpXor otpM2 otpK) = otpXor otpM otpM2 := by decide
example : (otpXor (otpXor otpM otpK) (otpXor otpM2 otpK)).count 0 = 15 := by decide
example : otpXor (otpXor (otpXor otpM2 otpK) (otpXor otpM otpK)) otpM = otpM2 := by decide
-- Tampering: flip c's byte 10 by 0x0E and the bank reads '9' (0x39), "TRANSFER 950 TO BOB.".
example : ((0x37 ^^^ 0x42 : ℕ) ^^^ 0x0E) ^^^ 0x42 = 0x39 := by decide

-- The toy, in 32nds: 4 messages coded 0..3 with prior 4/8, 2/8, 1/8, 1/8, and 4 two-bit keys,
-- each with chance 1/4. Joint chance (in 32nds) of (m, c) is prior8 m when m ⊕ k = c for
-- some key; posterior equals prior in all 16 cells: joint(m, c) * 8 = prior8 m * P(C = c).
def toyPrior8 : Fin 4 → ℕ := ![4, 2, 1, 1]
def toyJoint (keys : List ℕ) (m c : Fin 4) : ℕ :=
  toyPrior8 m * (keys.filter (fun k => m.val ^^^ k = c.val)).length
example : ∀ m c : Fin 4,
    toyJoint [0, 1, 2, 3] m c * 8 = toyPrior8 m * (∑ m' : Fin 4, toyJoint [0, 1, 2, 3] m' c) := by
  decide
-- With 3 keys for 4 messages, 4 of the 16 cells are impossible; with 1 key, 12 are.
example : ((Finset.univ : Finset (Fin 4 × Fin 4)).filter (fun x =>
    toyJoint [0, 1, 2] x.1 x.2 = 0 ∧ (∑ m' : Fin 4, toyJoint [0, 1, 2] m' x.2) ≠ 0)).card = 4 := by
  decide
example : ((Finset.univ : Finset (Fin 4 × Fin 4)).filter (fun x =>
    toyJoint [0] x.1 x.2 = 0 ∧ (∑ m' : Fin 4, toyJoint [0] m' x.2) ≠ 0)).card = 12 := by
  decide

#print axioms one_time_pad_perfect_secrecy
#print axioms one_time_pad_decrypts_and_ciphertext_uniform
#print axioms perfect_secrecy_needs_as_many_keys_as_messages
