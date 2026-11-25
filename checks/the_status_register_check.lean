-- The status register: replaying a date-ordered correction log from all-open succeeds exactly when every entry starts from the word its row holds, and then rebuilds every row's status on any date; the card's 64-row register, its 47-entry log, the JAC3 counterexample and its small cases check exactly.
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.Algebra.Field.Rat
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Logic.Function.Iterate
import Mathlib.Tactic.NormNum

/-! ## The register's fields -/

/-- The four status words, and no others. -/
inductive Status
  | «open» | claimed | proved | refuted
  deriving DecidableEq, Repr

/-- One correction-log entry: the date of its source (written YYYYMMDD, with DD = 00 for a
source dated to the month, MMDD = 0000 for one dated to the year), the row it changes, the word it replaces and the new word. -/
structure Entry (R : Type*) where
  date : ℕ
  row : R
  old : Status
  new : Status

section Replay

variable {R : Type*} [DecidableEq R]

/-- Apply one log entry to a state: it succeeds only if the word it replaces is the row's
current word, and then overwrites that row. -/
def applyEntry (S : R → Status) (e : Entry R) : Option (R → Status) :=
  if S e.row = e.old then some (Function.update S e.row e.new) else none

/-- Replay: start every row at open and apply the entries in order; `none` means some entry's
old word did not match. -/
def replay (L : List (Entry R)) : Option (R → Status) :=
  List.foldlM applyEntry (fun _ => Status.open) L

/-- Replay stopped at date `d`: read the log oldest first and stop at the first entry dated
after `d`. -/
def replayTo (log : List (Entry R)) (d : ℕ) : Option (R → Status) :=
  replay (log.takeWhile (fun e => e.date ≤ d))

/-- The last word written for row `r` in the list `L`, or open if `L` has no entry for `r`. -/
def lastWord (L : List (Entry R)) (r : R) : Status :=
  ((L.filter (fun e => e.row = r)).getLast?.map Entry.new).getD Status.open

/-- The card's formula: status(r, d) is the new status of the latest log entry for row `r`
dated on or before `d`, or open if there is none. -/
def statusOn (log : List (Entry R)) (d : ℕ) (r : R) : Status :=
  lastWord (log.filter (fun e => e.date ≤ d)) r

/-- An unbroken history: each entry's old word is the word its row holds just before it. -/
def Consistent (L : List (Entry R)) : Prop :=
  ∀ (i : ℕ) (h : i < L.length), L[i].old = lastWord (L.take i) L[i].row

/-- Ranks of the words, used only by the faulty replay that never moves a row down. -/
def Status.rank : Status → ℕ
  | .open => 0
  | .claimed => 1
  | .proved => 2
  | .refuted => 3

/-- The faulty replay of "What breaks": it skips every entry that would lower a row's rank. -/
def replayUpgradesOnly (L : List (Entry R)) : R → Status :=
  L.foldl (fun S e => if e.new.rank < (S e.row).rank then S else Function.update S e.row e.new)
    (fun _ => Status.open)

theorem lastWord_concat (L : List (Entry R)) (e : Entry R) (r : R) :
    lastWord (L ++ [e]) r = if e.row = r then e.new else lastWord L r := by
  unfold lastWord
  by_cases h : e.row = r
  · simp [List.filter_append, h]
  · simp [List.filter_append, h]

theorem consistent_concat (L : List (Entry R)) (e : Entry R) :
    Consistent (L ++ [e]) ↔ Consistent L ∧ e.old = lastWord L e.row := by
  constructor
  · intro h
    refine ⟨fun i hi => ?_, ?_⟩
    · have := h i (by simp; omega)
      simpa [List.getElem_append_left hi, List.take_append_of_le_length hi.le] using this
    · have := h L.length (by simp)
      simpa using this
  · rintro ⟨h1, h2⟩ i hi
    simp at hi
    rcases Nat.lt_or_ge i L.length with h | h
    · rw [List.getElem_append_left h, List.take_append_of_le_length h.le]; exact h1 i h
    · have : i = L.length := by omega
      subst this
      simpa using h2

theorem replay_concat (L : List (Entry R)) (e : Entry R) :
    replay (L ++ [e]) = (replay L).bind (fun S => applyEntry S e) := by
  unfold replay
  rw [List.foldlM_append]
  cases List.foldlM applyEntry (fun _ => Status.open) L with
  | none => rfl
  | some T =>
    change (applyEntry T e >>= fun b => pure b) = applyEntry T e
    cases applyEntry T e <;> rfl

theorem replay_iff (L : List (Entry R)) (S : R → Status) :
    replay L = some S ↔ Consistent L ∧ ∀ r, S r = lastWord L r := by
  induction L using List.reverseRecOn generalizing S with
  | nil =>
    show some (fun _ => Status.open) = some S ↔ _
    constructor
    · intro h
      cases h
      exact ⟨fun i hi => absurd hi (by simp), fun r => rfl⟩
    · rintro ⟨-, hS⟩
      congr 1
      funext r
      exact (hS r).symm
  | append_singleton L e ih =>
    rw [replay_concat, consistent_concat]
    constructor
    · intro h
      rcases hT : replay L with _ | T
      · rw [hT] at h; simp at h
      · rw [hT] at h
        simp only [Option.bind_some, applyEntry] at h
        split_ifs at h with hold
        obtain ⟨hc, hT'⟩ := (ih T).1 hT
        cases h
        refine ⟨⟨hc, ?_⟩, fun r => ?_⟩
        · rw [← hold, hT']
        · rw [lastWord_concat]
          by_cases h : e.row = r
          · subst h; simp
          · simp [Function.update_of_ne (Ne.symm h), h, hT']
    · rintro ⟨⟨hc, hold⟩, hS⟩
      have : replay L = some (fun r => lastWord L r) := (ih _).2 ⟨hc, fun r => rfl⟩
      rw [this]
      simp only [Option.bind_some, applyEntry, hold, ite_true]
      congr 1
      funext r
      rw [hS r, lastWord_concat]
      by_cases h : e.row = r
      · subst h; simp
      · simp [Function.update_of_ne (Ne.symm h), h]

omit [DecidableEq R] in
theorem takeWhile_eq_filter_of_sorted (log : List (Entry R)) (d : ℕ)
    (hdated : log.Pairwise (fun a b => a.date ≤ b.date)) :
    log.takeWhile (fun e => e.date ≤ d) = log.filter (fun e => e.date ≤ d) := by
  induction log with
  | nil => rfl
  | cons a l ih =>
    rw [List.pairwise_cons] at hdated
    by_cases h : a.date ≤ d
    · simp [h, ih hdated.2]
    · have : l.filter (fun e => e.date ≤ d) = [] := by
        rw [List.filter_eq_nil_iff]
        intro b hb
        have := hdated.1 b hb
        simp
        omega
      simp [h, this]

#print axioms lastWord_concat
#print axioms consistent_concat
#print axioms replay_concat
#print axioms replay_iff
#print axioms takeWhile_eq_filter_of_sorted

/-- The table is a summary of the log. If the log is listed in the order of its sources' dates,
then replaying it from all-open up to any date `d` succeeds exactly when every entry dated on or
before `d` starts from the word its row holds (an unbroken history), and the state it produces
is then, row by row, status(r, d): the new word of the latest entry for `r` dated on or before
`d`, or open if there is none. -/
theorem replay_rebuilds_register (log : List (Entry R)) (d : ℕ)
    (hdated : log.Pairwise (fun a b => a.date ≤ b.date)) (S : R → Status) :
    replayTo log d = some S ↔
      Consistent (log.filter (fun e => e.date ≤ d)) ∧ ∀ r, S r = statusOn log d r := by
  rw [replayTo, takeWhile_eq_filter_of_sorted log d hdated, replay_iff]
  rfl

/-- Replay catches every broken history: if some entry's old word differs from the word its row
holds just before it (for example "open to proved" on a claimed row), replay fails outright. -/
theorem replay_fails_on_broken_history (L : List (Entry R)) (i : ℕ) (hi : i < L.length)
    (hbad : L[i].old ≠ lastWord (L.take i) L[i].row) :
    replay L = none := by
  rcases h : replay L with _ | S
  · rfl
  · exact (hbad (((replay_iff L S).1 h).1 i hi)).elim

end Replay

/-! ## Row JAC3: the 2026 map with Jacobian determinant −2 that sends three points to one -/

open MvPolynomial in
/-- The map of row JAC3, with u = 1 + xy and v = 4 + 3xy:
F(x, y, z) = (u³z + y²uv, y + 3xu²z + 3xy²v, 2x − 3x²y − x³z). -/
noncomputable def jac3Map : Fin 3 → MvPolynomial (Fin 3) ℚ :=
  let x : MvPolynomial (Fin 3) ℚ := X 0
  let y : MvPolynomial (Fin 3) ℚ := X 1
  let z : MvPolynomial (Fin 3) ℚ := X 2
  let u := 1 + x * y
  let v := 4 + 3 * x * y
  ![u ^ 3 * z + y ^ 2 * u * v,
    y + 3 * x * u ^ 2 * z + 3 * x * y ^ 2 * v,
    2 * x - 3 * x ^ 2 * y - x ^ 3 * z]

open MvPolynomial in
/-- The numerals 2, 3 and 4 have partial derivative zero. -/
theorem pderiv_numerals_fin3 (i : Fin 3) :
    pderiv i (2 : MvPolynomial (Fin 3) ℚ) = 0 ∧ pderiv i (3 : MvPolynomial (Fin 3) ℚ) = 0 ∧
      pderiv i (4 : MvPolynomial (Fin 3) ℚ) = 0 :=
  ⟨by simpa using (pderiv i).map_natCast (A := MvPolynomial (Fin 3) ℚ) 2,
   by simpa using (pderiv i).map_natCast (A := MvPolynomial (Fin 3) ℚ) 3,
   by simpa using (pderiv i).map_natCast (A := MvPolynomial (Fin 3) ℚ) 4⟩

#print axioms pderiv_numerals_fin3

open MvPolynomial in
/-- Row JAC3's counterexample, rechecked exactly: the Jacobian determinant of the map, the
determinant of its grid of partial derivatives ∂F_i/∂x_j, is the constant −2, yet the three
different points (0, 0, −1/4), (1, −3/2, 13/2) and (−1, 3/2, 13/2) all map to (−1/4, 0, 0). -/
theorem jac3_det_neg_two_and_three_points_one_image :
    (Matrix.of fun i j => pderiv j (jac3Map i)).det = C (-2) ∧
      (fun i => eval ![0, 0, -1/4] (jac3Map i)) = ![-1/4, 0, 0] ∧
      (fun i => eval ![1, -3/2, 13/2] (jac3Map i)) = ![-1/4, 0, 0] ∧
      (fun i => eval ![-1, 3/2, 13/2] (jac3Map i)) = ![-1/4, 0, 0] := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [Matrix.det_fin_three]
    simp only [Matrix.of_apply, jac3Map, Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
    simp only [map_add, map_sub, Derivation.leibniz, Derivation.leibniz_pow,
      pderiv_X, smul_eq_mul, Derivation.map_one_eq_zero, (pderiv_numerals_fin3 _).1,
      (pderiv_numerals_fin3 _).2.1, (pderiv_numerals_fin3 _).2.2, nsmul_eq_mul, Pi.single_apply]
    simp only [Fin.reduceEq, ite_true, ite_false, map_neg, map_ofNat]
    push_cast
    ring
  all_goals
    funext i
    fin_cases i <;> simp [jac3Map] <;> norm_num

/-! ## The card's register as of 2026-11-25 -/

/-- The register's 64 rows. -/
inductive Row
  | RH | BSD | PNP | NS | HODGE | YM | POINC | TWIN | GOLD | LEG | NSQ | ABC | BEAL | FLT
  | DIST | SCH | UNIT | KAK3 | KAKN | HN | CDC | ER | ES | UC | SP8 | SP24 | SPZ | SPR | S6
  | CARA | RAM | SPC4 | HADW | SOFA | RUP | HSC | COLL | Z23 | JAC3 | JAC2 | SOFIC | KOTHE
  | PERC | HILB6B | HILB6F | IGP | M23 | CH | UGC | GI | LANG | GLANG | H10K | H10Q | AOC
  | AOS | CONN | BQP | ROUGH | OT | GEN | DDES | MF | SGD
  deriving DecidableEq, Repr

/-- A claim's kind. -/
inductive Kind
  | conjecture | «theorem» | model
  deriving DecidableEq, Repr

/-- The claim on record: none, a proof, or a disproof. -/
inductive Claim
  | noClaim | proof | disproof
  deriving DecidableEq, Repr

/-- Who accepted the claim: nobody, only its authors, a published dispute, or someone
independent (refereed, a prize, a formal proof rerun by others). -/
inductive Accept
  | nobody | authors | disputed | independent
  deriving DecidableEq, Repr

/-- The status rule: no claim is open; a claim accepted independently is proved, or refuted for
a disproof; any other claim stays claimed. -/
def rule : Claim → Accept → Status
  | .noClaim, _ => .open
  | .proof, .independent => .proved
  | .disproof, .independent => .refuted
  | _, _ => .claimed

/-- One typed row of the register. -/
structure RegRow where
  row : Row
  kind : Kind
  status : Status
  claim : Claim
  accept : Accept

open Row Kind Status Claim Accept

/-- The register as of 2026-11-25, as typed in the card's checks. -/
def register : List RegRow :=
  [⟨RH, conjecture, proved, proof, independent⟩, ⟨BSD, conjecture, «open», noClaim, nobody⟩,
   ⟨PNP, conjecture, «open», noClaim, nobody⟩, ⟨NS, conjecture, claimed, disproof, authors⟩,
   ⟨HODGE, conjecture, «open», noClaim, nobody⟩, ⟨YM, conjecture, «open», noClaim, nobody⟩,
   ⟨POINC, conjecture, proved, proof, independent⟩, ⟨TWIN, conjecture, «open», noClaim, nobody⟩,
   ⟨GOLD, conjecture, «open», noClaim, nobody⟩, ⟨LEG, conjecture, «open», noClaim, nobody⟩,
   ⟨NSQ, conjecture, «open», noClaim, nobody⟩, ⟨ABC, conjecture, claimed, proof, disputed⟩,
   ⟨BEAL, conjecture, «open», noClaim, nobody⟩, ⟨FLT, conjecture, proved, proof, independent⟩,
   ⟨DIST, conjecture, «open», noClaim, nobody⟩, ⟨SCH, conjecture, «open», noClaim, nobody⟩,
   ⟨UNIT, conjecture, refuted, disproof, independent⟩,
   ⟨KAK3, conjecture, proved, proof, independent⟩, ⟨KAKN, conjecture, «open», noClaim, nobody⟩,
   ⟨HN, conjecture, «open», noClaim, nobody⟩, ⟨CDC, conjecture, claimed, proof, authors⟩,
   ⟨ER, conjecture, «open», noClaim, nobody⟩, ⟨ES, conjecture, claimed, proof, authors⟩,
   ⟨UC, conjecture, «open», noClaim, nobody⟩, ⟨SP8, conjecture, proved, proof, independent⟩,
   ⟨SP24, conjecture, proved, proof, independent⟩, ⟨SPZ, conjecture, «open», noClaim, nobody⟩,
   ⟨SPR, conjecture, claimed, disproof, authors⟩, ⟨S6, «theorem», claimed, proof, authors⟩,
   ⟨CARA, conjecture, «open», noClaim, nobody⟩, ⟨RAM, conjecture, «open», noClaim, nobody⟩,
   ⟨SPC4, conjecture, «open», noClaim, nobody⟩, ⟨HADW, conjecture, «open», noClaim, nobody⟩,
   ⟨SOFA, «theorem», claimed, proof, authors⟩, ⟨RUP, conjecture, refuted, disproof, independent⟩,
   ⟨HSC, conjecture, «open», noClaim, nobody⟩, ⟨COLL, conjecture, «open», noClaim, nobody⟩,
   ⟨Z23, «theorem», claimed, proof, authors⟩, ⟨JAC3, conjecture, refuted, disproof, independent⟩,
   ⟨JAC2, conjecture, «open», noClaim, nobody⟩, ⟨SOFIC, conjecture, claimed, disproof, authors⟩,
   ⟨KOTHE, conjecture, claimed, disproof, authors⟩, ⟨PERC, conjecture, claimed, proof, authors⟩,
   ⟨HILB6B, «theorem», proved, proof, independent⟩, ⟨HILB6F, «theorem», claimed, proof, authors⟩,
   ⟨IGP, conjecture, «open», noClaim, nobody⟩, ⟨M23, conjecture, claimed, proof, authors⟩,
   ⟨CH, «theorem», proved, proof, independent⟩, ⟨UGC, conjecture, «open», noClaim, nobody⟩,
   ⟨GI, «theorem», proved, proof, independent⟩, ⟨LANG, conjecture, «open», noClaim, nobody⟩,
   ⟨GLANG, «theorem», proved, proof, independent⟩, ⟨H10K, «theorem», proved, proof, independent⟩,
   ⟨H10Q, conjecture, «open», noClaim, nobody⟩, ⟨AOC, «theorem», proved, proof, independent⟩,
   ⟨AOS, «theorem», claimed, proof, authors⟩, ⟨CONN, conjecture, refuted, disproof, independent⟩,
   ⟨BQP, conjecture, «open», noClaim, nobody⟩, ⟨ROUGH, model, «open», noClaim, nobody⟩,
   ⟨OT, «theorem», proved, proof, independent⟩, ⟨GEN, conjecture, «open», noClaim, nobody⟩,
   ⟨DDES, conjecture, «open», noClaim, nobody⟩, ⟨MF, «theorem», proved, proof, independent⟩,
   ⟨SGD, conjecture, «open», noClaim, nobody⟩]

/-- The correction log, oldest first; dates YYYYMMDD, DD = 00 for a month-precision source,
MMDD = 0000 for a year. -/
def cardLog : List (Entry Row) :=
  [⟨19631200, CH, «open», proved⟩, ⟨19910600, OT, «open», proved⟩, ⟨19930600, FLT, «open», claimed⟩,
   ⟨19950500, FLT, claimed, proved⟩, ⟨20021111, POINC, «open», claimed⟩,
   ⟨20060725, POINC, claimed, proved⟩, ⟨20110000, AOC, «open», proved⟩,
   ⟨20120800, ABC, «open», claimed⟩, ⟨20151211, GI, «open», claimed⟩,
   ⟨20160314, SP8, «open», claimed⟩, ⟨20160321, SP24, «open», claimed⟩,
   ⟨20160619, GI, claimed, proved⟩, ⟨20170104, GI, proved, «open»⟩, ⟨20170109, GI, «open», claimed⟩,
   ⟨20170116, GI, claimed, proved⟩, ⟨20170501, SP8, claimed, proved⟩,
   ⟨20170501, SP24, claimed, proved⟩, ⟨20180418, MF, «open», claimed⟩,
   ⟨20180727, MF, claimed, proved⟩, ⟨20200100, CONN, «open», claimed⟩,
   ⟨20210918, AOS, «open», claimed⟩, ⟨20240506, GLANG, «open», claimed⟩,
   ⟨20240814, HILB6B, «open», claimed⟩, ⟨20241129, SOFA, «open», claimed⟩,
   ⟨20241202, H10K, «open», claimed⟩, ⟨20250000, GLANG, claimed, proved⟩,
   ⟨20250224, KAK3, «open», claimed⟩, ⟨20250303, HILB6F, «open», claimed⟩,
   ⟨20250825, RUP, «open», claimed⟩, ⟨20251031, HILB6B, claimed, proved⟩,
   ⟨20251201, H10K, claimed, proved⟩, ⟨20260520, UNIT, «open», refuted⟩,
   ⟨20260527, SPR, «open», claimed⟩, ⟨20260710, CDC, «open», claimed⟩,
   ⟨20260713, RUP, claimed, refuted⟩, ⟨20260720, JAC3, «open», refuted⟩,
   ⟨20260723, KAK3, claimed, proved⟩, ⟨20260801, SOFIC, «open», claimed⟩,
   ⟨20260809, M23, «open», claimed⟩, ⟨20260810, Z23, «open», claimed⟩,
   ⟨20260828, PERC, «open», claimed⟩, ⟨20260907, KOTHE, «open», claimed⟩,
   ⟨20260908, NS, «open», claimed⟩, ⟨20260929, S6, «open», claimed⟩,
   ⟨20261016, CONN, claimed, refuted⟩, ⟨20261019, ES, «open», claimed⟩,
   ⟨20261121, RH, «open», proved⟩]

/-- All 64 rows, in register order. -/
def allRows : List Row := register.map RegRow.row

/-- How many rows of a state hold each word: (open, claimed, proved, refuted). -/
def tally (S : Row → Status) : ℕ × ℕ × ℕ × ℕ :=
  ((allRows.filter (fun r => S r = «open»)).length, (allRows.filter (fun r => S r = claimed)).length,
   (allRows.filter (fun r => S r = proved)).length, (allRows.filter (fun r => S r = refuted)).length)

-- 64 rows, 47 log entries; kinds: conjecture 50, theorem 13, model 1.
example : register.length = 64 ∧ cardLog.length = 47 := by decide
example : ((register.filter (·.kind = conjecture)).length, (register.filter (·.kind = «theorem»)).length,
    (register.filter (·.kind = model)).length) = (50, 13, 1) := by decide
-- The log is listed in date order, so the main theorem applies to it.
example : cardLog.Pairwise (fun a b => a.date ≤ b.date) := by decide
-- Road 1 = road 2: the status rule applied to each row's evidence gives the status typed in it.
example : ∀ x ∈ register, rule x.claim x.accept = x.status := by decide
-- Road 3 = road 2: the log replayed from all-open to 2026-11-25 gives every typed status.
example : ∀ x ∈ register, (replayTo cardLog 20261125).map (· x.row) = some x.status := by decide
-- The register as of 2026-11-25: 32 open, 14 claimed, 14 proved, 4 refuted.
example : (replayTo cardLog 20261125).map tally = some (32, 14, 14, 4) := by decide
example : 32 + 14 + 14 + 4 = 64 ∧ 14 + 4 = 18 := by norm_num
-- Between the 2026-09-13 snapshot and 2026-11-25 exactly four rows changed: RH, ES, S6, CONN.
example : (do
    let a ← replayTo cardLog 20260913
    let b ← replayTo cardLog 20261125
    pure (allRows.filter (fun r => a r ≠ b r))) = some [RH, ES, S6, CONN] := by decide
-- The snapshot's age: 17 days left in September, then 31 and 25.
example : (30 - 13) + 31 + 25 = 73 := by norm_num
-- The chart: rows claimed, and rows proved or refuted, at the end of 1995, 2000, …, 2025,
-- then on 2026-11-25.
example : [19951231, 20001231, 20051231, 20101231, 20151231, 20201231, 20251231, 20261125].map
    (fun d => (replayTo cardLog d).map (fun S => let t := tally S; (t.2.1, t.2.2.1 + t.2.2.2))) =
    [some (0, 3), some (0, 3), some (1, 3), some (0, 4), some (2, 5), some (2, 9), some (7, 12),
     some (14, 18)] := by decide
-- What breaks: counting every claim as accepted settles 32 rows, not 18.
example : (register.filter (fun x =>
    rule x.claim (if x.accept = authors ∨ x.accept = disputed then independent else x.accept) = proved ∨
    rule x.claim (if x.accept = authors ∨ x.accept = disputed then independent else x.accept) = refuted)).length
    = 32 := by decide
-- What breaks: counting abc's journal and ignoring the dispute gives 15 proved rows, not 14.
example : (register.filter (fun x =>
    rule x.claim (if x.accept = disputed then independent else x.accept) = proved)).length = 15 := by
  decide
-- What breaks: on 2017-01-05 GI is open; a replay that never moves a row down says proved.
example : (replayTo cardLog 20170105).map (· GI) = some «open» ∧
    replayUpgradesOnly (cardLog.takeWhile (fun e => e.date ≤ 20170105)) GI = proved := by decide
-- What breaks: one 365-day period puts claimed rows 335 days late.
example : 365 - 30 = 335 := by norm_num

/-- One step of the Collatz map. -/
def collatzStep (n : ℕ) : ℕ := if n % 2 = 0 then n / 2 else 3 * n + 1

-- COLL's small case: 27 first reaches 1 after 111 steps, and its peak on the way is 9232.
example : collatzStep^[111] 27 = 1 ∧ ∀ k < 111, collatzStep^[k] 27 ≠ 1 := by decide +kernel
example : (∀ k ≤ 111, collatzStep^[k] 27 ≤ 9232) ∧ ∃ k ≤ 111, collatzStep^[k] 27 = 9232 := by
  decide +kernel

#print axioms replay_rebuilds_register
#print axioms replay_fails_on_broken_history
#print axioms jac3_det_neg_two_and_three_points_one_image
