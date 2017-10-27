-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/43/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/44/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN bb_impressum smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_sansfontsections smallint DEFAULT 0;

;

COMMIT;

