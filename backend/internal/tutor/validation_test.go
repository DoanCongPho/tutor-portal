package tutor

import (
	"errors"
	"testing"
)

func TestBuildSubjects(t *testing.T) {
	t.Run("valid and deduped", func(t *testing.T) {
		in := []SubjectInput{
			{Subject: "Toán", Level: LevelHighSchool},
			{Subject: "Toán", Level: LevelHighSchool},       // exact dup → dropped
			{Subject: "Toán", Level: LevelUniversity},        // same subject, different level → kept
			{Subject: "Tiếng Anh", Level: LevelMiddleSchool}, // distinct
		}
		out, err := buildSubjects(in)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(out) != 3 {
			t.Fatalf("want 3 deduped subjects, got %d: %+v", len(out), out)
		}
	})

	t.Run("subject outside vocabulary", func(t *testing.T) {
		_, err := buildSubjects([]SubjectInput{{Subject: "Underwater Basketweaving", Level: LevelHighSchool}})
		if !errors.Is(err, ErrInvalidSubject) {
			t.Fatalf("want ErrInvalidSubject, got %v", err)
		}
	})

	t.Run("invalid level", func(t *testing.T) {
		_, err := buildSubjects([]SubjectInput{{Subject: "Toán", Level: "kindergarten"}})
		if !errors.Is(err, ErrInvalidLevel) {
			t.Fatalf("want ErrInvalidLevel, got %v", err)
		}
	})
}

func TestBuildDocuments(t *testing.T) {
	out, err := buildDocuments([]DocumentInput{{DocType: DocDegree, FileURL: "https://x/d.pdf"}})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(out) != 1 || out[0].DocType != DocDegree {
		t.Fatalf("unexpected docs: %+v", out)
	}

	if _, err := buildDocuments([]DocumentInput{{DocType: "selfie", FileURL: "x"}}); !errors.Is(err, ErrInvalidDocType) {
		t.Fatalf("want ErrInvalidDocType, got %v", err)
	}
}

func TestBuildSchedules(t *testing.T) {
	t.Run("normalizes clock and dedupes", func(t *testing.T) {
		in := []ScheduleInput{
			{DayOfWeek: 1, StartTime: "18:00", EndTime: "20:00"},
			{DayOfWeek: 1, StartTime: "18:00:00", EndTime: "20:00:00"}, // same after normalization → dropped
			{DayOfWeek: 0, StartTime: "09:00", EndTime: "11:30"},       // Sunday is valid
		}
		out, err := buildSchedules(in)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(out) != 2 {
			t.Fatalf("want 2 deduped slots, got %d: %+v", len(out), out)
		}
		if out[0].StartTime != "18:00:00" || out[0].EndTime != "20:00:00" {
			t.Fatalf("want normalized HH:MM:SS, got %+v", out[0])
		}
	})

	t.Run("rejects end before start", func(t *testing.T) {
		_, err := buildSchedules([]ScheduleInput{{DayOfWeek: 2, StartTime: "20:00", EndTime: "18:00"}})
		if !errors.Is(err, ErrInvalidSchedule) {
			t.Fatalf("want ErrInvalidSchedule, got %v", err)
		}
	})

	t.Run("rejects out-of-range day", func(t *testing.T) {
		_, err := buildSchedules([]ScheduleInput{{DayOfWeek: 7, StartTime: "08:00", EndTime: "09:00"}})
		if !errors.Is(err, ErrInvalidSchedule) {
			t.Fatalf("want ErrInvalidSchedule, got %v", err)
		}
	})

	t.Run("rejects malformed time", func(t *testing.T) {
		_, err := buildSchedules([]ScheduleInput{{DayOfWeek: 1, StartTime: "25:99", EndTime: "26:00"}})
		if !errors.Is(err, ErrInvalidSchedule) {
			t.Fatalf("want ErrInvalidSchedule, got %v", err)
		}
	})
}

func TestVocabularyValidators(t *testing.T) {
	if !IsValidSubject("Toán") || IsValidSubject("Nope") {
		t.Fatal("IsValidSubject wrong")
	}
	if !IsValidLevel(LevelPrimary) || IsValidLevel("grad_school") {
		t.Fatal("IsValidLevel wrong")
	}
	if !IsValidDocType(DocNationalID) || IsValidDocType("passport") {
		t.Fatal("IsValidDocType wrong")
	}
}
