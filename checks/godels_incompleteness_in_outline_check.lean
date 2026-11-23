-- Godel's theorems: a consistent system whose theorems a program can list, and which proves the checkable facts about programs, leaves some sentence unsettled; and the card's base-16 numbering, numerals and self-naming sentence G work as stated.
import Mathlib.Computability.Halting
import Mathlib.Data.Nat.Digits.Lemmas

open Nat.Partrec

namespace GodelCard

/-! ## The card's numbering

Eleven symbols `0 S + * = ( ) ~ x P D` get the codes 1 to 11, and a string is read as a number in
base 16, first symbol first (most significant). -/

/-- The card's eleven symbols. -/
def alphabet : List Char := ['0', 'S', '+', '*', '=', '(', ')', '~', 'x', 'P', 'D']

/-- The code of one symbol: 1 to 11 in the order of `alphabet`, and 0 for anything else. -/
def symCode : Char → ℕ
  | '0' => 1 | 'S' => 2 | '+' => 3 | '*' => 4 | '=' => 5 | '(' => 6
  | ')' => 7 | '~' => 8 | 'x' => 9 | 'P' => 10 | 'D' => 11 | _ => 0

/-- The symbol with a given code (a filler `'?'` for codes that name no symbol). -/
def symOf : ℕ → Char
  | 1 => '0' | 2 => 'S' | 3 => '+' | 4 => '*' | 5 => '=' | 6 => '('
  | 7 => ')' | 8 => '~' | 9 => 'x' | 10 => 'P' | 11 => 'D' | _ => '?'

/-- The code number `⌜s⌝` of a string: its symbol codes read as base-16 digits, first symbol
most significant. -/
def godelCode (s : List Char) : ℕ := Nat.ofDigits 16 (s.reverse.map symCode)

/-- Decoding by division: the base-16 digits of `n`, most significant first, read as symbols. -/
def decode (n : ℕ) : List Char := (Nat.digits 16 n).reverse.map symOf

/-- Terms built from zero, next, plus and times. -/
inductive Tm
  | zero
  | succ (t : Tm)
  | add (a b : Tm)
  | mul (a b : Tm)

/-- The number a term stands for. -/
def Tm.val : Tm → ℕ
  | .zero => 0
  | .succ t => t.val + 1
  | .add a b => a.val + b.val
  | .mul a b => a.val * b.val

/-- A term written out in the card's symbols: `0`, `St`, `(a+b)`, `(a*b)`. -/
def Tm.toChars : Tm → List Char
  | .zero => ['0']
  | .succ t => 'S' :: t.toChars
  | .add a b => ['('] ++ a.toChars ++ ['+'] ++ b.toChars ++ [')']
  | .mul a b => ['('] ++ a.toChars ++ ['*'] ++ b.toChars ++ [')']

/-- The card's numeral of `n`, built from the binary digits of `n`: `S0` for the leading 1, then
for each later digit `(SS0*t)`, with an extra `S` in front on a 1 digit. -/
def numeralTm (n : ℕ) : Tm :=
  match (Nat.digits 2 n).reverse with
  | [] => .zero
  | _ :: rest =>
      rest.foldl
        (fun t b => if b = 1 then .succ (.mul (.succ (.succ .zero)) t)
          else .mul (.succ (.succ .zero)) t)
        (.succ .zero)

/-- The numeral of `n` as a string of symbols. -/
def numeral (n : ℕ) : List Char := (numeralTm n).toChars

/-- Put the term `t` into every gap `x` of the string `s`. -/
def subst (s t : List Char) : List Char := s.flatMap fun c => if c = 'x' then t else [c]

/-- The diagonal map `D(n)`: decode `n`, put the numeral of `n` in place of `x`, re-encode. -/
def diag (n : ℕ) : ℕ := godelCode (subst (decode n) (numeral n))

/-- The template X = `~P(D(x))`: "the sentence numbered D(x) has no proof". -/
def X : List Char := "~P(D(x))".toList

/-- The sentence G: the numeral of X's own code put in place of `x`. -/
def G : List Char := subst X (numeral (godelCode X))

/-- The broken attempt H: `~P(x)` filled with its own code, without D. -/
def H : List Char := subst "~P(x)".toList (numeral (godelCode "~P(x)".toList))

/-! ## Helper lemmas -/

theorem symOf_symCode (c : Char) (hc : c ∈ alphabet) : symOf (symCode c) = c := by
  simp only [alphabet, List.mem_cons, List.not_mem_nil, or_false] at hc
  rcases hc with h|h|h|h|h|h|h|h|h|h|h <;> subst h <;> rfl

#print axioms symOf_symCode

theorem symCode_pos (c : Char) (hc : c ∈ alphabet) : 0 < symCode c ∧ symCode c < 16 := by
  simp only [alphabet, List.mem_cons, List.not_mem_nil, or_false] at hc
  rcases hc with h|h|h|h|h|h|h|h|h|h|h <;> subst h <;> decide

#print axioms symCode_pos

theorem digits_godelCode (s : List Char) (hs : ∀ c ∈ s, c ∈ alphabet) :
    Nat.digits 16 (godelCode s) = s.reverse.map symCode := by
  unfold godelCode
  apply Nat.digits_ofDigits 16 (by norm_num)
  · intro l hl
    obtain ⟨c, hc, rfl⟩ := List.mem_map.mp hl
    exact (symCode_pos c (hs c (List.mem_reverse.mp hc))).2
  · intro h
    obtain ⟨c, hc, he⟩ := List.mem_map.mp (List.getLast_mem h)
    rw [← he]
    exact (symCode_pos c (hs c (List.mem_reverse.mp hc))).1.ne'

#print axioms digits_godelCode

theorem foldl_length (rest : List ℕ) (t : Tm) :
    t.toChars.length + 6 * rest.length ≤
      (rest.foldl
        (fun t b => if b = 1 then Tm.succ (.mul (.succ (.succ .zero)) t)
          else Tm.mul (.succ (.succ .zero)) t) t).toChars.length := by
  induction rest generalizing t with
  | nil => simp
  | cons b rest ih =>
    rw [List.foldl_cons]
    refine le_trans ?_ (ih _)
    split_ifs <;> simp [Tm.toChars] <;> omega

#print axioms foldl_length

theorem numeral_length_ge (n k : ℕ) (hk : 2 ^ k ≤ n) : 2 + 6 * k ≤ (numeral n).length := by
  have hlen : k < (Nat.digits 2 n).length := (Nat.lt_digits_length_iff (by norm_num) n).2 hk
  unfold numeral numeralTm
  split
  · next heq =>
    rw [List.reverse_eq_nil_iff] at heq
    rw [heq] at hlen
    simp at hlen
  · next d rest heq =>
    have := congrArg List.length heq
    simp only [List.length_reverse, List.length_cons] at this
    have h2 := foldl_length rest (.succ .zero)
    simp only [Tm.toChars, List.length_cons, List.length_nil] at h2
    omega

#print axioms numeral_length_ge

/-! ## The theorems -/

/-- **Godel's first theorem, in Rosser's form, for a system described by a program.**
Sentences are coded by numbers, `neg` turns a sentence into its negation, and `Prov φ` says the
system proves `φ`. Suppose a program can list the theorems (`Prov` is semidecidable), the system is
consistent (it never proves a sentence and its negation), and it proves the checkable facts that
plus and times let it state: for each program `c` there is a sentence `σ c` that the system proves
when `c`, run on its own code, stops with answer 0, and refutes when that run stops with answer 1.
Then some sentence is left unsettled: the system proves neither it nor its negation. -/
theorem consistent_listable_system_leaves_a_sentence_unsettled
    (Prov : ℕ → Prop) (listable : REPred Prov)
    (neg : ℕ → ℕ) (hneg : Computable neg)
    (σ : Code → ℕ) (hσ : Computable σ)
    (consistent : ∀ φ, ¬ (Prov φ ∧ Prov (neg φ)))
    (proves_zero : ∀ c : Code, c.eval (Encodable.encode c) = Part.some 0 → Prov (σ c))
    (refutes_one : ∀ c : Code, c.eval (Encodable.encode c) = Part.some 1 → Prov (neg (σ c))) :
    ∃ φ, ¬ Prov φ ∧ ¬ Prov (neg φ) := by
  by_contra hcon
  push Not at hcon
  have h1 : REPred fun c => Prov (σ c) := Partrec.comp listable hσ
  have h2' : REPred fun c => Prov (neg (σ c)) := Partrec.comp listable (hneg.comp hσ)
  have h2 : REPred fun c => ¬ Prov (σ c) := by
    refine h2'.of_eq ?_
    intro c
    exact ⟨fun h hp => consistent _ ⟨hp, h⟩, fun h => hcon _ h⟩
  obtain ⟨D, hd⟩ : ComputablePred fun c => Prov (σ c) :=
    ComputablePred.computable_iff_re_compl_re'.2 ⟨h1, h2⟩
  let g : ℕ → ℕ := fun n => cond (decide (Prov (σ (Denumerable.ofNat Code n)))) 1 0
  have hg : Computable g :=
    Computable.cond (hd.comp (Computable.ofNat Code)) (Computable.const 1) (Computable.const 0)
  obtain ⟨c0, hc0⟩ := Nat.Partrec.Code.exists_code.1 (Partrec.nat_iff.1 hg)
  have hev : c0.eval (Encodable.encode c0) = Part.some (cond (decide (Prov (σ c0))) 1 0) := by
    rw [hc0]
    simp [g, Denumerable.ofNat_encode]
  by_cases hp : Prov (σ c0)
  · rw [decide_eq_true hp] at hev
    exact consistent _ ⟨hp, refutes_one c0 hev⟩
  · rw [decide_eq_false hp] at hev
    exact hp (proves_zero c0 hev)

/-- **Numbering is reversible.** Dividing the code of a string of the card's symbols by 16 again
and again spells the string back, so no two such strings share a code. -/
theorem decode_godelCode (s : List Char) (hs : ∀ c ∈ s, c ∈ alphabet) :
    decode (godelCode s) = s := by
  unfold decode
  rw [digits_godelCode s hs, ← List.map_reverse, List.reverse_reverse, List.map_map]
  conv_rhs => rw [← List.map_id s]
  apply List.map_congr_left
  intro c hc
  exact symOf_symCode c (hs c hc)

/-- **A sentence cannot contain its own numeral.** For every nonempty string of the card's
symbols, the numeral of its code is longer than the string itself, so it never fits inside it. -/
theorem numeral_longer_than_sentence (s : List Char) (hs : ∀ c ∈ s, c ∈ alphabet)
    (hne : s ≠ []) :
    s.length < (numeral (godelCode s)).length ∧ ¬ numeral (godelCode s) <:+: s := by
  have hk : 0 < s.length := List.length_pos_iff.mpr hne
  have hd : (Nat.digits 16 (godelCode s)).length = s.length := by
    rw [digits_godelCode s hs]; simp
  have h16 : 16 ^ (s.length - 1) ≤ godelCode s :=
    (Nat.lt_digits_length_iff (by norm_num) _).1 (by omega)
  have h2 : 2 ^ (4 * (s.length - 1)) ≤ godelCode s := by
    rw [pow_mul]; norm_num; exact h16
  have hl := numeral_length_ge _ _ h2
  have hlt : s.length < (numeral (godelCode s)).length := by omega
  refine ⟨hlt, fun hinf => ?_⟩
  have := hinf.length_le
  omega

/-! ## The card's worked numbers -/

set_option maxRecDepth 100000

-- The code of S0+S0=SS0 (1 + 1 = 2) is 8,910,885,409, and dividing by 16 spells it back.
example : godelCode "S0+S0=SS0".toList = 8910885409 := by decide
example : decode 8910885409 = "S0+S0=SS0".toList := by decide

-- The template X = ~P(D(x)) has code 2,322,295,159; its numeral has 205 symbols and the value
-- 2,322,295,159.
example : godelCode X = 2322295159 := by decide
example : (numeral 2322295159).length = 205 := by decide
example : (numeralTm 2322295159).val = 2322295159 := by decide

-- G has 8 − 1 + 205 = 212 symbols, and its code has 256 decimal digits, starting 101483056656.
example : G.length = 212 := by decide
example : (Nat.digits 10 (godelCode G)).length = 256 := by decide
example : godelCode G / 10 ^ 244 = 101483056656 := by decide

-- The diagonal map sends X's code to the code of G itself.
example : diag 2322295159 = godelCode G := by decide

-- What breaks: ~P(x) has code 566,935, and H, filled with that code without D, has a 156-digit
-- code, so H points at the template, not at itself.
example : godelCode "~P(x)".toList = 566935 := by decide
example : (Nat.digits 10 (godelCode H)).length = 156 := by decide
example : godelCode H ≠ 566935 := by decide

-- The smallest 8-symbol code, 0000 0000 in symbols, already needs a 177-symbol numeral.
example : godelCode (List.replicate 8 '0') = 286331153 := by decide
example : (numeral 286331153).length = 177 := by decide

#print axioms consistent_listable_system_leaves_a_sentence_unsettled
#print axioms decode_godelCode
#print axioms numeral_longer_than_sentence

end GodelCard
