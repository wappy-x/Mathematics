-- Prize citations: the status rule takes the earlier of the refereed date and the prize date, and a citation that does not name a result's proof moves no date.
import Mathlib.Order.WithBot
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Linarith

/-! Dates are whole numbers written YYYYMMDD (day 00 when the source gives only a month),
so their order is the calendar order. `⊤` means "never, as far as the sources show". -/

/-- The four types of phrase in a prize citation (pass 2 on the card). -/
inductive PhraseType
  | result
  | reproof
  | tool
  | field
  deriving DecidableEq, Repr

/-- The prize date `d_prize(c)`: the citation's date `dC` if the citation names a proof of
the result, scope included (its phrase is of type `result`), and `⊤` otherwise. -/
def prizeDate (t : PhraseType) (dC : WithTop ℕ) : WithTop ℕ :=
  if t = PhraseType.result then dC else ⊤

/-- The acceptance date `a(c) = min (d_ref(c), d_prize(c))`. -/
def acceptance (dRef : WithTop ℕ) (t : PhraseType) (dC : WithTop ℕ) : WithTop ℕ :=
  min dRef (prizeDate t dC)

/-- A prize citation sets a result's acceptance date earlier than its refereed paper
exactly when it names the proof as a result, scope included, and is dated before the paper;
every other phrase (reproof, tool, field or progress) is praise and moves no date. -/
theorem citation_sets_date_iff_names_result_before_paper
    (dRef : WithTop ℕ) (t : PhraseType) (dC : WithTop ℕ) :
    acceptance dRef t dC < dRef ↔ t = PhraseType.result ∧ dC < dRef := by
  unfold acceptance prizeDate
  cases t <;> simp [min_lt_iff]

/-- A prize dated after the refereed paper adds a source and changes nothing:
the acceptance date stays the paper's date. -/
theorem prize_after_paper_changes_nothing
    (dRef : WithTop ℕ) (t : PhraseType) (dC : WithTop ℕ) (h : dRef ≤ dC) :
    acceptance dRef t dC = dRef := by
  unfold acceptance prizeDate
  apply min_eq_left
  split
  · exact h
  · exact le_top

/-- The two roads to the genus of `x^n + y^n = 1` agree: the whole-number points strictly
inside the triangle (0, 0), (n, 0), (0, n) number `(n - 1)(n - 2)/2`. -/
theorem interior_points_eq_degree_genus (n : ℕ) :
    ((Finset.Ioo 0 n ×ˢ Finset.Ioo 0 n).filter
        (fun p : ℕ × ℕ => n * p.1 + n * p.2 < n * n)).card = (n - 1) * (n - 2) / 2 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hinner : ∀ a ∈ Finset.Ioo 0 n,
      ((Finset.Ioo 0 n).filter (fun b => n * a + n * b < n * n)).card = n - 2 - (a - 1) := by
    intro a ha
    rw [Finset.mem_Ioo] at ha
    have : (Finset.Ioo 0 n).filter (fun b => n * a + n * b < n * n) = Finset.Ioo 0 (n - a) := by
      ext b
      simp only [Finset.mem_filter, Finset.mem_Ioo]
      constructor
      · rintro ⟨⟨h1, h2⟩, h3⟩
        have : a + b < n := by
          by_contra h
          have h' : n ≤ a + b := by omega
          have := Nat.mul_le_mul_left n h'
          nlinarith
        omega
      · rintro ⟨h1, h2⟩
        refine ⟨⟨h1, by omega⟩, ?_⟩
        have : a + b < n := by omega
        nlinarith
    rw [this, Nat.card_Ioo]
    omega
  rw [Finset.card_filter, Finset.sum_product]
  have e1 : ∀ a ∈ Finset.Ioo 0 n,
      (∑ b ∈ Finset.Ioo 0 n, if n * (a, b).1 + n * (a, b).2 < n * n then 1 else 0) = n - 2 - (a - 1) := by
    intro a ha
    rw [← hinner a ha, Finset.card_filter]
  rw [Finset.sum_congr rfl e1]
  have hI : Finset.Ioo 0 n = Finset.Ico 1 n := by
    ext x; simp only [Finset.mem_Ioo, Finset.mem_Ico]; omega
  rw [hI, Finset.sum_Ico_eq_sum_range]
  have e2 : ∀ k ∈ Finset.range (n - 1), n - 2 - (1 + k - 1) = n - 1 - 1 - k := by
    intro k _; omega
  rw [Finset.sum_congr rfl e2]
  have h2 := Finset.sum_range_reflect (fun k => k) (n - 1)

  rw [h2]
  have h3 := Finset.sum_range_id_mul_two (n - 1)
  have : n - 1 - 1 = n - 2 := by omega
  rw [this] at h3
  omega

-- The status rule on the card's three rows.
-- Mordell: refereed 1983-10, Abel 2026-03-19 names it: the paper sets the date.
example : acceptance (19831000 : ℕ) PhraseType.result (20260319 : ℕ) = (19831000 : ℕ) := by decide
-- Geometric Langlands, characteristic 0: no refereed paper, Breakthrough 2025-04-05 names it.
example : acceptance ⊤ PhraseType.result (20250405 : ℕ) = (20250405 : ℕ) := by decide
-- Kakeya, three dimensions: "major advances" is progress; the refereed proof of 2026-11-06 sets it.
example : acceptance (20261106 : ℕ) PhraseType.field (20260723 : ℕ) = (20261106 : ℕ) := by decide
-- The misreading: "major advances" read as a result would date it 2026-07-23.
example : acceptance (20261106 : ℕ) PhraseType.result (20260723 : ℕ) = (20260723 : ℕ) := by decide
-- Dowling-Wilson for all geometric lattices: refereed 2026-07-01, Fields 2022-07-05 came first.
example : acceptance (20260701 : ℕ) PhraseType.result (20220705 : ℕ) = (20220705 : ℕ) := by decide

-- 106 days from 2026-07-23 to 2026-11-06, by the month table of 2026 (July to October).
example : ((([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] : List ℕ).drop 6).take 4).sum
    - 23 + 6 = 106 := by decide

-- Genus by the degree formula: 1, 3, 6, 10 for n = 3, 4, 5, 6; x^4 + y^4 = 1 has genus 3.
example : (4 - 1) * (4 - 2) / 2 = 3 := by decide
example : ((Finset.Ioo 0 3 ×ˢ Finset.Ioo 0 3).filter
    (fun p : ℕ × ℕ => 3 * p.1 + 3 * p.2 < 3 * 3)).card = 1 := by decide
example : ((Finset.Ioo 0 4 ×ˢ Finset.Ioo 0 4).filter
    (fun p : ℕ × ℕ => 4 * p.1 + 4 * p.2 < 4 * 4)).card = 3 := by decide
example : ((Finset.Ioo 0 5 ×ˢ Finset.Ioo 0 5).filter
    (fun p : ℕ × ℕ => 5 * p.1 + 5 * p.2 < 5 * 5)).card = 6 := by decide
example : ((Finset.Ioo 0 6 ×ˢ Finset.Ioo 0 6).filter
    (fun p : ℕ × ℕ => 6 * p.1 + 6 * p.2 < 6 * 6)).card = 10 := by decide
-- y^2 = x^3 - x + 1: the triangle (0, 0), (3, 0), (0, 2) holds one interior point, genus 1.
example : ((Finset.Ioo 0 3 ×ˢ Finset.Ioo 0 2).filter
    (fun p : ℕ × ℕ => 2 * p.1 + 3 * p.2 < 3 * 2)).card = 1 := by decide

-- The points kP on y^2 = x^3 - x + 1 from P = (1, 1), heights 1, 1, 1, 3, 5, 4.
example : ((1 : ℚ)) ^ 2 = (1 : ℚ) ^ 3 - 1 + 1 := by norm_num
example : ((1 : ℚ)) ^ 2 = (-1 : ℚ) ^ 3 - (-1) + 1 := by norm_num
example : ((-1 : ℚ)) ^ 2 = (0 : ℚ) ^ 3 - 0 + 1 := by norm_num
example : ((-5 : ℚ)) ^ 2 = (3 : ℚ) ^ 3 - 3 + 1 := by norm_num
example : ((11 : ℚ)) ^ 2 = (5 : ℚ) ^ 3 - 5 + 1 := by norm_num
example : ((7 / 8 : ℚ)) ^ 2 = (1 / 4 : ℚ) ^ 3 - 1 / 4 + 1 := by norm_num

#print axioms citation_sets_date_iff_names_result_before_paper
#print axioms prize_after_paper_changes_nothing
#print axioms interior_points_eq_degree_genus
