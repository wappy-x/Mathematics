-- Proof by contradiction: 31 dominoes cannot cover a chessboard with two opposite corners cut off, because every domino covers one dark square and one light, and no fraction squares to 2.
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Finset.Card
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.Ring.Int.Defs
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Group.Int.Even
import Mathlib.Tactic

/-- The squares of the chessboard: row r and column c, each from 1 to 8. -/
def board : Finset (ℕ × ℕ) := Finset.Icc 1 8 ×ˢ Finset.Icc 1 8

/-- The clipped board: the chessboard with the corners row 1 column 1 and row 8 column 8 cut off. -/
def clippedBoard : Finset (ℕ × ℕ) := (board.erase (1, 1)).erase (8, 8)

/-- A square is dark when its row number plus its column number is even. -/
abbrev IsDark (s : ℕ × ℕ) : Prop := (s.1 + s.2) % 2 = 0

/-- Two squares share an edge: same row and neighbouring columns, or same column and
neighbouring rows. -/
abbrev Adjacent (a b : ℕ × ℕ) : Prop :=
  (a.1 = b.1 ∧ (a.2 + 1 = b.2 ∨ b.2 + 1 = a.2)) ∨ (a.2 = b.2 ∧ (a.1 + 1 = b.1 ∨ b.1 + 1 = a.1))

/-- A domino is the set of two squares that share an edge. -/
def IsDomino (d : Finset (ℕ × ℕ)) : Prop := ∃ a b, Adjacent a b ∧ d = {a, b}

/-- The clipped board claim: no 31 dominoes cover the chessboard with two opposite corners
cut off. Whatever 31 dominoes you take, the squares they cover are never exactly the
clipped board. -/
theorem clipped_board_has_no_domino_cover (D : Finset (Finset (ℕ × ℕ)))
    (hcard : D.card = 31) (hD : ∀ d ∈ D, IsDomino d) :
    D.biUnion id ≠ clippedBoard := by
  intro hU
  have hone : ∀ d ∈ D, (d.filter (fun s => ¬ IsDark s)).card = 1 := by
    intro d hd
    obtain ⟨a, b, hab, rfl⟩ := hD d hd
    have hne : a ≠ b := by
      intro h
      subst h
      unfold Adjacent at hab
      omega
    have hdark : (IsDark a ↔ ¬ IsDark b) := by
      unfold Adjacent IsDark at *
      omega
    rw [Finset.card_eq_one]
    by_cases ha : IsDark a
    · refine ⟨b, ?_⟩
      have hb : ¬ IsDark b := hdark.mp ha
      ext x
      simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_singleton]
      constructor
      · rintro ⟨rfl | rfl, hx⟩
        · exact absurd ha hx
        · rfl
      · rintro rfl
        exact ⟨Or.inr rfl, hb⟩
    · refine ⟨a, ?_⟩
      have hb : IsDark b := by
        by_contra hb
        exact ha (hdark.mpr hb)
      ext x
      simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_singleton]
      constructor
      · rintro ⟨rfl | rfl, hx⟩
        · rfl
        · exact absurd hb hx
      · rintro rfl
        exact ⟨Or.inl rfl, ha⟩
  have hle : ((D.biUnion id).filter (fun s => ¬ IsDark s)).card ≤ 31 := by
    rw [Finset.filter_biUnion]
    calc (D.biUnion fun d => (id d).filter (fun s => ¬ IsDark s)).card
        ≤ ∑ d ∈ D, ((id d).filter (fun s => ¬ IsDark s)).card := Finset.card_biUnion_le
      _ = ∑ d ∈ D, 1 := Finset.sum_congr rfl (fun d hd => hone d hd)
      _ = 31 := by simp [hcard]
  rw [hU] at hle
  have h32 : (clippedBoard.filter (fun s => ¬ IsDark s)).card = 32 := by decide
  omega

/-- The trusted step: every domino covers one dark square and one light square. If two squares
share an edge, exactly one of them is dark. -/
theorem domino_covers_one_dark_one_light (a b : ℕ × ℕ) (h : Adjacent a b) :
    (IsDark a ↔ ¬ IsDark b) := by
  unfold Adjacent IsDark at *
  omega

/-- The same move one shelf over: no fraction p over q squares to 2, that is,
p × p is never 2 × q × q when q is not zero. -/
theorem no_fraction_squares_to_two (p q : ℤ) (hq : q ≠ 0) : p * p ≠ 2 * (q * q) := by
  have key : ∀ n : ℕ, ∀ p q : ℤ, q.natAbs = n → q ≠ 0 → p * p ≠ 2 * (q * q) := by
    intro n
    induction n using Nat.strong_induction_on with
    | _ n ih =>
      intro p q hn hq h
      have hp2 : Even p := by
        have : Even (p * p) := ⟨q * q, by rw [h]; ring⟩
        rcases Int.even_mul.mp this with h' | h' <;> exact h'
      obtain ⟨k, rfl⟩ := hp2
      have h2 : q * q = 2 * (k * k) := by nlinarith
      have hq2 : Even q := by
        have : Even (q * q) := ⟨k * k, by rw [h2]; ring⟩
        rcases Int.even_mul.mp this with h' | h' <;> exact h'
      obtain ⟨m, rfl⟩ := hq2
      have hm : m ≠ 0 := by
        rintro rfl
        simp at hq
      have h3 : k * k = 2 * (m * m) := by nlinarith
      have hlt : m.natAbs < n := by
        rw [← hn]
        have : 0 < m.natAbs := Int.natAbs_pos.mpr hm
        omega
      exact ih _ hlt k m rfl hm h3
  exact key _ p q rfl hq

-- The whole board: 64 squares, 32 dark and 32 light.
example : board.card = 64 := by decide
example : (board.filter IsDark).card = 32 ∧ (board.filter (fun s => ¬ IsDark s)).card = 32 := by
  decide

-- Both cut corners are dark: 1 + 1 = 2 and 8 + 8 = 16 are even.
example : IsDark (1, 1) ∧ IsDark (8, 8) := by decide

-- The clipped board: 62 squares, 30 dark and 32 light.
example : clippedBoard.card = 62 := by decide
example : (clippedBoard.filter IsDark).card = 30 ∧
    (clippedBoard.filter (fun s => ¬ IsDark s)).card = 32 := by decide

-- 31 dominoes cover 62 squares, and need 31 dark squares, but only 30 are left.
example : 31 * 2 = (62 : ℕ) ∧ 31 * 1 = (31 : ℕ) ∧ (32 : ℕ) - 2 = 30 ∧ (31 : ℕ) ≠ 30 := by decide

-- The control: cut one dark corner and one light, and the board has 31 dark and 31 light.
example : (((board.erase (1, 1)).erase (1, 8)).filter IsDark).card = 31 ∧
    (((board.erase (1, 1)).erase (1, 8)).filter (fun s => ¬ IsDark s)).card = 31 := by decide

-- The 112 places a domino can sit on the whole board (each counted once, from the end with
-- the smaller row plus column), and every one covers one dark square and one light.
set_option maxRecDepth 20000 in
example : ((board ×ˢ board).filter
    (fun p => p.1.1 + p.1.2 < p.2.1 + p.2.2 ∧ Adjacent p.1 p.2)).card = 112 := by
  decide
set_option maxRecDepth 20000 in
example : ∀ p ∈ (board ×ˢ board).filter
    (fun p => p.1.1 + p.1.2 < p.2.1 + p.2.2 ∧ Adjacent p.1 p.2),
    (IsDark p.1 ↔ ¬ IsDark p.2) := by
  decide

-- For the balanced cut a covering exists: four dominoes across each of rows 2 to 8, and
-- three more on columns 2 to 7 of row 1. That is 31 dominoes covering exactly that board.
set_option maxRecDepth 20000 in
example :
    let rows := (Finset.Icc 2 8 ×ˢ ({1, 3, 5, 7} : Finset ℕ)).image
      (fun x : ℕ × ℕ => ((x.1, x.2), (x.1, x.2 + 1)))
    let top := ({2, 4, 6} : Finset ℕ).image (fun c : ℕ => ((1, c), (1, c + 1)))
    let P := rows ∪ top
    P.card = 31 ∧ (∀ p ∈ P, Adjacent p.1 p.2) ∧
      P.biUnion (fun p => {p.1, p.2}) = (board.erase (1, 1)).erase (1, 8) := by
  decide

-- Fractions get close and stay wrong: 99 × 99 = 9801 and 2 × 70 × 70 = 9800, one apart.
example : (99 : ℤ) * 99 = 9801 ∧ (2 : ℤ) * (70 * 70) = 9800 ∧ (9801 : ℤ) - 9800 = 1 := by decide

#print axioms clipped_board_has_no_domino_cover
#print axioms domino_covers_one_dark_one_light
#print axioms no_fraction_squares_to_two
