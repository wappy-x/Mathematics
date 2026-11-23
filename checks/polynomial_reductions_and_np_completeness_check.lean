-- Reductions: a school fits its exams into k sessions exactly when its clash graph has a k-colouring, a graph has a k-colouring exactly when its one-student-per-line school fits, and the map f writes at most n squared pairs.
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex

/-! The card's two problems and its two maps.

`students i` is the set of exams that student `i` sits. A school fits in `k` sessions when some
assignment of one of `k` sessions to each exam gives each student's exams different sessions
(TIMETABLE_k). The map f writes one dot per exam and a line between two exams one student sits.
The map g writes one exam per dot and one student per line, sitting that line's two ends. -/

/-- TIMETABLE_k: the exams fit in `k` sessions with no student sitting two exams at once. -/
def FitsInSessions {V ι : Type*} (students : ι → Set V) (k : ℕ) : Prop :=
  ∃ a : V → Fin k, ∀ i, Set.InjOn a (students i)

/-- The map f: the clash graph, a line between two different exams that one student sits. -/
def clashGraph {V ι : Type*} (students : ι → Set V) : SimpleGraph V :=
  SimpleGraph.fromRel fun u v => ∃ i, u ∈ students i ∧ v ∈ students i

/-- The map g: one student per line of `G`, enrolled in the line's two ends. -/
def schoolOf {V : Type*} (G : SimpleGraph V) : {p : V × V // G.Adj p.1 p.2} → Set V :=
  fun e => {e.1.1, e.1.2}

/-- The map f keeps every answer: a school fits in `k` sessions exactly when its clash graph can be
coloured with `k` colours, no line joining two dots of one colour. So TIMETABLE_k reduces to
COLOURING_k, sending yes to yes and no to no. -/
theorem timetable_fits_iff_clash_graph_colorable {V ι : Type*} (students : ι → Set V) (k : ℕ) :
    FitsInSessions students k ↔ (clashGraph students).Colorable k := by
  constructor
  · rintro ⟨a, ha⟩
    refine ⟨SimpleGraph.Coloring.mk a ?_⟩
    intro u v huv hau
    rw [clashGraph, SimpleGraph.fromRel_adj] at huv
    obtain ⟨hne, ⟨i, hu, hv⟩ | ⟨i, hv, hu⟩⟩ := huv
    · exact hne (ha i hu hv hau)
    · exact hne (ha i hu hv hau)
  · rintro ⟨C⟩
    refine ⟨C, fun i u hu v hv huv => ?_⟩
    by_contra hne
    have hadj : (clashGraph students).Adj u v := by
      rw [clashGraph, SimpleGraph.fromRel_adj]
      exact ⟨hne, Or.inl ⟨i, hu, hv⟩⟩
    exact C.valid hadj huv

/-- The map g keeps every answer: a graph can be coloured with `k` colours exactly when the school
with one student per line, sitting its two ends, fits in `k` sessions. So COLOURING_k reduces to
TIMETABLE_k, which is the direction that carries colouring's hardness into timetabling. -/
theorem colorable_iff_school_of_graph_fits {V : Type*} (G : SimpleGraph V) (k : ℕ) :
    G.Colorable k ↔ FitsInSessions (schoolOf G) k := by
  constructor
  · rintro ⟨C⟩
    refine ⟨C, fun e u hu v hv huv => ?_⟩
    simp only [schoolOf, Set.mem_insert_iff, Set.mem_singleton_iff] at hu hv
    rcases hu with rfl | rfl <;> rcases hv with rfl | rfl
    · rfl
    · exact absurd huv (C.valid e.2)
    · exact absurd huv.symm (C.valid e.2)
    · rfl
  · rintro ⟨a, ha⟩
    refine ⟨SimpleGraph.Coloring.mk a ?_⟩
    intro u v huv hau
    have := ha ⟨(u, v), huv⟩ (by simp [schoolOf]) (by simp [schoolOf]) hau
    exact G.ne_of_adj huv this

/-- The map f is polynomial: a student sitting `s` exams gives `s (s - 1) / 2` pairs, and the pairs
for all students add up to at most the square of the total number of exam entries, so at most
the input length squared. -/
theorem clash_pairs_le_sq_input_length (sizes : List ℕ) :
    (sizes.map fun s => s * (s - 1) / 2).sum ≤ sizes.sum ^ 2 := by
  induction sizes with
  | nil => simp
  | cons s t ih =>
    simp only [List.map_cons, List.sum_cons]
    have h1 : s * (s - 1) / 2 ≤ s * s :=
      (Nat.div_le_self _ _).trans (Nat.mul_le_mul_left _ (Nat.sub_le _ _))
    calc s * (s - 1) / 2 + (t.map fun s => s * (s - 1) / 2).sum ≤ s * s + t.sum ^ 2 :=
          Nat.add_le_add h1 ih
      _ ≤ (s + t.sum) ^ 2 := by
          rw [add_sq, sq s]
          exact Nat.add_le_add_right (Nat.le_add_right _ _) _

/-! The card's school: Art 0, Biology 1, Chemistry 2, Drama 3, English 4, French 5, Geography 6. -/

/-- The eight students' exam lists. -/
def school : List (List ℕ) := [[0, 1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 0], [1, 4], [3, 4]]

/-- Every pair of exams one student sits, as the map f writes them, smaller exam first. -/
def schoolPairs : List (ℕ × ℕ) :=
  school.flatMap fun s =>
    (List.range s.length).flatMap fun i =>
      ((List.range s.length).filter (i < ·)).map fun j => (min s[i]! s[j]!, max s[i]! s[j]!)

/-- The session of exam `e` under assignment number `c`, read as `k`-ary digits, as in the code. -/
def session (k c e : ℕ) : ℕ := c / k ^ e % k

/-- The number of ways to give the 7 exams one of `k` sessions with every student's exams apart. -/
def timetables (k : ℕ) : ℕ :=
  ((List.range (k ^ 7)).filter fun c =>
    school.all fun s => (s.map (session k c)).Nodup).length

-- f writes 10 pairs and keeps 9 distinct clash lines.
example : schoolPairs.length = 10 := by decide
example : schoolPairs.dedup.length = 9 := by decide
-- The school written out, ABC/CD/DE/EF/FG/GA/BE/DE, is n = 24 symbols, and 10 ≤ 24 ^ 2 = 576.
example : (school.map List.length).sum + (school.length - 1) = 24 := by decide
example : (school.map fun s => s.length * (s.length - 1) / 2).sum = 10 ∧ 10 ≤ 24 ^ 2 ∧ 24 ^ 2 = 576 := by
  decide
-- Two sessions fail, three work in 48 ways.
example : timetables 2 = 0 := by decide +kernel
example : timetables 3 = 48 := by decide +kernel
-- The search sizes: 3 ^ 7 = 2,187 at 7 exams and 3 ^ 40, about 1.22 × 10 ^ 19, at 40.
example : 3 ^ 7 = 2187 := by decide
example : 3 ^ 40 = 12157665459056928801 := by decide
-- f's cost at m exams with 2m students of 5 exams each: 10 pairs per student.
example : [10, 20, 40, 80].map (fun m => 2 * m * (5 * 4 / 2)) = [200, 400, 800, 1600] := by decide
-- Sudoku as colouring: the k by k grid with r by r boxes has k ^ 2 (3k - 2r - 1) / 2 lines.
example : 4 ^ 2 * (3 * 4 - 2 * 2 - 1) / 2 = 56 ∧ 9 ^ 2 * (3 * 9 - 2 * 3 - 1) / 2 = 810 := by decide
example : 4 * 3 / 2 = 6 ∧ 9 * 8 / 2 = 36 := by decide

#print axioms timetable_fits_iff_clash_graph_colorable
#print axioms colorable_iff_school_of_graph_fits
#print axioms clash_pairs_le_sq_input_length
