-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/41/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/42/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN format_priority integer DEFAULT 0 NOT NULL;

;

COMMIT;

