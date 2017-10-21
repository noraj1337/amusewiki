-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/42/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/43/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_2up character varying(8) DEFAULT '40-80' NOT NULL;

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_4up character varying(8) DEFAULT '40-80' NOT NULL;

;

COMMIT;

