-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/39/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job ADD COLUMN started datetime NULL;

;

COMMIT;

