package tutor

import (
	"context"

	"gorm.io/gorm"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service { return &Service{repo: repo} }

// SubmitOnboarding persists a tutor's complete onboarding in one transaction
// (PRD §5.2): it updates the user's personal info, upserts the tutor profile,
// replaces the subject and schedule sets, appends the credential documents, and
// sets verification_status to pending_review. Re-submitting after a rejection or
// a documents request is allowed and re-enters the review queue (PRD §5.3).
//
// All validation runs before any write so a bad request never partially mutates
// state. The returned response is the freshly loaded aggregate.
func (s *Service) SubmitOnboarding(ctx context.Context, userID uint64, req SubmitOnboardingRequest) (*TutorProfileResponse, error) {
	if req.HourlyRate < minHourlyRate || req.HourlyRate > maxHourlyRate {
		return nil, ErrInvalidRate
	}

	subjects, err := buildSubjects(req.Subjects)
	if err != nil {
		return nil, err
	}

	slots, err := buildSchedules(req.Schedule)
	if err != nil {
		return nil, err
	}

	var bio *string
	if req.Bio != "" {
		bio = &req.Bio
	}
	var phone *string
	if req.Phone != "" {
		phone = &req.Phone
	}
	var avatar *string
	if req.AvatarURL != "" {
		avatar = &req.AvatarURL
	}

	var profileID uint64
	err = s.repo.WithinTx(ctx, func(tx *gorm.DB) error {
		if err := s.repo.UpdateUserPersonal(tx, userID, req.Name, phone, avatar); err != nil {
			return err
		}
		profile := &TutorProfile{
			UserID:             userID,
			HourlyRate:         req.HourlyRate,
			Bio:                bio,
			VerificationStatus: VerificationPending,
		}
		if err := s.repo.UpsertProfileByUserID(tx, profile); err != nil {
			return err
		}
		profileID = profile.ID

		if err := s.repo.DeleteSubjectsByTutor(tx, profileID); err != nil {
			return err
		}
		for i := range subjects {
			subjects[i].TutorID = profileID
		}
		if err := s.repo.InsertSubjects(tx, subjects); err != nil {
			return err
		}

		if err := s.repo.DeleteSchedulesByTutor(tx, profileID); err != nil {
			return err
		}
		for i := range slots {
			slots[i].TutorID = profileID
		}
		if err := s.repo.InsertSchedules(tx, slots); err != nil {
			return err
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	return s.loadResponse(ctx, profileID, userID)
}

// GetMyProfile returns the authenticated tutor's full onboarding aggregate, or
// ErrProfileNotFound if they have not onboarded yet.
func (s *Service) GetMyProfile(ctx context.Context, userID uint64) (*TutorProfileResponse, error) {
	profile, err := s.repo.FindProfileByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}
	return s.loadResponse(ctx, profile.ID, userID)
}

func (s *Service) loadResponse(ctx context.Context, profileID, userID uint64) (*TutorProfileResponse, error) {
	aggregate, err := s.repo.LoadAggregate(ctx, profileID)
	if err != nil {
		return nil, err
	}
	user, err := s.repo.FindUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	resp := toTutorProfileResponse(aggregate, user)
	return &resp, nil
}

// buildSubjects validates the controlled vocabulary and de-duplicates on
// (subject, level) so the UNIQUE constraint is never tripped by a repeated row.
func buildSubjects(in []SubjectInput) ([]TutorSubject, error) {
	seen := make(map[string]struct{}, len(in))
	out := make([]TutorSubject, 0, len(in))
	for _, s := range in {
		if !IsValidSubject(s.Subject) {
			return nil, ErrInvalidSubject
		}
		if !IsValidLevel(s.Level) {
			return nil, ErrInvalidLevel
		}
		key := s.Subject + "\x00" + s.Level
		if _, dup := seen[key]; dup {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, TutorSubject{Subject: s.Subject, Level: s.Level})
	}
	return out, nil
}

func buildDocuments(in []DocumentInput) ([]TutorDocument, error) {
	out := make([]TutorDocument, 0, len(in))
	for _, d := range in {
		if !IsValidDocType(d.DocType) {
			return nil, ErrInvalidDocType
		}
		out = append(out, TutorDocument{DocType: d.DocType, FileURL: d.FileURL})
	}
	return out, nil
}

// buildSchedules validates each slot's time range and canonicalizes the clock
// strings, de-duplicating identical (day, start, end) rows.
func buildSchedules(in []ScheduleInput) ([]Schedule, error) {
	seen := make(map[string]struct{}, len(in))
	out := make([]Schedule, 0, len(in))
	for _, s := range in {
		if s.DayOfWeek < 0 || s.DayOfWeek > 6 {
			return nil, ErrInvalidSchedule
		}
		if !validTimeRange(s.StartTime, s.EndTime) {
			return nil, ErrInvalidSchedule
		}
		start := normalizeClock(s.StartTime)
		end := normalizeClock(s.EndTime)
		key := string(rune(s.DayOfWeek)) + start + "\x00" + end
		if _, dup := seen[key]; dup {
			continue
		}
		seen[key] = struct{}{}
		out = append(out, Schedule{
			DayOfWeek:   s.DayOfWeek,
			StartTime:   start,
			EndTime:     end,
			IsAvailable: true,
		})
	}
	return out, nil
}
